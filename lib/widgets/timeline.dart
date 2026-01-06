import 'package:flutter/material.dart';
import 'package:frappe_app/config/frappe_icons.dart';
import 'package:frappe_app/config/frappe_palette.dart';
import 'package:frappe_app/model/get_doc_response.dart';
import 'package:frappe_app/utils/enums.dart';
import 'package:frappe_app/utils/frappe_icon.dart';
import 'package:frappe_app/utils/helpers.dart';
import 'package:frappe_app/views/send_email/send_email_view.dart';
import 'package:frappe_app/widgets/doc_version.dart';
import 'package:frappe_app/widgets/email_box.dart';

import 'package:timeline_tile/timeline_tile.dart';

import 'comment_box.dart';

class Timeline extends StatelessWidget {
  final Docinfo docinfo;
  final String doctype;
  final String name;
  final String emailSubjectField;
  final String emailSenderField;
  final bool communicationOnly;
  final Function switchCallback;
  final Function refreshCallback;

  Timeline({
    required this.docinfo,
    required this.doctype,
    required this.name,
    required this.emailSenderField,
    required this.emailSubjectField,
    required this.communicationOnly,
    required this.switchCallback,
    required this.refreshCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        List<Widget> children = [
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Row(
              children: [
                Text(
                  'Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: FrappePalette.grey[900],
                  ),
                ),
                Spacer(),
                Switch.adaptive(
                  value: communicationOnly,
                  activeColor: Colors.blue,
                  onChanged: (val) {
                    switchCallback(val);
                  },
                ),
                Text(
                  "Communication Only",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: FrappePalette.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ];

        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: TextButton.icon(
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  builder: (context) => SendEmailView(
                    callback: () {
                      refreshCallback();
                    },
                    subjectField: emailSubjectField,
                    to: emailSenderField,
                    doctype: doctype,
                    name: name,
                  ),
                );
              },
              icon: FrappeIcon(FrappeIcons.email),
              label: const Text(
                'New Email',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: FrappePalette.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        );

        for (var event in _processData()) {
          if (event["_category"] == "communications") {
            event = Communication.fromJson(event);
          } else if (event["_category"] == "comments") {
            event = Comment.fromJson(event);
          }

          if (event is Communication) {
            children.add(
              EmailBox(
                data: event,
                onReplyTo: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    builder: (context) => SendEmailView(
                      callback: refreshCallback,
                      doctype: doctype,
                      subjectField: emailSubjectField,
                      name: name,
                      to: event.sender,
                      body: "<blockquote> ${event.content} </blockquote>",
                    ),
                  );
                },
                onReplyAll: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    builder: (context) => SendEmailView(
                      callback: refreshCallback,
                      doctype: doctype,
                      subjectField: emailSubjectField,
                      name: name,
                      to: event.sender,
                      cc: event.cc,
                      bcc: event.bcc,
                      body: "<blockquote> ${event.content} </blockquote>",
                    ),
                  );
                },
              ),
            );
          } else if (event is Comment) {
            children.add(
              CommentBox(event, () {
                refreshCallback();
              }),
            );
          } else {
            if (communicationOnly) {
              continue;
            }

            children.add(DocVersion(event));
          }
        }

        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: children.length,
            itemBuilder: (context, idx) {
              return TimelineTile(
                alignment: TimelineAlign.start,
                lineXY: 0.0,
                isFirst: idx == 0,
                isLast: idx == children.length - 1,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  height: 20,
                  indicator: CircleAvatar(
                    radius: 10,
                    backgroundColor: FrappePalette.grey[300],
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 8,
                      child: Icon(
                        Icons.lens,
                        size: 6,
                        color: FrappePalette.grey[600],
                      ),
                    ),
                  ),
                ),
                beforeLineStyle: LineStyle(
                  color: FrappePalette.grey[200]!,
                  thickness: 2,
                ),
                afterLineStyle: LineStyle(
                  color: FrappePalette.grey[200]!,
                  thickness: 2,
                ),
                endChild: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: children[idx],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List _processData() {
    var _events = [
      ...docinfo.comments.map((comment) {
        var c = comment.toJson();
        c["_category"] = "comments";
        return c;
      }).toList(),
      ...docinfo.communications.map((communication) {
        var c = communication.toJson();
        c["_category"] = "communications";
        return c;
      }).toList(),
      ...docinfo.versions.map((version) {
        var v = version.toJson();
        v["_category"] = "versions";
        return v;
      }).toList(),
      ...docinfo.views.map((view) {
        var v = view.toJson();
        v["_category"] = "views";
        return v;
      }).toList(),
    ];
    var events = sortBy(_events, "creation", Order.desc);
    return events;
  }
}
