part of tajweed_viewer;

class TajweedViewerView extends StatelessWidget {
  const TajweedViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TajweedViewerCubit, TajweedViewerState>(
      builder: (context, state) {
        final cubit = context.read<TajweedViewerCubit>();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final Color scaffoldBackground = isDark
            ? const Color(0xFF0F131C)
            : const Color(0xFFF7F3E8);
        final Color accentBorderColor = isDark
            ? const Color(0xFFE2C375)
            : const Color(0xFFC39A3C);
        final Color headerBaseColor = isDark
            ? const Color(0xFF171B24)
            : const Color(0xFFF5EAD1);
        final Color headerAccentColor = isDark
            ? const Color(0xFF1F2532)
            : const Color(0xFFF1E0BB);

        Widget buildBody() {
          if (state.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل الصفحات',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            );
          }
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }
          if (state.pageCount <= 0) {
            return Center(
              child: Text(
                'لا توجد صفحات متاحة',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final bool isScrollMode = state.viewMode == TajweedViewMode.scroll;

          final Widget bodyContent = LayoutBuilder(
            builder: (context, constraints) {
              final shortestSide = constraints.biggest.shortestSide;
              final unit = (shortestSide > 0 ? shortestSide : 400) / 100.0;
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;

              final double topGutter = unit * 4;
              final double headerHorizontalPadding = unit * 5;
              final double fieldRadius = unit * 4;
              final double fieldPaddingH = unit * 4;
              final double fieldPaddingV = unit * 3;
              final double sectionSpacing = unit * 2;
              final double pagerBottomSpacing = unit * 3;
              final double batchIndicatorTopOffset = unit * 2.5;
              final double batchIndicatorPaddingH = unit * 4;
              final double batchIndicatorPaddingV = unit * 2.5;
              final double batchIndicatorRadius = unit * 4;
              final double batchIndicatorSpacing = unit * 2.5;
              final double batchIndicatorLoaderSize = unit * 5;
              final double footerHorizontalPadding = unit * 5;
              final double footerBottomPadding = unit * 5;
              final double suffixIconPaddingH = unit * 1.5;
              final double suffixIconPaddingV = unit;
              final double suffixIconMinExtent = unit * 13;
              final double iconButtonPadding = unit * 3;
              final Color headerShadowColor = colorScheme.shadow.withOpacity(
                isDark ? 0.45 : 0.12,
              );
              final Color batchIndicatorBg = colorScheme.surface.withOpacity(
                isDark ? 0.7 : 0.92,
              );
              final Color batchIndicatorBorder = colorScheme.outline
                  .withOpacity(isDark ? 0.4 : 0.35);

              final dropdownValue =
                  (state.currentPartStartPage != null &&
                      state.parts.any(
                        (part) => part.startPage == state.currentPartStartPage,
                      ))
                  ? state.currentPartStartPage
                  : null;

              final Color scrollDividerColor = accentBorderColor.withOpacity(
                isDark ? 0.5 : 0.35,
              );
              final double scrollDividerThickness = unit * 0.18;
              final int safeScrollIndex = state.pageCount > 0
                  ? math.max(
                      0,
                      math.min(state.pageCount - 1, state.currentPage - 1),
                    )
                  : 0;

              Widget buildPageSurface({
                required int pageIndex,
                required bool showFrame,
                required bool allowInnerScroll,
              }) {
                final part = cubit.partForPage(pageIndex);
                final cached = state.cache[pageIndex];
                final future = cached != null
                    ? Future<TajweedPageData>.value(cached)
                    : cubit.loadPage(pageIndex);

                return FutureBuilder<TajweedPageData>(
                  future: future,
                  initialData: cached,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final page = snapshot.data!;
                      if (page.lines.isEmpty) {
                        return Center(child: Text('Page $pageIndex is empty'));
                      }

                      return TajweedPageView(
                        lines: page.lines,
                        pageIndex: pageIndex,
                        unit: unit,
                        constraints: constraints,
                        partName: part?.name,
                        surahNames: state.surahNames,
                        showFrame: showFrame,
                        allowInnerScroll: allowInnerScroll,
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading page $pageIndex'),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              }

              Widget buildSwipePager() {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  cubit.flushPendingSwipeJump();
                });
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: PageView.builder(
                    key: const ValueKey('swipe-mode'),
                    controller: cubit.pageController,
                    onPageChanged: cubit.onPageChanged,
                    allowImplicitScrolling: true,
                    reverse: true,
                    itemCount: state.pageCount,
                    itemBuilder: (context, index) {
                      final pageIndex = index + 1;
                      return buildPageSurface(
                        pageIndex: pageIndex,
                        showFrame: true,
                        allowInnerScroll: true,
                      );
                    },
                  ),
                );
              }

              Widget buildScrollPager() {
                return ScrollablePositionedList.builder(
                  key: const ValueKey('scroll-mode'),
                  itemCount: state.pageCount,
                  itemScrollController: cubit.scrollListController,
                  itemPositionsListener: cubit.scrollPositionsListener,
                  initialScrollIndex: safeScrollIndex,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: footerBottomPadding,
                    top: unit * 2,
                  ),
                  itemBuilder: (context, index) {
                    final pageIndex = index + 1;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: headerHorizontalPadding,
                            vertical: unit * 1.6,
                          ),
                          child: buildPageSurface(
                            pageIndex: pageIndex,
                            showFrame: false,
                            allowInnerScroll: false,
                          ),
                        ),
                        if (pageIndex < state.pageCount)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: unit * 1.2),
                            child: Divider(
                              thickness: scrollDividerThickness,
                              color: scrollDividerColor,
                              height: 0,
                            ),
                          ),
                      ],
                    );
                  },
                );
              }

