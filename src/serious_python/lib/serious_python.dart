import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:serious_python_platform_interface/serious_python_platform_interface.dart';

// Conditional import for IO operations
import 'src/io_stub.dart' if (dart.library.io) 'src/io_impl.dart';

export 'package:serious_python_platform_interface/src/utils.dart';

/// Provides cross-platform functionality for running Python programs.
class SeriousPython {
  SeriousPython._();

  /// Prepares the packaged app on disk (if needed) and returns the directory
  /// that contains its entry point.
  ///
  /// On macOS/iOS/Windows/Linux the app ships unpacked inside the application
  /// bundle next to the Python stdlib and site-packages, so this is a path
  /// lookup. On Android the app ships as a stored `app.zip` asset and is
  /// unpacked once (version-keyed) to a writable files-dir location on the
  /// first launch after an install/update.
  static Future<String> prepareApp() {
    // The platform implementations use method channels / path_provider, which
    // require the Flutter binding — ensure it's up so callers can invoke this
    // (directly or via [run]) before `runApp()`.
    WidgetsFlutterBinding.ensureInitialized();
    return SeriousPythonPlatform.instance.prepareApp();
  }

  /// Runs Python program from an asset.
  ///
  /// [assetPath] is the path to an asset which is a zip archive
  /// with a Python program. When the app starts the archive is unpacked
  /// to a temporary directory and Serious Python plugin will try to run
  /// `main.py` in the root of the archive. Current directory is changed to
  /// a temporary directory.
  ///
  /// If a Python app has a different entry point
  /// it could be specified with [appFileName] parameter.
  ///
  /// Environment variables that must be available to a Python program could
  /// be passed in [environmentVariables].
  ///
  /// By default, Serious Python expects Python dependencies installed into
  /// `__pypackages__` directory in the root of app directory. Additional paths
  /// to look for 3rd-party packages can be specified with [modulePaths] parameter.
  ///
  /// Set [sync] to `true` to sychronously run Python program; otherwise the
  /// program starts in a new thread.
  static Future<String?> run(String assetPath,
      {String? appFileName,
      List<String>? modulePaths,
      Map<String, String>? environmentVariables,
      bool? sync}) async {
    // unpack app from asset
    String appPath = "";
    if (path.extension(assetPath) == ".zip") {
      appPath = await extractAssetZip(assetPath);
      if (appFileName != null) {
        appPath = path.join(appPath, appFileName);
      } else if (await File(path.join(appPath, "main.pyc")).exists()) {
        appPath = path.join(appPath, "main.pyc");
      } else if (await File(path.join(appPath, "main.py")).exists()) {
        appPath = path.join(appPath, "main.py");
      } else {
        throw Exception(
            "App archive must contain either `main.py` or `main.pyc`; otherwise `appFileName` must be specified.");
      }
    } else {
      appPath = await extractAsset(assetPath);
    }

    // set current directory to app path
    Directory.current = path.dirname(appPath);

    // run python program
    return runProgram(appPath,
        modulePaths: modulePaths,
        environmentVariables: environmentVariables,
        script: Platform.isWindows ? "" : null,
        sync: sync);
  }

  /// Runs Python program from a path.
  ///
  /// This is low-level method.
  /// Make sure `Directory.current` is set before calling this method.
  ///
  /// [appPath] is the full path to a .py or .pyc file to run.
  ///
  /// Environment variables that must be available to a Python program could
  /// be passed in [environmentVariables].
  ///
  /// By default, Serious Python expects Python dependencies installed into
  /// `__pypackages__` directory in the root of app directory. Additional paths
  /// to look for 3rd-party packages can be specified with [modulePaths] parameter.
  ///
  /// Set [sync] to `true` to synchronously run Python program; otherwise the
  /// program starts in a new thread.
  static Future<String?> runProgram(String appPath,
      {String? script,
        List<String>? modulePaths,
        Map<String, String>? environmentVariables,
        bool? sync}) async {
    return SeriousPythonPlatform.instance.run(appPath,
        script: script,
        modulePaths: modulePaths,
        environmentVariables: environmentVariables,
        sync: sync);
  }

  static void terminate() {
    SeriousPythonPlatform.instance.terminate();
  }
}