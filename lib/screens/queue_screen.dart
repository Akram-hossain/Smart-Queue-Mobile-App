import 'dart:async';

import 'package:flutter/material.dart';

import '../db/queue_db.dart';
import '../models/token.dart';

class QueueScreen extends StatefulWidget {
  final int? myTokenId;
  const QueueScreen({super.key, required this.myTokenId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<QueueToken> _tokens = const [];
  QueueToken? _myToken;
  int _myPosition = -1;
  bool _alertedNearTurn = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final tokens = await QueueDb.instance.activeTokens();
    QueueToken? me;
    var pos = -1;
    final myId = widget.myTokenId;
    if (myId != null) {
      me = await QueueDb.instance.getToken(myId);
      pos = await QueueDb.instance.positionOf(myId);
    }
    if (!mounted) return;
    setState(() {
      _tokens = tokens;
      _myToken = me;
      _myPosition = pos;
    });
    _maybeAlert();
  }

  void _maybeAlert() {
    if (widget.myTokenId == null) return;
    final nearTurn = _myPosition == 0 || _myPosition == 1;
    if (nearTurn && !_alertedNearTurn) {
      _alertedNearTurn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _myPosition == 0
                  ? "It's your turn now!"
                  : "You're next! Please get ready.",
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    } else if (_myPosition > 1) {
      _alertedNearTurn = false;
    }
  }

  Future<void> _callNext() async {
    await QueueDb.instance.callNext();
    await _refresh();
  }

  Future<void> _clearQueue() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear queue?'),
        content: const Text(
          'This removes every token from the queue. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await QueueDb.instance.clearAll();
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        actions: [
          IconButton(
            tooltip: 'Clear queue',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearQueue,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_myToken != null)
            _MyTokenCard(token: _myToken!, position: _myPosition),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tokens in queue: ${_tokens.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _tokens.isEmpty ? null : _callNext,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Call Next'),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: _tokens.isEmpty
                ? const Center(child: Text('No tokens issued yet.'))
                : ListView.builder(
                    itemCount: _tokens.length,
                    itemBuilder: (context, i) => _TokenRow(
                      token: _tokens[i],
                      isMine: _tokens[i].id == widget.myTokenId,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MyTokenCard extends StatelessWidget {
  final QueueToken token;
  final int position;
  const _MyTokenCard({required this.token, required this.position});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (String label, Color color) = switch (position) {
      -1 => ('Completed', Colors.grey),
      0 => ("It's your turn!", Colors.orange.shade700),
      1 => ('1 ahead of you', theme.colorScheme.primary),
      _ => ('$position ahead of you', theme.colorScheme.primary),
    };
    return Card(
      margin: const EdgeInsets.all(16),
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${token.tokenNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Token',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  final QueueToken token;
  final bool isMine;
  const _TokenRow({required this.token, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isServing = token.status == 'serving';
    final Color bg;
    final Color fg;
    if (isServing) {
      bg = Colors.orange.shade700;
      fg = Colors.white;
    } else if (isMine) {
      bg = theme.colorScheme.primary;
      fg = Colors.white;
    } else {
      bg = Colors.grey.shade300;
      fg = Colors.black87;
    }
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: bg,
        foregroundColor: fg,
        child: Text('${token.tokenNumber}'),
      ),
      title: Text(
        isServing ? 'Now serving' : 'Waiting',
        style: TextStyle(
          fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text('Issued ${_formatTime(token.issuedAt)}'),
      trailing: isMine ? const Chip(label: Text('You')) : null,
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
