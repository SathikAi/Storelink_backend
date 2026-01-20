import '../datasources/order_api_datasource.dart';
import '../models/order_model.dart';

class OrderRepository {
  final OrderApiDatasource _datasource;

  OrderRepository(this._datasource);

  Future<List<OrderModel>> getOrders({
    int page = 1,
    int pageSize = 50,
    String? customerUuid,
    String? status,
    String? paymentStatus,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _datasource.getOrders(
      page: page,
      pageSize: pageSize,
      customerUuid: customerUuid,
      status: status,
      paymentStatus: paymentStatus,
      search: search,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<OrderModel> getOrder(String uuid) {
    return _datasource.getOrder(uuid);
  }

  Future<OrderModel> createOrder(OrderCreateRequest request) {
    return _datasource.createOrder(request);
  }

  Future<OrderModel> updateOrder(
    String uuid,
    OrderUpdateRequest request,
  ) {
    return _datasource.updateOrder(uuid, request);
  }

  Future<OrderModel> cancelOrder(String uuid) {
    return _datasource.cancelOrder(uuid);
  }

  Future<void> deleteOrder(String uuid) {
    return _datasource.deleteOrder(uuid);
  }
}
