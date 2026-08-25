import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/tafsir/tafsir_bloc.dart';

/// Opens a bottom sheet listing reciters from [reciterBloc], letting the
/// user pick one. Pass the ancestor's [ReciterBloc] explicitly since a
/// bottom sheet is a separate route and doesn't inherit it automatically.
void openReciterPicker(BuildContext context, ReciterBloc reciterBloc) {
  showModalBottomSheet(
    context: context,
    builder: (_) =>
        BlocProvider.value(value: reciterBloc, child: const ReciterPickerSheet()),
  );
}

class ReciterPickerSheet extends StatelessWidget {
  const ReciterPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.selectReciterTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            BlocBuilder<ReciterBloc, ReciterState>(
              builder: (context, state) {
                if (state.isLoading && state.reciters.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColor.primary,
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 360.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.reciters.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: const Color(0xFFE3ECC5)),
                    itemBuilder: (context, index) {
                      final reciter = state.reciters[index];
                      final selected = reciter.id == state.selectedId;
                      return ListTile(
                        title: Text(
                          reciter.name,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColor.primary,
                              )
                            : null,
                        onTap: () {
                          context.read<ReciterBloc>().add(
                            SelectReciter(reciter.id),
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a bottom sheet with the tafsir text for [verseKey], choosing the
/// tafsir resource based on [isBangla].
void openTafsirSheet(BuildContext context, String verseKey, bool isBangla) {
  final resourceId = isBangla
      ? banglaTafsirResourceId
      : englishTafsirResourceId;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          TafsirBloc(tafsirResourceId: resourceId)..add(LoadTafsir(verseKey)),
      child: const TafsirSheet(),
    ),
  );
}

class TafsirSheet extends StatelessWidget {
  const TafsirSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.tafsirTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 420.h),
              child: BlocBuilder<TafsirBloc, TafsirState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                        ),
                      ),
                    );
                  }
                  if (state.hasError) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          appText.quranLoadError,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: Text(
                      state.text,
                      style: TextStyle(fontSize: 13.sp, height: 1.5),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
