import 'package:flutter/material.dart';

void main() {
  runApp(const FaceAIApp());
}

class FaceAIApp extends StatelessWidget {
  const FaceAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'المحترف في AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10111B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<String> titles = [
    'الرئيسية',
    'أعمالي',
    'حسابي',
  ];

  void showFeature(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242538),
        title: Text(title, textAlign: TextAlign.center),
        content: const Text(
          'هذه الأداة قيد التجهيز وسيتم ربطها بمحرك الذكاء الاصطناعي قريباً.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget featureCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => showFeature(title),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF202134),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          const Text(
            'أهلاً بيك في عالم الذكاء الاصطناعي',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'كل أدوات الإبداع في تطبيق واحد',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7038D0),
                  Color(0xFF31256F),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.auto_awesome, size: 38),
                SizedBox(height: 14),
                Text(
                  'المحترف في AI',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'اصنع صورك وفيديوهاتك وأعمالك الصوتية بالذكاء الاصطناعي.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'أدوات الذكاء الاصطناعي',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              featureCard(
                'تبديل الوجوه',
                'تبديل الوجوه في الصور',
                Icons.face_retouching_natural,
                Colors.purpleAccent,
              ),
              featureCard(
                'فيديو AI',
                'تبديل الوجوه بالفيديو',
                Icons.video_camera_back,
                Colors.blueAccent,
              ),
              featureCard(
                'استنساخ الصوت',
                'إنشاء صوت بالذكاء الاصطناعي',
                Icons.record_voice_over,
                Colors.orangeAccent,
              ),
              featureCard(
                'صناعة الأغاني',
                'أنشئ أغنيتك الخاصة',
                Icons.music_note,
                Colors.pinkAccent,
              ),
              featureCard(
                'تحرير الصور',
                'تعديل وتحسين الصور',
                Icons.image,
                Colors.greenAccent,
              ),
              featureCard(
                'أدوات إضافية',
                'اكتشف المزيد من الأدوات',
                Icons.auto_awesome,
                Colors.amberAccent,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF202134),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'حسابك المجاني',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'استمتع بتجربة مجانية لمدة 30 ثانية.',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget otherPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 65, color: Colors.purpleAccent),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم تجهيز هذا القسم قريباً',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homeContent(),
      otherPage('أعمالي', Icons.folder_open),
      otherPage('حسابي', Icons.person),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10111B),
          title: Text(
            titles[selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.auto_awesome, color: Colors.purpleAccent),
          ),
        ),
        body: pages[selectedIndex],
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF202134),
          indicatorColor: Colors.purple.withValues(alpha: 0.3),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
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
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
