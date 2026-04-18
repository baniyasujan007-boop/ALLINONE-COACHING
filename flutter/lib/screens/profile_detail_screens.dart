import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/course_model.dart';
import '../providers/app_state.dart';
import '../services/progress_service.dart';

class CompletedCoursesScreen extends StatelessWidget {
  const CompletedCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ProgressService>();
    final AppState appState = context.watch<AppState>();
    final String? userId = appState.currentUser?.id;
    final Set<String> completedLessonIds = userId == null
        ? <String>{}
        : ProgressService.instance.getProgress(userId).completedLessonIds;

    final List<CourseItem> completedCourses = appState.courses.where((
      CourseItem course,
    ) {
      if (course.lessons.isEmpty) {
        return false;
      }
      final int doneCount = course.lessons
          .where((LessonItem lesson) => completedLessonIds.contains(lesson.id))
          .length;
      return doneCount == course.lessons.length;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Completed Courses')),
      body: completedCourses.isEmpty
          ? const Center(child: Text('No completed courses yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: completedCourses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final CourseItem course = completedCourses[index];
                return ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(course.thumbnail),
                  ),
                  title: Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${course.lessons.length} / ${course.lessons.length} lessons',
                  ),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                );
              },
            ),
    );
  }
}

class TotalPaidScreen extends StatelessWidget {
  const TotalPaidScreen({super.key, required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    final double totalPaid = payments.fold(
      0,
      (double total, PaymentRecord item) => total + item.amount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Total Paid')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Amount You Have Paid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs ${totalPaid.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${payments.length} payment record(s)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key, required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: payments.isEmpty
          ? const Center(child: Text('No payment history yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final PaymentRecord payment = payments[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.receipt_long_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              payment.courseTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (payment.billingCycle.isNotEmpty)
                                  _formatBillingCycle(payment.billingCycle),
                                payment.paymentMethod.toUpperCase(),
                                payment.status,
                              ].join(' • '),
                            ),
                            if (payment.paidAt.isNotEmpty)
                              Text(
                                payment.paidAt,
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 12,
                                ),
                              ),
                            if (payment.accessExpiresAt != null)
                              Text(
                                payment.accessExpiresAt!.isAfter(DateTime.now())
                                    ? 'Access until ${payment.accessExpiresAt!.toLocal()}'
                                    : 'Access expired on ${payment.accessExpiresAt!.toLocal()}',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
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
}
