import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poc_offline_first/controller/fruits_controller.dart';
import 'package:poc_offline_first/page/campaings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // await Hive.deleteBoxFromDisk('TestOffline');
  // await Hive.deleteBoxFromDisk('Campaigns');
  // await Hive.deleteBoxFromDisk('sync_data_box');
  // await Hive.deleteFromDisk();

  await Hive.openBox('TestOffline');
  await Hive.openBox('Campaigns');
  await Hive.openBox('sync_data_box');

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
      routes: {
        '/home': (context) => const HomePage(),
        '/campaigns': (context) => const Campaigns(),
      },
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
  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  // ignore: non_constant_identifier_names
  final String TABLE_NAME = 'TestOffline';

  // final _fruitTableBox = Hive.box('TestOffline');

  @override
  void initState() {
    super.initState();
    _fruitController.syncTransactions().then((_) => _refreshItems());
    // _refreshItems();
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  // Get all items from the database
  void _refreshItems() {
    var data = _fruitController.getAllItems(TABLE_NAME);

    setState(() {
      _items = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  // Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _fruitController.createItem('/post', newItem);
    _refreshItems(); // update the UI
  }

  // Update a single item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    Map<String, dynamic> fruit = {
      'name': item['name'],
      'quantity': item['quantity'],
    };

    await _fruitController.updateItem('/put', itemKey, fruit, TABLE_NAME);
    _refreshItems(); // Update the UI
  }

  // Delete a single item
  Future<void> _deleteItem(int itemKey) async {
    await _fruitController.deleteItem('/delete', itemKey);

    _refreshItems(); // update the UI

    // Display a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Um item foi removido')));
  }

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(BuildContext ctx, int? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item
    if (itemKey != null) {
      final Map<String, dynamic> fruit = await _fruitController.getItemById(itemKey, TABLE_NAME);

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
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              color: Theme.of(context).primaryColor,
              child: const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('Frutas'),
              // navigate to home page
              onTap: () => Navigator.of(context).pushNamed('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_rounded),
              title: const Text('Vaquinhas'),
              onTap: () => Navigator.of(context).pushNamed('/campaigns'),
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sincronizar'),
              onTap: () async {
                await _fruitController.syncTransactions();
                _refreshItems();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Frutas'),
      ),

      body: _items.isEmpty
          ? const Center(
              child: Text(
                'Sem dados para mostrar',
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
                      subtitle: Text(
                        'Quantidade: ${currentItem['quantity'].toString()} | Preço: ${currentItem['price'].toString() ?? ""}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                              icon: const Icon(Icons.edit), onPressed: () => _showForm(context, currentItem['id'])),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            // onPressed: () => _deleteItem(currentItem['id'].toString()),
                            onPressed: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CupertinoAlertDialog(
                                    title: const Text('Excluir Item'),
                                    content: Text('Deseja excluir ${currentItem['name']}?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  );
                                },
                              ).then((confirm) {
                                if (confirm) {
                                  _deleteItem(currentItem['id']);
                                }
                              });
                            },
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
