import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:softi_common/resource.dart';
import 'package:softi_firebase_module/src/firestore/firebase_resource.dart';

T fromFirestore<T extends IResourceData>(FirestoreResource<T> res, DocumentSnapshot docSnap) {
  var map = docSnap.data();
  if (map == null) return null;

  var _map = firestireMap(map, true);
  if (_map == null) return null;

  var _result = res.deserializer({
    'id': docSnap.id,
    'path': docSnap.reference.path,
    ..._map,
  });

  return _result;
}

Map<String, dynamic> toFirestore(IResourceData doc) {
  var map = doc.toJson();
  if (map == null) return null;

  var _map = firestireMap(map, false);
  if (_map == null) return null;

  return _map..remove('id')..remove('path');
}

Map<String, dynamic> firestireMap(Map<String, dynamic> input, bool fromFirestore, [bool skipNull = true]) {
  var result = <String, dynamic>{};

  input.forEach((k, v) {
    if (skipNull && v == null) {
      return;
    } else if (v is Map) {
      result[k] = firestireMap(v, fromFirestore);
    } else if (v is List) {
      result[k] = firestireList(v, fromFirestore);
    } else {
      result[k] = firestoreTransform(v, fromFirestore);
    }
  });
  return result;
}

List firestireList(List input, bool fromFirestore, [bool skipNull = true]) {
  var result = [];

  input.forEach((v) {
    if (skipNull && v == null) {
      return;
    } else if (v is Map) {
      result.add(firestireMap(v, fromFirestore));
    } else if (v is List) {
      result.add(firestireList(v, fromFirestore));
    } else {
      result.add(firestoreTransform(v, fromFirestore));
    }
  });

  return result;
}

dynamic firestoreTransform(dynamic v, bool fromFirestore) {
  if (fromFirestore) {
    //FROM FIRESTORE

    if (v is Timestamp) {
      return v.toDate();
    } else if (v is DocumentReference) {
      return v.id;
    } else {
      return v;
    }
  } else {
    // TO FIRESTORE

    if (v is DateTime) {
      return Timestamp.fromDate(v);
    } else {
      return v;
    }
  }
}
