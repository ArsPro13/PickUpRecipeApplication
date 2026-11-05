// Вопрос «Прервать заваривание?».
//
// Задают его два места — кнопка «Прервать» на экране заваривания и крестик на
// плашке «Идёт заваривание», — и отвечать им положено одинаково.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Спрашивает, точно ли прерываем заваривание. true — прерываем.
///
/// Вопрос остался от времён, когда его задавал уход с экрана: одно касание
/// кнопки «назад» стирало отсчёт посреди пролива. Теперь уход ничего не
/// стирает и ни о чём не спрашивает — а «Прервать» стирает, и промах по ней
/// обошёлся бы так же дорого.
Future<bool> confirmBrewAbort(BuildContext context) async {
  final texts = AppLocalizations.of(context);

  final abort = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(texts.brewAbortTitle),
      content: Text(texts.brewAbortNote),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(texts.brewKeepBrewing),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(texts.brewAbort),
        ),
      ],
    ),
  );

  return abort ?? false;
}
