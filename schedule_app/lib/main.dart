import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This method is responsible for building the UI of the app.
    return MaterialApp(
      // The title of the app, which will be displayed in the device's app switcher or task manager.
      title: 'Scheduling App',

      // The theme data for the app, which defines the visual appearance.
      theme: ThemeData(
        primarySwatch:
            Colors.blue, // Specifies the primary color swatch for the app.
      ),

      // The home widget for the app, which represents the initial screen of the app.
      home: const MyHomePage(title: 'Scheduling App'),

      // A map of named routes for the app, which allows navigation to different screens.
      routes: {
        '/weather': (context) =>
            const WeatherScreen(), // Registers a route named '/weather' that leads to the WeatherScreen widget.
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  // Constructor for the MyHomePage widget.
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // Title of the home page, passed as a required parameter.
  final String title;

  // Override of the createState() method from StatefulWidget.
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  List<Event> _events = [];

  // This method is called when the state object is first created.
  @override
  void initState() {
    super.initState();
    _loadEvents(); // Load events from shared preferences.
  }

  // This method is called when the state object is about to be destroyed.
  @override
  void dispose() {
    _eventNameController.dispose();
    _dayController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Loads events from shared preferences.
  Future<void> _loadEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? eventList = prefs.getStringList('events');
    if (eventList != null) {
      setState(() {
        _events = eventList
            .map((eventString) => Event.fromMap(jsonDecode(eventString)))
            .toList();
      });
    }
  }

  // Saves events to shared preferences.
  Future<void> _saveEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> eventList =
        _events.map((event) => jsonEncode(event.toMap())).toList();
    await prefs.setStringList('events', eventList);
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Shows an alert dialog for adding an event.
        return AlertDialog(
          title: const Text('Add Event'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text form fields for entering event details.
                TextFormField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                  validator: (String? value) {
                    // Validates the entered event name.
                    if (value == null || value.isEmpty) {
                      return 'Please enter the event name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _dayController,
                  decoration: const InputDecoration(labelText: 'Day (DD)'),
                  validator: (String? value) {
                    // Validates the entered day.
                    if (value == null || value.isEmpty) {
                      return 'Please enter the day';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _startTimeController,
                  decoration:
                      const InputDecoration(labelText: 'Start Time (HH:mm)'),
                  validator: (String? value) {
                    // Validates the entered start time.
                    if (value == null || value.isEmpty) {
                      return 'Please enter the start time';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _durationController,
                  decoration:
                      const InputDecoration(labelText: 'Duration (in hours)'),
                  validator: (String? value) {
                    // Validates the entered duration.
                    if (value == null || value.isEmpty) {
                      return 'Please enter the duration';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String eventName = _eventNameController.text;
                  final int selectedDay = int.parse(_dayController.text);

                  final List<String> startTimeParts =
                      _startTimeController.text.split(':');
                  final int hours = int.parse(startTimeParts[0]);
                  final int minutes = int.parse(startTimeParts[1]);
                  final int seconds = 0; // Set seconds to 0

                  final int duration = int.parse(_durationController.text);

                  final DateTime startTime = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    selectedDay,
                    hours,
                    minutes,
                    seconds,
                  );
                  final DateTime endTime =
                      startTime.add(Duration(hours: duration));

                  setState(() {
                    // Adds a new event to the _events list.
                    _events.add(
                      Event(
                        eventName: eventName,
                        from: startTime,
                        to: endTime,
                        background: const Color(0xFF0F8644),
                        isAllDay: false,
                      ),
                    );
                  });

                  _saveEvents(); // Saves the updated events to shared preferences.

                  Navigator.of(context).pop(); // Closes the dialog.
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Event meeting = _events[index];
        final String eventName = meeting.eventName;
        final String startTime =
            meeting.from.toString().split(' ')[1].substring(0, 5);
        final String duration =
            meeting.to.difference(meeting.from).inHours.toString();

        return AlertDialog(
          title: const Text('Event Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Event Name: $eventName'),
              Text('Start Time: $startTime'),
              Text('Duration: $duration hours'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _events.removeAt(
                      index); // Removes the event at the specified index from the _events list.
                });
                _saveEvents(); // Saves the updated events to shared preferences.
                Navigator.of(context).pop(); // Closes the dialog.
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Closes the dialog without deleting the event.
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToWeatherScreen() {
    Navigator.pushNamed(context, '/weather');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SfCalendar(
        view: CalendarView.week,
        dataSource: EventDataSource(_events),
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        ),
        onTap: (CalendarTapDetails details) {
          if (details.targetElement == CalendarElement.appointment) {
            final Event meeting = details.appointments![0] as Event;
            final int index = _events.indexOf(meeting);
            _deleteEvent(index);
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addEvent,
            tooltip: 'Add Event',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _navigateToWeatherScreen,
            tooltip: 'Weather',
            child: const Icon(Icons.cloud),
          ),
        ],
      ),
    );
  }
}

class EventDataSource extends CalendarDataSource {
  // MeetingDataSource class that extends the CalendarDataSource class

  EventDataSource(List<Event> source) {
    // Constructor for the MeetingDataSource class that takes a List of Meetings as input
    // and assigns it to the 'appointments' field of the class
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    // Overridden method from the CalendarDataSource class that returns the start time
    // of the meeting at the specified 'index'
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    // Overridden method from the CalendarDataSource class that returns the end time
    // of the meeting at the specified 'index'
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    // Overridden method from the CalendarDataSource class that returns the subject
    // (event name) of the meeting at the specified 'index'
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    // Overridden method from the CalendarDataSource class that returns the color
    // (background) of the meeting at the specified 'index'
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    // Overridden method from the CalendarDataSource class that returns a boolean value
    // indicating whether the meeting at the specified 'index' is an all-day event or not
    return appointments![index].isAllDay;
  }
}

class Event {
  Event({
    required this.eventName,
    required this.from,
    required this.to,
    required this.background,
    required this.isAllDay,
  });

  // Definition of the Meeting class with required properties: eventName, from, to, background, isAllDay

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;

  Map<String, dynamic> toMap() {
    // Method that converts the Meeting object to a Map representation for serialization or storage
    return {
      'eventName': eventName,
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
      'background': background.value,
      'isAllDay': isAllDay,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    // Factory constructor that constructs a Meeting object from a Map representation
    return Event(
      eventName: map['eventName'],
      from: DateTime.fromMillisecondsSinceEpoch(map['from']),
      to: DateTime.fromMillisecondsSinceEpoch(map['to']),
      background: Color(map['background']),
      isAllDay: map['isAllDay'],
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> _currentWeather;
  late Future<Map<String, dynamic>> _forecastWeather;

  @override
  void initState() {
    super.initState();

    // Initialize the Future objects to fetch current and forecast weather data
    _currentWeather = _fetchCurrentWeatherData();
    _forecastWeather = _fetchForecastWeatherData();
  }

  // Method to fetch current weather data from the API
  Future<Map<String, dynamic>> _fetchCurrentWeatherData() async {
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=39.87&lon=-83.08&units=imperial&appid=d3f26c82d27e551d049d6a0e6795f5de'));

    if (response.statusCode == 200) {
      // If the response is successful (status code 200), decode the JSON response and return it
      return jsonDecode(response.body);
    } else {
      // If the response is not successful, throw an exception
      throw Exception('Failed to fetch weather data');
    }
  }

  // Method to fetch forecast weather data from the API
  Future<Map<String, dynamic>> _fetchForecastWeatherData() async {
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=39.87&lon=-83.08&units=imperial&appid=d3f26c82d27e551d049d6a0e6795f5de'));

    if (response.statusCode == 200) {
      // If the response is successful (status code 200), decode the JSON response and return it
      return jsonDecode(response.body);
    } else {
      // If the response is not successful, throw an exception
      throw Exception('Failed to fetch weather forecast data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: _currentWeather,
              builder: (context, snapshot) {
                // Builder for the current weather future
                if (snapshot.hasData) {
                  // If the future has completed and has data
                  final weatherData = snapshot.data as Map<String, dynamic>;
                  final main = weatherData['weather'][0]['main'];
                  final description = weatherData['weather'][0]['description'];

                  return Column(
                    children: [
                      const Icon(
                        Icons.cloud,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        main,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  // If the future has completed with an error
                  return const Text('Failed to fetch weather data');
                } else {
                  // If the future is still loading
                  return const CircularProgressIndicator();
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Weather Forecast for the Next Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder(
                future: _forecastWeather,
                builder: (context, snapshot) {
                  // Builder for the forecast weather future
                  if (snapshot.hasData) {
                    // If the future has completed and has data
                    final forecastData = snapshot.data as Map<String, dynamic>;
                    final List<dynamic> forecastList = forecastData['list'];

                    return ListView.builder(
                      itemCount: forecastList.length,
                      itemBuilder: (context, index) {
                        final forecast = forecastList[index];
                        final main = forecast['weather'][0]['main'];

                        final dateTime = DateTime.fromMillisecondsSinceEpoch(
                            forecast['dt'] * 1000);
                        final day = DateFormat('EEEE').format(dateTime);
                        final time = DateFormat('HH:mm').format(dateTime);

                        final isRainExpected =
                            main.toLowerCase().contains('rain');

                        if (isRainExpected) {
                          final dayTextStyle = TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          );

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                  255, 218, 231, 239), // Add a background color
                              border: Border.all(
                                  color: Colors.grey), // Add a border
                              borderRadius: BorderRadius.circular(
                                  8.0), // Add rounded corners
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.cloud,
                                  size: 50,
                                ),
                              ),
                              title: Text(
                                main,
                                style: const TextStyle(fontSize: 26),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day,
                                    style: dayTextStyle,
                                  ),
                                  Text(
                                    ' at $time',
                                    style: TextStyle(fontSize: 26),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Container(); // Return an empty container for non-rainy forecasts
                      },
                    );
                  } else if (snapshot.hasError) {
                    // If the future has completed with an error
                    return const Text('Failed to fetch weather forecast data');
                  } else {
                    // If the future is still loading
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
