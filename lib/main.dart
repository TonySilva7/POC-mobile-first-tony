import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poc_offline_first/controller/fruits_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.deleteBoxFromDisk('shopping_box');
  await Hive.deleteBoxFromDisk('transaction_box');

  await Hive.openBox('shopping_box');
  await Hive.openBox('transaction_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POC Offline First',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _items = [];
  final FruitController _fruitController = FruitController();

  // final _shoppingBox = Hive.box('shopping_box');

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Load data when app starts
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  // Get all items from the database
  void _refreshItems() async {
    // final data = _shoppingBox.keys.map((key) {
    //   final value = _shoppingBox.get(key);
    //   return {"key": key, "name": value["name"], "quantity": value['quantity']};
    // }).toList();

    var data = await _fruitController.getAllItems('/get-all');

    setState(() {
      _items = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  // Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    // await _shoppingBox.add(newItem);
    await _fruitController.createItem('/post', newItem);
    _refreshItems(); // update the UI
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  // Map<String, dynamic> _readItem(int key) {
  //   final item = _shoppingBox.get(key);
  //   return item;
  // }

  // Update a single item
  Future<void> _updateItem(String itemKey, Map<String, dynamic> item) async {
    Map<String, dynamic> fruit = {
      'name': item['name'],
      'quantity': item['quantity'],
    };

    await _fruitController.updateItem('/put', int.parse(itemKey), fruit);
    _refreshItems(); // Update the UI
  }

  // Delete a single item
  Future<void> _deleteItem(String itemKey) async {
    // await _shoppingBox.delete(itemKey);
    await _fruitController.deleteItem('/delete', itemKey);

    _refreshItems(); // update the UI

    // Display a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Um item foi removido')));
  }

  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(BuildContext ctx, String? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item
    if (itemKey != null) {
      final Map<String, dynamic> fruit = await _fruitController.getItemById(itemKey);

      _nameController.text = fruit.isNotEmpty ? fruit['name'] : _nameController.text;
      _quantityController.text = fruit.isNotEmpty ? fruit['quantity'].toString() : _quantityController.text;
    }

    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 15, left: 15, right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Quantity'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new item
                      if (itemKey == null) {
                        _createItem({"name": _nameController.text, "quantity": _quantityController.text});
                      }

                      // update an existing item
                      if (itemKey != null) {
                        _updateItem(itemKey,
                            {'name': _nameController.text.trim(), 'quantity': _quantityController.text.trim()});
                      }

                      // Clear the text fields
                      _nameController.text = '';
                      _quantityController.text = '';

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(itemKey == null ? 'Adicionar' : 'Atualizar'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POC Offline First'),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(
              // the list of items
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final currentItem = _items[index];
                return Card(
                  color: Colors.orange.shade100,
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                      title: Text(currentItem['name']),
                      subtitle: Text(currentItem['quantity'].toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                              icon: const Icon(Icons.edit), onPressed: () => _showForm(context, currentItem['id'])),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(currentItem['id'].toString()),
                          ),
                        ],
                      )),
                );
              }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
