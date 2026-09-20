import 'package:flutter/material.dart';

/// An e-book's cover picture. The bundled book image stands in while it loads,
/// when the book has no cover, or if the download fails.
class EbookCover extends StatelessWidget {
  const EbookCover({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset(
      'assets/images/book.png',
      fit: BoxFit.cover,
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
