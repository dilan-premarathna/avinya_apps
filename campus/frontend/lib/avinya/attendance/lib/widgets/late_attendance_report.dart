import 'package:flutter/material.dart';
// import 'package:attendance/widgets/week_picker.dart';
import 'package:attendance/widgets/date_range_picker.dart';
import 'package:attendance/widgets/excel_export.dart';
import 'package:gallery/data/campus_apps_portal.dart';
import 'package:attendance/data/activity_attendance.dart';
import 'package:gallery/data/person.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LateAttendanceReport extends StatefulWidget {
  const LateAttendanceReport({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LateAttendanceReport> createState() => _LateAttendanceReportState();
}

class _LateAttendanceReportState extends State<LateAttendanceReport> {
  List<ActivityAttendance> _fetchedAttendance = [];
  List<Person> _fetchedStudentList = [];
  Organization? _fetchedOrganization;
  bool _isFetching = true;

  //calendar specific variables
  DateTime? _selectedDay;

  late DataTableSource _data;
  List<String?> columnNames = [];
  List<Map<String, bool>> attendanceList = [];
  var _selectedValue;
  var activityId = 0;

  late String formattedStartDate;
  late String formattedEndDate;
  var today = DateTime.now();

  void selectWeek(DateTime today, activityId) async {
    // Update the variables to select the week
    final formatter = DateFormat('MMM d, yyyy');
    formattedStartDate = formatter.format(today);
    formattedEndDate = formatter.format(today);
    setState(() {
      _isFetching = false;
    });
  }

  @override
  void initState() {
    super.initState();
    var today = DateTime.now();
    activityId = campusAppsPortalInstance.activityIds['homeroom']!;
    selectWeek(today, activityId);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _data = MyData(_fetchedAttendance, columnNames, _fetchedOrganization,
        _selectedValue, updateSelected);
    DateRangePicker(updateDateRange, formattedStartDate);
  }

  void updateSelected(int index, bool value, List<bool> selected) {
    setState(() {
      selected[index] = value;
    });
  }

  void updateDateRange(_rangeStart, _rangeEnd) async {
    int? parentOrgId =
        campusAppsPortalInstance.getUserPerson().organization!.id;
    if (parentOrgId != null) {
      setState(() {
        _isFetching = true; // Set _isFetching to true before starting the fetch
      });
      try {
        setState(() {
          final startDate = _rangeStart ?? _selectedDay;
          final endDate = _rangeEnd ?? _selectedDay;
          final formatter = DateFormat('MMM d, yyyy');
          final formattedStartDate = formatter.format(startDate!);
          final formattedEndDate = formatter.format(endDate!);
          this.formattedStartDate = formattedStartDate;
          this.formattedEndDate = formattedEndDate;
          this._fetchedStudentList = _fetchedStudentList;
          refreshState(this._selectedValue);
        });
      } catch (error) {
        // Handle any errors that occur during the fetch
        setState(() {
          _isFetching = false; // Set _isFetching to false in case of error
        });
        // Perform error handling, e.g., show an error message
      }
    }
  }

  void refreshState(Organization? newValue) async {
    setState(() {
      _isFetching = true; // Set _isFetching to true before starting the fetch
    });
    int? parentOrgId =
        campusAppsPortalInstance.getUserPerson().organization!.id;
    var cols =
        columnNames.map((label) => DataColumn(label: Text(label!))).toList();
    _selectedValue = newValue ?? null;
    // print(newValue.id);

    if (_selectedValue == null) {
      _fetchedStudentList = await fetchOrganizationForAll(parentOrgId!);
      if (_fetchedOrganization != null) {
        _fetchedOrganization!.people = _fetchedStudentList;
        _fetchedOrganization!.id = parentOrgId;
        _fetchedOrganization!.description = "Select All";
      } else {
        _fetchedOrganization = Organization();
        _fetchedOrganization!.people = _fetchedStudentList;
        _fetchedOrganization!.id = parentOrgId;
        _fetchedOrganization!.description = "Select All";
      }
      _fetchedAttendance = await getLateAttendanceReportByParentOrg(
          parentOrgId,
          activityId,
          DateFormat('yyyy-MM-dd')
              .format(DateFormat('MMM d, yyyy').parse(this.formattedStartDate)),
          DateFormat('yyyy-MM-dd')
              .format(DateFormat('MMM d, yyyy').parse(this.formattedEndDate)));
    } else {
      _fetchedOrganization = await fetchOrganization(newValue!.id!);
      _fetchedAttendance = await getLateAttendanceReportByDate(
          _fetchedOrganization!.id!,
          activityId,
          DateFormat('yyyy-MM-dd')
              .format(DateFormat('MMM d, yyyy').parse(this.formattedStartDate)),
          DateFormat('yyyy-MM-dd')
              .format(DateFormat('MMM d, yyyy').parse(this.formattedEndDate)));
    }
    columnNames.clear();
    List<String?> names = _fetchedAttendance
        .map((attendance) => attendance.sign_in_time?.split(" ")[0])
        .where((name) => name != null) // Filter out null values
        .toList();
    columnNames.addAll(names);
    columnNames.sort((a, b) => b!.compareTo(a!));

    String? newSelectedVal;
    if (_selectedValue != null) {
      newSelectedVal = _selectedValue.description;
    }

    setState(() {
      _fetchedOrganization;
      this._isFetching = false;
      _data = MyData(_fetchedAttendance, columnNames, _fetchedOrganization,
          newSelectedVal, updateSelected);
    });
  }

  List<DataColumn> _buildDataColumns() {
    List<DataColumn> ColumnNames = [];

    if (_selectedValue == null) {
      ColumnNames.add(DataColumn(
          label: Text('Date',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Name',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Digital ID',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Class',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('In Time',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Late By',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
    } else {
      ColumnNames.add(DataColumn(
          label: Text('Date',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Name',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Digital ID',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('In Time',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
      ColumnNames.add(DataColumn(
          label: Text('Late By',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold))));
    }
    return ColumnNames;
  }

  @override
  Widget build(BuildContext context) {
    var cols =
        columnNames.map((label) => DataColumn(label: Text(label!))).toList();

    return SingleChildScrollView(
      child: campusAppsPortalPersonMetaDataInstance
              .getGroups()
              .contains('Student')
          ? Text("Please go to 'Mark Attedance' Page",
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold))
          : Wrap(
              children: <Widget>[
                Row(
                  children: [
                    SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        for (var org in campusAppsPortalInstance
                            .getUserPerson()
                            .organization!
                            .child_organizations)
                          // create a text widget with some padding
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (org.child_organizations.length > 0)
                                  Container(
                                    margin: EdgeInsets.only(
                                        left: 20, top: 20, bottom: 10),
                                    child: Row(children: <Widget>[
                                      Text('Select a class:'),
                                      SizedBox(width: 10),
                                      DropdownButton<Organization>(
                                        value: _selectedValue,
                                        onChanged:
                                            (Organization? newValue) async {
                                          _selectedValue = newValue ?? null;
                                          int? parentOrgId =
                                              campusAppsPortalInstance
                                                  .getUserPerson()
                                                  .organization!
                                                  .id;
                                          if (_selectedValue == null) {
                                            // _fetchedOrganization = null;
                                            _fetchedStudentList =
                                                await fetchOrganizationForAll(
                                                    parentOrgId!);
                                          } else {
                                            // _fetchedStudentList = <Person>[];
                                            _fetchedOrganization =
                                                await fetchOrganization(
                                                    newValue!.id!);
                                          }

                                          if (_selectedValue == null) {
                                            _fetchedAttendance =
                                                await getLateAttendanceReportByParentOrg(
                                                    parentOrgId!,
                                                    activityId,
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(DateFormat(
                                                                'MMM d, yyyy')
                                                            .parse(this
                                                                .formattedStartDate)),
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(DateFormat(
                                                                'MMM d, yyyy')
                                                            .parse(this
                                                                .formattedEndDate)));
                                          } else {
                                            _fetchedAttendance =
                                                await getLateAttendanceReportByDate(
                                                    _fetchedOrganization!.id!,
                                                    activityId,
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(DateFormat(
                                                                'MMM d, yyyy')
                                                            .parse(this
                                                                .formattedStartDate)),
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(DateFormat(
                                                                'MMM d, yyyy')
                                                            .parse(this
                                                                .formattedEndDate)));
                                          }

                                          if (_fetchedAttendance.length > 0) {
                                            // Add null check here
                                            // Process attendance data here
                                            columnNames.clear();
                                            List<String?> names =
                                                _fetchedAttendance
                                                    .map((attendance) =>
                                                        attendance.sign_in_time
                                                            ?.split(" ")[0])
                                                    .where((name) =>
                                                        name !=
                                                        null) // Filter out null values
                                                    .toList();
                                            columnNames.addAll(names);
                                          } else {
                                            columnNames.clear();
                                          }

                                          cols = columnNames
                                              .map((label) => DataColumn(
                                                  label: Text(label!)))
                                              .toList();
                                          if (_selectedValue == null) {
                                            setState(() {
                                              if (_fetchedOrganization !=
                                                  null) {
                                                _fetchedOrganization!.people =
                                                    _fetchedStudentList;
                                                _fetchedOrganization!.id =
                                                    parentOrgId;
                                                _fetchedOrganization!
                                                    .description = "Select All";
                                              } else {
                                                _fetchedOrganization =
                                                    Organization();
                                                _fetchedOrganization!.people =
                                                    _fetchedStudentList;
                                                _fetchedOrganization!.id =
                                                    parentOrgId;
                                                _fetchedOrganization!
                                                    .description = "Select All";
                                              }
                                              _fetchedStudentList;
                                              _data = MyData(
                                                  _fetchedAttendance,
                                                  columnNames,
                                                  _fetchedOrganization,
                                                  _selectedValue,
                                                  updateSelected);
                                            });
                                          } else {
                                            setState(() {
                                              _fetchedOrganization;
                                              _fetchedStudentList;
                                              _data = MyData(
                                                  _fetchedAttendance,
                                                  columnNames,
                                                  _fetchedOrganization,
                                                  _selectedValue.description,
                                                  updateSelected);
                                            });
                                          }
                                        },
                                        items: [
                                          // Add "Select All" option
                                          DropdownMenuItem<Organization>(
                                            value: null,
                                            child: Text("Select All"),
                                          ),
                                          // Add other organization options
                                          ...org.child_organizations
                                              .map((Organization value) {
                                            return DropdownMenuItem<
                                                Organization>(
                                              value: value,
                                              child: Text(value.description!),
                                            );
                                          }),
                                        ],
                                      ),
                                    ]),
                                  ),
                              ]),
                      ],
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                        textStyle: MaterialStateProperty.all(
                          TextStyle(fontSize: 20),
                        ),
                        elevation: MaterialStateProperty.all(20),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.greenAccent),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.black),
                      ),
                      onPressed: _isFetching
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DateRangePicker(
                                        updateDateRange, formattedStartDate)),
                              ),
                      child: Container(
                        height: 50, // Adjust the height as needed
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isFetching)
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: SpinKitFadingCircle(
                                  color: Colors
                                      .black, // Customize the color of the indicator
                                  size:
                                      20, // Customize the size of the indicator
                                ),
                              ),
                            if (!_isFetching)
                              Icon(Icons.calendar_today, color: Colors.black),
                            SizedBox(width: 10),
                            Text(
                              '${this.formattedStartDate} - ${this.formattedEndDate}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                SizedBox(height: 16.0),
                SizedBox(height: 32.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isFetching)
                      Container(
                        margin: EdgeInsets.only(top: 180),
                        child: SpinKitCircle(
                          color: (Colors
                              .blue), // Customize the color of the indicator
                          size: 50, // Customize the size of the indicator
                        ),
                      )
                    else if (cols.length > 0)
                      PaginatedDataTable(
                        showCheckboxColumn: false,
                        source: _data,
                        columns: _buildDataColumns(),
                        // header: const Center(child: Text('Daily Attendance')),
                        columnSpacing: 100,
                        horizontalMargin: 60,
                        rowsPerPage: _fetchedAttendance.length + 1,
                      )
                    else
                      Container(
                        margin: EdgeInsets.all(20),
                        child: Text('No attendance data found'),
                      ),
                  ],
                )
              ],
            ),
    );
  }
}

