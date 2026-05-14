import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/chat/user_chat_screen.dart';
import 'package:booking_system_flutter/screens/zoom_image_screen.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:nb_utils/nb_utils.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Future<ServiceDetailResponse>? future;
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    future = getPostDetails(
      postId: widget.postId,
      customerId: appStore.userId,
    );
  }

  Future<UserData?> _resolveChatReceiver(UserData provider) async {
    UserData receiverUser = UserData(
      id: provider.id,
      uid: provider.uid,
      firstName: provider.firstName ?? provider.displayName,
      lastName: provider.lastName,
      displayName: provider.displayName,
      profileImage: provider.profileImage,
      email: provider.email,
    );

    if (receiverUser.uid.validate().isEmpty && provider.id.validate() > 0) {
      receiverUser = await getUserDetail(provider.id.validate());
    }

    if (receiverUser.uid.validate().isEmpty &&
        receiverUser.email.validate().isNotEmpty) {
      receiverUser = await userService.getUser(email: receiverUser.email);
    }

    return receiverUser.uid.validate().isNotEmpty ? receiverUser : null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: "Post Detail",
      showLoader: false,
      child: FutureBuilder<ServiceDetailResponse>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return LoaderWidget().center();
          }
          if (snap.hasError) {
            return NoDataWidget(
              title: snap.error.toString(),
              imageWidget: ErrorStateWidget(),
              retryText: language.reload,
              onRetry: () {
                setState(() {
                  init();
                });
              },
            ).center();
          }
          if (!snap.hasData) return const Offstage();

          final serviceDetail = snap.data!.serviceDetail!;
          final provider = snap.data!.provider;

          final List<String> sliderUrls =
              serviceDetail.attachmentsArray.validate().isNotEmpty
                  ? serviceDetail.attachmentsArray
                      .validate()
                      .map((e) => e.url.validate())
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : serviceDetail.attachments
                      .validate()
                      .where((e) => e.isNotEmpty)
                      .toList();

          return Stack(
            children: [
              AnimatedScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Image Carousel
                  if (sliderUrls.isNotEmpty)
                    Stack(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: sliderUrls.length,
                            onPageChanged: (value) {
                              _pageIndex = value;
                              if (mounted) setState(() {});
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  ZoomImageScreen(
                                    galleryImages: sliderUrls,
                                    index: index,
                                  ).launch(context);
                                },
                                child: CachedImageWidget(
                                  url: sliderUrls[index],
                                  fit: BoxFit.cover,
                                  height: 250,
                                  width: context.width(),
                                ),
                              );
                            },
                          ),
                        ),
                        if (sliderUrls.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: boxDecorationDefault(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: radius(20),
                              ),
                              child: Text(
                                '${_pageIndex + 1}/${sliderUrls.length}',
                                style: secondaryTextStyle(
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                      ],
                    ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      16.height,
                      // Badges
                      Row(
                        children: [
                          if (serviceDetail.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: boxDecorationDefault(
                                  color: context.primaryColor
                                      .withValues(alpha: 0.1)),
                              child: Text(
                                serviceDetail.categoryName!,
                                style: boldTextStyle(
                                    color: context.primaryColor, size: 12),
                              ),
                            ),
                          8.width,
                          if (serviceDetail.subCategoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: boxDecorationDefault(
                                  color: context.primaryColor
                                      .withValues(alpha: 0.1)),
                              child: Text(
                                serviceDetail.subCategoryName!,
                                style: boldTextStyle(
                                    color: context.primaryColor, size: 12),
                              ),
                            ),
                        ],
                      ).paddingSymmetric(horizontal: 16),
                      16.height,

                      // Name and Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            serviceDetail.name.validate(),
                            style: boldTextStyle(size: 20),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).expand(),
                          16.width,
                          if (serviceDetail.priceFormat.validate().isNotEmpty)
                            Text(
                              serviceDetail.priceFormat.validate(),
                              style: boldTextStyle(
                                  size: 18, color: context.primaryColor),
                            )
                          else
                            PriceWidget(
                              price: serviceDetail.price ?? 0,
                              size: 20,
                            ),
                        ],
                      ).paddingSymmetric(horizontal: 16),
                      16.height,

                      // Description
                      if (serviceDetail.description != null &&
                          serviceDetail.description!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Description", style: boldTextStyle(size: 16)),
                            8.height,
                            Html(
                              data: serviceDetail.description.validate(),
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(14),
                                  color: context.iconColor,
                                ),
                                "p": Style(margin: Margins.only(bottom: 8)),
                              },
                            ),
                          ],
                        ).paddingSymmetric(horizontal: 16),

                      24.height,

                      // Order Detail
                      if (serviceDetail.postOrderDetail != null) ...[
                        Text("Order Detail", style: boldTextStyle(size: 16))
                            .paddingSymmetric(horizontal: 16),
                        8.height,
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: boxDecorationDefault(
                            color: context.cardColor,
                            border: Border.all(color: context.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Post Name",
                                      style: secondaryTextStyle()),
                                  16.width,
                                  Text(
                                    serviceDetail.postOrderDetail!.postName
                                        .validate(),
                                    style: boldTextStyle(size: 14),
                                    textAlign: TextAlign.end,
                                  ).expand(),
                                ],
                              ),
                              8.height,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Price", style: secondaryTextStyle()),
                                  Text(
                                      serviceDetail.postOrderDetail!.priceFormat
                                          .validate(),
                                      style: boldTextStyle(size: 14)),
                                ],
                              ),
                              if (serviceDetail
                                          .postOrderDetail!.discountAmount !=
                                      null &&
                                  serviceDetail
                                          .postOrderDetail!.discountAmount! >
                                      0) ...[
                                8.height,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Discount",
                                        style: secondaryTextStyle()),
                                    Text(
                                        '-' +
                                            serviceDetail.postOrderDetail!
                                                .discountAmountFormat
                                                .validate(),
                                        style: boldTextStyle(
                                            size: 14, color: Colors.green)),
                                  ],
                                ),
                              ],
                              Divider(color: context.dividerColor, height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Subtotal",
                                      style: boldTextStyle(size: 14)),
                                  Text(
                                      serviceDetail
                                          .postOrderDetail!.subtotalFormat
                                          .validate(),
                                      style: boldTextStyle(
                                          size: 16,
                                          color: context.primaryColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        24.height,
                      ],

                      // Seller Info Card
                      if (provider != null) ...[
                        Text("Seller Info", style: boldTextStyle(size: 16))
                            .paddingSymmetric(horizontal: 16),
                        8.height,
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: boxDecorationDefault(
                            color: context.cardColor,
                            border: Border.all(color: context.dividerColor),
                          ),
                          child: Row(
                            children: [
                              CachedImageWidget(
                                url: provider.profileImage.validate(),
                                height: 50,
                                circle: true,
                                fit: BoxFit.cover,
                              ),
                              16.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(provider.displayName.validate(),
                                      style: boldTextStyle()),
                                  Text("Tap Chat to message seller",
                                      style: secondaryTextStyle(size: 12)),
                                ],
                              ).expand(),
                            ],
                          ),
                        ),
                      ],
                      24.height,
                    ],
                  ),
                ],
              ),

              // Sticky "Chat with Seller" button
              if (provider != null && provider.id != appStore.userId)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AppButton(
                    onTap: () async {
                      doIfLoggedIn(context, () async {
                        appStore.setLoading(true);
                        final receiverUser =
                            await _resolveChatReceiver(provider)
                                .catchError((e) {
                          log(e.toString());
                          return null;
                        }).whenComplete(() => appStore.setLoading(false));

                        if (receiverUser == null) {
                          toast(
                              'Seller chat account is not ready. Please ask seller to login once.');
                          return;
                        }

                        UserChatScreen(
                                receiverUser: receiverUser, chatType: 'post')
                            .launch(context);
                      });
                    },
                    color: context.primaryColor,
                    textColor: Colors.white,
                    width: context.width(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Colors.white, size: 20),
                        8.width,
                        Text("Chat with Seller",
                            style: boldTextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
