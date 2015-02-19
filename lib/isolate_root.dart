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

  Future spawn(IsolateWrapper worker, int isolateId) {
    Completer completer = new Completer();
    ReceivePort receivePort = new ReceivePort();
    Isolate.spawn(IsolateSpawned.run, {
      'sendPort': receivePort.sendPort,
      'worker': worker,
      'isolateId': isolateId
    });

    receivePort.listen((var message) {
      if(message is SendPort) {
        _sendPort = message;
        completer.complete();
      } else if (message['type'] == 'request') {
        _sendPort.send({
          'id': message['id'],
          'type': 'response',
          'data': _onMessage(message['data'])
        });
      } else if (message['type'] == 'response') {
        _requests[message['id']].complete(message['data']);
        _requests.remove(message['id']);
      } else {
        throw new Exception('Unknown message type: $message');
      }
    });

    return completer.future;
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
      'type': 'request',
      'data': message
    });

    _requests[_lastKey] = request;
    _lastKey++;

    return request.future;
  }
}