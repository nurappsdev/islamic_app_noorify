import 'models/hadith_book.dart';

/// The books shown on the Hadith library "E-book" shelf.
///
/// Only [nawawi40] is backed by real data today (`assets/hadith/hadiths.xml`);
/// the rest are placeholders until their source files are added.
class HadithBookCatalog {
  const HadithBookCatalog._();

  static const nawawi40 = HadithBook(
    slug: 'nawawi-40',
    titleEn: '40 Hadith an-Nawawi',
    titleBn: 'চল্লিশ হাদিস (আন-নববী)',
    authorEn: 'Imam an-Nawawi',
    hadithCount: 42,
    assetXmlPath: 'assets/hadith/hadiths.xml',
  );

  static const all = <HadithBook>[
    nawawi40,
    HadithBook(
      slug: 'riyadus-salihin',
      titleEn: 'Riyad as-Salihin',
      titleBn: 'রিয়াদুস সালেহীন',
      authorEn: 'Imam an-Nawawi',
      hadithCount: 1896,
    ),
    HadithBook(
      slug: 'bukhari-shareef',
      titleEn: 'Sahih al-Bukhari',
      titleBn: 'সহীহ বুখারী',
      authorEn: 'Imam al-Bukhari',
      hadithCount: 7563,
    ),
    HadithBook(
      slug: 'muslim-shareef',
      titleEn: 'Sahih Muslim',
      titleBn: 'সহীহ মুসলিম',
      authorEn: 'Imam Muslim',
      hadithCount: 7470,
    ),
  ];

  static HadithBook? bySlug(String slug) {
    for (final book in all) {
      if (book.slug == slug) return book;
    }
    return null;
  }
}
