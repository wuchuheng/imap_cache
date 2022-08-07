import 'package:imap_cache/src/cache_io_abstract.dart';
import 'package:imap_cache/src/imap_service/imap_service.dart';
import 'package:imap_cache/src/local_cache_service/local_cache_service.dart';
import 'package:imap_cache/src/utils/logger.dart';
import 'package:imap_cache/src/utils/timer.dart';

class SyncData {
  /// If this is the case. then online synchronization of data to offline
  static Future<void> onlineExistAndLocalNone({
    required RegisterInfo onlineRegisterInfo,
    required RegisterInfo localRegisterInfo,
    required String key,
    required ImapService imapService,
  }) async {
    if (onlineRegisterInfo.data[key] == null ||
        onlineRegisterInfo.data[key]?.deletedAt != null ||
        await LocalCacheService().has(key: key)) {
      return;
    }
    String value = await imapService.get(key: key);
    await LocalCacheService().set(
      key: key,
      value: value,
    );
    Logger.info('synchronization: online --> local. key: $key value: $value');
  }

  /// If this is the case. compare witch side is up to date and synchronize the
  /// data to whichever side.
  static Future<void> onlineExistAndLocalExist({
    required RegisterInfo onlineRegisterInfo,
    required RegisterInfo localRegisterInfo,
    required String key,
    required ImapService imapService,
  }) async {
    if (onlineRegisterInfo.data[key] == null ||
        onlineRegisterInfo.data[key]?.deletedAt != null ||
        !await LocalCacheService().has(key: key)) {
      return;
    }
    RegisterItemInfo onlineKeyInfo = onlineRegisterInfo.data[key]!;
    RegisterItemInfo localKeyInfo = localRegisterInfo.data[key]!;
    if (onlineKeyInfo.hash == localKeyInfo.hash) {
      return;
    }
    int onlineKeyUpdatedAt =
        TimerUtil.timeStringConvertMilliseconds(onlineKeyInfo.lastUpdatedAt);
    int localKeyUpdatedAt =
        TimerUtil.timeStringConvertMilliseconds(localKeyInfo.lastUpdatedAt);
    if (onlineKeyUpdatedAt > localKeyUpdatedAt) {
      String value = await imapService.get(key: key);
      await LocalCacheService().set(
        key: key,
        value: value,
      );
      Logger.info('synchronization: online --> local. key: $key value: $value');
    } else {
      String value = await LocalCacheService().get(key: key);
      await imapService.set(key: key, value: value);
      Logger.info(
          'synchronization: local --> online . key: $key value: $value');
    }
  }

  /// If this is the case. then the local data is synchronized to the online.
  static Future<void> onlineNoneAndLocalExist({
    required RegisterInfo onlineRegisterInfo,
    required RegisterInfo localRegisterInfo,
    required String key,
    required ImapService imapService,
  }) async {
    if (onlineRegisterInfo.data.containsKey(key) &&
        onlineRegisterInfo.data[key]!.deletedAt == null) return;
    if (!await LocalCacheService().has(key: key)) return;
    String value = await LocalCacheService().get(key: key);
    if (onlineRegisterInfo.data.containsKey(key)) {
      RegisterItemInfo onlineKeyInfo = onlineRegisterInfo.data[key]!;
      RegisterItemInfo localKeyInfo = localRegisterInfo.data[key]!;
      int onlineKeyUpdatedAt =
          TimerUtil.timeStringConvertMilliseconds(onlineKeyInfo.lastUpdatedAt);
      int localKeyUpdatedAt =
          TimerUtil.timeStringConvertMilliseconds(localKeyInfo.lastUpdatedAt);
      if (onlineKeyUpdatedAt > localKeyUpdatedAt) {
        await LocalCacheService().unset(key: key);
        Logger.info('synchronization: Delete local. key: $key value: $value');
      } else {
        await imapService.set(key: key, value: value);
        Logger.info(
            'synchronization: local --> online . key: $key value: $value');
      }
    } else {
      await imapService.set(key: key, value: value);
      Logger.info(
          'synchronization: local --> online . key: $key value: $value'
      );
    }
  }
}
