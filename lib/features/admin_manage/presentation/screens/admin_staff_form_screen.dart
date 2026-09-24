import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_back_link.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_helper_note.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../admin_rooms/presentation/widgets/room_form_controls.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/staff_account.dart';
import '../../domain/entities/staff_draft.dart';
import '../../domain/repositories/admin_staff_repository.dart';
import '../../domain/usecases/staff_usecases.dart';
import '../admin_manage_routes.dart';
import '../providers/staff_form_controller.dart';
import '../widgets/staff_widgets.dart';

class AdminStaffFormScreen extends StatelessWidget {
  const AdminStaffFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StaffFormController>(
      create: (BuildContext context) => StaffFormController(
        CreateStaffAccountUseCase(context.read<AdminStaffRepository>()),
      ),
      child: Builder(
        builder: (BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppBackLink(label: 'Akun staf', onBack: () => _leave(context)),
            const Expanded(child: _StaffForm()),
          ],
        ),
      ),
    );
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AdminManageRoutes.staff);
  }
}

class _StaffForm extends StatefulWidget {
  const _StaffForm();

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  // Hak akses paling sempit jadi bawaan; admin harus dipilih dengan sadar.
  UserRole _role = UserRole.petSitter;
  bool _obscured = true;
  Map<StaffField, String> _errors = const <StaffField, String>{};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  StaffDraft get _draft => StaffDraft(
    name: _name.text,
    email: _email.text,
    password: _password.text,
    role: _role,
  );

  Future<void> _submit() async {
    final StaffDraft draft = _draft;
    final Map<StaffField, String> errors = draft.validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      return;
    }
    final StaffFormController form = context.read<StaffFormController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool saved = await form.submit(draft);
    if (!saved || !mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Akun ${draft.trimmedName} dibuat sebagai '
          '${staffRoleLabel(draft.role!).toLowerCase()}.',
        ),
      ),
    );
    _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    final StaffFormController form = context.watch<StaffFormController>();
    final bool busy = form.isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.space16,
        AppSpacing.screenEdge,
        AppSpacing.space32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Tambah akun staf',
                    style: AppTypography.headlineLg,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Akun langsung aktif. Staf masuk dengan email dan kata '
                  'sandi di bawah.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                const AppFieldLabel(text: 'Nama lengkap'),
                const SizedBox(height: AppSpacing.space8),
                AppTextField(
                  controller: _name,
                  hintText: 'Nama staf sesuai identitas',
                  semanticLabel: 'Nama lengkap staf',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const <String>[AutofillHints.name],
                  maxLength: StaffDraft.maxNameLength,
                  enabled: !busy,
                  errorText: _errors[StaffField.name],
                ),
                const SizedBox(height: AppSpacing.space20),
                const AppFieldLabel(text: 'Email'),
                const SizedBox(height: AppSpacing.space8),
                AppTextField(
                  controller: _email,
                  hintText: 'nama@email.com',
                  semanticLabel: 'Email staf',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  enabled: !busy,
                  errorText: _errors[StaffField.email],
                ),
                const SizedBox(height: AppSpacing.space20),
                const AppFieldLabel(text: 'Kata sandi sementara'),
                const SizedBox(height: AppSpacing.space8),
                AppPasswordField(
                  controller: _password,
                  hintText: 'Minimal 8 karakter',
                  semanticLabel: 'Kata sandi sementara',
                  obscured: _obscured,
                  onToggleObscured: () =>
                      setState(() => _obscured = !_obscured),
                  autofillHints: const <String>[AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  enabled: !busy,
                  errorText: _errors[StaffField.password],
                ),
                const SizedBox(height: AppSpacing.space20),
                const AppFieldLabel(text: 'Hak akses'),
                const SizedBox(height: AppSpacing.space8),
                RoleOptionCard(
                  title: 'Penjaga',
                  description: 'Mencatat check-in, check-out, dan laporan harian kucing.',
                  selected: _role == UserRole.petSitter,
                  onTap: () => setState(() => _role = UserRole.petSitter),
                ),
                const SizedBox(height: AppSpacing.space8),
                RoleOptionCard(
                  title: 'Admin',
                  description:
                      'Semua akses penjaga, ditambah konfirmasi reservasi, '
                      'kamar, dan pembuatan akun staf.',
                  selected: _role == UserRole.admin,
                  onTap: () => setState(() => _role = UserRole.admin),
                ),
                if (_errors[StaffField.role] != null)
                  FieldErrorText(text: _errors[StaffField.role]!),
                const SizedBox(height: AppSpacing.space16),
                const AppHelperNote(
                  icon: Icons.info_outline_rounded,
                  text:
                      'Berikan kata sandi ini langsung ke staf. Staf bisa '
                      'menggantinya lewat Lupa kata sandi di halaman masuk.',
                ),
                if (form.errorMessage != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.space16),
                  FieldErrorText(text: form.errorMessage!),
                ],
                const SizedBox(height: AppSpacing.space24),
                AppPrimaryButton(
                  label: 'Buat akun',
                  isLoading: busy,
                  onPressed: busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
