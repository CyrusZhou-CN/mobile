import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frappe_app/model/common.dart';
import 'package:frappe_app/model/get_doc_response.dart';
import 'package:frappe_app/model/get_versions_response.dart' as get_versions;
import 'package:frappe_app/model/group_by_count_response.dart' as group_by;
import 'package:frappe_app/model/login_request.dart';
import 'package:frappe_app/model/system_settings_response.dart';
import 'package:frappe_app/model/upload_file_response.dart';

import '../../model/doctype_response.dart';
import '../../model/desktop_page_response.dart';
import '../../model/desk_sidebar_items_response.dart';
import '../../model/login_response.dart';

import '../../services/api/api.dart';

import '../../utils/helpers.dart';
import '../../utils/dio_helper.dart';
import '../../model/offline_storage.dart';

class DioApi implements Api {
  Dio get _dio {
    if (DioHelper.dio == null) {
      throw Exception('Dio not initialized. Please set base URL first.');
    }
    return DioHelper.dio!;
  }

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      print('Dio login: Making POST request to /method/login');
      final response = await _dio.post(
        '/method/login',
        data: loginRequest.toJson(),
        options: Options(validateStatus: (status) => (status ?? 0) < 500),
      );

      print('Dio login: Response status: ${response.statusCode}');
      print('Dio login: Response data: ${response.data}');

      if (response.statusCode == HttpStatus.ok) {
        final setCookies = response.headers.map["set-cookie"];
        if (setCookies != null && setCookies.length > 3) {
          response.data["user_id"] = setCookies[3].split(';')[0].split('=')[1];
        }

        return LoginResponse.fromJson(response.data);
      } else {
        print(
          'Dio login: Non-200 response - Status: ${response.statusCode}, Data: ${response.data}',
        );
        String errorMessage = "Login failed";
        if (response.data is Map && response.data["message"] != null) {
          errorMessage = response.data["message"];
        } else if (response.data is String) {
          errorMessage = response.data;
        }
        throw ErrorResponse(
          statusMessage: errorMessage,
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      print('Dio login: Exception occurred: $e');
      if (!(e is DioException)) rethrow;

      final error = e.error;
      if (error is SocketException) {
        throw ErrorResponse(
          statusCode: HttpStatus.serviceUnavailable,
          statusMessage: error.message,
        );
      }

      if (error is HandshakeException) {
        throw ErrorResponse(
          statusCode: HttpStatus.serviceUnavailable,
          statusMessage:
              "Cannot connect securely to server."
              " Please ensure that the server has a valid SSL configuration.",
        );
      }

      throw ErrorResponse(statusMessage: error?.toString() ?? "Unknown error");
    }
  }

