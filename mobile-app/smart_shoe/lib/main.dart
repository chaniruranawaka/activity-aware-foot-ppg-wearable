import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const SmartShoeApp());
}

const String defaultEndpoint = 'http://192.168.4.1/data';

class SmartShoeApp extends StatelessWidget {
  const SmartShoeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF18A999);

    return MaterialApp(
      title: 'Smart Shoe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F8),
        useMaterial3: true,
      ),
      home: const ConnectionScreen(),
    );
  }
}

class ShoeReading {
  const ShoeReading({
    required this.deviceTimeMs,
    required this.oxygenLevel,
    required this.irValue,
    required this.motionLevel,
    required this.receivedAt,
  });

  final int deviceTimeMs;
  final double oxygenLevel;
  final int irValue;
  final double motionLevel;
  final DateTime receivedAt;

  factory ShoeReading.fromJson(Map<String, dynamic> json) {
    return ShoeReading(
      deviceTimeMs: _readInt(json, ['time_ms', 'timeMs', 'time']),
      oxygenLevel: _readNumber(json, ['spo2', 'o2', 'oxygen', 'oxygenLevel']),
      irValue: _readInt(json, ['ir', 'irValue']),
      motionLevel: _readNumber(json, [
        'motion_level',
        'motion',
        'motionLevel',
        'movement',
      ]),
      receivedAt: DateTime.now(),
    );
  }

  static double _readNumber(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    throw const FormatException('Missing sensor value');
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) {
          return parsed.round();
        }
      }
    }
    throw const FormatException('Missing sensor value');
  }
}

