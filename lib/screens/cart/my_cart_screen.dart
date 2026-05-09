import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/cart_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MyCartScreen extends StatefulWidget {
  const MyCartScreen({Key? key}) : super(key: key);

  @override
  State<MyCartScreen> createState() => _MyCartScreenState();
}

class _MyCartScreenState extends State<MyCartScreen> {
  Future<CartResponse>? future;
  bool isActionLoading = false;
  final TextEditingController shippingNameCont = TextEditingController();
  final TextEditingController shippingAddressCont = TextEditingController();
  final TextEditingController shippingCityCont = TextEditingController();
  final TextEditingController shippingPincodeCont = TextEditingController();
  String? selectedShippingState;
  String? selectedPaymentMethodType;
  Razorpay? razorpay;
  CartCheckoutResponse? pendingRazorpayCheckout;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    future = getCartList().then((value) {
      appStore.setCartCount(value.cartCount);
      return value;
    });
  }

  void setupRazorpay() {
    razorpay = Razorpay();
    razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, handleRazorpaySuccess);
    razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, handleRazorpayError);
    razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    razorpay?.clear();
    shippingNameCont.dispose();
    shippingAddressCont.dispose();
    shippingCityCont.dispose();
    shippingPincodeCont.dispose();
    super.dispose();
  }

  Future<void> refreshCart() async {
    init();
    setState(() {});
    await future;
  }

  Future<void> updateQuantity(CartItemData item, int quantity) async {
    final int maxQuantity = item.maxAllowedQuantity > 0
        ? item.maxAllowedQuantity
        : item.variant.maxPurchaseQty;
    if (quantity < 1) return;
    if (maxQuantity > 0 && quantity > maxQuantity) {
      toast('Maximum quantity allowed is $maxQuantity');
      return;
    }

    isActionLoading = true;
    setState(() {});

    await updateCartQuantity(cartItemId: item.cartItemId, quantity: quantity)
        .then((value) {
      toast(value.message.validate(value: 'Cart updated'));
      init();
    }).catchError((e) {
      toast(e.toString());
    });

    isActionLoading = false;
    setState(() {});
  }

  Future<void> removeItem(CartItemData item) async {
    isActionLoading = true;
    setState(() {});

    await removeCartItem(cartItemId: item.cartItemId).then((value) {
      toast(value.message.validate(value: 'Item removed'));
      init();
    }).catchError((e) {
      toast(e.toString());
    });

    isActionLoading = false;
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (shippingNameCont.text.isEmpty && appStore.userFullName.isNotEmpty) {
      shippingNameCont.text = appStore.userFullName;
    }

    return Scaffold(
      appBar: appBarWidget(
        'My Cart',
        textColor: white,
        textSize: APP_BAR_TEXT_SIZE,
        elevation: 0,
        color: context.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: white, size: 20),
            onPressed: () {
              refreshCart();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SnapHelperWidget<CartResponse>(
            future: future,
            loadingWidget: LoaderWidget(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error.toString(),
                imageWidget: const ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  refreshCart();
                },
              ).center();
            },
            onSuccess: (snap) {
              if (snap.data.isEmpty) {
                return NoDataWidget(
                  title: 'Your cart is empty',
                  subTitle: 'Products you add to cart will appear here.',
                  imageWidget: const EmptyStateWidget(),
                ).center();
              }

              return RefreshIndicator(
                color: context.primaryColor,
                onRefresh: refreshCart,
                child: AnimatedScrollView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 110),
                  listAnimationType: ListAnimationType.FadeIn,
                  children: [
                    _cartHeader(snap),
                    16.height,
                    ...snap.data
                        .map((item) => _cartItem(item).paddingBottom(12)),
                    4.height,
                    _priceSummary(snap.summary),
                    16.height,
                    _shippingForm(snap.checkout),
                    16.height,
                    if (_isShippingComplete(snap.checkout)) ...[
                      16.height,
                      _paymentMethods(snap.checkout.paymentMethods),
                    ],
                  ],
                ),
              );
            },
          ),
          if (isActionLoading) LoaderWidget().center(),
        ],
      ),
      bottomNavigationBar: SnapHelperWidget<CartResponse>(
        future: future,
        loadingWidget: const Offstage(),
        errorWidget: const Offstage(),
        onSuccess: (snap) {
          if (snap.data.isEmpty) return const Offstage();
          final bool canCheckout = _canCheckout(snap.checkout);

          return Container(
            decoration: boxDecorationDefault(
                color: context.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Grand Total', style: secondaryTextStyle()),
                    4.height,
                    Text(snap.summary.grandTotalFormat,
                        style: boldTextStyle(size: 18, color: primaryColor)),
                  ],
                ).expand(),
                AppButton(
                  text: 'Checkout',
                  color: canCheckout ? context.primaryColor : grey,
                  textColor: white,
                  elevation: 0,
                  shapeBorder: RoundedRectangleBorder(borderRadius: radius()),
                  onTap: () {
                    _onCheckoutTap(snap.checkout);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cartHeader(CartResponse data) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(),
        backgroundColor:
            appStore.isDarkMode ? context.cardColor : lightPrimaryColor,
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: boxDecorationDefault(
                color: context.primaryColor, shape: BoxShape.circle),
            child: const Icon(MaterialCommunityIcons.cart_outline,
                color: white, size: 22),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${data.cartCount} item${data.cartCount == 1 ? '' : 's'} in cart',
                  style: boldTextStyle(size: 16, color: primaryColor)),
              4.height,
              Text('Review products before checkout',
                  style: secondaryTextStyle()),
            ],
          ).expand(),
        ],
      ),
    );
  }

  Widget _cartItem(CartItemData item) {
    final int maxQuantity = item.maxAllowedQuantity > 0
        ? item.maxAllowedQuantity
        : item.variant.maxPurchaseQty;

    return Container(
      decoration: boxDecorationDefault(
          color: context.cardColor, borderRadius: radius()),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedImageWidget(
                  url: item.product.productImage,
                  height: 82,
                  width: 82,
                  fit: BoxFit.cover,
                  radius: defaultRadius),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name.validate(value: 'Product'),
                      style: boldTextStyle(size: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  6.height,
                  if (item.variant.label.isNotEmpty)
                    Text(item.variant.label,
                        style: secondaryTextStyle(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  6.height,
                  Row(
                    children: [
                      CachedImageWidget(
                          url: item.product.providerImage,
                          height: 18,
                          width: 18,
                          circle: true,
                          fit: BoxFit.cover),
                      6.width,
                      Text(item.product.providerName.validate(),
                              style: secondaryTextStyle(size: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          .expand(),
                    ],
                  ).visible(item.product.providerName.isNotEmpty ||
                      item.product.providerImage.isNotEmpty),
                  8.height,
                  Text(item.unitPriceFormat,
                      style: boldTextStyle(color: primaryColor, size: 13)),
                ],
              ).expand(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Ionicons.trash_outline,
                    color: redColor, size: 20),
                onPressed: () {
                  removeItem(item);
                },
              ),
            ],
          ),
          12.height,
          Row(
            children: [
              _quantityButton(
                  icon: Icons.remove,
                  onTap: () => updateQuantity(item, item.quantity - 1)),
              Container(
                height: 36,
                width: 42,
                alignment: Alignment.center,
                child: Text(item.quantity.toString(),
                    style: boldTextStyle(size: 14)),
              ),
              _quantityButton(
                  icon: Icons.add,
                  onTap: () => updateQuantity(item, item.quantity + 1)),
              if (maxQuantity > 0)
                Text('  Max $maxQuantity', style: secondaryTextStyle(size: 12))
                    .expand()
              else
                const Spacer(),
              Text(item.lineTotalFormat, style: boldTextStyle(size: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      height: 34,
      width: 34,
      decoration: boxDecorationDefault(
          color: context.primaryColor.withValues(alpha: 0.08),
          shape: BoxShape.circle),
      child: Icon(icon, color: context.primaryColor, size: 18),
    ).onTap(onTap);
  }

  Widget _priceSummary(CartSummary summary) {
    return Container(
      decoration: boxDecorationDefault(
          color: context.cardColor, borderRadius: radius()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Detail', style: boldTextStyle(size: 15)),
          14.height,
          _summaryRow('Subtotal', summary.subtotalFormat),
          if (summary.taxDetail.isNotEmpty)
            ...summary.taxDetail.map((tax) => _summaryRow(
                '${tax.title} (${tax.value}${tax.type == 'percent' ? '%' : ''})',
                tax.amount.toStringAsFixed(2))),
          _summaryRow('Tax', summary.taxTotalFormat)
              .visible(summary.taxDetail.isEmpty),
          Divider(color: context.dividerColor, height: 24),
          _summaryRow('Grand Total', summary.grandTotalFormat, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isTotal = false}) {
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

  bool _canCheckout(CartCheckout checkout) {
    return _isShippingComplete(checkout) &&
        selectedPaymentMethodType.validate().isNotEmpty;
  }

  bool _isShippingComplete(CartCheckout checkout) {
    final List<String> requiredFields = checkout.shippingRequiredFields;
    if (requiredFields.isEmpty) return true;

    final bool hasState = !requiredFields.contains('shipping_state') ||
        selectedShippingState.validate().isNotEmpty;

    return (!requiredFields.contains('shipping_name') ||
            shippingNameCont.text.trim().isNotEmpty) &&
        (!requiredFields.contains('shipping_address') ||
            shippingAddressCont.text.trim().isNotEmpty) &&
        hasState &&
        (!requiredFields.contains('shipping_city') ||
            shippingCityCont.text.trim().isNotEmpty) &&
        (!requiredFields.contains('shipping_pincode') ||
            shippingPincodeCont.text.trim().isNotEmpty) &&
        (!requiredFields.contains('shipping_country') ||
            checkout.shippingCountryDefault.trim().isNotEmpty);
  }

  Future<void> _onCheckoutTap(CartCheckout checkout) async {
    if (!_canCheckout(checkout)) {
      toast('Please complete shipping information and select payment method');
      return;
    }

    isActionLoading = true;
    setState(() {});

    final Map<String, dynamic> request = {
      'payment_method': selectedPaymentMethodType,
      'shipping_name': shippingNameCont.text.trim(),
      'shipping_address': shippingAddressCont.text.trim(),
      'shipping_state': selectedShippingState.validate(),
      'shipping_city': shippingCityCont.text.trim(),
      'shipping_pincode': shippingPincodeCont.text.trim(),
      'shipping_country': checkout.shippingCountryDefault.trim(),
    };

    await cartCheckout(request).then((response) async {
      await _handleCheckoutResponse(response);
    }).catchError((e) {
      toast(e.toString());
    });

    isActionLoading = false;
    setState(() {});
  }

  Future<void> _handleCheckoutResponse(CartCheckoutResponse response) async {
    final String actionType = response.paymentAction.type.toLowerCase();

    if (actionType == 'razorpay') {
      _openRazorpay(response);
      return;
    }

    await refreshCart();
    _showOrderSuccess(response);
  }

  void _openRazorpay(CartCheckoutResponse response) {
    final CartPaymentAction action = response.paymentAction;
    if (action.razorpayKey.isEmpty || action.razorpayOrderId.isEmpty) {
      toast('Razorpay details are missing');
      return;
    }

    pendingRazorpayCheckout = response;
    setupRazorpay();

    razorpay!.open({
      'key': action.razorpayKey,
      'order_id': action.razorpayOrderId,
      'amount': action.amount,
      'currency': action.currency,
      'name': APP_NAME,
      'theme.color': primaryColor.toHex(),
      'prefill': {
        'contact': appStore.userContactNumber,
        'email': appStore.userEmail,
      },
    });
  }

  Future<void> handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final CartCheckoutResponse? checkoutResponse = pendingRazorpayCheckout;
    final CartOrderData? order = checkoutResponse?.data;
    final String verifyEndpoint =
        checkoutResponse?.paymentAction.verifyEndpoint ?? '';

    if (order == null || verifyEndpoint.isEmpty) {
      toast('Unable to verify Razorpay payment');
      return;
    }

    isActionLoading = true;
    setState(() {});

    await productRazorpayVerify(
      verifyEndpoint: verifyEndpoint,
      request: {
        'order_id': order.id,
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      },
    ).then((verifyResponse) async {
      pendingRazorpayCheckout = null;
      await refreshCart();
      _showOrderSuccess(verifyResponse);
    }).catchError((e) {
      toast(e.toString());
    });

    isActionLoading = false;
    setState(() {});
  }

  void handleRazorpayError(PaymentFailureResponse response) {
    toast(response.message.validate(value: 'Razorpay payment failed'));
  }

  void handleRazorpayExternalWallet(ExternalWalletResponse response) {
    toast('External wallet ${response.walletName.validate()}');
  }

  void _showOrderSuccess(CartCheckoutResponse response) {
    showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      builder: (_) {
        final CartOrderData? order = response.data;

        return Container(
          width: context.width() * 0.82,
          padding: const EdgeInsets.all(20),
          decoration: boxDecorationDefault(
            color: context.cardColor,
            borderRadius: radius(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                width: 54,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const CachedImageWidget(
                  url: ic_right,
                  height: 18,
                  width: 18,
                  color: white,
                ),
              ),
              14.height,
              Text(
                response.message.validate(value: 'Order placed successfully.'),
                textAlign: TextAlign.center,
                style: boldTextStyle(size: 16),
              ),
              if (order != null && order.orderNumber.isNotEmpty) ...[
                8.height,
                Text(order.orderNumber,
                    textAlign: TextAlign.center,
                    style: secondaryTextStyle(size: 13)),
              ],
              if (order != null && order.totalFormat.isNotEmpty) ...[
                6.height,
                Text(order.totalFormat,
                    textAlign: TextAlign.center,
                    style: boldTextStyle(size: 15, color: primaryColor)),
              ],
              18.height,
              AppButton(
                text: language.done,
                height: 40,
                width: context.width() * 0.38,
                color: context.primaryColor,
                textColor: white,
                elevation: 0,
                shapeBorder: RoundedRectangleBorder(borderRadius: radius()),
                onTap: () {
                  finish(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shippingForm(CartCheckout checkout) {
    if (selectedShippingState != null &&
        !checkout.states.contains(selectedShippingState)) {
      selectedShippingState = null;
    }

    return Container(
      decoration: boxDecorationDefault(
          color: context.cardColor, borderRadius: radius()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping Information', style: boldTextStyle(size: 15)),
          16.height,
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 620;
              final double itemWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _textField(
                      label: 'Name',
                      controller: shippingNameCont,
                      textInputType: TextInputType.name,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _textField(
                      label: 'Address',
                      controller: shippingAddressCont,
                      maxLines: isWide ? 4 : 3,
                      textInputType: TextInputType.streetAddress,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _stateDropdown(checkout.states),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _textField(
                      label: 'City',
                      controller: shippingCityCont,
                      textInputType: TextInputType.text,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _textField(
                      label: 'Pincode',
                      controller: shippingPincodeCont,
                      textInputType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _readonlyField(
                      label: 'Country',
                      value:
                          checkout.shippingCountryDefault.validate(value: '-'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label, style: primaryTextStyle(size: 13)).paddingBottom(6);
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType? textInputType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: textInputType,
          maxLines: maxLines,
          style: primaryTextStyle(size: 14),
          decoration: inputDecoration(context, hintText: label),
          onChanged: (_) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _readonlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          initialValue: value,
          readOnly: true,
          style: primaryTextStyle(size: 14),
          decoration: inputDecoration(context, hintText: label),
        ),
      ],
    );
  }

  Widget _stateDropdown(List<String> states) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('State'),
        DropdownButtonFormField<String>(
          value: selectedShippingState,
          isExpanded: true,
          dropdownColor: context.cardColor,
          decoration: inputDecoration(context, hintText: 'State'),
          hint: Text('State', style: secondaryTextStyle(color: appTextSecondaryColor)),
          items: states.map((state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state, style: primaryTextStyle(size: 14)),
            );
          }).toList(),
          onChanged: states.isEmpty
              ? null
              : (value) {
                  selectedShippingState = value;
                  setState(() {});
                },
        ),
      ],
    );
  }

  Widget _paymentMethods(List<CartPaymentMethod> methods) {
    return Container(
      decoration: boxDecorationDefault(
          color: context.cardColor, borderRadius: radius()),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method', style: boldTextStyle(size: 15)),
          12.height,
          if (methods.isEmpty)
            Text('No payment methods available',
                style: secondaryTextStyle(size: 13))
          else
            Wrap(
              spacing: 4,
              runSpacing: 8,
              children: methods.map((method) {
                final bool isSelected =
                    selectedPaymentMethodType == method.type;
                return InkWell(
                  borderRadius: radius(),
                  onTap: () {
                    selectedPaymentMethodType = method.type;
                    setState(() {});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 18,
                        width: 18,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? context.primaryColor
                                : context.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? Container(
                                decoration: BoxDecoration(
                                  color: context.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : const Offstage(),
                      ),
                      6.width,
                      Text(method.title.validate(value: method.type),
                          style: primaryTextStyle(size: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
