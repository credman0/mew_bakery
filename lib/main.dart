import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/recipe_screen.dart';
import 'types.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? stateString = prefs.getString(RecipesState.getPrefsString());
  if (stateString == null) {
    stateString = json.encode(RecipesState.defaultState());
    prefs.setString(RecipesState.getPrefsString(), stateString);
  }
  Map<String, dynamic> stateJson = json.decode(stateString);
  RecipesState state = RecipesState.fromJson(stateJson);
  runApp(MainApp(state: state));
}

class MainApp extends StatelessWidget {
  final RecipesState state;

  const MainApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(state: state),
    );
  }
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: Center(
        // Show list of recipes
        child: ListView.builder(
          itemCount: widget.state.recipes.length,
          itemBuilder: (BuildContext context, int index) {
            Recipe recipe = widget.state.recipes[index];
            return Material(
                elevation: 4.0,
                child: ListTile(
                  title: Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeScreen(
                          recipe: recipe.deepCopy(),
                          state: widget.state,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  // Show dialog to rename or delete recipe
                  onLongPress: () => {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Recipe Options'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                TextButton(
                                  child: const Text('Rename'),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Rename Recipe'),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                TextField(
                                                  decoration: const InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    labelText: 'Name',
                                                  ),
                                                  onChanged: (String value) {
                                                    setState(() {
                                                      recipe.name = value;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Save'),
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Recipe'),
                                          content: const SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                Text(
                                                    'Are you sure you want to delete this recipe?'),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Delete'),
                                              onPressed: () async {
                                                widget.state.recipes
                                                    .remove(recipe);
                                                Navigator.of(context).pop();
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    )
                  },
                ));
          },
        ),
      ),
      // Add button to create new recipe
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () async {
              Recipe recipe = Recipe("New Recipe", [], []);
              widget.state.recipes.add(recipe);
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final RecipesState state;

  const HomePage({Key? key, required this.state}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}