class MyData extends DataTableSource {
  MyData(this._fetchedAttendance, this.columnNames, this._fetchedOrganization,
      this._selectedValue, this.updateSelected);

  final List<ActivityAttendance> _fetchedAttendance;
  final List<String?> columnNames;
  final Organization? _fetchedOrganization;
  final String? _selectedValue;
  final Function(int, bool, List<bool>) updateSelected;

  List<String> getDatesFromMondayToToday() {
    DateTime now = DateTime.now();
    DateTime previousMonday = now.subtract(Duration(days: now.weekday - 1));
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    List<String> dates = [];
    for (DateTime date = previousMonday;
        date.isBefore(currentDate);
        date = date.add(Duration(days: 1))) {
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        dates.add(DateFormat('yyyy-MM-dd').format(date));
      }
    }

    return dates;
  }

  List<int?> selectedPersonIds = [];
  String? lastProcessedDate;
  @override
  DataRow? getRow(int index) {
    if (index == 0 && _selectedValue == null) {
      List<DataCell> cells = List<DataCell>.filled(6, DataCell.empty);
      return DataRow(
        cells: cells,
      );
    } else if (index == 0 && _selectedValue != null) {
      List<DataCell> cells = List<DataCell>.filled(5, DataCell.empty);
      return DataRow(
        cells: cells,
      );
    }

    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final dateFormatter = DateFormat('yyyy-MM-dd');
    List<String> validDates = [];

    for (var element in columnNames) {
      if (dateRegex.hasMatch(element!)) {
        try {
          dateFormatter.parseStrict(element);
          validDates.add(element);
        } catch (e) {
          // Handle the exception or continue to the next element
        }
      }
    }

    if (_fetchedOrganization != null &&
        _fetchedOrganization!.people.isNotEmpty &&
        validDates.length > 0 &&
        index <= validDates.length) {
      var date = validDates[index - 1];
      List<DataCell> cells = [];
      if (_selectedValue == null) {
        cells = List<DataCell>.filled(6, DataCell.empty);
      } else {
        cells = List<DataCell>.filled(5, DataCell.empty);
      }

      cells[0] = DataCell(Text(date));
      for (final person in _fetchedOrganization!.people) {
        // Check if the person has already been selected

        for (final attendance in _fetchedAttendance) {
          if (attendance.person_id == person.id &&
              attendance.sign_in_time!.startsWith(date)) {
            var lateSignInTime = DateTime.parse(attendance.sign_in_time!);
            var officeStartTime = DateTime.parse("$date 07:30:00");
            var lateBy = lateSignInTime.difference(officeStartTime).inMinutes;

            if (lateBy > 0) if (selectedPersonIds.contains(person.id)) {
              break; // Skip to the next iteration if already selected
            }
            if (_selectedValue == null) {
              cells[1] = DataCell(Text(person.preferred_name!));
              cells[2] = DataCell(Text(person.digital_id.toString()));
              cells[3] = DataCell(Text(attendance.description.toString()));
              var formattedTime = DateFormat('hh:mm a').format(lateSignInTime);
              cells[4] = DataCell(Text(formattedTime));
              cells[5] = DataCell(Text(lateBy.toString() + " minutes"));
            } else {
              cells[1] = DataCell(Text(person.preferred_name!));
              cells[2] = DataCell(Text(person.digital_id.toString()));
              var formattedTime = DateFormat('hh:mm a').format(lateSignInTime);
              cells[3] = DataCell(Text(formattedTime));
              cells[4] = DataCell(Text(lateBy.toString() + " minutes"));
            }

            // Add the person ID to the set of selected IDs
            selectedPersonIds.add(person.id);

            return DataRow(cells: cells);
          }
        }
      }

      print(cells.length);
    }

    return null; // Return null for invalid index values
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount {
    int count = 0;
    if (_fetchedOrganization != null) {
      count = _fetchedAttendance.length + 1;
    }
    return count;
  }

  @override
  int get selectedRowCount => 0;
}
