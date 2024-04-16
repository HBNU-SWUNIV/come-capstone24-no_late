import 'package:flutter/material.dart';

import 'event.dart';
class AddEventPage extends StatefulWidget {
  final DateTime? selectedDate;
  final Event? event;


  AddEventPage({this.selectedDate, this.event});
  @override
  _AddEventPageState createState() => _AddEventPageState();
}




class _AddEventPageState extends State<AddEventPage> {
  late DateTime? selectedDate;
  late TimeOfDay selectedTime;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool isRecurring;



  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    selectedTime = widget.event?.time ?? TimeOfDay.now();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    isRecurring = widget.event?.isRecurring ?? false;
  }



  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      ),
      body: Form(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            if (selectedDate == null)
              ListTile(
                title: Text("Date: ${selectedDate?.toString().split(' ')[0] ?? 'Select a date'}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
            ListTile(
              title: Text("Time: ${selectedTime.format(context)}"),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
            CheckboxListTile(
              title: Text('Repeat Weekly'),
              value: isRecurring,
              onChanged: (bool? value) { // `bool?` 타입을 명시
                if (value != null) { // `value`가 `null`이 아닐 때만 상태를 업데이트
                  setState(() {
                    isRecurring = value;
                  });
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null)  {
                  final newEvent = Event(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    date: selectedDate!,
                    time: selectedTime,
                    isRecurring: isRecurring,
                  );
                  Navigator.pop(context, newEvent);

                  // Process data
                  // DateTime eventDate = selectedDate ?? DateTime.now();
                  //
                  //
                  // Event newEvent = Event(
                  //     title: _titleController.text,
                  //     description: _descriptionController.text,
                  //     date: eventDate,
                  //     time: selectedTime,
                  //     isRecurring: isRecurring
                  // );
                  //
                  // Navigator.pop(context, newEvent);


                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
