import '../datasources/customer_api_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final CustomerApiDatasource _datasource;

  CustomerRepository(this._datasource);

  Future<List<CustomerModel>> getCustomers({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) {
    return _datasource.getCustomers(
      page: page,
      pageSize: pageSize,
      search: search,
      isActive: isActive,
    );
  }

  Future<CustomerModel> getCustomer(String uuid) {
    return _datasource.getCustomer(uuid);
  }

  Future<CustomerModel> createCustomer(CustomerCreateRequest request) {
    return _datasource.createCustomer(request);
  }

  Future<CustomerModel> updateCustomer(
    String uuid,
    CustomerUpdateRequest request,
  ) {
    return _datasource.updateCustomer(uuid, request);
  }

  Future<void> deleteCustomer(String uuid) {
    return _datasource.deleteCustomer(uuid);
  }
}
