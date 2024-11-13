import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/category_model.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
import '../providers/category_provider.dart';
import 'root_screen.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final String? selectedEvent;
  final EventModel? event;
  final EventResultModel? actualevent;
  final bool isFinalEvent;
  final bool isEditing;
  final String? eventTitle;
  final DateTime? startTime;
  final DateTime? endTime;
  final Function? onEventAdded;


  AddEventScreen({
    this.selectedDate,
    this.selectedTime,
    this.event,
    this.actualevent,
    this.isFinalEvent = false,
    this.isEditing = false,
    this.eventTitle,
    this.startTime,
    this.endTime,
    this.selectedEvent,
    this.onEventAdded,
  });

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  DateTime? _selectedDate;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isRecurring = false; // 변경된 초기화 코드
  bool _showOnCalendar = true;
  bool _isAllDay = false;
  CategoryModel? selectedCategory;
  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.isEditing
            ? (widget.isFinalEvent
            ? widget.actualevent?.eventResultTitle
            : widget.event?.eventTitle)
            : widget.eventTitle);
    _contentController = TextEditingController(
        text: widget.isEditing
            ? (widget.isFinalEvent
            ? widget.actualevent?.eventResultTitle
            : widget.event?.eventContent)
            : null);
    _selectedDate = widget.selectedDate ??
        (widget.isEditing
            ? (widget.isFinalEvent ? DateTime.now() : widget.event?.eventDate)
            : null);
    _startTime = widget.selectedTime ??
        (widget.isEditing
            ? (widget.isFinalEvent
            ? DateTime.now()
            : widget.event?.eventSttTime)
            : null);
    _endTime = widget.actualevent?.eventResultEndTime ??
        (widget.isEditing
            ? (widget.isFinalEvent
            ? DateTime.now()
            : widget.event?.eventEndTime)
            : null);

    _isRecurring = widget.isEditing
        ? (widget.isFinalEvent ? false : widget.event?.isRecurring ?? false)
        : false;
    _showOnCalendar = widget.isEditing
        ? (widget.isFinalEvent ? true : widget.event?.showOnCalendar ?? true)
        : true;
    _isAllDay =
        widget.event?.isAllDay == true || widget.actualevent?.isAllDay == true;

    // 카테고리 초기화 추가
    selectedCategoryId = widget.isEditing
        ? (widget.isFinalEvent
        ? widget.actualevent?.categoryId
        : widget.event?.categoryId)
        : null;
    _getCurrentUser().then((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    if (currentUserId == null) {
      print('Error: User is not logged in');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('userId', isEqualTo: currentUserId)
          .get();
      setState(() {
        categories = snapshot.docs.map((doc) => {
          'categoryId': doc.id,
          'categoryName': doc['categoryName'] as String,
          'colorCode': doc['colorCode'] as String,
          'userId': doc['userId'] as String,
          // 필요한 다른 필드들을 여기에 추가하세요
        }).toList();

        // 카테고리가 선택되지 않은 경우에만 첫 번째 카테고리를 선택
        if (selectedCategoryId == null && categories.isNotEmpty) {
          selectedCategoryId = categories.first['categoryId'] as String;}
      });
    } catch (e) {
      print('Error loading categories: $e');
      // 에러 처리 로직 추가 (예: 사용자에게 알림)
    }
  }
  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
    } else {
      print('Error: User is not logged in');
      // 여기에 로그인 페이지로 리디렉션하는 로직을 추가할 수 있습니다.
    }
  }




  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomScrollDatePicker(
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final DateTime initialDateTime = isStartTime ? (_startTime ?? DateTime.now()) : (_endTime ?? DateTime.now());

    final TimeOfDay? selectedTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePicker(
          initialTime: TimeOfDay.fromDateTime(initialDateTime),
          use24HourFormat: true,
          isEndTime: !isStartTime,  // 종료 시간 선택인지 여부
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        final DateTime currentDate = _selectedDate ?? DateTime.now();
        final DateTime newDateTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          selectedTime.hour,
          0,
        );



        if (isStartTime) {
          _startTime = newDateTime;
          // 종료 시간이 시작 시간보다 이전이면 종료 시간을 시작 시간 + 1시간으로 설정
          if (_endTime != null && _endTime!.isBefore(_startTime!)) {
            _endTime = _startTime!.add(Duration(hours: 1));
          }
        } else {
          // 종료 시간이 시작 시간보다 이전이면 경고 메시지 표시
          if (_startTime != null && newDateTime.isBefore(_startTime!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('종료 시간은 시작 시간 이후여야 합니다.')),
            );
            return;
          }
          _endTime = newDateTime;
        }
      });

      _adjustDateForMidnight(isStartTime);
    }
  }



  // 종일 여부 토글을 위한 메서드
  void _toggleAllDay(bool value) {
    setState(() {
      _isAllDay = value;
      if (_isAllDay) {
        _startTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        _endTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59);
      }
    });
  }

  DateTime combineDateTime(DateTime date, DateTime time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }



  Future<void> _saveEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인이 필요합니다.')));

        }

        // 날짜와 시간 처리
        final eventDate = _selectedDate ?? DateTime.now();
        final startTimeOfDay = _timeOfDayFromDateTime(_startTime!) ?? TimeOfDay.now();
        final endTimeOfDay = _endTime != null ? _timeOfDayFromDateTime(_endTime!) : null;

        final startDateTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          startTimeOfDay.hour,
          0,
        );
        final endDateTime = endTimeOfDay != null
            ? DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          endTimeOfDay.hour,
          0,
        )
            : startDateTime.add(Duration(hours: 1));

        if (startDateTime.isAtSameMomentAs(endDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('시작 시간과 종료 시간이 같을 수 없습니다.')),
          );
          return; // 저장 프로세스 중단
        }


        if (widget.isFinalEvent) {
          await _saveFinalEvent(startDateTime, endDateTime);
        } else {
          await _saveRegularEvent(startDateTime, endDateTime);
        }

        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.loadCategories();


        if (widget.onEventAdded != null) {
          widget.onEventAdded!();
        }

        String message = widget.isEditing ? '일정이 수정되었습니다.' : '일정이 추가되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error saving event: $e');
        String errorMessage = e.toString().contains("User is not logged in")
            ? '로그인이 필요합니다.'
            : '일정 처리에 실패했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));


      }
    }
  }

  TimeOfDay? _timeOfDayFromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  DateTime _calculateEndDateTime(DateTime date, TimeOfDay startTime, TimeOfDay? endTime) {
    if (endTime == null) {
      // 종료 시간이 지정되지 않은 경우, 시작 시간으로부터 1시간 후로 설정
      return _combineDateAndTime(date, startTime).add(Duration(hours: 1));
    }

    DateTime endDateTime = _combineDateAndTime(date, endTime);
    if (endDateTime.isBefore(_combineDateAndTime(date, startTime))) {
      // 종료 시간이 시작 시간보다 이전인 경우 다음 날로 설정
      endDateTime = endDateTime.add(Duration(days: 1));
    }
    return endDateTime;
  }

  Future<void> _saveFinalEvent(DateTime startDateTime, DateTime endDateTime) async {
    String eventRetId = widget.actualevent?.eventResultId ?? '';
    if (eventRetId.isEmpty) {
      eventRetId = FirebaseFirestore.instance.collection('result_events').doc().id;
    }
    print('eventRetId: $eventRetId');

    String userId = getCurrentUserId();

    final eventResultData = EventResultModel(
      eventResultId: eventRetId,
      eventId: widget.actualevent?.eventId ?? '',
      categoryId: selectedCategoryId ?? '',
      userId: userId, // 사용자 ID 설정
      eventResultDate: _selectedDate,
      eventResultSttTime: combineDateTime(_selectedDate!, _startTime!),
      eventResultEndTime: combineDateTime(
          _endTime!.isBefore(_startTime!) ? _selectedDate!.add(Duration(days: 1)) : _selectedDate!,
          _endTime!
      ),
      eventResultTitle: _titleController.text,
      eventResultContent: _contentController.text,
      isAllDay: _isAllDay ? true : false,
      completedYn: '',
    );

    try {
      final docRef = FirebaseFirestore.instance.collection('result_events').doc(eventRetId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update(eventResultData.toMap());
      } else {
        await docRef.set(eventResultData.toMap());
      }
    } catch (e) {
      print('Error saving event: $e');
      // 추가적인 오류 처리 로직
    }
  }
  String getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception("User is not logged in");
    }
  }

  void _adjustDateForMidnight(bool isStartTime) {
    if (!isStartTime) {
      if (_endTime != null && _endTime!.hour == 0 && _endTime!.minute == 0) {
        setState(() {
          _endTime = _endTime!.add(Duration(days: 1));
        });
      }
    }
  }

  Future<void> _saveRegularEvent(DateTime startDateTime, DateTime endDateTime) async {
    String eventId = widget.event?.eventId ?? '';
    if (eventId.isEmpty) {
      eventId = FirebaseFirestore.instance.collection('events').doc().id;
    }

    String userId = getCurrentUserId();

    final eventData = EventModel(
      eventId: eventId,
      eventTitle: _titleController.text,
      eventDate: _selectedDate,
      eventContent: _contentController.text,
      categoryId: selectedCategoryId ?? categories.first['categoryId'],
      userId: userId,
      eventSttTime: startDateTime,
      eventEndTime: endDateTime,
      isAllDay: _isAllDay,
      completedYn: 'N',
      isRecurring: _isRecurring,
      showOnCalendar: _showOnCalendar,
      originalEventId: eventId, // 여기에 originalEventId 추가

    );

    if (widget.isEditing) {
      // 기존 이벤트 업데이트
      await _updateRecurringEvents(eventData);
    } else {
      // 새 이벤트 생성
      if (_isRecurring) {
        await _createRecurringEvents(eventData);
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .set(eventData.toMap());
      }
    }
  }

  Future<void> _updateRecurringEvents(EventModel baseEvent) async {
    final batch = FirebaseFirestore.instance.batch();

    // 기존의 모든 관련 반복 일정 찾기
    final existingEvents = await FirebaseFirestore.instance
        .collection('events')
        .where('originalEventId', isEqualTo: baseEvent.originalEventId)
        .get();

    if (existingEvents.docs.isEmpty) {
      // 기존 이벤트가 없으면 새로 생성
      await _createRecurringEvents(baseEvent);
      return;
    }

    // 모든 관련 반복 일정 업데이트
    for (var doc in existingEvents.docs) {
      final existingEvent = EventModel.fromMap(doc.data());
      final updatedEvent = baseEvent.copyWith(
        eventDate: existingEvent.eventDate,
        eventSttTime: DateTime(
          existingEvent.eventDate!.year,
          existingEvent.eventDate!.month,
          existingEvent.eventDate!.day,
          baseEvent.eventSttTime!.hour,
          0,
        ),
        eventEndTime: DateTime(
          existingEvent.eventDate!.year,
          existingEvent.eventDate!.month,
          existingEvent.eventDate!.day,
          baseEvent.eventEndTime!.hour,
        0,
        ),
        originalEventId: baseEvent.originalEventId,
      );
      batch.update(doc.reference, updatedEvent.toMap());
    }

    // 반복 설정이 꺼진 경우, 첫 번째 이벤트만 남기고 나머지 삭제
    if (baseEvent.isRecurring == false && existingEvents.docs.length > 1) {
      for (int i = 1; i < existingEvents.docs.length; i++) {
        batch.delete(existingEvents.docs[i].reference);
      }
    }

    // 일괄 업데이트 실행
    await batch.commit();
  }


  Future<void> _createRecurringEvents(EventModel baseEvent) async {
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < 4; i++) {
      final eventDate = baseEvent.eventDate!.add(Duration(days: 7 * i));
      final event = baseEvent.copyWith(
        eventId: i == 0 ? baseEvent.eventId : FirebaseFirestore.instance.collection('events').doc().id,
        eventDate: eventDate,
        eventSttTime: DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          baseEvent.eventSttTime!.hour,
          baseEvent.eventSttTime!.minute,
        ),
        eventEndTime: DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          baseEvent.eventEndTime!.hour,
          baseEvent.eventEndTime!.minute,
        ),
      );
      batch.set(FirebaseFirestore.instance.collection('events').doc(event.eventId), event.toMap());
    }

    await batch.commit();
  }

  Widget _buildDateTimeSelector() {
    return _buildCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.calendar_month, color: accentColor),
            title: Text('날짜'),
            subtitle: Text(_selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : '날짜를 선택하세요'),
            onTap: () => _selectDate(context),
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.access_time, color: accentColor),
            title: Text('시작 시간'),
            subtitle: Text(_startTime != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(_startTime!)
                : '시작 시간을 선택하세요'),
            onTap: () => _selectTime(context, true),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.access_time_filled, color: accentColor),
            title: Text('종료 시간'),
            subtitle: Text(_endTime != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(_endTime!)
                : '종료 시간을 선택하세요'),
            onTap: () => _selectTime(context, false),
          ),
        ],
      ),
    );
  }
  final Color mainColor = Colors.lightBlueAccent.withOpacity(0.1); // 스케줄러의 계획 항목 바탕색
  final Color accentColor =  Colors.lightBlue[900]!; // 강조색

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '일정 수정' : '일정 추가'),
        centerTitle: true,
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _buildCard(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '일정 이름',
                        prefixIcon: Icon(Icons.event, color: accentColor),
                        border: InputBorder.none,
                      ),
                      validator: (value) => value?.isEmpty ?? true ? '제목을 입력하세요' : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildCard(
                    child: TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: '내용',
                        prefixIcon: Icon(Icons.description, color: accentColor),
                        border: InputBorder.none,
                      ),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? '내용을 입력하세요' : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDateTimeSelector(),
                  SizedBox(height: 16),
                  _buildCard(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: '카테고리',
                        prefixIcon: Icon(Icons.category, color: accentColor),
                        border: InputBorder.none,

                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['categoryId'] as String,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(category['colorCode'])),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(category['categoryName'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategoryId = newValue;
                          });
                          if (widget.onEventAdded != null) {
                            widget.onEventAdded!();
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildCustomToggle(
                    icon: Icons.repeat,
                    title: '반복 여부',
                    subtitle: _isRecurring ? '매주 반복' : '반복 안함',
                    value: _isRecurring,
                    onChanged: (value) => setState(() => _isRecurring = value),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),

                  // 캘린더 표시 토글
                  _buildCustomToggle(
                    icon: Icons.calendar_view_month,
                    title: '캘린더에 표시',
                    subtitle: _showOnCalendar ? '캘린더에 표시됨' : '캘린더에 표시 안됨',
                    value: _showOnCalendar,
                    onChanged: (value) => setState(() => _showOnCalendar = value),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),

                  // 종일 토글
                  _buildCustomToggle(
                    icon: Icons.access_time_filled,
                    title: '종일',
                    subtitle: _isAllDay ? '하루 종일' : '시간 지정',
                    value: _isAllDay,
                    onChanged: _toggleAllDay,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveEvent,
                    child: Text('저장', style: TextStyle(fontSize: 18,color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      color: Colors.white, // 카드 내부는 흰색으로 유지
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: EdgeInsets.all(16), child: child),
    );
  }

  // Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
  //   return SwitchListTile(
  //     title: Text(title),
  //     value: value,
  //     onChanged: onChanged,
  //     activeColor: accentColor,
  //   );
  // }
  Widget _buildCustomToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(!value),
                child: Container(
                  width: 50,
                  height: 28,
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: value ? accentColor : Colors.grey[300],
                  ),
                  child: AnimatedAlign(
                    duration: Duration(milliseconds: 200),
                    alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// class CustomTimePicker extends StatefulWidget {
//   final TimeOfDay initialTime;
//   final bool use24HourFormat;
//   final bool isEndTime;
//
//
//   CustomTimePicker({required this.initialTime, this.use24HourFormat = true, this.isEndTime = false});
//
//   @override
//   _CustomTimePickerState createState() => _CustomTimePickerState();
// }
//
// class _CustomTimePickerState extends State<CustomTimePicker> {
//   late int _hour;
//   late int _minute;
//
//   @override
//   void initState() {
//     super.initState();
//     _hour = widget.initialTime.hour;
//     _minute = widget.initialTime.minute;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Container(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               '시간 선택',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildNumberPicker(
//                   context,
//                   _hour,
//                   0,
//                   widget.use24HourFormat ? 24 : 23,
//                   (value) => setState(() => _hour = value),
//                 ),
//                 Text(':', style: TextStyle(fontSize: 20)),
//                 _buildNumberPicker(
//                   context,
//                   _minute,
//                   0,
//                   59,
//                       (value) => setState(() => _minute = value),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               child: Text('확인'),
//               onPressed: () {
//                 if (_hour == 24) {
//                   _hour = 0;
//                   ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('24시는 다음 날 00시로 설정됩니다.')),
//                   // 날짜를 다음 날로 변경하는 로직 추가 필요
//                   );}
//                 Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute));
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNumberPicker(
//       BuildContext context,
//       int value,
//       int minValue,
//       int maxValue,
//       ValueChanged<int> onChanged,
//       ) {
//     return Container(
//       height: 100,
//       width: 70,
//       child: CupertinoPicker(
//         scrollController: FixedExtentScrollController(initialItem: value),
//         itemExtent: 30,
//         onSelectedItemChanged: onChanged,
//         children: List<Widget>.generate(
//           maxValue - minValue + 1,
//               (index) => Center(
//             child: Text(
//               (minValue + index).toString().padLeft(2, '0'),
//               style: TextStyle(fontSize: 20),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final bool use24HourFormat;
  final bool isEndTime;

  CustomTimePicker({
    required this.initialTime,
    this.use24HourFormat = true,
    this.isEndTime = false
  });

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _hour;
  late int _minute;
  final Color mainColor = Colors.lightBlue[900]!;
  final Color backgroundColor = Colors.grey[100]!;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEndTime ? '종료 시간' : '시작 시간',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.access_time, color: Colors.white),
                ],
              ),
            ),
            // 시간 선택 영역
            Container(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 시간 선택기
                  Expanded(
                    child: Column(
                      children: [
                        Text('시', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: _buildNumberPicker(
                            context,
                            _hour,
                            0,
                            widget.use24HourFormat ? 24 : 23,
                                (value) => setState(() => _hour = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 구분선
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          ':',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 분 선택기
                  Expanded(
                    child: Column(
                      children: [
                        Text('분', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: _buildNumberPicker(
                            context,
                            _minute,
                            0,
                            59,
                                (value) => setState(() => _minute = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 버튼 영역
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_hour == 24) {
                        _hour = 0;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('24시는 다음 날 00시로 설정됩니다.')),
                        );
                      }
                      Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker(
      BuildContext context,
      int value,
      int minValue,
      int maxValue,
      ValueChanged<int> onChanged,
      ) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(
        initialItem: value - minValue,
      ),
      itemExtent: 40,
      diameterRatio: 1.5,
      onSelectedItemChanged: onChanged,
      children: List<Widget>.generate(
        maxValue - minValue + 1,
            (index) => Center(
          child: Text(
            (minValue + index).toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: mainColor,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomScrollDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  CustomScrollDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  _CustomScrollDatePickerState createState() => _CustomScrollDatePickerState();
}

class _CustomScrollDatePickerState extends State<CustomScrollDatePicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  final Color mainColor = Colors.lightBlue[900]!;
  final Color backgroundColor = Colors.grey[100]!;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDayIfNeeded() {
    int daysInMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > daysInMonth) {
      setState(() {
        _selectedDay = daysInMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '날짜 선택',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: Colors.white),
                ],
              ),
            ),
            // 날짜 선택 영역
            Container(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 년도 선택
                  Expanded(
                    child: Column(
                      children: [
                        Text('년', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedYear - widget.firstDate.year,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedYear = widget.firstDate.year + index;
                                _updateDayIfNeeded();
                              });
                            },
                            children: List<Widget>.generate(
                              widget.lastDate.year - widget.firstDate.year + 1,
                                  (index) => Center(
                                child: Text(
                                  '${widget.firstDate.year + index}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // 월 선택
                  Expanded(
                    child: Column(
                      children: [
                        Text('월', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedMonth - 1,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedMonth = index + 1;
                                _updateDayIfNeeded();
                              });
                            },
                            children: List<Widget>.generate(
                              12,
                                  (index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // 일 선택
                  Expanded(
                    child: Column(
                      children: [
                        Text('일', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedDay - 1,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedDay = index + 1;
                              });
                            },
                            children: List<Widget>.generate(
                              _getDaysInMonth(_selectedYear, _selectedMonth),
                                  (index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 버튼 영역
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        DateTime(_selectedYear, _selectedMonth, _selectedDay),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class TouchableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  TouchableScale({
    required this.child,
    required this.onTap,
  });

  @override
  _TouchableScaleState createState() => _TouchableScaleState();
}

class _TouchableScaleState extends State<TouchableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
