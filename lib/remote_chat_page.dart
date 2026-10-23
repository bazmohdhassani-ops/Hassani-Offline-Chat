import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const RemoteChatPage();
        return const AuthPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  String? error;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'ایمیل را بنویس و رمز عبور حداقل ۶ حرف داشته باشد.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      if (registering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = switch (e.code) {
        'email-already-in-use' => 'این ایمیل قبلاً ثبت شده است؛ وارد شو.',
        'invalid-email' => 'ایمیل درست نیست.',
        'weak-password' => 'رمز عبور قوی‌تر انتخاب کن.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'ایمیل یا رمز عبور نادرست است.',
        'network-request-failed' => 'اتصال انترنت را بررسی کن.',
        'operation-not-allowed' => 'ورود ایمیلی هنوز در Firebase فعال نشده است.',
        _ => 'ورود موفق نشد: ${e.message ?? e.code}',
      });
    } catch (e) {
      setState(() => error = 'خطا: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.forum_rounded, size: 72, color: Color(0xFF173B75)),
          const SizedBox(height: 12),
          const Text('Lets Talk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(registering ? 'ساخت حساب جدید' : 'ورود به حساب', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'رمز عبور (حداقل ۶ حرف)', border: OutlineInputBorder())),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: busy ? null : submit,
            child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(registering ? 'ثبت‌نام' : 'ورود'),
          )),
          TextButton(onPressed: busy ? null : () => setState(() { registering = !registering; error = null; }),
            child: Text(registering ? 'حساب داری؟ وارد شو' : 'حساب نداری؟ ثبت‌نام کن')),
          const SizedBox(height: 8),
          const Text('برای آزمایش آنلاین، هر گوشی باید با حساب خودش وارد شود.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ],
      )),
    )),
  );
}

class RemoteChatPage extends StatefulWidget {
  const RemoteChatPage({super.key});
  @override
  State<RemoteChatPage> createState() => _RemoteChatPageState();
}

class _RemoteChatPageState extends State<RemoteChatPage> {
  final controller = TextEditingController();
  final picker = ImagePicker();
  final recorder = AudioRecorder();
  final audioPlayer = AudioPlayer();
  bool recording = false;
  bool sending = false;
  String? sendError;
  CollectionReference<Map<String, dynamic>> get messages =>
    FirebaseFirestore.instance.collection('rooms').doc('general').collection('messages');

