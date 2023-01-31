import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:poc_offline_first/page/campaings.dart';
import 'package:poc_offline_first/page/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // await Hive.deleteBoxFromDisk('TestOffline');
  // await Hive.deleteBoxFromDisk('Campaigns');
  // await Hive.deleteBoxFromDisk('sync_data_box');
  // await Hive.deleteFromDisk();

  await Hive.openBox('TestOffline');
  await Hive.openBox('Campaigns');
  await Hive.openBox('sync_data_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POC Offline First',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/campaigns': (context) => const Campaigns(),
      },
    );
  }
}
