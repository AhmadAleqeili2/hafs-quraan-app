part of tajweed_viewer;

class TajweedFullscreenCubit extends Cubit<TajweedFullscreenState> {
  TajweedFullscreenCubit({
    required int initialPage,
    required this.pageCount,
    required this.loadPage,
    required this.partResolver,
    required this.surahNames,
    required this.cache,
  }) : controller = PageController(initialPage: initialPage - 1),
       super(TajweedFullscreenState(currentPage: initialPage));

  final PageController controller;
  final int pageCount;
  final Future<TajweedPageData> Function(int) loadPage;
  final QuranPart? Function(int) partResolver;
  final Map<int, String> surahNames;
  final Map<int, TajweedPageData> cache;

  void onPageChanged(int index) {
    emit(state.copyWith(currentPage: index + 1));
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
