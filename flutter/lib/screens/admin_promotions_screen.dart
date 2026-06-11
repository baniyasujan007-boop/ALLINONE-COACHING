import 'package:flutter/material.dart';

import '../models/promotion.dart';
import '../services/promotion_service.dart';
import '../utils/edit_flow.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/glass_card.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = false;
  String? _error;
  PromotionsAdminOverview _overview = const PromotionsAdminOverview();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PromotionsAdminOverview overview = await PromotionService.instance
          .getAdminOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _saveCoupon([CouponAdminItem? coupon]) async {
    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _CouponDialog(
        coupon: coupon,
        onSubmit: (Map<String, dynamic> data) async {
          if (coupon == null) {
            await PromotionService.instance.createCoupon(data);
          } else {
            await PromotionService.instance.updateCoupon(coupon.id, data);
          }
        },
      ),
    );
    if (updated == true && mounted) {
      await _load();
    }
  }

  Future<void> _deleteCoupon(CouponAdminItem coupon) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Delete ${coupon.code}?'),
            content: const Text('This removes the coupon for future checkout.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    try {
      await PromotionService.instance.deleteCoupon(coupon.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<bool> _saveReferralSettings(ReferralSettings settings) async {
    try {
      await PromotionService.instance.updateReferralSettings(settings);
      await _load();
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated successfully')));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons & Referrals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.local_offer_rounded), text: 'Coupons'),
            Tab(icon: Icon(Icons.group_add_rounded), text: 'Rules'),
            Tab(icon: Icon(Icons.timeline_rounded), text: 'Tracking'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _saveCoupon(),
              icon: const Icon(Icons.add),
              label: const Text('Coupon'),
            )
          : null,
      body: AnimatedGradientBackground(
        dark: dark,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _CouponsTab(
                    coupons: _overview.coupons,
                    onEdit: _saveCoupon,
                    onDelete: _deleteCoupon,
                  ),
                  _ReferralRulesTab(
                    settings: _overview.referralSettings,
                    onSave: _saveReferralSettings,
                  ),
                  _ReferralTrackingTab(events: _overview.referralEvents),
                ],
              ),
      ),
    );
  }
}

