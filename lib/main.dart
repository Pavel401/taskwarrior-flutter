// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:loggy/loggy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'package:taskwarrior/routes/pageroute.dart';
import 'package:taskwarrior/services/notification_services.dart';
import 'package:taskwarrior/views/home/home.dart';
import 'package:taskwarrior/views/profile/profile.dart';
import 'package:taskwarrior/widgets/pallete.dart';
import 'package:taskwarrior/widgets/taskdetails/profiles_widget.dart';
// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, deprecated_member_use, avoid_unnecessary_containers, unused_element, prefer_const_literals_to_create_immutables, library_private_types_in_public_api, use_build_context_synchronously

import 'package:home_widget/home_widget.dart';

import 'package:taskwarrior/model/storage/storage_widget.dart';
// ignore_for_file: depend_on_referenced_packages, prefer_typing_uninitialized_variables

import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:taskwarrior/model/json/task.dart';
import 'package:taskwarrior/model/storage.dart';
// import 'package:taskwarrior/model/task.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart'

Future main([List<String> args = const []]) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  Directory? testingDirectory;
  if (args.contains('flutter_driver_test')) {
    testingDirectory = Directory(
      '${Directory.systemTemp.path}/flutter_driver_test/${const Uuid().v1()}',
    )..createSync(recursive: true);
    stdout.writeln(testingDirectory);
    Directory(
      '${testingDirectory.path}/profiles/acae0462-6a34-11e4-8001-002590720087',
    ).createSync(recursive: true);
  }

  runApp(
    FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) => (snapshot.hasData)
          ? ProfilesWidget(
              baseDirectory: testingDirectory ?? snapshot.data!,
              child: const MyApp(),
            )
          : const Placeholder(),
    ),
  );
}

Future init() async {
  Loggy.initLoggy(logPrinter: const PrettyPrinter());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

// ignore: use_key_in_widget_constructors
class _MyAppState extends State<MyApp> {
  NotificationService notificationService = NotificationService();

  late InheritedStorage storageWidget;

  late Storage storage;
  late final Filters filters;
  List<Task> taskData = [];
  List<ChartSeries> dailyBurnDown = [];
  Directory? baseDirectory;
  List<Task> allData = [];
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      storageWidget = StorageWidget.of(context);
      var currentProfile = ProfilesWidget.of(context).currentProfile;

      getApplicationDocumentsDirectory().then((directory) {
        setState(() {
          baseDirectory = directory;
          storage = Storage(
            Directory('${baseDirectory!.path}/profiles/$currentProfile'),
          );
        });

        ///fetch all data contains all the tasks
        allData = storage.data.allData();

        ///check if allData is not empty
        if (allData.isNotEmpty) {
          print("allData.length${allData.length}");

          ///sort the data by daily burn down
          HomeWidget.setAppGroupId('group.leighawidget');

          // Mock read in some data and update the headline
          final newHeadline = allData[0];

          // print(newHeadline);
          // print(newHeadline.id.toString());
          // print(newHeadline.description);
          HomeWidget.saveWidgetData<String>(
              'headline_title', newHeadline.id.toString());
          HomeWidget.saveWidgetData<String>(
              'headline_description', newHeadline.description);
          HomeWidget.updateWidget(
            iOSName: 'NewsWidgets',
            androidName: 'NewsWidget',
          );
        }
      });
    });

    ///sort the data by daily burn down
    HomeWidget.setAppGroupId('group.leighawidget');

    // print(newHeadline);
    // print(newHeadline.id.toString());
    // print(newHeadline.description);
    HomeWidget.saveWidgetData<String>(
        'headline_title', "newHeadline.id.toString()");
    HomeWidget.saveWidgetData<String>(
        'headline_description', "newHeadline.description");
    HomeWidget.updateWidget(
      iOSName: 'NewsWidgets',
      androidName: 'NewsWidget',
    );
    notificationService.initiliazeNotification();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskwarrior',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Palette.kToDark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: PageRoutes.home,
      routes: {
        PageRoutes.home: (context) => HomePage(),
        PageRoutes.profile: (context) => const ProfilePage(),
      },
    );
  }
}
