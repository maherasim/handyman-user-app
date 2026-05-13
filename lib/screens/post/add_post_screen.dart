import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/custom_image_picker.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class AddPostScreen extends StatefulWidget {
  final int? postId;
  final ServiceData? postData;

  AddPostScreen({this.postId, this.postData});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  bool isFeatured = false;

  int? selectedCategoryId;
  int? selectedSubcategoryId;

  List<dynamic> categories = [];
  List<dynamic> subcategories = [];
  List<dynamic> zones = [];

  List<int> selectedZones = [];
  int? selectedZoneId;

  List<File> imageFiles = [];
  List<String> selectedImages = [];
  Key imagePickerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    await getPostFormConfig(postId: widget.postId).then((value) {
      if (value['data'] != null) {
        categories = value['data']['categories'] ?? [];
        subcategories = value['data']['subcategories'] ?? [];
        zones = value['data']['zones'] ?? [];
        if (widget.postData != null) {
          applyPostData(widget.postData!);
        }
        if (value['data']['post'] is Map<String, dynamic>) {
          applyPostMap(value['data']['post']);
        }
        if (selectedZoneId != null &&
            !zones.any(
                (zone) => zone['id'].toString().toInt() == selectedZoneId)) {
          selectedZoneId = null;
          selectedZones.clear();
        }
      }
      setState(() {});
    }).catchError((e) {
      toast(e.toString());
    });

    if (widget.postId != null) {
      await loadPostDetails();
    }

    appStore.setLoading(false);
  }

  void applyPostMap(Map<String, dynamic> post) {
    nameController.text = post['name']?.toString().validate() ?? '';
    priceController.text =
        post['price'] != null ? post['price'].toString() : '';
    descriptionController.text =
        post['description']?.toString().validate() ?? '';
    final int? categoryId = parseInt(post['category_id']);
    final int? subcategoryId = parseInt(post['subcategory_id']);
    selectedCategoryId =
        containsOption(categories, categoryId) ? categoryId : null;
    selectedSubcategoryId =
        containsSubcategoryOption(subcategoryId) ? subcategoryId : null;
    isFeatured = parseInt(post['is_featured']).validate() == 1;

    if (post['service_zones'] is List) {
      for (final dynamic zone in post['service_zones']) {
        if (zone is Map) {
          final int? id = parseInt(zone['id']);
          if (id != null && !containsOption(zones, id)) {
            addMissingOption(zones, id, zone['name']?.toString() ?? 'Zone $id');
          }
        }
      }
    }

    final List<int> zoneIds = parseIntList(post['service_zone_ids']);
    if (zoneIds.isNotEmpty) {
      final int zoneId = zoneIds.first;
      selectedZoneId = containsOption(zones, zoneId) ? zoneId : null;
      selectedZones = selectedZoneId != null ? [selectedZoneId!] : [];
    } else if (post['service_zones'] is List &&
        (post['service_zones'] as List).isNotEmpty) {
      final dynamic zone = (post['service_zones'] as List).first;
      if (zone is Map) {
        final int? id = parseInt(zone['id']);
        if (id != null) {
          addMissingOption(zones, id, zone['name']?.toString() ?? 'Zone $id');
          selectedZoneId = id;
          selectedZones = [id];
        }
      }
    }

    selectedImages = parseStringList(post['attchments']);
    imagePickerKey = UniqueKey();
  }

  void applyPostData(ServiceData detail) {
    if (detail.categoryId != null &&
        !containsOption(categories, detail.categoryId)) {
      addMissingOption(categories, detail.categoryId!,
          detail.categoryName.validate(value: 'Category ${detail.categoryId}'));
    }
    if (detail.subCategoryId != null &&
        !containsOption(subcategories, detail.subCategoryId)) {
      addMissingOption(
          subcategories,
          detail.subCategoryId!,
          detail.subCategoryName
              .validate(value: 'Subcategory ${detail.subCategoryId}'),
          categoryId: detail.categoryId);
    }

    nameController.text = detail.name.validate();
    priceController.text = detail.price.validate().toString();
    descriptionController.text = detail.description.validate();
    selectedCategoryId =
        categories.any((e) => e['id'].toString().toInt() == detail.categoryId)
            ? detail.categoryId
            : null;
    selectedSubcategoryId = subcategories
            .any((e) => e['id'].toString().toInt() == detail.subCategoryId)
        ? detail.subCategoryId
        : null;
    isFeatured = detail.isFeatured.validate() == 1;

    final int? zoneId = resolveSelectedZoneIdFromPost(detail);
    if (zoneId != null &&
        zones.any((zone) => zone['id'].toString().toInt() == zoneId)) {
      selectedZoneId = zoneId;
      selectedZones = [zoneId];
    }
  }

  Future<void> loadPostDetails() async {
    await getPostDetails(postId: widget.postId!, customerId: appStore.userId)
        .then((value) {
      final ServiceData? detail = value.serviceDetail;
      if (detail == null) return;

      applyPostData(detail);

      final int? zoneId = resolveSelectedZoneId(value);
      if (zoneId != null &&
          zones.any((e) => e['id'].toString().toInt() == zoneId)) {
        selectedZoneId = zoneId;
        selectedZones = [zoneId];
      }

      setState(() {});
    }).catchError((e) {
      toast(e.toString());
    });
  }

  int? resolveSelectedZoneIdFromPost(ServiceData detail) {
    final mappings = detail.serviceAddressMapping.validate();
    if (mappings.isNotEmpty) {
      return mappings.first.providerAddressId;
    }

    return null;
  }

  int? resolveSelectedZoneId(ServiceDetailResponse response) {
    if (response.zones.isNotEmpty) {
      return response.zones.first.id;
    }

    final mappings =
        response.serviceDetail?.serviceAddressMapping.validate() ?? [];
    if (mappings.isNotEmpty) {
      return mappings.first.providerAddressId;
    }

    return null;
  }

  bool containsOption(List<dynamic> options, int? id) {
    if (id == null) return false;
    return options.any((option) => parseInt(option['id']) == id);
  }

  bool containsSubcategoryOption(int? id) {
    if (id == null || selectedCategoryId == null) return false;
    return subcategories.any((option) =>
        parseInt(option['id']) == id &&
        parseInt(option['category_id']) == selectedCategoryId);
  }

  void addMissingOption(List<dynamic> options, int id, String name,
      {int? categoryId}) {
    options.add({
      'id': id,
      'name': name,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  List<int> parseIntList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => parseInt(e)).whereType<int>().toList();
  }

  List<String> parseStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  void save() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      if (selectedCategoryId == null) {
        toast("Please select category");
        return;
      }
      if (selectedZones.isEmpty) {
        toast("Please select at least one zone");
        return;
      }
      if (widget.postId == null && imageFiles.isEmpty) {
        toast("Please select at least one image");
        return;
      }
      hideKeyboard(context);

      await savePost(
        id: widget.postId,
        name: nameController.text,
        categoryId: selectedCategoryId!,
        subcategoryId: selectedSubcategoryId,
        description: descriptionController.text,
        price: priceController.text.toDouble(),
        isFeatured: isFeatured ? 1 : 0,
        serviceZones: selectedZones,
        postAttachments: imageFiles,
        onSuccess: (res) {
          toast(res['message'] ?? 'Saved successfully');
          finish(context, true);
        },
        onError: (e) {
          toast(e.toString());
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: widget.postId == null ? "Create Post" : "Edit Post",
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: nameController,
                    textFieldType: TextFieldType.NAME,
                    decoration: inputDecoration(context,
                        fillColor: context.cardColor, hintText: "Post Name"),
                  ),
                  16.height,
                  DropdownButtonFormField<int>(
                    decoration:
                        inputDecoration(context, fillColor: context.cardColor),
                    hint: Text("Select Category", style: secondaryTextStyle()),
                    dropdownColor: context.cardColor,
                    style: primaryTextStyle(),
                    iconEnabledColor: context.iconColor,
                    value: selectedCategoryId,
                    items: categories
                        .map((e) => DropdownMenuItem<int>(
                              value: e['id'].toString().toInt(),
                              child: Text(e['name'], style: primaryTextStyle()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      selectedCategoryId = val;
                      selectedSubcategoryId = null;
                      setState(() {});
                    },
                  ),
                  16.height,
                  DropdownButtonFormField<int>(
                    decoration:
                        inputDecoration(context, fillColor: context.cardColor),
                    hint:
                        Text("Select Subcategory", style: secondaryTextStyle()),
                    dropdownColor: context.cardColor,
                    style: primaryTextStyle(),
                    iconEnabledColor: context.iconColor,
                    value: selectedSubcategoryId,
                    items: subcategories
                        .where((e) =>
                            e['category_id'].toString().toInt() ==
                            selectedCategoryId)
                        .map((e) => DropdownMenuItem<int>(
                              value: e['id'].toString().toInt(),
                              child: Text(e['name'], style: primaryTextStyle()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      selectedSubcategoryId = val;
                      setState(() {});
                    },
                  ),
                  16.height,
                  AppTextField(
                    controller: priceController,
                    textFieldType: TextFieldType.PHONE,
                    decoration: inputDecoration(context,
                        fillColor: context.cardColor, hintText: "Price"),
                  ),
                  16.height,
                  AppTextField(
                    controller: descriptionController,
                    textFieldType: TextFieldType.MULTILINE,
                    minLines: 3,
                    maxLines: 5,
                    decoration: inputDecoration(context,
                        fillColor: context.cardColor, hintText: "Description"),
                  ),
                  16.height,
                  Row(
                    children: [
                      Text("Is Featured?", style: primaryTextStyle()).expand(),
                      Switch(
                        value: isFeatured,
                        onChanged: (val) {
                          isFeatured = val;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  16.height,
                  DropdownButtonFormField<int>(
                    decoration:
                        inputDecoration(context, fillColor: context.cardColor),
                    hint: Text("Select Service Zone",
                        style: secondaryTextStyle()),
                    dropdownColor: context.cardColor,
                    style: primaryTextStyle(),
                    iconEnabledColor: context.iconColor,
                    value: selectedZoneId,
                    items: zones.map((zone) {
                      final int id = zone['id'].toString().toInt();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(zone['name'].toString(),
                            style: primaryTextStyle()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      selectedZoneId = val;
                      selectedZones = val != null ? [val] : [];
                      setState(() {});
                    },
                  ),
                  16.height,
                  Text("Images", style: boldTextStyle()),
                  8.height,
                  CustomImagePicker(
                    key: imagePickerKey,
                    selectedImages: selectedImages,
                    onFileSelected: (files) {
                      imageFiles = files
                          .where((file) => !file.path.contains('http'))
                          .toList();
                      setState(() {});
                    },
                    onRemoveClick: (path) {
                      imageFiles.removeWhere((element) => element.path == path);
                      selectedImages.removeWhere((element) => element == path);
                      setState(() {});
                    },
                  ),
                  32.height,
                  AppButton(
                    text: language.save,
                    color: context.primaryColor,
                    width: context.width(),
                    onTap: save,
                  ),
                ],
              ),
            ),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
