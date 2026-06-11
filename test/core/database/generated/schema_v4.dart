// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class LocalRecordings extends Table
    with TableInfo<LocalRecordings, LocalRecordingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalRecordings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> genreId = GeneratedColumn<String>(
    'genre_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> subcategoryId = GeneratedColumn<String>(
    'subcategory_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0.0'),
  );
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'m4a\''),
  );
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'local\''),
  );
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> gcsUrl = GeneratedColumn<String>(
    'gcs_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> cleaningStatus = GeneratedColumn<String>(
    'cleaning_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'none\''),
  );
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<DateTime> lastRetryAt = GeneratedColumn<DateTime>(
    'last_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> registerId = GeneratedColumn<String>(
    'register_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> resumableSessionUri =
      GeneratedColumn<String>(
        'resumable_session_uri',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<int> uploadedBytes = GeneratedColumn<int>(
    'uploaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> md5Hash = GeneratedColumn<String>(
    'md5_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    genreId,
    subcategoryId,
    title,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    cleaningStatus,
    recordedAt,
    createdAt,
    retryCount,
    lastRetryAt,
    registerId,
    resumableSessionUri,
    uploadedBytes,
    md5Hash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recordings';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalRecordingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecordingsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      genreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre_id'],
      )!,
      subcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_seconds'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      uploadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      gcsUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gcs_url'],
      ),
      cleaningStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cleaning_status'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_retry_at'],
      ),
      registerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register_id'],
      ),
      resumableSessionUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resumable_session_uri'],
      ),
      uploadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uploaded_bytes'],
      )!,
      md5Hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}md5_hash'],
      ),
    );
  }

  @override
  LocalRecordings createAlias(String alias) {
    return LocalRecordings(attachedDatabase, alias);
  }
}

