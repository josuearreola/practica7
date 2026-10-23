import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_role.dart';
import '../models/test_case.dart';
import '../providers/app_state_provider.dart';
import '../providers/incident_provider.dart';
import '../providers/test_matrix_provider.dart';

class TestMatrixView extends StatelessWidget {
  const TestMatrixView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentRole = appState.currentRole;

    // Requirement: "comprobación en tiempo real solo para el administrador y el agente"
    if (!currentRole.canAccessTestMatrix) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 48, color: Color(0xFFF87171)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Acceso Restringido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'La comprobación de la Matriz de Pruebas en tiempo real está habilitada EXCLUSIVAMENTE para el Administrador y el Agente de Atención.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appState.setRole(AppRole.admin),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Conmutar a Administrador para auditar'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              ),
            ],
          ),
        ),
      );
    }

    final testMatrix = context.watch<TestMatrixProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final tests = testMatrix.testCases;

    final passedCount = tests.where((t) => t.status == TestStatus.aprobado).length;
    final totalCount = tests.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: Color(0xFF34D399), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Matriz de Pruebas en Tiempo Real (TC01 - TC08)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprobación basada en casos de reporte de fallas, accesos perdidos y persistencia.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                // Progress stats pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$passedCount / $totalCount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                      ),
                      const Text(
                        'Casos Aprobados',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Run all tests button
                ElevatedButton.icon(
                  onPressed: testMatrix.isRunningAll
                      ? null
                      : () => testMatrix.runAllTests(incidentProvider),
                  icon: testMatrix.isRunningAll
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(testMatrix.isRunningAll ? 'Ejecutando...' : 'Ejecutar Toda la Matriz'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                // Export report button
                OutlinedButton.icon(
                  onPressed: () {
                    final report = testMatrix.generateExportableReport();
                    Clipboard.setData(ClipboardData(text: report));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informe en Markdown copiado al portapapeles.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text('Exportar'),
                ),
                const SizedBox(width: 8),
                // Reset matrix
                IconButton(
                  tooltip: 'Reiniciar resultados de la matriz',
                  icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => testMatrix.resetMatrix(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Test Cases Cards / Rows
          ...tests.map((tc) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF131B2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: tc.status == TestStatus.aprobado
                      ? const Color(0xFF10B981).withOpacity(0.5)
                      : tc.status == TestStatus.fallido
                          ? const Color(0xFFEF4444).withOpacity(0.5)
                          : const Color(0xFF334155),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Code, Name, Status chip, Run button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            tc.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tc.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Spacer(),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tc.status.color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tc.status.color.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tc.status.icon, size: 14, color: tc.status.color),
                              const SizedBox(width: 6),
                              Text(
                                tc.status.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: tc.status.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Individual run test button
                        ElevatedButton.icon(
                          onPressed: () => testMatrix.runTestCase(tc.code, incidentProvider),
                          icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                          label: const Text('Probar Caso', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Acción y Esperado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Acción: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                              Expanded(
                                child: Text(tc.action, style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Esperado: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                              Expanded(
                                child: Text(tc.expected, style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Observaciones
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.comment_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        const Text(
                          'Observaciones: ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        Expanded(
                          child: Text(
                            tc.observations,
                            style: TextStyle(
                              fontSize: 12,
                              color: tc.status == TestStatus.aprobado
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        if (tc.executedAt != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Ejecutado: ${tc.formattedExecutedAt}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
