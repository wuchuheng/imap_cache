import 'package:imap_cache/src/dto/subject_info.dart';

abstract class ImapDirectoryServiceAbstract {
  Future<bool> exists();

  Future<bool> create();

  Future<void> selectPath();

  Future<List<SubjectInfo>> getFiles();

  Future<String?> getFileByUid(int uid);

  Future<List<String>> getFileNamesByDateTime(DateTime dateTime);

  String get path;

  Future<void> createFile({required String fileName, required String content});

  Future<void> deleteFileByUid(int uid);
}