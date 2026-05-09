import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/custom_image_picker.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class AddPostScreen extends StatefulWidget {
  final int? postId;

  AddPostScreen({this.postId});

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

  List<File> imageFiles = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    await getPostFormConfig().then((value) {
      if (value['data'] != null) {
        categories = value['data']['categories'] ?? [];
        subcategories = value['data']['subcategories'] ?? [];
        zones = value['data']['zones'] ?? [];
      }
      setState(() {});
    }).catchError((e) {
      toast(e.toString());
    });

    appStore.setLoading(false);
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
                    decoration: inputDecoration(context, fillColor: context.cardColor, hintText: "Post Name"),
                  ),
                  16.height,
                  DropdownButtonFormField<int>(
                    decoration: inputDecoration(context, fillColor: context.cardColor),
                    hint: Text("Select Category", style: secondaryTextStyle()),
                    dropdownColor: context.cardColor,
                    style: primaryTextStyle(),
                    iconEnabledColor: context.iconColor,
                    value: selectedCategoryId,
                    items: categories.map((e) => DropdownMenuItem<int>(
                      value: e['id'],
                      child: Text(e['name'], style: primaryTextStyle()),
                    )).toList(),
                    onChanged: (val) {
                      selectedCategoryId = val;
                      selectedSubcategoryId = null;
                      setState(() {});
                    },
                  ),
                  16.height,
                  DropdownButtonFormField<int>(
                    decoration: inputDecoration(context, fillColor: context.cardColor),
                    hint: Text("Select Subcategory", style: secondaryTextStyle()),
                    dropdownColor: context.cardColor,
                    style: primaryTextStyle(),
                    iconEnabledColor: context.iconColor,
                    value: selectedSubcategoryId,
                    items: subcategories.where((e) => e['category_id'] == selectedCategoryId).map((e) => DropdownMenuItem<int>(
                      value: e['id'],
                      child: Text(e['name'], style: primaryTextStyle()),
                    )).toList(),
                    onChanged: (val) {
                      selectedSubcategoryId = val;
                      setState(() {});
                    },
                  ),
                  16.height,
                  AppTextField(
                    controller: priceController,
                    textFieldType: TextFieldType.PHONE,
                    decoration: inputDecoration(context, fillColor: context.cardColor, hintText: "Price"),
                  ),
                  16.height,
                  AppTextField(
                    controller: descriptionController,
                    textFieldType: TextFieldType.MULTILINE,
                    minLines: 3,
                    maxLines: 5,
                    decoration: inputDecoration(context, fillColor: context.cardColor, hintText: "Description"),
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
                  Text("Service Zones", style: boldTextStyle()),
                  8.height,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: zones.map((z) {
                      bool isSelected = selectedZones.contains(z['id']);
                      return FilterChip(
                        label: Text(z['name'], style: primaryTextStyle(color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        selectedColor: context.primaryColor,
                        checkmarkColor: Colors.white,
                        backgroundColor: context.cardColor,
                        onSelected: (val) {
                          if (val) {
                            selectedZones.add(z['id']);
                          } else {
                            selectedZones.remove(z['id']);
                          }
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  16.height,
                  Text("Images", style: boldTextStyle()),
                  8.height,
                  CustomImagePicker(
                    onFileSelected: (files) {
                      imageFiles = files;
                      setState(() {});
                    },
                    onRemoveClick: (path) {
                      imageFiles.removeWhere((element) => element.path == path);
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
          Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
