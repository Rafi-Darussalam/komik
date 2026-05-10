import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'home.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<dynamic> _bookmarks = [];
  bool _isLoading = true;
  Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      var url = Uri.parse('${AppConfig.baseUrl}/bookmarks');
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _bookmarks = jsonResponse['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching bookmarks: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeBookmark(int comicId) async {
    setState(() => _deletingIds.add(comicId));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/bookmarks/toggle/$comicId');
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _bookmarks.removeWhere((b) => b['id'] == comicId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark dihapus.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error removing bookmark: $e');
    } finally {
      if (mounted) setState(() => _deletingIds.remove(comicId));
    }
  }

  void _navigateToDetail(int comicId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicDetailPage(comicId: comicId),
      ),
    ).then((_) => _fetchBookmarks()); // refresh setelah kembali
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Bookmark Tersimpan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!_isLoading && _bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_bookmarks.length} komik',
                    style: const TextStyle(
                      color: Color(0xFF9C27B0),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 90, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada bookmark',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tekan tombol bookmark di halaman detail\nkomik untuk menyimpannya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF9C27B0),
                  onRefresh: _fetchBookmarks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookmarks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _bookmarks[index];
                      final comicId = item['id'] as int;
                      final isDeleting = _deletingIds.contains(comicId);

                      return GestureDetector(
                        onTap: () => _navigateToDetail(comicId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
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
                              // Cover Image
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(12),
                                ),
                                child: item['cover_url'] != null && (item['cover_url'] as String).isNotEmpty
                                    ? Image.network(
                                        item['cover_url'],
                                        width: 75,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 75,
                                          height: 110,
                                          color: Colors.grey.shade200,
                                          child: Icon(Icons.broken_image_outlined,
                                              color: Colors.grey.shade400),
                                        ),
                                      )
                                    : Container(
                                        width: 75,
                                        height: 110,
                                        color: Colors.grey.shade200,
                                        child: Icon(Icons.image_outlined,
                                            color: Colors.grey.shade400, size: 32),
                                      ),
                              ),

                              // Info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? 'Tanpa Judul',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['author'] ?? 'Anonim',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (item['latest_chapter'] != null && item['latest_chapter'] != '-')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9C27B0).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['latest_chapter'],
                                            style: const TextStyle(
                                              color: Color(0xFF9C27B0),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Delete button
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: isDeleting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF9C27B0),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Hapus Bookmark'),
                                              content: Text(
                                                  'Hapus "${item['title'] ?? 'komik ini'}" dari bookmark?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor: Colors.red),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            _removeBookmark(comicId);
                                          }
                                        },
                                        icon: const Icon(Icons.bookmark_remove_outlined),
                                        color: Colors.grey.shade400,
                                        tooltip: 'Hapus dari Bookmark',
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