              final double modeButtonSize = math.max(unit * 7.2, 44.0);
              final double modeButtonIconSize = math.max(unit * 3.2, 22.0);
              final double modeButtonsSpacing = unit * 4;

              Widget buildModeButton({
                required TajweedViewMode mode,
                required IconData icon,
                required String tooltip,
              }) {
                final bool isActive = state.viewMode == mode;
                final Color background = isActive
                    ? accentBorderColor.withOpacity(isDark ? 0.32 : 0.24)
                    : headerBaseColor.withOpacity(isDark ? 0.78 : 0.9);
                final Color borderColor = isActive
                    ? accentBorderColor.withOpacity(isDark ? 0.9 : 0.8)
                    : colorScheme.outline.withOpacity(isDark ? 0.4 : 0.3);

                return Tooltip(
                  message: tooltip,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: modeButtonSize,
                    height: modeButtonSize,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(modeButtonSize),
                      border: Border.all(color: borderColor, width: unit * 0.2),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: borderColor.withOpacity(
                                  isDark ? 0.55 : 0.35,
                                ),
                                blurRadius: unit * 2.2,
                                offset: Offset(0, unit * 0.6),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(modeButtonSize),
                        onTap: isActive ? null : () => cubit.setViewMode(mode),
                        child: Center(
                          child: Icon(
                            icon,
                            size: modeButtonIconSize,
                            color: isActive
                                ? accentBorderColor
                                : colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              Future<void> showPartPickerSheet() async {
                if (state.parts.isEmpty) return;
                final selectedStartPage = await showModalBottomSheet<int>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: headerBaseColor.withOpacity(
                    isDark ? 0.98 : 1.0,
                  ),
                  builder: (context) {
                    return SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: unit * 3,
                          vertical: unit * 2,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'اختر الجزء',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: unit * 2),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.5,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    final part = state.parts[index];
                                    final bool isSelected =
                                        part.startPage == dropdownValue;
                                    return ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          unit * 2,
                                        ),
                                      ),
                                      tileColor: isSelected
                                          ? accentBorderColor.withOpacity(
                                              isDark ? 0.25 : 0.15,
                                            )
                                          : null,
                                      leading: CircleAvatar(
                                        backgroundColor: accentBorderColor
                                            .withOpacity(isDark ? 0.85 : 0.7),
                                        child: Text('${index + 1}'),
                                      ),
                                      title: Text(
                                        part.name.isEmpty
                                            ? 'جزء ${index + 1}'
                                            : part.name,
                                      ),
                                      subtitle: Text('صفحة ${part.startPage}'),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(part.startPage),
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: unit),
                                  itemCount: state.parts.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (selectedStartPage != null) {
                  cubit.selectPart(selectedStartPage);
                }
              }

              Future<void> showPageJumpSheet() async {
                final controller = TextEditingController(
                  text: cubit.pageInputController.text,
                );
                final targetPage = await showModalBottomSheet<int>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  backgroundColor: headerBaseColor.withOpacity(
                    isDark ? 0.98 : 1.0,
                  ),
                  builder: (context) {
                    final bottomPadding = MediaQuery.of(
                      context,
                    ).viewInsets.bottom;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: unit * 3,
                        right: unit * 3,
                        bottom: bottomPadding + unit * 2,
                        top: unit * 3,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'اذهب إلى صفحة',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: unit * 2),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.go,
                            onSubmitted: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) {
                                Navigator.of(context).pop(parsed);
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              prefixIcon: const Icon(Icons.bookmark_add),
                              hintText: 'رقم الصفحة (1 - ${state.pageCount})',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  fieldRadius,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: fieldPaddingH,
                                vertical: fieldPaddingV,
                              ),
                            ),
                          ),
                          SizedBox(height: unit * 2),
                          FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('انتقال'),
                            onPressed: () {
                              final parsed = int.tryParse(controller.text);
                              if (parsed != null) {
                                Navigator.of(context).pop(parsed);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (targetPage != null) {
                  cubit.handlePageInput(targetPage.toString());
                }
              }

              Widget buildCircularActionButton({
                required IconData icon,
                required String tooltip,
                required VoidCallback? onPressed,
              }) {
                final bool enabled = onPressed != null;
                final Color background = enabled
                    ? accentBorderColor.withOpacity(isDark ? 0.35 : 0.25)
                    : colorScheme.onSurface.withOpacity(0.08);
                final Color borderColor = enabled
                    ? accentBorderColor.withOpacity(isDark ? 0.9 : 0.8)
                    : colorScheme.onSurface.withOpacity(0.2);
                final Color iconColor = enabled
                    ? accentBorderColor
                    : colorScheme.onSurface.withOpacity(0.4);

                return Tooltip(
                  message: tooltip,
                  waitDuration: const Duration(milliseconds: 400),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: modeButtonSize,
                    height: modeButtonSize,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(modeButtonSize),
                      border: Border.all(color: borderColor, width: unit * 0.2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(modeButtonSize),
                        onTap: enabled ? onPressed : null,
                        child: Center(
                          child: Icon(
                            icon,
                            size: modeButtonIconSize,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final Wrap bottomControls = Wrap(
                spacing: modeButtonsSpacing,
                runSpacing: unit * 1.4,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildCircularActionButton(
                    icon: Icons.auto_stories,
                    tooltip: 'اختيار الجزء',
                    onPressed: state.parts.isEmpty ? null : showPartPickerSheet,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildModeButton(
                        mode: TajweedViewMode.swipe,
                        icon: Icons.swipe_left_alt,
                        tooltip: 'وضع السحب التقليدي',
                      ),
                      SizedBox(width: modeButtonsSpacing),
                      buildModeButton(
                        mode: TajweedViewMode.scroll,
                        icon: Icons.view_agenda_outlined,
                        tooltip: 'وضع التمرير العمودي',
                      ),
                    ],
                  ),
                  buildCircularActionButton(
                    icon: Icons.bookmark_add_outlined,
                    tooltip: 'اذهب للصفحة',
                    onPressed: showPageJumpSheet,
                  ),
                ],
              );

              return Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                  SizedBox(height: topGutter * 0.5),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isScrollMode ? buildScrollPager() : buildSwipePager(),
                        if (state.isBatchLoading)
                          Positioned(
                            top: batchIndicatorTopOffset,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              ignoring: true,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: batchIndicatorPaddingH,
                                    vertical: batchIndicatorPaddingV,
                                  ),
                                  decoration: BoxDecoration(
                                    color: batchIndicatorBg,
                                    borderRadius: BorderRadius.circular(
                                      batchIndicatorRadius,
                                    ),
                                    border: Border.all(
                                      color: batchIndicatorBorder,
                                      width: unit * 0.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: batchIndicatorLoaderSize,
                                        height: batchIndicatorLoaderSize,
                                        child: CircularProgressIndicator(
                                          strokeWidth: unit * 0.8,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: batchIndicatorSpacing),
                                      Text(
                                        'جاري تحميل المزيد من الصفحات...',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: footerHorizontalPadding,
                      vertical: unit * 1.2,
                    ),
                    child: bottomControls,
                  ),
                  SizedBox(height: pagerBottomSpacing),
                ],
              );
            },
          );

          return _PinchZoomViewport(
            child: bodyContent,
            allowVerticalPan: !isScrollMode,
          );
        }

        return Scaffold(backgroundColor: scaffoldBackground, body: buildBody());
      },
    );
  }
}

