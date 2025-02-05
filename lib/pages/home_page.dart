import 'package:flutter/material.dart';
import '../services/database_services.dart';
import '../utils/expense_list.dart';
import '../models/expense.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final DatabaseService _databaseService = DatabaseService.instance;


  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();


  List<Expense> _expenses = []; // Store expenses locally, _loadExpenses loads data in here on startup
  bool _isLoading = true; // Track loading state
  int _total = 0;

  @override
  void initState() { // runs on startup
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    _expenses = await _databaseService.getExpenseDB();
    updateExpenseTotal(); // Update total only when data is fetched
    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  void updateExpenseTotal() async {
    var total = (await _databaseService.calculateTotalDB())[0]['Total'];
    setState(() {
      if (total == null){
        _total = 0;
      }
      else if (total is int){
        _total = total;
      }
      else{
        _total = total.toInt();
      }
    });
    
  }

  void addExpensePos() async { // called when + button is pressed
    if (_controller1.text.isNotEmpty && _controller2.text.isNotEmpty) {
      int amount = int.parse(_controller2.text);
      await _databaseService.addExpenseDB(_controller1.text, amount);

      setState(() {
        _expenses.add(Expense(id: _expenses.length + 1, content: _controller1.text, amount: amount)); // add to local list
        _total += amount; // Update total locally
        _controller1.clear();
        _controller2.clear();
      });
    }
  }

  void addExpenseNeg() async { // called when - button is pressed
    if (_controller1.text.isNotEmpty && _controller2.text.isNotEmpty) {
      int amount = -int.parse(_controller2.text);
      await _databaseService.addExpenseDB(_controller1.text, amount);

      setState(() {
        _expenses.add(Expense(id: _expenses.length + 1, content: _controller1.text, amount: amount));
        _total += amount; // Update total locally
        _controller1.clear();
        _controller2.clear();
      });
    }
  }


  void deleteExpense(int index) async {
    // Get the expense amount before deleting (to update total)
    int removedAmount = _expenses[index].amount;
    int removedId = _expenses[index].id;

    // First, delete from the database
    await _databaseService.deleteExpenseDB(removedId);

    // Then, update the UI
    setState(() {
      _total -= removedAmount;  // Update total
      _expenses.removeAt(index);  // Remove item from the list
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Expense Log'),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),

      // BODY ----------------------------
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox( // the total displayed in center
            height: 60,
            child: 
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      "₹$_total",
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
              ),
          const Padding( // Your expenses text below total
            padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your expenses: ",

                style: TextStyle(color: Color.fromARGB(255, 88, 88, 88)),
              ),
            ),
          ),
          Expanded( // actual list of expenses
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _expenseList()
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded( // expense content input field
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 5),
                  child: TextField(
                    controller: _controller1,
                    decoration: InputDecoration(
                        hintText: 'Add expense',
                        hintStyle: const TextStyle(fontSize: 15),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade900),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(15),
                        )),
                  ),
                )),
            Expanded( // expense amount input field
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: TextField(
                    controller: _controller2,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      
                        hintText: 'Add ₹',
                        hintStyle: const TextStyle(fontSize: 15),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade900),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(15),
                        )),
                  ),
                )),
            Padding( // + button
              padding: const EdgeInsets.only(right: 5),
              child: FloatingActionButton(
                foregroundColor: Colors.black,
                backgroundColor: Colors.grey.shade100,
                onPressed: addExpensePos,
                child: const Icon(Icons.add),
              ),
            ),
            Padding( // - button
              padding: const EdgeInsets.only(),
              child: FloatingActionButton(
                foregroundColor: Colors.black,
                backgroundColor: Colors.grey.shade100,
                onPressed: addExpenseNeg,
                child: const Icon(Icons.remove),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expenseList() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator()); // Show loading indicator
  }

  return ListView.builder(
    itemCount: _expenses.length,
    itemBuilder: (BuildContext context, index) {
      Expense expense = _expenses[index];
      return ExpenseList(
        expenseName: expense.content,
        expenseCost: expense.amount,
        deleteFunction: (context) => deleteExpense(index),
      );
    },
  );
}

}
