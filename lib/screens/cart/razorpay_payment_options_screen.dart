import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/model/cart_response.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:nb_utils/nb_utils.dart';

class RazorpayPaymentOptionsScreen extends StatelessWidget {
  final CartCheckoutResponse? checkoutResponse;
  final String? amountText;
  final VoidCallback onContinue;

  const RazorpayPaymentOptionsScreen({
    Key? key,
    this.checkoutResponse,
    this.amountText,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CartOrderData? order = checkoutResponse?.data;
    final String total = amountText.validate().isNotEmpty
        ? amountText!
        : order?.totalFormat.validate().isNotEmpty == true
            ? order!.totalFormat
            : '₹${((checkoutResponse?.paymentAction.amount ?? 0) / 100).toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const CachedImageWidget(
              url: 'assets/images/app_logo.png',
              height: 34,
              width: 34,
              radius: 8,
              fit: BoxFit.cover,
            ),
            8.width,
            Text(APP_NAME, style: boldTextStyle(color: Colors.white, size: 18)),
          ],
        ),
        actions: [
          Container(
            height: 32,
            width: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: boxDecorationDefault(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          20.height,
          Text('Payment Options', style: boldTextStyle(size: 20))
              .paddingSymmetric(horizontal: 16),
          28.height,
          Text('All Payment Options', style: secondaryTextStyle(size: 13))
              .paddingSymmetric(horizontal: 16),
          10.height,
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: boxDecorationDefault(
              color: Colors.white,
              borderRadius: radius(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              boxShadow: [],
            ),
            child: Column(
              children: [
                _paymentOption(
                  icon: MaterialCommunityIcons.credit_card_outline,
                  title: 'Cards',
                  logos: '💳  🟠  🔴  🔵',
                ),
                _divider(),
                _paymentOption(
                  icon: MaterialCommunityIcons.calendar_month_outline,
                  title: 'EMI',
                  logos: '❎  🏦  💳  🟧',
                ),
                _divider(),
                _paymentOption(
                  icon: MaterialCommunityIcons.bank_outline,
                  title: 'Netbanking',
                  logos: '🏦  🔶  🔔  🟢',
                  expanded: true,
                ),
                _divider(),
                _paymentOption(
                  icon: MaterialCommunityIcons.wallet_outline,
                  title: 'Wallet',
                  logos: '🔵  ⚫  🟣  🟢',
                  expanded: true,
                ),
                _divider(),
                _paymentOption(
                  icon: MaterialCommunityIcons.clock_outline,
                  title: 'Pay Later',
                  logos: '🔴  🅿️  🟥  🛡️',
                  expanded: true,
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: context.width(),
            color: Colors.grey.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "By proceeding, I agree to Razorpay's Privacy Notice •\nEdit Preferences",
              textAlign: TextAlign.center,
              style: secondaryTextStyle(size: 11),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(total, style: boldTextStyle(size: 17)),
                  2.height,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Details', style: secondaryTextStyle(size: 11)),
                      2.width,
                      const Icon(Icons.keyboard_arrow_up, size: 14),
                    ],
                  ),
                ],
              ).expand(),
              AppButton(
                text: 'Continue',
                width: context.width() * 0.62,
                height: 48,
                color: const Color(0xFF020817),
                textColor: Colors.white,
                elevation: 0,
                shapeBorder: RoundedRectangleBorder(borderRadius: radius(6)),
                onTap: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption({
    required IconData icon,
    required String title,
    required String logos,
    bool expanded = false,
  }) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 19),
          12.width,
          Text(title, style: boldTextStyle(size: 14)),
          8.width,
          Text(logos, style: primaryTextStyle(size: 11)).expand(),
          Icon(
            expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
            color: Colors.black,
            size: 20,
          ),
        ],
      ).paddingSymmetric(horizontal: 14),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withValues(alpha: 0.15),
    );
  }
}
