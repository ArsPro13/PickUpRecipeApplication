import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_data_model.dart';
import 'package:pick_up_recipe/src/features/recipes/domain/models/recipe_step_model.dart';

class EditRecipeState extends StateNotifier<RecipeData> {
  EditRecipeState(RecipeData recipe) : super(recipe);

  void updateDevice(String device) {
    //state = state.copyWith(device: device);
  }

  void updateTemperature(int temperature) {
    //state = state.copyWith(temperature: temperature);
  }

  void updateStep(int index, RecipeStep updatedStep) {
    final updatedSteps = [...state.steps];
    updatedSteps[index] = updatedStep;
    state = state.copyWith(steps: updatedSteps);
  }

  void deleteStep(int index) {
    final updatedSteps = [...state.steps]..removeAt(index);
    state = state.copyWith(steps: updatedSteps);
  }

  void reorderSteps(int oldIndex, int newIndex) {
    final updatedSteps = [...state.steps];
    final step = updatedSteps.removeAt(oldIndex);
    updatedSteps.insert(newIndex, step);

    // Обновляем seqNum для всех шагов
    for (int i = 0; i < updatedSteps.length; i++) {
      updatedSteps[i] = updatedSteps[i].copyWith(seqNum: i + 1);
    }

    state = state.copyWith(steps: updatedSteps);
  }

  // Add more update methods as needed
}

final editRecipeProvider =
    StateNotifierProvider<EditRecipeState, RecipeData>((ref) {
  throw UnimplementedError(); // Инициализируйте с реальным рецептом
});