import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/semantics.dart';

class ThreeDViewer extends StatefulWidget {
  const ThreeDViewer({
    super.key,
    required this.modelUrl,
    this.fallbackImage,
    this.semanticsLabel,
  });

  final String modelUrl;
  final String? fallbackImage;
  final String? semanticsLabel;

  @override
  State<ThreeDViewer> createState() => _ThreeDViewerState();
}

class _ThreeDViewerState extends State<ThreeDViewer> {
  late final Flutter3DController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: DecoratedBox(
        decoration: BoxDecoration(color: surface),
        child: AspectRatio(
          aspectRatio: 1,
          child: _hasError && widget.fallbackImage != null
              ? Image.network(widget.fallbackImage!, fit: BoxFit.cover)
              : Flutter3DViewer.network(
                  controller: _controller,
                  src: widget.modelUrl,
                  autoRotate: true,
                  backgroundColor: surface,
                  onError: () {
                    if (mounted) {
                      setState(() => _hasError = true);
                    }
                  },
                ),
        ),
      ),
    );

    return SemanticsHelper.labeled(
      label: widget.semanticsLabel ?? '3D item preview',
      child: child
          .animate()
          .scale(begin: 0.96, end: 1.03, curve: Curves.easeOut, duration: 600.ms),
    );
  }
}
