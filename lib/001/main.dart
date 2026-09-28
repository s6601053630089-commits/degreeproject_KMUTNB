import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pub;
import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'warehouse_item.dart';

void main() {
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse Grid Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blueGrey, useMaterial3: true),
      home: const WarehouseGridScreen(),
    );
  }
}

class RackItem {
  final String location;
  final int rack;
  final int level;
  final int bay;
  bool isVacant;
  WarehouseItem? details;

  RackItem({
    required this.location,
    required this.rack,
    required this.level,
    required this.bay,
    this.isVacant = true,
    this.details,
  });
}

class WarehouseGridScreen extends StatefulWidget {
  const WarehouseGridScreen({super.key});

  @override
  State<WarehouseGridScreen> createState() => _WarehouseGridScreenState();
}

class _WarehouseGridScreenState extends State<WarehouseGridScreen> {
  final int totalRacks = 10;
  final int totalLevels = 10;
  final int totalBays = 4;

  int selectedRack = 1;
  String? highlightedLocation;
  final TextEditingController searchController = TextEditingController();
  Map<String, RackItem> rackData = {};

  @override
  void initState() {
    super.initState();
    _initializeEmptyGridFrame();
    _seedMockData();
  }

  void _initializeEmptyGridFrame() {
    // ปรับ totalRacks เป็น 10 หรือ 13 และ totalBays เป็น 4 หรือ 5 ตามต้องการ
    for (int r = 1; r <= totalRacks; r++) {
      for (int l = totalLevels; l >= 1; l--) {
        for (int b = 1; b <= totalBays; b++) {
          String loc = 'R$r-L$l-B$b';
          rackData[loc] = RackItem(
            location: loc,
            rack: r,
            level: l,
            bay: b,
            isVacant: true,
          );
        }
      }
    }
  }

  void _seedMockData() {
    rackData['R2-L5-B2']?.isVacant = false;
    rackData['R2-L5-B2']?.details = WarehouseItem(
      grNo: 'GR-20231001',
      grDate: '2023-10-01',
      tagNo: 'TAG-001',
      warehouse: 'WH-MAIN',
      locationName: 'R2-L5-B2',
      skuCategory: 'Electronics',
      skuType: 'Component',
      skuSubType: 'Chipset',
      itemCode: 'SKU-A101',
      description: 'Micro Controller Chip A1',
      onHand: 50,
      available: 50,
      packKey: 'BOX-10',
      itemStatus: 'Good',
      lot: 'LOT-9988',
      batchNo: 'BATCH-001',
      palletNo: 'PLT-8899',
      unit: 'PCS',
      qtyPerPallet: 500,
      palletSize: '120x100',
      owner: 'Company ABC',
      palletSize2: 'Standard',
      totalCbm: 1.25,
    );
  }

