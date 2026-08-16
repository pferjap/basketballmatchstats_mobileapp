/// A player on a team's roster, as shown in the annotation player carousel.
///
/// The Players feature (roster management) lands in a later phase, so the Court
/// View receives its roster via [CourtViewArgs] (GoRouter `extra`) with a
/// demo fallback when none is supplied.
class RosterPlayer {
  const RosterPlayer({
    required this.id,
    required this.number,
    required this.name,
  });

  final String id;

  /// Jersey number shown inside the player chip.
  final int number;

  /// Display name shown under the chip.
  final String name;
}

/// One team competing in the annotated match: identity, display names and the
/// on-court roster used by the player selector.
class CourtTeam {
  const CourtTeam({
    required this.id,
    required this.name,
    this.clubName = '',
    this.roster = const <RosterPlayer>[],
  });

  final String id;
  final String name;
  final String clubName;
  final List<RosterPlayer> roster;
}

/// Display metadata for the Court View that is not carried by the match/event
/// streams (team names, rosters, competition label). Passed via GoRouter
/// `extra`; sensible fallbacks are used when absent.
class CourtViewArgs {
  const CourtViewArgs({
    required this.home,
    required this.away,
    this.competitionLabel,
    this.initialPeriod = 1,
    this.periodDurationSeconds = 600,
  });

  final CourtTeam home;
  final CourtTeam away;
  final String? competitionLabel;

  /// Period the match starts on (1–4 regulation, 5+ overtime).
  final int initialPeriod;

  /// Length of a period in seconds, used by the game clock (default 10:00).
  final int periodDurationSeconds;

  /// A neutral demo roster/teams used when the screen is opened without args
  /// (e.g. deep link) so the annotator UI is still usable.
  factory CourtViewArgs.demo() {
    return const CourtViewArgs(
      home: CourtTeam(
        id: 'home',
        name: 'Local',
        roster: <RosterPlayer>[
          RosterPlayer(id: 'h4', number: 4, name: 'Jugador 4'),
          RosterPlayer(id: 'h7', number: 7, name: 'Jugador 7'),
          RosterPlayer(id: 'h11', number: 11, name: 'Jugador 11'),
          RosterPlayer(id: 'h23', number: 23, name: 'Jugador 23'),
          RosterPlayer(id: 'h32', number: 32, name: 'Jugador 32'),
        ],
      ),
      away: CourtTeam(
        id: 'away',
        name: 'Visitante',
        roster: <RosterPlayer>[
          RosterPlayer(id: 'a5', number: 5, name: 'Jugador 5'),
          RosterPlayer(id: 'a8', number: 8, name: 'Jugador 8'),
          RosterPlayer(id: 'a10', number: 10, name: 'Jugador 10'),
          RosterPlayer(id: 'a21', number: 21, name: 'Jugador 21'),
          RosterPlayer(id: 'a33', number: 33, name: 'Jugador 33'),
        ],
      ),
    );
  }
}
