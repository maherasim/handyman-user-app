import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/post/post_category_screen.dart';
import 'package:booking_system_flutter/screens/post/add_post_screen.dart';
import 'package:booking_system_flutter/screens/post/my_post_list_screen.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/subscription/subscription_plan_screen.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';

class PostListScreen extends StatefulWidget {
  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen>
    with AutomaticKeepAliveClientMixin {
  ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  Future<List<ServiceData>>? future;
  List<ServiceData> posts = [];

  int page = 1;
  bool isLastPage = false;
  List<CategoryData> categoryList = [];
  List<CategoryData> subCategoryList = [];

  List<CategoryData> get _renderCategoryList {
    final List<CategoryData> list = categoryList.validate();
    if (list.any((e) => e.id == -1)) return list;
    return [CategoryData(id: -1, name: language.lblAll), ...list];
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init({bool showLoader = true}) async {
    if (showLoader) appStore.setLoading(true);

    future = getPostList({
      'per_page': PER_PAGE_ITEM,
      'page': page,
      'search': filterStore.search,
      'category_id': filterStore.categoryId.join(","),
      'min_price': filterStore.isPriceMin,
      'max_price': filterStore.isPriceMax,
      'latitude': appStore.latitude,
      'longitude': appStore.longitude,
    }).then((value) {
      isLastPage = value.serviceList.validate().length != PER_PAGE_ITEM;
      if (page == 1) {
        posts.clear();
        categoryList = value.categoryList.validate();
        subCategoryList = value.subCategoryList.validate();
      }
      posts.addAll(value.serviceList.validate());
      setState(() {});
      return posts;
    }).catchError((e) {
      toast(e.toString());
      throw e;
    }).whenComplete(() => appStore.setLoading(false));
  }

  void openCreatePostFlow() {
    doIfLoggedIn(context, () async {
      appStore.setLoading(true);
      bool allowToCreateFeatured = false;
      try {
        final response = await getUserPostList(1, perPage: 1);
        allowToCreateFeatured =
            response.allowToCreateFeatured.validate().toLowerCase() == 'yes';
      } catch (e) {
        toast(e.toString());
      } finally {
        appStore.setLoading(false);
      }

      if (!allowToCreateFeatured) {
        toast('Please purchase a subscription plan to create more posts');
        SubscriptionPlanScreen().launch(context);
        return;
      }

      AddPostScreen().launch(context).then((value) {
        if (value ?? false) {
          page = 1;
          init();
        }
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: appBarWidget(
        "Posts",
        textColor: white,
        showBack: false,
        color: context.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Post',
            onPressed: openCreatePostFlow,
          ),
        ],
      ),
      body: Stack(
        children: [
          SnapHelperWidget<List<ServiceData>>(
            future: future,
            initialData: posts.isNotEmpty ? posts : null,
            loadingWidget: LoaderWidget(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                onRetry: () {
                  page = 1;
                  init();
                },
              );
            },
            onSuccess: (list) {
              return AnimatedScrollView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                onSwipeRefresh: () async {
                  page = 1;
                  init(showLoader: false);
                  return await 1.seconds.delay;
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    init(showLoader: false);
                  }
                },
                children: [
                  12.height,
                  if (_renderCategoryList.isNotEmpty) ...[
                    SizedBox(
                      height: 102,
                      child: HorizontalList(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        spacing: 16,
                        itemCount: _renderCategoryList.length,
                        itemBuilder: (context, index) {
                          final c = _renderCategoryList[index];
                          final bool isSelected = c.id == -1
                              ? filterStore.categoryId.isEmpty
                              : filterStore.categoryId.contains(c.id);

                          final String imageUrl = c.categoryImage.validate();

                          return SizedBox(
                            width: 80,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 60,
                                  width: 60,
                                  decoration: boxDecorationDefault(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? context.primaryColor
                                            .withValues(alpha: 0.20)
                                        : const Color(0xFF3D4044),
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: boxDecorationDefault(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? context.primaryColor
                                                .withValues(alpha: 0.15)
                                            : const Color(0xFFE9ECEF),
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? CachedImageWidget(
                                              url: imageUrl,
                                              height: 40,
                                              width: 40,
                                              fit: BoxFit.cover,
                                              circle: true,
                                            )
                                          : Icon(
                                              Icons.image_outlined,
                                              color: isSelected
                                                  ? context.primaryColor
                                                  : const Color(0xFF9AA0A6),
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ),
                                8.height,
                                Text(
                                  c.name.validate(),
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: isSelected
                                        ? context.primaryColor
                                        : textPrimaryColorGlobal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).onTap(() {
                            if (c.id == -1) {
                              filterStore.categoryId.clear();
                              page = 1;
                              init();
                              return;
                            }

                            final bool hasSubCategories =
                                c.subcategories.validate().isNotEmpty;
                            if (hasSubCategories) {
                              PostCategoryScreen(category: c).launch(context);
                              return;
                            } else {
                              filterStore.categoryId
                                ..clear()
                                ..add(c.id.validate());
                            }
                            page = 1;
                            init();
                          });
                        },
                      ),
                    ),
                    16.height,
                  ],
                  if (list.isEmpty)
                    NoDataWidget(
                      title: "No posts found",
                      imageWidget: EmptyStateWidget(),
                    ).center()
                  else
                    AnimatedWrap(
                      spacing: 16,
                      runSpacing: 16,
                      itemCount: list.length,
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration:
                          FadeInConfiguration(duration: 0.milliseconds),
                      itemBuilder: (context, index) {
                        return ServiceComponent(
                          serviceData: list[index],
                          width: (context.width() - 48) / 2,
                          isCompactPostListing: true,
                          onUpdate: () {},
                        );
                      },
                    ).paddingSymmetric(horizontal: 16),
                ],
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
