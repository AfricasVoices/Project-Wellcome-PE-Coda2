import 'data_model.dart';
import 'dart:html' as html;
import 'logger.dart' as log;

import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method


Dataset generateEmptyDataset(String datasetId, int schemeCount, int messageCount) {
  Dataset dataset = new Dataset.empty(datasetId);
  for (int i = 0; i < schemeCount; i++) {
    Scheme scheme = new Scheme('scheme $i');
    for (int c = 0; c < 5; c++) {

      scheme.codes.add(
        new Code("$c", "Code $c", c, true)
      );
    }
    dataset.codeSchemes.add(scheme);
  }

  for (int i = 0; i < messageCount; i++) {
    dataset.messages.add(new Message('msg_$i', i, 'message', new DateTime.now()));
  }

  return dataset;
}

int nextSeq = 100;
typedef MessageUpdatesListener(List<Message> messages);

void setupListenerForUpdates(Dataset dataset, html.Window window,
  MessageUpdatesListener listener) {

  window.onMessage.listen((message) {
    log.trace("message Recieved", message.data);

    String text = message.data;
    var bytes = utf8.encode(text); // data being hashed
    String id = sha1.convert(bytes).toString();

    Message msg = new Message(id, nextSeq++, text, DateTime.now());
    listener([msg]);
  });
}
