import '../app/locator.dart';
import '../services/api/api.dart';

import '../utils/dio_helper.dart';
import '../model/offline_storage.dart';
import '../model/config.dart';

initApiConfig() async {
  if (Config().baseUrl != null) {
    await DioHelper.init(Config().baseUrl!);
    await DioHelper.initCookies();
  }
}

Future<void> cacheAllUsers() async {
  var allUsers = OfflineStorage.getItem('allUsers');
  allUsers = allUsers["data"];
  if (allUsers != null) {
    return;
  } else {
    var fieldNames = [
      "`tabUser`.`name`",
      "`tabUser`.`full_name`",
      "`tabUser`.`user_image`",
    ];

    var filters = [
      ["User", "enabled", "=", 1],
    ];

    try {
      var meta = await locator<Api>().getDoctype('User');

      var res = await locator<Api>().fetchList(
        fieldnames: fieldNames,
        doctype: 'User',
        orderBy: '`tabUser`.`modified` desc',
        filters: filters,
        meta: meta.docs[0],
      );

      var usr = {};
      res.forEach((element) {
        usr[element["name"]] = element;
      });
      OfflineStorage.putItem('allUsers', usr);
    } catch (e) {
      throw e;
    }
  }
}

Future<void> setBaseUrl(url) async {
  print('setBaseUrl called with: $url');

  // If URL already has a protocol, use it as-is
  if (url.startsWith('http://') || url.startsWith('https://')) {
    print('URL already has protocol: $url');
  } else {
    // If no protocol specified, use http for localhost/IP addresses, https for others
    if (url.startsWith('localhost') ||
        url.startsWith('127.0.0.1') ||
        RegExp(r'^\d+\.\d+\.\d+\.\d+').hasMatch(url)) {
      url = "http://$url";
      print('Added http:// prefix for local address: $url');
    } else {
      url = "https://$url";
      print('Added https:// prefix for remote address: $url');
    }
  }

  await Config.set('baseUrl', url);
  print('Config baseUrl set to: $url');
  await DioHelper.init(url);
  print(
    'DioHelper initialized with baseUrl: ${DioHelper.dio?.options.baseUrl}',
  );
}

String getAbsoluteUrl(String url) {
  return Uri.encodeFull("${Config().baseUrl}$url");
}
