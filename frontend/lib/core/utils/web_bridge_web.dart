import 'dart:html' as html;

/// On Android Chrome: redirects to the native app via custom scheme.
/// Returns true if the redirect was attempted (Android UA detected).
bool tryOpenMobileApp(String accessToken, String refreshToken) {
  try {
    final ua = html.window.navigator.userAgent;
    if (!ua.contains('Android')) return false;
    final uri = Uri(
      scheme: 'com.storelink.app',
      host: 'auth-callback',
      queryParameters: {
        'access_token': accessToken,
        if (refreshToken.isNotEmpty) 'refresh_token': refreshToken,
      },
    );
    html.window.location.href = uri.toString();
    return true;
  } catch (_) {
    return false;
  }
}
