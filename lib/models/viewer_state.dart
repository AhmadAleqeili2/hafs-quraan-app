part of tajweed_viewer;

enum TajweedViewerStatus { initial, loading, ready, failure }

enum TajweedViewMode { swipe, scroll }

class TajweedViewerState {
  const TajweedViewerState({
    this.pageCount = 0,
    this.currentPage = 1,
    this.currentPartStartPage,
    this.cache = const <int, TajweedPageData>{},
    this.parts = const [],
    this.surahNames = const {},
    this.status = TajweedViewerStatus.initial,
    this.errorMessage,
    this.isBatchLoading = false,
    this.viewMode = TajweedViewMode.swipe,
  });

  final int pageCount;
  final int currentPage;
  final int? currentPartStartPage;
  final Map<int, TajweedPageData> cache;
  final List<QuranPart> parts;
  final Map<int, String> surahNames;
  final TajweedViewerStatus status;
  final String? errorMessage;
  final bool isBatchLoading;
  final TajweedViewMode viewMode;

  bool get isLoading =>
      status == TajweedViewerStatus.initial ||
      status == TajweedViewerStatus.loading;

  bool get hasError => status == TajweedViewerStatus.failure;

  static const Object _unset = Object();

  TajweedViewerState copyWith({
    int? pageCount,
    int? currentPage,
    Object? currentPartStartPage = _unset,
    Map<int, TajweedPageData>? cache,
    List<QuranPart>? parts,
    Map<int, String>? surahNames,
    TajweedViewerStatus? status,
    String? errorMessage,
    bool? isBatchLoading,
    TajweedViewMode? viewMode,
  }) {
    return TajweedViewerState(
      pageCount: pageCount ?? this.pageCount,
      currentPage: currentPage ?? this.currentPage,
      currentPartStartPage: currentPartStartPage == _unset
          ? this.currentPartStartPage
          : currentPartStartPage as int?,
      cache: cache ?? this.cache,
      parts: parts ?? this.parts,
      surahNames: surahNames ?? this.surahNames,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isBatchLoading: isBatchLoading ?? this.isBatchLoading,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}
