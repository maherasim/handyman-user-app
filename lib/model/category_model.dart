import 'package:booking_system_flutter/model/pagination_model.dart';

class CategoryResponse {
  List<CategoryData>? categoryList;
  Pagination? pagination;

  CategoryResponse({this.categoryList, this.pagination});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryList: json['data'] != null ? (json['data'] as List).map((i) => CategoryData.fromJson(i)).toList() : null,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (categoryList != null) {
      data['data'] = categoryList!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

class CategoryData {
  String? categoryImage;
  String? subCategoryImage;
  String? color;
  String? description;
  int? id;
  int? categoryId;
  int? isFeatured;
  String? name;
  int? status;
  int? postsCount;
  List<CategoryData>? subcategories;
  bool isSelected;
  int? services;
  int? products;

  CategoryData({
    this.categoryImage,
    this.subCategoryImage,
    this.color,
    this.description,
    this.id,
    this.categoryId,
    this.isFeatured,
    this.name,
    this.status,
    this.postsCount,
    this.subcategories,
    this.isSelected = false,
    this.services,
    this.products,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      categoryImage: json['category_image'] ?? json['subcategory_image'],
      subCategoryImage: json['subcategory_image'],
      color: json['color'],
      description: json['description'],
      id: json['id'],
      categoryId: json['category_id'],
      isFeatured: json['is_featured'],
      name: json['name'],
      status: json['status'],
      postsCount: json['posts_count'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((i) => CategoryData.fromJson(i))
              .toList()
          : null,
      services: json['services'],
      products: json['products'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category_image'] = categoryImage;
    data['subcategory_image'] = subCategoryImage;
    data['color'] = color;
    data['description'] = description;
    data['id'] = id;
    data['category_id'] = categoryId;
    data['is_featured'] = isFeatured;
    data['name'] = name;
    data['status'] = status;
    data['posts_count'] = postsCount;
    if (subcategories != null) {
      data['subcategories'] = subcategories!.map((v) => v.toJson()).toList();
    }
    data['services'] = services;
    data['products'] = products;
    return data;
  }
}
