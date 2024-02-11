import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../types.dart';
import 'ingredient_screen.dart';
import 'ingredient_type_screen.dart';

class RecipeScreenState extends State<RecipeScreen> {
  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
            'This recipe has unsaved changes. Are you sure you want to leave?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Leave'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make a sorted copy of the ingredient list for each section
    List<List<Ingredient>> sortedSectionIngredients = [];
    for (RecipeSection section in widget.recipe.sections) {
      // Copy the list of ingredients and sort it
      List<Ingredient> sortedIngredients = List.from(section.ingredients);
      sortedIngredients.sort((a, b) => a.typeName.compareTo(b.typeName));
      sortedSectionIngredients.add(sortedIngredients);
    }
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          if (widget.state.isRecipeChanged(widget.recipe)) {
            _showBackDialog();
          } else {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.recipe.name,
              style: const TextStyle(
                fontSize: 24, // Increase the font size
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
          ),
          // Add a list view with the recipe sections
          body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(children: [
                ListView.builder(
                    scrollDirection: Axis.vertical, 
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: widget.recipe.sections.length,
                    itemBuilder: (BuildContext context, int index) {
                      RecipeSection section = widget.recipe.sections[index];
                      List<Ingredient> sortedIngredients =
                          sortedSectionIngredients[index];
                      // Nest a list view with the ingredients in each section
                      return Card(
                          elevation: 2.0, 
                          child: Column(
                            children: [
                              SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Spacer(),
                                        TextButton(
                                          child: Text(section.name,
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.black)),
                                          onLongPress: () {
                                            // Allow user to rename or delete the section
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Rename section'),
                                                  content: TextField(
                                                    controller:
                                                        TextEditingController(
                                                            text: section.name),
                                                    onChanged: (String value) {
                                                      setState(() {
                                                        section.name = value;
                                                      });
                                                    },
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          widget.recipe.sections
                                                              .removeAt(index);
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Delete'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text('Save'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          onPressed: () {},
                                        ),
                                        const Spacer(),
                                        // Move up or down the list
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              if (index > 0) {
                                                RecipeSection temp = widget
                                                    .recipe.sections[index];
                                                widget.recipe.sections[index] =
                                                    widget.recipe
                                                        .sections[index - 1];
                                                widget.recipe
                                                    .sections[index - 1] = temp;
                                              }
                                            });
                                          },
                                          child: const Icon(Icons.arrow_upward),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              if (index <
                                                  widget.recipe.sections
                                                          .length -
                                                      1) {
                                                RecipeSection temp = widget
                                                    .recipe.sections[index];
                                                widget.recipe.sections[index] =
                                                    widget.recipe
                                                        .sections[index + 1];
                                                widget.recipe
                                                    .sections[index + 1] = temp;
                                              }
                                            });
                                          },
                                          child:
                                              const Icon(Icons.arrow_downward),
                                        ),
                                      ])),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: section.ingredients.length,
                                itemBuilder: (BuildContext context, int index) {
                                  Ingredient ingredient =
                                      sortedIngredients[index];
                                  IngredientType type = widget.state
                                      .lookupIngredientType(
                                          ingredient.typeName);
                                  String formattedAmount = type.unit
                                      .format(ingredient.amountAsType(type));
                                  return Dismissible(
                                    // Each Dismissible must contain a Key. Keys allow Flutter to
                                    // uniquely identify widgets.
                                    key: Key(type.name),
                                    // Provide a function that tells the app
                                    // what to do after an item has been swiped away.
                                    onDismissed: (direction) {
                                      // Remove the item from the data source.
                                      setState(() {
                                        section.ingredients.removeAt(index);
                                      });

                                      // Then show a snackbar.
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  '${type.displayName} dismissed')));
                                    },
                                    child: ListTile(
                                      title: Text(
                                          '${type.displayName}: $formattedAmount${type.unit.separator}${type.unit.name}',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                IngredientModificationScreen(
                                              ingredient: ingredient,
                                              displayType: widget.state
                                                  .lookupIngredientType(
                                                      ingredient.typeName),
                                              sectionName: section.name,
                                            ),
                                          ),
                                        );
                                        setState(() {
                                          // Remove the ingredient if it has no amount
                                          if (ingredient.amountG == 0) {
                                            section.ingredients.remove(ingredient);
                                          }
                                        });
                                      },
                                    ),
                                    confirmDismiss:
                                        (DismissDirection direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Confirm"),
                                            content: Text(
                                                "Are you sure you wish to delete ${type.name}?"),
                                            actions: <Widget>[
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text("DELETE")),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text("CANCEL"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              // Add a button to add a new ingredient
                              ElevatedButton(
                                onPressed: () async {
                                  IngredientType? type = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          IngredientTypeSelectionScreen(
                                        state: widget.state,
                                      ),
                                    ),
                                  );
                                  if (type != null) {
                                    // Make sure the ingredient doesn't already exist
                                    if (section.ingredients.any((element) =>
                                        element.typeName.toLowerCase() ==
                                        type.name)) {
                                      // Show the modification screen
                                      Ingredient ingredient = section
                                          .ingredients
                                          .firstWhere((element) =>
                                              element.typeName.toLowerCase() ==
                                              type.name);

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                IngredientModificationScreen(
                                              ingredient: ingredient,
                                              displayType: widget.state
                                                  .lookupIngredientType(
                                                      ingredient.typeName),
                                              sectionName: section.name,
                                            ),
                                          ),
                                        ).then((value) => setState(() {
                                          // Remove the ingredient if it has no amount
                                          if (ingredient.amountG == 0) {
                                            section.ingredients.remove(ingredient);
                                          }
                                        }));
                                      }
                                      return;
                                    }
                                    Ingredient ingredient =
                                        Ingredient(type.name, 0);
                                    setState(() {
                                      // Add the new ingredient to the recipe
                                      section.ingredients.add(ingredient);
                                    });
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              IngredientModificationScreen(
                                            ingredient: ingredient,
                                            displayType: widget.state
                                                .lookupIngredientType(
                                                    ingredient.typeName),
                                            sectionName: section.name,
                                          ),
                                        ),
                                      ).then((value) => setState(() {
                                        // Remove the ingredient if it has no amount
                                        if (ingredient.amountG == 0) {
                                          section.ingredients.remove(ingredient);
                                        }
                                      }));
                                    }
                                  } else {
                                    setState(() {
                                      // Make sure if an ingredient was modified, the screen is still updated
                                    });
                                  }
                                },
                                child: const Text('Add ingredient'),
                              ),
                            ],
                          ));
                    }),
                // Add the cooking steps
                ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: widget.recipe.cookingSteps.length,
                  itemBuilder: (BuildContext context, int index) {
                    CookingStep step = widget.recipe.cookingSteps[index];
                    return Dismissible(
                      // Each Dismissible must contain a Key. Keys allow Flutter to
                      // uniquely identify widgets.
                      key: Key(step.name),
                      // Provide a function that tells the app
                      // what to do after an item has been swiped away.
                      onDismissed: (direction) {
                        // Remove the item from the data source.
                        setState(() {
                          widget.recipe.cookingSteps.removeAt(index);
                        });

                        // Then show a snackbar.
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${step.name} dismissed')));
                      },
                      child: Card(
                        elevation: 2.0,
                        child: ListTile(
                          title: Text(
                            '${step.name}: ${step.time} minutes${step.temperature != 0 ? ' at ${step.temperature} degrees' : ''}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, // This will make the Row as small as possible
                            children: <Widget>[
                              // Move up or down the list
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (index > 0) {
                                      CookingStep temp = widget.recipe.cookingSteps[index];
                                      widget.recipe.cookingSteps[index] = widget.recipe.cookingSteps[index - 1];
                                      widget.recipe.cookingSteps[index - 1] = temp;
                                    }
                                  });
                                },
                                child: const Icon(Icons.arrow_upward),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (index < widget.recipe.cookingSteps.length - 1) {
                                      CookingStep temp = widget.recipe.cookingSteps[index];
                                      widget.recipe.cookingSteps[index] = widget.recipe.cookingSteps[index + 1];
                                      widget.recipe.cookingSteps[index + 1] = temp;
                                    }
                                  });
                                },
                                child: const Icon(Icons.arrow_downward),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CookingStepModificationScreen(
                                  step: step,
                                ),
                              ),
                            );
                            setState(() {
                              // Update the screen with the new ingredient
                            });
                          },
                        ),
                      ),
                      confirmDismiss: (DismissDirection direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm"),
                              content: Text(
                                  "Are you sure you wish to delete ${step.name}?"),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("DELETE")),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("CANCEL"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ])),
          floatingActionButton: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 64.0, right: 32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Query if the user wants to add a new section or a new cooking step
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Add new'),
                            content: const Text(
                                'Would you like to add a new section or a new cooking step?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    widget.recipe.sections
                                        .add(RecipeSection('New section', []));
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Section'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    widget.recipe.cookingSteps.add(
                                        CookingStep("Cook in oven", 60, 350));
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Cooking step'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Icon(
                      Icons.add,
                      size: 64,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Save the state to shared preferences
                  widget.state.updateRecipe(widget.recipe);
                  widget.state.save();
                  // Go back to the home page
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.save,
                  size: 64,
                ),
              ),
            ],
          ),
        ));
  }
}

