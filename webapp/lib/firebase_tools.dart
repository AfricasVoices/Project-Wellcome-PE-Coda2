import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;

import 'firebase_constants.dart' as firebase_constants;
import 'user.dart' as user;
import 'data_model.dart';
import 'logger.dart' as log;
import 'config.dart';
import 'sample_data/sample_json_datasets.dart';
import 'dart:async';

class DatasetLoadException implements Exception {
  final String _message;
  const DatasetLoadException(this._message);
  String toString() => _message;
}

typedef MessageUpdatesListener(List<Message> messages, ChangeType changeType);
enum ChangeType {
  added,
  modified
}

firestore.Firestore _firestoreInstance = firebase.firestore();

init() async {
  if (TEST_MODE) return;

  await firebase_constants.init();

  firebase.initializeApp(
      apiKey: firebase_constants.apiKey,
      authDomain: firebase_constants.authDomain,
      databaseURL: firebase_constants.databaseURL,
      projectId: firebase_constants.projectId,
      storageBucket: firebase_constants.storageBucket,
      messagingSenderId: firebase_constants.messagingSenderId);
}

updateMessage(Dataset dataset, Message msg) {


  log.trace("skippedMessageUpdate", "$msg");
  return;


  // var docPath = "datasets/${dataset.id}/messages/${msg.id}";

  // if (TEST_MODE) {
  //   log.logFirestoreCall('updateMessage', '$docPath', msg.toFirebaseMap());
  //   return;
  // }

  // _firestoreInstance.doc(docPath).set(msg.toFirebaseMap()).then((_) {
  //   log.trace("updateMessage", "Complete: ${msg.id}");
  //   log.perf("updateMessage", sw.elapsedMilliseconds);
  //   updateDatasetStatus(dataset);
  // });
}

updateDatasetStatus(Dataset dataset) {
  Stopwatch sw = new Stopwatch()..start();
  log.trace("updateDatasetStatus", "${dataset.id}");

  int messagesCount = dataset.messages.length;
  int messagesWithLabel = dataset.messages.where((m) => m.labels.length > 0).length;
  int messagesWithWS = 0;
  int messagesWithNC = 0;

  // find the WS and NC Code scheme IDs
  var schemesIdtoWScodeIds = <String, Set<String>>{};
  var schemesIdtoNCcodeIds = <String, Set<String>>{};

  for (Scheme s in dataset.codeSchemes) {
    schemesIdtoWScodeIds.putIfAbsent(s.id, () => new Set());
    schemesIdtoNCcodeIds.putIfAbsent(s.id, () => new Set());

    var wsCodeIdList = s.codes.where(
      (c) => c.codeType == Code.CODETYPE_CONTROL && c.controlCode == "WS").toList();
    String wsCodeId = wsCodeIdList.length != 0 ? wsCodeIdList.first.id : null;
    
    var ncCodeIdList = s.codes.where(
      (c) => c.codeType == Code.CODETYPE_CONTROL && c.controlCode == "NC").toList();
    String ncCodeId = ncCodeIdList.length != 0 ? ncCodeIdList.first.id : null;

    if (wsCodeId != null) {
      schemesIdtoWScodeIds[s.id].add(wsCodeId);
    }
    if (ncCodeId != null) {
      schemesIdtoNCcodeIds[s.id].add(ncCodeId);
    }
  }

  for (Message m in dataset.messages) {
    for (Label l in m.labels) {
      String schemeId = l.schemeId;
      String codeId = l.codeId;

      if (schemesIdtoWScodeIds[schemeId].contains(codeId)) {
        messagesWithWS++;
      }
      if (schemesIdtoNCcodeIds[schemeId].contains(codeId)) {
        messagesWithNC++;
      }
    }
  }
  
  var stats = {
    "messages_count" : messagesCount,
    "messages_with_label" : messagesWithLabel,
    "wrong_scheme_messages" : messagesWithWS,
    "not_coded_messages" : messagesWithNC
  };

  var docPath = "datasets/${dataset.id}/metrics/messages";

_firestoreInstance.doc(docPath).set(stats).then((_) {
    log.trace("updateDatasetStatus", "Complete: ${dataset.id}");
    log.perf("updateDatasetStatus", sw.elapsedMilliseconds);
  });
}

