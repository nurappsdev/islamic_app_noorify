import 'package:flutter/material.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'quran_design.dart';

Future<T?> showQuranModal<T>(
  BuildContext context,
  Widget child, {
  double heightFactor = .91,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.surfaceColor(Colors.white),
  shape: const RoundedRectangleBorder(
    side: BorderSide(color: quranOlive),
    borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: FractionallySizedBox(heightFactor: heightFactor, child: child),
  ),
);

class QuranSheetHeading extends StatelessWidget {
  const QuranSheetHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        width: 46,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: quranInk,
          ),
        ),
      ),
    ],
  );
}
