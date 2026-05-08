import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
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
                  Container(
                    width: context.width(),
                    decoration: boxDecorationDefault(
                      color: context.cardColor,
                      borderRadius: radius(),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          context.primaryColor.withValues(alpha: 0.08),
                        ),
                        columnSpacing: 18,
                        horizontalMargin: 14,
                        columns: [
                          DataColumn(
                              label: Text('Order',
                                  style: boldTextStyle(size: 13))),
                          DataColumn(
                              label:
                                  Text('Date', style: boldTextStyle(size: 13))),
                          DataColumn(
                              label: Text('Items',
                                  style: boldTextStyle(size: 13))),
                          DataColumn(
                              label: Text('Status',
                                  style: boldTextStyle(size: 13))),
                          DataColumn(
                              label: Text('Payment',
                                  style: boldTextStyle(size: 13))),
                          DataColumn(
                              label: Text('Total',
                                  style: boldTextStyle(size: 13))),
                          DataColumn(
                              label: Text('Action',
                                  style: boldTextStyle(size: 13))),
                        ],
                        rows: snap.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                order.orderNumber
                                    .validate(value: '#${order.id}'),
                                style: primaryTextStyle(size: 13),
                              )),
                              DataCell(Text(order.orderDate,
                                  style: primaryTextStyle(size: 13))),
                              DataCell(Text(order.itemsCount.toString(),
                                  style: primaryTextStyle(size: 13))),
                              DataCell(_statusChip(order.status)),
                              DataCell(Text(
                                '${order.paymentType} / ${order.paymentStatus}',
                                style: primaryTextStyle(size: 13),
                              )),
                              DataCell(Text(order.totalFormat,
                                  style: boldTextStyle(
                                      size: 13, color: primaryColor))),
                              DataCell(
                                TextButton(
                                  onPressed: () {
                                    ProductOrderDetailScreen(orderId: order.id)
                                        .launch(context);
                                  },
                                  child: Text('View',
                                      style: boldTextStyle(
                                          size: 13,
                                          color: context.primaryColor)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
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
    final String value = status.validate(value: '-');

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
