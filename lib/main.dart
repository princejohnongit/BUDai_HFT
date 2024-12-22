import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'needs_page.dart';
import 'income_page.dart';
import 'profile_page.dart';
import 'payment_page.dart';
import 'csp_page.dart';
import 'expenditure_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeJsonFile(); // Ensure the file is initialized before the app runs
  runApp(MyApp());
}

Future<void> initializeJsonFile() async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/data.json';
  final file = File(filePath);

  if (!(await file.exists())) {
    const defaultData = {
      "needs": [],
      "income": [],
      "profile": {
        "name": "",
        "subscription": "",
        "email": "",
        "phone": "",
        "labels": []
      },
      "expenditure": [],
      "payment": [],
      "transactions": []
    };
    await file.writeAsString(jsonEncode(defaultData));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Budget',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    NeedsPage(),
    IncomePage(),
    ProfilePage(),
    ExpenditurePage(),
    PaymentPage(),
    FinancialCSPSolver()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Budget'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list, size: 30),
            label: 'Needs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money, size: 30),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off, size: 30),
            label: 'Expenditure',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment, size: 30),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment, size: 30),
            label: 'Best Plan',
          )
        ],
      ),
    );
  }
}

// PaymentPage Example
class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  double _balance = 0.0; // Initial balance (calculated dynamically)
  List<Transaction> _transactions = []; // Transactions (loaded dynamically)

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<void> _readData() async {
    final file = await _localFile;

    if (await file.exists()) {
      try {
        final jsonData = await file.readAsString();

        if (jsonData.isEmpty) {
          throw FormatException("File is empty");
        }

        final data = jsonDecode(jsonData);
        setState(() {
          _transactions = (data['transactions'] as List)
              .map((tx) => Transaction.fromJson(tx))
              .toList();

          _balance = _calculateBalance(); // Recalculate balance dynamically
        });
      } catch (e) {
        print("Error loading JSON data: $e");

        const defaultData = {
          "transactions": [],
        };
        await file.writeAsString(jsonEncode(defaultData));

        setState(() {
          _balance = 0.0;
          _transactions = [];
        });
      }
    } else {
      const defaultData = {
        "transactions": [],
      };
      await file.writeAsString(jsonEncode(defaultData));
      setState(() {
        _balance = 0.0;
        _transactions = [];
      });
    }
  }

  Future<void> _writeData() async {
    final file = await _localFile;
    final data = {
      'transactions': _transactions.map((tx) => tx.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data));
  }

  double _calculateBalance() {
    double income = _transactions
        .where((tx) => tx.type.startsWith('Income'))
        .fold(0.0, (sum, tx) => sum + tx.amount);
    double expenditure = _transactions
        .where((tx) => tx.type.startsWith('Expenditure'))
        .fold(0.0, (sum, tx) => sum + tx.amount);
    return income - expenditure;
  }

  @override
  void initState() {
    super.initState();
    _readData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Balance: ₹${_balance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return ListTile(
                  title: Text('${transaction.type}: ₹${transaction.amount}'),
                  subtitle: Text(transaction.date.toString()),
                );
              },
            ),
          ),
        ],
      ),
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
