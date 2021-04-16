// This file has helper functions to manage the app better

// This extends the string type to add a method named capitalize
//   that returns the string with the first letter capitalized
extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${this.substring(1)}";
    }
}