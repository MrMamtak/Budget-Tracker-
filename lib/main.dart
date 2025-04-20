import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = BudgetProvider();
  await provider.loadData();
  runApp(
    ChangeNotifierProvider(create: (_) => provider, child: BudgetApp()),
  );
}

class BudgetApp extends StatelessWidget {
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Budget Tracker',
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: ProjectListScreen(),
  );
}

// Models, Provider, and ProjectListScreen stay largely the same,
// except your fold calls use fold<double>(0.0, …) and you import fl_chart.
// In ProjectDetailScreen, replace the old PieChart with:

SizedBox(
  height: 200,
  child: PieChart(
    PieChartData(
      sections: proj.tasks.map((t) => PieChartSectionData(
        value: t.amount,
        title: t.desc,
      )).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 40,
    ),
  ),
),
