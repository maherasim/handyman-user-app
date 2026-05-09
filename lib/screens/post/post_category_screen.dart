import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class PostCategoryScreen extends StatefulWidget {
  final CategoryData category;

  const PostCategoryScreen({super.key, required this.category});

  @override
  State<PostCategoryScreen> createState() => _PostCategoryScreenState();
}

class _PostCategoryScreenState extends State<PostCategoryScreen> {
  ScrollController scrollController = ScrollController();
  Future<List<ServiceData>>? future;
  List<ServiceData> posts = [];

  int page = 1;
  bool isLastPage = false;

  int selectedSubCategoryId = -1; // -1 = All

  List<CategoryData> get _subcategories {
    final subs = widget.category.subcategories.validate();
    return [CategoryData(id: -1, name: language.lblAll), ...subs];
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init({bool showLoader = true}) {
    if (showLoader) appStore.setLoading(true);

    final Map<String, dynamic> request = {
      'per_page': PER_PAGE_ITEM,
      'page': page,
      'category_id': widget.category.id.validate(),
      'latitude': appStore.latitude,
      'longitude': appStore.longitude,
    };

    if (selectedSubCategoryId != -1) {
      request['subcategory_id'] = selectedSubCategoryId;
    }

    future = getPostList(request).then((value) {
      isLastPage = value.serviceList.validate().length != PER_PAGE_ITEM;
      if (page == 1) posts.clear();
      posts.addAll(value.serviceList.validate());
      setState(() {});
      return posts;
    }).catchError((e) {
      toast(e.toString());
      throw e;
    }).whenComplete(() => appStore.setLoading(false));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        widget.category.name.validate(value: 'Posts'),
        textColor: white,
        color: context.primaryColor,
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
                  if (_subcategories.length > 1) ...[
                    SizedBox(
                      height: 102,
                      child: HorizontalList(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        spacing: 16,
                        itemCount: _subcategories.length,
                        itemBuilder: (context, index) {
                          final s = _subcategories[index];
                          final bool isSelected = selectedSubCategoryId == s.id.validate(value: -1);

                          final String imageUrl = s.subCategoryImage.validate().isNotEmpty
                              ? s.subCategoryImage.validate()
                              : s.categoryImage.validate();

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
                                    color: isSelected ? context.primaryColor.withValues(alpha: 0.20) : const Color(0xFF3D4044),
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: boxDecorationDefault(
                                        shape: BoxShape.circle,
                                        color: isSelected ? context.primaryColor.withValues(alpha: 0.15) : const Color(0xFFE9ECEF),
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
                                              color: isSelected ? context.primaryColor : const Color(0xFF9AA0A6),
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ),
                                8.height,
                                Text(
                                  s.name.validate(),
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: isSelected ? context.primaryColor : textPrimaryColorGlobal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).onTap(() {
                            selectedSubCategoryId = s.id.validate(value: -1);
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
          Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}

