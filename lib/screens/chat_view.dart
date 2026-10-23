import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_role.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatAttachment? _pendingAttachment;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage({
    required BuildContext context,
    required ChatProvider chatProvider,
    required AppStateProvider appState,
  }) async {
    final senderRole = appState.selectedSenderRole;
    final receiverRole = appState.selectedReceiverRole;
    final text = _textController.text;
    final attachment = _pendingAttachment;

    final result = await chatProvider.sendMessage(
      senderRole: senderRole,
      receiverRole: receiverRole,
      text: text,
      attachment: attachment,
      isOfflineSimulated: appState.isOfflineSimulated,
    );

    if (!context.mounted) return;

    if (result.success) {
      _textController.clear();
      setState(() {
        _pendingAttachment = null;
      });
      _scrollToBottom();

      // Requirement 7: Mostrar una notificación visual cuando se envíe un mensaje
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Requirement 6: Evitar el envío de mensajes vacíos (y notificación de error)
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7F1D1D),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // File Picker dialog / native picker
  Future<void> _pickAttachment(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjuntar archivo a la conversación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona un archivo del sistema o un adjunto de prueba rápido:',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: Color(0xFF60A5FA)),
                ),
                title: const Text('Examinar archivos locales...', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Imágenes, documentos PDF, logs de incidentes', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final files = await FilePickerPlatform.instance.pickFiles();
                    if (files.isNotEmpty) {
                      final file = files.first;
                      final name = file.name;
                      final ext = name.contains('.') ? name.split('.').last : 'bin';
                      final isImg = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext.toLowerCase());

                      setState(() {
                        _pendingAttachment = ChatAttachment(
                          id: const Uuid().v4(),
                          fileName: name,
                          fileExtension: ext,
                          fileSizeBytes: 256 * 1024,
                          mimeType: isImg ? 'image/$ext' : 'application/octet-stream',
                          isImage: isImg,
                        );
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo abrir el selector: $e')),
                      );
                    }
                  }
                },
              ),
              const Divider(color: Color(0xFF334155)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Adjuntos rápidos de prueba (Casos Helpdesk):', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ),
              ...ChatAttachment.testSamples.map((sample) {
                return ListTile(
                  dense: true,
                  leading: Icon(sample.icon, color: sample.iconColor),
                  title: Text(sample.fileName, style: const TextStyle(fontSize: 13, color: Colors.white)),
                  trailing: Text(sample.formattedSize, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  onTap: () {
                    setState(() {
                      _pendingAttachment = sample;
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Clear history dialog
  void _confirmClearHistory(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Limpiar Historial', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            '¿Está seguro de que desea vaciar todo el historial de mensajes de la conversación? Los contadores se actualizarán.',
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () {
                chatProvider.clearHistory();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Historial de mensajes vaciado correctamente.'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              },
              child: const Text('Limpiar todo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final currentRole = appState.currentRole;

    final senderRole = appState.selectedSenderRole;
    final receiverRole = appState.selectedReceiverRole;

    // Filter messages for current channel view or show all
    final conversationMessages = chatProvider.messages;

    return Column(
      children: [
        // 1. HEADER: Requirement 1 ("Mostrar los nombres de los dos dispositivos conectados")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF131B2E),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Device A Badge
                _buildDevicePill(senderRole, 'EMISOR: ${senderRole.shortDeviceName}', appState.isDeviceOnline(senderRole)),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.swap_horiz_rounded, color: Color(0xFF38BDF8), size: 22),
                ),

                // Device B Badge
                _buildDevicePill(receiverRole, 'RECEPTOR: ${receiverRole.shortDeviceName}', appState.isDeviceOnline(receiverRole)),

                const SizedBox(width: 24),

                // Clear history button (AGREGAR: Agregar un botón para limpiar el historial)
                Tooltip(
                  message: 'Limpiar el historial de mensajes',
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmClearHistory(context, chatProvider),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF87171)),
                    label: const Text(
                      'Limpiar Historial',
                      style: TextStyle(fontSize: 12, color: Color(0xFFF87171)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7F1D1D)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. SENDER / RECEIVER SELECTOR BAR:
        // Requirement 2: "Permitir seleccionar el dispositivo emisor (administrador)"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: const Color(0xFF0F172A),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.settings_input_component_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                const Text(
                  'Canal de Envío:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 12),

                // Sender Selector (Requirement 2: Admin can choose sender)
                if (currentRole == AppRole.admin) ...[
                  const Text('Emisor: ', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                  DropdownButton<AppRole>(
                    value: senderRole,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    underline: const SizedBox(),
                    onChanged: (role) {
                      if (role != null) appState.setSelectedSenderRole(role);
                    },
                    items: AppRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Icon(r.icon, size: 14, color: r.primaryColor),
                            const SizedBox(width: 6),
                            Text(r.shortDeviceName),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 16),
                ] else ...[
                  Text(
                    'Emisor: ${currentRole.shortDeviceName}',
                    style: TextStyle(fontSize: 12, color: currentRole.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                ],

                // Receiver Selector
                const Text('Destinatario: ', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                DropdownButton<AppRole>(
                  value: receiverRole,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  underline: const SizedBox(),
                  onChanged: (role) {
                    if (role != null) appState.setSelectedReceiverRole(role);
                  },
                  items: AppRole.values.where((r) => r != senderRole).map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Icon(r.icon, size: 14, color: r.primaryColor),
                          const SizedBox(width: 6),
                          Text(r.shortDeviceName),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(width: 20),

                // Quick device message counter display
                Text(
                  'Total: ${chatProvider.totalMessagesCount} mensajes',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),

        // 3. CONVERSATION MESSAGE LIST (Requirement 5: Mostrar el mensaje y su emisor en una lista de conversación)
        Expanded(
          child: conversationMessages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: conversationMessages.length,
                  itemBuilder: (context, index) {
                    final msg = conversationMessages[index];
                    final isMyMessage = msg.senderRole == currentRole;
                    return _buildMessageBubble(msg, isMyMessage);
                  },
                ),
        ),

        // 4. PENDING ATTACHMENT PREVIEW (if selected)
        if (_pendingAttachment != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Icon(_pendingAttachment!.icon, color: _pendingAttachment!.iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pendingAttachment!.fileName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Adjunto preparado • ${_pendingAttachment!.formattedSize}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    setState(() {
                      _pendingAttachment = null;
                    });
                  },
                ),
              ],
            ),
          ),

        // 5. INPUT FIELD & SEND ACTIONS
        // Requirement 3: Contar con un campo de texto para redactar mensajes
        // Requirement 4: Permitir enviar mensajes al otro dispositivo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF131B2E),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              Tooltip(
                message: 'Adjuntar archivo o captura',
                child: IconButton(
                  onPressed: () => _pickAttachment(context),
                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF38BDF8)),
                ),
              ),

              const SizedBox(width: 8),

              // Text Field (Requirement 3)
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Redactar mensaje para ${receiverRole.shortDeviceName}...',
                    fillColor: const Color(0xFF0F172A),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: currentRole.primaryColor, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _handleSendMessage(
                    context: context,
                    chatProvider: chatProvider,
                    appState: appState,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Send Button (Requirement 4)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [senderRole.primaryColor, const Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: () => _handleSendMessage(
                    context: context,
                    chatProvider: chatProvider,
                    appState: appState,
                  ),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  tooltip: 'Enviar mensaje',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevicePill(AppRole role, String label, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: role.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: role.primaryColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: role.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey.shade700),
            const SizedBox(height: 12),
            const Text(
              'Sin mensajes en este canal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Redacta un mensaje o envía un archivo adjunto para iniciar la interacción.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // Message Bubble with Sender Name, Role Color, Timestamp, Attachment
  Widget _buildMessageBubble(ChatMessage msg, bool isMyMessage) {
    final sender = msg.senderRole;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: sender.primaryColor,
              child: Icon(sender.icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMyMessage ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                border: Border.all(
                  color: isMyMessage ? sender.primaryColor.withOpacity(0.5) : const Color(0xFF334155),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name and Role Badge (Requirement 5)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.senderDeviceName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sender.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: sender.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sender.badgeLabel,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sender.primaryColor),
                        ),
                      ),
                      if (msg.receiverDeviceName != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          msg.receiverDeviceName!,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),

                  // Message text
                  if (msg.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF1F5F9),
                        height: 1.35,
                      ),
                    ),
                  ],

                  // Attachment view (if present)
                  if (msg.hasAttachment) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(msg.attachment!.icon, color: msg.attachment!.iconColor, size: 24),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.attachment!.fileName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  msg.attachment!.formattedSize,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF38BDF8)),
                            tooltip: 'Descargar / Ver',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Abriendo archivo: ${msg.attachment!.fileName}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Timestamp (Requirement AGREGAR: "Agregar la hora de envío a cada mensaje")
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      msg.formattedTime,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: sender.primaryColor,
              child: Icon(sender.icon, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
