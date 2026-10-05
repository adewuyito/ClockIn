// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkerProfilesTable extends WorkerProfiles
    with TableInfo<$WorkerProfilesTable, WorkerProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalJobsMeta = const VerificationMeta(
    'totalJobs',
  );
  @override
  late final GeneratedColumn<int> totalJobs = GeneratedColumn<int>(
    'total_jobs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingSumMeta = const VerificationMeta(
    'ratingSum',
  );
  @override
  late final GeneratedColumn<BigInt> ratingSum = GeneratedColumn<BigInt>(
    'rating_sum',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    address,
    totalJobs,
    ratingSum,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'worker_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkerProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('total_jobs')) {
      context.handle(
        _totalJobsMeta,
        totalJobs.isAcceptableOrUnknown(data['total_jobs']!, _totalJobsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalJobsMeta);
    }
    if (data.containsKey('rating_sum')) {
      context.handle(
        _ratingSumMeta,
        ratingSum.isAcceptableOrUnknown(data['rating_sum']!, _ratingSumMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingSumMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {address};
  @override
  WorkerProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkerProfile(
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      totalJobs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_jobs'],
      )!,
      ratingSum: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}rating_sum'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $WorkerProfilesTable createAlias(String alias) {
    return $WorkerProfilesTable(attachedDatabase, alias);
  }
}

class WorkerProfile extends DataClass implements Insertable<WorkerProfile> {
  final String address;
  final int totalJobs;
  final BigInt ratingSum;
  final BigInt createdAt;
  final DateTime syncedAt;
  const WorkerProfile({
    required this.address,
    required this.totalJobs,
    required this.ratingSum,
    required this.createdAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['address'] = Variable<String>(address);
    map['total_jobs'] = Variable<int>(totalJobs);
    map['rating_sum'] = Variable<BigInt>(ratingSum);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  WorkerProfilesCompanion toCompanion(bool nullToAbsent) {
    return WorkerProfilesCompanion(
      address: Value(address),
      totalJobs: Value(totalJobs),
      ratingSum: Value(ratingSum),
      createdAt: Value(createdAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory WorkerProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkerProfile(
      address: serializer.fromJson<String>(json['address']),
      totalJobs: serializer.fromJson<int>(json['totalJobs']),
      ratingSum: serializer.fromJson<BigInt>(json['ratingSum']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'address': serializer.toJson<String>(address),
      'totalJobs': serializer.toJson<int>(totalJobs),
      'ratingSum': serializer.toJson<BigInt>(ratingSum),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  WorkerProfile copyWith({
    String? address,
    int? totalJobs,
    BigInt? ratingSum,
    BigInt? createdAt,
    DateTime? syncedAt,
  }) => WorkerProfile(
    address: address ?? this.address,
    totalJobs: totalJobs ?? this.totalJobs,
    ratingSum: ratingSum ?? this.ratingSum,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  WorkerProfile copyWithCompanion(WorkerProfilesCompanion data) {
    return WorkerProfile(
      address: data.address.present ? data.address.value : this.address,
      totalJobs: data.totalJobs.present ? data.totalJobs.value : this.totalJobs,
      ratingSum: data.ratingSum.present ? data.ratingSum.value : this.ratingSum,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkerProfile(')
          ..write('address: $address, ')
          ..write('totalJobs: $totalJobs, ')
          ..write('ratingSum: $ratingSum, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(address, totalJobs, ratingSum, createdAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkerProfile &&
          other.address == this.address &&
          other.totalJobs == this.totalJobs &&
          other.ratingSum == this.ratingSum &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class WorkerProfilesCompanion extends UpdateCompanion<WorkerProfile> {
  final Value<String> address;
  final Value<int> totalJobs;
  final Value<BigInt> ratingSum;
  final Value<BigInt> createdAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const WorkerProfilesCompanion({
    this.address = const Value.absent(),
    this.totalJobs = const Value.absent(),
    this.ratingSum = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkerProfilesCompanion.insert({
    required String address,
    required int totalJobs,
    required BigInt ratingSum,
    required BigInt createdAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : address = Value(address),
       totalJobs = Value(totalJobs),
       ratingSum = Value(ratingSum),
       createdAt = Value(createdAt);
  static Insertable<WorkerProfile> custom({
    Expression<String>? address,
    Expression<int>? totalJobs,
    Expression<BigInt>? ratingSum,
    Expression<BigInt>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (address != null) 'address': address,
      if (totalJobs != null) 'total_jobs': totalJobs,
      if (ratingSum != null) 'rating_sum': ratingSum,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkerProfilesCompanion copyWith({
    Value<String>? address,
    Value<int>? totalJobs,
    Value<BigInt>? ratingSum,
    Value<BigInt>? createdAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return WorkerProfilesCompanion(
      address: address ?? this.address,
      totalJobs: totalJobs ?? this.totalJobs,
      ratingSum: ratingSum ?? this.ratingSum,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (totalJobs.present) {
      map['total_jobs'] = Variable<int>(totalJobs.value);
    }
    if (ratingSum.present) {
      map['rating_sum'] = Variable<BigInt>(ratingSum.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkerProfilesCompanion(')
          ..write('address: $address, ')
          ..write('totalJobs: $totalJobs, ')
          ..write('ratingSum: $ratingSum, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewsTable extends Reviews with TableInfo<$ReviewsTable, Review> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workerAddressMeta = const VerificationMeta(
    'workerAddress',
  );
  @override
  late final GeneratedColumn<String> workerAddress = GeneratedColumn<String>(
    'worker_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewerAddressMeta = const VerificationMeta(
    'reviewerAddress',
  );
  @override
  late final GeneratedColumn<String> reviewerAddress = GeneratedColumn<String>(
    'reviewer_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<BigInt> timestamp = GeneratedColumn<BigInt>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewNoteMeta = const VerificationMeta(
    'reviewNote',
  );
  @override
  late final GeneratedColumn<String> reviewNote = GeneratedColumn<String>(
    'review_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _arweaveTxIdMeta = const VerificationMeta(
    'arweaveTxId',
  );
  @override
  late final GeneratedColumn<String> arweaveTxId = GeneratedColumn<String>(
    'arweave_tx_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workerAddress,
    reviewerAddress,
    jobId,
    rating,
    timestamp,
    reviewNote,
    arweaveTxId,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<Review> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('worker_address')) {
      context.handle(
        _workerAddressMeta,
        workerAddress.isAcceptableOrUnknown(
          data['worker_address']!,
          _workerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workerAddressMeta);
    }
    if (data.containsKey('reviewer_address')) {
      context.handle(
        _reviewerAddressMeta,
        reviewerAddress.isAcceptableOrUnknown(
          data['reviewer_address']!,
          _reviewerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewerAddressMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('review_note')) {
      context.handle(
        _reviewNoteMeta,
        reviewNote.isAcceptableOrUnknown(data['review_note']!, _reviewNoteMeta),
      );
    }
    if (data.containsKey('arweave_tx_id')) {
      context.handle(
        _arweaveTxIdMeta,
        arweaveTxId.isAcceptableOrUnknown(
          data['arweave_tx_id']!,
          _arweaveTxIdMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Review map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Review(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_address'],
      )!,
      reviewerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewer_address'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}timestamp'],
      )!,
      reviewNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_note'],
      ),
      arweaveTxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arweave_tx_id'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $ReviewsTable createAlias(String alias) {
    return $ReviewsTable(attachedDatabase, alias);
  }
}

class Review extends DataClass implements Insertable<Review> {
  final int id;
  final String workerAddress;
  final String reviewerAddress;
  final String jobId;
  final int rating;
  final BigInt timestamp;
  final String? reviewNote;
  final String? arweaveTxId;
  final DateTime syncedAt;
  const Review({
    required this.id,
    required this.workerAddress,
    required this.reviewerAddress,
    required this.jobId,
    required this.rating,
    required this.timestamp,
    this.reviewNote,
    this.arweaveTxId,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['worker_address'] = Variable<String>(workerAddress);
    map['reviewer_address'] = Variable<String>(reviewerAddress);
    map['job_id'] = Variable<String>(jobId);
    map['rating'] = Variable<int>(rating);
    map['timestamp'] = Variable<BigInt>(timestamp);
    if (!nullToAbsent || reviewNote != null) {
      map['review_note'] = Variable<String>(reviewNote);
    }
    if (!nullToAbsent || arweaveTxId != null) {
      map['arweave_tx_id'] = Variable<String>(arweaveTxId);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  ReviewsCompanion toCompanion(bool nullToAbsent) {
    return ReviewsCompanion(
      id: Value(id),
      workerAddress: Value(workerAddress),
      reviewerAddress: Value(reviewerAddress),
      jobId: Value(jobId),
      rating: Value(rating),
      timestamp: Value(timestamp),
      reviewNote: reviewNote == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewNote),
      arweaveTxId: arweaveTxId == null && nullToAbsent
          ? const Value.absent()
          : Value(arweaveTxId),
      syncedAt: Value(syncedAt),
    );
  }

  factory Review.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Review(
      id: serializer.fromJson<int>(json['id']),
      workerAddress: serializer.fromJson<String>(json['workerAddress']),
      reviewerAddress: serializer.fromJson<String>(json['reviewerAddress']),
      jobId: serializer.fromJson<String>(json['jobId']),
      rating: serializer.fromJson<int>(json['rating']),
      timestamp: serializer.fromJson<BigInt>(json['timestamp']),
      reviewNote: serializer.fromJson<String?>(json['reviewNote']),
      arweaveTxId: serializer.fromJson<String?>(json['arweaveTxId']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workerAddress': serializer.toJson<String>(workerAddress),
      'reviewerAddress': serializer.toJson<String>(reviewerAddress),
      'jobId': serializer.toJson<String>(jobId),
      'rating': serializer.toJson<int>(rating),
      'timestamp': serializer.toJson<BigInt>(timestamp),
      'reviewNote': serializer.toJson<String?>(reviewNote),
      'arweaveTxId': serializer.toJson<String?>(arweaveTxId),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  Review copyWith({
    int? id,
    String? workerAddress,
    String? reviewerAddress,
    String? jobId,
    int? rating,
    BigInt? timestamp,
    Value<String?> reviewNote = const Value.absent(),
    Value<String?> arweaveTxId = const Value.absent(),
    DateTime? syncedAt,
  }) => Review(
    id: id ?? this.id,
    workerAddress: workerAddress ?? this.workerAddress,
    reviewerAddress: reviewerAddress ?? this.reviewerAddress,
    jobId: jobId ?? this.jobId,
    rating: rating ?? this.rating,
    timestamp: timestamp ?? this.timestamp,
    reviewNote: reviewNote.present ? reviewNote.value : this.reviewNote,
    arweaveTxId: arweaveTxId.present ? arweaveTxId.value : this.arweaveTxId,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  Review copyWithCompanion(ReviewsCompanion data) {
    return Review(
      id: data.id.present ? data.id.value : this.id,
      workerAddress: data.workerAddress.present
          ? data.workerAddress.value
          : this.workerAddress,
      reviewerAddress: data.reviewerAddress.present
          ? data.reviewerAddress.value
          : this.reviewerAddress,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      rating: data.rating.present ? data.rating.value : this.rating,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      reviewNote: data.reviewNote.present
          ? data.reviewNote.value
          : this.reviewNote,
      arweaveTxId: data.arweaveTxId.present
          ? data.arweaveTxId.value
          : this.arweaveTxId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Review(')
          ..write('id: $id, ')
          ..write('workerAddress: $workerAddress, ')
          ..write('reviewerAddress: $reviewerAddress, ')
          ..write('jobId: $jobId, ')
          ..write('rating: $rating, ')
          ..write('timestamp: $timestamp, ')
          ..write('reviewNote: $reviewNote, ')
          ..write('arweaveTxId: $arweaveTxId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workerAddress,
    reviewerAddress,
    jobId,
    rating,
    timestamp,
    reviewNote,
    arweaveTxId,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Review &&
          other.id == this.id &&
          other.workerAddress == this.workerAddress &&
          other.reviewerAddress == this.reviewerAddress &&
          other.jobId == this.jobId &&
          other.rating == this.rating &&
          other.timestamp == this.timestamp &&
          other.reviewNote == this.reviewNote &&
          other.arweaveTxId == this.arweaveTxId &&
          other.syncedAt == this.syncedAt);
}

class ReviewsCompanion extends UpdateCompanion<Review> {
  final Value<int> id;
  final Value<String> workerAddress;
  final Value<String> reviewerAddress;
  final Value<String> jobId;
  final Value<int> rating;
  final Value<BigInt> timestamp;
  final Value<String?> reviewNote;
  final Value<String?> arweaveTxId;
  final Value<DateTime> syncedAt;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.workerAddress = const Value.absent(),
    this.reviewerAddress = const Value.absent(),
    this.jobId = const Value.absent(),
    this.rating = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.reviewNote = const Value.absent(),
    this.arweaveTxId = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String workerAddress,
    required String reviewerAddress,
    required String jobId,
    required int rating,
    required BigInt timestamp,
    this.reviewNote = const Value.absent(),
    this.arweaveTxId = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : workerAddress = Value(workerAddress),
       reviewerAddress = Value(reviewerAddress),
       jobId = Value(jobId),
       rating = Value(rating),
       timestamp = Value(timestamp);
  static Insertable<Review> custom({
    Expression<int>? id,
    Expression<String>? workerAddress,
    Expression<String>? reviewerAddress,
    Expression<String>? jobId,
    Expression<int>? rating,
    Expression<BigInt>? timestamp,
    Expression<String>? reviewNote,
    Expression<String>? arweaveTxId,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerAddress != null) 'worker_address': workerAddress,
      if (reviewerAddress != null) 'reviewer_address': reviewerAddress,
      if (jobId != null) 'job_id': jobId,
      if (rating != null) 'rating': rating,
      if (timestamp != null) 'timestamp': timestamp,
      if (reviewNote != null) 'review_note': reviewNote,
      if (arweaveTxId != null) 'arweave_tx_id': arweaveTxId,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ReviewsCompanion copyWith({
    Value<int>? id,
    Value<String>? workerAddress,
    Value<String>? reviewerAddress,
    Value<String>? jobId,
    Value<int>? rating,
    Value<BigInt>? timestamp,
    Value<String?>? reviewNote,
    Value<String?>? arweaveTxId,
    Value<DateTime>? syncedAt,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      workerAddress: workerAddress ?? this.workerAddress,
      reviewerAddress: reviewerAddress ?? this.reviewerAddress,
      jobId: jobId ?? this.jobId,
      rating: rating ?? this.rating,
      timestamp: timestamp ?? this.timestamp,
      reviewNote: reviewNote ?? this.reviewNote,
      arweaveTxId: arweaveTxId ?? this.arweaveTxId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workerAddress.present) {
      map['worker_address'] = Variable<String>(workerAddress.value);
    }
    if (reviewerAddress.present) {
      map['reviewer_address'] = Variable<String>(reviewerAddress.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<BigInt>(timestamp.value);
    }
    if (reviewNote.present) {
      map['review_note'] = Variable<String>(reviewNote.value);
    }
    if (arweaveTxId.present) {
      map['arweave_tx_id'] = Variable<String>(arweaveTxId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewsCompanion(')
          ..write('id: $id, ')
          ..write('workerAddress: $workerAddress, ')
          ..write('reviewerAddress: $reviewerAddress, ')
          ..write('jobId: $jobId, ')
          ..write('rating: $rating, ')
          ..write('timestamp: $timestamp, ')
          ..write('reviewNote: $reviewNote, ')
          ..write('arweaveTxId: $arweaveTxId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $DraftReviewsTable extends DraftReviews
    with TableInfo<$DraftReviewsTable, DraftReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workerAddressMeta = const VerificationMeta(
    'workerAddress',
  );
  @override
  late final GeneratedColumn<String> workerAddress = GeneratedColumn<String>(
    'worker_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _arweaveTxIdMeta = const VerificationMeta(
    'arweaveTxId',
  );
  @override
  late final GeneratedColumn<String> arweaveTxId = GeneratedColumn<String>(
    'arweave_tx_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workerAddress,
    jobId,
    rating,
    notes,
    arweaveTxId,
    createdAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('worker_address')) {
      context.handle(
        _workerAddressMeta,
        workerAddress.isAcceptableOrUnknown(
          data['worker_address']!,
          _workerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workerAddressMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('arweave_tx_id')) {
      context.handle(
        _arweaveTxIdMeta,
        arweaveTxId.isAcceptableOrUnknown(
          data['arweave_tx_id']!,
          _arweaveTxIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_address'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      arweaveTxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arweave_tx_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $DraftReviewsTable createAlias(String alias) {
    return $DraftReviewsTable(attachedDatabase, alias);
  }
}

class DraftReview extends DataClass implements Insertable<DraftReview> {
  final int id;
  final String workerAddress;
  final String jobId;
  final int rating;
  final String? notes;
  final String? arweaveTxId;
  final DateTime createdAt;
  final String status;
  const DraftReview({
    required this.id,
    required this.workerAddress,
    required this.jobId,
    required this.rating,
    this.notes,
    this.arweaveTxId,
    required this.createdAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['worker_address'] = Variable<String>(workerAddress);
    map['job_id'] = Variable<String>(jobId);
    map['rating'] = Variable<int>(rating);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || arweaveTxId != null) {
      map['arweave_tx_id'] = Variable<String>(arweaveTxId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  DraftReviewsCompanion toCompanion(bool nullToAbsent) {
    return DraftReviewsCompanion(
      id: Value(id),
      workerAddress: Value(workerAddress),
      jobId: Value(jobId),
      rating: Value(rating),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      arweaveTxId: arweaveTxId == null && nullToAbsent
          ? const Value.absent()
          : Value(arweaveTxId),
      createdAt: Value(createdAt),
      status: Value(status),
    );
  }

  factory DraftReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftReview(
      id: serializer.fromJson<int>(json['id']),
      workerAddress: serializer.fromJson<String>(json['workerAddress']),
      jobId: serializer.fromJson<String>(json['jobId']),
      rating: serializer.fromJson<int>(json['rating']),
      notes: serializer.fromJson<String?>(json['notes']),
      arweaveTxId: serializer.fromJson<String?>(json['arweaveTxId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workerAddress': serializer.toJson<String>(workerAddress),
      'jobId': serializer.toJson<String>(jobId),
      'rating': serializer.toJson<int>(rating),
      'notes': serializer.toJson<String?>(notes),
      'arweaveTxId': serializer.toJson<String?>(arweaveTxId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
    };
  }

  DraftReview copyWith({
    int? id,
    String? workerAddress,
    String? jobId,
    int? rating,
    Value<String?> notes = const Value.absent(),
    Value<String?> arweaveTxId = const Value.absent(),
    DateTime? createdAt,
    String? status,
  }) => DraftReview(
    id: id ?? this.id,
    workerAddress: workerAddress ?? this.workerAddress,
    jobId: jobId ?? this.jobId,
    rating: rating ?? this.rating,
    notes: notes.present ? notes.value : this.notes,
    arweaveTxId: arweaveTxId.present ? arweaveTxId.value : this.arweaveTxId,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );
  DraftReview copyWithCompanion(DraftReviewsCompanion data) {
    return DraftReview(
      id: data.id.present ? data.id.value : this.id,
      workerAddress: data.workerAddress.present
          ? data.workerAddress.value
          : this.workerAddress,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      rating: data.rating.present ? data.rating.value : this.rating,
      notes: data.notes.present ? data.notes.value : this.notes,
      arweaveTxId: data.arweaveTxId.present
          ? data.arweaveTxId.value
          : this.arweaveTxId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftReview(')
          ..write('id: $id, ')
          ..write('workerAddress: $workerAddress, ')
          ..write('jobId: $jobId, ')
          ..write('rating: $rating, ')
          ..write('notes: $notes, ')
          ..write('arweaveTxId: $arweaveTxId, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workerAddress,
    jobId,
    rating,
    notes,
    arweaveTxId,
    createdAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftReview &&
          other.id == this.id &&
          other.workerAddress == this.workerAddress &&
          other.jobId == this.jobId &&
          other.rating == this.rating &&
          other.notes == this.notes &&
          other.arweaveTxId == this.arweaveTxId &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class DraftReviewsCompanion extends UpdateCompanion<DraftReview> {
  final Value<int> id;
  final Value<String> workerAddress;
  final Value<String> jobId;
  final Value<int> rating;
  final Value<String?> notes;
  final Value<String?> arweaveTxId;
  final Value<DateTime> createdAt;
  final Value<String> status;
  const DraftReviewsCompanion({
    this.id = const Value.absent(),
    this.workerAddress = const Value.absent(),
    this.jobId = const Value.absent(),
    this.rating = const Value.absent(),
    this.notes = const Value.absent(),
    this.arweaveTxId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  DraftReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String workerAddress,
    required String jobId,
    required int rating,
    this.notes = const Value.absent(),
    this.arweaveTxId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
  }) : workerAddress = Value(workerAddress),
       jobId = Value(jobId),
       rating = Value(rating);
  static Insertable<DraftReview> custom({
    Expression<int>? id,
    Expression<String>? workerAddress,
    Expression<String>? jobId,
    Expression<int>? rating,
    Expression<String>? notes,
    Expression<String>? arweaveTxId,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerAddress != null) 'worker_address': workerAddress,
      if (jobId != null) 'job_id': jobId,
      if (rating != null) 'rating': rating,
      if (notes != null) 'notes': notes,
      if (arweaveTxId != null) 'arweave_tx_id': arweaveTxId,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
    });
  }

  DraftReviewsCompanion copyWith({
    Value<int>? id,
    Value<String>? workerAddress,
    Value<String>? jobId,
    Value<int>? rating,
    Value<String?>? notes,
    Value<String?>? arweaveTxId,
    Value<DateTime>? createdAt,
    Value<String>? status,
  }) {
    return DraftReviewsCompanion(
      id: id ?? this.id,
      workerAddress: workerAddress ?? this.workerAddress,
      jobId: jobId ?? this.jobId,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      arweaveTxId: arweaveTxId ?? this.arweaveTxId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workerAddress.present) {
      map['worker_address'] = Variable<String>(workerAddress.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (arweaveTxId.present) {
      map['arweave_tx_id'] = Variable<String>(arweaveTxId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftReviewsCompanion(')
          ..write('id: $id, ')
          ..write('workerAddress: $workerAddress, ')
          ..write('jobId: $jobId, ')
          ..write('rating: $rating, ')
          ..write('notes: $notes, ')
          ..write('arweaveTxId: $arweaveTxId, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $RecentLookupsTable extends RecentLookups
    with TableInfo<$RecentLookupsTable, RecentLookup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentLookupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastViewedAtMeta = const VerificationMeta(
    'lastViewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastViewedAt = GeneratedColumn<DateTime>(
    'last_viewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [address, lastViewedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_lookups';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentLookup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('last_viewed_at')) {
      context.handle(
        _lastViewedAtMeta,
        lastViewedAt.isAcceptableOrUnknown(
          data['last_viewed_at']!,
          _lastViewedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {address};
  @override
  RecentLookup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentLookup(
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      lastViewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_viewed_at'],
      )!,
    );
  }

  @override
  $RecentLookupsTable createAlias(String alias) {
    return $RecentLookupsTable(attachedDatabase, alias);
  }
}

class RecentLookup extends DataClass implements Insertable<RecentLookup> {
  final String address;
  final DateTime lastViewedAt;
  const RecentLookup({required this.address, required this.lastViewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['address'] = Variable<String>(address);
    map['last_viewed_at'] = Variable<DateTime>(lastViewedAt);
    return map;
  }

  RecentLookupsCompanion toCompanion(bool nullToAbsent) {
    return RecentLookupsCompanion(
      address: Value(address),
      lastViewedAt: Value(lastViewedAt),
    );
  }

  factory RecentLookup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentLookup(
      address: serializer.fromJson<String>(json['address']),
      lastViewedAt: serializer.fromJson<DateTime>(json['lastViewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'address': serializer.toJson<String>(address),
      'lastViewedAt': serializer.toJson<DateTime>(lastViewedAt),
    };
  }

  RecentLookup copyWith({String? address, DateTime? lastViewedAt}) =>
      RecentLookup(
        address: address ?? this.address,
        lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      );
  RecentLookup copyWithCompanion(RecentLookupsCompanion data) {
    return RecentLookup(
      address: data.address.present ? data.address.value : this.address,
      lastViewedAt: data.lastViewedAt.present
          ? data.lastViewedAt.value
          : this.lastViewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentLookup(')
          ..write('address: $address, ')
          ..write('lastViewedAt: $lastViewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(address, lastViewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentLookup &&
          other.address == this.address &&
          other.lastViewedAt == this.lastViewedAt);
}

class RecentLookupsCompanion extends UpdateCompanion<RecentLookup> {
  final Value<String> address;
  final Value<DateTime> lastViewedAt;
  final Value<int> rowid;
  const RecentLookupsCompanion({
    this.address = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentLookupsCompanion.insert({
    required String address,
    this.lastViewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : address = Value(address);
  static Insertable<RecentLookup> custom({
    Expression<String>? address,
    Expression<DateTime>? lastViewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (address != null) 'address': address,
      if (lastViewedAt != null) 'last_viewed_at': lastViewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentLookupsCompanion copyWith({
    Value<String>? address,
    Value<DateTime>? lastViewedAt,
    Value<int>? rowid,
  }) {
    return RecentLookupsCompanion(
      address: address ?? this.address,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (lastViewedAt.present) {
      map['last_viewed_at'] = Variable<DateTime>(lastViewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentLookupsCompanion(')
          ..write('address: $address, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EscrowContractsTable extends EscrowContracts
    with TableInfo<$EscrowContractsTable, EscrowContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EscrowContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employerMeta = const VerificationMeta(
    'employer',
  );
  @override
  late final GeneratedColumn<String> employer = GeneratedColumn<String>(
    'employer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerMeta = const VerificationMeta('worker');
  @override
  late final GeneratedColumn<String> worker = GeneratedColumn<String>(
    'worker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<BigInt> amount = GeneratedColumn<BigInt>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termsHashMeta = const VerificationMeta(
    'termsHash',
  );
  @override
  late final GeneratedColumn<String> termsHash = GeneratedColumn<String>(
    'terms_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termsTextMeta = const VerificationMeta(
    'termsText',
  );
  @override
  late final GeneratedColumn<String> termsText = GeneratedColumn<String>(
    'terms_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<BigInt> deadline = GeneratedColumn<BigInt>(
    'deadline',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fundedAtMeta = const VerificationMeta(
    'fundedAt',
  );
  @override
  late final GeneratedColumn<BigInt> fundedAt = GeneratedColumn<BigInt>(
    'funded_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<BigInt> completedAt = GeneratedColumn<BigInt>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastTxSignatureMeta = const VerificationMeta(
    'lastTxSignature',
  );
  @override
  late final GeneratedColumn<String> lastTxSignature = GeneratedColumn<String>(
    'last_tx_signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isTokenMeta = const VerificationMeta(
    'isToken',
  );
  @override
  late final GeneratedColumn<bool> isToken = GeneratedColumn<bool>(
    'is_token',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_token" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tokenMintMeta = const VerificationMeta(
    'tokenMint',
  );
  @override
  late final GeneratedColumn<String> tokenMint = GeneratedColumn<String>(
    'token_mint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disputeReasonMeta = const VerificationMeta(
    'disputeReason',
  );
  @override
  late final GeneratedColumn<String> disputeReason = GeneratedColumn<String>(
    'dispute_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disputeDetailsMeta = const VerificationMeta(
    'disputeDetails',
  );
  @override
  late final GeneratedColumn<String> disputeDetails = GeneratedColumn<String>(
    'dispute_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disputeEvidenceUriMeta =
      const VerificationMeta('disputeEvidenceUri');
  @override
  late final GeneratedColumn<String> disputeEvidenceUri =
      GeneratedColumn<String>(
        'dispute_evidence_uri',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _disputeRaisedByMeta = const VerificationMeta(
    'disputeRaisedBy',
  );
  @override
  late final GeneratedColumn<String> disputeRaisedBy = GeneratedColumn<String>(
    'dispute_raised_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disputeRaisedAtMeta = const VerificationMeta(
    'disputeRaisedAt',
  );
  @override
  late final GeneratedColumn<DateTime> disputeRaisedAt =
      GeneratedColumn<DateTime>(
        'dispute_raised_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    contractId,
    employer,
    worker,
    amount,
    termsHash,
    termsText,
    status,
    deadline,
    createdAt,
    fundedAt,
    completedAt,
    rating,
    lastTxSignature,
    syncedAt,
    isToken,
    tokenMint,
    disputeReason,
    disputeDetails,
    disputeEvidenceUri,
    disputeRaisedBy,
    disputeRaisedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'escrow_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<EscrowContract> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('employer')) {
      context.handle(
        _employerMeta,
        employer.isAcceptableOrUnknown(data['employer']!, _employerMeta),
      );
    } else if (isInserting) {
      context.missing(_employerMeta);
    }
    if (data.containsKey('worker')) {
      context.handle(
        _workerMeta,
        worker.isAcceptableOrUnknown(data['worker']!, _workerMeta),
      );
    } else if (isInserting) {
      context.missing(_workerMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('terms_hash')) {
      context.handle(
        _termsHashMeta,
        termsHash.isAcceptableOrUnknown(data['terms_hash']!, _termsHashMeta),
      );
    } else if (isInserting) {
      context.missing(_termsHashMeta);
    }
    if (data.containsKey('terms_text')) {
      context.handle(
        _termsTextMeta,
        termsText.isAcceptableOrUnknown(data['terms_text']!, _termsTextMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    } else if (isInserting) {
      context.missing(_deadlineMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('funded_at')) {
      context.handle(
        _fundedAtMeta,
        fundedAt.isAcceptableOrUnknown(data['funded_at']!, _fundedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fundedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('last_tx_signature')) {
      context.handle(
        _lastTxSignatureMeta,
        lastTxSignature.isAcceptableOrUnknown(
          data['last_tx_signature']!,
          _lastTxSignatureMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('is_token')) {
      context.handle(
        _isTokenMeta,
        isToken.isAcceptableOrUnknown(data['is_token']!, _isTokenMeta),
      );
    }
    if (data.containsKey('token_mint')) {
      context.handle(
        _tokenMintMeta,
        tokenMint.isAcceptableOrUnknown(data['token_mint']!, _tokenMintMeta),
      );
    }
    if (data.containsKey('dispute_reason')) {
      context.handle(
        _disputeReasonMeta,
        disputeReason.isAcceptableOrUnknown(
          data['dispute_reason']!,
          _disputeReasonMeta,
        ),
      );
    }
    if (data.containsKey('dispute_details')) {
      context.handle(
        _disputeDetailsMeta,
        disputeDetails.isAcceptableOrUnknown(
          data['dispute_details']!,
          _disputeDetailsMeta,
        ),
      );
    }
    if (data.containsKey('dispute_evidence_uri')) {
      context.handle(
        _disputeEvidenceUriMeta,
        disputeEvidenceUri.isAcceptableOrUnknown(
          data['dispute_evidence_uri']!,
          _disputeEvidenceUriMeta,
        ),
      );
    }
    if (data.containsKey('dispute_raised_by')) {
      context.handle(
        _disputeRaisedByMeta,
        disputeRaisedBy.isAcceptableOrUnknown(
          data['dispute_raised_by']!,
          _disputeRaisedByMeta,
        ),
      );
    }
    if (data.containsKey('dispute_raised_at')) {
      context.handle(
        _disputeRaisedAtMeta,
        disputeRaisedAt.isAcceptableOrUnknown(
          data['dispute_raised_at']!,
          _disputeRaisedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contractId};
  @override
  EscrowContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EscrowContract(
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      employer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employer'],
      )!,
      worker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}amount'],
      )!,
      termsHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terms_hash'],
      )!,
      termsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terms_text'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deadline'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      fundedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}funded_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}completed_at'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      lastTxSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_tx_signature'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
      isToken: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_token'],
      )!,
      tokenMint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_mint'],
      ),
      disputeReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispute_reason'],
      ),
      disputeDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispute_details'],
      ),
      disputeEvidenceUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispute_evidence_uri'],
      ),
      disputeRaisedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispute_raised_by'],
      ),
      disputeRaisedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dispute_raised_at'],
      ),
    );
  }

  @override
  $EscrowContractsTable createAlias(String alias) {
    return $EscrowContractsTable(attachedDatabase, alias);
  }
}

class EscrowContract extends DataClass implements Insertable<EscrowContract> {
  final String contractId;
  final String employer;
  final String worker;
  final BigInt amount;
  final String termsHash;
  final String? termsText;
  final String status;
  final BigInt deadline;
  final BigInt createdAt;
  final BigInt fundedAt;
  final BigInt completedAt;
  final int rating;
  final String? lastTxSignature;
  final DateTime syncedAt;
  final bool isToken;
  final String? tokenMint;
  final String? disputeReason;
  final String? disputeDetails;
  final String? disputeEvidenceUri;
  final String? disputeRaisedBy;
  final DateTime? disputeRaisedAt;
  const EscrowContract({
    required this.contractId,
    required this.employer,
    required this.worker,
    required this.amount,
    required this.termsHash,
    this.termsText,
    required this.status,
    required this.deadline,
    required this.createdAt,
    required this.fundedAt,
    required this.completedAt,
    required this.rating,
    this.lastTxSignature,
    required this.syncedAt,
    required this.isToken,
    this.tokenMint,
    this.disputeReason,
    this.disputeDetails,
    this.disputeEvidenceUri,
    this.disputeRaisedBy,
    this.disputeRaisedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contract_id'] = Variable<String>(contractId);
    map['employer'] = Variable<String>(employer);
    map['worker'] = Variable<String>(worker);
    map['amount'] = Variable<BigInt>(amount);
    map['terms_hash'] = Variable<String>(termsHash);
    if (!nullToAbsent || termsText != null) {
      map['terms_text'] = Variable<String>(termsText);
    }
    map['status'] = Variable<String>(status);
    map['deadline'] = Variable<BigInt>(deadline);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['funded_at'] = Variable<BigInt>(fundedAt);
    map['completed_at'] = Variable<BigInt>(completedAt);
    map['rating'] = Variable<int>(rating);
    if (!nullToAbsent || lastTxSignature != null) {
      map['last_tx_signature'] = Variable<String>(lastTxSignature);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    map['is_token'] = Variable<bool>(isToken);
    if (!nullToAbsent || tokenMint != null) {
      map['token_mint'] = Variable<String>(tokenMint);
    }
    if (!nullToAbsent || disputeReason != null) {
      map['dispute_reason'] = Variable<String>(disputeReason);
    }
    if (!nullToAbsent || disputeDetails != null) {
      map['dispute_details'] = Variable<String>(disputeDetails);
    }
    if (!nullToAbsent || disputeEvidenceUri != null) {
      map['dispute_evidence_uri'] = Variable<String>(disputeEvidenceUri);
    }
    if (!nullToAbsent || disputeRaisedBy != null) {
      map['dispute_raised_by'] = Variable<String>(disputeRaisedBy);
    }
    if (!nullToAbsent || disputeRaisedAt != null) {
      map['dispute_raised_at'] = Variable<DateTime>(disputeRaisedAt);
    }
    return map;
  }

  EscrowContractsCompanion toCompanion(bool nullToAbsent) {
    return EscrowContractsCompanion(
      contractId: Value(contractId),
      employer: Value(employer),
      worker: Value(worker),
      amount: Value(amount),
      termsHash: Value(termsHash),
      termsText: termsText == null && nullToAbsent
          ? const Value.absent()
          : Value(termsText),
      status: Value(status),
      deadline: Value(deadline),
      createdAt: Value(createdAt),
      fundedAt: Value(fundedAt),
      completedAt: Value(completedAt),
      rating: Value(rating),
      lastTxSignature: lastTxSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTxSignature),
      syncedAt: Value(syncedAt),
      isToken: Value(isToken),
      tokenMint: tokenMint == null && nullToAbsent
          ? const Value.absent()
          : Value(tokenMint),
      disputeReason: disputeReason == null && nullToAbsent
          ? const Value.absent()
          : Value(disputeReason),
      disputeDetails: disputeDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(disputeDetails),
      disputeEvidenceUri: disputeEvidenceUri == null && nullToAbsent
          ? const Value.absent()
          : Value(disputeEvidenceUri),
      disputeRaisedBy: disputeRaisedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(disputeRaisedBy),
      disputeRaisedAt: disputeRaisedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disputeRaisedAt),
    );
  }

  factory EscrowContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EscrowContract(
      contractId: serializer.fromJson<String>(json['contractId']),
      employer: serializer.fromJson<String>(json['employer']),
      worker: serializer.fromJson<String>(json['worker']),
      amount: serializer.fromJson<BigInt>(json['amount']),
      termsHash: serializer.fromJson<String>(json['termsHash']),
      termsText: serializer.fromJson<String?>(json['termsText']),
      status: serializer.fromJson<String>(json['status']),
      deadline: serializer.fromJson<BigInt>(json['deadline']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      fundedAt: serializer.fromJson<BigInt>(json['fundedAt']),
      completedAt: serializer.fromJson<BigInt>(json['completedAt']),
      rating: serializer.fromJson<int>(json['rating']),
      lastTxSignature: serializer.fromJson<String?>(json['lastTxSignature']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
      isToken: serializer.fromJson<bool>(json['isToken']),
      tokenMint: serializer.fromJson<String?>(json['tokenMint']),
      disputeReason: serializer.fromJson<String?>(json['disputeReason']),
      disputeDetails: serializer.fromJson<String?>(json['disputeDetails']),
      disputeEvidenceUri: serializer.fromJson<String?>(
        json['disputeEvidenceUri'],
      ),
      disputeRaisedBy: serializer.fromJson<String?>(json['disputeRaisedBy']),
      disputeRaisedAt: serializer.fromJson<DateTime?>(json['disputeRaisedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contractId': serializer.toJson<String>(contractId),
      'employer': serializer.toJson<String>(employer),
      'worker': serializer.toJson<String>(worker),
      'amount': serializer.toJson<BigInt>(amount),
      'termsHash': serializer.toJson<String>(termsHash),
      'termsText': serializer.toJson<String?>(termsText),
      'status': serializer.toJson<String>(status),
      'deadline': serializer.toJson<BigInt>(deadline),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'fundedAt': serializer.toJson<BigInt>(fundedAt),
      'completedAt': serializer.toJson<BigInt>(completedAt),
      'rating': serializer.toJson<int>(rating),
      'lastTxSignature': serializer.toJson<String?>(lastTxSignature),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
      'isToken': serializer.toJson<bool>(isToken),
      'tokenMint': serializer.toJson<String?>(tokenMint),
      'disputeReason': serializer.toJson<String?>(disputeReason),
      'disputeDetails': serializer.toJson<String?>(disputeDetails),
      'disputeEvidenceUri': serializer.toJson<String?>(disputeEvidenceUri),
      'disputeRaisedBy': serializer.toJson<String?>(disputeRaisedBy),
      'disputeRaisedAt': serializer.toJson<DateTime?>(disputeRaisedAt),
    };
  }

  EscrowContract copyWith({
    String? contractId,
    String? employer,
    String? worker,
    BigInt? amount,
    String? termsHash,
    Value<String?> termsText = const Value.absent(),
    String? status,
    BigInt? deadline,
    BigInt? createdAt,
    BigInt? fundedAt,
    BigInt? completedAt,
    int? rating,
    Value<String?> lastTxSignature = const Value.absent(),
    DateTime? syncedAt,
    bool? isToken,
    Value<String?> tokenMint = const Value.absent(),
    Value<String?> disputeReason = const Value.absent(),
    Value<String?> disputeDetails = const Value.absent(),
    Value<String?> disputeEvidenceUri = const Value.absent(),
    Value<String?> disputeRaisedBy = const Value.absent(),
    Value<DateTime?> disputeRaisedAt = const Value.absent(),
  }) => EscrowContract(
    contractId: contractId ?? this.contractId,
    employer: employer ?? this.employer,
    worker: worker ?? this.worker,
    amount: amount ?? this.amount,
    termsHash: termsHash ?? this.termsHash,
    termsText: termsText.present ? termsText.value : this.termsText,
    status: status ?? this.status,
    deadline: deadline ?? this.deadline,
    createdAt: createdAt ?? this.createdAt,
    fundedAt: fundedAt ?? this.fundedAt,
    completedAt: completedAt ?? this.completedAt,
    rating: rating ?? this.rating,
    lastTxSignature: lastTxSignature.present
        ? lastTxSignature.value
        : this.lastTxSignature,
    syncedAt: syncedAt ?? this.syncedAt,
    isToken: isToken ?? this.isToken,
    tokenMint: tokenMint.present ? tokenMint.value : this.tokenMint,
    disputeReason: disputeReason.present
        ? disputeReason.value
        : this.disputeReason,
    disputeDetails: disputeDetails.present
        ? disputeDetails.value
        : this.disputeDetails,
    disputeEvidenceUri: disputeEvidenceUri.present
        ? disputeEvidenceUri.value
        : this.disputeEvidenceUri,
    disputeRaisedBy: disputeRaisedBy.present
        ? disputeRaisedBy.value
        : this.disputeRaisedBy,
    disputeRaisedAt: disputeRaisedAt.present
        ? disputeRaisedAt.value
        : this.disputeRaisedAt,
  );
  EscrowContract copyWithCompanion(EscrowContractsCompanion data) {
    return EscrowContract(
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      employer: data.employer.present ? data.employer.value : this.employer,
      worker: data.worker.present ? data.worker.value : this.worker,
      amount: data.amount.present ? data.amount.value : this.amount,
      termsHash: data.termsHash.present ? data.termsHash.value : this.termsHash,
      termsText: data.termsText.present ? data.termsText.value : this.termsText,
      status: data.status.present ? data.status.value : this.status,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      fundedAt: data.fundedAt.present ? data.fundedAt.value : this.fundedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      rating: data.rating.present ? data.rating.value : this.rating,
      lastTxSignature: data.lastTxSignature.present
          ? data.lastTxSignature.value
          : this.lastTxSignature,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      isToken: data.isToken.present ? data.isToken.value : this.isToken,
      tokenMint: data.tokenMint.present ? data.tokenMint.value : this.tokenMint,
      disputeReason: data.disputeReason.present
          ? data.disputeReason.value
          : this.disputeReason,
      disputeDetails: data.disputeDetails.present
          ? data.disputeDetails.value
          : this.disputeDetails,
      disputeEvidenceUri: data.disputeEvidenceUri.present
          ? data.disputeEvidenceUri.value
          : this.disputeEvidenceUri,
      disputeRaisedBy: data.disputeRaisedBy.present
          ? data.disputeRaisedBy.value
          : this.disputeRaisedBy,
      disputeRaisedAt: data.disputeRaisedAt.present
          ? data.disputeRaisedAt.value
          : this.disputeRaisedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EscrowContract(')
          ..write('contractId: $contractId, ')
          ..write('employer: $employer, ')
          ..write('worker: $worker, ')
          ..write('amount: $amount, ')
          ..write('termsHash: $termsHash, ')
          ..write('termsText: $termsText, ')
          ..write('status: $status, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('fundedAt: $fundedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rating: $rating, ')
          ..write('lastTxSignature: $lastTxSignature, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isToken: $isToken, ')
          ..write('tokenMint: $tokenMint, ')
          ..write('disputeReason: $disputeReason, ')
          ..write('disputeDetails: $disputeDetails, ')
          ..write('disputeEvidenceUri: $disputeEvidenceUri, ')
          ..write('disputeRaisedBy: $disputeRaisedBy, ')
          ..write('disputeRaisedAt: $disputeRaisedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    contractId,
    employer,
    worker,
    amount,
    termsHash,
    termsText,
    status,
    deadline,
    createdAt,
    fundedAt,
    completedAt,
    rating,
    lastTxSignature,
    syncedAt,
    isToken,
    tokenMint,
    disputeReason,
    disputeDetails,
    disputeEvidenceUri,
    disputeRaisedBy,
    disputeRaisedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EscrowContract &&
          other.contractId == this.contractId &&
          other.employer == this.employer &&
          other.worker == this.worker &&
          other.amount == this.amount &&
          other.termsHash == this.termsHash &&
          other.termsText == this.termsText &&
          other.status == this.status &&
          other.deadline == this.deadline &&
          other.createdAt == this.createdAt &&
          other.fundedAt == this.fundedAt &&
          other.completedAt == this.completedAt &&
          other.rating == this.rating &&
          other.lastTxSignature == this.lastTxSignature &&
          other.syncedAt == this.syncedAt &&
          other.isToken == this.isToken &&
          other.tokenMint == this.tokenMint &&
          other.disputeReason == this.disputeReason &&
          other.disputeDetails == this.disputeDetails &&
          other.disputeEvidenceUri == this.disputeEvidenceUri &&
          other.disputeRaisedBy == this.disputeRaisedBy &&
          other.disputeRaisedAt == this.disputeRaisedAt);
}

class EscrowContractsCompanion extends UpdateCompanion<EscrowContract> {
  final Value<String> contractId;
  final Value<String> employer;
  final Value<String> worker;
  final Value<BigInt> amount;
  final Value<String> termsHash;
  final Value<String?> termsText;
  final Value<String> status;
  final Value<BigInt> deadline;
  final Value<BigInt> createdAt;
  final Value<BigInt> fundedAt;
  final Value<BigInt> completedAt;
  final Value<int> rating;
  final Value<String?> lastTxSignature;
  final Value<DateTime> syncedAt;
  final Value<bool> isToken;
  final Value<String?> tokenMint;
  final Value<String?> disputeReason;
  final Value<String?> disputeDetails;
  final Value<String?> disputeEvidenceUri;
  final Value<String?> disputeRaisedBy;
  final Value<DateTime?> disputeRaisedAt;
  final Value<int> rowid;
  const EscrowContractsCompanion({
    this.contractId = const Value.absent(),
    this.employer = const Value.absent(),
    this.worker = const Value.absent(),
    this.amount = const Value.absent(),
    this.termsHash = const Value.absent(),
    this.termsText = const Value.absent(),
    this.status = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.fundedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.lastTxSignature = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isToken = const Value.absent(),
    this.tokenMint = const Value.absent(),
    this.disputeReason = const Value.absent(),
    this.disputeDetails = const Value.absent(),
    this.disputeEvidenceUri = const Value.absent(),
    this.disputeRaisedBy = const Value.absent(),
    this.disputeRaisedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EscrowContractsCompanion.insert({
    required String contractId,
    required String employer,
    required String worker,
    required BigInt amount,
    required String termsHash,
    this.termsText = const Value.absent(),
    required String status,
    required BigInt deadline,
    required BigInt createdAt,
    required BigInt fundedAt,
    required BigInt completedAt,
    required int rating,
    this.lastTxSignature = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isToken = const Value.absent(),
    this.tokenMint = const Value.absent(),
    this.disputeReason = const Value.absent(),
    this.disputeDetails = const Value.absent(),
    this.disputeEvidenceUri = const Value.absent(),
    this.disputeRaisedBy = const Value.absent(),
    this.disputeRaisedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contractId = Value(contractId),
       employer = Value(employer),
       worker = Value(worker),
       amount = Value(amount),
       termsHash = Value(termsHash),
       status = Value(status),
       deadline = Value(deadline),
       createdAt = Value(createdAt),
       fundedAt = Value(fundedAt),
       completedAt = Value(completedAt),
       rating = Value(rating);
  static Insertable<EscrowContract> custom({
    Expression<String>? contractId,
    Expression<String>? employer,
    Expression<String>? worker,
    Expression<BigInt>? amount,
    Expression<String>? termsHash,
    Expression<String>? termsText,
    Expression<String>? status,
    Expression<BigInt>? deadline,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? fundedAt,
    Expression<BigInt>? completedAt,
    Expression<int>? rating,
    Expression<String>? lastTxSignature,
    Expression<DateTime>? syncedAt,
    Expression<bool>? isToken,
    Expression<String>? tokenMint,
    Expression<String>? disputeReason,
    Expression<String>? disputeDetails,
    Expression<String>? disputeEvidenceUri,
    Expression<String>? disputeRaisedBy,
    Expression<DateTime>? disputeRaisedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contractId != null) 'contract_id': contractId,
      if (employer != null) 'employer': employer,
      if (worker != null) 'worker': worker,
      if (amount != null) 'amount': amount,
      if (termsHash != null) 'terms_hash': termsHash,
      if (termsText != null) 'terms_text': termsText,
      if (status != null) 'status': status,
      if (deadline != null) 'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
      if (fundedAt != null) 'funded_at': fundedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rating != null) 'rating': rating,
      if (lastTxSignature != null) 'last_tx_signature': lastTxSignature,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isToken != null) 'is_token': isToken,
      if (tokenMint != null) 'token_mint': tokenMint,
      if (disputeReason != null) 'dispute_reason': disputeReason,
      if (disputeDetails != null) 'dispute_details': disputeDetails,
      if (disputeEvidenceUri != null)
        'dispute_evidence_uri': disputeEvidenceUri,
      if (disputeRaisedBy != null) 'dispute_raised_by': disputeRaisedBy,
      if (disputeRaisedAt != null) 'dispute_raised_at': disputeRaisedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EscrowContractsCompanion copyWith({
    Value<String>? contractId,
    Value<String>? employer,
    Value<String>? worker,
    Value<BigInt>? amount,
    Value<String>? termsHash,
    Value<String?>? termsText,
    Value<String>? status,
    Value<BigInt>? deadline,
    Value<BigInt>? createdAt,
    Value<BigInt>? fundedAt,
    Value<BigInt>? completedAt,
    Value<int>? rating,
    Value<String?>? lastTxSignature,
    Value<DateTime>? syncedAt,
    Value<bool>? isToken,
    Value<String?>? tokenMint,
    Value<String?>? disputeReason,
    Value<String?>? disputeDetails,
    Value<String?>? disputeEvidenceUri,
    Value<String?>? disputeRaisedBy,
    Value<DateTime?>? disputeRaisedAt,
    Value<int>? rowid,
  }) {
    return EscrowContractsCompanion(
      contractId: contractId ?? this.contractId,
      employer: employer ?? this.employer,
      worker: worker ?? this.worker,
      amount: amount ?? this.amount,
      termsHash: termsHash ?? this.termsHash,
      termsText: termsText ?? this.termsText,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      fundedAt: fundedAt ?? this.fundedAt,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      lastTxSignature: lastTxSignature ?? this.lastTxSignature,
      syncedAt: syncedAt ?? this.syncedAt,
      isToken: isToken ?? this.isToken,
      tokenMint: tokenMint ?? this.tokenMint,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeDetails: disputeDetails ?? this.disputeDetails,
      disputeEvidenceUri: disputeEvidenceUri ?? this.disputeEvidenceUri,
      disputeRaisedBy: disputeRaisedBy ?? this.disputeRaisedBy,
      disputeRaisedAt: disputeRaisedAt ?? this.disputeRaisedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (employer.present) {
      map['employer'] = Variable<String>(employer.value);
    }
    if (worker.present) {
      map['worker'] = Variable<String>(worker.value);
    }
    if (amount.present) {
      map['amount'] = Variable<BigInt>(amount.value);
    }
    if (termsHash.present) {
      map['terms_hash'] = Variable<String>(termsHash.value);
    }
    if (termsText.present) {
      map['terms_text'] = Variable<String>(termsText.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<BigInt>(deadline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (fundedAt.present) {
      map['funded_at'] = Variable<BigInt>(fundedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<BigInt>(completedAt.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (lastTxSignature.present) {
      map['last_tx_signature'] = Variable<String>(lastTxSignature.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (isToken.present) {
      map['is_token'] = Variable<bool>(isToken.value);
    }
    if (tokenMint.present) {
      map['token_mint'] = Variable<String>(tokenMint.value);
    }
    if (disputeReason.present) {
      map['dispute_reason'] = Variable<String>(disputeReason.value);
    }
    if (disputeDetails.present) {
      map['dispute_details'] = Variable<String>(disputeDetails.value);
    }
    if (disputeEvidenceUri.present) {
      map['dispute_evidence_uri'] = Variable<String>(disputeEvidenceUri.value);
    }
    if (disputeRaisedBy.present) {
      map['dispute_raised_by'] = Variable<String>(disputeRaisedBy.value);
    }
    if (disputeRaisedAt.present) {
      map['dispute_raised_at'] = Variable<DateTime>(disputeRaisedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EscrowContractsCompanion(')
          ..write('contractId: $contractId, ')
          ..write('employer: $employer, ')
          ..write('worker: $worker, ')
          ..write('amount: $amount, ')
          ..write('termsHash: $termsHash, ')
          ..write('termsText: $termsText, ')
          ..write('status: $status, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('fundedAt: $fundedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rating: $rating, ')
          ..write('lastTxSignature: $lastTxSignature, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isToken: $isToken, ')
          ..write('tokenMint: $tokenMint, ')
          ..write('disputeReason: $disputeReason, ')
          ..write('disputeDetails: $disputeDetails, ')
          ..write('disputeEvidenceUri: $disputeEvidenceUri, ')
          ..write('disputeRaisedBy: $disputeRaisedBy, ')
          ..write('disputeRaisedAt: $disputeRaisedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftContractsTable extends DraftContracts
    with TableInfo<$DraftContractsTable, DraftContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerAddressMeta = const VerificationMeta(
    'workerAddress',
  );
  @override
  late final GeneratedColumn<String> workerAddress = GeneratedColumn<String>(
    'worker_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountSolMeta = const VerificationMeta(
    'amountSol',
  );
  @override
  late final GeneratedColumn<double> amountSol = GeneratedColumn<double>(
    'amount_sol',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termsTextMeta = const VerificationMeta(
    'termsText',
  );
  @override
  late final GeneratedColumn<String> termsText = GeneratedColumn<String>(
    'terms_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<BigInt> deadline = GeneratedColumn<BigInt>(
    'deadline',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
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
  static const VerificationMeta _isTokenMeta = const VerificationMeta(
    'isToken',
  );
  @override
  late final GeneratedColumn<bool> isToken = GeneratedColumn<bool>(
    'is_token',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_token" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tokenMintMeta = const VerificationMeta(
    'tokenMint',
  );
  @override
  late final GeneratedColumn<String> tokenMint = GeneratedColumn<String>(
    'token_mint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contractId,
    workerAddress,
    amountSol,
    termsText,
    deadline,
    createdAt,
    isToken,
    tokenMint,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftContract> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('worker_address')) {
      context.handle(
        _workerAddressMeta,
        workerAddress.isAcceptableOrUnknown(
          data['worker_address']!,
          _workerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workerAddressMeta);
    }
    if (data.containsKey('amount_sol')) {
      context.handle(
        _amountSolMeta,
        amountSol.isAcceptableOrUnknown(data['amount_sol']!, _amountSolMeta),
      );
    } else if (isInserting) {
      context.missing(_amountSolMeta);
    }
    if (data.containsKey('terms_text')) {
      context.handle(
        _termsTextMeta,
        termsText.isAcceptableOrUnknown(data['terms_text']!, _termsTextMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    } else if (isInserting) {
      context.missing(_deadlineMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_token')) {
      context.handle(
        _isTokenMeta,
        isToken.isAcceptableOrUnknown(data['is_token']!, _isTokenMeta),
      );
    }
    if (data.containsKey('token_mint')) {
      context.handle(
        _tokenMintMeta,
        tokenMint.isAcceptableOrUnknown(data['token_mint']!, _tokenMintMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftContract(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      workerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_address'],
      )!,
      amountSol: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_sol'],
      )!,
      termsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terms_text'],
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}deadline'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isToken: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_token'],
      )!,
      tokenMint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_mint'],
      ),
    );
  }

  @override
  $DraftContractsTable createAlias(String alias) {
    return $DraftContractsTable(attachedDatabase, alias);
  }
}

class DraftContract extends DataClass implements Insertable<DraftContract> {
  final int id;
  final String contractId;
  final String workerAddress;
  final double amountSol;
  final String? termsText;
  final BigInt deadline;
  final DateTime createdAt;
  final bool isToken;
  final String? tokenMint;
  const DraftContract({
    required this.id,
    required this.contractId,
    required this.workerAddress,
    required this.amountSol,
    this.termsText,
    required this.deadline,
    required this.createdAt,
    required this.isToken,
    this.tokenMint,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contract_id'] = Variable<String>(contractId);
    map['worker_address'] = Variable<String>(workerAddress);
    map['amount_sol'] = Variable<double>(amountSol);
    if (!nullToAbsent || termsText != null) {
      map['terms_text'] = Variable<String>(termsText);
    }
    map['deadline'] = Variable<BigInt>(deadline);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_token'] = Variable<bool>(isToken);
    if (!nullToAbsent || tokenMint != null) {
      map['token_mint'] = Variable<String>(tokenMint);
    }
    return map;
  }

  DraftContractsCompanion toCompanion(bool nullToAbsent) {
    return DraftContractsCompanion(
      id: Value(id),
      contractId: Value(contractId),
      workerAddress: Value(workerAddress),
      amountSol: Value(amountSol),
      termsText: termsText == null && nullToAbsent
          ? const Value.absent()
          : Value(termsText),
      deadline: Value(deadline),
      createdAt: Value(createdAt),
      isToken: Value(isToken),
      tokenMint: tokenMint == null && nullToAbsent
          ? const Value.absent()
          : Value(tokenMint),
    );
  }

  factory DraftContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftContract(
      id: serializer.fromJson<int>(json['id']),
      contractId: serializer.fromJson<String>(json['contractId']),
      workerAddress: serializer.fromJson<String>(json['workerAddress']),
      amountSol: serializer.fromJson<double>(json['amountSol']),
      termsText: serializer.fromJson<String?>(json['termsText']),
      deadline: serializer.fromJson<BigInt>(json['deadline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isToken: serializer.fromJson<bool>(json['isToken']),
      tokenMint: serializer.fromJson<String?>(json['tokenMint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contractId': serializer.toJson<String>(contractId),
      'workerAddress': serializer.toJson<String>(workerAddress),
      'amountSol': serializer.toJson<double>(amountSol),
      'termsText': serializer.toJson<String?>(termsText),
      'deadline': serializer.toJson<BigInt>(deadline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isToken': serializer.toJson<bool>(isToken),
      'tokenMint': serializer.toJson<String?>(tokenMint),
    };
  }

  DraftContract copyWith({
    int? id,
    String? contractId,
    String? workerAddress,
    double? amountSol,
    Value<String?> termsText = const Value.absent(),
    BigInt? deadline,
    DateTime? createdAt,
    bool? isToken,
    Value<String?> tokenMint = const Value.absent(),
  }) => DraftContract(
    id: id ?? this.id,
    contractId: contractId ?? this.contractId,
    workerAddress: workerAddress ?? this.workerAddress,
    amountSol: amountSol ?? this.amountSol,
    termsText: termsText.present ? termsText.value : this.termsText,
    deadline: deadline ?? this.deadline,
    createdAt: createdAt ?? this.createdAt,
    isToken: isToken ?? this.isToken,
    tokenMint: tokenMint.present ? tokenMint.value : this.tokenMint,
  );
  DraftContract copyWithCompanion(DraftContractsCompanion data) {
    return DraftContract(
      id: data.id.present ? data.id.value : this.id,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      workerAddress: data.workerAddress.present
          ? data.workerAddress.value
          : this.workerAddress,
      amountSol: data.amountSol.present ? data.amountSol.value : this.amountSol,
      termsText: data.termsText.present ? data.termsText.value : this.termsText,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isToken: data.isToken.present ? data.isToken.value : this.isToken,
      tokenMint: data.tokenMint.present ? data.tokenMint.value : this.tokenMint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftContract(')
          ..write('id: $id, ')
          ..write('contractId: $contractId, ')
          ..write('workerAddress: $workerAddress, ')
          ..write('amountSol: $amountSol, ')
          ..write('termsText: $termsText, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('isToken: $isToken, ')
          ..write('tokenMint: $tokenMint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contractId,
    workerAddress,
    amountSol,
    termsText,
    deadline,
    createdAt,
    isToken,
    tokenMint,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftContract &&
          other.id == this.id &&
          other.contractId == this.contractId &&
          other.workerAddress == this.workerAddress &&
          other.amountSol == this.amountSol &&
          other.termsText == this.termsText &&
          other.deadline == this.deadline &&
          other.createdAt == this.createdAt &&
          other.isToken == this.isToken &&
          other.tokenMint == this.tokenMint);
}

class DraftContractsCompanion extends UpdateCompanion<DraftContract> {
  final Value<int> id;
  final Value<String> contractId;
  final Value<String> workerAddress;
  final Value<double> amountSol;
  final Value<String?> termsText;
  final Value<BigInt> deadline;
  final Value<DateTime> createdAt;
  final Value<bool> isToken;
  final Value<String?> tokenMint;
  const DraftContractsCompanion({
    this.id = const Value.absent(),
    this.contractId = const Value.absent(),
    this.workerAddress = const Value.absent(),
    this.amountSol = const Value.absent(),
    this.termsText = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isToken = const Value.absent(),
    this.tokenMint = const Value.absent(),
  });
  DraftContractsCompanion.insert({
    this.id = const Value.absent(),
    required String contractId,
    required String workerAddress,
    required double amountSol,
    this.termsText = const Value.absent(),
    required BigInt deadline,
    this.createdAt = const Value.absent(),
    this.isToken = const Value.absent(),
    this.tokenMint = const Value.absent(),
  }) : contractId = Value(contractId),
       workerAddress = Value(workerAddress),
       amountSol = Value(amountSol),
       deadline = Value(deadline);
  static Insertable<DraftContract> custom({
    Expression<int>? id,
    Expression<String>? contractId,
    Expression<String>? workerAddress,
    Expression<double>? amountSol,
    Expression<String>? termsText,
    Expression<BigInt>? deadline,
    Expression<DateTime>? createdAt,
    Expression<bool>? isToken,
    Expression<String>? tokenMint,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contractId != null) 'contract_id': contractId,
      if (workerAddress != null) 'worker_address': workerAddress,
      if (amountSol != null) 'amount_sol': amountSol,
      if (termsText != null) 'terms_text': termsText,
      if (deadline != null) 'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
      if (isToken != null) 'is_token': isToken,
      if (tokenMint != null) 'token_mint': tokenMint,
    });
  }

  DraftContractsCompanion copyWith({
    Value<int>? id,
    Value<String>? contractId,
    Value<String>? workerAddress,
    Value<double>? amountSol,
    Value<String?>? termsText,
    Value<BigInt>? deadline,
    Value<DateTime>? createdAt,
    Value<bool>? isToken,
    Value<String?>? tokenMint,
  }) {
    return DraftContractsCompanion(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      workerAddress: workerAddress ?? this.workerAddress,
      amountSol: amountSol ?? this.amountSol,
      termsText: termsText ?? this.termsText,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      isToken: isToken ?? this.isToken,
      tokenMint: tokenMint ?? this.tokenMint,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (workerAddress.present) {
      map['worker_address'] = Variable<String>(workerAddress.value);
    }
    if (amountSol.present) {
      map['amount_sol'] = Variable<double>(amountSol.value);
    }
    if (termsText.present) {
      map['terms_text'] = Variable<String>(termsText.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<BigInt>(deadline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isToken.present) {
      map['is_token'] = Variable<bool>(isToken.value);
    }
    if (tokenMint.present) {
      map['token_mint'] = Variable<String>(tokenMint.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftContractsCompanion(')
          ..write('id: $id, ')
          ..write('contractId: $contractId, ')
          ..write('workerAddress: $workerAddress, ')
          ..write('amountSol: $amountSol, ')
          ..write('termsText: $termsText, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('isToken: $isToken, ')
          ..write('tokenMint: $tokenMint')
          ..write(')'))
        .toString();
  }
}

class $SeekerAttestationsTable extends SeekerAttestations
    with TableInfo<$SeekerAttestationsTable, SeekerAttestation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeekerAttestationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAttestedMeta = const VerificationMeta(
    'isAttested',
  );
  @override
  late final GeneratedColumn<bool> isAttested = GeneratedColumn<bool>(
    'is_attested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_attested" IN (0, 1))',
    ),
  );
  static const VerificationMeta _stakedAmountMeta = const VerificationMeta(
    'stakedAmount',
  );
  @override
  late final GeneratedColumn<double> stakedAmount = GeneratedColumn<double>(
    'staked_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _guardianNameMeta = const VerificationMeta(
    'guardianName',
  );
  @override
  late final GeneratedColumn<String> guardianName = GeneratedColumn<String>(
    'guardian_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Helius'),
  );
  static const VerificationMeta _cooldownActiveMeta = const VerificationMeta(
    'cooldownActive',
  );
  @override
  late final GeneratedColumn<bool> cooldownActive = GeneratedColumn<bool>(
    'cooldown_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cooldown_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _txSignatureMeta = const VerificationMeta(
    'txSignature',
  );
  @override
  late final GeneratedColumn<String> txSignature = GeneratedColumn<String>(
    'tx_signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    address,
    isAttested,
    stakedAmount,
    guardianName,
    cooldownActive,
    txSignature,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seeker_attestations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeekerAttestation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('is_attested')) {
      context.handle(
        _isAttestedMeta,
        isAttested.isAcceptableOrUnknown(data['is_attested']!, _isAttestedMeta),
      );
    } else if (isInserting) {
      context.missing(_isAttestedMeta);
    }
    if (data.containsKey('staked_amount')) {
      context.handle(
        _stakedAmountMeta,
        stakedAmount.isAcceptableOrUnknown(
          data['staked_amount']!,
          _stakedAmountMeta,
        ),
      );
    }
    if (data.containsKey('guardian_name')) {
      context.handle(
        _guardianNameMeta,
        guardianName.isAcceptableOrUnknown(
          data['guardian_name']!,
          _guardianNameMeta,
        ),
      );
    }
    if (data.containsKey('cooldown_active')) {
      context.handle(
        _cooldownActiveMeta,
        cooldownActive.isAcceptableOrUnknown(
          data['cooldown_active']!,
          _cooldownActiveMeta,
        ),
      );
    }
    if (data.containsKey('tx_signature')) {
      context.handle(
        _txSignatureMeta,
        txSignature.isAcceptableOrUnknown(
          data['tx_signature']!,
          _txSignatureMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {address};
  @override
  SeekerAttestation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeekerAttestation(
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      isAttested: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_attested'],
      )!,
      stakedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}staked_amount'],
      )!,
      guardianName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guardian_name'],
      )!,
      cooldownActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cooldown_active'],
      )!,
      txSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tx_signature'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $SeekerAttestationsTable createAlias(String alias) {
    return $SeekerAttestationsTable(attachedDatabase, alias);
  }
}

class SeekerAttestation extends DataClass
    implements Insertable<SeekerAttestation> {
  final String address;
  final bool isAttested;
  final double stakedAmount;
  final String guardianName;
  final bool cooldownActive;
  final String? txSignature;
  final DateTime syncedAt;
  const SeekerAttestation({
    required this.address,
    required this.isAttested,
    required this.stakedAmount,
    required this.guardianName,
    required this.cooldownActive,
    this.txSignature,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['address'] = Variable<String>(address);
    map['is_attested'] = Variable<bool>(isAttested);
    map['staked_amount'] = Variable<double>(stakedAmount);
    map['guardian_name'] = Variable<String>(guardianName);
    map['cooldown_active'] = Variable<bool>(cooldownActive);
    if (!nullToAbsent || txSignature != null) {
      map['tx_signature'] = Variable<String>(txSignature);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  SeekerAttestationsCompanion toCompanion(bool nullToAbsent) {
    return SeekerAttestationsCompanion(
      address: Value(address),
      isAttested: Value(isAttested),
      stakedAmount: Value(stakedAmount),
      guardianName: Value(guardianName),
      cooldownActive: Value(cooldownActive),
      txSignature: txSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(txSignature),
      syncedAt: Value(syncedAt),
    );
  }

  factory SeekerAttestation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeekerAttestation(
      address: serializer.fromJson<String>(json['address']),
      isAttested: serializer.fromJson<bool>(json['isAttested']),
      stakedAmount: serializer.fromJson<double>(json['stakedAmount']),
      guardianName: serializer.fromJson<String>(json['guardianName']),
      cooldownActive: serializer.fromJson<bool>(json['cooldownActive']),
      txSignature: serializer.fromJson<String?>(json['txSignature']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'address': serializer.toJson<String>(address),
      'isAttested': serializer.toJson<bool>(isAttested),
      'stakedAmount': serializer.toJson<double>(stakedAmount),
      'guardianName': serializer.toJson<String>(guardianName),
      'cooldownActive': serializer.toJson<bool>(cooldownActive),
      'txSignature': serializer.toJson<String?>(txSignature),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  SeekerAttestation copyWith({
    String? address,
    bool? isAttested,
    double? stakedAmount,
    String? guardianName,
    bool? cooldownActive,
    Value<String?> txSignature = const Value.absent(),
    DateTime? syncedAt,
  }) => SeekerAttestation(
    address: address ?? this.address,
    isAttested: isAttested ?? this.isAttested,
    stakedAmount: stakedAmount ?? this.stakedAmount,
    guardianName: guardianName ?? this.guardianName,
    cooldownActive: cooldownActive ?? this.cooldownActive,
    txSignature: txSignature.present ? txSignature.value : this.txSignature,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  SeekerAttestation copyWithCompanion(SeekerAttestationsCompanion data) {
    return SeekerAttestation(
      address: data.address.present ? data.address.value : this.address,
      isAttested: data.isAttested.present
          ? data.isAttested.value
          : this.isAttested,
      stakedAmount: data.stakedAmount.present
          ? data.stakedAmount.value
          : this.stakedAmount,
      guardianName: data.guardianName.present
          ? data.guardianName.value
          : this.guardianName,
      cooldownActive: data.cooldownActive.present
          ? data.cooldownActive.value
          : this.cooldownActive,
      txSignature: data.txSignature.present
          ? data.txSignature.value
          : this.txSignature,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeekerAttestation(')
          ..write('address: $address, ')
          ..write('isAttested: $isAttested, ')
          ..write('stakedAmount: $stakedAmount, ')
          ..write('guardianName: $guardianName, ')
          ..write('cooldownActive: $cooldownActive, ')
          ..write('txSignature: $txSignature, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    address,
    isAttested,
    stakedAmount,
    guardianName,
    cooldownActive,
    txSignature,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeekerAttestation &&
          other.address == this.address &&
          other.isAttested == this.isAttested &&
          other.stakedAmount == this.stakedAmount &&
          other.guardianName == this.guardianName &&
          other.cooldownActive == this.cooldownActive &&
          other.txSignature == this.txSignature &&
          other.syncedAt == this.syncedAt);
}

class SeekerAttestationsCompanion extends UpdateCompanion<SeekerAttestation> {
  final Value<String> address;
  final Value<bool> isAttested;
  final Value<double> stakedAmount;
  final Value<String> guardianName;
  final Value<bool> cooldownActive;
  final Value<String?> txSignature;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const SeekerAttestationsCompanion({
    this.address = const Value.absent(),
    this.isAttested = const Value.absent(),
    this.stakedAmount = const Value.absent(),
    this.guardianName = const Value.absent(),
    this.cooldownActive = const Value.absent(),
    this.txSignature = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeekerAttestationsCompanion.insert({
    required String address,
    required bool isAttested,
    this.stakedAmount = const Value.absent(),
    this.guardianName = const Value.absent(),
    this.cooldownActive = const Value.absent(),
    this.txSignature = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : address = Value(address),
       isAttested = Value(isAttested);
  static Insertable<SeekerAttestation> custom({
    Expression<String>? address,
    Expression<bool>? isAttested,
    Expression<double>? stakedAmount,
    Expression<String>? guardianName,
    Expression<bool>? cooldownActive,
    Expression<String>? txSignature,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (address != null) 'address': address,
      if (isAttested != null) 'is_attested': isAttested,
      if (stakedAmount != null) 'staked_amount': stakedAmount,
      if (guardianName != null) 'guardian_name': guardianName,
      if (cooldownActive != null) 'cooldown_active': cooldownActive,
      if (txSignature != null) 'tx_signature': txSignature,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeekerAttestationsCompanion copyWith({
    Value<String>? address,
    Value<bool>? isAttested,
    Value<double>? stakedAmount,
    Value<String>? guardianName,
    Value<bool>? cooldownActive,
    Value<String?>? txSignature,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return SeekerAttestationsCompanion(
      address: address ?? this.address,
      isAttested: isAttested ?? this.isAttested,
      stakedAmount: stakedAmount ?? this.stakedAmount,
      guardianName: guardianName ?? this.guardianName,
      cooldownActive: cooldownActive ?? this.cooldownActive,
      txSignature: txSignature ?? this.txSignature,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isAttested.present) {
      map['is_attested'] = Variable<bool>(isAttested.value);
    }
    if (stakedAmount.present) {
      map['staked_amount'] = Variable<double>(stakedAmount.value);
    }
    if (guardianName.present) {
      map['guardian_name'] = Variable<String>(guardianName.value);
    }
    if (cooldownActive.present) {
      map['cooldown_active'] = Variable<bool>(cooldownActive.value);
    }
    if (txSignature.present) {
      map['tx_signature'] = Variable<String>(txSignature.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeekerAttestationsCompanion(')
          ..write('address: $address, ')
          ..write('isAttested: $isAttested, ')
          ..write('stakedAmount: $stakedAmount, ')
          ..write('guardianName: $guardianName, ')
          ..write('cooldownActive: $cooldownActive, ')
          ..write('txSignature: $txSignature, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisputeCasesTable extends DisputeCases
    with TableInfo<$DisputeCasesTable, DisputeCaseData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisputeCasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juror1Meta = const VerificationMeta('juror1');
  @override
  late final GeneratedColumn<String> juror1 = GeneratedColumn<String>(
    'juror1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juror2Meta = const VerificationMeta('juror2');
  @override
  late final GeneratedColumn<String> juror2 = GeneratedColumn<String>(
    'juror2',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juror3Meta = const VerificationMeta('juror3');
  @override
  late final GeneratedColumn<String> juror3 = GeneratedColumn<String>(
    'juror3',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vote1Meta = const VerificationMeta('vote1');
  @override
  late final GeneratedColumn<int> vote1 = GeneratedColumn<int>(
    'vote1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vote2Meta = const VerificationMeta('vote2');
  @override
  late final GeneratedColumn<int> vote2 = GeneratedColumn<int>(
    'vote2',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vote3Meta = const VerificationMeta('vote3');
  @override
  late final GeneratedColumn<int> vote3 = GeneratedColumn<int>(
    'vote3',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quorumOutcomeMeta = const VerificationMeta(
    'quorumOutcome',
  );
  @override
  late final GeneratedColumn<int> quorumOutcome = GeneratedColumn<int>(
    'quorum_outcome',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('voting'),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    contractId,
    juror1,
    juror2,
    juror3,
    vote1,
    vote2,
    vote3,
    quorumOutcome,
    status,
    createdAt,
    resolvedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dispute_cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisputeCaseData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('juror1')) {
      context.handle(
        _juror1Meta,
        juror1.isAcceptableOrUnknown(data['juror1']!, _juror1Meta),
      );
    } else if (isInserting) {
      context.missing(_juror1Meta);
    }
    if (data.containsKey('juror2')) {
      context.handle(
        _juror2Meta,
        juror2.isAcceptableOrUnknown(data['juror2']!, _juror2Meta),
      );
    } else if (isInserting) {
      context.missing(_juror2Meta);
    }
    if (data.containsKey('juror3')) {
      context.handle(
        _juror3Meta,
        juror3.isAcceptableOrUnknown(data['juror3']!, _juror3Meta),
      );
    } else if (isInserting) {
      context.missing(_juror3Meta);
    }
    if (data.containsKey('vote1')) {
      context.handle(
        _vote1Meta,
        vote1.isAcceptableOrUnknown(data['vote1']!, _vote1Meta),
      );
    }
    if (data.containsKey('vote2')) {
      context.handle(
        _vote2Meta,
        vote2.isAcceptableOrUnknown(data['vote2']!, _vote2Meta),
      );
    }
    if (data.containsKey('vote3')) {
      context.handle(
        _vote3Meta,
        vote3.isAcceptableOrUnknown(data['vote3']!, _vote3Meta),
      );
    }
    if (data.containsKey('quorum_outcome')) {
      context.handle(
        _quorumOutcomeMeta,
        quorumOutcome.isAcceptableOrUnknown(
          data['quorum_outcome']!,
          _quorumOutcomeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contractId};
  @override
  DisputeCaseData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisputeCaseData(
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      juror1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}juror1'],
      )!,
      juror2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}juror2'],
      )!,
      juror3: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}juror3'],
      )!,
      vote1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vote1'],
      )!,
      vote2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vote2'],
      )!,
      vote3: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vote3'],
      )!,
      quorumOutcome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quorum_outcome'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $DisputeCasesTable createAlias(String alias) {
    return $DisputeCasesTable(attachedDatabase, alias);
  }
}

class DisputeCaseData extends DataClass implements Insertable<DisputeCaseData> {
  final String contractId;
  final String juror1;
  final String juror2;
  final String juror3;
  final int vote1;
  final int vote2;
  final int vote3;
  final int quorumOutcome;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime syncedAt;
  const DisputeCaseData({
    required this.contractId,
    required this.juror1,
    required this.juror2,
    required this.juror3,
    required this.vote1,
    required this.vote2,
    required this.vote3,
    required this.quorumOutcome,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contract_id'] = Variable<String>(contractId);
    map['juror1'] = Variable<String>(juror1);
    map['juror2'] = Variable<String>(juror2);
    map['juror3'] = Variable<String>(juror3);
    map['vote1'] = Variable<int>(vote1);
    map['vote2'] = Variable<int>(vote2);
    map['vote3'] = Variable<int>(vote3);
    map['quorum_outcome'] = Variable<int>(quorumOutcome);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  DisputeCasesCompanion toCompanion(bool nullToAbsent) {
    return DisputeCasesCompanion(
      contractId: Value(contractId),
      juror1: Value(juror1),
      juror2: Value(juror2),
      juror3: Value(juror3),
      vote1: Value(vote1),
      vote2: Value(vote2),
      vote3: Value(vote3),
      quorumOutcome: Value(quorumOutcome),
      status: Value(status),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory DisputeCaseData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisputeCaseData(
      contractId: serializer.fromJson<String>(json['contractId']),
      juror1: serializer.fromJson<String>(json['juror1']),
      juror2: serializer.fromJson<String>(json['juror2']),
      juror3: serializer.fromJson<String>(json['juror3']),
      vote1: serializer.fromJson<int>(json['vote1']),
      vote2: serializer.fromJson<int>(json['vote2']),
      vote3: serializer.fromJson<int>(json['vote3']),
      quorumOutcome: serializer.fromJson<int>(json['quorumOutcome']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contractId': serializer.toJson<String>(contractId),
      'juror1': serializer.toJson<String>(juror1),
      'juror2': serializer.toJson<String>(juror2),
      'juror3': serializer.toJson<String>(juror3),
      'vote1': serializer.toJson<int>(vote1),
      'vote2': serializer.toJson<int>(vote2),
      'vote3': serializer.toJson<int>(vote3),
      'quorumOutcome': serializer.toJson<int>(quorumOutcome),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  DisputeCaseData copyWith({
    String? contractId,
    String? juror1,
    String? juror2,
    String? juror3,
    int? vote1,
    int? vote2,
    int? vote3,
    int? quorumOutcome,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
    DateTime? syncedAt,
  }) => DisputeCaseData(
    contractId: contractId ?? this.contractId,
    juror1: juror1 ?? this.juror1,
    juror2: juror2 ?? this.juror2,
    juror3: juror3 ?? this.juror3,
    vote1: vote1 ?? this.vote1,
    vote2: vote2 ?? this.vote2,
    vote3: vote3 ?? this.vote3,
    quorumOutcome: quorumOutcome ?? this.quorumOutcome,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  DisputeCaseData copyWithCompanion(DisputeCasesCompanion data) {
    return DisputeCaseData(
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      juror1: data.juror1.present ? data.juror1.value : this.juror1,
      juror2: data.juror2.present ? data.juror2.value : this.juror2,
      juror3: data.juror3.present ? data.juror3.value : this.juror3,
      vote1: data.vote1.present ? data.vote1.value : this.vote1,
      vote2: data.vote2.present ? data.vote2.value : this.vote2,
      vote3: data.vote3.present ? data.vote3.value : this.vote3,
      quorumOutcome: data.quorumOutcome.present
          ? data.quorumOutcome.value
          : this.quorumOutcome,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisputeCaseData(')
          ..write('contractId: $contractId, ')
          ..write('juror1: $juror1, ')
          ..write('juror2: $juror2, ')
          ..write('juror3: $juror3, ')
          ..write('vote1: $vote1, ')
          ..write('vote2: $vote2, ')
          ..write('vote3: $vote3, ')
          ..write('quorumOutcome: $quorumOutcome, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contractId,
    juror1,
    juror2,
    juror3,
    vote1,
    vote2,
    vote3,
    quorumOutcome,
    status,
    createdAt,
    resolvedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisputeCaseData &&
          other.contractId == this.contractId &&
          other.juror1 == this.juror1 &&
          other.juror2 == this.juror2 &&
          other.juror3 == this.juror3 &&
          other.vote1 == this.vote1 &&
          other.vote2 == this.vote2 &&
          other.vote3 == this.vote3 &&
          other.quorumOutcome == this.quorumOutcome &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt &&
          other.syncedAt == this.syncedAt);
}

class DisputeCasesCompanion extends UpdateCompanion<DisputeCaseData> {
  final Value<String> contractId;
  final Value<String> juror1;
  final Value<String> juror2;
  final Value<String> juror3;
  final Value<int> vote1;
  final Value<int> vote2;
  final Value<int> vote3;
  final Value<int> quorumOutcome;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const DisputeCasesCompanion({
    this.contractId = const Value.absent(),
    this.juror1 = const Value.absent(),
    this.juror2 = const Value.absent(),
    this.juror3 = const Value.absent(),
    this.vote1 = const Value.absent(),
    this.vote2 = const Value.absent(),
    this.vote3 = const Value.absent(),
    this.quorumOutcome = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisputeCasesCompanion.insert({
    required String contractId,
    required String juror1,
    required String juror2,
    required String juror3,
    this.vote1 = const Value.absent(),
    this.vote2 = const Value.absent(),
    this.vote3 = const Value.absent(),
    this.quorumOutcome = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.resolvedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contractId = Value(contractId),
       juror1 = Value(juror1),
       juror2 = Value(juror2),
       juror3 = Value(juror3),
       createdAt = Value(createdAt);
  static Insertable<DisputeCaseData> custom({
    Expression<String>? contractId,
    Expression<String>? juror1,
    Expression<String>? juror2,
    Expression<String>? juror3,
    Expression<int>? vote1,
    Expression<int>? vote2,
    Expression<int>? vote3,
    Expression<int>? quorumOutcome,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contractId != null) 'contract_id': contractId,
      if (juror1 != null) 'juror1': juror1,
      if (juror2 != null) 'juror2': juror2,
      if (juror3 != null) 'juror3': juror3,
      if (vote1 != null) 'vote1': vote1,
      if (vote2 != null) 'vote2': vote2,
      if (vote3 != null) 'vote3': vote3,
      if (quorumOutcome != null) 'quorum_outcome': quorumOutcome,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisputeCasesCompanion copyWith({
    Value<String>? contractId,
    Value<String>? juror1,
    Value<String>? juror2,
    Value<String>? juror3,
    Value<int>? vote1,
    Value<int>? vote2,
    Value<int>? vote3,
    Value<int>? quorumOutcome,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return DisputeCasesCompanion(
      contractId: contractId ?? this.contractId,
      juror1: juror1 ?? this.juror1,
      juror2: juror2 ?? this.juror2,
      juror3: juror3 ?? this.juror3,
      vote1: vote1 ?? this.vote1,
      vote2: vote2 ?? this.vote2,
      vote3: vote3 ?? this.vote3,
      quorumOutcome: quorumOutcome ?? this.quorumOutcome,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (juror1.present) {
      map['juror1'] = Variable<String>(juror1.value);
    }
    if (juror2.present) {
      map['juror2'] = Variable<String>(juror2.value);
    }
    if (juror3.present) {
      map['juror3'] = Variable<String>(juror3.value);
    }
    if (vote1.present) {
      map['vote1'] = Variable<int>(vote1.value);
    }
    if (vote2.present) {
      map['vote2'] = Variable<int>(vote2.value);
    }
    if (vote3.present) {
      map['vote3'] = Variable<int>(vote3.value);
    }
    if (quorumOutcome.present) {
      map['quorum_outcome'] = Variable<int>(quorumOutcome.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisputeCasesCompanion(')
          ..write('contractId: $contractId, ')
          ..write('juror1: $juror1, ')
          ..write('juror2: $juror2, ')
          ..write('juror3: $juror3, ')
          ..write('vote1: $vote1, ')
          ..write('vote2: $vote2, ')
          ..write('vote3: $vote3, ')
          ..write('quorumOutcome: $quorumOutcome, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeliverableSubmissionsTable extends DeliverableSubmissions
    with TableInfo<$DeliverableSubmissionsTable, DeliverableSubmissionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliverableSubmissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submitterAddressMeta = const VerificationMeta(
    'submitterAddress',
  );
  @override
  late final GeneratedColumn<String> submitterAddress = GeneratedColumn<String>(
    'submitter_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
    'encrypted_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ivMeta = const VerificationMeta('iv');
  @override
  late final GeneratedColumn<String> iv = GeneratedColumn<String>(
    'iv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authTagMeta = const VerificationMeta(
    'authTag',
  );
  @override
  late final GeneratedColumn<String> authTag = GeneratedColumn<String>(
    'auth_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _plaintextHashMeta = const VerificationMeta(
    'plaintextHash',
  );
  @override
  late final GeneratedColumn<String> plaintextHash = GeneratedColumn<String>(
    'plaintext_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arweaveTxIdMeta = const VerificationMeta(
    'arweaveTxId',
  );
  @override
  late final GeneratedColumn<String> arweaveTxId = GeneratedColumn<String>(
    'arweave_tx_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('submitted'),
  );
  static const VerificationMeta _decryptionKeyHashMeta = const VerificationMeta(
    'decryptionKeyHash',
  );
  @override
  late final GeneratedColumn<String> decryptionKeyHash =
      GeneratedColumn<String>(
        'decryption_key_hash',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _completionNoteMeta = const VerificationMeta(
    'completionNote',
  );
  @override
  late final GeneratedColumn<String> completionNote = GeneratedColumn<String>(
    'completion_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wrappedKeyMeta = const VerificationMeta(
    'wrappedKey',
  );
  @override
  late final GeneratedColumn<String> wrappedKey = GeneratedColumn<String>(
    'wrapped_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contractId,
    submitterAddress,
    encryptedPayload,
    iv,
    authTag,
    plaintextHash,
    arweaveTxId,
    submittedAt,
    status,
    decryptionKeyHash,
    completionNote,
    wrappedKey,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deliverable_submissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliverableSubmissionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('submitter_address')) {
      context.handle(
        _submitterAddressMeta,
        submitterAddress.isAcceptableOrUnknown(
          data['submitter_address']!,
          _submitterAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submitterAddressMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('iv')) {
      context.handle(_ivMeta, iv.isAcceptableOrUnknown(data['iv']!, _ivMeta));
    } else if (isInserting) {
      context.missing(_ivMeta);
    }
    if (data.containsKey('auth_tag')) {
      context.handle(
        _authTagMeta,
        authTag.isAcceptableOrUnknown(data['auth_tag']!, _authTagMeta),
      );
    }
    if (data.containsKey('plaintext_hash')) {
      context.handle(
        _plaintextHashMeta,
        plaintextHash.isAcceptableOrUnknown(
          data['plaintext_hash']!,
          _plaintextHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plaintextHashMeta);
    }
    if (data.containsKey('arweave_tx_id')) {
      context.handle(
        _arweaveTxIdMeta,
        arweaveTxId.isAcceptableOrUnknown(
          data['arweave_tx_id']!,
          _arweaveTxIdMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('decryption_key_hash')) {
      context.handle(
        _decryptionKeyHashMeta,
        decryptionKeyHash.isAcceptableOrUnknown(
          data['decryption_key_hash']!,
          _decryptionKeyHashMeta,
        ),
      );
    }
    if (data.containsKey('completion_note')) {
      context.handle(
        _completionNoteMeta,
        completionNote.isAcceptableOrUnknown(
          data['completion_note']!,
          _completionNoteMeta,
        ),
      );
    }
    if (data.containsKey('wrapped_key')) {
      context.handle(
        _wrappedKeyMeta,
        wrappedKey.isAcceptableOrUnknown(data['wrapped_key']!, _wrappedKeyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliverableSubmissionData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliverableSubmissionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      submitterAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitter_address'],
      )!,
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      iv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iv'],
      )!,
      authTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_tag'],
      )!,
      plaintextHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plaintext_hash'],
      )!,
      arweaveTxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arweave_tx_id'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      decryptionKeyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decryption_key_hash'],
      ),
      completionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_note'],
      ),
      wrappedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wrapped_key'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $DeliverableSubmissionsTable createAlias(String alias) {
    return $DeliverableSubmissionsTable(attachedDatabase, alias);
  }
}

class DeliverableSubmissionData extends DataClass
    implements Insertable<DeliverableSubmissionData> {
  final int id;
  final String contractId;
  final String submitterAddress;
  final String encryptedPayload;
  final String iv;
  final String authTag;
  final String plaintextHash;
  final String? arweaveTxId;
  final DateTime submittedAt;
  final String status;
  final String? decryptionKeyHash;
  final String? completionNote;
  final String? wrappedKey;
  final DateTime syncedAt;
  const DeliverableSubmissionData({
    required this.id,
    required this.contractId,
    required this.submitterAddress,
    required this.encryptedPayload,
    required this.iv,
    required this.authTag,
    required this.plaintextHash,
    this.arweaveTxId,
    required this.submittedAt,
    required this.status,
    this.decryptionKeyHash,
    this.completionNote,
    this.wrappedKey,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contract_id'] = Variable<String>(contractId);
    map['submitter_address'] = Variable<String>(submitterAddress);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    map['iv'] = Variable<String>(iv);
    map['auth_tag'] = Variable<String>(authTag);
    map['plaintext_hash'] = Variable<String>(plaintextHash);
    if (!nullToAbsent || arweaveTxId != null) {
      map['arweave_tx_id'] = Variable<String>(arweaveTxId);
    }
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || decryptionKeyHash != null) {
      map['decryption_key_hash'] = Variable<String>(decryptionKeyHash);
    }
    if (!nullToAbsent || completionNote != null) {
      map['completion_note'] = Variable<String>(completionNote);
    }
    if (!nullToAbsent || wrappedKey != null) {
      map['wrapped_key'] = Variable<String>(wrappedKey);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  DeliverableSubmissionsCompanion toCompanion(bool nullToAbsent) {
    return DeliverableSubmissionsCompanion(
      id: Value(id),
      contractId: Value(contractId),
      submitterAddress: Value(submitterAddress),
      encryptedPayload: Value(encryptedPayload),
      iv: Value(iv),
      authTag: Value(authTag),
      plaintextHash: Value(plaintextHash),
      arweaveTxId: arweaveTxId == null && nullToAbsent
          ? const Value.absent()
          : Value(arweaveTxId),
      submittedAt: Value(submittedAt),
      status: Value(status),
      decryptionKeyHash: decryptionKeyHash == null && nullToAbsent
          ? const Value.absent()
          : Value(decryptionKeyHash),
      completionNote: completionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(completionNote),
      wrappedKey: wrappedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(wrappedKey),
      syncedAt: Value(syncedAt),
    );
  }

  factory DeliverableSubmissionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliverableSubmissionData(
      id: serializer.fromJson<int>(json['id']),
      contractId: serializer.fromJson<String>(json['contractId']),
      submitterAddress: serializer.fromJson<String>(json['submitterAddress']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
      iv: serializer.fromJson<String>(json['iv']),
      authTag: serializer.fromJson<String>(json['authTag']),
      plaintextHash: serializer.fromJson<String>(json['plaintextHash']),
      arweaveTxId: serializer.fromJson<String?>(json['arweaveTxId']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
      status: serializer.fromJson<String>(json['status']),
      decryptionKeyHash: serializer.fromJson<String?>(
        json['decryptionKeyHash'],
      ),
      completionNote: serializer.fromJson<String?>(json['completionNote']),
      wrappedKey: serializer.fromJson<String?>(json['wrappedKey']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contractId': serializer.toJson<String>(contractId),
      'submitterAddress': serializer.toJson<String>(submitterAddress),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
      'iv': serializer.toJson<String>(iv),
      'authTag': serializer.toJson<String>(authTag),
      'plaintextHash': serializer.toJson<String>(plaintextHash),
      'arweaveTxId': serializer.toJson<String?>(arweaveTxId),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
      'status': serializer.toJson<String>(status),
      'decryptionKeyHash': serializer.toJson<String?>(decryptionKeyHash),
      'completionNote': serializer.toJson<String?>(completionNote),
      'wrappedKey': serializer.toJson<String?>(wrappedKey),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  DeliverableSubmissionData copyWith({
    int? id,
    String? contractId,
    String? submitterAddress,
    String? encryptedPayload,
    String? iv,
    String? authTag,
    String? plaintextHash,
    Value<String?> arweaveTxId = const Value.absent(),
    DateTime? submittedAt,
    String? status,
    Value<String?> decryptionKeyHash = const Value.absent(),
    Value<String?> completionNote = const Value.absent(),
    Value<String?> wrappedKey = const Value.absent(),
    DateTime? syncedAt,
  }) => DeliverableSubmissionData(
    id: id ?? this.id,
    contractId: contractId ?? this.contractId,
    submitterAddress: submitterAddress ?? this.submitterAddress,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    iv: iv ?? this.iv,
    authTag: authTag ?? this.authTag,
    plaintextHash: plaintextHash ?? this.plaintextHash,
    arweaveTxId: arweaveTxId.present ? arweaveTxId.value : this.arweaveTxId,
    submittedAt: submittedAt ?? this.submittedAt,
    status: status ?? this.status,
    decryptionKeyHash: decryptionKeyHash.present
        ? decryptionKeyHash.value
        : this.decryptionKeyHash,
    completionNote: completionNote.present
        ? completionNote.value
        : this.completionNote,
    wrappedKey: wrappedKey.present ? wrappedKey.value : this.wrappedKey,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  DeliverableSubmissionData copyWithCompanion(
    DeliverableSubmissionsCompanion data,
  ) {
    return DeliverableSubmissionData(
      id: data.id.present ? data.id.value : this.id,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      submitterAddress: data.submitterAddress.present
          ? data.submitterAddress.value
          : this.submitterAddress,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      iv: data.iv.present ? data.iv.value : this.iv,
      authTag: data.authTag.present ? data.authTag.value : this.authTag,
      plaintextHash: data.plaintextHash.present
          ? data.plaintextHash.value
          : this.plaintextHash,
      arweaveTxId: data.arweaveTxId.present
          ? data.arweaveTxId.value
          : this.arweaveTxId,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      status: data.status.present ? data.status.value : this.status,
      decryptionKeyHash: data.decryptionKeyHash.present
          ? data.decryptionKeyHash.value
          : this.decryptionKeyHash,
      completionNote: data.completionNote.present
          ? data.completionNote.value
          : this.completionNote,
      wrappedKey: data.wrappedKey.present
          ? data.wrappedKey.value
          : this.wrappedKey,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliverableSubmissionData(')
          ..write('id: $id, ')
          ..write('contractId: $contractId, ')
          ..write('submitterAddress: $submitterAddress, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('iv: $iv, ')
          ..write('authTag: $authTag, ')
          ..write('plaintextHash: $plaintextHash, ')
          ..write('arweaveTxId: $arweaveTxId, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('status: $status, ')
          ..write('decryptionKeyHash: $decryptionKeyHash, ')
          ..write('completionNote: $completionNote, ')
          ..write('wrappedKey: $wrappedKey, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contractId,
    submitterAddress,
    encryptedPayload,
    iv,
    authTag,
    plaintextHash,
    arweaveTxId,
    submittedAt,
    status,
    decryptionKeyHash,
    completionNote,
    wrappedKey,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliverableSubmissionData &&
          other.id == this.id &&
          other.contractId == this.contractId &&
          other.submitterAddress == this.submitterAddress &&
          other.encryptedPayload == this.encryptedPayload &&
          other.iv == this.iv &&
          other.authTag == this.authTag &&
          other.plaintextHash == this.plaintextHash &&
          other.arweaveTxId == this.arweaveTxId &&
          other.submittedAt == this.submittedAt &&
          other.status == this.status &&
          other.decryptionKeyHash == this.decryptionKeyHash &&
          other.completionNote == this.completionNote &&
          other.wrappedKey == this.wrappedKey &&
          other.syncedAt == this.syncedAt);
}

class DeliverableSubmissionsCompanion
    extends UpdateCompanion<DeliverableSubmissionData> {
  final Value<int> id;
  final Value<String> contractId;
  final Value<String> submitterAddress;
  final Value<String> encryptedPayload;
  final Value<String> iv;
  final Value<String> authTag;
  final Value<String> plaintextHash;
  final Value<String?> arweaveTxId;
  final Value<DateTime> submittedAt;
  final Value<String> status;
  final Value<String?> decryptionKeyHash;
  final Value<String?> completionNote;
  final Value<String?> wrappedKey;
  final Value<DateTime> syncedAt;
  const DeliverableSubmissionsCompanion({
    this.id = const Value.absent(),
    this.contractId = const Value.absent(),
    this.submitterAddress = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.iv = const Value.absent(),
    this.authTag = const Value.absent(),
    this.plaintextHash = const Value.absent(),
    this.arweaveTxId = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.decryptionKeyHash = const Value.absent(),
    this.completionNote = const Value.absent(),
    this.wrappedKey = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  DeliverableSubmissionsCompanion.insert({
    this.id = const Value.absent(),
    required String contractId,
    required String submitterAddress,
    required String encryptedPayload,
    required String iv,
    this.authTag = const Value.absent(),
    required String plaintextHash,
    this.arweaveTxId = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.decryptionKeyHash = const Value.absent(),
    this.completionNote = const Value.absent(),
    this.wrappedKey = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : contractId = Value(contractId),
       submitterAddress = Value(submitterAddress),
       encryptedPayload = Value(encryptedPayload),
       iv = Value(iv),
       plaintextHash = Value(plaintextHash);
  static Insertable<DeliverableSubmissionData> custom({
    Expression<int>? id,
    Expression<String>? contractId,
    Expression<String>? submitterAddress,
    Expression<String>? encryptedPayload,
    Expression<String>? iv,
    Expression<String>? authTag,
    Expression<String>? plaintextHash,
    Expression<String>? arweaveTxId,
    Expression<DateTime>? submittedAt,
    Expression<String>? status,
    Expression<String>? decryptionKeyHash,
    Expression<String>? completionNote,
    Expression<String>? wrappedKey,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contractId != null) 'contract_id': contractId,
      if (submitterAddress != null) 'submitter_address': submitterAddress,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (iv != null) 'iv': iv,
      if (authTag != null) 'auth_tag': authTag,
      if (plaintextHash != null) 'plaintext_hash': plaintextHash,
      if (arweaveTxId != null) 'arweave_tx_id': arweaveTxId,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (status != null) 'status': status,
      if (decryptionKeyHash != null) 'decryption_key_hash': decryptionKeyHash,
      if (completionNote != null) 'completion_note': completionNote,
      if (wrappedKey != null) 'wrapped_key': wrappedKey,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  DeliverableSubmissionsCompanion copyWith({
    Value<int>? id,
    Value<String>? contractId,
    Value<String>? submitterAddress,
    Value<String>? encryptedPayload,
    Value<String>? iv,
    Value<String>? authTag,
    Value<String>? plaintextHash,
    Value<String?>? arweaveTxId,
    Value<DateTime>? submittedAt,
    Value<String>? status,
    Value<String?>? decryptionKeyHash,
    Value<String?>? completionNote,
    Value<String?>? wrappedKey,
    Value<DateTime>? syncedAt,
  }) {
    return DeliverableSubmissionsCompanion(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      submitterAddress: submitterAddress ?? this.submitterAddress,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      iv: iv ?? this.iv,
      authTag: authTag ?? this.authTag,
      plaintextHash: plaintextHash ?? this.plaintextHash,
      arweaveTxId: arweaveTxId ?? this.arweaveTxId,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      decryptionKeyHash: decryptionKeyHash ?? this.decryptionKeyHash,
      completionNote: completionNote ?? this.completionNote,
      wrappedKey: wrappedKey ?? this.wrappedKey,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (submitterAddress.present) {
      map['submitter_address'] = Variable<String>(submitterAddress.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
    }
    if (iv.present) {
      map['iv'] = Variable<String>(iv.value);
    }
    if (authTag.present) {
      map['auth_tag'] = Variable<String>(authTag.value);
    }
    if (plaintextHash.present) {
      map['plaintext_hash'] = Variable<String>(plaintextHash.value);
    }
    if (arweaveTxId.present) {
      map['arweave_tx_id'] = Variable<String>(arweaveTxId.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (decryptionKeyHash.present) {
      map['decryption_key_hash'] = Variable<String>(decryptionKeyHash.value);
    }
    if (completionNote.present) {
      map['completion_note'] = Variable<String>(completionNote.value);
    }
    if (wrappedKey.present) {
      map['wrapped_key'] = Variable<String>(wrappedKey.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliverableSubmissionsCompanion(')
          ..write('id: $id, ')
          ..write('contractId: $contractId, ')
          ..write('submitterAddress: $submitterAddress, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('iv: $iv, ')
          ..write('authTag: $authTag, ')
          ..write('plaintextHash: $plaintextHash, ')
          ..write('arweaveTxId: $arweaveTxId, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('status: $status, ')
          ..write('decryptionKeyHash: $decryptionKeyHash, ')
          ..write('completionNote: $completionNote, ')
          ..write('wrappedKey: $wrappedKey, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $UserEncryptionKeysTable extends UserEncryptionKeys
    with TableInfo<$UserEncryptionKeysTable, UserEncryptionKeyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserEncryptionKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walletAddressMeta = const VerificationMeta(
    'walletAddress',
  );
  @override
  late final GeneratedColumn<String> walletAddress = GeneratedColumn<String>(
    'wallet_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privateKeyMeta = const VerificationMeta(
    'privateKey',
  );
  @override
  late final GeneratedColumn<String> privateKey = GeneratedColumn<String>(
    'private_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    walletAddress,
    publicKey,
    privateKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_encryption_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEncryptionKeyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wallet_address')) {
      context.handle(
        _walletAddressMeta,
        walletAddress.isAcceptableOrUnknown(
          data['wallet_address']!,
          _walletAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_walletAddressMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('private_key')) {
      context.handle(
        _privateKeyMeta,
        privateKey.isAcceptableOrUnknown(data['private_key']!, _privateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_privateKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walletAddress};
  @override
  UserEncryptionKeyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEncryptionKeyData(
      walletAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_address'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      privateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserEncryptionKeysTable createAlias(String alias) {
    return $UserEncryptionKeysTable(attachedDatabase, alias);
  }
}

class UserEncryptionKeyData extends DataClass
    implements Insertable<UserEncryptionKeyData> {
  final String walletAddress;
  final String publicKey;
  final String privateKey;
  final DateTime createdAt;
  const UserEncryptionKeyData({
    required this.walletAddress,
    required this.publicKey,
    required this.privateKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wallet_address'] = Variable<String>(walletAddress);
    map['public_key'] = Variable<String>(publicKey);
    map['private_key'] = Variable<String>(privateKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserEncryptionKeysCompanion toCompanion(bool nullToAbsent) {
    return UserEncryptionKeysCompanion(
      walletAddress: Value(walletAddress),
      publicKey: Value(publicKey),
      privateKey: Value(privateKey),
      createdAt: Value(createdAt),
    );
  }

  factory UserEncryptionKeyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEncryptionKeyData(
      walletAddress: serializer.fromJson<String>(json['walletAddress']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      privateKey: serializer.fromJson<String>(json['privateKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walletAddress': serializer.toJson<String>(walletAddress),
      'publicKey': serializer.toJson<String>(publicKey),
      'privateKey': serializer.toJson<String>(privateKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserEncryptionKeyData copyWith({
    String? walletAddress,
    String? publicKey,
    String? privateKey,
    DateTime? createdAt,
  }) => UserEncryptionKeyData(
    walletAddress: walletAddress ?? this.walletAddress,
    publicKey: publicKey ?? this.publicKey,
    privateKey: privateKey ?? this.privateKey,
    createdAt: createdAt ?? this.createdAt,
  );
  UserEncryptionKeyData copyWithCompanion(UserEncryptionKeysCompanion data) {
    return UserEncryptionKeyData(
      walletAddress: data.walletAddress.present
          ? data.walletAddress.value
          : this.walletAddress,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      privateKey: data.privateKey.present
          ? data.privateKey.value
          : this.privateKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEncryptionKeyData(')
          ..write('walletAddress: $walletAddress, ')
          ..write('publicKey: $publicKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(walletAddress, publicKey, privateKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEncryptionKeyData &&
          other.walletAddress == this.walletAddress &&
          other.publicKey == this.publicKey &&
          other.privateKey == this.privateKey &&
          other.createdAt == this.createdAt);
}

class UserEncryptionKeysCompanion
    extends UpdateCompanion<UserEncryptionKeyData> {
  final Value<String> walletAddress;
  final Value<String> publicKey;
  final Value<String> privateKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserEncryptionKeysCompanion({
    this.walletAddress = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserEncryptionKeysCompanion.insert({
    required String walletAddress,
    required String publicKey,
    required String privateKey,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : walletAddress = Value(walletAddress),
       publicKey = Value(publicKey),
       privateKey = Value(privateKey);
  static Insertable<UserEncryptionKeyData> custom({
    Expression<String>? walletAddress,
    Expression<String>? publicKey,
    Expression<String>? privateKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (walletAddress != null) 'wallet_address': walletAddress,
      if (publicKey != null) 'public_key': publicKey,
      if (privateKey != null) 'private_key': privateKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserEncryptionKeysCompanion copyWith({
    Value<String>? walletAddress,
    Value<String>? publicKey,
    Value<String>? privateKey,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UserEncryptionKeysCompanion(
      walletAddress: walletAddress ?? this.walletAddress,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walletAddress.present) {
      map['wallet_address'] = Variable<String>(walletAddress.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (privateKey.present) {
      map['private_key'] = Variable<String>(privateKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserEncryptionKeysCompanion(')
          ..write('walletAddress: $walletAddress, ')
          ..write('publicKey: $publicKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkerProfilesTable workerProfiles = $WorkerProfilesTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  late final $DraftReviewsTable draftReviews = $DraftReviewsTable(this);
  late final $RecentLookupsTable recentLookups = $RecentLookupsTable(this);
  late final $EscrowContractsTable escrowContracts = $EscrowContractsTable(
    this,
  );
  late final $DraftContractsTable draftContracts = $DraftContractsTable(this);
  late final $SeekerAttestationsTable seekerAttestations =
      $SeekerAttestationsTable(this);
  late final $DisputeCasesTable disputeCases = $DisputeCasesTable(this);
  late final $DeliverableSubmissionsTable deliverableSubmissions =
      $DeliverableSubmissionsTable(this);
  late final $UserEncryptionKeysTable userEncryptionKeys =
      $UserEncryptionKeysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workerProfiles,
    reviews,
    draftReviews,
    recentLookups,
    escrowContracts,
    draftContracts,
    seekerAttestations,
    disputeCases,
    deliverableSubmissions,
    userEncryptionKeys,
  ];
}

typedef $$WorkerProfilesTableCreateCompanionBuilder =
    WorkerProfilesCompanion Function({
      required String address,
      required int totalJobs,
      required BigInt ratingSum,
      required BigInt createdAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$WorkerProfilesTableUpdateCompanionBuilder =
    WorkerProfilesCompanion Function({
      Value<String> address,
      Value<int> totalJobs,
      Value<BigInt> ratingSum,
      Value<BigInt> createdAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$WorkerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkerProfilesTable> {
  $$WorkerProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalJobs => $composableBuilder(
    column: $table.totalJobs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get ratingSum => $composableBuilder(
    column: $table.ratingSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkerProfilesTable> {
  $$WorkerProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalJobs => $composableBuilder(
    column: $table.totalJobs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get ratingSum => $composableBuilder(
    column: $table.ratingSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkerProfilesTable> {
  $$WorkerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get totalJobs =>
      $composableBuilder(column: $table.totalJobs, builder: (column) => column);

  GeneratedColumn<BigInt> get ratingSum =>
      $composableBuilder(column: $table.ratingSum, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$WorkerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkerProfilesTable,
          WorkerProfile,
          $$WorkerProfilesTableFilterComposer,
          $$WorkerProfilesTableOrderingComposer,
          $$WorkerProfilesTableAnnotationComposer,
          $$WorkerProfilesTableCreateCompanionBuilder,
          $$WorkerProfilesTableUpdateCompanionBuilder,
          (
            WorkerProfile,
            BaseReferences<_$AppDatabase, $WorkerProfilesTable, WorkerProfile>,
          ),
          WorkerProfile,
          PrefetchHooks Function()
        > {
  $$WorkerProfilesTableTableManager(
    _$AppDatabase db,
    $WorkerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> address = const Value.absent(),
                Value<int> totalJobs = const Value.absent(),
                Value<BigInt> ratingSum = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkerProfilesCompanion(
                address: address,
                totalJobs: totalJobs,
                ratingSum: ratingSum,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String address,
                required int totalJobs,
                required BigInt ratingSum,
                required BigInt createdAt,
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkerProfilesCompanion.insert(
                address: address,
                totalJobs: totalJobs,
                ratingSum: ratingSum,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkerProfilesTable, WorkerProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkerProfilesTable,
                    WorkerProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkerProfilesTable,
      WorkerProfile,
      $$WorkerProfilesTableFilterComposer,
      $$WorkerProfilesTableOrderingComposer,
      $$WorkerProfilesTableAnnotationComposer,
      $$WorkerProfilesTableCreateCompanionBuilder,
      $$WorkerProfilesTableUpdateCompanionBuilder,
      (
        WorkerProfile,
        BaseReferences<_$AppDatabase, $WorkerProfilesTable, WorkerProfile>,
      ),
      WorkerProfile,
      PrefetchHooks Function()
    >;
typedef $$ReviewsTableCreateCompanionBuilder =
    ReviewsCompanion Function({
      Value<int> id,
      required String workerAddress,
      required String reviewerAddress,
      required String jobId,
      required int rating,
      required BigInt timestamp,
      Value<String?> reviewNote,
      Value<String?> arweaveTxId,
      Value<DateTime> syncedAt,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<int> id,
      Value<String> workerAddress,
      Value<String> reviewerAddress,
      Value<String> jobId,
      Value<int> rating,
      Value<BigInt> timestamp,
      Value<String?> reviewNote,
      Value<String?> arweaveTxId,
      Value<DateTime> syncedAt,
    });

class $$ReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewerAddress => $composableBuilder(
    column: $table.reviewerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewNote => $composableBuilder(
    column: $table.reviewNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewerAddress => $composableBuilder(
    column: $table.reviewerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewNote => $composableBuilder(
    column: $table.reviewNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewerAddress => $composableBuilder(
    column: $table.reviewerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<BigInt> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get reviewNote => $composableBuilder(
    column: $table.reviewNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewsTable,
          Review,
          $$ReviewsTableFilterComposer,
          $$ReviewsTableOrderingComposer,
          $$ReviewsTableAnnotationComposer,
          $$ReviewsTableCreateCompanionBuilder,
          $$ReviewsTableUpdateCompanionBuilder,
          (Review, BaseReferences<_$AppDatabase, $ReviewsTable, Review>),
          Review,
          PrefetchHooks Function()
        > {
  $$ReviewsTableTableManager(_$AppDatabase db, $ReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> workerAddress = const Value.absent(),
                Value<String> reviewerAddress = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<BigInt> timestamp = const Value.absent(),
                Value<String?> reviewNote = const Value.absent(),
                Value<String?> arweaveTxId = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                workerAddress: workerAddress,
                reviewerAddress: reviewerAddress,
                jobId: jobId,
                rating: rating,
                timestamp: timestamp,
                reviewNote: reviewNote,
                arweaveTxId: arweaveTxId,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String workerAddress,
                required String reviewerAddress,
                required String jobId,
                required int rating,
                required BigInt timestamp,
                Value<String?> reviewNote = const Value.absent(),
                Value<String?> arweaveTxId = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                workerAddress: workerAddress,
                reviewerAddress: reviewerAddress,
                jobId: jobId,
                rating: rating,
                timestamp: timestamp,
                reviewNote: reviewNote,
                arweaveTxId: arweaveTxId,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewsTable, Review>(table),
                  BaseReferences<_$AppDatabase, $ReviewsTable, Review>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewsTable,
      Review,
      $$ReviewsTableFilterComposer,
      $$ReviewsTableOrderingComposer,
      $$ReviewsTableAnnotationComposer,
      $$ReviewsTableCreateCompanionBuilder,
      $$ReviewsTableUpdateCompanionBuilder,
      (Review, BaseReferences<_$AppDatabase, $ReviewsTable, Review>),
      Review,
      PrefetchHooks Function()
    >;
typedef $$DraftReviewsTableCreateCompanionBuilder =
    DraftReviewsCompanion Function({
      Value<int> id,
      required String workerAddress,
      required String jobId,
      required int rating,
      Value<String?> notes,
      Value<String?> arweaveTxId,
      Value<DateTime> createdAt,
      Value<String> status,
    });
typedef $$DraftReviewsTableUpdateCompanionBuilder =
    DraftReviewsCompanion Function({
      Value<int> id,
      Value<String> workerAddress,
      Value<String> jobId,
      Value<int> rating,
      Value<String?> notes,
      Value<String?> arweaveTxId,
      Value<DateTime> createdAt,
      Value<String> status,
    });

class $$DraftReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftReviewsTable> {
  $$DraftReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftReviewsTable> {
  $$DraftReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftReviewsTable> {
  $$DraftReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$DraftReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftReviewsTable,
          DraftReview,
          $$DraftReviewsTableFilterComposer,
          $$DraftReviewsTableOrderingComposer,
          $$DraftReviewsTableAnnotationComposer,
          $$DraftReviewsTableCreateCompanionBuilder,
          $$DraftReviewsTableUpdateCompanionBuilder,
          (
            DraftReview,
            BaseReferences<_$AppDatabase, $DraftReviewsTable, DraftReview>,
          ),
          DraftReview,
          PrefetchHooks Function()
        > {
  $$DraftReviewsTableTableManager(_$AppDatabase db, $DraftReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> workerAddress = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> arweaveTxId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DraftReviewsCompanion(
                id: id,
                workerAddress: workerAddress,
                jobId: jobId,
                rating: rating,
                notes: notes,
                arweaveTxId: arweaveTxId,
                createdAt: createdAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String workerAddress,
                required String jobId,
                required int rating,
                Value<String?> notes = const Value.absent(),
                Value<String?> arweaveTxId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DraftReviewsCompanion.insert(
                id: id,
                workerAddress: workerAddress,
                jobId: jobId,
                rating: rating,
                notes: notes,
                arweaveTxId: arweaveTxId,
                createdAt: createdAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftReviewsTable, DraftReview>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DraftReviewsTable,
                    DraftReview
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftReviewsTable,
      DraftReview,
      $$DraftReviewsTableFilterComposer,
      $$DraftReviewsTableOrderingComposer,
      $$DraftReviewsTableAnnotationComposer,
      $$DraftReviewsTableCreateCompanionBuilder,
      $$DraftReviewsTableUpdateCompanionBuilder,
      (
        DraftReview,
        BaseReferences<_$AppDatabase, $DraftReviewsTable, DraftReview>,
      ),
      DraftReview,
      PrefetchHooks Function()
    >;
typedef $$RecentLookupsTableCreateCompanionBuilder =
    RecentLookupsCompanion Function({
      required String address,
      Value<DateTime> lastViewedAt,
      Value<int> rowid,
    });
typedef $$RecentLookupsTableUpdateCompanionBuilder =
    RecentLookupsCompanion Function({
      Value<String> address,
      Value<DateTime> lastViewedAt,
      Value<int> rowid,
    });

class $$RecentLookupsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentLookupsTable> {
  $$RecentLookupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentLookupsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentLookupsTable> {
  $$RecentLookupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentLookupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentLookupsTable> {
  $$RecentLookupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<DateTime> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => column,
  );
}

class $$RecentLookupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentLookupsTable,
          RecentLookup,
          $$RecentLookupsTableFilterComposer,
          $$RecentLookupsTableOrderingComposer,
          $$RecentLookupsTableAnnotationComposer,
          $$RecentLookupsTableCreateCompanionBuilder,
          $$RecentLookupsTableUpdateCompanionBuilder,
          (
            RecentLookup,
            BaseReferences<_$AppDatabase, $RecentLookupsTable, RecentLookup>,
          ),
          RecentLookup,
          PrefetchHooks Function()
        > {
  $$RecentLookupsTableTableManager(_$AppDatabase db, $RecentLookupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentLookupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentLookupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentLookupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> address = const Value.absent(),
                Value<DateTime> lastViewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentLookupsCompanion(
                address: address,
                lastViewedAt: lastViewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String address,
                Value<DateTime> lastViewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentLookupsCompanion.insert(
                address: address,
                lastViewedAt: lastViewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecentLookupsTable, RecentLookup>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecentLookupsTable,
                    RecentLookup
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentLookupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentLookupsTable,
      RecentLookup,
      $$RecentLookupsTableFilterComposer,
      $$RecentLookupsTableOrderingComposer,
      $$RecentLookupsTableAnnotationComposer,
      $$RecentLookupsTableCreateCompanionBuilder,
      $$RecentLookupsTableUpdateCompanionBuilder,
      (
        RecentLookup,
        BaseReferences<_$AppDatabase, $RecentLookupsTable, RecentLookup>,
      ),
      RecentLookup,
      PrefetchHooks Function()
    >;
typedef $$EscrowContractsTableCreateCompanionBuilder =
    EscrowContractsCompanion Function({
      required String contractId,
      required String employer,
      required String worker,
      required BigInt amount,
      required String termsHash,
      Value<String?> termsText,
      required String status,
      required BigInt deadline,
      required BigInt createdAt,
      required BigInt fundedAt,
      required BigInt completedAt,
      required int rating,
      Value<String?> lastTxSignature,
      Value<DateTime> syncedAt,
      Value<bool> isToken,
      Value<String?> tokenMint,
      Value<String?> disputeReason,
      Value<String?> disputeDetails,
      Value<String?> disputeEvidenceUri,
      Value<String?> disputeRaisedBy,
      Value<DateTime?> disputeRaisedAt,
      Value<int> rowid,
    });
typedef $$EscrowContractsTableUpdateCompanionBuilder =
    EscrowContractsCompanion Function({
      Value<String> contractId,
      Value<String> employer,
      Value<String> worker,
      Value<BigInt> amount,
      Value<String> termsHash,
      Value<String?> termsText,
      Value<String> status,
      Value<BigInt> deadline,
      Value<BigInt> createdAt,
      Value<BigInt> fundedAt,
      Value<BigInt> completedAt,
      Value<int> rating,
      Value<String?> lastTxSignature,
      Value<DateTime> syncedAt,
      Value<bool> isToken,
      Value<String?> tokenMint,
      Value<String?> disputeReason,
      Value<String?> disputeDetails,
      Value<String?> disputeEvidenceUri,
      Value<String?> disputeRaisedBy,
      Value<DateTime?> disputeRaisedAt,
      Value<int> rowid,
    });

class $$EscrowContractsTableFilterComposer
    extends Composer<_$AppDatabase, $EscrowContractsTable> {
  $$EscrowContractsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employer => $composableBuilder(
    column: $table.employer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worker => $composableBuilder(
    column: $table.worker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termsHash => $composableBuilder(
    column: $table.termsHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termsText => $composableBuilder(
    column: $table.termsText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get fundedAt => $composableBuilder(
    column: $table.fundedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTxSignature => $composableBuilder(
    column: $table.lastTxSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isToken => $composableBuilder(
    column: $table.isToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenMint => $composableBuilder(
    column: $table.tokenMint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disputeReason => $composableBuilder(
    column: $table.disputeReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disputeDetails => $composableBuilder(
    column: $table.disputeDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disputeEvidenceUri => $composableBuilder(
    column: $table.disputeEvidenceUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disputeRaisedBy => $composableBuilder(
    column: $table.disputeRaisedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get disputeRaisedAt => $composableBuilder(
    column: $table.disputeRaisedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EscrowContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $EscrowContractsTable> {
  $$EscrowContractsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employer => $composableBuilder(
    column: $table.employer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worker => $composableBuilder(
    column: $table.worker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termsHash => $composableBuilder(
    column: $table.termsHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termsText => $composableBuilder(
    column: $table.termsText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get fundedAt => $composableBuilder(
    column: $table.fundedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTxSignature => $composableBuilder(
    column: $table.lastTxSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isToken => $composableBuilder(
    column: $table.isToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenMint => $composableBuilder(
    column: $table.tokenMint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disputeReason => $composableBuilder(
    column: $table.disputeReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disputeDetails => $composableBuilder(
    column: $table.disputeDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disputeEvidenceUri => $composableBuilder(
    column: $table.disputeEvidenceUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disputeRaisedBy => $composableBuilder(
    column: $table.disputeRaisedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get disputeRaisedAt => $composableBuilder(
    column: $table.disputeRaisedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EscrowContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EscrowContractsTable> {
  $$EscrowContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employer =>
      $composableBuilder(column: $table.employer, builder: (column) => column);

  GeneratedColumn<String> get worker =>
      $composableBuilder(column: $table.worker, builder: (column) => column);

  GeneratedColumn<BigInt> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get termsHash =>
      $composableBuilder(column: $table.termsHash, builder: (column) => column);

  GeneratedColumn<String> get termsText =>
      $composableBuilder(column: $table.termsText, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<BigInt> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get fundedAt =>
      $composableBuilder(column: $table.fundedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get lastTxSignature => $composableBuilder(
    column: $table.lastTxSignature,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<bool> get isToken =>
      $composableBuilder(column: $table.isToken, builder: (column) => column);

  GeneratedColumn<String> get tokenMint =>
      $composableBuilder(column: $table.tokenMint, builder: (column) => column);

  GeneratedColumn<String> get disputeReason => $composableBuilder(
    column: $table.disputeReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get disputeDetails => $composableBuilder(
    column: $table.disputeDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get disputeEvidenceUri => $composableBuilder(
    column: $table.disputeEvidenceUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get disputeRaisedBy => $composableBuilder(
    column: $table.disputeRaisedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get disputeRaisedAt => $composableBuilder(
    column: $table.disputeRaisedAt,
    builder: (column) => column,
  );
}

class $$EscrowContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EscrowContractsTable,
          EscrowContract,
          $$EscrowContractsTableFilterComposer,
          $$EscrowContractsTableOrderingComposer,
          $$EscrowContractsTableAnnotationComposer,
          $$EscrowContractsTableCreateCompanionBuilder,
          $$EscrowContractsTableUpdateCompanionBuilder,
          (
            EscrowContract,
            BaseReferences<
              _$AppDatabase,
              $EscrowContractsTable,
              EscrowContract
            >,
          ),
          EscrowContract,
          PrefetchHooks Function()
        > {
  $$EscrowContractsTableTableManager(
    _$AppDatabase db,
    $EscrowContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EscrowContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EscrowContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EscrowContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contractId = const Value.absent(),
                Value<String> employer = const Value.absent(),
                Value<String> worker = const Value.absent(),
                Value<BigInt> amount = const Value.absent(),
                Value<String> termsHash = const Value.absent(),
                Value<String?> termsText = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<BigInt> deadline = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt> fundedAt = const Value.absent(),
                Value<BigInt> completedAt = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String?> lastTxSignature = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<bool> isToken = const Value.absent(),
                Value<String?> tokenMint = const Value.absent(),
                Value<String?> disputeReason = const Value.absent(),
                Value<String?> disputeDetails = const Value.absent(),
                Value<String?> disputeEvidenceUri = const Value.absent(),
                Value<String?> disputeRaisedBy = const Value.absent(),
                Value<DateTime?> disputeRaisedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EscrowContractsCompanion(
                contractId: contractId,
                employer: employer,
                worker: worker,
                amount: amount,
                termsHash: termsHash,
                termsText: termsText,
                status: status,
                deadline: deadline,
                createdAt: createdAt,
                fundedAt: fundedAt,
                completedAt: completedAt,
                rating: rating,
                lastTxSignature: lastTxSignature,
                syncedAt: syncedAt,
                isToken: isToken,
                tokenMint: tokenMint,
                disputeReason: disputeReason,
                disputeDetails: disputeDetails,
                disputeEvidenceUri: disputeEvidenceUri,
                disputeRaisedBy: disputeRaisedBy,
                disputeRaisedAt: disputeRaisedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contractId,
                required String employer,
                required String worker,
                required BigInt amount,
                required String termsHash,
                Value<String?> termsText = const Value.absent(),
                required String status,
                required BigInt deadline,
                required BigInt createdAt,
                required BigInt fundedAt,
                required BigInt completedAt,
                required int rating,
                Value<String?> lastTxSignature = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<bool> isToken = const Value.absent(),
                Value<String?> tokenMint = const Value.absent(),
                Value<String?> disputeReason = const Value.absent(),
                Value<String?> disputeDetails = const Value.absent(),
                Value<String?> disputeEvidenceUri = const Value.absent(),
                Value<String?> disputeRaisedBy = const Value.absent(),
                Value<DateTime?> disputeRaisedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EscrowContractsCompanion.insert(
                contractId: contractId,
                employer: employer,
                worker: worker,
                amount: amount,
                termsHash: termsHash,
                termsText: termsText,
                status: status,
                deadline: deadline,
                createdAt: createdAt,
                fundedAt: fundedAt,
                completedAt: completedAt,
                rating: rating,
                lastTxSignature: lastTxSignature,
                syncedAt: syncedAt,
                isToken: isToken,
                tokenMint: tokenMint,
                disputeReason: disputeReason,
                disputeDetails: disputeDetails,
                disputeEvidenceUri: disputeEvidenceUri,
                disputeRaisedBy: disputeRaisedBy,
                disputeRaisedAt: disputeRaisedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EscrowContractsTable, EscrowContract>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EscrowContractsTable,
                    EscrowContract
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EscrowContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EscrowContractsTable,
      EscrowContract,
      $$EscrowContractsTableFilterComposer,
      $$EscrowContractsTableOrderingComposer,
      $$EscrowContractsTableAnnotationComposer,
      $$EscrowContractsTableCreateCompanionBuilder,
      $$EscrowContractsTableUpdateCompanionBuilder,
      (
        EscrowContract,
        BaseReferences<_$AppDatabase, $EscrowContractsTable, EscrowContract>,
      ),
      EscrowContract,
      PrefetchHooks Function()
    >;
typedef $$DraftContractsTableCreateCompanionBuilder =
    DraftContractsCompanion Function({
      Value<int> id,
      required String contractId,
      required String workerAddress,
      required double amountSol,
      Value<String?> termsText,
      required BigInt deadline,
      Value<DateTime> createdAt,
      Value<bool> isToken,
      Value<String?> tokenMint,
    });
typedef $$DraftContractsTableUpdateCompanionBuilder =
    DraftContractsCompanion Function({
      Value<int> id,
      Value<String> contractId,
      Value<String> workerAddress,
      Value<double> amountSol,
      Value<String?> termsText,
      Value<BigInt> deadline,
      Value<DateTime> createdAt,
      Value<bool> isToken,
      Value<String?> tokenMint,
    });

class $$DraftContractsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftContractsTable> {
  $$DraftContractsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountSol => $composableBuilder(
    column: $table.amountSol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termsText => $composableBuilder(
    column: $table.termsText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isToken => $composableBuilder(
    column: $table.isToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenMint => $composableBuilder(
    column: $table.tokenMint,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftContractsTable> {
  $$DraftContractsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountSol => $composableBuilder(
    column: $table.amountSol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termsText => $composableBuilder(
    column: $table.termsText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isToken => $composableBuilder(
    column: $table.isToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenMint => $composableBuilder(
    column: $table.tokenMint,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftContractsTable> {
  $$DraftContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerAddress => $composableBuilder(
    column: $table.workerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amountSol =>
      $composableBuilder(column: $table.amountSol, builder: (column) => column);

  GeneratedColumn<String> get termsText =>
      $composableBuilder(column: $table.termsText, builder: (column) => column);

  GeneratedColumn<BigInt> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isToken =>
      $composableBuilder(column: $table.isToken, builder: (column) => column);

  GeneratedColumn<String> get tokenMint =>
      $composableBuilder(column: $table.tokenMint, builder: (column) => column);
}

class $$DraftContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftContractsTable,
          DraftContract,
          $$DraftContractsTableFilterComposer,
          $$DraftContractsTableOrderingComposer,
          $$DraftContractsTableAnnotationComposer,
          $$DraftContractsTableCreateCompanionBuilder,
          $$DraftContractsTableUpdateCompanionBuilder,
          (
            DraftContract,
            BaseReferences<_$AppDatabase, $DraftContractsTable, DraftContract>,
          ),
          DraftContract,
          PrefetchHooks Function()
        > {
  $$DraftContractsTableTableManager(
    _$AppDatabase db,
    $DraftContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> workerAddress = const Value.absent(),
                Value<double> amountSol = const Value.absent(),
                Value<String?> termsText = const Value.absent(),
                Value<BigInt> deadline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isToken = const Value.absent(),
                Value<String?> tokenMint = const Value.absent(),
              }) => DraftContractsCompanion(
                id: id,
                contractId: contractId,
                workerAddress: workerAddress,
                amountSol: amountSol,
                termsText: termsText,
                deadline: deadline,
                createdAt: createdAt,
                isToken: isToken,
                tokenMint: tokenMint,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contractId,
                required String workerAddress,
                required double amountSol,
                Value<String?> termsText = const Value.absent(),
                required BigInt deadline,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isToken = const Value.absent(),
                Value<String?> tokenMint = const Value.absent(),
              }) => DraftContractsCompanion.insert(
                id: id,
                contractId: contractId,
                workerAddress: workerAddress,
                amountSol: amountSol,
                termsText: termsText,
                deadline: deadline,
                createdAt: createdAt,
                isToken: isToken,
                tokenMint: tokenMint,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftContractsTable, DraftContract>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DraftContractsTable,
                    DraftContract
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftContractsTable,
      DraftContract,
      $$DraftContractsTableFilterComposer,
      $$DraftContractsTableOrderingComposer,
      $$DraftContractsTableAnnotationComposer,
      $$DraftContractsTableCreateCompanionBuilder,
      $$DraftContractsTableUpdateCompanionBuilder,
      (
        DraftContract,
        BaseReferences<_$AppDatabase, $DraftContractsTable, DraftContract>,
      ),
      DraftContract,
      PrefetchHooks Function()
    >;
typedef $$SeekerAttestationsTableCreateCompanionBuilder =
    SeekerAttestationsCompanion Function({
      required String address,
      required bool isAttested,
      Value<double> stakedAmount,
      Value<String> guardianName,
      Value<bool> cooldownActive,
      Value<String?> txSignature,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$SeekerAttestationsTableUpdateCompanionBuilder =
    SeekerAttestationsCompanion Function({
      Value<String> address,
      Value<bool> isAttested,
      Value<double> stakedAmount,
      Value<String> guardianName,
      Value<bool> cooldownActive,
      Value<String?> txSignature,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$SeekerAttestationsTableFilterComposer
    extends Composer<_$AppDatabase, $SeekerAttestationsTable> {
  $$SeekerAttestationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAttested => $composableBuilder(
    column: $table.isAttested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stakedAmount => $composableBuilder(
    column: $table.stakedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guardianName => $composableBuilder(
    column: $table.guardianName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cooldownActive => $composableBuilder(
    column: $table.cooldownActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get txSignature => $composableBuilder(
    column: $table.txSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeekerAttestationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeekerAttestationsTable> {
  $$SeekerAttestationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAttested => $composableBuilder(
    column: $table.isAttested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stakedAmount => $composableBuilder(
    column: $table.stakedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guardianName => $composableBuilder(
    column: $table.guardianName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cooldownActive => $composableBuilder(
    column: $table.cooldownActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get txSignature => $composableBuilder(
    column: $table.txSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeekerAttestationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeekerAttestationsTable> {
  $$SeekerAttestationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isAttested => $composableBuilder(
    column: $table.isAttested,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stakedAmount => $composableBuilder(
    column: $table.stakedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guardianName => $composableBuilder(
    column: $table.guardianName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cooldownActive => $composableBuilder(
    column: $table.cooldownActive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get txSignature => $composableBuilder(
    column: $table.txSignature,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SeekerAttestationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeekerAttestationsTable,
          SeekerAttestation,
          $$SeekerAttestationsTableFilterComposer,
          $$SeekerAttestationsTableOrderingComposer,
          $$SeekerAttestationsTableAnnotationComposer,
          $$SeekerAttestationsTableCreateCompanionBuilder,
          $$SeekerAttestationsTableUpdateCompanionBuilder,
          (
            SeekerAttestation,
            BaseReferences<
              _$AppDatabase,
              $SeekerAttestationsTable,
              SeekerAttestation
            >,
          ),
          SeekerAttestation,
          PrefetchHooks Function()
        > {
  $$SeekerAttestationsTableTableManager(
    _$AppDatabase db,
    $SeekerAttestationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeekerAttestationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeekerAttestationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeekerAttestationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> address = const Value.absent(),
                Value<bool> isAttested = const Value.absent(),
                Value<double> stakedAmount = const Value.absent(),
                Value<String> guardianName = const Value.absent(),
                Value<bool> cooldownActive = const Value.absent(),
                Value<String?> txSignature = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeekerAttestationsCompanion(
                address: address,
                isAttested: isAttested,
                stakedAmount: stakedAmount,
                guardianName: guardianName,
                cooldownActive: cooldownActive,
                txSignature: txSignature,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String address,
                required bool isAttested,
                Value<double> stakedAmount = const Value.absent(),
                Value<String> guardianName = const Value.absent(),
                Value<bool> cooldownActive = const Value.absent(),
                Value<String?> txSignature = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeekerAttestationsCompanion.insert(
                address: address,
                isAttested: isAttested,
                stakedAmount: stakedAmount,
                guardianName: guardianName,
                cooldownActive: cooldownActive,
                txSignature: txSignature,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeekerAttestationsTable, SeekerAttestation>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SeekerAttestationsTable,
                    SeekerAttestation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeekerAttestationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeekerAttestationsTable,
      SeekerAttestation,
      $$SeekerAttestationsTableFilterComposer,
      $$SeekerAttestationsTableOrderingComposer,
      $$SeekerAttestationsTableAnnotationComposer,
      $$SeekerAttestationsTableCreateCompanionBuilder,
      $$SeekerAttestationsTableUpdateCompanionBuilder,
      (
        SeekerAttestation,
        BaseReferences<
          _$AppDatabase,
          $SeekerAttestationsTable,
          SeekerAttestation
        >,
      ),
      SeekerAttestation,
      PrefetchHooks Function()
    >;
typedef $$DisputeCasesTableCreateCompanionBuilder =
    DisputeCasesCompanion Function({
      required String contractId,
      required String juror1,
      required String juror2,
      required String juror3,
      Value<int> vote1,
      Value<int> vote2,
      Value<int> vote3,
      Value<int> quorumOutcome,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> resolvedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$DisputeCasesTableUpdateCompanionBuilder =
    DisputeCasesCompanion Function({
      Value<String> contractId,
      Value<String> juror1,
      Value<String> juror2,
      Value<String> juror3,
      Value<int> vote1,
      Value<int> vote2,
      Value<int> vote3,
      Value<int> quorumOutcome,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> resolvedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$DisputeCasesTableFilterComposer
    extends Composer<_$AppDatabase, $DisputeCasesTable> {
  $$DisputeCasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get juror1 => $composableBuilder(
    column: $table.juror1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get juror2 => $composableBuilder(
    column: $table.juror2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get juror3 => $composableBuilder(
    column: $table.juror3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vote1 => $composableBuilder(
    column: $table.vote1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vote2 => $composableBuilder(
    column: $table.vote2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vote3 => $composableBuilder(
    column: $table.vote3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quorumOutcome => $composableBuilder(
    column: $table.quorumOutcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DisputeCasesTableOrderingComposer
    extends Composer<_$AppDatabase, $DisputeCasesTable> {
  $$DisputeCasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get juror1 => $composableBuilder(
    column: $table.juror1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get juror2 => $composableBuilder(
    column: $table.juror2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get juror3 => $composableBuilder(
    column: $table.juror3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vote1 => $composableBuilder(
    column: $table.vote1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vote2 => $composableBuilder(
    column: $table.vote2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vote3 => $composableBuilder(
    column: $table.vote3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quorumOutcome => $composableBuilder(
    column: $table.quorumOutcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DisputeCasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DisputeCasesTable> {
  $$DisputeCasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get juror1 =>
      $composableBuilder(column: $table.juror1, builder: (column) => column);

  GeneratedColumn<String> get juror2 =>
      $composableBuilder(column: $table.juror2, builder: (column) => column);

  GeneratedColumn<String> get juror3 =>
      $composableBuilder(column: $table.juror3, builder: (column) => column);

  GeneratedColumn<int> get vote1 =>
      $composableBuilder(column: $table.vote1, builder: (column) => column);

  GeneratedColumn<int> get vote2 =>
      $composableBuilder(column: $table.vote2, builder: (column) => column);

  GeneratedColumn<int> get vote3 =>
      $composableBuilder(column: $table.vote3, builder: (column) => column);

  GeneratedColumn<int> get quorumOutcome => $composableBuilder(
    column: $table.quorumOutcome,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DisputeCasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DisputeCasesTable,
          DisputeCaseData,
          $$DisputeCasesTableFilterComposer,
          $$DisputeCasesTableOrderingComposer,
          $$DisputeCasesTableAnnotationComposer,
          $$DisputeCasesTableCreateCompanionBuilder,
          $$DisputeCasesTableUpdateCompanionBuilder,
          (
            DisputeCaseData,
            BaseReferences<_$AppDatabase, $DisputeCasesTable, DisputeCaseData>,
          ),
          DisputeCaseData,
          PrefetchHooks Function()
        > {
  $$DisputeCasesTableTableManager(_$AppDatabase db, $DisputeCasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisputeCasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisputeCasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisputeCasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contractId = const Value.absent(),
                Value<String> juror1 = const Value.absent(),
                Value<String> juror2 = const Value.absent(),
                Value<String> juror3 = const Value.absent(),
                Value<int> vote1 = const Value.absent(),
                Value<int> vote2 = const Value.absent(),
                Value<int> vote3 = const Value.absent(),
                Value<int> quorumOutcome = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisputeCasesCompanion(
                contractId: contractId,
                juror1: juror1,
                juror2: juror2,
                juror3: juror3,
                vote1: vote1,
                vote2: vote2,
                vote3: vote3,
                quorumOutcome: quorumOutcome,
                status: status,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contractId,
                required String juror1,
                required String juror2,
                required String juror3,
                Value<int> vote1 = const Value.absent(),
                Value<int> vote2 = const Value.absent(),
                Value<int> vote3 = const Value.absent(),
                Value<int> quorumOutcome = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisputeCasesCompanion.insert(
                contractId: contractId,
                juror1: juror1,
                juror2: juror2,
                juror3: juror3,
                vote1: vote1,
                vote2: vote2,
                vote3: vote3,
                quorumOutcome: quorumOutcome,
                status: status,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DisputeCasesTable, DisputeCaseData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DisputeCasesTable,
                    DisputeCaseData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DisputeCasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DisputeCasesTable,
      DisputeCaseData,
      $$DisputeCasesTableFilterComposer,
      $$DisputeCasesTableOrderingComposer,
      $$DisputeCasesTableAnnotationComposer,
      $$DisputeCasesTableCreateCompanionBuilder,
      $$DisputeCasesTableUpdateCompanionBuilder,
      (
        DisputeCaseData,
        BaseReferences<_$AppDatabase, $DisputeCasesTable, DisputeCaseData>,
      ),
      DisputeCaseData,
      PrefetchHooks Function()
    >;
typedef $$DeliverableSubmissionsTableCreateCompanionBuilder =
    DeliverableSubmissionsCompanion Function({
      Value<int> id,
      required String contractId,
      required String submitterAddress,
      required String encryptedPayload,
      required String iv,
      Value<String> authTag,
      required String plaintextHash,
      Value<String?> arweaveTxId,
      Value<DateTime> submittedAt,
      Value<String> status,
      Value<String?> decryptionKeyHash,
      Value<String?> completionNote,
      Value<String?> wrappedKey,
      Value<DateTime> syncedAt,
    });
typedef $$DeliverableSubmissionsTableUpdateCompanionBuilder =
    DeliverableSubmissionsCompanion Function({
      Value<int> id,
      Value<String> contractId,
      Value<String> submitterAddress,
      Value<String> encryptedPayload,
      Value<String> iv,
      Value<String> authTag,
      Value<String> plaintextHash,
      Value<String?> arweaveTxId,
      Value<DateTime> submittedAt,
      Value<String> status,
      Value<String?> decryptionKeyHash,
      Value<String?> completionNote,
      Value<String?> wrappedKey,
      Value<DateTime> syncedAt,
    });

class $$DeliverableSubmissionsTableFilterComposer
    extends Composer<_$AppDatabase, $DeliverableSubmissionsTable> {
  $$DeliverableSubmissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submitterAddress => $composableBuilder(
    column: $table.submitterAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iv => $composableBuilder(
    column: $table.iv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authTag => $composableBuilder(
    column: $table.authTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plaintextHash => $composableBuilder(
    column: $table.plaintextHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decryptionKeyHash => $composableBuilder(
    column: $table.decryptionKeyHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionNote => $composableBuilder(
    column: $table.completionNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wrappedKey => $composableBuilder(
    column: $table.wrappedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeliverableSubmissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliverableSubmissionsTable> {
  $$DeliverableSubmissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submitterAddress => $composableBuilder(
    column: $table.submitterAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iv => $composableBuilder(
    column: $table.iv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authTag => $composableBuilder(
    column: $table.authTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plaintextHash => $composableBuilder(
    column: $table.plaintextHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decryptionKeyHash => $composableBuilder(
    column: $table.decryptionKeyHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionNote => $composableBuilder(
    column: $table.completionNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wrappedKey => $composableBuilder(
    column: $table.wrappedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeliverableSubmissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliverableSubmissionsTable> {
  $$DeliverableSubmissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submitterAddress => $composableBuilder(
    column: $table.submitterAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iv =>
      $composableBuilder(column: $table.iv, builder: (column) => column);

  GeneratedColumn<String> get authTag =>
      $composableBuilder(column: $table.authTag, builder: (column) => column);

  GeneratedColumn<String> get plaintextHash => $composableBuilder(
    column: $table.plaintextHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arweaveTxId => $composableBuilder(
    column: $table.arweaveTxId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get decryptionKeyHash => $composableBuilder(
    column: $table.decryptionKeyHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completionNote => $composableBuilder(
    column: $table.completionNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wrappedKey => $composableBuilder(
    column: $table.wrappedKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DeliverableSubmissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeliverableSubmissionsTable,
          DeliverableSubmissionData,
          $$DeliverableSubmissionsTableFilterComposer,
          $$DeliverableSubmissionsTableOrderingComposer,
          $$DeliverableSubmissionsTableAnnotationComposer,
          $$DeliverableSubmissionsTableCreateCompanionBuilder,
          $$DeliverableSubmissionsTableUpdateCompanionBuilder,
          (
            DeliverableSubmissionData,
            BaseReferences<
              _$AppDatabase,
              $DeliverableSubmissionsTable,
              DeliverableSubmissionData
            >,
          ),
          DeliverableSubmissionData,
          PrefetchHooks Function()
        > {
  $$DeliverableSubmissionsTableTableManager(
    _$AppDatabase db,
    $DeliverableSubmissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliverableSubmissionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DeliverableSubmissionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeliverableSubmissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> submitterAddress = const Value.absent(),
                Value<String> encryptedPayload = const Value.absent(),
                Value<String> iv = const Value.absent(),
                Value<String> authTag = const Value.absent(),
                Value<String> plaintextHash = const Value.absent(),
                Value<String?> arweaveTxId = const Value.absent(),
                Value<DateTime> submittedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> decryptionKeyHash = const Value.absent(),
                Value<String?> completionNote = const Value.absent(),
                Value<String?> wrappedKey = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => DeliverableSubmissionsCompanion(
                id: id,
                contractId: contractId,
                submitterAddress: submitterAddress,
                encryptedPayload: encryptedPayload,
                iv: iv,
                authTag: authTag,
                plaintextHash: plaintextHash,
                arweaveTxId: arweaveTxId,
                submittedAt: submittedAt,
                status: status,
                decryptionKeyHash: decryptionKeyHash,
                completionNote: completionNote,
                wrappedKey: wrappedKey,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contractId,
                required String submitterAddress,
                required String encryptedPayload,
                required String iv,
                Value<String> authTag = const Value.absent(),
                required String plaintextHash,
                Value<String?> arweaveTxId = const Value.absent(),
                Value<DateTime> submittedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> decryptionKeyHash = const Value.absent(),
                Value<String?> completionNote = const Value.absent(),
                Value<String?> wrappedKey = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => DeliverableSubmissionsCompanion.insert(
                id: id,
                contractId: contractId,
                submitterAddress: submitterAddress,
                encryptedPayload: encryptedPayload,
                iv: iv,
                authTag: authTag,
                plaintextHash: plaintextHash,
                arweaveTxId: arweaveTxId,
                submittedAt: submittedAt,
                status: status,
                decryptionKeyHash: decryptionKeyHash,
                completionNote: completionNote,
                wrappedKey: wrappedKey,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DeliverableSubmissionsTable,
                    DeliverableSubmissionData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DeliverableSubmissionsTable,
                    DeliverableSubmissionData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeliverableSubmissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeliverableSubmissionsTable,
      DeliverableSubmissionData,
      $$DeliverableSubmissionsTableFilterComposer,
      $$DeliverableSubmissionsTableOrderingComposer,
      $$DeliverableSubmissionsTableAnnotationComposer,
      $$DeliverableSubmissionsTableCreateCompanionBuilder,
      $$DeliverableSubmissionsTableUpdateCompanionBuilder,
      (
        DeliverableSubmissionData,
        BaseReferences<
          _$AppDatabase,
          $DeliverableSubmissionsTable,
          DeliverableSubmissionData
        >,
      ),
      DeliverableSubmissionData,
      PrefetchHooks Function()
    >;
typedef $$UserEncryptionKeysTableCreateCompanionBuilder =
    UserEncryptionKeysCompanion Function({
      required String walletAddress,
      required String publicKey,
      required String privateKey,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UserEncryptionKeysTableUpdateCompanionBuilder =
    UserEncryptionKeysCompanion Function({
      Value<String> walletAddress,
      Value<String> publicKey,
      Value<String> privateKey,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$UserEncryptionKeysTableFilterComposer
    extends Composer<_$AppDatabase, $UserEncryptionKeysTable> {
  $$UserEncryptionKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get walletAddress => $composableBuilder(
    column: $table.walletAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserEncryptionKeysTableOrderingComposer
    extends Composer<_$AppDatabase, $UserEncryptionKeysTable> {
  $$UserEncryptionKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get walletAddress => $composableBuilder(
    column: $table.walletAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserEncryptionKeysTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserEncryptionKeysTable> {
  $$UserEncryptionKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get walletAddress => $composableBuilder(
    column: $table.walletAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserEncryptionKeysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserEncryptionKeysTable,
          UserEncryptionKeyData,
          $$UserEncryptionKeysTableFilterComposer,
          $$UserEncryptionKeysTableOrderingComposer,
          $$UserEncryptionKeysTableAnnotationComposer,
          $$UserEncryptionKeysTableCreateCompanionBuilder,
          $$UserEncryptionKeysTableUpdateCompanionBuilder,
          (
            UserEncryptionKeyData,
            BaseReferences<
              _$AppDatabase,
              $UserEncryptionKeysTable,
              UserEncryptionKeyData
            >,
          ),
          UserEncryptionKeyData,
          PrefetchHooks Function()
        > {
  $$UserEncryptionKeysTableTableManager(
    _$AppDatabase db,
    $UserEncryptionKeysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserEncryptionKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserEncryptionKeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserEncryptionKeysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> walletAddress = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<String> privateKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserEncryptionKeysCompanion(
                walletAddress: walletAddress,
                publicKey: publicKey,
                privateKey: privateKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String walletAddress,
                required String publicKey,
                required String privateKey,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserEncryptionKeysCompanion.insert(
                walletAddress: walletAddress,
                publicKey: publicKey,
                privateKey: privateKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserEncryptionKeysTable, UserEncryptionKeyData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $UserEncryptionKeysTable,
                    UserEncryptionKeyData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserEncryptionKeysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserEncryptionKeysTable,
      UserEncryptionKeyData,
      $$UserEncryptionKeysTableFilterComposer,
      $$UserEncryptionKeysTableOrderingComposer,
      $$UserEncryptionKeysTableAnnotationComposer,
      $$UserEncryptionKeysTableCreateCompanionBuilder,
      $$UserEncryptionKeysTableUpdateCompanionBuilder,
      (
        UserEncryptionKeyData,
        BaseReferences<
          _$AppDatabase,
          $UserEncryptionKeysTable,
          UserEncryptionKeyData
        >,
      ),
      UserEncryptionKeyData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkerProfilesTableTableManager get workerProfiles =>
      $$WorkerProfilesTableTableManager(_db, _db.workerProfiles);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db, _db.reviews);
  $$DraftReviewsTableTableManager get draftReviews =>
      $$DraftReviewsTableTableManager(_db, _db.draftReviews);
  $$RecentLookupsTableTableManager get recentLookups =>
      $$RecentLookupsTableTableManager(_db, _db.recentLookups);
  $$EscrowContractsTableTableManager get escrowContracts =>
      $$EscrowContractsTableTableManager(_db, _db.escrowContracts);
  $$DraftContractsTableTableManager get draftContracts =>
      $$DraftContractsTableTableManager(_db, _db.draftContracts);
  $$SeekerAttestationsTableTableManager get seekerAttestations =>
      $$SeekerAttestationsTableTableManager(_db, _db.seekerAttestations);
  $$DisputeCasesTableTableManager get disputeCases =>
      $$DisputeCasesTableTableManager(_db, _db.disputeCases);
  $$DeliverableSubmissionsTableTableManager get deliverableSubmissions =>
      $$DeliverableSubmissionsTableTableManager(
        _db,
        _db.deliverableSubmissions,
      );
  $$UserEncryptionKeysTableTableManager get userEncryptionKeys =>
      $$UserEncryptionKeysTableTableManager(_db, _db.userEncryptionKeys);
}
