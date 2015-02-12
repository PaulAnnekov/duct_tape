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
      if(message['type'] == MessageType.REQUEST) {
        if(_onMessage == null) {
          throw new Exception('Message was sent by root but child does not '
          'listen for messages');
        }

        _onMessage(message['message']).then((response) {
          _sendPort.send({
            'id': message['id'],
            'type': MessageType.RESPONSE,
            'data': response
          });
        });
      } else if (message['type'] == MessageType.RESPONSE) {
        _requests[message['id']].complete(message['data']);
        _requests.remove(message['id']);
      } else {
        throw new Exception('Unknown message type: $message');
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
      'type': MessageType.REQUEST,
      'data': message
    });

    _requests[_lastKey] = request;
    _lastKey++;

    return request.future;
  }

  /**
   * Listen for incoming requests from root isolate. [onMessage] will be called
   * on each request from root.
   */
  void listen(Future onMessage(dynamic data)) {
    _onMessage = onMessage;
  }
}