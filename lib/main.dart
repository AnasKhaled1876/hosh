import 'package:flutter/widgets.dart';
import 'package:hosh/app/di/app_dependencies.dart';
import 'package:hosh/app/view/hoosh_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppDependencies dependencies = AppDependencies.create();
  runApp(HooshApp(dependencies: dependencies));
}