  Future<void> fetchWarehouseData() async {
    final url = Uri.parse('http://localhost:3000/api/items');

    try {
      final response = await http.get(url);

      // เช็กความพร้อมของหน้าจอก่อนใช้ context
      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> list = jsonDecode(response.body);

        setState(() {
          _initializeEmptyGridFrame();

          for (var itemJson in list) {
            var item = WarehouseItem.fromJson(itemJson);

            if (rackData.containsKey(item.locationName)) {
              rackData[item.locationName]?.isVacant = false;
              rackData[item.locationName]?.details = item;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ซิงค์ข้อมูลจาก Backend สำเร็จ!'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      // เช็กความพร้อมของหน้าจอก่อนใช้ context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการดึงข้อมูล: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // แปลงพิกัดจาก R1-01-01 เป็น R1-L1-B1
  String _formatLocationName(String rawLoc) {
    final regExp = RegExp(r'^R(\d+)-0*(\d+)-0*(\d+)$');
    final match = regExp.firstMatch(rawLoc.trim());
    if (match != null) {
      String rack = match.group(1)!;
      String level = match.group(2)!;
      String bay = match.group(3)!;
      return 'R$rack-L$level-B$bay';
    }
    return rawLoc.trim();
  }

  Future<void> loadExcelData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        var bytes = result.files.single.bytes!;

        // ใช้ excel_pub.Excel เพื่อแก้ Undefined name 'Excel'
        var excel = excel_pub.Excel.decodeBytes(bytes);

        setState(() {
          _initializeEmptyGridFrame();

          for (var table in excel.tables.keys) {
            var rows = excel.tables[table]!.rows;
            if (rows.isEmpty) continue;

            for (int i = 1; i < rows.length; i++) {
              var row = rows[i];
              if (row.isEmpty) continue;

              // อ่านข้อมูลตาม Index จริงของ DATAbase.xlsx
              String grNo = row[0]?.value?.toString().trim() ?? '';
              String rawLoc = row[4]?.value?.toString().trim() ?? '';
              String itemCode = row[8]?.value?.toString().trim() ?? '';
              String desc = row[9]?.value?.toString().trim() ?? '';
              int onHand = int.tryParse(row[10]?.value?.toString() ?? '0') ?? 0;
              String palletNo = row[21]?.value?.toString().trim() ?? '';

              if (rawLoc.isEmpty) continue;

              // แปลงชื่อพิกัด R1-01-01 -> R1-L1-B1
              String loc = _formatLocationName(rawLoc);

              if (rackData.containsKey(loc)) {
                WarehouseItem item = WarehouseItem(
                  grNo: grNo,
                  grDate: '',
                  tagNo: '',
                  warehouse: 'WH-MAIN',
                  locationName: loc,
                  skuCategory: '',
                  skuType: '',
                  skuSubType: '',
                  itemCode: itemCode,
                  description: desc,
                  onHand: onHand,
                  available: onHand,
                  packKey: '',
                  itemStatus: 'Good',
                  lot: '',
                  batchNo: '',
                  palletNo: palletNo,
                  unit: 'PCS',
                  qtyPerPallet: 0,
                  palletSize: '',
                  owner: '',
                  palletSize2: '',
                  totalCbm: 0.0,
                );

                rackData[loc]?.isVacant = false;
                rackData[loc]?.details = item;
              }
            }
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('นำเข้าไฟล์ "${result.files.single.name}" สำเร็จ!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอ่านไฟล์: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSmartSearch() {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    int? rackNum = int.tryParse(query);
    if (rackNum != null && rackNum >= 1 && rackNum <= totalRacks) {
      setState(() {
        selectedRack = rackNum;
        highlightedLocation = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('สลับไปที่ Rack $rackNum')));
      return;
    }

    RackItem? foundItem;
    for (var item in rackData.values) {
      if (!item.isVacant && item.details != null) {
        var d = item.details!;
        bool matchSKU = d.itemCode.toLowerCase().contains(query.toLowerCase());
        bool matchPallet = d.palletNo.toLowerCase().contains(
          query.toLowerCase(),
        );
        bool matchGR = d.grNo.toLowerCase().contains(query.toLowerCase());
        bool matchBatch = d.batchNo.toLowerCase().contains(query.toLowerCase());

        if (matchSKU || matchPallet || matchGR || matchBatch) {
          foundItem = item;
          break;
        }
      }
    }

    if (foundItem != null) {
      setState(() {
        selectedRack = foundItem!.rack;
        highlightedLocation = foundItem.location;
      });
      var d = foundItem.details!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'พบสินค้า [${d.itemCode}] / พาเลท [${d.palletNo}] ที่ Rack ${foundItem.rack} (ชั้น L${foundItem.level} ช่อง B${foundItem.bay})',
          ),
          backgroundColor: Colors.teal[700],
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลตรงกับคำค้นหา'),
          backgroundColor: Colors.deepOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Data Grid'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,

        actions: [
          ElevatedButton.icon(
            onPressed: loadExcelData,
            icon: const Icon(Icons.upload_file),
            label: const Text('นำเข้า Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),

          // ปุ่มที่ 2: ซิงค์ข้อมูล Backend
          ElevatedButton.icon(
            onPressed: fetchWarehouseData,
            icon: const Icon(Icons.sync),
            label: const Text('ซิงค์ข้อมูล Backend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: fetchWarehouseData,
            icon: const Icon(Icons.sync),
            label: const Text('ซิงค์ข้อมูล Backend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาเลขแรค / SKU / Pallet No / GR No',
                          hintStyle: const TextStyle(fontSize: 12),
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _handleSmartSearch,
                          ),
                        ),
                        onSubmitted: (_) => _handleSmartSearch(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSmartSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ค้นหา'),
                    ),
                    const Spacer(),
                    const Text(
                      'เลือกแรค: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: selectedRack,
                      items: List.generate(totalRacks, (index) => index + 1)
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text('Rack $r'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedRack = val;
                            highlightedLocation = null;
                            searchController.text = val.toString();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendBox(Colors.white, 'ช่องว่าง (Vacant)'),
                const SizedBox(width: 16),
                _buildLegendBox(Colors.teal, 'มีสินค้า (Occupied)'),
                const SizedBox(width: 16),
                _buildLegendBox(
                  Colors.orange,
                  'ตำแหน่งที่ค้นพบ (Found)',
                  borderColor: Colors.deepOrange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rack $selectedRack',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: totalLevels,
                          itemBuilder: (context, levelIdx) {
                            int levelNum = totalLevels - levelIdx;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      'L$levelNum',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(totalBays, (
                                      bayIdx,
                                    ) {
                                      int bayNum = bayIdx + 1;
                                      String loc =
                                          'R$selectedRack-L$levelNum-B$bayNum';
                                      RackItem item = rackData[loc]!;
                                      bool isHighlighted =
                                          (loc == highlightedLocation);

                                      Color boxColor = item.isVacant
                                          ? Colors.white
                                          : Colors.teal;
                                      if (isHighlighted) {
                                        boxColor = Colors.orange;
                                      }

                                      String tooltipMessage = '$loc: ช่องว่าง';
                                      if (!item.isVacant &&
                                          item.details != null) {
                                        var d = item.details!;
                                        tooltipMessage =
                                            '''
พิกัด: $loc
SKU: ${d.itemCode} (${d.description})
Pallet No: ${d.palletNo}
GR No: ${d.grNo} (${d.grDate})
Batch: ${d.batchNo} | Lot: ${d.lot}
จำนวน: ${d.onHand} ${d.unit}
''';
                                      }

                                      return Tooltip(
                                        message: tooltipMessage,
                                        padding: const EdgeInsets.all(8.0),
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: boxColor,
                                            border: Border.all(
                                              color: isHighlighted
                                                  ? Colors.red
                                                  : Colors.grey[400]!,
                                              width: isHighlighted ? 2.5 : 1.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'B$bayNum',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isHighlighted
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color:
                                                  (item.isVacant &&
                                                      !isHighlighted)
                                                  ? Colors.black54
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBox(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor ?? Colors.grey),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
