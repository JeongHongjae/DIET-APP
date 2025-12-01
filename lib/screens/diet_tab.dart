import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DietTab extends StatefulWidget {
  const DietTab({super.key});

  @override
  State<DietTab> createState() => _DietTabState();
}

class _DietTabState extends State<DietTab> {
  DateTime _selectedDate = DateTime.now();
  bool _isDetailView = false; 

  final List<String> _favorites = ["현미밥", "달걀부침", "덮밥", "깍두기", "라면"];

  // ★ [수정] 콜레스테롤 삭제 및 기준치 업데이트
  final Map<String, double> _rdi = {
    'kcal': 2500, 
    'carbo': 324, 
    'protein': 55, 
    'fat': 54,
    'vit_c': 100, 
    'calcium': 700, 
    'sodium': 2000, 
    'trans_fat': 0.5, // 트랜스지방 기준치 명시 (0.5g 초과 시 위험)
  };

  Map<String, Map<String, String>> _tempMemoImage = {
    "breakfast": {"memo": "", "image": ""},
    "lunch": {"memo": "", "image": ""},
    "dinner": {"memo": "", "image": ""},
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
  }

  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String get _selectedDateString => _getDateString(_selectedDate);

  DateTime get _monday {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }
  DateTime get _sunday => _monday.add(const Duration(days: 6));

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('diet_logs');
    
    if (_isDetailView) {
      query = query.where('date', isEqualTo: _getDateString(_selectedDate));
    } else {
      query = query
          .where('date', isGreaterThanOrEqualTo: _getDateString(_monday))
          .where('date', isLessThanOrEqualTo: _getDateString(_sunday));
    }

    return Scaffold(
      appBar: _isDetailView ? _buildDetailAppBar() : _buildSummaryAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("데이터 로드 중 오류 발생"));
          
          final docs = snapshot.data?.docs ?? [];
          
