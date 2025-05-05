import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  User? user = FirebaseAuth.instance.currentUser;
  final _itemController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
    } else {
      throw Exception('no user signed in');
    }
  }

  Future<void> _addItem(String itemName) async {
    final lowerItemName = itemName.toLowerCase();
    final ingredientDoc = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('ingredients')
        .doc(lowerItemName)
        .get();

    if (ingredientDoc.exists) {
      _showAlreadyExistsDialog(lowerItemName);
    } else {
      _addItemToShoppingList(lowerItemName);
    }
  }

  void _addItemToShoppingList(String itemName) {
    _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shoppingList')
        .add({
      'name': itemName,
      'quantity': 1, // default quantity set to 1
      'createdAt': FieldValue.serverTimestamp(),
      'isChecked': false, // default to unchecked
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ingredient added to shopping list!')),
    );

    _itemController.clear();
  }

  void _showAlreadyExistsDialog(String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('item already exists'),
        content: Text('you already have this ingredient. add to shopping list anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addItemToShoppingList(itemName);
            },
            child: Text('yes'),
          ),
        ],
      ),
    );
  }

  void _updateItemChecked(String itemId, bool isChecked) {
    _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shoppingList')
        .doc(itemId)
        .update({'isChecked': isChecked});
  }

  void _updateItemQuantity(String itemId, int quantity) {
    if (quantity > 0) {
      _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('shoppingList')
          .doc(itemId)
          .update({'quantity': quantity});
    }
  }

  void _deleteItem(String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('shoppingList')
          .doc(itemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('item removed from shopping list!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error deleting item.')),
      );
    }
  }


  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userShoppingListRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shoppingList')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "s h o p p i n g   l i s t",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF283618),
          ),
        ),
        centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'enter item',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final itemName = _itemController.text.trim();
                    if (itemName.isNotEmpty) {
                      _addItem(itemName);
                    }
                  },
                  child: Text('add'),
                ),
              ],
            ),
            SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: userShoppingListRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('error loading shopping list.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!.docs;

                  if (items.isEmpty) {
                    return Center(child: Text('no items in your shopping list.'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemId = item.id;
                      final itemName = item['name'];
                      final quantity = item['quantity'];
                      final isChecked = item['isChecked'];

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                        title: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: Offset(0, 2), // vertical offset of shadow
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isChecked,
                              onChanged: (bool? newValue) {
                                _updateItemChecked(itemId, newValue ?? false);
                              },
                            ),
                            title: Text(
                              itemName,
                              style: TextStyle(
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  'quantity: ',
                                  style: TextStyle(
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(text: '$quantity'),
                                    decoration: InputDecoration(border: InputBorder.none),
                                    style: TextStyle(
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                      fontSize: 12,
                                    ),
                                    onChanged: (value) {
                                      final qty = int.tryParse(value);
                                      if (qty != null) {
                                        _updateItemQuantity(itemId, qty);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteItem(itemId);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
