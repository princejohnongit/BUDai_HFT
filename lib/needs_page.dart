import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NeedsPage extends StatefulWidget {
  @override
  _NeedsPageState createState() => _NeedsPageState();
}

class _NeedsPageState extends State<NeedsPage> {
  Map<String, dynamic> jsonData = {
    'needs': [],
    'income': [],
    'profile': {'labels': []},
    'expenditure': [],
    'payment': []
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<void> _loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final fileContent = await file.readAsString();
        setState(() {
          jsonData = jsonDecode(fileContent);
        });
      } else {
        await _saveData();
      }
    } catch (e) {
      print("Error loading JSON data: $e");
    }
  }

  Future<void> _saveData() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(jsonData));
  }

  void removeNeed(int index) {
    setState(() {
      final removedNeed = jsonData['needs'].removeAt(index);
      jsonData['expenditure'].add({
        'name': removedNeed['name'],
        'amount': removedNeed['amount'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _saveData();
  }

  void addNeed(Map<String, dynamic> need) {
    setState(() {
      jsonData['needs'].add(need);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Needs Page'),
      ),
      body: Column(
        children: [
          Expanded(
            child: (jsonData['needs'] == null || jsonData['needs'].isEmpty)
                ? Center(
                    child: Text(
                      'No needs added yet. Click "Add Need" to start!',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: jsonData['needs'].length,
                    itemBuilder: (context, index) {
                      final need = jsonData['needs'][index];
                      return ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                          need['name'],
                          style: TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          'Type: ${need['needType']} | Label: ${need['priority']} | Amount: ${need['amount']}',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeNeed(index),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                final newNeedData = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddNeedPage()),
                );
                if (newNeedData != null) {
                  addNeed(newNeedData);
                }
              },
              child: Text('Add Need'),
            ),
          ),
        ],
      ),
    );
  }
}

class AddNeedPage extends StatefulWidget {
  @override
  _AddNeedPageState createState() => _AddNeedPageState();
}

class _AddNeedPageState extends State<AddNeedPage> {
  Map<String, dynamic> jsonData = {
    'needs': [],
    'income': [],
    'profile': {'labels': []},
    'expenditure': [],
    'payment': []
  };

  String needType = 'Long Term';
  final _formKey = GlobalKey<FormState>();
  String? selectedDuration, name, amount, priority;
  List<String> labels = [];
  String newLabel = '';

  @override
  void initState() {
    super.initState();
    loadExpenditureData();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<void> loadExpenditureData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final fileContent = await file.readAsString();
        jsonData = jsonDecode(fileContent);
        setState(() {
          if (jsonData.containsKey('profile') &&
              jsonData['profile'].containsKey('labels')) {
            labels = List<String>.from(jsonData['profile']['labels']);
          }
        });
      }
    } catch (e) {
      print("Error reading file: $e");
    }
  }

  Future<void> saveDataToJson() async {
    try {
      final file = await _localFile;

      // Add new label if it doesn't exist and has a value
      if (newLabel.isNotEmpty &&
          !jsonData['profile']['labels'].contains(newLabel)) {
        List<dynamic> currentLabels = List.from(jsonData['profile']['labels']);
        currentLabels.add(newLabel);

        // Update labels in jsonData
        jsonData['profile']['labels'] = currentLabels;

        // Write back the entire data
        await file.writeAsString(jsonEncode(jsonData));

        // Update local state
        setState(() {
          labels = List<String>.from(currentLabels);
        });
      }
    } catch (e) {
      print("Error writing to file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving label: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Need'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: needType,
                items: ['Long Term', 'Short Term']
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    needType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Need Type',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              if (needType == 'Long Term') ...[
                DropdownButtonFormField<String>(
                  value: selectedDuration,
                  items: ['Daily', 'Weekly', 'Monthly', '6 Months', 'Yearly']
                      .map((duration) => DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDuration = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ? 'Please select a duration' : null,
                ),
                SizedBox(height: 16),
              ],
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => name = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => amount = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an amount' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                items:
                    labels
                        .map((label) => DropdownMenuItem<String>(
                              value: label,
                              child: Text(label),
                            ))
                        .toList(),
                onChanged: (value) async {
                  if (value == 'Add New Label') {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Add New Label'),
                        content: TextField(
                          onChanged: (value) {
                            newLabel = value;
                          },
                          decoration: InputDecoration(hintText: "Enter label"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, newLabel),
                            child: Text('Add'),
                          ),
                        ],
                      ),
                    );

                    if (result != null && result.isNotEmpty) {
                      print(result);
                      setState(() {
                        labels.add(result);
                        priority = result;
                      });
                      await saveDataToJson();
                    }
                  } else {
                    setState(() {
                      priority = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select or add a label' : null,
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newNeed = {
                        'needType': needType,
                        'duration': needType == 'Long Term'
                            ? selectedDuration ?? ''
                            : '',
                        'amount': amount!,
                        'name': name!,
                        'priority': priority!,
                      };
                      Navigator.pop(context, newNeed);
                    }
                  },
                  child: Text('Save Need'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
