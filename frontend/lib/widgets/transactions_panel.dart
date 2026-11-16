import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../models/category.dart';
import '../models/operation.dart';
import '../utils/money.dart';
import 'emoji_icon.dart';
import 'highlighted_text.dart';
import 'primary_button.dart';

enum TransactionsStatus { loading, error, loaded }

enum _Filter { all, income, expense }

/// The "Transactions" card: search, All/Income/Expenses filter and the table.
/// [operations] should already be the ones of [month]. Search and filter run on the phone side.
class TransactionsPanel extends StatefulWidget {
  final TransactionsStatus status;
  final List<Operation> operations;
  final Map<int, Category> categories;
  final String currency;
  final DateTime month;
  final VoidCallback onRetry;

  const TransactionsPanel({
    super.key,
    required this.status,
    required this.operations,
    required this.categories,
    required this.currency,
    required this.month,
    required this.onRetry,
  });

  @override
  State<TransactionsPanel> createState() => _TransactionsPanelState();
}

class _TransactionsPanelState extends State<TransactionsPanel> {
  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _monthFormat = DateFormat('MMMM yyyy');

  final _searchController = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Category? _categoryOf(Operation o) =>
      o.categoryId == null ? null : widget.categories[o.categoryId];

  /// The backend only has a comment, so that is the main line.
  /// Without a comment: the category name, then "Income" / "Expense".
  String _titleOf(Operation o) {
    final comment = o.comment;
    if (comment != null && comment.isNotEmpty) return comment;
    final category = _categoryOf(o);
    if (category != null) return category.name;
    return o.isIncome
        ? AppStrings.operationIncome
        : AppStrings.operationExpense;
  }

  List<Operation> get _visible {
    final q = _query.trim().toLowerCase();
    return widget.operations.where((o) {
      if (_filter == _Filter.income && !o.isIncome) return false;
      if (_filter == _Filter.expense && o.isIncome) return false;
      if (q.isEmpty) return true;
      return _titleOf(o).toLowerCase().contains(q) ||
          (_categoryOf(o)?.name.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 420),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 760;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(compact),
              const Divider(height: 1, color: AppColors.border),
              _body(compact),
            ],
          );
        },
      ),
    );
  }

  // ---------- header ----------

  Widget _header(bool compact) {
    final month = _monthFormat.format(widget.month);
    final subtitle = widget.status == TransactionsStatus.loaded
        ? AppStrings.transactionsSubtitle(month, widget.operations.length)
        : month;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.transactions,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );

    final controls = Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _searchField(),
        // In the design, but it has no actions yet.
        const Icon(Icons.more_vert, size: 20, color: AppColors.textPrimary),
        _filterToggle(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), controls],
            )
          : Row(
              children: [
                Expanded(child: title),
                controls,
              ],
            ),
    );
  }

  Widget _searchField() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search, size: 24, color: AppColors.textPrimary),
        const SizedBox(width: 10),
        SizedBox(
          width: 192,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            cursorColor: AppColors.primary,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.hint),
              filled: true,
              fillColor: AppColors.searchFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(AppStrings.filterAll, _Filter.all),
          _segment(AppStrings.income, _Filter.income),
          _segment(AppStrings.expenses, _Filter.expense),
        ],
      ),
    );
  }

  Widget _segment(String label, _Filter filter) {
    final selected = _filter == filter;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- body ----------

  Widget _message(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
    child: Center(child: child),
  );

  Widget _body(bool compact) {
    switch (widget.status) {
      case TransactionsStatus.loading:
        return _message(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(width: 10),
              Text(
                AppStrings.transactionsLoading,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        );

      case TransactionsStatus.error:
        return _message(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.transactionsError,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: AppStrings.retry,
                icon: Icons.refresh,
                onPressed: widget.onRetry,
              ),
            ],
          ),
        );

      case TransactionsStatus.loaded:
        if (widget.operations.isEmpty) {
          return _message(
            const Text(
              AppStrings.transactionsEmpty,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }
        final rows = _visible;
        if (rows.isEmpty) {
          return _message(
            const Text(
              AppStrings.transactionsNoMatch,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: [
            if (!compact) _tableHeader(),
            for (var i = 0; i < rows.length; i++) ...[
              _row(rows[i], compact),
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          ],
        );
    }
  }

  // Column widths shared by the header and the rows.
  static const _flexDescription = 50;
  static const _flexCategory = 19;
  static const _flexDate = 14;
  static const _flexAmount = 17;

  Widget _tableHeader() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: _flexDescription,
            child: Text(AppStrings.colDescription, style: style),
          ),
          Expanded(
            flex: _flexCategory,
            child: Text(AppStrings.colCategory, style: style),
          ),
          Expanded(
            flex: _flexDate,
            child: Text(AppStrings.colDate, style: style),
          ),
          Expanded(
            flex: _flexAmount,
            child: Text(
              AppStrings.colAmount,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Operation o, bool compact) {
    final category = _categoryOf(o);
    final amountText = Text(
      '${formatSigned(o.isIncome ? o.amount : -o.amount)} ${widget.currency}',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: o.isIncome ? AppColors.income : AppColors.expense,
      ),
    );
    final title = HighlightedText(
      text: _titleOf(o),
      query: _query,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );

    if (compact) {
      final details = [
        if (category != null) category.name,
        _dateFormat.format(o.date),
      ].join(' · ');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            _ArrowBadge(income: o.isIncome),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            amountText,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: _flexDescription,
            child: Row(
              children: [
                _ArrowBadge(income: o.isIncome),
                const SizedBox(width: 14),
                Expanded(child: title),
              ],
            ),
          ),
          Expanded(
            flex: _flexCategory,
            child: Align(
              alignment: Alignment.centerLeft,
              child: category == null
                  ? const Text(
                      '—',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  : _CategoryChip(category: category, query: _query),
            ),
          ),
          Expanded(
            flex: _flexDate,
            child: Text(
              _dateFormat.format(o.date),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: _flexAmount,
            child: Align(alignment: Alignment.centerRight, child: amountText),
          ),
        ],
      ),
    );
  }
}

class _ArrowBadge extends StatelessWidget {
  final bool income;
  const _ArrowBadge({required this.income});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: income ? AppColors.incomeTile : AppColors.expenseTile,
        shape: BoxShape.circle,
      ),
      child: Icon(
        income ? Icons.south_west : Icons.north_east,
        size: 16,
        color: income ? AppColors.income : AppColors.expense,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final String query;
  const _CategoryChip({required this.category, required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiIcon(emoji: category.icon, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: HighlightedText(
              text: category.name,
              query: query,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
