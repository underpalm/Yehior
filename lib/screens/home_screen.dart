import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/features.dart';
import '../constants/theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_input.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/pill_button.dart';
import '../widgets/verse_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    // Auto-scroll when streaming
    if (provider.isStreaming) _scrollToBottom();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: _buildAppBar(provider),
      bottomNavigationBar: BottomInput(
        controller: _messageController,
        onSend: _send,
      ),
      body: SafeArea(
        bottom: false,
        child: provider.activeConversation == null
            ? _buildStartScreen(provider)
            : _buildChatView(provider),
      ),
    );
  }

  AppBar _buildAppBar(ChatProvider provider) {
    return AppBar(
      backgroundColor: kBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: kTextPrimary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        provider.activeConversation?.title ?? 'Yehior',
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        if (provider.activeConversation != null)
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: kTextPrimary),
            tooltip: 'Neuer Chat',
            onPressed: provider.startNewChat,
          ),
        const Padding(
          padding: EdgeInsets.only(right: 12.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF5C6BC0),
            child: Text('N', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildStartScreen(ChatProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Hallo Nerd',
            style: TextStyle(fontSize: 28, color: kTextSecondary, fontWeight: FontWeight.w400),
          ),
          const Text(
            'Womit fangen wir an?',
            style: TextStyle(fontSize: 36, color: Colors.black, fontWeight: FontWeight.w500, height: 1.1),
          ),
          const SizedBox(height: 24),
          const VerseCard(),
          const SizedBox(height: 24),
          ...kFeatures.map(
            (f) => PillButton(
              text: '${f['icon']}  ${f['label']!}',
              onTap: () => provider.sendMessage(f['label']!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(ChatProvider provider) {
    final messages = provider.activeConversation!.messages;
    final showStreaming = provider.isStreaming && provider.streamingText.isNotEmpty;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: messages.length + (showStreaming ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < messages.length) {
          return ChatBubble(
            text: messages[i]['text'] as String,
            isUser: messages[i]['isUser'] as bool,
          );
        }
        // Streaming bubble
        return ChatBubble(text: provider.streamingText, isUser: false, isStreaming: true);
      },
    );
  }
}