class _PinchZoomViewport extends StatefulWidget {
  const _PinchZoomViewport({
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.allowVerticalPan = true,
  }) : assert(minScale > 0),
       assert(maxScale >= minScale);

  final Widget child;
  final double minScale;
  final double maxScale;
  final bool allowVerticalPan;

  @override
  State<_PinchZoomViewport> createState() => _PinchZoomViewportState();
}

class _PinchZoomViewportState extends State<_PinchZoomViewport> {
  final Map<int, Offset> _pointerPositions = <int, Offset>{};
  double _scale = 1.0;
  double _baseScale = 1.0;
  double? _initialDistance;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;
  int? _primaryPointer;
  Offset? _lastPrimaryPosition;
  bool _isDragging = false;

  bool get _isPinching => _pointerPositions.length >= 2;
  bool get _isZoomed => _scale > widget.minScale + 0.001;
  bool get _shouldAbsorb => _isPinching || (_isZoomed && _isDragging);
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  void _onPointerDown(PointerDownEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;
    if (_pointerPositions.length == 1) {
      _primaryPointer = event.pointer;
      _lastPrimaryPosition = event.localPosition;
    } else if (_pointerPositions.length == 2) {
      _initializePinchGesture();
      setState(() {});
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointerPositions.containsKey(event.pointer)) return;
    _pointerPositions[event.pointer] = event.localPosition;

    if (_isPinching) {
      _updateScaleFromPinch();
      _updateOffsetFromFocalChange();
      return;
    }

    if (_isZoomed && _primaryPointer == event.pointer) {
      _dragWithPrimaryPointer(event.localPosition);
    } else if (_primaryPointer == event.pointer) {
      _lastPrimaryPosition = event.localPosition;
    }
  }

