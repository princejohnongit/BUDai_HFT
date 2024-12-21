import 'package:flutter/material.dart';
import 'needs_page.dart';
import 'income_page.dart';
import 'profile_page.dart';
import 'payment_page.dart';
import 'csp_page.dart';
import 'expenditure_page.dart';

void main() {
  runApp(MyApp());
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

