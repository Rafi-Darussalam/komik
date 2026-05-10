import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'start.dart';
import 'notification_page.dart';
import 'bookmarks_page.dart';

// Helper untuk format rating agar konsisten (misal: 1.0, 4.5)
String _formatRating(dynamic rating) {
  if (rating == null) return '0.0';
  double? val = double.tryParse(rating.toString());
  if (val == null) return '0.0';
  return val.toStringAsFixed(1);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;
  late PageController _pageController;
  int _currentCarouselIndex = 1;

  final TextEditingController _searchController = TextEditingController();

  // Array untuk melacak history klik komik (List item akan bertambah dinamis di menu ke-3)
  Map<String, dynamic>? _userData;
  List<dynamic> _apiHistories = [];
  bool _isLoadingHistories = true;
  List<dynamic> _apiComics = [];
  bool _isLoadingComics = true;
  Timer? _carouselTimer;
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingPhoto = false;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    // Infinite scroll: memberikan nilai awal yang besar agar bisa scroll ke kiri/kanan tanpa batas (9999 % 3 = 0, mulai dari komik pertama)
    _pageController = PageController(viewportFraction: 0.6, initialPage: 9999);
    // Timer untuk auto slide carousel setiap 4 detik
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
    // Listener untuk memicu render ulang (rebuild) ketika teks pencarian berubah
    _searchController.addListener(() {
      setState(() {});
    });

    _fetchComics();
    _fetchHistories();
    _fetchUser();
    _fetchNotificationsCount();
  }

  Future<void> _fetchNotificationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/notifications');
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> notifs = jsonResponse['data'];
        setState(() {
          _unreadNotificationsCount = notifs.length;
        });
      }
    } catch (e) {
      print('Error fetching notifications count: $e');
    }
  }

  Future<void> _fetchUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/user');
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
          _userData = jsonResponse;
        });
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  Future<void> _fetchHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/histories');
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
          _apiHistories = jsonResponse['data'];
          _isLoadingHistories = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingHistories = false;
      });
    }
  }

  Future<void> _fetchComics() async {
    try {
      var url = Uri.parse('${AppConfig.baseUrl}/comics');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _apiComics = jsonResponse['data'];
          _isLoadingComics = false;
        });
      } else {
        setState(() {
          _isLoadingComics = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingComics = false;
      });
    }
  }

  Future<void> _pickAndCropProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _updateProfilePhoto(pickedFile);
    }
  }

  Future<void> _updateProfilePhoto(XFile imageFile) async {
    setState(() => _isUpdatingPhoto = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/user/profile-photo');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_photo',
            bytes,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _userData = jsonResponse['user'];
          // Pastikan profile_photo_url ada di dalam _userData
          if (_userData != null && jsonResponse['profile_photo_url'] != null) {
            _userData!['profile_photo_url'] = jsonResponse['profile_photo_url'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui foto profil')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUpdatingPhoto = false);
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==== LOGIKA NAVIGASI DETAIL KOMIK + HISTORY TRACKING ====
  void _openComicDetail(dynamic comic) async {
    final int comicId = comic['id'];

    // Record history to API
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/histories'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: {'comic_id': comicId.toString(), 'last_chapter_read': '1'},
        );
        _fetchHistories(); // Refresh history list
      }
    } catch (e) {
      print('Error recording history: $e');
    }

    // Buka halaman ComicDetailPage
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComicDetailPage(comicId: comicId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: _selectedIndex == 1
                ? _buildSearchPage()
                : _selectedIndex == 2
                ? _buildHistoryPage()
                : _selectedIndex == 3
                ? _buildSettingsPage()
                : _buildHomePage(),
          ),

          // Fixed Bottom Bar position
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 20,
              ),
              child: _buildBottomBar(),
            ),
          ),
        ],
      ),
    );
  }

  // ==== HALAMAN UTAMA ====

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: 120,
      ), // Padding to prevent content hiding behind bottom bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Untuk Anda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 15),
          _buildCarousel(),
          const SizedBox(height: 15),
          _buildCarouselIndicator(),
          const SizedBox(height: 25),
          _buildCategories(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildVerticalList(),
          ),
        ],
      ),
    );
  }

  // ==== HALAMAN PENCARIAN ====

  Widget _buildSearchPage() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              icon: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.black54,
                                ),
                              ),
                              hintText: 'Cari',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(Icons.tune, size: 30),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: 120,
                      left: 20,
                      right: 20,
                    ),
                    child: _buildVerticalList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==== HALAMAN HISTORY ====
  Widget _buildHistoryPage() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _isLoadingHistories
                ? const Center(child: CircularProgressIndicator())
                : _apiHistories.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada histori membaca.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchHistories,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        bottom: 120,
                        left: 20,
                        right: 20,
                        top: 20,
                      ),
                      child: Column(
                        children: _apiHistories.map((history) {
                          final comic = history['comic'];
                          return _buildComicItem(comic);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ==== HALAMAN SETTINGS & LOGOUT ====
  Widget _buildSettingsPage() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 40),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF9C27B0),
                          width: 2,
                        ),
                      ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              _userData != null &&
                                      _userData!['profile_photo_url'] != null &&
                                      _userData!['profile_photo_url'].toString().isNotEmpty
                                  ? NetworkImage(
                                      '${_userData!['profile_photo_url']}?v=${DateTime.now().millisecondsSinceEpoch}',
                                    )
                                  : null,
                          child: (_userData == null ||
                                  _userData!['profile_photo_url'] == null ||
                                  _userData!['profile_photo_url'].toString().isEmpty)
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                )
                              : _isUpdatingPhoto
                                  ? const CircularProgressIndicator()
                                  : null,
                        ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUpdatingPhoto
                            ? null
                            : _pickAndCropProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF9C27B0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  _userData != null ? _userData!['name'] : 'Nama User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData != null ? _userData!['email'] : 'Email User',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 30),
                const Divider(),
                
                ListTile(
                  leading: const Icon(
                    Icons.bookmark_outline,
                    color: Color(0xFF9C27B0),
                  ),
                  title: const Text('Bookmark Tersimpan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookmarksPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Keluar Akun',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Panggil API logout (opsional tapi disarankan)
      if (token != null) {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }

      // Hapus token lokal
      await prefs.remove('auth_token');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StartPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Jika gagal API, tetap hapus token lokal dan balik ke start
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StartPage()),
          (route) => false,
        );
      }
    }
  }

  // ==== KOMPONEN GLOBAL UI ====

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    _userData != null &&
                            _userData!['profile_photo_url'] != null &&
                            _userData!['profile_photo_url'].toString().isNotEmpty
                        ? NetworkImage(
                            '${_userData!['profile_photo_url']}?v=${DateTime.now().millisecondsSinceEpoch}',
                          )
                        : null,
                child: (_userData == null ||
                        _userData!['profile_photo_url'] == null ||
                        _userData!['profile_photo_url'].toString().isEmpty)
                    ? Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    _userData != null ? _userData!['name'] : 'Memuat...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 28),
                onPressed: () {
                  // Langsung hilangkan badge saat ikon ditekan
                  setState(() => _unreadNotificationsCount = 0);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_unreadNotificationsCount > 9 ? '9+' : _unreadNotificationsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    if (_isLoadingComics) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_apiComics.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('Tidak ada komik')),
      );
    }

    // Ambil 3 komik pertama dari API
    final carouselData = _apiComics.take(3).toList();

    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentCarouselIndex = index % carouselData.length;
          });
        },
        itemBuilder: (context, index) {
          final realIndex = index % carouselData.length;
          final data = carouselData[realIndex];

          return _buildCarouselItem(
            index, // Mengirimkan index absolut untuk animasi parallax
            data,
          );
        },
      ),
    );
  }

  Widget _buildCarouselItem(int index, dynamic comic) {
    final String imagePath = comic['cover_url'] ?? 'images/background.png';
    final String avgRating = _formatRating(comic['ratings_avg_rating']);

    return GestureDetector(
      onTap: () => _openComicDetail(comic),
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double value = 1.0;
          if (_pageController.position.haveDimensions) {
            value = _pageController.page! - index;
            value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
          } else {
            value = index == 9999 ? 1.0 : 0.85;
          }

          return Center(
            child: SizedBox(height: 250 * value, child: child),
          );
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: imagePath.startsWith('http')
                      ? NetworkImage(imagePath)
                      : AssetImage(imagePath) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      avgRating,
                      style: const TextStyle(
                        color: Colors.white,
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

  Widget _buildCarouselIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: _currentCarouselIndex == index ? 25 : 15,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _currentCarouselIndex == index
                ? Colors.black
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildCategories() {
    final categories = ['Populer', 'Baru', 'Harian'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(
                  right: index != categories.length - 1 ? 10 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF9C27B0) : Colors.white,
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerticalList() {
    if (_isLoadingComics) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_apiComics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('Tidak ada komik')),
      );
    }

    // Sort berdasarkan kategori aktif
    List<dynamic> sortedComics = List.from(_apiComics);
    final now = DateTime.now();

    if (_selectedCategoryIndex == 0) {
      // Populer: rating tertinggi dulu
      sortedComics.sort((a, b) {
        final ratingA = double.tryParse(a['ratings_avg_rating']?.toString() ?? '0') ?? 0;
        final ratingB = double.tryParse(b['ratings_avg_rating']?.toString() ?? '0') ?? 0;
        return ratingB.compareTo(ratingA);
      });
    } else if (_selectedCategoryIndex == 1) {
      // Baru: created_at terbaru dulu
      sortedComics.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
    } else if (_selectedCategoryIndex == 2) {
      // Harian: komik yang dibuat/diperbarui dalam 7 hari terakhir, rating tertinggi
      sortedComics = sortedComics.where((comic) {
        final date = DateTime.tryParse(comic['created_at'] ?? '');
        if (date == null) return false;
        return now.difference(date).inDays <= 7;
      }).toList();

      if (sortedComics.isEmpty) {
        // Fallback: kalau tidak ada yang baru, tampilkan semua, sortir rating
        sortedComics = List.from(_apiComics);
        sortedComics.sort((a, b) {
          final ratingA = double.tryParse(a['ratings_avg_rating']?.toString() ?? '0') ?? 0;
          final ratingB = double.tryParse(b['ratings_avg_rating']?.toString() ?? '0') ?? 0;
          return ratingB.compareTo(ratingA);
        });
      } else {
        sortedComics.sort((a, b) {
          final ratingA = double.tryParse(a['ratings_avg_rating']?.toString() ?? '0') ?? 0;
          final ratingB = double.tryParse(b['ratings_avg_rating']?.toString() ?? '0') ?? 0;
          return ratingB.compareTo(ratingA);
        });
      }
    }

    if (sortedComics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Belum ada komik dalam kategori ini.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: sortedComics.map((data) {
        return _buildComicItem(data);
      }).toList(),
    );
  }


  Widget _buildComicItem(dynamic comic) {
    final String title = comic['title'] ?? 'Unknown';
    final keyword = _searchController.text.toLowerCase();

    // Hanya disaring apabila sedang berada pada menu pencarian
    if (_selectedIndex == 1 &&
        keyword.isNotEmpty &&
        !title.toLowerCase().contains(keyword)) {
      return const SizedBox.shrink();
    }

    return _ComicListItem(
      comic: comic,
      onTap: () => _openComicDetail(comic),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDCE4),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home, 0),
          _buildNavItem(Icons.search_outlined, Icons.search, 1),
          _buildNavItem(Icons.history_outlined, Icons.history, 2),
          _buildNavItem(Icons.settings_outlined, Icons.settings, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData solidIcon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          // Kosongkan keyword pencarian saat pindah tab (selain menu Search)
          if (index != 1) {
            _searchController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C27B0) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? solidIcon : outlinedIcon,
          color: isSelected ? Colors.white : Colors.black87,
          size: 28,
        ),
      ),
    );
  }
}

