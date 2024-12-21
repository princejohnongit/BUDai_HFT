import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class IncomePage extends StatefulWidget {
  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  List<Map<String, dynamic>> savedIncome = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  // Get the local file path
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/data.json');

    // Create the file if it doesn't exist
    if (!await file.exists()) {
      await file.create();
      await file.writeAsString(jsonEncode({'income': []}));
    }
    return file;
  }

  // Save income to the JSON file
  Future<void> _saveIncome(Map<String, dynamic> newIncome) async {
    final file = await _localFile;
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final List<dynamic> existingIncome = jsonData['income'] ?? [];
      existingIncome.add(newIncome);
      jsonData['income'] = existingIncome;

      await file.writeAsString(jsonEncode(jsonData));

      setState(() {
        savedIncome = List<Map<String, dynamic>>.from(existingIncome);
      });
    } catch (e) {
      print('Error saving income: $e');
    }
  }

  // Load income from the JSON file
  Future<void> _loadIncome() async {
    try {
      setState(() => isLoading = true);
      final file = await _localFile;
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      setState(() {
        savedIncome = (jsonData['income'] as List?)
                ?.map((item) => Map<String, dynamic>.from(item))
                .toList() ??
            [];
      });
    } catch (e) {
      print('Error loading income: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Remove income from the JSON file and the list
  Future<void> _removeIncome(int index) async {
    try {
      final file = await _localFile;
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final List<dynamic> existingIncome = jsonData['income'] ?? [];
      existingIncome.removeAt(index);
      jsonData['income'] = existingIncome;

      await file.writeAsString(jsonEncode(jsonData));

      setState(() {
        savedIncome = List<Map<String, dynamic>>.from(existingIncome);
      });
    } catch (e) {
      print('Error removing income: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Income Page'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: savedIncome.isEmpty
                      ? Center(
                          child: Text(
                            'No income added yet. Click "Add Income" to start!',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: savedIncome.length,
                          itemBuilder: (context, index) {
                            final income = savedIncome[index];
                            return ListTile(
                              leading: Icon(Icons.monetization_on,
                                  color: Colors.green),
                              title: Text(
                                income['amount']?.toString() ?? 'No Amount',
                                style: TextStyle(fontSize: 18),
                              ),
                              subtitle: Text(
                                'Type: ${income['type']} | Reliability: ${income['reliability']} | Frequency: ${income['frequency']}',
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeIncome(index),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final newIncomeData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddIncomePage()),
                      );
                      if (newIncomeData != null) {
                        await _saveIncome(newIncomeData);
                      }
                    },
                    child: Text('Add Income'),
                  ),
                ),
              ],
            ),
    );
  }
}

class AddIncomePage extends StatefulWidget {
  @override
  _AddIncomePageState createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  String? amount, type, reliability, frequency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Income'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => amount = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the amount' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                items: [
                  'Rental Income',
                  'Freelance Earning',
                  'Incentive',
                  'Profit'
                ]
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    type = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select a type' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: reliability,
                items: [
                  'High Reliability',
                  'Medium Reliability',
                  'Low Reliability'
                ]
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    reliability = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Reliability',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select reliability' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: frequency,
                items: ['Daily', 'Weekly', 'Monthly', '6 Months', 'Yearly']
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    frequency = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select a frequency' : null,
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newIncome = {
                        'amount': amount!,
                        'type': type!,
                        'reliability': reliability!,
                        'frequency': frequency!,
                      };
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Income Added Successfully!')),
                      );
                      Navigator.pop(context, newIncome);
                    }
                  },
                  child: Text('Save Income'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
