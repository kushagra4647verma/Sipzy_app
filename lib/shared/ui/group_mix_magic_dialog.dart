import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/models/restaurant_model.dart';

enum GroupMixStep { participants, baseSelection, result }

class GroupMixMagicDialog extends StatefulWidget {
  final List beverages;
  final Restaurant restaurant;

  const GroupMixMagicDialog({
    super.key,
    required this.beverages,
    required this.restaurant,
  });

  @override
  State<GroupMixMagicDialog> createState() => _GroupMixMagicDialogState();
}

class _GroupMixMagicDialogState extends State<GroupMixMagicDialog> {
  GroupMixStep _step = GroupMixStep.participants;

  int _participants = 3;
  List<String?> _baseDrinks = [];
  final List<Map<String, dynamic>> _results = [];

  List<String> _availableSpirits() {
    final set = <String>{};

    for (final b in widget.beverages) {
      final tags = (b['tags'] ?? '').toString().toLowerCase();
      final category = (b['category'] ?? '').toString().toLowerCase();
      final baseDrink =
          (b['base_drink'] ?? b['baseDrink'] ?? '').toString().toLowerCase();

      for (final s in [
        'vodka',
        'whisky',
        'rum',
        'gin',
        'tequila',
        'wine',
        'beer'
      ]) {
        if (tags.contains(s) || category.contains(s) || baseDrink.contains(s)) {
          set.add(s[0].toUpperCase() + s.substring(1));
        }
      }
    }

    return set.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _baseDrinks = List.filled(_participants, null);
  }

  void _generateMix() {
    final random = Random();
    _results.clear();

    for (int i = 0; i < _participants; i++) {
      final base = _baseDrinks[i];

      final filtered = widget.beverages.where((b) {
        final tags = (b['tags'] ?? '').toString().toLowerCase();
        final category = (b['category'] ?? '').toString().toLowerCase();
        final baseDrink =
            (b['base_drink'] ?? b['baseDrink'] ?? '').toString().toLowerCase();

        if (base == null) return true;
        return tags.contains(base.toLowerCase()) ||
            category.contains(base.toLowerCase()) ||
            baseDrink.contains(base.toLowerCase());
      }).toList();

      if (filtered.isEmpty) continue;

      final drink = filtered[random.nextInt(filtered.length)];

      // Get actual rating
      final ratings = drink['ratings'] as Map<String, dynamic>? ?? {};
      final avgRating = ratings['avgHuman'] ??
          ratings['avghuman'] ??
          (drink['sipzy_rating'] ?? 0);

      _results.add({
        'participant': 'Participant ${i + 1}',
        'beverage': drink,
        'rating': avgRating.toStringAsFixed(1),
        'tags': _extractTags(drink),
      });
    }

    setState(() => _step = GroupMixStep.result);
  }

  List<String> _extractTags(Map beverage) {
    final tags = <String>[];

    // Extract from category
    final category = (beverage['category'] ?? '').toString().toLowerCase();
    if (category.contains('sweet')) tags.add('#Sweet');
    if (category.contains('fruity')) tags.add('#Fruity');
    if (category.contains('sour')) tags.add('#Sour');
    if (category.contains('bitter')) tags.add('#Bitter');

    // Extract from base drink
    final baseDrink =
        (beverage['base_drink'] ?? beverage['baseDrink'] ?? '').toString();
    if (baseDrink.isNotEmpty) {
      tags.add(
          '#${baseDrink[0].toUpperCase()}${baseDrink.substring(1).toLowerCase()}');
    }

    return tags.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2A1B3D),
              const Color(0xFF1A1A2E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _header(),
            if (_step == GroupMixStep.participants) _participantsStep(),
            if (_step == GroupMixStep.baseSelection) _baseSelectionStep(),
            if (_step == GroupMixStep.result) _resultStep(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step != GroupMixStep.participants)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_step == GroupMixStep.baseSelection) {
                    _step = GroupMixStep.participants;
                  } else if (_step == GroupMixStep.result) {
                    _step = GroupMixStep.baseSelection;
                  }
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          const Icon(
            Icons.local_bar,
            color: AppTheme.primary,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _participantsStep() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Group Mix Magic',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let AI create the perfect mix for your group',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Number of Participants Label
            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.people, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Number of Participants',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _participants,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  items: List.generate(6, (index) => index + 1).map((count) {
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text(
                        count.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _participants = value;
                        _baseDrinks = List.filled(value, null);
                        _results.clear();
                      });
                    }
                  },
                ),
              ),
            ),

            const Spacer(),

            // Generate Mix Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB366FF), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _step = GroupMixStep.baseSelection);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Generate Mix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _baseSelectionStep() {
    final spirits = _availableSpirits();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Group Mix Magic',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let AI create the perfect mix for your group',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Number of Participants (non-editable display)
            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.people, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Number of Participants',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _participants.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Base Drink Selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.local_bar, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Base Drink Selection for Each Participant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _participants,
                itemBuilder: (_, i) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participant ${i + 1}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _baseDrinks[i],
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A2E),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            hint: const Text(
                              'Choose spirit',
                              style: TextStyle(color: AppTheme.textTertiary),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Surprise me!',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              ...spirits.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (v) =>
                                setState(() => _baseDrinks[i] = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),

            // Generate Mix Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB366FF), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _generateMix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Generate Mix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _resultStep() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Your Perfect Mix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _generateMix,
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (_, i) {
                  final rec = _results[i];
                  final bev = rec['beverage'];
                  final tags = rec['tags'] as List<String>;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.border.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with participant badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: bev['photo'] != null &&
                                      bev['photo'].toString().isNotEmpty
                                  ? Image.network(
                                      bev['photo'],
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),

                            // Participant badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  rec['participant'],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Rating badge
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppTheme.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rec['rating'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Beverage details
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bev['name'] ?? 'Drink',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Tags
                              if (tags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tag.contains('Vodka')
                                            ? const Color(0xFF6B4EFF)
                                            : tag.contains('Whisky')
                                                ? const Color(0xFFFFAB4E)
                                                : tag.contains('Sweet')
                                                    ? const Color(0xFFFF6B9D)
                                                    : const Color(0xFF4ECFFF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 8),

                              // Price
                              Text(
                                '₹${bev['price'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 140,
      color: AppTheme.glassLight,
      child: const Center(
        child: Icon(
          Icons.local_bar,
          color: AppTheme.textTertiary,
          size: 40,
        ),
      ),
    );
  }
}
