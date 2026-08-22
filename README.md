# mobprogact

## Lab Activity 2: Discussion

This activity uses a simple layered design. The `Product` model converts the JSON response into typed Dart objects, so screens do not need to read raw maps. `ProductService` owns the HTTP request and response validation. `HomeScreen` calls the service through a `FutureBuilder`, then renders loading, error, empty, and product states. Tapping a product passes the model to `ProductScreen`, which displays its details.

The new design follows a lightweight separation-of-concerns pattern: models represent data, services handle API access, providers hold shared application state, and screens/widgets handle presentation. `ThemeProvider` extends `ChangeNotifier`; `Provider` supplies it above `MaterialApp`, allowing the settings screen to update light and dark themes across the application. Search is kept local to the loaded list, which avoids extra API calls while the user types.

Implemented enhancements:

- Search bar above the product list.
- Details page opened by selecting a product card.
- Settings page containing the dark/light mode switch.