class _CouponsTab extends StatelessWidget {
  const _CouponsTab({
    required this.coupons,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CouponAdminItem> coupons;
  final ValueChanged<CouponAdminItem> onEdit;
  final ValueChanged<CouponAdminItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return const Center(child: Text('No coupons yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final CouponAdminItem coupon = coupons[index];
        final String reward = coupon.type == 'percent'
            ? '${coupon.value.toStringAsFixed(0)}%'
            : 'Rs ${coupon.value.toStringAsFixed(0)}';
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      coupon.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Switch(
                    value: coupon.isActive,
                    onChanged: (_) => onEdit(coupon),
                  ),
                  IconButton(
                    onPressed: () => onEdit(coupon),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    onPressed: () => onDelete(coupon),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  reward,
                  'Used ${coupon.usageCount}/${coupon.maxRedemptions == 0 ? 'Unlimited' : coupon.maxRedemptions}',
                  'User limit ${coupon.perUserLimit == 0 ? 'Unlimited' : coupon.perUserLimit}',
                  if (coupon.minOrderAmount > 0)
                    'Min Rs ${coupon.minOrderAmount.toStringAsFixed(0)}',
                ].join(' • '),
              ),
              if (coupon.expiresAt != null) ...<Widget>[
                const SizedBox(height: 4),
                Text('Expires ${coupon.expiresAt!.toLocal()}'),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReferralRulesTab extends StatefulWidget {
  const _ReferralRulesTab({required this.settings, required this.onSave});

  final ReferralSettings settings;
  final Future<bool> Function(ReferralSettings) onSave;

  @override
  State<_ReferralRulesTab> createState() => _ReferralRulesTabState();
}

class _ReferralRulesTabState extends State<_ReferralRulesTab> {
  late bool _enabled;
  late bool _firstPurchaseOnly;
  late String _refereeType;
  late String _referrerType;
  late final TextEditingController _refereeValue;
  late final TextEditingController _referrerValue;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxByUser;
  late final TextEditingController _maxByCode;
  late final TextEditingController _maxByIp;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final ReferralSettings s = widget.settings;
    _enabled = s.enabled;
    _firstPurchaseOnly = s.firstPurchaseOnly;
    _refereeType = s.refereeRewardType;
    _referrerType = s.referrerRewardType;
    _refereeValue = TextEditingController(
      text: s.refereeRewardValue.toStringAsFixed(0),
    );
    _referrerValue = TextEditingController(
      text: s.referrerRewardValue.toStringAsFixed(0),
    );
    _minOrder = TextEditingController(
      text: s.minOrderAmount.toStringAsFixed(0),
    );
    _maxByUser = TextEditingController(
      text: s.maxSuccessfulReferralsPerUser.toString(),
    );
    _maxByCode = TextEditingController(text: s.maxUsesPerCode.toString());
    _maxByIp = TextEditingController(text: s.maxRewardsPerIp.toString());
  }

  @override
  void dispose() {
    _refereeValue.dispose();
    _referrerValue.dispose();
    _minOrder.dispose();
    _maxByUser.dispose();
    _maxByCode.dispose();
    _maxByIp.dispose();
    super.dispose();
  }

  double _double(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  int _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String? _numberValidator(String? value) {
    final String raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Required';
    }
    final num? parsed = num.tryParse(raw);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          GlassCard(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Referral rewards enabled'),
                  value: _enabled,
                  onChanged: (bool value) => setState(() => _enabled = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('First purchase only'),
                  value: _firstPurchaseOnly,
                  onChanged: (bool value) =>
                      setState(() => _firstPurchaseOnly = value),
                ),
                const SizedBox(height: 8),
                _RewardEditor(
                  title: 'Student discount',
                  type: _refereeType,
                  controller: _refereeValue,
                  onTypeChanged: (String value) =>
                      setState(() => _refereeType = value),
                ),
                const SizedBox(height: 12),
                _RewardEditor(
                  title: 'Referrer reward',
                  type: _referrerType,
                  controller: _referrerValue,
                  onTypeChanged: (String value) =>
                      setState(() => _referrerType = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minOrder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum order amount',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: _numberValidator,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _maxByUser,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max successful referrals per user',
                    prefixIcon: Icon(Icons.person_pin_circle_rounded),
                  ),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _maxByCode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max uses per referral code',
                    prefixIcon: Icon(Icons.qr_code_rounded),
                  ),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _maxByIp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max rewards per network',
                    prefixIcon: Icon(Icons.security_rounded),
                  ),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            setState(() => _submitting = true);
                            final bool ok = await widget.onSave(
                              ReferralSettings(
                                enabled: _enabled,
                                refereeRewardType: _refereeType,
                                refereeRewardValue: _double(_refereeValue),
                                referrerRewardType: _referrerType,
                                referrerRewardValue: _double(_referrerValue),
                                minOrderAmount: _double(_minOrder),
                                firstPurchaseOnly: _firstPurchaseOnly,
                                maxSuccessfulReferralsPerUser: _int(_maxByUser),
                                maxUsesPerCode: _int(_maxByCode),
                                maxRewardsPerIp: _int(_maxByIp),
                              ),
                            );
                            if (!context.mounted) return;
                            setState(() => _submitting = false);
                            if (ok && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop(true);
                            }
                          },
                    icon: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_submitting ? 'Saving...' : 'Save Rules'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralTrackingTab extends StatelessWidget {
  const _ReferralTrackingTab({required this.events});

  final List<ReferralEventAdminItem> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No referral activity yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final ReferralEventAdminItem event = events[index];
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      event.referralCode,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(event.status),
                ],
              ),
              const SizedBox(height: 6),
              Text('${event.referredUserName} used ${event.referrerName}'),
              const SizedBox(height: 4),
              Text(event.courseTitle),
              const SizedBox(height: 4),
              Text(
                'Discount Rs ${event.refereeDiscountAmount.toStringAsFixed(0)} • Reward Rs ${event.referrerRewardAmount.toStringAsFixed(0)} • Paid Rs ${event.finalAmount.toStringAsFixed(0)}',
              ),
              if (event.createdAt != null) ...<Widget>[
                const SizedBox(height: 4),
                Text('Created ${event.createdAt!.toLocal()}'),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RewardEditor extends StatelessWidget {
  const _RewardEditor({
    required this.title,
    required this.type,
    required this.controller,
    required this.onTypeChanged,
  });

  final String title;
  final String type;
  final TextEditingController controller;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: title),
            validator: (String? value) {
              final String raw = value?.trim() ?? '';
              if (raw.isEmpty) return 'Required';
              final num? parsed = num.tryParse(raw);
              if (parsed == null || parsed < 0) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: type,
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(value: 'flat', child: Text('Rs')),
            DropdownMenuItem<String>(value: 'percent', child: Text('%')),
          ],
          onChanged: (String? value) {
            if (value != null) onTypeChanged(value);
          },
        ),
      ],
    );
  }
}

