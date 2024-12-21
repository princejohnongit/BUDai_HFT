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
    'profile': {},
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
        // Create a new file with the initial structure
        await _saveData();
      }
    } catch (e) {
      // Handle file read errors
      print("Error loading JSON data: $e");
    }
  }

  Future<void> _saveData() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(jsonData));
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
            child: jsonData['needs'].isEmpty
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
                          need['name']!,
                          style: TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          'Type: ${need['needType']} | Priority: ${need['priority']}',
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
  String needType = 'Long Term';
  final _formKey = GlobalKey<FormState>();
  String? selectedDuration, name, amount, priority;

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
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Total Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => amount = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter amount' : null,
                ),
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
                  labelText: 'Priority (High/Medium/Low)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => priority = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter priority' : null,
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newNeed = {
                        'needType': needType,
                        'duration': selectedDuration ?? '',
                        'amount': amount ?? '',
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
