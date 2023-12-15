part of 'package:xrp_dart/src/xrpl/bytes/serializer.dart';

abstract class UInt extends SerializedType {
  UInt([List<int>? buffer]) : super(buffer);

  int get value {
    return int.parse(BytesUtils.toHexString(_buffer), radix: 16);
  }

  @override
  dynamic toJson() {
    return value;
  }
}
