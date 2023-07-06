// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'package:intl/intl.dart';

import 'package:taskwarrior/config/app_settings.dart';
import 'package:taskwarrior/model/storage.dart';
import 'package:taskwarrior/model/storage/storage_widget.dart';
import 'package:taskwarrior/services/notification_services.dart';
import 'package:taskwarrior/widgets/taskw.dart';
// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:taskwarrior/views/home/home.dart';
import 'package:taskwarrior/widgets/taskdetails/profiles_widget.dart';
// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, deprecated_member_use, avoid_unnecessary_containers, unused_element, prefer_const_literals_to_create_immutables, library_private_types_in_public_api, use_build_context_synchronously

// ignore_for_file: depend_on_referenced_packages, prefer_typing_uninitialized_variables

import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:taskwarrior/model/json/task.dart';

// import 'package:taskwarrior/model/task.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart'
class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AddTaskBottomSheetState createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final formKey = GlobalKey<FormState>();
  final namecontroller = TextEditingController();
  //final prioritycontroller;
  DateTime? due;
  String dueString = '';
  String priority = 'M';
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    namecontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Add Task';

    return Center(
      child: SingleChildScrollView(
        child: AlertDialog(
          backgroundColor: AppSettings.isDarkMode
              ? const Color.fromARGB(255, 220, 216, 216)
              : Colors.white,
          title: const Center(child: Text(title)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 8),
                  buildName(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text(
                              "Due : ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, height: 3.3),
                            ),
                            GestureDetector(
                              onLongPress: () {
                                due = null;
                                setState(() {});
                              },
                              child: ActionChip(
                                  backgroundColor: AppSettings.isDarkMode
                                      ? Colors.white
                                      : const Color.fromARGB(
                                          255, 220, 216, 216),
                                  label: Text(
                                    (due != null)
                                        ? dueString
                                        : "select due date",
                                  ),
                                  onPressed: () async {
                                    var initialDate =
                                        due?.toLocal() ?? DateTime.now();
                                    var date = await showDatePicker(
                                      context: context,
                                      initialDate: initialDate,
                                      firstDate: DateTime(
                                          1990), // >= 1980-01-01T00:00:00.000Z
                                      lastDate: DateTime(2037, 12,
                                          31), // < 2038-01-19T03:14:08.000Z
                                    );
                                    if (date != null) {
                                      var time = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            TimeOfDay.fromDateTime(initialDate),
                                      );
                                      if (time != null) {
                                        var dateTime = date.add(
                                          Duration(
                                            hours: time.hour,
                                            minutes: time.minute,
                                          ),
                                        );
                                        dateTime = dateTime.add(
                                          Duration(
                                            hours: time.hour - dateTime.hour,
                                          ),
                                        );
                                        due = dateTime.toUtc();
                                        NotificationService
                                            notificationService =
                                            NotificationService();
                                        notificationService
                                            .initiliazeNotification();

                                        if ((dateTime.millisecondsSinceEpoch -
                                                DateTime.now()
                                                    .millisecondsSinceEpoch) >
                                            0) {
                                          notificationService.sendNotification(
                                              dateTime, namecontroller.text);
                                        }

                                        dueString =
                                            DateFormat("dd-MM-yyyy HH:mm")
                                                .format(dateTime);
                                      }
                                    }
                                    setState(() {});
                                  }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 8),
                  const SizedBox(height: 0),
                  buildPriority(),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            buildCancelButton(context),
            buildAddButton(context),
          ],
        ),
      ),
    );
  }

  late InheritedStorage storageWidget;

  late Storage storage;
  late final Filters filters;
  List<Task> taskData = [];
  List<ChartSeries> dailyBurnDown = [];
  Directory? baseDirectory;
  List<Task> allData = [];

  Future<void> _sendData() async {
    try {
      storageWidget = StorageWidget.of(context);
      var currentProfile = ProfilesWidget.of(context).currentProfile;

      baseDirectory = await getApplicationDocumentsDirectory();
      setState(() {
        storage = Storage(
          Directory('${baseDirectory!.path}/profiles/$currentProfile'),
        );
      });

      ///fetch all data contains all the tasks
      allData = storage.data.allData();

      ///check if allData is not empty
      if (allData.isNotEmpty) {
        HomeWidget.setAppGroupId('taskwarrior');
        final List<String> placesData = [];
        final List<String> datesData = [];

        for (int i = 0; i < allData.length; i++) {
          placesData.add(
              "${(allData[i].id == 0) ? '#' : allData[i].id}. ${allData[i].description}");
          datesData.add(
              'Last Modified: ${(allData[i].modified != null) ? age(allData[i].modified!) : ((allData[i].start != null) ? age(allData[i].start!) : '-')} | '
                          'Due: ${(allData[i].due != null) ? when(allData[i].due!) : '-'}'
                      .replaceFirst(RegExp(r' \[\]$'), '')
                      .replaceAll(RegExp(r' +'), ' ') +
                  formatUrgency(urgency(allData[i])));
        }
        await HomeWidget.saveWidgetData<String>(
            'placesData', placesData.join(','));
        await HomeWidget.saveWidgetData<String>(
            'datesData', datesData.join(','));
        _updateWidget();
      }
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future<void> _sendAndUpdate() async {
    await _sendData();
  }

  Future<void> _updateWidget() async {
    try {

      
      await HomeWidget.updateWidget(
        name: 'WidgetProvider',
        androidName: 'WidgetProvider',
        qualifiedAndroidName: "com.example.taskwarrior.widget.WidgetProvider",
      );

      print("widget is updated");
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget. $exception');
    }
  }

  Widget buildName() => TextFormField(
        controller: namecontroller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter Task',
        ),
        validator: (name) => name != null && name.isEmpty
            ? 'You cannot leave this field empty!'
            : null,
      );
  Widget buildPriority() => Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Priority :  ',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            DropdownButton<String>(
              dropdownColor: AppSettings.isDarkMode
                  ? const Color.fromARGB(255, 220, 216, 216)
                  : Colors.white,
              value: priority,
              elevation: 16,
              style: const TextStyle(color: Colors.black),
              underline: Container(
                height: 1.5,
                color: Colors.black,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  priority = newValue!;
                });
              },
              items: <String>['H', 'M', 'L']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('  $value'),
                );
              }).toList(),
            )
          ],
        ),
      ]);
  Widget buildCancelButton(BuildContext context) => TextButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
      );

  Widget buildAddButton(BuildContext context) {
    int errCode = 0;
    return TextButton(
      child: const Text("Add"),
      onPressed: () {
        try {
          if (formKey.currentState!.validate()) {
            if (due == null) {
              errCode = 1;
              throw const FormatException(
                  'Due date cannot be empty'); // added an exception case for not leaving due date empty
            }
            var task = taskParser(namecontroller.text)
                .rebuild((b) => b..due = due)
                .rebuild((p) => p..priority = priority);

            StorageWidget.of(context).mergeTask(task);
            //StorageWidget.of(context).mergeTask(prioritytask);
            namecontroller.text = '';
            due = null;
            priority = 'M';
            setState(() {});
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text(
                    'Task Added Successfully, Tap to Edit'), // Intimating the user about the double tap to edit feature
                backgroundColor: AppSettings.isDarkMode
                    ? const Color.fromARGB(255, 61, 61, 61)
                    : const Color.fromARGB(255, 39, 39, 39),
                duration: const Duration(seconds: 2)));

            _sendAndUpdate();
          }
        } on FormatException catch (e) {
          Navigator.of(context).pop();
          if (errCode == 1) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text(
                    'Due date cannot be empty'), // Intimating the user not to leave the due date empty
                backgroundColor: AppSettings.isDarkMode
                    ? const Color.fromARGB(255, 61, 61, 61)
                    : const Color.fromARGB(255, 39, 39, 39),
                duration: const Duration(seconds: 2)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Task Addition Failed'),
                backgroundColor: AppSettings.isDarkMode
                    ? const Color.fromARGB(255, 61, 61, 61)
                    : const Color.fromARGB(255, 39, 39, 39),
                duration: const Duration(seconds: 2)));
          }
          log(e.toString());
        }
      },
    );
  }
}
