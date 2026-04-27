import 'dart:async';
import 'package:flutter/material.dart';

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
  final List<Map<String, String>> _historyList = [];
  Timer? _carouselTimer;
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
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==== LOGIKA NAVIGASI DETAIL KOMIK + HISTORY TRACKING ====
  void _openComicDetail(
    String title,
    String category,
    String likes,
    String imagePath,
  ) {
    setState(() {
      // Menghapus jika sudah ada, kemudian memindahkannya kembali ke bagian paling atas
      _historyList.removeWhere((item) => item['title'] == title);
      _historyList.insert(0, {
        'title': title,
        'category': category,
        'likes': likes,
        'imagePath': imagePath,
      });
    });

    // Buka halaman ComicDetailPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicDetailPage(
          title: title,
          category: category,
          likes: likes,
          imagePath: imagePath,
        ),
      ),
    );
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
            child: _historyList.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada histori membaca.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: 120,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: Column(
                      children: _historyList.map((item) {
                        return _buildComicItem(
                          item['title']!,
                          item['category']!,
                          item['likes']!,
                          item['imagePath']!,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
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
              const CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage('images/background.png'),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const Text(
                    'Mr_Brojak',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    // Ambil 3 komik pertama dari list global comicsData
    final carouselData = comicsData.take(3).toList();

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
            data['title']!,
            data['category']!,
            data['likes']!,
            data['imagePath']!,
          );
        },
      ),
    );
  }

  Widget _buildCarouselItem(
    int index,
    String title,
    String category,
    String likes,
    String imagePath,
  ) {
    return GestureDetector(
      onTap: () => _openComicDetail(title, category, likes, imagePath),
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
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
    return Column(
      children: comicsData.map((data) {
        return _buildComicItem(
          data['title'] as String,
          data['category'] as String,
          data['likes'] as String,
          data['imagePath'] as String,
        );
      }).toList(),
    );
  }

  Widget _buildComicItem(
    String title,
    String category,
    String likes,
    String imagePath,
  ) {
    // Membaca kata kunci langsung dari controller untuk mencegah error undefined karena state hot reload
    final keyword = _searchController.text.toLowerCase();

    // Hanya disaring apabila sedang berada pada menu pencarian
    if (_selectedIndex == 1 &&
        keyword.isNotEmpty &&
        !title.toLowerCase().contains(keyword)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _openComicDetail(title, category, likes, imagePath),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
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
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFF9C27B0),
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        likes,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
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

class ComicDetailPage extends StatelessWidget {
  final String title;
  final String category;
  final String likes;
  final String imagePath;

  const ComicDetailPage({
    super.key,
    required this.title,
    required this.category,
    required this.likes,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Cari data dummy berdasarkan judul komik
    final mockData = comicsData.firstWhere(
      (element) => element['title'] == title,
      orElse: () => comicsData[0], // fallback untuk mencegah error
    );

    final String displaySynopsis = mockData['synopsis'] as String;
    final List<dynamic> displayEpisodes = mockData['episodes'] as List<dynamic>;

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
                  child: Image.asset(
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
                          const Icon(
                            Icons.visibility,
                            color: Color(0xFF9C27B0),
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '631M',
                            style: TextStyle(
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(
                            Icons.person_outline,
                            color: Color(0xFF9C27B0),
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            likes,
                            style: const TextStyle(
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w600,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailActionButton(Icons.bookmark_border, 'List'),
                  _buildDetailActionButton(Icons.star_border, 'Rate'),
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
                ep['epTitle'],
                ep['date'],
                ep['likes'],
                ep['imagePath'],
                ep['content'],
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
    String epTitle,
    String date,
    String likes,
    String imagePath,
    String content,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReadingPage(title: title, epTitle: epTitle, content: content),
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
              child: Image.asset(
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
            const Icon(Icons.favorite, color: Color(0xFF9C27B0), size: 18),
            const SizedBox(width: 5),
            Text(likes, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> comicsData = [
  {
    'title': 'The Stellar Swordmaster',
    'category': 'Action',
    'likes': '2M',
    'imagePath': 'images/worlds_strongest_troll.png',
    'synopsis':
        'Sinopsis The Stellar Swordmaster (silakan diubah). Kisah seorang ahli pedang bintang yang turun ke dunia untuk mengembalikan kedamaian.',
    'episodes': [
      {
        'epTitle': 'Episode 2',
        'date': '14 Okt 2022',
        'likes': '3.100',
        'imagePath': 'images/worlds_strongest_troll.png',
        'content':
            'Isi untuk The Stellar Swordmaster - Episode 2. Konflik memanas saat karakter utama ditantang rivalnya.',
      },
      {
        'epTitle': 'Episode 1',
        'date': '7 Okt 2022',
        'likes': '2.364',
        'imagePath': 'images/worlds_strongest_troll.png',
        'content':
            'Isi untuk The Stellar Swordmaster - Episode 1. Kisah bermula dari sebuah turnamen pertarungan bawah tanah.',
      },
    ],
  },
  {
    'title': 'My Husband Was Stolen Twice',
    'category': 'Romance',
    'likes': '49.749',
    'imagePath': 'images/from_a_knight_to_a_lady.png',
    'synopsis':
        'Sinopsis My Husband Was Stolen Twice (silakan diubah). Intrik politik istana dan pengkhianatan berlapis oleh sang kekasih.',
    'episodes': [
      {
        'epTitle': 'Episode 2',
        'date': '12 Sep 2022',
        'likes': '1.500',
        'imagePath': 'images/from_a_knight_to_a_lady.png',
        'content':
            'Isi untuk My Husband Was Stolen Twice - Episode 2. Rencana pembalasan dendam mulai disiapkan perlahan-lahan.',
      },
      {
        'epTitle': 'Episode 1',
        'date': '5 Sep 2022',
        'likes': '1.000',
        'imagePath': 'images/from_a_knight_to_a_lady.png',
        'content':
            'Isi untuk My Husband Was Stolen Twice - Episode 1. Di malam yang nahas, kebenaran tentang sang suami akhirnya terungkap.',
      },
    ],
  },
  {
    'title': 'The End Has Come',
    'category': 'Thriller',
    'likes': '65.549',
    'imagePath': 'images/winter_breeze.png',
    'synopsis':
        'Sinopsis The End Has Come (silakan diubah). Ketika dunia dilanda wabah monster dari dimensi lain, satu pahlawan tersisa.',
    'episodes': [
      {
        'epTitle': 'Episode 2',
        'date': '20 Agu 2022',
        'likes': '5.000',
        'imagePath': 'images/winter_breeze.png',
        'content':
            'Isi untuk The End Has Come - Episode 2. Persediaan mulai menipis dan zona aman dikepung oleh predator haus darah.',
      },
      {
        'epTitle': 'Episode 1',
        'date': '10 Agu 2022',
        'likes': '4.500',
        'imagePath': 'images/winter_breeze.png',
        'content':
            'Isi untuk The End Has Come - Episode 1. Menyadari kejanggalan dalam siaran televisi tepat sebelum badai merah menutupi langit.',
      },
    ],
  },
  {
    'title': 'Duchess In Ruins',
    'category': 'Kerajaan',
    'likes': '12.345',
    'imagePath': 'images/background.png',
    'synopsis':
        'Sinopsis Duchess In Ruins (silakan diubah). Kisah seorang duchess agung yang membalikkan nasib kerajaannya yang tengah hancur.',
    'episodes': [
      {
        'epTitle': 'Episode 2',
        'date': '3 Nov 2022',
        'likes': '2.100',
        'imagePath': 'images/background.png',
        'content':
            'Isi untuk Duchess In Ruins - Episode 2. Strategi mulai dijalankan untuk menjatuhkan para pengkhianat istana.',
      },
      {
        'epTitle': 'Episode 1',
        'date': '26 Okt 2022',
        'likes': '1.300',
        'imagePath': 'images/background.png',
        'content':
            'Isi untuk Duchess In Ruins - Episode 1. Sebuah awal keruntuhan yang memaksa sang pahlawan bangkit kembali.',
      },
    ],
  },
  {
    'title': 'Winter Castle',
    'category': 'Fantasy',
    'likes': '1M',
    'imagePath': 'images/background.png',
    'synopsis':
        'Sinopsis Winter Castle (silakan diubah). Legenda kutukan abadi dan misteri yang menyelimuti istana es di utara.',
    'episodes': [
      {
        'epTitle': 'Episode 2',
        'date': '29 Des 2022',
        'likes': '3.200',
        'imagePath': 'images/background.png',
        'content':
            'Isi untuk Winter Castle - Episode 2. Rahasia gelap di lorong bawah tanah istana mulai terkuak.',
      },
      {
        'epTitle': 'Episode 1',
        'date': '22 Des 2022',
        'likes': '2.000',
        'imagePath': 'images/background.png',
        'content':
            'Isi untuk Winter Castle - Episode 1. Badai salju pertama membawa surat misterius dari masa lalu.',
      },
    ],
  },
];

// ============================================================================ //
//  KOMPONEN HALAMAN BACA (READING PAGE)
// ============================================================================ //

class ReadingPage extends StatelessWidget {
  final String title;
  final String epTitle;
  final String content;

  const ReadingPage({
    super.key,
    required this.title,
    required this.epTitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          '$title - $epTitle',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Placeholder Panel Komik
            _buildComicPanel('Panel 1', Colors.grey.shade300, 300),
            _buildComicPanel('Panel 2', Colors.grey.shade400, 400),
            _buildComicPanel('Panel 3', Colors.grey.shade300, 350),
            const SizedBox(height: 40),
            const Text(
              'To be continued...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildComicPanel(String text, Color color, double height) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 10),
      color: color,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
