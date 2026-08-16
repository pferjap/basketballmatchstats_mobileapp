import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/presentation/models/annotation_action.dart';
import 'package:hoop_analytics/core/theme/app_colors.dart';

AnnotationAction actionFor(AnnotationActionId id) =>
    kAnnotationActions.firstWhere((a) => a.id == id);

void main() {
  test('catalog has the nine expected actions in three categories', () {
    expect(kAnnotationActions.length, 9);
    expect(
      kAnnotationActions
          .where((a) => a.category == AnnotationCategory.shot)
          .length,
      3,
    );
    expect(
      kAnnotationActions
          .where((a) => a.category == AnnotationCategory.action)
          .length,
      3,
    );
    expect(
      kAnnotationActions
          .where((a) => a.category == AnnotationCategory.foul)
          .length,
      3,
    );
  });

  test('made shots carry point values and score, misses do not', () {
    final two = actionFor(AnnotationActionId.twoPoints);
    final three = actionFor(AnnotationActionId.threePoints);
    final miss = actionFor(AnnotationActionId.miss);

    expect(two.eventType, EventType.pointsMade);
    expect(two.scoringPoints, 2);
    expect(three.scoringPoints, 3);
    expect(miss.scoringPoints, 0);
    expect(two.color, AppColors.success);
    expect(two.requiresDetails, isTrue);
    expect(miss.requiresDetails, isTrue);
  });

  test('only personal/offensive fouls count as team fouls', () {
    expect(actionFor(AnnotationActionId.foulPersonal).isTeamFoul, isTrue);
    expect(actionFor(AnnotationActionId.foulOffensive).isTeamFoul, isTrue);
    expect(actionFor(AnnotationActionId.freeThrows).isTeamFoul, isFalse);
    expect(actionFor(AnnotationActionId.assist).isTeamFoul, isFalse);
  });

  test('buildMetadata merges points and static metadata', () {
    expect(
      actionFor(AnnotationActionId.threePoints).buildMetadata(),
      <String, dynamic>{'points': 3},
    );
    expect(
      actionFor(AnnotationActionId.foulOffensive).buildMetadata(),
      <String, dynamic>{'offensive': true},
    );
    expect(actionFor(AnnotationActionId.assist).buildMetadata(), isNull);
  });
}
