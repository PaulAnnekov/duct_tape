part of duct_tape;

class IsolatesController {
  Function _onMessage = () {};

  List<IsolateRoot> _isolates = new List<IsolateRoot>();

  spawn(IsolateWrapper base) {
    IsolateRoot rootIsolate = new IsolateRoot();
    rootIsolate.spawn(base);
    rootIsolate.listen((message) {
      return _onMessage(message);
    });

    _isolates.add(rootIsolate);
  }

  /**
   * Listens for messages from isolates. [onData] will be called on each message.
   */
  void listen(onMessage(message)) {
    _onMessage = onMessage;
  }

  /**
   * Sends message to isolates.
   */
  void send(message) {
    _isolates.forEach((IsolateRoot isolate) {
      isolate.send(message);
    });
  }
}