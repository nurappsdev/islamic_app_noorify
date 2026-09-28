import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/juz_summary.dart';
import '../../domain/surah_summary.dart';
import '../quran_route_args.dart';
import 'quran_design.dart';
import 'quran_modal.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/localization/localization_context.dart';

class QuranFilterSheet extends StatefulWidget {
  const QuranFilterSheet({super.key, required this.initial, this.service});
  final SurahRouteArgs initial;
  final QuranContentService? service;
  @override
  State<QuranFilterSheet> createState() => _QuranFilterSheetState();
}

class _QuranFilterSheetState extends State<QuranFilterSheet> {
  late final _api = widget.service ?? QuranContentService.shared;
  List<SurahSummary> _surahs = [];
  List<JuzSummary> _paras = [];
  SurahSummary? _surah;
  JuzSummary? _para;
  int _ayah = 1;
  String _query = '', _type = '';
  bool _loading = true, _error = false;
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait<Object>([
        _api.loadSurahs(),
        _api.loadParas(),
      ]);
      if (!mounted) return;
      _surahs = [...results[0] as List<SurahSummary>]
        ..sort((a, b) => a.number.compareTo(b.number));
      _paras = [...results[1] as List<JuzSummary>]
        ..sort((a, b) => a.number.compareTo(b.number));
      _surah =
          _surahs
              .where((s) => s.number == widget.initial.surahNo)
              .firstOrNull ??
          _surahs.firstOrNull;
      _para = _paras
          .where((p) => p.number == widget.initial.paraNumber)
          .firstOrNull;
      _ayah = widget.initial.ayahNo.clamp(_first, _last);
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  int get _first => _para != null && _para!.startSurahNo == _surah?.number
      ? _para!.startAyah
      : 1;
  int get _last => _para != null && _para!.endSurahNo == _surah?.number
      ? _para!.endAyah
      : (_surah?.totalAyah ?? 1).clamp(1, 1000);
  bool _inPara(SurahSummary s) =>
      _para == null || _para!.surahs.any((p) => p.number == s.number);
  void _selectSurah(SurahSummary s) => setState(() {
    FocusScope.of(context).unfocus();
    _surah = s;
    _ayah = _first;
  });
  void _selectPara(JuzSummary p) => setState(() {
    _para = p;
    _type = '';
    _query = '';
    _search.clear();
    _surah = _surahs.where((s) => s.number == p.startSurahNo).firstOrNull;
    _ayah = _first;
  });
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) return QuranRetry(onRetry: _load);
    if (_surahs.isEmpty || _paras.isEmpty) {
      return Center(child: Text(AppText.of(context).quranNoFilters));
    }
    final matches = _surahs
        .where(
          (s) =>
              _inPara(s) &&
              (_type.isEmpty ||
                  s.revelationPlace.toLowerCase().startsWith(_type)) &&
              '${s.number} ${s.name} ${s.translation} ${s.nameArabic}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      top: false,
      child: Column(
        children: [
          QuranSheetHeading(AppText.of(context).quranFilterTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(
                  AppText.of(context).tabSurah,
                  style: const TextStyle(fontSize: 19),
                ),
                Wrap(
                  spacing: 5,
                  children: [
                    for (final item in [
                      ('', AppText.of(context).quranAllTypes),
                      ('mec', AppText.of(context).meccan),
                      ('med', AppText.of(context).medinian),
                    ])
                      ChoiceChip(
                        label: Text(
                          item.$1.isEmpty
                              ? item.$2
                              : context.localizedDigits(
                                  '${item.$2} (${_surahs.where((s) => s.revelationPlace.toLowerCase().startsWith(item.$1)).length})',
                                ),
                        ),
                        selected: _type == item.$1,
                        selectedColor: quranBorder,
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: quranBorder),
                        labelStyle: const TextStyle(color: Colors.black87),
                        onSelected: (_) => setState(() => _type = item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppText.of(context).quranJuzParaCarousel,
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                    if (_para != null)
                      TextButton(
                        onPressed: () => setState(() => _para = null),
                        child: Text(AppText.of(context).allLabel),
                      ),
                  ],
                ),
                SizedBox(
                  height: 180,
                  child: _ParaCarousel(
                    paras: _paras,
                    initial: _para?.number,
                    onSelected: _selectPara,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppText.of(context).quranSearchAndSelectSurah,
                  style: const TextStyle(fontSize: 19),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  onChanged: (q) => setState(() => _query = q),
                  decoration: InputDecoration(
                    hintText: AppText.of(context).searchSurah,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: AppText.of(context).clearLabel,
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: quranBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: quranOlive),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: quranBorder),
                    ),
                  ),
                ),
                if (_surah != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      context.localizedDigits(
                        AppText.of(context).quranSelectedSurah.fill({
                          'n': _surah!.number,
                          'name': _surah!.name,
                        }),
                      ),
                      style: const TextStyle(color: quranInk),
                    ),
                  ),
                SizedBox(
                  height: 76,
                  child: matches.isEmpty
                      ? Center(
                          child: Text(AppText.of(context).quranNoSurahsFound),
                        )
                      : ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (_, i) {
                            final s = matches[i];
                            return ListTile(
                              dense: true,
                              selected: _surah?.number == s.number,
                              selectedTileColor: quranPale,
                              selectedColor: quranInk,
                              title: Text(
                                context.localizedDigits(
                                  '${s.number}. ${s.name}',
                                ),
                              ),
                              subtitle: Text(
                                context.localizedDigits(
                                  AppText.of(
                                    context,
                                  ).quranSurahTranslationAyahs.fill({
                                    'translation': s.translation,
                                    'n': s.totalAyah,
                                  }),
                                ),
                              ),
                              trailing: _surah?.number == s.number
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: quranOlive,
                                    )
                                  : null,
                              onTap: () => _selectSurah(s),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppText.of(context).quranSelectAyat,
                  style: const TextStyle(fontSize: 19),
                ),
                QuranAyahWheel(
                  key: ValueKey('${_surah?.number}:${_para?.number}'),
                  first: _first,
                  last: _last,
                  initial: _ayah,
                  onChanged: (n) => setState(() => _ayah = n),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 54),
                    ),
                    child: Text(AppText.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _surah == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            SurahRouteArgs(
                              surahNo: _surah!.number,
                              surahName: _surah!.name,
                              ayahNo: _ayah,
                              paraNumber: _para?.number,
                              paraStartAyah: _para == null ? null : _first,
                              endAyah: _para == null ? null : _last,
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: quranOlive,
                      minimumSize: const Size(0, 54),
                    ),
                    child: Text(AppText.of(context).commonApply),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParaCarousel extends StatefulWidget {
  const _ParaCarousel({
    required this.paras,
    required this.initial,
    required this.onSelected,
  });
  final List<JuzSummary> paras;
  final int? initial;
  final ValueChanged<JuzSummary> onSelected;
  @override
  State<_ParaCarousel> createState() => _ParaCarouselState();
}

class _ParaCarouselState extends State<_ParaCarousel> {
  late final _controller = PageController(
    viewportFraction: .62,
    initialPage: widget.paras
        .indexWhere((p) => p.number == widget.initial)
        .clamp(0, widget.paras.length - 1),
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: widget.paras.length,
    onPageChanged: (i) => widget.onSelected(widget.paras[i]),
    itemBuilder: (_, i) {
      final p = widget.paras[i];
      return InkWell(
        onTap: () => widget.onSelected(p),
        child: Container(
          margin: const EdgeInsets.all(7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: quranBorder),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: quranPale,
                child: Text(
                  context.localizedDigits('${p.number}'),
                  style: const TextStyle(color: quranOlive, fontSize: 20),
                ),
              ),
              Flexible(
                child: Text(
                  p.surahs.map((s) => s.name).join(' & '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: quranOlive, fontSize: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: quranOlive,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.localizedDigits(
                      '${p.startSurahNo}:${p.startAyah} – ${p.endSurahNo}:${p.endAyah}',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class QuranAyahWheel extends StatefulWidget {
  const QuranAyahWheel({
    super.key,
    required this.first,
    required this.last,
    required this.initial,
    required this.onChanged,
  });
  final int first, last, initial;
  final ValueChanged<int> onChanged;
  @override
  State<QuranAyahWheel> createState() => _QuranAyahWheelState();
}

class _QuranAyahWheelState extends State<QuranAyahWheel> {
  late int _selected = widget.initial;
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial - widget.first,
  );
  @override
  void didUpdateWidget(QuranAyahWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != _selected) {
      _selected = widget.initial.clamp(widget.first, widget.last);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToItem(_selected - widget.first);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read here, not in the wheel's item builder: that runs during layout,
    // where a widget can't subscribe to the language.
    final ayahLabel = AppText.of(context).quranAyahNumber;
    final numbers = context.localizedNumbers;
    return SizedBox(
      height: 70,
      child: RotatedBox(
        quarterTurns: -1,
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: 52,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 12,
          perspective: .001,
          onSelectedItemChanged: (index) {
            final value = widget.first + index;
            if (value == _selected) return;
            setState(() => _selected = value);
            HapticFeedback.selectionClick();
            widget.onChanged(value);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.last - widget.first + 1,
            builder: (_, i) {
              final n = widget.first + i;
              return RotatedBox(
                quarterTurns: 1,
                child: Semantics(
                  selected: n == _selected,
                  label: ayahLabel.fill({'n': numbers.digits('$n')}),
                  child: GestureDetector(
                    onTap: () => _controller.animateToItem(
                      i,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: n == _selected ? quranBorder : null,
                        border: Border.all(color: quranBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(numbers.digits('$n')),
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
