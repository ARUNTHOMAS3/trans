import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/repositories/customers_repository.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository();
});

final customersProvider = FutureProvider<List<SalesCustomer>>((ref) async {
  final repo = ref.watch(customersRepositoryProvider);
  return repo.getCustomers();
});
