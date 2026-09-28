class RackItem {
  final String location;
  final String zone;
  final int rack;
  final int level;
  final int bay;
  bool isVacant;
  String? sku;

  RackItem({
    required this.location,
    required this.zone,
    required this.rack,
    required this.level,
    required this.bay,
    this.isVacant = true,
    this.sku,
  });

  factory RackItem.fromMap(Map<String, dynamic> map) {
    return RackItem(
      location: map['ตำแหน่ง']?.toString() ?? '',
      zone: map['ตำแหน่งR']?.toString() ?? 'R',
      rack: int.tryParse(map['แรคเท่าไหร่'].toString()) ?? 1,
      level: int.tryParse(map['ชั้น'].toString()) ?? 1,
      bay: int.tryParse(map['ช่อง'].toString()) ?? 1,
    );
  }
}
