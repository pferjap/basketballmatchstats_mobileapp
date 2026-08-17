import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_dropdown_field.dart';
import '../../../../core/widgets/admin/admin_form_field.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../providers/match_form_provider.dart';

/// Create/edit form for a match (Plan.md T-030).
///
/// Pops with `true` once the match has been saved so the caller can refresh its
/// list; pops with no result when cancelled.
class MatchFormPage extends ConsumerStatefulWidget {
  const MatchFormPage({this.match, super.key});

  /// The match being edited, or `null` to schedule a new one.
  final Match? match;

  @override
  ConsumerState<MatchFormPage> createState() => _MatchFormPageState();
}

class _MatchFormPageState extends ConsumerState<MatchFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _competitionId;
  late final TextEditingController _seasonId;
  late final TextEditingController _venue;
  late final TextEditingController _scheduledAt;
  String? _homeTeamId;
  String? _awayTeamId;
  DateTime? _scheduledAtValue;

  bool get _isEditing => widget.match != null;

  @override
  void initState() {
    super.initState();
    final match = widget.match;
    _competitionId = TextEditingController(text: match?.competitionId ?? '');
    _seasonId = TextEditingController(text: match?.seasonId ?? '');
    _venue = TextEditingController(text: match?.venue ?? '');
    _scheduledAtValue = match?.scheduledAt;
    _scheduledAt = TextEditingController(
      text: _formatDateTime(match?.scheduledAt),
    );
    _homeTeamId = match?.homeTeamId;
    _awayTeamId = match?.awayTeamId;
  }

  @override
  void dispose() {
    _competitionId.dispose();
    _seasonId.dispose();
    _venue.dispose();
    _scheduledAt.dispose();
    super.dispose();
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _pickScheduledAt() async {
    final now = DateTime.now();
    final current = _scheduledAtValue ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha del partido',
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Hora del partido',
    );
    if (time == null) {
      return;
    }
    setState(() {
      _scheduledAtValue = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _scheduledAt.text = _formatDateTime(_scheduledAtValue);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final homeTeamId = _homeTeamId;
    final awayTeamId = _awayTeamId;
    final scheduledAt = _scheduledAtValue;

    final String? blocker;
    if (homeTeamId == null || awayTeamId == null) {
      blocker = 'Selecciona el equipo local y el visitante.';
    } else if (homeTeamId == awayTeamId) {
      blocker = 'El equipo local y el visitante deben ser distintos.';
    } else if (scheduledAt == null) {
      blocker = 'Selecciona la fecha y la hora del partido.';
    } else {
      blocker = null;
    }

    if (blocker != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocker), backgroundColor: AppColors.error),
      );
      return;
    }

    final controller = ref.read(matchFormControllerProvider.notifier);
    final match = widget.match;

    final bool saved;
    if (match == null) {
      saved = await controller.create(
        CreateMatchParams(
          homeTeamId: homeTeamId!,
          awayTeamId: awayTeamId!,
          scheduledAt: scheduledAt!,
          competitionId: _optional(_competitionId),
          seasonId: _optional(_seasonId),
          venue: _optional(_venue),
        ),
      );
    } else {
      saved = await controller.update(
        match.id,
        UpdateMatchParams(
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          scheduledAt: scheduledAt,
          competitionId: _optional(_competitionId),
          seasonId: _optional(_seasonId),
          venue: _optional(_venue),
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
    final error = ref.read(matchFormControllerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      matchFormControllerProvider.select((MatchFormState s) => s.isSubmitting),
    );
    final teams = ref.watch(matchFormTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _isEditing ? 'Editar partido' : 'Crear partido',
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
                data: (List<Team> items) {
                  final options = <String, String>{
                    for (final Team team in items) team.id: team.name,
                  };
                  return Column(
                    children: <Widget>[
                      AdminDropdownField<String>(
                        label: 'Equipo local',
                        hint: 'Selecciona el equipo local',
                        value: _homeTeamId,
                        items: options,
                        onChanged: (String? value) =>
                            setState(() => _homeTeamId = value),
                      ),
                      AdminDropdownField<String>(
                        label: 'Equipo visitante',
                        hint: 'Selecciona el equipo visitante',
                        value: _awayTeamId,
                        items: options,
                        onChanged: (String? value) =>
                            setState(() => _awayTeamId = value),
                      ),
                    ],
                  );
                },
              ),
              AdminFormField(
                controller: _scheduledAt,
                label: 'Fecha y hora',
                hint: 'dd/mm/aaaa hh:mm',
                readOnly: true,
                onTap: _pickScheduledAt,
              ),
              AdminFormField(
                controller: _competitionId,
                label: 'Competición (ID)',
                hint: 'Identificador de la competición',
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
                controller: _seasonId,
                label: 'Temporada (ID)',
                hint: 'Identificador de la temporada',
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
                controller: _venue,
                label: 'Lugar / cancha',
                hint: 'Pabellón Municipal',
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
