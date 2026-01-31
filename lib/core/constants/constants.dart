// ignore_for_file: constant_identifier_names

//App State
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const APPNAME = "Sonus Music Player";

const USERKEY = 'userkey';

// Determine layouts
double get screenWidth => MediaQuery.of(Get.context!).size.width;

Orientation get orientation => MediaQuery.of(Get.context!).orientation;
bool get isLandscape => orientation == Orientation.landscape;

bool get isTablet => screenWidth >= 768;
bool get isTabletLandscape => isTablet && isLandscape;

// Notifications
const CHANNELKEY = 'basic_channel';
const CHANNELNAME = 'Basic Notifications';
const CHANNELDESCRIPTION = 'Notification channel for basic notifications';
