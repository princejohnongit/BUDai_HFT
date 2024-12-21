import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Data Models
class Need {
  final String needType;
  final String duration;
  final double amount;
  final String name;
  final String label;
  double? allocated;
  double? score;
  bool? fulfilled;

  Need({
    required this.needType,
    required this.duration,
    required this.amount,
    required this.name,
    required this.label,
    this.allocated,
    this.score,
    this.fulfilled,
  });

  factory Need.fromJson(Map<String, dynamic> json) {
    return Need(
      needType: json['needType'] as String,
      duration: json['duration'] as String,
      amount: double.parse(json['amount']),
      name: json['name'] as String,
      label: json['priority'] as String,
    );
  }
}

class Income {
  final double amount;
  final String type;
  final String reliability;
  final String frequency;

  Income({
    required this.amount,
    required this.type,
    required this.reliability,
    required this.frequency,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      amount: double.parse(json['amount']),
      type: json['type'] as String,
      reliability: json['reliability'] as String,
      frequency: json['frequency'] as String,
    );
  }
}

class FinancialCSPSolver extends StatefulWidget {
  const FinancialCSPSolver({Key? key}) : super(key: key);

  @override
  _FinancialCSPSolverState createState() => _FinancialCSPSolverState();
}

class _FinancialCSPSolverState extends State<FinancialCSPSolver> {
  List<Need>? results;

  double calculateTotalIncome(List<Income> incomes) {
    return incomes.fold(0, (total, income) {
      switch (income.frequency) {
        case "6 Months":
          return total + (income.amount / 6);
        default:
          return total + income.amount;
      }
    });
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<Map<String, dynamic>> _loadJsonData() async {
    final file = await _localFile;
    final jsonString = await file.readAsString();
    return jsonDecode(jsonString);
  }

  double calculateNeedScore(Need need, List<String> labels) {
    final labelIndex =
        labels.indexWhere((label) => need.label.toLowerCase() == label.toLowerCase());
    double h = labelIndex != -1 ? (labels.length - labelIndex).toDouble() : 0.0;
    return h / need.amount;
  }

  void solveCSP(Map<String, dynamic> data) {
    try {
      final incomes =
          (data['income'] as List).map((inc) => Income.fromJson(inc)).toList();
      final monthlyIncome = calculateTotalIncome(incomes);
      var availableFunds = monthlyIncome;

      final needs =
          (data['needs'] as List).map((need) => Need.fromJson(need)).toList();
      final labels = (data['profile']['labels'] as List).cast<String>();

      for (var need in needs) {
        need.score = calculateNeedScore(need, labels);
      }
      needs.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

      for (var need in needs) {
        final allocation = need.amount.clamp(0, availableFunds);
        need.allocated = allocation.toDouble();
        need.fulfilled = allocation >= need.amount;
        availableFunds -= allocation;
      }

      setState(() {
        results = needs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing data: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadJsonData().then((data) {
      solveCSP(data);
    });
  }

  Widget buildNode(Need need, bool isLast) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: need.fulfilled == true ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: need.fulfilled == true ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                need.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
              Text('Label: ${need.label}'),
              Text('Score: ${need.score?.toStringAsFixed(1)}'),
              Text(
                'Allocated: \$${need.allocated?.toStringAsFixed(2)} / \$${need.amount}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Icon(
            Icons.arrow_downward,
            size: 24,
            color: Colors.blue,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Needs Allocation'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          
              const SizedBox(height: 16),
              if (results != null) ...[
                const Text(
                  'Optimized Needs Allocation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: results!.length,
                    itemBuilder: (context, index) {
                      final need = results![index];
                      return buildNode(need, index == results!.length - 1);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
