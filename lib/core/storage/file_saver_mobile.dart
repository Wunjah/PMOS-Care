import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareFile(List<int> bytes, String filename, String shareText) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  
  await Share.shareXFiles(
    [XFile(file.path)],
    text: shareText,
    subject: shareText,
  );
}
