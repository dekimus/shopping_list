import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void removeItem(GroceryItem item) async {
    final index = groceryItems.indexOf(item);

    setState(() {
      groceryItems.remove(item);
    });
    final url = Uri.parse(
        'https://shopping-list-f02de-default-rtdb.europe-west1.firebasedatabase.app/shopping-list/${item.id}.json');
    final response = await http.delete(
      url,
    );

    if (response.statusCode >= 400) {
      setState(() {
        groceryItems.insert(index, item);
        _error = "An error occurred: ${response.statusCode}";
      });
    }
  }

  void _loadItems() async {
    final url = Uri.parse(
        'https://shopping-list-f02de-default-rtdb.europe-west1.firebasedatabase.app/shopping-list.json');
    try {
      final response = await http.get(
        url,
      );

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<GroceryItem> loadedItems = [];
      final Map<String, dynamic> data = json.decode(response.body);
      for (var dat in data.entries) {
        final cat = categories.entries
            .firstWhere(
                (element) => element.value.title == dat.value["category"])
            .value;
        loadedItems.add(GroceryItem(
            id: dat.key,
            name: dat.value["name"],
            quantity: dat.value["quantity"],
            category: cat));
      }
      setState(() {
        groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = "An error occurred: $error";
        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (context) {
        return const NewItem();
      },
    ));
    if (newItem != null) {
      setState(() {
        groceryItems.add(newItem);
      });
    }
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : groceryItems.isEmpty
              ? _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(child: Text("No items added...."))
              : ListView.builder(
                  itemCount: groceryItems.length,
                  itemBuilder: (context, index) {
                    final item = groceryItems[index];
                    return Dismissible(
                      key: Key(item.id),
                      child: ListTile(
                        title: Text(groceryItems[index].name),
                        leading: Container(
                          width: 24,
                          height: 24,
                          color: groceryItems[index].category.color,
                        ),
                        trailing: Text('${groceryItems[index].quantity}'),
                      ),
                      onDismissed: (direction) {
                        removeItem(item);
                      },
                    );
                  },
                ),
    );
  }
}
