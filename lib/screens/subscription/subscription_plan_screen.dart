import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/subscription_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  Future<SubscriptionConfigResponse>? future;
  List<Plan> plans = [];
  List<PaymentMethod> paymentMethods = [];
  int? selectedPlanId;
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getSubscriptionConfig();
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

      if (response.status == true && response.checkoutUrl != null) {
        if (await canLaunchUrl(Uri.parse(response.checkoutUrl!))) {
          await launchUrl(
            Uri.parse(response.checkoutUrl!),
            mode: LaunchMode.externalApplication,
          );
        } else {
          toast(language.invalidURL);
        }
      } else {
        toast(language.somethingWentWrong);
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
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

              if (plans.isEmpty) {
                return NoDataWidget(
                  title: 'No plans available',
                  imageWidget: const EmptyStateWidget(),
                );
              }

              return AnimatedScrollView(
                padding: const EdgeInsets.all(16),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                children: [
                  ...plans.map((plan) {
                    return _buildPlanCard(plan).paddingBottom(16);
                  }).toList(),
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
}
