part of tajweed_viewer;

class TajweedFullscreenState {
  const TajweedFullscreenState({required this.currentPage});

  final int currentPage;

  TajweedFullscreenState copyWith({int? currentPage}) {
    return TajweedFullscreenState(currentPage: currentPage ?? this.currentPage);
  }
}