// ============================================================================ //
//  KOMPONEN REUSABLE HALAMAN DETAIL KOMIK (HANYA DIKLIK MELALUI NAVIGATOR PUSH)
// ============================================================================ //

class ComicDetailPage extends StatefulWidget {
  final int comicId;

  const ComicDetailPage({super.key, required this.comicId});

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  dynamic _comicData;
  bool _isLoading = true;
  int _userRating = 0; // 0 means not rated yet
  bool _isBookmarked = false;
  bool _isTogglingBookmark = false;

  @override
  void initState() {
    super.initState();
    _fetchComicDetail();
    _fetchUserRating();
    _fetchBookmarkStatus();
  }

  Future<void> _fetchUserRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/ratings/${widget.comicId}');
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
          _userRating = jsonResponse['rating'];
        });
      }
    } catch (e) {
      print('Error fetching user rating: $e');
    }
  }

  Future<void> _submitRating(int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/ratings');
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'comic_id': widget.comicId.toString(),
          'rating': rating.toString(),
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _userRating = rating;
          // Update average rating in _comicData
          if (_comicData != null) {
            _comicData['ratings_avg_rating'] = jsonResponse['average_rating'];
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terima kasih atas rating Anda!')),
          );
        }
      }
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  Future<void> _fetchBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/bookmarks/check/${widget.comicId}');
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && mounted) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _isBookmarked = jsonResponse['is_bookmarked'] == true;
        });
      }
    } catch (e) {
      print('Error fetching bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;
    setState(() => _isTogglingBookmark = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      var url = Uri.parse('${AppConfig.baseUrl}/bookmarks/toggle/${widget.comicId}');
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && mounted) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _isBookmarked = jsonResponse['is_bookmarked'] == true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? 'Berhasil ditambahkan ke bookmark!' : 'Bookmark dihapus.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
    } finally {
      if (mounted) setState(() => _isTogglingBookmark = false);
    }
  }

  Future<void> _fetchComicDetail() async {
    try {
      var url = Uri.parse('${AppConfig.baseUrl}/comics/${widget.comicId}');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _comicData = jsonResponse['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_comicData == null) {
      return const Scaffold(body: Center(child: Text('Gagal memuat data')));
    }

    final String title = _comicData['title'] ?? 'Unknown';
    final String imagePath = _comicData['cover_url'] ?? 'images/background.png';
    final String category = _comicData['author'] ?? 'Unknown';
    final String displaySynopsis =
        _comicData['synopsis'] ?? 'Tidak ada sinopsis.';
    final List<dynamic> displayEpisodes = _comicData['episodes'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image dengan Back Button dan Gradient transisi
            Stack(
              children: [
                // Gambar utama latar belakang komik
                SizedBox(
                  height: 450,
                  width: double.infinity,
                  child: imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey),
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                ),
                // Gradient untuk memudarkan (fade) gambar ke warna putih
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
                // Tombol Back di kiri atas layar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Tombol Share di kanan atas layar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ),
                // Identitas Judul, Kategori, Views, & Likes
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Color(0xFF9C27B0),
                            size: 18,
                          ),
                          SizedBox(width: 5),
                          Text(
                            (_comicData['histories_count'] ?? 0).toString(),
                            style: const TextStyle(
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.star, color: Color(0xFF9C27B0), size: 18),
                          SizedBox(width: 5),
                          Text(
                            _formatRating(_comicData['ratings_avg_rating']),
                            style: const TextStyle(
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 15),
                          Text(
                            '(${_comicData['ratings_count'] ?? 0} Rating)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Layout Tombol Aksi List, Rate, Komen, Download
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    'Beri Rating Komik Ini:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _userRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 35,
                        ),
                        onPressed: () => _submitRating(index + 1),
                      );
                    }),
                  ),
                  if (_userRating > 0)
                    const Text(
                      'Anda sudah memberi rating',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Layout Tombol Aksi List, Rate, Komen, Download
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _toggleBookmark,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _isBookmarked
                                ? const Color(0xFF9C27B0)
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: _isTogglingBookmark
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: _isBookmarked
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isBookmarked ? 'Tersimpan' : 'Simpan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isBookmarked
                                ? const Color(0xFF9C27B0)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDetailActionButton(Icons.chat_bubble_outline, 'Komen'),
                  _buildDetailActionButton(Icons.download_outlined, 'Download'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Bagian Sinopsis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displaySynopsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Bagian Daftar Episode
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Episode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ...displayEpisodes.map(
              (ep) => _buildDetailEpisodeItem(
                context,
                title,
                ep['title'] ?? 'Chapter',
                ep['created_at']?.split('T')[0] ?? '',
                imagePath,
                ep['content'] ?? '',
                ep['id'],
              ),
            ),

            const SizedBox(height: 40), // Padding pernapasan bawah
          ],
        ),
      ),
    );
  }

  Widget _buildDetailActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: Color(0xFF9C27B0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDetailEpisodeItem(
    BuildContext context,
    String comicTitle,
    String epTitle,
    String date,
    String imagePath,
    String content,
    int episodeId,
  ) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingPage(
              title: comicTitle,
              epTitle: epTitle,
              episodeId: episodeId,
            ),

          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
              child: imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      imagePath,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    epTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.star, color: Color(0xFF9C27B0), size: 18),
            const SizedBox(width: 5),
            Text(
              _formatRating(_comicData?['ratings_avg_rating']),
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
}

