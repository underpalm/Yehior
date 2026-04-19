import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/features.dart';
import '../constants/theme.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';
import '../screens/plans_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/search_screen.dart';
import 'drawer_icon_button.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Drawer(
      child: Column(
        children: [
          // Top icon row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DrawerIconButton(
                  icon: Icons.search,
                  label: 'Suche',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
                DrawerIconButton(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Pläne',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    );
                  },
                ),
                DrawerIconButton(
                  icon: Icons.bookmark_border,
                  label: 'Gespeichert',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Neuer Chat
          ListTile(
            leading: const Icon(Icons.add_comment_outlined),
            title: const Text('Neuer Chat'),
            onTap: () {
              provider.startNewChat();
              Navigator.pop(context);
            },
          ),

          // Feature-Schnellstart
          ...kFeatures.map((f) => ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                title: Text(
                  '${f['icon']}  ${f['label']}',
                  style: const TextStyle(fontSize: 14, color: kTextSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  provider.startFeatureChat(f['label']!);
                },
              )),

          const Divider(height: 1),

          // Gesprächsverlauf
          Expanded(
            child: provider.conversations.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Gespräche',
                      style: TextStyle(color: kTextSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, i) {
                      final conv = provider.conversations[i];
                      final isActive = conv.id == provider.activeId;
                      return ListTile(
                        title: Text(
                          conv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isActive,
                        selectedTileColor: kSelectedTile,
                        trailing: IconButton(
                          icon: const Icon(Icons.more_horiz, size: 18, color: kTextSecondary),
                          onPressed: () => _showConversationMenu(context, provider, conv),
                        ),
                        onTap: () {
                          provider.openConversation(conv.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Einstellungen'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showConversationMenu(
    BuildContext context,
    ChatProvider provider,
    Conversation conv,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Umbenennen'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, provider, conv);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Löschen', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                provider.deleteConversation(conv.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    ChatProvider provider,
    Conversation conv,
  ) {
    final controller = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                provider.renameConversation(conv.id, newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
