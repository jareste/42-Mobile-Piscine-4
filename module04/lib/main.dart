import 'package:flutter/material.dart';
import 'github.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'github.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: FirebaseAuth.instance.currentUser,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show a loading spinner while waiting
          } else {
            if (snapshot.data != null) {
              return LoggedInView(); // Show the logged in view if a user is logged in
            } else {
              return const MyHomePage(title: 'Flutter Demo Home Page'); // Show the MyHomePage if no user is logged in
            }
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;



  void openGitHubSignInPage(BuildContext context, Uri url) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(),
        body: WebView(
          initialUrl: url.toString(),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
          },
          navigationDelegate: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    }));
  }


  Future<UserCredential> signInWithGitHub() async {
    String clientId = dotenv.env['GITHUBKEY'] ?? '';
    String clientSecret = dotenv.env['GITHUBSECRET'] ?? '';

    final Uri gitHubOAuthUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'scope': 'read:user user:email',
    });


    final Uri gitHubTokenUrl = Uri.https('github.com', '/login/oauth/access_token', {
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': 'CODE_FROM_REDIRECT_URL',
    });
    final http.Response response = await http.post(gitHubTokenUrl, headers: {'Accept': 'application/json'});
    final Map<String, dynamic> responseBody = convert.jsonDecode(response.body);
    if (responseBody == null || !responseBody.containsKey('access_token') || responseBody['access_token'] == null) {
      throw Exception('Failed to obtain access token');
    }
    final String accessToken = responseBody['access_token'];
    final AuthCredential credential = GithubAuthProvider.credential(accessToken);
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Sign in with GitHub'),
          onPressed: () async {
            try {
              // Construct the GitHub OAuth URL
              final Uri gitHubOAuthUrl = Uri.https('github.com', '/login/oauth/authorize', {
                'client_id': clientId,
                'scope': 'read:user user:email',
              });

              openGitHubSignInPage(context, gitHubOAuthUrl);

              // UserCredential userCredential = await signInWithGitHub(code);
              // if (userCredential.user != null) {
              //   print('Successfully signed in with GitHub. uid: ${userCredential.user!.uid}');
              // } else {
              //   print('No user signed in.');
              // }
            } catch (e) {
              print('Failed to sign in with GitHub: $e');
            }
          },
        ),
      ),
    );
  }
}
