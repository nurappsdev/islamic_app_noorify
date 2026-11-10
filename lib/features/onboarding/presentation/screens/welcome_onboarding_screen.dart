import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/features/onboarding/data/onboarding_preference.dart';
import 'package:tuhfatul_muslim/features/splash/utils/post_splash_route.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  State<WelcomeOnboardingScreen> createState() =>
      _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  final PageController _pageController = PageController();
  var _pageIndex = 0;
  var _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_pageIndex == _onboardingPages.length - 1) {
      await _complete();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    await OnboardingPreference.markCompleted();
    if (!mounted) return;
    final destination = await resolvePostSplashRoute();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(destination, (route) => false);
  }

  void _toggleLanguage() {
    final currentLanguage = context.read<LanguageBloc>().state.language;
    final next = currentLanguage == AppLanguage.bangla
        ? AppLanguage.english
        : AppLanguage.bangla;
    context.read<LanguageBloc>().add(UpdateLanguage(next));
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageBloc>().state.language;
    final isLastPage = _pageIndex == _onboardingPages.length - 1;

    if (kIsWeb) {
      return _WebWelcomeOnboardingLayout(
        controller: _pageController,
        pageIndex: _pageIndex,
        language: language,
        isLastPage: isLastPage,
        isCompleting: _isCompleting,
        onLanguageToggle: _toggleLanguage,
        onPageChanged: (index) => setState(() => _pageIndex = index),
        onNext: _next,
        onSkip: _complete,
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDCE8B8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 12.w, 0),
                child: Row(
                  children: [
                    if (_pageIndex == 0)
                      _LanguageToggle(
                        language: language,
                        onTap: _toggleLanguage,
                      ),
                    const Spacer(),
                    _SkipButton(
                      language: language,
                      onPressed: _isCompleting ? null : _complete,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onboardingPages.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final item = _onboardingPages[index];
                    return _OnboardingPage(page: item, language: language);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                child: Column(
                  children: [
                    _PageDots(currentIndex: _pageIndex),
                    SizedBox(height: 18.h),
                    SizedBox(
                      width: isLastPage ? 174.w : 128.w,
                      height: 44.h,
                      child: ElevatedButton(
                        onPressed: _isCompleting ? null : _next,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF8D9D48),
                          disabledBackgroundColor: const Color(0xFF8D9D48),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                        ),
                        child: Text(
                          isLastPage
                              ? language == AppLanguage.bangla
                                    ? 'শুরু করুন'
                                    : 'Get Started'
                              : language == AppLanguage.bangla
                              ? 'পরবর্তী'
                              : 'Next',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width browser onboarding. It keeps the mobile flow and its content,
/// but gives larger screens a two-column story layout rather than scaling the
/// phone composition across the entire viewport.
class _WebWelcomeOnboardingLayout extends StatelessWidget {
  const _WebWelcomeOnboardingLayout({
    required this.controller,
    required this.pageIndex,
    required this.language,
    required this.isLastPage,
    required this.isCompleting,
    required this.onLanguageToggle,
    required this.onPageChanged,
    required this.onNext,
    required this.onSkip,
  });

  final PageController controller;
  final int pageIndex;
  final AppLanguage language;
  final bool isLastPage;
  final bool isCompleting;
  final VoidCallback onLanguageToggle;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onNext;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFEAF1D2), Color(0xFFD7E6AC)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 1280 ? 64.0 : 24.0;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      16,
                      horizontal,
                      28,
                    ),
                    child: Column(
                      children: [
                        _WebOnboardingHeader(
                          pageIndex: pageIndex,
                          language: language,
                          isCompleting: isCompleting,
                          onLanguageToggle: onLanguageToggle,
                          onSkip: onSkip,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView.builder(
                            controller: controller,
                            itemCount: _onboardingPages.length,
                            onPageChanged: onPageChanged,
                            itemBuilder: (context, index) => _WebOnboardingPage(
                              page: _onboardingPages[index],
                              language: language,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _WebPageDots(currentIndex: pageIndex),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: isLastPage ? 196 : 146,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isCompleting ? null : onNext,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF718338),
                              disabledBackgroundColor: const Color(0xFF718338),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              isLastPage
                                  ? language == AppLanguage.bangla
                                        ? 'শুরু করুন'
                                        : 'Get Started'
                                  : language == AppLanguage.bangla
                                  ? 'পরবর্তী'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WebOnboardingHeader extends StatelessWidget {
  const _WebOnboardingHeader({
    required this.pageIndex,
    required this.language,
    required this.isCompleting,
    required this.onLanguageToggle,
    required this.onSkip,
  });

  final int pageIndex;
  final AppLanguage language;
  final bool isCompleting;
  final VoidCallback onLanguageToggle;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showProgress = constraints.maxWidth >= 360;
        return Row(
          children: [
            if (pageIndex == 0)
              _WebLanguageToggle(language: language, onTap: onLanguageToggle)
            else
              const SizedBox(width: 1),
            const Spacer(),
            if (showProgress) ...[
              Text(
                '${pageIndex + 1} / ${_onboardingPages.length}',
                style: const TextStyle(
                  color: Color(0xFF66723D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 18),
            ],
            OutlinedButton(
              onPressed: isCompleting ? null : onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF65713F),
                side: const BorderSide(color: Color(0xFFB8CB7B)),
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                language == AppLanguage.bangla ? 'এড়িয়ে যান' : 'Skip',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WebLanguageToggle extends StatelessWidget {
  const _WebLanguageToggle({required this.language, required this.onTap});

  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate_rounded,
                size: 18,
                color: Color(0xFF65713F),
              ),
              const SizedBox(width: 6),
              Text(
                language == AppLanguage.bangla ? 'বাংলা' : 'English',
                style: const TextStyle(
                  color: Color(0xFF4D5831),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebOnboardingPage extends StatelessWidget {
  const _WebOnboardingPage({required this.page, required this.language});

  final _OnboardingPageData page;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final bangla = language == AppLanguage.bangla;
    final imagePath = page.assetPathFor(language);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final title = Text(
          bangla ? page.titleBn : page.titleEn,
          key: ValueKey('onboarding-title-${page.assetPath}-$bangla'),
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: const Color(0xFF15190E),
            fontSize: compact ? 27 : 34,
            fontWeight: FontWeight.w700,
            height: 1.16,
          ),
        );
        final body = Text(
          bangla ? page.bodyBn : page.bodyEn,
          key: ValueKey('onboarding-body-${page.assetPath}-$bangla'),
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: const Color(0xFF313B20),
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            height: 1.48,
          ),
        );
        final image = Image.asset(
          imagePath,
          key: ValueKey('onboarding-image-$imagePath'),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );

        if (compact) {
          final imageHeight = (constraints.maxHeight * .48).clamp(180.0, 380.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              key: const ValueKey('web-onboarding-compact-layout'),
              children: [
                SizedBox(height: imageHeight, child: image),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: title,
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: body,
                ),
              ],
            ),
          );
        }

        return Row(
          key: const ValueKey('web-onboarding-wide-layout'),
          children: [
            Expanded(
              flex: 6,
              child: Padding(padding: const EdgeInsets.all(24), child: image),
            ),
            const SizedBox(width: 54),
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 20), body],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WebPageDots extends StatelessWidget {
  const _WebPageDots({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_onboardingPages.length, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 28 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF718338) : const Color(0x80FFFFFF),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.language, required this.onTap});

  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = language == AppLanguage.bangla ? 'বাংলা' : 'English';

    return Semantics(
      button: true,
      label: 'Change language',
      child: Material(
        color: Colors.white.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 17.sp,
                  color: const Color(0xFF65713F),
                ),
                SizedBox(width: 5.w),
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF4D5831),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.language, required this.onPressed});

  final AppLanguage language;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF859153),
        side: const BorderSide(color: Color(0xFFCDDDA2)),
        minimumSize: Size(72.w, 36.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        language == AppLanguage.bangla ? 'এড়িয়ে যান' : 'Skip',
        style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page, required this.language});

  final _OnboardingPageData page;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final bangla = language == AppLanguage.bangla;
    final imagePath = page.assetPathFor(language);
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 0),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Flexible(
            flex: 11,
            child: Image.asset(
              imagePath,
              key: ValueKey('onboarding-image-$imagePath'),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const Spacer(flex: 3),
          Text(
            bangla ? page.titleBn : page.titleEn,
            key: ValueKey('onboarding-title-${page.assetPath}-$bangla'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF15190E),
              fontSize: bangla ? 23.sp : 24.sp,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            bangla ? page.bodyBn : page.bodyEn,
            key: ValueKey('onboarding-body-${page.assetPath}-$bangla'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF1B2012),
              fontSize: bangla ? 15.sp : 16.sp,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.38,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_onboardingPages.length, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 25.w : 10.w,
          height: 10.h,
          margin: EdgeInsets.symmetric(horizontal: 2.5.w),
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0x99FFFFFF),
            borderRadius: BorderRadius.circular(20.r),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.assetPath,
    this.assetPathBn,
    required this.titleEn,
    required this.bodyEn,
    required this.titleBn,
    required this.bodyBn,
  });

  final String assetPath;
  final String? assetPathBn;
  final String titleEn;
  final String bodyEn;
  final String titleBn;
  final String bodyBn;

  String assetPathFor(AppLanguage language) =>
      language == AppLanguage.bangla ? assetPathBn ?? assetPath : assetPath;
}

const _onboardingPages = [
  _OnboardingPageData(
    assetPath: 'assets/onboard/salatImg.png',
    assetPathBn: 'assets/onboard/salatBangla.png',
    titleEn: 'Make Every Good Deed Count',
    bodyEn:
        'Track your daily Amol, build meaningful habits, and stay consistent in your worship.',
    titleBn: 'প্রতিটি ভালো আমলকে মূল্যবান করুন',
    bodyBn:
        'প্রতিদিনের আমল ট্র্যাক করুন, অর্থবহ অভ্যাস গড়ে তুলুন এবং ইবাদতে ধারাবাহিক থাকুন।',
  ),
  _OnboardingPageData(
    assetPath: 'assets/onboard/onBoard2.png',
    titleEn: 'Never Miss a Moment of Remembrance',
    bodyEn:
        'Set gentle reminders for your daily worship, Zikr, and spiritual routine.',
    titleBn: 'স্মরণের একটি মুহূর্তও হারাবেন না',
    bodyBn:
        'দৈনন্দিন ইবাদত, জিকির ও আত্মিক রুটিনের জন্য কোমল স্মরণ করিয়ে দেওয়ার ব্যবস্থা রাখুন।',
  ),
  _OnboardingPageData(
    assetPath: 'assets/onboard/onBoard3.png',
    titleEn: 'Connect with the Words of Allah',
    bodyEn:
        'Read, reflect, and make the Holy Quran a meaningful part of your everyday life.',
    titleBn: 'আল্লাহর বাণীর সঙ্গে যুক্ত থাকুন',
    bodyBn:
        'কুরআন পড়ুন, ভাবুন এবং পবিত্র কুরআনকে আপনার প্রতিদিনের জীবনের অর্থবহ অংশ করুন।',
  ),
  _OnboardingPageData(
    assetPath: 'assets/onboard/onBoard4.png',
    assetPathBn: 'assets/onboard/onBoard4Bangla.png',
    titleEn: 'Keep Your Heart Close to Allah',
    bodyEn:
        'Make daily remembrance easier and bring more peace and mindfulness into your routine.',
    titleBn: 'হৃদয়কে আল্লাহর নিকটে রাখুন',
    bodyBn:
        'প্রতিদিনের স্মরণ সহজ করুন এবং আপনার রুটিনে আরও শান্তি ও সচেতনতা নিয়ে আসুন।',
  ),
  _OnboardingPageData(
    assetPath: 'assets/onboard/onBoard5.png',
    titleEn: 'Let Every Prayer Begin with the Heart',
    bodyEn:
        'Explore meaningful supplications and make Dua a beautiful part of your daily life.',
    titleBn: 'প্রতিটি দোয়া হৃদয় থেকে শুরু হোক',
    bodyBn:
        'অর্থবহ দোয়া আবিষ্কার করুন এবং দোয়াকে আপনার দৈনন্দিন জীবনের সুন্দর অংশ করে তুলুন।',
  ),
  _OnboardingPageData(
    assetPath: 'assets/onboard/onBoard6.png',
    titleEn: 'Learn from the Teachings of the Prophet',
    bodyEn:
        'Discover authentic prophetic teachings and find guidance for everyday life.',
    titleBn: 'নবীর শিক্ষায় শিখুন',
    bodyBn:
        'বিশুদ্ধ নববী শিক্ষা জানুন এবং প্রতিদিনের জীবনের জন্য পথনির্দেশ খুঁজে নিন।',
  ),
];
