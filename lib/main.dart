
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const MoraGame());

class MoraGame extends StatelessWidget {
  const MoraGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مربوطين في بعض 😂',
      theme: ThemeData.dark(),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late final TickerController ticker;

  double p1x = 100, p1y = 0, p1vx = 0, p1vy = 0;
  double p2x = 180, p2y = 0, p2vx = 0, p2vy = 0;
  double dogX = 400, dogY = 0;
  double camera = 0;
  double elapsed = 0;
  int score = 0;
  int falls = 0;
  int mode = 0;
  int skin = 0;
  bool left1 = false, right1 = false, jump1 = false;
  bool left2 = false, right2 = false, jump2 = false;
  bool grounded1 = true, grounded2 = true;
  bool paused = false;

  final List<double> obstacles = List<double>.generate(
    80, (i) => 350 + i * 230,
  );

  @override
  void initState() {
    super.initState();
    ticker = TickerController(onTick: updateGame)..start();
  }

  void updateGame(double dt) {
    if (!mounted || paused) return;

    setState(() {
      elapsed += dt;

      final old1x = p1x;
      final old2x = p2x;

      p1vx += (right1 ? 500 : 0) * dt;
      p1vx -= (left1 ? 500 : 0) * dt;
      p2vx += (right2 ? 500 : 0) * dt;
      p2vx -= (left2 ? 500 : 0) * dt;

      p1vx *= math.pow(0.985, dt * 60).toDouble();
      p2vx *= math.pow(0.985, dt * 60).toDouble();

      p1vx = p1vx.clamp(-190, 190).toDouble();
      p2vx = p2vx.clamp(-190, 190).toDouble();

      if (jump1 && grounded1) {
        p1vy = -360;
        grounded1 = false;
      }
      if (jump2 && grounded2) {
        p2vy = -360;
        grounded2 = false;
      }
      jump1 = false;
      jump2 = false;

      p1vy += 780 * dt;
      p2vy += 780 * dt;

      p1x += p1vx * dt;
      p2x += p2vx * dt;
      p1y += p1vy * dt;
      p2y += p2vy * dt;

      if (p1y > 0) {
        p1y = 0;
        p1vy = 0;
        grounded1 = true;
      }
      if (p2y > 0) {
        p2y = 0;
        p2vy = 0;
        grounded2 = true;
      }

      // حبل مرن يشد اللاعبين لبعض.
      final dx = p2x - p1x;
      final dy = p2y - p1y;
      final distance = math.sqrt(dx * dx + dy * dy);
      const ropeLength = 125.0;

      if (distance > ropeLength && distance > 0) {
        final excess = distance - ropeLength;
        final nx = dx / distance;
        final ny = dy / distance;
        final correction = excess * 0.48;

        p1x += nx * correction;
        p1y += ny * correction;
        p2x -= nx * correction;
        p2y -= ny * correction;

        final pull = excess * 2.8;
        p1vx += nx * pull * dt;
        p2vx -= nx * pull * dt;
        p1vy += ny * pull * dt;
        p2vy -= ny * pull * dt;
      }

      // الكلب يطارد أقرب لاعب.
      final targetX =
          (dogX - p1x).abs() < (dogX - p2x).abs()
              ? p1x
              : p2x;

      if (targetX > dogX) {
        dogX += (mode == 1 ? 145 : 90) * dt;
      } else {
        dogX -= 55 * dt;
      }

      dogX = dogX.clamp(0, 100000).toDouble();

      // العقبات تعيد اللاعبين إلى أقرب نقطة آمنة.
      for (final obstacle in obstacles) {
        final hit1 =
            (p1x - obstacle).abs() < 20 && p1y > -25;
        final hit2 =
            (p2x - obstacle).abs() < 20 && p2y > -25;

        if (hit1 || hit2) {
          p1x = math.max(60, old1x - 12);
          p2x = math.max(120, old2x - 12);
          p1vx = -p1vx.abs() * 0.4;
          p2vx = -p2vx.abs() * 0.4;
          falls++;
          break;
        }
      }

      if ((p1x - dogX).abs() < 24 ||
          (p2x - dogX).abs() < 24) {
        p1vx -= 100 * dt;
        p2vx -= 100 * dt;
      }

      if (p1x > camera + 300) camera = p1x - 300;
      if (p2x > camera + 300) camera = p2x - 300;

      score = math.max(score, (math.max(p1x, p2x) / 10).floor());
    });
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void resetGame() {
    setState(() {
      p1x = 100;
      p2x = 180;
      p1y = p2y = 0;
      p1vx = p2vx = p1vy = p2vy = 0;
      dogX = 400;
      camera = 0;
      score = falls = 0;
      elapsed = 0;
      grounded1 = grounded2 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10152B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '😂 مربوطين في بعض',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => paused = !paused),
                    icon: Icon(paused
                        ? Icons.play_arrow
                        : Icons.pause),
                  ),
                  IconButton(
                    onPressed: resetGame,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                Chip(label: Text('🏆 $score')),
                Chip(label: Text('💥 $falls')),
                ChoiceChip(
                  label: const Text('مغامرة'),
                  selected: mode == 0,
                  onSelected: (_) => setState(() => mode = 0),
                ),
                ChoiceChip(
                  label: const Text('الكلب المجنون'),
                  selected: mode == 1,
                  onSelected: (_) => setState(() => mode = 1),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                    painter: WorldPainter(
                      p1x: p1x,
                      p1y: p1y,
                      p2x: p2x,
                      p2y: p2y,
                      dogX: dogX,
                      camera: camera,
                      obstacles: obstacles,
                      skin: skin,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text('اللاعب الأول',
                          style: TextStyle(color: Colors.cyanAccent)),
                      for (final emoji in ['😂', '🤡', '🐸'])
                        InkWell(
                          onTap: () => setState(
                            () => skin = ['😂', '🤡', '🐸']
                                .indexOf(emoji),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 25)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      holdButton('⬅️', () => left1 = true,
                          () => left1 = false),
                      holdButton('➡️', () => right1 = true,
                          () => right1 = false),
                      ElevatedButton(
                        onPressed: () => jump1 = true,
                        child: const Text('قفز 🦘'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اللاعب الثاني: استخدم الأزرار التالية على نفس الجهاز',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      holdButton('◀️', () => left2 = true,
                          () => left2 = false),
                      holdButton('▶️', () => right2 = true,
                          () => right2 = false),
                      ElevatedButton(
                        onPressed: () => jump2 = true,
                        child: const Text('قفز 2'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget holdButton(
    String text,
    VoidCallback down,
    VoidCallback up,
  ) {
    return GestureDetector(
      onTapDown: (_) => down(),
      onTapUp: (_) => up(),
      onTapCancel: up,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF293452),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class TickerController {
  final void Function(double) onTick;
  final Stopwatch watch = Stopwatch();
  late final Ticker ticker;
  Duration previous = Duration.zero;
  bool active = false;

  TickerController({required this.onTick}) {
    ticker = Ticker((elapsed) {
      if (!active) return;
      final dt = (elapsed - previous).inMicroseconds / 1000000;
      previous = elapsed;
      onTick(dt.clamp(0.001, 0.04));
    });
  }

  void start() {
    active = true;
    previous = Duration.zero;
    ticker.start();
  }

  void dispose() {
    active = false;
    ticker.dispose();
  }
}

class WorldPainter extends CustomPainter {
  final double p1x, p1y, p2x, p2y, dogX, camera;
  final List<double> obstacles;
  final int skin;

  WorldPainter({
    required this.p1x,
    required this.p1y,
    required this.p2x,
    required this.p2y,
    required this.dogX,
    required this.camera,
    required this.obstacles,
    required this.skin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFF283A66);
    canvas.drawRect(Offset.zero & size, sky);

    final groundY = size.height * 0.76;

    final sun = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(size.width - 55, 50), 28, sun);

    final ground = Paint()..color = const Color(0xFFB59A66);
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      ground,
    );

    // مبانٍ مصرية في الخلفية.
    final buildingPaint = Paint()..color = const Color(0xFF74604F);
    for (int i = 0; i < 15; i++) {
      final bx = ((i * 90 - camera * 0.25) % (size.width + 90));
      canvas.drawRect(
        Rect.fromLTWH(bx, groundY - 95, 58, 95),
        buildingPaint,
      );
    }

    final scale = size.width / 360;
    final x1 = size.width * 0.36;
    final x2 = x1 + (p2x - p1x) * scale;
    final y1 = groundY + p1y * scale - 14;
    final y2 = groundY + p2y * scale - 14;

    final ropePaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), ropePaint);

    for (final obstacle in obstacles) {
      final ox = size.width * 0.36 + (obstacle - camera) * scale;
      if (ox < -30 || ox > size.width + 30) continue;

      final path = Path()
        ..moveTo(ox - 17, groundY)
        ..lineTo(ox, groundY - 35)
        ..lineTo(ox + 17, groundY)
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = Colors.deepOrangeAccent,
      );
    }

    drawPerson(canvas, Offset(x1, y1), Colors.cyanAccent,
        ['😂', '🤡', '🐸'][skin]);
    drawPerson(canvas, Offset(x2, y2), Colors.pinkAccent, '🤣');

    final dogScreenX = size.width * 0.36 + (dogX - camera) * scale;
    if (dogScreenX > -30 && dogScreenX < size.width + 30) {
      drawPerson(
        canvas,
        Offset(dogScreenX, groundY - 12),
        Colors.brown,
        '🐕',
      );
    }

    final text = TextPainter(
      text: const TextSpan(
        text: 'اجري يا عم! الكلب وراك 😂',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: size.width - 20);

    text.paint(canvas, const Offset(10, 10));
  }

  void drawPerson(
    Canvas canvas,
    Offset point,
    Color color,
    String emoji,
  ) {
    canvas.drawCircle(point, 16, Paint()..color = color);

    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 25),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(point.dx - tp.width / 2, point.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant WorldPainter oldDelegate) => true;
}
