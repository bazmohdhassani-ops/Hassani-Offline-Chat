import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'remote_chat_page.dart';

bool firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    firebaseInitialized = true;
  } catch (_) {
    // Keep the local demo usable when the device is offline or Firebase is unavailable.
  }
  runApp(const HassaniChatApp());
}

class HassaniChatApp extends StatelessWidget {
  const HassaniChatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hassani Chat',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00D6A0), brightness: Brightness.dark, surface: const Color(0xFF07131C)),
          scaffoldBackgroundColor: const Color(0xFF061018),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF061018), foregroundColor: Colors.white, elevation: 0),
          navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF081923), indicatorColor: Color(0xFF123B38), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF00C995), foregroundColor: Color(0xFF001A15)),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Color(0xFF10212B), hintStyle: TextStyle(color: Color(0xFF8A9BA5)), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide.none)),
        ),
        home: const AppShell(),
      );
}


class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const ChatsPage(),
      const CallsPage(),
      const UpdatesPage(),
      const ToolsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'چت‌ها'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'تماس‌ها'),
          NavigationDestination(icon: Icon(Icons.circle_outlined), selectedIcon: Icon(Icons.circle), label: 'وضعیت‌ها'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view), label: 'ابزارها'),
        ],
      ),
    );
  }
}

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تماس‌ها', style: TextStyle(fontSize: 28)), actions: [
      IconButton(onPressed: () => showSearch(context: context, delegate: _SimpleSearchDelegate('جستجوی تماس')), icon: const Icon(Icons.search)),
      IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'Hassani Chat', children: const [Text('تماس‌های واقعی هنوز در این نسخه فعال نیستند.')]), icon: const Icon(Icons.more_vert)),
    ]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Row(children: [
        _CallAction(icon: Icons.call, label: 'تماس', color: const Color(0xFF00C995)),
        _CallAction(icon: Icons.calendar_month, label: 'زمان‌بندی', color: const Color(0xFF159BE8)),
        _CallAction(icon: Icons.dialpad, label: 'صفحه‌کلید', color: const Color(0xFF8C72F6)),
        _CallAction(icon: Icons.favorite_border, label: 'علاقه‌مندی', color: const Color(0xFFE95788)),
      ]),
      const SizedBox(height: 28),
      const Text('تماس‌های اخیر', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const _CallRow(name: 'تماس آزمایشی', detail: 'تاریخچهٔ تماس پس از فعال‌سازی تماس‌ها نمایش داده می‌شود', icon: Icons.person),
      const Divider(color: Color(0xFF1D303A)),
      const ListTile(leading: Icon(Icons.info_outline, color: Color(0xFF00C995)), title: Text('تماس صوتی و تصویری'), subtitle: Text('این بخش فعلاً نمایشی است؛ تماس زنده هنوز پیاده‌سازی نشده است.')),
    ]),
  );
}

