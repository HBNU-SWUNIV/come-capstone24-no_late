import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
            ? (widget.isFinalEvent
            ? DateTime.parse(widget.actualevent!.eventResultDate)
            : widget.event?.eventDate)
            : null);
    _startTime = widget.selectedTime ??
        (widget.isEditing
            ? (widget.isFinalEvent
            ? DateTime.parse(widget.actualevent!.eventResultSttTime)
            : widget.event?.eventSttTime)
            : null);
    _endTime = widget.endTime ??
        (widget.isEditing
            ? (widget.isFinalEvent
            ? DateTime.parse(widget.actualevent!.eventResultEndTime)
            : widget.event?.eventEndTime)
            : null);
    _isRecurring = widget.isEditing
        ? (widget.isFinalEvent
        ? false
        : widget.event?.isRecurring ?? false)
        : false;
    _showOnCalendar = widget.isEditing
        ? (widget.isFinalEvent
        ? true
        : widget.event?.showOnCalendar ?? true)
        : true;
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

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _startTime ?? DateTime.now() : _endTime ?? DateTime.now()),
    );
    if (selectedTime != null) {
      setState(() {
        final date = _selectedDate ?? DateTime.now();
        if (isStartTime) {
          _startTime = DateTime(date.year, date.month, date.day, selectedTime.hour,
              selectedTime.minute);
        } else {
          _endTime = DateTime(date.year, date.month, date.day, selectedTime.hour,
              selectedTime.minute);
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.isFinalEvent) {
        String eventRetId = widget.actualevent?.eventResultId ?? '';
        if (eventRetId.isEmpty) {
          eventRetId = FirebaseFirestore.instance.collection('result_events').doc().id;
        }
        print('eventRetId: $eventRetId'); // 추가된 로그

        final newEventResult = EventResultModel(
          eventResultId: eventRetId,
          categoryId: '',
          userId: '',
          eventResultDate: _selectedDate?.toIso8601String() ?? '',
          eventResultSttTime: _startTime?.toIso8601String() ?? '',
          eventResultEndTime: _endTime?.toIso8601String() ?? '',
          eventResultTitle: _titleController.text,
          eventResultContent: _contentController.text, eventId: '', completeYn: '',
        );
        if (widget.isEditing && widget.actualevent != null) {
          // 기존 일정 수정
          await FirebaseFirestore.instance
              .collection('result_events')
              .doc(widget.actualevent!.eventResultId)
              .update(newEventResult.toMap());
        } else {
          // 새로운 일정 추가
          await FirebaseFirestore.instance
              .collection('result_events')
              .doc(eventRetId)
              .set(newEventResult.toMap());
        }

        Navigator.pop(context, newEventResult);
      } else {
        String eventId = widget.event?.eventId ?? '';
        if (eventId.isEmpty) {
          eventId = FirebaseFirestore.instance.collection('events').doc().id;
        }
        print('eventId: $eventId'); // 추가된 로그

        final newEvent = EventModel(
          eventId: eventId,
          eventTitle: _titleController.text,
          eventDate: _selectedDate,
          eventContent: _contentController.text,
          categoryId: '',
          userId: '',
          eventSttTime: _startTime,
          eventEndTime: _endTime,
          allDayYn: 'N',
          completeYn: 'N',
          isRecurring: _isRecurring,
          showOnCalendar: _showOnCalendar,
        );

        // if (_isRecurring) {
        //   // 한 달 동안 일주일에 한 번씩 반복 이벤트 생성
        //   for (int i = 0; i < 4; i++) {
        //     final recurringDate = DateTime(
        //       _selectedDate!.year,
        //       _selectedDate!.month,
        //       _selectedDate!.day + (i * 7),
        //     );
        //     final recurringEvent = newEvent.copyWith(
        //       eventId: FirebaseFirestore.instance.collection('events').doc().id,
        //       eventDate: recurringDate,
        //     );
        //     await FirebaseFirestore.instance
        //         .collection('events')
        //         .doc(recurringEvent.eventId)
        //         .set(recurringEvent.toMap());
        //   }
        // }

        if (_isRecurring) {
          // 한 달 동안 일주일에 한 번씩 반복 이벤트 생성
          for (int i = 1; i < 4; i++) {
            final recurringDate = _selectedDate!.add(Duration(days: i * 7));
            final recurringEvent = newEvent.copyWith(
              eventId: FirebaseFirestore.instance.collection('events').doc().id,
              eventDate: recurringDate,
            );
            await FirebaseFirestore.instance
                .collection('events')
                .doc(recurringEvent.eventId)
                .set(recurringEvent.toMap());


          }
        }

        String message;
        try {
          if (widget.isEditing) {
            // 문서가 존재하는지 확인
            DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
                .collection('events')
                .doc(widget.event!.eventId)
                .get();

            if (documentSnapshot.exists) {
              // 기존 이벤트 수정
              await FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.event!.eventId)
                  .update(newEvent.toMap());
              message = '일정이 수정되었습니다.';
            } else {
              throw Exception('Document not found: ${widget.event!.eventId}');
            }
          } else {
            // 새 이벤트 추가
            final eventRef =
            await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());
            final eventId = eventRef.id;
            await eventRef.update({'eventId': eventId});
            message = '일정이 추가되었습니다.';
          }

          // 성공 알림 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } catch (e) {
          // 예외 발생 시 처리
          print('Error updating or adding document: $e');
          message = '일정 처리에 실패했습니다.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
                  ? DateFormat.Hm().format(_startTime!)
                  : '시작 시간을 선택하세요'),
              onTap: () => _selectTime(context, true),
            ),
            ListTile(
              title: Text('종료 시간'),
              subtitle: Text(_endTime != null
                  ? DateFormat.Hm().format(_endTime!)
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
