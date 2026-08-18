import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_dropdown_field.dart';
import '../../../../core/widgets/admin/admin_form_field.dart';
import '../../../../core/widgets/entity_avatar_picker.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../providers/player_form_provider.dart';

class PlayerFormPage extends ConsumerStatefulWidget {
  const PlayerFormPage({this.player, super.key});

  final Player? player;

  @override
  ConsumerState<PlayerFormPage> createState() => _PlayerFormPageState();
}

class _PlayerFormPageState extends ConsumerState<PlayerFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _jerseyNumber;
  String? _teamId;
  PlayerPosition? _position;

  bool get _isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();
    final player = widget.player;
    _firstName = TextEditingController(text: player?.firstName ?? '');
    _lastName = TextEditingController(text: player?.lastName ?? '');
    _jerseyNumber = TextEditingController(
      text: player?.jerseyNumber?.toString() ?? '',
    );
    _teamId = player?.teamId;
    _position = player?.position;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _jerseyNumber.dispose();
    super.dispose();
  }

  int? _optionalInt(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede superar 100 caracteres.';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los apellidos son obligatorios.';
    }
    if (value.trim().length > 100) {
      return 'Los apellidos no pueden superar 100 caracteres.';
    }
    return null;
  }

  String? _validateJerseyNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final number = int.tryParse(value.trim());
    if (number == null || number < 0 || number > 99) {
      return 'El dorsal debe estar entre 0 y 99.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final teamId = _teamId;
    if (teamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el equipo al que pertenece el jugador.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = ref.read(playerFormControllerProvider.notifier);
    final player = widget.player;

    final bool saved;
    if (player == null) {
      saved = await controller.create(
        CreatePlayerParams(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          teamId: teamId,
          jerseyNumber: _optionalInt(_jerseyNumber),
          position: _position,
        ),
      );
    } else {
      saved = await controller.update(
        player.id,
        UpdatePlayerParams(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          teamId: teamId,
          jerseyNumber: _optionalInt(_jerseyNumber),
          position: _position,
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
    final error = ref.read(playerFormControllerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      playerFormControllerProvider.select(
        (PlayerFormState s) => s.isSubmitting,
      ),
    );
    final teams = ref.watch(playerFormTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _isEditing ? 'Editar jugador' : 'Crear jugador',
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
                        iconData: Icons.person_outline,
                        currentImageUrl: widget.player?.photoUrl,
                        onImageSelected: (_) {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(kSpacingM),
                      children: <Widget>[
                        AdminFormField(
                          controller: _firstName,
                          label: 'Nombre',
                          hint: 'Álvaro',
                          validator: _validateFirstName,
                          textInputAction: TextInputAction.next,
                        ),
                        AdminFormField(
                          controller: _lastName,
                          label: 'Apellidos',
                          hint: 'Ruiz',
                          validator: _validateLastName,
                          textInputAction: TextInputAction.next,
                        ),
                        AdminFormField(
                          controller: _jerseyNumber,
                          label: 'Dorsal',
                          hint: '9',
                          validator: _validateJerseyNumber,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        AdminDropdownField<PlayerPosition>(
                          label: 'Posición',
                          hint: 'Selecciona una posición',
                          value: _position,
                          items: <PlayerPosition, String>{
                            for (final PlayerPosition p
                                in PlayerPosition.values)
                              p: kPlayerPositionLabels[p]!,
                          },
                          onChanged: (PlayerPosition? value) =>
                              setState(() => _position = value),
                        ),
                        teams.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.only(bottom: kSpacingM),
                            child: LinearProgressIndicator(
                              color: AppColors.info,
                              backgroundColor: AppColors.surface,
                            ),
                          ),
                          error: (Object error, StackTrace stackTrace) =>
                              const Padding(
                                padding: EdgeInsets.only(bottom: kSpacingM),
                                child: Text(
                                  'No se pudieron cargar los equipos.',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                          data: (List<Team> items) =>
                              AdminDropdownField<String>(
                                label: 'Equipo',
                                hint: 'Selecciona un equipo',
                                value: _teamId,
                                items: <String, String>{
                                  for (final Team team in items)
                                    team.id: team.name,
                                },
                                onChanged: (String? value) =>
                                    setState(() => _teamId = value),
                              ),
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
