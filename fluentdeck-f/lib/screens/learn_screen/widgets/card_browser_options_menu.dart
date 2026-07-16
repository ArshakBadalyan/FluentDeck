import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/card_browser_utils.dart';

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

/// Card browser overflow menu.
class CardBrowserOptionsMenu {
  static Widget _checkTrailing(bool active) {
    if (!active) return const SizedBox.shrink();
    return const Icon(Icons.check_rounded, color: AppColors.primaryPurple, size: 22);
  }

  static Future<T?> _showSheet<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.tune_rounded,
    required List<Widget> children,
    double initialSize = 0.62,
    double minSize = 0.38,
    double maxSize = 0.82,
  }) {
    return showFrostedBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                AppSheetHeader(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: children,
                  ),
                ),
              ],
            );
          },
        );
      },
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
    final cardLabel = '${state.visibleCount} card${state.visibleCount == 1 ? '' : 's'}';
    final action = await _showSheet<String>(
      context,
      title: 'Options',
      subtitle: cardLabel,
      icon: Icons.tune_rounded,
      initialSize: 0.68,
      maxSize: 0.88,
      children: [
        AppSheetActionTile(
          icon: Icons.sort_rounded,
          title: 'Change display order',
          subtitle: state.sortLabel,
          onTap: () => Navigator.pop(context, 'sort'),
        ),
        AppSheetActionTile(
          icon: Icons.bookmark_outline_rounded,
          title: 'Filter marked',
          trailing: _checkTrailing(state.markedFilter),
          showChevron: false,
          onTap: () => Navigator.pop(context, 'filter_marked'),
        ),
        AppSheetActionTile(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Filter suspended',
          trailing: _checkTrailing(state.suspendedFilter),
          showChevron: false,
          onTap: () => Navigator.pop(context, 'filter_suspended'),
        ),
        AppSheetActionTile(
          icon: Icons.label_outline_rounded,
          title: 'Filter by tag',
          onTap: () => Navigator.pop(context, 'filter_tag'),
        ),
        AppSheetActionTile(
          icon: Icons.flag_outlined,
          title: 'Filter by flag',
          iconColor: state.flagFilter != null ? AppColors.primaryPurple : null,
          subtitle:
              state.flagFilter == null
                  ? null
                  : state.flagFilter == 0
                  ? 'No flag'
                  : 'Flag ${state.flagFilter}',
          onTap: () => Navigator.pop(context, 'filter_flag'),
        ),
        AppSheetActionTile(
          icon: Icons.visibility_outlined,
          title: 'Preview',
          subtitle: 'Preview first card in list',
          onTap: () => Navigator.pop(context, 'preview'),
        ),
        AppSheetActionTile(
          icon: state.selectMode ? Icons.close_rounded : Icons.checklist_rounded,
          title: state.selectMode ? 'Exit select mode' : 'Select cards',
          onTap: () => Navigator.pop(context, 'toggle_select'),
        ),
        AppSheetActionTile(
          icon: Icons.select_all_rounded,
          title: 'Select all',
          enabled: state.visibleCount > 0,
          showChevron: false,
          onTap: () => Navigator.pop(context, 'select_all'),
        ),
        AppSheetActionTile(
          icon: Icons.filter_list_rounded,
          title: 'Create filtered deck',
          subtitle: 'Save current search as a study deck',
          onTap: () => Navigator.pop(context, 'filtered_deck'),
        ),
        AppSheetActionTile(
          icon: Icons.settings_outlined,
          title: 'Browser options',
          onTap: () => Navigator.pop(context, 'browser_options'),
        ),
      ],
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
      title: 'Filter by flag',
      icon: Icons.flag_outlined,
      initialSize: 0.52,
      children: [
        AppSheetActionTile(
          icon: Icons.flag_outlined,
          title: 'Any flag',
          trailing: _checkTrailing(current == null),
          showChevron: false,
          onTap: () => Navigator.pop(context, -1),
        ),
        AppSheetActionTile(
          icon: Icons.outlined_flag,
          title: 'No flag',
          trailing: _checkTrailing(current == 0),
          showChevron: false,
          onTap: () => Navigator.pop(context, 0),
        ),
        for (final e in flagColors.entries)
          AppSheetActionTile(
            icon: Icons.flag_rounded,
            iconColor: e.value,
            title: 'Flag ${e.key}',
            trailing: _checkTrailing(current == e.key),
            showChevron: false,
            onTap: () => Navigator.pop(context, e.key),
          ),
      ],
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
      title: 'Browser options',
      icon: Icons.settings_outlined,
      initialSize: 0.42,
      children: [
        AppSheetActionTile(
          icon: Icons.filter_alt_off_outlined,
          title: 'Clear all filters',
          subtitle: 'Reset search and filter chips',
          onTap: () => Navigator.pop(context, 'clear'),
        ),
        AppSheetActionTile(
          icon: Icons.refresh_rounded,
          title: 'Refresh',
          subtitle: 'Reload cards from the server',
          onTap: () => Navigator.pop(context, 'refresh'),
        ),
      ],
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'clear':
        onClearFilters();
      case 'refresh':
        onRefresh();
    }
  }

  /// Sort picker: field + ascending/descending/default.
  static Future<({CardBrowserSortField? field, CardBrowserSortDir? dir})?> showDisplayOrderSheet(
    BuildContext context, {
    required CardBrowserSortField? currentField,
    required CardBrowserSortDir? currentDir,
    required String Function(CardBrowserSortField) fieldLabel,
  }) async {
    return _showSheet<({CardBrowserSortField? field, CardBrowserSortDir? dir})>(
      context,
      title: 'Change display order',
      subtitle: 'Pick a column and sort direction',
      icon: Icons.sort_rounded,
      initialSize: 0.62,
      maxSize: 0.88,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
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
          AppSheetActionTile(
            icon: Icons.sort_by_alpha_rounded,
            title: fieldLabel(field),
            trailing: _checkTrailing(currentField == field && currentDir != null),
            showChevron: false,
            onTap: () {
              Navigator.pop(
                context,
                (field: field, dir: currentDir ?? CardBrowserSortDir.asc),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Text(
            'Direction',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        AppSheetActionTile(
          icon: Icons.restart_alt_rounded,
          title: 'Default (no sort)',
          trailing: _checkTrailing(currentField == null || currentDir == null),
          showChevron: false,
          onTap: () => Navigator.pop(context, (field: null, dir: null)),
        ),
        AppSheetActionTile(
          icon: Icons.arrow_upward_rounded,
          title: 'Ascending',
          trailing: _checkTrailing(currentDir == CardBrowserSortDir.asc),
          showChevron: false,
          onTap:
              () => Navigator.pop(
                context,
                (field: currentField ?? CardBrowserSortField.front, dir: CardBrowserSortDir.asc),
              ),
        ),
        AppSheetActionTile(
          icon: Icons.arrow_downward_rounded,
          title: 'Descending',
          trailing: _checkTrailing(currentDir == CardBrowserSortDir.desc),
          showChevron: false,
          onTap:
              () => Navigator.pop(
                context,
                (field: currentField ?? CardBrowserSortField.front, dir: CardBrowserSortDir.desc),
              ),
        ),
      ],
    );
  }
}
