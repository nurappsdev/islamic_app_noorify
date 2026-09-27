import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';

/// Quiz dashboard and comparison responses page their `days`; the totals
/// always cover the whole range. These load every page the server's `meta`
/// announces and merge the days, so a chart can show the full range.
typedef QuizPageLoader<T> =
    Future<Either<Failure, T>> Function(QuizDashboardFilter filter);

/// A safety stop: the API caps a range at 365 days, so a well-behaved
/// `totalPage` never gets near this.
const _maxPages = 400;

Future<Either<Failure, QuizDashboardData>> loadAllDashboardPages(
  QuizPageLoader<QuizDashboardData> load,
  QuizDashboardFilter filter,
) async {
  var result = await load(filter);
  var merged = result.fold((_) => null, (data) => data);
  if (merged == null) return result;
  while (merged!.meta.hasMore && merged.meta.page < _maxPages) {
    result = await load(filter.copyWith(page: merged.meta.page + 1));
    final next = result.fold((_) => null, (data) => data);
    // A later page failing leaves the range incomplete; report it.
    if (next == null) return result;
    merged = mergeDashboardPages(merged, next);
  }
  return Right(merged);
}

Future<Either<Failure, QuizComparison>> loadAllComparisonPages(
  QuizPageLoader<QuizComparison> load,
  QuizComparisonFilter filter,
) async {
  var result = await load(filter);
  var merged = result.fold((_) => null, (data) => data);
  if (merged == null) return result;
  while (merged!.meta.hasMore && merged.meta.page < _maxPages) {
    result = await load(filter.copyWith(page: merged.meta.page + 1));
    final next = result.fold((_) => null, (data) => data);
    if (next == null) return result;
    merged = QuizComparison(
      from: merged.from,
      to: merged.to,
      period: merged.period,
      comparedWith: merged.comparedWith,
      // The same users on every page; their days are joined by `key`.
      users: [
        for (final user in merged.users)
          _mergeUser(user, next.users.where((u) => u.key == user.key)),
      ],
      difference: merged.difference,
      meta: next.meta,
    );
  }
  return Right(merged);
}

QuizComparedUser _mergeUser(
  QuizComparedUser user,
  Iterable<QuizComparedUser> nextPage,
) {
  if (nextPage.isEmpty) return user;
  return QuizComparedUser(
    key: user.key,
    rank: user.rank,
    isCurrentUser: user.isCurrentUser,
    userId: user.userId,
    name: user.name,
    avatarUrl: user.avatarUrl,
    totalPoints: user.totalPoints,
    dashboard: mergeDashboardPages(user.dashboard, nextPage.first.dashboard),
  );
}

/// [first]'s days followed by [next]'s, with [next]'s pagination.
QuizDashboardData mergeDashboardPages(
  QuizDashboardData first,
  QuizDashboardData next,
) => QuizDashboardData(
  from: first.from,
  to: first.to,
  period: first.period,
  days: [...first.days, ...next.days],
  totals: first.totals,
  meta: next.meta,
);
