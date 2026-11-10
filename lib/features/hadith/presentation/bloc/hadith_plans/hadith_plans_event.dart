abstract class HadithPlansEvent {
  const HadithPlansEvent();
}

/// Loads (or reloads) the first page of plans; also the retry after a
/// failure, and what runs after a plan has been created.
class LoadHadithPlans extends HadithPlansEvent {
  const LoadHadithPlans();
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithPlans extends HadithPlansEvent {
  const LoadMoreHadithPlans();
}
