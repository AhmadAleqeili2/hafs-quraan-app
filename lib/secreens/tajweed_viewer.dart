library tajweed_viewer;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

part '../models/page_models.dart';
part '../widgets/tajweed_viewer/page_frame.dart';
part '../widgets/tajweed_viewer/surah_header_frame.dart';
part '../widgets/tajweed_viewer/responsive_typography.dart';
part '../widgets/tajweed_viewer/page_renderer.dart';
part '../models/viewer_state.dart';
part '../models/fullscreen_state.dart';
part '../services/tajweed_data_service.dart';
part '../controllers/tajweed_viewer_cubit.dart';
part '../controllers/tajweed_fullscreen_cubit.dart';
part '../widgets/tajweed_viewer/viewer_view.dart';

const double kBaseFontSize = 16;

class TajweedViewer extends StatelessWidget {
  const TajweedViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TajweedViewerCubit()..initialize(),
      child: const TajweedViewerView(),
    );
  }
}
