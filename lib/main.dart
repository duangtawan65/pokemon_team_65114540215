import 'package:flutter/material.dart';
import 'package:myapp/myapp.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // เพิ่มบรรทัดนี้
  await GetStorage.init();
  runApp(const MyApp());
}