import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_role.dart';
import '../models/incident_report.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/incident_provider.dart';

class CreateCaseDialog extends StatefulWidget {
  const CreateCaseDialog({super.key});

  @override
  State<CreateCaseDialog> createState() => _CreateCaseDialogState();
}

class _CreateCaseDialogState extends State<CreateCaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _idController = TextEditingController(
    text: 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
  );
  IncidentCategory _selectedCategory = IncidentCategory.reporteFallas;
  IncidentPriority _selectedPriority = IncidentPriority.alta;
  bool _isDirectToAdmin = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _equipmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final appState = context.read<AppStateProvider>();
    final incidentProvider = context.read<IncidentProvider>();
    final chatProvider = context.read<ChatProvider>();

    final userRole = appState.currentRole;
    final id = _idController.text.trim();
    final title = _titleController.text.trim();
    final equipment = _equipmentController.text.trim();
    final description = _descriptionController.text.trim();

    // Determine target recipient (Admin if direct or agent offline, else Agent)
    final targetRole = _isDirectToAdmin || !appState.isAgentConnected ? AppRole.admin : AppRole.agente;

    final result = await incidentProvider.createReport(
      id: id,
      title: title,
      equipment: equipment,
      description: description,
      category: _selectedCategory,
      priority: _selectedPriority,
      reportedByRole: userRole,
      assignedRole: targetRole,
      isDirectToAdmin: _isDirectToAdmin,
    );

    setState(() => _isSubmitting = false);

    if (result.success && mounted) {
      // Also post a case summary notification into the live chat
      final categoryLabel = _selectedCategory == IncidentCategory.reporteFallas
          ? '⚠️ REPORTE DE FALLAS'
          : _selectedCategory == IncidentCategory.solucionAccesosPerdidos
              ? '🔑 ACCESO PERDIDO'
              : '🔄 PROCESO DE ATENCIÓN';

      final ticketId = result.report?.id ?? id;
      final chatText = '📋 [$ticketId] $categoryLabel: "$title" en $equipment.\n'
          'Prioridad: ${_selectedPriority.name.toUpperCase()}.\n'
          'Descripción: $description'
          '${_isDirectToAdmin ? '\n⚡ SOLICITUD DIRECTA AL ADMINISTRADOR' : ''}';

      await chatProvider.sendMessage(
        senderRole: userRole,
        receiverRole: targetRole,
        text: chatText,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Caso registrado exitosamente y transmitido a ${targetRole.shortDeviceName}.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(result.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentRole = appState.currentRole;

    return Dialog(
      backgroundColor: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
      ),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: currentRole.primaryColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assignment_add, color: currentRole.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Redactar Nuevo Caso / Reporte',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Emisor: ${currentRole.deviceName}',
                            style: TextStyle(fontSize: 12, color: currentRole.primaryColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category Selector
                const Text(
                  'Tipo de Caso / Incidente:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryChip(
                      IncidentCategory.reporteFallas,
                      'Reporte de Fallas',
                      Icons.warning_amber_rounded,
                      const Color(0xFFEF4444),
                    ),
                    _buildCategoryChip(
                      IncidentCategory.solucionAccesosPerdidos,
                      'Solución de Accesos Perdidos',
                      Icons.lock_reset_rounded,
                      const Color(0xFFF59E0B),
                    ),
                    _buildCategoryChip(
                      IncidentCategory.procesoAtencion,
                      'Proceso de Atención',
                      Icons.support_agent_rounded,
                      const Color(0xFF38BDF8),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Case ID Input
                TextFormField(
                  controller: _idController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Identificador del Caso (ID Único) *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'Ej. REP-001, FALLA-01',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF38BDF8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el ID del caso' : null,
                ),
                const SizedBox(height: 14),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Título o Asunto del Caso *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'Ej. Servidor Postgres no responde tras reinicio',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF818CF8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el título del caso' : null,
                ),
                const SizedBox(height: 14),

                // Equipment / System Input
                TextFormField(
                  controller: _equipmentController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Equipo, Área o Sistema Afectado *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'Ej. Servidor Dell R740 / Base de datos / Switch Cisco',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.devices_rounded, color: Color(0xFF38BDF8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Especifica el equipo o sistema afectado' : null,
                ),
                const SizedBox(height: 14),

                // Description Input
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Descripción Detallada del Problema *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'Describe la falla observada, síntomas y pasos para reproducir...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'La descripción es obligatoria' : null,
                ),
                const SizedBox(height: 16),

                // Priority Selector
                Row(
                  children: [
                    const Text(
                      'Prioridad:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<IncidentPriority>(
                        value: _selectedPriority,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: IncidentPriority.values.map((p) {
                          Color color;
                          switch (p) {
                            case IncidentPriority.critica:
                              color = const Color(0xFFEF4444);
                              break;
                            case IncidentPriority.alta:
                              color = const Color(0xFFF97316);
                              break;
                            case IncidentPriority.media:
                              color = const Color(0xFFFBBF24);
                              break;
                            case IncidentPriority.baja:
                              color = const Color(0xFF38BDF8);
                              break;
                          }
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(p.name.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPriority = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Direct to Admin Checkbox (Requirement)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDirectToAdmin
                        ? const Color(0xFF6366F1).withOpacity(0.15)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDirectToAdmin ? const Color(0xFF6366F1) : const Color(0xFF334155),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _isDirectToAdmin,
                    onChanged: (val) => setState(() => _isDirectToAdmin = val ?? false),
                    title: const Text(
                      'Solicitud Directa al Administrador',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Asigna y escala el problema directamente al Administrador omitiendo al Agente.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    activeColor: const Color(0xFF6366F1),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentRole.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: _isSubmitting ? null : _submitCase,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Registrando Caso...' : 'Publicar y Transmitir Caso al Chat',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(IncidentCategory category, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
