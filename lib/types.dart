import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fraction/fraction.dart';

const String _recipeStateKey = 'recipeState';
const String dataVersion = '1.0.0';

enum IngredientUnit {
  g,
  kg,
  ml,
  l,
  piece,
  cups,
  tsp,
  tbsp,
}

/// Possible denominators for fractions, 3 and 8
const List<int> fractionDenominators = [3, 8];

Fraction roundFraction(Fraction fraction, {int roundedDenominator = 2}) {
  int roundedNumerator = (fraction.toDouble() * roundedDenominator).round();
  return Fraction(roundedNumerator, roundedDenominator);
}

String formatFraction(double value) {
  Fraction fraction = Fraction.fromDouble(value, precision: 0.01);
  fraction = fraction.reduce();
  if (fraction.isWhole) {
    return fraction.numerator.toString();
  } else {
    /// Try the possible denominators and return the one that is closest to the original value
    Fraction bestFraction = fraction;
    double bestDifference = double.infinity;
    for (int denominator in fractionDenominators) {
      Fraction rounded = roundFraction(fraction, roundedDenominator: denominator);
      double difference = (fraction.toDouble() - rounded.toDouble()).abs();
      if (difference < bestDifference) {
        bestFraction = rounded;
        bestDifference = difference;
      }
    }
    bestFraction = bestFraction.reduce();
    if (bestFraction.numerator == 0) {
      return '0';
    } else if (bestFraction.isProper) {
      return bestFraction.toStringAsGlyph();
    } else {
      return MixedFraction.fromFraction(bestFraction).toStringAsGlyph();
    }
  }
}

String formatNonfraction(double value){
  if (value == value.roundToDouble()) {
    return value.round().toString();
  } else {
    return value.toStringAsFixed(1);
  }
}

extension UnitExtension on IngredientUnit {
  String get name {
    switch (this) {
      case IngredientUnit.g:
        return 'g';
      case IngredientUnit.kg:
        return 'kg';
      case IngredientUnit.ml:
        return 'ml';
      case IngredientUnit.l:
        return 'l';
      case IngredientUnit.cups:
        return 'cups';
      case IngredientUnit.piece:
        return 'piece';
      case IngredientUnit.tsp:
        return 'tsp';
      case IngredientUnit.tbsp:
        return 'tbsp';
    }
  }

  bool formattedAsFraction() {
    switch (this) {
      case IngredientUnit.g:
        return false;
      case IngredientUnit.kg:
        return false;
      case IngredientUnit.ml:
        return false;
      case IngredientUnit.l:
        return false;
      case IngredientUnit.cups:
        return true;
      case IngredientUnit.piece:
        return false;
      case IngredientUnit.tsp:
        return true;
      case IngredientUnit.tbsp:
        return true;
    }
  }

  String format(double value) {
    if (formattedAsFraction()) {
      return formatFraction(value);
    } else {
      return formatNonfraction(value);
    }
  }

  /// Returns a space if the unit needs a space for display
  String get separator {
    switch (this) {
      case IngredientUnit.g:
        return '';
      case IngredientUnit.kg:
        return '';
      case IngredientUnit.ml:
        return '';
      case IngredientUnit.l:
        return '';
      case IngredientUnit.piece:
        return ' ';
      case IngredientUnit.cups:
        return ' ';
      case IngredientUnit.tsp:
        return ' ';
      case IngredientUnit.tbsp:
        return ' ';
    }
  }
}

class IngredientType {
  final String name;
  final IngredientUnit unit;
  final double gPerMl;
  static const double mlPerCup = 236.588;
  static const double mlPerTsp = 4.92892;
  static const double mlPerTbsp = 14.7868;

  IngredientType(this.name, this.unit, {double? gPerMl}) : 
    gPerMl = gPerMl ?? defaultGPerMl(name);

