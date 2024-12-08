// ignore_for_file: use_super_parameters, prefer_const_constructors_in_immutables, unnecessary_import

import 'dart:ui';
import 'package:flutter/material.dart' ;
import '../models/drawing_mode.dart';
import '../models/sketch.dart';

class DrawingCanvas extends StatelessWidget {
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<bool> filled;

  DrawingCanvas({
    Key? key,
    required this.height,
    required this.width,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.sideBarController,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildAllPaths(),
        buildCurrentPath(context),
      ],
    );
  }

  Widget buildAllPaths() {
    return ValueListenableBuilder<List<Sketch>>(
      valueListenable: allSketches,
      builder: (context, sketches, _) {
        return RepaintBoundary(
          child: SizedBox(
            height: height,
            width: width,
            child: CustomPaint(
              painter: SketchPainter(sketches: sketches),
            ),
          ),
        );
      },
    );
  }

  Widget buildCurrentPath(BuildContext context) {
    return ValueListenableBuilder<Sketch?>(
      valueListenable: currentSketch,
      builder: (context, sketch, _) {
        return Listener(
          onPointerDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final offset = box.globalToLocal(details.position);

            currentSketch.value = Sketch(
              points: [offset],
              color: drawingMode.value == DrawingMode.eraser
                  ? Color(0xfff2f3f7)
                  : selectedColor.value,
              size: drawingMode.value == DrawingMode.eraser
                  ? eraserSize.value
                  : strokeSize.value,
              type: () {
                switch (drawingMode.value) {
                  case DrawingMode.line:
                    return SketchType.line;
                  case DrawingMode.circle:
                    return SketchType.circle;
                  case DrawingMode.square:
                    return SketchType.rectangle;
                  default:
                    return SketchType.scribble;
                }
              }(),
            );
          },
          onPointerMove: (details) {
            final box = context.findRenderObject() as RenderBox;
            final offset = box.globalToLocal(details.position);

            final points = List<Offset>.from(currentSketch.value?.points ?? [])
              ..add(offset);
            currentSketch.value = Sketch(
              points: points,
              color: drawingMode.value == DrawingMode.eraser
                  ? const Color(0xfff2f3f7)
                  : selectedColor.value,
              size: drawingMode.value == DrawingMode.eraser
                  ? eraserSize.value
                  : strokeSize.value,
              type: () {
                switch (drawingMode.value) {
                  case DrawingMode.line:
                    return SketchType.line;
                  case DrawingMode.circle:
                    return SketchType.circle;
                  case DrawingMode.square:
                    return SketchType.rectangle;
                  default:
                    return SketchType.scribble;
                }
              }(),
            );
          },
          onPointerUp: (details) {
            allSketches.value = List<Sketch>.from(allSketches.value)
              ..add(currentSketch.value!);
          },
          child: RepaintBoundary(
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketch == null ? [] : [sketch],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;

  SketchPainter({required this.sketches});

  @override
  void paint(Canvas canvas, Size size) {
    for (Sketch sketch in sketches) {
      final points = sketch.points;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length - 1; ++i) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      Paint paint = Paint()
        ..color = sketch.color
        ..strokeWidth = sketch.size
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      Offset firstPoint = sketch.points.first;
      Offset lastPoint = sketch.points.last;

      Rect rect = Rect.fromPoints(firstPoint, lastPoint);
      if (sketch.type == SketchType.scribble) {
        canvas.drawPath(path, paint);
      } else if (sketch.type == SketchType.line) {
        canvas.drawLine(firstPoint, lastPoint, paint);
      } else if (sketch.type == SketchType.circle) {
        canvas.drawOval(rect, paint);
      } else if (sketch.type == SketchType.rectangle) {
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
