import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:frappe_app/config/frappe_icons.dart';
import 'package:frappe_app/config/palette.dart';
import 'package:frappe_app/model/common.dart';
import 'package:frappe_app/utils/frappe_icon.dart';
import 'package:frappe_app/widgets/form_builder_typeahead.dart'
    show
        ItemBuilder,
        SuggestionsCallback,
        SelectionToTextTransformer,
        FormBuilderTypeAhead;

import '../../model/doctype_response.dart';

import 'base_control.dart';
import 'base_input.dart';

typedef String SelectionToTextTransformer<T>(T selection);

class AutoComplete extends StatefulWidget {
  final DoctypeField doctypeField;
  final OnControlChanged? onControlChanged;

  final Map? doc;
  final void Function(dynamic)? onSuggestionSelected;
  final Widget? suffixIcon;
  final Key? key;
  final ItemBuilder<dynamic>? itemBuilder;
  final SuggestionsCallback<dynamic>? suggestionsCallback;
  final SelectionToTextTransformer? selectionToTextTransformer;
  final InputDecoration? inputDecoration;
  final TextEditingController? controller;

  AutoComplete({
    required this.doctypeField,
    this.onControlChanged,
    this.doc,
    this.controller,
    this.inputDecoration,
    this.suffixIcon,
    this.key,
    this.onSuggestionSelected,
    this.itemBuilder,
    this.suggestionsCallback,
    this.selectionToTextTransformer,
  });

  @override
  _AutoCompleteState createState() => _AutoCompleteState();
}

class _AutoCompleteState extends State<AutoComplete>
    with Control, ControlInput {
  TextEditingController? _typeAheadController;

  @override
  void initState() {
    _typeAheadController = widget.controller ?? TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String? Function(dynamic)> validators = [];

    var f = setMandatory(widget.doctypeField);

    if (f != null) {
      validators.add(f);
    }

    return Theme(
      data: Theme.of(context).copyWith(primaryColor: Colors.black),
      child: FormBuilderTypeAhead<dynamic>(
        key: widget.key ?? Key(widget.doctypeField.fieldname),
        controller: _typeAheadController ?? TextEditingController(),
        focusNode: FocusNode(),
        onSuggestionSelected: widget.onSuggestionSelected,
        onChanged: (val) {
          if (widget.onControlChanged != null) {
            widget.onControlChanged!(
              FieldValue(field: widget.doctypeField, value: val),
            );
          }
        },
        onSaved: (val) {},
        onReset: () {},
        valueTransformer: (val) => val,
        loadingBuilder: (context) => const CircularProgressIndicator(),
        noItemsFoundBuilder: (context) => const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('No items found'),
        ),
        direction: AxisDirection.up,
        validator: FormBuilderValidators.compose(validators),
        decoration:
            widget.inputDecoration ??
            Palette.formFieldDecoration(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [widget.suffixIcon ?? FrappeIcon(FrappeIcons.select)],
              ),
            ),
        selectionToTextTransformer:
            widget.selectionToTextTransformer ??
            (item) {
              return item.toString();
            },
        name: widget.doctypeField.fieldname,
        itemBuilder:
            widget.itemBuilder ??
            (context, item) {
              return ListTile(title: Text(item.toString()));
            },
        initialValue: widget.doc != null
            ? widget.doc![widget.doctypeField.fieldname]
            : null,
        suggestionsCallback:
            widget.suggestionsCallback ??
            (query) {
              var lowercaseQuery = query.toLowerCase();
              List opts;
              if (widget.doctypeField.options is String) {
                opts = widget.doctypeField.options.split('\n');
              } else {
                opts = widget.doctypeField.options ?? [];
              }
              return Future.value(
                opts
                    .where(
                      (option) => option.toLowerCase().contains(lowercaseQuery),
                    )
                    .toList(),
              );
            },
      ),
    );
  }
}
