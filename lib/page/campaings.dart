import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:poc_offline_first/controller/fruits_controller.dart';

class Campaigns extends StatefulWidget {
  const Campaigns({super.key});

  @override
  State<Campaigns> createState() => _CampaignsState();
}

class _CampaignsState extends State<Campaigns> {
  List<Map<String, dynamic>> _items = [];
  final FruitController _fruitController = FruitController();
  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // ignore: non_constant_identifier_names
  final String TABLE_NAME = 'Campaigns';

  @override
  void initState() {
    super.initState();
    _fruitController.syncTransactions().then((_) => _refreshItems());
  }

  @override
  void dispose() {
    // Hive.close();
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
      'goalValue': item['goalValue'],
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

  void _showForm(BuildContext ctx, int? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item
    if (itemKey != null) {
      final Map<String, dynamic> fruit = await _fruitController.getItemById(itemKey, TABLE_NAME);

      _nameController.text = fruit.isNotEmpty ? fruit['name'] : _nameController.text;
      _quantityController.text =
          fruit.isNotEmpty ? (fruit['quantity'] ?? fruit['goalValue']).toString() : _quantityController.text;
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
                            {'name': _nameController.text.trim(), 'goalValue': _quantityController.text.trim()});
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
    // return an Scaffold with elements like fruits
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campanhas'),
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
    );
  }
}