class LocalRecordingsData extends DataClass
    implements Insertable<LocalRecordingsData> {
  final String id;
  final String projectId;
  final String genreId;
  final String? subcategoryId;
  final String? title;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final String localFilePath;
  final String uploadStatus;
  final String? serverId;
  final String? gcsUrl;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? registerId;
  final String? resumableSessionUri;
  final int uploadedBytes;
  final String? md5Hash;
  const LocalRecordingsData({
    required this.id,
    required this.projectId,
    required this.genreId,
    this.subcategoryId,
    this.title,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    required this.localFilePath,
    required this.uploadStatus,
    this.serverId,
    this.gcsUrl,
    required this.cleaningStatus,
    required this.recordedAt,
    required this.createdAt,
    required this.retryCount,
    this.lastRetryAt,
    this.registerId,
    this.resumableSessionUri,
    required this.uploadedBytes,
    this.md5Hash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['genre_id'] = Variable<String>(genreId);
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<String>(subcategoryId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['duration_seconds'] = Variable<double>(durationSeconds);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['format'] = Variable<String>(format);
    map['local_file_path'] = Variable<String>(localFilePath);
    map['upload_status'] = Variable<String>(uploadStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || gcsUrl != null) {
      map['gcs_url'] = Variable<String>(gcsUrl);
    }
    map['cleaning_status'] = Variable<String>(cleaningStatus);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt);
    }
    if (!nullToAbsent || registerId != null) {
      map['register_id'] = Variable<String>(registerId);
    }
    if (!nullToAbsent || resumableSessionUri != null) {
      map['resumable_session_uri'] = Variable<String>(resumableSessionUri);
    }
    map['uploaded_bytes'] = Variable<int>(uploadedBytes);
    if (!nullToAbsent || md5Hash != null) {
      map['md5_hash'] = Variable<String>(md5Hash);
    }
    return map;
  }

  LocalRecordingsCompanion toCompanion(bool nullToAbsent) {
    return LocalRecordingsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      genreId: Value(genreId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      durationSeconds: Value(durationSeconds),
      fileSizeBytes: Value(fileSizeBytes),
      format: Value(format),
      localFilePath: Value(localFilePath),
      uploadStatus: Value(uploadStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      gcsUrl: gcsUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(gcsUrl),
      cleaningStatus: Value(cleaningStatus),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
      registerId: registerId == null && nullToAbsent
          ? const Value.absent()
          : Value(registerId),
      resumableSessionUri: resumableSessionUri == null && nullToAbsent
          ? const Value.absent()
          : Value(resumableSessionUri),
      uploadedBytes: Value(uploadedBytes),
      md5Hash: md5Hash == null && nullToAbsent
          ? const Value.absent()
          : Value(md5Hash),
    );
  }

  factory LocalRecordingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecordingsData(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      genreId: serializer.fromJson<String>(json['genreId']),
      subcategoryId: serializer.fromJson<String?>(json['subcategoryId']),
      title: serializer.fromJson<String?>(json['title']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      format: serializer.fromJson<String>(json['format']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      gcsUrl: serializer.fromJson<String?>(json['gcsUrl']),
      cleaningStatus: serializer.fromJson<String>(json['cleaningStatus']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetryAt: serializer.fromJson<DateTime?>(json['lastRetryAt']),
      registerId: serializer.fromJson<String?>(json['registerId']),
      resumableSessionUri: serializer.fromJson<String?>(
        json['resumableSessionUri'],
      ),
      uploadedBytes: serializer.fromJson<int>(json['uploadedBytes']),
      md5Hash: serializer.fromJson<String?>(json['md5Hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'genreId': serializer.toJson<String>(genreId),
      'subcategoryId': serializer.toJson<String?>(subcategoryId),
      'title': serializer.toJson<String?>(title),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'format': serializer.toJson<String>(format),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'serverId': serializer.toJson<String?>(serverId),
      'gcsUrl': serializer.toJson<String?>(gcsUrl),
      'cleaningStatus': serializer.toJson<String>(cleaningStatus),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetryAt': serializer.toJson<DateTime?>(lastRetryAt),
      'registerId': serializer.toJson<String?>(registerId),
      'resumableSessionUri': serializer.toJson<String?>(resumableSessionUri),
      'uploadedBytes': serializer.toJson<int>(uploadedBytes),
      'md5Hash': serializer.toJson<String?>(md5Hash),
    };
  }

  LocalRecordingsData copyWith({
    String? id,
    String? projectId,
    String? genreId,
    Value<String?> subcategoryId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    double? durationSeconds,
    int? fileSizeBytes,
    String? format,
    String? localFilePath,
    String? uploadStatus,
    Value<String?> serverId = const Value.absent(),
    Value<String?> gcsUrl = const Value.absent(),
    String? cleaningStatus,
    DateTime? recordedAt,
    DateTime? createdAt,
    int? retryCount,
    Value<DateTime?> lastRetryAt = const Value.absent(),
    Value<String?> registerId = const Value.absent(),
    Value<String?> resumableSessionUri = const Value.absent(),
    int? uploadedBytes,
    Value<String?> md5Hash = const Value.absent(),
  }) => LocalRecordingsData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    genreId: genreId ?? this.genreId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    title: title.present ? title.value : this.title,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    format: format ?? this.format,
    localFilePath: localFilePath ?? this.localFilePath,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    gcsUrl: gcsUrl.present ? gcsUrl.value : this.gcsUrl,
    cleaningStatus: cleaningStatus ?? this.cleaningStatus,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
    registerId: registerId.present ? registerId.value : this.registerId,
    resumableSessionUri: resumableSessionUri.present
        ? resumableSessionUri.value
        : this.resumableSessionUri,
    uploadedBytes: uploadedBytes ?? this.uploadedBytes,
    md5Hash: md5Hash.present ? md5Hash.value : this.md5Hash,
  );
  LocalRecordingsData copyWithCompanion(LocalRecordingsCompanion data) {
    return LocalRecordingsData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      title: data.title.present ? data.title.value : this.title,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      format: data.format.present ? data.format.value : this.format,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      gcsUrl: data.gcsUrl.present ? data.gcsUrl.value : this.gcsUrl,
      cleaningStatus: data.cleaningStatus.present
          ? data.cleaningStatus.value
          : this.cleaningStatus,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastRetryAt: data.lastRetryAt.present
          ? data.lastRetryAt.value
          : this.lastRetryAt,
      registerId: data.registerId.present
          ? data.registerId.value
          : this.registerId,
      resumableSessionUri: data.resumableSessionUri.present
          ? data.resumableSessionUri.value
          : this.resumableSessionUri,
      uploadedBytes: data.uploadedBytes.present
          ? data.uploadedBytes.value
          : this.uploadedBytes,
      md5Hash: data.md5Hash.present ? data.md5Hash.value : this.md5Hash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecordingsData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('genreId: $genreId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('title: $title, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('format: $format, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('serverId: $serverId, ')
          ..write('gcsUrl: $gcsUrl, ')
          ..write('cleaningStatus: $cleaningStatus, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('registerId: $registerId, ')
          ..write('resumableSessionUri: $resumableSessionUri, ')
          ..write('uploadedBytes: $uploadedBytes, ')
          ..write('md5Hash: $md5Hash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    projectId,
    genreId,
    subcategoryId,
    title,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    cleaningStatus,
    recordedAt,
    createdAt,
    retryCount,
    lastRetryAt,
    registerId,
    resumableSessionUri,
    uploadedBytes,
    md5Hash,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecordingsData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.genreId == this.genreId &&
          other.subcategoryId == this.subcategoryId &&
          other.title == this.title &&
          other.durationSeconds == this.durationSeconds &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.format == this.format &&
          other.localFilePath == this.localFilePath &&
          other.uploadStatus == this.uploadStatus &&
          other.serverId == this.serverId &&
          other.gcsUrl == this.gcsUrl &&
          other.cleaningStatus == this.cleaningStatus &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt &&
          other.registerId == this.registerId &&
          other.resumableSessionUri == this.resumableSessionUri &&
          other.uploadedBytes == this.uploadedBytes &&
          other.md5Hash == this.md5Hash);
}

class LocalRecordingsCompanion extends UpdateCompanion<LocalRecordingsData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> genreId;
  final Value<String?> subcategoryId;
  final Value<String?> title;
  final Value<double> durationSeconds;
  final Value<int> fileSizeBytes;
  final Value<String> format;
  final Value<String> localFilePath;
  final Value<String> uploadStatus;
  final Value<String?> serverId;
  final Value<String?> gcsUrl;
  final Value<String> cleaningStatus;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetryAt;
  final Value<String?> registerId;
  final Value<String?> resumableSessionUri;
  final Value<int> uploadedBytes;
  final Value<String?> md5Hash;
  final Value<int> rowid;
  const LocalRecordingsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.genreId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.format = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.gcsUrl = const Value.absent(),
    this.cleaningStatus = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.registerId = const Value.absent(),
    this.resumableSessionUri = const Value.absent(),
    this.uploadedBytes = const Value.absent(),
    this.md5Hash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecordingsCompanion.insert({
    required String id,
    required String projectId,
    required String genreId,
    this.subcategoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.format = const Value.absent(),
    required String localFilePath,
    this.uploadStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.gcsUrl = const Value.absent(),
    this.cleaningStatus = const Value.absent(),
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.registerId = const Value.absent(),
    this.resumableSessionUri = const Value.absent(),
    this.uploadedBytes = const Value.absent(),
    this.md5Hash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       genreId = Value(genreId),
       localFilePath = Value(localFilePath),
       recordedAt = Value(recordedAt);
  static Insertable<LocalRecordingsData> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? genreId,
    Expression<String>? subcategoryId,
    Expression<String>? title,
    Expression<double>? durationSeconds,
    Expression<int>? fileSizeBytes,
    Expression<String>? format,
    Expression<String>? localFilePath,
    Expression<String>? uploadStatus,
    Expression<String>? serverId,
    Expression<String>? gcsUrl,
    Expression<String>? cleaningStatus,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetryAt,
    Expression<String>? registerId,
    Expression<String>? resumableSessionUri,
    Expression<int>? uploadedBytes,
    Expression<String>? md5Hash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (genreId != null) 'genre_id': genreId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (title != null) 'title': title,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (format != null) 'format': format,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (serverId != null) 'server_id': serverId,
      if (gcsUrl != null) 'gcs_url': gcsUrl,
      if (cleaningStatus != null) 'cleaning_status': cleaningStatus,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
      if (registerId != null) 'register_id': registerId,
      if (resumableSessionUri != null)
        'resumable_session_uri': resumableSessionUri,
      if (uploadedBytes != null) 'uploaded_bytes': uploadedBytes,
      if (md5Hash != null) 'md5_hash': md5Hash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecordingsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? genreId,
    Value<String?>? subcategoryId,
    Value<String?>? title,
    Value<double>? durationSeconds,
    Value<int>? fileSizeBytes,
    Value<String>? format,
    Value<String>? localFilePath,
    Value<String>? uploadStatus,
    Value<String?>? serverId,
    Value<String?>? gcsUrl,
    Value<String>? cleaningStatus,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<DateTime?>? lastRetryAt,
    Value<String?>? registerId,
    Value<String?>? resumableSessionUri,
    Value<int>? uploadedBytes,
    Value<String?>? md5Hash,
    Value<int>? rowid,
  }) {
    return LocalRecordingsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      genreId: genreId ?? this.genreId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      title: title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      format: format ?? this.format,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      serverId: serverId ?? this.serverId,
      gcsUrl: gcsUrl ?? this.gcsUrl,
      cleaningStatus: cleaningStatus ?? this.cleaningStatus,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      registerId: registerId ?? this.registerId,
      resumableSessionUri: resumableSessionUri ?? this.resumableSessionUri,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      md5Hash: md5Hash ?? this.md5Hash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (genreId.present) {
      map['genre_id'] = Variable<String>(genreId.value);
    }
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<String>(subcategoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (gcsUrl.present) {
      map['gcs_url'] = Variable<String>(gcsUrl.value);
    }
    if (cleaningStatus.present) {
      map['cleaning_status'] = Variable<String>(cleaningStatus.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastRetryAt.present) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt.value);
    }
    if (registerId.present) {
      map['register_id'] = Variable<String>(registerId.value);
    }
    if (resumableSessionUri.present) {
      map['resumable_session_uri'] = Variable<String>(
        resumableSessionUri.value,
      );
    }
    if (uploadedBytes.present) {
      map['uploaded_bytes'] = Variable<int>(uploadedBytes.value);
    }
    if (md5Hash.present) {
      map['md5_hash'] = Variable<String>(md5Hash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecordingsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('genreId: $genreId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('title: $title, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('format: $format, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('serverId: $serverId, ')
          ..write('gcsUrl: $gcsUrl, ')
          ..write('cleaningStatus: $cleaningStatus, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('registerId: $registerId, ')
          ..write('resumableSessionUri: $resumableSessionUri, ')
          ..write('uploadedBytes: $uploadedBytes, ')
          ..write('md5Hash: $md5Hash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalGenres extends Table with TableInfo<LocalGenres, LocalGenresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalGenres(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    icon,
    color,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_genres';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGenresData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGenresData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  LocalGenres createAlias(String alias) {
    return LocalGenres(attachedDatabase, alias);
  }
}

class LocalGenresData extends DataClass implements Insertable<LocalGenresData> {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int sortOrder;
  const LocalGenresData({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocalGenresCompanion toCompanion(bool nullToAbsent) {
    return LocalGenresCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortOrder: Value(sortOrder),
    );
  }

  factory LocalGenresData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGenresData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LocalGenresData copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? sortOrder,
  }) => LocalGenresData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalGenresData copyWithCompanion(LocalGenresCompanion data) {
    return LocalGenresData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalGenresData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, icon, color, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGenresData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder);
}

class LocalGenresCompanion extends UpdateCompanion<LocalGenresData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LocalGenresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalGenresCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LocalGenresData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalGenresCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? icon,
    Value<String?>? color,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LocalGenresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGenresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalSubcategories extends Table
    with TableInfo<LocalSubcategories, LocalSubcategoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalSubcategories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> genreId = GeneratedColumn<String>(
    'genre_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    genreId,
    name,
    description,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_subcategories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSubcategoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSubcategoriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      genreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  LocalSubcategories createAlias(String alias) {
    return LocalSubcategories(attachedDatabase, alias);
  }
}

class LocalSubcategoriesData extends DataClass
    implements Insertable<LocalSubcategoriesData> {
  final String id;
  final String genreId;
  final String name;
  final String? description;
  final int sortOrder;
  const LocalSubcategoriesData({
    required this.id,
    required this.genreId,
    required this.name,
    this.description,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genre_id'] = Variable<String>(genreId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocalSubcategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalSubcategoriesCompanion(
      id: Value(id),
      genreId: Value(genreId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sortOrder: Value(sortOrder),
    );
  }

  factory LocalSubcategoriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSubcategoriesData(
      id: serializer.fromJson<String>(json['id']),
      genreId: serializer.fromJson<String>(json['genreId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genreId': serializer.toJson<String>(genreId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LocalSubcategoriesData copyWith({
    String? id,
    String? genreId,
    String? name,
    Value<String?> description = const Value.absent(),
    int? sortOrder,
  }) => LocalSubcategoriesData(
    id: id ?? this.id,
    genreId: genreId ?? this.genreId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalSubcategoriesData copyWithCompanion(LocalSubcategoriesCompanion data) {
    return LocalSubcategoriesData(
      id: data.id.present ? data.id.value : this.id,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSubcategoriesData(')
          ..write('id: $id, ')
          ..write('genreId: $genreId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, genreId, name, description, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSubcategoriesData &&
          other.id == this.id &&
          other.genreId == this.genreId &&
          other.name == this.name &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder);
}

class LocalSubcategoriesCompanion
    extends UpdateCompanion<LocalSubcategoriesData> {
  final Value<String> id;
  final Value<String> genreId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LocalSubcategoriesCompanion({
    this.id = const Value.absent(),
    this.genreId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSubcategoriesCompanion.insert({
    required String id,
    required String genreId,
    required String name,
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       genreId = Value(genreId),
       name = Value(name);
  static Insertable<LocalSubcategoriesData> custom({
    Expression<String>? id,
    Expression<String>? genreId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genreId != null) 'genre_id': genreId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSubcategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? genreId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LocalSubcategoriesCompanion(
      id: id ?? this.id,
      genreId: genreId ?? this.genreId,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genreId.present) {
      map['genre_id'] = Variable<String>(genreId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSubcategoriesCompanion(')
          ..write('id: $id, ')
          ..write('genreId: $genreId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV4 extends GeneratedDatabase {
  DatabaseAtV4(QueryExecutor e) : super(e);
  late final LocalRecordings localRecordings = LocalRecordings(this);
  late final LocalGenres localGenres = LocalGenres(this);
  late final LocalSubcategories localSubcategories = LocalSubcategories(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localRecordings,
    localGenres,
    localSubcategories,
  ];
  @override
  int get schemaVersion => 4;
}
