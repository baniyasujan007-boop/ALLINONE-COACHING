import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/app_state.dart';
import '../services/progress_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/lesson_tile.dart';
import 'video_player_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({required this.course, super.key});

  final CourseItem course;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  Future<void> _openFirstLesson(CourseItem course) async {
    if (course.lessons.isEmpty) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          courseTitle: course.title,
          lesson: course.lessons.first,
        ),
      ),
    );
  }

  Future<void> _showCheckout(AppState appState, CourseItem course) async {
    String paymentMethod = 'upi';
    String billingCycle = _defaultBillingCycle(course);
    bool processing = false;
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CoursePricingItem activePricing = _activePricing(course);
    final Map<String, double> cyclePrices = <String, double>{
      'monthly': activePricing.monthly,
      'quarterly': activePricing.quarterly,
      'semiAnnual': activePricing.semiAnnual,
      'yearly': activePricing.yearly,
    };
    final List<MapEntry<String, double>> availableCycles = cyclePrices.entries
        .where((MapEntry<String, double> entry) => entry.value > 0)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double amount = _selectedBillingAmount(course, billingCycle);
            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Complete payment',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pay online to unlock ${course.title} instantly.',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ...availableCycles.map(
                            (MapEntry<String, double> entry) =>
                                _PaymentMethodTile(
                                  title: _billingLabel(entry.key),
                                  subtitle: _planSubtitle(course, entry.key),
                                  value: entry.key,
                                  groupValue: billingCycle,
                                  onChanged: (String value) {
                                    setModalState(() {
                                      billingCycle = value;
                                    });
                                  },
                                ),
                          ),
                          if (availableCycles.isNotEmpty)
                            const SizedBox(height: 8),
                          _PaymentMethodTile(
                            title: 'UPI',
                            subtitle: 'Fast online payment',
                            value: 'upi',
                            groupValue: paymentMethod,
                            onChanged: (String value) {
                              setModalState(() {
                                paymentMethod = value;
                              });
                            },
                          ),
                          _PaymentMethodTile(
                            title: 'Card',
                            subtitle: 'Credit or debit card',
                            value: 'card',
                            groupValue: paymentMethod,
                            onChanged: (String value) {
                              setModalState(() {
                                paymentMethod = value;
                              });
                            },
                          ),
                          _PaymentMethodTile(
                            title: 'Net Banking',
                            subtitle: 'Bank transfer checkout',
                            value: 'bank',
                            groupValue: paymentMethod,
                            onChanged: (String value) {
                              setModalState(() {
                                paymentMethod = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.receipt_long_rounded),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Amount payable',
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rs ${amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label: processing
                                ? 'Processing payment...'
                                : 'Pay Now • Rs ${amount.toStringAsFixed(0)}',
                            icon: Icons.lock_open_rounded,
                            onPressed: processing
                                ? () {}
                                : () async {
                                    setModalState(() {
                                      processing = true;
                                    });
                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 900),
                                    );
                                    final bool ok = await appState
                                        .purchaseCourse(
                                          course.id,
                                          paymentMethod: paymentMethod,
                                          billingCycle: billingCycle,
                                        );
                                    if (!mounted) {
                                      return;
                                    }
                                    if (navigator.canPop()) {
                                      navigator.pop();
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? _successMessageForBillingCycle(
                                                  billingCycle,
                                                )
                                              : appState.authError ??
                                                    'Payment failed',
                                        ),
                                      ),
                                    );
                                    if (ok) {
                                      await _openFirstLesson(course);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _purchaseCourse(AppState appState, CourseItem course) async {
    if (_selectedBillingAmount(course, _defaultBillingCycle(course)) > 0) {
      await _showCheckout(appState, course);
      return;
    }
    final bool ok = await appState.purchaseCourse(course.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (course.price > 0
                    ? 'Course purchased successfully'
                    : 'Course unlocked successfully')
              : appState.authError ?? 'Purchase failed',
        ),
      ),
    );
    if (ok) {
      await _openFirstLesson(course);
    }
  }

  String _defaultBillingCycle(CourseItem course) {
    final CoursePricingItem pricing = _activePricing(course);
    if (pricing.monthly > 0) return 'monthly';
    if (pricing.quarterly > 0) return 'quarterly';
    if (pricing.semiAnnual > 0) return 'semiAnnual';
    if (pricing.yearly > 0) return 'yearly';
    return '';
  }

  double _selectedBillingAmount(CourseItem course, String billingCycle) {
    final CoursePricingItem pricing = _activePricing(course);
    switch (billingCycle) {
      case 'monthly':
        return pricing.monthly;
      case 'quarterly':
        return pricing.quarterly;
      case 'semiAnnual':
        return pricing.semiAnnual;
      case 'yearly':
        return pricing.yearly;
      default:
        return pricing.lowest > 0 ? pricing.lowest : course.price;
    }
  }

  String _billingLabel(String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return 'Monthly Plan';
      case 'quarterly':
        return 'Quarterly Plan';
      case 'semiAnnual':
        return 'Semi-Annual Plan';
      case 'yearly':
        return 'Yearly Plan';
      default:
        return billingCycle;
    }
  }

  String _billingDurationLabel(String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return 'Access for 1 month';
      case 'quarterly':
        return 'Access for 3 months';
      case 'semiAnnual':
        return 'Access for 6 months';
      case 'yearly':
        return 'Access for 12 months';
      default:
        return 'Access starts after payment';
    }
  }

  String _coursePriceLabel(CourseItem course) {
    final CoursePricingItem pricing = _activePricing(course);
    final List<String> plans = <String>[
      if (pricing.monthly > 0)
        'Monthly Rs ${pricing.monthly.toStringAsFixed(0)}',
      if (pricing.quarterly > 0)
        'Quarterly Rs ${pricing.quarterly.toStringAsFixed(0)}',
      if (pricing.semiAnnual > 0)
        'Semi-Annual Rs ${pricing.semiAnnual.toStringAsFixed(0)}',
      if (pricing.yearly > 0) 'Yearly Rs ${pricing.yearly.toStringAsFixed(0)}',
    ];
    if (plans.isNotEmpty) {
      return plans.join(' • ');
    }
    if (course.price <= 0) {
      return 'Free';
    }
    return 'Rs ${course.price.toStringAsFixed(0)}';
  }

  CoursePricingItem _activePricing(CourseItem course) {
    return course.offer.isActive ? course.offer.pricing : course.pricing;
  }

  String _planSubtitle(CourseItem course, String billingCycle) {
    final double activeAmount = _selectedBillingAmount(course, billingCycle);
    final double originalAmount = _originalBillingAmount(course, billingCycle);
    if (!course.offer.isActive ||
        originalAmount <= 0 ||
        activeAmount >= originalAmount) {
      return 'Rs ${activeAmount.toStringAsFixed(0)} • ${_billingDurationLabel(billingCycle)}';
    }
    return 'Offer Rs ${activeAmount.toStringAsFixed(0)} • Was Rs ${originalAmount.toStringAsFixed(0)} • ${_billingDurationLabel(billingCycle)}';
  }

  double _originalBillingAmount(CourseItem course, String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return course.pricing.monthly;
      case 'quarterly':
        return course.pricing.quarterly;
      case 'semiAnnual':
        return course.pricing.semiAnnual;
      case 'yearly':
        return course.pricing.yearly;
      default:
        return course.pricing.lowest > 0 ? course.pricing.lowest : course.price;
    }
  }

  String _offerCountdown(DateTime expiresAt) {
    final Duration remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Offer ended';
    }
    if (remaining.inDays >= 1) {
      return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h left';
    }
    if (remaining.inHours >= 1) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
    }
    return '${remaining.inMinutes}m left';
  }

  String _successMessageForBillingCycle(String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return 'Payment successful. Course unlocked for 1 month.';
      case 'quarterly':
        return 'Payment successful. Course unlocked for 3 months.';
      case 'semiAnnual':
        return 'Payment successful. Course unlocked for 6 months.';
      case 'yearly':
        return 'Payment successful. Course unlocked for 12 months.';
      default:
        return 'Payment successful. Course unlocked.';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final AppState appState = context.read<AppState>();
      await appState.refreshProfile();
      if (!mounted) {
        return;
      }
      await appState.loadCourseDetails(widget.course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    context.watch<ProgressService>();
    final CourseItem course =
        appState.courseById(widget.course.id) ?? widget.course;
    final bool isPurchased = appState.ownsCourse(course.id);
    final bool needsRenewal = appState.hasExpiredCourseAccess(course.id);
    final bool canAccess = !course.isLocked || isPurchased;
    final String? userId = appState.currentUser?.id;
    final Set<String> completedLessonIds = userId == null
        ? <String>{}
        : ProgressService.instance.getProgress(userId).completedLessonIds;
    final int doneLessons = course.lessons
        .where((LessonItem lesson) => completedLessonIds.contains(lesson.id))
        .length;
    final double progressValue = course.lessons.isEmpty
        ? 0
        : doneLessons / course.lessons.length;
    final int progressPercent = (progressValue * 100).round();

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Image.network(
                  course.thumbnail,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.person_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(course.instructor),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(course.rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _InfoChip(
                        icon: Icons.sell_rounded,
                        label: _activePricing(course).lowest > 0
                            ? 'Starts at Rs ${_activePricing(course).lowest.toStringAsFixed(0)}'
                            : course.price <= 0
                            ? 'Free'
                            : 'Rs ${course.price.toStringAsFixed(0)}',
                      ),
                      _InfoChip(
                        icon: canAccess
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        label: canAccess
                            ? 'Unlocked'
                            : needsRenewal
                            ? 'Renewal needed'
                            : 'Locked',
                      ),
                      _InfoChip(
                        icon: Icons.task_alt_rounded,
                        label: '$progressPercent% complete',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (course.offer.isActive && course.offer.expiresAt != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFFFFA93A), Color(0xFFFF6B57)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            course.offer.title.isEmpty
                                ? 'Limited-Time Offer'
                                : course.offer.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _offerCountdown(course.offer.expiresAt!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Course Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progressValue),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _InfoChip(
                              icon: Icons.check_circle_rounded,
                              label:
                                  '$doneLessons / ${course.lessons.length} lessons',
                            ),
                            _InfoChip(
                              icon: Icons.insights_rounded,
                              label: '$progressPercent% finished',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_activePricing(course).lowest > 0) ...<Widget>[
                    Text(
                      _coursePriceLabel(course),
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monthly plan opens the course for 1 month. Renew after expiry to continue access.',
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (course.offer.isActive && course.pricing.lowest > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Regular price: ${CoursePricingItem(monthly: course.pricing.monthly, quarterly: course.pricing.quarterly, semiAnnual: course.pricing.semiAnnual, yearly: course.pricing.yearly).lowest > 0 ? 'Starts at Rs ${course.pricing.lowest.toStringAsFixed(0)}' : 'Rs ${course.price.toStringAsFixed(0)}'}',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  Text(
                    course.description,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Lessons',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (appState.coursesLoading && course.lessons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (course.lessons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No lessons added yet.'),
                    )
                  else
                    ...course.lessons.map(
                      (LessonItem lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Opacity(
                          opacity: canAccess ? 1 : 0.62,
                          child: LessonTile(
                            lesson: lesson,
                            leading: Checkbox(
                              value: completedLessonIds.contains(lesson.id),
                              onChanged: !canAccess || userId == null
                                  ? null
                                  : (_) {
                                      ProgressService.instance
                                          .toggleLessonComplete(
                                            userId: userId,
                                            lessonId: lesson.id,
                                          );
                                    },
                            ),
                            titleSuffix: completedLessonIds.contains(lesson.id)
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: !canAccess
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Purchase this course to unlock lessons.',
                                        ),
                                      ),
                                    );
                                  }
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => VideoPlayerScreen(
                                        courseTitle: course.title,
                                        lesson: lesson,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (!canAccess)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'This course is locked',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedBillingAmount(
                                      course,
                                      _defaultBillingCycle(course),
                                    ) >
                                    0
                                ? needsRenewal
                                      ? 'Your previous plan has ended. Renew to unlock all lessons again.'
                                      : 'Make an online payment to unlock all lessons instantly.'
                                : 'Ask admin to unlock this course or enroll to continue.',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: canAccess
                        ? 'Start Learning'
                        : _selectedBillingAmount(
                                course,
                                _defaultBillingCycle(course),
                              ) <=
                              0
                        ? 'Unlock Course'
                        : needsRenewal
                        ? 'Renew Course'
                        : course.offer.isActive
                        ? 'Choose Offer Plan'
                        : 'Choose Plan & Pay',
                    icon: canAccess
                        ? Icons.play_circle_fill_rounded
                        : Icons.shopping_bag_rounded,
                    onPressed: appState.authLoading
                        ? () {}
                        : !canAccess
                        ? () => _purchaseCourse(appState, course)
                        : course.lessons.isEmpty
                        ? () {}
                        : () => _openFirstLesson(course),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 1.8 : 1,
          ),
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
