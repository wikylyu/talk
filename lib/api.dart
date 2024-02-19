import 'package:http/http.dart' as http;

Future<String> getToken() async {
  final r = await http.get(Uri.parse("https://live.chainboats.com/getToken"));
  return r.body;
}
