import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Opens the platform mail composer for [email].
Future<void> launchEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email.trim());
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Opens [rawUrl] in the browser, adding `https://` when the scheme is missing
/// (e.g. `linkedin.com/in/...`).
Future<void> launchWebUrl(String rawUrl) async {
  var url = rawUrl.trim();
  if (url.isEmpty) return;
  if (!url.startsWith(RegExp(r'https?://'))) {
    url = 'https://$url';
  }
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Opens the phone dialer for [phone].
Future<void> launchPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
  await launchUrl(uri);
}

/// Tappable text styled as a hyperlink. Pass exactly one of [email]/[url]/
/// [phone]; falls back to plain [text] when none is provided.
class LinkText extends StatelessWidget {
  const LinkText({
    super.key,
    required this.text,
    this.email,
    this.url,
    this.phone,
    this.style,
    this.maxLines,
  });

  final String text;
  final String? email;
  final String? url;
  final String? phone;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? AppTextStyles.bodyMedium).copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return InkWell(
      onTap: () {
        if (email != null && email!.isNotEmpty) {
          launchEmail(email!);
        } else if (url != null && url!.isNotEmpty) {
          launchWebUrl(url!);
        } else if (phone != null && phone!.isNotEmpty) {
          launchPhone(phone!);
        }
      },
      child: Text(
        text,
        style: base,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}
