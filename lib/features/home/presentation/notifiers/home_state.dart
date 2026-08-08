enum GreetingPeriod { morning, afternoon, evening }

class HomeState {
  final GreetingPeriod greeting;
  final bool isRefreshing;
  final int totalRecordings;
  final double totalDuration;
  final int unclassifiedCount;

  const HomeState({
    this.greeting = GreetingPeriod.morning,
    this.isRefreshing = false,
    this.totalRecordings = 0,
    this.totalDuration = 0.0,
    this.unclassifiedCount = 0,
  });

  HomeState copyWith({
    GreetingPeriod? greeting,
    bool? isRefreshing,
    int? totalRecordings,
    double? totalDuration,
    int? unclassifiedCount,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      totalRecordings: totalRecordings ?? this.totalRecordings,
      totalDuration: totalDuration ?? this.totalDuration,
      unclassifiedCount: unclassifiedCount ?? this.unclassifiedCount,
    );
  }
}
