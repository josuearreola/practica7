import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_role.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/create_case_dialog.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatAttachment? _pendingAttachment;
  bool _hasInputError = false;

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
    final text = _textController.text.trim();
    final attachment = _pendingAttachment;

    // VALIDACIÓN CRÍTICA (Requisito 6): Evitar el envío de mensajes vacíos
    if (text.isEmpty && attachment == null) {
      setState(() {
        _hasInputError = true;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Validación: No se puede enviar un mensaje vacío. Escriba un texto o adjunte un archivo.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Reset error state
    if (_hasInputError) {
      setState(() => _hasInputError = false);
    }

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
        _hasInputError = false;
      });
      _scrollToBottom();

      // VALIDACIÓN VISUAL (Requisito 7): Notificación visual de éxito al enviar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text(
                result.createdMessage?.formattedTime ?? '',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF064E3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // File Picker dialog
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
                subtitle: const Text('Imágenes, documentos PDF, logs de incidentes',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final files = await FilePicker.pickFiles();
                    if (files.isNotEmpty) {
                      final file = files.first;
                      final name = file.name;
                      final ext = file.extension ?? (name.contains('.') ? name.split('.').last : 'bin');
                      final isImg = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext.toLowerCase());
                      final size = file.lengthSync() ?? (256 * 1024);

                      setState(() {
                        _pendingAttachment = ChatAttachment(
                          id: const Uuid().v4(),
                          fileName: name,
                          fileExtension: ext,
                          fileSizeBytes: size,
                          mimeType: isImg ? 'image/$ext' : 'application/octet-stream',
                          isImage: isImg,
                        );
                        _hasInputError = false;
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
                child: Text('Adjuntos rápidos de prueba (Casos Helpdesk):',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                      _hasInputError = false;
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

  // Clear history dialog (Requisito AGREGAR)
  void _confirmClearHistory(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF475569)),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Limpiar Historial', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: const Text(
            '¿Está seguro de que desea vaciar todo el historial de mensajes de la conversación? Los contadores por dispositivo se actualizarán a cero.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
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

    final conversationMessages = chatProvider.messages;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19),
      ),
      child: Column(
        children: [
          // 1. HEADER: Requirement 1 ("Mostrar los nombres de los dos dispositivos conectados")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              border: const Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Channel indicator icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.connect_without_contact_rounded, color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: 10),

                  // Device A Badge (Emisor)
                  _buildDevicePill(
                    role: senderRole,
                    prefix: 'EMISOR',
                    name: senderRole.shortDeviceName,
                    isOnline: appState.isDeviceOnline(senderRole),
                    isMe: senderRole == currentRole,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.sync_alt_rounded, color: Color(0xFF38BDF8), size: 20),
                  ),

                  // Device B Badge (Receptor)
                  _buildDevicePill(
                    role: receiverRole,
                    prefix: 'RECEPTOR',
                    name: receiverRole.shortDeviceName,
                    isOnline: appState.isDeviceOnline(receiverRole),
                    isMe: receiverRole == currentRole,
                  ),

                  const SizedBox(width: 16),

                  // Quick Action: Redactar Caso Dialog
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentRole.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.assignment_add, size: 15),
                    label: const Text(
                      'Nuevo Caso',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const CreateCaseDialog(),
                      );
                    },
                  ),

                  const SizedBox(width: 10),

                  // Clear history button (Requisito AGREGAR)
                  Tooltip(
                    message: 'Limpiar el historial de mensajes de la conversación',
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmClearHistory(context, chatProvider),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 15, color: Color(0xFFF87171)),
                      label: const Text(
                        'Limpiar',
                        style: TextStyle(fontSize: 12, color: Color(0xFFF87171)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7F1D1D)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CHANNEL SELECTOR BAR:
          // Requirement 2: "Permitir seleccionar el dispositivo emisor (administrador)"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  const Text(
                    'Configurar Canal:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 12),

                  // Sender Selector (Requirement 2: Admin can select sender)
                  if (currentRole == AppRole.admin) ...[
                    const Text('Emisor: ', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                    DropdownButton<AppRole>(
                      value: senderRole,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      underline: const SizedBox(),
                      onChanged: (role) {
                        if (role != null) appState.setSelectedSenderRole(role);
                      },
                      items: AppRole.coreRoles.map((r) {
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
                  const Text('Enviar a: ', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                  DropdownButton<AppRole>(
                    value: receiverRole,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    onChanged: (role) {
                      if (role != null) appState.setSelectedReceiverRole(role);
                    },
                    items: AppRole.coreRoles.where((r) => r != senderRole).map((r) {
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

                  // Real-time counter of sent messages
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      '${chatProvider.totalMessagesCount} msgs en historial',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. CONVERSATION MESSAGE LIST (Requirement 5: Mostrar mensaje y emisor en lista)
          Expanded(
            child: conversationMessages.isEmpty
                ? _buildEmptyState(context, senderRole, receiverRole)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Icon(_pendingAttachment!.icon, color: _pendingAttachment!.iconColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pendingAttachment!.fileName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Archivo adjunto listo para enviar • ${_pendingAttachment!.formattedSize}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
          // Requirement 3: Campo de texto para redactar mensajes
          // Requirement 4: Permitir enviar mensajes al otro dispositivo
          // Requirement 6: Evitar el envío de mensajes vacíos (validación con borde rojo y alerta)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131B2E),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                Tooltip(
                  message: 'Adjuntar archivo o evidencia',
                  child: IconButton(
                    onPressed: () => _pickAttachment(context),
                    icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF38BDF8), size: 22),
                  ),
                ),

                const SizedBox(width: 6),

                // Text Field (Requirement 3 + Requirement 6 Validation)
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (val) {
                      if (_hasInputError && val.trim().isNotEmpty) {
                        setState(() => _hasInputError = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _hasInputError
                          ? '⚠️ Escribe un mensaje (No se puede enviar vacío)...'
                          : 'Redactar mensaje para ${receiverRole.shortDeviceName}...',
                      hintStyle: TextStyle(
                        color: _hasInputError ? const Color(0xFFFCA5A5) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                      fillColor: _hasInputError ? const Color(0xFF2B1115) : const Color(0xFF0F172A),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: _hasInputError ? const Color(0xFFEF4444) : const Color(0xFF334155),
                          width: _hasInputError ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: _hasInputError ? const Color(0xFFEF4444) : const Color(0xFF334155),
                          width: _hasInputError ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: _hasInputError ? const Color(0xFFEF4444) : currentRole.primaryColor,
                          width: 2,
                        ),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: senderRole.primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _handleSendMessage(
                      context: context,
                      chatProvider: chatProvider,
                      appState: appState,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    tooltip: 'Enviar mensaje a ${receiverRole.shortDeviceName}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicePill({
    required AppRole role,
    required String prefix,
    required String name,
    required bool isOnline,
    required bool isMe,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: role.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: role.primaryColor.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$prefix: $name${isMe ? ' (Tú)' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: role.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppRole senderRole, AppRole receiverRole) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_outlined, size: 48, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Canal Listo para Conversar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay mensajes aún entre ${senderRole.shortDeviceName} y ${receiverRole.shortDeviceName}.\nRedacta un mensaje abajo o registra un nuevo caso de falla para iniciar.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const CreateCaseDialog(),
                  );
                },
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Redactar Primer Caso / Reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Message Bubble with Sender Name, Role Color, Timestamp, Attachment, and Incident Card support
  Widget _buildMessageBubble(ChatMessage msg, bool isMyMessage) {
    final sender = msg.senderRole;
    final isIncidentCard = msg.text.startsWith('📋 [');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isIncidentCard
                    ? const Color(0xFF1E2238)
                    : isMyMessage
                        ? const Color(0xFF1E3A8A).withOpacity(0.35)
                        : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                border: Border.all(
                  color: isIncidentCard
                      ? const Color(0xFFF59E0B).withOpacity(0.6)
                      : isMyMessage
                          ? sender.primaryColor.withOpacity(0.5)
                          : const Color(0xFF334155),
                  width: isIncidentCard ? 1.5 : 1,
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
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),

                  // Message text
                  if (msg.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isIncidentCard ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9),
                        height: 1.4,
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
                            tooltip: 'Descargar / Abrir',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Abriendo adjunto: ${msg.attachment!.fileName}'),
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

                  // Timestamp formatted as hh:mm:ss a (Requirement AGREGAR)
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
            const SizedBox(width: 8),
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
