import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../service/view_all_service_screen.dart';

class ServiceListComponent extends StatelessWidget {
  final List<ServiceData> serviceList;
  final String? title;
  final VoidCallback? onViewAll;

  ServiceListComponent({required this.serviceList, this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        ViewAllLabel(
          label: title ?? language.service,
          list: serviceList,
          onTap: () {
            if (onViewAll != null) {
              onViewAll!.call();
            } else {
              ViewAllServiceScreen().launch(context);
            }
          },
        ).paddingSymmetric(horizontal: 16),
        8.height,
        serviceList.isNotEmpty
            ? HorizontalList(
                itemCount: serviceList.length,
                spacing: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final double cardWidth = (context.width() - 44) / 2;
                  return ServiceComponent(
                    serviceData: serviceList[index],
                    width: cardWidth,
                  );
                },
              )
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: NoDataWidget(
                  title: language.lblNoServicesFound,
                  imageWidget: EmptyStateWidget(),
                ),
              ).center(),
      ],
    );
  }
}