class Esp32SensorClient {
  static Future<ShoeReading> fetchReading(String endpoint) async {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Enter a valid ESP32 URL');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response must be a JSON object');
      }

      return ShoeReading.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }
}

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _connecting = false;
  String _status = 'Ready';

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _status = 'Connecting';
    });

    try {
      const endpoint = defaultEndpoint;
      final reading = await Esp32SensorClient.fetchReading(endpoint);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              SmartShoeDashboard(endpoint: endpoint, initialReading: reading),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connecting = false;
        _status = 'Unable to connect: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAFBF7), Color(0xFFEAF1FF), Color(0xFFF8F2E8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LogoBadge(),
                    const SizedBox(height: 24),
                    Text(
                      'Smart Shoe',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: const Color(0xFF122A34),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real-Time Dashboard',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF52636B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: _panelDecoration(elevated: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF8F5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFD5ECE8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.sensors,
                                  color: Color(0xFF18A999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Live Session',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: const Color(0xFF122A34),
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _status,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF536A76),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: const [
                              Expanded(
                                child: _LaunchSignal(
                                  icon: Icons.water_drop,
                                  label: 'O2 Level',
                                  color: Color(0xFF18A999),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _LaunchSignal(
                                  icon: Icons.directions_run,
                                  label: 'Motion Level',
                                  color: Color(0xFF2E6BC6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _connecting ? null : _connect,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF122A34),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: _connecting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.power_settings_new),
                              label: Text(
                                _connecting ? 'Connecting' : 'Connect',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDDE8EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A263238),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const CustomPaint(painter: _SmartShoeLogoPainter()),
      ),
    );
  }
}

class _SmartShoeLogoPainter extends CustomPainter {
  const _SmartShoeLogoPainter();

  static const Color _ink = Color(0xFF122A34);
  static const Color _cyan = Color(0xFF18A999);
  static const Color _blue = Color(0xFF2E6BC6);
  static const Color _soft = Color(0xFFEAF8F5);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width, size.height) / 112;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, 43 * scale, Paint()..color = _soft);
    _drawGear(canvas, center, scale);
    _drawMotionOrbit(canvas, center, scale);
    _drawSensorCore(canvas, center, scale);
    _drawOxygenDrop(canvas, center + Offset(-17 * scale, 13 * scale), scale);
  }

  void _drawGear(Canvas canvas, Offset center, double scale) {
    final toothPaint = Paint()..color = const Color(0xFFCADADF);
    for (var i = 0; i < 12; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * pi / 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -38 * scale),
            width: 8 * scale,
            height: 13 * scale,
          ),
          Radius.circular(3 * scale),
        ),
        toothPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(center, 34 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      34 * scale,
      Paint()
        ..color = const Color(0xFFD5E4E8)
        ..strokeWidth = 2 * scale
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(center, 21 * scale, Paint()..color = _ink);
  }

  void _drawMotionOrbit(Canvas canvas, Offset center, double scale) {
    final rect = Rect.fromCircle(center: center, radius: 31 * scale);
    canvas.drawArc(
      rect,
      -0.95,
      2.15,
      false,
      Paint()
        ..color = _blue
        ..strokeWidth = 4 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 39 * scale),
      -0.72,
      0.62,
      false,
      Paint()
        ..color = _cyan
        ..strokeWidth = 3 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center + Offset(28 * scale, -18 * scale),
      4 * scale,
      Paint()..color = _cyan,
    );
    canvas.drawCircle(
      center + Offset(38 * scale, -9 * scale),
      2.7 * scale,
      Paint()..color = _blue,
    );
  }

  void _drawSensorCore(Canvas canvas, Offset center, double scale) {
    canvas.drawCircle(center, 13 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      13 * scale,
      Paint()
        ..color = _cyan
        ..strokeWidth = 2.2 * scale
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(center, 5.5 * scale, Paint()..color = _blue);

    final tp = TextPainter(
      text: TextSpan(
        text: 'O2',
        style: TextStyle(
          color: _ink,
          fontSize: 9.5 * scale,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center + Offset(-tp.width / 2, -31 * scale));
  }

  void _drawOxygenDrop(Canvas canvas, Offset center, double scale) {
    final drop = Path()
      ..moveTo(center.dx, center.dy - 12 * scale)
      ..cubicTo(
        center.dx + 10 * scale,
        center.dy - 1 * scale,
        center.dx + 11 * scale,
        center.dy + 11 * scale,
        center.dx,
        center.dy + 14 * scale,
      )
      ..cubicTo(
        center.dx - 11 * scale,
        center.dy + 11 * scale,
        center.dx - 10 * scale,
        center.dy - 1 * scale,
        center.dx,
        center.dy - 12 * scale,
      )
      ..close();

    canvas.drawPath(drop, Paint()..color = _cyan);
    canvas.drawCircle(
      center + Offset(2 * scale, 4 * scale),
      4 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _SmartShoeLogoPainter oldDelegate) => false;
}

class _LaunchSignal extends StatelessWidget {
  const _LaunchSignal({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1EAED)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF122A34),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SmartShoeDashboard extends StatefulWidget {
  const SmartShoeDashboard({
    super.key,
    required this.endpoint,
    required this.initialReading,
    this.demoMode = false,
  });

  final String endpoint;
  final ShoeReading initialReading;
  final bool demoMode;

  @override
  State<SmartShoeDashboard> createState() => _SmartShoeDashboardState();
}

class _SmartShoeDashboardState extends State<SmartShoeDashboard>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late AnimationController _animationController;
  late ShoeReading _reading;
  Timer? _pollTimer;
  Timer? _demoTimer;
  String _status = 'Live data connected';
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _reading = widget.initialReading;
    _animationController = AnimationController(
      vsync: this,
      duration: _durationForMotion(_reading.motionLevel),
    )..repeat();

    if (widget.demoMode) {
      _isPolling = false;
      _status = 'Demo data running';
      _startDemoTimer();
    } else {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _demoTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchReading();
    });
  }

  Duration _durationForMotion(double motionLevel) {
    final motion = (motionLevel / 100).clamp(0.0, 1.0).toDouble();
    final milliseconds = (1650 - motion * 1090).round().clamp(560, 1650);
    return Duration(milliseconds: milliseconds.toInt());
  }

  void _syncAnimationPace(double motionLevel) {
    final nextDuration = _durationForMotion(motionLevel);
    if (_animationController.duration == nextDuration) {
      return;
    }

    final value = _animationController.value;
    _animationController.duration = nextDuration;
    _animationController.value = value;
    _animationController.repeat(period: nextDuration);
  }

  void _startDemoTimer() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      final nextReading = _nextDemoReading();
      _syncAnimationPace(nextReading.motionLevel);
      setState(() {
        _reading = nextReading;
      });
    });
  }

  ShoeReading _nextDemoReading() {
    final t = DateTime.now().millisecondsSinceEpoch / 1000;
    final oxygen = 93 + (sin(t * 0.7) + 1) * 3;
    final motion = ((sin(t * 0.85) + 1) * 50).clamp(0, 100).toDouble();
    return ShoeReading(
      deviceTimeMs: DateTime.now().millisecondsSinceEpoch % 100000,
      oxygenLevel: oxygen,
      irValue: 45000 + _random.nextInt(18000),
      motionLevel: motion,
      receivedAt: DateTime.now(),
    );
  }

  Future<void> _fetchReading() async {
    try {
      final reading = await Esp32SensorClient.fetchReading(widget.endpoint);
      if (!mounted) {
        return;
      }
      _syncAnimationPace(reading.motionLevel);
      setState(() {
        _reading = reading;
        _status = 'Live data connected';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Last reading kept: $error';
      });
    }
  }

  void _pauseOrResume() {
    if (widget.demoMode) {
      return;
    }
    if (_isPolling) {
      _pollTimer?.cancel();
      setState(() {
        _isPolling = false;
        _status = 'Connection paused';
      });
    } else {
      setState(() {
        _isPolling = true;
        _status = 'Live data connected';
      });
      _fetchReading();
      _startPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = _reading.motionLevel.clamp(0, 100).toDouble();
    final oxygen = _reading.oxygenLevel.clamp(0, 100).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shoe'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: widget.demoMode
                ? 'Demo mode'
                : _isPolling
                ? 'Pause'
                : 'Resume',
            onPressed: widget.demoMode ? null : _pauseOrResume,
            icon: Icon(_isPolling ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Change endpoint',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ConnectionScreen()),
              );
            },
            icon: const Icon(Icons.wifi_find),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _LiveStatusBar(
              status: _status,
              isLive: _isPolling && !widget.demoMode,
              isDemo: widget.demoMode,
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: motion, end: motion),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, smoothMotion, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: oxygen, end: oxygen),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, smoothOxygen, _) {
                    return _RobotMotionPanel(
                      motionLevel: smoothMotion,
                      oxygenLevel: smoothOxygen,
                      controller: _animationController,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                final cards = [
                  SensorCard(
                    title: 'O2 Level',
                    value: oxygen,
                    unit: '%',
                    icon: Icons.water_drop,
                    color: const Color(0xFF18A999),
                    maxValue: 100,
                  ),
                  SensorCard(
                    title: 'Motion Level',
                    value: motion,
                    unit: '',
                    icon: Icons.speed,
                    color: const Color(0xFF2E6BC6),
                    maxValue: 100,
                  ),
                ];

                if (!wide) {
                  return Column(
                    children: [
                      cards.first,
                      const SizedBox(height: 12),
                      cards.last,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cards.first),
                    const SizedBox(width: 12),
                    Expanded(child: cards.last),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Last update: ${_formatTime(_reading.receivedAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _RobotMotionPanel extends StatelessWidget {
  const _RobotMotionPanel({
    required this.motionLevel,
    required this.oxygenLevel,
    required this.controller,
  });

  final double motionLevel;
  final double oxygenLevel;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final motionRatio = (motionLevel / 100).clamp(0.0, 1.0).toDouble();
    final oxygenRatio = (oxygenLevel / 100).clamp(0.0, 1.0).toDouble();
    final motionText = motionLevel < 8
        ? 'Stabilized'
        : motionLevel < 35
        ? 'Walking'
        : motionLevel < 70
        ? 'Running'
        : 'High motion';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF8F5), Color(0xFFEAF1FF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE8EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14263238),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.precision_manufacturing,
                color: Color(0xFF18A999),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  motionText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF122A34),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${motionLevel.toStringAsFixed(1)} / 100',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2E6BC6),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.68,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: BiomechRobotPainter(
                    motionLevel: motionLevel,
                    oxygenLevel: oxygenLevel,
                    phase: controller.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: motionRatio,
                    color: const Color(0xFF2E6BC6),
                    backgroundColor: const Color(0xFFDDE8EA),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: oxygenRatio,
                    color: const Color(0xFF18A999),
                    backgroundColor: const Color(0xFFDDE8EA),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BiomechRobotPainter extends CustomPainter {
  BiomechRobotPainter({
    required this.motionLevel,
    required this.oxygenLevel,
    required this.phase,
  });

  final double motionLevel;
  final double oxygenLevel;
  final double phase;

  static const Color _jointInk = Color(0xFF0D151A);
  static const Color _rearInk = Color(0xFF344047);
  static const Color _shell = Color(0xFFF8FAFA);
  static const Color _shellShade = Color(0xFFDDE5E8);
  static const Color _rearShell = Color(0xFFE1E7EA);
  static const Color _rearShellShade = Color(0xFFBEC9CE);
  static const Color _line = Color(0xFF809098);
  static const Color _neonCyan = Color(0xFF2CFBFF);
  static const Color _neonPink = Color(0xFFFF3CF7);
  static const Color _neonViolet = Color(0xFF7A5CFF);
  static const Color _deepPanel = Color(0xFF101A24);

  @override
  void paint(Canvas canvas, Size size) {
    final motion = (motionLevel / 100).clamp(0.0, 1.0).toDouble();
    final oxygen = (oxygenLevel / 100).clamp(0.0, 1.0).toDouble();
    final activity = _smoothStep(0.05, 0.34, motion);
    final scale = min(size.width / 390, size.height / 285);
    final groundY = size.height * 0.82;
    final theta = phase * pi * 2;
    final strideBob = pow(cos(theta).abs(), 1.35).toDouble();
    final idleBreath = sin(theta * 2) * 1.5 * (1 - activity) * scale;
    final bodyBob = (-(1.8 + 5.5 * activity) * strideBob * scale) + idleBreath;
    final pelvis = Offset(size.width * 0.49, groundY - 112 * scale + bodyBob);
    Offset bodyPoint(double x, double y) {
      return pelvis + Offset(x * scale, y * scale);
    }

    final hipRear = bodyPoint(-5, 1);
    final hipFront = bodyPoint(10, 0);
    final shoulderRear = bodyPoint(5, -86);
    final shoulderFront = bodyPoint(26, -84);
    final neck = bodyPoint(28, -113);
    final headCenter = bodyPoint(52, -142);
    final rearLeg = _legPose(
      hipRear,
      theta + pi,
      groundY,
      scale,
      activity,
      false,
    );
    final frontLeg = _legPose(hipFront, theta, groundY, scale, activity, true);
    final rearArm = _armPose(shoulderRear, theta, scale, activity, false);
    final frontArm = _armPose(shoulderFront, theta + pi, scale, activity, true);

    _paintBackground(canvas, size, groundY, scale, motion);
    _paintNeonTrail(canvas, size, groundY, scale, motion, theta);
    _paintLeg(canvas, rearLeg, scale, front: false);
    _paintArm(canvas, rearArm, scale, front: false);
    _paintTorso(canvas, bodyPoint, pelvis, neck, scale, oxygen);
    _paintHead(canvas, headCenter, 0, scale, oxygen);
    _paintLeg(canvas, frontLeg, scale, front: true);
    _paintArm(canvas, frontArm, scale, front: true);
    _drawHipWheel(canvas, pelvis, scale, oxygen);
    _drawJoint(canvas, shoulderFront, 11 * scale, front: true);
  }

  void _paintBackground(
    Canvas canvas,
    Size size,
    double groundY,
    double scale,
    double motion,
  ) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEF8FA), Color(0xFFE9F1F5), Color(0xFFDDE8EF)],
        ).createShader(bounds),
    );
    final shadowPaint = Paint()..color = const Color(0x26121C22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, groundY + 8 * scale),
        width: size.width * (0.34 + motion * 0.12),
        height: 15 * scale,
      ),
      shadowPaint,
    );
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x002CFBFF), Color(0x992CFBFF), Color(0x00FF3CF7)],
      ).createShader(Rect.fromLTWH(0, groundY - 2 * scale, size.width, 6))
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.09, groundY),
      Offset(size.width * 0.91, groundY),
      groundPaint,
    );
    final gridPaint = Paint()
      ..color = const Color(0x262CFBFF)
      ..strokeWidth = 0.8 * scale;
    for (var i = 0; i < 6; i++) {
      final y = groundY + (i + 1) * 8 * scale;
      canvas.drawLine(
        Offset(size.width * 0.12, y),
        Offset(size.width * 0.88, y),
        gridPaint,
      );
    }
  }

  void _paintNeonTrail(
    Canvas canvas,
    Size size,
    double groundY,
    double scale,
    double motion,
    double theta,
  ) {
    if (motion < 0.08) {
      return;
    }

    final activity = _smoothStep(0.08, 0.52, motion);
    final baseY = groundY - 139 * scale;
    for (var i = 0; i < 5; i++) {
      final y = baseY + (i * 24 + sin(theta + i) * 4) * scale;
      final startX = size.width * (0.14 + i * 0.025);
      final endX = size.width * (0.36 + i * 0.018);
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y - 4 * scale),
        Paint()
          ..color = Color.lerp(
            _neonPink,
            _neonCyan,
            i / 4,
          )!.withValues(alpha: 0.18 * activity)
          ..strokeWidth = (2.6 - i * 0.25) * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintTorso(
    Canvas canvas,
    Offset Function(double x, double y) bodyPoint,
    Offset pelvis,
    Offset neck,
    double scale,
    double oxygen,
  ) {
    final spineTop = bodyPoint(19, -107);
    canvas.drawLine(
      pelvis,
      spineTop,
      Paint()
        ..color = _jointInk
        ..strokeWidth = 13 * scale
        ..strokeCap = StrokeCap.round,
    );

    final torso = _closedPath([
      bodyPoint(-24, -92),
      bodyPoint(6, -111),
      bodyPoint(43, -101),
      bodyPoint(58, -64),
      bodyPoint(43, -20),
      bodyPoint(13, 6),
      bodyPoint(-31, -8),
      bodyPoint(-40, -55),
    ]);
    final torsoBounds = torso.getBounds();
    canvas.drawPath(
      torso,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shell, Color(0xFFFFFFFF), _shellShade],
        ).createShader(torsoBounds),
    );
    canvas.drawPath(
      torso,
      Paint()
        ..color = _line
        ..strokeWidth = 1.4 * scale
        ..style = PaintingStyle.stroke,
    );

    final corePanel = _closedPath([
      bodyPoint(11, -91),
      bodyPoint(38, -78),
      bodyPoint(34, -31),
      bodyPoint(12, -20),
      bodyPoint(-4, -50),
    ]);
    canvas.drawPath(corePanel, Paint()..color = _deepPanel);

    final glow = _oxygenHealthColor(oxygen);
    final chest = bodyPoint(27, -77);
    _drawJoint(canvas, chest, 16 * scale, front: true, accent: glow);
    _drawOxygenHealthBar(canvas, bodyPoint, scale, oxygen);
    _drawCyberLine(
      canvas,
      bodyPoint(12, -86),
      bodyPoint(31, -72),
      _neonCyan,
      scale,
    );
    _drawCyberLine(
      canvas,
      bodyPoint(8, -64),
      bodyPoint(32, -51),
      _neonPink,
      scale,
    );
    _drawCyberLine(
      canvas,
      bodyPoint(18, -38),
      bodyPoint(30, -31),
      _neonViolet,
      scale,
    );
    canvas.drawLine(
      bodyPoint(-20, -42),
      bodyPoint(31, -56),
      Paint()
        ..color = const Color(0x66809098)
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      bodyPoint(4, -15),
      bodyPoint(27, -28),
      Paint()
        ..color = const Color(0x66809098)
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      neck,
      bodyPoint(23, -101),
      Paint()
        ..color = _jointInk
        ..strokeWidth = 10 * scale
        ..strokeCap = StrokeCap.round,
    );
    _drawJoint(canvas, neck, 8 * scale, front: true);
  }

  void _paintHead(
    Canvas canvas,
    Offset center,
    double angle,
    double scale,
    double oxygen,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final shellPath = Path()
      ..moveTo(-28 * scale, -7 * scale)
      ..quadraticBezierTo(-20 * scale, -26 * scale, 7 * scale, -27 * scale)
      ..quadraticBezierTo(32 * scale, -27 * scale, 41 * scale, -10 * scale)
      ..lineTo(46 * scale, -1 * scale)
      ..quadraticBezierTo(37 * scale, 18 * scale, 14 * scale, 24 * scale)
      ..quadraticBezierTo(-11 * scale, 28 * scale, -28 * scale, 12 * scale)
      ..quadraticBezierTo(-35 * scale, 3 * scale, -28 * scale, -7 * scale)
      ..close();
    final headBounds = Rect.fromLTWH(
      -36 * scale,
      -28 * scale,
      84 * scale,
      59 * scale,
    );
    canvas.drawPath(
      shellPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shell, Color(0xFFFFFFFF), _shellShade],
        ).createShader(headBounds),
    );
    canvas.drawPath(
      shellPath,
      Paint()
        ..color = _line
        ..strokeWidth = 1.3 * scale
        ..style = PaintingStyle.stroke,
    );

    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(15 * scale, -16 * scale, 29 * scale, 26 * scale),
      Radius.circular(10 * scale),
    );
    canvas.drawRRect(face, Paint()..color = _deepPanel);
    final eyeGlow = _oxygenHealthColor(oxygen);
    canvas.drawLine(
      Offset(19 * scale, -5 * scale),
      Offset(40 * scale, -5 * scale),
      Paint()
        ..color = eyeGlow
        ..strokeWidth = 2.6 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(33 * scale, -4 * scale),
      4.8 * scale,
      Paint()..color = eyeGlow,
    );
    canvas.drawCircle(
      Offset(33 * scale, -4 * scale),
      1.8 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      Offset(36 * scale, 14 * scale),
      Offset(21 * scale, 19 * scale),
      Paint()
        ..color = _neonPink
        ..strokeWidth = 1.4 * scale
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(-16 * scale, -1 * scale),
      7.2 * scale,
      Paint()..color = _jointInk,
    );
    canvas.drawCircle(
      Offset(-16 * scale, -1 * scale),
      3.8 * scale,
      Paint()..color = _neonViolet,
    );
    canvas.drawLine(
      Offset(-4 * scale, -21 * scale),
      Offset(24 * scale, -22 * scale),
      Paint()
        ..color = _neonCyan
        ..strokeWidth = 1.5 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintLeg(
    Canvas canvas,
    _TwoBonePose pose,
    double scale, {
    required bool front,
  }) {
    _drawSegment(
      canvas,
      pose.root,
      pose.joint,
      16 * scale,
      scale,
      front: front,
    );
    _drawSegment(canvas, pose.joint, pose.end, 15 * scale, scale, front: front);
    _paintFoot(canvas, pose.end, pose.endAngle, scale, front: front);
    _drawJoint(canvas, pose.root, 9 * scale, front: front);
    _drawJoint(canvas, pose.joint, 10 * scale, front: front);
    _drawJoint(canvas, pose.end, 7 * scale, front: front);
  }

  void _paintArm(
    Canvas canvas,
    _TwoBonePose pose,
    double scale, {
    required bool front,
  }) {
    _drawSegment(
      canvas,
      pose.root,
      pose.joint,
      12 * scale,
      scale,
      front: front,
    );
    _drawSegment(canvas, pose.joint, pose.end, 11 * scale, scale, front: front);
    _drawJoint(canvas, pose.root, 8.5 * scale, front: front);
    _drawJoint(canvas, pose.joint, 7.5 * scale, front: front);
    _paintHand(canvas, pose.end, pose.endAngle, scale, front: front);
  }

  _TwoBonePose _legPose(
    Offset hip,
    double legPhase,
    double groundY,
    double scale,
    double activity,
    bool lead,
  ) {
    final stride = 50 * activity * scale;
    final idleOffset = (lead ? 14 : -14) * (1 - activity) * scale;
    final liftWave = pow(max(0.0, -cos(legPhase)), 0.78).toDouble();
    final ankle = Offset(
      hip.dx + idleOffset - sin(legPhase) * stride,
      groundY - 18 * scale - 31 * activity * liftWave * scale,
    );
    final knee = _solveJoint(hip, ankle, 58 * scale, 64 * scale, -1);
    final toeRoll =
        (-0.03 + cos(legPhase) * 0.34 * activity) +
        max(0.0, -sin(legPhase)) * 0.18 * activity;
    return _TwoBonePose(hip, knee, ankle, toeRoll);
  }

  _TwoBonePose _armPose(
    Offset shoulder,
    double armPhase,
    double scale,
    double activity,
    bool front,
  ) {
    final reach = (19 + 34 * activity) * scale;
    final wrist = Offset(
      shoulder.dx + (front ? 4 : -7) * scale - sin(armPhase) * reach,
      shoulder.dy + (54 - 8 * activity) * scale + cos(armPhase) * 10 * scale,
    );
    final elbow = _solveJoint(
      shoulder,
      wrist,
      38 * scale,
      40 * scale,
      front ? 1 : -1,
    );
    final handAngle = atan2(wrist.dy - elbow.dy, wrist.dx - elbow.dx);
    return _TwoBonePose(shoulder, elbow, wrist, handAngle);
  }

  Offset _solveJoint(
    Offset root,
    Offset target,
    double upper,
    double lower,
    double bendSign,
  ) {
    final dx = target.dx - root.dx;
    final dy = target.dy - root.dy;
    final rawDistance = max(1.0, sqrt(dx * dx + dy * dy));
    final distance = rawDistance.clamp(1.0, upper + lower - 0.1).toDouble();
    final ux = dx / rawDistance;
    final uy = dy / rawDistance;
    final along =
        (upper * upper - lower * lower + distance * distance) / (2 * distance);
    final height = sqrt(max(0.0, upper * upper - along * along));
    final base = root + Offset(ux * along, uy * along);
    final perpendicular = Offset(-uy, ux);
    return base + perpendicular * height * bendSign;
  }

  void _drawSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
    double scale, {
    required bool front,
  }) {
    final dark = front ? _jointInk : _rearInk;
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = dark
        ..strokeWidth = width * 0.58
        ..strokeCap = StrokeCap.round,
    );

    final shellStart = Offset.lerp(start, end, 0.15)!;
    final shellEnd = Offset.lerp(start, end, 0.86)!;
    _drawCapsule(canvas, shellStart, shellEnd, width, scale, front: front);
  }

  void _drawCapsule(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
    double scale, {
    required bool front,
  }) {
    final delta = end - start;
    final length = delta.distance;
    if (length <= 0.1) {
      return;
    }

    final rect = Rect.fromLTWH(0, -width / 2, length, width);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width / 2));
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(atan2(delta.dy, delta.dx));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: front
              ? const [_shell, Color(0xFFFFFFFF), _shellShade]
              : const [_rearShell, Color(0xFFEFF3F5), _rearShellShade],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = front ? _line : const Color(0xFF8B999F)
        ..strokeWidth = 1.1 * scale
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(length * 0.18, -width * 0.22),
      Offset(length * 0.62, -width * 0.22),
      Paint()
        ..color = const Color(0xB3FFFFFF)
        ..strokeWidth = max(1.0, 1.5 * scale)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(length * 0.2, width * 0.22),
      Offset(length * 0.82, width * 0.18),
      Paint()
        ..color = front ? _neonCyan : _neonViolet.withValues(alpha: 0.72)
        ..strokeWidth = max(1.0, 1.4 * scale)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintFoot(
    Canvas canvas,
    Offset ankle,
    double angle,
    double scale, {
    required bool front,
  }) {
    canvas.save();
    canvas.translate(ankle.dx, ankle.dy);
    canvas.rotate(angle);

    final sole = RRect.fromRectAndRadius(
      Rect.fromLTWH(-23 * scale, 7 * scale, 60 * scale, 8 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(sole, Paint()..color = front ? _jointInk : _rearInk);
    canvas.drawLine(
      Offset(-17 * scale, 15 * scale),
      Offset(34 * scale, 15 * scale),
      Paint()
        ..color = front ? _neonPink : _neonViolet
        ..strokeWidth = 2.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    final upper = Path()
      ..moveTo(-22 * scale, 4 * scale)
      ..lineTo(6 * scale, 3 * scale)
      ..quadraticBezierTo(25 * scale, 0, 34 * scale, 7 * scale)
      ..lineTo(29 * scale, 12 * scale)
      ..lineTo(-18 * scale, 12 * scale)
      ..quadraticBezierTo(-26 * scale, 10 * scale, -22 * scale, 4 * scale)
      ..close();
    final bounds = Rect.fromLTWH(-27 * scale, 0, 64 * scale, 15 * scale);
    canvas.drawPath(
      upper,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: front
              ? const [_shell, Color(0xFFFFFFFF), _shellShade]
              : const [_rearShell, Color(0xFFEFF3F5), _rearShellShade],
        ).createShader(bounds),
    );
    canvas.drawPath(
      upper,
      Paint()
        ..color = front ? _line : const Color(0xFF8B999F)
        ..strokeWidth = 1.1 * scale
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  void _paintHand(
    Canvas canvas,
    Offset wrist,
    double angle,
    double scale, {
    required bool front,
  }) {
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(angle);
    final handColor = front ? _jointInk : _rearInk;
    canvas.drawCircle(Offset.zero, 8 * scale, Paint()..color = handColor);
    for (var i = 0; i < 3; i++) {
      final finger = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (4 + i * 3) * scale,
          (-6 + i * 4) * scale,
          10 * scale,
          4 * scale,
        ),
        Radius.circular(2 * scale),
      );
      canvas.drawRRect(
        finger,
        Paint()..color = front ? _neonCyan : _rearShellShade,
      );
    }
    canvas.restore();
  }

  void _drawJoint(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool front,
    Color? accent,
  }) {
    final outer = front ? _jointInk : _rearInk;
    canvas.drawCircle(center, radius, Paint()..color = outer);
    canvas.drawCircle(
      center,
      radius * 0.7,
      Paint()..color = front ? _shellShade : _rearShellShade,
    );
    canvas.drawCircle(center, radius * 0.42, Paint()..color = outer);
    if (accent != null) {
      canvas.drawCircle(center, radius * 0.22, Paint()..color = accent);
    } else if (front) {
      canvas.drawCircle(
        center,
        radius * 0.78,
        Paint()
          ..color = _neonCyan.withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, radius * 0.12),
      );
    }
  }

  void _drawHipWheel(
    Canvas canvas,
    Offset center,
    double scale,
    double oxygen,
  ) {
    final glow = _oxygenHealthColor(oxygen);
    canvas.drawCircle(center, 21 * scale, Paint()..color = _jointInk);
    canvas.drawCircle(center, 15 * scale, Paint()..color = _shellShade);
    canvas.drawCircle(center, 11 * scale, Paint()..color = _jointInk);
    canvas.drawCircle(
      center,
      6 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale
        ..color = glow,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 18 * scale),
      -pi / 4,
      pi * 1.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scale
        ..strokeCap = StrokeCap.round
        ..color = _neonPink,
    );
  }

  void _drawOxygenHealthBar(
    Canvas canvas,
    Offset Function(double x, double y) bodyPoint,
    double scale,
    double oxygen,
  ) {
    final ratio = oxygen.clamp(0.0, 1.0).toDouble();
    final color = _oxygenHealthColor(ratio);
    final barTop = bodyPoint(-23, -82);
    final barRect = Rect.fromLTWH(barTop.dx, barTop.dy, 12 * scale, 58 * scale);
    final barRRect = RRect.fromRectAndRadius(
      barRect,
      Radius.circular(6 * scale),
    );

    canvas.drawRRect(barRRect, Paint()..color = const Color(0xFF0A1118));
    canvas.save();
    canvas.clipRRect(barRRect);
    final fillRect = Rect.fromLTRB(
      barRect.left,
      barRect.bottom - barRect.height * ratio,
      barRect.right,
      barRect.bottom,
    );
    canvas.drawRect(
      fillRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withValues(alpha: 0.72), color],
        ).createShader(barRect),
    );
    canvas.restore();

    canvas.drawRRect(
      barRRect,
      Paint()
        ..color = color
        ..strokeWidth = 1.6 * scale
        ..style = PaintingStyle.stroke,
    );
    for (var i = 1; i < 5; i++) {
      final y = barRect.bottom - barRect.height * i / 5;
      canvas.drawLine(
        Offset(barRect.left + 2.5 * scale, y),
        Offset(barRect.right - 2.5 * scale, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.46)
          ..strokeWidth = 0.8 * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    final cap = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: bodyPoint(-17, -90),
        width: 18 * scale,
        height: 6 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(cap, Paint()..color = _deepPanel);
    canvas.drawRRect(
      cap,
      Paint()
        ..color = color
        ..strokeWidth = 1.2 * scale
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(bodyPoint(-17, -15), 3.5 * scale, Paint()..color = color);
  }

  void _drawCyberLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double scale,
  ) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 1.7 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(start, 2.2 * scale, Paint()..color = color);
    canvas.drawCircle(end, 2.2 * scale, Paint()..color = color);
  }

  Color _oxygenHealthColor(double oxygen) {
    const warning = Color(0xFFFFD166);
    if (oxygen < 0.9) {
      return Color.lerp(_neonPink, warning, oxygen / 0.9)!;
    }

    final healthy = ((oxygen - 0.9) / 0.1).clamp(0.0, 1.0).toDouble();
    return Color.lerp(warning, _neonCyan, healthy)!;
  }

  Path _closedPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  double _smoothStep(double edge0, double edge1, double value) {
    final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0).toDouble();
    return t * t * (3 - 2 * t);
  }

  @override
  bool shouldRepaint(covariant BiomechRobotPainter oldDelegate) {
    return oldDelegate.motionLevel != motionLevel ||
        oldDelegate.oxygenLevel != oxygenLevel ||
        oldDelegate.phase != phase;
  }
}

class _TwoBonePose {
  const _TwoBonePose(this.root, this.joint, this.end, this.endAngle);

  final Offset root;
  final Offset joint;
  final Offset end;
  final double endAngle;
}

class _LiveStatusBar extends StatelessWidget {
  const _LiveStatusBar({
    required this.status,
    required this.isLive,
    required this.isDemo,
  });

  final String status;
  final bool isLive;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final color = isLive
        ? const Color(0xFF15815F)
        : isDemo
        ? const Color(0xFF8A6500)
        : const Color(0xFF7B2E2E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.maxValue,
  });

  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                text: value.toStringAsFixed(1),
                children: [
                  TextSpan(
                    text: unit,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFF122A34),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              color: color,
              backgroundColor: const Color(0xFFEAEFF2),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration({bool elevated = false}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFDDE8EA)),
    boxShadow: [
      BoxShadow(
        color: const Color(0x14263238),
        blurRadius: elevated ? 24 : 14,
        offset: Offset(0, elevated ? 14 : 8),
      ),
    ],
  );
}
