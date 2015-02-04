part of duct_tape;

class IsolatesController {
  Function _onMessage = () {};

  spawn(IsolateWrapper base) {
    IsolateRoot rootIsolate = new IsolateRoot();
    rootIsolate.spawn(base);
    rootIsolate.listen((message) {
      return _onMessage(message);
    });
  }

  /**
   * Listens for messages from isolates. [onData] will be called on each message.
   */
  void listen(onMessage(message)) {
    _onMessage = onMessage;
  }
}