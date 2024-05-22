import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import 'root_screen.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final EventModel? event;

  AddEventScreen({this.selectedDate, this.event});

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
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.eventTitle);
    _contentController = TextEditingController(text: widget.event?.eventContent);
    _selectedDate = widget.selectedDate ?? widget.event?.eventDate;
    _startTime = widget.event?.eventSttTime;
    _endTime = widget.event?.eventEndTime;
    _isRecurring = widget.event?.isRecurring ?? false;
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
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime ?? DateTime.now() : _endTime ?? DateTime.now()),
    );
    if (selectedTime != null) {
      setState(() {
        final date = _selectedDate ?? DateTime.now();
        if (isStartTime) {
          _startTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute);
        } else {
          _endTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute);
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      final newEvent = EventModel(
        eventTitle: _titleController.text,
        eventDate: _selectedDate,
        eventContent: _contentController.text,
        eventId: widget.event?.eventId ?? '',
        categoryId: '',
        userId: '',
        eventSttTime: _startTime,
        eventEndTime: _endTime,
        allDayYn: 'N',
        completeYn: 'N',
        isRecurring: _isRecurring,
      );

      if (widget.event != null) {
        // Edit existing event
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event!.eventId)
            .update(newEvent.toMap());
      } else {
        // Add new event
        final eventRef = await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());
        final eventId = eventRef.id;
        await eventRef.update({'eventId': eventId});
      }

      Navigator.pop(context, newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '일정 추가' : '일정 수정'),
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