class _CallAction extends StatelessWidget {
  const _CallAction({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Container(width: 58, height: 58, decoration: BoxDecoration(color: color.withOpacity(.16), shape: BoxShape.circle), child: Icon(icon, color: color, size: 27)),
    const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFB0BEC5))),
  ]));
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.name, required this.detail, required this.icon});
  final String name, detail;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(backgroundColor: Color(0xFF19313C), child: Icon(Icons.person, color: Color(0xFFB7C9D1))),
    title: Text(name), subtitle: Text(detail, style: const TextStyle(color: Color(0xFF8A9BA5))),
    trailing: Icon(icon, color: const Color(0xFF00C995)),
  );
}

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('وضعیت‌ها', style: TextStyle(fontSize: 28)), actions: [
      IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'Hassani Chat', children: const [Text('انتشار وضعیت واقعی در نسخهٔ آینده اضافه می‌شود.')]), icon: const Icon(Icons.more_vert)),
    ]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('وضعیت من', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      Row(children: [
        Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00D6A0), width: 2)), child: const CircleAvatar(backgroundColor: Color(0xFF152A35), child: Icon(Icons.person, size: 34, color: Color(0xFFB8CAD2)))),
        const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('وضعیت من', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('یک عکس یا متن برای وضعیت انتخاب کن', style: TextStyle(color: Color(0xFF8A9BA5)))])),
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتشار وضعیت هنوز فعال نشده است.'))), icon: const Icon(Icons.add_circle, color: Color(0xFF00D6A0), size: 30)),
      ]),
      const SizedBox(height: 28),
      const Text('کانال‌ها و خبرها', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _UpdateTile(icon: Icons.public, title: 'جامعهٔ حسنی', subtitle: 'کانال‌ها و به‌روزرسانی‌ها در نسخه‌های بعدی'),
      _UpdateTile(icon: Icons.groups_rounded, title: 'گروه‌های دوستان', subtitle: 'فضایی برای خبرها و گفتگوهای گروهی'),
      const SizedBox(height: 12),
      const Text('یادداشت: وضعیت و کانال آنلاین هنوز به سرور وصل نشده است.', style: TextStyle(color: Color(0xFF8A9BA5))),
    ]),
  );
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF0D202B), child: ListTile(
    leading: CircleAvatar(backgroundColor: const Color(0xFF123B38), child: Icon(icon, color: const Color(0xFF00D6A0))),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8A9BA5))),
  ));
}

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ابزارها', style: TextStyle(fontSize: 28)), actions: [
      IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'Hassani Chat', children: const [Text('نسخهٔ آزمایشی Hassani Chat')]), icon: const Icon(Icons.more_vert)),
    ]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('حساب من', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(color: const Color(0xFF0D202B), child: const ListTile(
        leading: CircleAvatar(backgroundColor: Color(0xFF123B38), child: Icon(Icons.person, color: Color(0xFF00D6A0))),
        title: Text('Hassani Chat'), subtitle: Text('پیام‌رسان شخصی و مستقل'),
      )),
      const SizedBox(height: 24),
      const Text('مدیریت', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _ToolTile(icon: Icons.chat_bubble_outline, title: 'گفتگوهای محلی', subtitle: 'ساخت گفتگو و آزمایش پیام در همین گوشی'),
      _ToolTile(icon: Icons.cloud_outlined, title: 'وضعیت اتصال', subtitle: firebaseInitialized ? 'Firebase بارگذاری شده' : 'Firebase در دسترس نیست'),
      _ToolTile(icon: Icons.lock_outline, title: 'حریم خصوصی', subtitle: 'تنظیمات امنیتی پیشرفته هنوز تکمیل نشده'),
      _ToolTile(icon: Icons.settings_outlined, title: 'تنظیمات', subtitle: 'اطلاعات و وضعیت قابلیت‌های برنامه'),
      const SizedBox(height: 12),
      const Text('قابلیت‌هایی که هنوز نیاز به توسعه دارند: چت خصوصی، تماس زنده، وضعیت آنلاین و ارتباط مستقیم آفلاین بین گوشی‌ها.', style: TextStyle(color: Color(0xFF8A9BA5))),
    ]),
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF0D202B), child: ListTile(
    leading: Icon(icon, color: const Color(0xFF00D6A0)), title: Text(title), subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8A9BA5))),
  ));
}

class _SimpleSearchDelegate extends SearchDelegate<String> {
  _SimpleSearchDelegate(String hint) : super(searchFieldLabel: hint);
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) => Center(child: Text('نتیجه‌ای برای «$query» ثبت نشده است.'));
  @override
  Widget buildSuggestions(BuildContext context) => const Center(child: Text('نام تماس را جستجو کن.'));
}

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تنظیمات و وضعیت')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const ListTile(leading: Icon(Icons.chat_bubble_outline, color: Color(0xFF00D6A0)), title: Text('چت محلی'), subtitle: Text('پیام‌های آزمایشی فعلاً فقط در همین گوشی هستند.')),
      ListTile(leading: Icon(firebaseInitialized ? Icons.cloud_done : Icons.cloud_off, color: const Color(0xFF00D6A0)), title: const Text('اتصال آنلاین'), subtitle: Text(firebaseInitialized ? 'Firebase بارگذاری شده است.' : 'Firebase وصل نیست.')),
      const Divider(),
      const ListTile(leading: Icon(Icons.info_outline, color: Color(0xFF00D6A0)), title: Text('قابلیت‌های تکمیل‌نشده'), subtitle: Text('تماس واقعی، چت خصوصی و اتصال مستقیم آفلاین بین گوشی‌ها هنوز ساخته نشده‌اند.')),
    ]),
  );
}

class Chat {
  Chat(this.name, this.lastMessage, this.time, {this.group = false});
  final String name;
  String lastMessage;
  String time;
  final bool group;
  final List<ChatMessage> messages = [];
}

