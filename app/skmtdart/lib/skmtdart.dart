
import 'dart:async';

import 'package:flutter/services.dart';

import 'dart:ffi';
import 'dart:io';

import 'skmtdart_ffi.g.dart';

//import 'package:path_provider/path_provider.dart';


const LIB_PATH = 'packages/skmtdart_ffi/linux/libskmtdart_ffi.so';

class Skmtdart {
  static const MethodChannel _channel =
      const MethodChannel('skmtdart');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}



// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names
final DynamicLibrary _dl = _open_internal();

/// Reference to the Dynamic Library, it should be only used for low-level access
final DynamicLibrary dl = _dl;

final SkmtDartffi skmtffi = SkmtDartffi(dl);

DynamicLibrary _open_internal() {
  if (Platform.isAndroid) return DynamicLibrary.open('libskmtdart_ffi.so');
  //if (Platform.isLinux) return DynamicLibrary.open(LIB_PATH);
  //if (Platform.isLinux) return DynamicLibrary.open('libskmtdart_ffi.so'); // wont work
  if (Platform.isLinux) return DynamicLibrary.executable();
  if (Platform.isIOS) return DynamicLibrary.executable();
  throw UnsupportedError('This platform is not supported.');
}

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;

  int addfunc(int op1, int op2) {
    return skmtffi.add_func(op1, op2);
    //return op1 + op2;
  }
}


