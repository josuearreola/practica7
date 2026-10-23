import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_role.dart';
import '../models/incident_report.dart';
import '../providers/app_state_provider.dart';
import '../providers/incident_provider.dart';

class TicketsView extends StatefulWidget {
  const TicketsView({super.key});

  @override
  State<TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends State<TicketsView> {
  IncidentCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateTicketDialog(BuildContext context, {bool isDirectToAdmin = false}) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: 'REP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final titleController = TextEditingController();
    final equipController = TextEditingController();
    final descController = TextEditingController();
    IncidentCategory category = isDirectToAdmin ? IncidentCategory.solucionAccesosPerdidos : IncidentCategory.reporteFallas;
    IncidentPriority priority = isDirectToAdmin ? IncidentPriority.alta : IncidentPriority.media;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131B2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              title: Row(
                children: [
                  Icon(
                    isDirectToAdmin ? Icons.security_rounded : Icons.add_task_rounded,
                    color: isDirectToAdmin ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDirectToAdmin ? 'Solicitud Directa al Administrador' : 'Nuevo Reporte de Caso',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDirectToAdmin)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
                            ),
                            child: const Text(
                              'Esta solicitud se remitirá directamente al Administrador para aprobación de permisos o accesos perdidos.',
                              style: TextStyle(fontSize: 12, color: Color(0xFFFCA5A5)),
                            ),
                          ),
                        TextFormField(
                          controller: idController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Identificador del Reporte (ej. REP001, REP005)',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Título del Asunto',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: equipController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Equipo / Sistema Afectado * (Obligatorio)',
                            prefixIcon: Icon(Icons.computer_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Descripción del Problema * (Obligatorio)',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<IncidentCategory>(
                          initialValue: category,
                          dropdownColor: const Color(0xFF1E293B),
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: IncidentCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat.displayName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => category = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<IncidentPriority>(
                          initialValue: priority,
                          dropdownColor: const Color(0xFF1E293B),
                          decoration: const InputDecoration(
                            labelText: 'Prioridad',
                            prefixIcon: Icon(Icons.flag_rounded),
                          ),
                          items: IncidentPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.displayName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => priority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDirectToAdmin ? const Color(0xFFDC2626) : const Color(0xFF3B82F6),
                  ),
                  onPressed: () async {
                    final appState = Provider.of<AppStateProvider>(context, listen: false);
                    final incidentProvider = Provider.of<IncidentProvider>(context, listen: false);

                    final res = await incidentProvider.createReport(
                      id: idController.text,
                      title: titleController.text,
                      equipment: equipController.text,
                      description: descController.text,
                      category: category,
                      priority: priority,
                      isDirectToAdmin: isDirectToAdmin,
                      assignedRole: isDirectToAdmin ? AppRole.admin : AppRole.agente,
                      reportedByRole: appState.currentRole,
                      isOfflineSimulated: appState.isOfflineSimulated,
                    );

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Search ID Dialog (for TC06: Consultar ID REP999 sin crash)
  void _searchReportDialog(BuildContext context) {
    final searchCtrl = TextEditingController(text: 'REP999');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final incidentProvider = context.watch<IncidentProvider>();
            IncidentReport? foundReport;
            bool searched = false;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF38BDF8)),
                  SizedBox(width: 10),
                  Text('Consultar Reporte por ID', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ID del reporte a consultar',
                        hintText: 'ej. REP001 o REP999',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          foundReport = incidentProvider.getReportById(searchCtrl.text);
                          searched = true;
                        });
                      },
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Consultar Documento'),
                    ),
                    if (searched) ...[
                      const SizedBox(height: 16),
                      if (foundReport == null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF475569)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Documento "${searchCtrl.text}" no encontrado. La aplicación gestionó el resultado vacío correctamente sin bloquearse (TC06).',
                                  style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F46).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${foundReport!.id} - ${foundReport!.title}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text('Equipo: ${foundReport!.equipment}', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                              Text('Prioridad: ${foundReport!.priority.displayName}', style: TextStyle(color: foundReport!.priority.color, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final currentRole = appState.currentRole;

    final allReports = incidentProvider.reports;
    final filtered = allReports.where((r) {
      if (_selectedCategory != null && r.category != _selectedCategory) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return r.id.toLowerCase().contains(query) ||
            r.title.toLowerCase().contains(query) ||
            r.equipment.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Top Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF131B2E),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // New ticket button
              ElevatedButton.icon(
                onPressed: () => _openCreateTicketDialog(context),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Nuevo Reporte'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),

              // Direct to admin request button (for users or urgent cases)
              ElevatedButton.icon(
                onPressed: () => _openCreateTicketDialog(context, isDirectToAdmin: true),
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Solicitud Directa al Admin'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              ),

              // Query by ID button (TC06)
              OutlinedButton.icon(
                onPressed: () => _searchReportDialog(context),
                icon: const Icon(Icons.search, size: 16, color: Color(0xFF38BDF8)),
                label: const Text('Consultar ID (TC06)', style: TextStyle(color: Color(0xFF38BDF8))),
              ),

              const SizedBox(width: 8),

              // Category Filter chips
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = null);
                    },
                  ),
                  ...IncidentCategory.values.map((cat) {
                    return ChoiceChip(
                      label: Text(cat.displayName),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        // List of tickets
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade700),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay reportes que coincidan con el filtro',
                        style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final report = filtered[index];
                    return _buildReportCard(context, report, currentRole, incidentProvider, appState);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    IncidentReport report,
    AppRole currentRole,
    IncidentProvider incidentProvider,
    AppStateProvider appState,
  ) {
    final isAdmin = currentRole == AppRole.admin;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF161F33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: report.isDirectToAdmin
              ? const Color(0xFFDC2626).withOpacity(0.6)
              : const Color(0xFF334155),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    report.id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: report.priority.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: report.priority.color.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, size: 12, color: report.priority.color),
                      const SizedBox(width: 4),
                      Text(
                        'Prioridad: ${report.priority.displayName}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: report.priority.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: report.status.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.status.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: report.status.color),
                  ),
                ),
                if (report.isDirectToAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SOLICITUD DIRECTA AL ADMIN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF87171)),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  report.formattedCreatedAt,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Title & Equipment
            Text(
              report.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.devices_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  'Equipo: ${report.equipment}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(width: 14),
                Icon(report.category.icon, size: 14, color: const Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(
                  report.category.displayName,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              report.description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.3),
            ),

            if (report.resolutionNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nota de atención: ${report.resolutionNotes!}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(color: Color(0xFF1E293B), height: 24),

            // Bottom Actions & Assignment
            Row(
              children: [
                // Assigned badge
                Icon(report.assignedRole.icon, size: 14, color: report.assignedRole.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Asignado a: ${report.assignedRole.displayName}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: report.assignedRole.primaryColor),
                ),

                const Spacer(),

                // Change Priority Dropdown (TC04 - Actualización de prioridad)
                DropdownButton<IncidentPriority>(
                  value: report.priority,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  underline: const SizedBox(),
                  onChanged: (newPriority) {
                    if (newPriority != null) {
                      incidentProvider.updatePriority(
                        report.id,
                        newPriority,
                        isOfflineSimulated: appState.isOfflineSimulated,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Prioridad de ${report.id} actualizada a ${newPriority.displayName} (TC04).'),
                        ),
                      );
                    }
                  },
                  items: IncidentPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('Prioridad: ${p.displayName}'),
                    );
                  }).toList(),
                ),

                const SizedBox(width: 8),

                // Admin Reassignment (Role Interchange)
                if (isAdmin) ...[
                  IconButton(
                    tooltip: 'Reasignar caso (Agente ↔ Admin)',
                    icon: const Icon(Icons.published_with_changes_rounded, size: 18, color: Color(0xFF38BDF8)),
                    onPressed: () {
                      final newRole = report.assignedRole == AppRole.agente ? AppRole.admin : AppRole.agente;
                      final newStatus = newRole == AppRole.admin ? IncidentStatus.escaladoAdmin : IncidentStatus.enAtencion;
                      incidentProvider.reassignReport(report.id, newRole, newStatus);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reporte ${report.id} reasignado a ${newRole.displayName}.'),
                          backgroundColor: newRole.primaryColor,
                        ),
                      );
                    },
                  ),
                ],

                // Delete Report (TC05 - Eliminación)
                IconButton(
                  tooltip: 'Eliminar reporte (TC05)',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                  onPressed: () async {
                    final res = await incidentProvider.deleteReport(
                      report.id,
                      isOfflineSimulated: appState.isOfflineSimulated,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
