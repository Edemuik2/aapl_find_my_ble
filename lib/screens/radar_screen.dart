import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ble_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    // Вычисляем угол поворота стрелки относительно севера телефона
    final double relativeAngle =
        (ble.targetAzimuth - ble.deviceHeading) * (pi / 180);

    String distanceText;
    if (ble.distance < 0.3) {
      distanceText = "HERE";
    } else if (ble.distance < 1.0) {
      distanceText = "NEARBY\n${(ble.distance * 100).toInt()} cm";
    } else {
      distanceText = "${ble.distance.toStringAsFixed(1)} m";
    }

    return Scaffold(
      body: Stack(
        children: [
          // Фоновые круги
          Center(
            child: CustomPaint(
              painter: RadarPainter(),
              size: const Size(300, 300),
            ),
          ),

          // Стрелка и точка
          Center(
            child: Transform.rotate(
              angle: relativeAngle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (ble.distance >= 0.5)
                    const Icon(
                          Icons.keyboard_arrow_up,
                          size: 80,
                          color: Colors.blueAccent,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms),
                  // Точка на окружности
                  Transform.translate(
                    offset: const Offset(0, -130),
                    child:
                        Container(
                              width: 15,
                              height: 15,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox(),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.5, 1.5),
                            )
                            .then()
                            .fadeOut(),
                  ),
                ],
              ),
            ),
          ),

          // Текст расстояния
          Align(
            alignment: const Alignment(0, 0.5),
            child:
                Text(
                      distanceText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    )
                    .animate(target: ble.distance < 1 ? 1 : 0)
                    .tint(color: Colors.greenAccent),
          ),

          // Кнопка "Нашел"
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: TextButton(
                onPressed: () {
                  ble.reset();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Я НАШЕЛ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.1) // Исправлено здесь
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 3, paint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 6, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
