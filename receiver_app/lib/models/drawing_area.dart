import 'package:flutter/material.dart';

class DrawingArea {
  Offset point;
  Paint areaPaint;

  DrawingArea.fromMap(String data) {
    List<dynamic> d = data.split(',');
    point = Offset(double.parse(d[0]), double.parse(d[1]));
    areaPaint = Paint();

    String c = d[2];
    String colorData = c.substring(6, c.length - 1);
    print(colorData);
    Color color = Color(int.parse(colorData));
    areaPaint.color = color;
    areaPaint.strokeWidth = double.parse(d[3]);
  }

  DrawingArea({this.point, this.areaPaint});
}
