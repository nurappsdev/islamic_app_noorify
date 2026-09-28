import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import '../../domain/quran_plan.dart';
import '../../data/services/quran_plan_store.dart';
import '../quran_route_args.dart';
import 'create_quran_plan_screen.dart';

class QuranPlanScreen extends StatefulWidget {
  const QuranPlanScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<QuranPlanScreen> createState() => _QuranPlanScreenState();
}

class _QuranPlanScreenState extends State<QuranPlanScreen> {
  int _tab = 0; // 0 = My Plan, 1 = Search Plan, 2 = Complete Plan
  List<QuranPlan> _plans = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final list = await QuranPlanStore.loadPlans();
    if (mounted) {
      setState(() {
        _plans = list;
        _loading = false;
      });
    }
  }

  Future<void> _openCreatePlan() async {
    final result = await Navigator.of(context).push<QuranPlan>(
      MaterialPageRoute(builder: (_) => const CreateQuranPlanScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _tab = 0;
      });
      _loadPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan "${result.name}" created successfully!'),
          backgroundColor: const Color(0xFF6B8042),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _enrollPreset(QuranPlan preset) async {
    final newPlan = QuranPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: preset.name,
      days: preset.days,
      startSurah: preset.startSurah,
      startSurahName: preset.startSurahName,
      endSurah: preset.endSurah,
      endSurahName: preset.endSurahName,
      createdAt: DateTime.now(),
    );
    await QuranPlanStore.savePlan(newPlan);
    if (!mounted) return;
    setState(() => _tab = 0);
    _loadPlans();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started "${newPlan.name}"!'),
        backgroundColor: const Color(0xFF6B8042),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleComplete(QuranPlan plan) async {
    await QuranPlanStore.toggleComplete(plan.id);
    _loadPlans();
  }

  Future<void> _deletePlan(QuranPlan plan) async {
    await QuranPlanStore.deletePlan(plan.id);
    _loadPlans();
  }

  void _openPlanReading(QuranPlan plan) {
    Navigator.of(context).pushNamed(
      RouteNames.quranSurahDetail,
      arguments: SurahRouteArgs(
        surahNo: plan.startSurah,
        surahName: plan.startSurahName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    const borderColor = Color(0xFFD2E3A8);

    final myActivePlans = _plans.where((p) => !p.isCompleted).toList();
    final completedPlans = _plans.where((p) => p.isCompleted).toList();

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 8.h),
                // Top Segmented Tabs: "My Plan", "Search Plan", "Complete Plan"
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      _buildTopTab(
                        index: 0,
                        title: appText.myPlan.isNotEmpty
                            ? appText.myPlan
                            : 'My Plan',
                      ),
                      SizedBox(width: 8.w),
                      _buildTopTab(
                        index: 1,
                        title: appText.searchPlan.isNotEmpty
                            ? appText.searchPlan
                            : 'Search Plan',
                      ),
                      SizedBox(width: 8.w),
                      _buildTopTab(
                        index: 2,
                        title: appText.completePlan.isNotEmpty
                            ? appText.completePlan
                            : 'Complete Plan',
                      ),
                    ],
                  ),
                ),

                // Search Bar when in Search Plan tab
                if (_tab == 1) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search plan...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7A8D49),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8EF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(
                            color: Color(0xFF9EAA52),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Tab Content Body
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9EAA52),
                          ),
                        )
                      : _tab == 0
                      ? _buildMyPlanTab(myActivePlans)
                      : _tab == 1
                      ? _buildSearchPlanTab()
                      : _buildCompletePlanTab(completedPlans),
                ),
              ],
            ),

            // Floating "Create Plan" button on "My Plan" and "Search Plan" tabs
            if (_tab != 2)
              Positioned(
                right: 20.w,
                bottom: 24.h,
                child: FilledButton.icon(
                  onPressed: _openCreatePlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9EAA52),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 13.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  icon: Icon(Icons.edit_note_rounded, size: 20.sp),
                  label: Text(
                    'Create Plan',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTab({required int index, required String title}) {
    final isSelected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4E5A8) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF232D1C)
                : const Color(0xFF4A553E),
          ),
        ),
      ),
    );
  }

  Widget _buildMyPlanTab(List<QuranPlan> activePlans) {
    if (activePlans.isEmpty) {
      return Center(
        child: _PlanEmptyIllustration(
          message: "You haven't created any plan yet !",
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
      itemCount: activePlans.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = activePlans[index];
        return _QuranPlanCard(
          plan: plan,
          buttonText: 'Read',
          onAction: () => _openPlanReading(plan),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF7A8D49)),
            onSelected: (val) {
              if (val == 'complete') {
                _toggleComplete(plan);
              } else if (val == 'delete') {
                _deletePlan(plan);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF6B8042),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Mark Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Plan'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchPlanTab() {
    final query = _searchQuery.trim().toLowerCase();
    final presets = QuranPlanStore.presetSearchPlans.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.days.toString().contains(query);
    }).toList();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
      itemCount: presets.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = presets[index];
        return _QuranPlanCard(
          plan: plan,
          buttonText: 'Get Start',
          onAction: () => _enrollPreset(plan),
        );
      },
    );
  }

  Widget _buildCompletePlanTab(List<QuranPlan> completedPlans) {
    if (completedPlans.isEmpty) {
      return Center(
        child: _PlanEmptyIllustration(
          message: "You haven't completed any plan yet !",
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
      itemCount: completedPlans.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = completedPlans[index];
        return _QuranPlanCard(
          plan: plan,
          statusBadge: 'Completed',
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _deletePlan(plan),
          ),
        );
      },
    );
  }
}

