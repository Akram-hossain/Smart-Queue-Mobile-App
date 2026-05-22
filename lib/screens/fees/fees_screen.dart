import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../models/semester_fee.dart';
import '../../providers/fee_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/date_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/section_header.dart';

final _money = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(feesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Semester fees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.feeNew),
        icon: const Icon(Icons.add),
        label: const Text('New record'),
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppPadding.lg),
          child: LoadingSkeleton(),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load fees',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(feesProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No fee records yet',
              message:
                  'Add your semester fee to track paid, due and deadlines.',
              actionLabel: 'Add record',
              onAction: () => context.push(AppRoutes.feeNew),
            );
          }
          final total = items.fold<double>(0, (s, f) => s + f.totalFee);
          final paid = items.fold<double>(0, (s, f) => s + f.paidAmount);
          final due = (total - paid).clamp(0, double.infinity).toDouble();
          final unpaid = items.where((f) => !f.isPaid).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          return RefreshIndicator(
            onRefresh: () => ref.read(feesProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppPadding.lg),
              children: [
                GradientCard(
                  colors: const [AppColors.warning, AppColors.accent],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total due',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        _money.format(due),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : (paid / total).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _Mini(label: 'Paid', value: _money.format(paid)),
                          ),
                          Expanded(
                            child: _Mini(label: 'Total', value: _money.format(total)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (unpaid.isNotEmpty) ...[
                  const SizedBox(height: AppPadding.lg),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Next payment: ${_money.format(unpaid.first.dueAmount)} for ${unpaid.first.semesterLabel} by ${DateFmt.shortDate(unpaid.first.dueDate)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppPadding.lg),
                SectionHeader(
                  title: 'All records',
                  subtitle: '${items.length} entries',
                ),
                const SizedBox(height: AppPadding.sm + 4),
                ...items.map((f) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppPadding.sm + 4),
                      child: _FeeCard(item: f),
                    )),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}

class _FeeCard extends ConsumerWidget {
  const _FeeCard({required this.item});
  final SemesterFee item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paidColor = item.isPaid
        ? AppColors.success
        : (item.isOverdue ? AppColors.danger : AppColors.warning);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push(AppRoutes.feeNew, extra: item),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.semesterLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: paidColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.isPaid
                          ? 'Paid'
                          : (item.isOverdue ? 'Overdue' : 'Due'),
                      style: TextStyle(
                        color: paidColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: item.paidRatio.toDouble(),
                  minHeight: 8,
                  backgroundColor: paidColor.withOpacity(0.15),
                  color: paidColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Paid ${_money.format(item.paidAmount)} of ${_money.format(item.totalFee)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'by ${DateFmt.shortDate(item.dueDate)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: item.isOverdue
                          ? AppColors.danger
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (item.paymentNote != null && item.paymentNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.paymentNote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
