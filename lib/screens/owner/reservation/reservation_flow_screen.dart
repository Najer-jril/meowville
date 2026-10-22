import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';

import '../../../data/data.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/common.dart';
import 'step_addon.dart';
import 'step_pet_date.dart';
import 'step_room.dart';
import 'step_summary.dart';

class ReservationFlowScreen extends StatefulWidget {
  const ReservationFlowScreen({
    super.key,
    this.preselectedType,
    this.preselectedCat,
  });

  final RoomType? preselectedType;
  final Cat? preselectedCat;

  @override
  State<ReservationFlowScreen> createState() => _ReservationFlowScreenState();
}

class _ReservationFlowScreenState extends State<ReservationFlowScreen> {
  static const _titles = [
    'Pilih Tanggal & Kucing',
    'Pilih Kamar',
    'Layanan Tambahan',
    'Ringkasan Reservasi',
  ];

  AdminStore get _store => context.read<AdminStore>();
  int _step = 0;
  DateTimeRange? _range;
  late Cat? _cat = widget.preselectedCat;
  late RoomType? _type = widget.preselectedType;
  final Set<Addon> _addons = {};
  String? _proof;
  bool _submitting = false;

  bool get _canContinue => switch (_step) {
    0 => _range != null && _cat != null,
    1 => _type != null,
    _ => true,
  };

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  void _next() {
    if (_step == 0 && _type != null) {
      final left = _store.remainingFor(_type!, _range!.start, _range!.end);
      if (left < 1) _type = null;
    }
    setState(() => _step++);
  }

  Future<void> _submit() async {
    final range = _range!;
    final type = _type!;
    final cat = _cat!;
    if (_store.remainingFor(type, range.start, range.end) < 1) {
      await showInfoDialog(
        context,
        icon: Icons.error_outline,
        title: 'Kamar baru saja penuh',
        message:
            'Tipe ${type.name} tidak tersedia lagi di tanggal ini. '
            'Silakan pilih tipe atau tanggal lain.',
        buttonLabel: 'Pilih Ulang',
      );
      setState(() {
        _type = null;
        _step = 1;
      });
      return;
    }
    setState(() => _submitting = true);
    final r = _store.createReservation(
      cat: cat,
      type: type,
      checkIn: range.start,
      checkOut: range.end,
      addons: _addons.toList(),
      paymentProof: _proof,
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.ownerReservationSuccess,
      arguments: r,
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = switch (_step) {
      0 => StepPetDate(
        range: _range,
        cat: _cat,
        onRangeChanged: (r) => setState(() {
          _range = r;
          if (_cat != null && _store.clashFor(_cat!, r.start, r.end) != null) {
            _cat = null;
          }
        }),
        onCatChanged: (c) => setState(() => _cat = c),
      ),
      1 => StepRoom(
        range: _range!,
        selected: _type,
        onSelected: (t) => setState(() => _type = t),
      ),
      2 => StepAddon(
        selected: _addons,
        onToggle: (a) => setState(
          () => _addons.contains(a) ? _addons.remove(a) : _addons.add(a),
        ),
      ),
      _ => StepSummary(
        cat: _cat!,
        type: _type!,
        range: _range!,
        addons: _addons.toList(),
        proof: _proof,
        onProofChanged: (p) => setState(() => _proof = p),
      ),
    };

    final addonTotal = _addons.fold(0, (s, a) => s + a.price);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: SubPageAppBar(title: _titles[_step]),
        body: Column(
          children: [
            _Progress(step: _step),
            Expanded(child: step),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 2 && _addons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '${_addons.length} layanan dipilih - '
                    '${Fmt.rupiah(addonTotal)}',
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(fontSize: 14, color: AppColors.primary),
                  ),
                ),
              if (_step == 1 && _type == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Pilih satu tipe kamar untuk lanjut.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              _step == 3
                  ? FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Kirim Reservasi'),
                    )
                  : FilledButton.icon(
                      onPressed: _canContinue ? _next : null,
                      icon: const Icon(Icons.arrow_forward),
                      iconAlignment: IconAlignment.end,
                      label: const Text('Lanjut'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Langkah ${step + 1} dari 4',
            style: text.labelLarge!.copyWith(
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: (step + 1) / 4, minHeight: 6),
          ),
        ],
      ),
    );
  }
}
