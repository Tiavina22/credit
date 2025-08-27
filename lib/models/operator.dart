class MobileOperator {
  final String name;
  final String ussdFormat;
  final String logoPath;
  final String color;

  const MobileOperator({
    required this.name,
    required this.ussdFormat,
    required this.logoPath,
    required this.color,
  });

  String generateUSSD(String code) {
    return ussdFormat.replaceAll('{code}', code);
  }

  static const List<MobileOperator> operators = [
    MobileOperator(
      name: 'Yas',
      ussdFormat: '#321*{code}#',
      logoPath: 'assets/images/yas_logo.png',
      color: '#FF6B6B',
    ),
    MobileOperator(
      name: 'Orange',
      ussdFormat: '144{code}',
      logoPath: 'assets/images/orange_logo.png',
      color: '#FF8C00',
    ),
    MobileOperator(
      name: 'Airtel',
      ussdFormat: '*999*{code}#',
      logoPath: 'assets/images/airtel_logo.png',
      color: '#FF0000',
    ),
  ];
}
