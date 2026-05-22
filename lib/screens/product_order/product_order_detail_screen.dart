import 'dart:async';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_detail_model.dart';
import 'package:booking_system_flutter/model/product_order_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_history_list_widget.dart';
import 'package:booking_system_flutter/screens/booking/handyman_info_screen.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/chat/user_chat_screen.dart';
import 'package:booking_system_flutter/screens/zoom_image_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
  ProductOrderLocation? liveLocation;
  gmaps.GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    future = getProductOrderDetail(widget.orderId).then((value) {
      if (_normalizeStatus(value.deliveryStatus) == 'on_going' ||
          _normalizeStatus(value.status) == 'on_going' ||
          _normalizeStatus(value.deliveryStatus) == 'delivered' ||
          _normalizeStatus(value.status) == 'delivered') {
        getProductOrderLocation(widget.orderId).then((loc) {
          if (mounted) {
            setState(() {
              liveLocation = loc;
              if (mapController != null) {
                mapController!.animateCamera(
                  gmaps.CameraUpdate.newLatLngZoom(
                    gmaps.LatLng(loc.latitude.toDouble(), loc.longitude.toDouble()),
                    14.0,
                  ),
                );
              }
            });
          }
        }).catchError((e) {
          log(e.toString());
        });
      }
      return value;
    });
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
              _provider(order.provider, order.handyman),
              _handyman(order.handyman, order.provider),
              _locationTrackWidget(order),
              _summary(order),
              16.height,
              _shipping(order.shipping),
              16.height,
              _items(order.items),
              _proofList(order),
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
          8.height,
          TextButton(
            onPressed: () {
              _showOrderStatus(order);
            },
            child: Text(
              language.viewStatus,
              style: boldTextStyle(color: primaryColor, size: 14),
            ),
          ).center(),
        ],
      ),
    );
  }

  void _showOrderStatus(ProductOrderData order) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.50,
          minChildSize: 0.2,
          maxChildSize: 1,
          builder: (context, scrollController) {
            return _ProductOrderStatusHistorySheet(
              orderId: order.id,
              activity: order.activity.reversed.toList(),
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Widget _provider(
      ProductOrderContact? provider, ProductOrderContact? handyman) {
    if (provider == null) return const Offstage();
    final bool providerIsHandyman =
        handyman != null && provider.id == handyman.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'About Vendor',
                    style: boldTextStyle(size: LABEL_TEXT_SIZE),
                  ),
                  if (providerIsHandyman)
                    TextSpan(
                      text: ' (as Delivery Boy)',
                      style: secondaryTextStyle(size: LABEL_TEXT_SIZE),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: provider.id > 0
                  ? () {
                      ProviderInfoScreen(
                        providerId: provider.id,
                        canCustomerContact: true,
                      ).launch(context).then((value) {
                        setStatusBarColor(context.primaryColor);
                      });
                    }
                  : null,
              child: Text(language.viewDetail, style: secondaryTextStyle()),
            ),
          ],
        ),
        _contactCard(contact: provider, isProvider: true),
      ],
    );
  }

  Widget _handyman(
      ProductOrderContact? handyman, ProductOrderContact? provider) {
    if (handyman == null) return const Offstage();
    if (provider != null && provider.id == handyman.id) return const Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About Delivery Boy',
              style: boldTextStyle(size: LABEL_TEXT_SIZE),
            ),
            GestureDetector(
              onTap: handyman.id > 0
                  ? () {
                      HandymanInfoScreen(handymanId: handyman.id)
                          .launch(context)
                          .then((value) => null);
                    }
                  : null,
              child: Text(
                language.viewDetail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: handyman.id > 0 ? primaryColor : textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
        16.height,
        _contactCard(contact: handyman, isProvider: false),
      ],
    );
  }

  Widget _contactCard({
    required ProductOrderContact contact,
    required bool isProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        border: appStore.isDarkMode
            ? Border.all(color: context.dividerColor)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageBorder(src: contact.profileImage.validate(), height: 60),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Marquee(
                        child: Text(contact.displayName.validate(value: '-'),
                            style: boldTextStyle()),
                      ).flexible(),
                      16.width,
                      Image.asset(ic_verified, height: 16, color: Colors.green)
                          .visible(contact.isVerified == 1),
                      if (contact.contactNumber.isNotEmpty) ...[
                        16.width,
                        GestureDetector(
                          onTap: () {
                            _launchWhatsApp(contact.contactNumber);
                          },
                          child: Image.asset(ic_whatsapp, height: 22),
                        ),
                      ],
                    ],
                  ),
                  4.height,
                  Row(
                    children: [
                      Image.asset(
                        ic_star_fill,
                        height: 14,
                        fit: BoxFit.fitWidth,
                        color: getRatingBarColor(contact.rating.toInt()),
                      ),
                      4.width,
                      Text(
                        contact.rating.toStringAsFixed(1),
                        style:
                            boldTextStyle(color: textSecondaryColor, size: 14),
                      ),
                    ],
                  ),
                ],
              ).expand(),
            ],
          ),
          if (contact.email.isNotEmpty ||
              contact.contactNumber.isNotEmpty ||
              contact.address.isNotEmpty) ...[
            16.height,
            if (contact.email.isNotEmpty)
              _infoRow(language.email, contact.email),
            if (contact.contactNumber.isNotEmpty)
              _infoRow(language.mobile, contact.contactNumber),
            if (contact.address.isNotEmpty)
              _infoRow(language.hintAddress, contact.address),
          ],
          8.height,
          Divider(color: context.dividerColor),
          8.height,
          Row(
            children: [
              if (contact.contactNumber.isNotEmpty)
                AppButton(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ic_calling.iconImage(size: 18, color: Colors.white),
                      8.width,
                      Text(language.lblCall,
                          style: boldTextStyle(color: white)),
                    ],
                  ).fit(),
                  width: context.width(),
                  color: primaryColor,
                  elevation: 0,
                  onTap: () {
                    launchCall(contact.contactNumber);
                  },
                ).paddingRight(16).expand(),
              AppButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ic_chat.iconImage(size: 18),
                    8.width,
                    Text(language.lblChat, style: boldTextStyle()),
                  ],
                ).fit(),
                width: context.width(),
                elevation: 0,
                color: context.scaffoldBackgroundColor,
                onTap: () async {
                  _openChat(contact);
                },
              ).expand(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationTrackWidget(ProductOrderData order) {
    final bool canTrack =
        _normalizeStatus(order.deliveryStatus) == 'on_going' ||
            _normalizeStatus(order.status) == 'on_going' ||
            _normalizeStatus(order.deliveryStatus) == 'delivered' ||
            _normalizeStatus(order.status) == 'delivered';

    if (!canTrack) return const Offstage();

    final ProductOrderLocation location = liveLocation ?? order.latestLocation ??
        ProductOrderLocation(latitude: 0, longitude: 0, datetime: '');
    final gmaps.LatLng latLng = gmaps.LatLng(
        location.latitude.toDouble(), location.longitude.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text('Delivery Boy Location', style: boldTextStyle()),
        4.height,
        if (location.datetime.isNotEmpty)
          Row(
            children: [
              Text('${language.lastUpdatedAt} ',
                  style: secondaryTextStyle(size: 10)),
              Text(
                DateTime.parse(location.datetime).timeAgo,
                style: primaryTextStyle(size: 10),
              ),
            ],
          )
        else
          Text('Location is not updated yet',
              style: secondaryTextStyle(size: 10)),
        8.height,
        SizedBox(
          height: 250,
          child: gmaps.GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              if (liveLocation != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    controller.animateCamera(
                      gmaps.CameraUpdate.newLatLngZoom(
                        gmaps.LatLng(liveLocation!.latitude.toDouble(), liveLocation!.longitude.toDouble()),
                        14.0,
                      ),
                    );
                  }
                });
              }
            },
            zoomControlsEnabled: true,
            initialCameraPosition: gmaps.CameraPosition(
              target: latLng,
              zoom: 14.0,
            ),
            mapType: gmaps.MapType.normal,
            minMaxZoomPreference: const gmaps.MinMaxZoomPreference(1, 40),
            gestureRecognizers: Set()
              ..add(Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()))
              ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
              ..add(Factory<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer()))
              ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
              ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
            markers: {
              gmaps.Marker(
                markerId: const gmaps.MarkerId('productOrderLocation'),
                position: latLng,
              ),
            },
          ),
        ),
        10.height,
        Row(
          children: [
            AppButton(
              onTap: () {
                ProductOrderTrackLocation(
                  orderId: order.id,
                  initialLocation: order.latestLocation,
                ).launch(context);
              },
              padding: const EdgeInsets.only(top: 0, left: 8, right: 8),
              height: 42,
              color: const Color(0xFF39A81D),
              textColor: white,
              text: language.track,
            ).expand(),
            16.width,
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(12),
              decoration: boxDecorationDefault(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: const CachedImageWidget(
                url: ic_refresh,
                color: textSecondaryColor,
                height: 42,
              ),
            ).onTap(() {
              _refreshProductOrderLocation(order.id);
            }),
            16.width,
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(12),
              decoration: boxDecorationDefault(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: const CachedImageWidget(
                url: ic_share,
                color: textSecondaryColor,
                height: 22,
              ),
            ).onTap(() {
              share(
                url:
                    'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                context: context,
              );
            }),
          ],
        ),
      ],
    );
  }

  String _normalizeStatus(String value) {
    return value.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  Future<void> _refreshProductOrderLocation(int orderId) async {
    appStore.setLoading(true);
    try {
      final loc = await getProductOrderLocation(orderId);
      liveLocation = loc;
      if (mapController != null) {
        mapController!.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(
            gmaps.LatLng(loc.latitude.toDouble(), loc.longitude.toDouble()),
            14.0,
          ),
        );
      }
      refreshOrder();
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
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

  String _shippingAddress(ProductOrderShipping shipping) {
    return [
      shipping.address,
      shipping.city,
      shipping.state,
      shipping.pincode,
      shipping.country,
    ].where((element) => element.trim().isNotEmpty).join(', ');
  }

  void _launchWhatsApp(String contactNumber) {
    String phoneNumber = '';
    if (contactNumber.validate().contains('+')) {
      phoneNumber = contactNumber.validate().replaceAll('-', '');
    } else {
      phoneNumber = '+${contactNumber.validate().replaceAll('-', '')}';
    }

    launchUrl(
      Uri.parse('${getSocialMediaLink(LinkProvider.WHATSAPP)}$phoneNumber'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _openChat(ProductOrderContact contact) async {
    if (contact.email.isEmpty && contact.id == 0 && contact.uid.isEmpty) {
      toast(language.isNotAvailableForChat);
      return;
    }

    toast(language.pleaseWaitWhileWeLoadChatDetails);

    UserData? user;
    if (contact.uid.isNotEmpty) {
      user = UserData(
        id: contact.id,
        uid: contact.uid,
        firstName: contact.firstName,
        lastName: contact.lastName,
        displayName: contact.displayName,
        profileImage: contact.profileImage,
        email: contact.email,
        contactNumber: contact.contactNumber,
      );
    }

    if ((user?.uid.validate().isEmpty ?? true) && contact.id > 0) {
      try {
        user = await getUserDetail(contact.id);
      } catch (e) {
        log(e.toString());
      }
    }

    if ((user?.uid.validate().isEmpty ?? true) && contact.email.isNotEmpty) {
      user = await userService.getUserNull(email: contact.email);
    }

    Fluttertoast.cancel();

    if (user != null && user.uid.validate().isNotEmpty) {
      UserChatScreen(receiverUser: user, chatType: 'product_order')
          .launch(context);
    } else {
      toast(
          '${contact.displayName.validate(value: 'User')} ${language.isNotAvailableForChat}');
    }
  }

  Widget _shipping(ProductOrderShipping? shipping) {
    if (shipping == null) return const Offstage();

    return _section(
      title: 'Shipping',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shipping.name.validate(value: '-'), style: boldTextStyle()),
          6.height,
          Text(_shippingAddress(shipping), style: secondaryTextStyle(size: 13)),
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

  Widget _proofList(ProductOrderData order) {
    if (!_isDelivered(order)) return const Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text('Proof List', style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        order.proof.isNotEmpty
            ? _proofListBody(order.proof)
            : SnapHelperWidget<List<ProductOrderProof>>(
                future: getProductOrderProofList(order.id),
                loadingWidget: LoaderWidget(),
                errorBuilder: (error) {
                  return Text(error.toString(), style: secondaryTextStyle())
                      .paddingAll(16);
                },
                onSuccess: (proofList) {
                  if (proofList.isEmpty) {
                    return Text(language.noDataAvailable,
                            style: secondaryTextStyle())
                        .center()
                        .paddingAll(16);
                  }

                  return _proofListBody(proofList);
                },
              ),
      ],
    );
  }

  Widget _proofListBody(List<ProductOrderProof> proofList) {
    return Column(
      children: proofList.map((proof) {
        final List<String> images = proof.url.isNotEmpty ? [proof.url] : [];

        return Container(
          width: context.width(),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: boxDecorationDefault(color: context.cardColor),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (proof.url.isNotEmpty)
                Container(
                  decoration: boxDecorationRoundedWithShadow(10),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: CachedImageWidget(
                    url: proof.url,
                    height: 62,
                    width: 62,
                    fit: BoxFit.cover,
                  ),
                ).onTap(() {
                  ZoomImageScreen(galleryImages: images, index: 0)
                      .launch(context);
                }),
              if (proof.url.isNotEmpty) 12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proof.description.validate(value: 'Delivered proof'),
                    style: boldTextStyle(size: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (proof.createdAt.isNotEmpty) ...[
                    6.height,
                    Text(formatDate(proof.createdAt),
                        style: secondaryTextStyle(size: 12)),
                  ],
                ],
              ).expand(),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isDelivered(ProductOrderData order) {
    return ['delivered', 'complete', 'completed']
            .contains(_normalizeStatus(order.deliveryStatus)) ||
        ['delivered', 'complete', 'completed']
            .contains(_normalizeStatus(order.status));
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: context.width(),
      decoration: boxDecorationDefault(
          color: context.cardColor, borderRadius: radius()),
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

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: boldTextStyle(
            size: 12,
            color: appStore.isDarkMode ? textSecondaryColor : textPrimaryColor,
          ),
        ).expand(),
        8.width,
        Text(
          value,
          style: boldTextStyle(
            size: 12,
            color: appStore.isDarkMode ? white : textSecondaryColor,
            weight: FontWeight.w400,
          ),
          softWrap: true,
        ).expand(flex: 4),
      ],
    ).paddingBottom(8);
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

class _ProductOrderStatusHistorySheet extends StatelessWidget {
  final int orderId;
  final List<BookingActivity> activity;
  final ScrollController scrollController;

  const _ProductOrderStatusHistorySheet({
    required this.orderId,
    required this.activity,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius:
            radiusOnly(topLeft: defaultRadius, topRight: defaultRadius),
        backgroundColor: context.cardColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                40.width,
                Container(
                  width: 40,
                  height: 2,
                  color: Colors.grey.withValues(alpha: 0.3),
                ).center(),
                IconButton(
                  onPressed: () => finish(context),
                  icon: const Icon(Icons.close_sharp, size: 20.0),
                )
              ],
            ),
            4.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Product Order History',
                    style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                Row(
                  children: [
                    Text('${language.lblID}:',
                        style: boldTextStyle(color: primaryColor)),
                    4.width,
                    Text('#$orderId',
                        style: boldTextStyle(color: primaryColor)),
                  ],
                ),
              ],
            ),
            16.height,
            Divider(color: context.dividerColor),
            16.height,
            activity.isNotEmpty
                ? AnimatedListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activity.length,
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    itemBuilder: (_, i) {
                      return BookingHistoryListWidget(
                        data: activity[i],
                        index: i,
                        length: activity.length.validate(),
                      );
                    },
                  )
                : Text(language.noDataAvailable).center().paddingAll(16),
          ],
        ),
      ),
    );
  }
}

