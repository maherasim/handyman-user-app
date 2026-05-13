import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/contact_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/chat/widget/user_item_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblChat,
      child: Observer(builder: (context) {
        return SnapHelperWidget(
          future: Future.value(FirebaseAuth.instance.currentUser != null &&
              appStore.uid.isNotEmpty),
          onSuccess: (isLoggedIn) {
            if (!isLoggedIn) {
              return NoDataWidget(
                title: language.youAreNotConnectedWithChatServer,
                subTitle: language.NotConnectedWithChatServerMessage,
                onRetry: () async {
                  if (!appStore.isLoggedIn) {
                    const SignInScreen().launch(context);
                  } else {
                    appStore.setLoading(true);
                    await authService.verifyFirebaseUser().then((value) {
                      setState(() {});
                    }).catchError((e) {
                      toast(e.toString());
                    });
                    appStore.setLoading(false);
                  }
                },
                retryText: language.connect,
                imageWidget: const EmptyStateWidget(),
              ).paddingSymmetric(horizontal: 16);
            } else {
              return StreamBuilder<QuerySnapshot>(
                stream: chatServices
                    .fetchChatListQuery(userId: appStore.uid)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return NoDataWidget(
                      title: snap.error.toString(),
                      imageWidget: const ErrorStateWidget(),
                    ).paddingSymmetric(horizontal: 16);
                  }

                  if (snap.connectionState == ConnectionState.waiting) {
                    return LoaderWidget().center();
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return NoDataWidget(
                      title: language.noConversation,
                      subTitle: language.noConversationSubTitle,
                      imageWidget: const EmptyStateWidget(),
                    ).paddingSymmetric(horizontal: 16);
                  }

                  return AnimatedListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: docs.length,
                    listAnimationType: ListAnimationType.FadeIn,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final contact = ContactModel.fromJson(data);
                      final userUid = contact.uid.validate();

                      if (userUid.isEmpty) return const Offstage();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserItemWidget(userUid: userUid, contact: contact),
                          if (index != docs.length - 1)
                            Divider(
                                height: 0,
                                indent: 82,
                                color: context.dividerColor),
                        ],
                      );
                    },
                  );
                },
              );
            }
          },
          loadingWidget: LoaderWidget(),
          errorBuilder: (p0) {
            return NoDataWidget(
              title: p0,
              imageWidget: const ErrorStateWidget(),
            );
          },
        );
      }),
    );
  }
}
