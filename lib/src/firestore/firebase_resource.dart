import 'package:flutter/foundation.dart';
import 'package:softi_common/resource.dart';

class FirestoreResource<T> extends IResource<T> {
  final String endpoint;
  final Deserializer<T> fromJson;

  FirestoreResource({
    @required this.fromJson,
    @required this.endpoint,
  });

  @override
  String endpointResolver({
    ResourceRequestType requestType,
    QueryParameters queryParams,
    QueryPagination querypagination,
    String dataId,
    String dataPath,
    T dataObject,
  }) {
    return endpoint;
  }

  @override
  T deserializer(Map<String, dynamic> serializedData) {
    return fromJson(serializedData);
  }
}
