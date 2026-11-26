import 'dart:convert';
import 'dart:io';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
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
      'description': 'اختيار صوت رجل أو امرأة أو طفل',
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
      'description': 'تحسين أساسي وتكبير الصور',
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
          builder: (_) => const VideoFaceSwapStudio(),
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
          builder: (_) => AudioStudioPage(mode: type, title: names[type]!),
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
      final apiKey = (prefs.getString('backend_api_key') ?? '').trim();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/faceswap'));
      if (apiKey.isNotEmpty) request.headers['Authorization'] = 'Bearer $apiKey';
      request.files.add(await http.MultipartFile.fromPath('source', sourceFace!.path));
      request.files.add(await http.MultipartFile.fromPath('target', targetImage!.path));
      final streamed = await request.send().timeout(const Duration(minutes: 15));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        var detail = 'الخادم رد برمز ${response.statusCode}.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['detail'] != null) detail = body['detail'].toString();
        } catch (_) {}
        throw Exception(detail);
      }
      if (response.bodyBytes.isEmpty || !response.headers['content-type'].toString().contains('image/')) {
        throw Exception('الخادم لم يُرجع صورة صالحة. راجع سجل الخادم.');
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


class VideoFaceSwapStudio extends StatefulWidget {
  const VideoFaceSwapStudio({super.key});
  @override
  State<VideoFaceSwapStudio> createState() => _VideoFaceSwapStudioState();
}
class _VideoFaceSwapStudioState extends State<VideoFaceSwapStudio> {
  final ImagePicker picker = ImagePicker();
  File? sourceFace, targetVideo, resultVideo;
  VideoPlayerController? player;
  List<Map<String, dynamic>> detectedFaces = [];
  int referenceFrameNumber = 0;
  double referenceTimeSeconds = 0;
  int selectedFaceIndex = 0;
  bool processing = false;
  bool detecting = false;

  Future<String> _baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var base = (prefs.getString('backend_url') ?? '').trim();
    while (base.endsWith('/')) { base = base.substring(0, base.length - 1); }
    if (base.isEmpty) throw Exception('احفظ رابط خادم المعالجة من الإعدادات أولاً.');
    return base;
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final key = (prefs.getString('backend_api_key') ?? '').trim();
    return key.isEmpty ? {} : {'Authorization': 'Bearer $key'};
  }

  Future<void> chooseFace() async {
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file != null && mounted) setState(() => sourceFace = File(file.path));
  }

  Future<void> chooseVideo() async {
    final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (file == null) return;
    final selected = File(file.path);
    if (await selected.length() > 100 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حجم الفيديو أكبر من 100 ميجابايت.')));
      return;
    }
    if (mounted) {
      setState(() {
        targetVideo = selected;
        detectedFaces = [];
        selectedFaceIndex = 0;
        referenceFrameNumber = 0;
        referenceTimeSeconds = 0;
        resultVideo = null;
      });
    }
  }

  Future<void> detectFaces() async {
    if (targetVideo == null || detecting || processing) return;
    setState(() => detecting = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${await _baseUrl()}/api/video-faces'));
      request.headers.addAll(await _headers());
      request.files.add(await http.MultipartFile.fromPath('target_video', targetVideo!.path));
      final streamed = await request.send().timeout(const Duration(minutes: 15));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        var detail = 'الخادم رد برمز ${response.statusCode}.';
        try { final body = jsonDecode(response.body); if (body is Map && body['detail'] != null) detail = body['detail'].toString(); } catch (_) {}
        throw Exception(detail);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final faces = (body['faces'] as List? ?? []).cast<Map<String, dynamic>>();
      if (faces.isEmpty) throw Exception('لم يتم العثور على وجوه في الفيديو.');
      if (!mounted) return;
      setState(() {
        detectedFaces = faces;
        referenceFrameNumber = (body['reference_frame_number'] as num?)?.toInt() ?? 0;
        referenceTimeSeconds = (body['reference_time_seconds'] as num?)?.toDouble() ?? 0;
        selectedFaceIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اكتشاف ${faces.length} وجه في لقطة من الفيديو. اختار الشخص المطلوب.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر اكتشاف الوجوه: $e')));
    } finally {
      if (mounted) setState(() => detecting = false);
    }
  }

  Future<void> processVideo() async {
    if (sourceFace == null || targetVideo == null || detectedFaces.isEmpty || processing) return;
    setState(() => processing = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${await _baseUrl()}/api/faceswap-video'));
      request.headers.addAll(await _headers());
      request.fields['reference_frame_number'] = referenceFrameNumber.toString();
      request.fields['reference_face_position'] = selectedFaceIndex.toString();
      request.files.add(await http.MultipartFile.fromPath('source', sourceFace!.path));
      request.files.add(await http.MultipartFile.fromPath('target_video', targetVideo!.path));
      final streamed = await request.send().timeout(const Duration(minutes: 65));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200 || !response.headers['content-type'].toString().contains('video/')) {
        var detail = 'الخادم رد برمز ${response.statusCode}.';
        try { final body = jsonDecode(response.body); if (body is Map && body['detail'] != null) detail = body['detail'].toString(); } catch (_) {}
        throw Exception(detail);
      }
      final dir = await getApplicationDocumentsDirectory();
      final output = File('${dir.path}/faceswap_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await output.writeAsBytes(response.bodyBytes, flush: true);
      await player?.dispose();
      player = VideoPlayerController.file(output);
      await player!.initialize();
      if (!mounted) return;
      setState(() => resultVideo = output);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز الفيديو وحفظه داخل أعمالي.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذرت معالجة الفيديو: $e')));
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  void dispose() { player?.dispose(); super.dispose(); }

  Widget selectionCard(String title, String subtitle, IconData icon, VoidCallback action, {String? filename}) {
    return Card(child: ListTile(
      leading: Icon(icon, color: const Color(0xFF9B7BFA), size: 32),
      title: Text(title), subtitle: Text(filename ?? subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.upload_file), onTap: action,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تبديل الوجوه بالفيديو')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('اختار صورة الوجه البديل والفيديو اللي عايز تبدّل فيه وجه شخص محدد.', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        selectionCard('صورة الوجه البديل', 'اختار صورة واضحة للوجه', Icons.face, chooseFace, filename: sourceFace?.path.split('/').last),
        selectionCard('الفيديو المستهدف', 'MP4 أو MOV • من ثانية إلى 60 ثانية • حتى 100MB', Icons.video_file, chooseVideo, filename: targetVideo?.path.split('/').last),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: targetVideo != null && !detecting && !processing ? detectFaces : null,
          icon: detecting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.face_retouching_natural),
          label: Text(detecting ? 'جاري اكتشاف الوجوه...' : 'اكتشاف الوجوه في الفيديو'),
        ),
        if (detectedFaces.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('اختار الشخص اللي عايز تبدّل وجهه • لقطة مرجعية عند الثانية ${referenceTimeSeconds.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detectedFaces.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82),
            itemBuilder: (context, index) {
              final selected = selectedFaceIndex == index;
              final bytes = base64Decode(detectedFaces[index]['image'] as String);
              return InkWell(
                onTap: () => setState(() => selectedFaceIndex = index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? const Color(0xFF9B7BFA) : Colors.white24, width: selected ? 3 : 1),
                    color: const Color(0xFF1B1E2E),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity))),
                    const SizedBox(height: 5),
                    Text(selected ? '✓ الشخص المحدد' : 'الشخص ${index + 1}', style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: sourceFace != null && targetVideo != null && detectedFaces.isNotEmpty && !processing ? processVideo : null,
          icon: processing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
          label: Text(processing ? 'جاري معالجة الفيديو...' : 'ابدأ تبديل وجه الشخص المحدد'),
        ),
        if (processing) const Padding(padding: EdgeInsets.all(16), child: Text('قد تستغرق المعالجة وقتًا حسب طول الفيديو وقدرة السيرفر.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60))),
        if (resultVideo != null && player != null) ...[
          const SizedBox(height: 24), const Text('النتيجة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 10),
          AspectRatio(aspectRatio: player!.value.aspectRatio, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: VideoPlayer(player!))),
          VideoProgressIndicator(player!, allowScrubbing: true),
          IconButton(onPressed: () => setState(() => player!.value.isPlaying ? player!.pause() : player!.play()), icon: Icon(player!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, size: 42)),
        ],
      ]),
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
      final apiKey = (prefs.getString('backend_api_key') ?? '').trim();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/enhance'));
      if (apiKey.isNotEmpty) request.headers['Authorization'] = 'Bearer $apiKey';
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
            if (widget.enhance)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'المعالجة الحالية تضبط الألوان والحدة وتكبّر الصورة حتى 2x. تحسين أساسي، وليست بعدُ تقنية ترميم بالذكاء الاصطناعي.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
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

// استوديوهات الصوت والأغاني. التوليد الفعلي ينتظر محرك المعالجة.
class AudioStudioPage extends StatefulWidget {
  final String mode; final String title;
  const AudioStudioPage({super.key, required this.mode, required this.title});
  @override State<AudioStudioPage> createState() => _AudioStudioPageState();
}
class _AudioStudioPageState extends State<AudioStudioPage> {
  final name = TextEditingController(); final lyrics = TextEditingController(); final prompt = TextEditingController();
  PlatformFile? audio; String language = 'مصري'; String genre = 'بوب'; String mood = 'رومانسي'; String voiceType = 'رجل'; bool consent = false; bool instrumental = false; bool isProcessing = false; File? changedVoice;
  bool get clone => widget.mode == 'voice'; bool get change => widget.mode == 'changevoice';
  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, withData: true, allowedExtensions: ['wav','mp3','m4a','aac','ogg','flac']);
    if (result != null && result.files.isNotEmpty && mounted) setState(() => audio = result.files.single);
  }
  Future<void> prepare() async {
    if (clone && (name.text.trim().isEmpty || audio == null || !consent)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم النموذج وارفع عينة وأكد امتلاكك موافقة صاحب الصوت.'))); return; }
    if (change && audio == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختار الملف الصوتي أولاً.'))); return; }
    if (change) { await convertVoice(); return; }
    if (!clone && prompt.text.trim().isEmpty && lyrics.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب وصف الأغنية أو كلماتها.'))); return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محرك استنساخ الصوت وتوليد الأغاني لم يُربط بعد. لم يتم إنشاء نتيجة وهمية.')));
  }
  Future<void> convertVoice() async {
    if (audio == null || isProcessing) return;
    setState(() => isProcessing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      var baseUrl = (prefs.getString('backend_url') ?? '').trim();
      while (baseUrl.endsWith('/')) { baseUrl = baseUrl.substring(0, baseUrl.length - 1); }
      if (baseUrl.isEmpty) throw Exception('احفظ عنوان خادم المعالجة من الإعدادات أولاً.');
      final bytes = audio!.bytes;
      if (bytes == null || bytes.isEmpty) throw Exception('تعذر قراءة الملف الصوتي؛ أعد اختياره.');
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/change-voice'));
      final apiKey = (prefs.getString('backend_api_key') ?? '').trim();
      if (apiKey.isNotEmpty) request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['voice_type'] = voiceType;
      request.files.add(http.MultipartFile.fromBytes('audio', bytes, filename: audio!.name));
      final streamed = await request.send().timeout(const Duration(minutes: 6));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        String message = 'الخادم رد برمز ${response.statusCode}.';
        try { message = (jsonDecode(response.body) as Map)['detail']?.toString() ?? message; } catch (_) {}
        throw Exception(message);
      }
      final directory = await getApplicationDocumentsDirectory();
      final output = File('${directory.path}/changed_voice_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await output.writeAsBytes(response.bodyBytes, flush: true);
      if (!mounted) return;
      setState(() => changedVoice = output);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل الصوت وحفظ ملف MP3 داخل أعمالي.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحويل الصوت: $error')));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }
  @override void dispose() { name.dispose(); lyrics.dispose(); prompt.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(clone ? 'أنشئ نموذجًا لصوت تملك حق استخدامه، ثم جهّز نصًا ليقرأه.' : change ? 'ارفع التسجيل واختار فئة الصوت الجديدة: رجل أو امرأة أو طفل.' : 'اكتب وصف الأغنية أو كلماتها وحدد اللون الموسيقي.'))),
      const SizedBox(height: 16),
      if (clone) ...[
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم نموذج الصوت', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        _audioTile(),
        CheckboxListTile(value: consent, onChanged: (v) => setState(() => consent = v ?? false), title: const Text('أؤكد أن لدي موافقة صاحب الصوت أو أن الصوت صوتي.'), subtitle: const Text('لا تستخدم تسجيلات أشخاص دون إذنهم.'), controlAffinity: ListTileControlAffinity.leading),
        TextField(controller: lyrics, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'النص الذي تريد أن يقرأه الصوت', border: OutlineInputBorder())),
      ] else if (change) ...[
        _audioTile(), const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: voiceType, decoration: const InputDecoration(labelText: 'نوع الصوت البديل', border: OutlineInputBorder()), items: const ['رجل','امرأة','طفل'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => voiceType = v ?? voiceType)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: language, decoration: const InputDecoration(labelText: 'اللهجة (اختياري)', border: OutlineInputBorder()), items: const ['مصري','خليجي','فصحى','إنجليزي أمريكي','إنجليزي بريطاني'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => language = v ?? language)),

      ] else ...[
        TextField(controller: prompt, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'وصف الأغنية', hintText: 'أغنية رومانسية مصرية بإيقاع هادئ...', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: lyrics, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'كلمات الأغنية (اختياري)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: genre, decoration: const InputDecoration(labelText: 'اللون الموسيقي', border: OutlineInputBorder()), items: const ['بوب','رومانسي','شعبي','مهرجانات','روك','طربي','إنشاد','موسيقى سينمائية'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => genre = v ?? genre)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: mood, decoration: const InputDecoration(labelText: 'الإحساس والحالة العاطفية', border: OutlineInputBorder()), items: const ['حزين','شجن','عتاب','ألم','صحوة بعد الوجع','رومانسي','فرح','حماس','أمل'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => mood = v ?? mood)),

        SwitchListTile(value: instrumental, onChanged: (v) => setState(() => instrumental = v), title: const Text('موسيقى فقط بدون غناء')),
      ],
      const SizedBox(height: 20), FilledButton.icon(onPressed: isProcessing ? null : prepare, icon: isProcessing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow), label: Text(isProcessing ? 'جارٍ تحويل الصوت...' : clone ? 'تجهيز نموذج الصوت' : change ? 'تحويل الصوت وحفظ MP3' : 'تجهيز الأغنية')),
      if (change) const Padding(padding: EdgeInsets.only(top: 10), child: Text('تحويل محلي بتأثيرات طبقة الصوت عبر FFmpeg؛ ليس استنساخاً لهوية صوت شخص.', textAlign: TextAlign.center)),
      if (changedVoice != null) Card(child: ListTile(leading: const Icon(Icons.audio_file), title: const Text('تم حفظ الصوت المحوّل'), subtitle: Text(changedVoice!.path), trailing: const Icon(Icons.check_circle))),
      if (!change) const SizedBox(height: 12), if (!change) const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('محرك استنساخ الصوت وتوليد الأغاني لم يُربط بعد؛ لن يتم عرض نتائج وهمية.'))),
    ]));
  }
  Widget _audioTile() => Card(child: ListTile(leading: const Icon(Icons.audio_file), title: Text(audio?.name ?? 'اختيار ملف صوتي'), subtitle: const Text('WAV / MP3 / M4A / AAC / OGG / FLAC'), trailing: const Icon(Icons.upload_file), onTap: pickAudio));
}
// صفحة أعمالي: تعرض النتائج المحفوظة محلياً على الهاتف

