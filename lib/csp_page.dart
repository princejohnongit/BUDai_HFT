import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class CSPPage extends StatefulWidget {
  @override
  _CSPPageState createState() => _CSPPageState();
}

class _CSPPageState extends State<CSPPage> {
  Map<String, dynamic> _data = {};
  double _totalIncome = 0;
  List<Map<String, dynamic>> _satisfiedNeeds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final file = File('data.json');
      final jsonString = await file.readAsString();
      setState(() {
        _data = jsonDecode(jsonString);
        _totalIncome = _calculateTotalIncome();
        _satisfiedNeeds = _solveCSP();
      });
    } catch (e) {
      print('Error reading data: $e');
    }
  }

  double _calculateTotalIncome() {
    double total = 0;
    if (_data.containsKey('income')) {
      for (var income in _data['income']) {
        total += double.tryParse(income['amount']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> _solveCSP() {
    List<Map<String, dynamic>> needs = List<Map<String, dynamic>>.from(_data['needs'] ?? []);
    List<String> labels = List<String>.from(_data['profile']['Labels'] ?? []);

    // Sort needs by priority based on labels
    needs.sort((a, b) {
      int priorityA = labels.indexOf(a['Label']) != -1 ? labels.indexOf(a['Label']) : labels.length;
      int priorityB = labels.indexOf(b['Label']) != -1 ? labels.indexOf(b['Label']) : labels.length;
      return priorityA.compareTo(priorityB);
    });

    double remainingIncome = _totalIncome;
    List<Map<String, dynamic>> satisfiedNeeds = [];

    for (var need in needs) {
      double needAmount = double.tryParse(need['amount']?.toString() ?? '0') ?? 0;
      if (remainingIncome >= needAmount) {
        satisfiedNeeds.add(need);
        remainingIncome -= needAmount;
      }
    }

    return satisfiedNeeds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSP Solver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Income: \$${_totalIncome.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Satisfied Needs:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: _satisfiedNeeds.length,
                itemBuilder: (context, index) {
                  final need = _satisfiedNeeds[index];
                  return ListTile(
                    title: Text(need['name'] ?? 'Unknown Need'),
                    subtitle: Text('Amount: \$${need["amount"]}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
