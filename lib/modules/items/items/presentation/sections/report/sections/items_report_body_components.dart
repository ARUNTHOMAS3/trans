part of '../items_report_body.dart';

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? trailingIcon;

  const _MenuRow({required this.icon, required this.label, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (trailingIcon != null) ...[
          const SizedBox(width: 6),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );
  }
}

class _TransactionChip extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _TransactionChip({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: 'New Transaction',
        elevation: 8,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        offset: const Offset(0, 36),
        onSelected: onSelected,
        itemBuilder: (menuContext) => [
          PopupMenuItem<String>(
            value: 'sales',
            enabled: false,
            padding: EdgeInsets.zero,
            child: _HoverableMenuItem(
              label: 'Sales Order',
              onTap: () => Navigator.pop(menuContext, 'sales'),
              rounded: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          PopupMenuItem<String>(
            value: 'purchase',
            enabled: false,
            padding: EdgeInsets.zero,
            child: _HoverableMenuItem(
              label: 'Purchase Order',
              onTap: () => Navigator.pop(menuContext, 'purchase'),
              rounded: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
          ),
        ],
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'New Transaction',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Color.fromARGB(255, 10, 10, 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionOverflowChip extends StatelessWidget {
  final ValueChanged<_SelectionOverflowAction> onSelected;

  const _SelectionOverflowChip({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<_SelectionOverflowAction>(
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        offset: const Offset(0, 36),
        onSelected: onSelected,
        itemBuilder: (menuContext) => [
          PopupMenuItem<_SelectionOverflowAction>(
            value: _SelectionOverflowAction.disableBin,
            enabled: false,
            padding: EdgeInsets.zero,
            child: _HoverableMenuItem(
              label: 'Disable Bin location',
              rounded: const BorderRadius.vertical(top: Radius.circular(8)),
              onTap: () => Navigator.pop(
                menuContext,
                _SelectionOverflowAction.disableBin,
              ),
            ),
          ),
          PopupMenuItem<_SelectionOverflowAction>(
            value: _SelectionOverflowAction.delete,
            enabled: false,
            padding: EdgeInsets.zero,
            child: _HoverableMenuItem(
              label: 'Delete',
              rounded: const BorderRadius.vertical(bottom: Radius.circular(8)),
              onTap: () =>
                  Navigator.pop(menuContext, _SelectionOverflowAction.delete),
            ),
          ),
        ],
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(Icons.more_horiz, size: 18, color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SelectionChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverableMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final BorderRadius rounded;

  const _HoverableMenuItem({
    required this.label,
    required this.onTap,
    this.rounded = BorderRadius.zero,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isHovered = _hovering;
    final Color bg = isHovered ? AppTheme.primaryBlueDark : Colors.white;
    final Color textColor = isHovered ? Colors.white : AppTheme.textPrimary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: widget.rounded,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: bg, borderRadius: widget.rounded),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHovered ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

extension _ItemsReportBodyFooter on _ItemsReportBodyState {
  Widget _buildTableFooter({
    required int totalItems,
    required int rangeStart,
    required int rangeEnd,
    required bool isSinglePage,
    VoidCallback? onPrevPage,
    VoidCallback? onNextPage,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Text(
            'Total Count: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSubtle,
            ),
          ),
          Text(
            '$totalItems',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            key: _paginationKey,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _showPaginationMenu,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ref.read(itemsPerPageProvider)} per page',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSubtle,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 28, color: AppTheme.borderColor),
                IconButton(
                  onPressed: onPrevPage,
                  icon: Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: onPrevPage != null
                        ? AppTheme.textSubtle
                        : AppTheme.textMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '$rangeStart - $rangeEnd',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSubtle,
                  ),
                ),
                IconButton(
                  onPressed: onNextPage,
                  icon: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: onNextPage != null
                        ? AppTheme.textSubtle
                        : AppTheme.textMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
