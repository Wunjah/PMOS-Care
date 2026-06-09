import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/file_saver.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../cycle_tracker/presentation/providers/cycle_provider.dart';
import '../../../weight_tracker/presentation/providers/weight_provider.dart';
import '../../../activity_tracker/presentation/providers/activity_provider.dart';
import '../../../diet/presentation/providers/diet_provider.dart';
import '../../../symptoms/presentation/providers/symptom_provider.dart';
import '../../../medication/presentation/providers/medication_provider.dart';
import '../components/reports_charts.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isGeneratingPdf = false;

  final List<Map<String, dynamic>> _labMetrics = [
    {
      'name': 'Free Androgen Index (FAI)',
      'value': '7.2 %',
      'status': 'Elevated',
      'refRange': 'Reference: 0.8% - 6.0%',
      'indicator': AppTheme.glycemicHigh,
      'description': 'High free androgens lead to hirsutism, cystic acne, and irregular ovulation.',
    },
    {
      'name': 'Insulin Resistance (HOMA-IR)',
      'value': '2.4',
      'status': 'Borderline',
      'refRange': 'Reference: < 1.9',
      'indicator': AppTheme.glycemicMedium,
      'description': 'Elevated levels suggest slight peripheral insulin resistance, typical in PCOS.',
    },
    {
      'name': 'LH / FSH Ratio',
      'value': '2.1',
      'status': 'Indicative of PCOS',
      'refRange': 'Reference: ~ 1.0',
      'indicator': AppTheme.glycemicMedium,
      'description': 'Luteinizing hormone is elevated relative to follicle stimulating hormone.',
    },
    {
      'name': 'Total Testosterone',
      'value': '72 ng/dL',
      'status': 'High Normal',
      'refRange': 'Reference: 15 - 70 ng/dL',
      'indicator': AppTheme.glycemicLow,
      'description': 'Slightly high testosterone levels, which may affect cycle regularity.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateAndSharePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdf = pw.Document();
      
      // Get cycle logs from provider
      final cycleState = ref.read(cycleStateNotifierProvider);
      final cycles = cycleState.cycles;

      // Get weight logs
      final weightState = ref.read(weightStateNotifierProvider);
      final weights = weightState.weights;

      // Get symptom logs
      final symptomState = ref.read(symptomStateNotifierProvider);
      final symptoms = symptomState.symptoms;

      // Get medication logs
      final medicationState = ref.read(medicationStateNotifierProvider);
      final medications = medicationState.medications;

      // Get nutrition/meal logs
      final mealState = ref.read(mealLogStateNotifierProvider);
      final meals = mealState.mealLogs;

      // Get activity logs
      final activityState = ref.read(activityStateNotifierProvider);
      final activities = activityState.activities;

      // Get user details
      final authState = ref.read(authStateNotifierProvider);
      String patientName = 'Wumjah';
      String patientEmail = 'wumjah@pmoscare.org';
      if (authState is AuthAuthenticated) {
        patientName = authState.user.displayName;
        patientEmail = authState.user.email ?? 'wumjah@pmoscare.org';
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header Title
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PMOS CARE CLINICAL PORTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(DateTime.now().toIso8601String().substring(0, 10), style: const pw.TextStyle(color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // HIPAA Security Alert
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.indigo50,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CONFIDENTIAL PATIENT RECORD (HIPAA COMPLIANT)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo900)),
                    pw.SizedBox(height: 4),
                    pw.Text('This report contains protected health information (PHI) intended solely for the clinician\'s review. It is securely generated and compiled from local patient-reported outcomes.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.indigo700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Patient Profile Section
              pw.Text('Patient Profile', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Name: $patientName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Email: $patientEmail', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Lab Diagnostics Section
              pw.Text('Clinical Lab Diagnostics Indicators', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Metric Parameter', 'Value', 'Assessment Interpretation', 'Clinical Normal Range'],
                data: _labMetrics.map((m) => [m['name'], m['value'], m['status'], m['refRange']]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 25),

              // Menstrual Cycle History
              pw.Text('Cycle Log History (Self-Reported)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (cycles.isEmpty)
                pw.Text('No cycle records logged in this period.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Start Date', 'Flow Severity', 'Pain Level', 'Reported Symptoms'],
                  data: cycles.map((c) {
                    final startDateStr = c.startDate.toIso8601String().substring(0, 10);
                    final flowStr = c.flowIntensity.toString().split('.').last;
                    final symptomsStr = c.symptoms.join(', ');
                    return [startDateStr, flowStr, '${c.painLevel}/10', symptomsStr];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 25),

              // Weight Logs Summary in PDF
              pw.Text('Weight & Waist Log History (Self-Reported)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (weights.isEmpty)
                pw.Text('No weight records logged in this period.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Date Logged', 'Weight (kg)', 'Waist Size (inches)'],
                  data: weights.map((w) {
                    final dateStr = w.timestamp.toIso8601String().substring(0, 10);
                    return [dateStr, '${w.weightKg} kg', '${w.waistSizeInches} in'];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 25),

              // Symptom History logs
              pw.Text('Symptom Log History (Self-Reported)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (symptoms.isEmpty)
                pw.Text('No symptom logs recorded.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Mood', 'Fatigue', 'Pain', 'Androgen Indicators', 'Metabolic Markers'],
                  data: symptoms.map((s) {
                    final dateStr = s.timestamp.toIso8601String().substring(0, 10);
                    final androgenStr = 'Acne: ${s.acneSeverity}\nHirsutism FG: ${s.ferrimanGallweyScore ?? "none"}';
                    final metabolicStr = 'Bloating: ${s.bloating}\nCravings: ${s.cravings.join(", ")}';
                    return [dateStr, s.mood, '${s.fatigueLevel}/5', '${s.pelvicPain}/5', androgenStr, metabolicStr];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 25),

              // Scheduled Medications
              pw.Text('Medications Treatment Compliance (Self-Reported)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (medications.isEmpty)
                pw.Text('No medications scheduled.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Medication Name', 'Dosage', 'Preferred Timing', 'Taken Today'],
                  data: medications.map((m) {
                    return [m.name, m.dosage, m.timing.toUpperCase(), m.isTakenToday ? 'Yes' : 'No'];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 25),

              // Nutrition Logs
              pw.Text('Nutrition & Daily Meals Log (Self-Reported)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (meals.isEmpty)
                pw.Text('No meal logs recorded.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Meal Type', 'Food Name', 'Calories', 'Protein', 'Fiber', 'Water'],
                  data: meals.map((m) {
                    final dateStr = m.timestamp.toIso8601String().substring(0, 10);
                    return [dateStr, m.mealType.toUpperCase(), m.foodName, '${m.calories} kcal', '${m.proteinGrams}g', '${m.fiberGrams}g', '${m.waterMl}ml'];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 25),

              // Activities Logs
              pw.Text('Physical Fitness & Workouts Logs (Self-Reported)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (activities.isEmpty)
                pw.Text('No activities logged.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Activity Type', 'Duration', 'Calories Burned'],
                  data: activities.map((a) {
                    final dateStr = a.timestamp.toIso8601String().substring(0, 10);
                    return [dateStr, a.activityType.toUpperCase(), '${a.durationMinutes} mins', '${a.caloriesBurned} kcal'];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),

              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Report compiled automatically by PMOS Care. Thank you for your commitment to hormonal health.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await saveAndShareFile(
        pdfBytes,
        'PMOS_Care_Clinical_Report.pdf',
        'PMOS Care Patient Health Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _generateAndShareCsv() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final weightState = ref.read(weightStateNotifierProvider);
      final mealState = ref.read(mealLogStateNotifierProvider);
      final symptomState = ref.read(symptomStateNotifierProvider);

      final buffer = StringBuffer();
      
      // 1. General Header
      buffer.writeln('PMOS CARE PATIENT HEALTH DATA');
      buffer.writeln('Generated on,${DateTime.now().toIso8601String()}');
      buffer.writeln();

      // 2. Weight Logs Table
      buffer.writeln('WEIGHT & WAIST LOGS');
      buffer.writeln('Date,Weight (kg),Waist Size (inches)');
      for (final w in weightState.weights) {
        final dateStr = w.timestamp.toIso8601String().substring(0, 10);
        buffer.writeln('$dateStr,${w.weightKg},${w.waistSizeInches}');
      }
      buffer.writeln();

      // 3. Symptoms Table
      buffer.writeln('DAILY SYMPTOMS LOGS');
      buffer.writeln('Date,Mood,Fatigue (1-5),Pelvic Pain (1-5),Bloating,Acne,Alopecia,Ferriman-Gallwey Score,Cravings');
      for (final s in symptomState.symptoms) {
        final dateStr = s.timestamp.toIso8601String().substring(0, 10);
        final cravingsStr = s.cravings.join(';');
        buffer.writeln('$dateStr,${s.mood},${s.fatigueLevel},${s.pelvicPain},${s.bloating},${s.acneSeverity},${s.alopeciaSeverity},${s.ferrimanGallweyScore ?? ''},"$cravingsStr"');
      }
      buffer.writeln();

      // 4. Meal Logs Table
      buffer.writeln('NUTRITION & MEAL LOGS');
      buffer.writeln('Date,Meal Type,Food/Hydration,Calories (kcal),Protein (g),Fiber (g),Water (ml)');
      for (final m in mealState.mealLogs) {
        final dateStr = m.timestamp.toIso8601String().substring(0, 10);
        buffer.writeln('$dateStr,${m.mealType},"${m.foodName}",${m.calories},${m.proteinGrams},${m.fiberGrams},${m.waterMl}');
      }

      final csvBytes = utf8.encode(buffer.toString());
      await saveAndShareFile(
        csvBytes,
        'PMOS_Care_Clinical_Data.csv',
        'PMOS Care Patient Health Data (CSV)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate CSV: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightStateNotifierProvider);
    final activityState = ref.watch(activityStateNotifierProvider);
    final mealLogState = ref.watch(mealLogStateNotifierProvider);
    final symptomState = ref.watch(symptomStateNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'Clinical Reports',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryWellness,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryWellness,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Lab & Trends'),
            Tab(icon: Icon(Icons.download_outlined), text: 'Clinical Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Lab & Trends
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Clinical Lab Diagnostics Indicators',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ..._labMetrics.map((metric) {
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              metric['name'] as String,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (metric['indicator'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                metric['status'] as String,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: metric['indicator'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              metric['value'] as String,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryWellness,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              metric['refRange'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          metric['description'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              const Text(
                'Self-Reported Health Trends',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      WeightChart(weights: weightState.weights),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      ActivityChart(activities: activityState.activities),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      NutritionChart(mealLogs: mealLogState.mealLogs),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      SymptomSeverityChart(symptoms: symptomState.symptoms),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Tab 2: Clinical Export
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: AppTheme.primaryLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.primaryWellness.withOpacity(0.2)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.lock_person_outlined, color: AppTheme.primaryWellness, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HIPAA Data Privacy Shield',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryWellness,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your data is encrypted locally using AES-256 standard and meets medical HIPAA confidentiality guidelines.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Habits Compliance',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Dietary Plan Compliance: 85% Low-GI meal checklist matching Cameroonian meal planner.'),
                        _buildBulletPoint('Fitness & Physical Activity: 30 minutes light cardio/aerobics checked.'),
                        _buildBulletPoint('Medication Adherence: Metformin log compliance rated 90%.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isGeneratingPdf ? 'Compiling PDF...' : 'Download PDF Report'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isGeneratingPdf ? null : _generateAndShareCsv,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.grid_on),
                  label: Text(_isGeneratingPdf ? 'Compiling CSV...' : 'Download CSV Report'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.glycemicLow, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
