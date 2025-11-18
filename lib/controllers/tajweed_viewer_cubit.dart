part of tajweed_viewer;

class TajweedViewerCubit extends Cubit<TajweedViewerState> {
  TajweedViewerCubit({TajweedDataService? dataService})
    : _cache = <int, TajweedPageData>{},
      _dataService = dataService ?? const TajweedDataService(),
      pageController = PageController(),
      pageInputController = TextEditingController(text: '1'),
      scrollListController = ItemScrollController(),
      scrollPositionsListener = ItemPositionsListener.create(),
      super(const TajweedViewerState()) {
    scrollPositionsListener.itemPositions.addListener(
      _handleScrollPositionsChanged,
    );
  }

  static const int _prefetchBatchSize = 10;

  final PageController pageController;
  final TextEditingController pageInputController;
  final ItemScrollController scrollListController;
  final ItemPositionsListener scrollPositionsListener;
  final Map<int, TajweedPageData> _cache;
  final TajweedDataService _dataService;
  Future<void>? _batchLoadingFuture;
  int? _pendingScrollIndex;
  int? _pendingSwipeIndex;

  Map<int, TajweedPageData> get cache => _cache;

  Future<void> initialize() async {
    emit(
      state.copyWith(
        status: TajweedViewerStatus.loading,
        isBatchLoading: false,
        lineSpacingReady: false,
      ),
    );
    try {
      await LayoutMeasurementCache.instance.ensureInitialized();
      final pageCount = await _dataService.loadPageCount();
      final clampedCurrent = math.max(
        1,
        math.min(state.currentPage, pageCount),
      );
      pageInputController.text = clampedCurrent.toString();

      final parts = await _dataService.loadParts();
      final surahNames = await _dataService.loadSurahNames();
      final partStart = _partForPage(clampedCurrent, parts)?.startPage;

      emit(
        state.copyWith(
          status: TajweedViewerStatus.loading,
          pageCount: pageCount,
          currentPage: clampedCurrent,
          currentPartStartPage: partStart,
          parts: List<QuranPart>.unmodifiable(parts),
          surahNames: Map<int, String>.unmodifiable(surahNames),
        ),
      );

      final initialBatchStart = _batchStartForPage(clampedCurrent);
      final initialBatchEnd = _batchEndForStart(initialBatchStart, pageCount);
      await _loadBatch(initialBatchStart, initialBatchEnd);

      emit(
        state.copyWith(
          status: TajweedViewerStatus.ready,
          isBatchLoading: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TajweedViewerStatus.failure,
          errorMessage: error.toString(),
          isBatchLoading: false,
        ),
      );
    }
  }

  Future<TajweedPageData> loadPage(int page) async {
    final cached = _cache[page];
    if (cached != null) {
      return cached;
    }
    await _ensureBatchLoadedForPage(page);

    final loaded = _cache[page];
    if (loaded != null) {
      return loaded;
    }

    final pageData = await _dataService.loadPage(page);
    _cache[page] = pageData;
    emit(state.copyWith(cache: Map<int, TajweedPageData>.unmodifiable(_cache)));
    return pageData;
  }

  QuranPart? partForPage(int page) => _partForPage(page);

  QuranPart? _partForPage(int page, [List<QuranPart>? override]) {
    final parts = override ?? state.parts;
    for (final part in parts) {
      if (page >= part.startPage && page <= part.endPage) {
        return part;
      }
    }
    return null;
  }

  void setViewMode(TajweedViewMode mode) {
    if (state.viewMode == mode) return;
    final targetPage = state.currentPage;
    _pendingScrollIndex = null;
    _pendingSwipeIndex = null;
    emit(state.copyWith(viewMode: mode));
    if (mode == TajweedViewMode.swipe) {
      _jumpToSwipeIndex(targetPage - 1);
    } else {
      _jumpToScrollIndex(targetPage - 1);
    }
  }

  void toggleViewMode() {
    final next = state.viewMode == TajweedViewMode.swipe
        ? TajweedViewMode.scroll
        : TajweedViewMode.swipe;
    setViewMode(next);
  }

  void onPageChanged(int index) {
    _updateCurrentPage(index + 1);
  }

  void _updateCurrentPage(int page) {
    final int maxPage = state.pageCount > 0 ? state.pageCount : page;
    final int target = page.clamp(1, maxPage).toInt();
    pageInputController.text = target.toString();
    final partStart = _partForPage(target)?.startPage;
    if (target == state.currentPage &&
        partStart == state.currentPartStartPage) {
      return;
    }
    emit(state.copyWith(currentPage: target, currentPartStartPage: partStart));
  }

  void _jumpToScrollIndex(int index) {
    if (index < 0) return;
    if (scrollListController.isAttached) {
      scrollListController.jumpTo(index: index);
      _pendingScrollIndex = null;
    } else {
      _pendingScrollIndex = index;
    }
  }

