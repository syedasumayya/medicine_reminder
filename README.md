# My Medicine

![Flutter CI](https://github.com/syedasumayya/medicine_reminder/actions/workflows/flutter-ci.yml/badge.svg)

**Now you never forget your medicine.**

A Flutter app that turns a typed prescription into a daily medicine schedule, reminds you on your phone, tracks every dose, and shares a weekly report with family.

**Live app:** https://syedasumayya.github.io/medicine_reminder/

## Features

- **Daily schedule:** medicines grouped into Morning, Afternoon and Evening, with a "Today's progress" bar
- **Track doses:** Mark taken, Skip and Undo, plus a "Missed" mark when a dose is more than 1 hour late
- **Pill pictures:** nine pill icons, chosen automatically (capsule, tablet, vitamin) or picked by you
- **Add, edit and delete** medicines with a dose and a time
- **Import a prescription:** upload a typed PDF or paste the text. The app finds the medicines (for example `Tab Panadol 500mg 1+0+1 x 5 days` or `Cap Amoxil TDS`), and a review screen lets you untick anything before it is added. The PDF is read on your own device.
- **Phone reminders:** notifications at every dose time, even when the app is closed (through the free ntfy app). A reminder is cancelled when you mark the dose Taken or Skipped, and medicine names can be hidden for privacy.
- **In-app reminder pop-up** while the app is open
- **Weekly report:** adherence percentage, ring chart and a day-by-day list. Copy it or share it on WhatsApp.
- Light and dark mode, installable on a phone like a normal app (PWA)

## How to use it on a phone

1. Open the live app link in Chrome (Android) or Safari (iPhone) and choose **Install app** or **Add to Home Screen**.
2. Add medicines with **+**, or use **Import** to read a prescription PDF.
3. Open **Reminders**, install the free ntfy app, subscribe to your private topic, turn reminders on, and press **Send test notification**.
4. Open the app at least once every 2 days. It refreshes the reminders automatically.

## Tech

- Flutter and Dart (Material 3)
- `shared_preferences` for saving data on the device
- `file_picker` and `syncfusion_flutter_pdf` for reading PDF text (Syncfusion Community License)
- `http` for sending reminders to ntfy.sh, `url_launcher` for WhatsApp
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
  models/     Medicine and DoseLog
  screens/    Home, Add/Edit, Import, Review, Report, Reminders, About
  services/   Storage, prescription parser, PDF reader, reminders, report builder
  theme/      Colours and themes
  utils/      Date and time helpers
  widgets/    Pill pictures, logo, pop-up dialogs
test/         Unit and widget tests
```

## Good to know

- Medicines are saved in the browser of the device you use. Clearing the browser data removes them.
- Only PDFs that contain real text can be read. A photo or a scan saved as PDF cannot (paste the text instead).
- Reminders are scheduled 3 days ahead and travel through the free ntfy.sh service. Keep your topic name private.

## Roadmap

- Backup and restore of your data
- A native Android app with built-in notifications
- Camera scanning of paper prescriptions (OCR)
- Live sharing with family members

## Disclaimer

This app is a reminder tool, not a substitute for medical advice. Always follow your doctor's instructions and check imported prescriptions by hand.
