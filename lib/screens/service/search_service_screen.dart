import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/store/filter_store.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';
import '../../main.dart';
import '../../model/service_data_model.dart';
import '../../network/rest_apis.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../booking/component/provider_service_component.dart';

class SearchServiceScreen extends StatefulWidget {
  final List<ServiceData>? featuredList;
  final String search;

  SearchServiceScreen({Key? key, this.featuredList, this.search = ""})
      : super(key: key);

  @override
  State<SearchServiceScreen> createState() => _SearchServiceScreenState();
}

class _SearchServiceScreenState extends State<SearchServiceScreen> {
  Future<List<ServiceData>>? futureService;
  List<ServiceData> serviceList = [];

  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchCont = TextEditingController();
  int? subCategory;

  int page = 1;
  bool isLastPage = true;

  @override
  void initState() {
    super.initState();
    filterStore = FilterStore();
    if (widget.search.isNotEmpty) {
      searchCont.text = widget.search;
      page = 1;
      appStore.setLoading(true);
      fetchAllServiceData();
    }
  }

  void fetchAllServiceData() async {
    serviceList.clear();
    final Map<String, dynamic> request = {
      'per_page': PER_PAGE_ITEM,
      'page': page,
      'search': searchCont.text,
      'category_id': filterStore.categoryId.join(","),
      'min_price': filterStore.isPriceMin,
      'max_price': filterStore.isPriceMax,
      'latitude': filterStore.latitude,
      'longitude': filterStore.longitude,
    };

    futureService = Future.wait([
      searchServiceAPI(
        page: page,
        list: <ServiceData>[],
        categoryId: filterStore.categoryId.join(','),
        subCategory:
            subCategory != null ? subCategory.validate().toString() : '',
        providerId: filterStore.providerId.join(","),
        isPriceMin: filterStore.isPriceMin,
        isPriceMax: filterStore.isPriceMax,
        ratingId: filterStore.ratingId.join(','),
        search: searchCont.text,
        latitude: filterStore.latitude,
        longitude: filterStore.longitude,
        lastPageCallBack: (p0) {
          isLastPage = true;
        },
      ),
      getProductList(request).then((value) => value.serviceList.validate()),
      getPostList(request).then((value) => value.serviceList.validate()),
    ]).then((lists) {
      serviceList.addAll(lists[0]);
      serviceList.addAll(lists[1]);
      serviceList.addAll(lists[2]);
      isLastPage = true;
      return serviceList;
    });
  }

  String get setSearchString {
    return language.search;
  }

  bool get isFilterApplied {
    return filterStore.providerId.isNotEmpty ||
        filterStore.handymanId.isNotEmpty ||
        filterStore.ratingId.isNotEmpty ||
        filterStore.categoryId.isNotEmpty ||
        filterStore.isPriceMax.isNotEmpty ||
        filterStore.isPriceMin.isNotEmpty;
  }

  bool get showRecommended {
    return searchCont.text.isEmpty && !isFilterApplied;
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    filterStore.clearFilters();
    searchFocusNode.dispose();
    filterStore.setSelectedSubCategory(catId: 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: setSearchString,
        child: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AppTextField(
                          textFieldType: TextFieldType.OTHER,
                          focus: searchFocusNode,
                          controller: searchCont,
                          suffix: CloseButton(
                            onPressed: () {
                              page = 1;
                              searchCont.clear();
                              filterStore.setSearch('');
                              serviceList = [];
                              futureService = null;
                              setState(() {});
                            },
                          ).visible(searchCont.text.isNotEmpty),
                          onFieldSubmitted: (s) {
                            page = 1;
                            filterStore.setSearch(s);
                            appStore.setLoading(true);
                            fetchAllServiceData();
                            setState(() {});
                          },
                          decoration: inputDecoration(context).copyWith(
                            hintText:
                                "${language.lblSearchFor} $setSearchString",
                            prefixIcon:
                                ic_search.iconImage(size: 10).paddingAll(14),
                            hintStyle: secondaryTextStyle(),
                          ),
                        ).expand(),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                onSwipeRefresh: () {
                  page = 1;
                  appStore.setLoading(true);
                  fetchAllServiceData();
                  setState(() {});
                  return Future.value(false);
                },
                onNextPage: () {
                  if (!showRecommended) {
                    if (!isLastPage) {
                      page++;
                      appStore.setLoading(true);
                      fetchAllServiceData();
                      setState(() {});
                    }
                  }
                },
                children: [
                  showRecommended
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.featuredList.validate().isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  16.height,
                                  Text(language.recommendedForYou,
                                          style: boldTextStyle(
                                              size: LABEL_TEXT_SIZE))
                                      .paddingSymmetric(horizontal: 16),
                                  AnimatedListView(
                                    itemCount:
                                        widget.featuredList.validate().length,
                                    listAnimationType: ListAnimationType.FadeIn,
                                    fadeInConfiguration: FadeInConfiguration(
                                        duration: 2.seconds),
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    emptyWidget: NoDataWidget(
                                      title: language.lblNoServicesFound,
                                      subTitle: (searchCont.text.isNotEmpty ||
                                              filterStore
                                                  .providerId.isNotEmpty ||
                                              filterStore.categoryId.isNotEmpty)
                                          ? language.noDataFoundInFilter
                                          : null,
                                      imageWidget: const EmptyStateWidget(),
                                    ),
                                    itemBuilder: (_, index) {
                                      return ProviderServiceComponent(
                                              serviceData: widget.featuredList
                                                  .validate()[index])
                                          .paddingAll(8);
                                    },
                                  ).paddingAll(8),
                                ],
                              )
                            else
                              const NoDataWidget(
                                title:
                                    'Start searching your service,Posts,Products',
                                imageWidget: EmptyStateWidget(),
                              ),
                          ],
                        )
                      : SnapHelperWidget(
                          future: futureService,
                          loadingWidget: appStore.isLoading
                              ? const Offstage()
                              : LoaderWidget(),
                          errorBuilder: (p0) {
                            return NoDataWidget(
                              title: p0,
                              retryText: language.reload,
                              imageWidget: const ErrorStateWidget(),
                              onRetry: () {
                                page = 1;
                                appStore.setLoading(true);
                                fetchAllServiceData();
                                setState(() {});
                              },
                            );
                          },
                          onSuccess: (data) {
                            if (serviceList.isEmpty) {
                              return NoDataWidget(
                                title: language.lblNoServicesFound,
                                imageWidget: const EmptyStateWidget(),
                              ).center();
                            }

                            return AnimatedListView(
                              itemCount: serviceList.length,
                              listAnimationType: ListAnimationType.FadeIn,
                              fadeInConfiguration:
                                  FadeInConfiguration(duration: 2.seconds),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (_, index) {
                                return ServiceComponent(
                                  serviceData: serviceList[index],
                                ).paddingAll(8);
                              },
                            ).paddingAll(8);
                          },
                        ),
                ],
              ).expand(),
            ],
          ),
        ),
      ),
    );
  }
}
