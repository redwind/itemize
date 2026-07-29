/// Where the privacy policy and terms actually live.
///
/// Apple will not review a build without a reachable privacy policy URL, and a
/// paywall that takes money without linking its terms is a 3.1.2 rejection
/// waiting to happen. Both are one string each, kept here rather than typed
/// into two screens, so there is exactly one place to change when the pages
/// move.
///
/// The markup for both pages is in `docs/`, ready to be served by GitHub Pages
/// or anything else that serves a file. Publish those, then put the real
/// addresses here.
///
/// `legal_urls_test.dart` fails while these are still placeholders. That is
/// deliberate and it is the point: this is a submission requirement that is
/// invisible until a reviewer rejects the build, so it is worth a red test
/// rather than a note in a file nobody opens.
const String kPrivacyPolicyUrl = _unset;
const String kTermsOfUseUrl = _unset;

/// The value both start life as.
const String _unset = 'https://example.invalid/set-me';

/// Whether [url] has been pointed at something real.
///
/// `.invalid` is reserved by RFC 2606 precisely so that it can never resolve,
/// which makes it a placeholder that cannot be mistaken for a working address
/// by anything -- including a reviewer's browser.
bool isLegalUrlConfigured(String url) =>
    url != _unset && Uri.tryParse(url)?.hasScheme == true;

/// Whether both pages are ready to be linked to.
bool get legalUrlsConfigured =>
    isLegalUrlConfigured(kPrivacyPolicyUrl) &&
    isLegalUrlConfigured(kTermsOfUseUrl);
