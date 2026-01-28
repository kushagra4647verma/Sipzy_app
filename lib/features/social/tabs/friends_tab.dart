import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/user_service.dart';
import 'dart:async';

class FriendsTab extends StatefulWidget {
  final List friends;
  final VoidCallback onRefresh;

  const FriendsTab({
    super.key,
    required this.friends,
    required this.onRefresh,
  });

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final _userService = UserService();
  final _searchController = TextEditingController();
  Timer? _debounce;
  List _searchResults = [];
  bool _searching = false;
  bool _showSearch = false;
  String? _removingFriendId;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchFriends(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final results = await _userService.searchFriends(query.trim());
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      print('❌ Search friends error: $e');
      setState(() => _searching = false);
      _showToast('Failed to search friends', isError: true);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchFriends(value);
    });
  }

  Future<void> _addFriend(String userId, String name) async {
    try {
      final success = await _userService.addFriend(userId);

      if (success) {
        _showToast('Added $name as friend');
        widget.onRefresh();
        _searchController.clear();
        setState(() {
          _searchResults = [];
          _showSearch = false;
        });
      } else {
        _showToast('Failed to add friend', isError: true);
      }
    } catch (e) {
      print('❌ Add friend error: $e');
      _showToast('Error adding friend', isError: true);
    }
  }

  Future<void> _removeFriend(String friendId, String name) async {
    setState(() => _removingFriendId = friendId);

    try {
      final success = await _userService.removeFriend(friendId);

      if (success) {
        _showToast('Removed $name');
        widget.onRefresh();
      } else {
        _showToast('Failed to remove friend', isError: true);
      }
    } catch (e) {
      print('❌ Remove friend error: $e');
      _showToast('Error removing friend', isError: true);
    } finally {
      setState(() => _removingFriendId = null);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _showSearch ? _buildSearchResults() : _buildFriendsList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showSearch
                      ? AppTheme.primary.withOpacity(0.5)
                      : AppTheme.border.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppTheme.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _onSearchChanged(value);
                        setState(() => _showSearch = value.isNotEmpty);
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search friends by name...',
                        hintStyle: TextStyle(
                            color: AppTheme.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppTheme.textTertiary, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showSearch = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'No users found',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => _UserCard(
        user: _searchResults[i],
        onAdd: _addFriend,
        isFriend: _isFriend(_searchResults[i]['id'] ??
            _searchResults[i]['userId'] ??
            _searchResults[i]['user_id']),
      ),
    );
  }

  bool _isFriend(String? userId) {
    if (userId == null) return false;
    return widget.friends.any((f) =>
        (f['friendId'] ?? f['friend_id'] ?? f['userId'] ?? f['id']) == userId);
  }

  Widget _buildFriendsList() {
    if (widget.friends.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.primary,
      backgroundColor: AppTheme.card,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.friends.length,
        itemBuilder: (_, i) => _FriendCard(
          friend: widget.friends[i],
          onRemove: (id, name) => _confirmRemoveFriend(id, name),
          isRemoving: _removingFriendId ==
              (widget.friends[i]['friendId'] ??
                  widget.friends[i]['friend_id'] ??
                  widget.friends[i]['id']),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child:
                Icon(Icons.group_outlined, size: 64, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          const Text(
            'No friends yet',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for friends to connect\nand share your beverage journey',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _showSearch = true);
              // Focus search field
            },
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('Search Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFriend(String friendId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title:
            const Text('Remove Friend?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove $name from your friends?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friendId, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map user;
  final Function(String, String) onAdd;
  final bool isFriend;

  const _UserCard({
    required this.user,
    required this.onAdd,
    required this.isFriend,
  });

  @override
  Widget build(BuildContext context) {
    final userId = user['id'] ?? user['userId'] ?? user['user_id'] ?? '';
    final name = user['name'] ?? user['username'] ?? 'User';
    final photo = user['photo'] ?? user['profile_photo'] ?? user['avatar'];
    final location = user['location'] ?? user['city'] ?? '';
    final friendsCount = user['friendsCount'] ?? user['friends_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _buildAvatar(photo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.textTertiary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  '$friendsCount friends',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
              ),
              child: const Text(
                'Friends',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => onAdd(userId.toString(), name),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic photo) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.glassLight,
      backgroundImage: photo != null && photo.toString().isNotEmpty
          ? NetworkImage(photo.toString())
          : null,
      child: photo == null || photo.toString().isEmpty
          ? const Icon(Icons.person, color: AppTheme.textTertiary, size: 24)
          : null,
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Map friend;
  final Function(String, String) onRemove;
  final bool isRemoving;

  const _FriendCard({
    required this.friend,
    required this.onRemove,
    required this.isRemoving,
  });

  @override
  Widget build(BuildContext context) {
    final friendId =
        friend['friendId'] ?? friend['friend_id'] ?? friend['id'] ?? '';
    final name = friend['name'] ?? friend['username'] ?? 'Friend';
    final photo =
        friend['photo'] ?? friend['profile_photo'] ?? friend['avatar'];
    final location = friend['location'] ?? friend['city'] ?? '';
    final friendsCount = friend['friendsCount'] ?? friend['friends_count'] ?? 0;

    return GestureDetector(
      onTap: () {
        if (friendId.toString().isNotEmpty) {
          context.push('/profile/$friendId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            _buildAvatar(photo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppTheme.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '$friendsCount friends',
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isRemoving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            else
              IconButton(
                onPressed: () => onRemove(friendId.toString(), name),
                icon: const Icon(Icons.person_remove),
                color: Colors.red.shade400,
                tooltip: 'Remove Friend',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic photo) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.glassLight,
      backgroundImage: photo != null && photo.toString().isNotEmpty
          ? NetworkImage(photo.toString())
          : null,
      child: photo == null || photo.toString().isEmpty
          ? const Icon(Icons.person, color: AppTheme.textTertiary, size: 24)
          : null,
    );
  }
}
