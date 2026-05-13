import 'package:equatable/equatable.dart';
import 'pricelist_model.dart';

class PriceListPagination extends Equatable {
  final List<PriceList> items;
  final int totalCount;
  final int page;
  final int limit;

  const PriceListPagination({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
  });

  @override
  List<Object?> get props => [items, totalCount, page, limit];
}
