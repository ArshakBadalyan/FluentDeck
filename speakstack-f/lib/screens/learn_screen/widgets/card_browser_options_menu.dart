import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/utils/card_browser_utils.dart';

/// Browser state shown in menu labels (checkmarks / subtitles).
class CardBrowserOptionsState {
  final bool markedFilter;
  final bool suspendedFilter;
  final bool selectMode;
  final int? flagFilter;
  final String sortLabel;
  final int visibleCount;

  const CardBrowserOptionsState({
    this.markedFilter = false,
    this.suspendedFilter = false,
    this.selectMode = false,
    this.flagFilter,
    this.sortLabel = 'Question',
    this.visibleCount = 0,
  });
}

/// AnkiDroid-style card browser overflow menu (Step 2 parity).
class CardBrowserOptionsMenu {
  static Future<T?> _showSheet<T>(
    BuildContext context, {
    required Widget Function(BuildContext sheetContext) builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: builder,
    );
  }

  static Widget _sheetShell({
    required BuildContext sheetContext,
    required String title,
    String? trailing,
    required List<Widget> children,
  }) {
    final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;

    return Material(
      color: Colors.white,
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool enabled = true,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required CardBrowserOptionsState state,
    required VoidCallback onChangeDisplayOrder,
    required VoidCallback onFilterMarked,
    required VoidCallback onFilterSuspended,
    required VoidCallback onFilterByTag,
    required Future<void> Function(int? flag) onApplyFlagFilter,
    required VoidCallback onPreview,
    required VoidCallback onSelectAll,
    required VoidCallback onToggleSelectMode,
    required VoidCallback onCreateFilteredDeck,
    required VoidCallback onClearFilters,
    required VoidCallback onRefresh,
  }) async {
    final action = await _showSheet<String>(
      context,
      builder:
          (sheetContext) => _sheetShell(
            sheetContext: sheetContext,
            title: 'Options',
            trailing: '${state.visibleCount} card${state.visibleCount == 1 ? '' : 's'}',
            children: [
              _menuTile(
                icon: Icons.sort,
                title: 'Change display order',
                subtitle: state.sortLabel,
                onTap: () => Navigator.pop(sheetContext, 'sort'),
              ),
              _menuTile(
                icon: Icons.bookmark_outline,
                title: 'Filter marked',
                trailing:
                    state.markedFilter
                        ? Icon(Icons.check, color: AppColors.primaryPurple)
                        : null,
                onTap: () => Navigator.pop(sheetContext, 'filter_marked'),
              ),
              _menuTile(
                icon: Icons.pause_circle_outline,
                title: 'Filter suspended',
                trailing:
                    state.suspendedFilter
                        ? Icon(Icons.check, color: AppColors.primaryPurple)
                        : null,
                onTap: () => Navigator.pop(sheetContext, 'filter_suspended'),
              ),
              _menuTile(
                icon: Icons.label_outline,
                title: 'Filter by tag',
                onTap: () => Navigator.pop(sheetContext, 'filter_tag'),
              ),
              _menuTile(
                icon: Icons.flag_outlined,
                title: 'Filter by flag',
                iconColor: state.flagFilter != null ? AppColors.primaryPurple : null,
                subtitle:
                    state.flagFilter == null
                        ? null
                        : state.flagFilter == 0
                        ? 'No flag'
                        : 'Flag ${state.flagFilter}',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, 'filter_flag'),
              ),
              _menuTile(
                icon: Icons.visibility_outlined,
                title: 'Preview',
                subtitle: 'Preview first card in list',
                onTap: () => Navigator.pop(sheetContext, 'preview'),
              ),
              _menuTile(
                icon: state.selectMode ? Icons.close : Icons.checklist,
                title: state.selectMode ? 'Exit select mode' : 'Select cards',
                onTap: () => Navigator.pop(sheetContext, 'toggle_select'),
              ),
              _menuTile(
                icon: Icons.select_all,
                title: 'Select all',
                enabled: state.visibleCount > 0,
                onTap: () => Navigator.pop(sheetContext, 'select_all'),
              ),
              _menuTile(
                icon: Icons.filter_list,
                title: 'Create filtered deck',
                subtitle: 'Save current search as a study deck',
                onTap: () => Navigator.pop(sheetContext, 'filtered_deck'),
              ),
              _menuTile(
                icon: Icons.tune,
                title: 'Browser options',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, 'browser_options'),
              ),
            ],
          ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'sort':
        onChangeDisplayOrder();
      case 'filter_marked':
        onFilterMarked();
      case 'filter_suspended':
        onFilterSuspended();
      case 'filter_tag':
        onFilterByTag();
      case 'filter_flag':
        await _showFlagFilterSheet(
          context,
          current: state.flagFilter,
          onApply: onApplyFlagFilter,
        );
      case 'preview':
        onPreview();
      case 'toggle_select':
        onToggleSelectMode();
      case 'select_all':
        onSelectAll();
      case 'filtered_deck':
        onCreateFilteredDeck();
      case 'browser_options':
        await _showBrowserOptionsSheet(
          context,
          onClearFilters: onClearFilters,
          onRefresh: onRefresh,
        );
    }
  }

  static Future<void> _showFlagFilterSheet(
    BuildContext context, {
    required int? current,
    required Future<void> Function(int? flag) onApply,
  }) async {
    final value = await _showSheet<int?>(
      context,
      builder:
          (sheetContext) => _sheetShell(
            sheetContext: sheetContext,
            title: 'Filter by flag',
            children: [
              _menuTile(
                icon: Icons.flag_outlined,
                title: 'Any flag',
                trailing:
                    current == null ? Icon(Icons.check, color: AppColors.primaryPurple) : null,
                onTap: () => Navigator.pop(sheetContext, -1),
              ),
              _menuTile(
                icon: Icons.outlined_flag,
                title: 'No flag',
                trailing: current == 0 ? Icon(Icons.check, color: AppColors.primaryPurple) : null,
                onTap: () => Navigator.pop(sheetContext, 0),
              ),
              for (final e in flagColors.entries)
                _menuTile(
                  icon: Icons.flag,
                  iconColor: e.value,
                  title: 'Flag ${e.key}',
                  trailing:
                      current == e.key
                          ? Icon(Icons.check, color: AppColors.primaryPurple)
                          : null,
                  onTap: () => Navigator.pop(sheetContext, e.key),
                ),
            ],
          ),
    );

    if (!context.mounted) return;
    if (value == null) return;
    await onApply(value == -1 ? null : value);
  }

  static Future<void> _showBrowserOptionsSheet(
    BuildContext context, {
    required VoidCallback onClearFilters,
    required VoidCallback onRefresh,
  }) async {
    final action = await _showSheet<String>(
      context,
      builder:
          (sheetContext) => _sheetShell(
            sheetContext: sheetContext,
            title: 'Browser options',
            children: [
              _menuTile(
                icon: Icons.filter_alt_off_outlined,
                title: 'Clear all filters',
                onTap: () => Navigator.pop(sheetContext, 'clear'),
              ),
              _menuTile(
                icon: Icons.refresh,
                title: 'Refresh',
                onTap: () => Navigator.pop(sheetContext, 'refresh'),
              ),
            ],
          ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'clear':
        onClearFilters();
      case 'refresh':
        onRefresh();
    }
  }

  /// Anki-style sort picker: field + ascending/descending/default.
  static Future<({CardBrowserSortField? field, CardBrowserSortDir? dir})?> showDisplayOrderSheet(
    BuildContext context, {
    required CardBrowserSortField? currentField,
    required CardBrowserSortDir? currentDir,
    required String Function(CardBrowserSortField) fieldLabel,
  }) async {
    return _showSheet<({CardBrowserSortField? field, CardBrowserSortDir? dir})>(
      context,
      builder:
          (sheetContext) => _sheetShell(
            sheetContext: sheetContext,
            title: 'Change display order',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Sort field',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              for (final field in CardBrowserSortField.values)
                _menuTile(
                  icon: Icons.sort_by_alpha,
                  title: fieldLabel(field),
                  trailing:
                      currentField == field && currentDir != null
                          ? Icon(Icons.check, color: AppColors.primaryPurple)
                          : null,
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      (field: field, dir: currentDir ?? CardBrowserSortDir.asc),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Direction',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              _menuTile(
                icon: Icons.restart_alt,
                title: 'Default (no sort)',
                trailing:
                    currentField == null || currentDir == null
                        ? Icon(Icons.check, color: AppColors.primaryPurple)
                        : null,
                onTap: () => Navigator.pop(sheetContext, (field: null, dir: null)),
              ),
              _menuTile(
                icon: Icons.arrow_upward,
                title: 'Ascending',
                trailing:
                    currentDir == CardBrowserSortDir.asc
                        ? Icon(Icons.check, color: AppColors.primaryPurple)
                        : null,
                onTap: () => Navigator.pop(
                  sheetContext,
                  (field: currentField ?? CardBrowserSortField.front, dir: CardBrowserSortDir.asc),
                ),
              ),
              _menuTile(
                icon: Icons.arrow_downward,
                title: 'Descending',
                trailing:
                    currentDir == CardBrowserSortDir.desc
                        ? Icon(Icons.check, color: AppColors.primaryPurple)
                        : null,
                onTap: () => Navigator.pop(
                  sheetContext,
                  (field: currentField ?? CardBrowserSortField.front, dir: CardBrowserSortDir.desc),
                ),
              ),
            ],
          ),
    );
  }
}
