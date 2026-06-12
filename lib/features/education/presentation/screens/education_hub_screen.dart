import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class EducationHubScreen extends StatefulWidget {
  const EducationHubScreen({super.key});

  @override
  State<EducationHubScreen> createState() => _EducationHubScreenState();
}

class _EducationHubScreenState extends State<EducationHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Video player state
  bool _isPlayingVideo = false;
  Map<String, dynamic>? _activeVideo;
  bool _isPaused = false;
  double _videoProgress = 0.0;
  Timer? _videoTimer;

  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Understanding PCOS & Insulin Resistance',
      'category': 'Hormones',
      'readTime': '6 min read',
      'summary': 'Insulin resistance is a key driver of PCOS symptoms in over 70% of cases. Learn how to manage it with simple dietary changes.',
      'content': 'Polycystic Ovary Syndrome (PCOS) is a common hormonal condition that affects women of reproductive age. A primary underlying cause for many women with PCOS is insulin resistance. This is when the cells of the body do not respond properly to the hormone insulin, leading to high glucose levels in the bloodstream. Consequently, the pancreas produces even more insulin.\n\nElevated insulin levels stimulate the ovaries to produce excess androgens (male hormones), which can disrupt menstrual cycles, impair ovulation, and cause issues like acne and excess hair growth.\n\n### Key Dietary Strategies:\n1. **Focus on Low Glycemic Index (GI) Foods:** Eat whole grains, legumes, and non-starchy vegetables that digest slowly, helping prevent blood sugar spikes.\n2. **Combine Macronutrients:** Always pair carbohydrates with healthy fats or lean proteins to slow glucose absorption.\n3. **Stay Active:** Exercise helps muscle cells absorb glucose directly from the bloodstream, bypassing the need for high insulin levels.',
      'author': 'Dr. Elena Rossi, Endocrinologist',
      'tags': ['PCOS', 'Insulin', 'Diet'],
      'youtubeUrl': 'https://www.youtube.com/results?search_query=PCOS+and+Insulin+Resistance+education',
    },
    {
      'title': 'Low-GI Cameroonian Swaps for PCOS Relief',
      'category': 'Nutrition',
      'readTime': '5 min read',
      'summary': 'Discover healthy alternatives to high-GI local staples like white garri and cassava fufu to stabilize your hormones.',
      'content': 'Many traditional Cameroonian dishes are delicious but rich in refined carbohydrates. For women managing PCOS, standard white cassava fufu or large helpings of white rice can cause sharp spikes in blood glucose and insulin levels.\n\nFortunately, you don\'t have to abandon your culinary heritage to heal your body. By making strategic swaps and modifying recipes, you can enjoy Cameroonian flavors while keeping your blood sugar stable.\n\n### Healthy Swaps:\n* **Plantain Fufu (Unripe):** Unripe green plantains have a lower glycemic index than fully ripe ones or cassava flour. Grated and prepared fufu from green plantain is a superior alternative.\n* **Brown Rice or Whole Millet:** Instead of white rice, pair Ndole or Eru with brown rice or cooked whole millet.\n* **Increase Vegetable Volume:** When preparing meals like Ndole, increase the ratio of bitterleaf and cut back on added refined oils or processed meats. Focus on lean chicken, fish, or groundnut paste in moderate quantities.',
      'author': 'Sarah Jenkins, Nutritionist',
      'tags': ['Nutrition', 'Cameroon', 'Recipes'],
      'youtubeUrl': 'https://www.youtube.com/results?search_query=Low+GI+Cameroon+food+swaps+PCOS',
    },
    {
      'title': 'Exercise & PCOS: What Works Best?',
      'category': 'Fitness',
      'readTime': '4 min read',
      'summary': 'Not all exercises are equal for hormone balance. Learn how high-intensity vs. strength training affects cortisol.',
      'content': 'Exercise is a powerful tool to enhance insulin sensitivity and manage PCOS. However, intense, prolonged workouts can sometimes spike cortisol (the stress hormone), which can counteract hormonal balance in some women.\n\n### 1. Strength Training\nBuilding lean muscle mass is excellent for PCOS because muscles consume the majority of glucose in the body. Two to three sessions of resistance training per week can significantly lower insulin resistance.\n\n### 2. Low-Intensity Steady State (LISS)\nWalking, swimming, or light cycling for 30–45 minutes is highly effective. It helps lower insulin and cortisol simultaneously without putting the body under high stress.\n\n### 3. Yoga & Core Stability\nYoga helps reduce chronic stress levels, which are often elevated in women with PCOS. It improves autonomic nervous system balance and can aid sleep quality.',
      'author': 'Coach Marcus Thorne, Fitness Specialist',
      'tags': ['Fitness', 'Exercise', 'Hormones'],
      'youtubeUrl': 'https://www.youtube.com/results?search_query=Best+exercise+workout+for+PCOS+and+hormones',
    },
  ];

  final List<Map<String, dynamic>> _videos = [
    {
      'title': 'Demystifying Androgens & Cyst Formation',
      'tutor': 'Dr. Elena Rossi',
      'duration': '12:45',
      'durationSec': 765,
      'description': 'A detailed medical explanation of how hormonal imbalances lead to typical PCOS ultrasound features and physical symptoms.',
      'thumbnailColor': AppTheme.primaryWellness,
    },
    {
      'title': 'PCOS Grocery Shopping Guide in Yaoundé',
      'tutor': 'Sarah Jenkins, RD',
      'duration': '08:30',
      'durationSec': 510,
      'description': 'Walk through local markets to identify low-GI vegetables, healthy fats, and high-quality protein choices.',
      'thumbnailColor': AppTheme.brandActive,
    },
    {
      'title': 'Hormone-Balancing 15-Minute Home Yoga Flow',
      'tutor': 'Coach Leila Kamga',
      'duration': '15:20',
      'durationSec': 920,
      'description': 'A gentle, stress-reducing yoga sequence designed to support fertility and lower evening cortisol levels.',
      'thumbnailColor': AppTheme.accentMenstrual,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoTimer?.cancel();
    super.dispose();
  }

  void _startVideoTimer() {
    _videoTimer?.cancel();
    _videoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlayingVideo && !_isPaused) {
        setState(() {
          _videoProgress += 0.01;
          if (_videoProgress >= 1.0) {
            _videoProgress = 0.0;
            _isPaused = true;
            _videoTimer?.cancel();
          }
        });
      }
    });
  }

  void _playVideo(Map<String, dynamic> video) {
    setState(() {
      _activeVideo = video;
      _isPlayingVideo = true;
      _isPaused = false;
      _videoProgress = 0.0;
    });
    _startVideoTimer();
  }

  void _closeVideo() {
    _videoTimer?.cancel();
    setState(() {
      _isPlayingVideo = false;
      _activeVideo = null;
      _videoProgress = 0.0;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _startVideoTimer();
      } else {
        _videoTimer?.cancel();
      }
    });
  }

  void _seekVideo(double val) {
    setState(() {
      _videoProgress = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Education Hub',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryWellness,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryWellness,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Articles & Insights', icon: Icon(Icons.article_outlined)),
            Tab(text: 'Video Lectures', icon: Icon(Icons.video_library_outlined)),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildArticlesTab(),
              _buildVideosTab(),
            ],
          ),
          if (_isPlayingVideo && _activeVideo != null) _buildVideoOverlay(),
        ],
      ),
    );
  }

  Widget _buildArticlesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () async {
              final url = Uri.parse(article['youtubeUrl'] as String);
              final messenger = ScaffoldMessenger.of(context);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not launch: $url')),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article['category'],
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppTheme.primaryWellness,
                          ),
                        ),
                      ),
                      Text(
                        article['readTime'],
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article['summary'],
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        article['author'],
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Text(
                        'Read Article',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryWellness,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryWellness),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Thumbnail
                GestureDetector(
                  onTap: () => _playVideo(video),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 85,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (video['thumbnailColor'] as Color).withOpacity(0.8),
                              video['thumbnailColor'] as Color,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: AppTheme.primaryWellness, size: 20),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video['duration'],
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Video info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instructor: ${video['tutor']}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _playVideo(video),
                        child: const Row(
                          children: [
                            Icon(Icons.play_circle_fill, size: 16, color: AppTheme.primaryWellness),
                            SizedBox(width: 4),
                            Text(
                              'Watch Lecture',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryWellness,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildVideoOverlay() {
    final video = _activeVideo!;
    final progressSec = (_videoProgress * video['durationSec']).round();
    final minutes = (progressSec ~/ 60).toString().padLeft(2, '0');
    final seconds = (progressSec % 60).toString().padLeft(2, '0');

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player Area
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade800, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated visualizer / screenshare
                    AnimatedBuilder(
                      animation: _isPlayingVideo ? const AlwaysStoppedAnimation(0) : const AlwaysStoppedAnimation(0),
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade900,
                                (video['thumbnailColor'] as Color).withOpacity(_isPaused ? 0.3 : 0.6),
                                Colors.grey.shade900,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _isPaused ? Icons.pause_circle_outline : Icons.play_circle_outline,
                              color: Colors.white30,
                              size: 72,
                            ),
                          ),
                        );
                      },
                    ),
                    // HUD Controls
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: _closeVideo,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, size: 12, color: Colors.greenAccent),
                            SizedBox(width: 4),
                            Text(
                              'Secure HIPAA Stream',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Video duration bar at the bottom of video screen
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.black.withOpacity(0.5),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$minutes:$seconds',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: _videoProgress,
                                  activeColor: AppTheme.primaryWellness,
                                  inactiveColor: Colors.white24,
                                  onChanged: _seekVideo,
                                ),
                              ),
                            ),
                            Text(
                              video['duration'],
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Video details card
              Card(
                color: AppTheme.cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${video['tutor']}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video['description'],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Lectures'),
                onPressed: _closeVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