enum MessageKind { text, image, audio }

class ChatMessage {
  ChatMessage(this.kind, this.content, {this.mine = true}) : time = TimeOfDay.now().formatShort();
  final MessageKind kind;
  final String content; // text or local file path
  final bool mine;
  final String time;
}

extension on TimeOfDay {
  String formatShort() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String query = '';
  final List<Chat> chats = [
    Chat('گفتگوی آزمایشی', 'به Hassani Offline Chat خوش آمدی', 'اکنون'),
    Chat('گروه دوستان', 'گروه نمونه برای آزمایش', 'دیروز', group: true),
    Chat('همکاران شفاخانه', 'گفتگوی محلی آزمایشی', 'دیروز', group: true),
  ];

  Future<void> _newChat() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گفتگوی تازه'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'نام مخاطب یا گروه')),
          const SizedBox(height: 8),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شمارهٔ تلفن (اختیاری)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, nameController.text.trim()), child: const Text('ایجاد')),
        ],
      ),
    );
    phoneController.dispose();
    nameController.dispose();
    if (name != null && name.isNotEmpty && mounted) {
      final chat = Chat(name, 'گفتگو ایجاد شد؛ هنوز متصل نیست', 'اکنون');
      setState(() => chats.insert(0, chat));
      _openChat(chat);
    }
  }

  void _openChat(Chat chat) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(chat: chat))).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = chats.where((chat) =>
      chat.name.toLowerCase().contains(query) ||
      chat.lastMessage.toLowerCase().contains(query)
    ).toList();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF061018), foregroundColor: Colors.white,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hassani Offline Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(firebaseInitialized ? 'Firebase آماده شد؛ پیام‌رسانی آنلاین هنوز فعال نشده' : 'نسخهٔ آزمایشی محلی', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
          actions: [IconButton(tooltip: 'وضعیت اتصال', onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('وضعیت اتصال'),
            content: Text(firebaseInitialized ? 'تنظیمات Firebase بارگذاری شد؛ ارسال و دریافت پیام هنوز پیاده‌سازی نشده است.' : 'Firebase راه‌اندازی نشد. این نسخه هنوز به گوشی‌های دیگر متصل نیست و پیام‌ها فقط در همین گوشی آزمایش می‌شوند.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('فهمیدم'))],
          )), icon: const Icon(Icons.device_hub_rounded))],
        ),
        body: Column(children: [
          Container(
            margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF173B75), Color(0xFF3976D9)]), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.forum_rounded, color: Colors.white)),
              SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('سلام، خوش آمدی!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4), Text('گفتگوهای خود را مدیریت کن.', style: TextStyle(color: Colors.white70)),
              ])),
            ]),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            const Expanded(child: Text('گفتگوها', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Text('${chats.length} گفتگو', style: const TextStyle(color: Color(0xFF8A9BA5))),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: TextField(
            onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجوی گفتگوها', filled: true, fillColor: const Color(0xFF10212B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          )),
          Expanded(child: ListView.builder(itemCount: filteredChats.length, itemBuilder: (context, index) {
            final chat = filteredChats[index];
            return Card(color: const Color(0xFF0D202B), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), elevation: 0, child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFF17343D), child: Icon(chat.group ? Icons.groups_rounded : Icons.person_rounded, color: const Color(0xFF00D6A0))),
              title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(chat.time, style: const TextStyle(fontSize: 11, color: Color(0xFF8A9BA5))),
              onTap: () => _openChat(chat),
            ));
          })),
        ]),
        floatingActionButton: FloatingActionButton.extended(onPressed: _newChat, icon: const Icon(Icons.add_comment_rounded), label: const Text('گفتگوی تازه')),
      );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chat});
  final Chat chat;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final picker = ImagePicker();
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  bool recording = false;
  bool playing = false;

  void _addMessage(ChatMessage message, String preview) {
    setState(() {
      widget.chat.messages.add(message);
      widget.chat.lastMessage = preview;
      widget.chat.time = message.time;
    });
  }

  void _sendText() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    _addMessage(ChatMessage(MessageKind.text, text), text);
    controller.clear();
  }

  Future<void> _pickImage() async {
    try {
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
      if (image != null) _addMessage(ChatMessage(MessageKind.image, image.path), '📷 عکس');
    } catch (e) { _notice('انتخاب عکس موفق نشد: $e'); }
  }

  Future<void> _toggleRecording() async {
    if (recording) {
      final path = await recorder.stop();
      if (!mounted) return;
      setState(() => recording = false);
      if (path != null) _addMessage(ChatMessage(MessageKind.audio, path), '🎤 پیام صوتی');
      return;
    }
    try {
      if (!await recorder.hasPermission()) { _notice('اجازهٔ استفاده از میکروفون داده نشد.'); return; }
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() => recording = true);
    } catch (e) { _notice('ضبط صدا شروع نشد: $e'); }
  }

  Future<void> _playAudio(String path) async {
    try {
      if (playing) { await player.stop(); setState(() => playing = false); }
      else {
        setState(() => playing = true);
        player.onPlayerComplete.first.then((_) { if (mounted) setState(() => playing = false); });
        await player.play(DeviceFileSource(path));
      }
    } catch (e) { if (mounted) setState(() => playing = false); _notice('پخش صدا موفق نشد: $e'); }
  }

  void _notice(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  @override
  void dispose() {
    controller.dispose();
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  Widget _messageBubble(ChatMessage message) {
    Widget content;
    switch (message.kind) {
      case MessageKind.text:
        content = Text(message.content, style: const TextStyle(fontSize: 16));
        break;
      case MessageKind.image:
        content = ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(message.content), width: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('عکس در دسترس نیست')));
        break;
      case MessageKind.audio:
        content = Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _playAudio(message.content), icon: Icon(playing ? Icons.stop_circle : Icons.play_circle_fill, size: 34)),
          const Flexible(child: Text('پیام صوتی')),
          const Icon(Icons.graphic_eq),
        ]);
        break;
    }
    return Align(alignment: message.mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart, child: Container(
      constraints: const BoxConstraints(maxWidth: 290), margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: message.mine ? const Color(0xFF123B38) : const Color(0xFF10212B), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [content, const SizedBox(height: 3), Text(message.time, style: const TextStyle(fontSize: 10, color: Colors.black54))]),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.chat.name), backgroundColor: const Color(0xFF061018), foregroundColor: Colors.white,
          bottom: const PreferredSize(preferredSize: Size.fromHeight(20), child: Padding(padding: EdgeInsets.only(bottom: 6), child: Text('آزمایش محلی — هنوز به دستگاه دیگر وصل نیست', style: TextStyle(color: Colors.white70, fontSize: 11))))),
        body: Column(children: [
          Expanded(child: widget.chat.messages.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('پیام متنی بنویس، عکس انتخاب کن یا دکمهٔ میکروفون را برای ضبط صدا بزن. این پیام‌ها فعلاً فقط در همین گوشی ذخیره می‌شوند.', textAlign: TextAlign.center)))
            : ListView.builder(padding: const EdgeInsets.all(12), itemCount: widget.chat.messages.length, itemBuilder: (_, i) => _messageBubble(widget.chat.messages[i]))),
          if (recording) Container(width: double.infinity, color: Colors.red.shade50, padding: const EdgeInsets.all(8), child: const Text('● در حال ضبط صدا — برای پایان، میکروفون را بزن', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 8), child: Row(children: [
            IconButton(tooltip: 'انتخاب عکس', onPressed: _pickImage, icon: const Icon(Icons.image_outlined)),
            IconButton(tooltip: recording ? 'پایان ضبط' : 'ضبط پیام صوتی', onPressed: _toggleRecording, icon: Icon(recording ? Icons.stop_circle : Icons.mic, color: recording ? Colors.red : const Color(0xFF00C995))),
            Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendText(), decoration: InputDecoration(hintText: 'پیامت را بنویس...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
            const SizedBox(width: 5), IconButton.filled(onPressed: _sendText, icon: const Icon(Icons.send_rounded)),
          ]))),
        ]),
      );
}


class FirebaseUnavailablePage extends StatelessWidget {
  const FirebaseUnavailablePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, size: 64, color: Colors.blueGrey),
        const SizedBox(height: 16),
        const Text('اتصال به Firebase برقرار نشد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('انترنت را بررسی کن و برنامه را دوباره باز کن. نسخهٔ محلی قبلی هنوز در کُد موجود است.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => main(), child: const Text('تلاش دوباره')),
      ],
    ))),
  );
}
