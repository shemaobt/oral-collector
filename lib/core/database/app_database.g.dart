// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalRecordingsTable extends LocalRecordings
    with TableInfo<$LocalRecordingsTable, LocalRecording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreIdMeta = const VerificationMeta(
    'genreId',
  );
  @override
  late final GeneratedColumn<String> genreId = GeneratedColumn<String>(
    'genre_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subcategoryIdMeta = const VerificationMeta(
    'subcategoryId',
  );
  @override
  late final GeneratedColumn<String> subcategoryId = GeneratedColumn<String>(
    'subcategory_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('m4a'),
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadStatusMeta = const VerificationMeta(
    'uploadStatus',
  );
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gcsUrlMeta = const VerificationMeta('gcsUrl');
  @override
  late final GeneratedColumn<String> gcsUrl = GeneratedColumn<String>(
    'gcs_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registerIdMeta = const VerificationMeta(
    'registerId',
  );
  @override
  late final GeneratedColumn<String> registerId = GeneratedColumn<String>(
    'register_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storytellerIdMeta = const VerificationMeta(
    'storytellerId',
  );
  @override
  late final GeneratedColumn<String> storytellerId = GeneratedColumn<String>(
    'storyteller_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cleaningStatusMeta = const VerificationMeta(
    'cleaningStatus',
  );
  @override
  late final GeneratedColumn<String> cleaningStatus = GeneratedColumn<String>(
    'cleaning_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastRetryAtMeta = const VerificationMeta(
    'lastRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRetryAt = GeneratedColumn<DateTime>(
    'last_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumableSessionUriMeta =
      const VerificationMeta('resumableSessionUri');
  @override
  late final GeneratedColumn<String> resumableSessionUri =
      GeneratedColumn<String>(
        'resumable_session_uri',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _uploadedBytesMeta = const VerificationMeta(
    'uploadedBytes',
  );
  @override
  late final GeneratedColumn<int> uploadedBytes = GeneratedColumn<int>(
    'uploaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _md5HashMeta = const VerificationMeta(
    'md5Hash',
  );
  @override
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
    description,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    registerId,
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('genre_id')) {
      context.handle(
        _genreIdMeta,
        genreId.isAcceptableOrUnknown(data['genre_id']!, _genreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_genreIdMeta);
    }
    if (data.containsKey('subcategory_id')) {
      context.handle(
        _subcategoryIdMeta,
        subcategoryId.isAcceptableOrUnknown(
          data['subcategory_id']!,
          _subcategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('upload_status')) {
      context.handle(
        _uploadStatusMeta,
        uploadStatus.isAcceptableOrUnknown(
          data['upload_status']!,
          _uploadStatusMeta,
        ),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('gcs_url')) {
      context.handle(
        _gcsUrlMeta,
        gcsUrl.isAcceptableOrUnknown(data['gcs_url']!, _gcsUrlMeta),
      );
    }
    if (data.containsKey('register_id')) {
      context.handle(
        _registerIdMeta,
        registerId.isAcceptableOrUnknown(data['register_id']!, _registerIdMeta),
      );
    }
    if (data.containsKey('storyteller_id')) {
      context.handle(
        _storytellerIdMeta,
        storytellerId.isAcceptableOrUnknown(
          data['storyteller_id']!,
          _storytellerIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('cleaning_status')) {
      context.handle(
        _cleaningStatusMeta,
        cleaningStatus.isAcceptableOrUnknown(
          data['cleaning_status']!,
          _cleaningStatusMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_retry_at')) {
      context.handle(
        _lastRetryAtMeta,
        lastRetryAt.isAcceptableOrUnknown(
          data['last_retry_at']!,
          _lastRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('resumable_session_uri')) {
      context.handle(
        _resumableSessionUriMeta,
        resumableSessionUri.isAcceptableOrUnknown(
          data['resumable_session_uri']!,
          _resumableSessionUriMeta,
        ),
      );
    }
    if (data.containsKey('uploaded_bytes')) {
      context.handle(
        _uploadedBytesMeta,
        uploadedBytes.isAcceptableOrUnknown(
          data['uploaded_bytes']!,
          _uploadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('md5_hash')) {
      context.handle(
        _md5HashMeta,
        md5Hash.isAcceptableOrUnknown(data['md5_hash']!, _md5HashMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalRecording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecording(
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
    );
  }

  @override
  $LocalRecordingsTable createAlias(String alias) {
    return $LocalRecordingsTable(attachedDatabase, alias);
  }
}

class LocalRecording extends DataClass implements Insertable<LocalRecording> {
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
  const LocalRecording({
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
    );
  }

  factory LocalRecording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecording(
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
    };
  }

  LocalRecording copyWith({
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
  }) => LocalRecording(
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
  );
  LocalRecording copyWithCompanion(LocalRecordingsCompanion data) {
    return LocalRecording(
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecording(')
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
          ..write('storytellerId: $storytellerId, ')
          ..write('userId: $userId, ')
          ..write('cleaningStatus: $cleaningStatus, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt, ')
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
    description,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    registerId,
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
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecording &&
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
          other.storytellerId == this.storytellerId &&
          other.userId == this.userId &&
          other.cleaningStatus == this.cleaningStatus &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt &&
          other.resumableSessionUri == this.resumableSessionUri &&
          other.uploadedBytes == this.uploadedBytes &&
          other.md5Hash == this.md5Hash);
}

class LocalRecordingsCompanion extends UpdateCompanion<LocalRecording> {
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
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       genreId = Value(genreId),
       localFilePath = Value(localFilePath),
       recordedAt = Value(recordedAt);
  static Insertable<LocalRecording> custom({
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalGenresTable extends LocalGenres
    with TableInfo<$LocalGenresTable, LocalGenre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  VerificationContext validateIntegrity(
    Insertable<LocalGenre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGenre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGenre(
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
  $LocalGenresTable createAlias(String alias) {
    return $LocalGenresTable(attachedDatabase, alias);
  }
}

class LocalGenre extends DataClass implements Insertable<LocalGenre> {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int sortOrder;
  const LocalGenre({
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

  factory LocalGenre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGenre(
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

  LocalGenre copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? sortOrder,
  }) => LocalGenre(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalGenre copyWithCompanion(LocalGenresCompanion data) {
    return LocalGenre(
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
    return (StringBuffer('LocalGenre(')
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
      (other is LocalGenre &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder);
}

class LocalGenresCompanion extends UpdateCompanion<LocalGenre> {
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
  static Insertable<LocalGenre> custom({
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

class $LocalSubcategoriesTable extends LocalSubcategories
    with TableInfo<$LocalSubcategoriesTable, LocalSubcategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSubcategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreIdMeta = const VerificationMeta(
    'genreId',
  );
  @override
  late final GeneratedColumn<String> genreId = GeneratedColumn<String>(
    'genre_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  VerificationContext validateIntegrity(
    Insertable<LocalSubcategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genre_id')) {
      context.handle(
        _genreIdMeta,
        genreId.isAcceptableOrUnknown(data['genre_id']!, _genreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_genreIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSubcategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSubcategory(
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
  $LocalSubcategoriesTable createAlias(String alias) {
    return $LocalSubcategoriesTable(attachedDatabase, alias);
  }
}

class LocalSubcategory extends DataClass
    implements Insertable<LocalSubcategory> {
  final String id;
  final String genreId;
  final String name;
  final String? description;
  final int sortOrder;
  const LocalSubcategory({
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

  factory LocalSubcategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSubcategory(
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

  LocalSubcategory copyWith({
    String? id,
    String? genreId,
    String? name,
    Value<String?> description = const Value.absent(),
    int? sortOrder,
  }) => LocalSubcategory(
    id: id ?? this.id,
    genreId: genreId ?? this.genreId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalSubcategory copyWithCompanion(LocalSubcategoriesCompanion data) {
    return LocalSubcategory(
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
    return (StringBuffer('LocalSubcategory(')
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
      (other is LocalSubcategory &&
          other.id == this.id &&
          other.genreId == this.genreId &&
          other.name == this.name &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder);
}

class LocalSubcategoriesCompanion extends UpdateCompanion<LocalSubcategory> {
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
  static Insertable<LocalSubcategory> custom({
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

class $LocalStorytellersTable extends LocalStorytellers
    with TableInfo<$LocalStorytellersTable, LocalStoryteller> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStorytellersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dialectMeta = const VerificationMeta(
    'dialect',
  );
  @override
  late final GeneratedColumn<String> dialect = GeneratedColumn<String>(
    'dialect',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalAcceptanceConfirmedMeta =
      const VerificationMeta('externalAcceptanceConfirmed');
  @override
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
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_storytellers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStoryteller> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('dialect')) {
      context.handle(
        _dialectMeta,
        dialect.isAcceptableOrUnknown(data['dialect']!, _dialectMeta),
      );
    }
    if (data.containsKey('external_acceptance_confirmed')) {
      context.handle(
        _externalAcceptanceConfirmedMeta,
        externalAcceptanceConfirmed.isAcceptableOrUnknown(
          data['external_acceptance_confirmed']!,
          _externalAcceptanceConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStoryteller map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStoryteller(
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
    );
  }

  @override
  $LocalStorytellersTable createAlias(String alias) {
    return $LocalStorytellersTable(attachedDatabase, alias);
  }
}

class LocalStoryteller extends DataClass
    implements Insertable<LocalStoryteller> {
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
  const LocalStoryteller({
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
    );
  }

  factory LocalStoryteller.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStoryteller(
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
    };
  }

  LocalStoryteller copyWith({
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
  }) => LocalStoryteller(
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
  );
  LocalStoryteller copyWithCompanion(LocalStorytellersCompanion data) {
    return LocalStoryteller(
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStoryteller(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('location: $location, ')
          ..write('dialect: $dialect, ')
          ..write('externalAcceptanceConfirmed: $externalAcceptanceConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStoryteller &&
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
          other.updatedAt == this.updatedAt);
}

class LocalStorytellersCompanion extends UpdateCompanion<LocalStoryteller> {
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
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       sex = Value(sex);
  static Insertable<LocalStoryteller> custom({
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalRecordingsTable localRecordings = $LocalRecordingsTable(
    this,
  );
  late final $LocalGenresTable localGenres = $LocalGenresTable(this);
  late final $LocalSubcategoriesTable localSubcategories =
      $LocalSubcategoriesTable(this);
  late final $LocalStorytellersTable localStorytellers =
      $LocalStorytellersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localRecordings,
    localGenres,
    localSubcategories,
    localStorytellers,
  ];
}

typedef $$LocalRecordingsTableCreateCompanionBuilder =
    LocalRecordingsCompanion Function({
      required String id,
      required String projectId,
      required String genreId,
      Value<String?> subcategoryId,
      Value<String?> title,
      Value<String?> description,
      Value<double> durationSeconds,
      Value<int> fileSizeBytes,
      Value<String> format,
      required String localFilePath,
      Value<String> uploadStatus,
      Value<String?> serverId,
      Value<String?> gcsUrl,
      Value<String?> registerId,
      Value<String?> storytellerId,
      Value<String?> userId,
      Value<String> cleaningStatus,
      required DateTime recordedAt,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<DateTime?> lastRetryAt,
      Value<String?> resumableSessionUri,
      Value<int> uploadedBytes,
      Value<String?> md5Hash,
      Value<int> rowid,
    });
typedef $$LocalRecordingsTableUpdateCompanionBuilder =
    LocalRecordingsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> genreId,
      Value<String?> subcategoryId,
      Value<String?> title,
      Value<String?> description,
      Value<double> durationSeconds,
      Value<int> fileSizeBytes,
      Value<String> format,
      Value<String> localFilePath,
      Value<String> uploadStatus,
      Value<String?> serverId,
      Value<String?> gcsUrl,
      Value<String?> registerId,
      Value<String?> storytellerId,
      Value<String?> userId,
      Value<String> cleaningStatus,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<DateTime?> lastRetryAt,
      Value<String?> resumableSessionUri,
      Value<int> uploadedBytes,
      Value<String?> md5Hash,
      Value<int> rowid,
    });

class $$LocalRecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRecordingsTable> {
  $$LocalRecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gcsUrl => $composableBuilder(
    column: $table.gcsUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registerId => $composableBuilder(
    column: $table.registerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storytellerId => $composableBuilder(
    column: $table.storytellerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleaningStatus => $composableBuilder(
    column: $table.cleaningStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumableSessionUri => $composableBuilder(
    column: $table.resumableSessionUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uploadedBytes => $composableBuilder(
    column: $table.uploadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get md5Hash => $composableBuilder(
    column: $table.md5Hash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRecordingsTable> {
  $$LocalRecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gcsUrl => $composableBuilder(
    column: $table.gcsUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registerId => $composableBuilder(
    column: $table.registerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storytellerId => $composableBuilder(
    column: $table.storytellerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleaningStatus => $composableBuilder(
    column: $table.cleaningStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumableSessionUri => $composableBuilder(
    column: $table.resumableSessionUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadedBytes => $composableBuilder(
    column: $table.uploadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get md5Hash => $composableBuilder(
    column: $table.md5Hash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRecordingsTable> {
  $$LocalRecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get genreId =>
      $composableBuilder(column: $table.genreId, builder: (column) => column);

  GeneratedColumn<String> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get gcsUrl =>
      $composableBuilder(column: $table.gcsUrl, builder: (column) => column);

  GeneratedColumn<String> get registerId => $composableBuilder(
    column: $table.registerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storytellerId => $composableBuilder(
    column: $table.storytellerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get cleaningStatus => $composableBuilder(
    column: $table.cleaningStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumableSessionUri => $composableBuilder(
    column: $table.resumableSessionUri,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uploadedBytes => $composableBuilder(
    column: $table.uploadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get md5Hash =>
      $composableBuilder(column: $table.md5Hash, builder: (column) => column);
}

class $$LocalRecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRecordingsTable,
          LocalRecording,
          $$LocalRecordingsTableFilterComposer,
          $$LocalRecordingsTableOrderingComposer,
          $$LocalRecordingsTableAnnotationComposer,
          $$LocalRecordingsTableCreateCompanionBuilder,
          $$LocalRecordingsTableUpdateCompanionBuilder,
          (
            LocalRecording,
            BaseReferences<
              _$AppDatabase,
              $LocalRecordingsTable,
              LocalRecording
            >,
          ),
          LocalRecording,
          PrefetchHooks Function()
        > {
  $$LocalRecordingsTableTableManager(
    _$AppDatabase db,
    $LocalRecordingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> genreId = const Value.absent(),
                Value<String?> subcategoryId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> durationSeconds = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> gcsUrl = const Value.absent(),
                Value<String?> registerId = const Value.absent(),
                Value<String?> storytellerId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> cleaningStatus = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastRetryAt = const Value.absent(),
                Value<String?> resumableSessionUri = const Value.absent(),
                Value<int> uploadedBytes = const Value.absent(),
                Value<String?> md5Hash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordingsCompanion(
                id: id,
                projectId: projectId,
                genreId: genreId,
                subcategoryId: subcategoryId,
                title: title,
                description: description,
                durationSeconds: durationSeconds,
                fileSizeBytes: fileSizeBytes,
                format: format,
                localFilePath: localFilePath,
                uploadStatus: uploadStatus,
                serverId: serverId,
                gcsUrl: gcsUrl,
                registerId: registerId,
                storytellerId: storytellerId,
                userId: userId,
                cleaningStatus: cleaningStatus,
                recordedAt: recordedAt,
                createdAt: createdAt,
                retryCount: retryCount,
                lastRetryAt: lastRetryAt,
                resumableSessionUri: resumableSessionUri,
                uploadedBytes: uploadedBytes,
                md5Hash: md5Hash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String genreId,
                Value<String?> subcategoryId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> durationSeconds = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String> format = const Value.absent(),
                required String localFilePath,
                Value<String> uploadStatus = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> gcsUrl = const Value.absent(),
                Value<String?> registerId = const Value.absent(),
                Value<String?> storytellerId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> cleaningStatus = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastRetryAt = const Value.absent(),
                Value<String?> resumableSessionUri = const Value.absent(),
                Value<int> uploadedBytes = const Value.absent(),
                Value<String?> md5Hash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordingsCompanion.insert(
                id: id,
                projectId: projectId,
                genreId: genreId,
                subcategoryId: subcategoryId,
                title: title,
                description: description,
                durationSeconds: durationSeconds,
                fileSizeBytes: fileSizeBytes,
                format: format,
                localFilePath: localFilePath,
                uploadStatus: uploadStatus,
                serverId: serverId,
                gcsUrl: gcsUrl,
                registerId: registerId,
                storytellerId: storytellerId,
                userId: userId,
                cleaningStatus: cleaningStatus,
                recordedAt: recordedAt,
                createdAt: createdAt,
                retryCount: retryCount,
                lastRetryAt: lastRetryAt,
                resumableSessionUri: resumableSessionUri,
                uploadedBytes: uploadedBytes,
                md5Hash: md5Hash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRecordingsTable,
      LocalRecording,
      $$LocalRecordingsTableFilterComposer,
      $$LocalRecordingsTableOrderingComposer,
      $$LocalRecordingsTableAnnotationComposer,
      $$LocalRecordingsTableCreateCompanionBuilder,
      $$LocalRecordingsTableUpdateCompanionBuilder,
      (
        LocalRecording,
        BaseReferences<_$AppDatabase, $LocalRecordingsTable, LocalRecording>,
      ),
      LocalRecording,
      PrefetchHooks Function()
    >;
typedef $$LocalGenresTableCreateCompanionBuilder =
    LocalGenresCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> icon,
      Value<String?> color,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LocalGenresTableUpdateCompanionBuilder =
    LocalGenresCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> icon,
      Value<String?> color,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$LocalGenresTableFilterComposer
    extends Composer<_$AppDatabase, $LocalGenresTable> {
  $$LocalGenresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalGenresTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalGenresTable> {
  $$LocalGenresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalGenresTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalGenresTable> {
  $$LocalGenresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LocalGenresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalGenresTable,
          LocalGenre,
          $$LocalGenresTableFilterComposer,
          $$LocalGenresTableOrderingComposer,
          $$LocalGenresTableAnnotationComposer,
          $$LocalGenresTableCreateCompanionBuilder,
          $$LocalGenresTableUpdateCompanionBuilder,
          (
            LocalGenre,
            BaseReferences<_$AppDatabase, $LocalGenresTable, LocalGenre>,
          ),
          LocalGenre,
          PrefetchHooks Function()
        > {
  $$LocalGenresTableTableManager(_$AppDatabase db, $LocalGenresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalGenresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalGenresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalGenresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGenresCompanion(
                id: id,
                name: name,
                description: description,
                icon: icon,
                color: color,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGenresCompanion.insert(
                id: id,
                name: name,
                description: description,
                icon: icon,
                color: color,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalGenresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalGenresTable,
      LocalGenre,
      $$LocalGenresTableFilterComposer,
      $$LocalGenresTableOrderingComposer,
      $$LocalGenresTableAnnotationComposer,
      $$LocalGenresTableCreateCompanionBuilder,
      $$LocalGenresTableUpdateCompanionBuilder,
      (
        LocalGenre,
        BaseReferences<_$AppDatabase, $LocalGenresTable, LocalGenre>,
      ),
      LocalGenre,
      PrefetchHooks Function()
    >;
typedef $$LocalSubcategoriesTableCreateCompanionBuilder =
    LocalSubcategoriesCompanion Function({
      required String id,
      required String genreId,
      required String name,
      Value<String?> description,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LocalSubcategoriesTableUpdateCompanionBuilder =
    LocalSubcategoriesCompanion Function({
      Value<String> id,
      Value<String> genreId,
      Value<String> name,
      Value<String?> description,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$LocalSubcategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSubcategoriesTable> {
  $$LocalSubcategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSubcategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSubcategoriesTable> {
  $$LocalSubcategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSubcategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSubcategoriesTable> {
  $$LocalSubcategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genreId =>
      $composableBuilder(column: $table.genreId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LocalSubcategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSubcategoriesTable,
          LocalSubcategory,
          $$LocalSubcategoriesTableFilterComposer,
          $$LocalSubcategoriesTableOrderingComposer,
          $$LocalSubcategoriesTableAnnotationComposer,
          $$LocalSubcategoriesTableCreateCompanionBuilder,
          $$LocalSubcategoriesTableUpdateCompanionBuilder,
          (
            LocalSubcategory,
            BaseReferences<
              _$AppDatabase,
              $LocalSubcategoriesTable,
              LocalSubcategory
            >,
          ),
          LocalSubcategory,
          PrefetchHooks Function()
        > {
  $$LocalSubcategoriesTableTableManager(
    _$AppDatabase db,
    $LocalSubcategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSubcategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSubcategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSubcategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> genreId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSubcategoriesCompanion(
                id: id,
                genreId: genreId,
                name: name,
                description: description,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String genreId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSubcategoriesCompanion.insert(
                id: id,
                genreId: genreId,
                name: name,
                description: description,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSubcategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSubcategoriesTable,
      LocalSubcategory,
      $$LocalSubcategoriesTableFilterComposer,
      $$LocalSubcategoriesTableOrderingComposer,
      $$LocalSubcategoriesTableAnnotationComposer,
      $$LocalSubcategoriesTableCreateCompanionBuilder,
      $$LocalSubcategoriesTableUpdateCompanionBuilder,
      (
        LocalSubcategory,
        BaseReferences<
          _$AppDatabase,
          $LocalSubcategoriesTable,
          LocalSubcategory
        >,
      ),
      LocalSubcategory,
      PrefetchHooks Function()
    >;
typedef $$LocalStorytellersTableCreateCompanionBuilder =
    LocalStorytellersCompanion Function({
      required String id,
      required String projectId,
      required String name,
      required String sex,
      Value<int?> age,
      Value<String?> location,
      Value<String?> dialect,
      Value<bool> externalAcceptanceConfirmed,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalStorytellersTableUpdateCompanionBuilder =
    LocalStorytellersCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> name,
      Value<String> sex,
      Value<int?> age,
      Value<String?> location,
      Value<String?> dialect,
      Value<bool> externalAcceptanceConfirmed,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalStorytellersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStorytellersTable> {
  $$LocalStorytellersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dialect => $composableBuilder(
    column: $table.dialect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get externalAcceptanceConfirmed => $composableBuilder(
    column: $table.externalAcceptanceConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStorytellersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStorytellersTable> {
  $$LocalStorytellersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dialect => $composableBuilder(
    column: $table.dialect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get externalAcceptanceConfirmed => $composableBuilder(
    column: $table.externalAcceptanceConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStorytellersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStorytellersTable> {
  $$LocalStorytellersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get dialect =>
      $composableBuilder(column: $table.dialect, builder: (column) => column);

  GeneratedColumn<bool> get externalAcceptanceConfirmed => $composableBuilder(
    column: $table.externalAcceptanceConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalStorytellersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStorytellersTable,
          LocalStoryteller,
          $$LocalStorytellersTableFilterComposer,
          $$LocalStorytellersTableOrderingComposer,
          $$LocalStorytellersTableAnnotationComposer,
          $$LocalStorytellersTableCreateCompanionBuilder,
          $$LocalStorytellersTableUpdateCompanionBuilder,
          (
            LocalStoryteller,
            BaseReferences<
              _$AppDatabase,
              $LocalStorytellersTable,
              LocalStoryteller
            >,
          ),
          LocalStoryteller,
          PrefetchHooks Function()
        > {
  $$LocalStorytellersTableTableManager(
    _$AppDatabase db,
    $LocalStorytellersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStorytellersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStorytellersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStorytellersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> dialect = const Value.absent(),
                Value<bool> externalAcceptanceConfirmed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStorytellersCompanion(
                id: id,
                projectId: projectId,
                name: name,
                sex: sex,
                age: age,
                location: location,
                dialect: dialect,
                externalAcceptanceConfirmed: externalAcceptanceConfirmed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String name,
                required String sex,
                Value<int?> age = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> dialect = const Value.absent(),
                Value<bool> externalAcceptanceConfirmed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStorytellersCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                sex: sex,
                age: age,
                location: location,
                dialect: dialect,
                externalAcceptanceConfirmed: externalAcceptanceConfirmed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStorytellersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStorytellersTable,
      LocalStoryteller,
      $$LocalStorytellersTableFilterComposer,
      $$LocalStorytellersTableOrderingComposer,
      $$LocalStorytellersTableAnnotationComposer,
      $$LocalStorytellersTableCreateCompanionBuilder,
      $$LocalStorytellersTableUpdateCompanionBuilder,
      (
        LocalStoryteller,
        BaseReferences<
          _$AppDatabase,
          $LocalStorytellersTable,
          LocalStoryteller
        >,
      ),
      LocalStoryteller,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalRecordingsTableTableManager get localRecordings =>
      $$LocalRecordingsTableTableManager(_db, _db.localRecordings);
  $$LocalGenresTableTableManager get localGenres =>
      $$LocalGenresTableTableManager(_db, _db.localGenres);
  $$LocalSubcategoriesTableTableManager get localSubcategories =>
      $$LocalSubcategoriesTableTableManager(_db, _db.localSubcategories);
  $$LocalStorytellersTableTableManager get localStorytellers =>
      $$LocalStorytellersTableTableManager(_db, _db.localStorytellers);
}
