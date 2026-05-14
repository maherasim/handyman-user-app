import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/featured_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/slider_and_location_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/horizontal_shop_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/shimmer/dashboard_shimmer.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../../newDashboard/dashboard_3/component/referral_component.dart';
import '../component/booking_confirmed_component.dart';
import '../component/new_job_request_component.dart';
import '../component/promotional_banner_slider_component.dart';

class DashboardFragment extends StatefulWidget {
  final Function(int)? onChangeTab;

  DashboardFragment({this.onChangeTab});

  @override
  _DashboardFragmentState createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment>
    with AutomaticKeepAliveClientMixin {
  static const int homeSectionItemLimit = 10;

  Future<DashboardResponse>? future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    init(showLoader: false);

    setStatusBarColorChange();

    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) async {
      await init();
    });
  }

  Future<void> init({bool showLoader = true}) async {
    appStore.setLoading(showLoader);
    future = loadDashboardData(
        isCurrentLocation: appStore.isCurrentLocation,
        lat: getDoubleAsync(LATITUDE),
        long: getDoubleAsync(LONGITUDE));
    setStatusBarColorChange();
    setState(() {});
  }

  Future<DashboardResponse> loadDashboardData({
    bool isCurrentLocation = false,
    double? lat,
    double? long,
  }) async {
    final DashboardResponse dashboard = await userDashboard(
      isCurrentLocation: isCurrentLocation,
      lat: lat,
      long: long,
    );

    try {
      final Map<String, dynamic> request = {
        'per_page': homeSectionItemLimit,
        'page': 1,
        if (isCurrentLocation) 'latitude': lat,
        if (isCurrentLocation) 'longitude': long,
      };

      final List<ServiceData> serviceList = [];
      final List<dynamic> responses = await Future.wait([
        searchServiceAPI(
          page: 1,
          list: serviceList,
          latitude: isCurrentLocation ? lat.validate().toString() : '',
          longitude: isCurrentLocation ? long.validate().toString() : '',
        ),
        getProductList(request),
        getPostList(request),
      ]);

      dashboard.service = (responses[0] as List<ServiceData>)
          .take(homeSectionItemLimit)
          .toList();
      dashboard.product =
          (responses[1] as ServiceResponse).serviceList.validate();
      dashboard.post = _featuredFirst(
          (responses[2] as ServiceResponse).serviceList.validate());
      cachedDashboardResponse = dashboard;
    } catch (e) {
      log(e.toString());
    }

    return dashboard;
  }

  List<ServiceData> _featuredFirst(List<ServiceData> list) {
    final List<ServiceData> sortedList = List<ServiceData>.from(list);
    sortedList.sort(
        (a, b) => b.isFeatured.validate().compareTo(a.isFeatured.validate()));
    return sortedList;
  }

  Future<void> setStatusBarColorChange() async {
    setStatusBarColor(
      statusBarIconBrightness: appStore.isDarkMode
          ? Brightness.light
          : await isNetworkAvailable()
              ? Brightness.light
              : Brightness.dark,
      transparentColor,
      delayInMilliSeconds: 800,
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          Observer(
            builder: (context) {
              return AbsorbPointer(
                absorbing: appStore.isLoading,
                child: SnapHelperWidget<DashboardResponse>(
                  initialData: cachedDashboardResponse,
                  future: future,
                  errorBuilder: (error) {
                    return NoDataWidget(
                      title: error,
                      imageWidget: const ErrorStateWidget(),
                      retryText: language.reload,
                      onRetry: () async {
                        await init();
                      },
                    );
                  },
                  loadingWidget: DashboardShimmer(),
                  onSuccess: (snap) {
                    if (snap.notificationUnreadCount != null)
                      appStore.setUnreadCount(snap.notificationUnreadCount!);

                    return AnimatedScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration:
                          FadeInConfiguration(duration: 0.milliseconds),
                      onSwipeRefresh: () async {
                        setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
                        await init();

                        return await 2.seconds.delay;
                      },
                      children: [
                        SliderLocationComponent(
                          sliderList: snap.slider.validate(),
                          featuredList: snap.featuredServices.validate(),
                          callback: () async {
                            await init();
                          },
                        ),
                        30.height,
                        PendingBookingComponent(
                            upcomingConfirmedBooking: snap.upcomingData),
                        CategoryComponent(
                          categoryList: snap.category.validate(),
                          isHorizontal: true,
                          title: 'Top Categories',
                        ),
                        12.height,
                        CategoryComponent(
                          categoryList: snap.productCategory.validate(),
                          isHorizontal: true,
                          title: 'Product Categories',
                        ),
                        12.height,
                        CategoryComponent(
                          categoryList: snap.classifiedCategory.validate(),
                          isHorizontal: true,
                          title: 'Classified Categories',
                        ),
                        if (appStore.isLoggedIn && snap.referralRule.validate())
                          DashboardReferralComponent().paddingTop(16),
                        if (snap.promotionalBanner.validate().isNotEmpty &&
                            appConfigurationStore.isPromotionalBanner)
                          PromotionalBannerSliderComponent(
                            promotionalBannerList:
                                snap.promotionalBanner.validate(),
                          ).paddingTop(16),
                        16.height,
                        FeaturedServiceListComponent(
                            serviceList: snap.featuredServices.validate()),
                        ServiceListComponent(
                          serviceList: snap.service
                              .validate()
                              .take(homeSectionItemLimit)
                              .toList(),
                          alwaysShowViewAll: true,
                        ),
                        ServiceListComponent(
                          serviceList: snap.product
                              .validate()
                              .take(homeSectionItemLimit)
                              .toList(),
                          title: 'Products',
                          alwaysShowViewAll: true,
                          onViewAll: () {
                            widget.onChangeTab?.call(1);
                          },
                        ),
                        ServiceListComponent(
                          serviceList: snap.post
                              .validate()
                              .take(homeSectionItemLimit)
                              .toList(),
                          title: 'Posts',
                          alwaysShowViewAll: true,
                          onViewAll: () {
                            widget.onChangeTab?.call(2);
                          },
                        ),
                        16.height,
                        HorizontalShopListComponent(
                          shopList: snap.shops.validate().take(5).toList(),
                          showServices: false,
                        ),
                        16.height,
                        if (appConfigurationStore.jobRequestStatus)
                          const NewJobRequestComponent(),
                      ],
                    );
                  },
                ),
              );
            },
          ),

          /// 🔒 Loader Overlay and Interaction Block
          Observer(
            builder: (context) {
              return appStore.isLoading
                  ? LoaderWidget().center()
                  : const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
