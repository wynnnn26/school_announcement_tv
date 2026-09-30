# School Announcement TV Display (CSE101 Final Project)

Digital school bulletin board for a TV / large screen. Local data only: a `List<Announcement>` in `lib/data/sample_data.dart`. No database, no backend, `setState()` only.

## Run
```
flutter create --platforms=windows,web,android,ios .   # generates platform folders (keeps lib/, assets/)
flutter pub get
flutter run -d windows        # or: -d chrome
flutter test
```

## Screens
- **Home** – the TV display (wide: 3 columns, narrow: stacked). AppBar icons open the other screens.
- **Form** – add / edit (type, title, description, date, time, location, category, featured).
- **Summary** – totals + cards with View / Edit / Delete.
