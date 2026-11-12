import 'utils_web.dart' if (dart.library.io) 'utils_io.dart';

Future<String> extractAssetOrFile(String path,
    {bool isAsset = true, String? targetPath, bool checkHash = false}) {
  return getPlatformUtils().extractAssetOrFile(path,
      isAsset: isAsset, targetPath: targetPath, checkHash: checkHash);
}

Future<String> extractAssetZip(String assetPath,
    {String? targetPath, bool checkHash = false}) {
  return getPlatformUtils().extractAssetZip(assetPath,
      targetPath: targetPath, checkHash: checkHash);
}

Future<String> extractFileZip(String filePath,
    {String? targetPath, bool checkHash = false}) {
  return getPlatformUtils().extractFileZip(filePath,
      targetPath: targetPath, checkHash: checkHash);
}

Future<String> extractAsset(String assetPath) {
  return getPlatformUtils().extractAsset(assetPath);
}

/// Lists the files under [path] (optionally [recursive]ly), one per line.
///
/// Small debug helper used to inspect bundled/unpacked directories. Returns
/// `"<not found>"` if the directory does not exist.
Future<String> getDirFiles(String path, {bool recursive = false}) async {
  return getPlatformUtils().getDirFiles(path, recursive: recursive);
}
