import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/gemini_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/diet_provider.dart';

// ─── Design tokens (matching home & calendar screens) ────────────────────────
const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kBodyText = Color(0xFF464552);
const _kMutedText = Color(0xFF777684);
const _kBg = Color(0xFFF8F9FF);
const _kGlass = Color(0xB3FFFFFF);
const _kGlassBorder = Color(0x80FFFFFF);
const _kDivider = Color(0xFFE7E8EE);
const _kTealDark = Color(0xFF00696A);
const _kTealBg = Color(0x1A45A8A9);
const _kTealBorder = Color(0x3345A8A9);
const _kTeal = Color(0xFF45A8A9);
const _kProgressTrack = Color(0xFFECEEF3);

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSuitability = 'All';

  static const _categoryLabels = <String, String>{
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

  final List<Map<String, String>> _chatMessages = [];
  final _chatController = TextEditingController();
  String _selectedDish = 'Ndole';
  bool _isAiTyping = false;

  final Map<String, Map<String, dynamic>> _recipes = {
    'Ndole': {
      'name': 'Ndole (Bitterleaf Stew)',
      'ingredients':
          'Bitterleaf, peanuts, onions, garlic, crayfish, fish/beef, healthy oil.',
      'instructions':
          'Boil raw peanuts, grind them. Wash bitterleaves to remove bitterness. Sauté onions, add peanuts and bitterleaves, simmer with fish/crayfish.',
      'optimizations':
          '✔ Swap palm/standard oil for olive or canola oil in very limited quantity.\n✔ Use lean fish or skinless chicken instead of fatty beef or tripe.\n✔ Pair with unripe boiled plantains or oatmeal fufu instead of high-glycemic white cassava fufu.',
    },
    'Achu': {
      'name': 'Achu Soup & Taro',
      'ingredients':
          'Taro (cocoyam), limestone (kanwa), warm red oil, spices, fish/beef.',
      'instructions':
          'Boil cocoyam, pound into a smooth paste. Mix limestone water with warm red oil to emulsify yellow Achu soup, add spices.',
      'optimizations':
          '✔ Taro is high in fast carbs; reduce the portion size of Achu paste.\n✔ Minimise red palm oil in the yellow soup to reduce saturated fats.\n✔ Increase steamed fish and green vegetables on the side to lower overall glycaemic load.',
    },
    'Eru': {
      'name': 'Eru & Waterleaf',
      'ingredients':
          'Eru leaves (Okok), waterleaf, palm oil, crayfish, hides (canda), fish/beef.',
      'instructions':
          'Slice waterleaf and Eru leaves. Cook waterleaf, add Eru, crayfish, canda, beef, and palm oil. Simmer until water evaporates.',
      'optimizations':
          '✔ Limit red palm oil to 1–2 tablespoons maximum.\n✔ Choose lean fish or skinless poultry instead of fatty meats.\n✔ Pair with oatmeal or plantain fufu rather than cassava fufu.',
    },
    'Rice & Stew': {
      'name': 'Rice and Tomato/Beef Stew',
      'ingredients':
          'Local red or brown rice, fresh tomatoes, onions, garlic, ginger, spices, lean beef or fish, healthy oil.',
      'instructions':
          'Boil local red rice. Blend tomatoes, onions, garlic and ginger. Boil down tomato blend. Heat minimal oil, sauté onions, add tomato paste and cook. Add boiled beef/fish and simmer.',
      'optimizations':
          '✔ ALWAYS use local red rice or brown rice to lower the Glycaemic Index.\n✔ Limit cooking oil to 1–2 tablespoons to prevent excessive saturated fat intake.\n✔ Serve with steamed vegetables or garden egg salad to increase fibre.',
    },
    'Fufu & Njama Njama': {
      'name': 'Fufu and Njama Njama (Huckleberry)',
      'ingredients':
          'Njama njama leaves, onions, tomatoes, fufu flour (oat or green plantain), optional lean chicken/fish.',
      'instructions':
          'Wash huckleberry leaves. Sauté onions and tomatoes, add leaves and steam. Prepare fufu by mixing oat flour or unripe plantain flour with boiling water until smooth.',
      'optimizations':
          '✔ Swap high-GI cassava fufu with plantain fufu or oatmeal fufu.\n✔ Limit added oils when frying the njama njama.\n✔ Add boiled eggs or grilled fish to improve hormone regulation.',
    },
  };

  void _sendChatMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'message': query});
      _chatController.clear();
      _isAiTyping = true;
    });

    final List<Map<String, dynamic>> geminiHistory = _chatMessages.map((msg) {
      return {
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': msg['message'] ?? ''}
        ],
      };
    }).toList();

    final assistantMsgIndex = _chatMessages.length;
    setState(() => _chatMessages.add({'role': 'assistant', 'message': ''}));

    const systemInstruction =
        'You are the PMOS Care AI Chef, specialising in optimising traditional Cameroonian cuisine for women with PMOS/PCOS. '
        'Focus on dishes such as Ndole, Eru, Achu, Rice & Stew, Fufu & Njama Njama, Koki, and Mbanga. '
        'Suggest swapping high-glycaemic staples (cassava fufu, white garri, white rice) with low-glycaemic alternatives '
        '(boiled unripe plantain, oatmeal fufu, plantain fufu). '
        'All recommendations MUST focus on Cameroonian foods. If you lack specific dish information, provide a link to '
        'https://www.cameroonweb.com/CameroonHomePage/food/ or a relevant search query.';

    final accumulated = StringBuffer();
    bool hasError = false;

    try {
      final stream = GeminiService().queryGeminiStream(
        geminiHistory,
        systemInstruction: systemInstruction,
      );

      await for (final token in stream) {
        if (!mounted) return;
        if (token == 'Google AI is temporarily unavailable.') {
          hasError = true;
          accumulated
            ..clear()
            ..write('Google AI is temporarily unavailable.');
          break;
        }
        accumulated.write(token);
        setState(() {
          _chatMessages[assistantMsgIndex]['message'] = accumulated.toString();
          _isAiTyping = false;
        });
      }
    } catch (_) {
      hasError = true;
      accumulated
        ..clear()
        ..write('Google AI is temporarily unavailable.');
    }

    if (!mounted) return;
    if (hasError || accumulated.isEmpty) {
      setState(() {
        _chatMessages[assistantMsgIndex]['message'] =
            'Google AI is temporarily unavailable.';
        _isAiTyping = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    GeminiService().loadApiKey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

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
                _buildFoodGuide(),
                _buildMealTracker(),
                _buildDietaryAdvice(),
                _buildAiKitchenGuide(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Frosted Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _kBg.withOpacity(0.9),
            border: const Border(bottom: BorderSide(color: _kDivider)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _kTealBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restaurant_outlined,
                                      size: 11, color: _kTealDark),
                                  SizedBox(width: 4),
                                  Text(
                                    'NUTRITION',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _kTealDark,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Diet & Nutrition',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                letterSpacing: -0.5,
                                color: _kDarkText,
                              ),
                            ),
                            const Text(
                              'Cameroonian food guide & PMOS meal planning',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: _kMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kTealBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kTealBorder),
                        ),
                        child: const Icon(Icons.restaurant_rounded,
                            color: _kTeal, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  labelColor: _kPrimary,
                  unselectedLabelColor: _kMutedText,
                  indicatorColor: _kPrimary,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                        icon: Icon(Icons.restaurant_outlined, size: 16),
                        text: 'Food Guide'),
                    Tab(
                        icon: Icon(Icons.track_changes_outlined, size: 16),
                        text: 'Tracker'),
                    Tab(
                        icon: Icon(Icons.tips_and_updates_outlined, size: 16),
                        text: 'Advice'),
                    Tab(
                        icon: Icon(Icons.psychology_outlined, size: 16),
                        text: 'AI Chef'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Food Guide tab ────────────────────────────────────────────────────────────

  Widget _buildFoodGuide() {
    final foodsAsync = ref.watch(foodsProvider);

    return foodsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kPrimary)),
      error: (e, _) => Center(child: Text('Error loading foods: $e')),
      data: (foods) {
        final filtered = foods.where((f) {
          final matchesSearch = _searchQuery.isEmpty ||
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.localName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory =
              _selectedCategory == 'All' || f.category == _selectedCategory;
          final matchesSuitability =
              _selectedSuitability == 'All' || f.suitability == _selectedSuitability;
          return matchesSearch && matchesCategory && matchesSuitability;
        }).toList();

        return Column(
          children: [
            _buildSearchBar(),
            _buildSuitabilityFilter(),
            _buildCategoryFilter(),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No foods match your search.',
                        style:
                            TextStyle(fontFamily: 'Inter', color: _kMutedText),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.only(bottom: 24, top: 4),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _FoodCard(food: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search Cameroonian foods…',
            hintStyle: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: _kMutedText),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _kMutedText, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 16, color: _kMutedText),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
      ),
    );
  }

  Widget _buildSuitabilityFilter() {
    const options = ['All', 'Good', 'Moderate', 'Limit'];
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: options.map((option) {
          final isSelected = _selectedSuitability == option;
          late Color chipColor;
          late Color textColor;
          if (option == 'Good') {
            chipColor = isSelected
                ? AppTheme.glycemicLow
                : AppTheme.glycemicLow.withOpacity(0.1);
            textColor =
                isSelected ? Colors.white : AppTheme.glycemicLow;
          } else if (option == 'Moderate') {
            chipColor = isSelected
                ? AppTheme.glycemicMedium
                : AppTheme.glycemicMedium.withOpacity(0.1);
            textColor =
                isSelected ? Colors.white : AppTheme.glycemicMedium;
          } else if (option == 'Limit') {
            chipColor = isSelected
                ? AppTheme.glycemicHigh
                : AppTheme.glycemicHigh.withOpacity(0.1);
            textColor =
                isSelected ? Colors.white : AppTheme.glycemicHigh;
          } else {
            chipColor = isSelected ? _kPrimary : _kProgressTrack;
            textColor = isSelected ? Colors.white : _kBodyText;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSuitability = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: _categoryLabels.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedCategory = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: isSelected
                      ? null
                      : Border.all(color: _kDivider),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected ? Colors.white : _kBodyText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Meal Tracker tab ──────────────────────────────────────────────────────────

  Widget _buildMealTracker() {
    final mealState = ref.watch(mealLogStateNotifierProvider);
    final today = DateTime.now();

    final todayLogs = mealState.mealLogs.where((log) {
      return log.timestamp.year == today.year &&
          log.timestamp.month == today.month &&
          log.timestamp.day == today.day;
    }).toList();

    double totalCals = 0;
    double totalProtein = 0;
    double totalFiber = 0;
    double totalWater = 0;

    for (final log in todayLogs) {
      if (log.mealType == 'water') {
        totalWater += log.waterMl;
      } else {
        totalCals += log.calories;
        totalProtein += log.proteinGrams;
        totalFiber += log.fiberGrams;
        totalWater += log.waterMl;
      }
    }

    final waterFraction = (totalWater / 2500).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient summary card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.8, -0.6),
                end: Alignment(0.8, 0.6),
                colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: -28,
                  right: -18,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 110,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            "Today's Summary",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalCals.toStringAsFixed(0),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 7),
                          child: Text(
                            'kcal today',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFFE2DFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildMiniStat('Protein',
                            '${totalProtein.toStringAsFixed(1)}g'),
                        const SizedBox(width: 28),
                        _buildMiniStat(
                            'Fiber', '${totalFiber.toStringAsFixed(1)}g'),
                        const SizedBox(width: 28),
                        _buildMiniStat(
                            'Water', '${totalWater.toStringAsFixed(0)}ml'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Hydration card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _kTealBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kTealBorder),
                      ),
                      child: const Icon(Icons.water_drop_outlined,
                          color: _kTealDark, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hydration',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _kDarkText,
                          ),
                        ),
                        Text(
                          '${totalWater.toStringAsFixed(0)} / 2500 ml',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: _kMutedText),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildWaterButton('+250ml', 250),
                    const SizedBox(width: 8),
                    _buildWaterButton('+500ml', 500),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: _kProgressTrack),
                        FractionallySizedBox(
                          widthFactor: waterFraction,
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _kTeal,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: _kTeal.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Today's meals ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Meals",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: _kDarkText,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddMealDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Log Meal',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          todayLogs.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kDivider),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: _kProgressTrack,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_outlined,
                            color: _kMutedText, size: 22),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No meals logged yet',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _kBodyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Log Meal" to track your nutrition',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _kMutedText),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayLogs.length,
                  itemBuilder: (context, index) {
                    final log = todayLogs[index];
                    final isWater = log.mealType == 'water';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isWater
                                  ? _kTealBg
                                  : const Color(0x1A5152B9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isWater
                                    ? _kTealBorder
                                    : const Color(0x335152B9),
                              ),
                            ),
                            child: Icon(
                              isWater
                                  ? Icons.water_drop_outlined
                                  : Icons.restaurant_outlined,
                              color: isWater ? _kTealDark : _kPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isWater ? 'Hydration' : log.foodName,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _kDarkText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isWater
                                      ? '${log.waterMl.toStringAsFixed(0)} ml water'
                                      : '${log.mealType.toUpperCase()} • ${log.calories.toStringAsFixed(0)} kcal • P: ${log.proteinGrams}g • F: ${log.fiberGrams}g',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      color: _kMutedText),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppTheme.glycemicHigh),
                            onPressed: () => ref
                                .read(mealLogStateNotifierProvider.notifier)
                                .removeMealLog(log.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFFE2DFFF),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterButton(String label, double amount) {
    return GestureDetector(
      onTap: () {
        ref.read(mealLogStateNotifierProvider.notifier).addMealLog(
              mealType: 'water',
              foodName: 'Water',
              calories: 0,
              proteinGrams: 0,
              fiberGrams: 0,
              waterMl: amount,
              date: DateTime.now(),
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kTealBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _kTealBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTealDark,
          ),
        ),
      ),
    );
  }

  // ── Add Meal dialog ───────────────────────────────────────────────────────────

  void _showAddMealDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final foodNameController = TextEditingController();
    final calsController = TextEditingController();
    final proteinController = TextEditingController();
    final fiberController = TextEditingController();
    final waterController = TextEditingController();
    String selectedMealType = 'breakfast';
    const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Log Meal',
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: _kDarkText),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: mealTypes
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.toUpperCase())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setS(() => selectedMealType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: foodNameController,
                    decoration: InputDecoration(
                      labelText: 'Food / Meal Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: 'e.g. Ndole with boiled plantain',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: calsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Calories (kcal)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: 'e.g. 350',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: proteinController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            hintText: '20',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: fiberController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Fiber (g)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            hintText: '5',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: waterController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Water (ml) — optional',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: '300',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: _kMutedText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  await ref
                      .read(mealLogStateNotifierProvider.notifier)
                      .addMealLog(
                        mealType: selectedMealType,
                        foodName: foodNameController.text,
                        calories: double.parse(calsController.text),
                        proteinGrams: double.parse(proteinController.text),
                        fiberGrams: double.parse(fiberController.text),
                        waterMl:
                            double.tryParse(waterController.text) ?? 0.0,
                        date: DateTime.now(),
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Meal logged successfully!'),
                        backgroundColor: AppTheme.glycemicLow,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dietary Advice tab ────────────────────────────────────────────────────────

  Widget _buildDietaryAdvice() {
    final adviceAsync = ref.watch(dietaryAdviceProvider);

    return adviceAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kPrimary)),
      error: (e, _) => Center(child: Text('Error loading advice: $e')),
      data: (sections) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sections.length,
        itemBuilder: (context, i) =>
            _AdviceSectionWidget(section: sections[i]),
      ),
    );
  }

  // ── AI Kitchen Guide tab ──────────────────────────────────────────────────────

  Widget _buildAiKitchenGuide() {
    final recipe = _recipes[_selectedDish]!;

    return Column(
      children: [
        // Dish selector
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
            ),
            child: DropdownButton<String>(
              value: _selectedDish,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _kMutedText, size: 20),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kDarkText,
              ),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDish = val);
              },
              items: _recipes.keys
                  .map((key) => DropdownMenuItem<String>(
                        value: key,
                        child: Text(
                          _recipes[key]!['name'] as String,
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kDarkText),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Recipe glass card ──────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kGlassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kTealBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book_outlined,
                                  size: 11, color: _kTealDark),
                              SizedBox(width: 4),
                              Text(
                                'RECIPE',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _kTealDark,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          recipe['name'] as String,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildRecipeSection(
                          'Ingredients',
                          recipe['ingredients'] as String,
                          Icons.list_alt_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildRecipeSection(
                          'Preparation',
                          recipe['instructions'] as String,
                          Icons.soup_kitchen_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── PMOS optimisations gradient banner ─────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -22,
                      right: -22,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Icon(
                          Icons.tips_and_updates_outlined,
                          size: 90,
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'PMOS Optimisations',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          recipe['optimizations'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.6,
                            color: Color(0xFFE2DFFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── AI chat section ────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kTealBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kTealBorder),
                    ),
                    child: const Icon(Icons.psychology_outlined,
                        color: _kTealDark, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask AI Cooking Assistant',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _kDarkText,
                        ),
                      ),
                      Text(
                        'Powered by Google Gemini',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: _kMutedText),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chat history
              Container(
                constraints: const BoxConstraints(
                    minHeight: 120, maxHeight: 240),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kDivider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _chatMessages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Ask about ingredients, cooking methods,\nor PMOS-friendly substitutions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: _kMutedText,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _chatMessages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              constraints:
                                  const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? _kPrimary
                                    : _kProgressTrack,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(
                                      isUser ? 14 : 4),
                                  bottomRight: Radius.circular(
                                      isUser ? 4 : 14),
                                ),
                              ),
                              child: Text(
                                msg['message'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isUser
                                      ? Colors.white
                                      : _kBodyText,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (_isAiTyping) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_kPrimary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Chef is typing…',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: _kMutedText),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // Chat input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _kDivider),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about this recipe…',
                          hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: _kMutedText),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _kDarkText),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: _sendChatMessage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeSection(
      String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: _kMutedText),
            const SizedBox(width: 5),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kMutedText,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.5,
            color: _kBodyText,
          ),
        ),
      ],
    );
  }
}

