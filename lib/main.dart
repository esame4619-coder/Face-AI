import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      ),
      home: const HomeScreen(),
    );
  }
}

// الشاشة الرئيسية

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

// الصفحة الرئيسية

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Map<String, dynamic>> tools = const [
    {
      'name': 'تبديل الوجوه',
      'description': 'تبديل الوجوه في الصور',
      'icon': Icons.face_retouching_natural,
      'color': Color(0xFF8B5CF6),
      'type': 'faceswap',
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
                        border: Border.all(color: Colors.white10),
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
    if (type == 'faceswap') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FaceSwapStudio(),
        ),
      );
    } else if (type == 'enhance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ImageStudio(enhance: true),
        ),
      );
    } else if (type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ComingSoonPage(
            title: 'استوديو الفيديو',
          ),
        ),
      );
    } else {
      final names = {
        'voice': 'استنساخ الأصوات',
        'changevoice': 'تغيير الأصوات',
        'music': 'صناعة الأغاني',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComingSoonPage(
            title: names[type]!,
          ),
        ),
      );
    }
  }
}

// استوديو تبديل الوجوه

class FaceSwapStudio extends StatefulWidget {
  const FaceSwapStudio({super.key});

  @override
  State<FaceSwapStudio> createState() => _FaceSwapStudioState();
}

class _FaceSwapStudioState extends State<FaceSwapStudio> {
  final ImagePicker picker = ImagePicker();

  File? sourceFace;
  File? targetImage;
  File? resultImage;
  bool isProcessing = false;

