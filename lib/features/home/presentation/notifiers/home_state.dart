enum GreetingPeriod { morning, afternoon, evening }

class HomeState {
  final int localPendingCount;
  final double localPendingDuration;
  final GreetingPeriod greeting;
  final bool isRefreshing;
  final int totalRecordings;
  final double totalDuration;

  const HomeState({
    this.localPendingCount = 0,
    this.localPendingDuration = 0,
    this.greeting = GreetingPeriod.morning,
    this.isRefreshing = false,
    this.totalRecordings = 0,
    this.totalDuration = 0.0,
  });

  HomeState copyWith({
    int? localPendingCount,
    double? localPendingDuration,
    GreetingPeriod? greeting,
    bool? isRefreshing,
    int? totalRecordings,
    double? totalDuration,
  }) {
    return HomeState(
      localPendingCount: localPendingCount ?? this.localPendingCount,
      localPendingDuration: localPendingDuration ?? this.localPendingDuration,
      greeting: greeting ?? this.greeting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      totalRecordings: totalRecordings ?? this.totalRecordings,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}
