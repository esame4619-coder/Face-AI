import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MohtarifAI());
}

class MohtarifAI extends StatelessWidget {
  const MohtarifAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'المحترف في AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10121D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    MyWorksPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          backgroundColor: const Color(0xFF191B2B),
          indicatorColor: const Color(0xFF7048C8),
          onDestinationSelected: (index) {
            setState(() => selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'أعمالي',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Map<String, dynamic>> tools = const [
    {
      'name': 'تبديل الوجوه',
      'description': 'تبديل الوجوه في الصور',
      'icon': Icons.face_retouching_natural,
      'color': Color(0xFF8B5CF6),
      'type': 'image',
    },
    {
      'name': 'استوديو الفيديو',
      'description': 'إنشاء وتعديل فيديوهات AI',
      'icon': Icons.movie_creation,
      'color': Color(0xFFEC4899),
      'type': 'video',
    },
    {
      'name': 'استنساخ الأصوات',
      'description': 'إنشاء أصوات والتحكم فيها',
      'icon': Icons.record_voice_over,
      'color': Color(0xFF06B6D4),
      'type': 'voice',
    },
    {
      'name': 'تغيير الأصوات',
      'description': 'المصرية والإنجليزية',
      'icon': Icons.graphic_eq,
      'color': Color(0xFF10B981),
      'type': 'changevoice',
    },
    {
      'name': 'صناعة الأغاني',
      'description': 'إنشاء أغاني بالذكاء الاصطناعي',
      'icon': Icons.music_note,
      'color': Color(0xFFF59E0B),
      'type': 'music',
    },
    {
      'name': 'تحسين الصور',
      'description': 'رفع الجودة وإزالة العيوب',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF3B82F6),
      'type': 'enhance',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المحترف في AI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'عالمك الإبداعي بين إيديك',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7048C8),
                          Color(0xFF252A55),
                        ],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, size: 35),
                        SizedBox(height: 12),
                        Text(
                          'استوديو الذكاء الاصطناعي',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'اصنع صورك وفيديوهاتك وأصواتك بطريقتك.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'أدواتك الإبداعية',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = tools[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      openTool(context, tool['type']);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1E2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            tool['icon'],
                            color: tool['color'],
                            size: 35,
                          ),
                          const Spacer(),
                          Text(
                            tool['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tool['description'],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: tools.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.12,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }

  void openTool(BuildContext context, String type) {
    if (type == 'image' || type == 'enhance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageStudio(enhance: type == 'enhance'),
        ),
      );
    } else {
      final names = {
        'video': 'استوديو الفيديو',
        'voice': 'استنساخ الأصوات',
        'changevoice': 'تغيير الأصوات',
        'music': 'صناعة الأغاني',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComingSoonPage(title: names[type]!),
        ),
      );
    }
  }
}

class ImageStudio extends StatefulWidget {
  final bool enhance;

  const ImageStudio({super.key, this.enhance = false});

  @override
  State<ImageStudio> createState() => _ImageStudioState();
}

class _ImageStudioState extends State<ImageStudio> {
  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الصورة'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.enhance ? 'تحسين الصور' : 'استوديو الصور',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E2E),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12),
                ),
                child: selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 75,
                            color: Color(0xFF9B7BFA),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'اختر صورة للبدء',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'يمكنك اختيار صورة من هاتفك',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('اختيار صورة من المعرض'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(17),
                  backgroundColor: const Color(0xFF7048C8),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقاط صورة بالكاميرا'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(17),
                ),
              ),
            ),
            if (selectedImage != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() => selectedImage = null);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('إزالة الصورة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 75,
              color: Color(0xFF9B7BFA),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'نجهز أدوات الاستوديو الخاص بك',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class MyWorksPage extends StatelessWidget {
  const MyWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 65, color: Colors.white54),
          SizedBox(height: 15),
          Text(
            'أعمالي',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر هنا ملفاتك ونتائج أعمالك',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('المستخدم الشخصي'),
              subtitle: Text('تطبيقك الخاص'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('اللغة'),
              subtitle: Text('العربية'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('عن التطبيق'),
              subtitle: Text('المحترف في AI'),
            ),
          ],
        ),
      ),
    );
  }
}
