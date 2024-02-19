import 'package:http/http.dart' as http;

Future<String> getToken() async {
  final r = await http.get(Uri.parse("https://livekit.wikylyu.xyz/getToken"));
  return r.body;
}
