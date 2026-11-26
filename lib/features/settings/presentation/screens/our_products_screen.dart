import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/settings/data/datasources/settings_support_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/settings/data/repositories/settings_support_repository_impl.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/product_item.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/get_our_products.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/cubit/our_products_cubit.dart';
import 'package:tuhfatul_muslim/features/settings/presentation/widgets/settings_page_scaffold.dart';

/// Settings -> Our Products: the other apps this team publishes, each with
/// its store links (`GET /settings/our-products`).
class OurProductsScreen extends StatelessWidget {
  const OurProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (_) => OurProductsCubit(
        GetOurProducts(
          SettingsSupportRepositoryImpl(SettingsSupportRemoteDataSourceImpl()),
        ),
      )..load(),
      child: SettingsPageScaffold(
        title: appText.ourProducts,
        child: BlocBuilder<OurProductsCubit, OurProductsState>(
          builder: (context, state) => switch (state.status) {
            OurProductsStatus.loading => const SettingsStateView(
              isLoading: true,
            ),
            OurProductsStatus.failure => SettingsStateView(
              message: state.errorMessage,
              onRetry: () => context.read<OurProductsCubit>().load(),
            ),
            OurProductsStatus.success when state.products.isEmpty =>
              SettingsStateView(message: appText.ourProductsEmpty),
            OurProductsStatus.success => ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                Text(
                  appText.ourProductsSubtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.inkColor(const Color(0xFF6B7551)),
                  ),
                ),
                SizedBox(height: 14.h),
                for (final product in state.products) ...[
                  _ProductCard(product: product),
                  SizedBox(height: 12.h),
                ],
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final tagline = product.tagline;
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductLogo(name: product.name, logoUrl: product.logoUrl),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.inkColor(AppColor.authLogo),
                      ),
                    ),
                    if (tagline != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        tagline,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(const Color(0xFF6B7551)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (product.hasStoreLink) ...[
            SizedBox(height: 14.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: [
                if (product.playStoreUrl?.isNotEmpty ?? false)
                  _StoreButton(
                    label: appText.productPlayStore,
                    icon: Icons.shop_rounded,
                    url: product.playStoreUrl!,
                  ),
                if (product.appStoreUrl?.isNotEmpty ?? false)
                  _StoreButton(
                    label: appText.productAppStore,
                    icon: Icons.apple_rounded,
                    url: product.appStoreUrl!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final dimension = 48.r;
    final trimmed = name.trim();
    final placeholder = Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFDCE7AC)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: context.inkColor(const Color(0xFF7F8F52)),
        ),
      ),
    );
    final url = logoUrl;
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Image.network(
        url,
        width: dimension,
        height: dimension,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;

  Future<void> _open(BuildContext context) async {
    final appText = AppText.readOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) return;
    messenger.showSnackBar(SnackBar(content: Text(appText.linkOpenFailed)));
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: Icon(icon, size: 16.sp),
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.inkColor(AppColor.primary),
        side: const BorderSide(color: AppColor.primary),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }
}