class RecipeScreen extends StatefulWidget {
  final Recipe recipe;
  final RecipesState state;

  const RecipeScreen({Key? key, required this.recipe, required this.state})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RecipeScreenState();
}

class IngredientModificationScreenState
    extends State<IngredientModificationScreen> {
  @override
  Widget build(BuildContext context) {
    String formattedAmount = widget.displayType.unit
        .format(widget.ingredient.amountAsType(widget.displayType));
    const TextStyle buttonStyle = TextStyle(fontSize: 48);
    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${widget.sectionName} > ${widget.displayType.displayName}')),
      body: Center(
        // Show the ingredient type name and amount, and provide buttons and a scrollbar to add or remove from the quantity in quantities of 1, 10 and 100
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.displayType.displayName + " as ",
                style: const TextStyle(fontSize: 24),
              ),
              DropdownButton<IngredientUnit>(
                value: widget.displayType.unit,
                icon: const Icon(Icons.arrow_downward),
                style: const TextStyle(fontSize: 24, color: Colors.black),
                onChanged: (IngredientUnit? newValue) {
                  setState(() {
                    widget.displayType =
                        IngredientType(widget.displayType.name, newValue!);
                  });
                },
                items: IngredientUnit.values
                    .map<DropdownMenuItem<IngredientUnit>>(
                        (IngredientUnit value) {
                  return DropdownMenuItem<IngredientUnit>(
                    value: value,
                    child: Text(value.toString().split('.').last),
                  );
                }).toList(),
              ),
            ],
          ),
          // Show the amount emphasized with a border and 5 px of padding
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 5),
            ),
            padding: const EdgeInsets.all(5),
            child: Text(
                '$formattedAmount${widget.displayType.unit.separator}${widget.displayType.unit.name}',
                style: const TextStyle(fontSize: 48)),
          ),
          // Add the scroll bar
          Slider(
            value: widget.ingredient.amountAsType(widget.displayType),
            min: 0,
            max: 1000,
            divisions: 100,
            label:
                '$formattedAmount${widget.displayType.unit.separator}${widget.displayType.unit.name}',
            onChanged: (double value) {
              setState(() {
                widget.ingredient.setAmountAsType(widget.displayType, value);
              });
            },
          ),
          // Add buttons, and set them to fill the column
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntrinsicWidth(
                // Buttons to subtract
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, -0.1);
                        });
                      },
                      child: const Text('-0.1', style: buttonStyle),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, -1);
                        });
                      },
                      child: const Text('-1', style: buttonStyle),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, -10);
                        });
                      },
                      child: const Text('-10', style: buttonStyle),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, -100);
                        });
                      },
                      child: const Text('-100', style: buttonStyle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Buttons to add
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, 0.1);
                        });
                      },
                      child: const Text('+0.1', style: buttonStyle),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, 1);
                        });
                      },
                      child: const Text('+1', style: buttonStyle),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, 10);
                        });
                      },
                      child: const Text('+10', style: buttonStyle),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.ingredient
                              .incrementAsType(widget.displayType, 100);
                        });
                      },
                      child: const Text('+100', style: buttonStyle),
                    ),
                  ],
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }
}

