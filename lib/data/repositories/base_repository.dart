import '../../core/error/app_error_mapper.dart';

abstract class BaseRepository {
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      throw AppErrorMapper.map(error, stackTrace);
    }
  }
}
