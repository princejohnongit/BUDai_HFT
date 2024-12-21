import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  double _balance = 0.0; // Initial balance (loaded dynamically)
  List<Transaction> _transactions = []; // Transactions (loaded dynamically)

  // Get the local file path
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  // Read data from data.json
  Future<void> _readData() async {
    final file = await _localFile;
    if (await file.exists()) {
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData);
      setState(() {
        _balance = data['balance'] ?? 0.0;
        _transactions = (data['transactions'] as List)
            .map((tx) => Transaction.fromJson(tx))
            .toList();
      });
    } else {
      // Create the file with default structure if it doesn't exist
      await file.writeAsString(jsonEncode({'balance': 0.0, 'transactions': []}));
    }
  }

  // Write data to data.json
  Future<void> _writeData() async {
    final file = await _localFile;
    final data = {
      'balance': _balance,
      'transactions': _transactions.map((tx) => tx.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data));
  }

  // Handle payments
  void _makePayment(double amount, String method) {
    setState(() {
      if (_balance >= amount) {
        _balance -= amount;
        _transactions.add(
          Transaction(amount: amount, type: "Sent via $method", date: DateTime.now()),
        );
        _writeData(); // Save to file
      } else {
        _showErrorDialog("Insufficient balance!");
      }
    });
  }

  // Request payments
  void _requestPayment(String contact, double amount) {
    setState(() {
      _transactions.add(
        Transaction(amount: amount, type: "Requested from $contact", date: DateTime.now()),
      );
      _writeData(); // Save to file
    });
  }

  // Show error dialogs
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _readData(); // Load data when the app starts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Interface'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance overview
            Text(
              "Balance: ₹${_balance.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Payment options
            ElevatedButton(
              onPressed: _showPaymentDialog,
              child: Text("Send Money"),
            ),
            SizedBox(height: 10),

            // Request Payment
            ElevatedButton(
              onPressed: _showRequestDialog,
              child: Text("Request Money"),
            ),
            SizedBox(height: 20),

            // Transaction History
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return ListTile(
                    title: Text("${transaction.type} ₹${transaction.amount}"),
                    subtitle: Text("${transaction.date.toLocal()}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double amount = 0;
        String method = "Account Number";
        return AlertDialog(
          title: Text("Send Money"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
                onChanged: (value) {
                  amount = double.tryParse(value) ?? 0;
                },
              ),
              DropdownButton<String>(
                value: method,
                items: [
                  "Account Number",
                  "UPI ID",
                  "Scan QR Code",
                ].map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    method = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _makePayment(amount, method);
                Navigator.pop(context);
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double amount = 0;
        String contact = "";
        return AlertDialog(
          title: Text("Request Money"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Contact"),
                onChanged: (value) {
                  contact = value;
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
                onChanged: (value) {
                  amount = double.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _requestPayment(contact, amount);
                Navigator.pop(context);
              },
              child: Text("Request"),
            ),
          ],
        );
      },
    );
  }
}

// Transaction model
class Transaction {
  final double amount;
  final String type;
  final DateTime date;

  Transaction({required this.amount, required this.type, required this.date});

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      amount: json['amount'],
      type: json['type'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
    };
  }
}