Future<List<Scheme>> loadSchemes(String datasetId) async {
  List<Scheme> ret = <Scheme>[];
  Stopwatch sw = new Stopwatch()..start();

  log.trace("loadSchemes", "Loading schemes for: $datasetId");

  var schemeCollectionRoot = "/datasets/$datasetId/code_schemes";
  log.trace("loadSchemes", "Root of query: $schemeCollectionRoot");

  var schemesQuery = await _firestoreInstance.collection(schemeCollectionRoot).get();
  log.trace("loadSchemes", "Query constructed");

  schemesQuery.forEach((scheme) {
    log.trace("loadSchemes", "Processing ${scheme.id}");

    ret.add(new Scheme.fromFirebaseMap(scheme.data()));
  });

  log.trace("loadSchemes", "${ret.length} schemes loaded in ${sw.elapsedMilliseconds}ms");
  log.perf("loadSchemes", sw.elapsedMilliseconds);
  return ret;
}

void setupListenerForFirebaseMessageUpdates(Dataset dataset, MessageUpdatesListener listener) {
  Stopwatch sw = new Stopwatch()..start();
  log.trace("setupListenerForFirebaseMessageUpdates", "Loading messages for: ${dataset.id}");

  var messagesCollectionRoot = "/datasets/${dataset.id}/messages";
  log.trace("setupListenerForFirebaseMessageUpdates", "Root of query: $messagesCollectionRoot");

  _firestoreInstance.collection(messagesCollectionRoot).onSnapshot.listen((querySnapshot) {
    // No need to process local writes to Firebase
    if (querySnapshot.metadata.hasPendingWrites) {
      log.trace("setupListenerForFirebaseMessageUpdates", "Skipping processing of local messages");
      return;
    }

    log.trace("setupListenerForFirebaseMessageUpdates", "Starting processing ${querySnapshot.docChanges().length} messages.");
    List<Message> added = [];
    List<Message> modified = [];
    querySnapshot.docChanges().forEach((documentChange) {
      Message message = new Message.fromFirebaseMap(documentChange.doc.data());
      if (documentChange.type == "added") {
        added.add(message);
      } else if (documentChange.type == "modified") {
        modified.add(message);
      } else {
        log.log("setupListenerForFirebaseMessageUpdates: Warning! Skip processing ${documentChange.type} message ${message.id}");
      }
    });
    log.trace("setupListenerForFirebaseMessageUpdates", "Finished processing ${querySnapshot.docChanges().length} messages in ${sw.elapsedMilliseconds}ms.");
    log.perf("DatasetLoad", sw.elapsedMilliseconds);

    listener(added, ChangeType.added);
    listener(modified, ChangeType.modified);
  });
}

Future<Dataset> loadDatasetWithOnlyCodeSchemes(String datasetId) async {
  log.verbose("Loading dataset: $datasetId");

  // TODO handle non-datasets for demo usage

  if (TEST_MODE) {
    log.logFirestoreCall('loadDataset', '$datasetId', jsonDatasetTwoSchemes);
    return new Dataset('two schemes', [], jsonDatasetTwoSchemes['CodeSchemes']);
  }

  List<Scheme> schemes = await loadSchemes(datasetId);

  return new Dataset(datasetId, [], schemes);
}

Future<List<String>> getDatasetIdsList() async {
  List<String> datasetIds = <String>[];
  Stopwatch sw = new Stopwatch()..start();

  log.trace("setupListenerForFirebaseMessageUpdates", "Loading dataset list");

  var datasetsCollectionRoot = "/datasets";
  log.trace("getDatasetIdsList", "Root of query: $datasetsCollectionRoot");

  var datasetsQuery = await _firestoreInstance
    .collection(datasetsCollectionRoot)
    .where("users", "array-contains", user.getUserEmail())
    .get();
  log.trace("getDatasetIdsList", "Query constructed");

  datasetsQuery.forEach((dataset) {
    log.trace("getDatasetIdsList", "Processing ${dataset.id}");

    datasetIds.add(dataset.id);
  });

  log.trace("getDatasetIdsList", "${datasetIds.length} dataset ids collected in ${sw.elapsedMilliseconds}ms.");
  log.perf("getDatasetIdsList", sw.elapsedMilliseconds);

  return datasetIds;
}
