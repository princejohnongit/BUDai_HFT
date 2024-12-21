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

  void _showChatWindow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat, size: 28, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Chat with Buddy",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Hello there. Myself Buddy to help you!",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Placeholder for user messages or chatbot responses
                        Text(
                          "Feel free to ask me anything about your expenditures.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenditure'),
      ),
      body: Stack(
        children: [
          expenditure.isEmpty
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
          // Chatbot bubble with "Let's Chat" text
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showChatWindow,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Let's Chat",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _showChatWindow,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