// ─── Food Card ────────────────────────────────────────────────────────────────

class _FoodCard extends StatelessWidget {
  final FoodItem food;
  const _FoodCard({required this.food});

  Color get _accentColor {
    switch (food.suitability) {
      case 'Good':
        return AppTheme.glycemicLow;
      case 'Moderate':
        return AppTheme.glycemicMedium;
      case 'Limit':
        return AppTheme.glycemicHigh;
      default:
        return Colors.grey;
    }
  }

  Color get _badgeBg {
    switch (food.suitability) {
      case 'Good':
        return AppTheme.glycemicLow.withOpacity(0.1);
      case 'Moderate':
        return AppTheme.glycemicMedium.withOpacity(0.1);
      case 'Limit':
        return AppTheme.glycemicHigh.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 4,
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            food.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kDarkText,
            ),
          ),
          subtitle: Text(
            food.localName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _kMutedText,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  food.suitability,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _kMutedText, size: 18),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                food.explanation,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.5,
                  color: _kBodyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Advice Section ───────────────────────────────────────────────────────────

class _AdviceSectionWidget extends StatelessWidget {
  final AdviceSection section;
  const _AdviceSectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            section.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _kMutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...section.cards.map((card) => _AdviceCardWidget(card: card)),
          const SizedBox(height: 4),
          const Divider(color: _kDivider),
        ],
      ),
    );
  }
}

class _AdviceCardWidget extends StatelessWidget {
  final AdviceCard card;
  const _AdviceCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0x1A5152B9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined,
                color: _kPrimary, size: 18),
          ),
          title: Text(
            card.title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kDarkText,
            ),
          ),
          children: [
            Text(
              card.body,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.6,
                color: _kBodyText,
              ),
            ),
            if (card.foodExamples.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: card.foodExamples
                    .map(
                      (food) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x1A5152B9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          food,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
