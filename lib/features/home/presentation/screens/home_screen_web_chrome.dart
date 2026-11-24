// FLUTTER WEB ONLY - the Android and iOS builds never render anything in this
// file.
//
// The browser frame drawn around the dashboard content: top bar, notification
// and profile menus, left sidebar, footer, and the decorative lattice
// background. A phone build never reaches any of it.
//
// Used by `home_screen_web.dart`.

part of 'home_screen.dart';

/// Desktop footer that carries the same pale-mint surface as the Home page.
/// Its mosque skyline is a local asset so it stays crisp and local.
class _WebHomeFooter extends StatelessWidget {
  const _WebHomeFooter();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;
        final sidePadding = wide ? 34.0 : 24.0;
        final availableWidth = constraints.maxWidth - sidePadding * 2;
        final columnWidth = wide ? (availableWidth - 72) / 4 : 255.0;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IgnorePointer(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Reversing the footer gradient keeps the skyline legible
                    // while using the exact same two requested colours.
                    colors: [Color(0xFFA8C98A), Color(0xFF386C35)],
                  ).createShader(bounds),
                  child: Image.asset(
                    'assets/mosqe.png',
                    width: double.infinity,
                    // Keep the artwork's natural ratio so a wide browser never
                    // crops the domes and minarets at the top or bottom.
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF386C35),
                padding: EdgeInsets.fromLTRB(sidePadding, 30, sidePadding, 30),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 36,
                  spacing: 24,
                  children: [
                    SizedBox(
                      width: columnWidth,
                      child: const _WebFooterBrand(),
                    ),
                    SizedBox(
                      width: columnWidth,
                      child: _WebFooterColumn(
                        title: 'Important Features',
                        children: [
                          _WebFooterLink(
                            icon: Icons.menu_book_rounded,
                            label: appText.categoryQuran,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.quran),
                          ),
                          _WebFooterLink(
                            icon: Icons.local_library_rounded,
                            label: appText.categoryHadith,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.hadith),
                          ),
                          _WebFooterLink(
                            icon: Icons.access_time_rounded,
                            label: appText.prayerTimesTitle,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.prayerTimes),
                          ),
                          _WebFooterLink(
                            icon: Icons.fact_check_rounded,
                            label: appText.todaysAmolTrack,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AmolTrackingScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: columnWidth,
                      child: _WebFooterColumn(
                        title: 'Other Features',
                        children: [
                          _WebFooterLink(
                            icon: Icons.volunteer_activism_rounded,
                            label: appText.featureDua,
                            onTap: () =>
                                Navigator.of(context).pushNamed(RouteNames.dua),
                          ),
                          _WebFooterLink(
                            icon: Icons.nightlight_round,
                            label: appText.featureDijpr,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.zikr),
                          ),
                          _WebFooterLink(
                            icon: Icons.workspace_premium_rounded,
                            label: appText.featureAsmaUlHusna,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.asma),
                          ),
                          _WebFooterLink(
                            icon: Icons.quiz_rounded,
                            label: appText.featureQuizAndLearn,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.winQuiz),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: columnWidth,
                      child: const _WebFooterContact(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WebFooterBrand extends StatelessWidget {
  const _WebFooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset('assets/appLogo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 18),
        const Text(
          'A complete Islamic companion for every Muslim. Read, learn, and track your daily Ibadah in one place.',
          style: TextStyle(color: _webFooterMutedInk, height: 1.55),
        ),
        const SizedBox(height: 20),
        const _WebFooterStoreBadge(),
      ],
    );
  }
}

class _WebFooterColumn extends StatelessWidget {
  const _WebFooterColumn({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _webFooterInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 54, height: 3, color: const Color(0xFF75B56D)),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _WebFooterLink extends StatelessWidget {
  const _WebFooterLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8ECD9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _webFooterAccent, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _webFooterInk, fontSize: 16),
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

class _WebFooterContact extends StatelessWidget {
  const _WebFooterContact();

  @override
  Widget build(BuildContext context) {
    return const _WebFooterColumn(
      title: 'Contact',
      children: [
        _WebFooterInfo(icon: Icons.location_on_rounded, label: 'Bangladesh'),
        _WebFooterInfo(icon: Icons.phone_rounded, label: '+880 1601-761564'),
        _WebFooterInfo(
          icon: Icons.mail_rounded,
          label: 'support@tuhfatulmuslim.org',
        ),
        SizedBox(height: 8),
        _WebFooterSocials(),
      ],
    );
  }
}

class _WebFooterInfo extends StatelessWidget {
  const _WebFooterInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _webFooterAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _webFooterMutedInk, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebFooterSocials extends StatelessWidget {
  const _WebFooterSocials();

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.facebook, Icons.play_circle_fill, Icons.send_rounded];
    return Row(
      children: [
        for (final icon in icons)
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFA8D3AD)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _webFooterInk, size: 20),
          ),
      ],
    );
  }
}

