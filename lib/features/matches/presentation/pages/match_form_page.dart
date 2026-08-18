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
import '../widgets/match_teams_preview.dart';

class MatchFormPage extends ConsumerStatefulWidget {
  const MatchFormPage({this.match, super.key});

  final Match? match;

  @override
  ConsumerState<MatchFormPage> createState() => _MatchFormPageState();
}

class _MatchFormPageState extends ConsumerState<MatchFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _scheduledAt;
  String? _homeTeamId;
  String? _awayTeamId;
  DateTime? _scheduledAtValue;

  bool get _isEditing => widget.match != null;

  @override
  void initState() {
    super.initState();
    final match = widget.match;
    _scheduledAtValue = match?.scheduledAt;
    _scheduledAt = TextEditingController(
      text: _formatDateTime(match?.scheduledAt),
    );
    _homeTeamId = match?.homeTeamId;
    _awayTeamId = match?.awayTeamId;
  }

  @override
  void dispose() {
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

    // The API requires the organising club; a match's owner club is taken from
    // its home team, so the two teams may belong to different clubs.
    final teams = ref.read(matchFormTeamsProvider).valueOrNull ?? const <Team>[];
    String? clubId;
    if (homeTeamId != null) {
      for (final Team team in teams) {
        if (team.id == homeTeamId) {
          clubId = team.clubId;
          break;
        }
      }
    }

    final String? blocker;
    if (homeTeamId == null || awayTeamId == null) {
      blocker = 'Selecciona el equipo local y el visitante.';
    } else if (homeTeamId == awayTeamId) {
      blocker = 'El equipo local y el visitante deben ser distintos.';
    } else if (clubId == null) {
      blocker = 'No se pudo determinar el club del equipo local.';
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
          clubId: clubId!,
          homeTeamId: homeTeamId!,
          awayTeamId: awayTeamId!,
          scheduledAt: scheduledAt!,
        ),
      );
    } else {
      saved = await controller.update(
        match.id,
        UpdateMatchParams(
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          scheduledAt: scheduledAt,
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
    final teamsAsync = ref.watch(matchFormTeamsProvider);

    final List<Team> teamsList =
        teamsAsync.maybeWhen(data: (List<Team> t) => t, orElse: () => <Team>[]);

    String? homeTeamName;
    String? awayTeamName;
    String? homeTeamLogo;
    String? awayTeamLogo;
    for (final Team t in teamsList) {
      if (t.id == _homeTeamId) {
        homeTeamName = t.name;
        homeTeamLogo = t.logoUrl;
      }
      if (t.id == _awayTeamId) {
        awayTeamName = t.name;
        awayTeamLogo = t.logoUrl;
      }
    }

    final homeOptions = <String, String>{
      for (final Team t in teamsList) t.id: t.name,
    };
    final awayOptions = <String, String>{
      for (final Team t in teamsList)
        if (t.id != _homeTeamId) t.id: t.name,
    };

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
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final previewHeight = constraints.maxHeight * 0.20;
            return Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: previewHeight,
                    child: Center(
                      child: MatchTeamsPreview(
                        homeTeamName: homeTeamName,
                        awayTeamName: awayTeamName,
                        homeTeamLogoUrl: homeTeamLogo,
                        awayTeamLogoUrl: awayTeamLogo,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(kSpacingM),
                      children: <Widget>[
                        teamsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.only(bottom: kSpacingM),
                            child: LinearProgressIndicator(
                              color: AppColors.info,
                              backgroundColor: AppColors.surface,
                            ),
                          ),
                          error: (Object e, StackTrace s) => const Padding(
                            padding: EdgeInsets.only(bottom: kSpacingM),
                            child: Text(
                              'No se pudieron cargar los equipos.',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                          data: (_) => Column(
                            children: <Widget>[
                              AdminDropdownField<String>(
                                label: 'Equipo local',
                                hint: 'Selecciona el equipo local',
                                value: _homeTeamId,
                                items: homeOptions,
                                onChanged: (String? value) => setState(() {
                                  _homeTeamId = value;
                                  if (_awayTeamId == value) {
                                    _awayTeamId = null;
                                  }
                                }),
                              ),
                              AdminDropdownField<String>(
                                label: 'Equipo visitante',
                                hint: 'Selecciona el equipo visitante',
                                value: _awayTeamId,
                                items: awayOptions,
                                onChanged: (String? value) =>
                                    setState(() => _awayTeamId = value),
                              ),
                            ],
                          ),
                        ),
                        AdminFormField(
                          controller: _scheduledAt,
                          label: 'Fecha y hora',
                          hint: 'dd/mm/aaaa hh:mm',
                          readOnly: true,
                          onTap: _pickScheduledAt,
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
