import 'dart:io';

import 'package:flutter_prunekit/src/cli/runner.dart';

Future<void> main(List<String> arguments) async {
  final exitCode = await run(arguments);
  exit(exitCode);
}