class IngredientModificationScreen extends StatefulWidget {
  final Ingredient ingredient;
  IngredientType displayType;
  final String sectionName;

  IngredientModificationScreen(
      {Key? key,
      required this.ingredient,
      required this.displayType,
      required this.sectionName})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => IngredientModificationScreenState();
}

class IngredientTypeSelectionScreen extends StatefulWidget {
  final RecipesState state;

  const IngredientTypeSelectionScreen({Key? key, required this.state})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => IngredientTypeSelectionScreenState();
}

class IngredientTypeSelectionScreenState
    extends State<IngredientTypeSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select ingredient type')),
      body: ListView.builder(
        itemCount: widget.state.ingredientTypes.length,
        itemBuilder: (BuildContext context, int index) {
          IngredientType type = widget.state.ingredientTypes[index];
          return ListTile(
            title: Text(type.displayName),
            onTap: () {
              Navigator.pop(context, type);
            },
            // Dialog to change the type's unit
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IngredientTypeScreen(
                      type: type, index: index, state: widget.state),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () async {
              // Add a new ingredient type
              IngredientType? type = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      IngredientTypeCreationScreen(state: widget.state),
                ),
              );
              if (type != null) {
                setState(() {
                  // Check if the ingredient type already exists
                  if (widget.state.ingredientTypes.any((element) =>
                      element.name.toLowerCase() == type.name.toLowerCase())) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'An ingredient type with that name already exists')));
                    return;
                  }
                  widget.state.ingredientTypes.add(type);
                });
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class CookingStepModificationScreen extends StatefulWidget {
  final CookingStep step;

  const CookingStepModificationScreen({Key? key, required this.step})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => CookingStepModificationScreenState();
}

class CookingStepModificationScreenState
    extends State<CookingStepModificationScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modify cooking step')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text field to enter the step's description
                TextFormField(
                  initialValue: widget.step.name,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    setState(() {
                      widget.step.name = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Text field to enter the step's time
                TextFormField(
                  initialValue: widget.step.time.toString(),
                  // Confirm the value is an integer
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp('\\d|\\.')),
                  ], // Only numbers can be entered
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a time';
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    setState(() {
                      widget.step.time = double.parse(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Text field to enter the step's temperature
                TextFormField(
                  initialValue: widget.step.temperature.toString(),
                  // Confirm the value is an integer
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ], // Only numbers can be entered
                  decoration: const InputDecoration(
                    labelText: 'Temperature',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.parse(value) < 0) {
                      return 'Please enter a temperature';
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    setState(() {
                      widget.step.temperature = int.parse(value);
                    });
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