  Future<void> runFaceSwap() async {
    if (sourceFace == null || targetImage == null || isProcessing) return;
    setState(() => isProcessing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      var baseUrl = (prefs.getString('backend_url') ?? '').trim();
      while (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      if (baseUrl.isEmpty) {
        throw Exception('احفظ عنوان خادم المعالجة من الإعدادات أولاً.');
      }
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/faceswap'));
      request.files.add(await http.MultipartFile.fromPath('source', sourceFace!.path));
      request.files.add(await http.MultipartFile.fromPath('target', targetImage!.path));
      final streamed = await request.send().timeout(const Duration(minutes: 6));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception('الخادم رد برمز ${response.statusCode}.');
      }
      final directory = await getApplicationDocumentsDirectory();
      final output = File('${directory.path}/faceswap_${DateTime.now().millisecondsSinceEpoch}.png');
      await output.writeAsBytes(response.bodyBytes, flush: true);
      if (!mounted) return;
      setState(() => resultImage = output);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تبديل الوجه وحفظ النتيجة داخل التطبيق.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تبديل الوجه: $error')),
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> selectImage(bool isFace) async {
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (file == null) return;

      setState(() {
        if (isFace) {
          sourceFace = File(file.path);
        } else {
          targetImage = File(file.path);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر اختيار الصورة'),
        ),
      );
    }
  }

  Widget imageBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 230,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Expanded(
                child: image == null
                    ? const Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          size: 55,
                          color: Color(0xFF9B7BFA),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استوديو تبديل الوجوه'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'اختر الوجه والصورة المستهدفة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'حدد الصورتين لتجهيز عملية التبديل',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                imageBox(
                  title: 'الوجه الأصلي',
                  image: sourceFace,
                  onTap: () => selectImage(true),
                ),
                const SizedBox(width: 12),
                imageBox(
                  title: 'الصورة المستهدفة',
                  image: targetImage,
                  onTap: () => selectImage(false),
                ),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sourceFace != null && targetImage != null && !isProcessing
                    ? runFaceSwap
                    : null,
                icon: isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(isProcessing ? 'جاري تنفيذ تبديل الوجه...' : 'ابدأ تبديل الوجه'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7048C8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                ),
              ),
            ),
            if (resultImage != null) ...[
              const SizedBox(height: 16),
              const Text('النتيجة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(resultImage!, height: 220, fit: BoxFit.contain),
              ),
            ],
            const SizedBox(height: 15),
            const Text(
              'يمكنك تغيير أي صورة وإعادة اختيارها في أي وقت.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

// استوديو الصور وتحسينها

class ImageStudio extends StatefulWidget {
  final bool enhance;

  const ImageStudio({super.key, this.enhance = false});

  @override
  State<ImageStudio> createState() => _ImageStudioState();
}

class _ImageStudioState extends State<ImageStudio> {
  File? selectedImage;
  File? enhancedImage;
  bool isEnhancing = false;
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

  Future<void> enhanceSelectedImage() async {
    if (selectedImage == null || isEnhancing) return;
    setState(() => isEnhancing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      var baseUrl = (prefs.getString('backend_url') ?? '').trim();
      while (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      if (baseUrl.isEmpty) throw Exception('احفظ عنوان خادم المعالجة من الإعدادات أولاً.');
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/enhance'));
      request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
      final streamed = await request.send().timeout(const Duration(minutes: 2));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) throw Exception('الخادم رد برمز ${response.statusCode}.');
      final directory = await getApplicationDocumentsDirectory();
      final output = File('${directory.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.png');
      await output.writeAsBytes(response.bodyBytes, flush: true);
      if (!mounted) return;
      setState(() => enhancedImage = output);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحسين الصورة وحفظ النتيجة داخل التطبيق.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحسين الصورة: $error')));
    } finally {
      if (mounted) setState(() => isEnhancing = false);
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
            if (widget.enhance && selectedImage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isEnhancing ? null : enhanceSelectedImage,
                  icon: isEnhancing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high),
                  label: Text(isEnhancing ? 'جاري تحسين الصورة...' : 'ابدأ تحسين الصورة'),
                ),
              ),
              if (enhancedImage != null) ...[
                const SizedBox(height: 12),
                const Text('الصورة بعد التحسين'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(enhancedImage!, height: 180, fit: BoxFit.contain),
                ),
              ],
            ],
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

// الأدوات التي سيتم تطويرها

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

// صفحة أعمالي

class MyWorksPage extends StatelessWidget {
  const MyWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 65,
            color: Colors.white54,
          ),
          SizedBox(height: 15),
          Text(
            'أعمالي',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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

// الإعدادات

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController controller = TextEditingController();
  bool isLoading = true;
  bool isTesting = false;
  @override
  void initState() { super.initState(); loadSettings(); }
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    controller.text = prefs.getString('backend_url') ?? '';
    if (mounted) setState(() => isLoading = false);
  }
  String normalizedUrl() {
    var value = controller.text.trim();
    while (value.endsWith('/')) { value = value.substring(0, value.length - 1); }
    return value;
  }
  Future<void> saveSettings() async {
    final value = normalizedUrl();
    if (value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب عنواناً صحيحاً يبدأ بـ http:// أو https://')));
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ عنوان خادم المعالجة.')));
  }
  Future<void> testConnection() async {
    final value = normalizedUrl();
    final uri = Uri.tryParse('$value/health');
    if (value.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب عنوان خادم صحيح أولاً.')));
      return;
    }
    setState(() => isTesting = true);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final available = data['engine_available'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(available ? 'الاتصال ناجح ومحرك FaceFusion متاح.' : 'الاتصال ناجح، لكن محرك FaceFusion غير مثبت على الخادم بعد.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الخادم رد برمز ${response.statusCode}.')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الاتصال بالخادم: $error')));
    } finally {
      if (mounted) setState(() => isTesting = false);
    }
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ListTile(leading: Icon(Icons.person_outline), title: Text('المستخدم الشخصي'), subtitle: Text('تطبيقك الخاص')),
                const Divider(),
                const ListTile(leading: Icon(Icons.language), title: Text('اللغة'), subtitle: Text('العربية')),
                const Divider(),
                const Text('خادم المعالجة المجاني', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('اكتب عنوان جهازك الذي يشغّل Backend المحترف في AI. مثال: http://192.168.1.5:8000 — لا تكتب localhost عند استخدام الهاتف.', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 12),
                TextField(controller: controller, keyboardType: TextInputType.url, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'http://192.168.1.5:8000', border: OutlineInputBorder(), labelText: 'عنوان خادم المعالجة')),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: saveSettings, icon: const Icon(Icons.save), label: const Text('حفظ الإعدادات'))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: isTesting ? null : testConnection, icon: isTesting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering), label: const Text('اختبار الاتصال بالخادم'))),
                const SizedBox(height: 24),
                const Divider(),
                const ListTile(leading: Icon(Icons.info_outline), title: Text('عن التطبيق'), subtitle: Text('المحترف في AI')),
              ],
            ),
    );
  }
}
