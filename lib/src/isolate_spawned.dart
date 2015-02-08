part of duct_tape;

class IsolateSpawned {
  SendPort _sendPort;

  /**
   * Called on each message received from root isolate.
   */
  Function _onMessage;

  Map<int, Completer> _requests = {};

  int _lastKey = 0;

  IsolateSpawned(this._sendPort);

  /**
   * Exchange ports between current isolate and root.
   */
  void _exchangePorts() {
    var port = new ReceivePort();
    _sendPort.send(port.sendPort);

    port.listen((Map message) {
      if(!message.containsKey('id')) {
        if(_onMessage == null) {
          throw new Exception('Message was sent by root but child does not '
          'listen for messages');
        }

        _onMessage(message['message']);
      } else {
        _requests[message['id']].complete(message['message']);
        _requests.remove(message['id']);
      }
    });
  }

  /**
   * Starts passed [worker].
   */
  void _startWorker(IsolateWrapper worker) {
    worker.run(this);
  }

  /**
   * Entry point for new isolate.
   */
  static run(Map data) {
    IsolateSpawned isolate = new IsolateSpawned(data['sendPort']);
    isolate._exchangePorts();
    isolate._startWorker(data['worker']);
  }

  /**
   * Sends message to root isolate.
   */
  Future send(var message) {
    Completer request = new Completer();

    _sendPort.send({
      'id': _lastKey,
      'message': message
    });

    _requests[_lastKey] = request;
    _lastKey++;

    return request.future;
  }

  void listen(Function onMessage) {
    _onMessage = onMessage;
  }
}