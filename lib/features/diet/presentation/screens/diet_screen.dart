import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            Tab(icon: Icon(Icons.tips_and_updates_outlined), text: 'Advice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFoodGuide(),
          _buildDietaryAdvice(),
        ],
      ),
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
            chipColor = isSelected ? AppTheme.glycemicLow : AppTheme.glycemicLow.withValues(alpha: 0.12);
            labelColor = isSelected ? Colors.white : AppTheme.glycemicLow;
          } else if (option == 'Moderate') {
            chipColor = isSelected ? AppTheme.glycemicMedium : AppTheme.glycemicMedium.withValues(alpha: 0.12);
            labelColor = isSelected ? Colors.white : AppTheme.glycemicMedium;
          } else if (option == 'Limit') {
            chipColor = isSelected ? AppTheme.glycemicHigh : AppTheme.glycemicHigh.withValues(alpha: 0.12);
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
        return AppTheme.glycemicLow.withValues(alpha: 0.15);
      case 'Moderate':
        return AppTheme.glycemicMedium.withValues(alpha: 0.15);
      case 'Limit':
        return AppTheme.glycemicHigh.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
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
