class BaseResponseModel {
  String? message;
  bool? status;
  int? cartCount;

  BaseResponseModel({this.message, this.status, this.cartCount});

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    return BaseResponseModel(
      message: json['message'],
      status: json['status'],
      cartCount: json['cart_count'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = message;
    data['status'] = status;
    return data;
  }
}
