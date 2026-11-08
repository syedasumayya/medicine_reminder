import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/models/dose_log.dart';
import 'package:medicine_reminder/models/medicine.dart';
import 'package:medicine_reminder/widgets/dialogs.dart';

const Medicine _panadol = Medicine(
  id: 1,
  name: 'Panadol',
  dose: '1 tablet',
  hour: 8,
  minute: 0,
);

/// A tiny app with one button that runs [onPressed] with a usable context.
Widget _appWithButton(Future<void> Function(BuildContext context) onPressed) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => onPressed(context),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Reminder dialog shows the medicine and returns Taken',
      (WidgetTester tester) async {
    DoseStatus? answer;
    await tester.pumpWidget(
      _appWithButton((context) async {
        answer = await showReminderDialog(context, _panadol);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Time for your medicine!'), findsOneWidget);
    expect(find.textContaining('Panadol'), findsOneWidget);

    await tester.tap(find.text('Taken'));
    await tester.pumpAndSettle();

    expect(answer, DoseStatus.taken);
  });

  testWidgets('Reminder dialog returns Skipped for Skip',
      (WidgetTester tester) async {
    DoseStatus? answer;
    await tester.pumpWidget(
      _appWithButton((context) async {
        answer = await showReminderDialog(context, _panadol);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(answer, DoseStatus.skipped);
  });

  testWidgets('Reminder dialog returns nothing for Later',
      (WidgetTester tester) async {
    DoseStatus? answer = DoseStatus.taken; // start with something else
    await tester.pumpWidget(
      _appWithButton((context) async {
        answer = await showReminderDialog(context, _panadol);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(answer, isNull);
  });

  testWidgets('Delete dialog returns true for Delete',
      (WidgetTester tester) async {
    bool? answer;
    await tester.pumpWidget(
      _appWithButton((context) async {
        answer = await showDeleteMedicineDialog(context);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Delete medicine?'), findsOneWidget);
    expect(find.text('This will also remove its history.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(answer, isTrue);
  });

  testWidgets('Delete dialog returns false for Cancel',
      (WidgetTester tester) async {
    bool? answer;
    await tester.pumpWidget(
      _appWithButton((context) async {
        answer = await showDeleteMedicineDialog(context);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });
}
