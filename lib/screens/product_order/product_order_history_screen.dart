import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/product_order_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/product_order/product_order_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:nb_utils/nb_utils.dart';

class ProductOrderHistoryScreen extends StatefulWidget {
  const ProductOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ProductOrderHistoryScreen> createState() =>
      _ProductOrderHistoryScreenState();
}

class _ProductOrderHistoryScreenState extends State<ProductOrderHistoryScreen> {
  Future<List<ProductOrderData>>? future;
  final List<ProductOrderData> orderList = [];
  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    future = getProductOrders(
      page,
      orderList: orderList,
      lastPageCallBack: (value) {
        isLastPage = value;
      },
    );
  }

  Future<void> refreshOrders() async {
    page = 1;
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
      appBarTitle: 'Order History',
      showLoader: false,
      actions: [
        IconButton(
          icon: const Icon(Ionicons.refresh, color: white, size: 20),
          onPressed: refreshOrders,
        ),
      ],
      child: Stack(
        children: [
          SnapHelperWidget<List<ProductOrderData>>(
            future: future,
            loadingWidget: LoaderWidget(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error.toString(),
                imageWidget: const ErrorStateWidget(),
                retryText: language.reload,
                onRetry: refreshOrders,
              ).center();
            },
            onSuccess: (snap) {
              if (snap.isEmpty) {
                return NoDataWidget(
                  title: 'No orders found',
                  subTitle: 'Your product orders will appear here.',
                  imageWidget: const EmptyStateWidget(),
                ).center();
              }

              return AnimatedScrollView(
                padding: const EdgeInsets.all(16),
                onSwipeRefresh: () async {
                  await refreshOrders();
                  return 1.seconds.delay;
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    init();
                    setState(() {});
                  }
                },
                children: [
                  ...snap.map((order) {
                    return GestureDetector(
                      onTap: () {
                        ProductOrderDetailScreen(orderId: order.id)
                            .launch(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration:
                            boxDecorationDefault(color: context.cardColor),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedImageWidget(
                              url: order.productImage,
                              height: 75,
                              width: 75,
                              radius: 8,
                              fit: BoxFit.cover,
                            ),
                            12.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order.orderNumber.validate(),
                                      style: boldTextStyle(size: 14),
                                    ).expand(),
                                    _statusChip(order.status),
                                  ],
                                ),
                                4.height,
                                Text(
                                  order.items.isNotEmpty 
                                    ? order.items.map((e) => e.productName).join(", ")
                                    : "${order.itemsCount} Item(s)",
                                  style: secondaryTextStyle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                8.height,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(order.orderDate,
                                        style: secondaryTextStyle(size: 12)),
                                    Text(order.totalFormat,
                                        style: boldTextStyle(
                                            color: primaryColor, size: 14)),
                                  ],
                                ),
                              ],
                            ).expand(),
                            8.width,
                            const Icon(Icons.chevron_right,
                                color: grey, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
          Observer(
            builder: (_) =>
                LoaderWidget().visible(appStore.isLoading && page != 1),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    String value = status.validate(value: '-');
    Color color = primaryColor;

    if (value.toLowerCase().contains('pending')) {
      color = pending;
    } else if (value.toLowerCase().contains('completed')) {
      color = completed;
    } else if (value.toLowerCase().contains('cancelled')) {
      color = cancelled;
    } else if (value.toLowerCase().contains('hold')) {
      color = hold;
    } else if (value.toLowerCase().contains('progress')) {
      color = in_progress;
    } else if (value.toLowerCase().contains('failed')) {
      color = failed;
    } else if (value.toLowerCase().contains('rejected')) {
      color = rejected;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: boxDecorationDefault(
        color: color.withValues(alpha: 0.1),
        borderRadius: radius(8),
      ),
      child: Text(
        value.capitalizeFirstLetter(),
        style: boldTextStyle(size: 10, color: color),
      ),
    );
  }
}
