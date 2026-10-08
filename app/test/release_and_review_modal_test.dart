import 'package:clockin/core/models/deliverable_submission.dart';
import 'package:clockin/core/models/escrow_contract.dart';
import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/features/contracts/release_and_review_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the Release & Review sheet on small phones.
///
/// On a 360×640dp Galaxy J7 the sheet's content was taller than the screen and
/// did not scroll, so the "Release … & Submit Review" button was cut off and
/// could not be tapped. These tests open the sheet through its real
/// `showModalBottomSheet` route in its tallest state (a submitted deliverable,
/// which adds the deliverable card and the revisions button).
///
/// Widget tests render text in a square-glyph test font that is taller and
/// wider than the real font, so content here is taller than on a device —
/// a conservative check for this vertical-overflow bug.
void main() {
  const contractId = 'ctr-j7-test';

  final contract = EscrowContract(
    contractId: contractId,
    employer: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
    worker: 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk',
    amount: BigInt.from(500000000),
    termsHash: '00',
    status: ContractStatus.inProgress,
    createdAt: DateTime.utc(2026, 10, 6),
  );

  final submission = DeliverableSubmission(
    id: 1,
    contractId: contractId,
    submitterAddress: 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk',
    encryptedPayload: 'Y2lwaGVydGV4dA==',
    iv: 'aXY=',
    authTag: 'dGFn',
    plaintextHash: 'abc123',
    submittedAt: DateTime.utc(2026, 10, 6),
    completionNote: 'Delivered the dashboard redesign and handoff notes.',
  );

  /// Layout errors raised while the sheet is open, split by kind.
  ///
  /// Only *vertical* overflow is this bug, so only it fails the test. The test
  /// font's glyphs are far wider than the real font's, so horizontal overflow
  /// measured here says nothing about a device and is recorded but not judged.
  /// Any error that is not a RenderFlex overflow always fails.
  late List<String> verticalOverflows;
  late List<String> horizontalOverflows;
  late List<String> otherErrors;

  void captureLayoutErrors() {
    verticalOverflows = [];
    horizontalOverflows = [];
    otherErrors = [];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed by') && text.contains('on the bottom')) {
        verticalOverflows.add(text);
      } else if (text.contains('overflowed by')) {
        horizontalOverflows.add(text);
      } else {
        otherErrors.add(text);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  void expectNoVerticalOverflow() {
    expect(verticalOverflows, isEmpty, reason: 'sheet content must not be cut off vertically');
    expect(otherErrors, isEmpty);
  }

  Future<void> openSheet(WidgetTester tester, {double keyboard = 0}) async {
    captureLayoutErrors();
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    tester.view.padding = const FakeViewPadding(top: 24 * 2, bottom: 0);
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          latestDeliverableProvider(contractId).overrideWith((ref) => Stream.value(submission)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => ReleaseAndReviewModal.show(
                    context,
                    contract,
                    initialDecryptedContent: 'URL: https://github.com/clockin/pull/42',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder releaseButton() =>
      find.widgetWithText(ElevatedButton, 'Release ${contract.formattedAmount} & Submit Review');

  testWidgets('on a 360×640 screen the sheet does not overflow and Release is tappable',
      (tester) async {
    await openSheet(tester);

    expectNoVerticalOverflow();

    // The button is fully on-screen and nothing covers it.
    final rect = tester.getRect(releaseButton());
    expect(rect.bottom, lessThanOrEqualTo(640));
    expect(releaseButton().hitTestable(), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Request Changes / Revisions').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('the sheet body scrolls to reveal everything above the buttons', (tester) async {
    await openSheet(tester);

    final callout = find.text('RELEASING FROM ESCROW TO WORKER');
    final before = tester.getTopLeft(callout).dy;
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(callout).dy;

    expect(after, lessThan(before), reason: 'body content should scroll up');
    // Scrolling the body never moves the pinned action button off-screen.
    expect(releaseButton().hitTestable(), findsOneWidget);
    expectNoVerticalOverflow();
  });

  testWidgets('with the keyboard open, the sheet sits above it and Release stays reachable',
      (tester) async {
    const keyboard = 260.0; // typical on-screen keyboard height on a 640dp phone
    await openSheet(tester, keyboard: keyboard);

    expectNoVerticalOverflow();
    final rect = tester.getRect(releaseButton());
    expect(rect.bottom, lessThanOrEqualTo(640 - keyboard));
    expect(releaseButton().hitTestable(), findsOneWidget);
  });
}
