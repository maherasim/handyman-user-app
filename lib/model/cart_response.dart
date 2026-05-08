import 'package:nb_utils/nb_utils.dart';

class CartResponse {
  final bool status;
  final List<CartItemData> data;
  final CartSummary summary;
  final int cartCount;
  final CartCheckout checkout;

  CartResponse({
    required this.status,
    required this.data,
    required this.summary,
    required this.cartCount,
    required this.checkout,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      status: _parseBool(json['status']),
      data: (json['data'] as List? ?? [])
          .map((e) => CartItemData.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      summary: CartSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
      cartCount: (json['cart_count'] ?? 0).toString().toInt(),
      checkout: CartCheckout.fromJson(
          (json['checkout'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
    );
  }
}

class CartItemData {
  final int cartItemId;
  final int productId;
  final int productVariantId;
  final int quantity;
  final int maxAllowedQuantity;
  final num unitPrice;
  final String unitPriceFormat;
  final num lineTotal;
  final String lineTotalFormat;
  final CartProductData product;
  final CartVariantData variant;

  CartItemData({
    required this.cartItemId,
    required this.productId,
    required this.productVariantId,
    required this.quantity,
    required this.maxAllowedQuantity,
    required this.unitPrice,
    required this.unitPriceFormat,
    required this.lineTotal,
    required this.lineTotalFormat,
    required this.product,
    required this.variant,
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    return CartItemData(
      cartItemId: (json['cart_item_id'] ?? 0).toString().toInt(),
      productId: (json['product_id'] ?? 0).toString().toInt(),
      productVariantId: (json['product_variant_id'] ?? 0).toString().toInt(),
      quantity: (json['quantity'] ?? 0).toString().toInt(),
      maxAllowedQuantity:
          (json['max_allowed_quantity'] ?? 0).toString().toInt(),
      unitPrice: _parseNum(json['unit_price']),
      unitPriceFormat: (json['unit_price_format'] ?? '').toString(),
      lineTotal: _parseNum(json['line_total']),
      lineTotalFormat: (json['line_total_format'] ?? '').toString(),
      product: CartProductData.fromJson(
          (json['product'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
      variant: CartVariantData.fromJson(
          (json['variant'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
    );
  }
}

class CartProductData {
  final int id;
  final String name;
  final String providerName;
  final String providerImage;
  final String productImage;

  CartProductData({
    required this.id,
    required this.name,
    required this.providerName,
    required this.providerImage,
    required this.productImage,
  });

  factory CartProductData.fromJson(Map<String, dynamic> json) {
    return CartProductData(
      id: (json['id'] ?? 0).toString().toInt(),
      name: (json['name'] ?? '').toString(),
      providerName: (json['provider_name'] ?? '').toString(),
      providerImage: (json['provider_image'] ?? '').toString(),
      productImage: (json['product_image'] ?? '').toString(),
    );
  }
}

class CartVariantData {
  final int id;
  final String optionValue;
  final String attributeName;
  final String label;
  final num price;
  final String priceFormat;
  final int stock;
  final int maxPurchaseQty;

  CartVariantData({
    required this.id,
    required this.optionValue,
    required this.attributeName,
    required this.label,
    required this.price,
    required this.priceFormat,
    required this.stock,
    required this.maxPurchaseQty,
  });

  factory CartVariantData.fromJson(Map<String, dynamic> json) {
    return CartVariantData(
      id: (json['id'] ?? 0).toString().toInt(),
      optionValue: (json['option_value'] ?? '').toString(),
      attributeName: (json['attribute_name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      price: _parseNum(json['price']),
      priceFormat: (json['price_format'] ?? '').toString(),
      stock: (json['stock'] ?? 0).toString().toInt(),
      maxPurchaseQty: (json['max_purchase_qty'] ?? 0).toString().toInt(),
    );
  }
}

class CartSummary {
  final num subtotal;
  final String subtotalFormat;
  final num taxTotal;
  final String taxTotalFormat;
  final num grandTotal;
  final String grandTotalFormat;
  final List<CartTaxDetail> taxDetail;

  CartSummary({
    required this.subtotal,
    required this.subtotalFormat,
    required this.taxTotal,
    required this.taxTotalFormat,
    required this.grandTotal,
    required this.grandTotalFormat,
    required this.taxDetail,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      subtotal: _parseNum(json['subtotal']),
      subtotalFormat: (json['subtotal_format'] ?? '').toString(),
      taxTotal: _parseNum(json['tax_total']),
      taxTotalFormat: (json['tax_total_format'] ?? '').toString(),
      grandTotal: _parseNum(json['grand_total']),
      grandTotalFormat: (json['grand_total_format'] ?? '').toString(),
      taxDetail: (json['tax_detail'] as List? ?? [])
          .map(
              (e) => CartTaxDetail.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class CartTaxDetail {
  final String title;
  final String type;
  final num value;
  final num amount;

  CartTaxDetail({
    required this.title,
    required this.type,
    required this.value,
    required this.amount,
  });

  factory CartTaxDetail.fromJson(Map<String, dynamic> json) {
    return CartTaxDetail(
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      value: _parseNum(json['value']),
      amount: _parseNum(json['amount']),
    );
  }
}

class CartCheckout {
  final List<String> shippingRequiredFields;
  final String shippingCountryDefault;
  final List<String> states;
  final List<CartPaymentMethod> paymentMethods;

  CartCheckout({
    required this.shippingRequiredFields,
    required this.shippingCountryDefault,
    required this.states,
    required this.paymentMethods,
  });

  factory CartCheckout.fromJson(Map<String, dynamic> json) {
    return CartCheckout(
      shippingRequiredFields: (json['shipping_required_fields'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      shippingCountryDefault:
          (json['shipping_country_default'] ?? '').toString(),
      states: (json['states'] as List? ?? []).map((e) => e.toString()).toList(),
      paymentMethods: (json['payment_methods'] as List? ?? [])
          .map((e) =>
              CartPaymentMethod.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class CartPaymentMethod {
  final String type;
  final String title;
  final bool isOnline;
  final int isTest;
  final num balance;
  final String balanceFormat;

  CartPaymentMethod({
    required this.type,
    required this.title,
    required this.isOnline,
    required this.isTest,
    required this.balance,
    required this.balanceFormat,
  });

  factory CartPaymentMethod.fromJson(Map<String, dynamic> json) {
    return CartPaymentMethod(
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      isOnline: _parseBool(json['is_online']),
      isTest: (json['is_test'] ?? 0).toString().toInt(),
      balance: _parseNum(json['balance']),
      balanceFormat: (json['balance_format'] ?? '').toString(),
    );
  }
}

class CartCheckoutResponse {
  final bool status;
  final String message;
  final CartOrderData? data;
  final CartPaymentAction paymentAction;
  final int cartCount;

  CartCheckoutResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.paymentAction,
    required this.cartCount,
  });

  factory CartCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CartCheckoutResponse(
      status: _parseBool(json['status']),
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map
          ? CartOrderData.fromJson(
              (json['data'] as Map).cast<String, dynamic>())
          : null,
      paymentAction: CartPaymentAction.fromJson(
          (json['payment_action'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
      cartCount: (json['cart_count'] ?? 0).toString().toInt(),
    );
  }
}

class CartOrderData {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentType;
  final String paymentStatus;
  final num subtotal;
  final num taxTotal;
  final num total;
  final String totalFormat;
  final String txnId;

  CartOrderData({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentType,
    required this.paymentStatus,
    required this.subtotal,
    required this.taxTotal,
    required this.total,
    required this.totalFormat,
    required this.txnId,
  });

  factory CartOrderData.fromJson(Map<String, dynamic> json) {
    return CartOrderData(
      id: (json['id'] ?? 0).toString().toInt(),
      orderNumber: (json['order_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      subtotal: _parseNum(json['subtotal']),
      taxTotal: _parseNum(json['tax_total']),
      total: _parseNum(json['total']),
      totalFormat: (json['total_format'] ?? '').toString(),
      txnId: (json['txn_id'] ?? '').toString(),
    );
  }
}

class CartPaymentAction {
  final String type;
  final String razorpayKey;
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String verifyEndpoint;

  CartPaymentAction({
    required this.type,
    required this.razorpayKey,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.verifyEndpoint,
  });

  factory CartPaymentAction.fromJson(Map<String, dynamic> json) {
    return CartPaymentAction(
      type: (json['type'] ?? '').toString(),
      razorpayKey: (json['razorpay_key'] ?? '').toString(),
      razorpayOrderId: (json['razorpay_order_id'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toString().toInt(),
      currency: (json['currency'] ?? '').toString(),
      verifyEndpoint: (json['verify_endpoint'] ?? '').toString(),
    );
  }
}

num _parseNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
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
