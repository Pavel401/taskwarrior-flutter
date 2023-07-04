// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, deprecated_member_use, avoid_unnecessary_containers, unused_element, prefer_const_literals_to_create_immutables, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskwarrior/config/app_settings.dart';
import 'package:taskwarrior/drawer/filter_drawer.dart';
import 'package:taskwarrior/drawer/nav_drawer.dart';
import 'package:taskwarrior/model/storage/storage_widget.dart';
import 'package:taskwarrior/widgets/addTask.dart';
import 'package:taskwarrior/widgets/buildTasks.dart';
import 'package:taskwarrior/widgets/pallete.dart';
import 'package:taskwarrior/widgets/tag_filter.dart';
import 'package:taskwarrior/widgets/taskdetails/profiles_widget.dart';
import 'package:path_provider/path_provider.dart';
// ignore_for_file: depend_on_referenced_packages, prefer_typing_uninitialized_variables

import 'dart:io';

import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:taskwarrior/model/json/task.dart';
import 'package:taskwarrior/model/storage.dart';

class Filters {
  const Filters({
    required this.pendingFilter,
    required this.togglePendingFilter,
    required this.tagFilters,
    required this.projects,
    required this.projectFilter,
    required this.toggleProjectFilter,
  });

  final bool pendingFilter;
  final void Function() togglePendingFilter;
  final TagFilters tagFilters;
  final dynamic projects;
  final String projectFilter;
  final void Function(String) toggleProjectFilter;
}

class HomePage extends StatefulWidget {
  static const String routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InheritedStorage storageWidget;

  late Storage storage;
  late final Filters filters;
  List<Task> taskData = [];
  List<ChartSeries> dailyBurnDown = [];
  Directory? baseDirectory;
  List<Task> allData = [];

  ///to check if the data is synced or not

  bool isSyncNeeded = false;

  ///call the synchronize function from storage_widget.dart
  ///to sync the data from the server
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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
          ///sort the data by daily burn down
          HomeWidget.setAppGroupId('group.leighawidget');

          // Mock read in some data and update the headline
          final newHeadline = allData[0];
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

    ///didChangeDependencies loads after the initState
    ///it provides the context from the tree
    if (!isSyncNeeded) {
      ///check if the data is synced or not
      ///if not then sync the data
      isNeededtoSync();
      isSyncNeeded = true;
    }
  }

  isNeededtoSync() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? value;
    value = prefs.getBool('sync') ?? false;

    if (value) {
      storageWidget = StorageWidget.of(context);
      storageWidget.synchronize(context);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    var storageWidget = StorageWidget.of(context);
    var taskData = storageWidget.tasks;

    var pendingFilter = storageWidget.pendingFilter;
    var pendingTags = storageWidget.pendingTags;

    var selectedTagsMap = {
      for (var tag in storageWidget.selectedTags) tag.substring(1): tag,
    };

    var keys = (pendingTags.keys.toSet()..addAll(selectedTagsMap.keys)).toList()
      ..sort();

    var tags = {
      for (var tag in keys)
        tag: TagFilterMetadata(
          display:
              '${selectedTagsMap[tag] ?? tag} ${pendingTags[tag]?.frequency ?? 0}',
          selected: selectedTagsMap.containsKey(tag),
        ),
    };

    var tagFilters = TagFilters(
      tagUnion: storageWidget.tagUnion,
      toggleTagUnion: storageWidget.toggleTagUnion,
      tags: tags,
      toggleTagFilter: storageWidget.toggleTagFilter,
    );
    var filters = Filters(
      pendingFilter: pendingFilter,
      togglePendingFilter: storageWidget.togglePendingFilter,
      projects: storageWidget.projects,
      projectFilter: storageWidget.projectFilter,
      toggleProjectFilter: storageWidget.toggleProjectFilter,
      tagFilters: tagFilters,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.kToDark.shade200,
        title: Text('Home Page', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: (storageWidget.searchVisible)
                ? Tooltip(
                    message: 'Cancel',
                    child: const Icon(Icons.cancel, color: Colors.white))
                : Tooltip(
                    message: 'Search',
                    child: const Icon(Icons.search, color: Colors.white)),
            onPressed: storageWidget.toggleSearch,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => storageWidget.synchronize(context),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Tooltip(
                message: 'Filters',
                child: const Icon(Icons.filter_list, color: Colors.white),
              ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: Tooltip(
                message: 'Menu',
                child: const Icon(Icons.menu, color: Colors.white)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: NavDrawer(storageWidget: storageWidget, notifyParent: refresh),
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(content: Text('Tap back again to exit')),
        child: Container(
          color:
              AppSettings.isDarkMode ? Palette.kToDark.shade200 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Column(
              children: <Widget>[
                if (storageWidget.searchVisible)
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) {
                        storageWidget.search(value);
                      },
                      controller: storageWidget.searchController,
                      decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(Icons.search_rounded),
                          fillColor: Colors.grey[300],
                          filled: true,
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                Expanded(
                  child: Scrollbar(
                    child: TasksBuilder(
                        // darkmode: AppSettings.isDarkMode,
                        taskData: taskData,
                        pendingFilter: pendingFilter,
                        searchVisible: storageWidget.searchVisible),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      endDrawer: FilterDrawer(filters),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn3",
        backgroundColor:
            AppSettings.isDarkMode ? Colors.white : Palette.kToDark.shade200,
        child: Tooltip(
          message: 'Add Task',
          child: Icon(
            Icons.add,
            color: AppSettings.isDarkMode
                ? Palette.kToDark.shade200
                : Colors.white,
          ),
        ),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const AddTaskBottomSheet(),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  refresh() {
    setState(() {});
  }
}
