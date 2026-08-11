import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:serious_python_platform_interface/serious_python_platform_interface.dart';

// Conditional import for IO operations
import 'src/io_stub.dart' if (dart.library.io) 'src/io_impl.dart';

export 'package:serious_python_platform_interface/src/utils.dart';

/// Provides cross-platform functionality for running Python programs.
class SeriousPython {
  SeriousPython._();

  /// Returns the current name and version of the operating system.
  static Future<String?> getPlatformVersion() {
    return SeriousPythonPlatform.instance.getPlatformVersion();
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
  ///
  /// [stackSize] sets the stack size (in bytes) of that thread on iOS/macOS;
  /// defaults to 8 MB. Ignored on other platforms.
  static Future<String?> run(String assetPath,
      {String? appFileName,
      List<String>? modulePaths,
      Map<String, String>? environmentVariables,
      bool? sync,
      int? stackSize}) async {
    // Handle web platform differently
    if (kIsWeb) {
      return _runWeb(assetPath,
          appFileName: appFileName, modulePaths: modulePaths, environmentVariables: environmentVariables, sync: sync);
    } else {
      return _runDesktop(assetPath,
          appFileName: appFileName,
          modulePaths: modulePaths,
          environmentVariables: environmentVariables,
          sync: sync,
          stackSize: stackSize);
    }
  }

  /// Web-specific implementation
  static Future<String?> _runWeb(String assetPath,
      {String? appFileName, List<String>? modulePaths, Map<String, String>? environmentVariables, bool? sync}) async {
    String virtualPath;
    if (path.extension(assetPath) == ".zip") {
      virtualPath = assetPath.replaceAll(".zip", "");
      // TODO Check if path exists and except with unzip hint if not
    } else {
      virtualPath = assetPath;
    }

    if (appFileName != null) {
      virtualPath = '$virtualPath/$appFileName';
    } else {
      virtualPath = '$virtualPath/main.py';
    }

    return runProgram(virtualPath, modulePaths: modulePaths, environmentVariables: environmentVariables, sync: sync);
  }

  /// Desktop-specific implementation
  static Future<String?> _runDesktop(String assetPath,
      {String? appFileName,
      List<String>? modulePaths,
      Map<String, String>? environmentVariables,
      bool? sync,
      int? stackSize}) async {
    String appPath = "";
    if (path.extension(assetPath) == ".zip") {
      appPath = await extractAssetZip(assetPath);
      if (appFileName != null) {
        appPath = path.join(appPath, appFileName);
      } else {
        appPath = await FileSystem.findMainFile(appPath);
      }
    } else {
      appPath = await extractAsset(assetPath);
    }

    // set current directory to app path
    await FileSystem.setCurrentDirectory(path.dirname(appPath));

    // run python program
    return runProgram(appPath,
        modulePaths: modulePaths,
        environmentVariables: environmentVariables,
        script: FileSystem.isWindows ? "" : null,
        sync: sync,
        stackSize: stackSize);
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
  ///
  /// [stackSize] sets the stack size (in bytes) of that thread on iOS/macOS;
  /// defaults to 8 MB. Ignored on other platforms.
  static Future<String?> runProgram(String appPath,
      {String? script,
      List<String>? modulePaths,
      Map<String, String>? environmentVariables,
      bool? sync,
      int? stackSize}) async {
    return SeriousPythonPlatform.instance.run(appPath,
        script: script,
        modulePaths: modulePaths,
        environmentVariables: environmentVariables,
        sync: sync,
        stackSize: stackSize);
  }

  static void terminate() {
    SeriousPythonPlatform.instance.terminate();
  }
}