class _QuranPlanCard extends StatelessWidget {
  const _QuranPlanCard({
    required this.plan,
    this.buttonText,
    this.onAction,
    this.statusBadge,
    this.trailing,
  });

  final QuranPlan plan;
  final String? buttonText;
  final VoidCallback? onAction;
  final String? statusBadge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const cardBorderColor = Color(0xFFD2E3A8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.pageColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Row(
        children: [
          // Left: Quran book illustration on pastel squircle
          Container(
            width: 56.r,
            height: 56.r,
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBBE),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Image.asset('assets/images/Quran.png', fit: BoxFit.contain),
          ),
          SizedBox(width: 14.w),

          // Middle: Title and Days
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF282442),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${plan.days} Days',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF8B9875),
                  ),
                ),
              ],
            ),
          ),

          // Right: Action button or status
          if (buttonText != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E5A8),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  buttonText!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF26321F),
                  ),
                ),
              ),
            ),

          if (statusBadge != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EED0),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                statusBadge!,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B8042),
                ),
              ),
            ),

          ?trailing,
        ],
      ),
    );
  }
}

/// Custom Empty state illustration matching the user's design screenshots
class _PlanEmptyIllustration extends StatelessWidget {
  const _PlanEmptyIllustration({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Folded paper sheet with ? and radiating lines
        SizedBox(
          width: 140.w,
          height: 130.h,
          child: CustomPaint(painter: _EmptyDocumentPainter()),
        ),
        SizedBox(height: 16.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF888888),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EmptyDocumentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paperPaint = Paint()
      ..color = const Color(0xFFD4E5A8)
      ..style = PaintingStyle.fill;

    final foldPaint = Paint()
      ..color = const Color(0xFF869E4C)
      ..style = PaintingStyle.fill;

    final rayPaint = Paint()
      ..color = const Color(0xFF768943)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw radiating lines on top left
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.22),
      Offset(size.width * 0.16, size.height * 0.13),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.29),
      Offset(size.width * 0.17, size.height * 0.27),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.35),
      Offset(size.width * 0.17, size.height * 0.39),
      rayPaint,
    );

    // Draw document sheet with top right corner folded
    final docLeft = size.width * 0.38;
    final docTop = size.height * 0.18;
    final docWidth = size.width * 0.44;
    final docHeight = size.height * 0.65;
    final foldSize = 14.0;

    final docPath = Path()
      ..moveTo(docLeft, docTop)
      ..lineTo(docLeft + docWidth - foldSize, docTop)
      ..lineTo(docLeft + docWidth, docTop + foldSize)
      ..lineTo(docLeft + docWidth, docTop + docHeight - 8)
      ..quadraticBezierTo(
        docLeft + docWidth,
        docTop + docHeight,
        docLeft + docWidth - 8,
        docTop + docHeight,
      )
      ..lineTo(docLeft + 8, docTop + docHeight)
      ..quadraticBezierTo(
        docLeft,
        docTop + docHeight,
        docLeft,
        docTop + docHeight - 8,
      )
      ..close();

    canvas.drawPath(docPath, paperPaint);

    // Fold triangle on top-right
    final foldPath = Path()
      ..moveTo(docLeft + docWidth - foldSize, docTop)
      ..lineTo(docLeft + docWidth, docTop + foldSize)
      ..lineTo(docLeft + docWidth - foldSize, docTop + foldSize)
      ..close();
    canvas.drawPath(foldPath, foldPaint);

    // Bottom dark curved accent
    final bottomAccent = Path()
      ..moveTo(docLeft, docTop + docHeight - 4)
      ..lineTo(docLeft + docWidth, docTop + docHeight - 4)
      ..lineTo(docLeft + docWidth - 4, docTop + docHeight)
      ..lineTo(docLeft + 4, docTop + docHeight)
      ..close();
    canvas.drawPath(bottomAccent, foldPaint);

    // Circle badge with question mark ? on the left of paper
    final badgeCenter = Offset(size.width * 0.35, size.height * 0.36);
    final badgeRadius = 18.0;

    final badgePaint = Paint()
      ..color = const Color(0xFFD4E5A8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Color(0xFF6B8042),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      badgeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
