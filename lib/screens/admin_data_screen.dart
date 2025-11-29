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
  String statusMessage = "대기 중... (엑셀 파일 준비됨)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("엑셀 데이터 업로드")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: _uploadExcelData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("엑셀 읽어서 DB에 쏘기", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadExcelData() async {
    setState(() => statusMessage = "엑셀 파일 읽는 중...");

    try {
      // 1. 엑셀 파일 로드 (파일명: food.xlsx)
      final ByteData data = await rootBundle.load('assets/data/food.xlsx');
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);

      // 2. 첫 번째 시트 가져오기
      final sheet = excel.tables[excel.tables.keys.first];
      
      if (sheet == null) {
        setState(() => statusMessage = "시트를 찾을 수 없습니다.");
        return;
      }

      final db = FirebaseFirestore.instance;
      int count = 0;
      int limit = 2000; // 2천개 제한

      // 3. 한 줄씩 읽기 (첫 줄은 제목이니까 건너뜀)
      // row[0]: A열, row[1]: B열 ... 엑셀 열 순서를 확인해야 합니다!
      // ★ 중요: 엑셀 파일을 열어서 A, B, C... 열이 뭔지 보고 아래 인덱스 숫자를 고치세요.
      
      // (보통 식약처 엑셀 순서 예시)
      // A(0): 번호, B(1): 식품코드, C(2): 식품명, ... Q(16): 에너지 ...
      
      // 정확성을 위해 엑셀 열 제목을 먼저 매핑하는 로직을 씁니다.
      List<dynamic> headers = sheet.rows[0]; // 첫 줄(제목)
      Map<String, int> headerMap = {};
      
      for (int i = 0; i < headers.length; i++) {
        var value = headers[i]?.value.toString() ?? "";
        headerMap[value] = i; // 예: "식품명": 2
      }

      // 필수 항목이 없으면 중단
      if (!headerMap.containsKey("식품명") || !headerMap.containsKey("에너지(kcal)")) {
         setState(() => statusMessage = "엑셀 헤더 이름을 찾을 수 없습니다.\n파일의 첫 줄을 확인하세요.");
         return;
      }

      // 데이터 읽기 시작 (1번째 줄부터)
      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        
        // 이름 가져오기
        String foodName = _getVal(row, headerMap["식품명"]);
        if (foodName.isEmpty) continue;

        // 대표 이름 추출 (김밥_채소 -> 김밥) - 로직 유지
        String mainName = foodName.split('_')[0]; 
        
        Map<String, dynamic> myFoodData = {
          "name": foodName,
          
          // ★ 엑셀의 한글 제목과 정확히 일치해야 합니다! (띄어쓰기, 괄호 주의)
          "kcal": _parseNum(_getVal(row, headerMap["에너지(kcal)"])),
          "protein": _parseNum(_getVal(row, headerMap["단백질(g)"])),
          "fat": _parseNum(_getVal(row, headerMap["지방(g)"])),
          "carbo": _parseNum(_getVal(row, headerMap["탄수화물(g)"])),
          
          "calcium": _parseNum(_getVal(row, headerMap["칼슘(mg)"])),
          "sodium": _parseNum(_getVal(row, headerMap["나트륨(mg)"])),
          
          // 비타민 C (엑셀 파일 열어서 제목 확인 필수! 보통 '비타민 C(mg)' 임)
          "vit_c": _parseNum(_getVal(row, headerMap["비타민 C(mg)"])),

          // 엑셀 헤더 이름이 정확해야 합니다!
          "cholesterol": _parseNum(_getVal(row, headerMap["콜레스테롤(mg)"])),
          "saturated_fat": _parseNum(_getVal(row, headerMap["포화지방산(g)"])), 
          "trans_fat": _parseNum(_getVal(row, headerMap["트랜스지방산(g)"])),
          
          "category": "일반",
        };

        // ID에 /가 있으면 에러나므로 _로 치환
        String docId = foodName.replaceAll("/", "_");
        
        await db.collection('foods').doc(docId).set(myFoodData);
        count++;

        if (count % 100 == 0) setState(() => statusMessage = "$count개 처리 중...");
        if (count >= limit) break;
      }

      setState(() => statusMessage = "완료! 총 $count개 등록됨.");

    } catch (e) {
      setState(() => statusMessage = "에러: $e");
      print(e);
    }
  }

  // 엑셀 셀 값 가져오는 헬퍼 함수
  String _getVal(List<Data?> row, int? index) {
    if (index == null || index >= row.length) return "";
    return row[index]?.value.toString() ?? "";
  }

  double _parseNum(String val) {
    if (val == "" || val == "null") return 0.0;
    return double.tryParse(val) ?? 0.0;
  }
}