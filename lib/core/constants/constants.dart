// ignore_for_file: constant_identifier_names

//App State
import 'package:flutter/material.dart';

const APPNAME = "Sonus Music Player";

const USERKEY = 'userkey';

// Determine layouts
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isTablet => screenWidth >= 768;
  bool get isTabletLandscape => isTablet && isLandscape;
}

// Notifications
const CHANNELKEY = 'basic_channel';
const CHANNELNAME = 'Basic Notifications';
const CHANNELDESCRIPTION = 'Notification channel for basic notifications';
