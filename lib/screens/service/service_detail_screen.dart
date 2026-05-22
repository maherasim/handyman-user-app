import 'package:booking_system_flutter/component/at_shop_service_icon_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/online_service_icon_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'package:booking_system_flutter/model/slot_data.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/book_service_screen.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_detail_provider_widget.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/component/horizontal_shop_list_component.dart';
import 'package:booking_system_flutter/screens/review/components/review_widget.dart';
import 'package:booking_system_flutter/screens/review/rating_view_all_screen.dart';
import 'package:booking_system_flutter/screens/service/component/related_service_component.dart';
import 'package:booking_system_flutter/screens/service/component/service_detail_header_component.dart';
import 'package:booking_system_flutter/screens/service/component/service_faq_widget.dart';
import 'package:booking_system_flutter/screens/service/package/package_component.dart';
import 'package:booking_system_flutter/screens/service/shimmer/service_detail_shimmer.dart';
import 'package:booking_system_flutter/screens/shop/shop_list_screen.dart';
import 'package:booking_system_flutter/store/service_addon_store.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/images.dart';
import 'addons/service_addons_component.dart';

ServiceAddonStore serviceAddonStore = ServiceAddonStore();

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final ServiceData? service;
  final bool isFromProviderInfo;
  final String detailType;

  ServiceDetailScreen({
    required this.serviceId,
    this.service,
    this.isFromProviderInfo = false,
    this.detailType = 'service',
  });

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with TickerProviderStateMixin {
  PageController pageController = PageController();

  Future<ServiceDetailResponse>? future;

  int selectedAddressId = 0;
  int selectedBookingAddressId = -1;
  BookingPackage? selectedPackage;

  ShopModel? selectedShop;
  bool _isCartActionLoading = false;
  int _productQuantity = 1;
  bool _showProductQuantityControl = false;
  int? _productCartItemId;

  @override
  void initState() {
    super.initState();
    serviceAddonStore.selectedServiceAddon.clear();
    setStatusBarColor(transparentColor);
    init();
  }

  void init() async {
    if (widget.detailType == 'product') {
      future = getProductDetails(
        productId: widget.serviceId.validate(),
        customerId: appStore.userId,
      );
    } else if (widget.detailType == 'post') {
      future = getPostDetails(
        postId: widget.serviceId.validate(),
        customerId: appStore.userId,
      );
    } else {
      future = getServiceDetails(
        serviceId: widget.serviceId.validate(),
        customerId: appStore.userId,
      );
    }
    setState(() {});
  }

  //region Widgets
  Widget availableWidget(
      {required ServiceDetailResponse zone, required ServiceData data}) {
    if (zone.zones.validate().isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          8.height,
          Text(language.lblAvailableAt,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          8.height,
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                zone.zones.validate().length,
                (index) {
                  Zones value = zone.zones.validate()[index];
                  if (value.id == null) return Offstage();
                  bool isSelected = selectedAddressId == index;
                  if (selectedBookingAddressId == -1) {
                    selectedBookingAddressId =
                        zone.zones.validate().first.id.validate();
                  }
                  return GestureDetector(
                    onTap: () {
                      selectedAddressId = index;
                      selectedBookingAddressId = value.id.validate();
                      setState(() {});
                    },
                    child: Container(
                      decoration: boxDecorationDefault(
                          color: appStore.isDarkMode
                              ? isSelected
                                  ? primaryColor
                                  : Colors.black
                              : isSelected
                                  ? primaryColor
                                  : Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10),
                        child: Text(
                          value.name.validate(),
                          style: boldTextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : textPrimaryColorGlobal),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          8.height,
        ],
      );
    }
    if (data.serviceAddressMapping.validate().isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          8.height,
          Text(language.lblAvailableAt,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          8.height,
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                data.serviceAddressMapping!.length,
                (index) {
                  ServiceAddressMapping value =
                      data.serviceAddressMapping![index];
                  if (value.providerAddressMapping == null)
                    return const Offstage();
                  bool isSelected = selectedAddressId == index;
                  if (selectedBookingAddressId == -1) {
                    selectedBookingAddressId = data
                        .serviceAddressMapping!.first.providerAddressId
                        .validate();
                  }
                  return GestureDetector(
                    onTap: () {
                      selectedAddressId = index;
                      selectedBookingAddressId =
                          value.providerAddressId.validate();
                      setState(() {});
                    },
                    child: Container(
                      decoration: boxDecorationDefault(
                          color: appStore.isDarkMode
                              ? isSelected
                                  ? primaryColor
                                  : Colors.black
                              : isSelected
                                  ? primaryColor
                                  : Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10),
                        child: Text(
                          value.providerAddressMapping!.address.validate(),
                          style: boldTextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : textPrimaryColorGlobal),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          8.height,
        ],
      );
    }
    return const Offstage();
  }

  Widget providerWidget({required UserData data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.lblAboutProvider,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        BookingDetailProviderWidget(providerData: data).onTap(() async {
          await ProviderInfoScreen(providerId: data.id).launch(context);
          setStatusBarColor(Colors.transparent);
        }),
      ],
    ).paddingAll(16);
  }

  Widget serviceFaqWidget({required List<ServiceFaq> data}) {
    if (data.isEmpty) return const Offstage();

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          8.height,
          ViewAllLabel(label: language.lblFaq, list: data),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            padding: const EdgeInsets.all(0),
            itemBuilder: (_, index) =>
                ServiceFaqWidget(serviceFaq: data[index]),
          ),
          8.height,
        ],
      ),
    );
  }

  Widget slotsAvailable(
      {required List<SlotData> data, required bool isSlotAvailable}) {
    if (!isSlotAvailable ||
        data.where((element) => element.slot.validate().isNotEmpty).isEmpty)
      return const Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        Text(language.lblAvailableOnTheseDays,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(
              data
                  .where((element) => element.slot.validate().isNotEmpty)
                  .length, (index) {
            SlotData value = data
                .where((element) => element.slot.validate().isNotEmpty)
                .toList()[index];

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              decoration: boxDecorationDefault(
                color: context.cardColor,
                border: appStore.isDarkMode
                    ? Border.all(color: context.dividerColor)
                    : null,
              ),
              child: Text(value.day.capitalizeFirstLetter(),
                  style: secondaryTextStyle(
                      size: LABEL_TEXT_SIZE, color: primaryColor)),
            );
          }),
        ),
        8.height,
      ],
    );
  }

  Widget reviewWidget(
      {required List<RatingData> data,
      required ServiceDetailResponse serviceDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          //label: language.review,
          label:
              '${language.review} (${serviceDetailResponse.serviceDetail!.totalReview})',
          list: data,
          onTap: () {
            RatingViewAllScreen(serviceId: widget.serviceId).launch(context);
          },
        ),
        data.isNotEmpty
            ? Wrap(
                children: List.generate(
                  data.length,
                  (index) => ReviewWidget(data: data[index]),
                ),
              ).paddingTop(8)
            : Text(language.lblNoReviews, style: secondaryTextStyle()),
      ],
    ).paddingSymmetric(horizontal: 16);
  }

  Widget relatedServiceWidget(
      {required List<ServiceData> serviceList, required int serviceId}) {
    if (serviceList.isEmpty) return const Offstage();

    serviceList.removeWhere((element) => element.id == serviceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (serviceList.isNotEmpty)
          Text(
            language.lblRelatedServices,
            style: boldTextStyle(size: LABEL_TEXT_SIZE),
          ).paddingSymmetric(horizontal: 16),
        8.height,
        if (serviceList.isNotEmpty)
          ListView.builder(
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            itemCount: serviceList.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, index) => RelatedServiceComponent(
              serviceData: serviceList[index],
              width: appConfigurationStore.userDashboardType ==
                      DEFAULT_USER_DASHBOARD
                  ? context.width() / 2 - 26
                  : 280,
            ).paddingOnly(bottom: 16, left: 8, right: 8),
          )
      ],
    );
  }

  //endregion
  void bookNow(ServiceDetailResponse serviceDetailResponse) {
    doIfLoggedIn(context, () async {
      serviceDetailResponse.serviceDetail!.bookingAddressId =
          selectedBookingAddressId;
      if (serviceDetailResponse.serviceDetail!.isOnShopService &&
          serviceDetailResponse.shops.validate().length > 1) {
        await showModalBottomSheet(
          context: context,
          backgroundColor: context.scaffoldBackgroundColor,
          barrierColor: appStore.isDarkMode ? Colors.white10 : Colors.black26,
          showDragHandle: true,
          isScrollControlled: true,
          constraints: BoxConstraints(maxHeight: context.height() * 0.9),
          enableDrag: true,
          shape: RoundedRectangleBorder(
            borderRadius: radiusOnly(topRight: 16, topLeft: 16),
          ),
          builder: (context) {
            return ShopListScreen(
              serviceId: widget.serviceId,
              selectedShop: selectedShop,
              isShopChange: false,
              isForBooking: true,
            );
          },
        ).then(
          (value) {
            if (value != null) {
              selectedShop = value;
              handleBookNow(serviceDetailResponse, serviceId: widget.serviceId);
            }
          },
        );
      } else {
        if (serviceDetailResponse.serviceDetail!.isOnShopService &&
            serviceDetailResponse.shops.validate().length == 1) {
          selectedShop = serviceDetailResponse.shops.first;
        }
        handleBookNow(serviceDetailResponse, serviceId: widget.serviceId);
      }
    });
  }

  handleBookNow(ServiceDetailResponse serviceDetailResponse, {int? serviceId}) {
    BookServiceScreen(
      serviceId: serviceId,
      data: serviceDetailResponse,
      selectedPackage: selectedPackage,
      selectedShop: selectedShop,
    ).launch(context).then((value) {
      setStatusBarColor(transparentColor);
    });
  }

  bool _requiresVariantSelection(ServiceData product) {
    return product.hasVariants == true ||
        product.requiresVariantSelection == true;
  }

  Future<void> _onProductCartTap(ServiceData product) async {
    if (_isCartActionLoading) return;

    if (_requiresVariantSelection(product)) {
      doIfLoggedIn(context, () async {
        _isCartActionLoading = true;
        setState(() {});
        try {
          final ProductDetailOptionResponse detail =
              await getProductDetailOptions(productId: product.id.validate());
          if (!mounted) return;
          await _showVariantPicker(detail);
        } catch (e) {
          toast(e.toString());
        } finally {
          _isCartActionLoading = false;
          if (mounted) setState(() {});
        }
      });
      return;
    }

    _productQuantity = 1;
    _showProductQuantityControl = true;
    setState(() {});
    await _addSimpleProductToCart(product: product, quantity: 1);
  }

  Future<void> _addSimpleProductToCart({
    required ServiceData product,
    int? quantity,
  }) async {
    if (_isCartActionLoading) return;

    doIfLoggedIn(context, () async {
      _isCartActionLoading = true;
      setState(() {});
      try {
        final res = await addToCart(
          productId: product.id.validate(),
          quantity: quantity ?? _productQuantity,
        );
        if (res.containsKey('cart_id') || res.containsKey('cart_item_id')) {
          _productCartItemId =
              (res['cart_id'] ?? res['cart_item_id']).toString().toInt();
        }
        toast('Product added to cart');
        if (res.containsKey('cart_count')) {
          appStore.setCartCount(res['cart_count'].toString().toInt());
        } else {
          getCartList()
              .then((value) => appStore.setCartCount(value.cartCount))
              .catchError((e) => log(e.toString()));
        }
      } catch (e) {
        toast(e.toString());
      } finally {
        _isCartActionLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _removeProductFromCart() async {
    if (_productCartItemId == null || _isCartActionLoading) return;

    doIfLoggedIn(context, () async {
      _isCartActionLoading = true;
      setState(() {});
      try {
        final value = await removeCartItem(cartItemId: _productCartItemId!);
        _productCartItemId = null;
        toast('Product removed from cart');
        if (value.cartCount != null) {
          appStore.setCartCount(value.cartCount!);
        } else {
          getCartList()
              .then((val) => appStore.setCartCount(val.cartCount))
              .catchError((e) => log(e.toString()));
        }
      } catch (e) {
        toast(e.toString());
      } finally {
        _isCartActionLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _showVariantPicker(ProductDetailOptionResponse detail) async {
    final List<ProductVariantOption> variants = detail.variants.where((e) {
      return e.isAvailable && e.quantityLimit > 0;
    }).toList();
    if (variants.isEmpty) {
      toast('No variants available');
      return;
    }

    ProductVariantOption selectedVariant = variants.first;
    int quantity = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: boxDecorationDefault(
                      shape: BoxShape.circle, color: Colors.black54),
                  child: const Icon(Icons.close, color: white),
                ).onTap(() => finish(context)),
                16.height,
                Container(
                  decoration: boxDecorationDefault(
                    color: context.scaffoldBackgroundColor,
                    borderRadius: radiusOnly(topLeft: 24, topRight: 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(detail.product.name.validate(),
                                  style: boldTextStyle(size: 18))
                              .expand(),
                        ],
                      ).paddingAll(16),
                      Container(
                        width: context.width(),
                        color: context.cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select variant',
                                    style: boldTextStyle(size: 18))
                                .paddingSymmetric(horizontal: 16),
                            4.height,
                            Text('Select any 1', style: secondaryTextStyle())
                                .paddingSymmetric(horizontal: 16),
                            16.height,
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: boxDecorationDefault(
                                color: context.scaffoldBackgroundColor,
                                borderRadius: radius(12),
                                border: Border.all(color: context.dividerColor),
                              ),
                              child: Column(
                                children: variants.map((variant) {
                                  final bool isSelected =
                                      selectedVariant.id == variant.id;
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.stop_circle_outlined,
                                              color: Colors.green, size: 24),
                                          12.width,
                                          Text(
                                            variant.label.isNotEmpty
                                                ? variant.label
                                                : (variant
                                                        .optionValue.isNotEmpty
                                                    ? variant.optionValue
                                                    : variant.attributeName),
                                            style: boldTextStyle(size: 16),
                                          ).expand(),
                                          Text(variant.priceFormat,
                                              style: boldTextStyle(size: 16)),
                                          16.width,
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            color: isSelected
                                                ? context.primaryColor
                                                : context.dividerColor,
                                          ),
                                        ],
                                      ).paddingAll(16).onTap(() {
                                        selectedVariant = variant;
                                        modalSetState(() {});
                                      }),
                                      if (variant != variants.last)
                                        const Divider(height: 0),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: context.navigationBarHeight + 16,
                        ),
                        decoration: boxDecorationDefault(
                            color: context.scaffoldBackgroundColor),
                        child: Row(
                          children: [
                            Container(
                              height: 48,
                              decoration: boxDecorationDefault(
                                color: context.cardColor,
                                border: Border.all(color: context.primaryColor),
                                borderRadius: radius(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove,
                                        color: context.primaryColor),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        quantity--;
                                        modalSetState(() {});
                                      }
                                    },
                                  ),
                                  Text('$quantity',
                                      style: boldTextStyle(
                                          color: context.primaryColor,
                                          size: 18)),
                                  IconButton(
                                    icon: Icon(Icons.add,
                                        color: context.primaryColor),
                                    onPressed: () {
                                      if (quantity <
                                          selectedVariant.quantityLimit) {
                                        quantity++;
                                        modalSetState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            16.width,
                            AppButton(
                              height: 48,
                              color: context.primaryColor,
                              text:
                                  'Add | ${appConfigurationStore.currencySymbol}${selectedVariant.price * quantity}',
                              textStyle: boldTextStyle(color: white),
                              onTap: () async {
                                try {
                                  final res = await addToCart(
                                    productId: detail.product.id.validate(),
                                    productVariantId:
                                        selectedVariant.productVariantId,
                                    quantity: quantity,
                                  );
                                  if (res.containsKey('cart_count')) {
                                    appStore.setCartCount(
                                        res['cart_count'].toString().toInt());
                                  } else {
                                    getCartList()
                                        .then((value) => appStore
                                            .setCartCount(value.cartCount))
                                        .catchError((e) => log(e.toString()));
                                  }
                                  if (!mounted) return;
                                  finish(context);
                                  toast('Product added to cart');
                                } catch (e) {
                                  toast(e.toString());
                                }
                              },
                            ).expand(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _productCartBar(ServiceData product) {
    if (_requiresVariantSelection(product) || !_showProductQuantityControl) {
      return AppButton(
        onTap: () => _onProductCartTap(product),
        color: context.primaryColor,
        width: context.width(),
        child: _isCartActionLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(white),
                ),
              )
            : Text('Add to Cart', style: boldTextStyle(color: white)),
      ).paddingSymmetric(horizontal: 16.0, vertical: 10.0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Container(
            height: 48,
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: white,
              border: Border.all(color: context.primaryColor),
              borderRadius: radius(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, color: context.primaryColor),
                  onPressed: _isCartActionLoading
                      ? null
                      : () {
                          if (_productQuantity <= 1) {
                            _productQuantity = 0;
                            _showProductQuantityControl = false;
                            _removeProductFromCart();
                            setState(() {});
                            return;
                          }
                          _productQuantity--;
                          setState(() {});
                          _addSimpleProductToCart(
                            product: product,
                            quantity: _productQuantity,
                          );
                        },
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_productQuantity',
                    textAlign: TextAlign.center,
                    style: boldTextStyle(color: context.primaryColor, size: 18),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: context.primaryColor),
                  onPressed: _isCartActionLoading
                      ? null
                      : () {
                          _productQuantity++;
                          setState(() {});
                          _addSimpleProductToCart(
                            product: product,
                            quantity: _productQuantity,
                          );
                        },
                ),
              ],
            ),
          ),
          16.width,
          AppButton(
            onTap: () {},
            color: context.primaryColor,
            width: context.width(),
            child: _isCartActionLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(white),
                    ),
                  )
                : Text('Added to Cart', style: boldTextStyle(color: white)),
          ).expand(),
        ],
      ),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    setStatusBarColor(
        widget.isFromProviderInfo ? primaryColor : transparentColor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildBodyWidget(AsyncSnapshot<ServiceDetailResponse> snap) {
      if (snap.hasError) {
        return NoDataWidget(
          title: snap.error.toString(),
          imageWidget: ErrorStateWidget(),
          retryText: language.reload,
          onRetry: () {
            init();
          },
        ).center();
      } else if (snap.hasData) {
        return AppScaffold(
          appBarTitle: snap.data!.serviceDetail?.categoryName.validate() ?? '',
          showLoader: false,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedScrollView(
                    padding: EdgeInsets.only(
                      bottom: 120,
                    ),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    onSwipeRefresh: () async {
                      appStore.setLoading(true);
                      init();
                      setState(() {});
                      return await 2.seconds.delay;
                    },
                    children: [
                      8.height,
                      ServiceDetailHeaderComponent(
                          serviceDetail: snap.data!.serviceDetail!),
                      4.height,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (snap.data!.isAvailableAtShop) ...[
                                    ShopServiceIconWidget(),
                                    8.width,
                                  ],
                                  if (snap.data!.serviceDetail!
                                      .isOnlineService) ...[
                                    const OnlineServiceIconWidget(),
                                    10.width
                                  ],
                                  Flexible(
                                      child: Container(
                                    decoration: BoxDecoration(
                                      color: appStore.isDarkMode
                                          ? Colors.black
                                          : lightPrimaryColor,
                                      borderRadius: radius(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    child: Text(
                                      (snap.data!.serviceDetail?.categoryName
                                              .validate() ??
                                          ' '),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  )),
                                ],
                              ).expand(),
                              TextIcon(
                                suffix: Row(
                                  children: [
                                    Image.asset(
                                      ic_star_fill,
                                      height: 18,
                                      color: getRatingBarColor(snap
                                          .data!.serviceDetail!.totalRating
                                          .validate()
                                          .toInt()),
                                    ),
                                    4.width,
                                    Text(
                                        snap.data!.serviceDetail!.totalRating
                                            .validate()
                                            .toStringAsFixed(1),
                                        style: boldTextStyle()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          12.height,
                          Text(
                            snap.data!.serviceDetail!.name.validate(),
                            style: primaryTextStyle(
                                weight: FontWeight.bold, size: 16),
                          ),
                          10.height,
                          if (convertToHourMinute(
                                  snap.data!.serviceDetail!.duration.validate())
                              .isNotEmpty)
                            Row(
                              children: [
                                Text(language.duration,
                                    style: secondaryTextStyle()),
                                8.width,
                                Text(
                                  convertToHourMinute(snap
                                      .data!.serviceDetail!.duration
                                      .validate()),
                                  style: secondaryTextStyle(
                                      weight: FontWeight.bold,
                                      color: textPrimaryColorGlobal),
                                )
                              ],
                            ),
                          10.height,
                          Row(
                            children: [
                              if (snap.data!.serviceDetail!.discount
                                      .validate() >
                                  0)
                                PriceWidget(
                                  size: 14,
                                  price: snap
                                      .data!.serviceDetail!.getDiscountedPrice
                                      .validate(),
                                ).paddingRight(8),
                              PriceWidget(
                                size: snap.data!.serviceDetail!.discount != 0
                                    ? 12
                                    : 14,
                                price:
                                    snap.data!.serviceDetail!.price.validate(),
                                isLineThroughEnabled:
                                    snap.data!.serviceDetail!.discount != 0
                                        ? true
                                        : false,
                                color: snap.data!.serviceDetail!.discount != 0
                                    ? textSecondaryColorGlobal
                                    : primaryColor,
                              ),
                              10.width,
                              if (snap.data!.serviceDetail!.discount
                                      .validate() >
                                  0)
                                Text(
                                  "${snap.data!.serviceDetail!.discount.validate()}% ${language.lblOff}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      color: defaultActivityStatus,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ).expand(),
                            ],
                          ),
                          10.height
                        ],
                      ).paddingSymmetric(horizontal: 16),
                      Container(
                        width: context.width(),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: radius(),
                          border: appStore.isDarkMode
                              ? Border.all(color: context.dividerColor)
                              : null,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            snap.data!.serviceDetail!.description
                                    .validate()
                                    .isNotEmpty
                                ? ReadMoreText(
                                    snap.data!.serviceDetail!.description
                                        .validate(),
                                    style: secondaryTextStyle(),
                                    colorClickableText: context.primaryColor,
                                    textAlign: TextAlign.justify,
                                  )
                                : Text(language.lblNotDescription,
                                    style: secondaryTextStyle()),
                            8.height,
                            slotsAvailable(
                              data: snap.data!.serviceDetail!.bookingSlots
                                  .validate(),
                              isSlotAvailable:
                                  snap.data!.serviceDetail!.isSlotAvailable,
                            ),
                            availableWidget(
                              data: snap.data!.serviceDetail!,
                              zone: snap.data!,
                            ),
                          ],
                        ),
                      ).paddingSymmetric(horizontal: 16, vertical: 8),
                      if (snap.data!.provider != null)
                        providerWidget(data: snap.data!.provider!),
                      if (snap.data!.shops.validate().isNotEmpty)
                        HorizontalShopListComponent(
                          listTitle: language.lblAboutShop,
                          shopList: snap.data!.shops.validate(),
                          cardWidth: context.width() * 0.9,
                          serviceId: snap.data!.serviceDetail!.id.validate(),
                          serviceName:
                              snap.data!.serviceDetail!.name.validate(),
                          showServices: false,
                        ),
                      if (snap.data!.serviceDetail!.servicePackage
                          .validate()
                          .isNotEmpty)
                        PackageComponent(
                          servicePackage: snap
                              .data!.serviceDetail!.servicePackage
                              .validate(),
                          callBack: (v) {
                            if (v != null) {
                              selectedPackage = v;
                            } else {
                              selectedPackage = null;
                            }
                            bookNow(snap.data!);
                          },
                        ),
                      if (snap.data!.serviceaddon.validate().isNotEmpty)
                        AddonComponent(
                          serviceAddon: snap.data!.serviceaddon.validate(),
                          onSelectionChange: (v) {
                            serviceAddonStore.setSelectedServiceAddon(v);
                          },
                        ),
                      serviceFaqWidget(data: snap.data!.serviceFaq.validate())
                          .paddingSymmetric(horizontal: 16),
                      reviewWidget(
                          data: snap.data!.ratingData!,
                          serviceDetailResponse: snap.data!),
                      24.height,
                      if (snap.data!.relatedService.validate().isNotEmpty)
                        relatedServiceWidget(
                          serviceList: snap.data!.relatedService.validate(),
                          serviceId: snap.data!.serviceDetail!.id.validate(),
                        ),
                    ],
                  ),
                ),
                if (widget.detailType == 'product')
                  _productCartBar(snap.data!.serviceDetail!)
                else
                  AppButton(
                    onTap: () {
                      selectedPackage = null;
                      bookNow(snap.data!);
                    },
                    color: context.primaryColor,
                    child: Text(language.lblBookNow,
                        style: boldTextStyle(color: white)),
                    width: context.width(),
                    textColor: Colors.white,
                  ).paddingSymmetric(horizontal: 16.0, vertical: 10.0)
              ],
            ),
          ),
        );
      }
      return ServiceDetailShimmer();
    }

    return FutureBuilder<ServiceDetailResponse>(
      initialData: listOfCachedData
          .firstWhere((element) => element?.$1 == widget.serviceId.validate(),
              orElse: () => null)
          ?.$2,
      future: future,
      builder: (context, snap) {
        return Scaffold(
          body: Stack(
            children: [
              buildBodyWidget(snap),
              Observer(
                  builder: (context) =>
                      LoaderWidget().visible(appStore.isLoading)),
            ],
          ),
        );
      },
    );
  }
}