class ProductOrderTrackLocation extends StatefulWidget {
  final int orderId;
  final ProductOrderLocation? initialLocation;

  const ProductOrderTrackLocation({
    Key? key,
    required this.orderId,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<ProductOrderTrackLocation> createState() =>
      _ProductOrderTrackLocationState();
}

class _ProductOrderTrackLocationState extends State<ProductOrderTrackLocation>
    with WidgetsBindingObserver {
  gmaps.CameraPosition _initialLocation =
      const gmaps.CameraPosition(target: gmaps.LatLng(0.0, 0.0));
  gmaps.GoogleMapController? mapController;
  Set<gmaps.Marker> _markers = {};
  ProductOrderLocation? latestLocation;
  Timer? _timer;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    latestLocation = widget.initialLocation;
    _updateMarker();
    _refreshLocation();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshLocation();
    });
  }

  Future<void> _refreshLocation() async {
    isLoading = true;
    setState(() {});

    try {
      latestLocation = await getProductOrderLocation(widget.orderId);
      _updateMarker();
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  void _updateMarker() {
    final ProductOrderLocation? location = latestLocation;
    if (location == null) return;

    final gmaps.LatLng latLng = gmaps.LatLng(
        location.latitude.toDouble(), location.longitude.toDouble());

    _initialLocation = gmaps.CameraPosition(target: latLng, zoom: 14);
    _markers = {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('productOrderLocation'),
        position: latLng,
      ),
    };
    mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(latLng, 14));
  }

  void _stopLocationUpdates() {
    _timer?.cancel();
    mapController?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopLocationUpdates();
    } else if (state == AppLifecycleState.resumed) {
      _refreshLocation();
      _startLocationUpdates();
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Track Delivery Boy Location',
      child: Stack(
        children: [
          gmaps.GoogleMap(
            mapType: gmaps.MapType.normal,
            markers: _markers,
            initialCameraPosition: _initialLocation,
            gestureRecognizers: Set()
              ..add(Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()))
              ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
              ..add(Factory<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer()))
              ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
              ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
            onMapCreated: (controller) {
              mapController = controller;
              _updateMarker();
            },
          ),
          Positioned(
            left: 10,
            top: 10,
            child: const CupertinoActivityIndicator(color: black)
                .visible(isLoading),
          ),
        ],
      ),
    );
  }
}
