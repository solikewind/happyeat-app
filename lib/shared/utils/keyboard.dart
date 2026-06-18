import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void dismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}