  void _onPointerEnd(PointerEvent event) {
    final bool wasPinching = _isPinching;
    _pointerPositions.remove(event.pointer);
    if (_primaryPointer == event.pointer) {
      _primaryPointer = _pointerPositions.isNotEmpty
          ? _pointerPositions.keys.first
          : null;
      _lastPrimaryPosition = _primaryPointer != null
          ? _pointerPositions[_primaryPointer!]
          : null;
    }

    if (_isPinching) {
      final bool resetDragging = _initializePinchGesture();
      if (!wasPinching || resetDragging) {
        setState(() {});
      }
    } else {
      _initialDistance = null;
      _lastFocalPoint = null;
      _baseScale = _scale;
    }

    if (!_isZoomed && (_scale != widget.minScale || _offset != Offset.zero)) {
      setState(() {
        _scale = widget.minScale;
        _offset = Offset.zero;
      });
      _isDragging = false;
    } else if (wasPinching && !_isPinching) {
      setState(() {});
    }

    if (_pointerPositions.isEmpty && _isDragging) {
      setState(() => _isDragging = false);
    }
  }

  bool _initializePinchGesture() {
    _initialDistance = _currentDistance();
    _baseScale = _scale;
    _lastFocalPoint = _currentFocalPoint();
    final bool resetDragging = _isDragging;
    _isDragging = false;
    return resetDragging;
  }

