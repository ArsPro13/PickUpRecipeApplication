import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../features/legal/data_sources/remote/legal_service.dart';
import '../features/legal/domain/legal_document.dart';
import '../themes/app_theme.dart';
import '../themes/app_tokens.dart';

/// Заголовок листа по виду документа.
///
/// Вид документа домен отдаёт кодом, а заголовок подставляет экран: домен
/// языка экрана не знает, а название документа у каждого языка своё.
extension LegalKindText on LegalKind {
  String title(AppLocalizations texts) => switch (this) {
        LegalKind.userAgreement => texts.svcLegalUserAgreement,
        LegalKind.privacy => texts.svcLegalPrivacy,
        LegalKind.consent => texts.svcLegalConsent,
      };
}

/// Показывает правовой документ листом снизу.
///
/// Лист, а не переход на отдельный экран: человек читает документ посреди
/// заполнения формы, и увести его со страницы значит потерять введённые
/// почту и пароль. Лист закрывается — форма остаётся как была.
Future<void> showLegalSheet(BuildContext context, LegalKind kind) {
  // Курсор уводим из поля до того, как лист откроется.
  //
  // Модальный маршрут запоминает, что было в фокусе, и на закрытии возвращает
  // фокус туда же. Для поля ввода это значит клавиатуру: человек набрал почту,
  // спрятал клавиатуру, открыл политику, потянул лист вниз — и клавиатура
  // выскочила обратно, хотя к полю он не притрагивался. Набранное при этом не
  // теряется: уходит фокус, а не текст, — контроллеры полей живут на экране.
  //
  // Снимается фокус здесь, а не на экране регистрации: лист открывают из
  // формы, и поднимать за собой клавиатуру он не должен нигде.
  FocusManager.instance.primaryFocus?.unfocus();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _LegalSheet(kind: kind),
  );
}

class _LegalSheet extends StatefulWidget {
  const _LegalSheet({required this.kind});

  final LegalKind kind;

  @override
  State<_LegalSheet> createState() => _LegalSheetState();
}

class _LegalSheetState extends State<_LegalSheet> {
  late Future<LegalDocument> _document;

  @override
  void initState() {
    super.initState();
    _document = const LegalService().fetch(widget.kind);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.kind.title(texts),
                      style: context.texts.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: texts.svcLegalClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<LegalDocument>(
                future: _document,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    // Прямо говорим, что документа нет, вместо пустого экрана:
                    // пустой экран человек читает как «согласия не требуется».
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.s6),
                      child: Text(
                        texts.svcLegalUnavailable('${Uri.parse(widget.kind.path)}'),
                        style: context.texts.bodyMedium,
                      ),
                    );
                  }

                  final document = snapshot.data!;
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    children: [
                      if (document.version.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                          child: Text(
                            texts.svcLegalVersion(document.version),
                            style: context.texts.bodySmall,
                          ),
                        ),
                      // Markdown показывается как есть, без разметки: тянуть
                      // ради этих трёх документов пакет-рендерер незачем, а
                      // читаемость от решёток в заголовках не страдает.
                      SelectableText(
                        document.body,
                        style: context.texts.bodySmall,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