class MyWorksPage extends StatefulWidget {
  const MyWorksPage({super.key});

  @override
  State<MyWorksPage> createState() => _MyWorksPageState();
}

class _MyWorksPageState extends State<MyWorksPage> {
  List<File> works = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWorks();
  }

  Future<void> loadWorks() async {
    setState(() => isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final entries = await directory.list().toList();
      final found = entries
          .whereType<File>()
          .where((file) {
            final name = file.uri.pathSegments.last;
            return name.startsWith('faceswap_') ||
                name.startsWith('enhanced_') ||
                name.startsWith('faceswap_video_') ||
                name.startsWith('changed_voice_');
          })
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (mounted) setState(() => works = found);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الأعمال المحفوظة.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String titleFor(File file) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('faceswap_video_')) return 'فيديو بعد تبديل الوجه';
    if (name.startsWith('changed_voice_')) return 'صوت بعد تغيير الطبقة';
    return name.startsWith('faceswap_') ? 'نتيجة تبديل وجه' : 'صورة محسّنة';
  }

  Future<void> deleteWork(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العمل'),
        content: const Text('هل تريد حذف هذه النتيجة من الهاتف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await file.delete();
    await loadWorks();
  }

  void previewWork(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titleFor(file), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Flexible(
                child: file.path.endsWith('.mp4')
                    ? _SavedVideoPreview(file: file)
                    : InteractiveViewer(child: Image.file(file, fit: BoxFit.contain)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
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
        title: const Text('أعمالي'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadWorks,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الأعمال',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : works.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 65, color: Colors.white54),
                      const SizedBox(height: 15),
                      const Text('لسه مفيش أعمال محفوظة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('نتائج تبديل الوجوه وتحسين الصور هتظهر هنا.', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: loadWorks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('تحديث'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadWorks,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: works.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final file = works[index];
                      return InkWell(
                        onTap: () => previewWork(file),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1E2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Expanded(
                                child: file.path.toLowerCase().endsWith('.mp4') ? Container(width: double.infinity, color: const Color(0xFF111321), child: const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Color(0xFF9B7BFA)))) : Image.file(file, width: double.infinity, fit: BoxFit.cover),
                              ),
                              ListTile(
                                dense: true,
                                title: Text(titleFor(file), style: const TextStyle(fontSize: 12)),
                                trailing: IconButton(
                                  onPressed: () => deleteWork(file),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'حذف',
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


class _SavedVideoPreview extends StatefulWidget {
  final File file;
  const _SavedVideoPreview({required this.file});
  @override
  State<_SavedVideoPreview> createState() => _SavedVideoPreviewState();
}
class _SavedVideoPreviewState extends State<_SavedVideoPreview> {
  late final VideoPlayerController controller;
  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) { if (mounted) setState(() {}); });
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
      IconButton(
        onPressed: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
        icon: Icon(controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle, size: 42),
      ),
    ]);
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
  final TextEditingController apiKeyController = TextEditingController();
  bool isLoading = true;
  bool isTesting = false;
  bool isLoadingPool = false;
  Map<String, dynamic>? poolStatus;
  @override
  void initState() { super.initState(); loadSettings(); }
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    controller.text = prefs.getString('backend_url') ?? '';
    apiKeyController.text = prefs.getString('backend_api_key') ?? '';
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
    await prefs.setString('backend_api_key', apiKeyController.text.trim());
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
        final poolConfigured = data['worker_pool_configured'] == true;
        final engineAvailable = data['engine_available'] == true;
        final message = poolConfigured
            ? 'الاتصال بمدير المعالجة ناجح ومجموعة العمال مُعرّفة.'
            : engineAvailable
                ? 'الاتصال ناجح ومحرك FaceFusion المحلي متاح.'
                : 'الاتصال ناجح، لكن لا توجد مجموعة عمال أو محرك محلي جاهز بعد.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الخادم رد برمز ${response.statusCode}.')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الاتصال بالخادم. تأكد أن الرابط صحيح وأن الخادم يعمل ويمكن الوصول إليه. التفاصيل: $error')));
    } finally {
      if (mounted) setState(() => isTesting = false);
    }
  }
  Future<void> refreshPoolStatus() async {
    final value = normalizedUrl();
    final uri = Uri.tryParse('$value/pool/status');
    if (value.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('احفظ رابط المدير أولاً.')));
      return;
    }
    setState(() => isLoadingPool = true);
    try {
      final key = apiKeyController.text.trim();
      final headers = key.isEmpty ? <String, String>{} : <String, String>{'Authorization': 'Bearer $key'};
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => poolStatus = data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر قراءة حالة السيرفرات: ${response.statusCode}')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر قراءة مجموعة السيرفرات: $error')));
    } finally {
      if (mounted) setState(() => isLoadingPool = false);
    }
  }
  @override
  void dispose() { controller.dispose(); apiKeyController.dispose(); super.dispose(); }
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
                const Text('مدير المعالجة ومجموعة السيرفرات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('أدخل رابط خادم المدير بعد نشره. المدير يوزّع طلبات تبديل الوجوه على العمال المتاحين. احفظ مفتاح المدير إذا كان مفعّلاً. عند استخدام الهاتف لا تكتب localhost؛ أدخل رابط HTTPS الفعلي أو عنوان جهازك على نفس شبكة Wi‑Fi.', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 12),
                TextField(controller: controller, keyboardType: TextInputType.url, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'http://192.168.1.5:8000', border: OutlineInputBorder(), labelText: 'رابط مدير المعالجة')),
                const SizedBox(height: 12),
                TextField(controller: apiKeyController, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'مفتاح الوصول (اختياري إذا فعّله الخادم)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: saveSettings, icon: const Icon(Icons.save), label: const Text('حفظ الإعدادات'))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: isTesting ? null : testConnection, icon: isTesting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering), label: const Text('اختبار الاتصال بالخادم'))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: isLoadingPool ? null : refreshPoolStatus, icon: isLoadingPool ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.hub_outlined), label: const Text('عرض حالة مجموعة السيرفرات'))),
                if (poolStatus != null) ...[
                  const SizedBox(height: 12),
                  Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('السيرفرات المسجلة: ${poolStatus!['configured'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...((poolStatus!['workers'] as List<dynamic>? ?? []).map((item) {
                      final worker = item as Map<String, dynamic>;
                      final online = worker['online'] == true;
                      final quota = worker['daily_jobs_limit'];
                      final used = worker['jobs_used_today'] ?? 0;
                      return ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(online ? Icons.check_circle : Icons.error, color: online ? Colors.green : Colors.red), title: Text('${worker['name'] ?? 'Worker'}'), subtitle: Text(online ? 'متصل • استُخدم اليوم $used${quota == null ? '' : ' من $quota'}' : 'غير متصل'));
                    })),
                  ]))),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const ListTile(leading: Icon(Icons.info_outline), title: Text('عن التطبيق'), subtitle: Text('المحترف في AI')),
              ],
            ),
    );
  }
}
