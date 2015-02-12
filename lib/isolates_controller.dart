part of duct_tape;

class IsolatesController {
  Function _onMessage = () {};

  List<Map> _isolates = new List<Map>();

  Queue<Map> _tasks = new Queue();

  spawn(IsolateWrapper base, [int count = 1]) {
    for(var i = 0; i < count; i++) {
      IsolateRoot rootIsolate = new IsolateRoot();
      rootIsolate.spawn(base);
      rootIsolate.listen((message) {
        return _onMessage(message);
      });

      _isolates.add({
        'isolate': rootIsolate,
        'is_busy': false
      });
    }
  }

  /**
   * Listens for messages from isolates. [onData] will be called on each message.
   */
  void listen(onMessage(message)) {
    _onMessage = onMessage;
  }

  /**
   * Tries to run queued task in free isolate.
   */
  _runTasks() {
    if(_tasks.isEmpty)
      return;

    Map isolate = _isolates.firstWhere((Map isolate) =>
        isolate['is_busy'] == false, orElse: () => null);

    if(isolate == null)
      return;

    isolate['is_busy'] = true;

    Map task = _tasks.removeFirst();

    (isolate['isolate'] as IsolateRoot).send(task['task']).then((data) {
      isolate['is_busy'] = false;
      (task['completer'] as Completer).complete(data);
      _runTasks();
    });
  }

  /**
   * Sends message to isolates.
   */
  Future<dynamic> send(message) {
    Completer completer = new Completer();
    _tasks.add({
      'completer': completer,
      'task': message
    });

    _runTasks();

    return completer.future;
  }
}