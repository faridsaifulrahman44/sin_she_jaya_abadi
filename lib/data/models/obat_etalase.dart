/// Fixed etalase location options for medication storage.
enum Etalase {
  etalase1('Etalase 1'),
  etalase2('Etalase 2'),
  etalase3('Etalase 3');

  const Etalase(this.label);

  final String label;

  String get value => name;

  static Etalase fromString(String? value) {
    if (value == null) return Etalase.etalase1;
    return Etalase.values.firstWhere(
      (e) => e.value == value || e.label == value,
      orElse: () => Etalase.etalase1,
    );
  }
}
