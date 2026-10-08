import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/deliverable_submission.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/contract_chat_service.dart';
import '../../core/services/encryption_key_registry.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// One row in the chat thread: a day divider, a contract event, or a message.
sealed class ChatTimelineItem {
  DateTime get at;
}

class ChatDayDivider extends ChatTimelineItem {
  @override
  final DateTime at;
  ChatDayDivider(this.at);
}

class ChatSystemEvent extends ChatTimelineItem {
  @override
  final DateTime at;
  final String label;
  final IconData icon;
  final Color color;
  ChatSystemEvent(this.at, this.label, this.icon, this.color);
}

class ChatMessageItem extends ChatTimelineItem {
  final ChatMessage message;
  ChatMessageItem(this.message);
  @override
  DateTime get at => message.sentAt;
}

/// Merges messages with the contract's own milestones (funded, deliverables,
/// dispute, settlement) in time order, with a divider at each new day.
///
/// The events come from on-chain and synced state the app already holds, not
/// from the chat collection, so neither party can forge or delete them.
List<ChatTimelineItem> buildChatTimeline({
  required EscrowContract contract,
  required List<DeliverableSubmission> deliverables,
  required List<ChatMessage> messages,
}) {
  final events = <ChatTimelineItem>[
    ChatSystemEvent(contract.createdAt, 'Contract created', Icons.description_outlined,
        AppColors.primaryContainer),
    if (contract.fundedAt != null)
      ChatSystemEvent(contract.fundedAt!, 'Escrow funded · ${contract.formattedAmount} locked',
          Icons.check_circle_rounded, AppColors.tertiaryContainer),
  ];

  final sorted = [...deliverables]..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  for (var i = 0; i < sorted.length; i++) {
    events.add(ChatSystemEvent(sorted[i].submittedAt, 'Worker submitted deliverable v${i + 1}',
        Icons.upload_file_rounded, AppColors.primaryContainer));
  }
  if (contract.disputeRaisedAt != null) {
    events.add(ChatSystemEvent(contract.disputeRaisedAt!, 'Dispute raised',
        Icons.gavel_rounded, AppColors.warning));
  }
  if (contract.completedAt != null) {
    final cancelled = contract.status == ContractStatus.cancelled;
    events.add(ChatSystemEvent(
      contract.completedAt!,
      cancelled ? 'Contract cancelled · escrow refunded' : 'Payment released · contract completed',
      cancelled ? Icons.undo_rounded : Icons.verified_rounded,
      cancelled ? AppColors.outline : AppColors.tertiaryContainer,
    ));
  }

  final items = [...events, ...messages.map(ChatMessageItem.new)]
    ..sort((a, b) => a.at.compareTo(b.at));

  final out = <ChatTimelineItem>[];
  DateTime? day;
  for (final item in items) {
    final local = item.at.toLocal();
    final d = DateTime(local.year, local.month, local.day);
    if (day != d) {
      out.add(ChatDayDivider(d));
      day = d;
    }
    out.add(item);
  }
  return out;
}

/// End-to-end encrypted chat between a contract's employer and worker.
class ContractChatScreen extends ConsumerStatefulWidget {
  final String contractId;

  const ContractChatScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractChatScreen> createState() => _ContractChatScreenState();
}

