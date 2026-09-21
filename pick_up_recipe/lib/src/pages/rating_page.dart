// Экран 05 «Как получилось» — оценка чашки.
//
// Обязательного здесь нет вовсе. Карта вкуса всегда в каком-то положении,
// звёзды можно не ставить, оси можно не трогать — и кнопка внизу работает
// при любом их сочетании. Так и должно быть: оценку ставят через минуту
// после чашки, часто одной рукой, и экран, который отказывается закрываться,
// пока в него не ткнули в нужное место, просто закроют силой.
//
// Раньше звёзды были обязательны, и кнопка на них молча ничего не делала:
// объяснение появлялось строкой ниже, за краем экрана. Незаполненные звёзды
// теперь уезжают как «не сказал» (в базе NULL), а не как ноль — ноль на шкале
// 0…10 значит «отвратительно» и попал бы в среднюю по позиции у обжарщика.
//
// НО НЕОБЯЗАТЕЛЬНОСТЬ НАДО ЕЩЁ И ПОКАЗАТЬ. Звёзды стояли ВЫШЕ разделителя
// «Необязательно», то есть ровно там, где он обещает обязательную часть, —
// и экран целиком читался как анкета, которую сдают обжарщику. Звёзды уехали
// под разделитель, к осям, и подписаны прямо: на поправку рецепта они не
// влияют, они нужны самому человеку, чтобы потом найти свою лучшую чашку.
//
// А над всем этим стоит плашка, отвечающая на вопрос, который человек задаёт
// себе первым: зачем это заполнять. Ответ — «чтобы следующая чашка вышла
// лучше», и он про него, а не про обжарщика.
//
// Карта вместо анкеты потому, что одна точка отвечает на оба вопроса правил:
// горизонталь — экстракция (помол, температура, время), вертикаль —
// концентрация (соотношение). Шесть ползунков спрашивали бы то же самое
// шестью вопросами, из которых пять не влияют ни на одну поправку.
//
// Это не бланк SCA: там десять признаков с шагом 0,25 и нет горечи вовсе,
// а у нас на ней держатся правила. Режим каппинга, если понадобится, —
// отдельный экран.
//
// Всё натыканное переживает выход: экран пишет черновик в `RatingDrafts` и
// поднимает его обратно при возврате. Оценку ставят отвлекаясь, и потерянная
// половина работы не восстанавливается — чашка уже выпита.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/network_status.dart';
import '../../core/offline/offline_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../features/packs/domain/models/pack_model.dart';
import '../features/recipes/application/rating_draft.dart';
import '../features/recipes/domain/models/correction_model.dart';
import '../features/recipes/data_sources/remote/recipe_service.dart';
import '../features/recipes/domain/models/recipe_data_model.dart';
import '../features/recipes/domain/taste_map.dart';
import '../features/reference/application/reference_state.dart';
import '../features/reference/domain/flavor_descriptor_entry.dart';
import '../features/reference/domain/rating_words.dart';
import '../general_widgets/descriptor_chip.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../general_widgets/app_layout.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class RatingPage extends ConsumerStatefulWidget {
  const RatingPage({super.key, required this.recipe, this.pack});

  final RecipeData recipe;
  final PackData? pack;

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  final RecipeService _service = RecipeService();

  TastePoint _point = TastePoint.center;

  /// Общее впечатление в звёздах. 0 — не поставили, и это нормально.
  int _stars = 0;

  bool _busy = false;
  String? _error;

  /// Какие ползунки трогали. Нетронутая ось не уезжает вовсе: середина шкалы —
  /// это положение ползунка по умолчанию, а не то, что человек сказал.
  ///
  /// По одной оси, а не общим признаком: подпись обещает, что уедет только
  /// подвинутое, и «тронул аромат — поехали все шесть» было бы обманом.
  final Set<String> _touched = {};

  double _aroma = 5;
  double _flavor = 5;
  double _aftertaste = 5;
  double _acidity = 5;
  double _bitterness = 5;
  double _sweetness = 5;
  double _body = 5;

  /// Отмеченные слова — слаги общего справочника.
  ///
  /// Один набор на весь экран, а не по набору на план: слово описывает
  /// чашку, а не место в анкете, и «ягода» в аромате и «ягода» во вкусе —
  /// одна и та же ягода. В базе у оценки тоже один набор.
  final Set<String> _words = {};

  /// Выше этого значения у кислотности и сладости появляются слова.
  ///
  /// Шкала здесь 0…10, а «шесть» с макета — это шесть из девяти, то есть
  /// две трети. Спрашивать «какая именно кислотность» у того, кто поставил
  /// тройку, незачем: он уже сказал, что её нет.
  static const double _wordsFrom = 6.5;

  /// Отложенная запись черновика.
  ///
  /// Точку карты ведут пальцем, и запись на каждом кадре означала бы полсотни
  /// обращений к хранилищу за один жест. Пишем, когда рука остановилась.
  Timer? _draftWrite;

  /// Звёзды 1…5 → шкала 0…10, в которой живёт recipes_estimations.
  /// null — звёзд не ставили.
  double? get _overall => _stars == 0 ? null : _stars * 2;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    // Уходят с этого экрана чаще всего именно посреди оценки — дописываем то,
    // что не успел отложенный таймер, иначе последнее движение пропадёт.
    if (_draftWrite?.isActive ?? false) {
      _draftWrite!.cancel();
      unawaited(RatingDrafts.save(_draft()));
    }
    super.dispose();
  }

  /// Поднимает незаконченную оценку этой же чашки.
  ///
  /// Сверяем и рецепт, и пачку: базовый рецепт обжарщика один на всех, и
  /// перенести на другую пачку чужую половину оценки было бы хуже, чем
  /// потерять её.
  Future<void> _restoreDraft() async {
    final draft = await RatingDrafts.load();
    if (!mounted || draft == null) return;
    if (draft.recipe.id != widget.recipe.id) return;
    if (draft.pack?.packId != widget.pack?.packId) return;

    setState(() {
      _point = draft.point;
      _stars = draft.stars;
      for (final axis in draft.axes.entries) {
        _touched.add(axis.key);
        switch (axis.key) {
          case 'aroma':
            _aroma = axis.value;
          case 'flavor':
            _flavor = axis.value;
          case 'aftertaste':
            _aftertaste = axis.value;
          case 'acidity':
            _acidity = axis.value;
          case 'bitterness':
            _bitterness = axis.value;
          case 'sweetness':
            _sweetness = axis.value;
          case 'body':
            _body = axis.value;
        }
      }
      _words
        ..clear()
        ..addAll(draft.words);
    });
  }

  RatingDraft _draft() => RatingDraft(
        recipe: widget.recipe,
        pack: widget.pack,
        point: _point,
        stars: _stars,
        axes: {
          for (final axis in _touched) axis: _axisValue(axis),
        },
        words: _words.toList(),
        savedAt: DateTime.now(),
      );

  double _axisValue(String axis) => switch (axis) {
        'aroma' => _aroma,
        'flavor' => _flavor,
        'aftertaste' => _aftertaste,
        'acidity' => _acidity,
        'bitterness' => _bitterness,
        'body' => _body,
        _ => _sweetness,
      };

  /// Запомнить сказанное — не сразу, а как только рука остановится.
  void _remember() {
    _draftWrite?.cancel();
    _draftWrite = Timer(AppDuration.slow, () => RatingDrafts.save(_draft()));
  }

  /// Отправляет оценку; [wantCorrection] — ещё и открыть рецепт с поправкой.
  ///
  /// Отдельной страницы «что изменилось» нет: по макету diff убран, и
  /// «Поправить рецепт» ведёт прямо в конструктор, где поправка уже
  /// применена, изменения помечены точками и её можно отменить целиком.
  Future<void> _submit({required bool wantCorrection}) async {
    final texts = AppLocalizations.of(context);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Базовый рецепт (packId == 0) общий, и оценку на него не повесить:
      // владельца у него нет. Первая оценка и есть «первая правка» из C7 —
      // заводим свою копию с пачкой, с которой пришли, и оцениваем её.
      // Дальше вся цепочка — поправка, правки — идёт по копии.
      if (widget.recipe.packId == 0 && widget.pack != null) {
        widget.recipe.packId = widget.pack!.packId;
        widget.recipe.id = await _service.evolveRecipe(widget.recipe);
      }

      await _service.postEstimation(
        recipeId: widget.recipe.id,
        // Уезжает только сказанное. Нетронутые оси не размазываются общей
        // оценкой и не подменяются серединой шкалы: и то, и другое — числа,
        // которых человек не называл.
        aroma: _touched.contains('aroma') ? _aroma : null,
        flavor: _touched.contains('flavor') ? _flavor : null,
        aftertaste: _touched.contains('aftertaste') ? _aftertaste : null,
        acidity: _touched.contains('acidity') ? _acidity : null,
        bitterness: _touched.contains('bitterness') ? _bitterness : null,
        sweetness: _touched.contains('sweetness') ? _sweetness : null,
        overall: _overall,
        // Слова уезжают слагами: подпись зависит от языка телефона, а
        // сравнивать оценки надо между телефонами.
        descriptors: _words.toList(),
        // Тело живёт не колонкой оценки, а дополнительной осью справочника,
        // и уезжает по своему слагу — вместе с остальными тронутыми.
        axes: {
          if (_touched.contains('body')) 'body': _body,
        },
        // По-русски и на английском телефоне: комментарий читают люди в
        // кабинете обжарщика, и язык этого поля — не язык телефона.
        comment: _point.isCenter ? '' : _point.summaryRu,
      );

      // Оценка уехала (или встала в очередь) — продолжать больше нечего.
      _draftWrite?.cancel();
      await RatingDrafts.clear();

      if (!mounted) return;

      if (!wantCorrection || _point.complaints.isEmpty) {
        if (!NetworkStatus.online.value) {
          _say(texts.rateSavedOffline);
        }
        await context.router.maybePop();
        return;
      }

      // Сервер отвечает и списком изменений, и готовым поправленным
      // рецептом: числа считает он, клиент их не выдумывает.
      final RecipeCorrection correction;
      try {
        correction = await _service.suggestCorrection(
          recipeId: widget.recipe.id,
          complaints: _point.complaints,
        );
      } on OfflineException {
        // Поправку считает сервер по своим правилам — повторить их на
        // телефоне значит завести вторые правила, которые разойдутся с
        // первыми. Оценка уже в очереди; рецепт можно поправить руками.
        if (!mounted) return;
        _say(texts.rateSavedCorrectionLater);
        await context.router.maybePop();
        return;
      }

      if (!mounted) return;

      // Жалобы тянут в разные стороны — сначала техника, не цифры (S15/S16).
      if (correction.hasConflicts) {
        await context.router.replace(
          RatingConflictRoute(
            recipe: widget.recipe,
            pack: widget.pack,
            summary: _point.summaryFor(texts),
            correction: correction,
          ),
        );
        return;
      }

      if (correction.isEmpty || correction.recipe == null) {
        _say(texts.rateNothingToChange);
        await context.router.maybePop();
        return;
      }

      // replace, а не push: возврат из конструктора должен вести к списку
      // рецептов, а не на уже отправленную оценку.
      await context.router.replace(
        RecipeBuilderRoute(
          recipe: correction.recipe!,
          original: widget.recipe,
          correctionLabel: _point.summaryFor(texts),
          pack: widget.pack,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ползунок подвинули: запоминаем это отдельно от значения.
  ///
  /// Без такого признака нетронутая середина шкалы уехала бы как «пятёрка по
  /// аромату» — число, которого никто не называл.
  void _axis(String axis, VoidCallback change) {
    setState(() {
      change();
      _touched.add(axis);
    });
    _remember();
  }

  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Уйти, ничего не сказав.
  ///
  /// Черновик при этом стирается: «пропустить» — это ответ, а не отложить.
  /// Иначе плашка «продолжите оценку» встретила бы человека на вкладке пачек
  /// сразу после того, как он отказался.
  Future<void> _skip() async {
    _draftWrite?.cancel();
    await RatingDrafts.clear();
    if (!mounted) return;
    await context.router.maybePop();
  }

  void _toggleWord(String slug) {
    setState(() {
      if (!_words.remove(slug)) _words.add(slug);
    });
    _remember();
  }

  /// Всё колесо: слова, которых нет на экране.
  Future<void> _openWheel(
    List<FlavorDescriptorEntry> dictionary,
    bool english,
  ) async {
    final texts = AppLocalizations.of(context);
    final palette = ref.read(paletteNowProvider);

    // Тактильность в колесе не показывается: её спрашивает свой план ниже,
    // и одно и то же слово в двух местах экрана значило бы два разных
    // вопроса про одно ощущение.
    final byCategory = <String, List<FlavorDescriptorEntry>>{};
    for (final entry in dictionary) {
      if (entry.category == 'mouthfeel') continue;
      byCategory.putIfAbsent(entry.category, () => []).add(entry);
    }
    final categories = byCategory.keys.toList()
      ..sort((a, b) =>
          palette.bySlug(a).sortOrder.compareTo(palette.bySlug(b).sortOrder));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                0,
                AppSpacing.s5,
                AppSpacing.s5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texts.rateWheelTitle, style: context.texts.titleMedium),
                  const SizedBox(height: AppSpacing.s2),
                  Text(texts.rateWheelHint, style: context.texts.labelSmall),
                  const SizedBox(height: AppSpacing.s4),
                  for (final category in categories) ...[
                    Text(
                      palette.bySlug(category).label(english),
                      style: context.texts.labelSmall?.copyWith(
                        color: palette
                            .bySlug(category)
                            .ink(Theme.of(context).brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Wrap(
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s2,
                      children: [
                        for (final entry in byCategory[category]!)
                          DescriptorChip(
                            word: entry.label(english),
                            lookup: entry.slug,
                            dense: true,
                            selected: _words.contains(entry.slug),
                            onTap: () {
                              _toggleWord(entry.slug);
                              setSheet(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final english = Localizations.localeOf(context).languageCode != 'ru';
    final brightness = Theme.of(context).brightness;
    final palette = ref.watch(paletteNowProvider);

    // Подписи слов берутся из справочника, если он приехал, и из встроенного
    // набора, если нет: оценку ставят там же, где заваривали, а это чаще
    // всего кухня без сети.
    final dictionary =
        ref.watch(flavorDescriptorsProvider).valueOrNull ?? const [];
    final known = {for (final entry in dictionary) entry.slug: entry};
    String labelOf(RatingWord word) =>
        known[word.slug]?.label(english) ?? word.label(english);

    // Обжарщик пишет дескрипторы словами, а хранятся они слагами. Слово с
    // пачки ищется в словаре по имени; не нашлось — уедет как есть, и
    // сервер его не запишет: строки справочника для него нет.
    final slugOfName = <String, String>{
      for (final entry in dictionary)
        if (entry.name.isNotEmpty) entry.name.toLowerCase(): entry.slug,
      for (final entry in dictionary)
        if (entry.nameEn.isNotEmpty) entry.nameEn.toLowerCase(): entry.slug,
    };

    final subtitle = [
      widget.pack?.packName,
      widget.recipe.title.isNotEmpty
          ? widget.recipe.title
          : widget.recipe.device,
    ].whereType<String>().where((it) => it.isNotEmpty).join(' · ');

    // Обещания обжарщика — только у пачки, которую завёл обжарщик. У пачки,
    // заведённой руками, дескрипторы вписал сам человек, и спрашивать его,
    // нашёл ли он собственные слова, незачем.
    final promised = (widget.pack?.roasterName ?? '').isEmpty
        ? const <String>[]
        : (widget.pack?.packDescriptors ?? const <String>[]);

    Widget words(List<RatingWord> set) => _WordRow(
          words: set,
          chosen: _words,
          label: labelOf,
          onToggle: _toggleWord,
        );

    return AppScreen(
      title: texts.rateTitle,
      actions: [
        TextButton(
          onPressed: _busy ? null : _skip,
          child: Text(texts.rateSkip),
        ),
      ],
      body: [
        if (subtitle.isNotEmpty) ...[
          Text(subtitle, style: context.texts.bodySmall),
          const SizedBox(height: AppSpacing.s3),
        ],

        // Что делать с картой — одной строкой над ней. Человек видит круг
        // раньше, чем любое объяснение под ним.
        Text(texts.rateHowTo, style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.s2),

        HeroSurface(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: TasteMap(
            point: _point,
            onChanged: (point) {
              setState(() => _point = point);
              _remember();
            },
          ),
        ),

        const SizedBox(height: AppSpacing.s3),
        _SummaryLine(
          point: _point,
          onReset: _point.isCenter
              ? null
              : () {
                  setState(() => _point = TastePoint.center);
                  _remember();
                },
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.uiWarning,
                  size: AppSizes.icon20, color: context.colors.error),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  _error!,
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.colors.error),
                ),
              ),
            ],
          ),
        ],

        if (promised.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s5),
          _PromiseBlock(
            promised: promised,
            chosen: _words,
            slugOf: (word) => slugOfName[word.trim().toLowerCase()] ?? word,
            onToggle: _toggleWord,
          ),
        ],

        const _OptionalDivider(),

        // ТРИ ПЛАНА, А НЕ ОДИН СПИСОК. Раньше шесть ползунков стояли подряд,
        // и «кислотность» соседствовала с «телом»: первое — вкус, второе —
        // ощущение, и вопрос был один на двоих. Теперь планы разведены и
        // подписаны, а у каждого свой цвет.
        _Plane(
          title: texts.ratePlaneFlavour,
          note: texts.ratePlaneFlavourNote,
          color: palette.bySlug('fruit').ink(brightness),
          children: [
            _ScaleLine(
              name: texts.rateAxisAroma,
              value: _aroma,
              onChanged: (v) => _axis('aroma', () => _aroma = v),
            ),
            _ScaleLine(
              name: texts.rateAxisFlavor,
              value: _flavor,
              onChanged: (v) => _axis('flavor', () => _flavor = v),
            ),
            _ScaleLine(
              name: texts.rateAxisAftertaste,
              value: _aftertaste,
              onChanged: (v) => _axis('aftertaste', () => _aftertaste = v),
            ),
            const SizedBox(height: AppSpacing.s2),
            words(kFlavourWords),
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              label: texts.rateWholeWheel,
              kind: AppButtonKind.secondary,
              block: false,
              onPressed: dictionary.isEmpty
                  ? null
                  : () => _openWheel(dictionary, english),
            ),
          ],
        ),

        _Plane(
          title: texts.ratePlaneTastes,
          note: texts.ratePlaneTastesNote,
          color: context.colors.primary,
          children: [
            _ScaleLine(
              name: texts.rateAxisAcidity,
              value: _acidity,
              color: palette.bySlug('citrus').ink(brightness),
              ends: (texts.rateEndNone, texts.rateEndBright),
              onChanged: (v) => _axis('acidity', () => _acidity = v),
            ),
            // Слова появляются только у сильного: у того, кто поставил
            // двойку, спрашивать «какая именно кислотность» нечего.
            if (_acidity >= _wordsFrom) ...[
              const SizedBox(height: AppSpacing.s2),
              words(kAcidityWords),
              const SizedBox(height: AppSpacing.s3),
            ],
            _ScaleLine(
              name: texts.rateAxisSweetness,
              value: _sweetness,
              color: palette.bySlug('sugars').ink(brightness),
              ends: (texts.rateEndNone, texts.rateEndThick),
              onChanged: (v) => _axis('sweetness', () => _sweetness = v),
            ),
            if (_sweetness >= _wordsFrom) ...[
              const SizedBox(height: AppSpacing.s2),
              words(kSweetnessWords),
            ],
          ],
        ),

        _Plane(
          title: texts.ratePlaneMouth,
          note: texts.ratePlaneMouthNote,
          color: palette.bySlug('mouthfeel').ink(brightness),
          children: [
            _ScaleLine(
              name: texts.rateAxisBody,
              value: _body,
              color: palette.bySlug('mouthfeel').ink(brightness),
              ends: (texts.rateEndLight, texts.rateEndFull),
              onChanged: (v) => _axis('body', () => _body = v),
            ),
            const SizedBox(height: AppSpacing.s2),
            words(kBodyWords),
          ],
        ),

        const SizedBox(height: AppSpacing.s5),

        // Звёзды — единственное, что уходит обжарщику, и стоят они последними
        // не по важности, а по порядку разговора: сперва про чашку, потом
        // общее впечатление.
        _Stars(
          value: _stars,
          onChanged: (value) {
            setState(() {
              _stars = value;
              _error = null;
            });
            _remember();
          },
        ),

        const SizedBox(height: AppSpacing.s5),
        const _ForYouPlate(),
      ],
      bottom: [
        if (_point.complaints.isEmpty)
          AppButton(
            label: texts.rateSave,
            loading: _busy,
            onPressed: _busy ? null : () => _submit(wantCorrection: false),
          )
        else ...[
          AppButton(
            label: texts.rateFixRecipe,
            icon: AppIcons.uiEdit,
            loading: _busy,
            onPressed: _busy ? null : () => _submit(wantCorrection: true),
          ),
          // Своей распорки здесь нет: панель уже разводит соседей на
          // AppSpacing.s2, и стоявший тут s3 только складывался с ним —
          // выходило двадцать восемь точек, из-за которых вторая кнопка
          // прижималась к нижней навигации.
          AppButton(
            label: texts.rateJustSave,
            kind: AppButtonKind.secondary,
            onPressed: _busy ? null : () => _submit(wantCorrection: false),
          ),
        ],
        TextButton(
          onPressed: _busy ? null : _skip,
          child: Text(texts.rateSkipRating),
        ),
      ],
    );
  }
}

/// Карта вкуса: две оси, три кольца, цель обжарщика в центре и своя точка.
class TasteMap extends StatelessWidget {
  const TasteMap({super.key, required this.point, required this.onChanged});

  final TastePoint point;
  final ValueChanged<TastePoint> onChanged;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        void report(Offset local) {
          // Точка карты — доля от половины стороны: (0,0) в центре,
          // ±1 у края. Ось Y перевёрнута: вверх на экране — это «крепко».
          final half = size / 2;
          onChanged(
            TastePoint(
              (local.dx - half) / half,
              -(local.dy - half) / half,
            ).clamped(),
          );
        }

        return GestureDetector(
          onTapDown: (details) => report(details.localPosition),
          onPanUpdate: (details) => report(details.localPosition),
          child: Semantics(
            label: texts.rateMapSemantics(point.summaryFor(texts)),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _TasteMapPainter(
                  point: point,
                  ends: (
                    sour: texts.rateTasteSour,
                    bitter: texts.rateTasteBitter,
                    strong: texts.rateTasteStrong,
                    weak: texts.rateTasteWeak,
                  ),
                  frame: context.palette.border,
                  ink: context.colors.onSurface,
                  accent: context.colors.primary,
                  zones: _TasteZones.of(Theme.of(context).brightness),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Раскраска колец карты: чем дальше от центра, тем хуже.
///
/// Цвета зашиты числами, а не взяты из темы: это выбранные краски, а не
/// производные от фона. В тёмной теме — мягкий светофор, в светлой —
/// «Пряности»: олива, куркума, паприка. Одни и те же три круга в тёмной теме
/// светофором выглядели правильно, а в светлой краснили — на белом та же
/// заливка читается вдвое громче.
///
/// Непрозрачность у светлой темы выше: заливка ложится на белое и гаснет.
class _TasteZones {
  const _TasteZones(this.colors, this.alpha, this.aim);

  /// От центра наружу: «как задумано», «заметно», «сильно мимо».
  final List<Color> colors;
  final List<double> alpha;

  /// Пунктир цели обжарщика. Не цвет ближнего кольца: пунктир лежит ПОВЕРХ
  /// этого кольца, и тем же цветом его не видно — проверено на экране.
  final Color aim;

  static const _TasteZones _light = _TasteZones(
    [Color(0xFFA9C24F), Color(0xFFF2B733), Color(0xFFD95F2E)],
    [0.64, 0.58, 0.52],
    Color(0xFF5F7320),
  );

  static const _TasteZones _dark = _TasteZones(
    [Color(0xFF3FBF63), Color(0xFFE5A93C), Color(0xFFE2594A)],
    [0.46, 0.38, 0.32],
    Color(0xFF7BE29A),
  );

  static _TasteZones of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  Color band(int ring) => colors[ring].withValues(alpha: alpha[ring]);
}

class _TasteMapPainter extends CustomPainter {
  const _TasteMapPainter({
    required this.point,
    required this.ends,
    required this.frame,
    required this.ink,
    required this.accent,
    required this.zones,
  });

  final TastePoint point;

  /// Подписи четырёх концов осей — уже на языке интерфейса: холст словаря
  /// не видит, а по-русски они были прибиты прямо здесь.
  final ({String sour, String bitter, String strong, String weak}) ends;

  final Color frame;
  final Color ink;
  final Color accent;
  final _TasteZones zones;

  /// Доли поля, на которых стоят кольца. Внешнее кольцо и есть край поля.
  static const List<double> _rings = [0.34, 0.67, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final half = size.width / 2;

    // Поле оставляет поля под подписи осей.
    final field = half * 0.76;

    // Кольца заливаются снаружи внутрь: заливки полупрозрачные, и «зелёное
    // поверх жёлтого поверх красного» — это и есть три ступени.
    for (var ring = _rings.length - 1; ring >= 0; ring--) {
      canvas.drawCircle(
        center,
        field * _rings[ring],
        Paint()..color = zones.band(ring),
      );
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.thin
      ..color = frame;

    for (final fraction in _rings) {
      canvas.drawCircle(center, field * fraction, line);
    }

    canvas.drawLine(
      Offset(center.dx - field, center.dy),
      Offset(center.dx + field, center.dy),
      line,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - field),
      Offset(center.dx, center.dy + field),
      line,
    );

    // Цель обжарщика — в центре: «получилось как задумано». Пунктиром, а не
    // сплошным: сплошной круг того же цвета читался как ещё одно кольцо.
    _dashedCircle(
      canvas,
      center,
      field * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.thick
        ..color = zones.aim,
    );

    // Подписи крупнее прежних двенадцати пунктов: карта шириной с ладонь, и
    // мелкая подпись у края круга не читается на ходу.
    final labelSize = (field * 0.14).clamp(12.0, 18.0);

    _label(canvas, ends.sour, Offset(0, center.dy), ink, labelSize);
    _label(canvas, ends.bitter, Offset(size.width, center.dy), ink, labelSize,
        anchorRight: true);
    // Все четыре подписи — наречия, одной частью речи. «Крепче» и «слабее»
    // рядом с «кисло» и «горько» читались как два разных вопроса на одном
    // круге: одна ось спрашивала «по сравнению с чем», вторая — «какое».
    // То же правило держит и английский: одна часть речи на все четыре конца.
    _label(canvas, ends.strong,
        Offset(center.dx, center.dy - field - labelSize), ink, labelSize,
        centered: true);
    _label(canvas, ends.weak,
        Offset(center.dx, center.dy + field + labelSize), ink, labelSize,
        centered: true);

    if (point.isCenter) return;

    final you =
        Offset(center.dx + point.x * field, center.dy - point.y * field);

    canvas.drawLine(
      center,
      you,
      Paint()
        ..strokeWidth = AppStroke.thin
        ..color = accent.withValues(alpha: 0.5),
    );
    canvas.drawCircle(
        you, AppSpacing.s5, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawCircle(you, AppSpacing.s2, Paint()..color = accent);
  }

  /// Пунктирная окружность: Flutter рисует пунктир только дугами.
  void _dashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashes = 16;
    const sweep = 6.283185307179586 / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double fontSize, {
    bool centered = false,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = centered
        ? at.dx - painter.width / 2
        : (anchorRight ? at.dx - painter.width : at.dx);

    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  // Не только точка: сменившийся язык оставляет точку на месте, а подписи
  // осей меняет, и без сравнения они остались бы от прошлого языка. Тема
  // меняет раскраску колец — её тоже надо сравнивать.
  @override
  bool shouldRepaint(_TasteMapPainter oldDelegate) =>
      oldDelegate.point != point ||
      oldDelegate.ends != ends ||
      oldDelegate.zones != zones;
}

/// Что человек сказал картой — словами.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.point, required this.onReset});

  final TastePoint point;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return QuietSurface(
      child: Row(
        children: [
          AppIcon(
            point.isCenter ? AppIcons.uiCheck : AppIcons.uiWarning,
            size: AppSizes.icon20,
            color: point.isCenter
                ? context.palette.success
                : context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
              child: Text(point.summaryFor(texts),
                  style: context.texts.bodyMedium)),
          if (onReset != null)
            IconButton(
              onPressed: onReset,
              tooltip: texts.remove,
              icon: AppIcon(
                AppIcons.uiClose,
                size: AppSizes.icon16,
                color: context.colors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Общее впечатление: пять звёзд.
class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return QuietSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(texts.rateOverall, style: context.texts.bodyMedium),
              const SizedBox(width: AppSpacing.s2),
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => onChanged(star),
                  tooltip: texts.rateStarsOf(star),
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.tapTarget - AppSpacing.s4,
                    minHeight: AppSizes.tapTarget - AppSpacing.s4,
                  ),
                  padding: EdgeInsets.zero,
                  icon: AppIcon(
                    star <= value ? AppIcons.uiStarFilled : AppIcons.uiStar,
                    size: AppSizes.icon24,
                    color: star <= value
                        ? context.colors.primary
                        : context.colors.secondary,
                  ),
                ),
              const Spacer(),
              if (value > 0)
                Text(
                  '$value',
                  style: context.texts.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(texts.rateOverallNote, style: context.texts.labelSmall),
        ],
      ),
    );
  }
}

/// Плашка «оценка нужна вам».
///
/// Отдельным виджетом, а не строкой текста: у неё своя поверхность фирменного
/// цвета, и на экране она читается как ответ, а не как мелкая сноска, которую
/// пропускают. Ровно этот вопрос — «зачем мне это заполнять» — и превращал
/// экран в анкету, которую пролистывают к кнопке.
class _ForYouPlate extends StatelessWidget {
  const _ForYouPlate();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.09),
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            AppIcons.uiUser,
            size: AppSizes.icon20,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
              child: Text(texts.rateForYou, style: context.texts.labelSmall)),
        ],
      ),
    );
  }
}

/// Разделитель «Необязательно»: всё нужное правилам осталось выше.
class _OptionalDivider extends StatelessWidget {
  const _OptionalDivider();

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
      child: Row(
        children: [
          Text(texts.rateOptional, style: context.texts.bodySmall),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Divider(color: context.palette.border)),
        ],
      ),
    );
  }
}


