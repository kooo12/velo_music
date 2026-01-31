import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/features/home/home_controller.dart';

class SearchView extends GetView<HomeController> {
  const SearchView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Search'),
    );
  }
}