class ReadingPage extends StatefulWidget {
  final String title;
  final String epTitle;
  final int episodeId;

  const ReadingPage({
    super.key,
    required this.title,
    required this.epTitle,
    required this.episodeId,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  List<dynamic> _panels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPanels();
  }

  Future<void> _fetchPanels() async {
    try {
      var url = Uri.parse('${AppConfig.baseUrl}/episodes/${widget.episodeId}');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _panels = jsonResponse['data']['panels'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          '${widget.title} - ${widget.epTitle}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _panels.length + 1,
              itemBuilder: (context, index) {
                if (index == _panels.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'To be continued...',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  );
                }

                final panel = _panels[index];
                final String imagePath = panel['image_path'];
                final String imageUrl = imagePath.startsWith('http')
                    ? imagePath
                    : '${AppConfig.baseUrl}/images/$imagePath';

                return Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}

// ==== STATEFUL COMIC LIST ITEM (untuk bookmark mandiri per item) ====
class _ComicListItem extends StatefulWidget {
  final dynamic comic;
  final VoidCallback onTap;

  const _ComicListItem({required this.comic, required this.onTap});

  @override
  State<_ComicListItem> createState() => _ComicListItemState();
}

class _ComicListItemState extends State<_ComicListItem> {
  bool _isBookmarked = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final comicId = widget.comic['id'];
      var url = Uri.parse('${AppConfig.baseUrl}/bookmarks/check/$comicId');
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _isBookmarked = data['is_bookmarked'] == true;
        });
      }
    } catch (e) {
      print('Error checking bookmark: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final comicId = widget.comic['id'];
      var url = Uri.parse('${AppConfig.baseUrl}/bookmarks/toggle/$comicId');
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _isBookmarked = data['is_bookmarked'] == true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked
                ? 'Ditambahkan ke bookmark!'
                : 'Bookmark dihapus.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.comic['title'] ?? 'Unknown';
    final String category = widget.comic['author'] ?? 'Unknown';
    final String imagePath = widget.comic['cover_url'] ?? 'images/background.png';
    final String avgRating = _formatRating(widget.comic['ratings_avg_rating']);

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 90, height: 120, color: Colors.grey.shade200),
                    )
                  : Image.asset(
                      imagePath,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFF9C27B0), size: 18),
                      const SizedBox(width: 5),
                      Text(
                        avgRating,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bookmark button
            _isToggling
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 28,
                      color: _isBookmarked
                          ? const Color(0xFF9C27B0)
                          : Colors.grey.shade600,
                    ),
                    onPressed: _toggleBookmark,
                  ),
          ],
        ),
      ),
    );
  }
}