class _ContractChatScreenState extends ConsumerState<ContractChatScreen> {
  final _controller = TextEditingController();
  bool _publishingKey = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(ChatSession session) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    _controller.clear();
    try {
      // Offline, Firestore queues the write and this future only completes once
      // it reaches the server; the bubble shows "Sending…" in the meantime.
      await ref.read(contractChatServiceProvider).send(session, text);
    } catch (e) {
      if (!mounted) return;
      if (_controller.text.isEmpty) _controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is StateError ? e.message : 'Message not sent: $e')),
      );
    }
  }

  Future<void> _publishKey(String me) async {
    setState(() => _publishingKey = true);
    final result = await ref.read(encryptionKeyRegistryProvider).attestAndPublish(me);
    if (!mounted) return;
    setState(() => _publishingKey = false);
    if (result == KeyRegistrationResult.published) {
      ref.invalidate(encryptionKeyRegistryProvider);
      ref.invalidate(contractChatSessionProvider(widget.contractId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result == KeyRegistrationResult.notConnected
            ? 'Connect your wallet first.'
            : 'Signing was declined — chat stays locked.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contract = ref.watch(contractProvider(widget.contractId)).valueOrNull;
    final sessionAsync = ref.watch(contractChatSessionProvider(widget.contractId));
    final session = sessionAsync.valueOrNull;
    final deliverables =
        ref.watch(contractDeliverablesProvider(widget.contractId)).valueOrNull ?? const [];
    final messages = (session != null && session.canRead)
        ? ref.watch(contractChatMessagesProvider(session)).valueOrNull ?? const <ChatMessage>[]
        : const <ChatMessage>[];

    final isEmployer = contract?.isEmployer(session?.me) ?? false;
    final counterpartyRole = isEmployer ? 'Worker' : 'Employer';
    final counterparty = session?.counterparty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat with $counterpartyRole',
                style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
            if (counterparty != null)
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: counterparty));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied'), duration: Duration(seconds: 1)),
                  );
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_short(counterparty),
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                  const SizedBox(width: 4),
                  const Icon(Icons.content_copy_rounded, size: 13, color: AppColors.outline),
                ]),
              ),
          ],
        ),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: _DevnetChip())],
      ),
      body: contract == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _ContextStrip(contract: contract),
                Expanded(
                  child: _Thread(
                    items: buildChatTimeline(
                      contract: contract,
                      deliverables: deliverables,
                      messages: messages,
                    ),
                    me: session?.me,
                    counterpartyRole: counterpartyRole.toLowerCase(),
                  ),
                ),
                _bottom(sessionAsync, counterpartyRole),
              ],
            ),
    );
  }

  Widget _bottom(AsyncValue<ChatSession?> sessionAsync, String counterpartyRole) {
    final session = sessionAsync.valueOrNull;
    if (session == null) {
      return _Banner(
        icon: Icons.lock_clock_rounded,
        text: sessionAsync.hasError ? 'Chat could not be opened.' : 'Opening encrypted chat…',
      );
    }
    switch (session.state) {
      case ChatSetupState.notAParty:
        return const _Banner(
          icon: Icons.block_rounded,
          text: 'Only the employer and worker on this contract can use its chat.',
        );
      case ChatSetupState.unavailable:
        return const _Banner(
          icon: Icons.cloud_off_rounded,
          text: 'Chat needs Firebase, which is not configured in this build.',
        );
      case ChatSetupState.needsMyKey:
        return _Banner(
          icon: Icons.key_rounded,
          text: 'Sign a one-time message so the ${counterpartyRole.toLowerCase()} can verify '
              'your encryption key. No transaction, no fee.',
          action: FilledButton.icon(
            onPressed: _publishingKey ? null : () => _publishKey(session.me!),
            icon: _publishingKey
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.verified_user_rounded, size: 18),
            label: const Text('Sign & enable chat'),
          ),
        );
      case ChatSetupState.waitingForCounterparty:
        return _Banner(
          icon: Icons.hourglass_top_rounded,
          text: 'Waiting for the ${counterpartyRole.toLowerCase()} to publish their encryption '
              'key. Chat unlocks as soon as they open ClockIn and sign.',
          action: TextButton(
            onPressed: () => ref.invalidate(contractChatSessionProvider(widget.contractId)),
            child: const Text('Check again'),
          ),
        );
      case ChatSetupState.ready:
        if (session.readOnly) {
          return const _Banner(
            icon: Icons.lock_rounded,
            text: 'This contract is settled. The conversation is kept, read-only.',
          );
        }
        return _Composer(
          controller: _controller,
          hint: 'Message the ${counterpartyRole.toLowerCase()}…',
          onSend: () => _send(session),
        );
    }
  }
}

String _short(String a) => a.length > 10 ? '${a.substring(0, 4)}…${a.substring(a.length - 4)}' : a;

class _DevnetChip extends StatelessWidget {
  const _DevnetChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('DEVNET',
            style: AppTypography.labelSm.copyWith(
                color: AppColors.primaryContainer, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]),
    );
  }
}

