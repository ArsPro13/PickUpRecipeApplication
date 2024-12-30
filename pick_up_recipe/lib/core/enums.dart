// Методы заваривания
enum BrewingMethods {
  harioV60,
  all,
}

extension BrewingMethodsTitleExtension on BrewingMethods {
  String getTitle() {
    switch (this) {
      case BrewingMethods.harioV60:
        return "Hario V60";
      case BrewingMethods.all:
        return "Choose brewing method";
    }
  }
}

extension BrewingMethodsBackendNameExtension on BrewingMethods {
  String getName() {
    switch (this) {
      case BrewingMethods.harioV60:
        return "hario_v60";
      case BrewingMethods.all:
        return "undefined";
    }
  }
}

extension BrewingMethodsFromString on String {
  BrewingMethods? toBrewingMethod() {
    switch (toLowerCase()) {
      case "hario v60":
        return BrewingMethods.harioV60;
      case "choose brewing method":
        return BrewingMethods.all;
      default:
        return null;
    }
  }
}