  void _dragWithPrimaryPointer(Offset position) {
    if (_lastPrimaryPosition == null) {
      _lastPrimaryPosition = position;
      return;
    }
    Offset delta = position - _lastPrimaryPosition!;
    _lastPrimaryPosition = position;
    if (!widget.allowVerticalPan) {
      delta = Offset(delta.dx, 0);
    }
    if (delta == Offset.zero) return;

    final Offset nextOffset = _clampOffset(_offset + delta);
    if (nextOffset == _offset) {
      if (_isDragging) {
        setState(() => _isDragging = false);
      }
      return;
    }

    setState(() {
      _offset = nextOffset;
      _isDragging = true;
    });
  }

  void _updateScaleFromPinch() {
    if (_initialDistance == null || _initialDistance! <= 0) return;
    final double? distance = _currentDistance();
    if (distance == null || distance <= 0) return;
    final double desiredScale = (_baseScale * distance / _initialDistance!)
        .clamp(widget.minScale, widget.maxScale);
    if ((desiredScale - _scale).abs() <= 0.001) return;

    final Offset? focal = _currentFocalPoint();
    setState(() {
      final double previousScale = _scale;
      _scale = desiredScale;
      if (focal != null) {
        final Offset focalFromCenter = _centeredWithinWidget(focal);
        _offset = _clampOffset(
          _offset + focalFromCenter * (previousScale - _scale),
        );
      }
    });
  }

  void _updateOffsetFromFocalChange() {
    final Offset? focal = _currentFocalPoint();
    if (focal == null) return;
    if (_lastFocalPoint == null) {
      _lastFocalPoint = focal;
      return;
    }
    final Offset delta = focal - _lastFocalPoint!;
    if (delta == Offset.zero) return;
    _lastFocalPoint = focal;
    setState(() {
      _offset = _clampOffset(_offset + delta);
    });
  }

  double? _currentDistance() {
    if (_pointerPositions.length < 2) return null;
    final iterator = _pointerPositions.values.iterator;
    if (!iterator.moveNext()) return null;
    final Offset first = iterator.current;
    if (!iterator.moveNext()) return null;
    final Offset second = iterator.current;
    return (first - second).distance;
  }

  Offset? _currentFocalPoint() {
    if (_pointerPositions.isEmpty) return null;
    Offset sum = Offset.zero;
    for (final entry in _pointerPositions.values) {
      sum += entry;
    }
    return sum / _pointerPositions.length.toDouble();
  }

  Offset _centeredWithinWidget(Offset point) {
    final RenderBox? box = _renderBox;
    if (box == null || !box.hasSize) return point;
    final Size size = box.size;
    return point - Offset(size.width / 2, size.height / 2);
  }

  Offset _clampOffset(Offset value) {
    final RenderBox? box = _renderBox;
    if (box == null || !box.hasSize) return value;
    final Size size = box.size;
    if (size.isEmpty) return value;
    final double horizontalLimit = (size.width * (_scale - 1)) / 2;
    final double verticalLimit = (size.height * (_scale - 1)) / 2;
    if (horizontalLimit <= 0 && verticalLimit <= 0) {
      return Offset.zero;
    }
    final double dx = value.dx.clamp(-horizontalLimit, horizontalLimit);
    final double dy = value.dy.clamp(-verticalLimit, verticalLimit);
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final Widget transformedChild = Transform.translate(
      offset: _offset,
      child: Transform.scale(
        scale: _scale,
        alignment: Alignment.center,
        child: widget.child,
      ),
    );

    final Widget gatedChild = AbsorbPointer(
      absorbing: _shouldAbsorb,
      child: transformedChild,
    );

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: ClipRect(child: gatedChild),
    );
  }
}

class _TajweedFullscreenView extends StatelessWidget {
  const _TajweedFullscreenView({
    required this.initialPage,
    required this.pageCount,
    required this.loadPage,
    required this.partResolver,
    required this.surahNames,
    required this.cache,
  });

  final int initialPage;
  final int pageCount;
  final Future<TajweedPageData> Function(int) loadPage;
  final QuranPart? Function(int) partResolver;
  final Map<int, String> surahNames;
  final Map<int, TajweedPageData> cache;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TajweedFullscreenCubit(
        initialPage: initialPage,
        pageCount: pageCount,
        loadPage: loadPage,
        partResolver: partResolver,
        surahNames: surahNames,
        cache: cache,
      ),
      child: const _TajweedFullscreenBody(),
    );
  }
}

