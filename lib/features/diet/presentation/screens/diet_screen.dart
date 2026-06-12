import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/ai_service.dart';
import '../providers/diet_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kBodyText = Color(0xFF464552);
const _kMutedText = Color(0xFF777684);
const _kBg = Color(0xFFF8F9FF);
const _kDivider = Color(0xFFE7E8EE);
const _kTealDark = Color(0xFF00696A);
const _kTealBg = Color(0x1A45A8A9);
const _kTealBorder = Color(0x3345A8A9);
const _kTeal = Color(0xFF45A8A9);
const _kProgressTrack = Color(0xFFECEEF3);

// ── Recommended meal data ─────────────────────────────────────────────────────
class _RecommendedMeal {
  final String name;
  final String subtitle;
  final int calories;
  final List<Color> gradient;
  final IconData icon;
  final String badge;
  final Color badgeColor;

  const _RecommendedMeal({
    required this.name,
    required this.subtitle,
    required this.calories,
    required this.gradient,
    required this.icon,
    required this.badge,
    required this.badgeColor,
  });
}

const _kMeals = [
  _RecommendedMeal(
    name: 'Ndolè',
    subtitle: 'Bitterleaf Stew',
    calories: 285,
    gradient: [Color(0xFF2D6A4F), Color(0xFF52B788)],
    icon: Icons.eco,
    badge: 'PMOS-Friendly',
    badgeColor: Color(0xFF2D6A4F),
  ),
  _RecommendedMeal(
    name: 'Eru & Waterleaf',
    subtitle: 'Iron-rich greens',
    calories: 210,
    gradient: [Color(0xFF1B4332), Color(0xFF40916C)],
    icon: Icons.spa,
    badge: 'High Fiber',
    badgeColor: Color(0xFF1B4332),
  ),
  _RecommendedMeal(
    name: 'Njama Njama',
    subtitle: 'Huckleberry greens',
    calories: 165,
    gradient: [Color(0xFF023E8A), Color(0xFF0096C7)],
    icon: Icons.local_florist,
    badge: 'Low GI',
    badgeColor: Color(0xFF023E8A),
  ),
  _RecommendedMeal(
    name: 'Grilled Fish',
    subtitle: 'Omega-3 & protein',
    calories: 320,
    gradient: [Color(0xFF9D4EDD), Color(0xFFC77DFF)],
    icon: Icons.set_meal,
    badge: 'High Protein',
    badgeColor: Color(0xFF9D4EDD),
  ),
  _RecommendedMeal(
    name: 'Plantain Fufu',
    subtitle: 'Low-GI staple',
    calories: 240,
    gradient: [Color(0xFFD4A017), Color(0xFFE9C46A)],
    icon: Icons.grain,
    badge: 'Energy',
    badgeColor: Color(0xFFB7791F),
  ),
  _RecommendedMeal(
    name: 'Achu Soup',
    subtitle: 'Cocoyam & spices',
    calories: 310,
    gradient: [Color(0xFFAE2012), Color(0xFFE85D04)],
    icon: Icons.soup_kitchen,
    badge: 'Traditional',
    badgeColor: Color(0xFFAE2012),
  ),
];

// ── Category chip data ────────────────────────────────────────────────────────
const _categoryLabels = <String, String>{
  'All': 'All',
  'leafy_vegetables': 'Leafy Veg',
  'starchy_staples': 'Staples',
  'proteins': 'Proteins',
  'fruits': 'Fruits',
  'soups_stews': 'Soups & Stews',
  'drinks': 'Drinks',
  'cooking_fats': 'Fats',
  'snacks': 'Snacks',
};

