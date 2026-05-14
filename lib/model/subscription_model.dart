class SubscriptionConfigResponse {
  List<Plan>? plans;
  List<PaymentMethod>? paymentMethods;

  SubscriptionConfigResponse({this.plans, this.paymentMethods});

  factory SubscriptionConfigResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionConfigResponse(
      plans: json['plans'] != null
          ? (json['plans'] as List).map((i) => Plan.fromJson(i)).toList()
          : null,
      paymentMethods: json['payment_methods'] != null
          ? (json['payment_methods'] as List)
              .map((i) => PaymentMethod.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (plans != null) {
      data['plans'] = plans!.map((v) => v.toJson()).toList();
    }
    if (paymentMethods != null) {
      data['payment_methods'] = paymentMethods!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

class Plan {
  int? id;
  String? title;
  String? identifier;
  num? amount;
  String? duration;
  String? description;
  String? planType;
  String? type;
  String? trialPeriod;
  String? playstoreIdentifier;
  String? appstoreIdentifier;
  PlanLimitation? planLimitation;

  Plan({
    this.id,
    this.title,
    this.identifier,
    this.amount,
    this.duration,
    this.description,
    this.planType,
    this.type,
    this.trialPeriod,
    this.playstoreIdentifier,
    this.appstoreIdentifier,
    this.planLimitation,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: _parseInt(json['id']),
      title: json['title'],
      identifier: json['identifier'],
      amount: _parseNum(json['amount']),
      duration: json['duration'],
      description: json['description'],
      planType: json['plan_type'],
      type: json['type'],
      trialPeriod: json['trial_period'],
      playstoreIdentifier: json['playstore_identifier'],
      appstoreIdentifier: json['appstore_identifier'],
      planLimitation: json['plan_limitation'] != null
          ? PlanLimitation.fromJson(json['plan_limitation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    data['identifier'] = identifier;
    data['amount'] = amount;
    data['duration'] = duration;
    data['description'] = description;
    data['plan_type'] = planType;
    data['type'] = type;
    data['trial_period'] = trialPeriod;
    data['playstore_identifier'] = playstoreIdentifier;
    data['appstore_identifier'] = appstoreIdentifier;
    if (planLimitation != null) {
      data['plan_limitation'] = planLimitation!.toJson();
    }
    return data;
  }
}

class PlanLimitation {
  FeaturedClassified? featuredClassified;

  PlanLimitation({this.featuredClassified});

  factory PlanLimitation.fromJson(Map<String, dynamic> json) {
    return PlanLimitation(
      featuredClassified: json['featured_classified'] != null
          ? FeaturedClassified.fromJson(json['featured_classified'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (featuredClassified != null) {
      data['featured_classified'] = featuredClassified!.toJson();
    }
    return data;
  }
}

class FeaturedClassified {
  String? isChecked;
  int? limit;

  FeaturedClassified({this.isChecked, this.limit});

  factory FeaturedClassified.fromJson(Map<String, dynamic> json) {
    return FeaturedClassified(
      isChecked: json['is_checked'],
      limit: _parseInt(json['limit']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['is_checked'] = isChecked;
    data['limit'] = limit;
    return data;
  }
}

class PaymentMethod {
  int? id;
  String? title;
  String? type;
  int? status;
  int? isTest;
  PaymentValue? value;
  PaymentValue? liveValue;

  PaymentMethod({
    this.id,
    this.title,
    this.type,
    this.status,
    this.isTest,
    this.value,
    this.liveValue,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: _parseInt(json['id']),
      title: json['title'],
      type: json['type'],
      status: _parseInt(json['status']),
      isTest: _parseInt(json['is_test']),
      value:
          json['value'] != null ? PaymentValue.fromJson(json['value']) : null,
      liveValue: json['live_value'] != null
          ? PaymentValue.fromJson(json['live_value'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    data['type'] = type;
    data['status'] = status;
    data['is_test'] = isTest;
    if (value != null) {
      data['value'] = value!.toJson();
    }
    if (liveValue != null) {
      data['live_value'] = liveValue!.toJson();
    }
    return data;
  }
}

class PaymentValue {
  String? stripeUrl;
  String? stripeKey;
  String? stripePublickey;
  String? razorUrl;
  String? razorKey;
  String? razorSecret;
  String? flutterwaveUrl;
  String? flutterwavePublic;
  String? flutterwaveSecret;
  String? flutterwaveEncryption;

  PaymentValue({
    this.stripeUrl,
    this.stripeKey,
    this.stripePublickey,
    this.razorUrl,
    this.razorKey,
    this.razorSecret,
    this.flutterwaveUrl,
    this.flutterwavePublic,
    this.flutterwaveSecret,
    this.flutterwaveEncryption,
  });

  factory PaymentValue.fromJson(Map<String, dynamic> json) {
    return PaymentValue(
      stripeUrl: json['stripe_url'],
      stripeKey: json['stripe_key'],
      stripePublickey: json['stripe_publickey'],
      razorUrl: json['razor_url'],
      razorKey: json['razor_key'],
      razorSecret: json['razor_secret'],
      flutterwaveUrl: json['flutterwave_url'],
      flutterwavePublic: json['flutterwave_public'],
      flutterwaveSecret: json['flutterwave_secret'],
      flutterwaveEncryption: json['flutterwave_encryption'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['stripe_url'] = stripeUrl;
    data['stripe_key'] = stripeKey;
    data['stripe_publickey'] = stripePublickey;
    data['razor_url'] = razorUrl;
    data['razor_key'] = razorKey;
    data['razor_secret'] = razorSecret;
    data['flutterwave_url'] = flutterwaveUrl;
    data['flutterwave_public'] = flutterwavePublic;
    data['flutterwave_secret'] = flutterwaveSecret;
    data['flutterwave_encryption'] = flutterwaveEncryption;
    return data;
  }
}

class CheckoutResponse {
  bool? status;
  String? checkoutUrl;
  String? paymentType;
  String? sessionId;
  Subscription? subscription;

  CheckoutResponse({
    this.status,
    this.checkoutUrl,
    this.paymentType,
    this.sessionId,
    this.subscription,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      status: json['status'],
      checkoutUrl: json['checkout_url'],
      paymentType: json['payment_type'],
      sessionId: json['session_id'],
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['checkout_url'] = checkoutUrl;
    data['payment_type'] = paymentType;
    data['session_id'] = sessionId;
    if (subscription != null) {
      data['subscription'] = subscription!.toJson();
    }
    return data;
  }
}

class Subscription {
  int? id;
  int? planId;
  String? title;
  String? identifier;
  num? amount;
  String? type;
  String? txnId;
  String? status;
  String? startAt;
  String? endAt;
  int? duration;
  String? description;
  String? planType;
  String? module;
  String? activeInAppPurchaseIdentifier;
  PlanLimitation? planLimitation;

  Subscription({
    this.id,
    this.planId,
    this.title,
    this.identifier,
    this.amount,
    this.type,
    this.txnId,
    this.status,
    this.startAt,
    this.endAt,
    this.duration,
    this.description,
    this.planType,
    this.module,
    this.activeInAppPurchaseIdentifier,
    this.planLimitation,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: _parseInt(json['id']),
      planId: _parseInt(json['plan_id']),
      title: json['title'],
      identifier: json['identifier'],
      amount: _parseNum(json['amount']),
      type: json['type'],
      txnId: json['txn_id'],
      status: json['status'],
      startAt: json['start_at'],
      endAt: json['end_at'],
      duration: _parseInt(json['duration']),
      description: json['description'],
      planType: json['plan_type'],
      module: json['module'],
      activeInAppPurchaseIdentifier: json['active_in_app_purchase_identifier'],
      planLimitation: json['plan_limitation'] != null
          ? PlanLimitation.fromJson(json['plan_limitation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['plan_id'] = planId;
    data['title'] = title;
    data['identifier'] = identifier;
    data['amount'] = amount;
    data['type'] = type;
    data['txn_id'] = txnId;
    data['status'] = status;
    data['start_at'] = startAt;
    data['end_at'] = endAt;
    data['duration'] = duration;
    data['description'] = description;
    data['plan_type'] = planType;
    data['module'] = module;
    data['active_in_app_purchase_identifier'] = activeInAppPurchaseIdentifier;
    if (planLimitation != null) {
      data['plan_limitation'] = planLimitation!.toJson();
    }
    return data;
  }
}

class SubscriptionHistoryResponse {
  bool? status;
  SubscriptionHistoryPagination? pagination;
  List<SubscriptionHistoryData>? data;

  SubscriptionHistoryResponse({this.status, this.pagination, this.data});

  factory SubscriptionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryResponse(
      status: json['status'],
      pagination: json['pagination'] != null
          ? SubscriptionHistoryPagination.fromJson(json['pagination'])
          : null,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((i) => SubscriptionHistoryData.fromJson(i))
              .toList()
          : null,
    );
  }
}

class SubscriptionHistoryPagination {
  int? totalItems;
  int? perPage;
  int? currentPage;
  int? totalPages;
  int? from;
  int? to;
  int? nextPage;
  int? previousPage;

  SubscriptionHistoryPagination({
    this.totalItems,
    this.perPage,
    this.currentPage,
    this.totalPages,
    this.from,
    this.to,
    this.nextPage,
    this.previousPage,
  });

  factory SubscriptionHistoryPagination.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryPagination(
      totalItems: _parseInt(json['total_items']),
      perPage: _parseInt(json['per_page']),
      currentPage: _parseInt(json['currentPage']),
      totalPages: _parseInt(json['totalPages']),
      from: _parseInt(json['from']),
      to: _parseInt(json['to']),
      nextPage: _parseInt(json['next_page']),
      previousPage: _parseInt(json['previous_page']),
    );
  }
}

class SubscriptionHistoryData {
  int? id;
  int? planId;
  String? title;
  String? identifier;
  String? type;
  num? amount;
  String? status;
  String? computedStatus;
  bool? isActive;
  bool? isExpired;
  String? startAt;
  String? endAt;
  int? daysLeft;
  int? duration;
  String? planType;
  String? module;
  int? featuredPostsLimit;
  PlanLimitation? planLimitation;
  SubscriptionPayment? payment;
  String? createdAt;
  String? updatedAt;

  SubscriptionHistoryData({
    this.id,
    this.planId,
    this.title,
    this.identifier,
    this.type,
    this.amount,
    this.status,
    this.computedStatus,
    this.isActive,
    this.isExpired,
    this.startAt,
    this.endAt,
    this.daysLeft,
    this.duration,
    this.planType,
    this.module,
    this.featuredPostsLimit,
    this.planLimitation,
    this.payment,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionHistoryData.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryData(
      id: _parseInt(json['id']),
      planId: _parseInt(json['plan_id']),
      title: json['title'],
      identifier: json['identifier'],
      type: json['type'],
      amount: _parseNum(json['amount']),
      status: json['status'],
      computedStatus: json['computed_status'],
      isActive: _parseBool(json['is_active']),
      isExpired: _parseBool(json['is_expired']),
      startAt: json['start_at'],
      endAt: json['end_at'],
      daysLeft: _parseInt(json['days_left']),
      duration: _parseInt(json['duration']),
      planType: json['plan_type'],
      module: json['module'],
      featuredPostsLimit: _parseInt(json['featured_posts_limit']),
      planLimitation: json['plan_limitation'] != null
          ? PlanLimitation.fromJson(json['plan_limitation'])
          : null,
      payment: json['payment'] != null
          ? SubscriptionPayment.fromJson(json['payment'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class SubscriptionPayment {
  int? id;
  num? amount;
  String? paymentType;
  String? paymentStatus;
  String? txnId;
  String? createdAt;

  SubscriptionPayment({
    this.id,
    this.amount,
    this.paymentType,
    this.paymentStatus,
    this.txnId,
    this.createdAt,
  });

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return SubscriptionPayment(
      id: _parseInt(json['id']),
      amount: _parseNum(json['amount']),
      paymentType: json['payment_type'],
      paymentStatus: json['payment_status'],
      txnId: json['txn_id'],
      createdAt: json['created_at'],
    );
  }
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final String text = value.toString().trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].contains(text)) return true;
  if (['false', '0', 'no', 'off'].contains(text)) return false;
  return null;
}