  Future<void> send() async {
    final text = controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || sending) return;
    setState(() { sending = true; sendError = null; });
    try {
      await messages.add({
        'senderUid': user.uid,
        'senderEmail': user.email ?? 'کاربر',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'kind': 'text',
      });
      controller.clear();
    } on FirebaseException catch (e) {
      setState(() => sendError = e.code == 'permission-denied'
        ? 'دسترسی دیتابیس تنظیم نشده؛ Rules فایربیس باید نشر شود.'
        : 'ارسال نشد: ${e.message ?? e.code}');
    } catch (e) {
      setState(() => sendError = 'ارسال نشد: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> sendFile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sending) return;
    try {
      final picked = await FilePicker.platform.pickFiles(withData: false);
      if (picked == null || picked.files.single.path == null || !mounted) return;
      setState(() { sending = true; sendError = null; });
      final selected = picked.files.single;
      final safeName = selected.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = FirebaseStorage.instance.ref('rooms/general/${user.uid}/files/${DateTime.now().millisecondsSinceEpoch}_$safeName');
      final type = selected.extension?.toLowerCase() == 'pdf' ? 'application/pdf' : 'application/octet-stream';
      final task = await ref.putFile(File(selected.path!), SettableMetadata(contentType: type));
      final url = await task.ref.getDownloadURL();
      await messages.add({
        'senderUid': user.uid, 'senderEmail': user.email ?? 'کاربر',
        'text': selected.name, 'mediaUrl': url, 'fileName': selected.name,
        'createdAt': FieldValue.serverTimestamp(), 'kind': 'file',
      });
    } on FirebaseException catch (e) {
      if (mounted) setState(() => sendError = 'ارسال فایل نشد: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => sendError = 'ارسال فایل نشد: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> toggleRecording() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sending) return;
    if (recording) {
      try {
        final path = await recorder.stop();
        if (mounted) setState(() => recording = false);
        if (path == null) return;
        setState(() { sending = true; sendError = null; });
        final name = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final ref = FirebaseStorage.instance.ref('rooms/general/${user.uid}/$name');
        final task = await ref.putFile(File(path), SettableMetadata(contentType: 'audio/mp4'));
        final url = await task.ref.getDownloadURL();
        await messages.add({
          'senderUid': user.uid, 'senderEmail': user.email ?? 'کاربر',
          'text': 'پیام صوتی', 'mediaUrl': url, 'fileName': name,
          'createdAt': FieldValue.serverTimestamp(), 'kind': 'audio',
        });
      } on FirebaseException catch (e) {
        if (mounted) setState(() => sendError = 'ارسال پیام صوتی نشد: ${e.message ?? e.code}');
      } catch (e) {
        if (mounted) setState(() => sendError = 'پیام صوتی ارسال نشد: $e');
      } finally {
        if (mounted) setState(() { sending = false; recording = false; });
      }
      return;
    }
    try {
      if (!await recorder.hasPermission()) {
        setState(() => sendError = 'اجازهٔ میکروفون داده نشده است.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/hassani_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() { recording = true; sendError = null; });
    } catch (e) {
      if (mounted) setState(() => sendError = 'ضبط صدا شروع نشد: $e');
    }
  }

  Future<void> sendImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sending) return;
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
      if (picked == null || !mounted) return;
      setState(() { sending = true; sendError = null; });
      final file = File(picked.path);
      final name = '${DateTime.now().millisecondsSinceEpoch}_${picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final ref = FirebaseStorage.instance.ref('rooms/general/${user.uid}/$name');
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      await messages.add({
        'senderUid': user.uid,
        'senderEmail': user.email ?? 'کاربر',
        'text': '',
        'mediaUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
        'kind': 'image',
      });
    } on FirebaseException catch (e) {
      if (mounted) setState(() => sendError = 'ارسال عکس نشد: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => sendError = 'ارسال عکس نشد: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String clock(Timestamp? ts) {
    if (ts == null) return '...';
    final d = ts.toDate().toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() { controller.dispose(); recorder.dispose(); audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF173B75), foregroundColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lets Talk — اتاق عمومی'),
          Text('پیام‌ها از طریق انترنت همگام می‌شوند', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [IconButton(tooltip: 'خروج', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(10), color: const Color(0xFFE8EFFC),
          child: Text('حساب: ${me?.email ?? ''}\nاین فعلاً یک اتاق مشترک آزمایشی است؛ هر کسی که حساب دارد می‌تواند پیام‌ها را ببیند.', style: const TextStyle(fontSize: 12))),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: messages.orderBy('createdAt').limit(200).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('پیام‌ها بار نشدند. مطمئن شو Firestore ساخته شده و Rules نشر شده است.\n${snapshot.error}', textAlign: TextAlign.center)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('هنوز پیامی نیست. اولین پیام را بفرست.'));
            return ListView.builder(padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, i) {
              final data = docs[i].data();
              final mine = data['senderUid'] == me?.uid;
              return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                constraints: const BoxConstraints(maxWidth: 310), margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: mine ? const Color(0xFFDCE8FF) : Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mine ? 'من' : (data['senderEmail'] as String? ?? 'کاربر'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2457A7))),
                  const SizedBox(height: 3),
                  if (data['kind'] == 'image' && data['mediaUrl'] is String) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(data['mediaUrl'] as String, width: 230, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(width: 230, height: 140, child: Center(child: CircularProgressIndicator())), errorBuilder: (_, __, ___) => const Text('عکس بار نشد')))),
                  if (data['kind'] == 'audio' && data['mediaUrl'] is String) Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => audioPlayer.play(UrlSource(data['mediaUrl'] as String)), icon: const Icon(Icons.play_circle_fill)),
                    const Text('پیام صوتی'),
                  ]),
                  if (data['kind'] == 'file' && data['mediaUrl'] is String) InkWell(
                    onTap: () => launchUrl(Uri.parse(data['mediaUrl'] as String), mode: LaunchMode.externalApplication),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.attach_file), const SizedBox(width: 6),
                      Flexible(child: Text(data['fileName'] as String? ?? 'بازکردن فایل', maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.open_in_new, size: 16),
                    ]),
                  ),
                  if ((data['text'] as String? ?? '').isNotEmpty) Text(data['text'] as String, style: const TextStyle(fontSize: 16)),
                  Align(alignment: Alignment.bottomRight, child: Text(clock(data['createdAt'] as Timestamp?), style: const TextStyle(fontSize: 10, color: Colors.black54))),
                ]),
              ));
            });
          },
        )),
        if (sendError != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(sendError!, style: const TextStyle(color: Colors.red))),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: controller, onSubmitted: (_) => send(), textInputAction: TextInputAction.send, decoration: const InputDecoration(hintText: 'پیام بنویس...', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          IconButton(onPressed: sending ? null : sendImage, tooltip: 'ارسال عکس آنلاین', icon: const Icon(Icons.image_outlined)),
          IconButton(onPressed: sending ? null : sendFile, tooltip: 'ارسال فایل آنلاین', icon: const Icon(Icons.attach_file)),
          IconButton(onPressed: sending ? null : toggleRecording, tooltip: recording ? 'توقف و ارسال صدا' : 'ضبط پیام صوتی', color: recording ? Colors.red : null, icon: Icon(recording ? Icons.stop_circle : Icons.mic)),
          IconButton.filled(onPressed: sending || recording ? null : send, icon: const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
}
