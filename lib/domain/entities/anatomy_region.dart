enum AnatomyFacing { anterior, posterior }

enum AnatomyRegion {
  trapezius(label: 'Trapezius', facing: AnatomyFacing.posterior),
  anteriorDeltoid(label: 'Front Delts', facing: AnatomyFacing.anterior),
  lateralDeltoid(label: 'Side Delts', facing: AnatomyFacing.anterior),
  posteriorDeltoid(label: 'Rear Delts', facing: AnatomyFacing.posterior),
  pectoralis(label: 'Chest', facing: AnatomyFacing.anterior),
  biceps(label: 'Biceps', facing: AnatomyFacing.anterior),
  triceps(label: 'Triceps', facing: AnatomyFacing.posterior),
  forearm(label: 'Forearms', facing: AnatomyFacing.anterior),
  abdominals(label: 'Abdominals', facing: AnatomyFacing.anterior),
  obliques(label: 'Obliques', facing: AnatomyFacing.anterior),
  latissimusDorsi(label: 'Lats', facing: AnatomyFacing.posterior),
  rhomboids(label: 'Rhomboids', facing: AnatomyFacing.posterior),
  lowerBack(label: 'Lower Back', facing: AnatomyFacing.posterior),
  glutes(label: 'Glutes', facing: AnatomyFacing.posterior),
  quadriceps(label: 'Quadriceps', facing: AnatomyFacing.anterior),
  hamstrings(label: 'Hamstrings', facing: AnatomyFacing.posterior),
  adductors(label: 'Adductors', facing: AnatomyFacing.anterior),
  calves(label: 'Calves', facing: AnatomyFacing.posterior);

  const AnatomyRegion({required this.label, required this.facing});

  final String label;
  final AnatomyFacing facing;

  static AnatomyRegion? tryParse(String? storedName) => storedName == null
      ? null
      : AnatomyRegion.values
          .where((AnatomyRegion region) => region.name == storedName)
          .firstOrNull;

  static Iterable<AnatomyRegion> onSide(AnatomyFacing side) =>
      AnatomyRegion.values.where((AnatomyRegion region) => region.facing == side);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
