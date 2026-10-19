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
        title: 'Hassani Offline Chat',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        ),
        home: firebaseInitialized ? const AuthGate() : const FirebaseUnavailablePage(),
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
          backgroundColor: const Color(0xFF173B75), foregroundColor: Colors.white,
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            Text('${chats.length} گفتگو', style: const TextStyle(color: Colors.black54)),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: TextField(
            onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'جستجوی گفتگوها', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          )),
          Expanded(child: ListView.builder(itemCount: filteredChats.length, itemBuilder: (context, index) {
            final chat = filteredChats[index];
            return Card(color: Colors.white, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), elevation: 0, child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFE3ECFF), child: Icon(chat.group ? Icons.groups_rounded : Icons.person_rounded, color: const Color(0xFF2457A7))),
              title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(chat.time, style: const TextStyle(fontSize: 11, color: Colors.black45)),
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
      decoration: BoxDecoration(color: message.mine ? const Color(0xFFDCE8FF) : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [content, const SizedBox(height: 3), Text(message.time, style: const TextStyle(fontSize: 10, color: Colors.black54))]),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.chat.name), backgroundColor: const Color(0xFF173B75), foregroundColor: Colors.white,
          bottom: const PreferredSize(preferredSize: Size.fromHeight(20), child: Padding(padding: EdgeInsets.only(bottom: 6), child: Text('آزمایش محلی — هنوز به دستگاه دیگر وصل نیست', style: TextStyle(color: Colors.white70, fontSize: 11))))),
        body: Column(children: [
          Expanded(child: widget.chat.messages.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('پیام متنی بنویس، عکس انتخاب کن یا دکمهٔ میکروفون را برای ضبط صدا بزن. این پیام‌ها فعلاً فقط در همین گوشی ذخیره می‌شوند.', textAlign: TextAlign.center)))
            : ListView.builder(padding: const EdgeInsets.all(12), itemCount: widget.chat.messages.length, itemBuilder: (_, i) => _messageBubble(widget.chat.messages[i]))),
          if (recording) Container(width: double.infinity, color: Colors.red.shade50, padding: const EdgeInsets.all(8), child: const Text('● در حال ضبط صدا — برای پایان، میکروفون را بزن', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 8), child: Row(children: [
            IconButton(tooltip: 'انتخاب عکس', onPressed: _pickImage, icon: const Icon(Icons.image_outlined)),
            IconButton(tooltip: recording ? 'پایان ضبط' : 'ضبط پیام صوتی', onPressed: _toggleRecording, icon: Icon(recording ? Icons.stop_circle : Icons.mic, color: recording ? Colors.red : const Color(0xFF173B75))),
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
