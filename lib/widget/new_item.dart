import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = "";
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      _isSending = true;
      _formKey.currentState!.save();
      final url = Uri.parse(
          'https://shopping-list-f02de-default-rtdb.europe-west1.firebasedatabase.app/shopping-list.json');
      http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                "name": _enteredName,
                "quantity": _enteredQuantity,
                "category": _selectedCategory.title
              }))
          .then((response) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          Navigator.of(context).pop(GroceryItem(
              id: data['name'],
              name: _enteredName,
              quantity: _enteredQuantity,
              category: _selectedCategory));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    maxLength: 50,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text("Name")),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length <= 1 ||
                          value.trim().length > 50) {
                        return "Must be between 2 and 50 characters.";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredName = value!;
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          decoration: const InputDecoration(
                              label: Text("Quantity"),
                              border: OutlineInputBorder()),
                          initialValue: _enteredQuantity.toString(),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                int.tryParse(value) == null ||
                                int.tryParse(value)! <= 0) {
                              return "Must be a valid number.";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredQuantity = int.parse(value!);
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField(
                          value: _selectedCategory,
                          items: [
                            for (final cat in categories.entries)
                              DropdownMenuItem(
                                  value: cat.value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        color: cat.value.color,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(cat.value.title)
                                    ],
                                  ))
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: _isSending
                              ? null
                              : () {
                                  _formKey.currentState!.reset();
                                },
                          child: const Text("Reset")),
                      const SizedBox(
                        width: 24,
                      ),
                      ElevatedButton(
                          onPressed: _isSending ? null : _saveItem,
                          child: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator())
                              : const Text("Add item"))
                    ],
                  )
                ],
              ))),
    );
  }
}
