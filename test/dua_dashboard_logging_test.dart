import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';

/// Drives [DuaApiLogInterceptor] with an answer shaped like the one the
/// Daily filter has been returning — percentages filled in, the comparison's
/// times and points empty — and reads back what it printed.
List<String> _logOf(
  Object? body, {
  String timeframe = 'daily',
  int statusCode = 200,
}) {
  final lines = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) lines.add(message);
  };
  addTearDown(() => debugPrint = original);

  final options = RequestOptions(
    path: '/duas/reading/dashboard',
    method: 'GET',
    queryParameters: {'timeframe': timeframe},
  );
  DuaApiLogInterceptor().onResponse(
    Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
    ResponseInterceptorHandler(),
  );
  return lines;
}

const _body = {
  'success': true,
  'data': {
    'timeframe': 'daily',
    'overview': {
      'totalDuasRecited': 148,
      'dailyTargetText': '35/40',
      'totalReadingTimeFormatted': '3h 45m',
      'myPositionPercentage': 68,
      'competitorPercentage': 32,
      'comparison': {
        'me': {'name': 'Nizam', 'readingTimeFormatted': '', 'pointsText': ''},
        'rival': {
          'name': 'Labib Al Mahmud',
          'readingTimeFormatted': '',
          'pointsText': '',
        },
      },
    },
    'weeklyActivity': {
      'days': [
        {
          'dayOfWeek': 'FRI',
          'readMinutes': 11,
          'my': {'name': 'Nizam', 'readingTimeFormatted': '11 min'},
          'rival': {'name': 'Anas', 'readingTimeFormatted': ''},
        },
      ],
    },
  },
};

void main() {
  test('the dashboard answer is traced per timeframe', () {
    final log = _logOf(_body, timeframe: 'weekly');
    final text = log.join('\n');

    expect(text, contains('timeframe=weekly status=200'));
    expect(text, contains('end weekly'));
  });

  test('the pills and the comparison are called out side by side', () {
    final text = _logOf(_body).join('\n');

    // The two numbers that disagree, printed next to each other.
    expect(text, contains('myPositionPercentage=68 competitorPercentage=32'));
    expect(text, contains("comparison.me name=Nizam time='' points=''"));
    expect(
      text,
      contains("comparison.rival name=Labib Al Mahmud time='' points=''"),
    );
  });

  test('each activity entry shows its own two sides', () {
    final text = _logOf(_body).join('\n');

    expect(text, contains('weeklyActivity.days=1'));
    expect(text, contains('monthlyActivity.periods=none'));
    expect(text, contains("entry FRI readMinutes=11"));
    expect(text, contains("my=Nizam/'11 min'"));
    expect(text, contains("rival=Anas/''"));
  });

  test('the whole body follows the summary', () {
    final text = _logOf(_body).join('\n');

    expect(text, contains('----- full body -----'));
    expect(text, contains('"totalReadingTimeFormatted": "3h 45m"'));
  });

  test('an answer with no data object still prints what came back', () {
    final text = _logOf({'success': false, 'message': 'nope'}).join('\n');

    expect(text, contains('no data object'));
    expect(text, contains('"message": "nope"'));
  });

  test('a missing comparison is named rather than passed over', () {
    final text = _logOf({
      'data': {
        'overview': {'myPositionPercentage': 0},
      },
    }).join('\n');

    expect(text, contains('comparison: ABSENT'));
  });

  test('a long body is split so no line is clipped away', () {
    final text = _logOf({
      'data': {
        'overview': {'dailyTargetText': 'x' * 3000},
      },
    }).join('\n');

    expect(text, contains('x' * 700));
    // Every printed line stays inside debugPrint's comfortable width.
    for (final line in text.split('\n')) {
      expect(line.length, lessThanOrEqualTo(720), reason: line);
    }
  });
}
