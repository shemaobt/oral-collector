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
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
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
  late final GeneratedColumn<String> registerId = GeneratedColumn<String>(
    'register_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> secondaryGenreId = GeneratedColumn<String>(
    'secondary_genre_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> secondarySubcategoryId =
      GeneratedColumn<String>(
        'secondary_subcategory_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> secondaryRegisterId =
      GeneratedColumn<String>(
        'secondary_register_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> storytellerId = GeneratedColumn<String>(
    'storyteller_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  late final GeneratedColumn<String> splitFromId = GeneratedColumn<String>(
    'split_from_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> splitIndex = GeneratedColumn<int>(
    'split_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> splitSegmentCount = GeneratedColumn<int>(
    'split_segment_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    genreId,
    subcategoryId,
    title,
    description,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    registerId,
    secondaryGenreId,
    secondarySubcategoryId,
    secondaryRegisterId,
    storytellerId,
    userId,
    cleaningStatus,
    recordedAt,
    createdAt,
    retryCount,
    lastRetryAt,
    resumableSessionUri,
    uploadedBytes,
    md5Hash,
    splitFromId,
    splitIndex,
    splitSegmentCount,
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
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
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
      registerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register_id'],
      ),
      secondaryGenreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_genre_id'],
      ),
      secondarySubcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_subcategory_id'],
      ),
      secondaryRegisterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_register_id'],
      ),
      storytellerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storyteller_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
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
      splitFromId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_from_id'],
      ),
      splitIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_index'],
      ),
      splitSegmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_segment_count'],
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
  final String? description;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final String localFilePath;
  final String uploadStatus;
  final String? serverId;
  final String? gcsUrl;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final String? storytellerId;
  final String? userId;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? resumableSessionUri;
  final int uploadedBytes;
  final String? md5Hash;
  final String? splitFromId;
  final int? splitIndex;
  final int? splitSegmentCount;
  const LocalRecordingsData({
    required this.id,
    required this.projectId,
    required this.genreId,
    this.subcategoryId,
    this.title,
    this.description,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    required this.localFilePath,
    required this.uploadStatus,
    this.serverId,
    this.gcsUrl,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    this.storytellerId,
    this.userId,
    required this.cleaningStatus,
    required this.recordedAt,
    required this.createdAt,
    required this.retryCount,
    this.lastRetryAt,
    this.resumableSessionUri,
    required this.uploadedBytes,
    this.md5Hash,
    this.splitFromId,
    this.splitIndex,
    this.splitSegmentCount,
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
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
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
    if (!nullToAbsent || registerId != null) {
      map['register_id'] = Variable<String>(registerId);
    }
    if (!nullToAbsent || secondaryGenreId != null) {
      map['secondary_genre_id'] = Variable<String>(secondaryGenreId);
    }
    if (!nullToAbsent || secondarySubcategoryId != null) {
      map['secondary_subcategory_id'] = Variable<String>(
        secondarySubcategoryId,
      );
    }
    if (!nullToAbsent || secondaryRegisterId != null) {
      map['secondary_register_id'] = Variable<String>(secondaryRegisterId);
    }
    if (!nullToAbsent || storytellerId != null) {
      map['storyteller_id'] = Variable<String>(storytellerId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['cleaning_status'] = Variable<String>(cleaningStatus);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt);
    }
    if (!nullToAbsent || resumableSessionUri != null) {
      map['resumable_session_uri'] = Variable<String>(resumableSessionUri);
    }
    map['uploaded_bytes'] = Variable<int>(uploadedBytes);
    if (!nullToAbsent || md5Hash != null) {
      map['md5_hash'] = Variable<String>(md5Hash);
    }
    if (!nullToAbsent || splitFromId != null) {
      map['split_from_id'] = Variable<String>(splitFromId);
    }
    if (!nullToAbsent || splitIndex != null) {
      map['split_index'] = Variable<int>(splitIndex);
    }
    if (!nullToAbsent || splitSegmentCount != null) {
      map['split_segment_count'] = Variable<int>(splitSegmentCount);
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
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
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
      registerId: registerId == null && nullToAbsent
          ? const Value.absent()
          : Value(registerId),
      secondaryGenreId: secondaryGenreId == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryGenreId),
      secondarySubcategoryId: secondarySubcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(secondarySubcategoryId),
      secondaryRegisterId: secondaryRegisterId == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryRegisterId),
      storytellerId: storytellerId == null && nullToAbsent
          ? const Value.absent()
          : Value(storytellerId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      cleaningStatus: Value(cleaningStatus),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
      resumableSessionUri: resumableSessionUri == null && nullToAbsent
          ? const Value.absent()
          : Value(resumableSessionUri),
      uploadedBytes: Value(uploadedBytes),
      md5Hash: md5Hash == null && nullToAbsent
          ? const Value.absent()
          : Value(md5Hash),
      splitFromId: splitFromId == null && nullToAbsent
          ? const Value.absent()
          : Value(splitFromId),
      splitIndex: splitIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(splitIndex),
      splitSegmentCount: splitSegmentCount == null && nullToAbsent
          ? const Value.absent()
          : Value(splitSegmentCount),
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
      description: serializer.fromJson<String?>(json['description']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      format: serializer.fromJson<String>(json['format']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      gcsUrl: serializer.fromJson<String?>(json['gcsUrl']),
      registerId: serializer.fromJson<String?>(json['registerId']),
      secondaryGenreId: serializer.fromJson<String?>(json['secondaryGenreId']),
      secondarySubcategoryId: serializer.fromJson<String?>(
        json['secondarySubcategoryId'],
      ),
      secondaryRegisterId: serializer.fromJson<String?>(
        json['secondaryRegisterId'],
      ),
      storytellerId: serializer.fromJson<String?>(json['storytellerId']),
      userId: serializer.fromJson<String?>(json['userId']),
      cleaningStatus: serializer.fromJson<String>(json['cleaningStatus']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetryAt: serializer.fromJson<DateTime?>(json['lastRetryAt']),
      resumableSessionUri: serializer.fromJson<String?>(
        json['resumableSessionUri'],
      ),
      uploadedBytes: serializer.fromJson<int>(json['uploadedBytes']),
      md5Hash: serializer.fromJson<String?>(json['md5Hash']),
      splitFromId: serializer.fromJson<String?>(json['splitFromId']),
      splitIndex: serializer.fromJson<int?>(json['splitIndex']),
      splitSegmentCount: serializer.fromJson<int?>(json['splitSegmentCount']),
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
      'description': serializer.toJson<String?>(description),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'format': serializer.toJson<String>(format),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'serverId': serializer.toJson<String?>(serverId),
      'gcsUrl': serializer.toJson<String?>(gcsUrl),
      'registerId': serializer.toJson<String?>(registerId),
      'secondaryGenreId': serializer.toJson<String?>(secondaryGenreId),
      'secondarySubcategoryId': serializer.toJson<String?>(
        secondarySubcategoryId,
      ),
      'secondaryRegisterId': serializer.toJson<String?>(secondaryRegisterId),
      'storytellerId': serializer.toJson<String?>(storytellerId),
      'userId': serializer.toJson<String?>(userId),
      'cleaningStatus': serializer.toJson<String>(cleaningStatus),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetryAt': serializer.toJson<DateTime?>(lastRetryAt),
      'resumableSessionUri': serializer.toJson<String?>(resumableSessionUri),
      'uploadedBytes': serializer.toJson<int>(uploadedBytes),
      'md5Hash': serializer.toJson<String?>(md5Hash),
      'splitFromId': serializer.toJson<String?>(splitFromId),
      'splitIndex': serializer.toJson<int?>(splitIndex),
      'splitSegmentCount': serializer.toJson<int?>(splitSegmentCount),
    };
  }

  LocalRecordingsData copyWith({
    String? id,
    String? projectId,
    String? genreId,
    Value<String?> subcategoryId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    double? durationSeconds,
    int? fileSizeBytes,
    String? format,
    String? localFilePath,
    String? uploadStatus,
    Value<String?> serverId = const Value.absent(),
    Value<String?> gcsUrl = const Value.absent(),
    Value<String?> registerId = const Value.absent(),
    Value<String?> secondaryGenreId = const Value.absent(),
    Value<String?> secondarySubcategoryId = const Value.absent(),
    Value<String?> secondaryRegisterId = const Value.absent(),
    Value<String?> storytellerId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    String? cleaningStatus,
    DateTime? recordedAt,
    DateTime? createdAt,
    int? retryCount,
    Value<DateTime?> lastRetryAt = const Value.absent(),
    Value<String?> resumableSessionUri = const Value.absent(),
    int? uploadedBytes,
    Value<String?> md5Hash = const Value.absent(),
    Value<String?> splitFromId = const Value.absent(),
    Value<int?> splitIndex = const Value.absent(),
    Value<int?> splitSegmentCount = const Value.absent(),
  }) => LocalRecordingsData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    genreId: genreId ?? this.genreId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    format: format ?? this.format,
    localFilePath: localFilePath ?? this.localFilePath,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    gcsUrl: gcsUrl.present ? gcsUrl.value : this.gcsUrl,
    registerId: registerId.present ? registerId.value : this.registerId,
    secondaryGenreId: secondaryGenreId.present
        ? secondaryGenreId.value
        : this.secondaryGenreId,
    secondarySubcategoryId: secondarySubcategoryId.present
        ? secondarySubcategoryId.value
        : this.secondarySubcategoryId,
    secondaryRegisterId: secondaryRegisterId.present
        ? secondaryRegisterId.value
        : this.secondaryRegisterId,
    storytellerId: storytellerId.present
        ? storytellerId.value
        : this.storytellerId,
    userId: userId.present ? userId.value : this.userId,
    cleaningStatus: cleaningStatus ?? this.cleaningStatus,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
    resumableSessionUri: resumableSessionUri.present
        ? resumableSessionUri.value
        : this.resumableSessionUri,
    uploadedBytes: uploadedBytes ?? this.uploadedBytes,
    md5Hash: md5Hash.present ? md5Hash.value : this.md5Hash,
    splitFromId: splitFromId.present ? splitFromId.value : this.splitFromId,
    splitIndex: splitIndex.present ? splitIndex.value : this.splitIndex,
    splitSegmentCount: splitSegmentCount.present
        ? splitSegmentCount.value
        : this.splitSegmentCount,
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
      description: data.description.present
          ? data.description.value
          : this.description,
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
      registerId: data.registerId.present
          ? data.registerId.value
          : this.registerId,
      secondaryGenreId: data.secondaryGenreId.present
          ? data.secondaryGenreId.value
          : this.secondaryGenreId,
      secondarySubcategoryId: data.secondarySubcategoryId.present
          ? data.secondarySubcategoryId.value
          : this.secondarySubcategoryId,
      secondaryRegisterId: data.secondaryRegisterId.present
          ? data.secondaryRegisterId.value
          : this.secondaryRegisterId,
      storytellerId: data.storytellerId.present
          ? data.storytellerId.value
          : this.storytellerId,
      userId: data.userId.present ? data.userId.value : this.userId,
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
      resumableSessionUri: data.resumableSessionUri.present
          ? data.resumableSessionUri.value
          : this.resumableSessionUri,
      uploadedBytes: data.uploadedBytes.present
          ? data.uploadedBytes.value
          : this.uploadedBytes,
      md5Hash: data.md5Hash.present ? data.md5Hash.value : this.md5Hash,
      splitFromId: data.splitFromId.present
          ? data.splitFromId.value
          : this.splitFromId,
      splitIndex: data.splitIndex.present
          ? data.splitIndex.value
          : this.splitIndex,
      splitSegmentCount: data.splitSegmentCount.present
          ? data.splitSegmentCount.value
          : this.splitSegmentCount,
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
          ..write('description: $description, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('format: $format, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('serverId: $serverId, ')
          ..write('gcsUrl: $gcsUrl, ')
          ..write('registerId: $registerId, ')
          ..write('secondaryGenreId: $secondaryGenreId, ')
          ..write('secondarySubcategoryId: $secondarySubcategoryId, ')
          ..write('secondaryRegisterId: $secondaryRegisterId, ')
          ..write('storytellerId: $storytellerId, ')
          ..write('userId: $userId, ')
          ..write('cleaningStatus: $cleaningStatus, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('resumableSessionUri: $resumableSessionUri, ')
          ..write('uploadedBytes: $uploadedBytes, ')
          ..write('md5Hash: $md5Hash, ')
          ..write('splitFromId: $splitFromId, ')
          ..write('splitIndex: $splitIndex, ')
          ..write('splitSegmentCount: $splitSegmentCount')
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
    description,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    registerId,
    secondaryGenreId,
    secondarySubcategoryId,
    secondaryRegisterId,
    storytellerId,
    userId,
    cleaningStatus,
    recordedAt,
    createdAt,
    retryCount,
    lastRetryAt,
    resumableSessionUri,
    uploadedBytes,
    md5Hash,
    splitFromId,
    splitIndex,
    splitSegmentCount,
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
          other.description == this.description &&
          other.durationSeconds == this.durationSeconds &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.format == this.format &&
          other.localFilePath == this.localFilePath &&
          other.uploadStatus == this.uploadStatus &&
          other.serverId == this.serverId &&
          other.gcsUrl == this.gcsUrl &&
          other.registerId == this.registerId &&
          other.secondaryGenreId == this.secondaryGenreId &&
          other.secondarySubcategoryId == this.secondarySubcategoryId &&
          other.secondaryRegisterId == this.secondaryRegisterId &&
          other.storytellerId == this.storytellerId &&
          other.userId == this.userId &&
          other.cleaningStatus == this.cleaningStatus &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt &&
          other.resumableSessionUri == this.resumableSessionUri &&
          other.uploadedBytes == this.uploadedBytes &&
          other.md5Hash == this.md5Hash &&
          other.splitFromId == this.splitFromId &&
          other.splitIndex == this.splitIndex &&
          other.splitSegmentCount == this.splitSegmentCount);
}

class LocalRecordingsCompanion extends UpdateCompanion<LocalRecordingsData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> genreId;
  final Value<String?> subcategoryId;
  final Value<String?> title;
  final Value<String?> description;
  final Value<double> durationSeconds;
  final Value<int> fileSizeBytes;
  final Value<String> format;
  final Value<String> localFilePath;
  final Value<String> uploadStatus;
  final Value<String?> serverId;
  final Value<String?> gcsUrl;
  final Value<String?> registerId;
  final Value<String?> secondaryGenreId;
  final Value<String?> secondarySubcategoryId;
  final Value<String?> secondaryRegisterId;
  final Value<String?> storytellerId;
  final Value<String?> userId;
  final Value<String> cleaningStatus;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetryAt;
  final Value<String?> resumableSessionUri;
  final Value<int> uploadedBytes;
  final Value<String?> md5Hash;
  final Value<String?> splitFromId;
  final Value<int?> splitIndex;
  final Value<int?> splitSegmentCount;
  final Value<int> rowid;
  const LocalRecordingsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.genreId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.format = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.gcsUrl = const Value.absent(),
    this.registerId = const Value.absent(),
    this.secondaryGenreId = const Value.absent(),
    this.secondarySubcategoryId = const Value.absent(),
    this.secondaryRegisterId = const Value.absent(),
    this.storytellerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.cleaningStatus = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.resumableSessionUri = const Value.absent(),
    this.uploadedBytes = const Value.absent(),
    this.md5Hash = const Value.absent(),
    this.splitFromId = const Value.absent(),
    this.splitIndex = const Value.absent(),
    this.splitSegmentCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecordingsCompanion.insert({
    required String id,
    required String projectId,
    required String genreId,
    this.subcategoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.format = const Value.absent(),
    required String localFilePath,
    this.uploadStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.gcsUrl = const Value.absent(),
    this.registerId = const Value.absent(),
    this.secondaryGenreId = const Value.absent(),
    this.secondarySubcategoryId = const Value.absent(),
    this.secondaryRegisterId = const Value.absent(),
    this.storytellerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.cleaningStatus = const Value.absent(),
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.resumableSessionUri = const Value.absent(),
    this.uploadedBytes = const Value.absent(),
    this.md5Hash = const Value.absent(),
    this.splitFromId = const Value.absent(),
    this.splitIndex = const Value.absent(),
    this.splitSegmentCount = const Value.absent(),
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
    Expression<String>? description,
    Expression<double>? durationSeconds,
    Expression<int>? fileSizeBytes,
    Expression<String>? format,
    Expression<String>? localFilePath,
    Expression<String>? uploadStatus,
    Expression<String>? serverId,
    Expression<String>? gcsUrl,
    Expression<String>? registerId,
    Expression<String>? secondaryGenreId,
    Expression<String>? secondarySubcategoryId,
    Expression<String>? secondaryRegisterId,
    Expression<String>? storytellerId,
    Expression<String>? userId,
    Expression<String>? cleaningStatus,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetryAt,
    Expression<String>? resumableSessionUri,
    Expression<int>? uploadedBytes,
    Expression<String>? md5Hash,
    Expression<String>? splitFromId,
    Expression<int>? splitIndex,
    Expression<int>? splitSegmentCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (genreId != null) 'genre_id': genreId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (format != null) 'format': format,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (serverId != null) 'server_id': serverId,
      if (gcsUrl != null) 'gcs_url': gcsUrl,
      if (registerId != null) 'register_id': registerId,
      if (secondaryGenreId != null) 'secondary_genre_id': secondaryGenreId,
      if (secondarySubcategoryId != null)
        'secondary_subcategory_id': secondarySubcategoryId,
      if (secondaryRegisterId != null)
        'secondary_register_id': secondaryRegisterId,
      if (storytellerId != null) 'storyteller_id': storytellerId,
      if (userId != null) 'user_id': userId,
      if (cleaningStatus != null) 'cleaning_status': cleaningStatus,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
      if (resumableSessionUri != null)
        'resumable_session_uri': resumableSessionUri,
      if (uploadedBytes != null) 'uploaded_bytes': uploadedBytes,
      if (md5Hash != null) 'md5_hash': md5Hash,
      if (splitFromId != null) 'split_from_id': splitFromId,
      if (splitIndex != null) 'split_index': splitIndex,
      if (splitSegmentCount != null) 'split_segment_count': splitSegmentCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecordingsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? genreId,
    Value<String?>? subcategoryId,
    Value<String?>? title,
    Value<String?>? description,
    Value<double>? durationSeconds,
    Value<int>? fileSizeBytes,
    Value<String>? format,
    Value<String>? localFilePath,
    Value<String>? uploadStatus,
    Value<String?>? serverId,
    Value<String?>? gcsUrl,
    Value<String?>? registerId,
    Value<String?>? secondaryGenreId,
    Value<String?>? secondarySubcategoryId,
    Value<String?>? secondaryRegisterId,
    Value<String?>? storytellerId,
    Value<String?>? userId,
    Value<String>? cleaningStatus,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<DateTime?>? lastRetryAt,
    Value<String?>? resumableSessionUri,
    Value<int>? uploadedBytes,
    Value<String?>? md5Hash,
    Value<String?>? splitFromId,
    Value<int?>? splitIndex,
    Value<int?>? splitSegmentCount,
    Value<int>? rowid,
  }) {
    return LocalRecordingsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      genreId: genreId ?? this.genreId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      format: format ?? this.format,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      serverId: serverId ?? this.serverId,
      gcsUrl: gcsUrl ?? this.gcsUrl,
      registerId: registerId ?? this.registerId,
      secondaryGenreId: secondaryGenreId ?? this.secondaryGenreId,
      secondarySubcategoryId:
          secondarySubcategoryId ?? this.secondarySubcategoryId,
      secondaryRegisterId: secondaryRegisterId ?? this.secondaryRegisterId,
      storytellerId: storytellerId ?? this.storytellerId,
      userId: userId ?? this.userId,
      cleaningStatus: cleaningStatus ?? this.cleaningStatus,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      resumableSessionUri: resumableSessionUri ?? this.resumableSessionUri,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      md5Hash: md5Hash ?? this.md5Hash,
      splitFromId: splitFromId ?? this.splitFromId,
      splitIndex: splitIndex ?? this.splitIndex,
      splitSegmentCount: splitSegmentCount ?? this.splitSegmentCount,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
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
    if (registerId.present) {
      map['register_id'] = Variable<String>(registerId.value);
    }
    if (secondaryGenreId.present) {
      map['secondary_genre_id'] = Variable<String>(secondaryGenreId.value);
    }
    if (secondarySubcategoryId.present) {
      map['secondary_subcategory_id'] = Variable<String>(
        secondarySubcategoryId.value,
      );
    }
    if (secondaryRegisterId.present) {
      map['secondary_register_id'] = Variable<String>(
        secondaryRegisterId.value,
      );
    }
    if (storytellerId.present) {
      map['storyteller_id'] = Variable<String>(storytellerId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
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
    if (splitFromId.present) {
      map['split_from_id'] = Variable<String>(splitFromId.value);
    }
    if (splitIndex.present) {
      map['split_index'] = Variable<int>(splitIndex.value);
    }
    if (splitSegmentCount.present) {
      map['split_segment_count'] = Variable<int>(splitSegmentCount.value);
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
          ..write('description: $description, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('format: $format, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('serverId: $serverId, ')
          ..write('gcsUrl: $gcsUrl, ')
          ..write('registerId: $registerId, ')
          ..write('secondaryGenreId: $secondaryGenreId, ')
          ..write('secondarySubcategoryId: $secondarySubcategoryId, ')
          ..write('secondaryRegisterId: $secondaryRegisterId, ')
          ..write('storytellerId: $storytellerId, ')
          ..write('userId: $userId, ')
          ..write('cleaningStatus: $cleaningStatus, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('resumableSessionUri: $resumableSessionUri, ')
          ..write('uploadedBytes: $uploadedBytes, ')
          ..write('md5Hash: $md5Hash, ')
          ..write('splitFromId: $splitFromId, ')
          ..write('splitIndex: $splitIndex, ')
          ..write('splitSegmentCount: $splitSegmentCount, ')
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

class LocalStorytellers extends Table
    with TableInfo<LocalStorytellers, LocalStorytellersData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalStorytellers(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> dialect = GeneratedColumn<String>(
    'dialect',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> externalAcceptanceConfirmed =
      GeneratedColumn<bool>(
        'external_acceptance_confirmed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("external_acceptance_confirmed" IN (0, 1))',
        ),
        defaultValue: const CustomExpression('0'),
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
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'synced\''),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    name,
    sex,
    age,
    location,
    dialect,
    externalAcceptanceConfirmed,
    createdAt,
    updatedAt,
    serverId,
    syncStatus,
    retryCount,
    lastRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_storytellers';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStorytellersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStorytellersData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      dialect: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialect'],
      ),
      externalAcceptanceConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}external_acceptance_confirmed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_retry_at'],
      ),
    );
  }

  @override
  LocalStorytellers createAlias(String alias) {
    return LocalStorytellers(attachedDatabase, alias);
  }
}

class LocalStorytellersData extends DataClass
    implements Insertable<LocalStorytellersData> {
  final String id;
  final String projectId;
  final String name;
  final String sex;
  final int? age;
  final String? location;
  final String? dialect;
  final bool externalAcceptanceConfirmed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? serverId;
  final String syncStatus;
  final int retryCount;
  final DateTime? lastRetryAt;
  const LocalStorytellersData({
    required this.id,
    required this.projectId,
    required this.name,
    required this.sex,
    this.age,
    this.location,
    this.dialect,
    required this.externalAcceptanceConfirmed,
    required this.createdAt,
    this.updatedAt,
    this.serverId,
    required this.syncStatus,
    required this.retryCount,
    this.lastRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['sex'] = Variable<String>(sex);
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || dialect != null) {
      map['dialect'] = Variable<String>(dialect);
    }
    map['external_acceptance_confirmed'] = Variable<bool>(
      externalAcceptanceConfirmed,
    );
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt);
    }
    return map;
  }

  LocalStorytellersCompanion toCompanion(bool nullToAbsent) {
    return LocalStorytellersCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      sex: Value(sex),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      dialect: dialect == null && nullToAbsent
          ? const Value.absent()
          : Value(dialect),
      externalAcceptanceConfirmed: Value(externalAcceptanceConfirmed),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
    );
  }

  factory LocalStorytellersData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStorytellersData(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      sex: serializer.fromJson<String>(json['sex']),
      age: serializer.fromJson<int?>(json['age']),
      location: serializer.fromJson<String?>(json['location']),
      dialect: serializer.fromJson<String?>(json['dialect']),
      externalAcceptanceConfirmed: serializer.fromJson<bool>(
        json['externalAcceptanceConfirmed'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetryAt: serializer.fromJson<DateTime?>(json['lastRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'sex': serializer.toJson<String>(sex),
      'age': serializer.toJson<int?>(age),
      'location': serializer.toJson<String?>(location),
      'dialect': serializer.toJson<String?>(dialect),
      'externalAcceptanceConfirmed': serializer.toJson<bool>(
        externalAcceptanceConfirmed,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'serverId': serializer.toJson<String?>(serverId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetryAt': serializer.toJson<DateTime?>(lastRetryAt),
    };
  }

  LocalStorytellersData copyWith({
    String? id,
    String? projectId,
    String? name,
    String? sex,
    Value<int?> age = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> dialect = const Value.absent(),
    bool? externalAcceptanceConfirmed,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<String?> serverId = const Value.absent(),
    String? syncStatus,
    int? retryCount,
    Value<DateTime?> lastRetryAt = const Value.absent(),
  }) => LocalStorytellersData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    sex: sex ?? this.sex,
    age: age.present ? age.value : this.age,
    location: location.present ? location.value : this.location,
    dialect: dialect.present ? dialect.value : this.dialect,
    externalAcceptanceConfirmed:
        externalAcceptanceConfirmed ?? this.externalAcceptanceConfirmed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
    syncStatus: syncStatus ?? this.syncStatus,
    retryCount: retryCount ?? this.retryCount,
    lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
  );
  LocalStorytellersData copyWithCompanion(LocalStorytellersCompanion data) {
    return LocalStorytellersData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      sex: data.sex.present ? data.sex.value : this.sex,
      age: data.age.present ? data.age.value : this.age,
      location: data.location.present ? data.location.value : this.location,
      dialect: data.dialect.present ? data.dialect.value : this.dialect,
      externalAcceptanceConfirmed: data.externalAcceptanceConfirmed.present
          ? data.externalAcceptanceConfirmed.value
          : this.externalAcceptanceConfirmed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastRetryAt: data.lastRetryAt.present
          ? data.lastRetryAt.value
          : this.lastRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStorytellersData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('location: $location, ')
          ..write('dialect: $dialect, ')
          ..write('externalAcceptanceConfirmed: $externalAcceptanceConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    name,
    sex,
    age,
    location,
    dialect,
    externalAcceptanceConfirmed,
    createdAt,
    updatedAt,
    serverId,
    syncStatus,
    retryCount,
    lastRetryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStorytellersData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.sex == this.sex &&
          other.age == this.age &&
          other.location == this.location &&
          other.dialect == this.dialect &&
          other.externalAcceptanceConfirmed ==
              this.externalAcceptanceConfirmed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverId == this.serverId &&
          other.syncStatus == this.syncStatus &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt);
}

class LocalStorytellersCompanion
    extends UpdateCompanion<LocalStorytellersData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> sex;
  final Value<int?> age;
  final Value<String?> location;
  final Value<String?> dialect;
  final Value<bool> externalAcceptanceConfirmed;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String?> serverId;
  final Value<String> syncStatus;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetryAt;
  final Value<int> rowid;
  const LocalStorytellersCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.sex = const Value.absent(),
    this.age = const Value.absent(),
    this.location = const Value.absent(),
    this.dialect = const Value.absent(),
    this.externalAcceptanceConfirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStorytellersCompanion.insert({
    required String id,
    required String projectId,
    required String name,
    required String sex,
    this.age = const Value.absent(),
    this.location = const Value.absent(),
    this.dialect = const Value.absent(),
    this.externalAcceptanceConfirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       sex = Value(sex);
  static Insertable<LocalStorytellersData> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? sex,
    Expression<int>? age,
    Expression<String>? location,
    Expression<String>? dialect,
    Expression<bool>? externalAcceptanceConfirmed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? serverId,
    Expression<String>? syncStatus,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (sex != null) 'sex': sex,
      if (age != null) 'age': age,
      if (location != null) 'location': location,
      if (dialect != null) 'dialect': dialect,
      if (externalAcceptanceConfirmed != null)
        'external_acceptance_confirmed': externalAcceptanceConfirmed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverId != null) 'server_id': serverId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStorytellersCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? sex,
    Value<int?>? age,
    Value<String?>? location,
    Value<String?>? dialect,
    Value<bool>? externalAcceptanceConfirmed,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<String?>? serverId,
    Value<String>? syncStatus,
    Value<int>? retryCount,
    Value<DateTime?>? lastRetryAt,
    Value<int>? rowid,
  }) {
    return LocalStorytellersCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      location: location ?? this.location,
      dialect: dialect ?? this.dialect,
      externalAcceptanceConfirmed:
          externalAcceptanceConfirmed ?? this.externalAcceptanceConfirmed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (dialect.present) {
      map['dialect'] = Variable<String>(dialect.value);
    }
    if (externalAcceptanceConfirmed.present) {
      map['external_acceptance_confirmed'] = Variable<bool>(
        externalAcceptanceConfirmed.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastRetryAt.present) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStorytellersCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('location: $location, ')
          ..write('dialect: $dialect, ')
          ..write('externalAcceptanceConfirmed: $externalAcceptanceConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RecordingSessions extends Table
    with TableInfo<RecordingSessions, RecordingSessionsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecordingSessions(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> registerId = GeneratedColumn<String>(
    'register_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> storytellerId = GeneratedColumn<String>(
    'storyteller_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> lastCheckpointAt =
      GeneratedColumn<DateTime>(
        'last_checkpoint_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'active\''),
  );
  late final GeneratedColumn<double> totalDurationSeconds =
      GeneratedColumn<double>(
        'total_duration_seconds',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const CustomExpression('0.0'),
      );
  late final GeneratedColumn<String> segmentPathsJson = GeneratedColumn<String>(
    'segment_paths_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'[]\''),
  );
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
    'is_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paused" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> lastSegmentIndex = GeneratedColumn<int>(
    'last_segment_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('-1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    genreId,
    subcategoryId,
    registerId,
    storytellerId,
    userId,
    startedAt,
    lastCheckpointAt,
    status,
    totalDurationSeconds,
    segmentPathsJson,
    isPaused,
    lastSegmentIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_sessions';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingSessionsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingSessionsData(
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
      registerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register_id'],
      ),
      storytellerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storyteller_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      lastCheckpointAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checkpoint_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_duration_seconds'],
      )!,
      segmentPathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_paths_json'],
      )!,
      isPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paused'],
      )!,
      lastSegmentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_segment_index'],
      )!,
    );
  }

  @override
  RecordingSessions createAlias(String alias) {
    return RecordingSessions(attachedDatabase, alias);
  }
}