  void _jumpToSwipeIndex(int index) {
    if (index < 0) return;
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
      _pendingSwipeIndex = null;
    } else {
      _pendingSwipeIndex = index;
    }
  }

  void _handleScrollPositionsChanged() {
    if (state.viewMode != TajweedViewMode.scroll) {
      return;
    }
    if (_pendingScrollIndex != null && scrollListController.isAttached) {
      final target = _pendingScrollIndex!;
      _pendingScrollIndex = null;
      scrollListController.jumpTo(index: target);
      return;
    }
    final positions = scrollPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final visible = positions
        .where((pos) => pos.itemTrailingEdge > 0 && pos.itemLeadingEdge < 1)
        .toList();
    if (visible.isEmpty) return;

    double coverageFor(ItemPosition pos) {
      final double start = pos.itemLeadingEdge.clamp(0.0, 1.0);
      final double end = pos.itemTrailingEdge.clamp(0.0, 1.0);
      return (end - start).clamp(0.0, 1.0);
    }

    visible.sort((a, b) {
      final double coverageA = coverageFor(a);
      final double coverageB = coverageFor(b);
      final int coverageDiff = coverageB.compareTo(coverageA);
      if (coverageDiff != 0) {
        return coverageDiff;
      }
      // Fallback to whichever is closer to the viewport center.
      final double aCenterDistance =
          (((a.itemLeadingEdge + a.itemTrailingEdge) / 2) - 0.5).abs();
      final double bCenterDistance =
          (((b.itemLeadingEdge + b.itemTrailingEdge) / 2) - 0.5).abs();
      return aCenterDistance.abs().compareTo(bCenterDistance.abs());
    });

    final bestIndex = visible.first.index;
    _updateCurrentPage(bestIndex + 1);
  }

  void flushPendingSwipeJump() {
    if (_pendingSwipeIndex != null && pageController.hasClients) {
      final target = _pendingSwipeIndex!;
      _pendingSwipeIndex = null;
      pageController.jumpToPage(target);
    }
  }

  void handlePageInput(String value) {
    final page = int.tryParse(value);
    if (page == null) return;
    jumpToPage(page);
  }

  void jumpToPage(int page) {
    if (state.pageCount <= 0) return;
    final target = page.clamp(1, state.pageCount).toInt();
    if (state.viewMode == TajweedViewMode.swipe) {
      _jumpToSwipeIndex(target - 1);
    } else {
      _jumpToScrollIndex(target - 1);
    }
    _updateCurrentPage(target);
  }

  void selectPart(int? startPage) {
    if (startPage == null) return;
    pageInputController.text = startPage.toString();
    emit(state.copyWith(currentPartStartPage: startPage));
    jumpToPage(startPage);
  }

  Future<void> openFullscreen(BuildContext context) async {
    if (state.pageCount <= 0) return;
    final selectedPage = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => _TajweedFullscreenView(
          initialPage: state.currentPage,
          pageCount: state.pageCount,
          loadPage: loadPage,
          partResolver: partForPage,
          surahNames: state.surahNames,
          cache: _cache,
        ),
        fullscreenDialog: true,
      ),
    );
    if (selectedPage != null) {
      jumpToPage(selectedPage);
    }
  }

  @override
  Future<void> close() {
    scrollPositionsListener.itemPositions.removeListener(
      _handleScrollPositionsChanged,
    );
    pageController.dispose();
    pageInputController.dispose();
    return super.close();
  }

  void markLineSpacingReady() {
    if (state.lineSpacingReady) return;
    emit(state.copyWith(lineSpacingReady: true));
  }

  int _batchStartForPage(int page) {
    if (page <= 0) return 1;
    final zeroBased = page - 1;
    final batchIndex = zeroBased ~/ _prefetchBatchSize;
    return batchIndex * _prefetchBatchSize + 1;
  }

  int _batchEndForStart(int startPage, int totalPages) {
    if (totalPages <= 0) {
      return startPage;
    }
    return math.min(totalPages, startPage + _prefetchBatchSize - 1);
  }

  Future<void> _ensureBatchLoadedForPage(int page) async {
    if (state.pageCount <= 0) return;
    final batchStart = _batchStartForPage(page);
    final batchEnd = _batchEndForStart(batchStart, state.pageCount);
    if (_isRangeCached(batchStart, batchEnd)) {
      return;
    }

    if (_batchLoadingFuture != null) {
      try {
        await _batchLoadingFuture;
      } catch (_) {
        // Previous batch load failed; allow new attempt below.
      }
      if (_isRangeCached(batchStart, batchEnd)) {
        return;
      }
    }

    _batchLoadingFuture = _loadBatch(batchStart, batchEnd);
    try {
      await _batchLoadingFuture;
    } finally {
      _batchLoadingFuture = null;
    }
  }

  Future<void> _loadBatch(int startPage, int endPage) async {
    if (startPage > endPage) return;
    emit(state.copyWith(isBatchLoading: true));
    try {
      var didChange = false;
      for (var page = startPage; page <= endPage; page++) {
        if (_cache.containsKey(page)) {
          continue;
        }
        final pageData = await _dataService.loadPage(page);
        _cache[page] = pageData;
        didChange = true;
      }
      if (didChange) {
        emit(
          state.copyWith(cache: Map<int, TajweedPageData>.unmodifiable(_cache)),
        );
      }
    } finally {
      emit(state.copyWith(isBatchLoading: false));
    }
  }

  bool _isRangeCached(int startPage, int endPage) {
    if (startPage > endPage) {
      return true;
    }
    for (var page = startPage; page <= endPage; page++) {
      if (!_cache.containsKey(page)) {
        return false;
      }
    }
    return true;
  }
}