/// План оценки: цветная полоска, название, пояснение и содержимое.
///
/// План — это не раздел формы, а вопрос одного рода: «на что похоже»,
/// «какие основные вкусы», «какое во рту». Пока они стояли одним списком
/// ползунков, «кислотность» и «тело» читались как однородные, хотя первое —
/// вкус, а второе — ощущение.
class _Plane extends StatelessWidget {
  const _Plane({
    required this.title,
    required this.note,
    required this.color,
    required this.children,
  });

  final String title;
  final String note;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.s1,
                height: AppSpacing.s5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.small,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(title, style: context.texts.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s4),
            child: Text(note, style: context.texts.labelSmall),
          ),
          const SizedBox(height: AppSpacing.s3),
          QuietSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна линия шкалы: название слева, значение справа, подписи концов внизу.
///
/// Подписи концов, а не только цифра: «кислотность 7» ничего не значит без
/// того, где у шкалы «нет», а где «яркая». Цифра оставлена — по ней человек
/// потом сравнивает две чашки.
class _ScaleLine extends StatelessWidget {
  const _ScaleLine({
    required this.name,
    required this.value,
    required this.onChanged,
    this.ends,
    this.color,
  });

  final String name;
  final double value;
  final ValueChanged<double> onChanged;

  /// Что значат концы шкалы. Пусто — обычные «слабо» и «сильно».
  final (String, String)? ends;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final tint = color ?? context.colors.primary;
    final (low, high) =
        ends ?? (texts.rateScaleLow, texts.rateScaleHigh);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: context.texts.bodySmall)),
              Text(
                value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
                style: context.texts.bodySmall?.copyWith(color: tint),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tint,
              thumbColor: tint,
              overlayColor: tint.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value,
              max: 10,
              divisions: 40,
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(low, style: context.texts.labelSmall),
              Text(high, style: context.texts.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ряд слов с выбором. Предела нет: отмечают столько, сколько почувствовали.
class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.words,
    required this.chosen,
    required this.label,
    required this.onToggle,
  });

  final List<RatingWord> words;
  final Set<String> chosen;
  final String Function(RatingWord word) label;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: [
        for (final word in words)
          DescriptorChip(
            word: label(word),
            lookup: word.slug,
            categorySlug: word.category,
            dense: true,
            selected: chosen.contains(word.slug),
            onTap: () => onToggle(word.slug),
          ),
      ],
    );
  }
}

