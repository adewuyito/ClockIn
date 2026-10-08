import 'package:clockin/core/models/deliverable_submission.dart';
import 'package:clockin/core/models/escrow_contract.dart';
import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/core/services/contract_chat_crypto.dart';
import 'package:clockin/core/services/contract_chat_service.dart';
import 'package:clockin/core/services/deliverable_encryption_service.dart';
import 'package:clockin/features/contracts/contract_chat_screen.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const employer = 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ';
  const worker = 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk';
  const id = 'ctr-chat-ui';

  EscrowContract contractWith(ContractStatus status, {DateTime? completedAt}) => EscrowContract(
        contractId: id,
        employer: employer,
        worker: worker,
        amount: BigInt.from(500000000),
        termsHash: '00',
        status: status,
        createdAt: DateTime(2026, 10, 6, 9),
        fundedAt: DateTime(2026, 10, 6, 9, 5),
        completedAt: completedAt,
      );

  DeliverableSubmission deliverable(DateTime at) => DeliverableSubmission(
        contractId: id,
        submitterAddress: worker,
        encryptedPayload: 'x',
        iv: 'x',
        authTag: '',
        plaintextHash: 'h',
        submittedAt: at,
      );

  late crypto.SecretKey key;
  setUpAll(() async {
    final k = DeliverableEncryptionService();
    key = await ContractChatCrypto.deriveContractKey(
      myPrivateKeyBase64: (await k.generateX25519KeyPair()).privateKeyBase64,
      theirPublicKeyBase64: (await k.generateX25519KeyPair()).publicKeyBase64,
      contractId: id,
    );
  });

  group('buildChatTimeline', () {
    test('merges contract events and messages in time order with day dividers', () {
      final items = buildChatTimeline(
        contract: contractWith(ContractStatus.completed, completedAt: DateTime(2026, 10, 7, 18)),
        deliverables: [deliverable(DateTime(2026, 10, 7, 12)), deliverable(DateTime(2026, 10, 7, 9))],
        messages: [
          ChatMessage(id: 'a', sender: employer, text: 'hi', sentAt: DateTime(2026, 10, 6, 10)),
          ChatMessage(id: 'b', sender: worker, text: 'done', sentAt: DateTime(2026, 10, 7, 12, 1)),
        ],
      );
      final labels = items.map((i) => switch (i) {
            ChatDayDivider(:final at) => 'day ${at.day}',
            ChatSystemEvent(:final label) => label,
            ChatMessageItem(:final message) => 'msg ${message.text}',
          });
      expect(labels, [
        'day 6',
        'Contract created',
        'Escrow funded · 0.5 SOL locked',
        'msg hi',
        'day 7',
        'Worker submitted deliverable v1',
        'Worker submitted deliverable v2',
        'msg done',
        'Payment released · contract completed',
      ]);
    });

    test('a cancelled contract reads as refunded, not released', () {
      final items = buildChatTimeline(
        contract: contractWith(ContractStatus.cancelled, completedAt: DateTime(2026, 10, 8)),
        deliverables: const [],
        messages: const [],
      );
      expect(items.whereType<ChatSystemEvent>().last.label, 'Contract cancelled · escrow refunded');
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    required EscrowContract contract,
    required ChatSession session,
    List<ChatMessage> messages = const [],
  }) async {
    // Test-font glyphs are much wider than Plus Jakarta Sans; give them room.
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        contractProvider.overrideWith((ref, _) => Stream.value(contract)),
        contractDeliverablesProvider.overrideWith((ref, _) => Stream.value(const [])),
        contractChatSessionProvider.overrideWith((ref, _) async => session),
        contractChatMessagesProvider.overrideWith((ref, _) => Stream.value(messages)),
      ],
      child: const MaterialApp(home: ContractChatScreen(contractId: id)),
    ));
    await tester.pumpAndSettle();
  }

  ChatSession ready({bool readOnly = false}) => ContractChatService.sessionForTest(
        contractId: id,
        me: worker,
        counterparty: employer,
        key: key,
        readOnly: readOnly,
      );

  testWidgets('ready: shows the thread, my pending message, and a composer', (tester) async {
    await pump(
      tester,
      contract: contractWith(ContractStatus.inProgress),
      session: ready(),
      messages: [
        ChatMessage(id: 'a', sender: employer, text: 'Can you send the Figma?', sentAt: DateTime.now()),
        ChatMessage(id: 'b', sender: worker, text: 'Uploading now', sentAt: DateTime.now(), pending: true),
      ],
    );
    expect(find.text('Chat with Employer'), findsOneWidget);
    expect(find.text('Can you send the Figma?'), findsOneWidget);
    expect(find.text('Uploading now'), findsOneWidget);
    expect(find.text('Sending…'), findsOneWidget);
    expect(find.textContaining('Escrow funded'), findsOneWidget);
    expect(find.byKey(const Key('chat-composer')), findsOneWidget);
  });

  testWidgets('settled contract: history stays, composer is replaced', (tester) async {
    await pump(
      tester,
      contract: contractWith(ContractStatus.completed, completedAt: DateTime.now()),
      session: ready(readOnly: true),
      messages: [ChatMessage(id: 'a', sender: employer, text: 'Thanks!', sentAt: DateTime.now())],
    );
    expect(find.text('Thanks!'), findsOneWidget);
    expect(find.byKey(const Key('chat-composer')), findsNothing);
    expect(find.textContaining('read-only'), findsOneWidget);
  });

  ChatSession blocked(ChatSetupState state) => ContractChatService.sessionForTest(
        contractId: id,
        me: worker,
        counterparty: employer,
        state: state,
      );

  testWidgets('my key not attested yet: offers the one-time signature', (tester) async {
    await pump(tester,
        contract: contractWith(ContractStatus.inProgress),
        session: blocked(ChatSetupState.needsMyKey));
    expect(find.text('Sign & enable chat'), findsOneWidget);
    expect(find.byKey(const Key('chat-composer')), findsNothing);
    // Contract events still render while chat is locked.
    expect(find.textContaining('Escrow funded'), findsOneWidget);
  });

  testWidgets('counterparty has no key yet: explains and offers a re-check', (tester) async {
    await pump(tester,
        contract: contractWith(ContractStatus.inProgress),
        session: blocked(ChatSetupState.waitingForCounterparty));
    expect(find.textContaining('Waiting for the employer'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.byKey(const Key('chat-composer')), findsNothing);
  });

  testWidgets('send is disabled until there is text', (tester) async {
    await pump(tester, contract: contractWith(ContractStatus.inProgress), session: ready());
    final send = find.byKey(const Key('chat-send'));
    expect(tester.widget<InkWell>(send).onTap, isNull);
    await tester.enterText(find.byKey(const Key('chat-composer')), 'hello');
    await tester.pump();
    expect(tester.widget<InkWell>(send).onTap, isNotNull);
  });
}
