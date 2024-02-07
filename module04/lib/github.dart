import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

String clientId = dotenv.env['GITHUBKEY'] ?? '';
String clientSecret = dotenv.env['GITHUBSECRET'] ?? '';
String redirectUri = dotenv.env['GITHUBREDIRECTURI'] ?? '';

Future<UserCredential> signInWithGitHub() async {
  final Uri authorizationUrl = Uri.https('github.com', '/login/oauth/authorize', {
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'scope': 'read:user',
  });

  final Stream<String?> uriLinkStream = linkStream.map((String? link) {
    if (link != null) {
      final Uri uri = Uri.parse(link);
      if (uri.queryParameters.containsKey('code')) {
        return uri.queryParameters['code'];
      }
    }
    return null;
  });

  if (await canLaunchUrl(Uri.parse(authorizationUrl.toString()))) {
    await launchUrl(Uri.parse(authorizationUrl.toString()));
  } else {
    throw 'Could not launch $authorizationUrl';
  }

  final String? authorizationCode = await uriLinkStream.firstWhere((code) => code != null, orElse: () => null);

  final http.Response response = await http.post(
    Uri.https('github.com', '/login/oauth/access_token'),
    headers: {'Accept': 'application/json'},
    body: {
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': authorizationCode,
      'redirect_uri': redirectUri,
    },
  );

  final Map<String, dynamic> body = jsonDecode(response.body);

  final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(
    GithubAuthProvider.credential(body['access_token']),
  );

  return userCredential;
}