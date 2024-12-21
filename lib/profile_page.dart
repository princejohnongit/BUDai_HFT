import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _subscription = "";
  List<String> _labels = [];

  Map<String, dynamic> _kycData = {}; // Data loaded from the file.

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data on initialization.
  }

  // Get the local file path
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  // Load existing data from the file
  Future<void> _loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          _kycData = jsonDecode(contents);
          _labels = List<String>.from(_kycData["profile"]?["labels"] ?? []);
        });
      } else {
        // Initialize with a basic structure if file doesn't exist.
        _kycData = {
          "needs": [],
          "income": [],
          "profile": {},
          "expenditure": [],
          "payment": []
        };
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  // Save data to the file
  Future<void> _saveKYC() async {
    // Update profile data in the map.
    _kycData["profile"] = {
      "name": _nameController.text,
      "subscription": _subscription,
      "email": _emailController.text,
      "phone": _phoneController.text,
      "labels": _labels,
    };

    final jsonString = jsonEncode(_kycData);

    try {
      final file = await _localFile;
      await file.writeAsString(jsonString);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Data Saved'),
          content: Text('Data saved to: ${file.path}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to save KYC: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
    }
  }

  // Add label functionality
  Future<void> _addLabel() async {
    String newLabel = "";
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Priority Label'),
          content: TextField(
            onChanged: (value) {
              newLabel = value;
            },
            decoration: InputDecoration(hintText: "Enter label name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newLabel.isNotEmpty) {
                  setState(() {
                    _labels.add(newLabel);
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Remove label functionality
  Future<void> _removeLabel(int index) async {
    setState(() {
      _labels.removeAt(index);
    });
    await _saveKYC();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            DropdownButtonFormField<String>(
              value: _subscription.isEmpty ? null : _subscription,
              items: ["Free", "Premium"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _subscription = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Subscription'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addLabel,
              child: Text('Add Priority Label'),
            ),
            SizedBox(height: 20),
            Text(
              'Priority Labels:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final label = _labels.removeAt(oldIndex);
                    _labels.insert(newIndex, label);
                  });
                },
                children: _labels
                    .asMap()
                    .map((index, label) => MapEntry(
                          index,
                          ListTile(
                            key: ValueKey(label),
                            title: Text(label),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => _removeLabel(index),
                            ),
                          ),
                        ))
                    .values
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveKYC,
          child: Text('Save'),
        ),
      ),
    );
  }
}
