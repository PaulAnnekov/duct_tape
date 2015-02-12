part of duct_tape;

enum MessageType { REQUEST, RESPONSE }

class IsolateRoot {
  /**
   * Receiving port of spawned isolate. Used to send messages to it.
   */
  SendPort _sendPort;

  Function _onMessage = () {};

  Map<int, Completer> _requests = {};

  int _lastKey = 0;

  void spawn(IsolateWrapper worker) {
    ReceivePort receivePort = new ReceivePort();
    Isolate.spawn(IsolateSpawned.run, {
        'sendPort': receivePort.sendPort,
        'worker': worker
    });

    receivePort.listen((var message) {
      if(message is SendPort) {
        _sendPort = message;
      } else if (message['type'] == MessageType.REQUEST) {
        _sendPort.send({
          'id': message['id'],
          'type': MessageType.RESPONSE,
          'data': _onMessage(message['data'])
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
   * Listens for messages from spawned isolate. [onMessage] will be called on
   * each message.
   */
  void listen(onMessage(message)) {
    _onMessage = onMessage;
  }

  /**
   * Sends message to isolate.
   */
  Future<dynamic> send(message) {
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
}