class RecordingSessionsData extends DataClass
    implements Insertable<RecordingSessionsData> {
  final String id;
  final String projectId;
  final String genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? storytellerId;
  final String? userId;
  final DateTime startedAt;
  final DateTime? lastCheckpointAt;
  final String status;
  final double totalDurationSeconds;
  final String segmentPathsJson;
  final bool isPaused;
  final int lastSegmentIndex;
  const RecordingSessionsData({
    required this.id,
    required this.projectId,
    required this.genreId,
    this.subcategoryId,
    this.registerId,
    this.storytellerId,
    this.userId,
    required this.startedAt,
    this.lastCheckpointAt,
    required this.status,
    required this.totalDurationSeconds,
    required this.segmentPathsJson,
    required this.isPaused,
    required this.lastSegmentIndex,
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
    if (!nullToAbsent || registerId != null) {
      map['register_id'] = Variable<String>(registerId);
    }
    if (!nullToAbsent || storytellerId != null) {
      map['storyteller_id'] = Variable<String>(storytellerId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || lastCheckpointAt != null) {
      map['last_checkpoint_at'] = Variable<DateTime>(lastCheckpointAt);
    }
    map['status'] = Variable<String>(status);
    map['total_duration_seconds'] = Variable<double>(totalDurationSeconds);
    map['segment_paths_json'] = Variable<String>(segmentPathsJson);
    map['is_paused'] = Variable<bool>(isPaused);
    map['last_segment_index'] = Variable<int>(lastSegmentIndex);
    return map;
  }

  RecordingSessionsCompanion toCompanion(bool nullToAbsent) {
    return RecordingSessionsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      genreId: Value(genreId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      registerId: registerId == null && nullToAbsent
          ? const Value.absent()
          : Value(registerId),
      storytellerId: storytellerId == null && nullToAbsent
          ? const Value.absent()
          : Value(storytellerId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      startedAt: Value(startedAt),
      lastCheckpointAt: lastCheckpointAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckpointAt),
      status: Value(status),
      totalDurationSeconds: Value(totalDurationSeconds),
      segmentPathsJson: Value(segmentPathsJson),
      isPaused: Value(isPaused),
      lastSegmentIndex: Value(lastSegmentIndex),
    );
  }

  factory RecordingSessionsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingSessionsData(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      genreId: serializer.fromJson<String>(json['genreId']),
      subcategoryId: serializer.fromJson<String?>(json['subcategoryId']),
      registerId: serializer.fromJson<String?>(json['registerId']),
      storytellerId: serializer.fromJson<String?>(json['storytellerId']),
      userId: serializer.fromJson<String?>(json['userId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastCheckpointAt: serializer.fromJson<DateTime?>(
        json['lastCheckpointAt'],
      ),
      status: serializer.fromJson<String>(json['status']),
      totalDurationSeconds: serializer.fromJson<double>(
        json['totalDurationSeconds'],
      ),
      segmentPathsJson: serializer.fromJson<String>(json['segmentPathsJson']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
      lastSegmentIndex: serializer.fromJson<int>(json['lastSegmentIndex']),
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
      'registerId': serializer.toJson<String?>(registerId),
      'storytellerId': serializer.toJson<String?>(storytellerId),
      'userId': serializer.toJson<String?>(userId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastCheckpointAt': serializer.toJson<DateTime?>(lastCheckpointAt),
      'status': serializer.toJson<String>(status),
      'totalDurationSeconds': serializer.toJson<double>(totalDurationSeconds),
      'segmentPathsJson': serializer.toJson<String>(segmentPathsJson),
      'isPaused': serializer.toJson<bool>(isPaused),
      'lastSegmentIndex': serializer.toJson<int>(lastSegmentIndex),
    };
  }

  RecordingSessionsData copyWith({
    String? id,
    String? projectId,
    String? genreId,
    Value<String?> subcategoryId = const Value.absent(),
    Value<String?> registerId = const Value.absent(),
    Value<String?> storytellerId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> lastCheckpointAt = const Value.absent(),
    String? status,
    double? totalDurationSeconds,
    String? segmentPathsJson,
    bool? isPaused,
    int? lastSegmentIndex,
  }) => RecordingSessionsData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    genreId: genreId ?? this.genreId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    registerId: registerId.present ? registerId.value : this.registerId,
    storytellerId: storytellerId.present
        ? storytellerId.value
        : this.storytellerId,
    userId: userId.present ? userId.value : this.userId,
    startedAt: startedAt ?? this.startedAt,
    lastCheckpointAt: lastCheckpointAt.present
        ? lastCheckpointAt.value
        : this.lastCheckpointAt,
    status: status ?? this.status,
    totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
    segmentPathsJson: segmentPathsJson ?? this.segmentPathsJson,
    isPaused: isPaused ?? this.isPaused,
    lastSegmentIndex: lastSegmentIndex ?? this.lastSegmentIndex,
  );
  RecordingSessionsData copyWithCompanion(RecordingSessionsCompanion data) {
    return RecordingSessionsData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      registerId: data.registerId.present
          ? data.registerId.value
          : this.registerId,
      storytellerId: data.storytellerId.present
          ? data.storytellerId.value
          : this.storytellerId,
      userId: data.userId.present ? data.userId.value : this.userId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastCheckpointAt: data.lastCheckpointAt.present
          ? data.lastCheckpointAt.value
          : this.lastCheckpointAt,
      status: data.status.present ? data.status.value : this.status,
      totalDurationSeconds: data.totalDurationSeconds.present
          ? data.totalDurationSeconds.value
          : this.totalDurationSeconds,
      segmentPathsJson: data.segmentPathsJson.present
          ? data.segmentPathsJson.value
          : this.segmentPathsJson,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
      lastSegmentIndex: data.lastSegmentIndex.present
          ? data.lastSegmentIndex.value
          : this.lastSegmentIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingSessionsData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('genreId: $genreId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('registerId: $registerId, ')
          ..write('storytellerId: $storytellerId, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastCheckpointAt: $lastCheckpointAt, ')
          ..write('status: $status, ')
          ..write('totalDurationSeconds: $totalDurationSeconds, ')
          ..write('segmentPathsJson: $segmentPathsJson, ')
          ..write('isPaused: $isPaused, ')
          ..write('lastSegmentIndex: $lastSegmentIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    genreId,
    subcategoryId,
    registerId,
    storytellerId,
    userId,
    startedAt,
    lastCheckpointAt,
    status,
    totalDurationSeconds,
    segmentPathsJson,
    isPaused,
    lastSegmentIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingSessionsData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.genreId == this.genreId &&
          other.subcategoryId == this.subcategoryId &&
          other.registerId == this.registerId &&
          other.storytellerId == this.storytellerId &&
          other.userId == this.userId &&
          other.startedAt == this.startedAt &&
          other.lastCheckpointAt == this.lastCheckpointAt &&
          other.status == this.status &&
          other.totalDurationSeconds == this.totalDurationSeconds &&
          other.segmentPathsJson == this.segmentPathsJson &&
          other.isPaused == this.isPaused &&
          other.lastSegmentIndex == this.lastSegmentIndex);
}

class RecordingSessionsCompanion
    extends UpdateCompanion<RecordingSessionsData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> genreId;
  final Value<String?> subcategoryId;
  final Value<String?> registerId;
  final Value<String?> storytellerId;
  final Value<String?> userId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> lastCheckpointAt;
  final Value<String> status;
  final Value<double> totalDurationSeconds;
  final Value<String> segmentPathsJson;
  final Value<bool> isPaused;
  final Value<int> lastSegmentIndex;
  final Value<int> rowid;
  const RecordingSessionsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.genreId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.registerId = const Value.absent(),
    this.storytellerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastCheckpointAt = const Value.absent(),
    this.status = const Value.absent(),
    this.totalDurationSeconds = const Value.absent(),
    this.segmentPathsJson = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.lastSegmentIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordingSessionsCompanion.insert({
    required String id,
    required String projectId,
    required String genreId,
    this.subcategoryId = const Value.absent(),
    this.registerId = const Value.absent(),
    this.storytellerId = const Value.absent(),
    this.userId = const Value.absent(),
    required DateTime startedAt,
    this.lastCheckpointAt = const Value.absent(),
    this.status = const Value.absent(),
    this.totalDurationSeconds = const Value.absent(),
    this.segmentPathsJson = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.lastSegmentIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       genreId = Value(genreId),
       startedAt = Value(startedAt);
  static Insertable<RecordingSessionsData> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? genreId,
    Expression<String>? subcategoryId,
    Expression<String>? registerId,
    Expression<String>? storytellerId,
    Expression<String>? userId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastCheckpointAt,
    Expression<String>? status,
    Expression<double>? totalDurationSeconds,
    Expression<String>? segmentPathsJson,
    Expression<bool>? isPaused,
    Expression<int>? lastSegmentIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (genreId != null) 'genre_id': genreId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (registerId != null) 'register_id': registerId,
      if (storytellerId != null) 'storyteller_id': storytellerId,
      if (userId != null) 'user_id': userId,
      if (startedAt != null) 'started_at': startedAt,
      if (lastCheckpointAt != null) 'last_checkpoint_at': lastCheckpointAt,
      if (status != null) 'status': status,
      if (totalDurationSeconds != null)
        'total_duration_seconds': totalDurationSeconds,
      if (segmentPathsJson != null) 'segment_paths_json': segmentPathsJson,
      if (isPaused != null) 'is_paused': isPaused,
      if (lastSegmentIndex != null) 'last_segment_index': lastSegmentIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? genreId,
    Value<String?>? subcategoryId,
    Value<String?>? registerId,
    Value<String?>? storytellerId,
    Value<String?>? userId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? lastCheckpointAt,
    Value<String>? status,
    Value<double>? totalDurationSeconds,
    Value<String>? segmentPathsJson,
    Value<bool>? isPaused,
    Value<int>? lastSegmentIndex,
    Value<int>? rowid,
  }) {
    return RecordingSessionsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      genreId: genreId ?? this.genreId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      registerId: registerId ?? this.registerId,
      storytellerId: storytellerId ?? this.storytellerId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      lastCheckpointAt: lastCheckpointAt ?? this.lastCheckpointAt,
      status: status ?? this.status,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      segmentPathsJson: segmentPathsJson ?? this.segmentPathsJson,
      isPaused: isPaused ?? this.isPaused,
      lastSegmentIndex: lastSegmentIndex ?? this.lastSegmentIndex,
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
    if (registerId.present) {
      map['register_id'] = Variable<String>(registerId.value);
    }
    if (storytellerId.present) {
      map['storyteller_id'] = Variable<String>(storytellerId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastCheckpointAt.present) {
      map['last_checkpoint_at'] = Variable<DateTime>(lastCheckpointAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalDurationSeconds.present) {
      map['total_duration_seconds'] = Variable<double>(
        totalDurationSeconds.value,
      );
    }
    if (segmentPathsJson.present) {
      map['segment_paths_json'] = Variable<String>(segmentPathsJson.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (lastSegmentIndex.present) {
      map['last_segment_index'] = Variable<int>(lastSegmentIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('genreId: $genreId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('registerId: $registerId, ')
          ..write('storytellerId: $storytellerId, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastCheckpointAt: $lastCheckpointAt, ')
          ..write('status: $status, ')
          ..write('totalDurationSeconds: $totalDurationSeconds, ')
          ..write('segmentPathsJson: $segmentPathsJson, ')
          ..write('isPaused: $isPaused, ')
          ..write('lastSegmentIndex: $lastSegmentIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV10 extends GeneratedDatabase {
  DatabaseAtV10(QueryExecutor e) : super(e);
  late final LocalRecordings localRecordings = LocalRecordings(this);
  late final LocalGenres localGenres = LocalGenres(this);
  late final LocalSubcategories localSubcategories = LocalSubcategories(this);
  late final LocalStorytellers localStorytellers = LocalStorytellers(this);
  late final RecordingSessions recordingSessions = RecordingSessions(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localRecordings,
    localGenres,
    localSubcategories,
    localStorytellers,
    recordingSessions,
  ];
  @override
  int get schemaVersion => 10;
}