class _WebFooterStoreBadge extends StatelessWidget {
  const _WebFooterStoreBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _openWebPlayStore,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Image(
                  image: AssetImage('assets/googleIcon.png'),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GET IT ON',
                    style: TextStyle(color: Color(0xFFDCEBD1), fontSize: 9),
                  ),
                  Text(
                    'Google Play',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pale-mint Web surface with a quiet, connected star lattice inspired by
/// the visual mood of the supplied reference (without reusing its image).
class _WebHomeBackground extends StatelessWidget {
  const _WebHomeBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF172218), Color(0xFF101912)]
              // A clean pale-mint base sampled from the colour mood of
              // devImg/img_9.png.
              : const [Color(0xFFF1FAF2), Color(0xFFE8F6EB)],
        ),
      ),
      child: CustomPaint(
        painter: _WebIslamicLatticePainter(
          color: isDark
              ? const Color(0xFFB9DDBB).withValues(alpha: .08)
              : const Color(0xFFE0F1E3).withValues(alpha: .82),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WebIslamicLatticePainter extends CustomPainter {
  const _WebIslamicLatticePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalSpacing = 112.0;
    const verticalSpacing = 96.0;
    const outerRadius = 29.0;
    const innerRadius = 15.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05;

    // Each eight-point star shares its cardinal points with its neighbours,
    // giving the background the soft connected-lattice feeling of img_9.
    for (
      var y = -verticalSpacing / 2;
      y < size.height + verticalSpacing;
      y += verticalSpacing
    ) {
      for (
        var x = -horizontalSpacing / 2;
        x < size.width + horizontalSpacing;
        x += horizontalSpacing
      ) {
        final center = Offset(x, y);
        final star = Path();
        for (var point = 0; point < 16; point++) {
          final radius = point.isEven ? outerRadius : innerRadius;
          final angle = -math.pi / 2 + point * math.pi / 8;
          final offset = Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          );
          if (point == 0) {
            star.moveTo(offset.dx, offset.dy);
          } else {
            star.lineTo(offset.dx, offset.dy);
          }
        }
        star.close();
        canvas.drawPath(star, paint);
        canvas.drawCircle(center, 8, paint);

        // These short links make adjacent stars read as one continuous motif.
        canvas.drawLine(
          Offset(center.dx + outerRadius, center.dy),
          Offset(center.dx + horizontalSpacing - outerRadius, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy + outerRadius),
          Offset(center.dx, center.dy + verticalSpacing - outerRadius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WebIslamicLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Desktop-only navigation matching the reference's persistent left rail.
/// It uses the app's existing routes; Android/iOS keep their bottom bar.
const _webHeaderInk = Color(0xFF26321B);
const _webHeaderMutedInk = Color(0xB326321B);

class _WebHomeTopBar extends StatelessWidget {
  const _WebHomeTopBar();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Material(
      // Use the same soft olive surface as the Amol Tracker card.
      color: context.surfaceColor(context.appPalette.tint),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .08),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 78,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final showReminder = constraints.maxWidth >= 1120;
              final showBrandName = constraints.maxWidth >= 620;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 620 ? 12 : 28,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/appLogo.png',
                      width: 46,
                      height: 46,
                      color: _webHeaderInk,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    if (showBrandName) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'Tuhfatul Muslim',
                        style: TextStyle(
                          color: _webHeaderInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 28),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _WebTopNavButton(
                              label: appText.home,
                              selected: true,
                            ),
                            PopupMenuButton<String>(
                              tooltip: appText.categoryQuran,
                              offset: const Offset(0, 46),
                              onSelected: (tab) =>
                                  Navigator.of(context).pushReplacementNamed(
                                    RouteNames.quranSurahs,
                                    arguments: tab,
                                  ),
                              itemBuilder: (context) => [
                                _quranMenuItem(
                                  'home',
                                  appText.categoryQuran,
                                  Icons.menu_book_outlined,
                                ),
                                _quranMenuItem(
                                  'learn',
                                  appText.learn.isEmpty
                                      ? 'Learn'
                                      : appText.learn,
                                  Icons.school_outlined,
                                ),
                                _quranMenuItem(
                                  'saved',
                                  appText.saved.isEmpty
                                      ? 'Saved'
                                      : appText.saved,
                                  Icons.bookmark_border_rounded,
                                ),
                                _quranMenuItem(
                                  'plan',
                                  appText.planner.isEmpty
                                      ? 'Plan'
                                      : appText.planner,
                                  Icons.assignment_turned_in_outlined,
                                ),
                                _quranMenuItem(
                                  'dashboard',
                                  appText.dashboard.isEmpty
                                      ? 'Dashboard'
                                      : appText.dashboard,
                                  Icons.grid_view_outlined,
                                ),
                              ],
                              child: _WebTopNavButton(
                                label: appText.categoryQuran,
                                trailing: Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                            _WebTopNavButton(
                              label: appText.categoryHadith,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.hadith),
                            ),
                            _WebTopNavButton(
                              label: appText.featureDua,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.dua),
                            ),
                            _WebTopNavButton(
                              label: appText.featureDijpr,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.zikr),
                            ),
                            _WebTopNavButton(
                              label: appText.todaysAmolTrack,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AmolTrackingScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showReminder) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 215,
                        child: HomeHeaderRotatingSubtitle(
                          style: TextStyle(
                            color: _webHeaderInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          reminderColor: _webHeaderInk,
                        ),
                      ),
                    ],
                    _WebHeaderNotifications(label: appText.notifications),
                    const SizedBox(width: 8),
                    _WebHeaderProfile(
                      fallbackName: appText.competitorName,
                      showDetails: !compact,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _quranMenuItem(
    String value,
    String label,
    IconData icon,
  ) => PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF316648)),
        const SizedBox(width: 10),
        Text(label),
      ],
    ),
  );
}

