import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/category_model.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('category').get();
      setState(() {
        categories = snapshot.docs.map((doc) => {
          'categoryId': doc.id,
          'categoryName': doc['categoryName'] as String,
          'colorCode': doc['colorCode'] as String,
          'userId': doc['userId'] as String,
          // 필요한 다른 필드들을 여기에 추가하세요
        }).toList();

        if (categories.isNotEmpty) {
          selectedCategoryId = categories.first['categoryId'] as String;
        }
      });
    } catch (e) {
      print('Error loading categories: $e');
      // 에러 처리 로직 추가 (예: 사용자에게 알림)
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  // 카테고리 선택을 위한 메서드 (이미 있다면 수정하세요)


  // 종일 여부 토글을 위한 메서드
  void _toggleAllDay(bool value) {
    setState(() {
      _isAllDay = value;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: isStartTime
              ? _startTime?.hour ?? TimeOfDay.now().hour
              : _endTime?.hour ?? (TimeOfDay.now().hour + 1) % 24,
          minute: 0),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (selectedTime != null) {
      setState(() {
        final date = _selectedDate ?? DateTime.now();
        if (isStartTime) {
          _startTime =
              DateTime(date.year, date.month, date.day, selectedTime.hour, 0);
        } else {
          _endTime =
              DateTime(date.year, date.month, date.day, selectedTime.hour, 0);
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (widget.isFinalEvent) {
          await _saveFinalEvent();
        } else {
          await _saveRegularEvent();
        }

        String message = widget.isEditing ? '일정이 수정되었습니다.' : '일정이 추가되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error saving event: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('일정 처리에 실패했습니다.')));
      }
    }
  }

  Future<void> _saveFinalEvent() async {
    String eventRetId = widget.actualevent?.eventResultId ?? '';
    if (eventRetId.isEmpty) {
      eventRetId = FirebaseFirestore.instance.collection('result_events').doc().id;
    }
    print('eventRetId: $eventRetId');

    final eventResultData = EventResultModel(
      eventResultId: eventRetId,
      eventId: widget.actualevent?.eventId ?? '',
      categoryId: selectedCategoryId ?? '',
      userId: '', // 사용자 ID 설정
      eventResultDate: _selectedDate,
      eventResultSttTime: _startTime ?? DateTime.now(),
      eventResultEndTime: _endTime ?? DateTime.now().add(Duration(hours: 1)),
      eventResultTitle: _titleController.text,
      eventResultContent: _contentController.text,
      isAllDay: _isAllDay ? true : false,
      completeYn: '',
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

  Future<void> _saveRegularEvent() async {
    String eventId = widget.event?.eventId ?? '';
    if (eventId.isEmpty) {
      eventId = FirebaseFirestore.instance.collection('events').doc().id;
    }
    print('eventId: $eventId');

    final eventData = EventModel(
      eventId: eventId,
      eventTitle: _titleController.text,
      eventDate: _selectedDate,
      eventContent: _contentController.text,
      categoryId: selectedCategoryId ?? categories.first['categoryId'],
      userId: '',
      eventSttTime: _startTime,
      eventEndTime: _endTime,
      isAllDay: _isAllDay,
      completeYn: 'N',
      isRecurring: _isRecurring,
      showOnCalendar: _showOnCalendar,
    );

    if (widget.event != null) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update(eventData.toMap());
    } else {
      final docRef = await FirebaseFirestore.instance
          .collection('events')
          .add(eventData.toMap());
      await docRef.update({'eventId': docRef.id});
    }

    if (_isRecurring) {
      await _createRecurringEvents(eventData);
    }
  }

  Future<void> _createRecurringEvents(EventModel baseEvent) async {
    for (int i = 1; i < 4; i++) {
      final recurringDate = _selectedDate!.add(Duration(days: i * 7));
      final recurringEvent = baseEvent.copyWith(
        eventId: FirebaseFirestore.instance.collection('events').doc().id,
        eventDate: recurringDate,
      );
      await FirebaseFirestore.instance
          .collection('events')
          .doc(recurringEvent.eventId)
          .set(recurringEvent.toMap());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '일정 수정' : '일정 추가'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '일정 이름',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '제목을 입력하세요';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(labelText: '내용'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '내용을 입력하세요';
                }
                return null;
              },
              keyboardType: TextInputType.text,
              maxLines: 3,
            ),
            ListTile(
              title: Text('날짜 선택'),
              subtitle: Text(_selectedDate != null
                  ? DateFormat.yMd().format(_selectedDate!)
                  : '날짜를 선택하세요'),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              title: Text('시작 시간'),
              subtitle: Text(_startTime != null
                  ? DateFormat('HH:00').format(_startTime!)
                  : '시작 시간을 선택하세요'),
              onTap: () => _selectTime(context, true),
            ),
            ListTile(
              title: Text('종료 시간'),
              subtitle: Text(_endTime != null
                  ? DateFormat('HH:00').format(_endTime!)
                  : '종료 시간을 선택하세요'),
              onTap: () => _selectTime(context, false),
            ),
            SwitchListTile(
              title: Text('반복 여부'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('캘린더에 표시'),
              value: _showOnCalendar,
              onChanged: (value) {
                setState(() {
                  _showOnCalendar = value;
                });
              },
            ),
            DropdownButton<String>(
              value: selectedCategoryId,
              hint: Text('카테고리 선택'),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCategoryId = newValue;
                  });
                }
              },
              items: categories.map<DropdownMenuItem<String>>((Map<String, dynamic> category) {
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
            ),
            CheckboxListTile(
              title: Text('종일'),
              value: _isAllDay,
              onChanged: (bool? value) {
                _toggleAllDay(value!);
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
