import 'package:equatable/equatable.dart';
import 'branch_pricelist_model.dart';

class BranchPriceListPagination extends Equatable {
  final List<BranchPriceList> items;
  final int totalCount;
  final int page;
  final int limit;

  const BranchPriceListPagination({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
  });

  @override
  List<Object?> get props => [items, totalCount, page, limit];
}