class _TajweedFullscreenBody extends StatelessWidget {
  const _TajweedFullscreenBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TajweedFullscreenCubit>();
    final mediaSize = MediaQuery.of(context).size;
    final shortestSide = math.min(mediaSize.width, mediaSize.height);
    final overlayUnit = (shortestSide > 0 ? shortestSide : 400) / 100.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final Color fullscreenBackground = isDark
        ? const Color(0xFF05080F)
        : const Color(0xFFFFFCF6);
    final Color overlayPanelColor = colorScheme.surfaceVariant.withOpacity(
      isDark ? 0.28 : 0.85,
    );
    final Color overlayBorderColor = colorScheme.onSurface.withOpacity(
      isDark ? 0.35 : 0.25,
    );
    final Color overlayIconBg = colorScheme.surface.withOpacity(
      isDark ? 0.45 : 0.8,
    );

    return BlocBuilder<TajweedFullscreenCubit, TajweedFullscreenState>(
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(state.currentPage);
            return false;
          },
          child: Scaffold(
            backgroundColor: fullscreenBackground,
            appBar: AppBar(),
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: PageView.builder(
                        controller: cubit.controller,
                        onPageChanged: cubit.onPageChanged,
                        reverse: true,
                        itemCount: cubit.pageCount,
                        itemBuilder: (context, index) {
                          final pageIndex = index + 1;
                          final cached = cubit.cache[pageIndex];
                          final future = cached != null
                              ? Future<TajweedPageData>.value(cached)
                              : cubit.loadPage(pageIndex);

                        return FutureBuilder<TajweedPageData>(
                          future: future,
                          initialData: cached,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final page = snapshot.data!;
                              if (page.lines.isEmpty) {
                                return Center(
                                  child: Text(
                                    'هذه الصفحة فارغة',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        isDark ? 0.7 : 0.6,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final shortest =
                                      constraints.biggest.shortestSide;
                                  final u =
                                      (shortest > 0 ? shortest : 400) / 100.0;
                                  final Color outerBorder = colorScheme.primary
                                      .withOpacity(isDark ? 0.8 : 0.7);
                                  final Color middleBorder = colorScheme
                                      .tertiary
                                      .withOpacity(isDark ? 0.9 : 0.8);
                                  final Color innerBorder = colorScheme.primary
                                      .withOpacity(isDark ? 0.6 : 0.5);

                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3 * u,
                                        vertical: 3 * u,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 0.5 * u,
                                            color: outerBorder,
                                          ),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 1 * u,
                                              color: middleBorder,
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 0.5 * u,
                                                color: innerBorder,
                                              ),
                                            ),
                                            child: TajweedPageView(
                                              lines: page.lines,
                                              pageIndex: pageIndex,
                                              unit: u,
                                              constraints: constraints,
                                              partName: cubit
                                                  .partResolver(pageIndex)
                                                  ?.name,
                                              surahNames: cubit.surahNames,
                                              showFrame: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'حدث خطأ أثناء تحميل الصفحة $pageIndex',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      isDark ? 0.8 : 0.7,
                                    ),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ),
                ),
                  Positioned(
                    top: overlayUnit * 4,
                    left: overlayUnit * 4,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: overlayIconBg,
                        foregroundColor: colorScheme.onSurface,
                        padding: EdgeInsets.all(overlayUnit * 1.2),
                        iconSize: overlayUnit * 5.5,
                      ),
                      onPressed: () =>
                          Navigator.of(context).pop(state.currentPage),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Positioned(
                    bottom: overlayUnit * 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.5 * overlayUnit,
                          vertical: 3 * overlayUnit,
                        ),
                        decoration: BoxDecoration(
                          color: overlayPanelColor,
                          borderRadius: BorderRadius.circular(overlayUnit * 6),
                          border: Border.all(color: overlayBorderColor),
                        ),
                        child: Text(
                          'الصفحة ${state.currentPage} / ${cubit.pageCount}',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
