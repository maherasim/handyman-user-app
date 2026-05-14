import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/subscription_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/cart/razorpay_payment_options_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  Future<SubscriptionConfigResponse>? future;
  Future<SubscriptionHistoryResponse>? historyFuture;
  List<Plan> plans = [];
  List<PaymentMethod> paymentMethods = [];
  List<SubscriptionHistoryData> history = [];
  int? selectedPlanId;
  String? selectedPaymentMethod;
  Razorpay? razorpay;
  CheckoutResponse? pendingRazorpayCheckout;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getSubscriptionConfig();
    historyFuture = getUserSubscriptionHistory();
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
    super.dispose();
  }

  Future<void> handleCheckout(Plan plan) async {
    if (paymentMethods.isEmpty) {
      toast(language.noPaymentMethodFound);
      return;
    }

    PaymentMethod? selectedMethod;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: context.height() * 0.75),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16,
                      MediaQuery.of(context).viewInsets.bottom + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.lblChoosePaymentMethod,
                        style: boldTextStyle(size: 18),
                      ),
                      16.height,
                      RadioGroup<PaymentMethod>(
                        groupValue: selectedMethod,
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedMethod = value;
                            });
                          }
                        },
                        child: Column(
                          children: paymentMethods.map((method) {
                            return RadioListTile<PaymentMethod>(
                              value: method,
                              title: Text(method.title.validate(),
                                  style: primaryTextStyle()),
                              subtitle: Text(method.type.validate(),
                                  style: secondaryTextStyle()),
                              activeColor: primaryColor,
                            );
                          }).toList(),
                        ),
                      ),
                      16.height,
                      AppButton(
                        text: language.lblPayNow,
                        width: context.width(),
                        color: primaryColor,
                        textStyle: boldTextStyle(color: white),
                        onTap: () {
                          if (selectedMethod != null) {
                            Navigator.pop(context, selectedMethod);
                          } else {
                            toast(language.chooseAnyOnePayment);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((value) async {
      if (value != null) {
        selectedPaymentMethod = value.type;
        await processCheckout(plan, selectedPaymentMethod!);
      }
    });
  }

  Future<void> processCheckout(Plan plan, String paymentMethod) async {
    appStore.setLoading(true);
    try {
      CheckoutResponse response = await userSubscriptionCheckout(
        planId: plan.id!,
        paymentMethod: paymentMethod,
      );

      if (response.status == true && _isRazorpay(paymentMethod)) {
        appStore.setLoading(false);
        _openSubscriptionPaymentOptions(response, plan);
      } else if (response.status == true && response.checkoutUrl != null) {
        await _launchExternalCheckout(response.checkoutUrl!);
      } else {
        toast(language.somethingWentWrong);
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  bool _isRazorpay(String paymentMethod) {
    final String normalized = paymentMethod.toLowerCase();
    return normalized == 'razorpay';
  }

  Future<void> _launchExternalCheckout(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      toast(language.invalidURL);
    }
  }

  void _openSubscriptionPaymentOptions(CheckoutResponse response, Plan plan) {
    final SubscriptionPaymentAction? action = response.paymentAction;

    if (action == null ||
        action.razorpayKey.validate().isEmpty ||
        action.razorpayOrderId.validate().isEmpty) {
      toast('Subscription Razorpay details are missing from API');
      return;
    }

    RazorpayPaymentOptionsScreen(
      amountText: '${plan.amount?.toStringAsFixed(2) ?? '0.00'}',
      onContinue: () {
        finish(context);
        300.milliseconds.delay.then((_) => _openRazorpay(response));
      },
    ).launch(context);
  }

  void _openRazorpay(CheckoutResponse response) {
    final SubscriptionPaymentAction? action = response.paymentAction;
    if (action == null ||
        action.razorpayKey.validate().isEmpty ||
        action.razorpayOrderId.validate().isEmpty) {
      toast('Subscription Razorpay details are missing');
      return;
    }

    pendingRazorpayCheckout = response;
    setupRazorpay();

    razorpay!.open({
      'key': action.razorpayKey,
      'order_id': action.razorpayOrderId,
      'amount': action.amount.validate(),
      'currency': action.currency.validate(value: 'INR'),
      'name': APP_NAME,
      'theme.color': primaryColor.toHex(),
      'prefill': {
        'contact': appStore.userContactNumber,
        'email': appStore.userEmail,
      },
    });
  }

  Future<void> handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final CheckoutResponse? checkoutResponse = pendingRazorpayCheckout;
    final SubscriptionPaymentAction? action = checkoutResponse?.paymentAction;
    final Subscription? subscription = checkoutResponse?.subscription;

    if (action == null || action.verifyEndpoint.validate().isEmpty) {
      toast('Unable to verify subscription payment');
      return;
    }

    appStore.setLoading(true);
    try {
      await subscriptionRazorpayVerify(
        verifyEndpoint: action.verifyEndpoint!,
        request: {
          if (subscription?.id != null) 'subscription_id': subscription!.id,
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
        },
      );

      pendingRazorpayCheckout = null;
      historyFuture = getUserSubscriptionHistory();
      setState(() {});
      toast('Subscription purchased successfully');
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  void handleRazorpayError(PaymentFailureResponse response) {
    toast(response.message.validate(value: 'Razorpay payment failed'));
  }

  void handleRazorpayExternalWallet(ExternalWalletResponse response) {
    toast('External wallet ${response.walletName.validate()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        'Subscription Plans',
        textColor: Colors.white,
        textSize: APP_BAR_TEXT_SIZE,
        color: primaryColor,
        showBack: true,
        backWidget: BackWidget(),
      ),
      body: Stack(
        children: [
          SnapHelperWidget<SubscriptionConfigResponse>(
            future: future,
            loadingWidget: LoaderWidget(),
            onSuccess: (snap) {
              plans = snap.plans ?? [];
              paymentMethods = snap.paymentMethods ?? [];

              return AnimatedScrollView(
                padding: const EdgeInsets.all(16),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                children: [
                  if (plans.isEmpty)
                    NoDataWidget(
                      title: 'No plans available',
                      imageWidget: const EmptyStateWidget(),
                    ).paddingBottom(16)
                  else
                    ...plans.map((plan) {
                      return _buildPlanCard(plan).paddingBottom(16);
                    }).toList(),
                  8.height,
                  _buildSubscriptionHistorySection(),
                ],
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: const ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  init();
                  setState(() {});
                },
              );
            },
          ),
          Observer(
              builder: (BuildContext context) =>
                  LoaderWidget().visible(appStore.isLoading.validate())),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(16),
        backgroundColor:
            appStore.isDarkMode ? context.cardColor : lightPrimaryColor,
        border: Border.all(color: primaryColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.title.validate(),
                  style: boldTextStyle(size: 18, color: primaryColor),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: boxDecorationDefault(
                  color: primaryColor,
                  borderRadius: radius(20),
                ),
                child: Text(
                  plan.type.validate().capitalizeFirstLetter(),
                  style: boldTextStyle(color: white, size: 12),
                ),
              ),
            ],
          ),
          16.height,
          Row(
            children: [
              Text(
                '${plan.amount?.toStringAsFixed(2) ?? '0.00'}',
                style: boldTextStyle(size: 32, color: primaryColor),
              ),
              8.width,
              Text(
                '/ ${plan.duration.validate()} ${plan.type.validate()}',
                style: secondaryTextStyle(size: 14),
              ),
            ],
          ),
          16.height,
          if (plan.description != null && plan.description!.isNotEmpty)
            Text(
              plan.description!,
              style: secondaryTextStyle(size: 14),
            ).paddingBottom(12),
          if (plan.planLimitation != null)
            _buildPlanLimitation(plan.planLimitation!),
          24.height,
          AppButton(
            text: 'Subscribe Now',
            width: context.width(),
            color: primaryColor,
            textStyle: boldTextStyle(color: white),
            onTap: () {
              handleCheckout(plan);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLimitation(PlanLimitation limitation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: boxDecorationDefault(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: radius(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Features',
            style: boldTextStyle(size: 14, color: primaryColor),
          ),
          8.height,
          if (limitation.featuredClassified != null)
            _buildFeatureItem(
              'Featured Classifieds',
              limitation.featuredClassified!.limit ?? 0,
              limitation.featuredClassified!.isChecked == 'on',
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, int limit, bool isEnabled) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? primaryColor : Colors.red,
          size: 20,
        ),
        8.width,
        Expanded(
          child: Text(
            '$title: $limit',
            style: secondaryTextStyle(size: 13),
          ),
        ),
      ],
    ).paddingSymmetric(vertical: 4);
  }

  Widget _buildSubscriptionHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription History',
            style: boldTextStyle(size: 18, color: primaryColor)),
        12.height,
        SnapHelperWidget<SubscriptionHistoryResponse>(
          future: historyFuture,
          loadingWidget: LoaderWidget().paddingSymmetric(vertical: 24),
          errorBuilder: (error) {
            return NoDataWidget(
              title: error,
              imageWidget: const ErrorStateWidget(),
              retryText: language.reload,
              onRetry: () {
                historyFuture = getUserSubscriptionHistory();
                setState(() {});
              },
            );
          },
          onSuccess: (snap) {
            history = snap.data ?? [];

            if (history.isEmpty) {
              return Container(
                width: context.width(),
                padding: const EdgeInsets.all(16),
                decoration: boxDecorationDefault(
                  color: context.cardColor,
                  borderRadius: radius(12),
                ),
                child: Text('No subscription history',
                    style: secondaryTextStyle(size: 14)),
              );
            }

            return Column(
              children: history
                  .map((item) => _buildHistoryCard(item).paddingBottom(12))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(SubscriptionHistoryData item) {
    final bool isActive = item.isActive.validate();
    final SubscriptionPayment? payment = item.payment;

    return Container(
      width: context.width(),
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        backgroundColor: context.cardColor,
        border: Border.all(
          color:
              isActive ? primaryColor.withValues(alpha: 0.45) : viewLineColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(item.title.validate(),
                    style: boldTextStyle(size: 16, color: primaryColor)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: boxDecorationDefault(
                  color: isActive
                      ? primaryColor.withValues(alpha: 0.14)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: radius(20),
                ),
                child: Text(
                  item.computedStatus
                      .validate(value: item.status.validate())
                      .capitalizeFirstLetter(),
                  style: boldTextStyle(
                    size: 12,
                    color: isActive ? primaryColor : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          12.height,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _historyMeta('Amount', item.amount?.toStringAsFixed(2) ?? '0.00'),
              _historyMeta(
                  'Featured', item.featuredPostsLimit.validate().toString()),
              if (item.daysLeft != null)
                _historyMeta('Days left', item.daysLeft.toString()),
              if (item.module.validate().isNotEmpty)
                _historyMeta('Module', item.module.validate()),
            ],
          ),
          12.height,
          if (item.startAt.validate().isNotEmpty)
            Text(
                'Start: ${formatDate(item.startAt.validate(), showDateWithTime: true)}',
                style: secondaryTextStyle(size: 13)),
          if (item.endAt.validate().isNotEmpty)
            Text(
                'End: ${formatDate(item.endAt.validate(), showDateWithTime: true)}',
                style: secondaryTextStyle(size: 13)),
          if (payment != null) ...[
            12.height,
            Divider(color: viewLineColor, height: 1),
            12.height,
            Row(
              children: [
                Icon(Icons.payment, size: 18, color: context.iconColor),
                8.width,
                Expanded(
                  child: Text(
                    '${payment.paymentType.validate()} - ${payment.paymentStatus.validate()}',
                    style: secondaryTextStyle(size: 13),
                  ),
                ),
              ],
            ),
            if (payment.txnId.validate().isNotEmpty)
              Text('Txn: ${payment.txnId.validate()}',
                      style: secondaryTextStyle(size: 12))
                  .paddingTop(4),
          ],
        ],
      ),
    );
  }

  Widget _historyMeta(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: boxDecorationDefault(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: radius(8),
      ),
      child: Text('$label: $value', style: secondaryTextStyle(size: 12)),
    );
  }
}
