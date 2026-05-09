import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/post/add_post_screen.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';

class MyPostListScreen extends StatefulWidget {
  @override
  _MyPostListScreenState createState() => _MyPostListScreenState();
}

class _MyPostListScreenState extends State<MyPostListScreen> {
  ScrollController scrollController = ScrollController();

  Future<List<ServiceData>>? future;
  List<ServiceData> posts = [];

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init({bool showLoader = true}) async {
    if (showLoader) appStore.setLoading(true);

    future = getUserPostList(page, perPage: PER_PAGE_ITEM).then((value) {
      isLastPage = value.serviceList.validate().length != PER_PAGE_ITEM;
      if (page == 1) {
        posts.clear();
      }
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
        "My Posts",
        textColor: white,
        showBack: true,
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
              if (list.isEmpty) {
                return NoDataWidget(
                  title: "No posts found",
                  imageWidget: EmptyStateWidget(),
                ).center();
              }
              return AnimatedScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
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
                        isMyPost: true,
                        onUpdate: () {
                          page = 1;
                          init();
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
          Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddPostScreen().launch(context).then((value) {
            if (value ?? false) {
              page = 1;
              init();
            }
          });
        },
        child: Icon(Icons.add, color: white),
        backgroundColor: context.primaryColor,
      ),
    );
  }
}
