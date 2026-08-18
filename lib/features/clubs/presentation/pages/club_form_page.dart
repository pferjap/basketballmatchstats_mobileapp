import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_form_field.dart';
import '../../../../core/widgets/entity_avatar_picker.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';
import '../providers/club_form_provider.dart';

class ClubFormPage extends ConsumerStatefulWidget {
  const ClubFormPage({this.club, super.key});

  final Club? club;

  @override
  ConsumerState<ClubFormPage> createState() => _ClubFormPageState();
}

class _ClubFormPageState extends ConsumerState<ClubFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;

  bool get _isEditing => widget.club != null;

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    _name = TextEditingController(text: club?.name ?? '');
    _city = TextEditingController(text: club?.city ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del club es obligatorio.';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres.';
    }
    if (value.trim().length > 120) {
      return 'El nombre no puede superar 120 caracteres.';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value != null && value.trim().length > 120) {
      return 'La ciudad no puede superar 120 caracteres.';
    }
    return null;
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final controller = ref.read(clubFormControllerProvider.notifier);
    final club = widget.club;

    final bool saved;
    if (club == null) {
      saved = await controller.create(
        CreateClubParams(name: _name.text.trim(), city: _optional(_city)),
      );
    } else {
      saved = await controller.update(
        club.id,
        UpdateClubParams(name: _name.text.trim(), city: _optional(_city)),
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
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final avatarHeight = constraints.maxHeight * 0.20;
            return Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: avatarHeight,
                    child: Center(
                      child: EntityAvatarPicker(
                        iconData: Icons.shield_outlined,
                        currentImageUrl: widget.club?.logoUrl,
                        onImageSelected: (_) {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(kSpacingM),
                      children: <Widget>[
                        AdminFormField(
                          controller: _name,
                          label: 'Nombre del club',
                          hint: 'Tigres Basket',
                          validator: _validateName,
                          textInputAction: TextInputAction.next,
                        ),
                        AdminFormField(
                          controller: _city,
                          label: 'Ciudad',
                          hint: 'Madrid',
                          validator: _validateCity,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
