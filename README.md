# Medicine Reminder

![Flutter CI](https://github.com/syedasumayya/medicine_reminder/actions/workflows/flutter-ci.yml/badge.svg)

A Flutter app that helps people remember their medicines, track whether they took them, and share a weekly report with family.

**Live demo:** https://syedasumayya.github.io/medicine_reminder/

## Features

- Add, edit and delete medicines with a dose and a time
- Daily schedule sorted by time, with Taken / Skip buttons, Undo and a progress bar
- Missed-dose detection (more than 1 hour late)
- In-app reminder pop-up when a dose is due
- Prescription parser: reads text such as `Tab Panadol 500mg 1+0+1 x 5 days` or `Cap Amoxil TDS` and turns it into medicines, with a review screen before anything is added
- Weekly adherence report (percentage, day-by-day list) that can be copied or shared on WhatsApp
- Data saved on the device, light and dark mode

## Tech

- Flutter and Dart
- `shared_preferences` for local storage
- `url_launcher` for WhatsApp sharing
- GitHub Actions: CI (analyze, test, build) and automatic deployment to GitHub Pages

## Run it locally

```
flutter pub get
flutter run -d chrome
```

## Run the tests

```
flutter analyze
flutter test
```

## Project structure

```
lib/
  models/      Medicine and DoseLog classes
  screens/     Home, Add/Edit, Scan Prescription, Weekly Report
  services/    Storage, prescription parser, report builder
  utils/       Date and time helpers
test/          Unit and widget tests
```

## Roadmap

- Real notifications that ring when the app is closed (Android)
- Camera scanning of prescriptions with ML Kit OCR (Android)
- Live sharing with family members through an online database

## Disclaimer

This app is a reminder tool, not a substitute for medical advice. Always follow your doctor's instructions and check scanned prescriptions by hand.