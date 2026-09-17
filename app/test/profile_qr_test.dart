import 'package:clockin/core/widgets/profile_qr_sheet.dart';
import 'package:clockin/core/widgets/qr_scanner_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('QrScanResult.parse tests', () {
    const testAddr = '8xrt2BeSqZfW7GqFv3qNf4K8jY1u9m6oP4s7T2wX1abc';

    test('parses raw Solana base58 address correctly', () {
      final res = QrScanResult.parse(testAddr);
      expect(res.solanaAddress, testAddr);
    });

    test('parses solana: URI correctly', () {
      final res = QrScanResult.parse('solana:$testAddr');
      expect(res.solanaAddress, testAddr);
    });

    test('parses solana: URI with query amount correctly', () {
      final res = QrScanResult.parse('solana:$testAddr?amount=2.5');
      expect(res.solanaAddress, testAddr);
      expect(res.amountSol, 2.5);
    });

    test('parses clockin://worker/ deep link correctly', () {
      final res = QrScanResult.parse('clockin://worker/$testAddr');
      expect(res.solanaAddress, testAddr);
    });

    test('parses clockin:worker: deep link correctly', () {
      final res = QrScanResult.parse('clockin:worker:$testAddr');
      expect(res.solanaAddress, testAddr);
    });

    test('parses clockin://contract/ deep link correctly', () {
      final res = QrScanResult.parse('clockin://contract/escrow-123');
      expect(res.contractId, 'escrow-123');
    });
  });

  group('ProfileQrCard & ProfileQrSheet Widget tests', () {
    const testAddress = '9xQeWvG816bUx9EPjHmaT23yvVM2VXmzMz58VmtA6abc';

    testWidgets('ProfileQrCard builds and displays QR code and address',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileQrCard(
                address: testAddress,
                title: 'My Reputation Pass',
                subtitle: 'Scan to view on-chain record',
              ),
            ),
          ),
        ),
      );

      // Verify title and subtitle
      expect(find.text('My Reputation Pass'), findsOneWidget);
      expect(find.text('Scan to view on-chain record'), findsOneWidget);

      // Verify QR image widget rendered
      expect(find.byType(QrImageView), findsOneWidget);

      // Tap Enlarge button
      await tester.tap(find.text('Enlarge'));
      await tester.pumpAndSettle();

      // ProfileQrSheet opens with two QrImageViews (one inline, one in sheet)
      expect(find.byType(QrImageView), findsNWidgets(2));
      expect(find.text('Solana Pay URI'), findsOneWidget);
      expect(find.text('Raw Address'), findsOneWidget);
      expect(find.text('Copy Solana URI'), findsOneWidget);
      expect(find.text('Copy Address'), findsOneWidget);

      // Toggle format to Raw Address
      await tester.tap(find.text('Raw Address'));
      await tester.pumpAndSettle();

      // Toggle back to Solana Pay URI
      await tester.tap(find.text('Solana Pay URI'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Solana Pay URI'), findsNothing);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });
}
