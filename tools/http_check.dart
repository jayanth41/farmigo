import 'dart:io';

void main(List<String> args) async {
  final urls = [
    'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
    'https://picsum.photos/600/400',
    'https://raw.githubusercontent.com/flutter/assets-for-api-docs/master/assets/widgets/owl.jpg',
  ];

  for (final url in urls) {
    print('\n---- Trying: $url');
    try {
      final uri = Uri.parse(url);
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 8);
      final req = await httpClient.getUrl(uri);
      // set a simple user-agent to avoid some hosts rejecting blank agents
      req.headers.set(HttpHeaders.userAgentHeader, 'DartHttpClient/1.0');
      final resp = await req.close();
      print('Status: \\${resp.statusCode}');
      print('Headers:\n${resp.headers}');
      final bodyBytes = await resp.fold<List<int>>(<int>[], (a, b) { a.addAll(b); return a; });
      print('Downloaded bytes: ${bodyBytes.length}');
      httpClient.close(force: true);
    } catch (e) {
      print('Exception: $e');
    }
  }
}
