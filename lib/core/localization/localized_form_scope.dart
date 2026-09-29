import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Wraps a form so the error messages it is already showing switch language
/// along with the app.
///
/// A validator writes its message when it runs, so an error shown before the
/// language was changed would stay in the old language. When the language
/// changes, every field of [child] that currently shows an error validates
/// again and shows the message in the new language. Fields with no error are
/// left alone: nothing new is flagged.
class LocalizedFormScope extends StatelessWidget {
  const LocalizedFormScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LanguageBloc, LanguageState>(
      listenWhen: (previous, current) => previous.language != current.language,
      listener: (context, _) {
        // After the frame, so the new language is in place everywhere.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) revalidateFieldsShowingErrors(context);
        });
      },
      child: child,
    );
  }
}

/// Validates again each form field under [context] that shows an error.
void revalidateFieldsShowingErrors(BuildContext context) {
  void visit(Element element) {
    if (element is StatefulElement) {
      final state = element.state;
      if (state is FormFieldState && state.hasError) state.validate();
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
}
