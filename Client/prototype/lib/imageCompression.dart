import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

File convertXFileToFile(XFile xfile) {
  return File(xfile.path);
}

Future<List<XFile>> compressAllImages(List<XFile> images) async {
  List<XFile> compressedImages = [];
  for (XFile image in images) {
    final sizeBefore = (await File(image.path).readAsBytes()).length;
    XFile compressedImage = await compressImage(image);
    final sizeAfter = (await File(compressedImage.path).readAsBytes()).length;
    compressedImages.add(compressedImage);
  }
  return compressedImages;
}

Future<XFile> compressImage(XFile file) async {
  final int maxFileSize = 1 * 1024 * 1024; // 1mb in bytes
  int quality = 80; // Starting quality value
  final tempDir = await getTemporaryDirectory();
  final resultFilePath = path.join(tempDir.path, path.basename(file.path));

  while ((await file.length()) > maxFileSize) {
    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: quality,
    );
    final resultFile = File(resultFilePath)..writeAsBytesSync(result!);
    file = XFile(resultFile.path);
    quality -= 10; // Decrease quality by 10 after each compression attempt
  }

  return file;
}
