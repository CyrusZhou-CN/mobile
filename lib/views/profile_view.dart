import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frappe_app/app/locator.dart';
import 'package:frappe_app/config/frappe_icons.dart';
import 'package:frappe_app/config/frappe_palette.dart';
import 'package:frappe_app/model/config.dart';
import 'package:frappe_app/model/system_settings_response.dart';
import 'package:frappe_app/services/api/api.dart';
import 'package:frappe_app/utils/enums.dart';
import 'package:frappe_app/utils/frappe_icon.dart';
import 'package:frappe_app/utils/helpers.dart';
import 'package:frappe_app/utils/navigation_helper.dart';
import 'package:frappe_app/views/login/login_view.dart';
import 'package:frappe_app/views/queue.dart';
import 'package:frappe_app/widgets/frappe_bottom_sheet.dart';
import 'package:frappe_app/widgets/frappe_button.dart';
import 'package:frappe_app/widgets/padded_card_list_tile.dart';
import 'package:frappe_app/widgets/user_avatar.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frappe_app/model/offline_storage.dart';

import 'form_view/form_view.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  SystemSettingsResponse? _systemSettings;
  List _languages = [];
  String _currentLanguage = '';
  String? _userId;

  @override
  void initState() {
    try {
      super.initState();
      print('ProfileView initState called');
      print('Before Config().userId');
      _userId = Config().userId;
      print('After Config().userId');
      print('ProfileView _userId set to: $_userId');
      _loadSystemSettings();
      _loadLanguages();

      // Delay language loading to ensure _link_titles is available
      Future.delayed(Duration(milliseconds: 500), () {
        print('Delayed language loading triggered');
        setState(() {});
      });
    } catch (e) {
      print('Error in ProfileView initState: $e');
    }
  }

  void _loadSystemSettings() {
    try {
      var stored = OfflineStorage.getItem("systemSettings");
      if (stored != null && stored["data"] != null) {
        var data = jsonDecode(jsonEncode(stored["data"]));
        _systemSettings = SystemSettingsResponse.fromJson(data);
        print(
          'System settings loaded from storage: ${_systemSettings?.toJson()}',
        );
        print('Time zone: ${_systemSettings?.message.defaults.timeZone}');
        print('Date format: ${_systemSettings?.message.defaults.dateFormat}');
        setState(() {});
      } else {
        print('No system settings found in OfflineStorage');
      }
    } catch (e) {
      print('Error loading system settings: $e');
    }

    // Debug User document and allUsers
    try {
      var userDoc = OfflineStorage.getItem('User$_userId');
      print('User doc for $_userId: $userDoc');

      var allUsers = OfflineStorage.getItem('allUsers');
      print('allUsers data: $allUsers');
    } catch (e) {
      print('Error checking User data: $e');
    }
  }

  void _loadLanguages() async {
    try {
      var languages = await locator<Api>().getLanguages();
      print('Languages loaded: $languages');
      print('Languages type: ${languages.runtimeType}');
      if (languages.isNotEmpty) {
        print('First language item: ${languages[0]}');
        print('First language item type: ${languages[0].runtimeType}');
      }
      setState(() {
        _languages = languages;
      });
    } catch (e) {
      print('Error loading languages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileView build called');
    var currentLang = _getCurrentLanguage();
    print('Current language to display: $currentLang');
    return Scaffold(
      appBar: AppBar(elevation: 0.8, title: Text('Profile')),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            children: [
              SizedBox(height: 8),
              UserAvatar(
                uid: Config().userId!,
                size: 120,
                shape: ImageShape.roundedRectangle,
              ),
              SizedBox(height: 6),
              Text(
                Config().user,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FrappePalette.grey[900],
                ),
              ),
              // TODO: add view profile
              // SizedBox(
              //   height: 3,
              // ),
              // Text(
              //   'View Profile',
              //   style: TextStyle(
              //     color: FrappePalette.blue,
              //     fontSize: 13,
              //   ),
              // ),
              SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[400]!,
                        blurRadius: 3.0,
                        offset: Offset(0, 1),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // System Settings Display
                      if (_systemSettings != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: FrappePalette.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System Settings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: FrappePalette.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildSettingRow(
                                  'Language',
                                  _getCurrentLanguage(),
                                ),
                                _buildSettingRow(
                                  'Time Zone',
                                  _systemSettings!.message.defaults.timeZone,
                                ),
                                _buildSettingRow(
                                  'Date Format',
                                  _systemSettings!.message.defaults.dateFormat,
                                ),
                                _buildSettingRow(
                                  'Time Format',
                                  _systemSettings!.message.defaults.timeFormat,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Divider(),
                        ),
                      ],
                      ProfileListTile(
                        title: "My Settings",
                        onTap: () {
                          PersistentNavBarNavigator.pushNewScreen(
                            context,
                            screen: FormView(
                              name: Config().userId!,
                              doctype: "User",
                            ),
                            withNavBar: true,
                          );
                        },
                        icon: FrappeIcon(FrappeIcons.my_settings),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Divider(),
                      ),
                      ProfileListTile(
                        title: "Documentation",
                        onTap: () async {
                          var url = "https://docs.erpnext.com/homepage";
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                        icon: FrappeIcon(FrappeIcons.file),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Divider(),
                      ),
                      ProfileListTile(
                        title: "User Forum",
                        onTap: () async {
                          var url = "https://discuss.erpnext.com/";
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                        icon: FrappeIcon(FrappeIcons.message_1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Divider(),
                      ),
                      ProfileListTile(
                        icon: FrappeIcon(FrappeIcons.bug),
                        onTap: () async {
                          var issueUrl =
                              "https://github.com/frappe/mobile/issues";
                          if (await canLaunch(issueUrl)) {
                            await launch(issueUrl);
                          } else {
                            throw 'Could not launch $issueUrl';
                          }
                        },
                        title: "Report an Issue",
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Divider(),
                      ),
                      ProfileListTile(
                        title: "About",
                        onTap: () async {
                          var apps = await locator<Api>().getVersions();
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            builder: (context) {
                              var socialMediaLinks = [
                                {
                                  "title": "Website",
                                  "url": "https://frappeframework.com",
                                },
                                {
                                  "title": "Source",
                                  "url": "https://github.com/frappe",
                                },
                                {
                                  "title": "Linkedin",
                                  "url":
                                      "https://linkedin.com/company/frappe-tech",
                                },
                                {
                                  "title": "Facebook",
                                  "url": "https://facebook.com/erpnext",
                                },
                                {
                                  "title": "Twitter",
                                  "url": "https://twitter.com/erpnext",
                                },
                              ];
                              return FractionallySizedBox(
                                heightFactor: 0.8,
                                child: Container(
                                  child: FrappeBottomSheet(
                                    title: "Frappe Framework",
                                    trailing: Text("Close"),
                                    onActionButtonPress: () {
                                      Navigator.of(context).pop();
                                    },
                                    showLeading: false,
                                    body: ConstrainedFlexView(
                                      MediaQuery.of(context).size.height - 200,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              'Open Source Applications for the Web',
                                            ),
                                          ),
                                          ...socialMediaLinks.map((
                                            socialMediaLink,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "${socialMediaLink["title"]!}: ",
                                                  ),
                                                  GestureDetector(
                                                    child: Text(
                                                      socialMediaLink["url"]!,
                                                      style: TextStyle(
                                                        color:
                                                            FrappePalette.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          Divider(thickness: 1),
                                          Text(
                                            "Installed Apps",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(height: 8),
                                          ...apps.message.frappeApps.values.map((
                                            app,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: "${app.title!}: ",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          "${app.version!} (${app.branch!})",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          Spacer(),
                                          Divider(thickness: 1),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Text(
                                              "© Frappe Technologies Pvt. Ltd and contributors",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        icon: FrappeIcon(FrappeIcons.info_outlined),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Divider(),
                      ),
                      ProfileListTile(
                        title: "View Website",
                        onTap: () async {
                          var url = Config().baseUrl!;
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                        icon: FrappeIcon(FrappeIcons.external_link),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FrappeRaisedButton(
                  height: 48,
                  fullWidth: true,
                  onPressed: () async {
                    await clearLoginInfo();
                    NavigationHelper.clearAllAndNavigateTo(
                      context: context,
                      page: Login(),
                    );
                  },
                  icon: FrappeIcons.logout,
                  titleWidget: Text(
                    "Logout",
                    style: TextStyle(color: FrappePalette.red[600]),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentLanguage() {
    print('ProfileView _getCurrentLanguage called');
    print('Config().userId: ${Config().userId}');
    print('Config().primaryCacheKey: ${Config().primaryCacheKey}');
    print('_userId: $_userId');
    // Try to get language from User document first
    try {
      var userDoc = OfflineStorage.getItem('User$_userId');
      print('ProfileView userDoc: $userDoc');
      if (userDoc != null &&
          userDoc['data'] != null &&
          userDoc['data']['docs'] != null) {
        var docs = userDoc['data']['docs'];
        if (docs is List && docs.isNotEmpty) {
          var language = docs[0]['language'];
          print('Language from User doc: $language');
          if (language != null && language.isNotEmpty) {
            for (var lang in _languages) {
              if (lang['code'] == language) {
                print('Matched language name: ${lang['name']}');
                return lang['name'];
              }
            }
            // If no match, return the raw language code
            print('No match found, returning raw language code: $language');
            return language;
          }
        }
      }
    } catch (e) {
      print('Error getting language from User doc: $e');
    }
    return '';
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: FrappePalette.grey[700]),
          ),
          Text(
            value.isNotEmpty ? value : 'Not set',
            style: TextStyle(
              fontSize: 13,
              color: FrappePalette.grey[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileListTile extends StatelessWidget {
  final void Function() onTap;
  final String title;
  final Widget icon;

  const ProfileListTile({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 10,
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      leading: icon,
      trailing: FrappeIcon(
        FrappeIcons.arrow_right,
        size: 18,
        color: FrappePalette.grey[700],
      ),
      onTap: onTap,
      title: Text(title),
    );
  }
}

class ConstrainedFlexView extends StatelessWidget {
  final Widget child;
  final double minSize;
  final Axis axis;

  const ConstrainedFlexView(
    this.minSize, {
    required this.child,
    this.axis = Axis.vertical,
  });

  bool get isHz => axis == Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        double viewSize = isHz ? constraints.maxWidth : constraints.maxHeight;
        if (viewSize > minSize) return child;
        return SingleChildScrollView(
          scrollDirection: axis,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isHz ? double.infinity : minSize,
              maxWidth: isHz ? minSize : double.infinity,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
