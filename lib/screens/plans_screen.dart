import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/reading_plans.dart';
import '../constants/theme.dart';
import '../models/reading_plan.dart';
import '../providers/chat_provider.dart';
import 'plan_detail_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    // Combine predefined + custom plans
    final allPlans = [
      ...kReadingPlans,
      ...provider.customPlans.map((c) => c.toReadingPlan()),
    ];

    // Separate active and available plans
    final activePlanIds =
        provider.planProgress.map((p) => p.planId).toSet();
    final activePlans =
        allPlans.where((p) => activePlanIds.contains(p.id)).toList();
    final availablePlans =
        allPlans.where((p) => !activePlanIds.contains(p.id)).toList();

    // Track which are custom
    final customPlanIds = provider.customPlans.map((c) => c.id).toSet();

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lesepläne',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Create plan button
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                provider.startPlanCreatorChat();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFCE93D8),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Color(0xFF7E57C2), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eigenen Plan erstellen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7E57C2),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'KI erstellt einen Plan nach deinen Bedürfnissen',
                            style: TextStyle(
                                fontSize: 13, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 20, color: kTextSecondary),
                  ],
                ),
              ),
            ),
          ),

          // Active plans
          if (activePlans.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Text(
                'AKTIVE PLÄNE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: kTextSecondary,
                ),
              ),
            ),
            ...activePlans.map((plan) {
              final progress = provider.getPlanProgress(plan.id)!;
              progress.setTotalDays(plan.totalDays);
              final completed = progress.completedDays.length;
              final percent = completed / plan.totalDays;
              final isCustom = customPlanIds.contains(plan.id);

              return _PlanCard(
                plan: plan,
                subtitle: '$completed von ${plan.totalDays} Tagen',
                progress: percent,
                onTap: () => _openPlan(context, plan),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz,
                      size: 18, color: kTextSecondary),
                  onPressed: () => _showPlanMenu(
                      context, provider, plan, isCustom: isCustom),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Available plans
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Text(
              'VERFÜGBARE PLÄNE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: kTextSecondary,
              ),
            ),
          ),
          if (availablePlans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Alle Pläne sind bereits aktiv!',
                style: TextStyle(color: kTextSecondary),
              ),
            )
          else
            ...availablePlans.map((plan) => _PlanCard(
                  plan: plan,
                  subtitle: '${plan.totalDays} Tage',
                  onTap: () => _confirmStart(context, provider, plan),
                )),
        ],
      ),
    );
  }

  void _openPlan(BuildContext context, ReadingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
    );
  }

  void _confirmStart(
      BuildContext context, ChatProvider provider, ReadingPlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.icon}  ${plan.title}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style:
                        const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow, color: Color(0xFF43A047)),
              ),
              title: const Text('Plan starten'),
              subtitle: Text('${plan.totalDays} Tage ab heute'),
              onTap: () {
                provider.startPlan(plan.id, plan.totalDays);
                Navigator.pop(context);
                _openPlan(context, plan);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlanMenu(
      BuildContext context, ChatProvider provider, ReadingPlan plan,
      {bool isCustom = false}) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Plan öffnen'),
              onTap: () {
                Navigator.pop(context);
                _openPlan(context, plan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('Neu starten',
                  style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                provider.startPlan(plan.id, plan.totalDays);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                  isCustom ? 'Plan löschen' : 'Plan entfernen',
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                if (isCustom) {
                  provider.deleteCustomPlan(plan.id);
                } else {
                  provider.removePlan(plan.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ReadingPlan plan;
  final String subtitle;
  final double? progress;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PlanCard({
    required this.plan,
    required this.subtitle,
    required this.onTap,
    this.progress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                ?trailing,
                if (trailing == null)
                  const Icon(Icons.chevron_right,
                      size: 20, color: kTextSecondary),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress!,
                  backgroundColor: kDivider,
                  color: kAccentBlue,
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
