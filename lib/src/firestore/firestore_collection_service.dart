import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:softi_common/resource.dart';
import 'package:softi_firebase_module/src/firestore/firebase_desirializer.dart';
import 'package:softi_firebase_module/src/firestore/firebase_resource.dart';

class FirestoreCollectionService extends ICollectionService {
  FirestoreCollectionService(
    this._firestoreInstance,
  );

  final FirebaseFirestore _firestoreInstance;

  CollectionReference _getRef<T extends IResourceData>(FirestoreResource<T> res) {
    return _firestoreInstance.collection(res.endpointResolver());
  }

  @override
  Stream<QueryResult<T>> find<T extends IResourceData>(
    IResource<T> res,
    QueryParameters queryParams, {
    QueryPagination pagination,
    bool reactive = true,
  }) {
    var _query = _firestoreQueryBuilder(
      _getRef<T>(res),
      params: queryParams,
      pagination: pagination,
    );

    var _querySnapshot = _query.snapshots();

    var _result = _querySnapshot.map<QueryResult<T>>(
      (snapshot) {
        var data = snapshot.docs
            //! Filter possible here
            .map<T>((doc) => fromFirestore<T>(res, doc))
            .toList();

        var changes = snapshot.docChanges
            //! Filter possible here
            .map((DocumentChange docChange) => DataChange<T>(
                  data: fromFirestore<T>(res, docChange.doc),
                  oldIndex: docChange.oldIndex,
                  newIndex: docChange.newIndex,
                  type: {
                    DocumentChangeType.added: DataChangeType.added,
                    DocumentChangeType.modified: DataChangeType.modified,
                    DocumentChangeType.removed: DataChangeType.removed,
                  }[docChange.type],
                ))
            .toList();

        return QueryResult<T>(
          data,
          changes,
          cursor: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        );
      },
    );

    return reactive ? _result : Stream.fromFuture(_result.first);
  }

  // Check if record exsits
  @override
  Future<bool> exists<T extends IResourceData>(IResource<T> res, String recordId) async {
    var _result = await _getRef<T>(res) //
        .doc(recordId)
        .snapshots()
        .first;

    return _result.exists;
  }

  // Stream documenent from db
  @override
  Stream<T> get<T extends IResourceData>(IResource<T> res, String recordId, {bool reactive = true}) {
    var _result = _getRef<T>(res) //
        .doc(recordId)
        .snapshots()
        .map<T>((snapshot) => fromFirestore<T>(res, snapshot));

    return (reactive ?? false) ? _result : Stream.fromFuture(_result.first);
  }

  @override
  Future<void> update<T extends IResourceData>(IResource<T> res, String id, Map<String, dynamic> values) async {
    var docRef = _getRef<T>(res) //
        .doc(id);

    await docRef.set(firestireMap(values, false), SetOptions(merge: true));
  }

  @override
  Future<T> save<T extends IResourceData>(IResource<T> res, T doc) async {
    var id = doc.getId() ?? '';
    DocumentReference docRef;

    if (id == '') {
      docRef = await _getRef<T>(res).add(toFirestore(doc));
    } else {
      docRef = _getRef<T>(res).doc(id);
      await docRef.set(toFirestore(doc), SetOptions(merge: false));
    }

    return fromFirestore<T>(res, await docRef.snapshots().first);
    // if (refresh)
    //   return fromFirestore<T>(res, await docRef.snapshots().first);
    // else
    //   return doc;
  }

  @override
  Future<void> delete<T extends IResourceData>(IResource<T> res, String documentId) async {
    await _getRef<T>(res) //
        .doc(documentId)
        .delete();
  }

  /// Internala fmethodes
  Query _firestoreQueryBuilder(
    CollectionReference ref, {
    QueryParameters params,
    QueryPagination pagination,
  }) {
    Query _query = ref;

    if (params?.filterList != null) {
      params.filterList.forEach((where) {
        switch (where.condition) {
          case QueryOperator.equal:
            _query = _query.where(where.field, isEqualTo: where.value);
            break;
          case QueryOperator.greaterThanOrEqualTo:
            _query = _query.where(where.field, isGreaterThanOrEqualTo: where.value);
            break;
          case QueryOperator.greaterThan:
            _query = _query.where(where.field, isGreaterThan: where.value);
            break;
          case QueryOperator.lessThan:
            _query = _query.where(where.field, isLessThan: where.value);
            break;
          case QueryOperator.lessThanOrEqualTo:
            _query = _query.where(where.field, isLessThanOrEqualTo: where.value);
            break;
          case QueryOperator.isIn:
            _query = _query.where(where.field, whereIn: where.value);
            break;
          case QueryOperator.arrayContains:
            _query = _query.where(where.field, arrayContains: where.value);
            break;
          case QueryOperator.arrayContainsAny:
            _query = _query.where(where.field, arrayContainsAny: where.value);
            break;
          default:
        }
      });
    }

    // Set orderBy
    if (params?.sortList != null) {
      params.sortList.forEach((orderBy) {
        _query = _query.orderBy(orderBy.field, descending: orderBy.desc);
      });
    }

    // _query = _query.orderBy(FieldPath.documentId, descending: true);

    // Get the last Document
    if (pagination?.cursor != null) {
      _query = _query.startAfterDocument(pagination?.cursor);
    }

    // if (pagination?.endCursor != null) {
    //   _query = _query.endAtDocument(pagination?.endCursor);
    // }

    _query = _query.limit(pagination?.limit ?? 10);

    return _query;
  }
}