          if (_isDetailView) {
            return _buildDetailBody(docs);
          } else {
            return _buildSummaryBody(docs);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildSummaryAppBar() {
    return AppBar(title: const Text("식단 캘린더 📅"), centerTitle: true);
  }

  PreferredSizeWidget _buildDetailAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => setState(() => _isDetailView = false),
      ),
      title: Text(DateFormat('MM월 dd일 (E)', 'ko_KR').format(_selectedDate)),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _saveMemoAndImage,
          child: const Text("저장", style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  // ==================== 1. 주간 요약 화면 (메인) ====================

  Widget _buildSummaryBody(List<QueryDocumentSnapshot> docs) {
    // ★ [수정] 단순 칼로리가 아니라, 날짜별 전체 영양소 집계가 필요함 (별 색깔 판단용)
    Map<String, Map<String, double>> dailyStats = {};
    
    // 주간 누적 (부족 영양소 분석용)
    Map<String, double> weeklyNutrients = {
      'carbo': 0, 'protein': 0, 'fat': 0, 'vit_c': 0, 'calcium': 0
    };

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      String date = data['date'];
      
      // 날짜별 통계 초기화
      if (!dailyStats.containsKey(date)) {
        dailyStats[date] = _initNutrients();
      }

      // 영양소 합산
      _rdi.keys.forEach((key) {
        double val = double.tryParse(data[key]?.toString() ?? "0") ?? 0;
        dailyStats[date]![key] = (dailyStats[date]![key] ?? 0) + val;
        
        // 주간 누적에도 추가
        if (weeklyNutrients.containsKey(key)) {
          weeklyNutrients[key] = (weeklyNutrients[key] ?? 0) + val;
        }
      });
    }

    // 주간 칼로리 맵 (그래프용)
    Map<String, double> dailyKcal = {};
    dailyStats.forEach((key, value) {
      dailyKcal[key] = value['kcal'] ?? 0;
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWeeklyCalendar(dailyKcal),
          const SizedBox(height: 20),
          _buildWeeklyAnalysisCard(dailyKcal, weeklyNutrients),
          const SizedBox(height: 20),
          _buildDailyList(dailyStats), // ★ 수정된 집계 데이터 전달
        ],
      ),
    );
  }

  Widget _buildWeeklyAnalysisCard(Map<String, double> dailyKcal, Map<String, double> weeklyNutrients) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("주간 식단 리포트 📊", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildWeeklyBarGraph(dailyKcal)),
              const SizedBox(width: 15),
              Container(width: 1, height: 120, color: Colors.grey[200]),
              const SizedBox(width: 15),
              Expanded(flex: 4, child: _buildDeficientNutrients(weeklyNutrients)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarGraph(Map<String, double> dailyKcal) {
    double maxKcal = _rdi['kcal']!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        DateTime day = _monday.add(Duration(days: index));
        String dateKey = _getDateString(day);
        double currentKcal = dailyKcal[dateKey] ?? 0;
        double percent = (currentKcal / maxKcal).clamp(0.0, 1.0);
        bool isToday = day.day == DateTime.now().day;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(width: 8, height: 80, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                Container(
                  width: 8,
                  height: 80 * percent,
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(DateFormat('E', 'ko_KR').format(day),
                style: TextStyle(fontSize: 10, color: isToday ? Colors.blue : Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }

  Widget _buildDeficientNutrients(Map<String, double> weeklyTotal) {
    Map<String, double> percentages = {};
    weeklyTotal.forEach((key, val) {
      if (_rdi.containsKey(key)) {
        percentages[key] = val / (_rdi[key]! * 7);
      }
    });

    var sortedKeys = percentages.keys.toList()..sort((a, b) => percentages[a]!.compareTo(percentages[b]!));
    var lacking = sortedKeys.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("부족해요! 💊", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 10),
        if (lacking.isEmpty)
          const Text("완벽해요!", style: TextStyle(fontSize: 12))
        else
          ...lacking.map((key) {
            String name = _getNutrientName(key);
            int pct = (percentages[key]! * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, size: 12, color: Colors.red[300]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text("$name ${pct}%", 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWeeklyCalendar(Map<String, double> dailyKcal) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          DateTime day = _monday.add(Duration(days: index));
          bool isSelected = day.day == _selectedDate.day;
          bool isToday = day.day == DateTime.now().day;
          bool hasRecord = (dailyKcal[_getDateString(day)] ?? 0) > 0;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Column(
              children: [
                Text(DateFormat('E', 'ko_KR').format(day),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (isToday ? Colors.blue[50] : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Text("${day.day}",
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
                const SizedBox(height: 4),
                Icon(Icons.circle, size: 5, color: hasRecord ? Colors.blue[300] : Colors.transparent),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ★ [수정] 별 색깔 로직 (건강/비건강 판별)
  Widget _buildDailyList(Map<String, Map<String, double>> dailyStats) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      itemBuilder: (context, index) {
        DateTime day = _monday.add(Duration(days: index));
        String dateKey = _getDateString(day);
        
        Map<String, double> nutrients = dailyStats[dateKey] ?? _initNutrients();
        double kcal = nutrients['kcal'] ?? 0;

        // 1. 별 개수 (칼로리 섭취량 기준)
        int stars = 0;
        if (kcal > _rdi['kcal']! * 0.9) stars = 3;
        else if (kcal > _rdi['kcal']! * 0.6) stars = 2;
        else if (kcal > _rdi['kcal']! * 0.3) stars = 1;

        // 2. ★ 별 색깔 (건강 여부 판단)
        bool isUnhealthy = false;
        // 나트륨, 트랜스지방, 탄수화물 과다 섭취
        if (nutrients['sodium']! > _rdi['sodium']! || 
            nutrients['trans_fat']! > _rdi['trans_fat']! || 
            nutrients['carbo']! > _rdi['carbo']!) {
          isUnhealthy = true;
        }
        // 단백질, 비타민C 부족 (별이 3개 다 찼을 때만 엄격하게 체크하거나, 항상 체크)
        // 여기서는 데이터가 어느정도 찼을때(별1개이상) 부족하면 빨간불로 표시
        if (stars > 0) {
           if (nutrients['protein']! < _rdi['protein']! * 0.5 || // 50% 미만이면 부족으로 간주
               nutrients['vit_c']! < _rdi['vit_c']! * 0.5) {
             isUnhealthy = true;
           }
        }

        Color starColor = isUnhealthy ? Colors.redAccent : Colors.amber;
        String statusText = isUnhealthy ? "(관리필요)" : "(건강함)";
        if (stars == 0) statusText = ""; // 기록 없으면 텍스트 없음

        return ListTile(
          onTap: () {
            setState(() {
              _selectedDate = day;
              _isDetailView = true;
            });
          },
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text("${day.month}/${day.day}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Row(
            children: [
              Text(DateFormat('EEEE', 'ko_KR').format(day)),
              const SizedBox(width: 8),
              Text(statusText, style: TextStyle(fontSize: 12, color: starColor, fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Icon(
              i < stars ? Icons.star : Icons.star_border, 
              color: starColor, size: 20
            )),
          ),
        );
      },
    );
  }

  // ==================== 2. 상세 기록 화면 (일일) ====================

  Widget _buildDetailBody(List<QueryDocumentSnapshot> docs) {
    Map<String, double> dailyTotal = _initNutrients();
    Map<String, List<Map<String, dynamic>>> meals = {
      'breakfast': [], 'lunch': [], 'dinner': []
    };

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      String type = data['mealType'] ?? 'breakfast';
      if (meals.containsKey(type)) meals[type]?.add(data);

      dailyTotal.forEach((key, val) {
        dailyTotal[key] = val + (double.tryParse(data[key]?.toString() ?? "0") ?? 0.0);
      });
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildNutrientDashboard(dailyTotal),
          const SizedBox(height: 30),
          _buildMealSection("아침", "breakfast", meals['breakfast']!),
          const SizedBox(height: 30),
          _buildMealSection("점심", "lunch", meals['lunch']!),
          const SizedBox(height: 30),
          _buildMealSection("저녁", "dinner", meals['dinner']!),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildNutrientDashboard(Map<String, double> total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("오늘의 영양 섭취", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("${total['kcal']!.toInt()} / ${_rdi['kcal']!.toInt()} kcal", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMacroNutrientCircle("탄수화물", total['carbo']!, _rdi['carbo']!, Colors.purple)),
              Expanded(child: _buildMacroNutrientCircle("단백질", total['protein']!, _rdi['protein']!, Colors.blue)),
              Expanded(child: _buildMacroNutrientCircle("지방", total['fat']!, _rdi['fat']!, Colors.orange)),
            ],
          ),
          const SizedBox(height: 20),
          _buildMicroNutrientBar("비타민 C", total['vit_c']!, _rdi['vit_c']!, "mg"),
          _buildMicroNutrientBar("나트륨", total['sodium']!, _rdi['sodium']!, "mg", isLimit: true),
          // ★ 콜레스테롤 삭제됨
          _buildMicroNutrientBar("트랜스지방", total['trans_fat']!, _rdi['trans_fat']!, "g", isLimit: true),
        ],
      ),
    );
  }

  Widget _buildMealSection(String label, String mealKey, List<Map<String, dynamic>> mealLogs) {
    double mCarbo = 0, mProtein = 0, mFat = 0;
    for (var log in mealLogs) {
      mCarbo += (log['carbo'] ?? 0);
      mProtein += (log['protein'] ?? 0);
      mFat += (log['fat'] ?? 0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _pickImage(mealKey),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      image: _tempMemoImage[mealKey]!['image'] != "" 
                          ? DecorationImage(image: FileImage(File(_tempMemoImage[mealKey]!['image']!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _tempMemoImage[mealKey]!['image'] == ""
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.camera_alt, color: Colors.grey), Text("사진 추가", style: TextStyle(fontSize: 10, color: Colors.grey))],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 5,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniBar("탄수화물", mCarbo, Colors.purple),
                      const SizedBox(height: 8),
                      _buildMiniBar("단백질", mProtein, Colors.blue),
                      const SizedBox(height: 8),
                      _buildMiniBar("지방", mFat, Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (mealLogs.isNotEmpty)
            Column(
              children: mealLogs.map((log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(log['foodName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${log['kcal']} kcal"),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => _deleteLog(log['id']),
                  ),
                ),
              )).toList(),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showInputModal(mealKey),
              icon: const Icon(Icons.add),
              label: const Text("음식 추가하기"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (val) {
              _tempMemoImage[mealKey]!['memo'] = val;
            },
            decoration: InputDecoration(
              hintText: "$label 식사 메모...",
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ★ [수정] 콜레스테롤 제거된 초기화 함수
  Map<String, double> _initNutrients() {
    return {
      'kcal': 0, 'carbo': 0, 'protein': 0, 'fat': 0,
      'vit_c': 0, 'calcium': 0, 'sodium': 0, 'trans_fat': 0
    };
  }

  String _getNutrientName(String key) {
    switch(key) {
      case 'carbo': return '탄수화물';
      case 'protein': return '단백질';
      case 'fat': return '지방';
      case 'vit_c': return '비타민C';
      case 'calcium': return '칼슘';
      case 'sodium': return '나트륨';
      case 'trans_fat': return '트랜스지방';
      default: return key;
    }
  }
  
  Widget _buildMacroNutrientCircle(String label, double current, double goal, Color color) {
    double percent = goal == 0 ? 0 : (current / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(value: percent, color: color, backgroundColor: Colors.grey[200], strokeWidth: 5),
            ),
            Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text("${current.toInt()}g", style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMicroNutrientBar(String label, double current, double goal, String unit, {bool isLimit = false}) {
    double percent = goal == 0 ? 0 : (current / goal).clamp(0.0, 1.0);
    Color barColor = isLimit && percent >= 1.0 ? Colors.red : Colors.green;
    
    // 작은 숫자(10 미만)는 소수점 1자리까지 표시
    String currentStr = goal < 10 ? current.toStringAsFixed(1) : current.toInt().toString();
    String goalStr = goal < 10 ? goal.toStringAsFixed(1) : goal.toInt().toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(
            child: LinearProgressIndicator(value: percent, color: barColor, backgroundColor: Colors.grey[200], minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60, 
            child: Text("$currentStr/$goalStr$unit", style: TextStyle(fontSize: 10, color: isLimit && percent >= 1.0 ? Colors.red : Colors.grey), textAlign: TextAlign.end)
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, double val, Color color) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(
          child: LinearProgressIndicator(value: (val / 100).clamp(0.0, 1.0), color: color, backgroundColor: Colors.grey[100], minHeight: 6, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text("${val.toInt()}g", style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showInputModal(String mealKey) {
    TextEditingController searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SizedBox(
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("음식 추가", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: "음식 검색 (예: 김밥)",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 15),
                    if (searchCtrl.text.isEmpty) ...[
                      const Text("즐겨찾기", style: TextStyle(color: Colors.grey)),
                      Wrap(
                        spacing: 8,
                        children: _favorites.map((food) => ActionChip(
                          label: Text(food),
                          backgroundColor: Colors.amber[50],
                          onPressed: () {
                            searchCtrl.text = food;
                            setModalState(() {});
                          },
                        )).toList(),
                      ),
                    ],
                    Expanded(
                      child: searchCtrl.text.isNotEmpty 
                        ? _buildSearchResults(searchCtrl.text, mealKey) 
                        : const Center(child: Text("음식을 검색하거나 즐겨찾기를 선택하세요.")),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(String query, String mealKey) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("검색 결과가 없습니다."));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${data['kcal']} kcal"),
              trailing: const Icon(Icons.add, color: Colors.blue),
              onTap: () {
                _addFoodLog(mealKey, data);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _addFoodLog(String mealType, Map<String, dynamic> foodData) async {
    await FirebaseFirestore.instance.collection('diet_logs').add({
      'date': _selectedDateString, 
      'mealType': mealType,
      'foodName': foodData['name'],
      'kcal': foodData['kcal'] ?? 0,
      'carbo': foodData['carbo'] ?? 0,
      'protein': foodData['protein'] ?? 0,
      'fat': foodData['fat'] ?? 0,
      'vit_c': foodData['vit_c'] ?? 0,
      'calcium': foodData['calcium'] ?? 0,
      'sodium': foodData['sodium'] ?? 0,
      // ★ 콜레스테롤 저장 제외
      'trans_fat': foodData['trans_fat'] ?? 0,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _deleteLog(String? docId) async {
    if (docId != null) {
      await FirebaseFirestore.instance.collection('diet_logs').doc(docId).delete();
    }
  }

  Future<void> _pickImage(String mealKey) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tempMemoImage[mealKey]!['image'] = pickedFile.path;
      });
    }
  }

  void _saveMemoAndImage() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 완료! (메모/사진은 현재 세션에만 유지됩니다)")));
  }
}