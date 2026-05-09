import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';

import 'pagination_model.dart';

class ServiceResponse {
  List<ServiceData>? serviceList;
  Pagination? pagination;
  num? max;
  num? min;
  List<ServiceData>? userServices;
  List<CategoryData>? categoryList;
  List<CategoryData>? subCategoryList;

  ServiceResponse({this.serviceList, this.pagination, this.max, this.min, this.userServices, this.categoryList, this.subCategoryList});

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      serviceList: json['data'] != null ? (json['data'] as List).map((i) => ServiceData.fromJson(i)).toList() : null,
      max: json['max'] != null ? num.parse(json['max'].toString()) : 0.0,
      min: json['min'] != null ? num.parse(json['min'].toString()) : 0.0,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      userServices: json['user_services'] != null ? (json['user_services'] as List).map((i) => ServiceData.fromJson(i)).toList() : null,
      categoryList: json['category'] != null ? (json['category'] as List).map((i) => CategoryData.fromJson(i)).toList() : null,
      subCategoryList: json['subcategory'] != null ? (json['subcategory'] as List).map((i) => CategoryData.fromJson(i)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['max'] = max;
    data['min'] = min;
    if (serviceList != null) {
      data['data'] = serviceList!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    if (userServices != null) {
      data['user_services'] = userServices!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
