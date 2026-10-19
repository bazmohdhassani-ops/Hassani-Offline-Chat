import 'package:flutter/material.dart';

void main() => runApp(const HassaniChatApp());

class HassaniChatApp extends StatelessWidget {
  const HassaniChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hassani Offline Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F5B)),
        useMaterial3: true,
      ),
      home: const ChatHomePage(),
    );
  }
}

class ChatItem {
  final String name;
  final String message;
  final String time;
  final IconData icon;
  const ChatItem(this.name, this.message, this.time, this.icon);
}

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final List<ChatItem> chats = const [
    ChatItem('گروه خانواده', 'سلام به همه 👋', '۸:۳۰', Icons.groups),
    ChatItem('احمد', 'بعداً صحبت می‌کنیم', 'دیروز', Icons.person),
    ChatItem('گروه دوستان', 'پیام نمونه', 'دیروز', Icons.group),
  ];
  final TextEditingController search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final visible = chats.where((c) =>
      c.name.toLowerCase().contains(search.text.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hassani Offline Chat',
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Hassani Offline Chat',
              applicationVersion: 'Starter 1.0',
              children: const [
                Text('این نسخهٔ ابتدایی رابط برنامه است. پیام‌رسانی واقعی میان دستگاه‌ها هنوز فعال نشده است.')
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'جستجوی گفتگوها...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                final chat = visible[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(chat.icon),
                  ),
                  title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(chat.message),
                  trailing: Text(chat.time, style: Theme.of(context).textTheme.bodySmall),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatPage(name: chat.name),
                  )),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('گفتگوی جدید'),
            content: const Text('این قابلیت در نسخهٔ ابتدایی فقط نمایشی است.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
          ),
        ),
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String name;
  const ChatPage({super.key, required this.name});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <String>['خوش آمدید به Hassani Offline Chat'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) => Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(messages[i]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ارسال عکس در نسخهٔ بعدی اضافه می‌شود.')),
                  ), icon: const Icon(Icons.image)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: 'پیام بنویسید...', border: OutlineInputBorder()),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  IconButton(onPressed: send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(text);
      controller.clear();
    });
  }
}
