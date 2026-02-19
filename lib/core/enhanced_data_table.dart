import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/ui_helper.dart';

/// Enhanced data table with sorting, filtering, and pagination
class EnhancedDataTable<T> extends StatefulWidget {
  final List<T> data;
  final List<DataColumn> columns;
  final Function(T) onRowTap;
  final Function(List<T>)? onSelectionChanged;
  final bool showCheckboxColumn;
  final Widget Function(T)? rowBuilder;
  final Function(T, int)? getSortValue;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool)? onSort;
  final int? rowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final Widget? emptyWidget;

  const EnhancedDataTable({
    Key? key,
    required this.data,
    required this.columns,
    this.onRowTap,
    this.onSelectionChanged,
    this.showCheckboxColumn = false,
    this.rowBuilder,
    this.getSortValue,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.rowsPerPage,
    this.onRowsPerPageChanged,
    this.emptyWidget,
  }) : super(key: key);

  @override
  State<EnhancedDataTable<T>> createState() => _EnhancedDataTableState<T>();
}

class _EnhancedDataTableState<T> extends State<EnhancedDataTable<T>> {
  late List<T> _sortedData;
  int _currentPage = 0;
  int _rowsPerPage = 10;
  final Set<T> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage ?? 10;
    _sortedData = _getSortedData();
  }

  @override
  void didUpdateWidget(EnhancedDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _sortedData = _getSortedData();
    }
  }

  List<T> _getSortedData() {
    if (widget.getSortValue == null || widget.sortColumnIndex == null) {
      return widget.data;
    }

    final sortedList = List<T>.from(widget.data);
    sortedList.sort((a, b) {
      final aValue = widget.getSortValue!(a, widget.sortColumnIndex!);
      final bValue = widget.getSortValue!(b, widget.sortColumnIndex!);
      
      if (widget.sortAscending) {
        return Comparable.compare(aValue, bValue);
      } else {
        return Comparable.compare(bValue, aValue);
      }
    });
    
    return sortedList;
  }

  List<T> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _sortedData.length);
    return _sortedData.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_sortedData.length / _rowsPerPage).ceil();

  void _handleSort(int columnIndex) {
    widget.onSort?.call(columnIndex, columnIndex == widget.sortColumnIndex ? !widget.sortAscending : true);
  }

  void _handleSelectionChanged(bool selected, T item) {
    setState(() {
      if (selected) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  void _handleRowTap(T item) {
    widget.onRowTap(item);
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedData.isEmpty) {
      return widget.emptyWidget ?? _buildEmptyState();
    }

    return Column(
      children: [
        _buildTableHeader(),
        Expanded(child: _buildTableBody()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: AppConstants.largeIconSize * 2, color: Colors.grey),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No data available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: AppConstants.headline5Size,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_sortedData.length} items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (widget.onRowsPerPageChanged != null) ...[
            SizedBox(width: AppConstants.defaultSpacing),
            DropdownButton<int>(
              value: _rowsPerPage,
              items: [10, 25, 50, 100].map((count) {
                return DropdownMenuItem(
                  value: count,
                  child: Text('$count per page'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _rowsPerPage = value!;
                    _currentPage = 0;
                  });
                  widget.onRowsPerPageChanged?.call(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    return Card(
      margin: EdgeInsets.all(AppConstants.smallPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: widget.columns,
          rows: _paginatedData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedItems.contains(item);
            
            return DataRow(
              selected: isSelected,
              onSelectChanged: widget.showCheckboxColumn ? (selected) => _handleSelectionChanged(selected!, item) : null,
              cells: widget.columns.asMap().entries.map((columnEntry) {
                final columnIndex = columnEntry.key;
                final column = columnEntry.value;
                
                return DataCell(
                  widget.rowBuilder?.call(item) ?? _buildDefaultCell(item, columnIndex),
                  onTap: () => _handleRowTap(item),
                );
              }).toList(),
            );
          }).toList(),
          sortColumnIndex: widget.sortColumnIndex,
          sortAscending: widget.sortAscending,
        ),
      ),
    );
  }

  Widget _buildDefaultCell(T item, int columnIndex) {
    // Default cell implementation - can be overridden by rowBuilder
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        item.toString(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
            tooltip: 'First Page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            tooltip: 'Previous Page',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_currentPage + 1} of $_totalPages',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
            tooltip: 'Next Page',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null,
            tooltip: 'Last Page',
          ),
        ],
      ),
    );
  }
}
