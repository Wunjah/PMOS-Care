import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/gemini_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'appointment_booking_screen.dart';

class SpecialistDirectoryScreen extends StatefulWidget {
  const SpecialistDirectoryScreen({super.key});

  @override
  State<SpecialistDirectoryScreen> createState() => _SpecialistDirectoryScreenState();
}

class _SpecialistDirectoryScreenState extends State<SpecialistDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All Specialists';

  final List<String> _categories = [
    'All Specialists',
    'PCOS Experts',
    'Endocrinology',
    'Gynecologists',
    'Nutritionists',
  ];

  final List<Map<String, dynamic>> _specialists = [
    {
      'name': 'Dr. Elena Rossi',
      'title': 'Senior Endocrinologist',
      'specialty': 'Endocrinology',
      'rating': 4.9,
      'reviews': 142,
      'experience': '12 years exp',
      'location': 'Yaoundé Central Hospital',
      'nextSlot': 'Tomorrow, 10:00 AM',
      'verified': true,
      'pcosExpert': true,
      'initials': 'ER',
      'avatarColor': Colors.indigo,
      'phone': '+237654376334',
    },
    {
      'name': 'Dr. Marcus Thorne',
      'title': 'Consultant OB-GYN',
      'specialty': 'Gynecologists',
      'rating': 4.8,
      'reviews': 98,
      'experience': '15 years exp',
      'location': 'Douala General Hospital',
      'nextSlot': 'Wednesday, 2:30 PM',
      'verified': true,
      'pcosExpert': true,
      'initials': 'MT',
      'avatarColor': Colors.purple,
      'phone': '+237678901234',
    },
    {
      'name': 'Sarah Jenkins, RD',
      'title': 'PCOS Nutrition Specialist',
      'specialty': 'Nutritionists',
      'rating': 4.7,
      'reviews': 85,
      'experience': '8 years exp',
      'location': 'Clara Health Clinic',
      'nextSlot': 'Thursday, 9:00 AM',
      'verified': true,
      'pcosExpert': false,
      'initials': 'SJ',
      'avatarColor': Colors.teal,
      'phone': '+237690123456',
    },
  ];

  // Chatbot State
  final _aiTextController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {
      'role': 'assistant',
      'message': 'Welcome to PMOS Care AI Health Coach! I am here to help you understand hormone patterns, low-glycemic dietary choices in Cameroon, activity streaks, and clinical reminders. Ask me anything about PMOS management.'
    }
  ];
  bool _isAiTyping = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApiKey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiTextController.dispose();
    super.dispose();
  }

  String _apiKey = '';

  Future<void> _loadApiKey() async {
    await GeminiService().loadApiKey();
    setState(() {
      _apiKey = GeminiService().apiKey;
    });
  }

  Future<void> _saveApiKey(String key) async {
    await GeminiService().saveApiKey(key);
    setState(() {
      _apiKey = key;
    });
  }

  Future<String> _getGeminiResponse(String query) async {
    if (_apiKey.isEmpty) {
      return _getRAGResponse(query);
    }

    try {
      const systemInstruction =
          "You are the PMOS Care AI Health Coach, an expert educational support agent specializing in Polyendocrine Metabolic Ovarian Syndrome (PMOS) and PCOS for women in Cameroon. "
          "Your task is to provide clinical-quality educational insights, focusing on low-glycemic dietary choices, weight/metabolic management, medication adherence (e.g. Metformin/Spironolactone), and cycle tracking. "
          "All meal recommendations and dietary advice MUST focus exclusively on traditional Cameroonian cuisine (such as rice and stew, fufu and njama njama, eru, ndole, achu, etc.). "
          "If you do not have specific information about a food item, dish, or request, or if the user asks for a broader database, you MUST provide a friendly suggestion to reference an existing database of Cameroonian dishes online (such as https://www.cameroonweb.com/CameroonHomePage/food/ or a search engine query for Cameroon food recipes). "
          "Keep your tone supportive, clinical, and clear. Explicitly remind the user in each message that you are an educational support tool, not a doctor.";

      final response = await GeminiService().queryGemini(query, systemInstruction: systemInstruction);
      return response.isNotEmpty ? response : "Google AI returned empty response.";
    } catch (e) {
      return "Network error connecting to Google AI: $e";
    }
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    final message = "Hello $name, I am contacting you from PMOS Care regarding a consultation.";
    final url = Uri.parse("https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _sendChatMessage() async {
    final query = _aiTextController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'message': query});
      _aiTextController.clear();
      _isAiTyping = true;
    });

    final response = await _getGeminiResponse(query);
    if (!mounted) return;
    setState(() {
      _chatMessages.add({'role': 'assistant', 'message': response});
      _isAiTyping = false;
    });
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Configure Google Gemini API Key',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your Google Gemini API Key below. This key is shared across AI boards and stored securely in local preferences.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                 controller: controller,
                 obscureText: true,
                 decoration: const InputDecoration(
                   labelText: 'API Key',
                   border: OutlineInputBorder(),
                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 ),
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveApiKey('');
                Navigator.pop(context);
              },
              child: const Text('Clear Key'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveApiKey(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getRAGResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('metformin') ||
        q.contains('spironolactone') ||
        q.contains('medication') ||
        q.contains('meds')) {
      return "Metformin helps manage insulin resistance by increasing muscle sensitivity to insulin. Spironolactone targets high androgen levels, reducing severe acne and hirsutism. Always log your medication compliance daily on the Medication tab, and consult your Ob-Gyn for clinical prescriptions.";
    }

    if (q.contains('fufu') ||
        q.contains('njama') ||
        q.contains('eru') ||
        q.contains('ndole') ||
        q.contains('achu') ||
        q.contains('stew') ||
        q.contains('rice') ||
        q.contains('cassava') ||
        q.contains('plantain') ||
        q.contains('staple') ||
        q.contains('eating') ||
        q.contains('carb') ||
        q.contains('diet') ||
        q.contains('food')) {
      return "In Cameroon, traditional cassava fufu has a high Glycemic Index (~85) which spikes insulin and worsens PMOS. We highly recommend swapping it with boiled unripe green plantains or oatmeal/plantain fufu. For njama njama or eru, cook with minimal red palm oil. For rice and stew, use local red or brown rice instead of white rice. For more details on Cameroonian dishes and recipes, you can reference the online database: https://www.cameroonweb.com/CameroonHomePage/food/";
    }

    if (q.contains('hirsutism') ||
        q.contains('hair') ||
        q.contains('ferriman') ||
        q.contains('fg')) {
      return "Hirsutism is excess body/facial hair growth caused by high levels of circulating free androgens. Clinicians measure this using the Ferriman-Gallwey (FG) scale (0-36). Log your FG score in the Symptom tab to track improvements. Low-GI diets and medications like Spironolactone are typical approaches.";
    }

    if (q.contains('acne') || q.contains('skin') || q.contains('tags') || q.contains('acanthosis')) {
      return "Acne, Acanthosis Nigricans (dark velvety skin patches), and skin tags are visual indicators of high insulin levels. Lowering dietary refined sugar and starchy carbs directly reduces skin flareups by improving glycemic control. Track these markers in the Symptom Logger daily.";
    }

    if (q.contains('exercise') || q.contains('workout') || q.contains('running') || q.contains('walking')) {
      return "Aerobic exercises like walking and running, combined with home or gym strength workouts, help muscle cells take up glucose without needing excess insulin. This is a powerful natural way to reverse insulin resistance. Try keeping an active workout streak in the Activity Tracker!";
    }

    if (q.contains('bloating') || q.contains('pain') || q.contains('cramp')) {
      return "Pelvic pain and abdominal bloating can be related to ovulation changes or hormonal imbalances in PCOS/PMOS. Track their severity (scale 1-5) on the Symptom Logger. Reducing processed foods and staying hydrated helps manage bloating. Severe, persistent pain warrants a visit to your Ob-Gyn.";
    }

    return "Hello! I can guide you on Cameroonian low-GI nutrition swaps (like fufu & njama njama, Ndole, Eru, and rice & stew), androgen excess symptoms, metabolic activities, and medication patterns. Note that I am an educational support assistant, not a doctor. For a full Cameroonian recipe database, visit: https://www.cameroonweb.com/CameroonHomePage/food/";
  }

  @override
  Widget build(BuildContext context) {
    final filteredSpecialists = _specialists.where((spec) {
      final matchesSearch = spec['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          spec['title'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCat = _selectedCategory == 'All Specialists' ||
          spec['specialty'] == _selectedCategory ||
          (_selectedCategory == 'PCOS Experts' && spec['pcosExpert'] == true);

      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'Specialists & AI Coach',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryWellness,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryWellness,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Find Specialist'),
            Tab(icon: Icon(Icons.psychology_outlined), text: 'AI Health Coach'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Find Specialist
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search doctors, specialties, locations...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedCategory = cat);
                                }
                              },
                              selectedColor: AppTheme.primaryWellness,
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide(
                                  color: isSelected ? AppTheme.primaryWellness : Colors.grey.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              showCheckmark: false,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredSpecialists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No specialists found',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try modifying your search or filter options',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSpecialists.length,
                        itemBuilder: (context, index) {
                          final spec = filteredSpecialists[index];
                          return _buildSpecialistCard(spec);
                        },
                      ),
              ),
            ],
          ),

          // Tab 2: AI Health Coach Chatbot
          Column(
            children: [
              // Medical Disclaimer Overlay
              Container(
                color: Colors.amber.shade50,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Disclaimer: PMOS Care AI Coach is an informational support tool and does not provide medical diagnostics, treatments, or prescriptions. Please consult with your healthcare provider for clinical decisions.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: _apiKey.isEmpty ? Colors.blue.shade50 : Colors.green.shade50,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _apiKey.isEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: _apiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _apiKey.isEmpty
                            ? 'Offline Mode (Local facts only). Set Google Gemini API key to chat.'
                            : 'Google AI Gemini Live (Active Connection)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _apiKey.isEmpty ? Colors.blue.shade900 : Colors.green.shade900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      onPressed: _showApiKeyDialog,
                      icon: Icon(
                        Icons.settings,
                        color: _apiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800,
                        size: 16,
                      ),
                      label: Text(
                        'Configure',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _apiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primaryWellness : Colors.white,
                          border: isUser ? null : Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'YOU' : 'AI COACH',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUser ? Colors.white70 : AppTheme.primaryWellness,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['message'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isUser ? Colors.white : AppTheme.textDark,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isAiTyping)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI Coach is typing...',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              // Chat Send Box
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aiTextController,
                        decoration: const InputDecoration(
                          hintText: 'Ask AI Coach about meals, symptoms...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primaryWellness),
                      onPressed: _sendChatMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(Map<String, dynamic> spec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: spec['avatarColor'] as Color,
                  child: Text(
                    spec['initials'] as String,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            spec['name'] as String,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (spec['verified'] == true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppTheme.primaryWellness, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spec['title'] as String,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${spec['rating']} (${spec['reviews']} reviews)',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.circle, size: 4, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            spec['experience'] as String,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spec['location'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Availability',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec['nextSlot'] as String,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryWellness,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                      tooltip: 'Chat on WhatsApp',
                      onPressed: () => _launchWhatsApp(spec['phone'] as String, spec['name'] as String),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(120, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentBookingScreen(specialist: spec),
                          ),
                        );
                      },
                      child: const Text(
                        'Book Now',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
