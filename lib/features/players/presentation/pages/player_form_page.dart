import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_dropdown_field.dart';
import '../../../../core/widgets/admin/admin_form_field.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../providers/player_form_provider.dart';

/// Create/edit form for a player (Plan.md T-029).
///
/// Pops with `true` once the player has been saved so the caller can refresh
/// its list; pops with no result when cancelled.
class PlayerFormPage extends ConsumerStatefulWidget {
  const PlayerFormPage({this.player, super.key});

  /// The player being edited, or `null` to create a new one.
  final Player? player;

  @override
  ConsumerState<PlayerFormPage> createState() => _PlayerFormPageState();
}

class _PlayerFormPageState extends ConsumerState<PlayerFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _jerseyNumber;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _photoUrl;
  late final TextEditingController _birthDate;
  String? _teamId;
  PlayerPosition? _position;
  DateTime? _birthDateValue;

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
    _height = TextEditingController(text: player?.height?.toString() ?? '');
    _weight = TextEditingController(text: player?.weight?.toString() ?? '');
    _photoUrl = TextEditingController(text: player?.photoUrl ?? '');
    _birthDateValue = player?.birthDate;
    _birthDate = TextEditingController(text: _formatDate(player?.birthDate));
    _teamId = player?.teamId;
    _position = player?.position;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _jerseyNumber.dispose();
    _height.dispose();
    _weight.dispose();
    _photoUrl.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _optionalInt(TextEditingController controller) {
    final value = _optional(controller);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDateValue ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 70),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) {
      setState(() {
        _birthDateValue = picked;
        _birthDate.text = _formatDate(picked);
      });
    }
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
          photoUrl: _optional(_photoUrl),
          birthDate: _birthDateValue,
          height: _optionalInt(_height),
          weight: _optionalInt(_weight),
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
          photoUrl: _optional(_photoUrl),
          birthDate: _birthDateValue,
          height: _optionalInt(_height),
          weight: _optionalInt(_weight),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(kSpacingM),
            children: <Widget>[
              AdminFormField(
                controller: _firstName,
                label: 'Nombre',
                hint: 'Álvaro',
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'El nombre es obligatorio.'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
                controller: _lastName,
                label: 'Apellidos',
                hint: 'Ruiz',
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Los apellidos son obligatorios.'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
                controller: _jerseyNumber,
                label: 'Dorsal',
                hint: '9',
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
                  for (final PlayerPosition p in PlayerPosition.values)
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
                error: (Object error, StackTrace stackTrace) => const Padding(
                  padding: EdgeInsets.only(bottom: kSpacingM),
                  child: Text(
                    'No se pudieron cargar los equipos.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                data: (List<Team> items) => AdminDropdownField<String>(
                  label: 'Equipo',
                  hint: 'Selecciona un equipo',
                  value: _teamId,
                  items: <String, String>{
                    for (final Team team in items) team.id: team.name,
                  },
                  onChanged: (String? value) => setState(() => _teamId = value),
                ),
              ),
              AdminFormField(
                controller: _birthDate,
                label: 'Fecha de nacimiento',
                hint: 'dd/mm/aaaa',
                readOnly: true,
                onTap: _pickBirthDate,
              ),
              AdminFormField(
                controller: _height,
                label: 'Altura (cm)',
                hint: '198',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
                controller: _weight,
                label: 'Peso (kg)',
                hint: '92',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
                controller: _photoUrl,
                label: 'URL de la foto',
                hint: 'https://…/jugador.png',
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
