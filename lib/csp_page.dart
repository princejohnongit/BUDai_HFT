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
  final String priority;
  double? allocated;
  double? score;
  bool? fulfilled;

  Need({
    required this.needType,
    required this.duration,
    required this.amount,
    required this.name,
    required this.priority,
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
      priority: json['priority'] as String,
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
    double score = 0;

    // Priority scoring
    // switch (need.priority.toLowerCase()) {
    //   case "high":
    //     score += 3;
    //     break;
    //   case "medium":
    //     score += 2;
    //     break;
    //   case "low":
    //     score += 1;
    //     break;
    // }

    // Label position scoring
    final labelIndex = labels.indexWhere(
        (label) => need.name.toLowerCase().contains(label.toLowerCase()));

    if (labelIndex != -1) {
      score += (labels.length - labelIndex);
    }

    return score;
  }

  void solveCSP(Map<String, dynamic> data) {
    try {
      // Parse income data
      final incomes =
          (data['income'] as List).map((inc) => Income.fromJson(inc)).toList();

      // Calculate monthly income
      final monthlyIncome = calculateTotalIncome(incomes);
      var availableFunds = monthlyIncome;

      // Parse and score needs
      final needs =
          (data['needs'] as List).map((need) => Need.fromJson(need)).toList();

      final labels = (data['profile']['labels'] as List).cast<String>();

      // Score and sort needs
      for (var need in needs) {
        need.score = calculateNeedScore(need, labels);
      }
      needs.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

      // Allocate funds
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
      solveCSP(data); // Solve CSP when data is loaded
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                final data = await _loadJsonData();
                solveCSP(data);
              },
              child: const Text('Analyze Financial Needs'),
            ),
            const SizedBox(height: 16),
            if (results != null) ...[
              const Text(
                'Optimized Needs Allocation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: results!.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final need = results![index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                need.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Score: ${need.score?.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Priority: ${need.priority}'),
                              Text(
                                'Allocated: \$${need.allocated?.toStringAsFixed(2)} / \$${need.amount}',
                              ),
                            ],
                          ),
                          if (index < results!.length - 1)
                            const Center(
                              child: Icon(
                                Icons.arrow_downward,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
