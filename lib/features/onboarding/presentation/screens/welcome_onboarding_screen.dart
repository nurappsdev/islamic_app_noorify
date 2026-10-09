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
  // The welcome journey intentionally introduces the product in English. Once
  // the visitor uses the toggle, their choice is also handed to LanguageBloc
  // and is saved for the rest of the app.
  AppLanguage _onboardingLanguage = AppLanguage.english;
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
    final next = _onboardingLanguage == AppLanguage.bangla
        ? AppLanguage.english
        : AppLanguage.bangla;
    setState(() => _onboardingLanguage = next);
    context.read<LanguageBloc>().add(UpdateLanguage(next));
  }

  @override
  Widget build(BuildContext context) {
    final language = _onboardingLanguage;
    final isLastPage = _pageIndex == _onboardingPages.length - 1;

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
        style: TextStyle(
          fontSize: 14.sp,
          fontStyle: FontStyle.italic,
          fontFamily: 'Times New Roman',
        ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 0),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Flexible(
            flex: 11,
            child: Image.asset(
              page.assetPath,
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
              fontFamily: bangla ? null : 'Times New Roman',
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
    required this.titleEn,
    required this.bodyEn,
    required this.titleBn,
    required this.bodyBn,
  });

  final String assetPath;
  final String titleEn;
  final String bodyEn;
  final String titleBn;
  final String bodyBn;
}

const _onboardingPages = [
  _OnboardingPageData(
    assetPath: 'assets/onboard/salatImg.png',
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
