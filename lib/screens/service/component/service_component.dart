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
    _quantityController.text = '1';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: radiusOnly(topLeft: 16, topRight: 16)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedImageWidget(
                        url: detail.product.firstServiceImage.validate(),
                        height: 44,
                        width: 44,
                        fit: BoxFit.cover,
                      ).cornerRadiusWithClipRRect(8),
                      12.width,
                      Text(
                        detail.product.name.validate(),
                        style: boldTextStyle(size: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ).expand(),
                    ],
                  ),
                  12.height,
                  Text('Select variant', style: boldTextStyle(size: 18)),
                  4.height,
                  Text('Select any 1', style: secondaryTextStyle()),
                  12.height,
                  Container(
                    decoration: boxDecorationDefault(color: context.cardColor),
                    child: Column(
                      children: variants.map((variant) {
                        final bool isSelected = selectedVariant.id == variant.id;
                        return RadioListTile<int>(
                          value: variant.id,
                          groupValue: selectedVariant.id,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          title: Text(
                            variant.label.isNotEmpty
                                ? variant.label
                                : (variant.optionValue.isNotEmpty ? variant.optionValue : variant.attributeName),
                            style: boldTextStyle(size: 16),
                          ),
                          subtitle: Text(
                            variant.priceFormat.isNotEmpty ? variant.priceFormat : '${variant.price}',
                            style: boldTextStyle(size: 15),
                          ),
                          activeColor: context.primaryColor,
                          onChanged: (value) {
                            if (value == null) return;
                            selectedVariant = variants.firstWhere((e) => e.id == value);
                            if (quantity > selectedVariant.quantityLimit) {
                              quantity = selectedVariant.quantityLimit;
                            }
                            modalSetState(() {});
                          },
                          selected: isSelected,
                        );
                      }).toList(),
                    ),
                  ),
                  16.height,
                  Row(
                    children: [
                      Container(
                        decoration: boxDecorationDefault(
                          color: context.cardColor,
                          border: Border.all(color: context.primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantity > 1) {
                                  quantity--;
                                  modalSetState(() {});
                                }
                              },
                            ),
                            Text('$quantity', style: boldTextStyle(size: 16)),
                            IconButton(
                              icon: const Icon(Icons.add),
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
                      12.width,
                      AppButton(
                        width: 0,
                        color: context.primaryColor,
                        textColor: white,
                        text: 'Add | ${selectedVariant.priceFormat.isNotEmpty ? selectedVariant.priceFormat : selectedVariant.price}',
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
                          } catch (e) {
                            toast(e.toString());
                          }
                        },
                      ).expand(),
                    ],
                  ),
                ],
              ),
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
          _onProductActionTap();
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
          buildServiceComponent(),
          if (_isProductCard)
            Align(
              alignment: Alignment.centerRight,
              child: _requiresVariantSelection || !_showInlineQuantityControl
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: boxDecorationDefault(color: context.primaryColor),
                      child: IconButton(
                        onPressed: _isCartActionLoading
                            ? null
                            : () {
                                if (_requiresVariantSelection) {
                                  _onProductActionTap();
                                } else {
                                  _cardQuantity = 1;
                                  _showInlineQuantityControl = true;
                                  setState(() {});
                                  _addSimpleProductToCart(quantity: 1);
                                }
                              },
                        icon: const Icon(Icons.add, color: white),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: boxDecorationDefault(
                        color: context.cardColor,
                        border: Border.all(color: context.primaryColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _isCartActionLoading
                                ? null
                                : () {
                                    if (_cardQuantity <= 1) {
                                      _showInlineQuantityControl = false;
                                      setState(() {});
                                      return;
                                    }
                                    _cardQuantity--;
                                    setState(() {});
                                    _addSimpleProductToCart(quantity: _cardQuantity);
                                  },
                          ),
                          Text('$_cardQuantity', style: boldTextStyle()),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _isCartActionLoading
                                ? null
                                : () {
                                    _cardQuantity++;
                                    setState(() {});
                                    _addSimpleProductToCart(quantity: _cardQuantity);
                                  },
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
