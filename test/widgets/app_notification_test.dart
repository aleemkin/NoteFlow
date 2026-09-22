import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/core/notifications/app_notification.dart';

void main() {
  Widget buildTestHost({required void Function(BuildContext) onTrigger}) {
    return MaterialApp(
      scaffoldMessengerKey: AppNotification.scaffoldMessengerKey,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onTrigger(context),
              child: const Text('Trigger Notification'),
            ),
          ),
        ),
      ),
    );
  }

  group('AppNotification Desktop Notification Tests', () {
    tearDown(() {
      AppNotification.dismiss();
    });

    testWidgets(
      'renders success notification in top-right corner with title and message',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestHost(
            onTrigger: (context) {
              AppNotification.showSuccess(
                context,
                'Drawing changes and snapshot saved.',
                title: 'Drawing Saved',
              );
            },
          ),
        );

        // Trigger notification
        await tester.tap(find.text('Trigger Notification'));
        await tester.pump();
        await tester.pump(
          const Duration(milliseconds: 250),
        ); // Animation settles

        // Verify card content
        expect(find.text('Drawing Saved'), findsOneWidget);
        expect(
          find.text('Drawing changes and snapshot saved.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        // Verify positioned in top right area
        final cardTopLeft = tester.getTopLeft(find.text('Drawing Saved'));
        expect(cardTopLeft.dy, lessThan(100)); // Near top
        expect(cardTopLeft.dx, greaterThan(200)); // Near right
      },
    );

    testWidgets('renders error notification with error icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          onTrigger: (context) {
            AppNotification.showError(
              context,
              'Failed to write note to disk.',
              title: 'Creation Failed',
            );
          },
        ),
      );

      await tester.tap(find.text('Trigger Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Creation Failed'), findsOneWidget);
      expect(find.text('Failed to write note to disk.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('dismisses notification when close button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          onTrigger: (context) {
            AppNotification.showInfo(
              context,
              'Reference copied to clipboard.',
              title: 'Reference Copied',
            );
          },
        ),
      );

      await tester.tap(find.text('Trigger Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Reference Copied'), findsOneWidget);

      // Tap close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Reference Copied'), findsNothing);
    });

    testWidgets('auto-dismisses notification after duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          onTrigger: (context) {
            AppNotification.showSuccess(
              context,
              'Changes saved.',
              duration: const Duration(milliseconds: 500),
            );
          },
        ),
      );

      await tester.tap(find.text('Trigger Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Changes saved.'), findsOneWidget);

      // Advance clock past auto-dismiss duration (500ms) and reverse fade animation (220ms)
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Changes saved.'), findsNothing);
    });

    testWidgets(
      'showing new notification replaces previous notification cleanly',
      (WidgetTester tester) async {
        int count = 0;
        await tester.pumpWidget(
          buildTestHost(
            onTrigger: (context) {
              count++;
              AppNotification.showInfo(
                context,
                'Message count: $count',
                title: 'Counter $count',
              );
            },
          ),
        );

        // Trigger first
        await tester.tap(find.text('Trigger Notification'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Counter 1'), findsOneWidget);

        // Trigger second
        await tester.tap(find.text('Trigger Notification'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Counter 1'), findsNothing);
        expect(find.text('Counter 2'), findsOneWidget);
      },
    );
  });

  group('AppNotification Android & Mobile SnackBar Tests', () {
    setUp(() {
      AppPlatform.overrideIsMobileForTest = true;
    });

    tearDown(() {
      AppPlatform.overrideIsMobileForTest = null;
      AppNotification.dismiss();
    });

    testWidgets(
      'renders floating SnackBar with icon, title, and message on mobile',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestHost(
            onTrigger: (context) {
              AppNotification.showSuccess(
                context,
                'Note saved successfully.',
                title: 'Saved',
              );
            },
          ),
        );

        await tester.tap(find.text('Trigger Notification'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // SnackBar is shown
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Note saved successfully.'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        // Should NOT render desktop overlay
        expect(
          find.byKey(const Key('notification_overlay_card')),
          findsNothing,
        );
      },
    );

    testWidgets('renders error SnackBar with error icon on mobile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          onTrigger: (context) {
            AppNotification.showError(
              context,
              'Could not open vault.',
              title: 'Error',
            );
          },
        ),
      );

      await tester.tap(find.text('Trigger Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Could not open vault.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('dismisses SnackBar via dismiss()', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          onTrigger: (context) {
            AppNotification.showInfo(context, 'Info message.', title: 'Notice');
          },
        ),
      );

      await tester.tap(find.text('Trigger Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(SnackBar), findsOneWidget);

      AppNotification.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
