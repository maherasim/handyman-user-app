import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';
import '../filter/filter_screen.dart';

class ProductFragment extends StatefulWidget {
  @override
  _ProductFragmentState createState() => _ProductFragmentState();
}

class _ProductFragmentState extends State<ProductFragment>
    with AutomaticKeepAliveClientMixin {
  ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  Future<List<ServiceData>>? future;
  List<ServiceData> products = [];

  int page = 1;
  bool isLastPage = false;
  List<CategoryData> categoryList = [];
  List<CategoryData> subCategoryList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init({bool showLoader = true}) async {
    if (showLoader) appStore.setLoading(true);

    future = getProductList({
      'per_page': PER_PAGE_ITEM,
      'page': page,
      'search': filterStore.search,
      'category_id': filterStore.categoryId.join(","),
      'min_price': filterStore.isPriceMin,
      'max_price': filterStore.isPriceMax,
      'latitude': appStore.latitude,
      'longitude': appStore.longitude,
    }).then((value) {
      isLastPage = value.serviceList.validate().length != PER_PAGE_ITEM;
      if (page == 1) {
        products.clear();
        categoryList = value.categoryList.validate();
        subCategoryList = value.subCategoryList.validate();
      }
      products.addAll(value.serviceList.validate());
      setState(() {});
      return products;
    }).catchError((e) {
      toast(e.toString());
      throw e;
    }).whenComplete(() => appStore.setLoading(false));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: appBarWidget(
        "Products",
        textColor: white,
        showBack: false,
        color: context.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: white),
            onPressed: () async {
              await FilterScreen(isFromProvider: true, categories: categoryList)
                  .launch(context)
                  .then((value) {
                if (value != null) {
                  page = 1;
                  init();
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SnapHelperWidget<List<ServiceData>>(
            future: future,
            initialData: products.isNotEmpty ? products : null,
            loadingWidget: LoaderWidget(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                onRetry: () {
                  page = 1;
                  init();
                },
              );
            },
            onSuccess: (list) {
              if (list.isEmpty) {
                return NoDataWidget(
                  title: "No products found",
                  imageWidget: EmptyStateWidget(),
                ).center();
              }

              return AnimatedScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                onSwipeRefresh: () async {
                  page = 1;
                  init(showLoader: false);
                  return await 1.seconds.delay;
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    init(showLoader: false);
                  }
                },
                children: [
                  AnimatedWrap(
                    spacing: 16,
                    runSpacing: 16,
                    itemCount: list.length,
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 0.milliseconds),
                    itemBuilder: (context, index) {
                      return ServiceComponent(
                        serviceData: list[index],
                        width: (context.width() - 48) / 2,
                        showFavouriteAction: false,
                        onUpdate: () {
                          // Optional: refresh if needed
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
