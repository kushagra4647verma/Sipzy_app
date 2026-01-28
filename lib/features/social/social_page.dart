import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/supabase_service.dart';
import 'tabs/badges_tab.dart';
import 'tabs/diary_tab.dart';
import 'tabs/friends_tab.dart';
import 'tabs/ratings_tab.dart';
import 'tabs/saves_tab.dart';

class ProfilePageSimple extends StatefulWidget {
  final String? userId; // null for current user

  const ProfilePageSimple({super.key, this.userId});

  @override
  State<ProfilePageSimple> createState() => _ProfilePageSimpleState();
}

class _ProfilePageSimpleState extends State<ProfilePageSimple>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _supabaseService = SupabaseService();

  late TabController _tabController;

  // Profile data
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _stats = {};

  // Tab data
  List _badges = [];
  List _diaryEntries = [];
  List _friends = [];
  List _ratings = [];
  List _bookmarks = [];

  bool _isLoading = true;
  bool _isCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkIfCurrentUser();
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkIfCurrentUser() {
    final currentUserId = _supabaseService.currentUser?.id;
    _isCurrentUser = widget.userId == null || widget.userId == currentUserId;
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadProfile(),
        _loadStats(),
        _loadBadges(),
        _loadDiary(),
        _loadFriends(),
        _loadRatings(),
        _loadBookmarks(),
      ]);
    } catch (e) {
      print('❌ Error loading profile data: $e');
      _showToast('Failed to load profile data', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getMyProfile();
      setState(() => _profile = profile);
    } catch (e) {
      print('❌ Error loading profile: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final userId = widget.userId ?? _supabaseService.currentUser?.id ?? '';
      final stats = await _userService.getUserStats(userId);
      setState(() => _stats = stats);
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _userService.getMyBadges();
      setState(() => _badges = badges);
    } catch (e) {
      print('❌ Error loading badges: $e');
    }
  }

  Future<void> _loadDiary() async {
    try {
      final entries = await _userService.getAllDiaryEntries();
      setState(() => _diaryEntries = entries);
    } catch (e) {
      print('❌ Error loading diary: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _userService.getAllFriends();
      setState(() => _friends = friends);
    } catch (e) {
      print('❌ Error loading friends: $e');
    }
  }

  Future<void> _loadRatings() async {
    try {
      final userId = widget.userId ?? _supabaseService.currentUser?.id ?? '';
      final ratings = await _userService.getUserRatings(userId);
      setState(() => _ratings = ratings);
    } catch (e) {
      print('❌ Error loading ratings: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _userService.getAllBookmarks();
      setState(() => _bookmarks = bookmarks);
    } catch (e) {
      print('❌ Error loading bookmarks: $e');
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          _profile['name'] ?? 'Profile',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isCurrentUser)
            IconButton(
              onPressed: () {
                // Navigate to edit profile or settings
              },
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 16),
        _buildTabBar(),
        Expanded(child: _buildTabView()),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final name = _profile['name'] ?? 'User';
    final username = _profile['username'] ?? '';
    final bio = _profile['bio'] ?? '';
    final location = _profile['location'] ?? _profile['city'] ?? '';
    final photo = _profile['photo'] ?? _profile['profile_photo'];

    final ratingsCount = _stats['ratingsCount'] ?? 0;
    final friendsCount = _stats['friendsCount'] ?? 0;
    final bookmarksCount = _bookmarks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          _buildProfilePicture(photo),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Bio
          if (bio.isNotEmpty) ...[
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          // Location
          if (location.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.textTertiary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Ratings', ratingsCount),
              _buildStatItem('Friends', friendsCount),
              _buildStatItem('Saves', bookmarksCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(dynamic photo) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: AppTheme.glassLight,
        backgroundImage: photo != null && photo.toString().isNotEmpty
            ? NetworkImage(photo.toString())
            : null,
        child: photo == null || photo.toString().isEmpty
            ? const Icon(Icons.person, size: 50, color: AppTheme.textTertiary)
            : null,
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.background,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.emoji_events, size: 20),
            text: 'Badges',
          ),
          Tab(
            icon: Icon(Icons.book, size: 20),
            text: 'Diary',
          ),
          Tab(
            icon: Icon(Icons.group, size: 20),
            text: 'Friends',
          ),
          Tab(
            icon: Icon(Icons.star, size: 20),
            text: 'Ratings',
          ),
          Tab(
            icon: Icon(Icons.bookmark, size: 20),
            text: 'Saves',
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        BadgesTab(
          badges: _badges,
          stats: _stats,
          bookmarks: _bookmarks,
          onRefresh: _loadAllData,
        ),
        DiaryTab(
          entries: _diaryEntries,
          onRefresh: _loadAllData,
        ),
        FriendsTab(
          friends: _friends,
          onRefresh: _loadAllData,
        ),
        RatingsTab(
          ratings: _ratings,
          onRefresh: _loadAllData,
        ),
        SavesTab(
          bookmarks: _bookmarks,
          userService: _userService,
          onRefresh: _loadAllData,
          showToast: _showToast,
        ),
      ],
    );
  }
}
