import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:frappe_app/model/common.dart';

import '../../model/doctype_response.dart';
import '../../app/locator.dart';
import '../../config/palette.dart';
import '../../services/api/api.dart';

import 'base_input.dart';
import 'base_control.dart';

class MultiSelect extends StatefulWidget {
  final DoctypeField doctypeField;
  final OnControlChanged? onControlChanged;

  final Map? doc;
  final FutureOr<List<dynamic>> Function(String)? findSuggestions;
  final dynamic Function(List<dynamic>)? valueTransformer;
  final Function(List<dynamic>)? onChanged;
  final Key? key;
  final Widget? prefixIcon;
  final Color? color;
  final Color? chipColor;

  MultiSelect({
    required this.doctypeField,
    this.onControlChanged,
    this.doc,
    this.key,
    this.findSuggestions,
    this.valueTransformer,
    this.onChanged,
    this.prefixIcon,
    this.color,
    this.chipColor,
  });
  @override
  _MultiSelectState createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> with Control, ControlInput {
  @override
  Widget build(BuildContext context) {
    List<String? Function(dynamic)> validators = [];

    var f = setMandatory(widget.doctypeField);

    if (f != null) {
      validators.add(f);
    }

    var initialValue;
    if (widget.doc != null) {
      if (widget.doc![widget.doctypeField.fieldname] != null) {
        if (widget.doctypeField.fieldtype == "Table MultiSelect") {
          initialValue = widget.doc![widget.doctypeField.fieldname]
              .map((e) => e[widget.doctypeField.fieldname])
              .toList();
        } else {
          initialValue = widget.doc![widget.doctypeField.fieldname]
              .split(',')
              .where((e) => e != " ")
              .toList();
        }
      } else {
        initialValue = [];
      }
    } else {
      initialValue = [];
    }

    // Temporarily replaced FormBuilderChipsInput with FormBuilderTextField due to package issues
    return FormBuilderTextField(
      key: widget.key ?? Key(widget.doctypeField.fieldname),
      focusNode: FocusNode(),
      onChanged: (val) {
        if (widget.onControlChanged != null) {
          // Parse comma-separated values
          var listVal = val?.split(',').map((e) => e.trim()).toList() ?? [];
          FieldValue(field: widget.doctypeField, value: listVal);
        }
      },
      validator: FormBuilderValidators.compose(validators),
      decoration: InputDecoration(
        labelText: widget.doctypeField.label,
        fillColor: widget.color ?? Palette.bgColor,
        filled: true,
        hintText: 'Enter values separated by commas',
        prefixIcon: widget.prefixIcon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [widget.prefixIcon!],
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: const BorderRadius.all(const Radius.circular(6.0)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: const BorderRadius.all(const Radius.circular(6.0)),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      name: widget.doctypeField.fieldname,
      initialValue: initialValue?.join(', '),
    );
  }
}
