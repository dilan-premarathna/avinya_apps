import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/auth.dart';
import 'package:mobile/data/campus_apps_portal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/config/app_config.dart';
import '../routing.dart';
import 'scaffold_body.dart';

class SMSScaffold extends StatelessWidget {
  static const pageNames = [
    '/attendance_marker',
    '/qr_attendance_marker',
    // '/bulk_attendance_marker/classes',
    '/daily_attendance_report',
    // '/weekly_payment_report',
    // '/person_attendance_report',
    '/duty_participants',
  ];

  static const studentPageNames = [
    '/attendance_marker',
    '/person_attendance_report',
  ];

  static const leaderParticipantPageNames = [
     '/attendance_marker',
     '/person_attendance_report',
     '/duty_attendance_marker',
  ];

  const SMSScaffold({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final routeState = RouteStateScope.of(context);
    final selectedIndex = _getSelectedIndex(routeState.route.pathTemplate);

    List<AdaptiveScaffoldDestination> destinations = [];
    if (campusAppsPortalInstance.isTeacher ||
        campusAppsPortalInstance.isSecurity ||
        campusAppsPortalInstance.isFoundation) {
      destinations = const [
        AdaptiveScaffoldDestination(
          title: 'Self Attendance',
          icon: Icons.person_outline,
        ),
        AdaptiveScaffoldDestination(
          title: 'QR Marker',
          icon: Icons.qr_code_scanner,
        ),
        // AdaptiveScaffoldDestination(
        //   title: 'Bulk Attendance Marker',
        //   icon: Icons.people,
        // ),
        AdaptiveScaffoldDestination(
          title: 'Daily Report',
          icon: Icons.summarize,
        ),
        // AdaptiveScaffoldDestination(
        //   title: 'Weekly Payment Report',
        //   icon: Icons.summarize,
        // ),
        AdaptiveScaffoldDestination(
          title: 'Assign duties',
          icon: Icons.work,
        ),
      ];
    }else if(campusAppsPortalInstance.isStudent 
      && campusAppsPortalInstance.getLeaderParticipant().role == 'leader'){
         
      destinations = const[
        AdaptiveScaffoldDestination(
          title: 'Attendance Marker',
          icon: Icons.person_outline,
        ),
        AdaptiveScaffoldDestination(
          title: 'Payment Report',
          icon: Icons.summarize,
        ),
        AdaptiveScaffoldDestination(
           title: 'Duty Attendance Marker',
           icon: Icons.people,
        ),
         
       ];  
      } 
    else {
      destinations = const [
        AdaptiveScaffoldDestination(
          title: 'Attendance Marker',
          icon: Icons.person_outline,
        ),
        AdaptiveScaffoldDestination(
          title: 'Payment Report',
          icon: Icons.summarize,
        ),
      ];
    }

    return Scaffold(
      body: AdaptiveNavigationScaffold(
        selectedIndex: selectedIndex,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 40,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                SMSAuthScope.of(context).signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User Signed Out')));
              },
            ),
            IconButton(
              icon: const Icon(Icons.info),
              tooltip: 'Help',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Help'),
                      ),
                      body: Align(
                        alignment: Alignment.center,
                        child: SelectableText.rich(TextSpan(
                          text:
                              "If you need help, write to us at admissions-help@avinyafoundation.org",
                          style: const TextStyle(color: Colors.blue),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launchUrl(Uri(
                                scheme: 'mailto',
                                path: 'admissions-help@avinyafoundation.org',
                                query:
                                    'subject=Avinya Academy Admissions - Bandaragama&body=Question on my application', //add subject and body here
                              ));
                            },
                        )),
                      ),
                    );
                  },
                ));
              },
            ),
          ],
        ),
        body: const SMSScaffoldBody(),
        onDestinationSelected: (idx) {
          if (campusAppsPortalInstance.isTeacher ||
              campusAppsPortalInstance.isSecurity ||
              campusAppsPortalInstance.isFoundation) {
            routeState.go(pageNames[idx]);
          }else if(campusAppsPortalInstance.isStudent 
            && campusAppsPortalInstance.getLeaderParticipant().role == 'leader'){

            routeState.go(leaderParticipantPageNames[idx]);

          }else {
            routeState.go(studentPageNames[idx]);
          }
        },
        destinations: destinations,
      ),
      persistentFooterButtons: [
        OutlinedButton(
            child: const Text('About'),
            onPressed: () {
              showAboutDialog(
                  context: context,
                  applicationName: AppConfig.applicationName,
                  applicationVersion: AppConfig.applicationVersion);
            }),
        // Text("© 2023, Avinya Foundation."),
      ],
    );
  }

  int _getSelectedIndex(String pathTemplate) {
    int index;

    if (campusAppsPortalInstance.isTeacher ||
        campusAppsPortalInstance.isSecurity ||
        campusAppsPortalInstance.isFoundation) {
      index = pageNames.indexOf(pathTemplate);
      
    }else if(campusAppsPortalInstance.isStudent 
            && campusAppsPortalInstance.getLeaderParticipant().role == 'leader'){
      
      index = leaderParticipantPageNames.indexOf(pathTemplate);
    }else {
      index = studentPageNames.indexOf(pathTemplate);
    }

    if (index >= 0) {
      return index;
    } else {
      return 0;
    }
  }
}
