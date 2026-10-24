import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_role.dart';
import '../models/incident_report.dart';
import '../providers/app_state_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/create_case_dialog.dart';

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF475569)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF38BDF8)),
                  SizedBox(width: 10),
                  Text('Consultar Reporte por ID (TC06)', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Prueba de validación: consultar un ID que no existe en el sistema para comprobar que no se bloquee la aplicación.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'ID del reporte a consultar',
                        hintText: 'ej. REP999 o ID personalizado',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
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
                                  'Documento "${searchCtrl.text}" no encontrado. La aplicación gestionó el resultado vacío correctamente sin bloquearse (TC06 Aprobado).',
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
                              Text('Equipo: ${foundReport!.equipment}',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                              Text('Prioridad: ${foundReport!.priority.displayName}',
                                  style: TextStyle(color: foundReport!.priority.color, fontSize: 12)),
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
                  child: const Text('Cerrar', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Change priority dialog (TC04)
  void _changePriorityDialog(BuildContext context, IncidentReport report, IncidentProvider provider) {
    IncidentPriority newPriority = report.priority;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Actualizar Prioridad: ${report.id}',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seleccione la nueva prioridad para este caso (Validación TC04):',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<IncidentPriority>(
                    value: newPriority,
                    dropdownColor: const Color(0xFF0F172A),
                    items: IncidentPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(p.displayName, style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => newPriority = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: () async {
                    final res = await provider.updateReportPriority(report.id, newPriority);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar Cambio'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete case dialog (TC05)
  void _confirmDeleteReport(BuildContext context, IncidentReport report, IncidentProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Text('Eliminar Caso ${report.id}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            '¿Está seguro de eliminar este reporte de forma permanente? Se validará la eliminación (TC05).',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                final res = await provider.deleteReport(report.id);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
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

    final fallasCount = allReports.where((r) => r.category == IncidentCategory.reporteFallas).length;
    final accesosCount = allReports.where((r) => r.category == IncidentCategory.solucionAccesosPerdidos).length;
    final atencionCount = allReports.where((r) => r.category == IncidentCategory.procesoAtencion).length;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19),
      ),
      child: Column(
        children: [
          // Top Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Casos e Incidentes',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Todo redactado desde cero por el usuario',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),

                // Button: Search ID (TC06)
                Tooltip(
                  message: 'Comprobar búsqueda por ID inexistente (TC06)',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    onPressed: () => _searchReportDialog(context),
                    icon: const Icon(Icons.search_rounded, size: 14, color: Color(0xFF38BDF8)),
                    label: const Text('Buscar ID', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                  ),
                ),

                const SizedBox(width: 8),

                // Button: Redactar Nuevo Caso
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.add, size: 16),
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
              ],
            ),
          ),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos (${allReports.length})', null, _selectedCategory == null),
                  const SizedBox(width: 6),
                  _buildFilterChip('Fallas ($fallasCount)', IncidentCategory.reporteFallas,
                      _selectedCategory == IncidentCategory.reporteFallas),
                  const SizedBox(width: 6),
                  _buildFilterChip('Accesos ($accesosCount)', IncidentCategory.solucionAccesosPerdidos,
                      _selectedCategory == IncidentCategory.solucionAccesosPerdidos),
                  const SizedBox(width: 6),
                  _buildFilterChip('Atención ($atencionCount)', IncidentCategory.procesoAtencion,
                      _selectedCategory == IncidentCategory.procesoAtencion),
                ],
              ),
            ),
          ),

          // Incident Cards List
          Expanded(
            child: allReports.isEmpty
                ? _buildEmptyState(context, currentRole)
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No hay casos en la categoría seleccionada.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final report = filtered[index];
                          return _buildReportCard(context, report, incidentProvider, appState);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IncidentCategory? category, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppRole currentRole) {
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
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_add, size: 48, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin Casos Pre-generados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'El panel está limpio. No hay tickets automáticos ni falsos.\n'
                'Cada dispositivo y usuario redacta sus propios casos de falla, solicitudes de acceso o procesos de atención.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const CreateCaseDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Redactar Mi Primer Caso Ahora'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    IncidentReport report,
    IncidentProvider incidentProvider,
    AppStateProvider appState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: report.isDirectToAdmin
              ? const Color(0xFFEF4444).withOpacity(0.6)
              : const Color(0xFF1E293B),
          width: report.isDirectToAdmin ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: ID, Category, Priority, Direct badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    report.id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(report.category.icon, size: 14, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  report.category.displayName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Priority Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: report.priority.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: report.priority.color.withOpacity(0.5)),
                  ),
                  child: Text(
                    report.priority.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: report.priority.color,
                    ),
                  ),
                ),
                if (report.isDirectToAdmin) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DIRECTO ADMIN',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 6),

            // Equipment
            Row(
              children: [
                const Icon(Icons.computer_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Equipo: ${report.equipment}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Description
            Text(
              report.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.35),
            ),

            const SizedBox(height: 10),

            // Assigned to and Reporter
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Reportado por: ${report.reportedByRole.shortDeviceName}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const Text('•', style: TextStyle(color: Color(0xFF475569))),
                Text(
                  'Asignado a: ${report.assignedRole.shortDeviceName}',
                  style: TextStyle(fontSize: 11, color: report.assignedRole.primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 8),

            // Actions: Status update, Priority update, Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: report.status.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.status.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: report.status.color),
                  ),
                ),

                Row(
                  children: [
                    // Status advancement button
                    if (report.status == IncidentStatus.abierto)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          foregroundColor: const Color(0xFF38BDF8),
                        ),
                        onPressed: () => incidentProvider.updateReportStatus(report.id, IncidentStatus.enAtencion),
                        child: const Text('Atender', style: TextStyle(fontSize: 11)),
                      )
                    else if (report.status == IncidentStatus.enAtencion)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          foregroundColor: const Color(0xFF10B981),
                        ),
                        onPressed: () => incidentProvider.updateReportStatus(report.id, IncidentStatus.resuelto),
                        child: const Text('Resolver', style: TextStyle(fontSize: 11)),
                      ),

                    // Priority button (TC04)
                    Tooltip(
                      message: 'Cambiar prioridad (TC04)',
                      child: IconButton(
                        icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFFBBF24)),
                        onPressed: () => _changePriorityDialog(context, report, incidentProvider),
                      ),
                    ),

                    // Delete button (TC05)
                    Tooltip(
                      message: 'Eliminar caso (TC05)',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        onPressed: () => _confirmDeleteReport(context, report, incidentProvider),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
