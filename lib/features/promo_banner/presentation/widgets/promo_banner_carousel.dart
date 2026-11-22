import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/repositories/promo_banner_repository.dart';
import 'package:tuhfatul_muslim/features/promo_banner/presentation/promo_banner_navigation.dart';
import 'package:tuhfatul_muslim/features/promo_banner/promo_banner_dependencies.dart';

/// The Home screen's promo slot, filled from `GET /promo-banners/active`.
///
/// It is the whole section, including its own absence: with no banners —
/// before the first answer, when the admin has deactivated them all, or when
/// the request failed and nothing was ever cached — it occupies no height at
/// all, so the cards above and below simply sit together.
///
/// One banner is a still card with no dots. Two or more advance on their own
/// every [autoPlayInterval], pause while a finger is down, and show the next
/// banner's edge so it is visible that the slot can be swiped.
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({
    super.key,
    this.repository,
    this.height,
    this.padding,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.resumeDelay = const Duration(seconds: 3),
  });

  /// Injectable for tests; production uses the feature composition root.
  final PromoBannerRepository? repository;

  /// Defaults to the design's 150dp.
  final double? height;

  /// Space kept around the slot, applied only when there is a banner to
  /// draw. It belongs to the widget rather than to the caller precisely so
  /// that an empty slot leaves no gap between the cards it sits between.
  final EdgeInsetsGeometry? padding;

  final Duration autoPlayInterval;

  /// How long after the finger lifts before auto-play resumes.
  final Duration resumeDelay;

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  /// Leaves the next banner's edge showing, which is what tells a reader the
  /// slot scrolls at all.
  static const _viewportFraction = 0.93;

  late final PromoBannerRepository _repository =
      widget.repository ?? promoBannerRepository;
  final _controller = PageController(viewportFraction: _viewportFraction);

  List<PromoBanner> _banners = const [];
  int _index = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getActiveBanners();
    if (!mounted) return;
    result.fold(
      // Nothing to show and nothing ever cached: stay collapsed and silent.
      // No dialog, no empty box — a promo is not worth an error state.
      (_) {},
      (banners) {
        setState(() {
          _banners = banners;
          _index = _index.clamp(0, banners.isEmpty ? 0 : banners.length - 1);
        });
        _restartAutoPlay();
      },
    );
  }

  void _restartAutoPlay() {
    _autoTimer?.cancel();
    if (_banners.length < 2) return;
    _autoTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_controller.hasClients || _banners.length < 2) return;
      _controller.animateToPage(
        (_index + 1) % _banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoPlay() => _autoTimer?.cancel();

  void _resumeAutoPlayLater() {
    _autoTimer?.cancel();
    if (_banners.length < 2) return;
    _autoTimer = Timer(widget.resumeDelay, _restartAutoPlay);
  }

  Future<void> _open(PromoBanner banner) =>
      openPromoBanner(context, banner, repository: _repository);

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    final height = widget.height ?? 150.h;
    return Padding(
      padding: widget.padding ?? EdgeInsets.only(bottom: 16.h),
      child: _banners.length == 1
          ? SizedBox(
              height: height,
              child: _PromoBannerCard(banner: _banners.first, onTap: _open),
            )
          : _slider(context, height),
    );
  }

  /// Two or more banners: a swipeable, self-advancing strip under its dots.
  Widget _slider(BuildContext context, double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _pauseAutoPlay(),
            onPointerUp: (_) => _resumeAutoPlayLater(),
            onPointerCancel: (_) => _resumeAutoPlayLater(),
            child: ScrollConfiguration(
              behavior: const _MouseDragBehavior(),
              child: PageView.builder(
                controller: _controller,
                // The first banner starts flush with the cards above it
                // rather than inset by half the peek.
                padEnds: false,
                itemCount: _banners.length,
                onPageChanged: (page) => setState(() => _index = page),
                itemBuilder: (context, page) => Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: _PromoBannerCard(banner: _banners[page], onTap: _open),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        SmoothPageIndicator(
          controller: _controller,
          count: _banners.length,
          effect: ExpandingDotsEffect(
            activeDotColor: context.inkColor(const Color(0xFFA1AD59)),
            dotColor: context.lineColor(const Color(0xFFDCE8B8)),
            dotHeight: 7.r,
            dotWidth: 7.r,
            expansionFactor: 3,
            spacing: 5.w,
            radius: 10.r,
          ),
        ),
      ],
    );
  }
}

/// One banner: the picture is the card. Only a banner that leads somewhere
/// takes a tap.
class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({required this.banner, required this.onTap});

  final PromoBanner banner;
  final Future<void> Function(PromoBanner banner) onTap;

  @override
  Widget build(BuildContext context) {
    final tappable = promoBannerIsTappable(banner);
    final radius = BorderRadius.circular(18.r);
    return Semantics(
      label: banner.title.isEmpty ? null : banner.title,
      button: tappable,
      image: true,
      child: Material(
        color: context.surfaceColor(Colors.white),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tappable ? () => onTap(banner) : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: context.lineColor(const Color(0xFFE6E9DF)),
              ),
            ),
            child: Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // A broken image must not leave a bare white card: the title
              // the admin wrote says what the banner was for.
              errorBuilder: (context, _, _) => _BannerFallback(banner: banner),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    padding: EdgeInsets.symmetric(horizontal: 18.w),
    color: context.surfaceColor(const Color(0xFFF3F6E9)),
    child: Text(
      banner.title,
      maxLines: 2,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.textInkColor(const Color(0xFF5E6B3A)),
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Lets a mouse drag the carousel on the browser, where Flutter otherwise
/// only accepts touch and stylus drags.
class _MouseDragBehavior extends MaterialScrollBehavior {
  const _MouseDragBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    if (kIsWeb) PointerDeviceKind.mouse,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