class _ContextStrip extends StatelessWidget {
  final EscrowContract contract;
  const _ContextStrip({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      child: InkWell(
        // The chat is opened from the contract screen, so going back opens it.
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('#${contract.contractId}',
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(contract.formattedAmount,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_statusLabel(contract.status),
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.outline),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.outline),
              const SizedBox(width: 4),
              Expanded(
                child: Text('Escrow locked on Solana · tap to open contract',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  static String _statusLabel(ContractStatus s) => switch (s) {
        ContractStatus.created => 'CREATED',
        ContractStatus.funded => 'FUNDED',
        ContractStatus.inProgress => 'IN PROGRESS',
        ContractStatus.completed => 'COMPLETED',
        ContractStatus.disputed => 'DISPUTED',
        ContractStatus.cancelled => 'CANCELLED',
      };
}

class _Thread extends StatelessWidget {
  final List<ChatTimelineItem> items;
  final String? me;
  final String counterpartyRole;

  const _Thread({required this.items, required this.me, required this.counterpartyRole});

  @override
  Widget build(BuildContext context) {
    // Reversed so the newest message sits at the bottom and the list opens there.
    final rows = items.reversed.toList();
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: rows.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == rows.length) return _EncryptionNotice(counterpartyRole: counterpartyRole);
        return switch (rows[i]) {
          ChatDayDivider(:final at) => Center(
              child: Text(_dayLabel(at),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.outline, fontWeight: FontWeight.w600)),
            ),
          final ChatSystemEvent e => _EventPill(event: e),
          ChatMessageItem(:final message) =>
            _Bubble(message: message, mine: message.isFrom(me)),
        };
      },
    );
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE d MMM').format(d);
  }
}

class _EncryptionNotice extends StatelessWidget {
  final String counterpartyRole;
  const _EncryptionNotice({required this.counterpartyRole});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.outline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'End-to-end encrypted. Only you and the $counterpartyRole can read these messages.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.outline, fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  final ChatSystemEvent event;
  const _EventPill({required this.event});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(event.icon, size: 15, color: event.color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(event.label,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(16);
    const tail = Radius.circular(4);
    final time = DateFormat('h:mm a').format(message.sentAt.toLocal());
    final meta = AppTypography.labelSm.copyWith(color: AppColors.outline);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mine ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.only(
                  topLeft: r,
                  topRight: r,
                  bottomLeft: mine ? r : tail,
                  bottomRight: mine ? tail : r,
                ),
                border: mine ? null : Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: SelectableText(
                message.text,
                style: AppTypography.bodyMd.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.onSurface,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: mine
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('$time · ', style: meta),
                      Icon(message.pending ? Icons.schedule_rounded : Icons.check_rounded,
                          size: 13,
                          color: message.pending ? AppColors.outline : AppColors.primary),
                      const SizedBox(width: 2),
                      Text(message.pending ? 'Sending…' : 'Sent', style: meta),
                    ])
                  : Text(time, style: meta),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.hint, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHighest)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.outline),
            const SizedBox(width: 4),
            Text('Encrypted on your device',
                style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, _) {
                final n = v.text.trim().length;
                if (n < ContractChatService.maxMessageLength - 200) return const SizedBox.shrink();
                return Text('$n/${ContractChatService.maxMessageLength}',
                    style: AppTypography.labelSm.copyWith(
                        color: n > ContractChatService.maxMessageLength
                            ? AppColors.error
                            : AppColors.outline));
              },
            ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                key: const Key('chat-composer'),
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.surfaceContainerHighest),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.surfaceContainerHighest),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, _) {
                final n = v.text.trim().length;
                final enabled = n > 0 && n <= ContractChatService.maxMessageLength;
                return Material(
                  color: enabled ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: const Key('chat-send'),
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onSend : null,
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.send_rounded,
                          size: 20, color: enabled ? AppColors.onPrimary : AppColors.outline),
                    ),
                  ),
                );
              },
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Banner({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHighest)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: AppColors.primaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant, height: 1.4)),
            ),
          ]),
          if (action != null) ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: action),
          ],
        ]),
      ),
    );
  }
}