  /// Returns the name of the ingredient type properly capitalized
  get displayName => name[0].toUpperCase() + name.substring(1);

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit.index,
        'g_per_ml': gPerMl,
        'data_version': dataVersion,
      };

  static IngredientType fromJson(Map<String, dynamic> json) {
    if (json['g_per_ml'] == null) {
      return IngredientType(json['name'], IngredientUnit.values[json['unit']]);
    } else {
      return IngredientType(json['name'], IngredientUnit.values[json['unit']],
          gPerMl: json['g_per_ml']);
    }
  }

  /// Returns the amount of the ingredient in grams
  double toGrams(double amount) {
    switch (unit) {
      case IngredientUnit.g:
        return amount;
      case IngredientUnit.kg:
        return amount * 1000;
      case IngredientUnit.ml:
        return amount * gPerMl;
      case IngredientUnit.l:
        return amount * gPerMl * 1000;
      case IngredientUnit.cups:
        return amount * mlPerCup * gPerMl;
      case IngredientUnit.piece:
        return amount;
      case IngredientUnit.tsp:
        return amount * mlPerTsp * gPerMl;
      case IngredientUnit.tbsp:
        return amount * mlPerTbsp * gPerMl;
    }
  }

  /// Returns the amount of the ingredient in the given unit
  double fromGrams(double amount, IngredientUnit toUnit) {
    switch (toUnit) {
      case IngredientUnit.g:
        return amount;
      case IngredientUnit.kg:
        return amount / 1000;
      case IngredientUnit.ml:
        return amount / gPerMl;
      case IngredientUnit.l:
        return amount / gPerMl / 1000;
      case IngredientUnit.cups:
        return amount / mlPerCup / gPerMl;
      case IngredientUnit.piece:
        return amount;
      case IngredientUnit.tsp:
        return amount / mlPerTsp / gPerMl;
      case IngredientUnit.tbsp:
        return amount / mlPerTbsp / gPerMl;
    }
  }

  /// Return reasonable defaults for the gPerMl value, based on the ingredient name
  /// If the name is not recognized, the default value is 1
  static double defaultGPerMl(String name) {
    switch (name.toLowerCase()) {
      case 'water':
        return 1;
      case 'milk':
        return 1.03;
      case 'flour':
        return 0.55;
      case 'sugar':
        return 0.85;
      case 'butter':
        return 0.95;
      case 'egg':
        return 1.03;
      case 'yeast':
        return 0.6;
      case 'baking powder':
        return 0.9;
      case 'baking soda':
        return 0.7;
      case 'salt':
        return 1.2;
      default:
        return 1;
    }
  }
}

class Ingredient {
  final String typeName;
  double amountG;

  Ingredient(this.typeName, this.amountG);

  Map<String, dynamic> toJson() => {
        'type': typeName,
        'amount_g': amountG,
        'data_version': dataVersion,
      };
    
  double amountAsType(IngredientType type) => type.fromGrams(amountG, type.unit);
  double setAmountAsType(IngredientType type, double amount) => amountG = type.toGrams(amount);
  void incrementAsType(IngredientType type, double increment) {
    amountG += type.toGrams(increment);
    if (amountG < 0) {
      amountG = 0;
    }
  }

  static Ingredient fromJson(Map<String, dynamic> json, List <IngredientType> ingredientTypes) {
    String typeName = json['type'];
    double amountG = 0;
    if (json.containsKey('amount_g')) {
      amountG = json['amount_g'];
    } else if (json.containsKey('amount')) {
      IngredientType type = ingredientTypes.firstWhere((element) => element.name == typeName);
      amountG = type.toGrams(json['amount']);
    }
    return Ingredient(typeName, amountG);
  }
}

class RecipeSection {
  String name;
  final List<Ingredient> ingredients;

  RecipeSection(this.name, this.ingredients);

  Map<String, dynamic> toJson() => {
        'name': name,
        'ingredients':
            ingredients.map((ingredient) => ingredient.toJson()).toList(),
        'data_version': dataVersion,
      };