class _CouponDialog extends StatefulWidget {
  const _CouponDialog({this.coupon, required this.onSubmit});

  final CouponAdminItem? coupon;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<_CouponDialog> {
  late final TextEditingController _code;
  late final TextEditingController _value;
  late final TextEditingController _expiry;
  late final TextEditingController _maxRedemptions;
  late final TextEditingController _perUserLimit;
  late final TextEditingController _minOrder;
  late String _type;
  late bool _active;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final CouponAdminItem? coupon = widget.coupon;
    _code = TextEditingController(text: coupon?.code ?? '');
    _value = TextEditingController(
      text: (coupon?.value ?? 0).toStringAsFixed(0),
    );
    _expiry = TextEditingController(
      text: coupon?.expiresAt?.toIso8601String().split('T').first ?? '',
    );
    _maxRedemptions = TextEditingController(
      text: (coupon?.maxRedemptions ?? 0).toString(),
    );
    _perUserLimit = TextEditingController(
      text: (coupon?.perUserLimit ?? 1).toString(),
    );
    _minOrder = TextEditingController(
      text: (coupon?.minOrderAmount ?? 0).toStringAsFixed(0),
    );
    _type = coupon?.type ?? 'flat';
    _active = coupon?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _expiry.dispose();
    _maxRedemptions.dispose();
    _perUserLimit.dispose();
    _minOrder.dispose();
    super.dispose();
  }

  double _double(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  int _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String? _numberValidator(String? value) {
    final String raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Required';
    final num? parsed = num.tryParse(raw);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.coupon == null ? 'Create Coupon' : 'Edit Coupon'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Coupon code is required'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _value,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Value'),
                      validator: _numberValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _type,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'flat',
                        child: Text('Rs'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'percent',
                        child: Text('%'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _expiry,
                decoration: const InputDecoration(
                  labelText: 'Expiry date',
                  hintText: 'YYYY-MM-DD',
                ),
                validator: (String? value) {
                  final String raw = value?.trim() ?? '';
                  if (raw.isEmpty) return null;
                  return DateTime.tryParse(raw) == null
                      ? 'Enter a valid date'
                      : null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _maxRedemptions,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max redemptions'),
                validator: _numberValidator,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _perUserLimit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Per user limit'),
                validator: _numberValidator,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _minOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum order amount',
                ),
                validator: _numberValidator,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (bool value) => setState(() => _active = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  await submitEditableForm(
                    context: context,
                    formKey: _formKey,
                    setLoading: (bool value) {
                      setState(() => _submitting = value);
                    },
                    submit: () async {
                      await widget.onSubmit(<String, dynamic>{
                        'code': _code.text.trim().toUpperCase(),
                        'type': _type,
                        'value': _double(_value),
                        'expiresAt': _expiry.text.trim().isEmpty
                            ? null
                            : DateTime.tryParse(
                                _expiry.text.trim(),
                              )?.toIso8601String(),
                        'maxRedemptions': _int(_maxRedemptions),
                        'perUserLimit': _int(_perUserLimit),
                        'minOrderAmount': _double(_minOrder),
                        'isActive': _active,
                      });
                    },
                  );
                },
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
