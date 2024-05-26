import 'package:flutter/material.dart';

class FilterList<T> extends StatelessWidget {
  const FilterList({
    required this.title,
    required this.selectedFilters,
    required this.filters,
    required this.filterNameBuilder,
    required this.onSelected,
    super.key,
  });

  final Widget title;
  final Set<T> selectedFilters;
  final List<T> filters;
  final String Function(T filter) filterNameBuilder;
  final void Function(T filter, bool selected)? onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DefaultTextStyle(
            style: textTheme.bodyMedium!,
            child: title,
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];

              return FilterChip(
                label: Text(filterNameBuilder(filter)),
                labelStyle: textTheme.labelMedium,
                selected: selectedFilters.contains(filter),
                onSelected: onSelected == null
                    ? null
                    : (value) => onSelected!(filter, value),
              );
            },
          ),
        ),
      ],
    );
  }
}
