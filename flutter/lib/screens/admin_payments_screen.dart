import 'package:flutter/material.dart';

import '../models/admin_user.dart';
import '../services/auth_service.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/glass_card.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  bool _loading = false;
  String? _error;
  List<_PaymentRow> _payments = <_PaymentRow>[];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<AdminUser> users = await AuthService.instance
          .getUsersForAdmin();
      final List<_PaymentRow> payments = <_PaymentRow>[];
      for (final AdminUser user in users) {
        for (final AdminPaymentRecord payment in user.paymentHistory) {
          if (payment.amount <= 0) {
            continue;
          }
          payments.add(
            _PaymentRow(
              userName: user.name,
              userEmail: user.email,
              payment: payment,
            ),
          );
        }
      }
      payments.sort(
        (_PaymentRow a, _PaymentRow b) =>
            b.payment.paidAt.compareTo(a.payment.paidAt),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final double totalRevenue = _payments.fold(
      0,
      (double total, _PaymentRow item) => total + item.payment.amount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Payments Overview')),
      body: AnimatedGradientBackground(
        dark: dark,
        child: RefreshIndicator(
          onRefresh: _loadPayments,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ListView(
                  children: <Widget>[
                    const SizedBox(height: 180),
                    Center(child: Text(_error!)),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Revenue',
                            value: 'Rs ${totalRevenue.toStringAsFixed(0)}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Payments',
                            value: '${_payments.length}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_payments.isEmpty)
                      const GlassCard(child: Text('No payments recorded yet.'))
                    else
                      ..._payments.map(
                        (_PaymentRow row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        row.payment.courseTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Rs ${row.payment.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('${row.userName} • ${row.userEmail}'),
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    'Method: ${row.payment.paymentMethod.toUpperCase()}',
                                    if (row.payment.billingCycle.isNotEmpty)
                                      'Plan: ${_formatBillingCycle(row.payment.billingCycle)}',
                                    'Status: ${row.payment.status}',
                                  ].join(' • '),
                                ),
                                if (row.payment.paidAt.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text('Paid at: ${row.payment.paidAt}'),
                                ],
                                if (row.payment.accessExpiresAt !=
                                    null) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text(
                                    row.payment.accessExpiresAt!.isAfter(
                                          DateTime.now(),
                                        )
                                        ? 'Access until: ${row.payment.accessExpiresAt!.toLocal()}'
                                        : 'Access expired: ${row.payment.accessExpiresAt!.toLocal()}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow {
  const _PaymentRow({
    required this.userName,
    required this.userEmail,
    required this.payment,
  });

  final String userName;
  final String userEmail;
  final AdminPaymentRecord payment;
}

String _formatBillingCycle(String billingCycle) {
  switch (billingCycle) {
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Quarterly';
    case 'semiAnnual':
      return 'Semi-Annual';
    case 'yearly':
      return 'Yearly';
    default:
      return billingCycle;
  }
}
