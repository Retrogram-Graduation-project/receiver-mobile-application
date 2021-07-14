import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class SentImage extends StatelessWidget {
  const SentImage({
    Key key,
    @required this.filePath,
    @required this.controller,
  }) : super(key: key);

  final String filePath;
  final PhotoViewControllerBase<PhotoViewControllerValue> controller;

  @override
  Widget build(BuildContext context) {
    double minScale = 0.03;
    double maxScale = 0.6;

    return PhotoView(
      imageProvider: FileImage(File(filePath)),
      controller: controller,
      enableRotation: true,
      initialScale: minScale * 1.5,
      minScale: minScale,
      maxScale: maxScale,
    );
  }
}
