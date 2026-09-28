import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/surah_summary.dart';
import '../quran_text.dart';

class QuranSurahPickerSheet extends StatefulWidget {
  const QuranSurahPickerSheet({
    super.key,
    this.selectedSurahNumber,
    required this.title,
  });

  final int? selectedSurahNumber;
  final String title;

  static Future<SurahSummary?> show(
    BuildContext context, {
    int? selectedSurahNumber,
    required String title,
  }) {
    return showModalBottomSheet<SurahSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranSurahPickerSheet(
        selectedSurahNumber: selectedSurahNumber,
        title: title,
      ),
    );
  }

  @override
  State<QuranSurahPickerSheet> createState() => _QuranSurahPickerSheetState();
}

class _QuranSurahPickerSheetState extends State<QuranSurahPickerSheet> {
  final _searchController = TextEditingController();
  List<SurahSummary> _surahs = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  Future<void> _loadSurahs() async {
    try {
      final list = await QuranContentService.shared.loadSurahs();
      if (mounted) {
        setState(() {
          _surahs = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuranText.of(context);
    final filtered = _surahs.where((s) {
      if (_query.isEmpty) return true;
      return s.name.toLowerCase().contains(_query) ||
          s.translation.toLowerCase().contains(_query) ||
          t.surahName(s.number).contains(_query) ||
          s.number.toString().contains(_query) ||
          t.n(s.number).contains(_query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.pageColor(Colors.white),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF282442),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 20.sp,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t.searchSurahHint,
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 10.h,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F6E7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: Color(0xFFD4E5A8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: Color(0xFFD4E5A8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(
                    color: Color(0xFFA1AE57),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFA1AE57)),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      t.noSurahsFound,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      final isSelected =
                          surah.number == widget.selectedSurahNumber;
                      return ListTile(
                        onTap: () => Navigator.pop(context, surah),
                        leading: Container(
                          width: 36.r,
                          height: 36.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFA1AE57)
                                : const Color(0xFFF0F5DF),
                            shape: BoxShape.circle,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t.n(surah.number),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF5D7033),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          t.surahName(surah.number, surah.name),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFA1AE57)
                                : const Color(0xFF282442),
                            fontSize: 14.sp,
                          ),
                        ),
                        subtitle: Text(
                          '${t.revelationPlace(surah.revelationPlace)} • ${t.ayahCount(surah.totalAyah)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Text(
                          surah.nameArabic,
                          style: TextStyle(
                            fontFamily: 'noorehuda',
                            fontSize: 16.sp,
                            color: const Color(0xFF4A5A38),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