  Future<DeskSidebarItemsResponse> getDeskSideBarItems() async {
    try {
      var response = await _dio.post(
        '/method/frappe.desk.desktop.get_desk_sidebar_items',
        options: Options(
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );

      if (response.statusCode == 417) {
        response = await _dio.post(
          '/method/frappe.desk.desktop.get_wspace_sidebar_items',
          options: Options(
            validateStatus: (status) {
              return (status ?? 0) < 500;
            },
          ),
        );
        // Handle different response structures for new Frappe versions
        if (response.data != null && response.data["message"] != null) {
          if (response.data["message"]["pages"] != null) {
            response.data["message"] = response.data["message"]["pages"];
          } else {
            // For newer Frappe versions, the structure might be different
            response.data["message"] = response.data["message"];
          }
        }
      }

      if (response.statusCode == HttpStatus.ok) {
        if (await OfflineStorage.storeApiResponse()) {
          await OfflineStorage.putItem('deskSidebarItems', response.data);
        }

        try {
          return DeskSidebarItemsResponse.fromJson(response.data);
        } catch (e) {
          // Handle different response structures for various Frappe versions
          if (response.data != null && response.data["message"] != null) {
            var messageData = response.data["message"];
            List<dynamic> items = [];

            // Try different possible structures
            if (messageData is Map) {
              if (messageData["Modules"] != null) {
                items.addAll(messageData["Modules"] ?? []);
              }
              if (messageData["Domains"] != null) {
                items.addAll(messageData["Domains"] ?? []);
              }
              if (messageData["Administration"] != null) {
                items.addAll(messageData["Administration"] ?? []);
              }
              if (messageData["pages"] != null) {
                items.addAll(messageData["pages"] ?? []);
              }
            } else if (messageData is List) {
              items = messageData;
            }

            response.data["message"] = items;
          }
          return DeskSidebarItemsResponse.fromJson(response.data);
        }
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
        // response;
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw e;
      }
    }
  }

  Future<DesktopPageResponse> getDesktopPage(String module) async {
    try {
      final response = await _dio.post(
        '/method/frappe.desk.desktop.get_desktop_page',
        data: {'page': module},
        options: Options(
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        if (await OfflineStorage.storeApiResponse()) {
          await OfflineStorage.putItem('${module}Doctypes', response.data);
        }

        return DesktopPageResponse.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw e;
      }
    }
  }

  Future<DoctypeResponse> getDoctype(String doctype) async {
    var queryParams = {'doctype': doctype};

    try {
      final response = await _dio.get(
        '/method/frappe.desk.form.load.getdoctype',
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );

      if (response.statusCode == HttpStatus.ok) {
        List metaFields = response.data["docs"][0]["fields"];
        response.data["docs"][0]["field_map"] = {};

        metaFields.forEach((field) {
          response.data["docs"][0]["field_map"]["${field["fieldname"]}"] = true;
        });
        if (await OfflineStorage.storeApiResponse()) {
          await OfflineStorage.putItem('${doctype}Meta', response.data);
        }
        return DoctypeResponse.fromJson(response.data);
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse(
          statusMessage: response.statusMessage ?? "Unknown error",
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<List> fetchList({
    required List fieldnames,
    required String doctype,
    required DoctypeDoc meta,
    required String orderBy,
    List? filters,
    int? pageLength,
    int? offset,
  }) async {
    var queryParams = {
      'doctype': doctype,
      'fields': jsonEncode(fieldnames),
      'page_length': pageLength?.toString() ?? '20',
      'with_comment_count': true,
      'order_by': orderBy,
    };

    queryParams['limit_start'] = offset?.toString() ?? '0';

    if (filters != null && filters.isNotEmpty) {
      queryParams['filters'] = jsonEncode(filters);
    }

    try {
      final response = await _dio.get(
        '/method/frappe.desk.reportview.get',
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );
      if (response.statusCode == HttpStatus.ok) {
        var l = response.data["message"];
        var newL = [];

        if (l.length == 0) {
          return newL;
        }

        for (int i = 0; i < l["values"].length; i++) {
          var o = {};
          for (int j = 0; j < l["keys"].length; j++) {
            var key = l["keys"][j];
            var value = l["values"][i][j];

            if (key == "docstatus") {
              key = "status";
              if (isSubmittable(meta)) {
                if (value == 0) {
                  value = "Draft";
                } else if (value == 1) {
                  value = "Submitted";
                } else if (value == 2) {
                  value = "Cancelled";
                }
              } else {
                value = value == 0 ? "Enabled" : "Disabled";
              }
            }
            o[key] = value;
          }
          newL.add(o);
        }

        if (await OfflineStorage.storeApiResponse()) {
          await OfflineStorage.putItem('${doctype}List', newL);
        }

        return newL;
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<GetDocResponse> getdoc(String doctype, String name) async {
    var queryParams = {'doctype': doctype, 'name': name};

    try {
      final response = await _dio.get(
        '/method/frappe.desk.form.load.getdoc',
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        if (await OfflineStorage.storeApiResponse()) {
          await OfflineStorage.putItem('$doctype$name', response.data);
        }
        return GetDocResponse.fromJson(response.data);
      } else if (response.statusCode == 403) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw e;
      }
    }
  }

  Future postComment(
    String refDocType,
    String refName,
    String content,
    String email,
  ) async {
    var queryParams = {
      'reference_doctype': refDocType,
      'reference_name': refName,
      'content': content,
      'comment_email': email,
      'comment_by': email,
    };

    final response = await _dio.post(
      '/method/frappe.desk.form.utils.add_comment',
      data: queryParams,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.statusCode == 200) {
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future sendEmail({
    required recipients,
    cc,
    bcc,
    required subject,
    required content,
    required doctype,
    required doctypeName,
    sendEmail,
    printHtml,
    sendMeACopy,
    printFormat,
    emailTemplate,
    attachments,
    readReceipt,
    printLetterhead,
  }) async {
    var queryParams = {
      'recipients': recipients,
      'subject': subject,
      'content': content,
      'doctype': doctype,
      'name': doctypeName,
      'send_email': 1,
      'attachments': json.encode(attachments),
      'read_receipt': readReceipt,
      'send_me_a_copy': sendMeACopy,
    };

    final response = await _dio.post(
      '/method/frappe.core.doctype.communication.email.make',
      data: queryParams,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.statusCode == 200) {
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future addAssignees(String doctype, String name, List assignees) async {
    var data = {
      'assign_to': json.encode(assignees),
      'assign_to_me': 0,
      'doctype': doctype,
      'name': name,
      'bulk_assign': false,
      're_assign': false,
    };

    try {
      var response = await _dio.post(
        '/method/frappe.desk.form.assign_to.add',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Something went wrong');
      }
    } catch (e) {
      if (e is DioException) {
        var error;
        if (e.response != null) {
          error = e.response;
        } else {
          error = e.error;
        }

        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusCode: error.statusCode,
            statusMessage: error.statusMessage,
          );
        }
      } else {
        throw e;
      }
    }
  }

  Future removeAssignee(String doctype, String name, String assignTo) async {
    var data = {'doctype': doctype, 'name': name, 'assign_to': assignTo};

    var response = await _dio.post(
      '/method/frappe.desk.form.assign_to.remove',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future getDocinfo(String doctype, String name) async {
    var data = {"doctype": doctype, "name": name};

    var response = await _dio.post(
      '/method/frappe.desk.form.load.get_docinfo',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return Docinfo.fromJson(response.data["docinfo"]);
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future removeAttachment(
    String doctype,
    String name,
    String attachmentName,
  ) async {
    var data = {"fid": attachmentName, "dt": doctype, "dn": name};

    var response = await _dio.post(
      '/method/frappe.desk.form.utils.remove_attach',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future deleteComment(String name) async {
    var queryParams = {'doctype': 'Comment', 'name': name};

    final response = await _dio.post(
      '/method/frappe.client.delete',
      data: queryParams,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future<List<UploadedFile>> uploadFiles({
    required String doctype,
    required String name,
    required List<FrappeFile> files,
  }) async {
    List<UploadedFile> uploadedFiles = [];

    for (FrappeFile frappeFile in files) {
      final filePath = frappeFile.file.path;
      if (filePath == null) continue;

      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
        "docname": name,
        "doctype": doctype,
        "is_private": frappeFile.isPrivate ? 1 : 0,
        "folder": "Home/Attachments",
      });

      var response = await _dio.post("/method/upload_file", data: formData);
      if (response.statusCode == 200) {
        var uploadedFilesResponse = UploadedFileResponse.fromJson(
          response.data,
        );
        uploadedFiles.add(uploadedFilesResponse.uploadedFile);
      } else {
        throw Exception('Something went wrong');
      }
    }

    return uploadedFiles;
  }

  Future saveDocs(String doctype, Map formValue) async {
    var data = {"doctype": doctype, ...formValue};

    try {
      final response = await _dio.post(
        '/method/frappe.desk.form.save.savedocs',
        data: "doc=${Uri.encodeComponent(json.encode(data))}&action=Save",
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.statusCode == 200) {
        return response;
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null &&
            e.response!.data != null &&
            e.response!.data["_server_messages"] != null) {
          var errorMsg = getServerMessage(e.response!.data["_server_messages"]);

          throw ErrorResponse(
            statusCode: e.response!.statusCode ?? 0,
            statusMessage: errorMsg,
          );
        } else {
          if (e.error is SocketException) {
            throw ErrorResponse(
              statusCode: HttpStatus.serviceUnavailable,
              statusMessage: (e.error as SocketException).message,
            );
          } else {
            throw ErrorResponse(
              statusCode: 0,
              statusMessage: e.error?.toString() ?? (e.message ?? ''),
            );
          }
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<Map> searchLink({
    String doctype = '',
    String refDoctype = '',
    String txt = '',
    int pageLength = 20,
  }) async {
    var queryParams = {
      'txt': txt,
      'doctype': doctype,
      'reference_doctype': refDoctype,
      'ignore_user_permissions': 0,
    };

    if (pageLength != null) {
      queryParams['page_length'] = pageLength;
    }

    try {
      final response = await _dio.post(
        '/method/frappe.desk.search.search_link',
        data: queryParams,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );
      if (response.statusCode == 200) {
        if (await OfflineStorage.storeApiResponse()) {
          if (pageLength != null && pageLength == 9999) {
            await OfflineStorage.putItem('${doctype}LinkFull', response.data);
          } else {
            await OfflineStorage.putItem('$txt${doctype}Link', response.data);
          }
        }
        return response.data;
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw e;
      }
    }
  }

  Future toggleLike(String doctype, String name, bool isFav) async {
    var data = {'doctype': doctype, 'name': name, 'add': isFav ? 'Yes' : 'No'};

    final response = await _dio.post(
      '/method/frappe.desk.like.toggle_like',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future getTags(String doctype, String txt) async {
    var data = {'doctype': doctype, 'txt': txt};

    final response = await _dio.post(
      '/method/frappe.desk.doctype.tag.tag.get_tags',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future removeTag(String doctype, String name, String tag) async {
    var data = {'dt': doctype, 'dn': name, 'tag': tag};

    final response = await _dio.post(
      '/method/frappe.desk.doctype.tag.tag.remove_tag',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future addTag(String doctype, String name, String tag) async {
    var data = {'dt': doctype, 'dn': name, 'tag': tag};

    final response = await _dio.post(
      '/method/frappe.desk.doctype.tag.tag.add_tag',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future addReview(String doctype, String name, Map reviewData) async {
    var doc = {"doctype": doctype, "name": name};

    var data =
        '''doc=${Uri.encodeComponent(json.encode(doc))}
              &to_user=${Uri.encodeComponent(reviewData["to_user"])}
              &points=${int.parse(reviewData["points"])}
              &review_type=${reviewData["review_type"]}
              &reason=${reviewData["reason"]}'''
            .replaceAll(new RegExp(r"\s+"), "");
    // trim all whitespace

    try {
      final response = await _dio.post(
        '/method/frappe.social.doctype.energy_point_log.energy_point_log.review',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        if (response.data["_server_messages"] != null) {
          var errorMsg = getServerMessage(response.data["_server_messages"]);

          throw ErrorResponse(statusMessage: errorMsg);
        }
        return response.data;
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future setPermission({
    required String doctype,
    required String name,
    required String user,
    required Map shareInfo,
  }) async {
    var data = {'doctype': doctype, 'name': name, 'user': user, ...shareInfo};

    final response = await _dio.post(
      '/method/frappe.share.set_permission',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future shareAdd(String doctype, String name, Map shareInfo) async {
    var data = {'doctype': doctype, 'name': name, ...shareInfo};

    final response = await _dio.post(
      '/method/frappe.share.add',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future<Map> getContactList(String query) async {
    var data = {"txt": query};

    final response = await _dio.post(
      '/method/frappe.email.get_contact_list',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future shareGetUsers({required String doctype, required String name}) async {
    var data = {"doctype": doctype, "name": name};

    final response = await _dio.post(
      '/method/frappe.share.get_users',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Future<group_by.GroupByCountResponse> getGroupByCount({
    required String doctype,
    required List currentFilters,
    required String field,
  }) async {
    var reqData = {
      "doctype": doctype,
      "current_filters": currentFilters,
      "field": field,
    };

    try {
      final response = await _dio.post(
        '/method/frappe.desk.listview.get_group_by_count',
        data: reqData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return group_by.GroupByCountResponse.fromJson(response.data);
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<int> getReportViewCount({
    required String doctype,
    required Map filters,
    required List<DoctypeField> fields,
  }) async {
    var reqData = {
      "doctype": doctype,
      "filters": filters,
      "fields": fields,
      "distinct": false,
    };

    try {
      final response = await _dio.post(
        '/method/frappe.desk.reportview.get_count',
        data: reqData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data["message"];
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<SystemSettingsResponse> getSystemSettings() async {
    try {
      final response = await _dio.post(
        '/method/frappe.core.doctype.system_settings.system_settings.load',
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        try {
          return SystemSettingsResponse.fromJson(response.data);
        } catch (e) {
          print('Warning: Failed to parse system settings response: $e');
          // Return a default/empty response to avoid breaking login
          return SystemSettingsResponse(
            message: Message(
              timezones: [],
              defaults: Defaults(
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
              ),
            ),
          );
        }
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<List> getLanguages() async {
    try {
      print('getLanguages: Calling search_link API for Language doctype');
      var queryParams = {
        'txt': '',
        'doctype': 'Language',
        'reference_doctype': 'User',
        'ignore_user_permissions': 0,
        'page_length': 9999,
      };
      final response = await _dio.post(
        '/method/frappe.desk.search.search_link',
        data: queryParams,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) {
            return (status ?? 0) < 500;
          },
        ),
      );
      print('getLanguages: API response: $response');
      if (response.statusCode == 200) {
        var data = response.data;
        print('getLanguages: response data: $data');
        if (data != null && data['message'] != null) {
          var results = data['message'] as List;
          print('getLanguages: results: $results');
          var result = results
              .map(
                (item) => {
                  'code': item['value'],
                  'name': item['label'] ?? item['value'],
                },
              )
              .toList();
          print('getLanguages: Mapped result: $result');
          return result;
        } else {
          print('getLanguages: No results in response');
          return [];
        }
      } else {
        print(
          'getLanguages: API call failed with status ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  Future<get_versions.GetVersionsResponse> getVersions() async {
    try {
      final response = await _dio.post(
        '/method/frappe.utils.change_log.get_versions',
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return get_versions.GetVersionsResponse.fromJson(response.data);
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }

  Future<List> getList({
    required List fields,
    required int limit,
    required String orderBy,
    required String doctype,
  }) async {
    try {
      final response = await _dio.get(
        '/method/frappe.desk.reportview.get_list',
        options: Options(contentType: Headers.formUrlEncodedContentType),
        queryParameters: {
          "fields": jsonEncode(fields),
          "limit": limit,
          "order_by": orderBy,
          "doctype": doctype,
        },
      );

      if (response.statusCode == 200) {
        return response.data["message"];
      } else if (response.statusCode == HttpStatus.forbidden) {
        throw ErrorResponse(
          statusCode: response.statusCode ?? 0,
          statusMessage: response.statusMessage ?? "Error",
        );
      } else {
        throw ErrorResponse();
      }
    } catch (e) {
      if (e is DioException) {
        var error = e.error;
        if (error is SocketException) {
          throw ErrorResponse(
            statusCode: HttpStatus.serviceUnavailable,
            statusMessage: error.message,
          );
        } else {
          throw ErrorResponse(
            statusMessage: error?.toString() ?? "Unknown error",
          );
        }
      } else {
        throw ErrorResponse();
      }
    }
  }
}
