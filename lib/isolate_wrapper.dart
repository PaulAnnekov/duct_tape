library duct_tape;

import "dart:async";
import "dart:isolate";

part 'src/isolate_spawned.dart';
part "isolate_root.dart";
part "isolates_controller.dart";

abstract class IsolateWrapper {
  run(IsolateSpawned isolate);
}