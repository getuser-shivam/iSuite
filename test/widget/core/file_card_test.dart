import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iSuite/presentation/widgets/file_card.dart';
import 'package:iSuite/core/advanced_ui_service.dart';

void main() {
  group('FileCard Widget Tests', () {
    late AdvancedUIService uiService;

    setUp(() async {
      uiService = AdvancedUIService.instance;
      await uiService.initialize();
    });

    testWidgets('FileCard displays file information correctly',
        (WidgetTester tester) async {
      const fileName = 'test_document.pdf';
      const fileSize = '2.5 MB';
      const lastModified = '2024-01-15 10:30';

      // Build the FileCard widget
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: fileName,
              fileSize: fileSize,
              lastModified: lastModified,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify that the file name is displayed
      expect(find.text(fileName), findsOneWidget);

      // Verify that the file size is displayed
      expect(find.text(fileSize), findsOneWidget);

      // Verify that the last modified date is displayed
      expect(find.text(lastModified), findsOneWidget);

      // Verify that an icon is present (file icon)
      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
    });

    testWidgets('FileCard shows correct icon for different file types',
        (WidgetTester tester) async {
      const testCases = [
        ('document.pdf', Icons.picture_as_pdf),
        ('image.jpg', Icons.image),
        ('video.mp4', Icons.video_file),
        ('audio.mp3', Icons.audio_file),
        ('folder', Icons.folder),
        ('unknown.xyz', Icons.insert_drive_file),
      ];

      for (final testCase in testCases) {
        final fileName = testCase.$1;
        final expectedIcon = testCase.$2;

        await tester.pumpWidget(
          MaterialApp(
            theme: uiService.getThemeData(brightness: Brightness.light),
            home: Scaffold(
              body: FileCard(
                fileName: fileName,
                fileSize: '1 KB',
                lastModified: '2024-01-15',
                onTap: () {},
              ),
            ),
          ),
        );

        // Verify the correct icon is displayed
        expect(find.byIcon(expectedIcon), findsOneWidget);

        // Clean up for next test
        await tester.pumpAndSettle();
      }
    });

    testWidgets('FileCard handles tap gestures correctly',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'test_file.txt',
              fileSize: '100 B',
              lastModified: '2024-01-15',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the FileCard
      await tester.tap(find.byType(FileCard));
      await tester.pumpAndSettle();

      // Verify that the onTap callback was called
      expect(tapped, isTrue);
    });

    testWidgets('FileCard applies correct styling from AdvancedUIService',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'styled_file.txt',
              fileSize: '50 KB',
              lastModified: '2024-01-15 14:20',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the Card widget
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      // Verify the Card has proper styling
      final Card card = tester.widget<Card>(cardFinder);
      expect(card.elevation, isNotNull);
      expect(card.margin, isNotNull);

      // Verify text styling
      final textFinder = find.text('styled_file.txt');
      final Text textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
    });

    testWidgets('FileCard displays file size with correct formatting',
        (WidgetTester tester) async {
      const testCases = [
        ('100', '100 B'),
        ('1024', '1 KB'),
        ('1048576', '1 MB'),
        ('1073741824', '1 GB'),
      ];

      for (final testCase in testCases) {
        final fileSize = testCase.$1;
        final expectedDisplay = testCase.$2;

        await tester.pumpWidget(
          MaterialApp(
            theme: uiService.getThemeData(brightness: Brightness.light),
            home: Scaffold(
              body: FileCard(
                fileName: 'test.txt',
                fileSize: fileSize,
                lastModified: '2024-01-15',
                onTap: () {},
              ),
            ),
          ),
        );

        // Verify the file size is displayed correctly
        expect(find.text(expectedDisplay), findsOneWidget);
      }
    });

    testWidgets('FileCard shows loading state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'loading_file.txt',
              fileSize: 'Unknown',
              lastModified: 'Loading...',
              onTap: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show CircularProgressIndicator when loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // File information should still be visible but with loading text
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('FileCard handles long file names gracefully',
        (WidgetTester tester) async {
      const longFileName = 'very_long_file_name_that_should_be_truncated_or_handled_gracefully.txt';

      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: SizedBox(
              width: 300, // Constrain width to test text overflow
              child: FileCard(
                fileName: longFileName,
                fileSize: '1 MB',
                lastModified: '2024-01-15',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // The file name should be displayed (truncated if necessary)
      expect(find.textContaining('very_long_file_name'), findsOneWidget);
    });

    testWidgets('FileCard is accessible with proper semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'accessible_file.pdf',
              fileSize: '500 KB',
              lastModified: '2024-01-15 16:45',
              onTap: () {},
            ),
          ),
        ),
      );

      // Check for semantic labels
      expect(find.bySemanticsLabel('accessible_file.pdf'), findsOneWidget);
      expect(find.bySemanticsLabel('500 KB'), findsOneWidget);
    });

    testWidgets('FileCard supports selection state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'selected_file.txt',
              fileSize: '200 B',
              lastModified: '2024-01-15',
              onTap: () {},
              isSelected: true,
            ),
          ),
        ),
      );

      // When selected, the card should have different styling
      final cardFinder = find.byType(Card);
      final Card card = tester.widget<Card>(cardFinder);

      // Selected cards should have different color/elevation
      expect(card.color, isNotNull);
    });

    testWidgets('FileCard adapts to different themes',
        (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'theme_test.txt',
              fileSize: '1 KB',
              lastModified: '2024-01-15',
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify light theme styling
      final lightCard = tester.widget<Card>(find.byType(Card));
      expect(lightCard.color, isNotNull);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: FileCard(
              fileName: 'theme_test.txt',
              fileSize: '1 KB',
              lastModified: '2024-01-15',
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify dark theme styling
      final darkCard = tester.widget<Card>(find.byType(Card));
      expect(darkCard.color, isNotNull);
    });

    testWidgets('FileCard handles error states gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: FileCard(
              fileName: 'error_file.txt',
              fileSize: 'Error loading size',
              lastModified: 'Error loading date',
              onTap: () {},
              hasError: true,
            ),
          ),
        ),
      );

      // Should display error information without crashing
      expect(find.text('Error loading size'), findsOneWidget);
      expect(find.text('Error loading date'), findsOneWidget);

      // Should show error icon
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('FileCard performance - renders quickly',
        (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          theme: uiService.getThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) => FileCard(
                fileName: 'file_$index.txt',
                fileSize: '${index * 1024} B',
                lastModified: '2024-01-15',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Wait for rendering to complete
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Should render 100 items in reasonable time (< 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      // Verify all items are rendered
      expect(find.byType(FileCard), findsNWidgets(100));
    });
  });
}
