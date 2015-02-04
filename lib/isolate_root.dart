part of duct_tape;

class IsolateRoot {
  SendPort _sendPort;
  Function _onMessage = () {};

  void spawn(IsolateWrapper worker) {
    ReceivePort receivePort = new ReceivePort();
    Isolate.spawn(IsolateSpawned.run, {
        'sendPort': receivePort.sendPort,
        'worker': worker
    });

    receivePort.listen((var message) {
      if(message is SendPort) {
        _sendPort = message;
      } else {
        _sendPort.send({
          'id': message['id'],
          'message': _onMessage(message['message'])
        });
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
}