import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:excel/excel.dart'; // 엑셀 패키지
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDataScreen extends StatefulWidget {
  const AdminDataScreen({super.key});

  @override
  State<AdminDataScreen> createState() => _AdminDataScreenState();
}

class _AdminDataScreenState extends State<AdminDataScreen> {
  String statusMessage = "대기 중... (버튼을 눌러주세요)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("데이터 업로드 (식품중량 반영)")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                statusMessage, 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadExcelData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text("엑셀 읽어서 DB 덮어쓰기", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadExcelData() async {
    setState(() => statusMessage = "엑셀 파일 읽는 중...");

    try {
      final ByteData data = await rootBundle.load('assets/data/food.xlsx');
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables[excel.tables.keys.first];
      
      if (sheet == null) {
        setState(() => statusMessage = "시트를 찾을 수 없습니다.");
        return;
      }

      final db = FirebaseFirestore.instance;
      int count = 0;
      int limit = 2000; 

      // 헤더 매핑 (첫 줄 읽기)
      List<dynamic> headers = sheet.rows[0]; 
      Map<String, int> headerMap = {};
      
      for (int i = 0; i < headers.length; i++) {
        var value = headers[i]?.value.toString() ?? "";
        headerMap[value] = i; 
      }

      // ★ [필수] 식품중량 컬럼 확인
      if (!headerMap.containsKey("식품중량")) {
         setState(() => statusMessage = "오류: 엑셀에서 '식품중량' 컬럼을 찾을 수 없습니다.\n파일의 첫 줄을 확인해주세요.");
         return;
      }

      // 데이터 읽기 시작
      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        
        String foodName = _getVal(row, headerMap["식품명"]);
        if (foodName.isEmpty) continue;

        // ★ [핵심 로직] 1회 제공량(식품중량) 계산
        // 1. 식품중량 값 가져오기 (예: "500g", "200ml", "150")
        String weightStr = _getVal(row, headerMap["식품중량"]);
        double servingWeight = _parseServingSize(weightStr);

        // 2. 비율 계산 (식품중량 / 100g)
        // 만약 중량이 0이면(데이터 없음), 그냥 100g 기준으로 저장 (ratio = 1.0)
        double ratio = (servingWeight > 0) ? (servingWeight / 100.0) : 1.0;

        Map<String, dynamic> myFoodData = {
          "name": foodName,
          
          // ★ 모든 영양소에 ratio 곱하기 (실제 섭취량 기준)
          "kcal": (_parseNum(_getVal(row, headerMap["에너지(kcal)"])) * ratio).round(),
          "carbo": (_parseNum(_getVal(row, headerMap["탄수화물(g)"])) * ratio).round(),
          "protein": (_parseNum(_getVal(row, headerMap["단백질(g)"])) * ratio).round(),
          "fat": (_parseNum(_getVal(row, headerMap["지방(g)"])) * ratio).round(),
          
          "calcium": (_parseNum(_getVal(row, headerMap["칼슘(mg)"])) * ratio).round(),
          "sodium": (_parseNum(_getVal(row, headerMap["나트륨(mg)"])) * ratio).round(),
          "vit_c": (_parseNum(_getVal(row, headerMap["비타민 C(mg)"])) * ratio).round(),
          
          "trans_fat": (_parseNum(_getVal(row, headerMap["트랜스지방산(g)"])) * ratio).toStringAsFixed(1), // 소수점 유지
          
          "serving_size": servingWeight.toInt(), // 참고용으로 1인분 무게도 저장
          "category": "일반",
        };

        // ID에 /가 있으면 에러나므로 _로 치환
        String docId = foodName.replaceAll("/", "_");
        
        await db.collection('foods').doc(docId).set(myFoodData);
        count++;

        if (count % 100 == 0) setState(() => statusMessage = "$count개 처리 중...");
        if (count >= limit) break;
      }

      setState(() => statusMessage = "완료! 총 $count개 (1인분 기준) 등록됨.");

    } catch (e) {
      setState(() => statusMessage = "에러: $e");
      print(e);
    }
  }

  String _getVal(List<Data?> row, int? index) {
    if (index == null || index >= row.length) return "";
    return row[index]?.value.toString() ?? "";
  }

  double _parseNum(String val) {
    if (val == "" || val == "null") return 0.0;
    // 천단위 콤마(,) 제거 후 변환
    String cleanVal = val.replaceAll(',', '');
    return double.tryParse(cleanVal) ?? 0.0;
  }

  // "500g", "200" -> 500.0, 200.0 변환
  double _parseServingSize(String val) {
    if (val.isEmpty || val == "null") return 0.0; // 없으면 0 리턴 -> ratio 계산시 1.0됨
    // 숫자와 소수점만 남기고 나머지(g, ml 등) 제거
    String numStr = val.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numStr) ?? 0.0;
  }
}