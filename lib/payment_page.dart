import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  double _balance = 5000.0; // Initial balance
  List<Transaction> _transactions = []; // List to hold transactions

  // Function to handle payments
  void _makePayment(double amount, String method) {
    setState(() {
      if (_balance >= amount) {
        _balance -= amount;
        _transactions.add(
          Transaction(amount: amount, type: "Sent via $method", date: DateTime.now()),
        );
      } else {
        _showErrorDialog("Insufficient balance!");
      }
    });
  }

  // Function to show error dialogs
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

  // Function to handle payment request
  void _requestPayment(String contact, double amount) {
    setState(() {
      _transactions.add(
        Transaction(amount: amount, type: "Requested from $contact", date: DateTime.now()),
      );
    });
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
            Text(
              "Make a Payment:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _showPaymentDialog();
              },
              child: Text("Send Money"),
            ),
            SizedBox(height: 20),

            // Request Payment
            Text(
              "Request Payment:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _showRequestDialog();
              },
              child: Text("Request Money"),
            ),
            SizedBox(height: 20),

            // Transaction History
            Text(
              "Transaction History:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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

            // Transaction Graph
            SizedBox(height: 20),
            Text(
              "Transaction Graph:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: _transactions.length.toDouble(),
                  minY: 0,
                  maxY: _balance + 1000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _transactions
                          .asMap()
                          .map((index, transaction) {
                            return MapEntry(
                              index,
                              FlSpot(index.toDouble(), _balance - transaction.amount),
                            );
                          })
                          .values
                          .toList(),
                      isCurved: true,
                      colors: [Colors.blue],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
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

// Transaction model to hold transaction data
class Transaction {
  final double amount;
  final String type;
  final DateTime date;

  Transaction({
    required this.amount,
    required this.type,
    required this.date,
  });
}
