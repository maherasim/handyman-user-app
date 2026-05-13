import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/contact_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/screens/chat/user_chat_screen.dart';
import 'package:booking_system_flutter/screens/chat/widget/last_messege_chat.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class UserItemWidget extends StatefulWidget {
  final String userUid;
  final ContactModel? contact;

  UserItemWidget({required this.userUid, this.contact});

  @override
  State<UserItemWidget> createState() => _UserItemWidgetState();
}

class _UserItemWidgetState extends State<UserItemWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserData>(
      stream: userService.singleUser(widget.userUid),
      builder: (context, snap) {
        if (snap.hasData) {
          UserData data = snap.data!;

          return InkWell(
            onTap: () {
              UserChatScreen(
                receiverUser: data,
                chatType: widget.contact?.chatType.validate(value: 'service') ??
                    'service',
              ).launch(context,
                  pageRouteAnimation: PageRouteAnimation.Fade,
                  duration: 300.milliseconds);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (data.profileImage.validate().isEmpty)
                    Container(
                      height: 40,
                      width: 40,
                      padding: const EdgeInsets.all(6),
                      color: context.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                              data.displayName
                                  .validate()[0]
                                  .validate()
                                  .toUpperCase(),
                              style: boldTextStyle(color: context.primaryColor))
                          .center()
                          .fit(),
                    ).cornerRadiusWithClipRRect(50)
                  else
                    CachedImageWidget(
                        url: data.profileImage.validate(),
                        height: 40,
                        circle: true,
                        fit: BoxFit.cover),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                data.firstName.validate() +
                                    " " +
                                    data.lastName.validate(),
                                style: boldTextStyle(),
                                maxLines: 1,
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                              ),
                              8.width,
                              _chatTypeBadge(context),
                            ],
                          ),
                          StreamBuilder<int>(
                            stream: chatServices.getUnReadCount(
                                senderId: appStore.uid.validate(),
                                receiverId: data.uid.validate()),
                            builder: (context, snap) {
                              if (snap.hasData) {
                                if (snap.data != 0) {
                                  return Container(
                                    height: 18,
                                    width: 18,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: primaryColor),
                                    child: Text(
                                      snap.data.validate().toString(),
                                      style: secondaryTextStyle(color: white),
                                      textAlign: TextAlign.center,
                                    ).center(),
                                  );
                                }
                              }
                              return const Offstage();
                            },
                          ),
                        ],
                      ),
                      LastMessageChat(
                          stream: chatServices.fetchLastMessageBetween(
                              senderId: appStore.uid.validate(),
                              receiverId: widget.userUid)),
                    ],
                  ).expand()
                ],
              ),
            ),
          );
        }
        if (snap.hasError) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryColor.withValues(alpha: 0.2),
              ),
              child:
                  Icon(Icons.person_off_outlined, color: context.primaryColor),
            ),
            title: Text(language.lblNoUserFound, style: boldTextStyle()),
            subtitle: Text(widget.userUid,
                style: secondaryTextStyle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(language.loadingChats, style: primaryTextStyle()),
        );
      },
    );
  }

  Widget _chatTypeBadge(BuildContext context) {
    final bool isPostChat = widget.contact?.chatType == 'post';
    final Color badgeColor = isPostChat ? Colors.blue : context.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: boxDecorationDefault(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: radius(10),
      ),
      child: Text(
        isPostChat ? 'Posts' : 'Service',
        style: secondaryTextStyle(color: badgeColor, size: 10),
      ),
    );
  }
}