  static RecipeSection fromJson(Map<String, dynamic> json, List<IngredientType> ingredientTypes) {
    return RecipeSection(
      json['name'],
      List<Ingredient>.from(json['ingredients']
          .map((ingredient) => Ingredient.fromJson(ingredient, ingredientTypes))),
    );
  }
}

class CookingStep {
  String name;
  double time;
  int? temperature; // null if not needed

  CookingStep(this.name, this.time, this.temperature);

  Map<String, dynamic> toJson() => {
        'name': name,
        'time': time,
        'temperature': temperature,
        'data_version': dataVersion,
      };

  static CookingStep fromJson(Map<String, dynamic> json) {
    return CookingStep(json['name'], json['time'], json['temperature']);
  }
}

class Recipe {
  String name;
  final List<RecipeSection> sections;
  final List<CookingStep> cookingSteps;

  Recipe(this.name, this.sections, this.cookingSteps);

  Map<String, dynamic> toJson() => {
        'name': name,
        'sections': sections.map((section) => section.toJson()).toList(),
        'cookingSteps':
            cookingSteps.map((step) => step.toJson()).toList(),
      };

  static Recipe fromJson(Map<String, dynamic> json, List<IngredientType> ingredientTypes) {
    return Recipe(
      json['name'],
      List<RecipeSection>.from(
          json['sections'].map((section) => RecipeSection.fromJson(section, ingredientTypes))),
      List<CookingStep>.from(
          json['cookingSteps'].map((step) => CookingStep.fromJson(step))),
    );
  }

