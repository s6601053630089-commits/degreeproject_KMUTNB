class WarehouseItem {
  final String grNo;
  final String grDate;
  final String tagNo;
  final String warehouse;
  final String locationName;
  final String skuCategory;
  final String skuType;
  final String skuSubType;
  final String itemCode;
  final String description;
  final int onHand;
  final int available;
  final String packKey;
  final String itemStatus;
  final String lot;
  final String batchNo;
  final String palletNo;
  final String unit;
  final int qtyPerPallet;
  final String palletSize;
  final String owner;
  final String palletSize2;
  final double totalCbm;

  WarehouseItem({
    required this.grNo,
    required this.grDate,
    required this.tagNo,
    required this.warehouse,
    required this.locationName,
    required this.skuCategory,
    required this.skuType,
    required this.skuSubType,
    required this.itemCode,
    required this.description,
    required this.onHand,
    required this.available,
    required this.packKey,
    required this.itemStatus,
    required this.lot,
    required this.batchNo,
    required this.palletNo,
    required this.unit,
    required this.qtyPerPallet,
    required this.palletSize,
    required this.owner,
    required this.palletSize2,
    required this.totalCbm,
  });

  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    return WarehouseItem(
      grNo: json['gr_no'] ?? '',
      grDate: json['gr_date'] ?? '',
      tagNo: json['tag_no'] ?? '',
      warehouse: json['warehouse'] ?? '',
      locationName: json['location_name'] ?? '',
      skuCategory: json['sku_category'] ?? '',
      skuType: json['sku_type'] ?? '',
      skuSubType: json['sku_sub_type'] ?? '',
      itemCode: json['item_code'] ?? '',
      description: json['description'] ?? '',
      onHand: (json['on_hand'] ?? 0) as int,
      available: (json['available'] ?? 0) as int,
      packKey: json['pack_key'] ?? '',
      itemStatus: json['item_status'] ?? '',
      lot: json['lot'] ?? '',
      batchNo: json['batch_no'] ?? '',
      palletNo: json['pallet_no'] ?? '',
      unit: json['unit'] ?? '',
      qtyPerPallet: (json['qty_per_pallet'] ?? 0) as int,
      palletSize: json['pallet_size'] ?? '',
      owner: json['owner'] ?? '',
      palletSize2: json['pallet_size2'] ?? '',
      totalCbm: (json['total_cbm'] ?? 0).toDouble(),
    );
  }
}
