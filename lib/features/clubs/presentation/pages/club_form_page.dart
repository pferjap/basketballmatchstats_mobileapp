import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';
import '../providers/club_form_provider.dart';

/// Create/edit form for a club (Plan.md T-027).
///
/// Pops with `true` once the club has been saved so the caller can refresh its
/// list; pops with no result when cancelled.
class ClubFormPage extends ConsumerStatefulWidget {
  const ClubFormPage({this.club, super.key});

  /// The club being edited, or `null` to create a new one.
  final Club? club;

  @override
  ConsumerState<ClubFormPage> createState() => _ClubFormPageState();
}

class _ClubFormPageState extends ConsumerState<ClubFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _foundedYear;
  late final TextEditingController _logoUrl;

  bool get _isEditing => widget.club != null;

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    _name = TextEditingController(text: club?.name ?? '');
    _city = TextEditingController(text: club?.city ?? '');
    _country = TextEditingController(text: club?.country ?? '');
    _foundedYear = TextEditingController(
      text: club?.foundedYear?.toString() ?? '',
    );
    _logoUrl = TextEditingController(text: club?.logoUrl ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _country.dispose();
    _foundedYear.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del club es obligatorio.';
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final year = int.tryParse(value.trim());
    if (year == null) {
      return 'Introduce un año válido.';
    }
    if (year < 1850 || year > DateTime.now().year) {
      return 'El año debe estar entre 1850 y ${DateTime.now().year}.';
    }
    return null;
  }

  /// Empty text means "no value"; for an edit that leaves the stored value
  /// untouched, since the repository only sends non-null fields.
  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final controller = ref.read(clubFormControllerProvider.notifier);
    final year = _optional(_foundedYear);
    final club = widget.club;

    final bool saved;
    if (club == null) {
      saved = await controller.create(
        CreateClubParams(
          name: _name.text.trim(),
          city: _optional(_city),
          country: _optional(_country),
          foundedYear: year == null ? null : int.parse(year),
          logoUrl: _optional(_logoUrl),
        ),
      );
    } else {
      saved = await controller.update(
        club.id,
        UpdateClubParams(
          name: _name.text.trim(),
          city: _optional(_city),
          country: _optional(_country),
          foundedYear: year == null ? null : int.parse(year),
          logoUrl: _optional(_logoUrl),
        ),
      );
    }

    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    final error = ref.read(clubFormControllerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      clubFormControllerProvider.select((ClubFormState s) => s.isSubmitting),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _isEditing ? 'Editar club' : 'Crear club',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(kSpacingM),
            children: <Widget>[
              _FormField(
                controller: _name,
                label: 'Nombre del club',
                hint: 'Tigres Basket',
                validator: _validateName,
                textInputAction: TextInputAction.next,
              ),
              _FormField(
                controller: _city,
                label: 'Ciudad',
                hint: 'Madrid',
                textInputAction: TextInputAction.next,
              ),
              _FormField(
                controller: _country,
                label: 'País',
                hint: 'España',
                textInputAction: TextInputAction.next,
              ),
              _FormField(
                controller: _foundedYear,
                label: 'Año de fundación',
                hint: '2018',
                validator: _validateYear,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                textInputAction: TextInputAction.next,
              ),
              _FormField(
                controller: _logoUrl,
                label: 'URL del escudo',
                hint: 'https://…/escudo.png',
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: kSpacingL),
              SizedBox(
                height: kMinTouchTarget,
                child: FilledButton(
                  onPressed: isSubmitting ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ),
              const SizedBox(height: kSpacingS),
              SizedBox(
                height: kMinTouchTarget,
                child: TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: kSpacingM,
                horizontal: kSpacingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.info),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
