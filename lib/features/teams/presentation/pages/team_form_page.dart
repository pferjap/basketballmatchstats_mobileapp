import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_form_field.dart';
import '../../../clubs/domain/entities/club.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../providers/team_form_provider.dart';

/// Create/edit form for a team (Plan.md T-028).
///
/// Pops with `true` once the team has been saved so the caller can refresh its
/// list; pops with no result when cancelled.
class TeamFormPage extends ConsumerStatefulWidget {
  const TeamFormPage({this.team, super.key});

  /// The team being edited, or `null` to create a new one.
  final Team? team;

  @override
  ConsumerState<TeamFormPage> createState() => _TeamFormPageState();
}

class _TeamFormPageState extends ConsumerState<TeamFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _logoUrl;
  String? _clubId;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _name = TextEditingController(text: team?.name ?? '');
    _category = TextEditingController(text: team?.category ?? '');
    _logoUrl = TextEditingController(text: team?.logoUrl ?? '');
    _clubId = team?.clubId;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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

    final bool saved;
    if (team == null) {
      saved = await controller.create(
        CreateTeamParams(
          name: _name.text.trim(),
          clubId: clubId,
          category: _optional(_category),
          logoUrl: _optional(_logoUrl),
        ),
      );
    } else {
      saved = await controller.update(
        team.id,
        UpdateTeamParams(
          name: _name.text.trim(),
          clubId: clubId,
          category: _optional(_category),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(kSpacingM),
            children: <Widget>[
              AdminFormField(
                controller: _name,
                label: 'Nombre del equipo',
                hint: 'Tigres Senior A',
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'El nombre del equipo es obligatorio.'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              _ClubDropdown(
                clubs: clubs,
                value: _clubId,
                onChanged: (String? value) => setState(() => _clubId = value),
              ),
              AdminFormField(
                controller: _category,
                label: 'Categoría',
                hint: 'Senior',
                textInputAction: TextInputAction.next,
              ),
              AdminFormField(
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
