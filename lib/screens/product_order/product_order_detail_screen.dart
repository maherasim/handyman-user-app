import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/product_order_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ProductOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const ProductOrderDetailScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<ProductOrderDetailScreen> createState() =>
      _ProductOrderDetailScreenState();
}

class _ProductOrderDetailScreenState extends State<ProductOrderDetailScreen> {
  Future<ProductOrderData>? future;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    future = getProductOrderDetail(widget.orderId);
  }

  Future<void> refreshOrder() async {
    init();
    setState(() {});
    await future;
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Order Detail',
      showLoader: false,
      child: SnapHelperWidget<ProductOrderData>(
        future: future,
        loadingWidget: LoaderWidget(),
        errorBuilder: (error) {
          return NoDataWidget(
            title: error.toString(),
            imageWidget: const ErrorStateWidget(),
            retryText: language.reload,
            onRetry: refreshOrder,
          ).center();
        },
        onSuccess: (order) {
          return AnimatedScrollView(
            padding: const EdgeInsets.all(16),
            onSwipeRefresh: () async {
              await refreshOrder();
              return 1.seconds.delay;
            },
            children: [
              _orderHeader(order),
              16.height,
              _summary(order),
              16.height,
              _shipping(order.shipping),
              16.height,
              _items(order.items),
            ],
          );
        },
      ),
    );
  }

  Widget _orderHeader(ProductOrderData order) {
    return Container(
      width: context.width(),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor:
            appStore.isDarkMode ? context.cardColor : lightPrimaryColor,
        borderRadius: radius(),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.orderNumber.validate(value: '#${order.id}'),
              style: boldTextStyle(size: 17, color: primaryColor)),
          8.height,
          Text(order.orderDate, style: secondaryTextStyle(size: 13)),
          14.height,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(order.status),
              _chip(order.paymentType),
              _chip(order.paymentStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(ProductOrderData order) {
    return _section(
      title: 'Price Detail',
      child: Column(
        children: [
          _row('Subtotal', order.subtotalFormat),
          _row('Tax', order.taxTotalFormat),
          Divider(color: context.dividerColor, height: 24),
          _row('Total', order.totalFormat, isTotal: true),
        ],
      ),
    );
  }

  Widget _shipping(ProductOrderShipping? shipping) {
    if (shipping == null) return const Offstage();

    final List<String> parts = [
      shipping.address,
      shipping.city,
      shipping.state,
      shipping.pincode,
      shipping.country,
    ].where((element) => element.trim().isNotEmpty).toList();

    return _section(
      title: 'Shipping',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shipping.name.validate(value: '-'), style: boldTextStyle()),
          6.height,
          Text(parts.join(', '), style: secondaryTextStyle(size: 13)),
        ],
      ),
    );
  }

  Widget _items(List<ProductOrderItem> items) {
    return _section(
      title: 'Items',
      child: items.isEmpty
          ? Text('No items found', style: secondaryTextStyle(size: 13))
          : Column(
              children: items.map((item) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedImageWidget(
                      url: item.product?.image.validate() ?? '',
                      height: 58,
                      width: 58,
                      fit: BoxFit.cover,
                      radius: defaultRadius,
                    ),
                    12.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName.validate(value: 'Product'),
                          style: boldTextStyle(size: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variantLabel.isNotEmpty) ...[
                          4.height,
                          Text(item.variantLabel,
                              style: secondaryTextStyle(size: 12)),
                        ],
                        8.height,
                        Text(
                          '${item.unitPriceFormat} x ${item.quantity}',
                          style: secondaryTextStyle(size: 12),
                        ),
                      ],
                    ).expand(),
                    12.width,
                    Text(item.lineTotalFormat,
                        style: boldTextStyle(size: 14, color: primaryColor)),
                  ],
                ).paddingBottom(16);
              }).toList(),
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: context.width(),
      decoration:
          boxDecorationDefault(color: context.cardColor, borderRadius: radius()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: boldTextStyle(size: 15)),
          14.height,
          child,
        ],
      ),
    );
  }

  Widget _row(String title, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Text(title,
                style: isTotal
                    ? boldTextStyle(size: 15)
                    : secondaryTextStyle(size: 14))
            .expand(),
        Text(value,
            style: boldTextStyle(
                size: isTotal ? 16 : 14,
                color: isTotal ? primaryColor : textPrimaryColorGlobal)),
      ],
    ).paddingBottom(isTotal ? 0 : 10);
  }

  Widget _chip(String text) {
    final String value = text.validate(value: '-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: boxDecorationDefault(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: radius(18),
      ),
      child: Text(value.capitalizeFirstLetter(),
          style: boldTextStyle(size: 12, color: context.primaryColor)),
    );
  }
}
