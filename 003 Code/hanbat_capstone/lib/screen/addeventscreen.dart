import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/calendar_screen.dart';
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
  late DateTime? selectedDate;
  late TimeOfDay selectedTime;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool isRecurring;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    selectedTime = TimeOfDay.fromDateTime(widget.event?.eventSttTime ?? DateTime.now());
    _titleController = TextEditingController(text: widget.event?.eventTitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.eventContent ?? '');
    isRecurring = widget.event?.isRecurring ?? false;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '일정 추가' : '일정 수정'),
      ),
      body: Form(
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
                  return '제목을 입려하세요';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '세부사항',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '세부사항을 터치해주세요';
                }
                return null;
              },
            ),
            if (selectedDate == null)
              ListTile(
                title: Text(
                    "날짜: ${selectedDate?.toString().split(' ')[0] ?? '날짜를 선택해주세요'}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
            ListTile(
              title: Text("시간: ${selectedTime.format(context)}"),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
            CheckboxListTile(
              title: Text('반복'),
              value: isRecurring,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    isRecurring = value;
                  });
                }
              },
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null) {
                  final updatedEvent = EventModel(
                    eventId: widget.event?.eventId ?? '',
                    categoryId: widget.event?.categoryId ?? '',
                    userId: widget.event?.userId ?? '',
                    eventDate: selectedDate!,
                    eventSttTime: DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    eventEndTime: DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    eventTitle: _titleController.text,
                    eventContent: _descriptionController.text,
                    allDayYn: 'N',
                    completeYn: 'N', 
                     isRecurring: isRecurring,
                  );

                  if (widget.event != null) {
                    // 기존 이벤트 업데이트
                    await FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.event!.eventId)
                        .update(updatedEvent.toMap());
                  } else {
                    // 새로운 이벤트 추가
                    final eventRef = await FirebaseFirestore.instance
                        .collection('events')
                        .add(updatedEvent.toMap());
                    final eventId = eventRef.id;
                    await eventRef.update({'eventId': eventId});
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RootScreen()),
                  );
                }


              },

              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
