import 'package:booking_system_flutter/model/booking_detail_model.dart';
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
    final dynamic rawData = json['data'];
    final List dataList =
        rawData is List ? rawData : (rawData is Map ? [rawData] : []);

    return ProductOrderListResponse(
      status: _parseBool(json['status']),
      pagination: ProductOrderPagination.fromJson(
        (json['pagination'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      data: dataList
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

class ProductOrderLocationResponse {
  final bool status;
  final ProductOrderLocation? data;

  ProductOrderLocationResponse({
    required this.status,
    required this.data,
  });

  factory ProductOrderLocationResponse.fromJson(Map<String, dynamic> json) {
    return ProductOrderLocationResponse(
      status: _parseBool(json['status']),
      data: json['data'] is Map
          ? ProductOrderLocation.fromJson(
              (json['data'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class ProductOrderProofListResponse {
  final bool status;
  final List<ProductOrderProof> data;

  ProductOrderProofListResponse({
    required this.status,
    required this.data,
  });

  factory ProductOrderProofListResponse.fromJson(Map<String, dynamic> json) {
    return ProductOrderProofListResponse(
      status: _parseBool(json['status']),
      data: (json['data'] as List? ?? [])
          .map((e) =>
              ProductOrderProof.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
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
  final String deliveryStatus;
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
  final String productImage;
  final String detailUrl;
  final ProductOrderCustomer? customer;
  final ProductOrderContact? provider;
  final ProductOrderContact? handyman;
  final ProductOrderShipping? shipping;
  final ProductOrderLocation? latestLocation;
  final List<BookingActivity> activity;
  final List<ProductOrderProof> proof;
  final List<ProductOrderItem> items;

  ProductOrderData({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.createdAt,
    required this.status,
    required this.deliveryStatus,
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
    required this.productImage,
    required this.detailUrl,
    required this.customer,
    required this.provider,
    required this.handyman,
    required this.shipping,
    required this.latestLocation,
    required this.activity,
    required this.proof,
    required this.items,
  });

  factory ProductOrderData.fromJson(Map<String, dynamic> json) {
    final List<ProductOrderItem> orderItems = (json['items'] as List? ?? [])
        .map((e) =>
            ProductOrderItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final String firstProductImage = orderItems.isNotEmpty
        ? orderItems.first.product?.image.validate() ?? ''
        : '';
    final ProductOrderShipping? shipping = (json['shipping'] ??
            json['delivery_address'] ??
            json['notes']?['shipping']) is Map
        ? ProductOrderShipping.fromJson(
            ((json['shipping'] ??
                    json['delivery_address'] ??
                    json['notes']?['shipping']) as Map)
                .cast<String, dynamic>(),
          )
        : null;
    final ProductOrderLocation? latestLocation = _parseLocation(
            json['latest_location'] ??
                json['location'] ??
                json['delivery_location']) ??
        (shipping != null && shipping.hasLocation
            ? ProductOrderLocation(
                latitude: shipping.latitude,
                longitude: shipping.longitude,
                datetime: '',
              )
            : null);

    return ProductOrderData(
      id: (json['id'] ?? 0).toString().toInt(),
      orderNumber:
          (json['order_number'] ?? json['order_code'] ?? '').toString(),
      orderDate: (json['order_date'] ?? json['date'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['date'] ?? '').toString(),
      status: (json['status_label'] ?? json['status'] ?? '').toString(),
      deliveryStatus:
          (json['delivery_status_label'] ?? json['delivery_status'] ?? '')
              .toString(),
      paymentType:
          (json['payment_type'] ?? json['payment_method'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      txnId: (json['txn_id'] ?? '').toString(),
      itemsCount: (json['items_count'] ??
              (json['items'] is List ? (json['items'] as List).length : 0))
          .toString()
          .toInt(),
      subtotal: _parseNum(json['subtotal']),
      subtotalFormat: (json['subtotal_format'] ?? '').toString(),
      taxTotal: _parseNum(json['tax_total'] ?? json['tax']),
      taxTotalFormat:
          (json['tax_total_format'] ?? _formatAmount(json['tax'])).toString(),
      total: _parseNum(json['total'] ?? json['total_amount']),
      totalFormat: (json['total_format'] ?? json['total_amount_format'] ?? '')
          .toString(),
      productImage: (json['product_image'] ?? firstProductImage).toString(),
      detailUrl: (json['detail_url'] ?? '').toString(),
      customer: _parseCustomer(json),
      provider: _parseContact(json['provider']),
      handyman: _parseContact(json['handyman'] ?? json['delivery_boy']),
      shipping: shipping,
      latestLocation: latestLocation,
      activity: (json['activity'] as List? ?? [])
          .map((e) =>
              BookingActivity.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      proof: (json['proof'] as List? ?? [])
          .map((e) =>
              ProductOrderProof.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      items: orderItems,
    );
  }
}

class ProductOrderProof {
  final int id;
  final int orderId;
  final int userId;
  final String url;
  final String description;
  final String createdAt;

  ProductOrderProof({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.url,
    required this.description,
    required this.createdAt,
  });

  factory ProductOrderProof.fromJson(Map<String, dynamic> json) {
    return ProductOrderProof(
      id: (json['id'] ?? 0).toString().toInt(),
      orderId: (json['order_id'] ?? 0).toString().toInt(),
      userId: (json['user_id'] ?? 0).toString().toInt(),
      url: (json['url'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class ProductOrderLocation {
  final num latitude;
  final num longitude;
  final String datetime;

  ProductOrderLocation({
    required this.latitude,
    required this.longitude,
    required this.datetime,
  });

  factory ProductOrderLocation.fromJson(Map<String, dynamic> json) {
    return ProductOrderLocation(
      latitude: _parseNum(json['latitude']),
      longitude: _parseNum(json['longitude']),
      datetime: (json['datetime'] ?? json['updated_at'] ?? '').toString(),
    );
  }
}

class ProductOrderContact {
  final int id;
  final String displayName;
  final String firstName;
  final String lastName;
  final String email;
  final String contactNumber;
  final String profileImage;
  final String address;
  final String uid;
  final num rating;
  final int isVerified;

  ProductOrderContact({
    required this.id,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.contactNumber,
    required this.profileImage,
    required this.address,
    required this.uid,
    required this.rating,
    required this.isVerified,
  });

  factory ProductOrderContact.fromJson(Map<String, dynamic> json) {
    final String firstName = (json['first_name'] ?? '').toString();
    final String lastName = (json['last_name'] ?? '').toString();
    final String fullName = [firstName, lastName]
        .where((element) => element.trim().isNotEmpty)
        .join(' ');

    return ProductOrderContact(
      id: (json['id'] ?? 0).toString().toInt(),
      displayName:
          (json['display_name'] ?? json['name'] ?? fullName).toString(),
      firstName: firstName,
      lastName: lastName,
      email: (json['email'] ?? '').toString(),
      contactNumber: (json['contact_number'] ??
              json['phone_number'] ??
              json['mobile'] ??
              json['contact'] ??
              '')
          .toString(),
      profileImage: (json['profile_image'] ??
              json['profileImage'] ??
              json['avatar'] ??
              json['image'] ??
              '')
          .toString(),
      address: (json['address'] ?? '').toString(),
      uid: (json['uid'] ?? '').toString(),
      rating: _parseNum(json['providers_service_rating'] ??
          json['handyman_rating'] ??
          json['rating']),
      isVerified: (json['is_verify_provider'] ?? json['is_verified'] ?? 0)
          .toString()
          .toInt(),
    );
  }
}

class ProductOrderCustomer {
  final int id;
  final String name;
  final String email;
  final String contactNumber;
  final String profileImage;
  final String address;

  ProductOrderCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.profileImage,
    required this.address,
  });

  factory ProductOrderCustomer.fromJson(Map<String, dynamic> json) {
    final String firstName = (json['first_name'] ?? '').toString();
    final String lastName = (json['last_name'] ?? '').toString();
    final String fullName = [firstName, lastName]
        .where((element) => element.trim().isNotEmpty)
        .join(' ');

    return ProductOrderCustomer(
      id: (json['id'] ?? json['customer_id'] ?? 0).toString().toInt(),
      name: (json['display_name'] ??
              json['name'] ??
              json['customer_name'] ??
              fullName)
          .toString(),
      email: (json['email'] ?? json['customer_email'] ?? '').toString(),
      contactNumber: (json['contact_number'] ??
              json['customer_contact'] ??
              json['phone_number'] ??
              json['mobile'] ??
              json['contact'] ??
              '')
          .toString(),
      profileImage: (json['profile_image'] ??
              json['profileImage'] ??
              json['avatar'] ??
              json['image'] ??
              '')
          .toString(),
      address: (json['address'] ?? json['customer_address'] ?? '').toString(),
    );
  }
}

class ProductOrderShipping {
  final String name;
  final String email;
  final String contactNumber;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final num latitude;
  final num longitude;

  bool get hasLocation => latitude != 0 && longitude != 0;

  ProductOrderShipping({
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory ProductOrderShipping.fromJson(Map<String, dynamic> json) {
    return ProductOrderShipping(
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      contactNumber: (json['contact_number'] ??
              json['phone_number'] ??
              json['mobile'] ??
              json['contact'] ??
              '')
          .toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      latitude: _parseNum(json['latitude'] ?? json['lat']),
      longitude: _parseNum(json['longitude'] ?? json['lng']),
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
      productVariantId:
          _parseNullableInt(json['product_variant_id'] ?? json['variant_id']),
      productName: (json['product_name'] ?? json['name'] ?? '').toString(),
      variantLabel: (json['variant_label'] ?? '').toString(),
      unitPrice: _parseNum(json['unit_price'] ?? json['price']),
      unitPriceFormat:
          (json['unit_price_format'] ?? json['price_format'] ?? '').toString(),
      quantity: (json['quantity'] ?? 0).toString().toInt(),
      lineTotal: _parseNum(json['line_total'] ?? json['total']),
      lineTotalFormat:
          (json['line_total_format'] ?? _formatAmount(json['total']))
              .toString(),
      product: json['product'] is Map
          ? ProductOrderProduct.fromJson(
              (json['product'] as Map).cast<String, dynamic>(),
            )
          : ProductOrderProduct.fromJson(json),
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

ProductOrderCustomer? _parseCustomer(Map<String, dynamic> json) {
  final dynamic rawCustomer =
      json['customer'] ?? json['user'] ?? json['customer_data'];

  if (rawCustomer is Map) {
    return ProductOrderCustomer.fromJson(rawCustomer.cast<String, dynamic>());
  }

  final ProductOrderCustomer customer = ProductOrderCustomer.fromJson(json);
  if (customer.name.isEmpty &&
      customer.email.isEmpty &&
      customer.contactNumber.isEmpty &&
      customer.profileImage.isEmpty &&
      customer.address.isEmpty) {
    return null;
  }

  return customer;
}

ProductOrderContact? _parseContact(dynamic value) {
  if (value is! Map) return null;

  final ProductOrderContact contact =
      ProductOrderContact.fromJson(value.cast<String, dynamic>());
  if (contact.id == 0 &&
      contact.displayName.isEmpty &&
      contact.email.isEmpty &&
      contact.contactNumber.isEmpty) {
    return null;
  }

  return contact;
}

ProductOrderLocation? _parseLocation(dynamic value) {
  if (value is! Map) return null;

  final ProductOrderLocation location =
      ProductOrderLocation.fromJson(value.cast<String, dynamic>());
  if (location.latitude == 0 && location.longitude == 0) return null;

  return location;
}

num _parseNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatAmount(dynamic value) {
  if (value == null) return '';
  return value.toString();
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
