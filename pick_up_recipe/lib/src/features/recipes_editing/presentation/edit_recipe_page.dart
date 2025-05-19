import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes_editing/application/edit_recipe_state.dart';
import 'package:pick_up_recipe/src/features/recipes_editing/data_sources/recipe_editing_service.dart';
import 'package:pick_up_recipe/src/features/recipes/data_sources/remote/recipe_service.dart';

@RoutePage()
class EditRecipePage extends ConsumerStatefulWidget {
  final RecipeData recipe;

  const EditRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  ConsumerState<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends ConsumerState<EditRecipePage> {
  void _saveRecipe() async {
    final recipe = ref.read(editRecipeProvider);

    final recipeService = RecipeService();
    final recipeEditingService = RecipeEditingService(recipeService);

    try {
      await recipeEditingService.updateRecipe(recipe);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = ref.watch(editRecipeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: recipe.steps.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          ref.read(editRecipeProvider.notifier).reorderSteps(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final step = recipe.steps[index];
          return ListTile(
            key: ValueKey(step.id),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step ${step.seqNum}: ${step.instruction}'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Time (s)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final updatedStep = step.copyWith(
                            time: int.tryParse(value) ?? step.time,
                          );
                          ref
                              .read(editRecipeProvider.notifier)
                              .updateStep(index, updatedStep);
                        },
                        controller: TextEditingController(
                          text: step.time.toString(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        decoration:
                            const InputDecoration(labelText: 'Water (ml)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final updatedStep = step.copyWith(
                            water: int.tryParse(value) ?? step.water,
                          );
                          ref
                              .read(editRecipeProvider.notifier)
                              .updateStep(index, updatedStep);
                        },
                        controller: TextEditingController(
                          text: step.water.toString(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(editRecipeProvider.notifier).deleteStep(index);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}