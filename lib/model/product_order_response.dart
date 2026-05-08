import 'package:nb_utils/nb_utils.dart';

class ProductOrderListResponse {
  final bool status;
  final ProductOrderPagination pagination;
  final List<ProductOrderData> data;

  ProductOrderListResponse({
    required this.status,
    required this.pagination,
    required this.data,
  });

  factory ProductOrderListResponse.fromJson(Map<String, dynamic> json) {
    return ProductOrderListResponse(
      status: _parseBool(json['status']),
      pagination: ProductOrderPagination.fromJson(
        (json['pagination'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      data: (json['data'] as List? ?? [])
          .map((e) =>
              ProductOrderData.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ProductOrderDetailResponse {
  final bool status;
  final ProductOrderData? data;

  ProductOrderDetailResponse({
    required this.status,
    required this.data,
  });

  factory ProductOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductOrderDetailResponse(
      status: _parseBool(json['status']),
      data: json['data'] is Map
          ? ProductOrderData.fromJson(
              (json['data'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class ProductOrderPagination {
  final int totalItems;
  final int perPage;
  final int currentPage;
  final int totalPages;
  final int from;
  final int to;

  ProductOrderPagination({
    required this.totalItems,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
    required this.from,
    required this.to,
  });

  factory ProductOrderPagination.fromJson(Map<String, dynamic> json) {
    return ProductOrderPagination(
      totalItems: (json['total_items'] ?? 0).toString().toInt(),
      perPage: (json['per_page'] ?? 0).toString().toInt(),
      currentPage: (json['currentPage'] ?? 0).toString().toInt(),
      totalPages: (json['totalPages'] ?? 0).toString().toInt(),
      from: (json['from'] ?? 0).toString().toInt(),
      to: (json['to'] ?? 0).toString().toInt(),
    );
  }
}

class ProductOrderData {
  final int id;
  final String orderNumber;
  final String orderDate;
  final String createdAt;
  final String status;
  final String paymentType;
  final String paymentStatus;
  final String txnId;
  final int itemsCount;
  final num subtotal;
  final String subtotalFormat;
  final num taxTotal;
  final String taxTotalFormat;
  final num total;
  final String totalFormat;
  final String detailUrl;
  final ProductOrderShipping? shipping;
  final List<ProductOrderItem> items;

  ProductOrderData({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.createdAt,
    required this.status,
    required this.paymentType,
    required this.paymentStatus,
    required this.txnId,
    required this.itemsCount,
    required this.subtotal,
    required this.subtotalFormat,
    required this.taxTotal,
    required this.taxTotalFormat,
    required this.total,
    required this.totalFormat,
    required this.detailUrl,
    required this.shipping,
    required this.items,
  });

  factory ProductOrderData.fromJson(Map<String, dynamic> json) {
    return ProductOrderData(
      id: (json['id'] ?? 0).toString().toInt(),
      orderNumber: (json['order_number'] ?? '').toString(),
      orderDate: (json['order_date'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      txnId: (json['txn_id'] ?? '').toString(),
      itemsCount: (json['items_count'] ?? 0).toString().toInt(),
      subtotal: _parseNum(json['subtotal']),
      subtotalFormat: (json['subtotal_format'] ?? '').toString(),
      taxTotal: _parseNum(json['tax_total']),
      taxTotalFormat: (json['tax_total_format'] ?? '').toString(),
      total: _parseNum(json['total']),
      totalFormat: (json['total_format'] ?? '').toString(),
      detailUrl: (json['detail_url'] ?? '').toString(),
      shipping: json['shipping'] is Map
          ? ProductOrderShipping.fromJson(
              (json['shipping'] as Map).cast<String, dynamic>(),
            )
          : null,
      items: (json['items'] as List? ?? [])
          .map((e) =>
              ProductOrderItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ProductOrderShipping {
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;

  ProductOrderShipping({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
  });

  factory ProductOrderShipping.fromJson(Map<String, dynamic> json) {
    return ProductOrderShipping(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
    );
  }
}

class ProductOrderItem {
  final int id;
  final int productId;
  final int? productVariantId;
  final String productName;
  final String variantLabel;
  final num unitPrice;
  final String unitPriceFormat;
  final int quantity;
  final num lineTotal;
  final String lineTotalFormat;
  final ProductOrderProduct? product;

  ProductOrderItem({
    required this.id,
    required this.productId,
    required this.productVariantId,
    required this.productName,
    required this.variantLabel,
    required this.unitPrice,
    required this.unitPriceFormat,
    required this.quantity,
    required this.lineTotal,
    required this.lineTotalFormat,
    required this.product,
  });

  factory ProductOrderItem.fromJson(Map<String, dynamic> json) {
    return ProductOrderItem(
      id: (json['id'] ?? 0).toString().toInt(),
      productId: (json['product_id'] ?? 0).toString().toInt(),
      productVariantId: _parseNullableInt(json['product_variant_id']),
      productName: (json['product_name'] ?? '').toString(),
      variantLabel: (json['variant_label'] ?? '').toString(),
      unitPrice: _parseNum(json['unit_price']),
      unitPriceFormat: (json['unit_price_format'] ?? '').toString(),
      quantity: (json['quantity'] ?? 0).toString().toInt(),
      lineTotal: _parseNum(json['line_total']),
      lineTotalFormat: (json['line_total_format'] ?? '').toString(),
      product: json['product'] is Map
          ? ProductOrderProduct.fromJson(
              (json['product'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class ProductOrderProduct {
  final int id;
  final String name;
  final String slug;
  final String image;
  final String detailUrl;

  ProductOrderProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    required this.detailUrl,
  });

  factory ProductOrderProduct.fromJson(Map<String, dynamic> json) {
    return ProductOrderProduct(
      id: (json['id'] ?? 0).toString().toInt(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      detailUrl: (json['detail_url'] ?? '').toString(),
    );
  }
}

num _parseNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}
