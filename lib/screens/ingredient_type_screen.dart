// IngredientTypeScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../types.dart';
import 'recipe_screen.dart';

class IngredientTypeScreen extends StatefulWidget {
  final IngredientType type;
  final int index;
  final RecipesState state;

  IngredientTypeScreen(
      {required this.type, required this.index, required this.state});

  @override
  _IngredientTypeScreenState createState() => _IngredientTypeScreenState();
}

class _IngredientTypeScreenState extends State<IngredientTypeScreen> {
  late IngredientUnit unit;
  late double gPerMl;

  @override
  void initState() {
    super.initState();
    unit = widget.type.unit;
    gPerMl = widget.type.gPerMl;
  }

  @override
  Widget build(BuildContext context) {
    final gPerMlController = TextEditingController(text: gPerMl.toString());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change unit'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 16),
          TextField(
            controller: gPerMlController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'gPerMl',
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allow digits and a decimal point anywhere.
              FilteringTextInputFormatter.deny(RegExp(r'\.\d*\.')), // Disallow multiple consecutive decimal points.
            ],// numbers can be entered
            onChanged: (value) {
              if (value == "") {
                gPerMl = 0;
                return;
              }
              gPerMl = double.parse(value);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            widget.state.ingredientTypes[widget.index] =
                IngredientType(widget.type.name, unit, gPerMl: gPerMl);
            widget.state.save();
          });
          Navigator.pop(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
