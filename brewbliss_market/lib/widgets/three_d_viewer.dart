import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../core/theme/design_tokens.dart';

class ThreeDViewer extends StatefulWidget {
  const ThreeDViewer({super.key, required this.modelUrl});

  final String modelUrl;

  @override
  State<ThreeDViewer> createState() => _ThreeDViewerState();
}

class _ThreeDViewerState extends State<ThreeDViewer> {
  late final Flutter3DController _controller;

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: AspectRatio(
        aspectRatio: 1,
        child: Flutter3DViewer.network(
          controller: _controller,
          src: widget.modelUrl,
          autoRotate: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
