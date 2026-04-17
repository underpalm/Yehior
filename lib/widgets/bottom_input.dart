import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../constants/theme.dart';
import '../models/chat_attachment.dart';
import '../providers/chat_provider.dart';
import '../screens/bible_reader_screen.dart';

class BottomInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const BottomInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  State<BottomInput> createState() => _BottomInputState();
}

class _BottomInputState extends State<BottomInput> {
  final _recorder = AudioRecorder();

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final provider = context.read<ChatProvider>();

    if (provider.isRecording) {
      // Stop recording
      final path = await _recorder.stop();
      provider.setRecording(false);

      if (path == null) return;

      // Transcribe
      provider.setTranscribing(true);
      try {
        final text = await provider.transcribeAudio(path);
        if (text.isNotEmpty) {
          widget.controller.text =
              widget.controller.text.isEmpty ? text : '${widget.controller.text} $text';
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transkription fehlgeschlagen: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        provider.setTranscribing(false);
        // Clean up temp file
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } else {
      // Start recording
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mikrofon-Berechtigung wurde nicht erteilt.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/yehior_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      provider.setRecording(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final attachment = provider.pendingAttachment;

    return Container(
      color: kBgColor,
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        color: kInputColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attachment preview
            if (attachment != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (attachment.isImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          attachment.bytes,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: kPillBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description, color: kAccentBlue),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: kTextPrimary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => provider.clearAttachment(),
                      child: const Icon(Icons.close, size: 18, color: kTextSecondary),
                    ),
                  ],
                ),
              ),

            // Recording indicator
            if (provider.isRecording)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Aufnahme läuft… Tippe erneut zum Stoppen.',
                      style: TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ],
                ),
              ),

            // Transcribing indicator
            if (provider.isTranscribing)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kPillBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sprache wird erkannt…',
                      style: TextStyle(fontSize: 13, color: kAccentBlue),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: widget.controller,
                enabled: !provider.isStreaming && !provider.isRecording && !provider.isTranscribing,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: provider.isStreaming
                      ? 'Antwort wird geladen…'
                      : provider.isTranscribing
                          ? 'Transkribiere…'
                          : attachment != null
                              ? 'Frage zum Anhang stellen…'
                              : 'Fragen...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: kTextSecondary, fontSize: 18),
                ),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: kTextPrimary),
                  onPressed: () => _showAttachMenu(context),
                ),
                const Spacer(),
                // Bibel-Button
                GestureDetector(
                  onTap: () => _showBibleMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPillBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 16, color: kAccentBlue),
                        SizedBox(width: 6),
                        Text(
                          'Bibel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: kAccentBlue,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.expand_more, size: 16, color: kAccentBlue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic — Whisper
                IconButton(
                  icon: provider.isRecording
                      ? _circleIcon(Icons.stop, recording: true)
                      : _circleIcon(Icons.mic_none),
                  onPressed: (provider.isStreaming || provider.isTranscribing)
                      ? null
                      : _toggleRecording,
                ),
                const SizedBox(width: 8),
                // Send
                IconButton(
                  icon: _circleIcon(
                    provider.isStreaming ? Icons.hourglass_top : Icons.send,
                    filled: true,
                  ),
                  onPressed: provider.isStreaming ? null : widget.onSend,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Anhang hinzufügen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPillBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: kAccentBlue),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Foto aufnehmen'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF43A047)),
              ),
              title: const Text('Foto aus Galerie'),
              subtitle: const Text('Bild vom Handy auswählen'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: Color(0xFFE65100)),
              ),
              title: const Text('Datei'),
              subtitle: const Text('PDF, Word oder Textdatei'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();

    if (source == ImageSource.camera) {
      final available = picker.supportsImageSource(ImageSource.camera);
      if (!available) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Kamera verfügbar auf diesem Gerät.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final base64Str = base64Encode(bytes);

    final ext = xFile.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    if (!context.mounted) return;
    context.read<ChatProvider>().setAttachment(ChatAttachment(
      type: AttachmentType.image,
      fileName: xFile.name,
      bytes: bytes,
      mimeType: mime,
      processedContent: base64Str,
    ));
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null && file.path == null) return;

    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final fileName = file.name;
    final ext = fileName.split('.').last.toLowerCase();

    String extractedText;
    if (ext == 'txt' || ext == 'rtf') {
      extractedText = String.fromCharCodes(bytes);
    } else {
      try {
        final rawText = String.fromCharCodes(bytes);
        final cleaned =
            rawText.replaceAll(RegExp(r'[^\x20-\x7E\xC0-\xFF\n\r\t]'), ' ');
        extractedText = cleaned.replaceAll(RegExp(r'\s{3,}'), '\n').trim();
        if (extractedText.length < 50) {
          extractedText =
              '[Die Datei „$fileName" konnte nicht vollständig gelesen werden. '
              'Bitte stelle deine Frage und beschreibe den Inhalt.]';
        }
      } catch (_) {
        extractedText =
            '[Die Datei „$fileName" konnte nicht gelesen werden. '
            'Bitte stelle deine Frage und beschreibe den Inhalt.]';
      }
    }

    if (!context.mounted) return;
    context.read<ChatProvider>().setAttachment(ChatAttachment(
      type: AttachmentType.document,
      fileName: fileName,
      bytes: bytes,
      processedContent: extractedText,
    ));
  }

  void _showBibleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Bibel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: kPillBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chat_outlined, color: kAccentBlue),
              ),
              title: const Text('Mit der Bibel chatten'),
              subtitle:
                  const Text('Stelle Fragen, erhalte Erklärungen & Andachten'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_book_outlined, color: kTextPrimary),
              ),
              title: const Text('Bibel lesen'),
              subtitle: const Text('Schlachter-Übersetzung — alle 66 Bücher'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BibleReaderScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, {bool filled = false, bool recording = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: recording
            ? Colors.red
            : filled
                ? kPillBlue
                : Colors.transparent,
        shape: BoxShape.circle,
        border: (filled || recording) ? null : Border.all(color: kDivider),
      ),
      child: Icon(
        icon,
        color: recording ? Colors.white : kTextPrimary,
        size: 24,
      ),
    );
  }
}
