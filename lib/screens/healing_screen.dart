import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';

class HealingScreen extends StatefulWidget {
  @override
  _HealingScreenState createState() => _HealingScreenState();
}

class _HealingScreenState extends State<HealingScreen> with TickerProviderStateMixin {
  static const platform = MethodChannel('com.example.app/play_audio');
  String? _selectedMusic;
  String? _selectedArtist;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _currentPosition = 0;
  double _totalDuration = 0;
  late AnimationController _waveAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> availableMusic = [
    {"title": "A Moment For Peace", "artist": "Healing Sounds", "file": "a_moment_for_peace.mp3", "duration": "3:24"},
    {"title": "The Winding Path", "artist": "Nature Sounds", "file": "the_winding_path.mp3", "duration": "2:58"},
  ];

  @override
  void initState() {
    super.initState();

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_isPlaying && !_isPaused) {
      _pulseController.repeat(reverse: true); // chỉ gọi sau khi khởi tạo xong
    }

    Future.delayed(Duration.zero, () {
      _setupProgressTimer();
    });
  }

  void _setupProgressTimer() {
    Future.microtask(() {
      if (_isPlaying && !_isPaused) {
        setState(() {
          if (_currentPosition < _totalDuration) {
            _currentPosition += 0.1;
          } else {
            _currentPosition = 0;
            _playNextTrack();
          }
        });
        Future.delayed(Duration(milliseconds: 100), _setupProgressTimer);
      } else {
        Future.delayed(Duration(milliseconds: 100), _setupProgressTimer);
      }
    });
  }

  void _playNextTrack() {
    if (_selectedMusic == null) return;

    int currentIndex = availableMusic.indexWhere((music) => music["file"] == _selectedMusic);
    if (currentIndex != -1 && currentIndex < availableMusic.length - 1) {
      _playPauseMusic(availableMusic[currentIndex + 1]["file"]!);
    } else if (currentIndex != -1) {
      // Loop back to first track
      _playPauseMusic(availableMusic[0]["file"]!);
    }
  }

  void _playPreviousTrack() {
    if (_selectedMusic == null) return;

    int currentIndex = availableMusic.indexWhere((music) => music["file"] == _selectedMusic);
    if (currentIndex > 0) {
      _playPauseMusic(availableMusic[currentIndex - 1]["file"]!);
    } else if (currentIndex == 0) {
      // Loop to last track
      _playPauseMusic(availableMusic[availableMusic.length - 1]["file"]!);
    }
  }

  Future<void> _playPauseMusic(String fileName) async {
    if (_isPlaying && _selectedMusic == fileName) {
      await platform.invokeMethod(_isPaused ? 'resumeAudio' : 'pauseAudio');
      setState(() => _isPaused = !_isPaused);
    } else {
      await platform.invokeMethod('playAudio', {"fileName": fileName});

      // Find the track info
      final trackInfo = availableMusic.firstWhere(
            (music) => music["file"] == fileName,
        orElse: () => {"title": fileName.split('/').last, "artist": "Unknown Artist", "duration": "0:00"},
      );

      // Parse duration string to seconds (simple implementation)
      final durationParts = trackInfo["duration"]!.split(':');
      final durationInSeconds = int.parse(durationParts[0]) * 60 + int.parse(durationParts[1]);

      setState(() {
        _selectedMusic = fileName;
        _selectedArtist = trackInfo["artist"];
        _isPlaying = true;
        _isPaused = false;
        _currentPosition = 0;
        _totalDuration = durationInSeconds.toDouble();
      });

      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _stopMusic() async {
    await platform.invokeMethod('stopAudio');
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _selectedMusic = null;
      _currentPosition = 0;
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _pickMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        await _stopMusic();
        await platform.invokeMethod('playAudio', {"fileName": filePath});

        final fileName = filePath.split('/').last;
        setState(() {
          _selectedMusic = filePath;
          _selectedArtist = "Custom Track";
          _isPlaying = true;
          _isPaused = false;
          _currentPosition = 0;
          _totalDuration = 180; // Default 3 minutes for custom tracks
        });
      }
    }
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  String _formatDuration(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Find current track info for display
    final currentTrack = _selectedMusic != null
        ? availableMusic.firstWhere(
          (music) => music["file"] == _selectedMusic,
      orElse: () => {
        "title": _selectedMusic!.split('/').last,
        "artist": _selectedArtist ?? "Unknown Artist",
      },
    )
        : {"title": "Select a track", "artist": "Tap play to begin"};

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9747FF), Color(0xFF7E30E1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status bar area
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("9:41", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 16),
                            SizedBox(width: 5),
                            Icon(Icons.wifi, color: Colors.white, size: 16),
                            SizedBox(width: 5),
                            Icon(Icons.battery_full, color: Colors.white, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),


              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Waveform visualization
                    ScaleTransition(
                      scale: _isPlaying && !_isPaused ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: (_isPlaying && !_isPaused)
                                  ? Colors.purpleAccent.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ClipOval(
                            child: AnimatedBuilder(
                              animation: _waveAnimationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: Size(320, 320),
                                  painter: WaveformPainter(
                                    animation: _waveAnimationController.value,
                                    isPlaying: _isPlaying && !_isPaused,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),


                    SizedBox(height: 40),

                    // Track title
                    Text(
                      currentTrack["title"] ?? "Select a track",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Artist name in pill
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            currentTrack["artist"] ?? "Unknown Artist",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40),

                    // Progress bar and time
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 30,
                                child: CustomPaint(
                                  size: Size(double.infinity, 30),
                                  painter: WaveformProgressPainter(
                                    progress: _totalDuration > 0 ? _currentPosition / _totalDuration : 0,
                                  ),
                                ),
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 1,
                                  activeTrackColor: Colors.transparent,
                                  inactiveTrackColor: Colors.transparent,
                                  thumbColor: Colors.white,
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0),
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                                ),
                                child: Slider(
                                  value: _currentPosition,
                                  min: 0,
                                  max: _totalDuration > 0 ? _totalDuration : 1,
                                  onChanged: (value) {
                                    setState(() {
                                      _currentPosition = value;
                                    });
                                  },
                                  onChangeEnd: (value) async {
                                    // In a real app, you would seek to this position
                                    await platform.invokeMethod('seekTo', {"position": value});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Previous button
                        GestureDetector(
                          onTap: _playPreviousTrack,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.replay_10,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(width: 24),

                        // Play/Pause button
                        GestureDetector(
                          onTap: () {
                            if (_selectedMusic != null) {
                              _playPauseMusic(_selectedMusic!);
                            } else if (availableMusic.isNotEmpty) {
                              _playPauseMusic(availableMusic[0]["file"]!);
                            }
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              (_isPlaying && !_isPaused) ? Icons.pause : Icons.play_arrow,
                              color: Color(0xFF7E30E1),
                              size: 40,
                            ),
                          ),
                        ),

                        SizedBox(width: 24),

                        // Next button
                        GestureDetector(
                          onTap: _playNextTrack,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.forward_10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom area for track selection (hidden by default)
              GestureDetector(
                onTap: () {
                  _showTrackSelectionSheet(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue_music, color: Colors.white70),
                      SizedBox(width: 8),
                      Text(
                        "View Playlist",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF7E30E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "🎶 Available Tracks",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...availableMusic.map((music) => ListTile(
                    title: Text(
                      music["title"]!,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      music["artist"]!,
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        (_isPlaying && _selectedMusic == music["file"])
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => _playPauseMusic(music["file"]!),
                    ),
                  )),
                  SizedBox(height: 20),
                  Text(
                    "📂 Upload Custom Track",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickMusic();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF7E30E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text("Choose Music File"),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animation;
  final bool isPlaying;

  WaveformPainter({required this.animation, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the background circle
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw the waveform layers
    final colors = [
      Color(0xFFFFB6C1).withOpacity(0.7),  // Light pink
      Color(0xFFFF69B4).withOpacity(0.8),  // Hot pink
      Color(0xFFFF1493).withOpacity(0.9),  // Deep pink
    ];

    for (int i = 0; i < colors.length; i++) {
      final waveHeight = radius * 0.6 - (i * radius * 0.15);
      final amplitude = isPlaying ? waveHeight * 0.3 : waveHeight * 0.1;
      final frequency = 6.0 + i * 2.0;
      final phase = animation * 2 * 3.14159 + (i * 3.14159 / 3);

      final wavePaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, size.height / 2 + amplitude * 0.2);

      for (double x = 0; x < size.width; x++) {
        final y = size.height / 2 +
            amplitude * sin((x / size.width) * frequency * 3.14159 + phase) *
                (0.5 + 0.5 * sin((x / size.width) * 2 * 3.14159));
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.isPlaying != isPlaying;
  }
}

class WaveformProgressPainter extends CustomPainter {
  final double progress;

  WaveformProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Generate random heights for the waveform bars
    final random = List.generate(
        100,
            (index) => (0.2 + 0.8 * (0.5 + 0.5 * sin(index * 0.2))) * height
    );

    final barWidth = width / random.length;
    final progressWidth = width * progress;

    // Draw inactive waveform
    final inactivePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw active waveform
    final activePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < random.length; i++) {
      final x = i * barWidth;
      final barHeight = random[i];
      final rect = Rect.fromLTWH(
          x,
          (height - barHeight) / 2,
          barWidth * 0.6,
          barHeight
      );

      if (x <= progressWidth) {
        canvas.drawRect(rect, activePaint);
      } else {
        canvas.drawRect(rect, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(WaveformProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
