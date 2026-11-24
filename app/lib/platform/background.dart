import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Runs a heavy computation off the UI thread: in an isolate on phones, inline on the web, where
/// `Isolate.run` is not available (the browser build has no isolates; the work blocks the tab for its
/// duration instead).
Future<R> background<R>(FutureOr<R> Function() work) => kIsWeb ? Future.sync(work) : Isolate.run(work);

/// Parallel workers for batched background jobs: 1 on the web (no isolates), else the CPU count.
int backgroundWorkers(int Function() cpus) => kIsWeb ? 1 : cpus();
