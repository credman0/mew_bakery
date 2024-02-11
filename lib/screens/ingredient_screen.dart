import 'package:flutter/material.dart';
import '../types.dart';

class IngredientTypeCreationScreen extends StatefulWidget {
  final RecipesState state;
  IngredientType ingredientType = const IngredientType('', IngredientUnit.g);

  IngredientTypeCreationScreen({Key? key, required this.state})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => IngredientTypeCreationScreenState();
}

class IngredientTypeCreationScreenState
    extends State<IngredientTypeCreationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Ingredient Type'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                onChanged: (String value) {
                  setState(() {
                    widget.ingredientType = IngredientType(
                        value, widget.ingredientType.unit);
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<IngredientUnit>(
                value: widget.ingredientType.unit,
                onChanged: (IngredientUnit? newValue) {
                  setState(() {
                    widget.ingredientType = IngredientType(
                        widget.ingredientType.name, newValue!);
                  });
                },
                items: IngredientUnit.values.map((IngredientUnit unit) {
                  return DropdownMenuItem<IngredientUnit>(
                    value: unit,
                    child: Text(unit.name),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, widget.ingredientType);
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}