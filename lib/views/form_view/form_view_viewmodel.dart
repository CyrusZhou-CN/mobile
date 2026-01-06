import 'dart:io';

import 'package:frappe_app/model/common.dart';
import 'package:frappe_app/model/get_doc_response.dart';
import 'package:frappe_app/utils/loading_indicator.dart';
import 'package:injectable/injectable.dart';

import '../../app/locator.dart';
import '../../model/doctype_response.dart';
import '../../views/base_viewmodel.dart';
import '../../services/api/api.dart';

import '../../model/offline_storage.dart';
import '../../model/config.dart';
import '../../utils/enums.dart';
import '../../utils/helpers.dart';
import '../../model/queue.dart';

class FormViewViewModel extends BaseViewModel {
  late String name;
  late DoctypeDoc meta;
  late bool isDirty;

  ErrorResponse? error;
  late GetDocResponse formData;
  final user = Config().user;
  Docinfo? docinfo;
  late bool communicationOnly;

  void refresh() {
    notifyListeners();
  }

  init({
    String? doctype,
    DoctypeDoc? constMeta,
    required String constName,
  }) async {
    setState(ViewState.busy);
    communicationOnly = true;
    name = constName;
    isDirty = false;
    if (constMeta == null) {
      if (doctype != null) {
        var metaResponse = await locator<Api>().getDoctype(doctype);
        meta = metaResponse.docs[0];
      }
    } else {
      meta = constMeta;
    }
    getData();
    print('FormView init - doctype: $doctype, name: $constName');
    if (meta.fields != null) {
      print('Total fields: ${meta.fields!.length}');
      var visibleFields = meta.fields!
          .where(
            (field) => field.hidden != 1 && field.fieldtype != "Column Break",
          )
          .toList();
      print('Visible fields: ${visibleFields.length}');
      var rolesField = meta.fields!.where(
        (field) => field.fieldname == 'roles',
      );
      if (rolesField.isNotEmpty) {
        print(
          'Roles field found: ${rolesField.first.fieldtype}, hidden: ${rolesField.first.hidden}, fieldname: ${rolesField.first.fieldname}',
        );
      } else {
        print('Roles field not found in meta.fields');
      }
      // Print all field names for debugging
      var fieldNames = meta.fields!
          .map((f) => '${f.fieldname}(${f.fieldtype}, hidden:${f.hidden})')
          .take(10)
          .toList(); // Limit to first 10
      print('First 10 fields: $fieldNames');
    }
  }

  handleFormDataChange() {
    if (!isDirty) {
      isDirty = true;
      notifyListeners();
    }
  }

  toggleSwitch(bool newVal) {
    communicationOnly = newVal;
    notifyListeners();
  }

  Future getData() async {
    setState(ViewState.busy);

    try {
      // var isOnline = await verifyOnline();
      var isOnline = true;
      var doctype = meta.name;

      if (!isOnline) {
        var response = OfflineStorage.getItem('$doctype$name');
        response = response["data"];
        if (response != null) {
          formData = GetDocResponse.fromJson(response);
          docinfo = formData.docinfo;
        } else {
          error = ErrorResponse(statusCode: HttpStatus.serviceUnavailable);
        }
      } else {
        formData = await locator<Api>().getdoc(doctype, name);
        docinfo = formData.docinfo;
        print(
          'Form data loaded for $doctype $name: ${formData.docs?.length ?? 0} docs',
        );
        if (formData.docs != null && formData.docs!.isNotEmpty) {
          print('First doc keys: ${formData.docs![0].keys.toList()}');
        }
      }
    } catch (e) {
      error = e as ErrorResponse;
    }

    setState(ViewState.idle);
  }

  getDocinfo() async {
    docinfo = await locator<Api>().getDocinfo(meta.name, name);
    notifyListeners();
  }

  Future handleUpdate({required Map formValue, required Map doc}) async {
    LoadingIndicator.loadingWithBackgroundDisabled("Saving");
    // var isOnline = await verifyOnline();
    var isOnline = true;
    if (!isOnline) {
      // if (queuedData != null) {
      //   queuedData["data"] = [
      //     {
      //       ...doc,
      //       ...formValue,
      //     }
      //   ];
      //   queuedData["updated_keys"] = {
      //     ...queuedData["updated_keys"],
      //     ...extractChangedValues(
      //       doc,
      //       formValue,
      //     )
      //   };
      //   queuedData["title"] = getTitle(
      //     meta.docs[0],
      //     formValue,
      //   );

      //   Queue.putAt(
      //     queuedData["qIdx"],
      //     queuedData,
      //   );
      // } else {
      //   Queue.add(
      //     {
      //       "type": "Update",
      //       "name": name,
      //       "doctype": meta.docs[0].name,
      //       "title": getTitle(meta.docs[0], formValue),
      //       "updated_keys": extractChangedValues(doc, formValue),
      //       "data": [
      //         {
      //           ...doc,
      //           ...formValue,
      //         }
      //       ],
      //     },
      //   );
      // }
      LoadingIndicator.stopLoading();
      throw ErrorResponse(statusCode: HttpStatus.serviceUnavailable);
    } else {
      formValue = {...doc, ...formValue};

      try {
        var response = await locator<Api>().saveDocs(meta.name, formValue);

        if (response.statusCode == HttpStatus.ok) {
          docinfo = Docinfo.fromJson(response.data["docinfo"]);
          formData = GetDocResponse(
            docs: response.data["docs"],
            docinfo: docinfo,
          );

          isDirty = false;

          LoadingIndicator.stopLoading();

          refresh();
        }
      } catch (e) {
        LoadingIndicator.stopLoading();
        throw e;
      }
    }
  }
}
