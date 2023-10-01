class Urls {
  const Urls._();

  static const loginXiaomi =
      'https://account.xiaomi.com/oauth2/authorize?skip_confirm=false&client_id=2882303761517383915&pt=0&scope=1+6000+16001+20000&redirect_uri=https%3A%2F%2Fhm.xiaomi.com%2Fwatch.do&_locale=en_US&response_type=code';
  static const loginAmazfit = 'https://account.huami.com/v2/client/login';
  static const linkedDevices =
      'https://api-mifit-us2.huami.com/users/{user_id}/devices';
}

class Payloads {
  const Payloads._();

  static final loginAmazfit = {
    'dn': 'account.huami.com,api-user.huami.com,app-analytics.huami.com,'
        'api-watch.huami.com,'
        'api-analytics.huami.com,api-mifit.huami.com',
    'app_version': '5.9.2-play_100355',
    'source': 'com.huami.watch.hmwatchmanager',
    'country_code': '',
    'device_id': '',
    'third_name': '',
    'lang': 'en',
    'device_model': 'android_phone',
    'allow_registration': 'false',
    'app_name': 'com.huami.midong',
    'code': '',
    'grant_type': '',
  };

  static final linkedDevices = {
    'apptoken': '',
  };
}
