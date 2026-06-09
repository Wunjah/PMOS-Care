import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/gemini_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/diet_provider.dart';

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
  String _apiKey = '';
  bool _isAiTyping = false;

  final Map<String, Map<String, dynamic>> _recipes = {
    'Ndole': {
      'name': 'Ndole (Bitterleaf Stew)',
      'ingredients': 'Bitterleaf, peanuts, onions, garlic, crayfish, fish/beef, healthy oil.',
      'instructions': 'Boil raw peanuts, grind them. Wash bitterleaves to remove bitterness. Saute onions, add peanuts and bitterleaves, simmer with fish/crayfish.',
      'optimizations': '✔ Swap palm/standard oil for olive or canola oil in very limited quantity.\n✔ Use lean fish or skinless chicken instead of fatty beef or tripe.\n✔ Pair with unripe boiled plantains or oatmeal fufu instead of high-glycemic white cassava fufu.',
    },
    'Achu': {
      'name': 'Achu Soup & Taro',
      'ingredients': 'Taro (cocoyam), limestone (kanwa), warm red oil, spices, fish/beef.',
      'instructions': 'Boil cocoyam, pound it into a smooth paste. Mix limestone water with warm red oil to emulsify yellow Achu soup, add spices.',
      'optimizations': '✔ Taro is high in fast carbs; reduce the portion size of Achu paste.\n✔ Minimize red palm oil in the yellow soup to reduce saturated fats.\n✔ Increase steamed fish and green vegetables on the side to lower overall glycemic load.',
    },
    'Eru': {
      'name': 'Eru & Waterleaf',
      'ingredients': 'Eru leaves (Okok), waterleaf, palm oil, crayfish, hides (canda), fish/beef.',
      'instructions': 'Slice waterleaf and Eru leaves. Cook waterleaf, add Eru, crayfish, canda, beef, and palm oil. Simmer until water evaporates.',
      'optimizations': '✔ Avoid adding heavy amounts of red palm oil (limit to 1-2 tablespoons).\n✔ Choose healthy lean fish or skinless poultry instead of fatty meats.\n✔ Pair with low-glycemic flour (oatmeal or plantain fufu) rather than cassava fufu.',
    },
    'Rice & Stew': {
      'name': 'Rice and Tomato/Beef Stew',
      'ingredients': 'Local red or brown rice, fresh tomatoes, onions, garlic, ginger, spices, lean beef or fish, healthy oil.',
      'instructions': 'Boil local red rice. Blend tomatoes, onions, garlic, and ginger. Boil down tomato blend. Heat minimal oil, saute onions, add tomato paste and cook. Add boiled beef/fish and simmer.',
      'optimizations': '✔ ALWAYS use local red rice or brown rice instead of white rice to lower the Glycemic Index.\n✔ Limit the cooking oil (1-2 tablespoons maximum) to prevent excessive saturated fat intake.\n✔ Serve with a side of steamed vegetables or garden egg salad to increase fiber.\n✔ If you don\'t have specific info about a dish, check the online Cameroonian dishes database: https://www.cameroonweb.com/CameroonHomePage/food/',
    },
    'Fufu & Njama Njama': {
      'name': 'Fufu and Njama Njama (Huckleberry)',
      'ingredients': 'Njama njama (huckleberry) leaves, onions, tomatoes, fufu flour (oat or green plantain), optional lean chicken/fish.',
      'instructions': 'Wash huckleberry leaves. Saute onions and tomatoes, add huckleberry leaves and steam. Prepare fufu by mixing oat flour or unripe plantain flour with boiling water until solid and smooth.',
      'optimizations': '✔ Swap high-GI cassava fufu or corn fufu with plantain fufu (made from unripe green plantains) or oatmeal fufu.\n✔ Limit added fats/oil when frying the njama njama.\n✔ Add a clean protein source (like boiled eggs or grilled fish) to improve hormone regulation.\n✔ If you don\'t have specific info about a dish, check the online Cameroonian dishes database: https://www.cameroonweb.com/CameroonHomePage/food/',
    },
  };

  void _sendChatMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    final userMsg = {'role': 'user', 'message': query};

    setState(() {
      _chatMessages.add(userMsg);
      _chatController.clear();
      _isAiTyping = true;
    });

    final List<Map<String, dynamic>> geminiHistory = _chatMessages.map((msg) {
      return {
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': msg['message'] ?? ''}
        ]
      };
    }).toList();

    final assistantMsgIndex = _chatMessages.length;
    setState(() {
      _chatMessages.add({'role': 'assistant', 'message': ''});
    });

    const systemInstruction = 
        "You are the PMOS Care AI Chef, specializing in optimizing traditional Cameroonian cuisine for women with PMOS/PCOS. "
        "Focus on traditional Cameroonian dishes (Ndole, Eru, Achu, Rice & Stew, Fufu & Njama Njama, Koki, Mbanga). "
        "Suggest swapping high-glycemic index staples (cassava fufu, white garri, white rice) with low-glycemic alternatives (boiled unripe plantain, oatmeal fufu, plantain fufu). "
        "All recommendations and meal advices MUST focus on Cameroonian foods. If you do not have information about any dish or recipe, you MUST provide a link to the existing database of Cameroonian dishes online (such as https://www.cameroonweb.com/CameroonHomePage/food/ or a search engine query for Cameroon food recipes).";

    StringBuffer accumulated = StringBuffer();
    bool hasError = false;

    try {
      final stream = GeminiService().queryGeminiStream(
        geminiHistory,
        systemInstruction: systemInstruction,
      );

      await for (final token in stream) {
        if (!mounted) return;
        if (token == "Google AI is temporarily unavailable.") {
          hasError = true;
          accumulated.clear();
          accumulated.write("Google AI is temporarily unavailable.");
          break;
        }
        accumulated.write(token);
        setState(() {
          _chatMessages[assistantMsgIndex]['message'] = accumulated.toString();
          _isAiTyping = false;
        });
      }
    } catch (e) {
      hasError = true;
      accumulated.clear();
      accumulated.write("Google AI is temporarily unavailable.");
    }

    if (!mounted) return;

    if (hasError || accumulated.isEmpty) {
      setState(() {
        _chatMessages[assistantMsgIndex]['message'] = "Google AI is temporarily unavailable.";
        _isAiTyping = false;
      });
    }

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final responseText = _chatMessages[assistantMsgIndex]['message'] ?? '';
    debugPrint('[Gemini Verification Log] message_id: $messageId, timestamp: ${DateTime.now().toIso8601String()}, request_sent_to_gemini: $query, response_received_from_gemini: $responseText');
  }

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApiKey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diet & Nutrition',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryWellness,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryWellness,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_outlined), text: 'Food Guide'),
            Tab(icon: Icon(Icons.track_changes_outlined), text: 'Tracker'),
            Tab(icon: Icon(Icons.tips_and_updates_outlined), text: 'Advice'),
            Tab(icon: Icon(Icons.psychology_outlined), text: 'AI Chef'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFoodGuide(),
          _buildMealTracker(),
          _buildDietaryAdvice(),
          _buildAiKitchenGuide(),
        ],
      ),
    );
  }

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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppTheme.primaryLight,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Nutrition Summary',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryWellness,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionStat('Calories', '${totalCals.toStringAsFixed(0)} kcal', Icons.local_fire_department, Colors.orange),
                      _buildNutritionStat('Protein', '${totalProtein.toStringAsFixed(1)} g', Icons.fitness_center, Colors.blue),
                      _buildNutritionStat('Fiber', '${totalFiber.toStringAsFixed(1)} g', Icons.eco, Colors.green),
                      _buildNutritionStat('Water', '${totalWater.toStringAsFixed(0)} ml', Icons.water_drop, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Quick Hydration Logger',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.teal, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Hydration: ${totalWater.toStringAsFixed(0)} / 2500 ml',
                        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.withAlpha(30),
                          foregroundColor: Colors.teal,
                          elevation: 0,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          ref.read(mealLogStateNotifierProvider.notifier).addMealLog(
                                mealType: 'water',
                                foodName: 'Water',
                                calories: 0,
                                proteinGrams: 0,
                                fiberGrams: 0,
                                waterMl: 250,
                                date: DateTime.now(),
                              );
                        },
                        child: const Text('+250ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.withAlpha(50),
                          foregroundColor: Colors.teal.shade900,
                          elevation: 0,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          ref.read(mealLogStateNotifierProvider.notifier).addMealLog(
                                mealType: 'water',
                                foodName: 'Water',
                                calories: 0,
                                proteinGrams: 0,
                                fiberGrams: 0,
                                waterMl: 500,
                                date: DateTime.now(),
                              );
                        },
                        child: const Text('+500ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Meals',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showAddMealDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Meal', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          todayLogs.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withAlpha(50)),
                  ),
                  child: const Text(
                    'No meals logged today.',
                    style: TextStyle(fontFamily: 'Inter', color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayLogs.length,
                  itemBuilder: (context, index) {
                    final log = todayLogs[index];
                    final isWater = log.mealType == 'water';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withAlpha(50)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isWater ? Colors.teal.withAlpha(30) : AppTheme.primaryLight,
                          child: Icon(
                            isWater ? Icons.water_drop : Icons.restaurant,
                            color: isWater ? Colors.teal : AppTheme.primaryWellness,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isWater ? 'Hydration' : log.foodName,
                          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          isWater
                              ? '${log.waterMl.toStringAsFixed(0)} ml water'
                              : '${log.mealType.toUpperCase()} | ${log.calories.toStringAsFixed(0)} kcal | P: ${log.proteinGrams}g | F: ${log.fiberGrams}g',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.glycemicHigh),
                          onPressed: () => ref.read(mealLogStateNotifierProvider.notifier).removeMealLog(log.id),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildNutritionStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final foodNameController = TextEditingController();
    final calsController = TextEditingController();
    final proteinController = TextEditingController();
    final fiberController = TextEditingController();
    final waterController = TextEditingController();
    String selectedMealType = 'breakfast';

    final List<String> mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Log Meal Details',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedMealType,
                        decoration: const InputDecoration(labelText: 'Meal Type', border: OutlineInputBorder()),
                        items: mealTypes
                            .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedMealType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: foodNameController,
                        decoration: const InputDecoration(
                          labelText: 'Food / Meal Name',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Ndole with boiled plantain',
                        ),
                        validator: (val) => (val == null || val.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: calsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 350',
                        ),
                        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: proteinController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Protein (g)',
                                border: OutlineInputBorder(),
                                hintText: 'e.g. 20',
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: fiberController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Fiber (g)',
                                border: OutlineInputBorder(),
                                hintText: 'e.g. 5',
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: waterController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Water Intake (ml) (optional)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 300',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final cals = double.parse(calsController.text);
                      final protein = double.parse(proteinController.text);
                      final fiber = double.parse(fiberController.text);
                      final water = double.tryParse(waterController.text) ?? 0.0;

                      await ref.read(mealLogStateNotifierProvider.notifier).addMealLog(
                            mealType: selectedMealType,
                            foodName: foodNameController.text,
                            calories: cals,
                            proteinGrams: protein,
                            fiberGrams: fiber,
                            waterMl: water,
                            date: DateTime.now(),
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meal logged successfully!'),
                            backgroundColor: AppTheme.glycemicLow,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFoodGuide() {
    final foodsAsync = ref.watch(foodsProvider);

    return foodsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
                        style: TextStyle(fontFamily: 'Inter', color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _FoodCard(food: filtered[i]),
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
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Cameroonian foods…',
          hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
        onChanged: (q) => setState(() => _searchQuery = q),
      ),
    );
  }

  Widget _buildSuitabilityFilter() {
    const options = ['All', 'Good', 'Moderate', 'Limit'];
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: options.map((option) {
          final isSelected = _selectedSuitability == option;
          Color chipColor = Colors.grey.shade200;
          Color labelColor = Colors.grey.shade700;
          if (option == 'Good') {
            chipColor = isSelected ? AppTheme.glycemicLow : AppTheme.glycemicLow.withOpacity(0.12);
            labelColor = isSelected ? Colors.white : AppTheme.glycemicLow;
          } else if (option == 'Moderate') {
            chipColor = isSelected ? AppTheme.glycemicMedium : AppTheme.glycemicMedium.withOpacity(0.12);
            labelColor = isSelected ? Colors.white : AppTheme.glycemicMedium;
          } else if (option == 'Limit') {
            chipColor = isSelected ? AppTheme.glycemicHigh : AppTheme.glycemicHigh.withOpacity(0.12);
            labelColor = isSelected ? Colors.white : AppTheme.glycemicHigh;
          } else {
            chipColor = isSelected ? AppTheme.primaryWellness : Colors.grey.shade200;
            labelColor = isSelected ? Colors.white : Colors.grey.shade700;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSuitability = option),
              child: Chip(
                label: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                ),
                backgroundColor: chipColor,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: _categoryLabels.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = entry.key),
              child: Chip(
                label: Text(
                  entry.value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.primaryWellness,
                  ),
                ),
                backgroundColor: isSelected
                    ? AppTheme.primaryWellness
                    : AppTheme.primaryLight,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDietaryAdvice() {
    final adviceAsync = ref.watch(dietaryAdviceProvider);

    return adviceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading advice: $e')),
      data: (sections) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sections.length,
        itemBuilder: (context, i) => _AdviceSectionWidget(section: sections[i]),
      ),
    );
  }

  Widget _buildAiKitchenGuide() {
    final recipe = _recipes[_selectedDish]!;

    return Column(
      children: [
        // Dropdown Dish Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Select Dish:  ',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDish,
                  isExpanded: true,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDish = val;
                      });
                    }
                  },
                  items: _recipes.keys.map((key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(_recipes[key]!['name'] as String, style: const TextStyle(fontFamily: 'Inter')),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Display selected recipe information
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['name'] as String,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryWellness),
                      ),
                      const SizedBox(height: 8),
                      Text('Ingredients: ${recipe['ingredients']}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
                      const SizedBox(height: 12),
                      const Text('Standard Preparation:', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(recipe['instructions'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4)),
                      const SizedBox(height: 16),
                      
                      // PMOS Optimizations Banner Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryWellness.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI PMOS Optimizations:',
                              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: AppTheme.primaryWellness, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recipe['optimizations'] as String,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.5, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Google AI Gemini status banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _apiKey.isEmpty ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _apiKey.isEmpty ? Colors.blue.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _apiKey.isEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: _apiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
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
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _showApiKeyDialog,
                      icon: Icon(
                        Icons.settings,
                        color: _apiKey.isEmpty ? Colors.blue.shade800 : Colors.green.shade800,
                        size: 14,
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
              const SizedBox(height: 16),

              // Interactive Chat
              const Text(
                'Ask AI Cooking Assistant',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryWellness),
              ),
              const SizedBox(height: 8),

              // Chat history list
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primaryWellness : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['message'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: isUser ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isAiTyping) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryWellness),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI Chef is typing...',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Send Chat Form
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Ask AI how to prep standard food...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryWellness),
                    onPressed: _sendChatMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem food;
  const _FoodCard({required this.food});

  Color get _borderColor {
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

  Color get _badgeColor {
    switch (food.suitability) {
      case 'Good':
        return AppTheme.glycemicLow.withOpacity(0.15);
      case 'Moderate':
        return AppTheme.glycemicMedium.withOpacity(0.15);
      case 'Limit':
        return AppTheme.glycemicHigh.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          food.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          food.localName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                food.suitability,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _borderColor,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
        children: [
          Text(
            food.explanation,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceSectionWidget extends StatelessWidget {
  final AdviceSection section;
  const _AdviceSectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryWellness,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            section.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          ...section.cards.map((card) => _AdviceCardWidget(card: card)),
          const SizedBox(height: 8),
          const Divider(),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(Icons.eco_outlined, color: AppTheme.primaryWellness),
        title: Text(
          card.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Text(
            card.body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          if (card.foodExamples.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.foodExamples
                  .map(
                    (food) => Chip(
                      label: Text(
                        food,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppTheme.primaryWellness,
                        ),
                      ),
                      backgroundColor: AppTheme.primaryLight,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
