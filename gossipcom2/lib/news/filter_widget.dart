import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/news/filter_model.dart';

class FilterWidget extends StatefulWidget {
  final FilterModel currentFilters;
  final Function(FilterModel) onFiltersChanged;
  final VoidCallback? onClearAll;
  final VoidCallback? onApply;

  const FilterWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
    this.onClearAll,
    this.onApply,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FilterModel _tempFilters = const FilterModel();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tempFilters = widget.currentFilters;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter News',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempFilters = const FilterModel();
                        });
                        widget.onClearAll?.call();
                      },
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onFiltersChanged(_tempFilters);
                        widget.onApply?.call();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1976D2),
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Date'),
              Tab(text: 'Source'),
              Tab(text: 'More'),
            ],
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildDateTab(),
                _buildSourceTab(),
                _buildMoreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Categories'),
          const SizedBox(height: 12),
          _buildChipList(
            FilterOptions.categories,
            _tempFilters.categories,
            (selected) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(categories: selected);
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Regions'),
          const SizedBox(height: 12),
          _buildChipList(
            FilterOptions.regions,
            _tempFilters.regions,
            (selected) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(regions: selected);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Publish Date'),
          const SizedBox(height: 12),
          ...PublishDateFilter.values.map((filter) {
            return RadioListTile<PublishDateFilter>(
              title: Text(
                _getDateFilterLabel(filter),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              value: filter,
              groupValue: _tempFilters.publishDate,
              onChanged: (value) {
                setState(() {
                  _tempFilters = _tempFilters.copyWith(publishDate: value);
                });
              },
            );
          }),
          if (_tempFilters.publishDate == PublishDateFilter.custom) ...[
            const SizedBox(height: 16),
            _buildDateRangePicker(),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sources'),
          const SizedBox(height: 12),
          _buildChipList(
            FilterOptions.commonSources,
            _tempFilters.sources,
            (selected) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(sources: selected);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Languages'),
          const SizedBox(height: 12),
          _buildChipList(
            FilterOptions.languages,
            _tempFilters.languages,
            (selected) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(languages: selected);
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('News Type'),
          const SizedBox(height: 12),
          _buildChipList(
            FilterOptions.newsTypes,
            _tempFilters.newsTypes,
            (selected) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(newsTypes: selected);
              });
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text(
              'Trending',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            subtitle: Text(
              'Show trending news instead of latest',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            value: _tempFilters.isTrending,
            onChanged: (value) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(isTrending: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildChipList(
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(
            option,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          selected: isSelected,
          onSelected: (bool isSelected) {
            final newSelection = List<String>.from(selected);
            if (isSelected) {
              newSelection.add(option);
            } else {
              newSelection.remove(option);
            }
            onChanged(newSelection);
          },
          selectedColor: const Color(0xFF1976D2),
          checkmarkColor: Colors.white,
          backgroundColor: Colors.grey.shade200,
        );
      }).toList(),
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      children: [
        ListTile(
          title: Text(
            'Start Date',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            _tempFilters.customStartDate?.toString().split(' ')[0] ?? 'Select start date',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _tempFilters.customStartDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(customStartDate: date);
              });
            }
          },
        ),
        ListTile(
          title: Text(
            'End Date',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            _tempFilters.customEndDate?.toString().split(' ')[0] ?? 'Select end date',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _tempFilters.customEndDate ?? DateTime.now(),
              firstDate: _tempFilters.customStartDate ?? DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(customEndDate: date);
              });
            }
          },
        ),
      ],
    );
  }

  String _getDateFilterLabel(PublishDateFilter filter) {
    switch (filter) {
      case PublishDateFilter.all:
        return 'All Time';
      case PublishDateFilter.today:
        return 'Today';
      case PublishDateFilter.last24Hours:
        return 'Last 24 Hours';
      case PublishDateFilter.thisWeek:
        return 'This Week';
      case PublishDateFilter.custom:
        return 'Custom Range';
    }
  }
}
