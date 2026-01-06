class SystemSettingsResponse {
  late Message message;

  SystemSettingsResponse({required this.message});

  SystemSettingsResponse.fromJson(Map<String, dynamic> json) {
    message = Message.fromJson(json['message']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message.toJson();
    return data;
  }
}

class Message {
  late List<String> timezones;
  late Defaults defaults;

  Message({required this.timezones, required this.defaults});

  Message.fromJson(Map<String, dynamic> json) {
    timezones = json['timezones'] != null
        ? json['timezones'].cast<String>()
        : [];
    defaults = json['defaults'] != null
        ? Defaults.fromJson(json['defaults'])
        : Defaults(
            appName: 'Frappe',
            timeZone: 'UTC',
            dateFormat: 'yyyy-mm-dd',
            timeFormat: 'HH:mm:ss',
            numberFormat: '#,###.##',
            floatPrecision: '2',
            currencyPrecision: '2',
            sessionExpiry: '6',
            sessionExpiryMobile: '30',
            minimumPasswordScore: '2',
            twoFactorMethod: 'OTP App',
            otpIssuerName: 'Frappe',
          );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timezones'] = this.timezones;
    data['defaults'] = this.defaults.toJson();
    return data;
  }
}

class Defaults {
  late String appName;
  late String timeZone;
  late String dateFormat;
  late String timeFormat;
  late String numberFormat;
  late String floatPrecision;
  late String currencyPrecision;
  late String sessionExpiry;
  late String sessionExpiryMobile;
  late String minimumPasswordScore;
  late String twoFactorMethod;
  late String otpIssuerName;

  Defaults({
    required this.appName,
    required this.timeZone,
    required this.dateFormat,
    required this.timeFormat,
    required this.numberFormat,
    required this.floatPrecision,
    required this.currencyPrecision,
    required this.sessionExpiry,
    required this.sessionExpiryMobile,
    required this.minimumPasswordScore,
    required this.twoFactorMethod,
    required this.otpIssuerName,
  });

  Defaults.fromJson(Map<String, dynamic> json) {
    appName = json['app_name'] ?? 'Frappe';
    timeZone = json['time_zone'] ?? 'UTC';
    dateFormat = json['date_format'] ?? 'yyyy-mm-dd';
    timeFormat = json['time_format'] ?? 'HH:mm:ss';
    numberFormat = json['number_format'] ?? '#,###.##';
    floatPrecision = json['float_precision'] ?? '2';
    currencyPrecision = json['currency_precision'] ?? '2';
    sessionExpiry = json['session_expiry'] ?? '6';
    sessionExpiryMobile = json['session_expiry_mobile'] ?? '30';
    minimumPasswordScore = json['minimum_password_score'] ?? '2';
    twoFactorMethod = json['two_factor_method'] ?? 'OTP App';
    otpIssuerName = json['otp_issuer_name'] ?? 'Frappe';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['app_name'] = this.appName;
    data['time_zone'] = this.timeZone;
    data['date_format'] = this.dateFormat;
    data['time_format'] = this.timeFormat;
    data['number_format'] = this.numberFormat;
    data['float_precision'] = this.floatPrecision;
    data['currency_precision'] = this.currencyPrecision;
    data['session_expiry'] = this.sessionExpiry;
    data['session_expiry_mobile'] = this.sessionExpiryMobile;
    data['minimum_password_score'] = this.minimumPasswordScore;
    data['two_factor_method'] = this.twoFactorMethod;
    data['otp_issuer_name'] = this.otpIssuerName;
    return data;
  }
}