/// Что обещал обжарщик — и что из этого нашлось.
///
/// Не «да / нет» у каждого слова, а тот же набор меток, что и везде: нажал —
/// значит нашёл. Две кнопки на слово превращали блок в анкету из шести
/// вопросов там, где их три.
///
/// Слова здесь — свободный текст с пачки, а не слаги справочника: обжарщик
/// пишет их сам. В набор они уезжают как есть, и цвет им подбирает палитра
/// по имени — ровно так же, как на карточке пачки.
class _PromiseBlock extends StatelessWidget {
  const _PromiseBlock({
    required this.promised,
    required this.chosen,
    required this.slugOf,
    required this.onToggle,
  });

  final List<String> promised;
  final Set<String> chosen;

  /// Слово с пачки → слаг справочника, если он известен.
  final String Function(String word) slugOf;

  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final found = promised.where((w) => chosen.contains(slugOf(w))).length;

    return QuietSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.ratePromiseTitle, style: context.texts.bodySmall),
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final word in promised)
                DescriptorChip(
                  word: word,
                  dense: true,
                  selected: chosen.contains(slugOf(word)),
                  onTap: () => onToggle(slugOf(word)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            found == 0
                ? texts.ratePromiseNone
                : texts.ratePromiseFound(found, promised.length),
            style: context.texts.labelSmall,
          ),
        ],
      ),
    );
  }
}
