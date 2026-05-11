import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/grocery_item.dart';
import '../../providers/grocery_provider.dart';

// ── Receipt palette ───────────────────────────────────────────────────────────
const _paper   = Color(0xFFF5E6D8);
const _ink     = Color(0xFF2A5C3F);
const _inkFade = Color(0xFF6A9C7A);
const _red     = Color.fromARGB(255, 6, 63, 16);
const _line    = Color(0xFF5A9A70);

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  bool _isEditing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    Future.microtask(() => _focus.requestFocus());
  }

  void _addItem(GroceryProvider grocery) {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      grocery.addItem(text, _guessEmoji(text));
    }
    _ctrl.clear();
    // Stay in editing mode so user can keep typing next item
    Future.microtask(() => _focus.requestFocus());
  }

  void _stopEditing() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      final grocery = context.read<GroceryProvider>();
      grocery.addItem(text, _guessEmoji(text));
    }
    _ctrl.clear();
    _focus.unfocus();
    setState(() => _isEditing = false);
  }

  String _guessEmoji(String name) {
    final n = name.toLowerCase();
    const map = {
      'milk': '🥛', 'süt': '🥛',
      'egg': '🥚', 'yumurta': '🥚',
      'bread': '🍞', 'ekmek': '🍞',
      'cheese': '🧀', 'peynir': '🧀',
      'chicken': '🍗', 'tavuk': '🍗',
      'beef': '🥩', 'et': '🥩',
      'fish': '🐟', 'balık': '🐟',
      'apple': '🍎', 'elma': '🍎',
      'banana': '🍌', 'muz': '🍌',
      'tomato': '🍅', 'domates': '🍅',
      'onion': '🧅', 'soğan': '🧅',
      'garlic': '🧄', 'sarımsak': '🧄',
      'lemon': '🍋', 'limon': '🍋',
      'potato': '🥔', 'patates': '🥔',
      'carrot': '🥕', 'havuç': '🥕',
      'rice': '🍚', 'pirinç': '🍚',
      'pasta': '🍝', 'makarna': '🍝',
      'butter': '🧈', 'tereyağ': '🧈',
      'oil': '🫙', 'yağ': '🫙',
      'sugar': '🍬', 'şeker': '🍬',
      'coffee': '☕', 'kahve': '☕',
      'tea': '🍵', 'çay': '🍵',
      'yogurt': '🥛', 'yoğurt': '🥛',
      'flour': '🌾', 'un': '🌾',
      'cucumber': '🥒', 'salatalık': '🥒',
      'pepper': '🫑', 'biber': '🫑',
      'salt': '🧂', 'tuz': '🧂',
    };
    for (final entry in map.entries) {
      if (n.contains(entry.key)) return entry.value;
    }
    return '🛒';
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();

    return GestureDetector(
      onTap: () {
        if (_isEditing) _stopEditing();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _ReceiptCard(
            grocery: grocery,
            isEditing: _isEditing,
            editingController: _ctrl,
            editingFocus: _focus,
            onToggle: (id) => grocery.toggleItem(id),
            onDelete: (id) => grocery.removeItem(id),
            onClearChecked: grocery.checked.isEmpty
                ? null
                : () => _showClearDialog(context, grocery),
            onTapBlankLine: _startEditing,
            onSubmitLine: () => _addItem(grocery),
            onEditingDone: _stopEditing,
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, GroceryProvider grocery) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove checked items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { grocery.clearChecked(); Navigator.pop(ctx); },
            child: const Text('Remove', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }
}

// ── Receipt card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final GroceryProvider grocery;
  final bool isEditing;
  final TextEditingController editingController;
  final FocusNode editingFocus;
  final void Function(String) onToggle;
  final void Function(String) onDelete;
  final VoidCallback? onClearChecked;
  final VoidCallback onTapBlankLine;
  final VoidCallback onSubmitLine;
  final VoidCallback onEditingDone;

  const _ReceiptCard({
    required this.grocery,
    required this.isEditing,
    required this.editingController,
    required this.editingFocus,
    required this.onToggle,
    required this.onDelete,
    this.onClearChecked,
    required this.onTapBlankLine,
    required this.onSubmitLine,
    required this.onEditingDone,
  });

  @override
  Widget build(BuildContext context) {
    final all       = grocery.items;
    final unchecked = grocery.unchecked;
    final checked   = grocery.checked;
    // Always show at least 14 lines total (items + blanks + editing line)
    final totalSlots  = 14;
    final filledSlots = all.length + (isEditing ? 1 : 0);
    final fillerCount = (totalSlots - filledSlots).clamp(0, totalSlots);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(2, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4,  offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReceiptHeader(total: all.length, checked: checked.length),
          _ColumnHeaders(),
          ...unchecked.map((item) => _ReceiptRow(
                item: item,
                onToggle: () => onToggle(item.id),
                onDelete: () => onDelete(item.id),
              )),
          ...checked.map((item) => _ReceiptRow(
                item: item,
                onToggle: () => onToggle(item.id),
                onDelete: () => onDelete(item.id),
              )),
          // Inline editing line — appears right after items
          if (isEditing)
            _InlineLine(
              controller: editingController,
              focusNode: editingFocus,
              onSubmit: onSubmitLine,
              onDone: onEditingDone,
            ),
          // Remaining blank lines — first one is tappable to start editing
          ...List.generate(fillerCount, (i) => _BlankLine(
                onTap: (!isEditing && i == 0) ? onTapBlankLine : null,
              )),
          if (onClearChecked != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: GestureDetector(
                onTap: onClearChecked,
                child: Text(
                  'Clear done items',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    color: _red,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    decorationColor: _red,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ReceiptHeader extends StatelessWidget {
  final int total;
  final int checked;
  const _ReceiptHeader({required this.total, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _ink, width: 2),
            ),
            child: const Center(
              child: Text('🛒', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GROCERY',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'LIST',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: 2,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),
          if (total > 0)
            Text(
              '$checked/$total',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _red,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Column labels ─────────────────────────────────────────────────────────────

class _ColumnHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ITEMIZED LIST',
              style: GoogleFonts.playfairDisplay(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _inkFade,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text(
            'DONE',
            style: GoogleFonts.playfairDisplay(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _inkFade,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReceiptRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: _red.withValues(alpha: 0.12),
        child: const Icon(Icons.delete_outline_rounded, color: _red, size: 18),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _line, width: 0.8)),
          ),
          child: Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: item.isChecked ? _inkFade : _ink,
                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    decorationColor: _inkFade,
                    decorationThickness: 2,
                  ),
                ),
              ),
              // Checkbox circle matching receipt style
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isChecked ? _ink : Colors.transparent,
                  border: Border.all(color: _ink, width: 1.5),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check_rounded, size: 13, color: _paper)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inline editing line ───────────────────────────────────────────────────────

class _InlineLine extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onDone;

  const _InlineLine({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'Write an item…',
                hintStyle: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  color: _inkFade,
                  fontStyle: FontStyle.italic,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          GestureDetector(
            onTap: onDone,
            child: const Icon(Icons.check_rounded, color: _inkFade, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Blank line ────────────────────────────────────────────────────────────────

class _BlankLine extends StatelessWidget {
  final VoidCallback? onTap;
  const _BlankLine({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line, width: 0.8)),
        ),
        child: onTap != null
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap to add…',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    color: _inkFade.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