class _WebHeaderNotifications extends StatelessWidget {
  const _WebHeaderNotifications({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: unreadNotificationCountNotifier,
      builder: (context, unreadCount, _) {
        final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: label,
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.notifications),
              icon: const Icon(Icons.notifications_none_rounded),
              color: _webHeaderInk,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE75A51),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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

class _WebHeaderProfile extends StatelessWidget {
  const _WebHeaderProfile({
    required this.fallbackName,
    required this.showDetails,
  });

  final String fallbackName;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final dashboardName = context.localized(
      context
          .watch<HomeDashboardBloc>()
          .state
          .dashboard
          ?.userSummary
          .localizedFullName,
    );
    final now = bangladeshNow();
    final date = const LocalizedDateFormatter(
      AppLanguage.bangla,
    ).banglaCalendar(now, ordinalDay: true, withSuffix: true);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatarCircle(
                dimension: 40,
                backgroundColor: Colors.white.withValues(alpha: .34),
                placeholderIconColor: _webHeaderInk,
              ),
              if (showDetails) ...[
                const SizedBox(width: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: profileNameNotifier,
                    builder: (context, profileName, _) {
                      final name = (profileName ?? '').trim().isNotEmpty
                          ? profileName!.trim()
                          : (dashboardName.isEmpty
                                ? fallbackName
                                : dashboardName);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _webHeaderInk,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _webHeaderMutedInk,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WebTopNavButton extends StatelessWidget {
  const _WebTopNavButton({
    required this.label,
    this.onTap,
    this.selected = false,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    const foreground = _webHeaderInk;
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: .56)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(trailing, size: 18, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Retained as an alternate navigation treatment while the top bar is the
// active Web navigation requested by the current design.
// ignore: unused_element
class _WebHomeSidebar extends StatelessWidget {
  const _WebHomeSidebar();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final destinations = [
      _WebSidebarDestination(
        icon: Icons.home_rounded,
        label: appText.home,
        selected: true,
        onTap: () {},
      ),
      _WebSidebarDestination(
        icon: Icons.menu_book_outlined,
        label: appText.categoryQuran,
        onTap: () =>
            Navigator.of(context).pushReplacementNamed(RouteNames.quranSurahs),
      ),
      _WebSidebarDestination(
        icon: Icons.auto_stories_outlined,
        label: appText.categoryHadith,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.hadith),
      ),
      _WebSidebarDestination(
        icon: Icons.volunteer_activism_outlined,
        label: appText.featureDua,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.dua),
      ),
      _WebSidebarDestination(
        icon: Icons.nightlight_round,
        label: appText.featureDijpr,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.zikr),
      ),
      _WebSidebarDestination(
        icon: Icons.fact_check_outlined,
        label: appText.todaysAmolTrack,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AmolTrackingScreen()),
        ),
      ),
      _WebSidebarDestination(
        icon: Icons.mosque_outlined,
        label: appText.viewPrayerTimes,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.prayerTimes),
      ),
      _WebSidebarDestination(
        icon: Icons.workspace_premium_outlined,
        label: appText.featureAsmaUlHusna,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.asma),
      ),
      _WebSidebarDestination(
        icon: Icons.quiz_outlined,
        label: appText.featureQuizAndLearn,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.winQuiz),
      ),
    ];

    return SizedBox(
      width: 276,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF01442F), Color(0xFF126745)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
            child: Column(
              children: [
                Image.asset('assets/appLogo.png', width: 78, height: 78),
                const SizedBox(height: 10),
                const Text(
                  'Tuhfatul Muslim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 26),
                for (final destination in destinations)
                  _WebSidebarTile(destination: destination),
                const Divider(color: Color(0x99D7E9C1), height: 30),
                _WebSidebarTile(
                  destination: _WebSidebarDestination(
                    icon: Icons.settings_outlined,
                    label: appText.settingsTitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.settings),
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

class _WebSidebarDestination {
  const _WebSidebarDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
}

class _WebSidebarTile extends StatelessWidget {
  const _WebSidebarTile({required this.destination});

  final _WebSidebarDestination destination;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: destination.selected
            ? const Color(0xFFA1AE57)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: destination.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            child: Row(
              children: [
                Icon(destination.icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