  Recipe deepCopy() {
    return Recipe(
      name,
      List<RecipeSection>.from(
          sections.map((section) => RecipeSection(section.name, List<Ingredient>.from(section.ingredients.map((ingredient) => Ingredient(ingredient.typeName, ingredient.amountG)))))),
      List<CookingStep>.from(
          cookingSteps.map((step) => CookingStep(step.name, step.time, step.temperature))),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is Recipe) {
      for (int i = 0; i < sections.length; i++) {
        if (sections[i].name != other.sections[i].name) {
          return false;
        }
        for (int j = 0; j < sections[i].ingredients.length; j++) {
          if (sections[i].ingredients[j].typeName !=
              other.sections[i].ingredients[j].typeName) {
            return false;
          }
          if (sections[i].ingredients[j].amountG !=
              other.sections[i].ingredients[j].amountG) {
            return false;
          }
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => name.hashCode;
}

class RecipesState with ChangeNotifier {
  final List<Recipe> _recipes;
  final List<IngredientType> _ingredientTypes;

  RecipesState(this._recipes, this._ingredientTypes);

  Map<String, dynamic> toJson() => {
        'recipes': _recipes.map((recipe) => recipe.toJson()).toList(),
        'ingredientTypes': _ingredientTypes
            .map((ingredientType) => ingredientType.toJson())
            .toList(),
      };

  static RecipesState fromJson(Map<String, dynamic> json) {
    List<IngredientType> ingredientTypes = List<IngredientType>.from(
      json['ingredientTypes'].map((ingredientType) => IngredientType.fromJson(ingredientType))
    );
    return RecipesState(
      List<Recipe>.from(
        json['recipes'].map((recipe) => Recipe.fromJson(recipe, ingredientTypes))
      ),
      ingredientTypes
    );
  }

  static RecipesState defaultState() {
    List<IngredientType> types = [];
    types.add( IngredientType("flour", IngredientUnit.g));
    types.add( IngredientType("baking powder", IngredientUnit.g));
    types.add( IngredientType("baking soda", IngredientUnit.g));
    types.add( IngredientType("salt", IngredientUnit.g));
    types.add( IngredientType("sugar", IngredientUnit.g));
    types.add( IngredientType("egg", IngredientUnit.piece));
    types.add( IngredientType("milk", IngredientUnit.ml));
    types.add( IngredientType("water", IngredientUnit.ml));
    types.add( IngredientType("butter", IngredientUnit.cups));
    types.add( IngredientType("yeast", IngredientUnit.g));
    types.add( IngredientType("coffee", IngredientUnit.ml));
    Recipe pretzelRecipe = Recipe(
      'Pretzels',
      [
        RecipeSection(
          'Dough',
          [
            Ingredient('flour', 480),
            Ingredient('yeast', 7),
            Ingredient('salt', 6),
            Ingredient('sugar', 13),
            Ingredient('butter', 28),
            Ingredient('water', 360),
          ],
        ),
        RecipeSection(
          'Baking soda bath',
          [
            Ingredient('baking soda', 120),
            Ingredient('water', 2160),
          ],
        ),
      ],
      [
        CookingStep('Mix dough', 3, 0),
        CookingStep('Knead dough', 10, 0),
        CookingStep('Boil pretzels', 0.5, 0),
        CookingStep('Bake pretzels', 15, 400),
      ],
    );
    Recipe breadRecipe = Recipe(
      'Bread',
      [
        RecipeSection(
          'Dough',
          [
            Ingredient('flour', 325),
            Ingredient('yeast', 9),
            Ingredient('salt', 5),
            Ingredient('sugar', 10),
            Ingredient('water', 230),
            Ingredient('egg', 2)
          ],
        ),
      ],
      [
        CookingStep('Bake bread', 15, 350),
      ],
    );

    Recipe bagelRecipe = Recipe(
      'Bagels',
      [
        RecipeSection(
          'Dough',
          [
            Ingredient('flour', 520),
            Ingredient('yeast', 7),
            Ingredient('salt', 12),
            Ingredient('sugar', 14),
            Ingredient('water', 360),
          ],
        ),
        RecipeSection(
          'Baking soda bath',
          [
            Ingredient('baking soda', 120),
            Ingredient('water', 2160),
          ],
        ),
      ],
      [
        CookingStep('Mix dough', 3, 0),
        CookingStep('Knead dough', 10, 0),
        CookingStep('Boil bagels', 0.5, 0),
        CookingStep('Bake bagels', 15, 400),
      ],
    );
    Recipe coffeeBread = Recipe(
      'Coffee Bread',
      [
        RecipeSection(
          'Dough',
          [
            Ingredient('flour', 300),
            Ingredient('baking powder', 9),
            Ingredient('baking soda', 2),
            Ingredient('salt', 1),
            Ingredient('sugar', 200),
            Ingredient('egg', 2),
            Ingredient('coffee', 236),
            Ingredient('butter', 57)
          ],
        ),
      ],
      [
        CookingStep('Bake', 48, 350),
      ],
    );
    RecipesState state = RecipesState([pretzelRecipe, breadRecipe, bagelRecipe, coffeeBread], types);
    return state;
  }

  List<Recipe> get recipes => _recipes;

  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
    notifyListeners();
  }

  void removeRecipe(Recipe recipe) {
    _recipes.remove(recipe);
    notifyListeners();
  }

  void updateRecipe(Recipe recipe) {
    _recipes[_recipes.indexWhere((element) => element.name == recipe.name)] =
        recipe;
    notifyListeners();
  }

  bool isRecipeChanged(Recipe recipe) {
    int index = _recipes.indexWhere((element) => element.name == recipe.name);
    if (index == -1) {
      return true;
    }
    return _recipes[index] != recipe;
  }

  List<IngredientType> get ingredientTypes => _ingredientTypes;

  void addIngredientType(IngredientType ingredientType) {
    _ingredientTypes.add(ingredientType);
    notifyListeners();
  }

  void removeIngredientType(IngredientType ingredientType) {
    _ingredientTypes.remove(ingredientType);
    notifyListeners();
  }

  /// Returns the ingredient type with the given name, ignoring case
  IngredientType lookupIngredientType(String name) {
    return _ingredientTypes.firstWhere(
      (ingredientType) =>
          ingredientType.name.toLowerCase() == name.toLowerCase(),
    );
  }

  static String getPrefsString() {
    return _recipeStateKey;
  }

  /// Saves the current state to disk
  void save() async {
    String stateString = json.encode(toJson());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(_recipeStateKey, stateString);
  }
}
