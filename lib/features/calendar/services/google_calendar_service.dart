import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:http/http.dart' as http;

class GoogleCalendarEvent {
  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    this.description,
    this.updated,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime? updated;
}

class GoogleCalendarSyncData {
  const GoogleCalendarSyncData({
    required this.accountEmail,
    required this.events,
    this.warnings = const <String>[],
  });

  final String accountEmail;
  final List<GoogleCalendarEvent> events;
  final List<String> warnings;
}

class GoogleCalendarService {
  GoogleCalendarService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(scopes: _scopes);

  final GoogleSignIn _googleSignIn;
  static const _scopes = <String>[
    calendar.CalendarApi.calendarReadonlyScope,
    tasks.TasksApi.tasksReadonlyScope,
  ];

  /// Opens Google account consent if needed, then loads events from today
  /// through the next 90 days from the user's primary calendar.
  Future<GoogleCalendarSyncData?> loadUpcomingEvents() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final hasGrantedScopes = await _googleSignIn.requestScopes(_scopes);
    if (!hasGrantedScopes) {
      throw StateError('Google Calendar and Google Tasks access was not granted.');
    }

    final headers = await account.authHeaders;
    final client = _GoogleAuthClient(headers);
    final api = calendar.CalendarApi(client);
    final events = <GoogleCalendarEvent>[];
    final warnings = <String>[];
    final startOfToday = DateTime.now();
    final timeMin = DateTime(startOfToday.year, startOfToday.month, startOfToday.day).toUtc();
    final timeMax = timeMin.add(const Duration(days: 90));

    try {
      await _loadCalendarEvents(api, events, timeMin, timeMax);
      try {
        await _loadGoogleTasks(tasks.TasksApi(client), events, timeMin, timeMax);
      } catch (_) {
        warnings.add('Google Tasks could not be read. Enable Google Tasks API in Google Cloud, then sync again.');
      }
    } finally {
      client.close();
    }

    return GoogleCalendarSyncData(accountEmail: account.email, events: events, warnings: warnings);
  }

  Future<void> _loadCalendarEvents(
    calendar.CalendarApi api,
    List<GoogleCalendarEvent> destination,
    DateTime timeMin,
    DateTime timeMax,
  ) async {
    final calendarIds = <String>[];
    String? calendarPageToken;
    do {
      final calendars = await api.calendarList.list(pageToken: calendarPageToken);
      calendarIds.addAll((calendars.items ?? const <calendar.CalendarListEntry>[])
          .where((entry) => entry.id != null && entry.selected != false)
          .map((entry) => entry.id!));
      calendarPageToken = calendars.nextPageToken;
    } while (calendarPageToken != null);

    for (final calendarId in calendarIds.toSet()) {
      String? eventPageToken;
      do {
        final response = await api.events.list(
          calendarId,
          timeMin: timeMin,
          timeMax: timeMax,
          singleEvents: true,
          orderBy: 'startTime',
          maxResults: 2500,
          pageToken: eventPageToken,
        );
        for (final event in response.items ?? const <calendar.Event>[]) {
          final id = event.id;
          final start = event.start?.dateTime ?? event.start?.date;
          if (id == null || start == null || event.status == 'cancelled') continue;
          destination.add(GoogleCalendarEvent(
            id: 'calendar:$calendarId:$id',
            title: (event.summary?.trim().isNotEmpty ?? false) ? event.summary!.trim() : 'Untitled event',
            description: event.description,
            start: start.toLocal(),
            updated: event.updated,
          ));
        }
        eventPageToken = response.nextPageToken;
      } while (eventPageToken != null);
    }
  }

  Future<void> _loadGoogleTasks(
    tasks.TasksApi api,
    List<GoogleCalendarEvent> destination,
    DateTime timeMin,
    DateTime timeMax,
  ) async {
    String? listPageToken;
    do {
      final taskLists = await api.tasklists.list(pageToken: listPageToken);
      for (final taskList in taskLists.items ?? const <tasks.TaskList>[]) {
        if (taskList.id == null) continue;
        String? taskPageToken;
        do {
          final taskPage = await api.tasks.list(
            taskList.id!,
            dueMin: timeMin.toIso8601String(),
            dueMax: timeMax.toIso8601String(),
            showCompleted: false,
            maxResults: 100,
            pageToken: taskPageToken,
          );
          for (final task in taskPage.items ?? const <tasks.Task>[]) {
            final id = task.id;
            final due = task.due;
            if (id == null || due == null || task.deleted == true) continue;
            final dueDate = DateTime.tryParse(due);
            if (dueDate == null) continue;
            destination.add(GoogleCalendarEvent(
              id: 'task:${taskList.id}:$id',
              title: (task.title?.trim().isNotEmpty ?? false) ? task.title!.trim() : 'Untitled task',
              description: task.notes,
              start: DateTime(dueDate.year, dueDate.month, dueDate.day),
              updated: task.updated == null ? null : DateTime.tryParse(task.updated!),
            ));
          }
          taskPageToken = taskPage.nextPageToken;
        } while (taskPageToken != null);
      }
      listPageToken = taskLists.nextPageToken;
    } while (listPageToken != null);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
