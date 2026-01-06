import 'package:frappe_app/model/login_request.dart';
import 'package:frappe_app/model/login_response.dart';
import 'package:frappe_app/utils/dio_helper.dart';
import 'package:injectable/injectable.dart';

import '../../app/locator.dart';
import '../../services/api/api.dart';
import '../../model/offline_storage.dart';

import '../../utils/helpers.dart';
import '../../utils/http.dart';

import '../../model/config.dart';

import '../../views/base_viewmodel.dart';

class SavedCredentials {
  String? serverURL;
  String? usr;

  SavedCredentials({this.serverURL, this.usr});
}

@lazySingleton
class LoginViewModel extends BaseViewModel {
  var savedCreds = SavedCredentials();

  late String loginButtonLabel;

  init() {
    loginButtonLabel = "Login";

    savedCreds = SavedCredentials(
      serverURL: Config().baseUrl,
      usr: OfflineStorage.getItem('usr')["data"],
    );
  }

  updateUserDetails(LoginResponse response) {
    Config.set('isLoggedIn', true);

    Config.set('userId', response.userId);
    Config.set('user', response.fullName);
  }

  getSystemSettings() async {
    print('Loading system settings...');
    var systemSettings = await locator<Api>().getSystemSettings();
    print('System settings loaded: ${systemSettings.toJson()}');
    // TODO: check permission
    OfflineStorage.putItem('systemSettings', systemSettings.toJson());
    print('System settings saved to OfflineStorage');
  }

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    loginButtonLabel = "Verifying...";
    notifyListeners();

    try {
      print('Making login API call to: ${Config().baseUrl}/api/method/login');
      var response = await locator<Api>().login(loginRequest);

      print('Login API response received: ${response.toJson()}');

      if (response.verification != null) {
        loginButtonLabel = "Verify";
        return response;
      } else {
        updateUserDetails(response);

        OfflineStorage.putItem('usr', loginRequest.usr);

        // These operations are not critical for login success
        try {
          await cacheAllUsers();
        } catch (e) {
          print('Warning: Failed to cache all users: $e');
        }

        try {
          await initAwesomeItems();
        } catch (e) {
          print('Warning: Failed to initialize awesome items: $e');
        }

        try {
          await DioHelper.initCookies();
        } catch (e) {
          print('Warning: Failed to initialize cookies: $e');
        }

        try {
          await getSystemSettings();
        } catch (e) {
          print('Warning: Failed to get system settings: $e');
        }

        loginButtonLabel = "Success";
        notifyListeners();

        return response;
      }
    } catch (e) {
      print('Login failed with error: $e');
      Config.set('isLoggedIn', false);
      loginButtonLabel = "Login";
      notifyListeners();
      throw e;
    }
  }
}
