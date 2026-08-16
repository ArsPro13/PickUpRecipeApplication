import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data_sources/remote/brew_method_service.dart';
import '../domain/brew_method.dart';

enum BrewMethodsStatus { loading, ready, failed }

/// Группа вместе с попавшими в неё методами — то, что рисует экран.
class GroupedMethods {
  const GroupedMethods({required this.name, required this.methods, this.slug = ''});

  final String name;

  /// Slug группы из справочника: по нему выбирается шаблон заваривания
  /// («давление» заканчивает шаги по признаку, а не по секундомеру).
  final String slug;

  final List<BrewMethod> methods;
}

class BrewMethodsState {
  const BrewMethodsState({
    this.status = BrewMethodsStatus.loading,
    this.grouped = const [],
    this.iconKeyBySlug = const {},
    this.groupSlugBySlug = const {},
    this.error,
  });

  final BrewMethodsStatus status;
  final List<GroupedMethods> grouped;

  /// icon_key по slug метода. Рецепт хранит slug (`hario_v60`), иконки лежат
  /// по icon_key (`v60`), и для двадцати методов этапа 1 они расходятся.
  /// Экраны, у которых в руках только slug, переводят его здесь, а не гадают.
  final Map<String, String> iconKeyBySlug;

  /// Семья прибора по его slug: пуровер, иммерсия, давление, холодные.
  /// По ней метка метода красится в свой цвет — семьдесят два прибора одним
  /// коричневым выглядят однородной массой.
  final Map<String, String> groupSlugBySlug;

  final String? error;
}

class BrewMethodsNotifier extends StateNotifier<BrewMethodsState> {
  BrewMethodsNotifier(this._service) : super(const BrewMethodsState());

  final BrewMethodService _service;

  Future<void> load() async {
    state = const BrewMethodsState();
    try {
      final methods = await _service.getMethods();
      final groups = await _service.getGroups();
      final grouped = groupMethods(methods, groups);

      state = BrewMethodsState(
        status: BrewMethodsStatus.ready,
        grouped: grouped,
        iconKeyBySlug: {
          for (final method in methods) method.slug: method.iconKey,
        },
        groupSlugBySlug: {
          for (final group in grouped)
            for (final method in group.methods) method.slug: group.slug,
        },
      );
    } catch (error) {
      state = BrewMethodsState(status: BrewMethodsStatus.failed, error: error.toString());
    }
  }
}

/// Раскладывает методы по группам в порядке справочника.
///
/// Метод без группы не теряется, а попадает в «Прочие»: двадцать методов в
/// списке, и молча спрятать один — худшее, что можно сделать с экраном выбора.
List<GroupedMethods> groupMethods(List<BrewMethod> methods, List<BrewMethodGroup> groups) {
  final ordered = [...groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final byGroup = <int?, List<BrewMethod>>{};

  for (final method in methods) {
    byGroup.putIfAbsent(method.groupId, () => []).add(method);
  }
  for (final list in byGroup.values) {
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  final result = <GroupedMethods>[];
  for (final group in ordered) {
    final inGroup = byGroup.remove(group.id);
    if (inGroup != null && inGroup.isNotEmpty) {
      result.add(GroupedMethods(name: group.name, slug: group.slug, methods: inGroup));
    }
  }

  final orphans = byGroup.values.expand((list) => list).toList();
  if (orphans.isNotEmpty) {
    orphans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    result.add(GroupedMethods(name: 'Прочие', methods: orphans));
  }

  return result;
}

final brewMethodServiceProvider = Provider<BrewMethodService>((ref) => BrewMethodService());

final brewMethodsProvider = StateNotifierProvider<BrewMethodsNotifier, BrewMethodsState>(
  (ref) => BrewMethodsNotifier(ref.watch(brewMethodServiceProvider)),
);
