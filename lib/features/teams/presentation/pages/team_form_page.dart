import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_form_field.dart';
import '../../../../core/widgets/entity_avatar_picker.dart';
import '../../../clubs/domain/entities/club.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../providers/team_form_provider.dart';
import '../providers/teams_providers.dart';

class TeamFormPage extends ConsumerStatefulWidget {
  const TeamFormPage({this.team, super.key});

  final Team? team;

  @override
  ConsumerState<TeamFormPage> createState() => _TeamFormPageState();
}

class _TeamFormPageState extends ConsumerState<TeamFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _clubId;
  String? _logoUrl;
  PickedImage? _pendingImage;
  bool _uploadingImage = false;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _name = TextEditingController(text: team?.name ?? '');
    _clubId = team?.clubId;
    _logoUrl = team?.logoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del equipo es obligatorio.';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres.';
    }
    if (value.trim().length > 120) {
      return 'El nombre no puede superar 120 caracteres.';
    }
    return null;
  }

  Future<void> _onImagePicked(PickedImage image) async {
    final team = widget.team;
    if (team == null) {
      // No id yet: keep the picked image and upload it after the team is saved.
      setState(() => _pendingImage = image);
      return;
    }
    setState(() {
      _pendingImage = image;
      _uploadingImage = true;
    });
    try {
      final updated = await ref
          .read(teamRepositoryProvider)
          .uploadTeamLogo(
            team.id,
            bytes: image.bytes,
            filename: image.filename,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _logoUrl = updated.logoUrl;
        _pendingImage = null;
        _uploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen actualizada.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingImage = null;
        _uploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final clubId = _clubId;
    if (clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el club al que pertenece el equipo.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = ref.read(teamFormControllerProvider.notifier);
    final team = widget.team;

    final Team? saved = team == null
        ? await controller.create(
            CreateTeamParams(name: _name.text.trim(), clubId: clubId),
          )
        : await controller.update(
            team.id,
            UpdateTeamParams(name: _name.text.trim(), clubId: clubId),
          );

    if (!mounted) {
      return;
    }
    if (saved != null) {
      final pending = _pendingImage;
      if (pending != null) {
        try {
          await ref
              .read(teamRepositoryProvider)
              .uploadTeamLogo(
                saved.id,
                bytes: pending.bytes,
                filename: pending.filename,
              );
        } on AppException catch (error) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Equipo guardado, pero no se pudo subir la imagen: '
                '${error.message}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop(true);
          return;
        }
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      return;
    }
    final error = ref.read(teamFormControllerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      teamFormControllerProvider.select((TeamFormState s) => s.isSubmitting),
    );
    final clubs = ref.watch(teamFormClubsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _isEditing ? 'Editar equipo' : 'Crear equipo',
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
                        iconData: Icons.groups_outlined,
                        currentImageUrl: _logoUrl,
                        pickedImageBytes: _pendingImage?.bytes,
                        isBusy: _uploadingImage,
                        onImagePicked: _onImagePicked,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(kSpacingM),
                      children: <Widget>[
                        AdminFormField(
                          controller: _name,
                          label: 'Nombre del equipo',
                          hint: 'Tigres Senior A',
                          validator: _validateName,
                          textInputAction: TextInputAction.done,
                        ),
                        _ClubDropdown(
                          clubs: clubs,
                          value: _clubId,
                          onChanged: (String? value) =>
                              setState(() => _clubId = value),
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

class _ClubDropdown extends StatelessWidget {
  const _ClubDropdown({
    required this.clubs,
    required this.value,
    required this.onChanged,
  });

  final AsyncValue<List<Club>> clubs;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Club',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          clubs.when(
            loading: () => const LinearProgressIndicator(
              color: AppColors.info,
              backgroundColor: AppColors.surface,
            ),
            error: (Object error, StackTrace stackTrace) => const Text(
              'No se pudieron cargar los clubes.',
              style: TextStyle(color: AppColors.error),
            ),
            data: (List<Club> items) => DropdownButtonFormField<String>(
              initialValue: value,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
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
              ),
              hint: const Text(
                'Selecciona un club',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              items: <DropdownMenuItem<String>>[
                for (final Club club in items)
                  DropdownMenuItem<String>(
                    value: club.id,
                    child: Text(club.name),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