// ── Screen ────────────────────────────────────────────────────────────────────
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSuitability = 'All';

  // AI Chef state
  final List<Map<String, String>> _chatMessages = [];
  final _chatController = TextEditingController();
  bool _isAiTyping = false;
  final ScrollController _chatScrollController = ScrollController();
  String _aiApiKey = '';

  // Meal log state
  final _mealTypeOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  String _selectedMealType = 'Breakfast';
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fiberController = TextEditingController();
  final _waterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAiKey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fiberController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _loadAiKey() async {
    await AIService().loadApiKey();
    if (mounted) setState(() => _aiApiKey = AIService().apiKey);
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isAiTyping) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _isAiTyping = true;
      _chatMessages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();

    const systemPrompt = '''You are "PMOS Chef", a warm and expert AI nutrition coach specialized in Cameroonian cuisine and managing Polycystic Ovarian Syndrome (PCOS/PMOS) through diet. You help users understand how local Cameroonian foods affect their hormonal health.

You give practical, culturally-sensitive advice about foods like ndolè, eru, njama njama, fufu, achu, plantains, garden eggs, bitter leaf, and other local dishes.

Always be encouraging, specific, and explain the nutritional science in simple terms. For any meal or food question, describe its nutritional benefits or drawbacks for PMOS and suggest healthier modifications.''';

    final history = _chatMessages
        .where((m) => m['content']!.isNotEmpty)
        .take(_chatMessages.length - 1)
        .toList();

    final stream = AIService().queryStream(history, systemPrompt: systemPrompt);
    await for (final chunk in stream) {
      if (!mounted) break;
      setState(() {
        final last = _chatMessages.last;
        _chatMessages[_chatMessages.length - 1] = {
          'role': 'assistant',
          'content': last['content']! + chunk,
        };
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

  Future<void> _logMeal() async {
    if (_foodNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name'), backgroundColor: Colors.red),
      );
      return;
    }

    await ref.read(mealLogStateNotifierProvider.notifier).addMealLog(
          mealType: _selectedMealType,
          foodName: _foodNameController.text.trim(),
          calories: double.tryParse(_caloriesController.text) ?? 0,
          proteinGrams: double.tryParse(_proteinController.text) ?? 0,
          fiberGrams: double.tryParse(_fiberController.text) ?? 0,
          waterMl: double.tryParse(_waterController.text) ?? 0,
          date: DateTime.now(),
        );

    _foodNameController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _fiberController.clear();
    _waterController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged!'), backgroundColor: Colors.green),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 120),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFoodGuideTab(),
                    _buildMealLogTab(),
                    _buildAiChefTab(),
                    _buildDietaryAdviceTab(),
                  ],
                ),
              ),
            ],
          ),
          _buildHeader(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final mealState = ref.watch(mealLogStateNotifierProvider);
    final todayMeals = mealState.mealLogs.where((m) {
      final now = DateTime.now();
      return m.timestamp.year == now.year && m.timestamp.month == now.month && m.timestamp.day == now.day;
    }).toList();

    final totalCal = todayMeals.fold<double>(0, (s, m) => s + m.calories);
    final totalProt = todayMeals.fold<double>(0, (s, m) => s + m.proteinGrams);
    final totalFiber = todayMeals.fold<double>(0, (s, m) => s + m.fiberGrams);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Your daily food guide',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            DateFormat('MMM d').format(DateTime.now()),
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildMiniStat('${totalCal.round()}', 'kcal', Icons.local_fire_department),
                        const SizedBox(width: 12),
                        _buildMiniStat('${totalProt.round()}g', 'protein', Icons.fitness_center),
                        const SizedBox(width: 12),
                        _buildMiniStat('${totalFiber.round()}g', 'fiber', Icons.grass),
                      ],
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

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kProgressTrack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500),
          labelColor: Colors.white,
          unselectedLabelColor: _kMutedText,
          indicator: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Food Guide'),
            Tab(text: 'Meal Log'),
            Tab(text: 'AI Chef'),
            Tab(text: 'Advice'),
          ],
        ),
      ),
    );
  }

  // ── Food Guide Tab ────────────────────────────────────────────────────────

  Widget _buildFoodGuideTab() {
    final foodsAsync = ref.watch(foodsProvider);
    return foodsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kPrimary)),
      error: (e, _) => Center(child: Text('Failed to load foods: $e')),
      data: (foods) {
        final filtered = foods.where((f) {
          final matchCat = _selectedCategory == 'All' || f.category == _selectedCategory;
          final matchSuit = _selectedSuitability == 'All' || f.suitability == _selectedSuitability;
          final matchQuery = _searchQuery.isEmpty || f.name.toLowerCase().contains(_searchQuery.toLowerCase()) || f.localName.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchCat && matchSuit && matchQuery;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildRecommendedSection()),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverToBoxAdapter(child: _buildSuitabilityChips()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '${filtered.length} foods',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildFoodCard(filtered[i]),
                childCount: filtered.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: _kDarkText),
        decoration: InputDecoration(
          hintText: 'Search Cameroonian foods...',
          hintStyle: const TextStyle(fontFamily: 'Inter', color: _kMutedText, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _kMutedText, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text('Recommended for You', style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.bold, color: _kDarkText)),
              Spacer(),
              Text('PMOS-optimised', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kMutedText)),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _kMeals.length,
            itemBuilder: (ctx, i) => _buildMealCard(_kMeals[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(_RecommendedMeal meal) {
    return Container(
      width: 152,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: meal.gradient.first.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: meal.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Icon
            Positioned(
              top: 20,
              right: 16,
              child: Icon(meal.icon, size: 52, color: Colors.white.withOpacity(0.85)),
            ),
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        meal.badge,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal.name,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      meal.subtitle,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 11, color: Colors.orangeAccent),
                        const SizedBox(width: 3),
                        Text(
                          '${meal.calories} kcal',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: _kDarkText)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categoryLabels.entries.map((e) => _buildFilterChip(
                label: e.value,
                selected: _selectedCategory == e.key,
                onTap: () => setState(() => _selectedCategory = e.key),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuitabilityChips() {
    const suitabilities = {'All': 'All', 'highly_recommended': 'Highly Rec.', 'moderate': 'Moderate', 'limit': 'Limit', 'avoid': 'Avoid'};
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suitability', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: _kDarkText)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: suitabilities.entries.map((e) {
                Color chipColor = _kPrimary;
                if (e.key == 'highly_recommended') chipColor = const Color(0xFF2D6A4F);
                if (e.key == 'moderate') chipColor = const Color(0xFFB7791F);
                if (e.key == 'limit') chipColor = Colors.orange;
                if (e.key == 'avoid') chipColor = Colors.red;
                return _buildFilterChip(
                  label: e.value,
                  selected: _selectedSuitability == e.key,
                  onTap: () => setState(() => _selectedSuitability = e.key),
                  selectedColor: chipColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final color = selectedColor ?? _kPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : _kDivider),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kMutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodItem food) {
    Color suitabilityColor = _kTeal;
    String suitabilityLabel = food.suitability;
    if (food.suitability == 'highly_recommended') {
      suitabilityColor = const Color(0xFF2D6A4F);
      suitabilityLabel = 'Highly Recommended';
    } else if (food.suitability == 'moderate') {
      suitabilityColor = const Color(0xFFB7791F);
      suitabilityLabel = 'Moderate';
    } else if (food.suitability == 'limit') {
      suitabilityColor = Colors.orange;
      suitabilityLabel = 'Limit';
    } else if (food.suitability == 'avoid') {
      suitabilityColor = Colors.red;
      suitabilityLabel = 'Avoid';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: suitabilityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant, color: suitabilityColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(food.name, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: _kDarkText)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: suitabilityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        suitabilityLabel,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: suitabilityColor),
                      ),
                    ),
                  ],
                ),
                if (food.localName.isNotEmpty && food.localName != food.name)
                  Text(food.localName, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text(food.explanation, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kBodyText), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Meal Log Tab ──────────────────────────────────────────────────────────

  Widget _buildMealLogTab() {
    final mealState = ref.watch(mealLogStateNotifierProvider);
    final today = DateTime.now();
    final todayMeals = mealState.mealLogs.where((m) =>
        m.timestamp.year == today.year && m.timestamp.month == today.month && m.timestamp.day == today.day).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddMealCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("Today's Meals", style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.bold, color: _kDarkText)),
              const Spacer(),
              Text('${todayMeals.length} logged', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
            ],
          ),
          const SizedBox(height: 12),
          if (mealState.isLoading)
            const Center(child: CircularProgressIndicator(color: _kPrimary))
          else if (todayMeals.isEmpty)
            _buildEmptyMeals()
          else
            ...todayMeals.map((m) => _buildMealLogItem(m)),
        ],
      ),
    );
  }

  Widget _buildAddMealCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Log a Meal', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: _kDarkText)),
            ],
          ),
          const SizedBox(height: 16),

          // Meal Type Selector
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _mealTypeOptions.map((type) => GestureDetector(
                onTap: () => setState(() => _selectedMealType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedMealType == type ? _kPrimary : _kProgressTrack,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedMealType == type ? Colors.white : _kMutedText,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Food Name (required)
          _buildInputField(
            controller: _foodNameController,
            label: 'Food Name *',
            hint: 'e.g. Ndolè with plantain',
            icon: Icons.restaurant,
            required: true,
          ),
          const SizedBox(height: 10),

          // Optional nutrition row
          const Text(
            'Nutrition (optional)',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _caloriesController, label: 'Calories', hint: 'kcal', icon: Icons.local_fire_department, numericOnly: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildInputField(controller: _proteinController, label: 'Protein', hint: 'g', icon: Icons.fitness_center, numericOnly: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildInputField(controller: _fiberController, label: 'Fiber', hint: 'g', icon: Icons.grass, numericOnly: true)),
            ],
          ),
          const SizedBox(height: 10),
          _buildInputField(controller: _waterController, label: 'Water (ml)', hint: '250', icon: Icons.water_drop, numericOnly: true),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log Meal', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool numericOnly = false,
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numericOnly ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kDarkText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText),
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kDivider),
        prefixIcon: Icon(icon, size: 16, color: _kMutedText),
        filled: true,
        fillColor: _kBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      ),
    );
  }

  Widget _buildEmptyMeals() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant_outlined, size: 40, color: _kMutedText),
          SizedBox(height: 12),
          Text('No meals logged today', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600, color: _kMutedText)),
          SizedBox(height: 4),
          Text('Use the form above to log your first meal', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kMutedText), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMealLogItem(dynamic meal) {
    final mealIcon = {
      'Breakfast': Icons.free_breakfast,
      'Lunch': Icons.lunch_dining,
      'Dinner': Icons.dinner_dining,
      'Snack': Icons.cookie,
    }[meal.mealType] ?? Icons.restaurant;

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(mealLogStateNotifierProvider.notifier).removeMealLog(meal.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(mealIcon, color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.foodName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: _kDarkText)),
                  Text(meal.mealType, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: _kMutedText)),
                ],
              ),
            ),
            if (meal.calories > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x15EB505E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 12, color: Color(0xFFEB505E)),
                    const SizedBox(width: 3),
                    Text('${meal.calories.round()} kcal', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFEB505E), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── AI Chef Tab ───────────────────────────────────────────────────────────

  Widget _buildAiChefTab() {
    return Column(
      children: [
        if (_aiApiKey.isEmpty) _buildApiKeyBanner(),
        Expanded(
          child: _chatMessages.isEmpty
              ? _buildChatWelcome()
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _chatMessages.length,
                  itemBuilder: (ctx, i) => _buildChatBubble(_chatMessages[i]),
                ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildApiKeyBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD048)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFB7791F), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Key Required', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB7791F))),
                Text('Get a free Groq API key at console.groq.com', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF92400E))),
              ],
            ),
          ),
          TextButton(
            onPressed: _showApiKeyDialog,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Set Key', style: TextStyle(fontSize: 12, color: Color(0xFF5152B9), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final ctrl = TextEditingController(text: _aiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Groq API Key', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'API Key (gsk_...)',
                border: OutlineInputBorder(),
                hintText: 'gsk_xxxxxxxxxxxx',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text('Get a free key at console.groq.com', style: TextStyle(fontSize: 12, color: _kMutedText)),
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

  Widget _buildChatWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.soup_kitchen, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'PMOS Chef',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: _kDarkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about Cameroonian foods, recipes, and how to eat well for PMOS management.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _kMutedText),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Is ndolè good for PMOS?',
                'Low-GI Cameroonian meals?',
                'How to cook eru healthily?',
                'Foods to avoid with PCOS?',
              ].map((q) => GestureDetector(
                onTap: () {
                  _chatController.text = q;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
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

  Widget _buildChatBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';
    final isEmpty = content.isEmpty && !isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          border: isUser ? null : Border.all(color: _kDivider),
        ),
        child: isEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),
                  ...List.generate(3, (i) => _buildTypingDot(i)),
                ],
              )
            : Text(
                content,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: isUser ? Colors.white : _kDarkText,
                  height: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 200),
      builder: (ctx, v, _) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: _kMutedText.withOpacity(0.4 + v * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kDivider.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: _kDarkText),
              decoration: InputDecoration(
                hintText: 'Ask about any Cameroonian meal...',
                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kMutedText),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _kDivider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _kDivider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isAiTyping ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _isAiTyping
                    ? null
                    : const LinearGradient(colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                color: _isAiTyping ? _kProgressTrack : null,
                shape: BoxShape.circle,
                boxShadow: _isAiTyping ? [] : [BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(
                _isAiTyping ? Icons.hourglass_empty : Icons.send_rounded,
                color: _isAiTyping ? _kMutedText : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dietary Advice Tab ────────────────────────────────────────────────────

  Widget _buildDietaryAdviceTab() {
    final adviceAsync = ref.watch(dietaryAdviceProvider);
    return adviceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kPrimary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sections) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        itemCount: sections.length,
        itemBuilder: (ctx, si) {
          final section = sections[si];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (si > 0) const SizedBox(height: 20),
              Text(section.title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: _kDarkText)),
              const SizedBox(height: 4),
              Text(section.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kMutedText)),
              const SizedBox(height: 12),
              ...section.cards.map((card) => _buildAdviceCard(card)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdviceCard(AdviceCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00696A), Color(0xFF45A8A9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tips_and_updates, color: Colors.white, size: 20),
          ),
          title: Text(card.title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: _kDarkText)),
          children: [
            Text(card.body, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kBodyText, height: 1.6)),
            if (card.foodExamples.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: card.foodExamples.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kTealBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _kTealBorder),
                  ),
                  child: Text(e, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kTealDark, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
