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

  Map<String, dynamic> _kycData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<void> _loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        
        setState(() {
          _kycData = data;
          
          // Load profile data if it exists
          if (_kycData.containsKey("profile")) {
            final profile = _kycData["profile"];
            _nameController.text = profile["name"] ?? "";
            _emailController.text = profile["email"] ?? "";
            _phoneController.text = profile["phone"] ?? "";
            _subscription = profile["subscription"] ?? "";
            _labels = List<String>.from(profile["labels"] ?? []);
          } else {
            // Initialize with empty profile if it doesn't exist
            _kycData["profile"] = {
              "name": "",
              "email": "",
              "phone": "",
              "subscription": "",
              "labels": []
            };
          }
        });
      } else {
        // Initialize with a basic structure if file doesn't exist
        _kycData = {
          "needs": [],
          "income": [],
          "profile": {
            "name": "",
            "email": "",
            "phone": "",
            "subscription": "",
            "labels": []
          },
          "expenditure": [],
          "payment": []
        };
      }
    } catch (e) {
      print("Error loading data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $e')),
      );
    }
  }

  Future<void> _saveKYC() async {
    try {
      final file = await _localFile;
      
      // Read existing data first
      String existingData = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(existingData);
      
      // Update only the profile section
      jsonData["profile"] = {
        "name": _nameController.text,
        "subscription": _subscription,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "labels": _labels,
      };

      // Write back the entire data
      await file.writeAsString(jsonEncode(jsonData));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> _addLabel() async {
    String newLabel = "";
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Label'),
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
      body: SingleChildScrollView(
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
              child: Text('Add Label'),
            ),
            SizedBox(height: 20),
            Text(
              'Priority Labels:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
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