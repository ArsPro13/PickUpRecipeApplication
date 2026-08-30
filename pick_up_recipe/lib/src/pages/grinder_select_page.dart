// Экран выбора кофемолки.
//
// Список сгруппирован по виду — ручные и электрические (ответ E7): в
// справочнике пятьдесят записей, и без группировки найти свою на глаз тяжело.
//
// Основная отмечается явно: в рецепте показывается одно число щелчков, и
// выбрать, чьи это деления, приложение за человека не может.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/network_status.dart';
import '../features/grinders/application/grinder_state.dart';
import '../features/grinders/domain/models/grinder_model.dart';
import '../general_widgets/app_icon.dart';
import '../general_widgets/app_kit.dart';
import '../themes/app_icons.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

@RoutePage()
class GrinderSelectPage extends ConsumerStatefulWidget {
  const GrinderSelectPage({super.key});

  @override
  ConsumerState<GrinderSelectPage> createState() => _GrinderSelectPageState();
}

class _GrinderSelectPageState extends ConsumerState<GrinderSelectPage> {
  final TextEditingController _search = TextEditingController();

  /// Выбранные кофемолки и та из них, что основная. Правки применяются
  /// кнопкой, а не сразу: случайное касание не должно менять пересчёт помола.
  final Set<int> _selected = {};
  int? _primary;

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(grinderStateProvider.notifier).loadCatalog();
      ref.read(grinderStateProvider.notifier).loadUserGrinders();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Переносит уже сохранённый набор в локальный выбор ровно один раз.
  void _seedFrom(GrinderState state) {
    if (_initialised || state.userGrinders.isEmpty) return;
    _initialised = true;
    _selected.addAll(state.userGrinders.map((item) => item.grinder.id));
    _primary = state.primary?.id;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(grinderStateProvider);
    _seedFrom(state);

    final query = _search.text.trim().toLowerCase();
    final catalog = query.isEmpty
        ? state.catalog
        : state.catalog.where((g) => g.name.toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Кофемолка')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s2,
              AppSpacing.s4,
              AppSpacing.s3,
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Найти кофемолку',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  child: AppIcon(
                    AppIcons.uiSearch,
                    size: AppSizes.icon20,
                    color: context.colors.secondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && state.catalog.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _catalogList(catalog),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: AppButton(
                label: 'Сохранить',
                loading: state.isLoading && state.catalog.isNotEmpty,
                onPressed: _selected.isEmpty ? null : () => _save(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalogList(List<Grinder> catalog) {
    if (catalog.isEmpty) {
      return const AppState(
        icon: AppIcons.stateEmpty,
        title: 'Такой кофемолки нет',
        description: 'Проверьте написание — в справочнике полсотни моделей',
      );
    }

    final byKind = <GrinderKind, List<Grinder>>{};
    for (final grinder in catalog) {
      byKind.putIfAbsent(grinder.kind, () => []).add(grinder);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      children: [
        for (final kind in GrinderKind.values)
          if (byKind[kind] != null) ...[
            SectionTitle(kind.title),
            for (final grinder in byKind[kind]!) _tile(grinder),
          ],
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }

  Widget _tile(Grinder grinder) {
    final selected = _selected.contains(grinder.id);

    return AppRow(
      label: grinder.name,
      icon: AppIcons.metricGrind,
      onTap: () => setState(() {
        if (selected) {
          _selected.remove(grinder.id);
          if (_primary == grinder.id) _primary = null;
        } else {
          _selected.add(grinder.id);
          _primary ??= grinder.id;
        }
      }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            TextButton(
              onPressed: () => setState(() => _primary = grinder.id),
              child: Text(_primary == grinder.id ? 'основная' : 'сделать основной'),
            ),
          AppIcon(
            selected ? AppIcons.uiCheck : AppIcons.uiPlus,
            size: AppSizes.icon20,
            color: selected ? context.colors.primary : context.colors.secondary,
          ),
        ],
      ),
    );
  }

  Future<void> _save(GrinderState state) async {
    final chosen = state.catalog.where((g) => _selected.contains(g.id)).toList();

    await ref.read(grinderStateProvider.notifier).save(chosen, primaryGrinderId: _primary);

    if (!mounted) return;

    final error = ref.read(grinderStateProvider).error;
    if (error != null) {
      // Набор кофемолок живёт на сервере (ответ на вопрос 19), и в очередь
      // он не встаёт: выбор делают дома, а не у чайника, и «сохраню потом»
      // здесь означало бы, что человек ушёл, считая дело сделанным.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NetworkStatus.online.value
                ? 'Не удалось сохранить кофемолки'
                : 'Без сети кофемолку не сохранить — она хранится в аккаунте',
          ),
        ),
      );
      return;
    }

    await context.router.maybePop();
  }
}
