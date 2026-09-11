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
  final DateTime syncedAt;
  const Review({
    required this.id,
    required this.workerAddress,
    required this.reviewerAddress,
    required this.jobId,
    required this.rating,
    required this.timestamp,
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
    DateTime? syncedAt,
  }) => Review(
    id: id ?? this.id,
    workerAddress: workerAddress ?? this.workerAddress,
    reviewerAddress: reviewerAddress ?? this.reviewerAddress,
    jobId: jobId ?? this.jobId,
    rating: rating ?? this.rating,
    timestamp: timestamp ?? this.timestamp,
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
          other.syncedAt == this.syncedAt);
}

class ReviewsCompanion extends UpdateCompanion<Review> {
  final Value<int> id;
  final Value<String> workerAddress;
  final Value<String> reviewerAddress;
  final Value<String> jobId;
  final Value<int> rating;
  final Value<BigInt> timestamp;
  final Value<DateTime> syncedAt;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.workerAddress = const Value.absent(),
    this.reviewerAddress = const Value.absent(),
    this.jobId = const Value.absent(),
    this.rating = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String workerAddress,
    required String reviewerAddress,
    required String jobId,
    required int rating,
    required BigInt timestamp,
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
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerAddress != null) 'worker_address': workerAddress,
      if (reviewerAddress != null) 'reviewer_address': reviewerAddress,
      if (jobId != null) 'job_id': jobId,
      if (rating != null) 'rating': rating,
      if (timestamp != null) 'timestamp': timestamp,
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
    Value<DateTime>? syncedAt,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      workerAddress: workerAddress ?? this.workerAddress,
      reviewerAddress: reviewerAddress ?? this.reviewerAddress,
      jobId: jobId ?? this.jobId,
      rating: rating ?? this.rating,
      timestamp: timestamp ?? this.timestamp,
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
  final DateTime createdAt;
  final String status;
  const DraftReview({
    required this.id,
    required this.workerAddress,
    required this.jobId,
    required this.rating,
    this.notes,
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
    DateTime? createdAt,
    String? status,
  }) => DraftReview(
    id: id ?? this.id,
    workerAddress: workerAddress ?? this.workerAddress,
    jobId: jobId ?? this.jobId,
    rating: rating ?? this.rating,
    notes: notes.present ? notes.value : this.notes,
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
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workerAddress, jobId, rating, notes, createdAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftReview &&
          other.id == this.id &&
          other.workerAddress == this.workerAddress &&
          other.jobId == this.jobId &&
          other.rating == this.rating &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class DraftReviewsCompanion extends UpdateCompanion<DraftReview> {
  final Value<int> id;
  final Value<String> workerAddress;
  final Value<String> jobId;
  final Value<int> rating;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<String> status;
  const DraftReviewsCompanion({
    this.id = const Value.absent(),
    this.workerAddress = const Value.absent(),
    this.jobId = const Value.absent(),
    this.rating = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  DraftReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String workerAddress,
    required String jobId,
    required int rating,
    this.notes = const Value.absent(),
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
    Expression<DateTime>? createdAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerAddress != null) 'worker_address': workerAddress,
      if (jobId != null) 'job_id': jobId,
      if (rating != null) 'rating': rating,
      if (notes != null) 'notes': notes,
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
    Value<DateTime>? createdAt,
    Value<String>? status,
  }) {
    return DraftReviewsCompanion(
      id: id ?? this.id,
      workerAddress: workerAddress ?? this.workerAddress,
      jobId: jobId ?? this.jobId,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkerProfilesTable workerProfiles = $WorkerProfilesTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  late final $DraftReviewsTable draftReviews = $DraftReviewsTable(this);
  late final $RecentLookupsTable recentLookups = $RecentLookupsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workerProfiles,
    reviews,
    draftReviews,
    recentLookups,
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
                Value<DateTime> syncedAt = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                workerAddress: workerAddress,
                reviewerAddress: reviewerAddress,
                jobId: jobId,
                rating: rating,
                timestamp: timestamp,
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
                Value<DateTime> syncedAt = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                workerAddress: workerAddress,
                reviewerAddress: reviewerAddress,
                jobId: jobId,
                rating: rating,
                timestamp: timestamp,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DraftReviewsCompanion(
                id: id,
                workerAddress: workerAddress,
                jobId: jobId,
                rating: rating,
                notes: notes,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DraftReviewsCompanion.insert(
                id: id,
                workerAddress: workerAddress,
                jobId: jobId,
                rating: rating,
                notes: notes,
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
}
