import 'package:flutter/material.dart';

class SurveyGraphScreen extends StatefulWidget {
  const SurveyGraphScreen({super.key});

  @override
  State<SurveyGraphScreen> createState() => _SurveyGraphScreenState();
}

class _SurveyGraphScreenState extends State<SurveyGraphScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anket Grafiği')),
      body: Container(child: Text("data")),
    );
  }
}
