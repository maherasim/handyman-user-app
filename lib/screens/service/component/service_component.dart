import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/generated/assets.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_4/component/service_dashboard_component_4.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../newDashboard/dashboard_1/component/service_dashboard_component_1.dart';
import '../../newDashboard/dashboard_2/component/service_dashboard_component_2.dart';
import '../../newDashboard/dashboard_3/component/service_dashboard_component_3.dart';

class ServiceComponent extends StatefulWidget {
  final ServiceData serviceData;
  final double? width;
  final bool? isBorderEnabled;
  final VoidCallback? onUpdate;
  final bool isFavouriteService;
  final bool isFromDashboard;
  final bool isFromViewAllService;
  final bool isFromServiceDetail;

  ServiceComponent({
    required this.serviceData,
    this.width,
    this.isBorderEnabled,
    this.isFavouriteService = false,
    this.onUpdate,
    this.isFromDashboard = false,
    this.isFromViewAllService = false,
    this.isFromServiceDetail = false,
  });

  @override
  ServiceComponentState createState() => ServiceComponentState();
}

class ServiceComponentState extends State<ServiceComponent> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  bool _isCartActionLoading = false;
  int _cardQuantity = 1;
  bool _showInlineQuantityControl = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  bool get _isProductCard {
    final String itemType = widget.serviceData.serviceType.validate().toLowerCase();
    return itemType == 'ecommerce' || itemType == 'product';
  }

  bool get _requiresVariantSelection {
    return widget.serviceData.hasVariants == true || widget.serviceData.requiresVariantSelection == true;
  }

  Future<void> _onProductActionTap() async {
    if (_isCartActionLoading) return;

    doIfLoggedIn(context, () async {
      _isCartActionLoading = true;
      setState(() {});
      try {
        if (_requiresVariantSelection) {
          final ProductDetailOptionResponse detail = await getProductDetailOptions(
            productId: widget.serviceData.id.validate(),
          );
          if (!mounted) return;
          await _showVariantPicker(detail);
        } else {
          await addToCart(productId: widget.serviceData.id.validate(), quantity: 1);
          toast('Product added to cart');
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
                  decoration: boxDecorationDefault(shape: BoxShape.circle, color: Colors.black54),
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
                          CachedImageWidget(
                            url: detail.product.firstServiceImage.validate(),
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ).cornerRadiusWithClipRRect(12),
                          16.width,
                          Text(detail.product.name.validate(), style: boldTextStyle(size: 18)).expand(),
                        ],
                      ).paddingAll(16),
                      Container(
                        width: context.width(),
                        color: context.cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select variant', style: boldTextStyle(size: 18)).paddingSymmetric(horizontal: 16),
                            4.height,
                            Text('Select any 1', style: secondaryTextStyle()).paddingSymmetric(horizontal: 16),
                            16.height,
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: boxDecorationDefault(
                                color: context.scaffoldBackgroundColor,
                                borderRadius: radius(12),
                                border: Border.all(color: context.dividerColor),
                              ),
                              child: Column(
                                children: variants.map((variant) {
                                  final bool isSelected = selectedVariant.id == variant.id;
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.stop_circle_outlined, color: Colors.green, size: 24),
                                          12.width,
                                          Text(
                                            variant.label.isNotEmpty
                                                ? variant.label
                                                : (variant.optionValue.isNotEmpty ? variant.optionValue : variant.attributeName),
                                            style: boldTextStyle(size: 16),
                                          ).expand(),
                                          Text(variant.priceFormat, style: boldTextStyle(size: 16)),
                                          16.width,
                                          Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                            color: isSelected ? context.primaryColor : context.dividerColor,
                                          ),
                                        ],
                                      ).paddingAll(16).onTap(() {
                                        selectedVariant = variant;
                                        modalSetState(() {});
                                      }),
                                      if (variant != variants.last) const Divider(height: 0),
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
                        decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor),
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
                                    icon: Icon(Icons.remove, color: context.primaryColor),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        quantity--;
                                        modalSetState(() {});
                                      }
                                    },
                                  ),
                                  Text('$quantity', style: boldTextStyle(color: context.primaryColor, size: 18)),
                                  IconButton(
                                    icon: Icon(Icons.add, color: context.primaryColor),
                                    onPressed: () {
                                      if (quantity < selectedVariant.quantityLimit) {
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
                              text: 'Add | ${appConfigurationStore.currencySymbol}${selectedVariant.price * quantity}',
                              textStyle: boldTextStyle(color: white),
                              onTap: () async {
                                try {
                                  await addToCart(
                                    productId: detail.product.id.validate(),
                                    productVariantId: selectedVariant.productVariantId,
                                    quantity: quantity,
                                  );
                                  if (!mounted) return;
                                  finish(context);
                                  toast('Product added to cart');
                                  widget.onUpdate?.call();
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

  Future<void> _addSimpleProductToCart({int? quantity}) async {
    if (_isCartActionLoading) return;
    doIfLoggedIn(context, () async {
      _isCartActionLoading = true;
      setState(() {});
      try {
        await addToCart(productId: widget.serviceData.id.validate(), quantity: quantity ?? _cardQuantity);
        toast('Product added to cart');
      } catch (e) {
        toast(e.toString());
      } finally {
        _isCartActionLoading = false;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String resolveDetailType() {
      final String itemType = widget.serviceData.serviceType.validate().toLowerCase();
      if (itemType == 'ecommerce' || itemType == 'product') return 'product';
      if (itemType == 'classified' || itemType == 'post') return 'post';
      return 'service';
    }

    Widget buildProductComponent() {
      return Container(
        width: widget.width,
        decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(12),
          backgroundColor: context.cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedImageWidget(
                  url: widget.serviceData.firstServiceImage.validate(),
                  height: 180,
                  width: widget.width ?? context.width(),
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRectOnly(topLeft: 12, topRight: 12),
                if (widget.serviceData.discount.validate() > 0)
                  Positioned(
                    top: 12,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: Colors.green.withValues(alpha: 0.9),
                        borderRadius: radiusOnly(topRight: 8, bottomRight: 8),
                      ),
                      child: Text(
                        "${widget.serviceData.discount}% OFF",
                        style: boldTextStyle(color: white, size: 10),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: boxDecorationWithShadow(boxShape: BoxShape.circle, backgroundColor: context.cardColor),
                    child: widget.serviceData.isFavourite == 1 ? Icon(Icons.bookmark, color: context.primaryColor, size: 20) : Icon(Icons.bookmark_border, color: context.dividerColor, size: 20),
                  ).onTap(() async {
                    if (widget.serviceData.isFavourite != 0) {
                      widget.serviceData.isFavourite = 1;
                      setState(() {});

                      await removeToWishList(serviceId: widget.serviceData.serviceId.validate().toInt()).then((value) {
                        if (!value) {
                          widget.serviceData.isFavourite = 1;
                          setState(() {});
                        }
                      });
                    } else {
                      widget.serviceData.isFavourite = 0;
                      setState(() {});

                      await addToWishList(serviceId: widget.serviceData.serviceId.validate().toInt()).then((value) {
                        if (!value) {
                          widget.serviceData.isFavourite = 1;
                          setState(() {});
                        }
                      });
                    }
                    widget.onUpdate?.call();
                  }),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _requiresVariantSelection || !_showInlineQuantityControl
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: white,
                            border: Border.all(color: context.primaryColor),
                            borderRadius: radius(8),
                          ),
                          child: Icon(Icons.add, color: context.primaryColor, size: 24),
                        ).onTap(() {
                          if (_requiresVariantSelection) {
                            _onProductActionTap();
                          } else {
                            _cardQuantity = 1;
                            _showInlineQuantityControl = true;
                            setState(() {});
                            _addSimpleProductToCart(quantity: 1);
                          }
                        })
                      : Container(
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: white,
                            border: Border.all(color: context.primaryColor),
                            borderRadius: radius(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.remove, color: context.primaryColor, size: 20).paddingAll(4).onTap(() {
                                if (_cardQuantity <= 1) {
                                  _showInlineQuantityControl = false;
                                  setState(() {});
                                  return;
                                }
                                _cardQuantity--;
                                setState(() {});
                                _addSimpleProductToCart(quantity: _cardQuantity);
                              }),
                              4.width,
                              Text('$_cardQuantity', style: boldTextStyle(color: context.primaryColor)),
                              4.width,
                              Icon(Icons.add, color: context.primaryColor, size: 20).paddingAll(4).onTap(() {
                                _cardQuantity++;
                                setState(() {});
                                _addSimpleProductToCart(quantity: _cardQuantity);
                              }),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                8.height,
                Text(
                  widget.serviceData.name.validate(),
                  style: boldTextStyle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.height,
                Row(
                  children: [
                    PriceWidget(
                      price: widget.serviceData.price.validate(),
                      color: context.primaryColor,
                      size: 16,
                    ),
                    if (widget.serviceData.discount.validate() > 0) ...[
                      8.width,
                      Text(
                        "${appConfigurationStore.currencySymbol}${widget.serviceData.price.validate()}",
                        style: secondaryTextStyle(decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ],
                ),
                4.height,
                Row(
                  children: [
                    DisabledRatingBarWidget(rating: widget.serviceData.totalRating.validate(), size: 12),
                    4.width,
                    Text("(${widget.serviceData.totalReview.validate().toInt()})", style: secondaryTextStyle(size: 10)),
                  ],
                ),
                8.height,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: radius(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: context.primaryColor),
                      4.width,
                      Text(
                        "${DateTime.parse(widget.serviceData.createdAt.validate(value: DateTime.now().toString())).timeAgo}",
                        style: boldTextStyle(size: 10, color: context.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ).paddingSymmetric(horizontal: 8, vertical: 8),
          ],
        ),
      );
    }

    Widget buildServiceComponent() {
      return Observer(builder: (context) {
        if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
          return ServiceDashboardComponent1(
            serviceData: widget.serviceData,
            width: widget.width ?? (widget.isFromViewAllService ? null : 280),
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            isFromDashboard: widget.isFromDashboard,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_2) {
          return ServiceDashboardComponent2(
            serviceData: widget.serviceData,
            width: widget.width ?? (widget.isFromViewAllService ? null : 280),
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            isFromDashboard: widget.isFromDashboard,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_3) {
          return ServiceDashboardComponent3(
            serviceData: widget.serviceData,
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            isFromDashboard: widget.isFromDashboard,
            width: widget.width ?? (widget.isFromViewAllService ? null : 280),
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_4) {
          return ServiceDashboardComponent4(
            serviceData: widget.serviceData,
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            width: widget.width ?? (widget.isFromViewAllService ? null : 280),
            isFromDashboard: widget.isFromDashboard,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else {
          return Container(
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: radius(),
              backgroundColor: context.cardColor,
              border: widget.isBorderEnabled.validate(value: false)
                  ? appStore.isDarkMode
                      ? Border.all(color: context.dividerColor)
                      : null
                  : null,
            ),
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 205,
                  width: context.width(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CachedImageWidget(
                        url: widget.isFavouriteService && widget.serviceData.serviceAttachments.validate().isNotEmpty
                            ? widget.serviceData.serviceAttachments!.first.validate()
                            : widget.serviceData.firstServiceImage.validate(),
                        fit: BoxFit.cover,
                        height: 180,
                        width: widget.width ?? context.width(),
                        circle: false,
                      ).cornerRadiusWithClipRRectOnly(topRight: defaultRadius.toInt(), topLeft: defaultRadius.toInt()),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          constraints: BoxConstraints(maxWidth: context.width() * 0.3),
                          decoration: boxDecorationWithShadow(
                            backgroundColor: context.cardColor.withValues(alpha: 0.9),
                            borderRadius: radius(24),
                          ),
                          child: Text(
                            "${widget.serviceData.subCategoryName.validate().isNotEmpty ? widget.serviceData.subCategoryName.validate() : widget.serviceData.categoryName.validate()}".toUpperCase(),
                            style: boldTextStyle(color: appStore.isDarkMode ? white : primaryColor, size: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).paddingSymmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      if (widget.serviceData.isOnlineService)
                        const Positioned(
                          top: 20,
                          right: 12,
                          child: Icon(Icons.circle, color: Colors.green, size: 12),
                        ),
                      if (widget.serviceData.isOnShopService)
                        Positioned(
                          top: 12,
                          right: 4,
                          child: Container(
                            decoration: boxDecorationDefault(
                              color: primaryColor,
                              borderRadius: radius(20),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(6), // 🔹 Reduced from 6 to 4
                              child: Image.asset(
                                Assets.iconsIcDefaultShop,
                                height: 12,
                                color: Colors.white,
                              ),
                              decoration: boxDecorationDefault(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      if (widget.isFavouriteService)
                        Positioned(
                          top: 8,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: boxDecorationWithShadow(boxShape: BoxShape.circle, backgroundColor: context.cardColor),
                            child: widget.serviceData.isFavourite == 1 ? ic_fill_heart.iconImage(color: favouriteColor, size: 18) : ic_heart.iconImage(color: unFavouriteColor, size: 18),
                          ).onTap(() async {
                            if (widget.serviceData.isFavourite != 0) {
                              widget.serviceData.isFavourite = 1;
                              setState(() {});

                              await removeToWishList(serviceId: widget.serviceData.serviceId.validate().toInt()).then((value) {
                                if (!value) {
                                  widget.serviceData.isFavourite = 1;
                                  setState(() {});
                                }
                              });
                            } else {
                              widget.serviceData.isFavourite = 0;
                              setState(() {});

                              await addToWishList(serviceId: widget.serviceData.serviceId.validate().toInt()).then((value) {
                                if (!value) {
                                  widget.serviceData.isFavourite = 1;
                                  setState(() {});
                                }
                              });
                            }
                            widget.onUpdate?.call();
                          }),
                        ),
                      Positioned(
                        bottom: 12,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: boxDecorationWithShadow(
                            backgroundColor: primaryColor,
                            borderRadius: radius(24),
                            border: Border.all(color: context.cardColor, width: 2),
                          ),
                          child: PriceWidget(
                            price: widget.serviceData.price.validate(),
                            isHourlyService: widget.serviceData.isHourlyService,
                            color: Colors.white,
                            hourlyTextColor: Colors.white,
                            size: 14,
                            isFreeService: widget.serviceData.type.validate() == SERVICE_TYPE_FREE,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DisabledRatingBarWidget(rating: widget.serviceData.totalRating.validate(), size: 14).paddingSymmetric(horizontal: 16),
                    8.height,
                    Text(
                      widget.serviceData.name.validate(),
                      style: boldTextStyle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).paddingSymmetric(horizontal: 16),
                    8.height,
                    Row(
                      children: [
                        ImageBorder(src: widget.serviceData.providerImage.validate(), height: 30),
                        8.width,
                        if (widget.serviceData.providerName.validate().isNotEmpty)
                          Text(
                            widget.serviceData.providerName.validate(),
                            style: secondaryTextStyle(size: 12, color: appStore.isDarkMode ? Colors.white : appTextSecondaryColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).expand()
                      ],
                    ).onTap(() async {
                      if (widget.serviceData.providerId != appStore.userId.validate()) {
                        await ProviderInfoScreen(providerId: widget.serviceData.providerId.validate()).launch(context);
                        setStatusBarColor(Colors.transparent);
                      }
                    }).paddingSymmetric(horizontal: 16),
                    16.height,
                  ],
                ),
              ],
            ),
          );
        }
      });
    }

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
        if (_isProductCard) {
          if (_requiresVariantSelection) {
            _onProductActionTap();
          } else {
            // If no variants, just go to detail or add to cart?
            // Usually detail is better on whole card tap
            ServiceDetailScreen(
              serviceId: widget.isFavouriteService ? widget.serviceData.serviceId.validate().toInt() : widget.serviceData.id.validate(),
              detailType: resolveDetailType(),
            ).launch(context).then((value) {
              setStatusBarColor(context.primaryColor);
              widget.onUpdate?.call();
            });
          }
          return;
        }
        ServiceDetailScreen(
          serviceId: widget.isFavouriteService ? widget.serviceData.serviceId.validate().toInt() : widget.serviceData.id.validate(),
          detailType: resolveDetailType(),
        ).launch(context).then((value) {
          setStatusBarColor(context.primaryColor);
          widget.onUpdate?.call();
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isProductCard ? buildProductComponent() : buildServiceComponent(),
        ],
      ),
    );
  }
}
