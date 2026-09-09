// Тексты разбора кода с упаковки.
//
// Разбор живёт в домене и отвечает кодом: язык экрана домену неизвестен, а
// объяснение у каждого языка своё. Перевод кода в текст — здесь, на границе с
// экраном, рядом с auth_rule_texts.dart и по тому же образцу.

import '../../l10n/app_localizations.dart';
import '../features/codes/domain/pack_code.dart';

extension PackCodeProblemText on PackCodeProblem {
  String text(AppLocalizations texts) => switch (kind) {
        PackCodeProblemKind.empty => texts.svcCodeEmpty,
        PackCodeProblemKind.length => texts.svcCodeLength(PackCode.length, entered),
        PackCodeProblemKind.unknownSymbol => texts.svcCodeUnknownSymbol(symbol),
        PackCodeProblemKind.checksum => texts.svcCodeChecksum,
      };
}
