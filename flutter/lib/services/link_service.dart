import 'package:url_launcher/url_launcher.dart';

class LinkService {
  LinkService._();
  static final LinkService instance = LinkService._();

  Future<void> openExternal(String url) async {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw Exception('Invalid URL');
    }
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Unable to open link');
    }
  }
}
