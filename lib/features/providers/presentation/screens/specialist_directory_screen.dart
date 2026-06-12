import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/ai_service.dart';
import 'appointment_booking_screen.dart';

const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kMutedText = Color(0xFF777684);
const _kBg = Color(0xFFF8F9FF);
const _kDivider = Color(0xFFE7E8EE);

class SpecialistDirectoryScreen extends StatefulWidget {
  const SpecialistDirectoryScreen({super.key});

  @override
  State<SpecialistDirectoryScreen> createState() => _SpecialistDirectoryScreenState();
}

class _SpecialistDirectoryScreenState extends State<SpecialistDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _aiApiKey = '';

  final List<String> _categories = ['All', 'PCOS Experts', 'Endocrinology', 'Gynecology', 'Nutrition'];

  final List<Map<String, dynamic>> _specialists = [
    {
      'name': 'Dr. Elena Rossi',
      'title': 'Senior Endocrinologist',
      'specialty': 'Endocrinology',
      'rating': 4.9,
      'reviews': 142,
      'experience': '12 yrs',
      'location': 'Yaoundé Central Hospital',
      'nextSlot': 'Tomorrow, 10:00 AM',
      'verified': true,
      'pcosExpert': true,
      'initials': 'ER',
      'avatarColor': _kPrimary,
      'phone': '+237654376334',
      'email': 'dr.rossi@pmoscare.cm',
      'specialty_tag': 'PCOS Experts',
    },
    {
      'name': 'Dr. Marcus Thorne',
      'title': 'Consultant OB-GYN',
      'specialty': 'Gynecology',
      'rating': 4.8,
      'reviews': 98,
      'experience': '15 yrs',
      'location': 'Douala General Hospital',
      'nextSlot': 'Wed, 2:30 PM',
      'verified': true,
      'pcosExpert': true,
      'initials': 'MT',
      'avatarColor': Colors.purple,
      'phone': '+237678901234',
      'email': 'dr.thorne@pmoscare.cm',
      'specialty_tag': 'Gynecology',
    },
    {
      'name': 'Sarah Jenkins, RD',
      'title': 'PCOS Nutrition Specialist',
      'specialty': 'Nutrition',
      'rating': 4.7,
      'reviews': 85,
      'experience': '8 yrs',
      'location': 'Clara Health Clinic, Bafoussam',
      'nextSlot': 'Thu, 9:00 AM',
      'verified': true,
      'pcosExpert': false,
      'initials': 'SJ',
      'avatarColor': Colors.teal,
      'phone': '+237690123456',
      'email': 'sarah.jenkins@pmoscare.cm',
      'specialty_tag': 'Nutrition',
    },
    {
      'name': 'Dr. Adjoua Mbeki',
      'title': 'PMOS Specialist & Gynecologist',
      'specialty': 'PCOS Experts',
      'rating': 4.9,
      'reviews': 203,
      'experience': '18 yrs',
      'location': 'Bamenda Regional Hospital',
      'nextSlot': 'Fri, 11:00 AM',
      'verified': true,
      'pcosExpert': true,
      'initials': 'AM',
      'avatarColor': Colors.deepOrange,
      'phone': '+237681234567',
      'email': 'dr.mbeki@pmoscare.cm',
      'specialty_tag': 'PCOS Experts',
    },
  ];

  final _aiTextController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();
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
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    await AIService().loadApiKey();
    if (mounted) setState(() => _aiApiKey = AIService().apiKey);
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    final msg = 'Hello $name, I am contacting you from PMOS Care regarding a consultation.';
    final url = Uri.parse('https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(msg)}');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _sendChatMessage() async {
    final query = _aiTextController.text.trim();
    if (query.isEmpty || _isAiTyping) return;
    _aiTextController.clear();
    setState(() {
      _chatMessages.add({'role': 'user', 'content': query});
      _isAiTyping = true;
      _chatMessages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();

    const systemPrompt =
        'You are the PMOS Care AI Health Coach, specializing in PMOS/PCOS for women in Cameroon. '
        'Give educational insights on diet (Cameroonian foods: ndolè, fufu, njama njama, eru, achu), '
        'medication adherence, cycle tracking, and metabolic management. '
        'Always remind users you are an educational tool, not a doctor. Be warm and supportive.';

    final history = _chatMessages
        .where((m) => m['content']!.isNotEmpty)
        .take(_chatMessages.length - 1)
        .map((m) => {'role': m['role']!, 'content': m['content']!})
        .toList();

    final stream = AIService().queryStream(history, systemPrompt: systemPrompt);
    await for (final token in stream) {
      if (!mounted) break;
      setState(() {
        final last = _chatMessages.last;
        _chatMessages[_chatMessages.length - 1] = {'role': 'assistant', 'content': last['content']! + token};
        _isAiTyping = false;
      });
      _scrollToBottom();
    }
    if (mounted) setState(() => _isAiTyping = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog() {
    final ctrl = TextEditingController(text: _aiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Configure AI Key', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Groq API Key (gsk_...)',
                border: OutlineInputBorder(),
                hintText: 'gsk_xxxxxxxxxxxx',
              ),
            ),
            const SizedBox(height: 8),
            const Text('Free key from console.groq.com', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () async {
              await AIService().saveApiKey(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() => _aiApiKey = ctrl.text.trim());
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered => _specialists.where((s) {
        final matchSearch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final matchCat = _selectedCategory == 'All' ||
            s['specialty_tag'] == _selectedCategory ||
            s['specialty'] == _selectedCategory;
        return matchSearch && matchCat;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSpecialistTab(),
                _buildAiCoachTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, Color(0xFF6C6DD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Find Specialists',
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Book verified PMOS healthcare providers',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('4 Verified', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Specialists'),
                Tab(icon: Icon(Icons.psychology_outlined, size: 18), text: 'AI Health Coach'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistTab() {
    final filtered = _filtered;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kDivider),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search doctors, specialties...',
                    hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kMutedText),
                    prefixIcon: const Icon(Icons.search, color: _kMutedText, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18, color: _kMutedText), onPressed: () => setState(() => _searchQuery = ''))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category chips
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? _kPrimary : _kBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: selected ? _kPrimary : _kDivider),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? Colors.white : _kDarkText,
                              )),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No specialists found', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildSpecialistCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSpecialistCard(Map<String, dynamic> spec) {
    final color = spec['avatarColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(spec['initials'] as String,
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    ),
                    if (spec['verified'] == true)
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified, color: _kPrimary, size: 16),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(spec['name'] as String,
                                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold, color: _kDarkText)),
                          ),
                          if (spec['pcosExpert'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF5152B9).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: const Text('PMOS Expert', style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: _kPrimary, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(spec['title'] as String,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text('${spec['rating']}',
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: _kDarkText)),
                          Text(' (${spec['reviews']})', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
                          const SizedBox(width: 10),
                          const Icon(Icons.work_outline, size: 12, color: _kMutedText),
                          const SizedBox(width: 3),
                          Text(spec['experience'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: _kMutedText),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(spec['location'] as String,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kMutedText),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: _kPrimary),
                const SizedBox(width: 6),
                Text('Next available: ', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kMutedText)),
                Text(spec['nextSlot'] as String,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: _kPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF25D366))),
                    onPressed: () => _launchWhatsApp(spec['phone'] as String, spec['name'] as String),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: const Text('Book Now', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentBookingScreen(specialist: spec))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCoachTab() {
    return Column(
      children: [
        // Disclaimer
        Container(
          color: Colors.amber.shade50,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Educational tool only — not a medical diagnosis.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
        // API key status
        GestureDetector(
          onTap: _showApiKeyDialog,
          child: Container(
            color: _aiApiKey.isEmpty ? Colors.blue.shade50 : Colors.green.shade50,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _aiApiKey.isEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size: 15,
                  color: _aiApiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiApiKey.isEmpty ? 'Tap to set Groq API key — get free key at console.groq.com' : 'AI Coach Active (Groq LLM)',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                        color: _aiApiKey.isEmpty ? Colors.blue.shade900 : Colors.green.shade900),
                  ),
                ),
                Text('Configure', style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: _aiApiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        // Messages
        Expanded(
          child: _chatMessages.isEmpty
              ? _buildCoachWelcome()
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (_, i) {
                    final msg = _chatMessages[i];
                    final isUser = msg['role'] == 'user';
                    final content = msg['content'] ?? '';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isUser ? _kPrimary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                          border: isUser ? null : Border.all(color: _kDivider),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: content.isEmpty && !isUser
                            ? const SizedBox(height: 16, width: 40, child: LinearProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isUser ? 'YOU' : 'AI COACH',
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: isUser ? Colors.white60 : _kPrimary)),
                                  const SizedBox(height: 4),
                                  Text(content,
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: isUser ? Colors.white : _kDarkText, height: 1.5)),
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ),
        if (_isAiTyping)
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 4),
            child: Row(children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('AI Coach is typing...', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
            ]),
          ),
        // Input bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _kDivider),
                  ),
                  child: TextField(
                    controller: _aiTextController,
                    onSubmitted: (_) => _sendChatMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask about PMOS, meals, symptoms...',
                      hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kMutedText),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChatMessage,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kPrimary, Color(0xFF6C6DD1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('AI Health Coach', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: _kDarkText)),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about PMOS, Cameroonian foods, medications, and lifestyle tips.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _kMutedText, height: 1.5),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: ['What is PMOS?', 'Foods to avoid?', 'Managing insulin?', 'Exercise tips?'].map((q) => GestureDetector(
                onTap: () { _aiTextController.text = q; _sendChatMessage(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _kPrimary.withOpacity(0.2)),
                  ),
                  child: Text(q, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
