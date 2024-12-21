import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ExpenditurePage extends StatefulWidget {
  @override
  _ExpenditurePageState createState() => _ExpenditurePageState();
}

class _ExpenditurePageState extends State<ExpenditurePage> {
  List<Map<String, dynamic>> expenditure = [];
  List<Map<String, dynamic>> savedIncome = [];

  @override
  void initState() {
    super.initState();
    loadExpenditureData();
  }

  // Get the local file path for data.json
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  // Load the expenditure data from the local file
  Future<void> loadExpenditureData() async {
    try {
      final file = await _localFile;
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData);
      
      setState(() {
        expenditure = List<Map<String, dynamic>>.from(data['expenditure']);
      });
    } catch (e) {
      // Handle file read error (file not found, parsing issue, etc.)
      print("Error reading file: $e");
    }
  }

  // Save income to the JSON file
  Future<void> _saveIncome() async {
    final file = await _localFile;
    try {
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData);

      // Modify the data with the new income
      data['income'] = savedIncome;

      // Save the modified data back to the file
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Handle file read/write error
      print("Error saving income: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenditure'),
      ),
      body: expenditure.isEmpty
          ? Center(child: Text('No expenditure data available.'))
          : ListView.builder(
              itemCount: expenditure.length,
              itemBuilder: (context, index) {
                final item = expenditure[index];
                final timestamp = DateTime.parse(item['timestamp']);
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item['name'], style: TextStyle(fontSize: 18)),
                    subtitle: Text(
                      'Amount: \$${item['amount']}\nDate: ${timestamp.toLocal()}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
