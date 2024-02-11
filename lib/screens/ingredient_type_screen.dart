// IngredientTypeScreen.dart
import 'package:flutter/material.dart';
import '../types.dart';
import 'recipe_screen.dart';

class IngredientTypeScreen extends StatefulWidget {
  final IngredientType type;
  final int index;
  final RecipesState state;

  IngredientTypeScreen({required this.type, required this.index, required this.state});

  @override
  _IngredientTypeScreenState createState() => _IngredientTypeScreenState();
}

class _IngredientTypeScreenState extends State<IngredientTypeScreen> {
  late IngredientUnit unit;

  @override
  void initState() {
    super.initState();
    unit = widget.type.unit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change unit'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current unit: ${widget.type.unit.name}'),
          const SizedBox(height: 16),
          DropdownButton<IngredientUnit>(
            value: unit,
            onChanged: (IngredientUnit? newValue) {
              setState(() {
                unit = newValue!;
              });
            },
            items: IngredientUnit.values.map((IngredientUnit unit) {
              return DropdownMenuItem<IngredientUnit>(
                value: unit,
                child: Text(unit.name),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            widget.state.ingredientTypes[widget.index] = IngredientType(
                widget.type.name, unit);
            widget.state.save();
          });
          Navigator.pop(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}