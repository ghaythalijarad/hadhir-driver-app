import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

part 'test_provider.g.dart';

@riverpod
String helloWorld(Ref ref) {
  return 'Hello, World!';
}

@Riverpod(keepAlive: true)
class Counter extends _$Counter {
  @override
  int build() {
    return 0;
  }

  void increment() {
    state++;
  }
}
