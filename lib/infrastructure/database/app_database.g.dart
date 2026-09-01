// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _registroLocalIdMeta =
      const VerificationMeta('registroLocalId');
  @override
  late final GeneratedColumn<String> registroLocalId = GeneratedColumn<String>(
      'registro_local_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroLocalId,
        endpoint,
        method,
        payloadJson,
        timestamp,
        status,
        retryCount,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('registro_local_id')) {
      context.handle(
          _registroLocalIdMeta,
          registroLocalId.isAcceptableOrUnknown(
              data['registro_local_id']!, _registroLocalIdMeta));
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      registroLocalId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}registro_local_id']),
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int id;
  final String? registroLocalId;
  final String endpoint;
  final String method;
  final String payloadJson;
  final DateTime timestamp;
  final String status;
  final int retryCount;
  final String? errorMessage;
  const OutboxEntry(
      {required this.id,
      this.registroLocalId,
      required this.endpoint,
      required this.method,
      required this.payloadJson,
      required this.timestamp,
      required this.status,
      required this.retryCount,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || registroLocalId != null) {
      map['registro_local_id'] = Variable<String>(registroLocalId);
    }
    map['endpoint'] = Variable<String>(endpoint);
    map['method'] = Variable<String>(method);
    map['payload_json'] = Variable<String>(payloadJson);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      registroLocalId: registroLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(registroLocalId),
      endpoint: Value(endpoint),
      method: Value(method),
      payloadJson: Value(payloadJson),
      timestamp: Value(timestamp),
      status: Value(status),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory OutboxEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<int>(json['id']),
      registroLocalId: serializer.fromJson<String?>(json['registroLocalId']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      method: serializer.fromJson<String>(json['method']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'registroLocalId': serializer.toJson<String?>(registroLocalId),
      'endpoint': serializer.toJson<String>(endpoint),
      'method': serializer.toJson<String>(method),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  OutboxEntry copyWith(
          {int? id,
          Value<String?> registroLocalId = const Value.absent(),
          String? endpoint,
          String? method,
          String? payloadJson,
          DateTime? timestamp,
          String? status,
          int? retryCount,
          Value<String?> errorMessage = const Value.absent()}) =>
      OutboxEntry(
        id: id ?? this.id,
        registroLocalId: registroLocalId.present
            ? registroLocalId.value
            : this.registroLocalId,
        endpoint: endpoint ?? this.endpoint,
        method: method ?? this.method,
        payloadJson: payloadJson ?? this.payloadJson,
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      registroLocalId: data.registroLocalId.present
          ? data.registroLocalId.value
          : this.registroLocalId,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      method: data.method.present ? data.method.value : this.method,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('registroLocalId: $registroLocalId, ')
          ..write('endpoint: $endpoint, ')
          ..write('method: $method, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, registroLocalId, endpoint, method,
      payloadJson, timestamp, status, retryCount, errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.registroLocalId == this.registroLocalId &&
          other.endpoint == this.endpoint &&
          other.method == this.method &&
          other.payloadJson == this.payloadJson &&
          other.timestamp == this.timestamp &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> id;
  final Value<String?> registroLocalId;
  final Value<String> endpoint;
  final Value<String> method;
  final Value<String> payloadJson;
  final Value<DateTime> timestamp;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.registroLocalId = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.method = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.registroLocalId = const Value.absent(),
    required String endpoint,
    required String method,
    required String payloadJson,
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
  })  : endpoint = Value(endpoint),
        method = Value(method),
        payloadJson = Value(payloadJson);
  static Insertable<OutboxEntry> custom({
    Expression<int>? id,
    Expression<String>? registroLocalId,
    Expression<String>? endpoint,
    Expression<String>? method,
    Expression<String>? payloadJson,
    Expression<DateTime>? timestamp,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroLocalId != null) 'registro_local_id': registroLocalId,
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  OutboxEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? registroLocalId,
      Value<String>? endpoint,
      Value<String>? method,
      Value<String>? payloadJson,
      Value<DateTime>? timestamp,
      Value<String>? status,
      Value<int>? retryCount,
      Value<String?>? errorMessage}) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      registroLocalId: registroLocalId ?? this.registroLocalId,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      payloadJson: payloadJson ?? this.payloadJson,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (registroLocalId.present) {
      map['registro_local_id'] = Variable<String>(registroLocalId.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('registroLocalId: $registroLocalId, ')
          ..write('endpoint: $endpoint, ')
          ..write('method: $method, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

class $ProcesosLocalTable extends ProcesosLocal
    with TableInfo<$ProcesosLocalTable, ProcesosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcesosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
      'codigo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requiereBinesMeta =
      const VerificationMeta('requiereBines');
  @override
  late final GeneratedColumn<bool> requiereBines = GeneratedColumn<bool>(
      'requiere_bines', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requiere_bines" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, nombre, codigo, requiereBines, activo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'procesos_local';
  @override
  VerificationContext validateIntegrity(Insertable<ProcesosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(_codigoMeta,
          codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta));
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('requiere_bines')) {
      context.handle(
          _requiereBinesMeta,
          requiereBines.isAcceptableOrUnknown(
              data['requiere_bines']!, _requiereBinesMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcesosLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcesosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
      codigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo'])!,
      requiereBines: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requiere_bines'])!,
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
    );
  }

  @override
  $ProcesosLocalTable createAlias(String alias) {
    return $ProcesosLocalTable(attachedDatabase, alias);
  }
}

class ProcesosLocalData extends DataClass
    implements Insertable<ProcesosLocalData> {
  final int id;
  final String nombre;
  final String codigo;
  final bool requiereBines;
  final bool activo;
  const ProcesosLocalData(
      {required this.id,
      required this.nombre,
      required this.codigo,
      required this.requiereBines,
      required this.activo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['codigo'] = Variable<String>(codigo);
    map['requiere_bines'] = Variable<bool>(requiereBines);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  ProcesosLocalCompanion toCompanion(bool nullToAbsent) {
    return ProcesosLocalCompanion(
      id: Value(id),
      nombre: Value(nombre),
      codigo: Value(codigo),
      requiereBines: Value(requiereBines),
      activo: Value(activo),
    );
  }

  factory ProcesosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcesosLocalData(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      codigo: serializer.fromJson<String>(json['codigo']),
      requiereBines: serializer.fromJson<bool>(json['requiereBines']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'codigo': serializer.toJson<String>(codigo),
      'requiereBines': serializer.toJson<bool>(requiereBines),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  ProcesosLocalData copyWith(
          {int? id,
          String? nombre,
          String? codigo,
          bool? requiereBines,
          bool? activo}) =>
      ProcesosLocalData(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        codigo: codigo ?? this.codigo,
        requiereBines: requiereBines ?? this.requiereBines,
        activo: activo ?? this.activo,
      );
  ProcesosLocalData copyWithCompanion(ProcesosLocalCompanion data) {
    return ProcesosLocalData(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      requiereBines: data.requiereBines.present
          ? data.requiereBines.value
          : this.requiereBines,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcesosLocalData(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('codigo: $codigo, ')
          ..write('requiereBines: $requiereBines, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, codigo, requiereBines, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcesosLocalData &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.codigo == this.codigo &&
          other.requiereBines == this.requiereBines &&
          other.activo == this.activo);
}

class ProcesosLocalCompanion extends UpdateCompanion<ProcesosLocalData> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<String> codigo;
  final Value<bool> requiereBines;
  final Value<bool> activo;
  const ProcesosLocalCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.codigo = const Value.absent(),
    this.requiereBines = const Value.absent(),
    this.activo = const Value.absent(),
  });
  ProcesosLocalCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required String codigo,
    this.requiereBines = const Value.absent(),
    this.activo = const Value.absent(),
  })  : nombre = Value(nombre),
        codigo = Value(codigo);
  static Insertable<ProcesosLocalData> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<String>? codigo,
    Expression<bool>? requiereBines,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      if (requiereBines != null) 'requiere_bines': requiereBines,
      if (activo != null) 'activo': activo,
    });
  }

  ProcesosLocalCompanion copyWith(
      {Value<int>? id,
      Value<String>? nombre,
      Value<String>? codigo,
      Value<bool>? requiereBines,
      Value<bool>? activo}) {
    return ProcesosLocalCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      requiereBines: requiereBines ?? this.requiereBines,
      activo: activo ?? this.activo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (requiereBines.present) {
      map['requiere_bines'] = Variable<bool>(requiereBines.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcesosLocalCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('codigo: $codigo, ')
          ..write('requiereBines: $requiereBines, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $CajasCambiosLocalTable extends CajasCambiosLocal
    with TableInfo<$CajasCambiosLocalTable, CajasCambiosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CajasCambiosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, nombre];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cajas_cambios_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<CajasCambiosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CajasCambiosLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CajasCambiosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
    );
  }

  @override
  $CajasCambiosLocalTable createAlias(String alias) {
    return $CajasCambiosLocalTable(attachedDatabase, alias);
  }
}

class CajasCambiosLocalData extends DataClass
    implements Insertable<CajasCambiosLocalData> {
  final int id;
  final String nombre;
  const CajasCambiosLocalData({required this.id, required this.nombre});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    return map;
  }

  CajasCambiosLocalCompanion toCompanion(bool nullToAbsent) {
    return CajasCambiosLocalCompanion(
      id: Value(id),
      nombre: Value(nombre),
    );
  }

  factory CajasCambiosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CajasCambiosLocalData(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
    };
  }

  CajasCambiosLocalData copyWith({int? id, String? nombre}) =>
      CajasCambiosLocalData(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
      );
  CajasCambiosLocalData copyWithCompanion(CajasCambiosLocalCompanion data) {
    return CajasCambiosLocalData(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CajasCambiosLocalData(')
          ..write('id: $id, ')
          ..write('nombre: $nombre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CajasCambiosLocalData &&
          other.id == this.id &&
          other.nombre == this.nombre);
}

class CajasCambiosLocalCompanion
    extends UpdateCompanion<CajasCambiosLocalData> {
  final Value<int> id;
  final Value<String> nombre;
  const CajasCambiosLocalCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
  });
  CajasCambiosLocalCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
  }) : nombre = Value(nombre);
  static Insertable<CajasCambiosLocalData> custom({
    Expression<int>? id,
    Expression<String>? nombre,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
    });
  }

  CajasCambiosLocalCompanion copyWith({Value<int>? id, Value<String>? nombre}) {
    return CajasCambiosLocalCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CajasCambiosLocalCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre')
          ..write(')'))
        .toString();
  }
}

class $TiposParoLocalTable extends TiposParoLocal
    with TableInfo<$TiposParoLocalTable, TiposParoLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiposParoLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
      'codigo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requiereGalonesMeta =
      const VerificationMeta('requiereGalones');
  @override
  late final GeneratedColumn<bool> requiereGalones = GeneratedColumn<bool>(
      'requiere_galones', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requiere_galones" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _requiereEquipoMeta =
      const VerificationMeta('requiereEquipo');
  @override
  late final GeneratedColumn<bool> requiereEquipo = GeneratedColumn<bool>(
      'requiere_equipo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requiere_equipo" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, codigo, nombre, requiereGalones, requiereEquipo, activo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tipos_paro_local';
  @override
  VerificationContext validateIntegrity(Insertable<TiposParoLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('codigo')) {
      context.handle(_codigoMeta,
          codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta));
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('requiere_galones')) {
      context.handle(
          _requiereGalonesMeta,
          requiereGalones.isAcceptableOrUnknown(
              data['requiere_galones']!, _requiereGalonesMeta));
    }
    if (data.containsKey('requiere_equipo')) {
      context.handle(
          _requiereEquipoMeta,
          requiereEquipo.isAcceptableOrUnknown(
              data['requiere_equipo']!, _requiereEquipoMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TiposParoLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TiposParoLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      codigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
      requiereGalones: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requiere_galones'])!,
      requiereEquipo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requiere_equipo'])!,
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
    );
  }

  @override
  $TiposParoLocalTable createAlias(String alias) {
    return $TiposParoLocalTable(attachedDatabase, alias);
  }
}

class TiposParoLocalData extends DataClass
    implements Insertable<TiposParoLocalData> {
  final int id;
  final String codigo;
  final String nombre;
  final bool requiereGalones;
  final bool requiereEquipo;
  final bool activo;
  const TiposParoLocalData(
      {required this.id,
      required this.codigo,
      required this.nombre,
      required this.requiereGalones,
      required this.requiereEquipo,
      required this.activo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['codigo'] = Variable<String>(codigo);
    map['nombre'] = Variable<String>(nombre);
    map['requiere_galones'] = Variable<bool>(requiereGalones);
    map['requiere_equipo'] = Variable<bool>(requiereEquipo);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  TiposParoLocalCompanion toCompanion(bool nullToAbsent) {
    return TiposParoLocalCompanion(
      id: Value(id),
      codigo: Value(codigo),
      nombre: Value(nombre),
      requiereGalones: Value(requiereGalones),
      requiereEquipo: Value(requiereEquipo),
      activo: Value(activo),
    );
  }

  factory TiposParoLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TiposParoLocalData(
      id: serializer.fromJson<int>(json['id']),
      codigo: serializer.fromJson<String>(json['codigo']),
      nombre: serializer.fromJson<String>(json['nombre']),
      requiereGalones: serializer.fromJson<bool>(json['requiereGalones']),
      requiereEquipo: serializer.fromJson<bool>(json['requiereEquipo']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'codigo': serializer.toJson<String>(codigo),
      'nombre': serializer.toJson<String>(nombre),
      'requiereGalones': serializer.toJson<bool>(requiereGalones),
      'requiereEquipo': serializer.toJson<bool>(requiereEquipo),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  TiposParoLocalData copyWith(
          {int? id,
          String? codigo,
          String? nombre,
          bool? requiereGalones,
          bool? requiereEquipo,
          bool? activo}) =>
      TiposParoLocalData(
        id: id ?? this.id,
        codigo: codigo ?? this.codigo,
        nombre: nombre ?? this.nombre,
        requiereGalones: requiereGalones ?? this.requiereGalones,
        requiereEquipo: requiereEquipo ?? this.requiereEquipo,
        activo: activo ?? this.activo,
      );
  TiposParoLocalData copyWithCompanion(TiposParoLocalCompanion data) {
    return TiposParoLocalData(
      id: data.id.present ? data.id.value : this.id,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      requiereGalones: data.requiereGalones.present
          ? data.requiereGalones.value
          : this.requiereGalones,
      requiereEquipo: data.requiereEquipo.present
          ? data.requiereEquipo.value
          : this.requiereEquipo,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TiposParoLocalData(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('requiereGalones: $requiereGalones, ')
          ..write('requiereEquipo: $requiereEquipo, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, codigo, nombre, requiereGalones, requiereEquipo, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TiposParoLocalData &&
          other.id == this.id &&
          other.codigo == this.codigo &&
          other.nombre == this.nombre &&
          other.requiereGalones == this.requiereGalones &&
          other.requiereEquipo == this.requiereEquipo &&
          other.activo == this.activo);
}

class TiposParoLocalCompanion extends UpdateCompanion<TiposParoLocalData> {
  final Value<int> id;
  final Value<String> codigo;
  final Value<String> nombre;
  final Value<bool> requiereGalones;
  final Value<bool> requiereEquipo;
  final Value<bool> activo;
  const TiposParoLocalCompanion({
    this.id = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.requiereGalones = const Value.absent(),
    this.requiereEquipo = const Value.absent(),
    this.activo = const Value.absent(),
  });
  TiposParoLocalCompanion.insert({
    this.id = const Value.absent(),
    required String codigo,
    required String nombre,
    this.requiereGalones = const Value.absent(),
    this.requiereEquipo = const Value.absent(),
    this.activo = const Value.absent(),
  })  : codigo = Value(codigo),
        nombre = Value(nombre);
  static Insertable<TiposParoLocalData> custom({
    Expression<int>? id,
    Expression<String>? codigo,
    Expression<String>? nombre,
    Expression<bool>? requiereGalones,
    Expression<bool>? requiereEquipo,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      if (requiereGalones != null) 'requiere_galones': requiereGalones,
      if (requiereEquipo != null) 'requiere_equipo': requiereEquipo,
      if (activo != null) 'activo': activo,
    });
  }

  TiposParoLocalCompanion copyWith(
      {Value<int>? id,
      Value<String>? codigo,
      Value<String>? nombre,
      Value<bool>? requiereGalones,
      Value<bool>? requiereEquipo,
      Value<bool>? activo}) {
    return TiposParoLocalCompanion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      requiereGalones: requiereGalones ?? this.requiereGalones,
      requiereEquipo: requiereEquipo ?? this.requiereEquipo,
      activo: activo ?? this.activo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (requiereGalones.present) {
      map['requiere_galones'] = Variable<bool>(requiereGalones.value);
    }
    if (requiereEquipo.present) {
      map['requiere_equipo'] = Variable<bool>(requiereEquipo.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiposParoLocalCompanion(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nombre: $nombre, ')
          ..write('requiereGalones: $requiereGalones, ')
          ..write('requiereEquipo: $requiereEquipo, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $ChecklistCategoriasLocalTable extends ChecklistCategoriasLocal
    with
        TableInfo<$ChecklistCategoriasLocalTable,
            ChecklistCategoriasLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistCategoriasLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
      'orden', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, nombre, orden];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_categorias_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<ChecklistCategoriasLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
          _ordenMeta, orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistCategoriasLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistCategoriasLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
      orden: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}orden'])!,
    );
  }

  @override
  $ChecklistCategoriasLocalTable createAlias(String alias) {
    return $ChecklistCategoriasLocalTable(attachedDatabase, alias);
  }
}

class ChecklistCategoriasLocalData extends DataClass
    implements Insertable<ChecklistCategoriasLocalData> {
  final int id;
  final String nombre;
  final int orden;
  const ChecklistCategoriasLocalData(
      {required this.id, required this.nombre, required this.orden});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['orden'] = Variable<int>(orden);
    return map;
  }

  ChecklistCategoriasLocalCompanion toCompanion(bool nullToAbsent) {
    return ChecklistCategoriasLocalCompanion(
      id: Value(id),
      nombre: Value(nombre),
      orden: Value(orden),
    );
  }

  factory ChecklistCategoriasLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistCategoriasLocalData(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      orden: serializer.fromJson<int>(json['orden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'orden': serializer.toJson<int>(orden),
    };
  }

  ChecklistCategoriasLocalData copyWith(
          {int? id, String? nombre, int? orden}) =>
      ChecklistCategoriasLocalData(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        orden: orden ?? this.orden,
      );
  ChecklistCategoriasLocalData copyWithCompanion(
      ChecklistCategoriasLocalCompanion data) {
    return ChecklistCategoriasLocalData(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      orden: data.orden.present ? data.orden.value : this.orden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistCategoriasLocalData(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, orden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistCategoriasLocalData &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.orden == this.orden);
}

class ChecklistCategoriasLocalCompanion
    extends UpdateCompanion<ChecklistCategoriasLocalData> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<int> orden;
  const ChecklistCategoriasLocalCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.orden = const Value.absent(),
  });
  ChecklistCategoriasLocalCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    this.orden = const Value.absent(),
  }) : nombre = Value(nombre);
  static Insertable<ChecklistCategoriasLocalData> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<int>? orden,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (orden != null) 'orden': orden,
    });
  }

  ChecklistCategoriasLocalCompanion copyWith(
      {Value<int>? id, Value<String>? nombre, Value<int>? orden}) {
    return ChecklistCategoriasLocalCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      orden: orden ?? this.orden,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistCategoriasLocalCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsLocalTable extends ChecklistItemsLocal
    with TableInfo<$ChecklistItemsLocalTable, ChecklistItemsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoriaIdMeta =
      const VerificationMeta('categoriaId');
  @override
  late final GeneratedColumn<int> categoriaId = GeneratedColumn<int>(
      'categoria_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoriaNombreMeta =
      const VerificationMeta('categoriaNombre');
  @override
  late final GeneratedColumn<String> categoriaNombre = GeneratedColumn<String>(
      'categoria_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
      'orden', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _tipoRegistroMeta =
      const VerificationMeta('tipoRegistro');
  @override
  late final GeneratedColumn<String> tipoRegistro = GeneratedColumn<String>(
      'tipo_registro', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('tractor'));
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoriaId, categoriaNombre, nombre, orden, tipoRegistro, activo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<ChecklistItemsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
          _categoriaIdMeta,
          categoriaId.isAcceptableOrUnknown(
              data['categoria_id']!, _categoriaIdMeta));
    } else if (isInserting) {
      context.missing(_categoriaIdMeta);
    }
    if (data.containsKey('categoria_nombre')) {
      context.handle(
          _categoriaNombreMeta,
          categoriaNombre.isAcceptableOrUnknown(
              data['categoria_nombre']!, _categoriaNombreMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
          _ordenMeta, orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta));
    }
    if (data.containsKey('tipo_registro')) {
      context.handle(
          _tipoRegistroMeta,
          tipoRegistro.isAcceptableOrUnknown(
              data['tipo_registro']!, _tipoRegistroMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItemsLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItemsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}categoria_id'])!,
      categoriaNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}categoria_nombre'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
      orden: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}orden'])!,
      tipoRegistro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo_registro'])!,
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
    );
  }

  @override
  $ChecklistItemsLocalTable createAlias(String alias) {
    return $ChecklistItemsLocalTable(attachedDatabase, alias);
  }
}

class ChecklistItemsLocalData extends DataClass
    implements Insertable<ChecklistItemsLocalData> {
  final int id;
  final int categoriaId;
  final String categoriaNombre;
  final String nombre;
  final int orden;
  final String tipoRegistro;
  final bool activo;
  const ChecklistItemsLocalData(
      {required this.id,
      required this.categoriaId,
      required this.categoriaNombre,
      required this.nombre,
      required this.orden,
      required this.tipoRegistro,
      required this.activo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['categoria_id'] = Variable<int>(categoriaId);
    map['categoria_nombre'] = Variable<String>(categoriaNombre);
    map['nombre'] = Variable<String>(nombre);
    map['orden'] = Variable<int>(orden);
    map['tipo_registro'] = Variable<String>(tipoRegistro);
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  ChecklistItemsLocalCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsLocalCompanion(
      id: Value(id),
      categoriaId: Value(categoriaId),
      categoriaNombre: Value(categoriaNombre),
      nombre: Value(nombre),
      orden: Value(orden),
      tipoRegistro: Value(tipoRegistro),
      activo: Value(activo),
    );
  }

  factory ChecklistItemsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItemsLocalData(
      id: serializer.fromJson<int>(json['id']),
      categoriaId: serializer.fromJson<int>(json['categoriaId']),
      categoriaNombre: serializer.fromJson<String>(json['categoriaNombre']),
      nombre: serializer.fromJson<String>(json['nombre']),
      orden: serializer.fromJson<int>(json['orden']),
      tipoRegistro: serializer.fromJson<String>(json['tipoRegistro']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoriaId': serializer.toJson<int>(categoriaId),
      'categoriaNombre': serializer.toJson<String>(categoriaNombre),
      'nombre': serializer.toJson<String>(nombre),
      'orden': serializer.toJson<int>(orden),
      'tipoRegistro': serializer.toJson<String>(tipoRegistro),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  ChecklistItemsLocalData copyWith(
          {int? id,
          int? categoriaId,
          String? categoriaNombre,
          String? nombre,
          int? orden,
          String? tipoRegistro,
          bool? activo}) =>
      ChecklistItemsLocalData(
        id: id ?? this.id,
        categoriaId: categoriaId ?? this.categoriaId,
        categoriaNombre: categoriaNombre ?? this.categoriaNombre,
        nombre: nombre ?? this.nombre,
        orden: orden ?? this.orden,
        tipoRegistro: tipoRegistro ?? this.tipoRegistro,
        activo: activo ?? this.activo,
      );
  ChecklistItemsLocalData copyWithCompanion(ChecklistItemsLocalCompanion data) {
    return ChecklistItemsLocalData(
      id: data.id.present ? data.id.value : this.id,
      categoriaId:
          data.categoriaId.present ? data.categoriaId.value : this.categoriaId,
      categoriaNombre: data.categoriaNombre.present
          ? data.categoriaNombre.value
          : this.categoriaNombre,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      orden: data.orden.present ? data.orden.value : this.orden,
      tipoRegistro: data.tipoRegistro.present
          ? data.tipoRegistro.value
          : this.tipoRegistro,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsLocalData(')
          ..write('id: $id, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('categoriaNombre: $categoriaNombre, ')
          ..write('nombre: $nombre, ')
          ..write('orden: $orden, ')
          ..write('tipoRegistro: $tipoRegistro, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, categoriaId, categoriaNombre, nombre, orden, tipoRegistro, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItemsLocalData &&
          other.id == this.id &&
          other.categoriaId == this.categoriaId &&
          other.categoriaNombre == this.categoriaNombre &&
          other.nombre == this.nombre &&
          other.orden == this.orden &&
          other.tipoRegistro == this.tipoRegistro &&
          other.activo == this.activo);
}

class ChecklistItemsLocalCompanion
    extends UpdateCompanion<ChecklistItemsLocalData> {
  final Value<int> id;
  final Value<int> categoriaId;
  final Value<String> categoriaNombre;
  final Value<String> nombre;
  final Value<int> orden;
  final Value<String> tipoRegistro;
  final Value<bool> activo;
  const ChecklistItemsLocalCompanion({
    this.id = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.categoriaNombre = const Value.absent(),
    this.nombre = const Value.absent(),
    this.orden = const Value.absent(),
    this.tipoRegistro = const Value.absent(),
    this.activo = const Value.absent(),
  });
  ChecklistItemsLocalCompanion.insert({
    this.id = const Value.absent(),
    required int categoriaId,
    this.categoriaNombre = const Value.absent(),
    required String nombre,
    this.orden = const Value.absent(),
    this.tipoRegistro = const Value.absent(),
    this.activo = const Value.absent(),
  })  : categoriaId = Value(categoriaId),
        nombre = Value(nombre);
  static Insertable<ChecklistItemsLocalData> custom({
    Expression<int>? id,
    Expression<int>? categoriaId,
    Expression<String>? categoriaNombre,
    Expression<String>? nombre,
    Expression<int>? orden,
    Expression<String>? tipoRegistro,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (categoriaNombre != null) 'categoria_nombre': categoriaNombre,
      if (nombre != null) 'nombre': nombre,
      if (orden != null) 'orden': orden,
      if (tipoRegistro != null) 'tipo_registro': tipoRegistro,
      if (activo != null) 'activo': activo,
    });
  }

  ChecklistItemsLocalCompanion copyWith(
      {Value<int>? id,
      Value<int>? categoriaId,
      Value<String>? categoriaNombre,
      Value<String>? nombre,
      Value<int>? orden,
      Value<String>? tipoRegistro,
      Value<bool>? activo}) {
    return ChecklistItemsLocalCompanion(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      nombre: nombre ?? this.nombre,
      orden: orden ?? this.orden,
      tipoRegistro: tipoRegistro ?? this.tipoRegistro,
      activo: activo ?? this.activo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<int>(categoriaId.value);
    }
    if (categoriaNombre.present) {
      map['categoria_nombre'] = Variable<String>(categoriaNombre.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (tipoRegistro.present) {
      map['tipo_registro'] = Variable<String>(tipoRegistro.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsLocalCompanion(')
          ..write('id: $id, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('categoriaNombre: $categoriaNombre, ')
          ..write('nombre: $nombre, ')
          ..write('orden: $orden, ')
          ..write('tipoRegistro: $tipoRegistro, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $CultivosLocalTable extends CultivosLocal
    with TableInfo<$CultivosLocalTable, CultivosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CultivosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idErpMeta = const VerificationMeta('idErp');
  @override
  late final GeneratedColumn<int> idErp = GeneratedColumn<int>(
      'id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _codigoEspecieMeta =
      const VerificationMeta('codigoEspecie');
  @override
  late final GeneratedColumn<String> codigoEspecie = GeneratedColumn<String>(
      'codigo_especie', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nombreEspecieMeta =
      const VerificationMeta('nombreEspecie');
  @override
  late final GeneratedColumn<String> nombreEspecie = GeneratedColumn<String>(
      'nombre_especie', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nombreCultivoMeta =
      const VerificationMeta('nombreCultivo');
  @override
  late final GeneratedColumn<String> nombreCultivo = GeneratedColumn<String>(
      'nombre_cultivo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sincronizadoAtMeta =
      const VerificationMeta('sincronizadoAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoAt =
      GeneratedColumn<DateTime>('sincronizado_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        idErp,
        codigoEspecie,
        nombreEspecie,
        nombreCultivo,
        activo,
        sincronizadoAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cultivos_local';
  @override
  VerificationContext validateIntegrity(Insertable<CultivosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_erp')) {
      context.handle(
          _idErpMeta, idErp.isAcceptableOrUnknown(data['id_erp']!, _idErpMeta));
    }
    if (data.containsKey('codigo_especie')) {
      context.handle(
          _codigoEspecieMeta,
          codigoEspecie.isAcceptableOrUnknown(
              data['codigo_especie']!, _codigoEspecieMeta));
    } else if (isInserting) {
      context.missing(_codigoEspecieMeta);
    }
    if (data.containsKey('nombre_especie')) {
      context.handle(
          _nombreEspecieMeta,
          nombreEspecie.isAcceptableOrUnknown(
              data['nombre_especie']!, _nombreEspecieMeta));
    } else if (isInserting) {
      context.missing(_nombreEspecieMeta);
    }
    if (data.containsKey('nombre_cultivo')) {
      context.handle(
          _nombreCultivoMeta,
          nombreCultivo.isAcceptableOrUnknown(
              data['nombre_cultivo']!, _nombreCultivoMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    if (data.containsKey('sincronizado_at')) {
      context.handle(
          _sincronizadoAtMeta,
          sincronizadoAt.isAcceptableOrUnknown(
              data['sincronizado_at']!, _sincronizadoAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idErp};
  @override
  CultivosLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CultivosLocalData(
      idErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_erp'])!,
      codigoEspecie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo_especie'])!,
      nombreEspecie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre_especie'])!,
      nombreCultivo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre_cultivo']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
      sincronizadoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}sincronizado_at'])!,
    );
  }

  @override
  $CultivosLocalTable createAlias(String alias) {
    return $CultivosLocalTable(attachedDatabase, alias);
  }
}

class CultivosLocalData extends DataClass
    implements Insertable<CultivosLocalData> {
  /// ID entero del ERP SQL Server.
  final int idErp;
  final String codigoEspecie;
  final String nombreEspecie;
  final String? nombreCultivo;
  final bool activo;
  final DateTime sincronizadoAt;
  const CultivosLocalData(
      {required this.idErp,
      required this.codigoEspecie,
      required this.nombreEspecie,
      this.nombreCultivo,
      required this.activo,
      required this.sincronizadoAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_erp'] = Variable<int>(idErp);
    map['codigo_especie'] = Variable<String>(codigoEspecie);
    map['nombre_especie'] = Variable<String>(nombreEspecie);
    if (!nullToAbsent || nombreCultivo != null) {
      map['nombre_cultivo'] = Variable<String>(nombreCultivo);
    }
    map['activo'] = Variable<bool>(activo);
    map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt);
    return map;
  }

  CultivosLocalCompanion toCompanion(bool nullToAbsent) {
    return CultivosLocalCompanion(
      idErp: Value(idErp),
      codigoEspecie: Value(codigoEspecie),
      nombreEspecie: Value(nombreEspecie),
      nombreCultivo: nombreCultivo == null && nullToAbsent
          ? const Value.absent()
          : Value(nombreCultivo),
      activo: Value(activo),
      sincronizadoAt: Value(sincronizadoAt),
    );
  }

  factory CultivosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CultivosLocalData(
      idErp: serializer.fromJson<int>(json['idErp']),
      codigoEspecie: serializer.fromJson<String>(json['codigoEspecie']),
      nombreEspecie: serializer.fromJson<String>(json['nombreEspecie']),
      nombreCultivo: serializer.fromJson<String?>(json['nombreCultivo']),
      activo: serializer.fromJson<bool>(json['activo']),
      sincronizadoAt: serializer.fromJson<DateTime>(json['sincronizadoAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idErp': serializer.toJson<int>(idErp),
      'codigoEspecie': serializer.toJson<String>(codigoEspecie),
      'nombreEspecie': serializer.toJson<String>(nombreEspecie),
      'nombreCultivo': serializer.toJson<String?>(nombreCultivo),
      'activo': serializer.toJson<bool>(activo),
      'sincronizadoAt': serializer.toJson<DateTime>(sincronizadoAt),
    };
  }

  CultivosLocalData copyWith(
          {int? idErp,
          String? codigoEspecie,
          String? nombreEspecie,
          Value<String?> nombreCultivo = const Value.absent(),
          bool? activo,
          DateTime? sincronizadoAt}) =>
      CultivosLocalData(
        idErp: idErp ?? this.idErp,
        codigoEspecie: codigoEspecie ?? this.codigoEspecie,
        nombreEspecie: nombreEspecie ?? this.nombreEspecie,
        nombreCultivo:
            nombreCultivo.present ? nombreCultivo.value : this.nombreCultivo,
        activo: activo ?? this.activo,
        sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
      );
  CultivosLocalData copyWithCompanion(CultivosLocalCompanion data) {
    return CultivosLocalData(
      idErp: data.idErp.present ? data.idErp.value : this.idErp,
      codigoEspecie: data.codigoEspecie.present
          ? data.codigoEspecie.value
          : this.codigoEspecie,
      nombreEspecie: data.nombreEspecie.present
          ? data.nombreEspecie.value
          : this.nombreEspecie,
      nombreCultivo: data.nombreCultivo.present
          ? data.nombreCultivo.value
          : this.nombreCultivo,
      activo: data.activo.present ? data.activo.value : this.activo,
      sincronizadoAt: data.sincronizadoAt.present
          ? data.sincronizadoAt.value
          : this.sincronizadoAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CultivosLocalData(')
          ..write('idErp: $idErp, ')
          ..write('codigoEspecie: $codigoEspecie, ')
          ..write('nombreEspecie: $nombreEspecie, ')
          ..write('nombreCultivo: $nombreCultivo, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idErp, codigoEspecie, nombreEspecie,
      nombreCultivo, activo, sincronizadoAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CultivosLocalData &&
          other.idErp == this.idErp &&
          other.codigoEspecie == this.codigoEspecie &&
          other.nombreEspecie == this.nombreEspecie &&
          other.nombreCultivo == this.nombreCultivo &&
          other.activo == this.activo &&
          other.sincronizadoAt == this.sincronizadoAt);
}

class CultivosLocalCompanion extends UpdateCompanion<CultivosLocalData> {
  final Value<int> idErp;
  final Value<String> codigoEspecie;
  final Value<String> nombreEspecie;
  final Value<String?> nombreCultivo;
  final Value<bool> activo;
  final Value<DateTime> sincronizadoAt;
  const CultivosLocalCompanion({
    this.idErp = const Value.absent(),
    this.codigoEspecie = const Value.absent(),
    this.nombreEspecie = const Value.absent(),
    this.nombreCultivo = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  });
  CultivosLocalCompanion.insert({
    this.idErp = const Value.absent(),
    required String codigoEspecie,
    required String nombreEspecie,
    this.nombreCultivo = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  })  : codigoEspecie = Value(codigoEspecie),
        nombreEspecie = Value(nombreEspecie);
  static Insertable<CultivosLocalData> custom({
    Expression<int>? idErp,
    Expression<String>? codigoEspecie,
    Expression<String>? nombreEspecie,
    Expression<String>? nombreCultivo,
    Expression<bool>? activo,
    Expression<DateTime>? sincronizadoAt,
  }) {
    return RawValuesInsertable({
      if (idErp != null) 'id_erp': idErp,
      if (codigoEspecie != null) 'codigo_especie': codigoEspecie,
      if (nombreEspecie != null) 'nombre_especie': nombreEspecie,
      if (nombreCultivo != null) 'nombre_cultivo': nombreCultivo,
      if (activo != null) 'activo': activo,
      if (sincronizadoAt != null) 'sincronizado_at': sincronizadoAt,
    });
  }

  CultivosLocalCompanion copyWith(
      {Value<int>? idErp,
      Value<String>? codigoEspecie,
      Value<String>? nombreEspecie,
      Value<String?>? nombreCultivo,
      Value<bool>? activo,
      Value<DateTime>? sincronizadoAt}) {
    return CultivosLocalCompanion(
      idErp: idErp ?? this.idErp,
      codigoEspecie: codigoEspecie ?? this.codigoEspecie,
      nombreEspecie: nombreEspecie ?? this.nombreEspecie,
      nombreCultivo: nombreCultivo ?? this.nombreCultivo,
      activo: activo ?? this.activo,
      sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idErp.present) {
      map['id_erp'] = Variable<int>(idErp.value);
    }
    if (codigoEspecie.present) {
      map['codigo_especie'] = Variable<String>(codigoEspecie.value);
    }
    if (nombreEspecie.present) {
      map['nombre_especie'] = Variable<String>(nombreEspecie.value);
    }
    if (nombreCultivo.present) {
      map['nombre_cultivo'] = Variable<String>(nombreCultivo.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (sincronizadoAt.present) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CultivosLocalCompanion(')
          ..write('idErp: $idErp, ')
          ..write('codigoEspecie: $codigoEspecie, ')
          ..write('nombreEspecie: $nombreEspecie, ')
          ..write('nombreCultivo: $nombreCultivo, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }
}

class $TractoresLocalTable extends TractoresLocal
    with TableInfo<$TractoresLocalTable, TractoresLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TractoresLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idErpMeta = const VerificationMeta('idErp');
  @override
  late final GeneratedColumn<int> idErp = GeneratedColumn<int>(
      'id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _codigoTractorMeta =
      const VerificationMeta('codigoTractor');
  @override
  late final GeneratedColumn<String> codigoTractor = GeneratedColumn<String>(
      'codigo_tractor', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descripcionMeta =
      const VerificationMeta('descripcion');
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
      'descripcion', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
      'marca', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
      'modelo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _matriculaMeta =
      const VerificationMeta('matricula');
  @override
  late final GeneratedColumn<String> matricula = GeneratedColumn<String>(
      'matricula', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _codigoInternoMeta =
      const VerificationMeta('codigoInterno');
  @override
  late final GeneratedColumn<String> codigoInterno = GeneratedColumn<String>(
      'codigo_interno', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
      'zona', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sincronizadoAtMeta =
      const VerificationMeta('sincronizadoAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoAt =
      GeneratedColumn<DateTime>('sincronizado_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        idErp,
        codigoTractor,
        descripcion,
        marca,
        modelo,
        matricula,
        codigoInterno,
        zona,
        activo,
        sincronizadoAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tractores_local';
  @override
  VerificationContext validateIntegrity(Insertable<TractoresLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_erp')) {
      context.handle(
          _idErpMeta, idErp.isAcceptableOrUnknown(data['id_erp']!, _idErpMeta));
    }
    if (data.containsKey('codigo_tractor')) {
      context.handle(
          _codigoTractorMeta,
          codigoTractor.isAcceptableOrUnknown(
              data['codigo_tractor']!, _codigoTractorMeta));
    } else if (isInserting) {
      context.missing(_codigoTractorMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
          _descripcionMeta,
          descripcion.isAcceptableOrUnknown(
              data['descripcion']!, _descripcionMeta));
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('marca')) {
      context.handle(
          _marcaMeta, marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta));
    }
    if (data.containsKey('modelo')) {
      context.handle(_modeloMeta,
          modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta));
    }
    if (data.containsKey('matricula')) {
      context.handle(_matriculaMeta,
          matricula.isAcceptableOrUnknown(data['matricula']!, _matriculaMeta));
    }
    if (data.containsKey('codigo_interno')) {
      context.handle(
          _codigoInternoMeta,
          codigoInterno.isAcceptableOrUnknown(
              data['codigo_interno']!, _codigoInternoMeta));
    }
    if (data.containsKey('zona')) {
      context.handle(
          _zonaMeta, zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    if (data.containsKey('sincronizado_at')) {
      context.handle(
          _sincronizadoAtMeta,
          sincronizadoAt.isAcceptableOrUnknown(
              data['sincronizado_at']!, _sincronizadoAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idErp};
  @override
  TractoresLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TractoresLocalData(
      idErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_erp'])!,
      codigoTractor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo_tractor'])!,
      descripcion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descripcion'])!,
      marca: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}marca']),
      modelo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modelo']),
      matricula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matricula']),
      codigoInterno: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo_interno']),
      zona: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}zona']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
      sincronizadoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}sincronizado_at'])!,
    );
  }

  @override
  $TractoresLocalTable createAlias(String alias) {
    return $TractoresLocalTable(attachedDatabase, alias);
  }
}

class TractoresLocalData extends DataClass
    implements Insertable<TractoresLocalData> {
  final int idErp;
  final String codigoTractor;
  final String descripcion;
  final String? marca;
  final String? modelo;
  final String? matricula;
  final String? codigoInterno;
  final String? zona;
  final bool activo;
  final DateTime sincronizadoAt;
  const TractoresLocalData(
      {required this.idErp,
      required this.codigoTractor,
      required this.descripcion,
      this.marca,
      this.modelo,
      this.matricula,
      this.codigoInterno,
      this.zona,
      required this.activo,
      required this.sincronizadoAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_erp'] = Variable<int>(idErp);
    map['codigo_tractor'] = Variable<String>(codigoTractor);
    map['descripcion'] = Variable<String>(descripcion);
    if (!nullToAbsent || marca != null) {
      map['marca'] = Variable<String>(marca);
    }
    if (!nullToAbsent || modelo != null) {
      map['modelo'] = Variable<String>(modelo);
    }
    if (!nullToAbsent || matricula != null) {
      map['matricula'] = Variable<String>(matricula);
    }
    if (!nullToAbsent || codigoInterno != null) {
      map['codigo_interno'] = Variable<String>(codigoInterno);
    }
    if (!nullToAbsent || zona != null) {
      map['zona'] = Variable<String>(zona);
    }
    map['activo'] = Variable<bool>(activo);
    map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt);
    return map;
  }

  TractoresLocalCompanion toCompanion(bool nullToAbsent) {
    return TractoresLocalCompanion(
      idErp: Value(idErp),
      codigoTractor: Value(codigoTractor),
      descripcion: Value(descripcion),
      marca:
          marca == null && nullToAbsent ? const Value.absent() : Value(marca),
      modelo:
          modelo == null && nullToAbsent ? const Value.absent() : Value(modelo),
      matricula: matricula == null && nullToAbsent
          ? const Value.absent()
          : Value(matricula),
      codigoInterno: codigoInterno == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoInterno),
      zona: zona == null && nullToAbsent ? const Value.absent() : Value(zona),
      activo: Value(activo),
      sincronizadoAt: Value(sincronizadoAt),
    );
  }

  factory TractoresLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TractoresLocalData(
      idErp: serializer.fromJson<int>(json['idErp']),
      codigoTractor: serializer.fromJson<String>(json['codigoTractor']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      marca: serializer.fromJson<String?>(json['marca']),
      modelo: serializer.fromJson<String?>(json['modelo']),
      matricula: serializer.fromJson<String?>(json['matricula']),
      codigoInterno: serializer.fromJson<String?>(json['codigoInterno']),
      zona: serializer.fromJson<String?>(json['zona']),
      activo: serializer.fromJson<bool>(json['activo']),
      sincronizadoAt: serializer.fromJson<DateTime>(json['sincronizadoAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idErp': serializer.toJson<int>(idErp),
      'codigoTractor': serializer.toJson<String>(codigoTractor),
      'descripcion': serializer.toJson<String>(descripcion),
      'marca': serializer.toJson<String?>(marca),
      'modelo': serializer.toJson<String?>(modelo),
      'matricula': serializer.toJson<String?>(matricula),
      'codigoInterno': serializer.toJson<String?>(codigoInterno),
      'zona': serializer.toJson<String?>(zona),
      'activo': serializer.toJson<bool>(activo),
      'sincronizadoAt': serializer.toJson<DateTime>(sincronizadoAt),
    };
  }

  TractoresLocalData copyWith(
          {int? idErp,
          String? codigoTractor,
          String? descripcion,
          Value<String?> marca = const Value.absent(),
          Value<String?> modelo = const Value.absent(),
          Value<String?> matricula = const Value.absent(),
          Value<String?> codigoInterno = const Value.absent(),
          Value<String?> zona = const Value.absent(),
          bool? activo,
          DateTime? sincronizadoAt}) =>
      TractoresLocalData(
        idErp: idErp ?? this.idErp,
        codigoTractor: codigoTractor ?? this.codigoTractor,
        descripcion: descripcion ?? this.descripcion,
        marca: marca.present ? marca.value : this.marca,
        modelo: modelo.present ? modelo.value : this.modelo,
        matricula: matricula.present ? matricula.value : this.matricula,
        codigoInterno:
            codigoInterno.present ? codigoInterno.value : this.codigoInterno,
        zona: zona.present ? zona.value : this.zona,
        activo: activo ?? this.activo,
        sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
      );
  TractoresLocalData copyWithCompanion(TractoresLocalCompanion data) {
    return TractoresLocalData(
      idErp: data.idErp.present ? data.idErp.value : this.idErp,
      codigoTractor: data.codigoTractor.present
          ? data.codigoTractor.value
          : this.codigoTractor,
      descripcion:
          data.descripcion.present ? data.descripcion.value : this.descripcion,
      marca: data.marca.present ? data.marca.value : this.marca,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      matricula: data.matricula.present ? data.matricula.value : this.matricula,
      codigoInterno: data.codigoInterno.present
          ? data.codigoInterno.value
          : this.codigoInterno,
      zona: data.zona.present ? data.zona.value : this.zona,
      activo: data.activo.present ? data.activo.value : this.activo,
      sincronizadoAt: data.sincronizadoAt.present
          ? data.sincronizadoAt.value
          : this.sincronizadoAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TractoresLocalData(')
          ..write('idErp: $idErp, ')
          ..write('codigoTractor: $codigoTractor, ')
          ..write('descripcion: $descripcion, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('matricula: $matricula, ')
          ..write('codigoInterno: $codigoInterno, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idErp, codigoTractor, descripcion, marca,
      modelo, matricula, codigoInterno, zona, activo, sincronizadoAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TractoresLocalData &&
          other.idErp == this.idErp &&
          other.codigoTractor == this.codigoTractor &&
          other.descripcion == this.descripcion &&
          other.marca == this.marca &&
          other.modelo == this.modelo &&
          other.matricula == this.matricula &&
          other.codigoInterno == this.codigoInterno &&
          other.zona == this.zona &&
          other.activo == this.activo &&
          other.sincronizadoAt == this.sincronizadoAt);
}

class TractoresLocalCompanion extends UpdateCompanion<TractoresLocalData> {
  final Value<int> idErp;
  final Value<String> codigoTractor;
  final Value<String> descripcion;
  final Value<String?> marca;
  final Value<String?> modelo;
  final Value<String?> matricula;
  final Value<String?> codigoInterno;
  final Value<String?> zona;
  final Value<bool> activo;
  final Value<DateTime> sincronizadoAt;
  const TractoresLocalCompanion({
    this.idErp = const Value.absent(),
    this.codigoTractor = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.matricula = const Value.absent(),
    this.codigoInterno = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  });
  TractoresLocalCompanion.insert({
    this.idErp = const Value.absent(),
    required String codigoTractor,
    required String descripcion,
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.matricula = const Value.absent(),
    this.codigoInterno = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  })  : codigoTractor = Value(codigoTractor),
        descripcion = Value(descripcion);
  static Insertable<TractoresLocalData> custom({
    Expression<int>? idErp,
    Expression<String>? codigoTractor,
    Expression<String>? descripcion,
    Expression<String>? marca,
    Expression<String>? modelo,
    Expression<String>? matricula,
    Expression<String>? codigoInterno,
    Expression<String>? zona,
    Expression<bool>? activo,
    Expression<DateTime>? sincronizadoAt,
  }) {
    return RawValuesInsertable({
      if (idErp != null) 'id_erp': idErp,
      if (codigoTractor != null) 'codigo_tractor': codigoTractor,
      if (descripcion != null) 'descripcion': descripcion,
      if (marca != null) 'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (matricula != null) 'matricula': matricula,
      if (codigoInterno != null) 'codigo_interno': codigoInterno,
      if (zona != null) 'zona': zona,
      if (activo != null) 'activo': activo,
      if (sincronizadoAt != null) 'sincronizado_at': sincronizadoAt,
    });
  }

  TractoresLocalCompanion copyWith(
      {Value<int>? idErp,
      Value<String>? codigoTractor,
      Value<String>? descripcion,
      Value<String?>? marca,
      Value<String?>? modelo,
      Value<String?>? matricula,
      Value<String?>? codigoInterno,
      Value<String?>? zona,
      Value<bool>? activo,
      Value<DateTime>? sincronizadoAt}) {
    return TractoresLocalCompanion(
      idErp: idErp ?? this.idErp,
      codigoTractor: codigoTractor ?? this.codigoTractor,
      descripcion: descripcion ?? this.descripcion,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      matricula: matricula ?? this.matricula,
      codigoInterno: codigoInterno ?? this.codigoInterno,
      zona: zona ?? this.zona,
      activo: activo ?? this.activo,
      sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idErp.present) {
      map['id_erp'] = Variable<int>(idErp.value);
    }
    if (codigoTractor.present) {
      map['codigo_tractor'] = Variable<String>(codigoTractor.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (matricula.present) {
      map['matricula'] = Variable<String>(matricula.value);
    }
    if (codigoInterno.present) {
      map['codigo_interno'] = Variable<String>(codigoInterno.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (sincronizadoAt.present) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TractoresLocalCompanion(')
          ..write('idErp: $idErp, ')
          ..write('codigoTractor: $codigoTractor, ')
          ..write('descripcion: $descripcion, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('matricula: $matricula, ')
          ..write('codigoInterno: $codigoInterno, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }
}

class $ImplementosLocalTable extends ImplementosLocal
    with TableInfo<$ImplementosLocalTable, ImplementosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImplementosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idErpMeta = const VerificationMeta('idErp');
  @override
  late final GeneratedColumn<int> idErp = GeneratedColumn<int>(
      'id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _codigoImplementoMeta =
      const VerificationMeta('codigoImplemento');
  @override
  late final GeneratedColumn<String> codigoImplemento = GeneratedColumn<String>(
      'codigo_implemento', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descripcionMeta =
      const VerificationMeta('descripcion');
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
      'descripcion', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
      'marca', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
      'modelo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _codigoInternoMeta =
      const VerificationMeta('codigoInterno');
  @override
  late final GeneratedColumn<String> codigoInterno = GeneratedColumn<String>(
      'codigo_interno', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
      'zona', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sincronizadoAtMeta =
      const VerificationMeta('sincronizadoAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoAt =
      GeneratedColumn<DateTime>('sincronizado_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        idErp,
        codigoImplemento,
        descripcion,
        marca,
        modelo,
        codigoInterno,
        zona,
        activo,
        sincronizadoAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'implementos_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<ImplementosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_erp')) {
      context.handle(
          _idErpMeta, idErp.isAcceptableOrUnknown(data['id_erp']!, _idErpMeta));
    }
    if (data.containsKey('codigo_implemento')) {
      context.handle(
          _codigoImplementoMeta,
          codigoImplemento.isAcceptableOrUnknown(
              data['codigo_implemento']!, _codigoImplementoMeta));
    } else if (isInserting) {
      context.missing(_codigoImplementoMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
          _descripcionMeta,
          descripcion.isAcceptableOrUnknown(
              data['descripcion']!, _descripcionMeta));
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('marca')) {
      context.handle(
          _marcaMeta, marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta));
    }
    if (data.containsKey('modelo')) {
      context.handle(_modeloMeta,
          modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta));
    }
    if (data.containsKey('codigo_interno')) {
      context.handle(
          _codigoInternoMeta,
          codigoInterno.isAcceptableOrUnknown(
              data['codigo_interno']!, _codigoInternoMeta));
    }
    if (data.containsKey('zona')) {
      context.handle(
          _zonaMeta, zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    if (data.containsKey('sincronizado_at')) {
      context.handle(
          _sincronizadoAtMeta,
          sincronizadoAt.isAcceptableOrUnknown(
              data['sincronizado_at']!, _sincronizadoAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idErp};
  @override
  ImplementosLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImplementosLocalData(
      idErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_erp'])!,
      codigoImplemento: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}codigo_implemento'])!,
      descripcion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descripcion'])!,
      marca: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}marca']),
      modelo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modelo']),
      codigoInterno: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo_interno']),
      zona: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}zona']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
      sincronizadoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}sincronizado_at'])!,
    );
  }

  @override
  $ImplementosLocalTable createAlias(String alias) {
    return $ImplementosLocalTable(attachedDatabase, alias);
  }
}

class ImplementosLocalData extends DataClass
    implements Insertable<ImplementosLocalData> {
  final int idErp;
  final String codigoImplemento;
  final String descripcion;
  final String? marca;
  final String? modelo;
  final String? codigoInterno;
  final String? zona;
  final bool activo;
  final DateTime sincronizadoAt;
  const ImplementosLocalData(
      {required this.idErp,
      required this.codigoImplemento,
      required this.descripcion,
      this.marca,
      this.modelo,
      this.codigoInterno,
      this.zona,
      required this.activo,
      required this.sincronizadoAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_erp'] = Variable<int>(idErp);
    map['codigo_implemento'] = Variable<String>(codigoImplemento);
    map['descripcion'] = Variable<String>(descripcion);
    if (!nullToAbsent || marca != null) {
      map['marca'] = Variable<String>(marca);
    }
    if (!nullToAbsent || modelo != null) {
      map['modelo'] = Variable<String>(modelo);
    }
    if (!nullToAbsent || codigoInterno != null) {
      map['codigo_interno'] = Variable<String>(codigoInterno);
    }
    if (!nullToAbsent || zona != null) {
      map['zona'] = Variable<String>(zona);
    }
    map['activo'] = Variable<bool>(activo);
    map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt);
    return map;
  }

  ImplementosLocalCompanion toCompanion(bool nullToAbsent) {
    return ImplementosLocalCompanion(
      idErp: Value(idErp),
      codigoImplemento: Value(codigoImplemento),
      descripcion: Value(descripcion),
      marca:
          marca == null && nullToAbsent ? const Value.absent() : Value(marca),
      modelo:
          modelo == null && nullToAbsent ? const Value.absent() : Value(modelo),
      codigoInterno: codigoInterno == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoInterno),
      zona: zona == null && nullToAbsent ? const Value.absent() : Value(zona),
      activo: Value(activo),
      sincronizadoAt: Value(sincronizadoAt),
    );
  }

  factory ImplementosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImplementosLocalData(
      idErp: serializer.fromJson<int>(json['idErp']),
      codigoImplemento: serializer.fromJson<String>(json['codigoImplemento']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      marca: serializer.fromJson<String?>(json['marca']),
      modelo: serializer.fromJson<String?>(json['modelo']),
      codigoInterno: serializer.fromJson<String?>(json['codigoInterno']),
      zona: serializer.fromJson<String?>(json['zona']),
      activo: serializer.fromJson<bool>(json['activo']),
      sincronizadoAt: serializer.fromJson<DateTime>(json['sincronizadoAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idErp': serializer.toJson<int>(idErp),
      'codigoImplemento': serializer.toJson<String>(codigoImplemento),
      'descripcion': serializer.toJson<String>(descripcion),
      'marca': serializer.toJson<String?>(marca),
      'modelo': serializer.toJson<String?>(modelo),
      'codigoInterno': serializer.toJson<String?>(codigoInterno),
      'zona': serializer.toJson<String?>(zona),
      'activo': serializer.toJson<bool>(activo),
      'sincronizadoAt': serializer.toJson<DateTime>(sincronizadoAt),
    };
  }

  ImplementosLocalData copyWith(
          {int? idErp,
          String? codigoImplemento,
          String? descripcion,
          Value<String?> marca = const Value.absent(),
          Value<String?> modelo = const Value.absent(),
          Value<String?> codigoInterno = const Value.absent(),
          Value<String?> zona = const Value.absent(),
          bool? activo,
          DateTime? sincronizadoAt}) =>
      ImplementosLocalData(
        idErp: idErp ?? this.idErp,
        codigoImplemento: codigoImplemento ?? this.codigoImplemento,
        descripcion: descripcion ?? this.descripcion,
        marca: marca.present ? marca.value : this.marca,
        modelo: modelo.present ? modelo.value : this.modelo,
        codigoInterno:
            codigoInterno.present ? codigoInterno.value : this.codigoInterno,
        zona: zona.present ? zona.value : this.zona,
        activo: activo ?? this.activo,
        sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
      );
  ImplementosLocalData copyWithCompanion(ImplementosLocalCompanion data) {
    return ImplementosLocalData(
      idErp: data.idErp.present ? data.idErp.value : this.idErp,
      codigoImplemento: data.codigoImplemento.present
          ? data.codigoImplemento.value
          : this.codigoImplemento,
      descripcion:
          data.descripcion.present ? data.descripcion.value : this.descripcion,
      marca: data.marca.present ? data.marca.value : this.marca,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      codigoInterno: data.codigoInterno.present
          ? data.codigoInterno.value
          : this.codigoInterno,
      zona: data.zona.present ? data.zona.value : this.zona,
      activo: data.activo.present ? data.activo.value : this.activo,
      sincronizadoAt: data.sincronizadoAt.present
          ? data.sincronizadoAt.value
          : this.sincronizadoAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImplementosLocalData(')
          ..write('idErp: $idErp, ')
          ..write('codigoImplemento: $codigoImplemento, ')
          ..write('descripcion: $descripcion, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('codigoInterno: $codigoInterno, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idErp, codigoImplemento, descripcion, marca,
      modelo, codigoInterno, zona, activo, sincronizadoAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImplementosLocalData &&
          other.idErp == this.idErp &&
          other.codigoImplemento == this.codigoImplemento &&
          other.descripcion == this.descripcion &&
          other.marca == this.marca &&
          other.modelo == this.modelo &&
          other.codigoInterno == this.codigoInterno &&
          other.zona == this.zona &&
          other.activo == this.activo &&
          other.sincronizadoAt == this.sincronizadoAt);
}

class ImplementosLocalCompanion extends UpdateCompanion<ImplementosLocalData> {
  final Value<int> idErp;
  final Value<String> codigoImplemento;
  final Value<String> descripcion;
  final Value<String?> marca;
  final Value<String?> modelo;
  final Value<String?> codigoInterno;
  final Value<String?> zona;
  final Value<bool> activo;
  final Value<DateTime> sincronizadoAt;
  const ImplementosLocalCompanion({
    this.idErp = const Value.absent(),
    this.codigoImplemento = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.codigoInterno = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  });
  ImplementosLocalCompanion.insert({
    this.idErp = const Value.absent(),
    required String codigoImplemento,
    required String descripcion,
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.codigoInterno = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  })  : codigoImplemento = Value(codigoImplemento),
        descripcion = Value(descripcion);
  static Insertable<ImplementosLocalData> custom({
    Expression<int>? idErp,
    Expression<String>? codigoImplemento,
    Expression<String>? descripcion,
    Expression<String>? marca,
    Expression<String>? modelo,
    Expression<String>? codigoInterno,
    Expression<String>? zona,
    Expression<bool>? activo,
    Expression<DateTime>? sincronizadoAt,
  }) {
    return RawValuesInsertable({
      if (idErp != null) 'id_erp': idErp,
      if (codigoImplemento != null) 'codigo_implemento': codigoImplemento,
      if (descripcion != null) 'descripcion': descripcion,
      if (marca != null) 'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (codigoInterno != null) 'codigo_interno': codigoInterno,
      if (zona != null) 'zona': zona,
      if (activo != null) 'activo': activo,
      if (sincronizadoAt != null) 'sincronizado_at': sincronizadoAt,
    });
  }

  ImplementosLocalCompanion copyWith(
      {Value<int>? idErp,
      Value<String>? codigoImplemento,
      Value<String>? descripcion,
      Value<String?>? marca,
      Value<String?>? modelo,
      Value<String?>? codigoInterno,
      Value<String?>? zona,
      Value<bool>? activo,
      Value<DateTime>? sincronizadoAt}) {
    return ImplementosLocalCompanion(
      idErp: idErp ?? this.idErp,
      codigoImplemento: codigoImplemento ?? this.codigoImplemento,
      descripcion: descripcion ?? this.descripcion,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      codigoInterno: codigoInterno ?? this.codigoInterno,
      zona: zona ?? this.zona,
      activo: activo ?? this.activo,
      sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idErp.present) {
      map['id_erp'] = Variable<int>(idErp.value);
    }
    if (codigoImplemento.present) {
      map['codigo_implemento'] = Variable<String>(codigoImplemento.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (codigoInterno.present) {
      map['codigo_interno'] = Variable<String>(codigoInterno.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (sincronizadoAt.present) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImplementosLocalCompanion(')
          ..write('idErp: $idErp, ')
          ..write('codigoImplemento: $codigoImplemento, ')
          ..write('descripcion: $descripcion, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('codigoInterno: $codigoInterno, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }
}

class $TrabajadoresLocalTable extends TrabajadoresLocal
    with TableInfo<$TrabajadoresLocalTable, TrabajadoresLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrabajadoresLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idErpMeta = const VerificationMeta('idErp');
  @override
  late final GeneratedColumn<int> idErp = GeneratedColumn<int>(
      'id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _usuarioErpIdMeta =
      const VerificationMeta('usuarioErpId');
  @override
  late final GeneratedColumn<int> usuarioErpId = GeneratedColumn<int>(
      'usuario_erp_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _codTrabajadorMeta =
      const VerificationMeta('codTrabajador');
  @override
  late final GeneratedColumn<String> codTrabajador = GeneratedColumn<String>(
      'cod_trabajador', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codigoBarraMeta =
      const VerificationMeta('codigoBarra');
  @override
  late final GeneratedColumn<String> codigoBarra = GeneratedColumn<String>(
      'codigo_barra', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nombresMeta =
      const VerificationMeta('nombres');
  @override
  late final GeneratedColumn<String> nombres = GeneratedColumn<String>(
      'nombres', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apellidosMeta =
      const VerificationMeta('apellidos');
  @override
  late final GeneratedColumn<String> apellidos = GeneratedColumn<String>(
      'apellidos', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dniMeta = const VerificationMeta('dni');
  @override
  late final GeneratedColumn<String> dni = GeneratedColumn<String>(
      'dni', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rolApkMeta = const VerificationMeta('rolApk');
  @override
  late final GeneratedColumn<String> rolApk = GeneratedColumn<String>(
      'rol_apk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('operador'));
  static const VerificationMeta _pinHashMeta =
      const VerificationMeta('pinHash');
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
      'pin_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sincronizadoAtMeta =
      const VerificationMeta('sincronizadoAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoAt =
      GeneratedColumn<DateTime>('sincronizado_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        idErp,
        usuarioErpId,
        codTrabajador,
        codigoBarra,
        nombres,
        apellidos,
        dni,
        rolApk,
        pinHash,
        activo,
        sincronizadoAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trabajadores_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<TrabajadoresLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_erp')) {
      context.handle(
          _idErpMeta, idErp.isAcceptableOrUnknown(data['id_erp']!, _idErpMeta));
    }
    if (data.containsKey('usuario_erp_id')) {
      context.handle(
          _usuarioErpIdMeta,
          usuarioErpId.isAcceptableOrUnknown(
              data['usuario_erp_id']!, _usuarioErpIdMeta));
    }
    if (data.containsKey('cod_trabajador')) {
      context.handle(
          _codTrabajadorMeta,
          codTrabajador.isAcceptableOrUnknown(
              data['cod_trabajador']!, _codTrabajadorMeta));
    } else if (isInserting) {
      context.missing(_codTrabajadorMeta);
    }
    if (data.containsKey('codigo_barra')) {
      context.handle(
          _codigoBarraMeta,
          codigoBarra.isAcceptableOrUnknown(
              data['codigo_barra']!, _codigoBarraMeta));
    }
    if (data.containsKey('nombres')) {
      context.handle(_nombresMeta,
          nombres.isAcceptableOrUnknown(data['nombres']!, _nombresMeta));
    } else if (isInserting) {
      context.missing(_nombresMeta);
    }
    if (data.containsKey('apellidos')) {
      context.handle(_apellidosMeta,
          apellidos.isAcceptableOrUnknown(data['apellidos']!, _apellidosMeta));
    } else if (isInserting) {
      context.missing(_apellidosMeta);
    }
    if (data.containsKey('dni')) {
      context.handle(
          _dniMeta, dni.isAcceptableOrUnknown(data['dni']!, _dniMeta));
    }
    if (data.containsKey('rol_apk')) {
      context.handle(_rolApkMeta,
          rolApk.isAcceptableOrUnknown(data['rol_apk']!, _rolApkMeta));
    }
    if (data.containsKey('pin_hash')) {
      context.handle(_pinHashMeta,
          pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    if (data.containsKey('sincronizado_at')) {
      context.handle(
          _sincronizadoAtMeta,
          sincronizadoAt.isAcceptableOrUnknown(
              data['sincronizado_at']!, _sincronizadoAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idErp};
  @override
  TrabajadoresLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrabajadoresLocalData(
      idErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_erp'])!,
      usuarioErpId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usuario_erp_id']),
      codTrabajador: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cod_trabajador'])!,
      codigoBarra: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo_barra']),
      nombres: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombres'])!,
      apellidos: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}apellidos'])!,
      dni: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dni']),
      rolApk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rol_apk'])!,
      pinHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_hash']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
      sincronizadoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}sincronizado_at'])!,
    );
  }

  @override
  $TrabajadoresLocalTable createAlias(String alias) {
    return $TrabajadoresLocalTable(attachedDatabase, alias);
  }
}

class TrabajadoresLocalData extends DataClass
    implements Insertable<TrabajadoresLocalData> {
  final int idErp;

  /// Usuarios.Id del ERP — es el que se envía al SP de jornada.
  final int? usuarioErpId;

  /// Usuarios.Codigo del ERP — código de login (ej. "PCORZO", "MVILLENA").
  /// Usado para lookup en auth y en la pantalla de bienvenida.
  final String codTrabajador;

  /// Código físico/barcode del trabajador (ej. "468834").
  /// Viene de SUBSTRING(t.Codigo, 6, ...) en el SP de sync.
  /// Usado por el portero al escanear y como fallback en login PIN.
  final String? codigoBarra;
  final String nombres;
  final String apellidos;
  final String? dni;

  /// 'operador' | 'supervisor'
  final String rolApk;

  /// SHA-256 del PIN — seteado al momento del primer login con PIN.
  final String? pinHash;
  final bool activo;
  final DateTime sincronizadoAt;
  const TrabajadoresLocalData(
      {required this.idErp,
      this.usuarioErpId,
      required this.codTrabajador,
      this.codigoBarra,
      required this.nombres,
      required this.apellidos,
      this.dni,
      required this.rolApk,
      this.pinHash,
      required this.activo,
      required this.sincronizadoAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_erp'] = Variable<int>(idErp);
    if (!nullToAbsent || usuarioErpId != null) {
      map['usuario_erp_id'] = Variable<int>(usuarioErpId);
    }
    map['cod_trabajador'] = Variable<String>(codTrabajador);
    if (!nullToAbsent || codigoBarra != null) {
      map['codigo_barra'] = Variable<String>(codigoBarra);
    }
    map['nombres'] = Variable<String>(nombres);
    map['apellidos'] = Variable<String>(apellidos);
    if (!nullToAbsent || dni != null) {
      map['dni'] = Variable<String>(dni);
    }
    map['rol_apk'] = Variable<String>(rolApk);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    map['activo'] = Variable<bool>(activo);
    map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt);
    return map;
  }

  TrabajadoresLocalCompanion toCompanion(bool nullToAbsent) {
    return TrabajadoresLocalCompanion(
      idErp: Value(idErp),
      usuarioErpId: usuarioErpId == null && nullToAbsent
          ? const Value.absent()
          : Value(usuarioErpId),
      codTrabajador: Value(codTrabajador),
      codigoBarra: codigoBarra == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoBarra),
      nombres: Value(nombres),
      apellidos: Value(apellidos),
      dni: dni == null && nullToAbsent ? const Value.absent() : Value(dni),
      rolApk: Value(rolApk),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      activo: Value(activo),
      sincronizadoAt: Value(sincronizadoAt),
    );
  }

  factory TrabajadoresLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrabajadoresLocalData(
      idErp: serializer.fromJson<int>(json['idErp']),
      usuarioErpId: serializer.fromJson<int?>(json['usuarioErpId']),
      codTrabajador: serializer.fromJson<String>(json['codTrabajador']),
      codigoBarra: serializer.fromJson<String?>(json['codigoBarra']),
      nombres: serializer.fromJson<String>(json['nombres']),
      apellidos: serializer.fromJson<String>(json['apellidos']),
      dni: serializer.fromJson<String?>(json['dni']),
      rolApk: serializer.fromJson<String>(json['rolApk']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      activo: serializer.fromJson<bool>(json['activo']),
      sincronizadoAt: serializer.fromJson<DateTime>(json['sincronizadoAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idErp': serializer.toJson<int>(idErp),
      'usuarioErpId': serializer.toJson<int?>(usuarioErpId),
      'codTrabajador': serializer.toJson<String>(codTrabajador),
      'codigoBarra': serializer.toJson<String?>(codigoBarra),
      'nombres': serializer.toJson<String>(nombres),
      'apellidos': serializer.toJson<String>(apellidos),
      'dni': serializer.toJson<String?>(dni),
      'rolApk': serializer.toJson<String>(rolApk),
      'pinHash': serializer.toJson<String?>(pinHash),
      'activo': serializer.toJson<bool>(activo),
      'sincronizadoAt': serializer.toJson<DateTime>(sincronizadoAt),
    };
  }

  TrabajadoresLocalData copyWith(
          {int? idErp,
          Value<int?> usuarioErpId = const Value.absent(),
          String? codTrabajador,
          Value<String?> codigoBarra = const Value.absent(),
          String? nombres,
          String? apellidos,
          Value<String?> dni = const Value.absent(),
          String? rolApk,
          Value<String?> pinHash = const Value.absent(),
          bool? activo,
          DateTime? sincronizadoAt}) =>
      TrabajadoresLocalData(
        idErp: idErp ?? this.idErp,
        usuarioErpId:
            usuarioErpId.present ? usuarioErpId.value : this.usuarioErpId,
        codTrabajador: codTrabajador ?? this.codTrabajador,
        codigoBarra: codigoBarra.present ? codigoBarra.value : this.codigoBarra,
        nombres: nombres ?? this.nombres,
        apellidos: apellidos ?? this.apellidos,
        dni: dni.present ? dni.value : this.dni,
        rolApk: rolApk ?? this.rolApk,
        pinHash: pinHash.present ? pinHash.value : this.pinHash,
        activo: activo ?? this.activo,
        sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
      );
  TrabajadoresLocalData copyWithCompanion(TrabajadoresLocalCompanion data) {
    return TrabajadoresLocalData(
      idErp: data.idErp.present ? data.idErp.value : this.idErp,
      usuarioErpId: data.usuarioErpId.present
          ? data.usuarioErpId.value
          : this.usuarioErpId,
      codTrabajador: data.codTrabajador.present
          ? data.codTrabajador.value
          : this.codTrabajador,
      codigoBarra:
          data.codigoBarra.present ? data.codigoBarra.value : this.codigoBarra,
      nombres: data.nombres.present ? data.nombres.value : this.nombres,
      apellidos: data.apellidos.present ? data.apellidos.value : this.apellidos,
      dni: data.dni.present ? data.dni.value : this.dni,
      rolApk: data.rolApk.present ? data.rolApk.value : this.rolApk,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      activo: data.activo.present ? data.activo.value : this.activo,
      sincronizadoAt: data.sincronizadoAt.present
          ? data.sincronizadoAt.value
          : this.sincronizadoAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrabajadoresLocalData(')
          ..write('idErp: $idErp, ')
          ..write('usuarioErpId: $usuarioErpId, ')
          ..write('codTrabajador: $codTrabajador, ')
          ..write('codigoBarra: $codigoBarra, ')
          ..write('nombres: $nombres, ')
          ..write('apellidos: $apellidos, ')
          ..write('dni: $dni, ')
          ..write('rolApk: $rolApk, ')
          ..write('pinHash: $pinHash, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      idErp,
      usuarioErpId,
      codTrabajador,
      codigoBarra,
      nombres,
      apellidos,
      dni,
      rolApk,
      pinHash,
      activo,
      sincronizadoAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrabajadoresLocalData &&
          other.idErp == this.idErp &&
          other.usuarioErpId == this.usuarioErpId &&
          other.codTrabajador == this.codTrabajador &&
          other.codigoBarra == this.codigoBarra &&
          other.nombres == this.nombres &&
          other.apellidos == this.apellidos &&
          other.dni == this.dni &&
          other.rolApk == this.rolApk &&
          other.pinHash == this.pinHash &&
          other.activo == this.activo &&
          other.sincronizadoAt == this.sincronizadoAt);
}

class TrabajadoresLocalCompanion
    extends UpdateCompanion<TrabajadoresLocalData> {
  final Value<int> idErp;
  final Value<int?> usuarioErpId;
  final Value<String> codTrabajador;
  final Value<String?> codigoBarra;
  final Value<String> nombres;
  final Value<String> apellidos;
  final Value<String?> dni;
  final Value<String> rolApk;
  final Value<String?> pinHash;
  final Value<bool> activo;
  final Value<DateTime> sincronizadoAt;
  const TrabajadoresLocalCompanion({
    this.idErp = const Value.absent(),
    this.usuarioErpId = const Value.absent(),
    this.codTrabajador = const Value.absent(),
    this.codigoBarra = const Value.absent(),
    this.nombres = const Value.absent(),
    this.apellidos = const Value.absent(),
    this.dni = const Value.absent(),
    this.rolApk = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  });
  TrabajadoresLocalCompanion.insert({
    this.idErp = const Value.absent(),
    this.usuarioErpId = const Value.absent(),
    required String codTrabajador,
    this.codigoBarra = const Value.absent(),
    required String nombres,
    required String apellidos,
    this.dni = const Value.absent(),
    this.rolApk = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
  })  : codTrabajador = Value(codTrabajador),
        nombres = Value(nombres),
        apellidos = Value(apellidos);
  static Insertable<TrabajadoresLocalData> custom({
    Expression<int>? idErp,
    Expression<int>? usuarioErpId,
    Expression<String>? codTrabajador,
    Expression<String>? codigoBarra,
    Expression<String>? nombres,
    Expression<String>? apellidos,
    Expression<String>? dni,
    Expression<String>? rolApk,
    Expression<String>? pinHash,
    Expression<bool>? activo,
    Expression<DateTime>? sincronizadoAt,
  }) {
    return RawValuesInsertable({
      if (idErp != null) 'id_erp': idErp,
      if (usuarioErpId != null) 'usuario_erp_id': usuarioErpId,
      if (codTrabajador != null) 'cod_trabajador': codTrabajador,
      if (codigoBarra != null) 'codigo_barra': codigoBarra,
      if (nombres != null) 'nombres': nombres,
      if (apellidos != null) 'apellidos': apellidos,
      if (dni != null) 'dni': dni,
      if (rolApk != null) 'rol_apk': rolApk,
      if (pinHash != null) 'pin_hash': pinHash,
      if (activo != null) 'activo': activo,
      if (sincronizadoAt != null) 'sincronizado_at': sincronizadoAt,
    });
  }

  TrabajadoresLocalCompanion copyWith(
      {Value<int>? idErp,
      Value<int?>? usuarioErpId,
      Value<String>? codTrabajador,
      Value<String?>? codigoBarra,
      Value<String>? nombres,
      Value<String>? apellidos,
      Value<String?>? dni,
      Value<String>? rolApk,
      Value<String?>? pinHash,
      Value<bool>? activo,
      Value<DateTime>? sincronizadoAt}) {
    return TrabajadoresLocalCompanion(
      idErp: idErp ?? this.idErp,
      usuarioErpId: usuarioErpId ?? this.usuarioErpId,
      codTrabajador: codTrabajador ?? this.codTrabajador,
      codigoBarra: codigoBarra ?? this.codigoBarra,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      rolApk: rolApk ?? this.rolApk,
      pinHash: pinHash ?? this.pinHash,
      activo: activo ?? this.activo,
      sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idErp.present) {
      map['id_erp'] = Variable<int>(idErp.value);
    }
    if (usuarioErpId.present) {
      map['usuario_erp_id'] = Variable<int>(usuarioErpId.value);
    }
    if (codTrabajador.present) {
      map['cod_trabajador'] = Variable<String>(codTrabajador.value);
    }
    if (codigoBarra.present) {
      map['codigo_barra'] = Variable<String>(codigoBarra.value);
    }
    if (nombres.present) {
      map['nombres'] = Variable<String>(nombres.value);
    }
    if (apellidos.present) {
      map['apellidos'] = Variable<String>(apellidos.value);
    }
    if (dni.present) {
      map['dni'] = Variable<String>(dni.value);
    }
    if (rolApk.present) {
      map['rol_apk'] = Variable<String>(rolApk.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (sincronizadoAt.present) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrabajadoresLocalCompanion(')
          ..write('idErp: $idErp, ')
          ..write('usuarioErpId: $usuarioErpId, ')
          ..write('codTrabajador: $codTrabajador, ')
          ..write('codigoBarra: $codigoBarra, ')
          ..write('nombres: $nombres, ')
          ..write('apellidos: $apellidos, ')
          ..write('dni: $dni, ')
          ..write('rolApk: $rolApk, ')
          ..write('pinHash: $pinHash, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt')
          ..write(')'))
        .toString();
  }
}

class $LotesLocalTable extends LotesLocal
    with TableInfo<$LotesLocalTable, LotesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LotesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idErpMeta = const VerificationMeta('idErp');
  @override
  late final GeneratedColumn<int> idErp = GeneratedColumn<int>(
      'id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _loteCodigoMeta =
      const VerificationMeta('loteCodigo');
  @override
  late final GeneratedColumn<String> loteCodigo = GeneratedColumn<String>(
      'lote_codigo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loteNombreMeta =
      const VerificationMeta('loteNombre');
  @override
  late final GeneratedColumn<String> loteNombre = GeneratedColumn<String>(
      'lote_nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fincaIdErpMeta =
      const VerificationMeta('fincaIdErp');
  @override
  late final GeneratedColumn<int> fincaIdErp = GeneratedColumn<int>(
      'finca_id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fincaNombreMeta =
      const VerificationMeta('fincaNombre');
  @override
  late final GeneratedColumn<String> fincaNombre = GeneratedColumn<String>(
      'finca_nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subloteMeta =
      const VerificationMeta('sublote');
  @override
  late final GeneratedColumn<String> sublote = GeneratedColumn<String>(
      'sublote', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _areaHaMeta = const VerificationMeta('areaHa');
  @override
  late final GeneratedColumn<double> areaHa = GeneratedColumn<double>(
      'area_ha', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
      'zona', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sincronizadoAtMeta =
      const VerificationMeta('sincronizadoAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoAt =
      GeneratedColumn<DateTime>('sincronizado_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  static const VerificationMeta _geometriaWktMeta =
      const VerificationMeta('geometriaWkt');
  @override
  late final GeneratedColumn<String> geometriaWkt = GeneratedColumn<String>(
      'geometria_wkt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudCentroMeta =
      const VerificationMeta('latitudCentro');
  @override
  late final GeneratedColumn<double> latitudCentro = GeneratedColumn<double>(
      'latitud_centro', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudCentroMeta =
      const VerificationMeta('longitudCentro');
  @override
  late final GeneratedColumn<double> longitudCentro = GeneratedColumn<double>(
      'longitud_centro', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _nombreCultivoMeta =
      const VerificationMeta('nombreCultivo');
  @override
  late final GeneratedColumn<String> nombreCultivo = GeneratedColumn<String>(
      'nombre_cultivo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorCultivoMeta =
      const VerificationMeta('colorCultivo');
  @override
  late final GeneratedColumn<String> colorCultivo = GeneratedColumn<String>(
      'color_cultivo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        idErp,
        loteCodigo,
        loteNombre,
        fincaIdErp,
        fincaNombre,
        sublote,
        areaHa,
        zona,
        activo,
        sincronizadoAt,
        geometriaWkt,
        latitudCentro,
        longitudCentro,
        nombreCultivo,
        colorCultivo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lotes_local';
  @override
  VerificationContext validateIntegrity(Insertable<LotesLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_erp')) {
      context.handle(
          _idErpMeta, idErp.isAcceptableOrUnknown(data['id_erp']!, _idErpMeta));
    }
    if (data.containsKey('lote_codigo')) {
      context.handle(
          _loteCodigoMeta,
          loteCodigo.isAcceptableOrUnknown(
              data['lote_codigo']!, _loteCodigoMeta));
    } else if (isInserting) {
      context.missing(_loteCodigoMeta);
    }
    if (data.containsKey('lote_nombre')) {
      context.handle(
          _loteNombreMeta,
          loteNombre.isAcceptableOrUnknown(
              data['lote_nombre']!, _loteNombreMeta));
    } else if (isInserting) {
      context.missing(_loteNombreMeta);
    }
    if (data.containsKey('finca_id_erp')) {
      context.handle(
          _fincaIdErpMeta,
          fincaIdErp.isAcceptableOrUnknown(
              data['finca_id_erp']!, _fincaIdErpMeta));
    } else if (isInserting) {
      context.missing(_fincaIdErpMeta);
    }
    if (data.containsKey('finca_nombre')) {
      context.handle(
          _fincaNombreMeta,
          fincaNombre.isAcceptableOrUnknown(
              data['finca_nombre']!, _fincaNombreMeta));
    } else if (isInserting) {
      context.missing(_fincaNombreMeta);
    }
    if (data.containsKey('sublote')) {
      context.handle(_subloteMeta,
          sublote.isAcceptableOrUnknown(data['sublote']!, _subloteMeta));
    }
    if (data.containsKey('area_ha')) {
      context.handle(_areaHaMeta,
          areaHa.isAcceptableOrUnknown(data['area_ha']!, _areaHaMeta));
    }
    if (data.containsKey('zona')) {
      context.handle(
          _zonaMeta, zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    if (data.containsKey('sincronizado_at')) {
      context.handle(
          _sincronizadoAtMeta,
          sincronizadoAt.isAcceptableOrUnknown(
              data['sincronizado_at']!, _sincronizadoAtMeta));
    }
    if (data.containsKey('geometria_wkt')) {
      context.handle(
          _geometriaWktMeta,
          geometriaWkt.isAcceptableOrUnknown(
              data['geometria_wkt']!, _geometriaWktMeta));
    }
    if (data.containsKey('latitud_centro')) {
      context.handle(
          _latitudCentroMeta,
          latitudCentro.isAcceptableOrUnknown(
              data['latitud_centro']!, _latitudCentroMeta));
    }
    if (data.containsKey('longitud_centro')) {
      context.handle(
          _longitudCentroMeta,
          longitudCentro.isAcceptableOrUnknown(
              data['longitud_centro']!, _longitudCentroMeta));
    }
    if (data.containsKey('nombre_cultivo')) {
      context.handle(
          _nombreCultivoMeta,
          nombreCultivo.isAcceptableOrUnknown(
              data['nombre_cultivo']!, _nombreCultivoMeta));
    }
    if (data.containsKey('color_cultivo')) {
      context.handle(
          _colorCultivoMeta,
          colorCultivo.isAcceptableOrUnknown(
              data['color_cultivo']!, _colorCultivoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idErp};
  @override
  LotesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LotesLocalData(
      idErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_erp'])!,
      loteCodigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lote_codigo'])!,
      loteNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lote_nombre'])!,
      fincaIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}finca_id_erp'])!,
      fincaNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}finca_nombre'])!,
      sublote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sublote']),
      areaHa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}area_ha']),
      zona: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}zona']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
      sincronizadoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}sincronizado_at'])!,
      geometriaWkt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}geometria_wkt']),
      latitudCentro: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitud_centro']),
      longitudCentro: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitud_centro']),
      nombreCultivo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre_cultivo']),
      colorCultivo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_cultivo']),
    );
  }

  @override
  $LotesLocalTable createAlias(String alias) {
    return $LotesLocalTable(attachedDatabase, alias);
  }
}

class LotesLocalData extends DataClass implements Insertable<LotesLocalData> {
  final int idErp;
  final String loteCodigo;
  final String loteNombre;
  final int fincaIdErp;
  final String fincaNombre;
  final String? sublote;
  final double? areaHa;
  final String? zona;
  final bool activo;
  final DateTime sincronizadoAt;
  final String? geometriaWkt;
  final double? latitudCentro;
  final double? longitudCentro;
  final String? nombreCultivo;
  final String? colorCultivo;
  const LotesLocalData(
      {required this.idErp,
      required this.loteCodigo,
      required this.loteNombre,
      required this.fincaIdErp,
      required this.fincaNombre,
      this.sublote,
      this.areaHa,
      this.zona,
      required this.activo,
      required this.sincronizadoAt,
      this.geometriaWkt,
      this.latitudCentro,
      this.longitudCentro,
      this.nombreCultivo,
      this.colorCultivo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_erp'] = Variable<int>(idErp);
    map['lote_codigo'] = Variable<String>(loteCodigo);
    map['lote_nombre'] = Variable<String>(loteNombre);
    map['finca_id_erp'] = Variable<int>(fincaIdErp);
    map['finca_nombre'] = Variable<String>(fincaNombre);
    if (!nullToAbsent || sublote != null) {
      map['sublote'] = Variable<String>(sublote);
    }
    if (!nullToAbsent || areaHa != null) {
      map['area_ha'] = Variable<double>(areaHa);
    }
    if (!nullToAbsent || zona != null) {
      map['zona'] = Variable<String>(zona);
    }
    map['activo'] = Variable<bool>(activo);
    map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt);
    if (!nullToAbsent || geometriaWkt != null) {
      map['geometria_wkt'] = Variable<String>(geometriaWkt);
    }
    if (!nullToAbsent || latitudCentro != null) {
      map['latitud_centro'] = Variable<double>(latitudCentro);
    }
    if (!nullToAbsent || longitudCentro != null) {
      map['longitud_centro'] = Variable<double>(longitudCentro);
    }
    if (!nullToAbsent || nombreCultivo != null) {
      map['nombre_cultivo'] = Variable<String>(nombreCultivo);
    }
    if (!nullToAbsent || colorCultivo != null) {
      map['color_cultivo'] = Variable<String>(colorCultivo);
    }
    return map;
  }

  LotesLocalCompanion toCompanion(bool nullToAbsent) {
    return LotesLocalCompanion(
      idErp: Value(idErp),
      loteCodigo: Value(loteCodigo),
      loteNombre: Value(loteNombre),
      fincaIdErp: Value(fincaIdErp),
      fincaNombre: Value(fincaNombre),
      sublote: sublote == null && nullToAbsent
          ? const Value.absent()
          : Value(sublote),
      areaHa:
          areaHa == null && nullToAbsent ? const Value.absent() : Value(areaHa),
      zona: zona == null && nullToAbsent ? const Value.absent() : Value(zona),
      activo: Value(activo),
      sincronizadoAt: Value(sincronizadoAt),
      geometriaWkt: geometriaWkt == null && nullToAbsent
          ? const Value.absent()
          : Value(geometriaWkt),
      latitudCentro: latitudCentro == null && nullToAbsent
          ? const Value.absent()
          : Value(latitudCentro),
      longitudCentro: longitudCentro == null && nullToAbsent
          ? const Value.absent()
          : Value(longitudCentro),
      nombreCultivo: nombreCultivo == null && nullToAbsent
          ? const Value.absent()
          : Value(nombreCultivo),
      colorCultivo: colorCultivo == null && nullToAbsent
          ? const Value.absent()
          : Value(colorCultivo),
    );
  }

  factory LotesLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LotesLocalData(
      idErp: serializer.fromJson<int>(json['idErp']),
      loteCodigo: serializer.fromJson<String>(json['loteCodigo']),
      loteNombre: serializer.fromJson<String>(json['loteNombre']),
      fincaIdErp: serializer.fromJson<int>(json['fincaIdErp']),
      fincaNombre: serializer.fromJson<String>(json['fincaNombre']),
      sublote: serializer.fromJson<String?>(json['sublote']),
      areaHa: serializer.fromJson<double?>(json['areaHa']),
      zona: serializer.fromJson<String?>(json['zona']),
      activo: serializer.fromJson<bool>(json['activo']),
      sincronizadoAt: serializer.fromJson<DateTime>(json['sincronizadoAt']),
      geometriaWkt: serializer.fromJson<String?>(json['geometriaWkt']),
      latitudCentro: serializer.fromJson<double?>(json['latitudCentro']),
      longitudCentro: serializer.fromJson<double?>(json['longitudCentro']),
      nombreCultivo: serializer.fromJson<String?>(json['nombreCultivo']),
      colorCultivo: serializer.fromJson<String?>(json['colorCultivo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idErp': serializer.toJson<int>(idErp),
      'loteCodigo': serializer.toJson<String>(loteCodigo),
      'loteNombre': serializer.toJson<String>(loteNombre),
      'fincaIdErp': serializer.toJson<int>(fincaIdErp),
      'fincaNombre': serializer.toJson<String>(fincaNombre),
      'sublote': serializer.toJson<String?>(sublote),
      'areaHa': serializer.toJson<double?>(areaHa),
      'zona': serializer.toJson<String?>(zona),
      'activo': serializer.toJson<bool>(activo),
      'sincronizadoAt': serializer.toJson<DateTime>(sincronizadoAt),
      'geometriaWkt': serializer.toJson<String?>(geometriaWkt),
      'latitudCentro': serializer.toJson<double?>(latitudCentro),
      'longitudCentro': serializer.toJson<double?>(longitudCentro),
      'nombreCultivo': serializer.toJson<String?>(nombreCultivo),
      'colorCultivo': serializer.toJson<String?>(colorCultivo),
    };
  }

  LotesLocalData copyWith(
          {int? idErp,
          String? loteCodigo,
          String? loteNombre,
          int? fincaIdErp,
          String? fincaNombre,
          Value<String?> sublote = const Value.absent(),
          Value<double?> areaHa = const Value.absent(),
          Value<String?> zona = const Value.absent(),
          bool? activo,
          DateTime? sincronizadoAt,
          Value<String?> geometriaWkt = const Value.absent(),
          Value<double?> latitudCentro = const Value.absent(),
          Value<double?> longitudCentro = const Value.absent(),
          Value<String?> nombreCultivo = const Value.absent(),
          Value<String?> colorCultivo = const Value.absent()}) =>
      LotesLocalData(
        idErp: idErp ?? this.idErp,
        loteCodigo: loteCodigo ?? this.loteCodigo,
        loteNombre: loteNombre ?? this.loteNombre,
        fincaIdErp: fincaIdErp ?? this.fincaIdErp,
        fincaNombre: fincaNombre ?? this.fincaNombre,
        sublote: sublote.present ? sublote.value : this.sublote,
        areaHa: areaHa.present ? areaHa.value : this.areaHa,
        zona: zona.present ? zona.value : this.zona,
        activo: activo ?? this.activo,
        sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
        geometriaWkt:
            geometriaWkt.present ? geometriaWkt.value : this.geometriaWkt,
        latitudCentro:
            latitudCentro.present ? latitudCentro.value : this.latitudCentro,
        longitudCentro:
            longitudCentro.present ? longitudCentro.value : this.longitudCentro,
        nombreCultivo:
            nombreCultivo.present ? nombreCultivo.value : this.nombreCultivo,
        colorCultivo:
            colorCultivo.present ? colorCultivo.value : this.colorCultivo,
      );
  LotesLocalData copyWithCompanion(LotesLocalCompanion data) {
    return LotesLocalData(
      idErp: data.idErp.present ? data.idErp.value : this.idErp,
      loteCodigo:
          data.loteCodigo.present ? data.loteCodigo.value : this.loteCodigo,
      loteNombre:
          data.loteNombre.present ? data.loteNombre.value : this.loteNombre,
      fincaIdErp:
          data.fincaIdErp.present ? data.fincaIdErp.value : this.fincaIdErp,
      fincaNombre:
          data.fincaNombre.present ? data.fincaNombre.value : this.fincaNombre,
      sublote: data.sublote.present ? data.sublote.value : this.sublote,
      areaHa: data.areaHa.present ? data.areaHa.value : this.areaHa,
      zona: data.zona.present ? data.zona.value : this.zona,
      activo: data.activo.present ? data.activo.value : this.activo,
      sincronizadoAt: data.sincronizadoAt.present
          ? data.sincronizadoAt.value
          : this.sincronizadoAt,
      geometriaWkt: data.geometriaWkt.present
          ? data.geometriaWkt.value
          : this.geometriaWkt,
      latitudCentro: data.latitudCentro.present
          ? data.latitudCentro.value
          : this.latitudCentro,
      longitudCentro: data.longitudCentro.present
          ? data.longitudCentro.value
          : this.longitudCentro,
      nombreCultivo: data.nombreCultivo.present
          ? data.nombreCultivo.value
          : this.nombreCultivo,
      colorCultivo: data.colorCultivo.present
          ? data.colorCultivo.value
          : this.colorCultivo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LotesLocalData(')
          ..write('idErp: $idErp, ')
          ..write('loteCodigo: $loteCodigo, ')
          ..write('loteNombre: $loteNombre, ')
          ..write('fincaIdErp: $fincaIdErp, ')
          ..write('fincaNombre: $fincaNombre, ')
          ..write('sublote: $sublote, ')
          ..write('areaHa: $areaHa, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt, ')
          ..write('geometriaWkt: $geometriaWkt, ')
          ..write('latitudCentro: $latitudCentro, ')
          ..write('longitudCentro: $longitudCentro, ')
          ..write('nombreCultivo: $nombreCultivo, ')
          ..write('colorCultivo: $colorCultivo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      idErp,
      loteCodigo,
      loteNombre,
      fincaIdErp,
      fincaNombre,
      sublote,
      areaHa,
      zona,
      activo,
      sincronizadoAt,
      geometriaWkt,
      latitudCentro,
      longitudCentro,
      nombreCultivo,
      colorCultivo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LotesLocalData &&
          other.idErp == this.idErp &&
          other.loteCodigo == this.loteCodigo &&
          other.loteNombre == this.loteNombre &&
          other.fincaIdErp == this.fincaIdErp &&
          other.fincaNombre == this.fincaNombre &&
          other.sublote == this.sublote &&
          other.areaHa == this.areaHa &&
          other.zona == this.zona &&
          other.activo == this.activo &&
          other.sincronizadoAt == this.sincronizadoAt &&
          other.geometriaWkt == this.geometriaWkt &&
          other.latitudCentro == this.latitudCentro &&
          other.longitudCentro == this.longitudCentro &&
          other.nombreCultivo == this.nombreCultivo &&
          other.colorCultivo == this.colorCultivo);
}

class LotesLocalCompanion extends UpdateCompanion<LotesLocalData> {
  final Value<int> idErp;
  final Value<String> loteCodigo;
  final Value<String> loteNombre;
  final Value<int> fincaIdErp;
  final Value<String> fincaNombre;
  final Value<String?> sublote;
  final Value<double?> areaHa;
  final Value<String?> zona;
  final Value<bool> activo;
  final Value<DateTime> sincronizadoAt;
  final Value<String?> geometriaWkt;
  final Value<double?> latitudCentro;
  final Value<double?> longitudCentro;
  final Value<String?> nombreCultivo;
  final Value<String?> colorCultivo;
  const LotesLocalCompanion({
    this.idErp = const Value.absent(),
    this.loteCodigo = const Value.absent(),
    this.loteNombre = const Value.absent(),
    this.fincaIdErp = const Value.absent(),
    this.fincaNombre = const Value.absent(),
    this.sublote = const Value.absent(),
    this.areaHa = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
    this.geometriaWkt = const Value.absent(),
    this.latitudCentro = const Value.absent(),
    this.longitudCentro = const Value.absent(),
    this.nombreCultivo = const Value.absent(),
    this.colorCultivo = const Value.absent(),
  });
  LotesLocalCompanion.insert({
    this.idErp = const Value.absent(),
    required String loteCodigo,
    required String loteNombre,
    required int fincaIdErp,
    required String fincaNombre,
    this.sublote = const Value.absent(),
    this.areaHa = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
    this.geometriaWkt = const Value.absent(),
    this.latitudCentro = const Value.absent(),
    this.longitudCentro = const Value.absent(),
    this.nombreCultivo = const Value.absent(),
    this.colorCultivo = const Value.absent(),
  })  : loteCodigo = Value(loteCodigo),
        loteNombre = Value(loteNombre),
        fincaIdErp = Value(fincaIdErp),
        fincaNombre = Value(fincaNombre);
  static Insertable<LotesLocalData> custom({
    Expression<int>? idErp,
    Expression<String>? loteCodigo,
    Expression<String>? loteNombre,
    Expression<int>? fincaIdErp,
    Expression<String>? fincaNombre,
    Expression<String>? sublote,
    Expression<double>? areaHa,
    Expression<String>? zona,
    Expression<bool>? activo,
    Expression<DateTime>? sincronizadoAt,
    Expression<String>? geometriaWkt,
    Expression<double>? latitudCentro,
    Expression<double>? longitudCentro,
    Expression<String>? nombreCultivo,
    Expression<String>? colorCultivo,
  }) {
    return RawValuesInsertable({
      if (idErp != null) 'id_erp': idErp,
      if (loteCodigo != null) 'lote_codigo': loteCodigo,
      if (loteNombre != null) 'lote_nombre': loteNombre,
      if (fincaIdErp != null) 'finca_id_erp': fincaIdErp,
      if (fincaNombre != null) 'finca_nombre': fincaNombre,
      if (sublote != null) 'sublote': sublote,
      if (areaHa != null) 'area_ha': areaHa,
      if (zona != null) 'zona': zona,
      if (activo != null) 'activo': activo,
      if (sincronizadoAt != null) 'sincronizado_at': sincronizadoAt,
      if (geometriaWkt != null) 'geometria_wkt': geometriaWkt,
      if (latitudCentro != null) 'latitud_centro': latitudCentro,
      if (longitudCentro != null) 'longitud_centro': longitudCentro,
      if (nombreCultivo != null) 'nombre_cultivo': nombreCultivo,
      if (colorCultivo != null) 'color_cultivo': colorCultivo,
    });
  }

  LotesLocalCompanion copyWith(
      {Value<int>? idErp,
      Value<String>? loteCodigo,
      Value<String>? loteNombre,
      Value<int>? fincaIdErp,
      Value<String>? fincaNombre,
      Value<String?>? sublote,
      Value<double?>? areaHa,
      Value<String?>? zona,
      Value<bool>? activo,
      Value<DateTime>? sincronizadoAt,
      Value<String?>? geometriaWkt,
      Value<double?>? latitudCentro,
      Value<double?>? longitudCentro,
      Value<String?>? nombreCultivo,
      Value<String?>? colorCultivo}) {
    return LotesLocalCompanion(
      idErp: idErp ?? this.idErp,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      loteNombre: loteNombre ?? this.loteNombre,
      fincaIdErp: fincaIdErp ?? this.fincaIdErp,
      fincaNombre: fincaNombre ?? this.fincaNombre,
      sublote: sublote ?? this.sublote,
      areaHa: areaHa ?? this.areaHa,
      zona: zona ?? this.zona,
      activo: activo ?? this.activo,
      sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
      geometriaWkt: geometriaWkt ?? this.geometriaWkt,
      latitudCentro: latitudCentro ?? this.latitudCentro,
      longitudCentro: longitudCentro ?? this.longitudCentro,
      nombreCultivo: nombreCultivo ?? this.nombreCultivo,
      colorCultivo: colorCultivo ?? this.colorCultivo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idErp.present) {
      map['id_erp'] = Variable<int>(idErp.value);
    }
    if (loteCodigo.present) {
      map['lote_codigo'] = Variable<String>(loteCodigo.value);
    }
    if (loteNombre.present) {
      map['lote_nombre'] = Variable<String>(loteNombre.value);
    }
    if (fincaIdErp.present) {
      map['finca_id_erp'] = Variable<int>(fincaIdErp.value);
    }
    if (fincaNombre.present) {
      map['finca_nombre'] = Variable<String>(fincaNombre.value);
    }
    if (sublote.present) {
      map['sublote'] = Variable<String>(sublote.value);
    }
    if (areaHa.present) {
      map['area_ha'] = Variable<double>(areaHa.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (sincronizadoAt.present) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt.value);
    }
    if (geometriaWkt.present) {
      map['geometria_wkt'] = Variable<String>(geometriaWkt.value);
    }
    if (latitudCentro.present) {
      map['latitud_centro'] = Variable<double>(latitudCentro.value);
    }
    if (longitudCentro.present) {
      map['longitud_centro'] = Variable<double>(longitudCentro.value);
    }
    if (nombreCultivo.present) {
      map['nombre_cultivo'] = Variable<String>(nombreCultivo.value);
    }
    if (colorCultivo.present) {
      map['color_cultivo'] = Variable<String>(colorCultivo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LotesLocalCompanion(')
          ..write('idErp: $idErp, ')
          ..write('loteCodigo: $loteCodigo, ')
          ..write('loteNombre: $loteNombre, ')
          ..write('fincaIdErp: $fincaIdErp, ')
          ..write('fincaNombre: $fincaNombre, ')
          ..write('sublote: $sublote, ')
          ..write('areaHa: $areaHa, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo, ')
          ..write('sincronizadoAt: $sincronizadoAt, ')
          ..write('geometriaWkt: $geometriaWkt, ')
          ..write('latitudCentro: $latitudCentro, ')
          ..write('longitudCentro: $longitudCentro, ')
          ..write('nombreCultivo: $nombreCultivo, ')
          ..write('colorCultivo: $colorCultivo')
          ..write(')'))
        .toString();
  }
}

class $SectoresLocalTable extends SectoresLocal
    with TableInfo<$SectoresLocalTable, SectoresLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectoresLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
      'codigo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _areaHaMeta = const VerificationMeta('areaHa');
  @override
  late final GeneratedColumn<double> areaHa = GeneratedColumn<double>(
      'area_ha', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
      'zona', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, nombre, codigo, areaHa, zona, activo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sectores_local';
  @override
  VerificationContext validateIntegrity(Insertable<SectoresLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(_codigoMeta,
          codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta));
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('area_ha')) {
      context.handle(_areaHaMeta,
          areaHa.isAcceptableOrUnknown(data['area_ha']!, _areaHaMeta));
    }
    if (data.containsKey('zona')) {
      context.handle(
          _zonaMeta, zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SectoresLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectoresLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
      codigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo'])!,
      areaHa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}area_ha']),
      zona: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}zona']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
    );
  }

  @override
  $SectoresLocalTable createAlias(String alias) {
    return $SectoresLocalTable(attachedDatabase, alias);
  }
}

class SectoresLocalData extends DataClass
    implements Insertable<SectoresLocalData> {
  final int id;
  final String nombre;
  final String codigo;
  final double? areaHa;
  final String? zona;
  final bool activo;
  const SectoresLocalData(
      {required this.id,
      required this.nombre,
      required this.codigo,
      this.areaHa,
      this.zona,
      required this.activo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['codigo'] = Variable<String>(codigo);
    if (!nullToAbsent || areaHa != null) {
      map['area_ha'] = Variable<double>(areaHa);
    }
    if (!nullToAbsent || zona != null) {
      map['zona'] = Variable<String>(zona);
    }
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  SectoresLocalCompanion toCompanion(bool nullToAbsent) {
    return SectoresLocalCompanion(
      id: Value(id),
      nombre: Value(nombre),
      codigo: Value(codigo),
      areaHa:
          areaHa == null && nullToAbsent ? const Value.absent() : Value(areaHa),
      zona: zona == null && nullToAbsent ? const Value.absent() : Value(zona),
      activo: Value(activo),
    );
  }

  factory SectoresLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectoresLocalData(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      codigo: serializer.fromJson<String>(json['codigo']),
      areaHa: serializer.fromJson<double?>(json['areaHa']),
      zona: serializer.fromJson<String?>(json['zona']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'codigo': serializer.toJson<String>(codigo),
      'areaHa': serializer.toJson<double?>(areaHa),
      'zona': serializer.toJson<String?>(zona),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  SectoresLocalData copyWith(
          {int? id,
          String? nombre,
          String? codigo,
          Value<double?> areaHa = const Value.absent(),
          Value<String?> zona = const Value.absent(),
          bool? activo}) =>
      SectoresLocalData(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        codigo: codigo ?? this.codigo,
        areaHa: areaHa.present ? areaHa.value : this.areaHa,
        zona: zona.present ? zona.value : this.zona,
        activo: activo ?? this.activo,
      );
  SectoresLocalData copyWithCompanion(SectoresLocalCompanion data) {
    return SectoresLocalData(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      areaHa: data.areaHa.present ? data.areaHa.value : this.areaHa,
      zona: data.zona.present ? data.zona.value : this.zona,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectoresLocalData(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('codigo: $codigo, ')
          ..write('areaHa: $areaHa, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, codigo, areaHa, zona, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectoresLocalData &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.codigo == this.codigo &&
          other.areaHa == this.areaHa &&
          other.zona == this.zona &&
          other.activo == this.activo);
}

class SectoresLocalCompanion extends UpdateCompanion<SectoresLocalData> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<String> codigo;
  final Value<double?> areaHa;
  final Value<String?> zona;
  final Value<bool> activo;
  const SectoresLocalCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.codigo = const Value.absent(),
    this.areaHa = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
  });
  SectoresLocalCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required String codigo,
    this.areaHa = const Value.absent(),
    this.zona = const Value.absent(),
    this.activo = const Value.absent(),
  })  : nombre = Value(nombre),
        codigo = Value(codigo);
  static Insertable<SectoresLocalData> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<String>? codigo,
    Expression<double>? areaHa,
    Expression<String>? zona,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      if (areaHa != null) 'area_ha': areaHa,
      if (zona != null) 'zona': zona,
      if (activo != null) 'activo': activo,
    });
  }

  SectoresLocalCompanion copyWith(
      {Value<int>? id,
      Value<String>? nombre,
      Value<String>? codigo,
      Value<double?>? areaHa,
      Value<String?>? zona,
      Value<bool>? activo}) {
    return SectoresLocalCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      areaHa: areaHa ?? this.areaHa,
      zona: zona ?? this.zona,
      activo: activo ?? this.activo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (areaHa.present) {
      map['area_ha'] = Variable<double>(areaHa.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectoresLocalCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('codigo: $codigo, ')
          ..write('areaHa: $areaHa, ')
          ..write('zona: $zona, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $SubprocesosLocalTable extends SubprocesosLocal
    with TableInfo<$SubprocesosLocalTable, SubprocesosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubprocesosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _procesoIdMeta =
      const VerificationMeta('procesoId');
  @override
  late final GeneratedColumn<int> procesoId = GeneratedColumn<int>(
      'proceso_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
      'nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
      'codigo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descripcionMeta =
      const VerificationMeta('descripcion');
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
      'descripcion', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
      'activo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("activo" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, procesoId, nombre, codigo, descripcion, activo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subprocesos_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<SubprocesosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('proceso_id')) {
      context.handle(_procesoIdMeta,
          procesoId.isAcceptableOrUnknown(data['proceso_id']!, _procesoIdMeta));
    } else if (isInserting) {
      context.missing(_procesoIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(_nombreMeta,
          nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta));
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(_codigoMeta,
          codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta));
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
          _descripcionMeta,
          descripcion.isAcceptableOrUnknown(
              data['descripcion']!, _descripcionMeta));
    }
    if (data.containsKey('activo')) {
      context.handle(_activoMeta,
          activo.isAcceptableOrUnknown(data['activo']!, _activoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubprocesosLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubprocesosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      procesoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}proceso_id'])!,
      nombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre'])!,
      codigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}codigo'])!,
      descripcion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descripcion']),
      activo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}activo'])!,
    );
  }

  @override
  $SubprocesosLocalTable createAlias(String alias) {
    return $SubprocesosLocalTable(attachedDatabase, alias);
  }
}

class SubprocesosLocalData extends DataClass
    implements Insertable<SubprocesosLocalData> {
  final int id;
  final int procesoId;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final bool activo;
  const SubprocesosLocalData(
      {required this.id,
      required this.procesoId,
      required this.nombre,
      required this.codigo,
      this.descripcion,
      required this.activo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['proceso_id'] = Variable<int>(procesoId);
    map['nombre'] = Variable<String>(nombre);
    map['codigo'] = Variable<String>(codigo);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    map['activo'] = Variable<bool>(activo);
    return map;
  }

  SubprocesosLocalCompanion toCompanion(bool nullToAbsent) {
    return SubprocesosLocalCompanion(
      id: Value(id),
      procesoId: Value(procesoId),
      nombre: Value(nombre),
      codigo: Value(codigo),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      activo: Value(activo),
    );
  }

  factory SubprocesosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubprocesosLocalData(
      id: serializer.fromJson<int>(json['id']),
      procesoId: serializer.fromJson<int>(json['procesoId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      codigo: serializer.fromJson<String>(json['codigo']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      activo: serializer.fromJson<bool>(json['activo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'procesoId': serializer.toJson<int>(procesoId),
      'nombre': serializer.toJson<String>(nombre),
      'codigo': serializer.toJson<String>(codigo),
      'descripcion': serializer.toJson<String?>(descripcion),
      'activo': serializer.toJson<bool>(activo),
    };
  }

  SubprocesosLocalData copyWith(
          {int? id,
          int? procesoId,
          String? nombre,
          String? codigo,
          Value<String?> descripcion = const Value.absent(),
          bool? activo}) =>
      SubprocesosLocalData(
        id: id ?? this.id,
        procesoId: procesoId ?? this.procesoId,
        nombre: nombre ?? this.nombre,
        codigo: codigo ?? this.codigo,
        descripcion: descripcion.present ? descripcion.value : this.descripcion,
        activo: activo ?? this.activo,
      );
  SubprocesosLocalData copyWithCompanion(SubprocesosLocalCompanion data) {
    return SubprocesosLocalData(
      id: data.id.present ? data.id.value : this.id,
      procesoId: data.procesoId.present ? data.procesoId.value : this.procesoId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      descripcion:
          data.descripcion.present ? data.descripcion.value : this.descripcion,
      activo: data.activo.present ? data.activo.value : this.activo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubprocesosLocalData(')
          ..write('id: $id, ')
          ..write('procesoId: $procesoId, ')
          ..write('nombre: $nombre, ')
          ..write('codigo: $codigo, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, procesoId, nombre, codigo, descripcion, activo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubprocesosLocalData &&
          other.id == this.id &&
          other.procesoId == this.procesoId &&
          other.nombre == this.nombre &&
          other.codigo == this.codigo &&
          other.descripcion == this.descripcion &&
          other.activo == this.activo);
}

class SubprocesosLocalCompanion extends UpdateCompanion<SubprocesosLocalData> {
  final Value<int> id;
  final Value<int> procesoId;
  final Value<String> nombre;
  final Value<String> codigo;
  final Value<String?> descripcion;
  final Value<bool> activo;
  const SubprocesosLocalCompanion({
    this.id = const Value.absent(),
    this.procesoId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.codigo = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
  });
  SubprocesosLocalCompanion.insert({
    this.id = const Value.absent(),
    required int procesoId,
    required String nombre,
    required String codigo,
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
  })  : procesoId = Value(procesoId),
        nombre = Value(nombre),
        codigo = Value(codigo);
  static Insertable<SubprocesosLocalData> custom({
    Expression<int>? id,
    Expression<int>? procesoId,
    Expression<String>? nombre,
    Expression<String>? codigo,
    Expression<String>? descripcion,
    Expression<bool>? activo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (procesoId != null) 'proceso_id': procesoId,
      if (nombre != null) 'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      if (descripcion != null) 'descripcion': descripcion,
      if (activo != null) 'activo': activo,
    });
  }

  SubprocesosLocalCompanion copyWith(
      {Value<int>? id,
      Value<int>? procesoId,
      Value<String>? nombre,
      Value<String>? codigo,
      Value<String?>? descripcion,
      Value<bool>? activo}) {
    return SubprocesosLocalCompanion(
      id: id ?? this.id,
      procesoId: procesoId ?? this.procesoId,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (procesoId.present) {
      map['proceso_id'] = Variable<int>(procesoId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubprocesosLocalCompanion(')
          ..write('id: $id, ')
          ..write('procesoId: $procesoId, ')
          ..write('nombre: $nombre, ')
          ..write('codigo: $codigo, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo')
          ..write(')'))
        .toString();
  }
}

class $MenusLocalTable extends MenusLocal
    with TableInfo<$MenusLocalTable, MenusLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenusLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
      'titulo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconoMeta = const VerificationMeta('icono');
  @override
  late final GeneratedColumn<String> icono = GeneratedColumn<String>(
      'icono', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rutaMeta = const VerificationMeta('ruta');
  @override
  late final GeneratedColumn<String> ruta = GeneratedColumn<String>(
      'ruta', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
      'orden', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
      'rol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, parentId, titulo, icono, ruta, orden, rol];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menus_local';
  @override
  VerificationContext validateIntegrity(Insertable<MenusLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('titulo')) {
      context.handle(_tituloMeta,
          titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta));
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('icono')) {
      context.handle(
          _iconoMeta, icono.isAcceptableOrUnknown(data['icono']!, _iconoMeta));
    }
    if (data.containsKey('ruta')) {
      context.handle(
          _rutaMeta, ruta.isAcceptableOrUnknown(data['ruta']!, _rutaMeta));
    }
    if (data.containsKey('orden')) {
      context.handle(
          _ordenMeta, orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta));
    }
    if (data.containsKey('rol')) {
      context.handle(
          _rolMeta, rol.isAcceptableOrUnknown(data['rol']!, _rolMeta));
    } else if (isInserting) {
      context.missing(_rolMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenusLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenusLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      titulo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titulo'])!,
      icono: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icono']),
      ruta: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ruta']),
      orden: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}orden'])!,
      rol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rol'])!,
    );
  }

  @override
  $MenusLocalTable createAlias(String alias) {
    return $MenusLocalTable(attachedDatabase, alias);
  }
}

class MenusLocalData extends DataClass implements Insertable<MenusLocalData> {
  final int id;
  final int? parentId;
  final String titulo;
  final String? icono;
  final String? ruta;
  final int orden;
  final String rol;
  const MenusLocalData(
      {required this.id,
      this.parentId,
      required this.titulo,
      this.icono,
      this.ruta,
      required this.orden,
      required this.rol});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['titulo'] = Variable<String>(titulo);
    if (!nullToAbsent || icono != null) {
      map['icono'] = Variable<String>(icono);
    }
    if (!nullToAbsent || ruta != null) {
      map['ruta'] = Variable<String>(ruta);
    }
    map['orden'] = Variable<int>(orden);
    map['rol'] = Variable<String>(rol);
    return map;
  }

  MenusLocalCompanion toCompanion(bool nullToAbsent) {
    return MenusLocalCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      titulo: Value(titulo),
      icono:
          icono == null && nullToAbsent ? const Value.absent() : Value(icono),
      ruta: ruta == null && nullToAbsent ? const Value.absent() : Value(ruta),
      orden: Value(orden),
      rol: Value(rol),
    );
  }

  factory MenusLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenusLocalData(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      titulo: serializer.fromJson<String>(json['titulo']),
      icono: serializer.fromJson<String?>(json['icono']),
      ruta: serializer.fromJson<String?>(json['ruta']),
      orden: serializer.fromJson<int>(json['orden']),
      rol: serializer.fromJson<String>(json['rol']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'titulo': serializer.toJson<String>(titulo),
      'icono': serializer.toJson<String?>(icono),
      'ruta': serializer.toJson<String?>(ruta),
      'orden': serializer.toJson<int>(orden),
      'rol': serializer.toJson<String>(rol),
    };
  }

  MenusLocalData copyWith(
          {int? id,
          Value<int?> parentId = const Value.absent(),
          String? titulo,
          Value<String?> icono = const Value.absent(),
          Value<String?> ruta = const Value.absent(),
          int? orden,
          String? rol}) =>
      MenusLocalData(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        titulo: titulo ?? this.titulo,
        icono: icono.present ? icono.value : this.icono,
        ruta: ruta.present ? ruta.value : this.ruta,
        orden: orden ?? this.orden,
        rol: rol ?? this.rol,
      );
  MenusLocalData copyWithCompanion(MenusLocalCompanion data) {
    return MenusLocalData(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      icono: data.icono.present ? data.icono.value : this.icono,
      ruta: data.ruta.present ? data.ruta.value : this.ruta,
      orden: data.orden.present ? data.orden.value : this.orden,
      rol: data.rol.present ? data.rol.value : this.rol,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenusLocalData(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('titulo: $titulo, ')
          ..write('icono: $icono, ')
          ..write('ruta: $ruta, ')
          ..write('orden: $orden, ')
          ..write('rol: $rol')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentId, titulo, icono, ruta, orden, rol);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenusLocalData &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.titulo == this.titulo &&
          other.icono == this.icono &&
          other.ruta == this.ruta &&
          other.orden == this.orden &&
          other.rol == this.rol);
}

class MenusLocalCompanion extends UpdateCompanion<MenusLocalData> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<String> titulo;
  final Value<String?> icono;
  final Value<String?> ruta;
  final Value<int> orden;
  final Value<String> rol;
  const MenusLocalCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.titulo = const Value.absent(),
    this.icono = const Value.absent(),
    this.ruta = const Value.absent(),
    this.orden = const Value.absent(),
    this.rol = const Value.absent(),
  });
  MenusLocalCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    required String titulo,
    this.icono = const Value.absent(),
    this.ruta = const Value.absent(),
    this.orden = const Value.absent(),
    required String rol,
  })  : titulo = Value(titulo),
        rol = Value(rol);
  static Insertable<MenusLocalData> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<String>? titulo,
    Expression<String>? icono,
    Expression<String>? ruta,
    Expression<int>? orden,
    Expression<String>? rol,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (titulo != null) 'titulo': titulo,
      if (icono != null) 'icono': icono,
      if (ruta != null) 'ruta': ruta,
      if (orden != null) 'orden': orden,
      if (rol != null) 'rol': rol,
    });
  }

  MenusLocalCompanion copyWith(
      {Value<int>? id,
      Value<int?>? parentId,
      Value<String>? titulo,
      Value<String?>? icono,
      Value<String?>? ruta,
      Value<int>? orden,
      Value<String>? rol}) {
    return MenusLocalCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      titulo: titulo ?? this.titulo,
      icono: icono ?? this.icono,
      ruta: ruta ?? this.ruta,
      orden: orden ?? this.orden,
      rol: rol ?? this.rol,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (icono.present) {
      map['icono'] = Variable<String>(icono.value);
    }
    if (ruta.present) {
      map['ruta'] = Variable<String>(ruta.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenusLocalCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('titulo: $titulo, ')
          ..write('icono: $icono, ')
          ..write('ruta: $ruta, ')
          ..write('orden: $orden, ')
          ..write('rol: $rol')
          ..write(')'))
        .toString();
  }
}

class $RegistrosDiariosLocalTable extends RegistrosDiariosLocal
    with TableInfo<$RegistrosDiariosLocalTable, RegistrosDiariosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegistrosDiariosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numeroRegistroMeta =
      const VerificationMeta('numeroRegistro');
  @override
  late final GeneratedColumn<String> numeroRegistro = GeneratedColumn<String>(
      'numero_registro', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
      'fecha', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _turnoMeta = const VerificationMeta('turno');
  @override
  late final GeneratedColumn<String> turno = GeneratedColumn<String>(
      'turno', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('dia'));
  static const VerificationMeta _procesoIdMeta =
      const VerificationMeta('procesoId');
  @override
  late final GeneratedColumn<int> procesoId = GeneratedColumn<int>(
      'proceso_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _procesoNombreMeta =
      const VerificationMeta('procesoNombre');
  @override
  late final GeneratedColumn<String> procesoNombre = GeneratedColumn<String>(
      'proceso_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _procesoCodigoMeta =
      const VerificationMeta('procesoCodigo');
  @override
  late final GeneratedColumn<String> procesoCodigo = GeneratedColumn<String>(
      'proceso_codigo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _cultivoIdErpMeta =
      const VerificationMeta('cultivoIdErp');
  @override
  late final GeneratedColumn<int> cultivoIdErp = GeneratedColumn<int>(
      'cultivo_id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cultivoNombreEspecieMeta =
      const VerificationMeta('cultivoNombreEspecie');
  @override
  late final GeneratedColumn<String> cultivoNombreEspecie =
      GeneratedColumn<String>('cultivo_nombre_especie', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _cultivoCodigoEspecieMeta =
      const VerificationMeta('cultivoCodigoEspecie');
  @override
  late final GeneratedColumn<String> cultivoCodigoEspecie =
      GeneratedColumn<String>('cultivo_codigo_especie', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _operadorIdErpMeta =
      const VerificationMeta('operadorIdErp');
  @override
  late final GeneratedColumn<int> operadorIdErp = GeneratedColumn<int>(
      'operador_id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _operadorCodigoMeta =
      const VerificationMeta('operadorCodigo');
  @override
  late final GeneratedColumn<String> operadorCodigo = GeneratedColumn<String>(
      'operador_codigo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _operadorNombreMeta =
      const VerificationMeta('operadorNombre');
  @override
  late final GeneratedColumn<String> operadorNombre = GeneratedColumn<String>(
      'operador_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _supervisorIdErpMeta =
      const VerificationMeta('supervisorIdErp');
  @override
  late final GeneratedColumn<int> supervisorIdErp = GeneratedColumn<int>(
      'supervisor_id_erp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _supervisorCodigoMeta =
      const VerificationMeta('supervisorCodigo');
  @override
  late final GeneratedColumn<String> supervisorCodigo = GeneratedColumn<String>(
      'supervisor_codigo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supervisorNombreMeta =
      const VerificationMeta('supervisorNombre');
  @override
  late final GeneratedColumn<String> supervisorNombre = GeneratedColumn<String>(
      'supervisor_nombre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tractorIdErpMeta =
      const VerificationMeta('tractorIdErp');
  @override
  late final GeneratedColumn<int> tractorIdErp = GeneratedColumn<int>(
      'tractor_id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tractorCodigoMeta =
      const VerificationMeta('tractorCodigo');
  @override
  late final GeneratedColumn<String> tractorCodigo = GeneratedColumn<String>(
      'tractor_codigo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tractorDescripcionMeta =
      const VerificationMeta('tractorDescripcion');
  @override
  late final GeneratedColumn<String> tractorDescripcion =
      GeneratedColumn<String>('tractor_descripcion', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _implementoIdErpMeta =
      const VerificationMeta('implementoIdErp');
  @override
  late final GeneratedColumn<int> implementoIdErp = GeneratedColumn<int>(
      'implemento_id_erp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _implementoCodigoMeta =
      const VerificationMeta('implementoCodigo');
  @override
  late final GeneratedColumn<String> implementoCodigo = GeneratedColumn<String>(
      'implemento_codigo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _implementoDescripcionMeta =
      const VerificationMeta('implementoDescripcion');
  @override
  late final GeneratedColumn<String> implementoDescripcion =
      GeneratedColumn<String>('implemento_descripcion', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cajaCambiosIdMeta =
      const VerificationMeta('cajaCambiosId');
  @override
  late final GeneratedColumn<int> cajaCambiosId = GeneratedColumn<int>(
      'caja_cambios_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cajaCambiosNombreMeta =
      const VerificationMeta('cajaCambiosNombre');
  @override
  late final GeneratedColumn<String> cajaCambiosNombre =
      GeneratedColumn<String>('caja_cambios_nombre', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subprocesoIdMeta =
      const VerificationMeta('subprocesoId');
  @override
  late final GeneratedColumn<int> subprocesoId = GeneratedColumn<int>(
      'subproceso_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _subprocesoNombreMeta =
      const VerificationMeta('subprocesoNombre');
  @override
  late final GeneratedColumn<String> subprocesoNombre = GeneratedColumn<String>(
      'subproceso_nombre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jornadaInicioAtMeta =
      const VerificationMeta('jornadaInicioAt');
  @override
  late final GeneratedColumn<DateTime> jornadaInicioAt =
      GeneratedColumn<DateTime>('jornada_inicio_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _jornadaFinAtMeta =
      const VerificationMeta('jornadaFinAt');
  @override
  late final GeneratedColumn<DateTime> jornadaFinAt = GeneratedColumn<DateTime>(
      'jornada_fin_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _tipoRegistroMeta =
      const VerificationMeta('tipoRegistro');
  @override
  late final GeneratedColumn<String> tipoRegistro = GeneratedColumn<String>(
      'tipo_registro', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('tractor'));
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
      'estado', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('borrador'));
  static const VerificationMeta _observacionesMaqMeta =
      const VerificationMeta('observacionesMaq');
  @override
  late final GeneratedColumn<String> observacionesMaq = GeneratedColumn<String>(
      'observaciones_maq', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motivoRechazoMeta =
      const VerificationMeta('motivoRechazo');
  @override
  late final GeneratedColumn<String> motivoRechazo = GeneratedColumn<String>(
      'motivo_rechazo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _firmaOperadorMeta =
      const VerificationMeta('firmaOperador');
  @override
  late final GeneratedColumn<String> firmaOperador = GeneratedColumn<String>(
      'firma_operador', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dispositivoIdMeta =
      const VerificationMeta('dispositivoId');
  @override
  late final GeneratedColumn<String> dispositivoId = GeneratedColumn<String>(
      'dispositivo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sincronizadoMeta =
      const VerificationMeta('sincronizado');
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
      'sincronizado', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sincronizado" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sincronizadoAtMeta =
      const VerificationMeta('sincronizadoAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoAt =
      GeneratedColumn<DateTime>('sincronizado_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        numeroRegistro,
        fecha,
        turno,
        procesoId,
        procesoNombre,
        procesoCodigo,
        cultivoIdErp,
        cultivoNombreEspecie,
        cultivoCodigoEspecie,
        operadorIdErp,
        operadorCodigo,
        operadorNombre,
        supervisorIdErp,
        supervisorCodigo,
        supervisorNombre,
        tractorIdErp,
        tractorCodigo,
        tractorDescripcion,
        implementoIdErp,
        implementoCodigo,
        implementoDescripcion,
        cajaCambiosId,
        cajaCambiosNombre,
        subprocesoId,
        subprocesoNombre,
        jornadaInicioAt,
        jornadaFinAt,
        tipoRegistro,
        estado,
        observacionesMaq,
        motivoRechazo,
        firmaOperador,
        dispositivoId,
        sincronizado,
        sincronizadoAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registros_diarios_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<RegistrosDiariosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('numero_registro')) {
      context.handle(
          _numeroRegistroMeta,
          numeroRegistro.isAcceptableOrUnknown(
              data['numero_registro']!, _numeroRegistroMeta));
    }
    if (data.containsKey('fecha')) {
      context.handle(
          _fechaMeta, fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta));
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('turno')) {
      context.handle(
          _turnoMeta, turno.isAcceptableOrUnknown(data['turno']!, _turnoMeta));
    }
    if (data.containsKey('proceso_id')) {
      context.handle(_procesoIdMeta,
          procesoId.isAcceptableOrUnknown(data['proceso_id']!, _procesoIdMeta));
    } else if (isInserting) {
      context.missing(_procesoIdMeta);
    }
    if (data.containsKey('proceso_nombre')) {
      context.handle(
          _procesoNombreMeta,
          procesoNombre.isAcceptableOrUnknown(
              data['proceso_nombre']!, _procesoNombreMeta));
    }
    if (data.containsKey('proceso_codigo')) {
      context.handle(
          _procesoCodigoMeta,
          procesoCodigo.isAcceptableOrUnknown(
              data['proceso_codigo']!, _procesoCodigoMeta));
    }
    if (data.containsKey('cultivo_id_erp')) {
      context.handle(
          _cultivoIdErpMeta,
          cultivoIdErp.isAcceptableOrUnknown(
              data['cultivo_id_erp']!, _cultivoIdErpMeta));
    } else if (isInserting) {
      context.missing(_cultivoIdErpMeta);
    }
    if (data.containsKey('cultivo_nombre_especie')) {
      context.handle(
          _cultivoNombreEspecieMeta,
          cultivoNombreEspecie.isAcceptableOrUnknown(
              data['cultivo_nombre_especie']!, _cultivoNombreEspecieMeta));
    }
    if (data.containsKey('cultivo_codigo_especie')) {
      context.handle(
          _cultivoCodigoEspecieMeta,
          cultivoCodigoEspecie.isAcceptableOrUnknown(
              data['cultivo_codigo_especie']!, _cultivoCodigoEspecieMeta));
    }
    if (data.containsKey('operador_id_erp')) {
      context.handle(
          _operadorIdErpMeta,
          operadorIdErp.isAcceptableOrUnknown(
              data['operador_id_erp']!, _operadorIdErpMeta));
    } else if (isInserting) {
      context.missing(_operadorIdErpMeta);
    }
    if (data.containsKey('operador_codigo')) {
      context.handle(
          _operadorCodigoMeta,
          operadorCodigo.isAcceptableOrUnknown(
              data['operador_codigo']!, _operadorCodigoMeta));
    }
    if (data.containsKey('operador_nombre')) {
      context.handle(
          _operadorNombreMeta,
          operadorNombre.isAcceptableOrUnknown(
              data['operador_nombre']!, _operadorNombreMeta));
    }
    if (data.containsKey('supervisor_id_erp')) {
      context.handle(
          _supervisorIdErpMeta,
          supervisorIdErp.isAcceptableOrUnknown(
              data['supervisor_id_erp']!, _supervisorIdErpMeta));
    }
    if (data.containsKey('supervisor_codigo')) {
      context.handle(
          _supervisorCodigoMeta,
          supervisorCodigo.isAcceptableOrUnknown(
              data['supervisor_codigo']!, _supervisorCodigoMeta));
    }
    if (data.containsKey('supervisor_nombre')) {
      context.handle(
          _supervisorNombreMeta,
          supervisorNombre.isAcceptableOrUnknown(
              data['supervisor_nombre']!, _supervisorNombreMeta));
    }
    if (data.containsKey('tractor_id_erp')) {
      context.handle(
          _tractorIdErpMeta,
          tractorIdErp.isAcceptableOrUnknown(
              data['tractor_id_erp']!, _tractorIdErpMeta));
    } else if (isInserting) {
      context.missing(_tractorIdErpMeta);
    }
    if (data.containsKey('tractor_codigo')) {
      context.handle(
          _tractorCodigoMeta,
          tractorCodigo.isAcceptableOrUnknown(
              data['tractor_codigo']!, _tractorCodigoMeta));
    }
    if (data.containsKey('tractor_descripcion')) {
      context.handle(
          _tractorDescripcionMeta,
          tractorDescripcion.isAcceptableOrUnknown(
              data['tractor_descripcion']!, _tractorDescripcionMeta));
    }
    if (data.containsKey('implemento_id_erp')) {
      context.handle(
          _implementoIdErpMeta,
          implementoIdErp.isAcceptableOrUnknown(
              data['implemento_id_erp']!, _implementoIdErpMeta));
    }
    if (data.containsKey('implemento_codigo')) {
      context.handle(
          _implementoCodigoMeta,
          implementoCodigo.isAcceptableOrUnknown(
              data['implemento_codigo']!, _implementoCodigoMeta));
    }
    if (data.containsKey('implemento_descripcion')) {
      context.handle(
          _implementoDescripcionMeta,
          implementoDescripcion.isAcceptableOrUnknown(
              data['implemento_descripcion']!, _implementoDescripcionMeta));
    }
    if (data.containsKey('caja_cambios_id')) {
      context.handle(
          _cajaCambiosIdMeta,
          cajaCambiosId.isAcceptableOrUnknown(
              data['caja_cambios_id']!, _cajaCambiosIdMeta));
    }
    if (data.containsKey('caja_cambios_nombre')) {
      context.handle(
          _cajaCambiosNombreMeta,
          cajaCambiosNombre.isAcceptableOrUnknown(
              data['caja_cambios_nombre']!, _cajaCambiosNombreMeta));
    }
    if (data.containsKey('subproceso_id')) {
      context.handle(
          _subprocesoIdMeta,
          subprocesoId.isAcceptableOrUnknown(
              data['subproceso_id']!, _subprocesoIdMeta));
    }
    if (data.containsKey('subproceso_nombre')) {
      context.handle(
          _subprocesoNombreMeta,
          subprocesoNombre.isAcceptableOrUnknown(
              data['subproceso_nombre']!, _subprocesoNombreMeta));
    }
    if (data.containsKey('jornada_inicio_at')) {
      context.handle(
          _jornadaInicioAtMeta,
          jornadaInicioAt.isAcceptableOrUnknown(
              data['jornada_inicio_at']!, _jornadaInicioAtMeta));
    }
    if (data.containsKey('jornada_fin_at')) {
      context.handle(
          _jornadaFinAtMeta,
          jornadaFinAt.isAcceptableOrUnknown(
              data['jornada_fin_at']!, _jornadaFinAtMeta));
    }
    if (data.containsKey('tipo_registro')) {
      context.handle(
          _tipoRegistroMeta,
          tipoRegistro.isAcceptableOrUnknown(
              data['tipo_registro']!, _tipoRegistroMeta));
    }
    if (data.containsKey('estado')) {
      context.handle(_estadoMeta,
          estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta));
    }
    if (data.containsKey('observaciones_maq')) {
      context.handle(
          _observacionesMaqMeta,
          observacionesMaq.isAcceptableOrUnknown(
              data['observaciones_maq']!, _observacionesMaqMeta));
    }
    if (data.containsKey('motivo_rechazo')) {
      context.handle(
          _motivoRechazoMeta,
          motivoRechazo.isAcceptableOrUnknown(
              data['motivo_rechazo']!, _motivoRechazoMeta));
    }
    if (data.containsKey('firma_operador')) {
      context.handle(
          _firmaOperadorMeta,
          firmaOperador.isAcceptableOrUnknown(
              data['firma_operador']!, _firmaOperadorMeta));
    }
    if (data.containsKey('dispositivo_id')) {
      context.handle(
          _dispositivoIdMeta,
          dispositivoId.isAcceptableOrUnknown(
              data['dispositivo_id']!, _dispositivoIdMeta));
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
          _sincronizadoMeta,
          sincronizado.isAcceptableOrUnknown(
              data['sincronizado']!, _sincronizadoMeta));
    }
    if (data.containsKey('sincronizado_at')) {
      context.handle(
          _sincronizadoAtMeta,
          sincronizadoAt.isAcceptableOrUnknown(
              data['sincronizado_at']!, _sincronizadoAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RegistrosDiariosLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegistrosDiariosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      numeroRegistro: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}numero_registro'])!,
      fecha: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fecha'])!,
      turno: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}turno'])!,
      procesoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}proceso_id'])!,
      procesoNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}proceso_nombre'])!,
      procesoCodigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}proceso_codigo'])!,
      cultivoIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cultivo_id_erp'])!,
      cultivoNombreEspecie: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cultivo_nombre_especie'])!,
      cultivoCodigoEspecie: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cultivo_codigo_especie'])!,
      operadorIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}operador_id_erp'])!,
      operadorCodigo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}operador_codigo'])!,
      operadorNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}operador_nombre'])!,
      supervisorIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}supervisor_id_erp']),
      supervisorCodigo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}supervisor_codigo']),
      supervisorNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}supervisor_nombre']),
      tractorIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tractor_id_erp'])!,
      tractorCodigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tractor_codigo'])!,
      tractorDescripcion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tractor_descripcion'])!,
      implementoIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}implemento_id_erp']),
      implementoCodigo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}implemento_codigo']),
      implementoDescripcion: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}implemento_descripcion']),
      cajaCambiosId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}caja_cambios_id']),
      cajaCambiosNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}caja_cambios_nombre']),
      subprocesoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subproceso_id']),
      subprocesoNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}subproceso_nombre']),
      jornadaInicioAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}jornada_inicio_at']),
      jornadaFinAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}jornada_fin_at']),
      tipoRegistro: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo_registro'])!,
      estado: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}estado'])!,
      observacionesMaq: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}observaciones_maq']),
      motivoRechazo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motivo_rechazo']),
      firmaOperador: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}firma_operador']),
      dispositivoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dispositivo_id']),
      sincronizado: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sincronizado'])!,
      sincronizadoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}sincronizado_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RegistrosDiariosLocalTable createAlias(String alias) {
    return $RegistrosDiariosLocalTable(attachedDatabase, alias);
  }
}

class RegistrosDiariosLocalData extends DataClass
    implements Insertable<RegistrosDiariosLocalData> {
  /// UUID local generado en el dispositivo.
  final String id;
  final String numeroRegistro;
  final DateTime fecha;
  final String turno;
  final int procesoId;
  final String procesoNombre;
  final String procesoCodigo;
  final int cultivoIdErp;
  final String cultivoNombreEspecie;
  final String cultivoCodigoEspecie;
  final int operadorIdErp;
  final String operadorCodigo;
  final String operadorNombre;
  final int? supervisorIdErp;
  final String? supervisorCodigo;
  final String? supervisorNombre;
  final int tractorIdErp;
  final String tractorCodigo;
  final String tractorDescripcion;
  final int? implementoIdErp;
  final String? implementoCodigo;
  final String? implementoDescripcion;
  final int? cajaCambiosId;
  final String? cajaCambiosNombre;
  final int? subprocesoId;
  final String? subprocesoNombre;
  final DateTime? jornadaInicioAt;
  final DateTime? jornadaFinAt;
  final String tipoRegistro;
  final String estado;
  final String? observacionesMaq;
  final String? motivoRechazo;
  final String? firmaOperador;
  final String? dispositivoId;
  final bool sincronizado;
  final DateTime? sincronizadoAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RegistrosDiariosLocalData(
      {required this.id,
      required this.numeroRegistro,
      required this.fecha,
      required this.turno,
      required this.procesoId,
      required this.procesoNombre,
      required this.procesoCodigo,
      required this.cultivoIdErp,
      required this.cultivoNombreEspecie,
      required this.cultivoCodigoEspecie,
      required this.operadorIdErp,
      required this.operadorCodigo,
      required this.operadorNombre,
      this.supervisorIdErp,
      this.supervisorCodigo,
      this.supervisorNombre,
      required this.tractorIdErp,
      required this.tractorCodigo,
      required this.tractorDescripcion,
      this.implementoIdErp,
      this.implementoCodigo,
      this.implementoDescripcion,
      this.cajaCambiosId,
      this.cajaCambiosNombre,
      this.subprocesoId,
      this.subprocesoNombre,
      this.jornadaInicioAt,
      this.jornadaFinAt,
      required this.tipoRegistro,
      required this.estado,
      this.observacionesMaq,
      this.motivoRechazo,
      this.firmaOperador,
      this.dispositivoId,
      required this.sincronizado,
      this.sincronizadoAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['numero_registro'] = Variable<String>(numeroRegistro);
    map['fecha'] = Variable<DateTime>(fecha);
    map['turno'] = Variable<String>(turno);
    map['proceso_id'] = Variable<int>(procesoId);
    map['proceso_nombre'] = Variable<String>(procesoNombre);
    map['proceso_codigo'] = Variable<String>(procesoCodigo);
    map['cultivo_id_erp'] = Variable<int>(cultivoIdErp);
    map['cultivo_nombre_especie'] = Variable<String>(cultivoNombreEspecie);
    map['cultivo_codigo_especie'] = Variable<String>(cultivoCodigoEspecie);
    map['operador_id_erp'] = Variable<int>(operadorIdErp);
    map['operador_codigo'] = Variable<String>(operadorCodigo);
    map['operador_nombre'] = Variable<String>(operadorNombre);
    if (!nullToAbsent || supervisorIdErp != null) {
      map['supervisor_id_erp'] = Variable<int>(supervisorIdErp);
    }
    if (!nullToAbsent || supervisorCodigo != null) {
      map['supervisor_codigo'] = Variable<String>(supervisorCodigo);
    }
    if (!nullToAbsent || supervisorNombre != null) {
      map['supervisor_nombre'] = Variable<String>(supervisorNombre);
    }
    map['tractor_id_erp'] = Variable<int>(tractorIdErp);
    map['tractor_codigo'] = Variable<String>(tractorCodigo);
    map['tractor_descripcion'] = Variable<String>(tractorDescripcion);
    if (!nullToAbsent || implementoIdErp != null) {
      map['implemento_id_erp'] = Variable<int>(implementoIdErp);
    }
    if (!nullToAbsent || implementoCodigo != null) {
      map['implemento_codigo'] = Variable<String>(implementoCodigo);
    }
    if (!nullToAbsent || implementoDescripcion != null) {
      map['implemento_descripcion'] = Variable<String>(implementoDescripcion);
    }
    if (!nullToAbsent || cajaCambiosId != null) {
      map['caja_cambios_id'] = Variable<int>(cajaCambiosId);
    }
    if (!nullToAbsent || cajaCambiosNombre != null) {
      map['caja_cambios_nombre'] = Variable<String>(cajaCambiosNombre);
    }
    if (!nullToAbsent || subprocesoId != null) {
      map['subproceso_id'] = Variable<int>(subprocesoId);
    }
    if (!nullToAbsent || subprocesoNombre != null) {
      map['subproceso_nombre'] = Variable<String>(subprocesoNombre);
    }
    if (!nullToAbsent || jornadaInicioAt != null) {
      map['jornada_inicio_at'] = Variable<DateTime>(jornadaInicioAt);
    }
    if (!nullToAbsent || jornadaFinAt != null) {
      map['jornada_fin_at'] = Variable<DateTime>(jornadaFinAt);
    }
    map['tipo_registro'] = Variable<String>(tipoRegistro);
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || observacionesMaq != null) {
      map['observaciones_maq'] = Variable<String>(observacionesMaq);
    }
    if (!nullToAbsent || motivoRechazo != null) {
      map['motivo_rechazo'] = Variable<String>(motivoRechazo);
    }
    if (!nullToAbsent || firmaOperador != null) {
      map['firma_operador'] = Variable<String>(firmaOperador);
    }
    if (!nullToAbsent || dispositivoId != null) {
      map['dispositivo_id'] = Variable<String>(dispositivoId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    if (!nullToAbsent || sincronizadoAt != null) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RegistrosDiariosLocalCompanion toCompanion(bool nullToAbsent) {
    return RegistrosDiariosLocalCompanion(
      id: Value(id),
      numeroRegistro: Value(numeroRegistro),
      fecha: Value(fecha),
      turno: Value(turno),
      procesoId: Value(procesoId),
      procesoNombre: Value(procesoNombre),
      procesoCodigo: Value(procesoCodigo),
      cultivoIdErp: Value(cultivoIdErp),
      cultivoNombreEspecie: Value(cultivoNombreEspecie),
      cultivoCodigoEspecie: Value(cultivoCodigoEspecie),
      operadorIdErp: Value(operadorIdErp),
      operadorCodigo: Value(operadorCodigo),
      operadorNombre: Value(operadorNombre),
      supervisorIdErp: supervisorIdErp == null && nullToAbsent
          ? const Value.absent()
          : Value(supervisorIdErp),
      supervisorCodigo: supervisorCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(supervisorCodigo),
      supervisorNombre: supervisorNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(supervisorNombre),
      tractorIdErp: Value(tractorIdErp),
      tractorCodigo: Value(tractorCodigo),
      tractorDescripcion: Value(tractorDescripcion),
      implementoIdErp: implementoIdErp == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoIdErp),
      implementoCodigo: implementoCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoCodigo),
      implementoDescripcion: implementoDescripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoDescripcion),
      cajaCambiosId: cajaCambiosId == null && nullToAbsent
          ? const Value.absent()
          : Value(cajaCambiosId),
      cajaCambiosNombre: cajaCambiosNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(cajaCambiosNombre),
      subprocesoId: subprocesoId == null && nullToAbsent
          ? const Value.absent()
          : Value(subprocesoId),
      subprocesoNombre: subprocesoNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(subprocesoNombre),
      jornadaInicioAt: jornadaInicioAt == null && nullToAbsent
          ? const Value.absent()
          : Value(jornadaInicioAt),
      jornadaFinAt: jornadaFinAt == null && nullToAbsent
          ? const Value.absent()
          : Value(jornadaFinAt),
      tipoRegistro: Value(tipoRegistro),
      estado: Value(estado),
      observacionesMaq: observacionesMaq == null && nullToAbsent
          ? const Value.absent()
          : Value(observacionesMaq),
      motivoRechazo: motivoRechazo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivoRechazo),
      firmaOperador: firmaOperador == null && nullToAbsent
          ? const Value.absent()
          : Value(firmaOperador),
      dispositivoId: dispositivoId == null && nullToAbsent
          ? const Value.absent()
          : Value(dispositivoId),
      sincronizado: Value(sincronizado),
      sincronizadoAt: sincronizadoAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sincronizadoAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RegistrosDiariosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegistrosDiariosLocalData(
      id: serializer.fromJson<String>(json['id']),
      numeroRegistro: serializer.fromJson<String>(json['numeroRegistro']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      turno: serializer.fromJson<String>(json['turno']),
      procesoId: serializer.fromJson<int>(json['procesoId']),
      procesoNombre: serializer.fromJson<String>(json['procesoNombre']),
      procesoCodigo: serializer.fromJson<String>(json['procesoCodigo']),
      cultivoIdErp: serializer.fromJson<int>(json['cultivoIdErp']),
      cultivoNombreEspecie:
          serializer.fromJson<String>(json['cultivoNombreEspecie']),
      cultivoCodigoEspecie:
          serializer.fromJson<String>(json['cultivoCodigoEspecie']),
      operadorIdErp: serializer.fromJson<int>(json['operadorIdErp']),
      operadorCodigo: serializer.fromJson<String>(json['operadorCodigo']),
      operadorNombre: serializer.fromJson<String>(json['operadorNombre']),
      supervisorIdErp: serializer.fromJson<int?>(json['supervisorIdErp']),
      supervisorCodigo: serializer.fromJson<String?>(json['supervisorCodigo']),
      supervisorNombre: serializer.fromJson<String?>(json['supervisorNombre']),
      tractorIdErp: serializer.fromJson<int>(json['tractorIdErp']),
      tractorCodigo: serializer.fromJson<String>(json['tractorCodigo']),
      tractorDescripcion:
          serializer.fromJson<String>(json['tractorDescripcion']),
      implementoIdErp: serializer.fromJson<int?>(json['implementoIdErp']),
      implementoCodigo: serializer.fromJson<String?>(json['implementoCodigo']),
      implementoDescripcion:
          serializer.fromJson<String?>(json['implementoDescripcion']),
      cajaCambiosId: serializer.fromJson<int?>(json['cajaCambiosId']),
      cajaCambiosNombre:
          serializer.fromJson<String?>(json['cajaCambiosNombre']),
      subprocesoId: serializer.fromJson<int?>(json['subprocesoId']),
      subprocesoNombre: serializer.fromJson<String?>(json['subprocesoNombre']),
      jornadaInicioAt: serializer.fromJson<DateTime?>(json['jornadaInicioAt']),
      jornadaFinAt: serializer.fromJson<DateTime?>(json['jornadaFinAt']),
      tipoRegistro: serializer.fromJson<String>(json['tipoRegistro']),
      estado: serializer.fromJson<String>(json['estado']),
      observacionesMaq: serializer.fromJson<String?>(json['observacionesMaq']),
      motivoRechazo: serializer.fromJson<String?>(json['motivoRechazo']),
      firmaOperador: serializer.fromJson<String?>(json['firmaOperador']),
      dispositivoId: serializer.fromJson<String?>(json['dispositivoId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      sincronizadoAt: serializer.fromJson<DateTime?>(json['sincronizadoAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'numeroRegistro': serializer.toJson<String>(numeroRegistro),
      'fecha': serializer.toJson<DateTime>(fecha),
      'turno': serializer.toJson<String>(turno),
      'procesoId': serializer.toJson<int>(procesoId),
      'procesoNombre': serializer.toJson<String>(procesoNombre),
      'procesoCodigo': serializer.toJson<String>(procesoCodigo),
      'cultivoIdErp': serializer.toJson<int>(cultivoIdErp),
      'cultivoNombreEspecie': serializer.toJson<String>(cultivoNombreEspecie),
      'cultivoCodigoEspecie': serializer.toJson<String>(cultivoCodigoEspecie),
      'operadorIdErp': serializer.toJson<int>(operadorIdErp),
      'operadorCodigo': serializer.toJson<String>(operadorCodigo),
      'operadorNombre': serializer.toJson<String>(operadorNombre),
      'supervisorIdErp': serializer.toJson<int?>(supervisorIdErp),
      'supervisorCodigo': serializer.toJson<String?>(supervisorCodigo),
      'supervisorNombre': serializer.toJson<String?>(supervisorNombre),
      'tractorIdErp': serializer.toJson<int>(tractorIdErp),
      'tractorCodigo': serializer.toJson<String>(tractorCodigo),
      'tractorDescripcion': serializer.toJson<String>(tractorDescripcion),
      'implementoIdErp': serializer.toJson<int?>(implementoIdErp),
      'implementoCodigo': serializer.toJson<String?>(implementoCodigo),
      'implementoDescripcion':
          serializer.toJson<String?>(implementoDescripcion),
      'cajaCambiosId': serializer.toJson<int?>(cajaCambiosId),
      'cajaCambiosNombre': serializer.toJson<String?>(cajaCambiosNombre),
      'subprocesoId': serializer.toJson<int?>(subprocesoId),
      'subprocesoNombre': serializer.toJson<String?>(subprocesoNombre),
      'jornadaInicioAt': serializer.toJson<DateTime?>(jornadaInicioAt),
      'jornadaFinAt': serializer.toJson<DateTime?>(jornadaFinAt),
      'tipoRegistro': serializer.toJson<String>(tipoRegistro),
      'estado': serializer.toJson<String>(estado),
      'observacionesMaq': serializer.toJson<String?>(observacionesMaq),
      'motivoRechazo': serializer.toJson<String?>(motivoRechazo),
      'firmaOperador': serializer.toJson<String?>(firmaOperador),
      'dispositivoId': serializer.toJson<String?>(dispositivoId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'sincronizadoAt': serializer.toJson<DateTime?>(sincronizadoAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RegistrosDiariosLocalData copyWith(
          {String? id,
          String? numeroRegistro,
          DateTime? fecha,
          String? turno,
          int? procesoId,
          String? procesoNombre,
          String? procesoCodigo,
          int? cultivoIdErp,
          String? cultivoNombreEspecie,
          String? cultivoCodigoEspecie,
          int? operadorIdErp,
          String? operadorCodigo,
          String? operadorNombre,
          Value<int?> supervisorIdErp = const Value.absent(),
          Value<String?> supervisorCodigo = const Value.absent(),
          Value<String?> supervisorNombre = const Value.absent(),
          int? tractorIdErp,
          String? tractorCodigo,
          String? tractorDescripcion,
          Value<int?> implementoIdErp = const Value.absent(),
          Value<String?> implementoCodigo = const Value.absent(),
          Value<String?> implementoDescripcion = const Value.absent(),
          Value<int?> cajaCambiosId = const Value.absent(),
          Value<String?> cajaCambiosNombre = const Value.absent(),
          Value<int?> subprocesoId = const Value.absent(),
          Value<String?> subprocesoNombre = const Value.absent(),
          Value<DateTime?> jornadaInicioAt = const Value.absent(),
          Value<DateTime?> jornadaFinAt = const Value.absent(),
          String? tipoRegistro,
          String? estado,
          Value<String?> observacionesMaq = const Value.absent(),
          Value<String?> motivoRechazo = const Value.absent(),
          Value<String?> firmaOperador = const Value.absent(),
          Value<String?> dispositivoId = const Value.absent(),
          bool? sincronizado,
          Value<DateTime?> sincronizadoAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      RegistrosDiariosLocalData(
        id: id ?? this.id,
        numeroRegistro: numeroRegistro ?? this.numeroRegistro,
        fecha: fecha ?? this.fecha,
        turno: turno ?? this.turno,
        procesoId: procesoId ?? this.procesoId,
        procesoNombre: procesoNombre ?? this.procesoNombre,
        procesoCodigo: procesoCodigo ?? this.procesoCodigo,
        cultivoIdErp: cultivoIdErp ?? this.cultivoIdErp,
        cultivoNombreEspecie: cultivoNombreEspecie ?? this.cultivoNombreEspecie,
        cultivoCodigoEspecie: cultivoCodigoEspecie ?? this.cultivoCodigoEspecie,
        operadorIdErp: operadorIdErp ?? this.operadorIdErp,
        operadorCodigo: operadorCodigo ?? this.operadorCodigo,
        operadorNombre: operadorNombre ?? this.operadorNombre,
        supervisorIdErp: supervisorIdErp.present
            ? supervisorIdErp.value
            : this.supervisorIdErp,
        supervisorCodigo: supervisorCodigo.present
            ? supervisorCodigo.value
            : this.supervisorCodigo,
        supervisorNombre: supervisorNombre.present
            ? supervisorNombre.value
            : this.supervisorNombre,
        tractorIdErp: tractorIdErp ?? this.tractorIdErp,
        tractorCodigo: tractorCodigo ?? this.tractorCodigo,
        tractorDescripcion: tractorDescripcion ?? this.tractorDescripcion,
        implementoIdErp: implementoIdErp.present
            ? implementoIdErp.value
            : this.implementoIdErp,
        implementoCodigo: implementoCodigo.present
            ? implementoCodigo.value
            : this.implementoCodigo,
        implementoDescripcion: implementoDescripcion.present
            ? implementoDescripcion.value
            : this.implementoDescripcion,
        cajaCambiosId:
            cajaCambiosId.present ? cajaCambiosId.value : this.cajaCambiosId,
        cajaCambiosNombre: cajaCambiosNombre.present
            ? cajaCambiosNombre.value
            : this.cajaCambiosNombre,
        subprocesoId:
            subprocesoId.present ? subprocesoId.value : this.subprocesoId,
        subprocesoNombre: subprocesoNombre.present
            ? subprocesoNombre.value
            : this.subprocesoNombre,
        jornadaInicioAt: jornadaInicioAt.present
            ? jornadaInicioAt.value
            : this.jornadaInicioAt,
        jornadaFinAt:
            jornadaFinAt.present ? jornadaFinAt.value : this.jornadaFinAt,
        tipoRegistro: tipoRegistro ?? this.tipoRegistro,
        estado: estado ?? this.estado,
        observacionesMaq: observacionesMaq.present
            ? observacionesMaq.value
            : this.observacionesMaq,
        motivoRechazo:
            motivoRechazo.present ? motivoRechazo.value : this.motivoRechazo,
        firmaOperador:
            firmaOperador.present ? firmaOperador.value : this.firmaOperador,
        dispositivoId:
            dispositivoId.present ? dispositivoId.value : this.dispositivoId,
        sincronizado: sincronizado ?? this.sincronizado,
        sincronizadoAt:
            sincronizadoAt.present ? sincronizadoAt.value : this.sincronizadoAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RegistrosDiariosLocalData copyWithCompanion(
      RegistrosDiariosLocalCompanion data) {
    return RegistrosDiariosLocalData(
      id: data.id.present ? data.id.value : this.id,
      numeroRegistro: data.numeroRegistro.present
          ? data.numeroRegistro.value
          : this.numeroRegistro,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      turno: data.turno.present ? data.turno.value : this.turno,
      procesoId: data.procesoId.present ? data.procesoId.value : this.procesoId,
      procesoNombre: data.procesoNombre.present
          ? data.procesoNombre.value
          : this.procesoNombre,
      procesoCodigo: data.procesoCodigo.present
          ? data.procesoCodigo.value
          : this.procesoCodigo,
      cultivoIdErp: data.cultivoIdErp.present
          ? data.cultivoIdErp.value
          : this.cultivoIdErp,
      cultivoNombreEspecie: data.cultivoNombreEspecie.present
          ? data.cultivoNombreEspecie.value
          : this.cultivoNombreEspecie,
      cultivoCodigoEspecie: data.cultivoCodigoEspecie.present
          ? data.cultivoCodigoEspecie.value
          : this.cultivoCodigoEspecie,
      operadorIdErp: data.operadorIdErp.present
          ? data.operadorIdErp.value
          : this.operadorIdErp,
      operadorCodigo: data.operadorCodigo.present
          ? data.operadorCodigo.value
          : this.operadorCodigo,
      operadorNombre: data.operadorNombre.present
          ? data.operadorNombre.value
          : this.operadorNombre,
      supervisorIdErp: data.supervisorIdErp.present
          ? data.supervisorIdErp.value
          : this.supervisorIdErp,
      supervisorCodigo: data.supervisorCodigo.present
          ? data.supervisorCodigo.value
          : this.supervisorCodigo,
      supervisorNombre: data.supervisorNombre.present
          ? data.supervisorNombre.value
          : this.supervisorNombre,
      tractorIdErp: data.tractorIdErp.present
          ? data.tractorIdErp.value
          : this.tractorIdErp,
      tractorCodigo: data.tractorCodigo.present
          ? data.tractorCodigo.value
          : this.tractorCodigo,
      tractorDescripcion: data.tractorDescripcion.present
          ? data.tractorDescripcion.value
          : this.tractorDescripcion,
      implementoIdErp: data.implementoIdErp.present
          ? data.implementoIdErp.value
          : this.implementoIdErp,
      implementoCodigo: data.implementoCodigo.present
          ? data.implementoCodigo.value
          : this.implementoCodigo,
      implementoDescripcion: data.implementoDescripcion.present
          ? data.implementoDescripcion.value
          : this.implementoDescripcion,
      cajaCambiosId: data.cajaCambiosId.present
          ? data.cajaCambiosId.value
          : this.cajaCambiosId,
      cajaCambiosNombre: data.cajaCambiosNombre.present
          ? data.cajaCambiosNombre.value
          : this.cajaCambiosNombre,
      subprocesoId: data.subprocesoId.present
          ? data.subprocesoId.value
          : this.subprocesoId,
      subprocesoNombre: data.subprocesoNombre.present
          ? data.subprocesoNombre.value
          : this.subprocesoNombre,
      jornadaInicioAt: data.jornadaInicioAt.present
          ? data.jornadaInicioAt.value
          : this.jornadaInicioAt,
      jornadaFinAt: data.jornadaFinAt.present
          ? data.jornadaFinAt.value
          : this.jornadaFinAt,
      tipoRegistro: data.tipoRegistro.present
          ? data.tipoRegistro.value
          : this.tipoRegistro,
      estado: data.estado.present ? data.estado.value : this.estado,
      observacionesMaq: data.observacionesMaq.present
          ? data.observacionesMaq.value
          : this.observacionesMaq,
      motivoRechazo: data.motivoRechazo.present
          ? data.motivoRechazo.value
          : this.motivoRechazo,
      firmaOperador: data.firmaOperador.present
          ? data.firmaOperador.value
          : this.firmaOperador,
      dispositivoId: data.dispositivoId.present
          ? data.dispositivoId.value
          : this.dispositivoId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      sincronizadoAt: data.sincronizadoAt.present
          ? data.sincronizadoAt.value
          : this.sincronizadoAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegistrosDiariosLocalData(')
          ..write('id: $id, ')
          ..write('numeroRegistro: $numeroRegistro, ')
          ..write('fecha: $fecha, ')
          ..write('turno: $turno, ')
          ..write('procesoId: $procesoId, ')
          ..write('procesoNombre: $procesoNombre, ')
          ..write('procesoCodigo: $procesoCodigo, ')
          ..write('cultivoIdErp: $cultivoIdErp, ')
          ..write('cultivoNombreEspecie: $cultivoNombreEspecie, ')
          ..write('cultivoCodigoEspecie: $cultivoCodigoEspecie, ')
          ..write('operadorIdErp: $operadorIdErp, ')
          ..write('operadorCodigo: $operadorCodigo, ')
          ..write('operadorNombre: $operadorNombre, ')
          ..write('supervisorIdErp: $supervisorIdErp, ')
          ..write('supervisorCodigo: $supervisorCodigo, ')
          ..write('supervisorNombre: $supervisorNombre, ')
          ..write('tractorIdErp: $tractorIdErp, ')
          ..write('tractorCodigo: $tractorCodigo, ')
          ..write('tractorDescripcion: $tractorDescripcion, ')
          ..write('implementoIdErp: $implementoIdErp, ')
          ..write('implementoCodigo: $implementoCodigo, ')
          ..write('implementoDescripcion: $implementoDescripcion, ')
          ..write('cajaCambiosId: $cajaCambiosId, ')
          ..write('cajaCambiosNombre: $cajaCambiosNombre, ')
          ..write('subprocesoId: $subprocesoId, ')
          ..write('subprocesoNombre: $subprocesoNombre, ')
          ..write('jornadaInicioAt: $jornadaInicioAt, ')
          ..write('jornadaFinAt: $jornadaFinAt, ')
          ..write('tipoRegistro: $tipoRegistro, ')
          ..write('estado: $estado, ')
          ..write('observacionesMaq: $observacionesMaq, ')
          ..write('motivoRechazo: $motivoRechazo, ')
          ..write('firmaOperador: $firmaOperador, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('sincronizadoAt: $sincronizadoAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        numeroRegistro,
        fecha,
        turno,
        procesoId,
        procesoNombre,
        procesoCodigo,
        cultivoIdErp,
        cultivoNombreEspecie,
        cultivoCodigoEspecie,
        operadorIdErp,
        operadorCodigo,
        operadorNombre,
        supervisorIdErp,
        supervisorCodigo,
        supervisorNombre,
        tractorIdErp,
        tractorCodigo,
        tractorDescripcion,
        implementoIdErp,
        implementoCodigo,
        implementoDescripcion,
        cajaCambiosId,
        cajaCambiosNombre,
        subprocesoId,
        subprocesoNombre,
        jornadaInicioAt,
        jornadaFinAt,
        tipoRegistro,
        estado,
        observacionesMaq,
        motivoRechazo,
        firmaOperador,
        dispositivoId,
        sincronizado,
        sincronizadoAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegistrosDiariosLocalData &&
          other.id == this.id &&
          other.numeroRegistro == this.numeroRegistro &&
          other.fecha == this.fecha &&
          other.turno == this.turno &&
          other.procesoId == this.procesoId &&
          other.procesoNombre == this.procesoNombre &&
          other.procesoCodigo == this.procesoCodigo &&
          other.cultivoIdErp == this.cultivoIdErp &&
          other.cultivoNombreEspecie == this.cultivoNombreEspecie &&
          other.cultivoCodigoEspecie == this.cultivoCodigoEspecie &&
          other.operadorIdErp == this.operadorIdErp &&
          other.operadorCodigo == this.operadorCodigo &&
          other.operadorNombre == this.operadorNombre &&
          other.supervisorIdErp == this.supervisorIdErp &&
          other.supervisorCodigo == this.supervisorCodigo &&
          other.supervisorNombre == this.supervisorNombre &&
          other.tractorIdErp == this.tractorIdErp &&
          other.tractorCodigo == this.tractorCodigo &&
          other.tractorDescripcion == this.tractorDescripcion &&
          other.implementoIdErp == this.implementoIdErp &&
          other.implementoCodigo == this.implementoCodigo &&
          other.implementoDescripcion == this.implementoDescripcion &&
          other.cajaCambiosId == this.cajaCambiosId &&
          other.cajaCambiosNombre == this.cajaCambiosNombre &&
          other.subprocesoId == this.subprocesoId &&
          other.subprocesoNombre == this.subprocesoNombre &&
          other.jornadaInicioAt == this.jornadaInicioAt &&
          other.jornadaFinAt == this.jornadaFinAt &&
          other.tipoRegistro == this.tipoRegistro &&
          other.estado == this.estado &&
          other.observacionesMaq == this.observacionesMaq &&
          other.motivoRechazo == this.motivoRechazo &&
          other.firmaOperador == this.firmaOperador &&
          other.dispositivoId == this.dispositivoId &&
          other.sincronizado == this.sincronizado &&
          other.sincronizadoAt == this.sincronizadoAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RegistrosDiariosLocalCompanion
    extends UpdateCompanion<RegistrosDiariosLocalData> {
  final Value<String> id;
  final Value<String> numeroRegistro;
  final Value<DateTime> fecha;
  final Value<String> turno;
  final Value<int> procesoId;
  final Value<String> procesoNombre;
  final Value<String> procesoCodigo;
  final Value<int> cultivoIdErp;
  final Value<String> cultivoNombreEspecie;
  final Value<String> cultivoCodigoEspecie;
  final Value<int> operadorIdErp;
  final Value<String> operadorCodigo;
  final Value<String> operadorNombre;
  final Value<int?> supervisorIdErp;
  final Value<String?> supervisorCodigo;
  final Value<String?> supervisorNombre;
  final Value<int> tractorIdErp;
  final Value<String> tractorCodigo;
  final Value<String> tractorDescripcion;
  final Value<int?> implementoIdErp;
  final Value<String?> implementoCodigo;
  final Value<String?> implementoDescripcion;
  final Value<int?> cajaCambiosId;
  final Value<String?> cajaCambiosNombre;
  final Value<int?> subprocesoId;
  final Value<String?> subprocesoNombre;
  final Value<DateTime?> jornadaInicioAt;
  final Value<DateTime?> jornadaFinAt;
  final Value<String> tipoRegistro;
  final Value<String> estado;
  final Value<String?> observacionesMaq;
  final Value<String?> motivoRechazo;
  final Value<String?> firmaOperador;
  final Value<String?> dispositivoId;
  final Value<bool> sincronizado;
  final Value<DateTime?> sincronizadoAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RegistrosDiariosLocalCompanion({
    this.id = const Value.absent(),
    this.numeroRegistro = const Value.absent(),
    this.fecha = const Value.absent(),
    this.turno = const Value.absent(),
    this.procesoId = const Value.absent(),
    this.procesoNombre = const Value.absent(),
    this.procesoCodigo = const Value.absent(),
    this.cultivoIdErp = const Value.absent(),
    this.cultivoNombreEspecie = const Value.absent(),
    this.cultivoCodigoEspecie = const Value.absent(),
    this.operadorIdErp = const Value.absent(),
    this.operadorCodigo = const Value.absent(),
    this.operadorNombre = const Value.absent(),
    this.supervisorIdErp = const Value.absent(),
    this.supervisorCodigo = const Value.absent(),
    this.supervisorNombre = const Value.absent(),
    this.tractorIdErp = const Value.absent(),
    this.tractorCodigo = const Value.absent(),
    this.tractorDescripcion = const Value.absent(),
    this.implementoIdErp = const Value.absent(),
    this.implementoCodigo = const Value.absent(),
    this.implementoDescripcion = const Value.absent(),
    this.cajaCambiosId = const Value.absent(),
    this.cajaCambiosNombre = const Value.absent(),
    this.subprocesoId = const Value.absent(),
    this.subprocesoNombre = const Value.absent(),
    this.jornadaInicioAt = const Value.absent(),
    this.jornadaFinAt = const Value.absent(),
    this.tipoRegistro = const Value.absent(),
    this.estado = const Value.absent(),
    this.observacionesMaq = const Value.absent(),
    this.motivoRechazo = const Value.absent(),
    this.firmaOperador = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegistrosDiariosLocalCompanion.insert({
    required String id,
    this.numeroRegistro = const Value.absent(),
    required DateTime fecha,
    this.turno = const Value.absent(),
    required int procesoId,
    this.procesoNombre = const Value.absent(),
    this.procesoCodigo = const Value.absent(),
    required int cultivoIdErp,
    this.cultivoNombreEspecie = const Value.absent(),
    this.cultivoCodigoEspecie = const Value.absent(),
    required int operadorIdErp,
    this.operadorCodigo = const Value.absent(),
    this.operadorNombre = const Value.absent(),
    this.supervisorIdErp = const Value.absent(),
    this.supervisorCodigo = const Value.absent(),
    this.supervisorNombre = const Value.absent(),
    required int tractorIdErp,
    this.tractorCodigo = const Value.absent(),
    this.tractorDescripcion = const Value.absent(),
    this.implementoIdErp = const Value.absent(),
    this.implementoCodigo = const Value.absent(),
    this.implementoDescripcion = const Value.absent(),
    this.cajaCambiosId = const Value.absent(),
    this.cajaCambiosNombre = const Value.absent(),
    this.subprocesoId = const Value.absent(),
    this.subprocesoNombre = const Value.absent(),
    this.jornadaInicioAt = const Value.absent(),
    this.jornadaFinAt = const Value.absent(),
    this.tipoRegistro = const Value.absent(),
    this.estado = const Value.absent(),
    this.observacionesMaq = const Value.absent(),
    this.motivoRechazo = const Value.absent(),
    this.firmaOperador = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.sincronizadoAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fecha = Value(fecha),
        procesoId = Value(procesoId),
        cultivoIdErp = Value(cultivoIdErp),
        operadorIdErp = Value(operadorIdErp),
        tractorIdErp = Value(tractorIdErp);
  static Insertable<RegistrosDiariosLocalData> custom({
    Expression<String>? id,
    Expression<String>? numeroRegistro,
    Expression<DateTime>? fecha,
    Expression<String>? turno,
    Expression<int>? procesoId,
    Expression<String>? procesoNombre,
    Expression<String>? procesoCodigo,
    Expression<int>? cultivoIdErp,
    Expression<String>? cultivoNombreEspecie,
    Expression<String>? cultivoCodigoEspecie,
    Expression<int>? operadorIdErp,
    Expression<String>? operadorCodigo,
    Expression<String>? operadorNombre,
    Expression<int>? supervisorIdErp,
    Expression<String>? supervisorCodigo,
    Expression<String>? supervisorNombre,
    Expression<int>? tractorIdErp,
    Expression<String>? tractorCodigo,
    Expression<String>? tractorDescripcion,
    Expression<int>? implementoIdErp,
    Expression<String>? implementoCodigo,
    Expression<String>? implementoDescripcion,
    Expression<int>? cajaCambiosId,
    Expression<String>? cajaCambiosNombre,
    Expression<int>? subprocesoId,
    Expression<String>? subprocesoNombre,
    Expression<DateTime>? jornadaInicioAt,
    Expression<DateTime>? jornadaFinAt,
    Expression<String>? tipoRegistro,
    Expression<String>? estado,
    Expression<String>? observacionesMaq,
    Expression<String>? motivoRechazo,
    Expression<String>? firmaOperador,
    Expression<String>? dispositivoId,
    Expression<bool>? sincronizado,
    Expression<DateTime>? sincronizadoAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numeroRegistro != null) 'numero_registro': numeroRegistro,
      if (fecha != null) 'fecha': fecha,
      if (turno != null) 'turno': turno,
      if (procesoId != null) 'proceso_id': procesoId,
      if (procesoNombre != null) 'proceso_nombre': procesoNombre,
      if (procesoCodigo != null) 'proceso_codigo': procesoCodigo,
      if (cultivoIdErp != null) 'cultivo_id_erp': cultivoIdErp,
      if (cultivoNombreEspecie != null)
        'cultivo_nombre_especie': cultivoNombreEspecie,
      if (cultivoCodigoEspecie != null)
        'cultivo_codigo_especie': cultivoCodigoEspecie,
      if (operadorIdErp != null) 'operador_id_erp': operadorIdErp,
      if (operadorCodigo != null) 'operador_codigo': operadorCodigo,
      if (operadorNombre != null) 'operador_nombre': operadorNombre,
      if (supervisorIdErp != null) 'supervisor_id_erp': supervisorIdErp,
      if (supervisorCodigo != null) 'supervisor_codigo': supervisorCodigo,
      if (supervisorNombre != null) 'supervisor_nombre': supervisorNombre,
      if (tractorIdErp != null) 'tractor_id_erp': tractorIdErp,
      if (tractorCodigo != null) 'tractor_codigo': tractorCodigo,
      if (tractorDescripcion != null) 'tractor_descripcion': tractorDescripcion,
      if (implementoIdErp != null) 'implemento_id_erp': implementoIdErp,
      if (implementoCodigo != null) 'implemento_codigo': implementoCodigo,
      if (implementoDescripcion != null)
        'implemento_descripcion': implementoDescripcion,
      if (cajaCambiosId != null) 'caja_cambios_id': cajaCambiosId,
      if (cajaCambiosNombre != null) 'caja_cambios_nombre': cajaCambiosNombre,
      if (subprocesoId != null) 'subproceso_id': subprocesoId,
      if (subprocesoNombre != null) 'subproceso_nombre': subprocesoNombre,
      if (jornadaInicioAt != null) 'jornada_inicio_at': jornadaInicioAt,
      if (jornadaFinAt != null) 'jornada_fin_at': jornadaFinAt,
      if (tipoRegistro != null) 'tipo_registro': tipoRegistro,
      if (estado != null) 'estado': estado,
      if (observacionesMaq != null) 'observaciones_maq': observacionesMaq,
      if (motivoRechazo != null) 'motivo_rechazo': motivoRechazo,
      if (firmaOperador != null) 'firma_operador': firmaOperador,
      if (dispositivoId != null) 'dispositivo_id': dispositivoId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (sincronizadoAt != null) 'sincronizado_at': sincronizadoAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegistrosDiariosLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? numeroRegistro,
      Value<DateTime>? fecha,
      Value<String>? turno,
      Value<int>? procesoId,
      Value<String>? procesoNombre,
      Value<String>? procesoCodigo,
      Value<int>? cultivoIdErp,
      Value<String>? cultivoNombreEspecie,
      Value<String>? cultivoCodigoEspecie,
      Value<int>? operadorIdErp,
      Value<String>? operadorCodigo,
      Value<String>? operadorNombre,
      Value<int?>? supervisorIdErp,
      Value<String?>? supervisorCodigo,
      Value<String?>? supervisorNombre,
      Value<int>? tractorIdErp,
      Value<String>? tractorCodigo,
      Value<String>? tractorDescripcion,
      Value<int?>? implementoIdErp,
      Value<String?>? implementoCodigo,
      Value<String?>? implementoDescripcion,
      Value<int?>? cajaCambiosId,
      Value<String?>? cajaCambiosNombre,
      Value<int?>? subprocesoId,
      Value<String?>? subprocesoNombre,
      Value<DateTime?>? jornadaInicioAt,
      Value<DateTime?>? jornadaFinAt,
      Value<String>? tipoRegistro,
      Value<String>? estado,
      Value<String?>? observacionesMaq,
      Value<String?>? motivoRechazo,
      Value<String?>? firmaOperador,
      Value<String?>? dispositivoId,
      Value<bool>? sincronizado,
      Value<DateTime?>? sincronizadoAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return RegistrosDiariosLocalCompanion(
      id: id ?? this.id,
      numeroRegistro: numeroRegistro ?? this.numeroRegistro,
      fecha: fecha ?? this.fecha,
      turno: turno ?? this.turno,
      procesoId: procesoId ?? this.procesoId,
      procesoNombre: procesoNombre ?? this.procesoNombre,
      procesoCodigo: procesoCodigo ?? this.procesoCodigo,
      cultivoIdErp: cultivoIdErp ?? this.cultivoIdErp,
      cultivoNombreEspecie: cultivoNombreEspecie ?? this.cultivoNombreEspecie,
      cultivoCodigoEspecie: cultivoCodigoEspecie ?? this.cultivoCodigoEspecie,
      operadorIdErp: operadorIdErp ?? this.operadorIdErp,
      operadorCodigo: operadorCodigo ?? this.operadorCodigo,
      operadorNombre: operadorNombre ?? this.operadorNombre,
      supervisorIdErp: supervisorIdErp ?? this.supervisorIdErp,
      supervisorCodigo: supervisorCodigo ?? this.supervisorCodigo,
      supervisorNombre: supervisorNombre ?? this.supervisorNombre,
      tractorIdErp: tractorIdErp ?? this.tractorIdErp,
      tractorCodigo: tractorCodigo ?? this.tractorCodigo,
      tractorDescripcion: tractorDescripcion ?? this.tractorDescripcion,
      implementoIdErp: implementoIdErp ?? this.implementoIdErp,
      implementoCodigo: implementoCodigo ?? this.implementoCodigo,
      implementoDescripcion:
          implementoDescripcion ?? this.implementoDescripcion,
      cajaCambiosId: cajaCambiosId ?? this.cajaCambiosId,
      cajaCambiosNombre: cajaCambiosNombre ?? this.cajaCambiosNombre,
      subprocesoId: subprocesoId ?? this.subprocesoId,
      subprocesoNombre: subprocesoNombre ?? this.subprocesoNombre,
      jornadaInicioAt: jornadaInicioAt ?? this.jornadaInicioAt,
      jornadaFinAt: jornadaFinAt ?? this.jornadaFinAt,
      tipoRegistro: tipoRegistro ?? this.tipoRegistro,
      estado: estado ?? this.estado,
      observacionesMaq: observacionesMaq ?? this.observacionesMaq,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      firmaOperador: firmaOperador ?? this.firmaOperador,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      sincronizado: sincronizado ?? this.sincronizado,
      sincronizadoAt: sincronizadoAt ?? this.sincronizadoAt,
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
    if (numeroRegistro.present) {
      map['numero_registro'] = Variable<String>(numeroRegistro.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (turno.present) {
      map['turno'] = Variable<String>(turno.value);
    }
    if (procesoId.present) {
      map['proceso_id'] = Variable<int>(procesoId.value);
    }
    if (procesoNombre.present) {
      map['proceso_nombre'] = Variable<String>(procesoNombre.value);
    }
    if (procesoCodigo.present) {
      map['proceso_codigo'] = Variable<String>(procesoCodigo.value);
    }
    if (cultivoIdErp.present) {
      map['cultivo_id_erp'] = Variable<int>(cultivoIdErp.value);
    }
    if (cultivoNombreEspecie.present) {
      map['cultivo_nombre_especie'] =
          Variable<String>(cultivoNombreEspecie.value);
    }
    if (cultivoCodigoEspecie.present) {
      map['cultivo_codigo_especie'] =
          Variable<String>(cultivoCodigoEspecie.value);
    }
    if (operadorIdErp.present) {
      map['operador_id_erp'] = Variable<int>(operadorIdErp.value);
    }
    if (operadorCodigo.present) {
      map['operador_codigo'] = Variable<String>(operadorCodigo.value);
    }
    if (operadorNombre.present) {
      map['operador_nombre'] = Variable<String>(operadorNombre.value);
    }
    if (supervisorIdErp.present) {
      map['supervisor_id_erp'] = Variable<int>(supervisorIdErp.value);
    }
    if (supervisorCodigo.present) {
      map['supervisor_codigo'] = Variable<String>(supervisorCodigo.value);
    }
    if (supervisorNombre.present) {
      map['supervisor_nombre'] = Variable<String>(supervisorNombre.value);
    }
    if (tractorIdErp.present) {
      map['tractor_id_erp'] = Variable<int>(tractorIdErp.value);
    }
    if (tractorCodigo.present) {
      map['tractor_codigo'] = Variable<String>(tractorCodigo.value);
    }
    if (tractorDescripcion.present) {
      map['tractor_descripcion'] = Variable<String>(tractorDescripcion.value);
    }
    if (implementoIdErp.present) {
      map['implemento_id_erp'] = Variable<int>(implementoIdErp.value);
    }
    if (implementoCodigo.present) {
      map['implemento_codigo'] = Variable<String>(implementoCodigo.value);
    }
    if (implementoDescripcion.present) {
      map['implemento_descripcion'] =
          Variable<String>(implementoDescripcion.value);
    }
    if (cajaCambiosId.present) {
      map['caja_cambios_id'] = Variable<int>(cajaCambiosId.value);
    }
    if (cajaCambiosNombre.present) {
      map['caja_cambios_nombre'] = Variable<String>(cajaCambiosNombre.value);
    }
    if (subprocesoId.present) {
      map['subproceso_id'] = Variable<int>(subprocesoId.value);
    }
    if (subprocesoNombre.present) {
      map['subproceso_nombre'] = Variable<String>(subprocesoNombre.value);
    }
    if (jornadaInicioAt.present) {
      map['jornada_inicio_at'] = Variable<DateTime>(jornadaInicioAt.value);
    }
    if (jornadaFinAt.present) {
      map['jornada_fin_at'] = Variable<DateTime>(jornadaFinAt.value);
    }
    if (tipoRegistro.present) {
      map['tipo_registro'] = Variable<String>(tipoRegistro.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (observacionesMaq.present) {
      map['observaciones_maq'] = Variable<String>(observacionesMaq.value);
    }
    if (motivoRechazo.present) {
      map['motivo_rechazo'] = Variable<String>(motivoRechazo.value);
    }
    if (firmaOperador.present) {
      map['firma_operador'] = Variable<String>(firmaOperador.value);
    }
    if (dispositivoId.present) {
      map['dispositivo_id'] = Variable<String>(dispositivoId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (sincronizadoAt.present) {
      map['sincronizado_at'] = Variable<DateTime>(sincronizadoAt.value);
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
    return (StringBuffer('RegistrosDiariosLocalCompanion(')
          ..write('id: $id, ')
          ..write('numeroRegistro: $numeroRegistro, ')
          ..write('fecha: $fecha, ')
          ..write('turno: $turno, ')
          ..write('procesoId: $procesoId, ')
          ..write('procesoNombre: $procesoNombre, ')
          ..write('procesoCodigo: $procesoCodigo, ')
          ..write('cultivoIdErp: $cultivoIdErp, ')
          ..write('cultivoNombreEspecie: $cultivoNombreEspecie, ')
          ..write('cultivoCodigoEspecie: $cultivoCodigoEspecie, ')
          ..write('operadorIdErp: $operadorIdErp, ')
          ..write('operadorCodigo: $operadorCodigo, ')
          ..write('operadorNombre: $operadorNombre, ')
          ..write('supervisorIdErp: $supervisorIdErp, ')
          ..write('supervisorCodigo: $supervisorCodigo, ')
          ..write('supervisorNombre: $supervisorNombre, ')
          ..write('tractorIdErp: $tractorIdErp, ')
          ..write('tractorCodigo: $tractorCodigo, ')
          ..write('tractorDescripcion: $tractorDescripcion, ')
          ..write('implementoIdErp: $implementoIdErp, ')
          ..write('implementoCodigo: $implementoCodigo, ')
          ..write('implementoDescripcion: $implementoDescripcion, ')
          ..write('cajaCambiosId: $cajaCambiosId, ')
          ..write('cajaCambiosNombre: $cajaCambiosNombre, ')
          ..write('subprocesoId: $subprocesoId, ')
          ..write('subprocesoNombre: $subprocesoNombre, ')
          ..write('jornadaInicioAt: $jornadaInicioAt, ')
          ..write('jornadaFinAt: $jornadaFinAt, ')
          ..write('tipoRegistro: $tipoRegistro, ')
          ..write('estado: $estado, ')
          ..write('observacionesMaq: $observacionesMaq, ')
          ..write('motivoRechazo: $motivoRechazo, ')
          ..write('firmaOperador: $firmaOperador, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('sincronizadoAt: $sincronizadoAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HorometrosLocalTable extends HorometrosLocal
    with TableInfo<$HorometrosLocalTable, HorometrosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HorometrosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tractorInicioMeta =
      const VerificationMeta('tractorInicio');
  @override
  late final GeneratedColumn<double> tractorInicio = GeneratedColumn<double>(
      'tractor_inicio', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _tractorFinalMeta =
      const VerificationMeta('tractorFinal');
  @override
  late final GeneratedColumn<double> tractorFinal = GeneratedColumn<double>(
      'tractor_final', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _implementoInicioMeta =
      const VerificationMeta('implementoInicio');
  @override
  late final GeneratedColumn<double> implementoInicio = GeneratedColumn<double>(
      'implemento_inicio', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _implementoFinalMeta =
      const VerificationMeta('implementoFinal');
  @override
  late final GeneratedColumn<double> implementoFinal = GeneratedColumn<double>(
      'implemento_final', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroId,
        tractorInicio,
        tractorFinal,
        implementoInicio,
        implementoFinal,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'horometros_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<HorometrosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('tractor_inicio')) {
      context.handle(
          _tractorInicioMeta,
          tractorInicio.isAcceptableOrUnknown(
              data['tractor_inicio']!, _tractorInicioMeta));
    }
    if (data.containsKey('tractor_final')) {
      context.handle(
          _tractorFinalMeta,
          tractorFinal.isAcceptableOrUnknown(
              data['tractor_final']!, _tractorFinalMeta));
    }
    if (data.containsKey('implemento_inicio')) {
      context.handle(
          _implementoInicioMeta,
          implementoInicio.isAcceptableOrUnknown(
              data['implemento_inicio']!, _implementoInicioMeta));
    }
    if (data.containsKey('implemento_final')) {
      context.handle(
          _implementoFinalMeta,
          implementoFinal.isAcceptableOrUnknown(
              data['implemento_final']!, _implementoFinalMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HorometrosLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HorometrosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      tractorInicio: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tractor_inicio']),
      tractorFinal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tractor_final']),
      implementoInicio: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}implemento_inicio']),
      implementoFinal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}implemento_final']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HorometrosLocalTable createAlias(String alias) {
    return $HorometrosLocalTable(attachedDatabase, alias);
  }
}

class HorometrosLocalData extends DataClass
    implements Insertable<HorometrosLocalData> {
  final String id;
  final String registroId;
  final double? tractorInicio;
  final double? tractorFinal;
  final double? implementoInicio;
  final double? implementoFinal;
  final DateTime updatedAt;
  const HorometrosLocalData(
      {required this.id,
      required this.registroId,
      this.tractorInicio,
      this.tractorFinal,
      this.implementoInicio,
      this.implementoFinal,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    if (!nullToAbsent || tractorInicio != null) {
      map['tractor_inicio'] = Variable<double>(tractorInicio);
    }
    if (!nullToAbsent || tractorFinal != null) {
      map['tractor_final'] = Variable<double>(tractorFinal);
    }
    if (!nullToAbsent || implementoInicio != null) {
      map['implemento_inicio'] = Variable<double>(implementoInicio);
    }
    if (!nullToAbsent || implementoFinal != null) {
      map['implemento_final'] = Variable<double>(implementoFinal);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HorometrosLocalCompanion toCompanion(bool nullToAbsent) {
    return HorometrosLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      tractorInicio: tractorInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(tractorInicio),
      tractorFinal: tractorFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(tractorFinal),
      implementoInicio: implementoInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoInicio),
      implementoFinal: implementoFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoFinal),
      updatedAt: Value(updatedAt),
    );
  }

  factory HorometrosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HorometrosLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      tractorInicio: serializer.fromJson<double?>(json['tractorInicio']),
      tractorFinal: serializer.fromJson<double?>(json['tractorFinal']),
      implementoInicio: serializer.fromJson<double?>(json['implementoInicio']),
      implementoFinal: serializer.fromJson<double?>(json['implementoFinal']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'tractorInicio': serializer.toJson<double?>(tractorInicio),
      'tractorFinal': serializer.toJson<double?>(tractorFinal),
      'implementoInicio': serializer.toJson<double?>(implementoInicio),
      'implementoFinal': serializer.toJson<double?>(implementoFinal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HorometrosLocalData copyWith(
          {String? id,
          String? registroId,
          Value<double?> tractorInicio = const Value.absent(),
          Value<double?> tractorFinal = const Value.absent(),
          Value<double?> implementoInicio = const Value.absent(),
          Value<double?> implementoFinal = const Value.absent(),
          DateTime? updatedAt}) =>
      HorometrosLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        tractorInicio:
            tractorInicio.present ? tractorInicio.value : this.tractorInicio,
        tractorFinal:
            tractorFinal.present ? tractorFinal.value : this.tractorFinal,
        implementoInicio: implementoInicio.present
            ? implementoInicio.value
            : this.implementoInicio,
        implementoFinal: implementoFinal.present
            ? implementoFinal.value
            : this.implementoFinal,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HorometrosLocalData copyWithCompanion(HorometrosLocalCompanion data) {
    return HorometrosLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      tractorInicio: data.tractorInicio.present
          ? data.tractorInicio.value
          : this.tractorInicio,
      tractorFinal: data.tractorFinal.present
          ? data.tractorFinal.value
          : this.tractorFinal,
      implementoInicio: data.implementoInicio.present
          ? data.implementoInicio.value
          : this.implementoInicio,
      implementoFinal: data.implementoFinal.present
          ? data.implementoFinal.value
          : this.implementoFinal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HorometrosLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('tractorInicio: $tractorInicio, ')
          ..write('tractorFinal: $tractorFinal, ')
          ..write('implementoInicio: $implementoInicio, ')
          ..write('implementoFinal: $implementoFinal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, registroId, tractorInicio, tractorFinal,
      implementoInicio, implementoFinal, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HorometrosLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.tractorInicio == this.tractorInicio &&
          other.tractorFinal == this.tractorFinal &&
          other.implementoInicio == this.implementoInicio &&
          other.implementoFinal == this.implementoFinal &&
          other.updatedAt == this.updatedAt);
}

class HorometrosLocalCompanion extends UpdateCompanion<HorometrosLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<double?> tractorInicio;
  final Value<double?> tractorFinal;
  final Value<double?> implementoInicio;
  final Value<double?> implementoFinal;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HorometrosLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.tractorInicio = const Value.absent(),
    this.tractorFinal = const Value.absent(),
    this.implementoInicio = const Value.absent(),
    this.implementoFinal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HorometrosLocalCompanion.insert({
    required String id,
    required String registroId,
    this.tractorInicio = const Value.absent(),
    this.tractorFinal = const Value.absent(),
    this.implementoInicio = const Value.absent(),
    this.implementoFinal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId);
  static Insertable<HorometrosLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<double>? tractorInicio,
    Expression<double>? tractorFinal,
    Expression<double>? implementoInicio,
    Expression<double>? implementoFinal,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (tractorInicio != null) 'tractor_inicio': tractorInicio,
      if (tractorFinal != null) 'tractor_final': tractorFinal,
      if (implementoInicio != null) 'implemento_inicio': implementoInicio,
      if (implementoFinal != null) 'implemento_final': implementoFinal,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HorometrosLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<double?>? tractorInicio,
      Value<double?>? tractorFinal,
      Value<double?>? implementoInicio,
      Value<double?>? implementoFinal,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HorometrosLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      tractorInicio: tractorInicio ?? this.tractorInicio,
      tractorFinal: tractorFinal ?? this.tractorFinal,
      implementoInicio: implementoInicio ?? this.implementoInicio,
      implementoFinal: implementoFinal ?? this.implementoFinal,
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
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (tractorInicio.present) {
      map['tractor_inicio'] = Variable<double>(tractorInicio.value);
    }
    if (tractorFinal.present) {
      map['tractor_final'] = Variable<double>(tractorFinal.value);
    }
    if (implementoInicio.present) {
      map['implemento_inicio'] = Variable<double>(implementoInicio.value);
    }
    if (implementoFinal.present) {
      map['implemento_final'] = Variable<double>(implementoFinal.value);
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
    return (StringBuffer('HorometrosLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('tractorInicio: $tractorInicio, ')
          ..write('tractorFinal: $tractorFinal, ')
          ..write('implementoInicio: $implementoInicio, ')
          ..write('implementoFinal: $implementoFinal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TiemposTurnoLocalTable extends TiemposTurnoLocal
    with TableInfo<$TiemposTurnoLocalTable, TiemposTurnoLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiemposTurnoLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _horaSalidaTallerMeta =
      const VerificationMeta('horaSalidaTaller');
  @override
  late final GeneratedColumn<String> horaSalidaTaller = GeneratedColumn<String>(
      'hora_salida_taller', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaLlegadaPuntoMeta =
      const VerificationMeta('horaLlegadaPunto');
  @override
  late final GeneratedColumn<String> horaLlegadaPunto = GeneratedColumn<String>(
      'hora_llegada_punto', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaSalidaPuntoMeta =
      const VerificationMeta('horaSalidaPunto');
  @override
  late final GeneratedColumn<String> horaSalidaPunto = GeneratedColumn<String>(
      'hora_salida_punto', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaLlegadaTallerMeta =
      const VerificationMeta('horaLlegadaTaller');
  @override
  late final GeneratedColumn<String> horaLlegadaTaller =
      GeneratedColumn<String>('hora_llegada_taller', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaRefrigerioMeta =
      const VerificationMeta('horaRefrigerio');
  @override
  late final GeneratedColumn<String> horaRefrigerio = GeneratedColumn<String>(
      'hora_refrigerio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroId,
        horaSalidaTaller,
        horaLlegadaPunto,
        horaSalidaPunto,
        horaLlegadaTaller,
        horaRefrigerio,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tiempos_turno_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<TiemposTurnoLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('hora_salida_taller')) {
      context.handle(
          _horaSalidaTallerMeta,
          horaSalidaTaller.isAcceptableOrUnknown(
              data['hora_salida_taller']!, _horaSalidaTallerMeta));
    }
    if (data.containsKey('hora_llegada_punto')) {
      context.handle(
          _horaLlegadaPuntoMeta,
          horaLlegadaPunto.isAcceptableOrUnknown(
              data['hora_llegada_punto']!, _horaLlegadaPuntoMeta));
    }
    if (data.containsKey('hora_salida_punto')) {
      context.handle(
          _horaSalidaPuntoMeta,
          horaSalidaPunto.isAcceptableOrUnknown(
              data['hora_salida_punto']!, _horaSalidaPuntoMeta));
    }
    if (data.containsKey('hora_llegada_taller')) {
      context.handle(
          _horaLlegadaTallerMeta,
          horaLlegadaTaller.isAcceptableOrUnknown(
              data['hora_llegada_taller']!, _horaLlegadaTallerMeta));
    }
    if (data.containsKey('hora_refrigerio')) {
      context.handle(
          _horaRefrigerioMeta,
          horaRefrigerio.isAcceptableOrUnknown(
              data['hora_refrigerio']!, _horaRefrigerioMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TiemposTurnoLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TiemposTurnoLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      horaSalidaTaller: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_salida_taller']),
      horaLlegadaPunto: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_llegada_punto']),
      horaSalidaPunto: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_salida_punto']),
      horaLlegadaTaller: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_llegada_taller']),
      horaRefrigerio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hora_refrigerio']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TiemposTurnoLocalTable createAlias(String alias) {
    return $TiemposTurnoLocalTable(attachedDatabase, alias);
  }
}

class TiemposTurnoLocalData extends DataClass
    implements Insertable<TiemposTurnoLocalData> {
  final String id;
  final String registroId;
  final String? horaSalidaTaller;
  final String? horaLlegadaPunto;
  final String? horaSalidaPunto;
  final String? horaLlegadaTaller;
  final String? horaRefrigerio;
  final DateTime updatedAt;
  const TiemposTurnoLocalData(
      {required this.id,
      required this.registroId,
      this.horaSalidaTaller,
      this.horaLlegadaPunto,
      this.horaSalidaPunto,
      this.horaLlegadaTaller,
      this.horaRefrigerio,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    if (!nullToAbsent || horaSalidaTaller != null) {
      map['hora_salida_taller'] = Variable<String>(horaSalidaTaller);
    }
    if (!nullToAbsent || horaLlegadaPunto != null) {
      map['hora_llegada_punto'] = Variable<String>(horaLlegadaPunto);
    }
    if (!nullToAbsent || horaSalidaPunto != null) {
      map['hora_salida_punto'] = Variable<String>(horaSalidaPunto);
    }
    if (!nullToAbsent || horaLlegadaTaller != null) {
      map['hora_llegada_taller'] = Variable<String>(horaLlegadaTaller);
    }
    if (!nullToAbsent || horaRefrigerio != null) {
      map['hora_refrigerio'] = Variable<String>(horaRefrigerio);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TiemposTurnoLocalCompanion toCompanion(bool nullToAbsent) {
    return TiemposTurnoLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      horaSalidaTaller: horaSalidaTaller == null && nullToAbsent
          ? const Value.absent()
          : Value(horaSalidaTaller),
      horaLlegadaPunto: horaLlegadaPunto == null && nullToAbsent
          ? const Value.absent()
          : Value(horaLlegadaPunto),
      horaSalidaPunto: horaSalidaPunto == null && nullToAbsent
          ? const Value.absent()
          : Value(horaSalidaPunto),
      horaLlegadaTaller: horaLlegadaTaller == null && nullToAbsent
          ? const Value.absent()
          : Value(horaLlegadaTaller),
      horaRefrigerio: horaRefrigerio == null && nullToAbsent
          ? const Value.absent()
          : Value(horaRefrigerio),
      updatedAt: Value(updatedAt),
    );
  }

  factory TiemposTurnoLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TiemposTurnoLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      horaSalidaTaller: serializer.fromJson<String?>(json['horaSalidaTaller']),
      horaLlegadaPunto: serializer.fromJson<String?>(json['horaLlegadaPunto']),
      horaSalidaPunto: serializer.fromJson<String?>(json['horaSalidaPunto']),
      horaLlegadaTaller:
          serializer.fromJson<String?>(json['horaLlegadaTaller']),
      horaRefrigerio: serializer.fromJson<String?>(json['horaRefrigerio']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'horaSalidaTaller': serializer.toJson<String?>(horaSalidaTaller),
      'horaLlegadaPunto': serializer.toJson<String?>(horaLlegadaPunto),
      'horaSalidaPunto': serializer.toJson<String?>(horaSalidaPunto),
      'horaLlegadaTaller': serializer.toJson<String?>(horaLlegadaTaller),
      'horaRefrigerio': serializer.toJson<String?>(horaRefrigerio),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TiemposTurnoLocalData copyWith(
          {String? id,
          String? registroId,
          Value<String?> horaSalidaTaller = const Value.absent(),
          Value<String?> horaLlegadaPunto = const Value.absent(),
          Value<String?> horaSalidaPunto = const Value.absent(),
          Value<String?> horaLlegadaTaller = const Value.absent(),
          Value<String?> horaRefrigerio = const Value.absent(),
          DateTime? updatedAt}) =>
      TiemposTurnoLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        horaSalidaTaller: horaSalidaTaller.present
            ? horaSalidaTaller.value
            : this.horaSalidaTaller,
        horaLlegadaPunto: horaLlegadaPunto.present
            ? horaLlegadaPunto.value
            : this.horaLlegadaPunto,
        horaSalidaPunto: horaSalidaPunto.present
            ? horaSalidaPunto.value
            : this.horaSalidaPunto,
        horaLlegadaTaller: horaLlegadaTaller.present
            ? horaLlegadaTaller.value
            : this.horaLlegadaTaller,
        horaRefrigerio:
            horaRefrigerio.present ? horaRefrigerio.value : this.horaRefrigerio,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TiemposTurnoLocalData copyWithCompanion(TiemposTurnoLocalCompanion data) {
    return TiemposTurnoLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      horaSalidaTaller: data.horaSalidaTaller.present
          ? data.horaSalidaTaller.value
          : this.horaSalidaTaller,
      horaLlegadaPunto: data.horaLlegadaPunto.present
          ? data.horaLlegadaPunto.value
          : this.horaLlegadaPunto,
      horaSalidaPunto: data.horaSalidaPunto.present
          ? data.horaSalidaPunto.value
          : this.horaSalidaPunto,
      horaLlegadaTaller: data.horaLlegadaTaller.present
          ? data.horaLlegadaTaller.value
          : this.horaLlegadaTaller,
      horaRefrigerio: data.horaRefrigerio.present
          ? data.horaRefrigerio.value
          : this.horaRefrigerio,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TiemposTurnoLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('horaSalidaTaller: $horaSalidaTaller, ')
          ..write('horaLlegadaPunto: $horaLlegadaPunto, ')
          ..write('horaSalidaPunto: $horaSalidaPunto, ')
          ..write('horaLlegadaTaller: $horaLlegadaTaller, ')
          ..write('horaRefrigerio: $horaRefrigerio, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      registroId,
      horaSalidaTaller,
      horaLlegadaPunto,
      horaSalidaPunto,
      horaLlegadaTaller,
      horaRefrigerio,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TiemposTurnoLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.horaSalidaTaller == this.horaSalidaTaller &&
          other.horaLlegadaPunto == this.horaLlegadaPunto &&
          other.horaSalidaPunto == this.horaSalidaPunto &&
          other.horaLlegadaTaller == this.horaLlegadaTaller &&
          other.horaRefrigerio == this.horaRefrigerio &&
          other.updatedAt == this.updatedAt);
}

class TiemposTurnoLocalCompanion
    extends UpdateCompanion<TiemposTurnoLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<String?> horaSalidaTaller;
  final Value<String?> horaLlegadaPunto;
  final Value<String?> horaSalidaPunto;
  final Value<String?> horaLlegadaTaller;
  final Value<String?> horaRefrigerio;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TiemposTurnoLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.horaSalidaTaller = const Value.absent(),
    this.horaLlegadaPunto = const Value.absent(),
    this.horaSalidaPunto = const Value.absent(),
    this.horaLlegadaTaller = const Value.absent(),
    this.horaRefrigerio = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiemposTurnoLocalCompanion.insert({
    required String id,
    required String registroId,
    this.horaSalidaTaller = const Value.absent(),
    this.horaLlegadaPunto = const Value.absent(),
    this.horaSalidaPunto = const Value.absent(),
    this.horaLlegadaTaller = const Value.absent(),
    this.horaRefrigerio = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId);
  static Insertable<TiemposTurnoLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<String>? horaSalidaTaller,
    Expression<String>? horaLlegadaPunto,
    Expression<String>? horaSalidaPunto,
    Expression<String>? horaLlegadaTaller,
    Expression<String>? horaRefrigerio,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (horaSalidaTaller != null) 'hora_salida_taller': horaSalidaTaller,
      if (horaLlegadaPunto != null) 'hora_llegada_punto': horaLlegadaPunto,
      if (horaSalidaPunto != null) 'hora_salida_punto': horaSalidaPunto,
      if (horaLlegadaTaller != null) 'hora_llegada_taller': horaLlegadaTaller,
      if (horaRefrigerio != null) 'hora_refrigerio': horaRefrigerio,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiemposTurnoLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<String?>? horaSalidaTaller,
      Value<String?>? horaLlegadaPunto,
      Value<String?>? horaSalidaPunto,
      Value<String?>? horaLlegadaTaller,
      Value<String?>? horaRefrigerio,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TiemposTurnoLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      horaSalidaTaller: horaSalidaTaller ?? this.horaSalidaTaller,
      horaLlegadaPunto: horaLlegadaPunto ?? this.horaLlegadaPunto,
      horaSalidaPunto: horaSalidaPunto ?? this.horaSalidaPunto,
      horaLlegadaTaller: horaLlegadaTaller ?? this.horaLlegadaTaller,
      horaRefrigerio: horaRefrigerio ?? this.horaRefrigerio,
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
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (horaSalidaTaller.present) {
      map['hora_salida_taller'] = Variable<String>(horaSalidaTaller.value);
    }
    if (horaLlegadaPunto.present) {
      map['hora_llegada_punto'] = Variable<String>(horaLlegadaPunto.value);
    }
    if (horaSalidaPunto.present) {
      map['hora_salida_punto'] = Variable<String>(horaSalidaPunto.value);
    }
    if (horaLlegadaTaller.present) {
      map['hora_llegada_taller'] = Variable<String>(horaLlegadaTaller.value);
    }
    if (horaRefrigerio.present) {
      map['hora_refrigerio'] = Variable<String>(horaRefrigerio.value);
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
    return (StringBuffer('TiemposTurnoLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('horaSalidaTaller: $horaSalidaTaller, ')
          ..write('horaLlegadaPunto: $horaLlegadaPunto, ')
          ..write('horaSalidaPunto: $horaSalidaPunto, ')
          ..write('horaLlegadaTaller: $horaLlegadaTaller, ')
          ..write('horaRefrigerio: $horaRefrigerio, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RegistrosSectoresLocalTable extends RegistrosSectoresLocal
    with TableInfo<$RegistrosSectoresLocalTable, RegistrosSectoresLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegistrosSectoresLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loteIdErpMeta =
      const VerificationMeta('loteIdErp');
  @override
  late final GeneratedColumn<int> loteIdErp = GeneratedColumn<int>(
      'lote_id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _loteCodigoMeta =
      const VerificationMeta('loteCodigo');
  @override
  late final GeneratedColumn<String> loteCodigo = GeneratedColumn<String>(
      'lote_codigo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _loteNombreMeta =
      const VerificationMeta('loteNombre');
  @override
  late final GeneratedColumn<String> loteNombre = GeneratedColumn<String>(
      'lote_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _fincaNombreMeta =
      const VerificationMeta('fincaNombre');
  @override
  late final GeneratedColumn<String> fincaNombre = GeneratedColumn<String>(
      'finca_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _areaTrabajadaMeta =
      const VerificationMeta('areaTrabajada');
  @override
  late final GeneratedColumn<double> areaTrabajada = GeneratedColumn<double>(
      'area_trabajada', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _observacionMeta =
      const VerificationMeta('observacion');
  @override
  late final GeneratedColumn<String> observacion = GeneratedColumn<String>(
      'observacion', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroId,
        loteIdErp,
        loteCodigo,
        loteNombre,
        fincaNombre,
        areaTrabajada,
        observacion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registros_sectores_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<RegistrosSectoresLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('lote_id_erp')) {
      context.handle(
          _loteIdErpMeta,
          loteIdErp.isAcceptableOrUnknown(
              data['lote_id_erp']!, _loteIdErpMeta));
    } else if (isInserting) {
      context.missing(_loteIdErpMeta);
    }
    if (data.containsKey('lote_codigo')) {
      context.handle(
          _loteCodigoMeta,
          loteCodigo.isAcceptableOrUnknown(
              data['lote_codigo']!, _loteCodigoMeta));
    }
    if (data.containsKey('lote_nombre')) {
      context.handle(
          _loteNombreMeta,
          loteNombre.isAcceptableOrUnknown(
              data['lote_nombre']!, _loteNombreMeta));
    }
    if (data.containsKey('finca_nombre')) {
      context.handle(
          _fincaNombreMeta,
          fincaNombre.isAcceptableOrUnknown(
              data['finca_nombre']!, _fincaNombreMeta));
    }
    if (data.containsKey('area_trabajada')) {
      context.handle(
          _areaTrabajadaMeta,
          areaTrabajada.isAcceptableOrUnknown(
              data['area_trabajada']!, _areaTrabajadaMeta));
    }
    if (data.containsKey('observacion')) {
      context.handle(
          _observacionMeta,
          observacion.isAcceptableOrUnknown(
              data['observacion']!, _observacionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RegistrosSectoresLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegistrosSectoresLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      loteIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lote_id_erp'])!,
      loteCodigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lote_codigo'])!,
      loteNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lote_nombre'])!,
      fincaNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}finca_nombre'])!,
      areaTrabajada: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}area_trabajada']),
      observacion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacion']),
    );
  }

  @override
  $RegistrosSectoresLocalTable createAlias(String alias) {
    return $RegistrosSectoresLocalTable(attachedDatabase, alias);
  }
}

class RegistrosSectoresLocalData extends DataClass
    implements Insertable<RegistrosSectoresLocalData> {
  final String id;
  final String registroId;
  final int loteIdErp;
  final String loteCodigo;
  final String loteNombre;
  final String fincaNombre;
  final double? areaTrabajada;
  final String? observacion;
  const RegistrosSectoresLocalData(
      {required this.id,
      required this.registroId,
      required this.loteIdErp,
      required this.loteCodigo,
      required this.loteNombre,
      required this.fincaNombre,
      this.areaTrabajada,
      this.observacion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    map['lote_id_erp'] = Variable<int>(loteIdErp);
    map['lote_codigo'] = Variable<String>(loteCodigo);
    map['lote_nombre'] = Variable<String>(loteNombre);
    map['finca_nombre'] = Variable<String>(fincaNombre);
    if (!nullToAbsent || areaTrabajada != null) {
      map['area_trabajada'] = Variable<double>(areaTrabajada);
    }
    if (!nullToAbsent || observacion != null) {
      map['observacion'] = Variable<String>(observacion);
    }
    return map;
  }

  RegistrosSectoresLocalCompanion toCompanion(bool nullToAbsent) {
    return RegistrosSectoresLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      loteIdErp: Value(loteIdErp),
      loteCodigo: Value(loteCodigo),
      loteNombre: Value(loteNombre),
      fincaNombre: Value(fincaNombre),
      areaTrabajada: areaTrabajada == null && nullToAbsent
          ? const Value.absent()
          : Value(areaTrabajada),
      observacion: observacion == null && nullToAbsent
          ? const Value.absent()
          : Value(observacion),
    );
  }

  factory RegistrosSectoresLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegistrosSectoresLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      loteIdErp: serializer.fromJson<int>(json['loteIdErp']),
      loteCodigo: serializer.fromJson<String>(json['loteCodigo']),
      loteNombre: serializer.fromJson<String>(json['loteNombre']),
      fincaNombre: serializer.fromJson<String>(json['fincaNombre']),
      areaTrabajada: serializer.fromJson<double?>(json['areaTrabajada']),
      observacion: serializer.fromJson<String?>(json['observacion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'loteIdErp': serializer.toJson<int>(loteIdErp),
      'loteCodigo': serializer.toJson<String>(loteCodigo),
      'loteNombre': serializer.toJson<String>(loteNombre),
      'fincaNombre': serializer.toJson<String>(fincaNombre),
      'areaTrabajada': serializer.toJson<double?>(areaTrabajada),
      'observacion': serializer.toJson<String?>(observacion),
    };
  }

  RegistrosSectoresLocalData copyWith(
          {String? id,
          String? registroId,
          int? loteIdErp,
          String? loteCodigo,
          String? loteNombre,
          String? fincaNombre,
          Value<double?> areaTrabajada = const Value.absent(),
          Value<String?> observacion = const Value.absent()}) =>
      RegistrosSectoresLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        loteIdErp: loteIdErp ?? this.loteIdErp,
        loteCodigo: loteCodigo ?? this.loteCodigo,
        loteNombre: loteNombre ?? this.loteNombre,
        fincaNombre: fincaNombre ?? this.fincaNombre,
        areaTrabajada:
            areaTrabajada.present ? areaTrabajada.value : this.areaTrabajada,
        observacion: observacion.present ? observacion.value : this.observacion,
      );
  RegistrosSectoresLocalData copyWithCompanion(
      RegistrosSectoresLocalCompanion data) {
    return RegistrosSectoresLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      loteIdErp: data.loteIdErp.present ? data.loteIdErp.value : this.loteIdErp,
      loteCodigo:
          data.loteCodigo.present ? data.loteCodigo.value : this.loteCodigo,
      loteNombre:
          data.loteNombre.present ? data.loteNombre.value : this.loteNombre,
      fincaNombre:
          data.fincaNombre.present ? data.fincaNombre.value : this.fincaNombre,
      areaTrabajada: data.areaTrabajada.present
          ? data.areaTrabajada.value
          : this.areaTrabajada,
      observacion:
          data.observacion.present ? data.observacion.value : this.observacion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegistrosSectoresLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('loteIdErp: $loteIdErp, ')
          ..write('loteCodigo: $loteCodigo, ')
          ..write('loteNombre: $loteNombre, ')
          ..write('fincaNombre: $fincaNombre, ')
          ..write('areaTrabajada: $areaTrabajada, ')
          ..write('observacion: $observacion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, registroId, loteIdErp, loteCodigo,
      loteNombre, fincaNombre, areaTrabajada, observacion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegistrosSectoresLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.loteIdErp == this.loteIdErp &&
          other.loteCodigo == this.loteCodigo &&
          other.loteNombre == this.loteNombre &&
          other.fincaNombre == this.fincaNombre &&
          other.areaTrabajada == this.areaTrabajada &&
          other.observacion == this.observacion);
}

class RegistrosSectoresLocalCompanion
    extends UpdateCompanion<RegistrosSectoresLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<int> loteIdErp;
  final Value<String> loteCodigo;
  final Value<String> loteNombre;
  final Value<String> fincaNombre;
  final Value<double?> areaTrabajada;
  final Value<String?> observacion;
  final Value<int> rowid;
  const RegistrosSectoresLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.loteIdErp = const Value.absent(),
    this.loteCodigo = const Value.absent(),
    this.loteNombre = const Value.absent(),
    this.fincaNombre = const Value.absent(),
    this.areaTrabajada = const Value.absent(),
    this.observacion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegistrosSectoresLocalCompanion.insert({
    required String id,
    required String registroId,
    required int loteIdErp,
    this.loteCodigo = const Value.absent(),
    this.loteNombre = const Value.absent(),
    this.fincaNombre = const Value.absent(),
    this.areaTrabajada = const Value.absent(),
    this.observacion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId),
        loteIdErp = Value(loteIdErp);
  static Insertable<RegistrosSectoresLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<int>? loteIdErp,
    Expression<String>? loteCodigo,
    Expression<String>? loteNombre,
    Expression<String>? fincaNombre,
    Expression<double>? areaTrabajada,
    Expression<String>? observacion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (loteIdErp != null) 'lote_id_erp': loteIdErp,
      if (loteCodigo != null) 'lote_codigo': loteCodigo,
      if (loteNombre != null) 'lote_nombre': loteNombre,
      if (fincaNombre != null) 'finca_nombre': fincaNombre,
      if (areaTrabajada != null) 'area_trabajada': areaTrabajada,
      if (observacion != null) 'observacion': observacion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegistrosSectoresLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<int>? loteIdErp,
      Value<String>? loteCodigo,
      Value<String>? loteNombre,
      Value<String>? fincaNombre,
      Value<double?>? areaTrabajada,
      Value<String?>? observacion,
      Value<int>? rowid}) {
    return RegistrosSectoresLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      loteIdErp: loteIdErp ?? this.loteIdErp,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      loteNombre: loteNombre ?? this.loteNombre,
      fincaNombre: fincaNombre ?? this.fincaNombre,
      areaTrabajada: areaTrabajada ?? this.areaTrabajada,
      observacion: observacion ?? this.observacion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (loteIdErp.present) {
      map['lote_id_erp'] = Variable<int>(loteIdErp.value);
    }
    if (loteCodigo.present) {
      map['lote_codigo'] = Variable<String>(loteCodigo.value);
    }
    if (loteNombre.present) {
      map['lote_nombre'] = Variable<String>(loteNombre.value);
    }
    if (fincaNombre.present) {
      map['finca_nombre'] = Variable<String>(fincaNombre.value);
    }
    if (areaTrabajada.present) {
      map['area_trabajada'] = Variable<double>(areaTrabajada.value);
    }
    if (observacion.present) {
      map['observacion'] = Variable<String>(observacion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegistrosSectoresLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('loteIdErp: $loteIdErp, ')
          ..write('loteCodigo: $loteCodigo, ')
          ..write('loteNombre: $loteNombre, ')
          ..write('fincaNombre: $fincaNombre, ')
          ..write('areaTrabajada: $areaTrabajada, ')
          ..write('observacion: $observacion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CosechaBinesLocalTable extends CosechaBinesLocal
    with TableInfo<$CosechaBinesLocalTable, CosechaBinesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CosechaBinesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _franjaHorariaMeta =
      const VerificationMeta('franjaHoraria');
  @override
  late final GeneratedColumn<String> franjaHoraria = GeneratedColumn<String>(
      'franja_horaria', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _turnoMeta = const VerificationMeta('turno');
  @override
  late final GeneratedColumn<String> turno = GeneratedColumn<String>(
      'turno', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cantidadMeta =
      const VerificationMeta('cantidad');
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
      'cantidad', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, registroId, franjaHoraria, turno, cantidad];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cosecha_bines_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<CosechaBinesLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('franja_horaria')) {
      context.handle(
          _franjaHorariaMeta,
          franjaHoraria.isAcceptableOrUnknown(
              data['franja_horaria']!, _franjaHorariaMeta));
    } else if (isInserting) {
      context.missing(_franjaHorariaMeta);
    }
    if (data.containsKey('turno')) {
      context.handle(
          _turnoMeta, turno.isAcceptableOrUnknown(data['turno']!, _turnoMeta));
    } else if (isInserting) {
      context.missing(_turnoMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(_cantidadMeta,
          cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CosechaBinesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CosechaBinesLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      franjaHoraria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}franja_horaria'])!,
      turno: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}turno'])!,
      cantidad: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cantidad'])!,
    );
  }

  @override
  $CosechaBinesLocalTable createAlias(String alias) {
    return $CosechaBinesLocalTable(attachedDatabase, alias);
  }
}

class CosechaBinesLocalData extends DataClass
    implements Insertable<CosechaBinesLocalData> {
  final String id;
  final String registroId;
  final String franjaHoraria;
  final String turno;
  final int cantidad;
  const CosechaBinesLocalData(
      {required this.id,
      required this.registroId,
      required this.franjaHoraria,
      required this.turno,
      required this.cantidad});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    map['franja_horaria'] = Variable<String>(franjaHoraria);
    map['turno'] = Variable<String>(turno);
    map['cantidad'] = Variable<int>(cantidad);
    return map;
  }

  CosechaBinesLocalCompanion toCompanion(bool nullToAbsent) {
    return CosechaBinesLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      franjaHoraria: Value(franjaHoraria),
      turno: Value(turno),
      cantidad: Value(cantidad),
    );
  }

  factory CosechaBinesLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CosechaBinesLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      franjaHoraria: serializer.fromJson<String>(json['franjaHoraria']),
      turno: serializer.fromJson<String>(json['turno']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'franjaHoraria': serializer.toJson<String>(franjaHoraria),
      'turno': serializer.toJson<String>(turno),
      'cantidad': serializer.toJson<int>(cantidad),
    };
  }

  CosechaBinesLocalData copyWith(
          {String? id,
          String? registroId,
          String? franjaHoraria,
          String? turno,
          int? cantidad}) =>
      CosechaBinesLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        franjaHoraria: franjaHoraria ?? this.franjaHoraria,
        turno: turno ?? this.turno,
        cantidad: cantidad ?? this.cantidad,
      );
  CosechaBinesLocalData copyWithCompanion(CosechaBinesLocalCompanion data) {
    return CosechaBinesLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      franjaHoraria: data.franjaHoraria.present
          ? data.franjaHoraria.value
          : this.franjaHoraria,
      turno: data.turno.present ? data.turno.value : this.turno,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CosechaBinesLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('franjaHoraria: $franjaHoraria, ')
          ..write('turno: $turno, ')
          ..write('cantidad: $cantidad')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, registroId, franjaHoraria, turno, cantidad);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CosechaBinesLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.franjaHoraria == this.franjaHoraria &&
          other.turno == this.turno &&
          other.cantidad == this.cantidad);
}

class CosechaBinesLocalCompanion
    extends UpdateCompanion<CosechaBinesLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<String> franjaHoraria;
  final Value<String> turno;
  final Value<int> cantidad;
  final Value<int> rowid;
  const CosechaBinesLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.franjaHoraria = const Value.absent(),
    this.turno = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CosechaBinesLocalCompanion.insert({
    required String id,
    required String registroId,
    required String franjaHoraria,
    required String turno,
    this.cantidad = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId),
        franjaHoraria = Value(franjaHoraria),
        turno = Value(turno);
  static Insertable<CosechaBinesLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<String>? franjaHoraria,
    Expression<String>? turno,
    Expression<int>? cantidad,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (franjaHoraria != null) 'franja_horaria': franjaHoraria,
      if (turno != null) 'turno': turno,
      if (cantidad != null) 'cantidad': cantidad,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CosechaBinesLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<String>? franjaHoraria,
      Value<String>? turno,
      Value<int>? cantidad,
      Value<int>? rowid}) {
    return CosechaBinesLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      franjaHoraria: franjaHoraria ?? this.franjaHoraria,
      turno: turno ?? this.turno,
      cantidad: cantidad ?? this.cantidad,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (franjaHoraria.present) {
      map['franja_horaria'] = Variable<String>(franjaHoraria.value);
    }
    if (turno.present) {
      map['turno'] = Variable<String>(turno.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CosechaBinesLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('franjaHoraria: $franjaHoraria, ')
          ..write('turno: $turno, ')
          ..write('cantidad: $cantidad, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParosEquiposLocalTable extends ParosEquiposLocal
    with TableInfo<$ParosEquiposLocalTable, ParosEquiposLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParosEquiposLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tipoParoIdMeta =
      const VerificationMeta('tipoParoId');
  @override
  late final GeneratedColumn<int> tipoParoId = GeneratedColumn<int>(
      'tipo_paro_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tipoParoCodigoMeta =
      const VerificationMeta('tipoParoCodigo');
  @override
  late final GeneratedColumn<String> tipoParoCodigo = GeneratedColumn<String>(
      'tipo_paro_codigo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tipoParoNombreMeta =
      const VerificationMeta('tipoParoNombre');
  @override
  late final GeneratedColumn<String> tipoParoNombre = GeneratedColumn<String>(
      'tipo_paro_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
      'motivo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _equipoMeta = const VerificationMeta('equipo');
  @override
  late final GeneratedColumn<String> equipo = GeneratedColumn<String>(
      'equipo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaInicioMeta =
      const VerificationMeta('horaInicio');
  @override
  late final GeneratedColumn<String> horaInicio = GeneratedColumn<String>(
      'hora_inicio', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _horaFinalMeta =
      const VerificationMeta('horaFinal');
  @override
  late final GeneratedColumn<String> horaFinal = GeneratedColumn<String>(
      'hora_final', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _galonesMeta =
      const VerificationMeta('galones');
  @override
  late final GeneratedColumn<double> galones = GeneratedColumn<double>(
      'galones', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroId,
        tipoParoId,
        tipoParoCodigo,
        tipoParoNombre,
        motivo,
        equipo,
        horaInicio,
        horaFinal,
        galones,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paros_equipos_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<ParosEquiposLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('tipo_paro_id')) {
      context.handle(
          _tipoParoIdMeta,
          tipoParoId.isAcceptableOrUnknown(
              data['tipo_paro_id']!, _tipoParoIdMeta));
    } else if (isInserting) {
      context.missing(_tipoParoIdMeta);
    }
    if (data.containsKey('tipo_paro_codigo')) {
      context.handle(
          _tipoParoCodigoMeta,
          tipoParoCodigo.isAcceptableOrUnknown(
              data['tipo_paro_codigo']!, _tipoParoCodigoMeta));
    }
    if (data.containsKey('tipo_paro_nombre')) {
      context.handle(
          _tipoParoNombreMeta,
          tipoParoNombre.isAcceptableOrUnknown(
              data['tipo_paro_nombre']!, _tipoParoNombreMeta));
    }
    if (data.containsKey('motivo')) {
      context.handle(_motivoMeta,
          motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta));
    }
    if (data.containsKey('equipo')) {
      context.handle(_equipoMeta,
          equipo.isAcceptableOrUnknown(data['equipo']!, _equipoMeta));
    }
    if (data.containsKey('hora_inicio')) {
      context.handle(
          _horaInicioMeta,
          horaInicio.isAcceptableOrUnknown(
              data['hora_inicio']!, _horaInicioMeta));
    } else if (isInserting) {
      context.missing(_horaInicioMeta);
    }
    if (data.containsKey('hora_final')) {
      context.handle(_horaFinalMeta,
          horaFinal.isAcceptableOrUnknown(data['hora_final']!, _horaFinalMeta));
    }
    if (data.containsKey('galones')) {
      context.handle(_galonesMeta,
          galones.isAcceptableOrUnknown(data['galones']!, _galonesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParosEquiposLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParosEquiposLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      tipoParoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tipo_paro_id'])!,
      tipoParoCodigo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tipo_paro_codigo'])!,
      tipoParoNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tipo_paro_nombre'])!,
      motivo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motivo']),
      equipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipo']),
      horaInicio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hora_inicio'])!,
      horaFinal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hora_final']),
      galones: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}galones']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ParosEquiposLocalTable createAlias(String alias) {
    return $ParosEquiposLocalTable(attachedDatabase, alias);
  }
}

class ParosEquiposLocalData extends DataClass
    implements Insertable<ParosEquiposLocalData> {
  final String id;
  final String registroId;
  final int tipoParoId;
  final String tipoParoCodigo;
  final String tipoParoNombre;
  final String? motivo;
  final String? equipo;
  final String horaInicio;
  final String? horaFinal;
  final double? galones;
  final DateTime createdAt;
  const ParosEquiposLocalData(
      {required this.id,
      required this.registroId,
      required this.tipoParoId,
      required this.tipoParoCodigo,
      required this.tipoParoNombre,
      this.motivo,
      this.equipo,
      required this.horaInicio,
      this.horaFinal,
      this.galones,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    map['tipo_paro_id'] = Variable<int>(tipoParoId);
    map['tipo_paro_codigo'] = Variable<String>(tipoParoCodigo);
    map['tipo_paro_nombre'] = Variable<String>(tipoParoNombre);
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(motivo);
    }
    if (!nullToAbsent || equipo != null) {
      map['equipo'] = Variable<String>(equipo);
    }
    map['hora_inicio'] = Variable<String>(horaInicio);
    if (!nullToAbsent || horaFinal != null) {
      map['hora_final'] = Variable<String>(horaFinal);
    }
    if (!nullToAbsent || galones != null) {
      map['galones'] = Variable<double>(galones);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ParosEquiposLocalCompanion toCompanion(bool nullToAbsent) {
    return ParosEquiposLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      tipoParoId: Value(tipoParoId),
      tipoParoCodigo: Value(tipoParoCodigo),
      tipoParoNombre: Value(tipoParoNombre),
      motivo:
          motivo == null && nullToAbsent ? const Value.absent() : Value(motivo),
      equipo:
          equipo == null && nullToAbsent ? const Value.absent() : Value(equipo),
      horaInicio: Value(horaInicio),
      horaFinal: horaFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(horaFinal),
      galones: galones == null && nullToAbsent
          ? const Value.absent()
          : Value(galones),
      createdAt: Value(createdAt),
    );
  }

  factory ParosEquiposLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParosEquiposLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      tipoParoId: serializer.fromJson<int>(json['tipoParoId']),
      tipoParoCodigo: serializer.fromJson<String>(json['tipoParoCodigo']),
      tipoParoNombre: serializer.fromJson<String>(json['tipoParoNombre']),
      motivo: serializer.fromJson<String?>(json['motivo']),
      equipo: serializer.fromJson<String?>(json['equipo']),
      horaInicio: serializer.fromJson<String>(json['horaInicio']),
      horaFinal: serializer.fromJson<String?>(json['horaFinal']),
      galones: serializer.fromJson<double?>(json['galones']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'tipoParoId': serializer.toJson<int>(tipoParoId),
      'tipoParoCodigo': serializer.toJson<String>(tipoParoCodigo),
      'tipoParoNombre': serializer.toJson<String>(tipoParoNombre),
      'motivo': serializer.toJson<String?>(motivo),
      'equipo': serializer.toJson<String?>(equipo),
      'horaInicio': serializer.toJson<String>(horaInicio),
      'horaFinal': serializer.toJson<String?>(horaFinal),
      'galones': serializer.toJson<double?>(galones),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ParosEquiposLocalData copyWith(
          {String? id,
          String? registroId,
          int? tipoParoId,
          String? tipoParoCodigo,
          String? tipoParoNombre,
          Value<String?> motivo = const Value.absent(),
          Value<String?> equipo = const Value.absent(),
          String? horaInicio,
          Value<String?> horaFinal = const Value.absent(),
          Value<double?> galones = const Value.absent(),
          DateTime? createdAt}) =>
      ParosEquiposLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        tipoParoId: tipoParoId ?? this.tipoParoId,
        tipoParoCodigo: tipoParoCodigo ?? this.tipoParoCodigo,
        tipoParoNombre: tipoParoNombre ?? this.tipoParoNombre,
        motivo: motivo.present ? motivo.value : this.motivo,
        equipo: equipo.present ? equipo.value : this.equipo,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFinal: horaFinal.present ? horaFinal.value : this.horaFinal,
        galones: galones.present ? galones.value : this.galones,
        createdAt: createdAt ?? this.createdAt,
      );
  ParosEquiposLocalData copyWithCompanion(ParosEquiposLocalCompanion data) {
    return ParosEquiposLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      tipoParoId:
          data.tipoParoId.present ? data.tipoParoId.value : this.tipoParoId,
      tipoParoCodigo: data.tipoParoCodigo.present
          ? data.tipoParoCodigo.value
          : this.tipoParoCodigo,
      tipoParoNombre: data.tipoParoNombre.present
          ? data.tipoParoNombre.value
          : this.tipoParoNombre,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      equipo: data.equipo.present ? data.equipo.value : this.equipo,
      horaInicio:
          data.horaInicio.present ? data.horaInicio.value : this.horaInicio,
      horaFinal: data.horaFinal.present ? data.horaFinal.value : this.horaFinal,
      galones: data.galones.present ? data.galones.value : this.galones,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParosEquiposLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('tipoParoId: $tipoParoId, ')
          ..write('tipoParoCodigo: $tipoParoCodigo, ')
          ..write('tipoParoNombre: $tipoParoNombre, ')
          ..write('motivo: $motivo, ')
          ..write('equipo: $equipo, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFinal: $horaFinal, ')
          ..write('galones: $galones, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      registroId,
      tipoParoId,
      tipoParoCodigo,
      tipoParoNombre,
      motivo,
      equipo,
      horaInicio,
      horaFinal,
      galones,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParosEquiposLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.tipoParoId == this.tipoParoId &&
          other.tipoParoCodigo == this.tipoParoCodigo &&
          other.tipoParoNombre == this.tipoParoNombre &&
          other.motivo == this.motivo &&
          other.equipo == this.equipo &&
          other.horaInicio == this.horaInicio &&
          other.horaFinal == this.horaFinal &&
          other.galones == this.galones &&
          other.createdAt == this.createdAt);
}

class ParosEquiposLocalCompanion
    extends UpdateCompanion<ParosEquiposLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<int> tipoParoId;
  final Value<String> tipoParoCodigo;
  final Value<String> tipoParoNombre;
  final Value<String?> motivo;
  final Value<String?> equipo;
  final Value<String> horaInicio;
  final Value<String?> horaFinal;
  final Value<double?> galones;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ParosEquiposLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.tipoParoId = const Value.absent(),
    this.tipoParoCodigo = const Value.absent(),
    this.tipoParoNombre = const Value.absent(),
    this.motivo = const Value.absent(),
    this.equipo = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFinal = const Value.absent(),
    this.galones = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParosEquiposLocalCompanion.insert({
    required String id,
    required String registroId,
    required int tipoParoId,
    this.tipoParoCodigo = const Value.absent(),
    this.tipoParoNombre = const Value.absent(),
    this.motivo = const Value.absent(),
    this.equipo = const Value.absent(),
    required String horaInicio,
    this.horaFinal = const Value.absent(),
    this.galones = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId),
        tipoParoId = Value(tipoParoId),
        horaInicio = Value(horaInicio);
  static Insertable<ParosEquiposLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<int>? tipoParoId,
    Expression<String>? tipoParoCodigo,
    Expression<String>? tipoParoNombre,
    Expression<String>? motivo,
    Expression<String>? equipo,
    Expression<String>? horaInicio,
    Expression<String>? horaFinal,
    Expression<double>? galones,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (tipoParoId != null) 'tipo_paro_id': tipoParoId,
      if (tipoParoCodigo != null) 'tipo_paro_codigo': tipoParoCodigo,
      if (tipoParoNombre != null) 'tipo_paro_nombre': tipoParoNombre,
      if (motivo != null) 'motivo': motivo,
      if (equipo != null) 'equipo': equipo,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFinal != null) 'hora_final': horaFinal,
      if (galones != null) 'galones': galones,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParosEquiposLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<int>? tipoParoId,
      Value<String>? tipoParoCodigo,
      Value<String>? tipoParoNombre,
      Value<String?>? motivo,
      Value<String?>? equipo,
      Value<String>? horaInicio,
      Value<String?>? horaFinal,
      Value<double?>? galones,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ParosEquiposLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      tipoParoId: tipoParoId ?? this.tipoParoId,
      tipoParoCodigo: tipoParoCodigo ?? this.tipoParoCodigo,
      tipoParoNombre: tipoParoNombre ?? this.tipoParoNombre,
      motivo: motivo ?? this.motivo,
      equipo: equipo ?? this.equipo,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFinal: horaFinal ?? this.horaFinal,
      galones: galones ?? this.galones,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (tipoParoId.present) {
      map['tipo_paro_id'] = Variable<int>(tipoParoId.value);
    }
    if (tipoParoCodigo.present) {
      map['tipo_paro_codigo'] = Variable<String>(tipoParoCodigo.value);
    }
    if (tipoParoNombre.present) {
      map['tipo_paro_nombre'] = Variable<String>(tipoParoNombre.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (equipo.present) {
      map['equipo'] = Variable<String>(equipo.value);
    }
    if (horaInicio.present) {
      map['hora_inicio'] = Variable<String>(horaInicio.value);
    }
    if (horaFinal.present) {
      map['hora_final'] = Variable<String>(horaFinal.value);
    }
    if (galones.present) {
      map['galones'] = Variable<double>(galones.value);
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
    return (StringBuffer('ParosEquiposLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('tipoParoId: $tipoParoId, ')
          ..write('tipoParoCodigo: $tipoParoCodigo, ')
          ..write('tipoParoNombre: $tipoParoNombre, ')
          ..write('motivo: $motivo, ')
          ..write('equipo: $equipo, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFinal: $horaFinal, ')
          ..write('galones: $galones, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistResultadosLocalTable extends ChecklistResultadosLocal
    with
        TableInfo<$ChecklistResultadosLocalTable,
            ChecklistResultadosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistResultadosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemNombreMeta =
      const VerificationMeta('itemNombre');
  @override
  late final GeneratedColumn<String> itemNombre = GeneratedColumn<String>(
      'item_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoriaNombreMeta =
      const VerificationMeta('categoriaNombre');
  @override
  late final GeneratedColumn<String> categoriaNombre = GeneratedColumn<String>(
      'categoria_nombre', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _resultadoMeta =
      const VerificationMeta('resultado');
  @override
  late final GeneratedColumn<String> resultado = GeneratedColumn<String>(
      'resultado', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _observacionMeta =
      const VerificationMeta('observacion');
  @override
  late final GeneratedColumn<String> observacion = GeneratedColumn<String>(
      'observacion', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fotoUrlMeta =
      const VerificationMeta('fotoUrl');
  @override
  late final GeneratedColumn<String> fotoUrl = GeneratedColumn<String>(
      'foto_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroId,
        itemId,
        itemNombre,
        categoriaNombre,
        resultado,
        observacion,
        fotoUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_resultados_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<ChecklistResultadosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_nombre')) {
      context.handle(
          _itemNombreMeta,
          itemNombre.isAcceptableOrUnknown(
              data['item_nombre']!, _itemNombreMeta));
    }
    if (data.containsKey('categoria_nombre')) {
      context.handle(
          _categoriaNombreMeta,
          categoriaNombre.isAcceptableOrUnknown(
              data['categoria_nombre']!, _categoriaNombreMeta));
    }
    if (data.containsKey('resultado')) {
      context.handle(_resultadoMeta,
          resultado.isAcceptableOrUnknown(data['resultado']!, _resultadoMeta));
    } else if (isInserting) {
      context.missing(_resultadoMeta);
    }
    if (data.containsKey('observacion')) {
      context.handle(
          _observacionMeta,
          observacion.isAcceptableOrUnknown(
              data['observacion']!, _observacionMeta));
    }
    if (data.containsKey('foto_url')) {
      context.handle(_fotoUrlMeta,
          fotoUrl.isAcceptableOrUnknown(data['foto_url']!, _fotoUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistResultadosLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistResultadosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      itemNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_nombre'])!,
      categoriaNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}categoria_nombre'])!,
      resultado: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resultado'])!,
      observacion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacion']),
      fotoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foto_url']),
    );
  }

  @override
  $ChecklistResultadosLocalTable createAlias(String alias) {
    return $ChecklistResultadosLocalTable(attachedDatabase, alias);
  }
}

class ChecklistResultadosLocalData extends DataClass
    implements Insertable<ChecklistResultadosLocalData> {
  final String id;
  final String registroId;
  final int itemId;
  final String itemNombre;
  final String categoriaNombre;

  /// 'bien' | 'mal' | 'na'
  final String resultado;
  final String? observacion;
  final String? fotoUrl;
  const ChecklistResultadosLocalData(
      {required this.id,
      required this.registroId,
      required this.itemId,
      required this.itemNombre,
      required this.categoriaNombre,
      required this.resultado,
      this.observacion,
      this.fotoUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    map['item_id'] = Variable<int>(itemId);
    map['item_nombre'] = Variable<String>(itemNombre);
    map['categoria_nombre'] = Variable<String>(categoriaNombre);
    map['resultado'] = Variable<String>(resultado);
    if (!nullToAbsent || observacion != null) {
      map['observacion'] = Variable<String>(observacion);
    }
    if (!nullToAbsent || fotoUrl != null) {
      map['foto_url'] = Variable<String>(fotoUrl);
    }
    return map;
  }

  ChecklistResultadosLocalCompanion toCompanion(bool nullToAbsent) {
    return ChecklistResultadosLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      itemId: Value(itemId),
      itemNombre: Value(itemNombre),
      categoriaNombre: Value(categoriaNombre),
      resultado: Value(resultado),
      observacion: observacion == null && nullToAbsent
          ? const Value.absent()
          : Value(observacion),
      fotoUrl: fotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoUrl),
    );
  }

  factory ChecklistResultadosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistResultadosLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      itemNombre: serializer.fromJson<String>(json['itemNombre']),
      categoriaNombre: serializer.fromJson<String>(json['categoriaNombre']),
      resultado: serializer.fromJson<String>(json['resultado']),
      observacion: serializer.fromJson<String?>(json['observacion']),
      fotoUrl: serializer.fromJson<String?>(json['fotoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'itemId': serializer.toJson<int>(itemId),
      'itemNombre': serializer.toJson<String>(itemNombre),
      'categoriaNombre': serializer.toJson<String>(categoriaNombre),
      'resultado': serializer.toJson<String>(resultado),
      'observacion': serializer.toJson<String?>(observacion),
      'fotoUrl': serializer.toJson<String?>(fotoUrl),
    };
  }

  ChecklistResultadosLocalData copyWith(
          {String? id,
          String? registroId,
          int? itemId,
          String? itemNombre,
          String? categoriaNombre,
          String? resultado,
          Value<String?> observacion = const Value.absent(),
          Value<String?> fotoUrl = const Value.absent()}) =>
      ChecklistResultadosLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        itemId: itemId ?? this.itemId,
        itemNombre: itemNombre ?? this.itemNombre,
        categoriaNombre: categoriaNombre ?? this.categoriaNombre,
        resultado: resultado ?? this.resultado,
        observacion: observacion.present ? observacion.value : this.observacion,
        fotoUrl: fotoUrl.present ? fotoUrl.value : this.fotoUrl,
      );
  ChecklistResultadosLocalData copyWithCompanion(
      ChecklistResultadosLocalCompanion data) {
    return ChecklistResultadosLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemNombre:
          data.itemNombre.present ? data.itemNombre.value : this.itemNombre,
      categoriaNombre: data.categoriaNombre.present
          ? data.categoriaNombre.value
          : this.categoriaNombre,
      resultado: data.resultado.present ? data.resultado.value : this.resultado,
      observacion:
          data.observacion.present ? data.observacion.value : this.observacion,
      fotoUrl: data.fotoUrl.present ? data.fotoUrl.value : this.fotoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistResultadosLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('itemId: $itemId, ')
          ..write('itemNombre: $itemNombre, ')
          ..write('categoriaNombre: $categoriaNombre, ')
          ..write('resultado: $resultado, ')
          ..write('observacion: $observacion, ')
          ..write('fotoUrl: $fotoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, registroId, itemId, itemNombre,
      categoriaNombre, resultado, observacion, fotoUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistResultadosLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.itemId == this.itemId &&
          other.itemNombre == this.itemNombre &&
          other.categoriaNombre == this.categoriaNombre &&
          other.resultado == this.resultado &&
          other.observacion == this.observacion &&
          other.fotoUrl == this.fotoUrl);
}

class ChecklistResultadosLocalCompanion
    extends UpdateCompanion<ChecklistResultadosLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<int> itemId;
  final Value<String> itemNombre;
  final Value<String> categoriaNombre;
  final Value<String> resultado;
  final Value<String?> observacion;
  final Value<String?> fotoUrl;
  final Value<int> rowid;
  const ChecklistResultadosLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemNombre = const Value.absent(),
    this.categoriaNombre = const Value.absent(),
    this.resultado = const Value.absent(),
    this.observacion = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistResultadosLocalCompanion.insert({
    required String id,
    required String registroId,
    required int itemId,
    this.itemNombre = const Value.absent(),
    this.categoriaNombre = const Value.absent(),
    required String resultado,
    this.observacion = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId),
        itemId = Value(itemId),
        resultado = Value(resultado);
  static Insertable<ChecklistResultadosLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<int>? itemId,
    Expression<String>? itemNombre,
    Expression<String>? categoriaNombre,
    Expression<String>? resultado,
    Expression<String>? observacion,
    Expression<String>? fotoUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (itemId != null) 'item_id': itemId,
      if (itemNombre != null) 'item_nombre': itemNombre,
      if (categoriaNombre != null) 'categoria_nombre': categoriaNombre,
      if (resultado != null) 'resultado': resultado,
      if (observacion != null) 'observacion': observacion,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistResultadosLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<int>? itemId,
      Value<String>? itemNombre,
      Value<String>? categoriaNombre,
      Value<String>? resultado,
      Value<String?>? observacion,
      Value<String?>? fotoUrl,
      Value<int>? rowid}) {
    return ChecklistResultadosLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      itemId: itemId ?? this.itemId,
      itemNombre: itemNombre ?? this.itemNombre,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      resultado: resultado ?? this.resultado,
      observacion: observacion ?? this.observacion,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (itemNombre.present) {
      map['item_nombre'] = Variable<String>(itemNombre.value);
    }
    if (categoriaNombre.present) {
      map['categoria_nombre'] = Variable<String>(categoriaNombre.value);
    }
    if (resultado.present) {
      map['resultado'] = Variable<String>(resultado.value);
    }
    if (observacion.present) {
      map['observacion'] = Variable<String>(observacion.value);
    }
    if (fotoUrl.present) {
      map['foto_url'] = Variable<String>(fotoUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistResultadosLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('itemId: $itemId, ')
          ..write('itemNombre: $itemNombre, ')
          ..write('categoriaNombre: $categoriaNombre, ')
          ..write('resultado: $resultado, ')
          ..write('observacion: $observacion, ')
          ..write('fotoUrl: $fotoUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RegistrosVehiculoLocalTable extends RegistrosVehiculoLocal
    with TableInfo<$RegistrosVehiculoLocalTable, RegistrosVehiculoLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegistrosVehiculoLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kmCamionInicioMeta =
      const VerificationMeta('kmCamionInicio');
  @override
  late final GeneratedColumn<double> kmCamionInicio = GeneratedColumn<double>(
      'km_camion_inicio', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _kmCamionFinalMeta =
      const VerificationMeta('kmCamionFinal');
  @override
  late final GeneratedColumn<double> kmCamionFinal = GeneratedColumn<double>(
      'km_camion_final', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _kmImplementoInicioMeta =
      const VerificationMeta('kmImplementoInicio');
  @override
  late final GeneratedColumn<double> kmImplementoInicio =
      GeneratedColumn<double>('km_implemento_inicio', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _kmImplementoFinalMeta =
      const VerificationMeta('kmImplementoFinal');
  @override
  late final GeneratedColumn<double> kmImplementoFinal =
      GeneratedColumn<double>('km_implemento_final', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _horaSalidaBaseTdMeta =
      const VerificationMeta('horaSalidaBaseTd');
  @override
  late final GeneratedColumn<String> horaSalidaBaseTd = GeneratedColumn<String>(
      'hora_salida_base_td', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaLlegadaZonaMeta =
      const VerificationMeta('horaLlegadaZona');
  @override
  late final GeneratedColumn<String> horaLlegadaZona = GeneratedColumn<String>(
      'hora_llegada_zona', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaRetornoBaseMeta =
      const VerificationMeta('horaRetornoBase');
  @override
  late final GeneratedColumn<String> horaRetornoBase = GeneratedColumn<String>(
      'hora_retorno_base', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaLlegadaTallerMeta =
      const VerificationMeta('horaLlegadaTaller');
  @override
  late final GeneratedColumn<String> horaLlegadaTaller =
      GeneratedColumn<String>('hora_llegada_taller', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaRefrigerioMeta =
      const VerificationMeta('horaRefrigerio');
  @override
  late final GeneratedColumn<String> horaRefrigerio = GeneratedColumn<String>(
      'hora_refrigerio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cantidadTancadasMeta =
      const VerificationMeta('cantidadTancadas');
  @override
  late final GeneratedColumn<int> cantidadTancadas = GeneratedColumn<int>(
      'cantidad_tancadas', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _observacionesMaqMeta =
      const VerificationMeta('observacionesMaq');
  @override
  late final GeneratedColumn<String> observacionesMaq = GeneratedColumn<String>(
      'observaciones_maq', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sincronizadoMeta =
      const VerificationMeta('sincronizado');
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
      'sincronizado', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sincronizado" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        registroId,
        kmCamionInicio,
        kmCamionFinal,
        kmImplementoInicio,
        kmImplementoFinal,
        horaSalidaBaseTd,
        horaLlegadaZona,
        horaRetornoBase,
        horaLlegadaTaller,
        horaRefrigerio,
        cantidadTancadas,
        observacionesMaq,
        sincronizado,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registros_vehiculo_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<RegistrosVehiculoLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('km_camion_inicio')) {
      context.handle(
          _kmCamionInicioMeta,
          kmCamionInicio.isAcceptableOrUnknown(
              data['km_camion_inicio']!, _kmCamionInicioMeta));
    }
    if (data.containsKey('km_camion_final')) {
      context.handle(
          _kmCamionFinalMeta,
          kmCamionFinal.isAcceptableOrUnknown(
              data['km_camion_final']!, _kmCamionFinalMeta));
    }
    if (data.containsKey('km_implemento_inicio')) {
      context.handle(
          _kmImplementoInicioMeta,
          kmImplementoInicio.isAcceptableOrUnknown(
              data['km_implemento_inicio']!, _kmImplementoInicioMeta));
    }
    if (data.containsKey('km_implemento_final')) {
      context.handle(
          _kmImplementoFinalMeta,
          kmImplementoFinal.isAcceptableOrUnknown(
              data['km_implemento_final']!, _kmImplementoFinalMeta));
    }
    if (data.containsKey('hora_salida_base_td')) {
      context.handle(
          _horaSalidaBaseTdMeta,
          horaSalidaBaseTd.isAcceptableOrUnknown(
              data['hora_salida_base_td']!, _horaSalidaBaseTdMeta));
    }
    if (data.containsKey('hora_llegada_zona')) {
      context.handle(
          _horaLlegadaZonaMeta,
          horaLlegadaZona.isAcceptableOrUnknown(
              data['hora_llegada_zona']!, _horaLlegadaZonaMeta));
    }
    if (data.containsKey('hora_retorno_base')) {
      context.handle(
          _horaRetornoBaseMeta,
          horaRetornoBase.isAcceptableOrUnknown(
              data['hora_retorno_base']!, _horaRetornoBaseMeta));
    }
    if (data.containsKey('hora_llegada_taller')) {
      context.handle(
          _horaLlegadaTallerMeta,
          horaLlegadaTaller.isAcceptableOrUnknown(
              data['hora_llegada_taller']!, _horaLlegadaTallerMeta));
    }
    if (data.containsKey('hora_refrigerio')) {
      context.handle(
          _horaRefrigerioMeta,
          horaRefrigerio.isAcceptableOrUnknown(
              data['hora_refrigerio']!, _horaRefrigerioMeta));
    }
    if (data.containsKey('cantidad_tancadas')) {
      context.handle(
          _cantidadTancadasMeta,
          cantidadTancadas.isAcceptableOrUnknown(
              data['cantidad_tancadas']!, _cantidadTancadasMeta));
    }
    if (data.containsKey('observaciones_maq')) {
      context.handle(
          _observacionesMaqMeta,
          observacionesMaq.isAcceptableOrUnknown(
              data['observaciones_maq']!, _observacionesMaqMeta));
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
          _sincronizadoMeta,
          sincronizado.isAcceptableOrUnknown(
              data['sincronizado']!, _sincronizadoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RegistrosVehiculoLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegistrosVehiculoLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      kmCamionInicio: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}km_camion_inicio']),
      kmCamionFinal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}km_camion_final']),
      kmImplementoInicio: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}km_implemento_inicio']),
      kmImplementoFinal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}km_implemento_final']),
      horaSalidaBaseTd: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_salida_base_td']),
      horaLlegadaZona: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_llegada_zona']),
      horaRetornoBase: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_retorno_base']),
      horaLlegadaTaller: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hora_llegada_taller']),
      horaRefrigerio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hora_refrigerio']),
      cantidadTancadas: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cantidad_tancadas']),
      observacionesMaq: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}observaciones_maq']),
      sincronizado: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sincronizado'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RegistrosVehiculoLocalTable createAlias(String alias) {
    return $RegistrosVehiculoLocalTable(attachedDatabase, alias);
  }
}

class RegistrosVehiculoLocalData extends DataClass
    implements Insertable<RegistrosVehiculoLocalData> {
  final String id;
  final String registroId;
  final double? kmCamionInicio;
  final double? kmCamionFinal;
  final double? kmImplementoInicio;
  final double? kmImplementoFinal;
  final String? horaSalidaBaseTd;
  final String? horaLlegadaZona;
  final String? horaRetornoBase;
  final String? horaLlegadaTaller;
  final String? horaRefrigerio;
  final int? cantidadTancadas;
  final String? observacionesMaq;
  final bool sincronizado;
  final DateTime createdAt;
  const RegistrosVehiculoLocalData(
      {required this.id,
      required this.registroId,
      this.kmCamionInicio,
      this.kmCamionFinal,
      this.kmImplementoInicio,
      this.kmImplementoFinal,
      this.horaSalidaBaseTd,
      this.horaLlegadaZona,
      this.horaRetornoBase,
      this.horaLlegadaTaller,
      this.horaRefrigerio,
      this.cantidadTancadas,
      this.observacionesMaq,
      required this.sincronizado,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    if (!nullToAbsent || kmCamionInicio != null) {
      map['km_camion_inicio'] = Variable<double>(kmCamionInicio);
    }
    if (!nullToAbsent || kmCamionFinal != null) {
      map['km_camion_final'] = Variable<double>(kmCamionFinal);
    }
    if (!nullToAbsent || kmImplementoInicio != null) {
      map['km_implemento_inicio'] = Variable<double>(kmImplementoInicio);
    }
    if (!nullToAbsent || kmImplementoFinal != null) {
      map['km_implemento_final'] = Variable<double>(kmImplementoFinal);
    }
    if (!nullToAbsent || horaSalidaBaseTd != null) {
      map['hora_salida_base_td'] = Variable<String>(horaSalidaBaseTd);
    }
    if (!nullToAbsent || horaLlegadaZona != null) {
      map['hora_llegada_zona'] = Variable<String>(horaLlegadaZona);
    }
    if (!nullToAbsent || horaRetornoBase != null) {
      map['hora_retorno_base'] = Variable<String>(horaRetornoBase);
    }
    if (!nullToAbsent || horaLlegadaTaller != null) {
      map['hora_llegada_taller'] = Variable<String>(horaLlegadaTaller);
    }
    if (!nullToAbsent || horaRefrigerio != null) {
      map['hora_refrigerio'] = Variable<String>(horaRefrigerio);
    }
    if (!nullToAbsent || cantidadTancadas != null) {
      map['cantidad_tancadas'] = Variable<int>(cantidadTancadas);
    }
    if (!nullToAbsent || observacionesMaq != null) {
      map['observaciones_maq'] = Variable<String>(observacionesMaq);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RegistrosVehiculoLocalCompanion toCompanion(bool nullToAbsent) {
    return RegistrosVehiculoLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      kmCamionInicio: kmCamionInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(kmCamionInicio),
      kmCamionFinal: kmCamionFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(kmCamionFinal),
      kmImplementoInicio: kmImplementoInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(kmImplementoInicio),
      kmImplementoFinal: kmImplementoFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(kmImplementoFinal),
      horaSalidaBaseTd: horaSalidaBaseTd == null && nullToAbsent
          ? const Value.absent()
          : Value(horaSalidaBaseTd),
      horaLlegadaZona: horaLlegadaZona == null && nullToAbsent
          ? const Value.absent()
          : Value(horaLlegadaZona),
      horaRetornoBase: horaRetornoBase == null && nullToAbsent
          ? const Value.absent()
          : Value(horaRetornoBase),
      horaLlegadaTaller: horaLlegadaTaller == null && nullToAbsent
          ? const Value.absent()
          : Value(horaLlegadaTaller),
      horaRefrigerio: horaRefrigerio == null && nullToAbsent
          ? const Value.absent()
          : Value(horaRefrigerio),
      cantidadTancadas: cantidadTancadas == null && nullToAbsent
          ? const Value.absent()
          : Value(cantidadTancadas),
      observacionesMaq: observacionesMaq == null && nullToAbsent
          ? const Value.absent()
          : Value(observacionesMaq),
      sincronizado: Value(sincronizado),
      createdAt: Value(createdAt),
    );
  }

  factory RegistrosVehiculoLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegistrosVehiculoLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      kmCamionInicio: serializer.fromJson<double?>(json['kmCamionInicio']),
      kmCamionFinal: serializer.fromJson<double?>(json['kmCamionFinal']),
      kmImplementoInicio:
          serializer.fromJson<double?>(json['kmImplementoInicio']),
      kmImplementoFinal:
          serializer.fromJson<double?>(json['kmImplementoFinal']),
      horaSalidaBaseTd: serializer.fromJson<String?>(json['horaSalidaBaseTd']),
      horaLlegadaZona: serializer.fromJson<String?>(json['horaLlegadaZona']),
      horaRetornoBase: serializer.fromJson<String?>(json['horaRetornoBase']),
      horaLlegadaTaller:
          serializer.fromJson<String?>(json['horaLlegadaTaller']),
      horaRefrigerio: serializer.fromJson<String?>(json['horaRefrigerio']),
      cantidadTancadas: serializer.fromJson<int?>(json['cantidadTancadas']),
      observacionesMaq: serializer.fromJson<String?>(json['observacionesMaq']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'kmCamionInicio': serializer.toJson<double?>(kmCamionInicio),
      'kmCamionFinal': serializer.toJson<double?>(kmCamionFinal),
      'kmImplementoInicio': serializer.toJson<double?>(kmImplementoInicio),
      'kmImplementoFinal': serializer.toJson<double?>(kmImplementoFinal),
      'horaSalidaBaseTd': serializer.toJson<String?>(horaSalidaBaseTd),
      'horaLlegadaZona': serializer.toJson<String?>(horaLlegadaZona),
      'horaRetornoBase': serializer.toJson<String?>(horaRetornoBase),
      'horaLlegadaTaller': serializer.toJson<String?>(horaLlegadaTaller),
      'horaRefrigerio': serializer.toJson<String?>(horaRefrigerio),
      'cantidadTancadas': serializer.toJson<int?>(cantidadTancadas),
      'observacionesMaq': serializer.toJson<String?>(observacionesMaq),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RegistrosVehiculoLocalData copyWith(
          {String? id,
          String? registroId,
          Value<double?> kmCamionInicio = const Value.absent(),
          Value<double?> kmCamionFinal = const Value.absent(),
          Value<double?> kmImplementoInicio = const Value.absent(),
          Value<double?> kmImplementoFinal = const Value.absent(),
          Value<String?> horaSalidaBaseTd = const Value.absent(),
          Value<String?> horaLlegadaZona = const Value.absent(),
          Value<String?> horaRetornoBase = const Value.absent(),
          Value<String?> horaLlegadaTaller = const Value.absent(),
          Value<String?> horaRefrigerio = const Value.absent(),
          Value<int?> cantidadTancadas = const Value.absent(),
          Value<String?> observacionesMaq = const Value.absent(),
          bool? sincronizado,
          DateTime? createdAt}) =>
      RegistrosVehiculoLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        kmCamionInicio:
            kmCamionInicio.present ? kmCamionInicio.value : this.kmCamionInicio,
        kmCamionFinal:
            kmCamionFinal.present ? kmCamionFinal.value : this.kmCamionFinal,
        kmImplementoInicio: kmImplementoInicio.present
            ? kmImplementoInicio.value
            : this.kmImplementoInicio,
        kmImplementoFinal: kmImplementoFinal.present
            ? kmImplementoFinal.value
            : this.kmImplementoFinal,
        horaSalidaBaseTd: horaSalidaBaseTd.present
            ? horaSalidaBaseTd.value
            : this.horaSalidaBaseTd,
        horaLlegadaZona: horaLlegadaZona.present
            ? horaLlegadaZona.value
            : this.horaLlegadaZona,
        horaRetornoBase: horaRetornoBase.present
            ? horaRetornoBase.value
            : this.horaRetornoBase,
        horaLlegadaTaller: horaLlegadaTaller.present
            ? horaLlegadaTaller.value
            : this.horaLlegadaTaller,
        horaRefrigerio:
            horaRefrigerio.present ? horaRefrigerio.value : this.horaRefrigerio,
        cantidadTancadas: cantidadTancadas.present
            ? cantidadTancadas.value
            : this.cantidadTancadas,
        observacionesMaq: observacionesMaq.present
            ? observacionesMaq.value
            : this.observacionesMaq,
        sincronizado: sincronizado ?? this.sincronizado,
        createdAt: createdAt ?? this.createdAt,
      );
  RegistrosVehiculoLocalData copyWithCompanion(
      RegistrosVehiculoLocalCompanion data) {
    return RegistrosVehiculoLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      kmCamionInicio: data.kmCamionInicio.present
          ? data.kmCamionInicio.value
          : this.kmCamionInicio,
      kmCamionFinal: data.kmCamionFinal.present
          ? data.kmCamionFinal.value
          : this.kmCamionFinal,
      kmImplementoInicio: data.kmImplementoInicio.present
          ? data.kmImplementoInicio.value
          : this.kmImplementoInicio,
      kmImplementoFinal: data.kmImplementoFinal.present
          ? data.kmImplementoFinal.value
          : this.kmImplementoFinal,
      horaSalidaBaseTd: data.horaSalidaBaseTd.present
          ? data.horaSalidaBaseTd.value
          : this.horaSalidaBaseTd,
      horaLlegadaZona: data.horaLlegadaZona.present
          ? data.horaLlegadaZona.value
          : this.horaLlegadaZona,
      horaRetornoBase: data.horaRetornoBase.present
          ? data.horaRetornoBase.value
          : this.horaRetornoBase,
      horaLlegadaTaller: data.horaLlegadaTaller.present
          ? data.horaLlegadaTaller.value
          : this.horaLlegadaTaller,
      horaRefrigerio: data.horaRefrigerio.present
          ? data.horaRefrigerio.value
          : this.horaRefrigerio,
      cantidadTancadas: data.cantidadTancadas.present
          ? data.cantidadTancadas.value
          : this.cantidadTancadas,
      observacionesMaq: data.observacionesMaq.present
          ? data.observacionesMaq.value
          : this.observacionesMaq,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegistrosVehiculoLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('kmCamionInicio: $kmCamionInicio, ')
          ..write('kmCamionFinal: $kmCamionFinal, ')
          ..write('kmImplementoInicio: $kmImplementoInicio, ')
          ..write('kmImplementoFinal: $kmImplementoFinal, ')
          ..write('horaSalidaBaseTd: $horaSalidaBaseTd, ')
          ..write('horaLlegadaZona: $horaLlegadaZona, ')
          ..write('horaRetornoBase: $horaRetornoBase, ')
          ..write('horaLlegadaTaller: $horaLlegadaTaller, ')
          ..write('horaRefrigerio: $horaRefrigerio, ')
          ..write('cantidadTancadas: $cantidadTancadas, ')
          ..write('observacionesMaq: $observacionesMaq, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      registroId,
      kmCamionInicio,
      kmCamionFinal,
      kmImplementoInicio,
      kmImplementoFinal,
      horaSalidaBaseTd,
      horaLlegadaZona,
      horaRetornoBase,
      horaLlegadaTaller,
      horaRefrigerio,
      cantidadTancadas,
      observacionesMaq,
      sincronizado,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegistrosVehiculoLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.kmCamionInicio == this.kmCamionInicio &&
          other.kmCamionFinal == this.kmCamionFinal &&
          other.kmImplementoInicio == this.kmImplementoInicio &&
          other.kmImplementoFinal == this.kmImplementoFinal &&
          other.horaSalidaBaseTd == this.horaSalidaBaseTd &&
          other.horaLlegadaZona == this.horaLlegadaZona &&
          other.horaRetornoBase == this.horaRetornoBase &&
          other.horaLlegadaTaller == this.horaLlegadaTaller &&
          other.horaRefrigerio == this.horaRefrigerio &&
          other.cantidadTancadas == this.cantidadTancadas &&
          other.observacionesMaq == this.observacionesMaq &&
          other.sincronizado == this.sincronizado &&
          other.createdAt == this.createdAt);
}

class RegistrosVehiculoLocalCompanion
    extends UpdateCompanion<RegistrosVehiculoLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<double?> kmCamionInicio;
  final Value<double?> kmCamionFinal;
  final Value<double?> kmImplementoInicio;
  final Value<double?> kmImplementoFinal;
  final Value<String?> horaSalidaBaseTd;
  final Value<String?> horaLlegadaZona;
  final Value<String?> horaRetornoBase;
  final Value<String?> horaLlegadaTaller;
  final Value<String?> horaRefrigerio;
  final Value<int?> cantidadTancadas;
  final Value<String?> observacionesMaq;
  final Value<bool> sincronizado;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RegistrosVehiculoLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.kmCamionInicio = const Value.absent(),
    this.kmCamionFinal = const Value.absent(),
    this.kmImplementoInicio = const Value.absent(),
    this.kmImplementoFinal = const Value.absent(),
    this.horaSalidaBaseTd = const Value.absent(),
    this.horaLlegadaZona = const Value.absent(),
    this.horaRetornoBase = const Value.absent(),
    this.horaLlegadaTaller = const Value.absent(),
    this.horaRefrigerio = const Value.absent(),
    this.cantidadTancadas = const Value.absent(),
    this.observacionesMaq = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegistrosVehiculoLocalCompanion.insert({
    required String id,
    required String registroId,
    this.kmCamionInicio = const Value.absent(),
    this.kmCamionFinal = const Value.absent(),
    this.kmImplementoInicio = const Value.absent(),
    this.kmImplementoFinal = const Value.absent(),
    this.horaSalidaBaseTd = const Value.absent(),
    this.horaLlegadaZona = const Value.absent(),
    this.horaRetornoBase = const Value.absent(),
    this.horaLlegadaTaller = const Value.absent(),
    this.horaRefrigerio = const Value.absent(),
    this.cantidadTancadas = const Value.absent(),
    this.observacionesMaq = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId);
  static Insertable<RegistrosVehiculoLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<double>? kmCamionInicio,
    Expression<double>? kmCamionFinal,
    Expression<double>? kmImplementoInicio,
    Expression<double>? kmImplementoFinal,
    Expression<String>? horaSalidaBaseTd,
    Expression<String>? horaLlegadaZona,
    Expression<String>? horaRetornoBase,
    Expression<String>? horaLlegadaTaller,
    Expression<String>? horaRefrigerio,
    Expression<int>? cantidadTancadas,
    Expression<String>? observacionesMaq,
    Expression<bool>? sincronizado,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (kmCamionInicio != null) 'km_camion_inicio': kmCamionInicio,
      if (kmCamionFinal != null) 'km_camion_final': kmCamionFinal,
      if (kmImplementoInicio != null)
        'km_implemento_inicio': kmImplementoInicio,
      if (kmImplementoFinal != null) 'km_implemento_final': kmImplementoFinal,
      if (horaSalidaBaseTd != null) 'hora_salida_base_td': horaSalidaBaseTd,
      if (horaLlegadaZona != null) 'hora_llegada_zona': horaLlegadaZona,
      if (horaRetornoBase != null) 'hora_retorno_base': horaRetornoBase,
      if (horaLlegadaTaller != null) 'hora_llegada_taller': horaLlegadaTaller,
      if (horaRefrigerio != null) 'hora_refrigerio': horaRefrigerio,
      if (cantidadTancadas != null) 'cantidad_tancadas': cantidadTancadas,
      if (observacionesMaq != null) 'observaciones_maq': observacionesMaq,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegistrosVehiculoLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<double?>? kmCamionInicio,
      Value<double?>? kmCamionFinal,
      Value<double?>? kmImplementoInicio,
      Value<double?>? kmImplementoFinal,
      Value<String?>? horaSalidaBaseTd,
      Value<String?>? horaLlegadaZona,
      Value<String?>? horaRetornoBase,
      Value<String?>? horaLlegadaTaller,
      Value<String?>? horaRefrigerio,
      Value<int?>? cantidadTancadas,
      Value<String?>? observacionesMaq,
      Value<bool>? sincronizado,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RegistrosVehiculoLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      kmCamionInicio: kmCamionInicio ?? this.kmCamionInicio,
      kmCamionFinal: kmCamionFinal ?? this.kmCamionFinal,
      kmImplementoInicio: kmImplementoInicio ?? this.kmImplementoInicio,
      kmImplementoFinal: kmImplementoFinal ?? this.kmImplementoFinal,
      horaSalidaBaseTd: horaSalidaBaseTd ?? this.horaSalidaBaseTd,
      horaLlegadaZona: horaLlegadaZona ?? this.horaLlegadaZona,
      horaRetornoBase: horaRetornoBase ?? this.horaRetornoBase,
      horaLlegadaTaller: horaLlegadaTaller ?? this.horaLlegadaTaller,
      horaRefrigerio: horaRefrigerio ?? this.horaRefrigerio,
      cantidadTancadas: cantidadTancadas ?? this.cantidadTancadas,
      observacionesMaq: observacionesMaq ?? this.observacionesMaq,
      sincronizado: sincronizado ?? this.sincronizado,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (kmCamionInicio.present) {
      map['km_camion_inicio'] = Variable<double>(kmCamionInicio.value);
    }
    if (kmCamionFinal.present) {
      map['km_camion_final'] = Variable<double>(kmCamionFinal.value);
    }
    if (kmImplementoInicio.present) {
      map['km_implemento_inicio'] = Variable<double>(kmImplementoInicio.value);
    }
    if (kmImplementoFinal.present) {
      map['km_implemento_final'] = Variable<double>(kmImplementoFinal.value);
    }
    if (horaSalidaBaseTd.present) {
      map['hora_salida_base_td'] = Variable<String>(horaSalidaBaseTd.value);
    }
    if (horaLlegadaZona.present) {
      map['hora_llegada_zona'] = Variable<String>(horaLlegadaZona.value);
    }
    if (horaRetornoBase.present) {
      map['hora_retorno_base'] = Variable<String>(horaRetornoBase.value);
    }
    if (horaLlegadaTaller.present) {
      map['hora_llegada_taller'] = Variable<String>(horaLlegadaTaller.value);
    }
    if (horaRefrigerio.present) {
      map['hora_refrigerio'] = Variable<String>(horaRefrigerio.value);
    }
    if (cantidadTancadas.present) {
      map['cantidad_tancadas'] = Variable<int>(cantidadTancadas.value);
    }
    if (observacionesMaq.present) {
      map['observaciones_maq'] = Variable<String>(observacionesMaq.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
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
    return (StringBuffer('RegistrosVehiculoLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('kmCamionInicio: $kmCamionInicio, ')
          ..write('kmCamionFinal: $kmCamionFinal, ')
          ..write('kmImplementoInicio: $kmImplementoInicio, ')
          ..write('kmImplementoFinal: $kmImplementoFinal, ')
          ..write('horaSalidaBaseTd: $horaSalidaBaseTd, ')
          ..write('horaLlegadaZona: $horaLlegadaZona, ')
          ..write('horaRetornoBase: $horaRetornoBase, ')
          ..write('horaLlegadaTaller: $horaLlegadaTaller, ')
          ..write('horaRefrigerio: $horaRefrigerio, ')
          ..write('cantidadTancadas: $cantidadTancadas, ')
          ..write('observacionesMaq: $observacionesMaq, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CombustibleVehiculoLocalTable extends CombustibleVehiculoLocal
    with
        TableInfo<$CombustibleVehiculoLocalTable,
            CombustibleVehiculoLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CombustibleVehiculoLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _glnsMeta = const VerificationMeta('glns');
  @override
  late final GeneratedColumn<double> glns = GeneratedColumn<double>(
      'glns', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _horaInicioMeta =
      const VerificationMeta('horaInicio');
  @override
  late final GeneratedColumn<String> horaInicio = GeneratedColumn<String>(
      'hora_inicio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _horaFinalMeta =
      const VerificationMeta('horaFinal');
  @override
  late final GeneratedColumn<String> horaFinal = GeneratedColumn<String>(
      'hora_final', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, registroId, glns, horaInicio, horaFinal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'combustible_vehiculo_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<CombustibleVehiculoLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('glns')) {
      context.handle(
          _glnsMeta, glns.isAcceptableOrUnknown(data['glns']!, _glnsMeta));
    }
    if (data.containsKey('hora_inicio')) {
      context.handle(
          _horaInicioMeta,
          horaInicio.isAcceptableOrUnknown(
              data['hora_inicio']!, _horaInicioMeta));
    }
    if (data.containsKey('hora_final')) {
      context.handle(_horaFinalMeta,
          horaFinal.isAcceptableOrUnknown(data['hora_final']!, _horaFinalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CombustibleVehiculoLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CombustibleVehiculoLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      glns: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}glns']),
      horaInicio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hora_inicio']),
      horaFinal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hora_final']),
    );
  }

  @override
  $CombustibleVehiculoLocalTable createAlias(String alias) {
    return $CombustibleVehiculoLocalTable(attachedDatabase, alias);
  }
}

class CombustibleVehiculoLocalData extends DataClass
    implements Insertable<CombustibleVehiculoLocalData> {
  final String id;
  final String registroId;
  final double? glns;
  final String? horaInicio;
  final String? horaFinal;
  const CombustibleVehiculoLocalData(
      {required this.id,
      required this.registroId,
      this.glns,
      this.horaInicio,
      this.horaFinal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    if (!nullToAbsent || glns != null) {
      map['glns'] = Variable<double>(glns);
    }
    if (!nullToAbsent || horaInicio != null) {
      map['hora_inicio'] = Variable<String>(horaInicio);
    }
    if (!nullToAbsent || horaFinal != null) {
      map['hora_final'] = Variable<String>(horaFinal);
    }
    return map;
  }

  CombustibleVehiculoLocalCompanion toCompanion(bool nullToAbsent) {
    return CombustibleVehiculoLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      glns: glns == null && nullToAbsent ? const Value.absent() : Value(glns),
      horaInicio: horaInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(horaInicio),
      horaFinal: horaFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(horaFinal),
    );
  }

  factory CombustibleVehiculoLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CombustibleVehiculoLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      glns: serializer.fromJson<double?>(json['glns']),
      horaInicio: serializer.fromJson<String?>(json['horaInicio']),
      horaFinal: serializer.fromJson<String?>(json['horaFinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'glns': serializer.toJson<double?>(glns),
      'horaInicio': serializer.toJson<String?>(horaInicio),
      'horaFinal': serializer.toJson<String?>(horaFinal),
    };
  }

  CombustibleVehiculoLocalData copyWith(
          {String? id,
          String? registroId,
          Value<double?> glns = const Value.absent(),
          Value<String?> horaInicio = const Value.absent(),
          Value<String?> horaFinal = const Value.absent()}) =>
      CombustibleVehiculoLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        glns: glns.present ? glns.value : this.glns,
        horaInicio: horaInicio.present ? horaInicio.value : this.horaInicio,
        horaFinal: horaFinal.present ? horaFinal.value : this.horaFinal,
      );
  CombustibleVehiculoLocalData copyWithCompanion(
      CombustibleVehiculoLocalCompanion data) {
    return CombustibleVehiculoLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      glns: data.glns.present ? data.glns.value : this.glns,
      horaInicio:
          data.horaInicio.present ? data.horaInicio.value : this.horaInicio,
      horaFinal: data.horaFinal.present ? data.horaFinal.value : this.horaFinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CombustibleVehiculoLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('glns: $glns, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFinal: $horaFinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, registroId, glns, horaInicio, horaFinal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CombustibleVehiculoLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.glns == this.glns &&
          other.horaInicio == this.horaInicio &&
          other.horaFinal == this.horaFinal);
}

class CombustibleVehiculoLocalCompanion
    extends UpdateCompanion<CombustibleVehiculoLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<double?> glns;
  final Value<String?> horaInicio;
  final Value<String?> horaFinal;
  final Value<int> rowid;
  const CombustibleVehiculoLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.glns = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CombustibleVehiculoLocalCompanion.insert({
    required String id,
    required String registroId,
    this.glns = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFinal = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId);
  static Insertable<CombustibleVehiculoLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<double>? glns,
    Expression<String>? horaInicio,
    Expression<String>? horaFinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (glns != null) 'glns': glns,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFinal != null) 'hora_final': horaFinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CombustibleVehiculoLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<double?>? glns,
      Value<String?>? horaInicio,
      Value<String?>? horaFinal,
      Value<int>? rowid}) {
    return CombustibleVehiculoLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      glns: glns ?? this.glns,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFinal: horaFinal ?? this.horaFinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (glns.present) {
      map['glns'] = Variable<double>(glns.value);
    }
    if (horaInicio.present) {
      map['hora_inicio'] = Variable<String>(horaInicio.value);
    }
    if (horaFinal.present) {
      map['hora_final'] = Variable<String>(horaFinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CombustibleVehiculoLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('glns: $glns, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFinal: $horaFinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PorteroLecturasLocalTable extends PorteroLecturasLocal
    with TableInfo<$PorteroLecturasLocalTable, PorteroLecturasLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PorteroLecturasLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _porteroIdErpMeta =
      const VerificationMeta('porteroIdErp');
  @override
  late final GeneratedColumn<int> porteroIdErp = GeneratedColumn<int>(
      'portero_id_erp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tractorIdErpMeta =
      const VerificationMeta('tractorIdErp');
  @override
  late final GeneratedColumn<int> tractorIdErp = GeneratedColumn<int>(
      'tractor_id_erp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tractorCodigoMeta =
      const VerificationMeta('tractorCodigo');
  @override
  late final GeneratedColumn<String> tractorCodigo = GeneratedColumn<String>(
      'tractor_codigo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tractorLeidoAtMeta =
      const VerificationMeta('tractorLeidoAt');
  @override
  late final GeneratedColumn<DateTime> tractorLeidoAt =
      GeneratedColumn<DateTime>('tractor_leido_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _implementoIdErpMeta =
      const VerificationMeta('implementoIdErp');
  @override
  late final GeneratedColumn<int> implementoIdErp = GeneratedColumn<int>(
      'implemento_id_erp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _implementoCodigoMeta =
      const VerificationMeta('implementoCodigo');
  @override
  late final GeneratedColumn<String> implementoCodigo = GeneratedColumn<String>(
      'implemento_codigo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _implementoLeidoAtMeta =
      const VerificationMeta('implementoLeidoAt');
  @override
  late final GeneratedColumn<DateTime> implementoLeidoAt =
      GeneratedColumn<DateTime>('implemento_leido_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _trabajadorIdErpMeta =
      const VerificationMeta('trabajadorIdErp');
  @override
  late final GeneratedColumn<int> trabajadorIdErp = GeneratedColumn<int>(
      'trabajador_id_erp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _trabajadorCodigoMeta =
      const VerificationMeta('trabajadorCodigo');
  @override
  late final GeneratedColumn<String> trabajadorCodigo = GeneratedColumn<String>(
      'trabajador_codigo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _operadorLeidoAtMeta =
      const VerificationMeta('operadorLeidoAt');
  @override
  late final GeneratedColumn<DateTime> operadorLeidoAt =
      GeneratedColumn<DateTime>('operador_leido_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cultivoIdErpMeta =
      const VerificationMeta('cultivoIdErp');
  @override
  late final GeneratedColumn<int> cultivoIdErp = GeneratedColumn<int>(
      'cultivo_id_erp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cultivoNombreMeta =
      const VerificationMeta('cultivoNombre');
  @override
  late final GeneratedColumn<String> cultivoNombre = GeneratedColumn<String>(
      'cultivo_nombre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _comentarioMeta =
      const VerificationMeta('comentario');
  @override
  late final GeneratedColumn<String> comentario = GeneratedColumn<String>(
      'comentario', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dispositivoIdMeta =
      const VerificationMeta('dispositivoId');
  @override
  late final GeneratedColumn<String> dispositivoId = GeneratedColumn<String>(
      'dispositivo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sincronizadoMeta =
      const VerificationMeta('sincronizado');
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
      'sincronizado', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sincronizado" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        porteroIdErp,
        tractorIdErp,
        tractorCodigo,
        tractorLeidoAt,
        implementoIdErp,
        implementoCodigo,
        implementoLeidoAt,
        trabajadorIdErp,
        trabajadorCodigo,
        operadorLeidoAt,
        cultivoIdErp,
        cultivoNombre,
        comentario,
        dispositivoId,
        sincronizado,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'portero_lecturas_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<PorteroLecturasLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('portero_id_erp')) {
      context.handle(
          _porteroIdErpMeta,
          porteroIdErp.isAcceptableOrUnknown(
              data['portero_id_erp']!, _porteroIdErpMeta));
    } else if (isInserting) {
      context.missing(_porteroIdErpMeta);
    }
    if (data.containsKey('tractor_id_erp')) {
      context.handle(
          _tractorIdErpMeta,
          tractorIdErp.isAcceptableOrUnknown(
              data['tractor_id_erp']!, _tractorIdErpMeta));
    }
    if (data.containsKey('tractor_codigo')) {
      context.handle(
          _tractorCodigoMeta,
          tractorCodigo.isAcceptableOrUnknown(
              data['tractor_codigo']!, _tractorCodigoMeta));
    }
    if (data.containsKey('tractor_leido_at')) {
      context.handle(
          _tractorLeidoAtMeta,
          tractorLeidoAt.isAcceptableOrUnknown(
              data['tractor_leido_at']!, _tractorLeidoAtMeta));
    }
    if (data.containsKey('implemento_id_erp')) {
      context.handle(
          _implementoIdErpMeta,
          implementoIdErp.isAcceptableOrUnknown(
              data['implemento_id_erp']!, _implementoIdErpMeta));
    }
    if (data.containsKey('implemento_codigo')) {
      context.handle(
          _implementoCodigoMeta,
          implementoCodigo.isAcceptableOrUnknown(
              data['implemento_codigo']!, _implementoCodigoMeta));
    }
    if (data.containsKey('implemento_leido_at')) {
      context.handle(
          _implementoLeidoAtMeta,
          implementoLeidoAt.isAcceptableOrUnknown(
              data['implemento_leido_at']!, _implementoLeidoAtMeta));
    }
    if (data.containsKey('trabajador_id_erp')) {
      context.handle(
          _trabajadorIdErpMeta,
          trabajadorIdErp.isAcceptableOrUnknown(
              data['trabajador_id_erp']!, _trabajadorIdErpMeta));
    }
    if (data.containsKey('trabajador_codigo')) {
      context.handle(
          _trabajadorCodigoMeta,
          trabajadorCodigo.isAcceptableOrUnknown(
              data['trabajador_codigo']!, _trabajadorCodigoMeta));
    }
    if (data.containsKey('operador_leido_at')) {
      context.handle(
          _operadorLeidoAtMeta,
          operadorLeidoAt.isAcceptableOrUnknown(
              data['operador_leido_at']!, _operadorLeidoAtMeta));
    }
    if (data.containsKey('cultivo_id_erp')) {
      context.handle(
          _cultivoIdErpMeta,
          cultivoIdErp.isAcceptableOrUnknown(
              data['cultivo_id_erp']!, _cultivoIdErpMeta));
    }
    if (data.containsKey('cultivo_nombre')) {
      context.handle(
          _cultivoNombreMeta,
          cultivoNombre.isAcceptableOrUnknown(
              data['cultivo_nombre']!, _cultivoNombreMeta));
    }
    if (data.containsKey('comentario')) {
      context.handle(
          _comentarioMeta,
          comentario.isAcceptableOrUnknown(
              data['comentario']!, _comentarioMeta));
    }
    if (data.containsKey('dispositivo_id')) {
      context.handle(
          _dispositivoIdMeta,
          dispositivoId.isAcceptableOrUnknown(
              data['dispositivo_id']!, _dispositivoIdMeta));
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
          _sincronizadoMeta,
          sincronizado.isAcceptableOrUnknown(
              data['sincronizado']!, _sincronizadoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PorteroLecturasLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PorteroLecturasLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      porteroIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}portero_id_erp'])!,
      tractorIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tractor_id_erp']),
      tractorCodigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tractor_codigo']),
      tractorLeidoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}tractor_leido_at']),
      implementoIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}implemento_id_erp']),
      implementoCodigo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}implemento_codigo']),
      implementoLeidoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}implemento_leido_at']),
      trabajadorIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trabajador_id_erp']),
      trabajadorCodigo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}trabajador_codigo']),
      operadorLeidoAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}operador_leido_at']),
      cultivoIdErp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cultivo_id_erp']),
      cultivoNombre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cultivo_nombre']),
      comentario: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comentario']),
      dispositivoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dispositivo_id']),
      sincronizado: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sincronizado'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PorteroLecturasLocalTable createAlias(String alias) {
    return $PorteroLecturasLocalTable(attachedDatabase, alias);
  }
}

class PorteroLecturasLocalData extends DataClass
    implements Insertable<PorteroLecturasLocalData> {
  final String id;
  final int porteroIdErp;
  final int? tractorIdErp;
  final String? tractorCodigo;
  final DateTime? tractorLeidoAt;
  final int? implementoIdErp;
  final String? implementoCodigo;
  final DateTime? implementoLeidoAt;
  final int? trabajadorIdErp;
  final String? trabajadorCodigo;
  final DateTime? operadorLeidoAt;
  final int? cultivoIdErp;
  final String? cultivoNombre;
  final String? comentario;
  final String? dispositivoId;
  final bool sincronizado;
  final DateTime createdAt;
  const PorteroLecturasLocalData(
      {required this.id,
      required this.porteroIdErp,
      this.tractorIdErp,
      this.tractorCodigo,
      this.tractorLeidoAt,
      this.implementoIdErp,
      this.implementoCodigo,
      this.implementoLeidoAt,
      this.trabajadorIdErp,
      this.trabajadorCodigo,
      this.operadorLeidoAt,
      this.cultivoIdErp,
      this.cultivoNombre,
      this.comentario,
      this.dispositivoId,
      required this.sincronizado,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['portero_id_erp'] = Variable<int>(porteroIdErp);
    if (!nullToAbsent || tractorIdErp != null) {
      map['tractor_id_erp'] = Variable<int>(tractorIdErp);
    }
    if (!nullToAbsent || tractorCodigo != null) {
      map['tractor_codigo'] = Variable<String>(tractorCodigo);
    }
    if (!nullToAbsent || tractorLeidoAt != null) {
      map['tractor_leido_at'] = Variable<DateTime>(tractorLeidoAt);
    }
    if (!nullToAbsent || implementoIdErp != null) {
      map['implemento_id_erp'] = Variable<int>(implementoIdErp);
    }
    if (!nullToAbsent || implementoCodigo != null) {
      map['implemento_codigo'] = Variable<String>(implementoCodigo);
    }
    if (!nullToAbsent || implementoLeidoAt != null) {
      map['implemento_leido_at'] = Variable<DateTime>(implementoLeidoAt);
    }
    if (!nullToAbsent || trabajadorIdErp != null) {
      map['trabajador_id_erp'] = Variable<int>(trabajadorIdErp);
    }
    if (!nullToAbsent || trabajadorCodigo != null) {
      map['trabajador_codigo'] = Variable<String>(trabajadorCodigo);
    }
    if (!nullToAbsent || operadorLeidoAt != null) {
      map['operador_leido_at'] = Variable<DateTime>(operadorLeidoAt);
    }
    if (!nullToAbsent || cultivoIdErp != null) {
      map['cultivo_id_erp'] = Variable<int>(cultivoIdErp);
    }
    if (!nullToAbsent || cultivoNombre != null) {
      map['cultivo_nombre'] = Variable<String>(cultivoNombre);
    }
    if (!nullToAbsent || comentario != null) {
      map['comentario'] = Variable<String>(comentario);
    }
    if (!nullToAbsent || dispositivoId != null) {
      map['dispositivo_id'] = Variable<String>(dispositivoId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PorteroLecturasLocalCompanion toCompanion(bool nullToAbsent) {
    return PorteroLecturasLocalCompanion(
      id: Value(id),
      porteroIdErp: Value(porteroIdErp),
      tractorIdErp: tractorIdErp == null && nullToAbsent
          ? const Value.absent()
          : Value(tractorIdErp),
      tractorCodigo: tractorCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(tractorCodigo),
      tractorLeidoAt: tractorLeidoAt == null && nullToAbsent
          ? const Value.absent()
          : Value(tractorLeidoAt),
      implementoIdErp: implementoIdErp == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoIdErp),
      implementoCodigo: implementoCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoCodigo),
      implementoLeidoAt: implementoLeidoAt == null && nullToAbsent
          ? const Value.absent()
          : Value(implementoLeidoAt),
      trabajadorIdErp: trabajadorIdErp == null && nullToAbsent
          ? const Value.absent()
          : Value(trabajadorIdErp),
      trabajadorCodigo: trabajadorCodigo == null && nullToAbsent
          ? const Value.absent()
          : Value(trabajadorCodigo),
      operadorLeidoAt: operadorLeidoAt == null && nullToAbsent
          ? const Value.absent()
          : Value(operadorLeidoAt),
      cultivoIdErp: cultivoIdErp == null && nullToAbsent
          ? const Value.absent()
          : Value(cultivoIdErp),
      cultivoNombre: cultivoNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(cultivoNombre),
      comentario: comentario == null && nullToAbsent
          ? const Value.absent()
          : Value(comentario),
      dispositivoId: dispositivoId == null && nullToAbsent
          ? const Value.absent()
          : Value(dispositivoId),
      sincronizado: Value(sincronizado),
      createdAt: Value(createdAt),
    );
  }

  factory PorteroLecturasLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PorteroLecturasLocalData(
      id: serializer.fromJson<String>(json['id']),
      porteroIdErp: serializer.fromJson<int>(json['porteroIdErp']),
      tractorIdErp: serializer.fromJson<int?>(json['tractorIdErp']),
      tractorCodigo: serializer.fromJson<String?>(json['tractorCodigo']),
      tractorLeidoAt: serializer.fromJson<DateTime?>(json['tractorLeidoAt']),
      implementoIdErp: serializer.fromJson<int?>(json['implementoIdErp']),
      implementoCodigo: serializer.fromJson<String?>(json['implementoCodigo']),
      implementoLeidoAt:
          serializer.fromJson<DateTime?>(json['implementoLeidoAt']),
      trabajadorIdErp: serializer.fromJson<int?>(json['trabajadorIdErp']),
      trabajadorCodigo: serializer.fromJson<String?>(json['trabajadorCodigo']),
      operadorLeidoAt: serializer.fromJson<DateTime?>(json['operadorLeidoAt']),
      cultivoIdErp: serializer.fromJson<int?>(json['cultivoIdErp']),
      cultivoNombre: serializer.fromJson<String?>(json['cultivoNombre']),
      comentario: serializer.fromJson<String?>(json['comentario']),
      dispositivoId: serializer.fromJson<String?>(json['dispositivoId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'porteroIdErp': serializer.toJson<int>(porteroIdErp),
      'tractorIdErp': serializer.toJson<int?>(tractorIdErp),
      'tractorCodigo': serializer.toJson<String?>(tractorCodigo),
      'tractorLeidoAt': serializer.toJson<DateTime?>(tractorLeidoAt),
      'implementoIdErp': serializer.toJson<int?>(implementoIdErp),
      'implementoCodigo': serializer.toJson<String?>(implementoCodigo),
      'implementoLeidoAt': serializer.toJson<DateTime?>(implementoLeidoAt),
      'trabajadorIdErp': serializer.toJson<int?>(trabajadorIdErp),
      'trabajadorCodigo': serializer.toJson<String?>(trabajadorCodigo),
      'operadorLeidoAt': serializer.toJson<DateTime?>(operadorLeidoAt),
      'cultivoIdErp': serializer.toJson<int?>(cultivoIdErp),
      'cultivoNombre': serializer.toJson<String?>(cultivoNombre),
      'comentario': serializer.toJson<String?>(comentario),
      'dispositivoId': serializer.toJson<String?>(dispositivoId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PorteroLecturasLocalData copyWith(
          {String? id,
          int? porteroIdErp,
          Value<int?> tractorIdErp = const Value.absent(),
          Value<String?> tractorCodigo = const Value.absent(),
          Value<DateTime?> tractorLeidoAt = const Value.absent(),
          Value<int?> implementoIdErp = const Value.absent(),
          Value<String?> implementoCodigo = const Value.absent(),
          Value<DateTime?> implementoLeidoAt = const Value.absent(),
          Value<int?> trabajadorIdErp = const Value.absent(),
          Value<String?> trabajadorCodigo = const Value.absent(),
          Value<DateTime?> operadorLeidoAt = const Value.absent(),
          Value<int?> cultivoIdErp = const Value.absent(),
          Value<String?> cultivoNombre = const Value.absent(),
          Value<String?> comentario = const Value.absent(),
          Value<String?> dispositivoId = const Value.absent(),
          bool? sincronizado,
          DateTime? createdAt}) =>
      PorteroLecturasLocalData(
        id: id ?? this.id,
        porteroIdErp: porteroIdErp ?? this.porteroIdErp,
        tractorIdErp:
            tractorIdErp.present ? tractorIdErp.value : this.tractorIdErp,
        tractorCodigo:
            tractorCodigo.present ? tractorCodigo.value : this.tractorCodigo,
        tractorLeidoAt:
            tractorLeidoAt.present ? tractorLeidoAt.value : this.tractorLeidoAt,
        implementoIdErp: implementoIdErp.present
            ? implementoIdErp.value
            : this.implementoIdErp,
        implementoCodigo: implementoCodigo.present
            ? implementoCodigo.value
            : this.implementoCodigo,
        implementoLeidoAt: implementoLeidoAt.present
            ? implementoLeidoAt.value
            : this.implementoLeidoAt,
        trabajadorIdErp: trabajadorIdErp.present
            ? trabajadorIdErp.value
            : this.trabajadorIdErp,
        trabajadorCodigo: trabajadorCodigo.present
            ? trabajadorCodigo.value
            : this.trabajadorCodigo,
        operadorLeidoAt: operadorLeidoAt.present
            ? operadorLeidoAt.value
            : this.operadorLeidoAt,
        cultivoIdErp:
            cultivoIdErp.present ? cultivoIdErp.value : this.cultivoIdErp,
        cultivoNombre:
            cultivoNombre.present ? cultivoNombre.value : this.cultivoNombre,
        comentario: comentario.present ? comentario.value : this.comentario,
        dispositivoId:
            dispositivoId.present ? dispositivoId.value : this.dispositivoId,
        sincronizado: sincronizado ?? this.sincronizado,
        createdAt: createdAt ?? this.createdAt,
      );
  PorteroLecturasLocalData copyWithCompanion(
      PorteroLecturasLocalCompanion data) {
    return PorteroLecturasLocalData(
      id: data.id.present ? data.id.value : this.id,
      porteroIdErp: data.porteroIdErp.present
          ? data.porteroIdErp.value
          : this.porteroIdErp,
      tractorIdErp: data.tractorIdErp.present
          ? data.tractorIdErp.value
          : this.tractorIdErp,
      tractorCodigo: data.tractorCodigo.present
          ? data.tractorCodigo.value
          : this.tractorCodigo,
      tractorLeidoAt: data.tractorLeidoAt.present
          ? data.tractorLeidoAt.value
          : this.tractorLeidoAt,
      implementoIdErp: data.implementoIdErp.present
          ? data.implementoIdErp.value
          : this.implementoIdErp,
      implementoCodigo: data.implementoCodigo.present
          ? data.implementoCodigo.value
          : this.implementoCodigo,
      implementoLeidoAt: data.implementoLeidoAt.present
          ? data.implementoLeidoAt.value
          : this.implementoLeidoAt,
      trabajadorIdErp: data.trabajadorIdErp.present
          ? data.trabajadorIdErp.value
          : this.trabajadorIdErp,
      trabajadorCodigo: data.trabajadorCodigo.present
          ? data.trabajadorCodigo.value
          : this.trabajadorCodigo,
      operadorLeidoAt: data.operadorLeidoAt.present
          ? data.operadorLeidoAt.value
          : this.operadorLeidoAt,
      cultivoIdErp: data.cultivoIdErp.present
          ? data.cultivoIdErp.value
          : this.cultivoIdErp,
      cultivoNombre: data.cultivoNombre.present
          ? data.cultivoNombre.value
          : this.cultivoNombre,
      comentario:
          data.comentario.present ? data.comentario.value : this.comentario,
      dispositivoId: data.dispositivoId.present
          ? data.dispositivoId.value
          : this.dispositivoId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PorteroLecturasLocalData(')
          ..write('id: $id, ')
          ..write('porteroIdErp: $porteroIdErp, ')
          ..write('tractorIdErp: $tractorIdErp, ')
          ..write('tractorCodigo: $tractorCodigo, ')
          ..write('tractorLeidoAt: $tractorLeidoAt, ')
          ..write('implementoIdErp: $implementoIdErp, ')
          ..write('implementoCodigo: $implementoCodigo, ')
          ..write('implementoLeidoAt: $implementoLeidoAt, ')
          ..write('trabajadorIdErp: $trabajadorIdErp, ')
          ..write('trabajadorCodigo: $trabajadorCodigo, ')
          ..write('operadorLeidoAt: $operadorLeidoAt, ')
          ..write('cultivoIdErp: $cultivoIdErp, ')
          ..write('cultivoNombre: $cultivoNombre, ')
          ..write('comentario: $comentario, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      porteroIdErp,
      tractorIdErp,
      tractorCodigo,
      tractorLeidoAt,
      implementoIdErp,
      implementoCodigo,
      implementoLeidoAt,
      trabajadorIdErp,
      trabajadorCodigo,
      operadorLeidoAt,
      cultivoIdErp,
      cultivoNombre,
      comentario,
      dispositivoId,
      sincronizado,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PorteroLecturasLocalData &&
          other.id == this.id &&
          other.porteroIdErp == this.porteroIdErp &&
          other.tractorIdErp == this.tractorIdErp &&
          other.tractorCodigo == this.tractorCodigo &&
          other.tractorLeidoAt == this.tractorLeidoAt &&
          other.implementoIdErp == this.implementoIdErp &&
          other.implementoCodigo == this.implementoCodigo &&
          other.implementoLeidoAt == this.implementoLeidoAt &&
          other.trabajadorIdErp == this.trabajadorIdErp &&
          other.trabajadorCodigo == this.trabajadorCodigo &&
          other.operadorLeidoAt == this.operadorLeidoAt &&
          other.cultivoIdErp == this.cultivoIdErp &&
          other.cultivoNombre == this.cultivoNombre &&
          other.comentario == this.comentario &&
          other.dispositivoId == this.dispositivoId &&
          other.sincronizado == this.sincronizado &&
          other.createdAt == this.createdAt);
}

class PorteroLecturasLocalCompanion
    extends UpdateCompanion<PorteroLecturasLocalData> {
  final Value<String> id;
  final Value<int> porteroIdErp;
  final Value<int?> tractorIdErp;
  final Value<String?> tractorCodigo;
  final Value<DateTime?> tractorLeidoAt;
  final Value<int?> implementoIdErp;
  final Value<String?> implementoCodigo;
  final Value<DateTime?> implementoLeidoAt;
  final Value<int?> trabajadorIdErp;
  final Value<String?> trabajadorCodigo;
  final Value<DateTime?> operadorLeidoAt;
  final Value<int?> cultivoIdErp;
  final Value<String?> cultivoNombre;
  final Value<String?> comentario;
  final Value<String?> dispositivoId;
  final Value<bool> sincronizado;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PorteroLecturasLocalCompanion({
    this.id = const Value.absent(),
    this.porteroIdErp = const Value.absent(),
    this.tractorIdErp = const Value.absent(),
    this.tractorCodigo = const Value.absent(),
    this.tractorLeidoAt = const Value.absent(),
    this.implementoIdErp = const Value.absent(),
    this.implementoCodigo = const Value.absent(),
    this.implementoLeidoAt = const Value.absent(),
    this.trabajadorIdErp = const Value.absent(),
    this.trabajadorCodigo = const Value.absent(),
    this.operadorLeidoAt = const Value.absent(),
    this.cultivoIdErp = const Value.absent(),
    this.cultivoNombre = const Value.absent(),
    this.comentario = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PorteroLecturasLocalCompanion.insert({
    required String id,
    required int porteroIdErp,
    this.tractorIdErp = const Value.absent(),
    this.tractorCodigo = const Value.absent(),
    this.tractorLeidoAt = const Value.absent(),
    this.implementoIdErp = const Value.absent(),
    this.implementoCodigo = const Value.absent(),
    this.implementoLeidoAt = const Value.absent(),
    this.trabajadorIdErp = const Value.absent(),
    this.trabajadorCodigo = const Value.absent(),
    this.operadorLeidoAt = const Value.absent(),
    this.cultivoIdErp = const Value.absent(),
    this.cultivoNombre = const Value.absent(),
    this.comentario = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        porteroIdErp = Value(porteroIdErp);
  static Insertable<PorteroLecturasLocalData> custom({
    Expression<String>? id,
    Expression<int>? porteroIdErp,
    Expression<int>? tractorIdErp,
    Expression<String>? tractorCodigo,
    Expression<DateTime>? tractorLeidoAt,
    Expression<int>? implementoIdErp,
    Expression<String>? implementoCodigo,
    Expression<DateTime>? implementoLeidoAt,
    Expression<int>? trabajadorIdErp,
    Expression<String>? trabajadorCodigo,
    Expression<DateTime>? operadorLeidoAt,
    Expression<int>? cultivoIdErp,
    Expression<String>? cultivoNombre,
    Expression<String>? comentario,
    Expression<String>? dispositivoId,
    Expression<bool>? sincronizado,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (porteroIdErp != null) 'portero_id_erp': porteroIdErp,
      if (tractorIdErp != null) 'tractor_id_erp': tractorIdErp,
      if (tractorCodigo != null) 'tractor_codigo': tractorCodigo,
      if (tractorLeidoAt != null) 'tractor_leido_at': tractorLeidoAt,
      if (implementoIdErp != null) 'implemento_id_erp': implementoIdErp,
      if (implementoCodigo != null) 'implemento_codigo': implementoCodigo,
      if (implementoLeidoAt != null) 'implemento_leido_at': implementoLeidoAt,
      if (trabajadorIdErp != null) 'trabajador_id_erp': trabajadorIdErp,
      if (trabajadorCodigo != null) 'trabajador_codigo': trabajadorCodigo,
      if (operadorLeidoAt != null) 'operador_leido_at': operadorLeidoAt,
      if (cultivoIdErp != null) 'cultivo_id_erp': cultivoIdErp,
      if (cultivoNombre != null) 'cultivo_nombre': cultivoNombre,
      if (comentario != null) 'comentario': comentario,
      if (dispositivoId != null) 'dispositivo_id': dispositivoId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PorteroLecturasLocalCompanion copyWith(
      {Value<String>? id,
      Value<int>? porteroIdErp,
      Value<int?>? tractorIdErp,
      Value<String?>? tractorCodigo,
      Value<DateTime?>? tractorLeidoAt,
      Value<int?>? implementoIdErp,
      Value<String?>? implementoCodigo,
      Value<DateTime?>? implementoLeidoAt,
      Value<int?>? trabajadorIdErp,
      Value<String?>? trabajadorCodigo,
      Value<DateTime?>? operadorLeidoAt,
      Value<int?>? cultivoIdErp,
      Value<String?>? cultivoNombre,
      Value<String?>? comentario,
      Value<String?>? dispositivoId,
      Value<bool>? sincronizado,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PorteroLecturasLocalCompanion(
      id: id ?? this.id,
      porteroIdErp: porteroIdErp ?? this.porteroIdErp,
      tractorIdErp: tractorIdErp ?? this.tractorIdErp,
      tractorCodigo: tractorCodigo ?? this.tractorCodigo,
      tractorLeidoAt: tractorLeidoAt ?? this.tractorLeidoAt,
      implementoIdErp: implementoIdErp ?? this.implementoIdErp,
      implementoCodigo: implementoCodigo ?? this.implementoCodigo,
      implementoLeidoAt: implementoLeidoAt ?? this.implementoLeidoAt,
      trabajadorIdErp: trabajadorIdErp ?? this.trabajadorIdErp,
      trabajadorCodigo: trabajadorCodigo ?? this.trabajadorCodigo,
      operadorLeidoAt: operadorLeidoAt ?? this.operadorLeidoAt,
      cultivoIdErp: cultivoIdErp ?? this.cultivoIdErp,
      cultivoNombre: cultivoNombre ?? this.cultivoNombre,
      comentario: comentario ?? this.comentario,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      sincronizado: sincronizado ?? this.sincronizado,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (porteroIdErp.present) {
      map['portero_id_erp'] = Variable<int>(porteroIdErp.value);
    }
    if (tractorIdErp.present) {
      map['tractor_id_erp'] = Variable<int>(tractorIdErp.value);
    }
    if (tractorCodigo.present) {
      map['tractor_codigo'] = Variable<String>(tractorCodigo.value);
    }
    if (tractorLeidoAt.present) {
      map['tractor_leido_at'] = Variable<DateTime>(tractorLeidoAt.value);
    }
    if (implementoIdErp.present) {
      map['implemento_id_erp'] = Variable<int>(implementoIdErp.value);
    }
    if (implementoCodigo.present) {
      map['implemento_codigo'] = Variable<String>(implementoCodigo.value);
    }
    if (implementoLeidoAt.present) {
      map['implemento_leido_at'] = Variable<DateTime>(implementoLeidoAt.value);
    }
    if (trabajadorIdErp.present) {
      map['trabajador_id_erp'] = Variable<int>(trabajadorIdErp.value);
    }
    if (trabajadorCodigo.present) {
      map['trabajador_codigo'] = Variable<String>(trabajadorCodigo.value);
    }
    if (operadorLeidoAt.present) {
      map['operador_leido_at'] = Variable<DateTime>(operadorLeidoAt.value);
    }
    if (cultivoIdErp.present) {
      map['cultivo_id_erp'] = Variable<int>(cultivoIdErp.value);
    }
    if (cultivoNombre.present) {
      map['cultivo_nombre'] = Variable<String>(cultivoNombre.value);
    }
    if (comentario.present) {
      map['comentario'] = Variable<String>(comentario.value);
    }
    if (dispositivoId.present) {
      map['dispositivo_id'] = Variable<String>(dispositivoId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
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
    return (StringBuffer('PorteroLecturasLocalCompanion(')
          ..write('id: $id, ')
          ..write('porteroIdErp: $porteroIdErp, ')
          ..write('tractorIdErp: $tractorIdErp, ')
          ..write('tractorCodigo: $tractorCodigo, ')
          ..write('tractorLeidoAt: $tractorLeidoAt, ')
          ..write('implementoIdErp: $implementoIdErp, ')
          ..write('implementoCodigo: $implementoCodigo, ')
          ..write('implementoLeidoAt: $implementoLeidoAt, ')
          ..write('trabajadorIdErp: $trabajadorIdErp, ')
          ..write('trabajadorCodigo: $trabajadorCodigo, ')
          ..write('operadorLeidoAt: $operadorLeidoAt, ')
          ..write('cultivoIdErp: $cultivoIdErp, ')
          ..write('cultivoNombre: $cultivoNombre, ')
          ..write('comentario: $comentario, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubLaboresLocalTable extends SubLaboresLocal
    with TableInfo<$SubLaboresLocalTable, SubLaboresLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubLaboresLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sublaborNombreMeta =
      const VerificationMeta('sublaborNombre');
  @override
  late final GeneratedColumn<String> sublaborNombre = GeneratedColumn<String>(
      'sublabor_nombre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, registroId, sublaborNombre, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sub_labores_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<SubLaboresLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('sublabor_nombre')) {
      context.handle(
          _sublaborNombreMeta,
          sublaborNombre.isAcceptableOrUnknown(
              data['sublabor_nombre']!, _sublaborNombreMeta));
    } else if (isInserting) {
      context.missing(_sublaborNombreMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubLaboresLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubLaboresLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      sublaborNombre: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sublabor_nombre'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SubLaboresLocalTable createAlias(String alias) {
    return $SubLaboresLocalTable(attachedDatabase, alias);
  }
}

class SubLaboresLocalData extends DataClass
    implements Insertable<SubLaboresLocalData> {
  final String id;
  final String registroId;

  /// Nombre de la sub-labor: 'Aplicación de cianamida' | 'Aplicación de chanchito' | 'Aplicación Sanitaria'
  final String sublaborNombre;
  final DateTime createdAt;
  const SubLaboresLocalData(
      {required this.id,
      required this.registroId,
      required this.sublaborNombre,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    map['sublabor_nombre'] = Variable<String>(sublaborNombre);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubLaboresLocalCompanion toCompanion(bool nullToAbsent) {
    return SubLaboresLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      sublaborNombre: Value(sublaborNombre),
      createdAt: Value(createdAt),
    );
  }

  factory SubLaboresLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubLaboresLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      sublaborNombre: serializer.fromJson<String>(json['sublaborNombre']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'sublaborNombre': serializer.toJson<String>(sublaborNombre),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SubLaboresLocalData copyWith(
          {String? id,
          String? registroId,
          String? sublaborNombre,
          DateTime? createdAt}) =>
      SubLaboresLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        sublaborNombre: sublaborNombre ?? this.sublaborNombre,
        createdAt: createdAt ?? this.createdAt,
      );
  SubLaboresLocalData copyWithCompanion(SubLaboresLocalCompanion data) {
    return SubLaboresLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      sublaborNombre: data.sublaborNombre.present
          ? data.sublaborNombre.value
          : this.sublaborNombre,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubLaboresLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('sublaborNombre: $sublaborNombre, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, registroId, sublaborNombre, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubLaboresLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.sublaborNombre == this.sublaborNombre &&
          other.createdAt == this.createdAt);
}

class SubLaboresLocalCompanion extends UpdateCompanion<SubLaboresLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<String> sublaborNombre;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SubLaboresLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.sublaborNombre = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubLaboresLocalCompanion.insert({
    required String id,
    required String registroId,
    required String sublaborNombre,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId),
        sublaborNombre = Value(sublaborNombre);
  static Insertable<SubLaboresLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<String>? sublaborNombre,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (sublaborNombre != null) 'sublabor_nombre': sublaborNombre,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubLaboresLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<String>? sublaborNombre,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SubLaboresLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      sublaborNombre: sublaborNombre ?? this.sublaborNombre,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (sublaborNombre.present) {
      map['sublabor_nombre'] = Variable<String>(sublaborNombre.value);
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
    return (StringBuffer('SubLaboresLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('sublaborNombre: $sublaborNombre, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MarchasLocalTable extends MarchasLocal
    with TableInfo<$MarchasLocalTable, MarchasLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarchasLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _registroIdMeta =
      const VerificationMeta('registroId');
  @override
  late final GeneratedColumn<String> registroId = GeneratedColumn<String>(
      'registro_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _marchaCodigoMeta =
      const VerificationMeta('marchaCodigo');
  @override
  late final GeneratedColumn<String> marchaCodigo = GeneratedColumn<String>(
      'marcha_codigo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _horasUsoMeta =
      const VerificationMeta('horasUso');
  @override
  late final GeneratedColumn<double> horasUso = GeneratedColumn<double>(
      'horas_uso', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, registroId, marchaCodigo, horasUso, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'marchas_local';
  @override
  VerificationContext validateIntegrity(Insertable<MarchasLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('registro_id')) {
      context.handle(
          _registroIdMeta,
          registroId.isAcceptableOrUnknown(
              data['registro_id']!, _registroIdMeta));
    } else if (isInserting) {
      context.missing(_registroIdMeta);
    }
    if (data.containsKey('marcha_codigo')) {
      context.handle(
          _marchaCodigoMeta,
          marchaCodigo.isAcceptableOrUnknown(
              data['marcha_codigo']!, _marchaCodigoMeta));
    } else if (isInserting) {
      context.missing(_marchaCodigoMeta);
    }
    if (data.containsKey('horas_uso')) {
      context.handle(_horasUsoMeta,
          horasUso.isAcceptableOrUnknown(data['horas_uso']!, _horasUsoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MarchasLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarchasLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      registroId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}registro_id'])!,
      marchaCodigo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}marcha_codigo'])!,
      horasUso: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}horas_uso']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MarchasLocalTable createAlias(String alias) {
    return $MarchasLocalTable(attachedDatabase, alias);
  }
}

class MarchasLocalData extends DataClass
    implements Insertable<MarchasLocalData> {
  final String id;
  final String registroId;

  /// Código de marcha: T-1..T-4, H-1..H-4, L-1..L-4
  final String marchaCodigo;
  final double? horasUso;
  final DateTime createdAt;
  const MarchasLocalData(
      {required this.id,
      required this.registroId,
      required this.marchaCodigo,
      this.horasUso,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['registro_id'] = Variable<String>(registroId);
    map['marcha_codigo'] = Variable<String>(marchaCodigo);
    if (!nullToAbsent || horasUso != null) {
      map['horas_uso'] = Variable<double>(horasUso);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MarchasLocalCompanion toCompanion(bool nullToAbsent) {
    return MarchasLocalCompanion(
      id: Value(id),
      registroId: Value(registroId),
      marchaCodigo: Value(marchaCodigo),
      horasUso: horasUso == null && nullToAbsent
          ? const Value.absent()
          : Value(horasUso),
      createdAt: Value(createdAt),
    );
  }

  factory MarchasLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarchasLocalData(
      id: serializer.fromJson<String>(json['id']),
      registroId: serializer.fromJson<String>(json['registroId']),
      marchaCodigo: serializer.fromJson<String>(json['marchaCodigo']),
      horasUso: serializer.fromJson<double?>(json['horasUso']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'registroId': serializer.toJson<String>(registroId),
      'marchaCodigo': serializer.toJson<String>(marchaCodigo),
      'horasUso': serializer.toJson<double?>(horasUso),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MarchasLocalData copyWith(
          {String? id,
          String? registroId,
          String? marchaCodigo,
          Value<double?> horasUso = const Value.absent(),
          DateTime? createdAt}) =>
      MarchasLocalData(
        id: id ?? this.id,
        registroId: registroId ?? this.registroId,
        marchaCodigo: marchaCodigo ?? this.marchaCodigo,
        horasUso: horasUso.present ? horasUso.value : this.horasUso,
        createdAt: createdAt ?? this.createdAt,
      );
  MarchasLocalData copyWithCompanion(MarchasLocalCompanion data) {
    return MarchasLocalData(
      id: data.id.present ? data.id.value : this.id,
      registroId:
          data.registroId.present ? data.registroId.value : this.registroId,
      marchaCodigo: data.marchaCodigo.present
          ? data.marchaCodigo.value
          : this.marchaCodigo,
      horasUso: data.horasUso.present ? data.horasUso.value : this.horasUso,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarchasLocalData(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('marchaCodigo: $marchaCodigo, ')
          ..write('horasUso: $horasUso, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, registroId, marchaCodigo, horasUso, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarchasLocalData &&
          other.id == this.id &&
          other.registroId == this.registroId &&
          other.marchaCodigo == this.marchaCodigo &&
          other.horasUso == this.horasUso &&
          other.createdAt == this.createdAt);
}

class MarchasLocalCompanion extends UpdateCompanion<MarchasLocalData> {
  final Value<String> id;
  final Value<String> registroId;
  final Value<String> marchaCodigo;
  final Value<double?> horasUso;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MarchasLocalCompanion({
    this.id = const Value.absent(),
    this.registroId = const Value.absent(),
    this.marchaCodigo = const Value.absent(),
    this.horasUso = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MarchasLocalCompanion.insert({
    required String id,
    required String registroId,
    required String marchaCodigo,
    this.horasUso = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        registroId = Value(registroId),
        marchaCodigo = Value(marchaCodigo);
  static Insertable<MarchasLocalData> custom({
    Expression<String>? id,
    Expression<String>? registroId,
    Expression<String>? marchaCodigo,
    Expression<double>? horasUso,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registroId != null) 'registro_id': registroId,
      if (marchaCodigo != null) 'marcha_codigo': marchaCodigo,
      if (horasUso != null) 'horas_uso': horasUso,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MarchasLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? registroId,
      Value<String>? marchaCodigo,
      Value<double?>? horasUso,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MarchasLocalCompanion(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      marchaCodigo: marchaCodigo ?? this.marchaCodigo,
      horasUso: horasUso ?? this.horasUso,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (registroId.present) {
      map['registro_id'] = Variable<String>(registroId.value);
    }
    if (marchaCodigo.present) {
      map['marcha_codigo'] = Variable<String>(marchaCodigo.value);
    }
    if (horasUso.present) {
      map['horas_uso'] = Variable<double>(horasUso.value);
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
    return (StringBuffer('MarchasLocalCompanion(')
          ..write('id: $id, ')
          ..write('registroId: $registroId, ')
          ..write('marchaCodigo: $marchaCodigo, ')
          ..write('horasUso: $horasUso, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncumplimientosLocalTable extends IncumplimientosLocal
    with TableInfo<$IncumplimientosLocalTable, IncumplimientosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncumplimientosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usuarioErpIdMeta =
      const VerificationMeta('usuarioErpId');
  @override
  late final GeneratedColumn<int> usuarioErpId = GeneratedColumn<int>(
      'usuario_erp_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nombreUsuarioMeta =
      const VerificationMeta('nombreUsuario');
  @override
  late final GeneratedColumn<String> nombreUsuario = GeneratedColumn<String>(
      'nombre_usuario', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _fechaJornadaMeta =
      const VerificationMeta('fechaJornada');
  @override
  late final GeneratedColumn<DateTime> fechaJornada = GeneratedColumn<DateTime>(
      'fecha_jornada', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _turnoMeta = const VerificationMeta('turno');
  @override
  late final GeneratedColumn<String> turno = GeneratedColumn<String>(
      'turno', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('dia'));
  static const VerificationMeta _tipoIncumplimientoMeta =
      const VerificationMeta('tipoIncumplimiento');
  @override
  late final GeneratedColumn<String> tipoIncumplimiento =
      GeneratedColumn<String>('tipo_incumplimiento', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detalleMeta =
      const VerificationMeta('detalle');
  @override
  late final GeneratedColumn<String> detalle = GeneratedColumn<String>(
      'detalle', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dispositivoIdMeta =
      const VerificationMeta('dispositivoId');
  @override
  late final GeneratedColumn<String> dispositivoId = GeneratedColumn<String>(
      'dispositivo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _firestoreDocIdMeta =
      const VerificationMeta('firestoreDocId');
  @override
  late final GeneratedColumn<String> firestoreDocId = GeneratedColumn<String>(
      'firestore_doc_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sincronizadoMeta =
      const VerificationMeta('sincronizado');
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
      'sincronizado', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sincronizado" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        usuarioErpId,
        nombreUsuario,
        fechaJornada,
        turno,
        tipoIncumplimiento,
        detalle,
        dispositivoId,
        firestoreDocId,
        sincronizado,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incumplimientos_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<IncumplimientosLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_erp_id')) {
      context.handle(
          _usuarioErpIdMeta,
          usuarioErpId.isAcceptableOrUnknown(
              data['usuario_erp_id']!, _usuarioErpIdMeta));
    } else if (isInserting) {
      context.missing(_usuarioErpIdMeta);
    }
    if (data.containsKey('nombre_usuario')) {
      context.handle(
          _nombreUsuarioMeta,
          nombreUsuario.isAcceptableOrUnknown(
              data['nombre_usuario']!, _nombreUsuarioMeta));
    }
    if (data.containsKey('fecha_jornada')) {
      context.handle(
          _fechaJornadaMeta,
          fechaJornada.isAcceptableOrUnknown(
              data['fecha_jornada']!, _fechaJornadaMeta));
    } else if (isInserting) {
      context.missing(_fechaJornadaMeta);
    }
    if (data.containsKey('turno')) {
      context.handle(
          _turnoMeta, turno.isAcceptableOrUnknown(data['turno']!, _turnoMeta));
    }
    if (data.containsKey('tipo_incumplimiento')) {
      context.handle(
          _tipoIncumplimientoMeta,
          tipoIncumplimiento.isAcceptableOrUnknown(
              data['tipo_incumplimiento']!, _tipoIncumplimientoMeta));
    } else if (isInserting) {
      context.missing(_tipoIncumplimientoMeta);
    }
    if (data.containsKey('detalle')) {
      context.handle(_detalleMeta,
          detalle.isAcceptableOrUnknown(data['detalle']!, _detalleMeta));
    }
    if (data.containsKey('dispositivo_id')) {
      context.handle(
          _dispositivoIdMeta,
          dispositivoId.isAcceptableOrUnknown(
              data['dispositivo_id']!, _dispositivoIdMeta));
    }
    if (data.containsKey('firestore_doc_id')) {
      context.handle(
          _firestoreDocIdMeta,
          firestoreDocId.isAcceptableOrUnknown(
              data['firestore_doc_id']!, _firestoreDocIdMeta));
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
          _sincronizadoMeta,
          sincronizado.isAcceptableOrUnknown(
              data['sincronizado']!, _sincronizadoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncumplimientosLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncumplimientosLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      usuarioErpId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usuario_erp_id'])!,
      nombreUsuario: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nombre_usuario'])!,
      fechaJornada: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}fecha_jornada'])!,
      turno: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}turno'])!,
      tipoIncumplimiento: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tipo_incumplimiento'])!,
      detalle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}detalle']),
      dispositivoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dispositivo_id']),
      firestoreDocId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}firestore_doc_id']),
      sincronizado: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sincronizado'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IncumplimientosLocalTable createAlias(String alias) {
    return $IncumplimientosLocalTable(attachedDatabase, alias);
  }
}

class IncumplimientosLocalData extends DataClass
    implements Insertable<IncumplimientosLocalData> {
  final String id;
  final int usuarioErpId;
  final String nombreUsuario;
  final DateTime fechaJornada;

  /// 'dia' | 'noche'
  final String turno;

  /// 'cierre_sin_sincronizar' | 'jornada_100_pct' | 'retraso_excesivo'
  final String tipoIncumplimiento;
  final String? detalle;
  final String? dispositivoId;
  final String? firestoreDocId;
  final bool sincronizado;
  final DateTime createdAt;
  const IncumplimientosLocalData(
      {required this.id,
      required this.usuarioErpId,
      required this.nombreUsuario,
      required this.fechaJornada,
      required this.turno,
      required this.tipoIncumplimiento,
      this.detalle,
      this.dispositivoId,
      this.firestoreDocId,
      required this.sincronizado,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_erp_id'] = Variable<int>(usuarioErpId);
    map['nombre_usuario'] = Variable<String>(nombreUsuario);
    map['fecha_jornada'] = Variable<DateTime>(fechaJornada);
    map['turno'] = Variable<String>(turno);
    map['tipo_incumplimiento'] = Variable<String>(tipoIncumplimiento);
    if (!nullToAbsent || detalle != null) {
      map['detalle'] = Variable<String>(detalle);
    }
    if (!nullToAbsent || dispositivoId != null) {
      map['dispositivo_id'] = Variable<String>(dispositivoId);
    }
    if (!nullToAbsent || firestoreDocId != null) {
      map['firestore_doc_id'] = Variable<String>(firestoreDocId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IncumplimientosLocalCompanion toCompanion(bool nullToAbsent) {
    return IncumplimientosLocalCompanion(
      id: Value(id),
      usuarioErpId: Value(usuarioErpId),
      nombreUsuario: Value(nombreUsuario),
      fechaJornada: Value(fechaJornada),
      turno: Value(turno),
      tipoIncumplimiento: Value(tipoIncumplimiento),
      detalle: detalle == null && nullToAbsent
          ? const Value.absent()
          : Value(detalle),
      dispositivoId: dispositivoId == null && nullToAbsent
          ? const Value.absent()
          : Value(dispositivoId),
      firestoreDocId: firestoreDocId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreDocId),
      sincronizado: Value(sincronizado),
      createdAt: Value(createdAt),
    );
  }

  factory IncumplimientosLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncumplimientosLocalData(
      id: serializer.fromJson<String>(json['id']),
      usuarioErpId: serializer.fromJson<int>(json['usuarioErpId']),
      nombreUsuario: serializer.fromJson<String>(json['nombreUsuario']),
      fechaJornada: serializer.fromJson<DateTime>(json['fechaJornada']),
      turno: serializer.fromJson<String>(json['turno']),
      tipoIncumplimiento:
          serializer.fromJson<String>(json['tipoIncumplimiento']),
      detalle: serializer.fromJson<String?>(json['detalle']),
      dispositivoId: serializer.fromJson<String?>(json['dispositivoId']),
      firestoreDocId: serializer.fromJson<String?>(json['firestoreDocId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioErpId': serializer.toJson<int>(usuarioErpId),
      'nombreUsuario': serializer.toJson<String>(nombreUsuario),
      'fechaJornada': serializer.toJson<DateTime>(fechaJornada),
      'turno': serializer.toJson<String>(turno),
      'tipoIncumplimiento': serializer.toJson<String>(tipoIncumplimiento),
      'detalle': serializer.toJson<String?>(detalle),
      'dispositivoId': serializer.toJson<String?>(dispositivoId),
      'firestoreDocId': serializer.toJson<String?>(firestoreDocId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IncumplimientosLocalData copyWith(
          {String? id,
          int? usuarioErpId,
          String? nombreUsuario,
          DateTime? fechaJornada,
          String? turno,
          String? tipoIncumplimiento,
          Value<String?> detalle = const Value.absent(),
          Value<String?> dispositivoId = const Value.absent(),
          Value<String?> firestoreDocId = const Value.absent(),
          bool? sincronizado,
          DateTime? createdAt}) =>
      IncumplimientosLocalData(
        id: id ?? this.id,
        usuarioErpId: usuarioErpId ?? this.usuarioErpId,
        nombreUsuario: nombreUsuario ?? this.nombreUsuario,
        fechaJornada: fechaJornada ?? this.fechaJornada,
        turno: turno ?? this.turno,
        tipoIncumplimiento: tipoIncumplimiento ?? this.tipoIncumplimiento,
        detalle: detalle.present ? detalle.value : this.detalle,
        dispositivoId:
            dispositivoId.present ? dispositivoId.value : this.dispositivoId,
        firestoreDocId:
            firestoreDocId.present ? firestoreDocId.value : this.firestoreDocId,
        sincronizado: sincronizado ?? this.sincronizado,
        createdAt: createdAt ?? this.createdAt,
      );
  IncumplimientosLocalData copyWithCompanion(
      IncumplimientosLocalCompanion data) {
    return IncumplimientosLocalData(
      id: data.id.present ? data.id.value : this.id,
      usuarioErpId: data.usuarioErpId.present
          ? data.usuarioErpId.value
          : this.usuarioErpId,
      nombreUsuario: data.nombreUsuario.present
          ? data.nombreUsuario.value
          : this.nombreUsuario,
      fechaJornada: data.fechaJornada.present
          ? data.fechaJornada.value
          : this.fechaJornada,
      turno: data.turno.present ? data.turno.value : this.turno,
      tipoIncumplimiento: data.tipoIncumplimiento.present
          ? data.tipoIncumplimiento.value
          : this.tipoIncumplimiento,
      detalle: data.detalle.present ? data.detalle.value : this.detalle,
      dispositivoId: data.dispositivoId.present
          ? data.dispositivoId.value
          : this.dispositivoId,
      firestoreDocId: data.firestoreDocId.present
          ? data.firestoreDocId.value
          : this.firestoreDocId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncumplimientosLocalData(')
          ..write('id: $id, ')
          ..write('usuarioErpId: $usuarioErpId, ')
          ..write('nombreUsuario: $nombreUsuario, ')
          ..write('fechaJornada: $fechaJornada, ')
          ..write('turno: $turno, ')
          ..write('tipoIncumplimiento: $tipoIncumplimiento, ')
          ..write('detalle: $detalle, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('firestoreDocId: $firestoreDocId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      usuarioErpId,
      nombreUsuario,
      fechaJornada,
      turno,
      tipoIncumplimiento,
      detalle,
      dispositivoId,
      firestoreDocId,
      sincronizado,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncumplimientosLocalData &&
          other.id == this.id &&
          other.usuarioErpId == this.usuarioErpId &&
          other.nombreUsuario == this.nombreUsuario &&
          other.fechaJornada == this.fechaJornada &&
          other.turno == this.turno &&
          other.tipoIncumplimiento == this.tipoIncumplimiento &&
          other.detalle == this.detalle &&
          other.dispositivoId == this.dispositivoId &&
          other.firestoreDocId == this.firestoreDocId &&
          other.sincronizado == this.sincronizado &&
          other.createdAt == this.createdAt);
}

class IncumplimientosLocalCompanion
    extends UpdateCompanion<IncumplimientosLocalData> {
  final Value<String> id;
  final Value<int> usuarioErpId;
  final Value<String> nombreUsuario;
  final Value<DateTime> fechaJornada;
  final Value<String> turno;
  final Value<String> tipoIncumplimiento;
  final Value<String?> detalle;
  final Value<String?> dispositivoId;
  final Value<String?> firestoreDocId;
  final Value<bool> sincronizado;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const IncumplimientosLocalCompanion({
    this.id = const Value.absent(),
    this.usuarioErpId = const Value.absent(),
    this.nombreUsuario = const Value.absent(),
    this.fechaJornada = const Value.absent(),
    this.turno = const Value.absent(),
    this.tipoIncumplimiento = const Value.absent(),
    this.detalle = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.firestoreDocId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncumplimientosLocalCompanion.insert({
    required String id,
    required int usuarioErpId,
    this.nombreUsuario = const Value.absent(),
    required DateTime fechaJornada,
    this.turno = const Value.absent(),
    required String tipoIncumplimiento,
    this.detalle = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.firestoreDocId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        usuarioErpId = Value(usuarioErpId),
        fechaJornada = Value(fechaJornada),
        tipoIncumplimiento = Value(tipoIncumplimiento);
  static Insertable<IncumplimientosLocalData> custom({
    Expression<String>? id,
    Expression<int>? usuarioErpId,
    Expression<String>? nombreUsuario,
    Expression<DateTime>? fechaJornada,
    Expression<String>? turno,
    Expression<String>? tipoIncumplimiento,
    Expression<String>? detalle,
    Expression<String>? dispositivoId,
    Expression<String>? firestoreDocId,
    Expression<bool>? sincronizado,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioErpId != null) 'usuario_erp_id': usuarioErpId,
      if (nombreUsuario != null) 'nombre_usuario': nombreUsuario,
      if (fechaJornada != null) 'fecha_jornada': fechaJornada,
      if (turno != null) 'turno': turno,
      if (tipoIncumplimiento != null) 'tipo_incumplimiento': tipoIncumplimiento,
      if (detalle != null) 'detalle': detalle,
      if (dispositivoId != null) 'dispositivo_id': dispositivoId,
      if (firestoreDocId != null) 'firestore_doc_id': firestoreDocId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncumplimientosLocalCompanion copyWith(
      {Value<String>? id,
      Value<int>? usuarioErpId,
      Value<String>? nombreUsuario,
      Value<DateTime>? fechaJornada,
      Value<String>? turno,
      Value<String>? tipoIncumplimiento,
      Value<String?>? detalle,
      Value<String?>? dispositivoId,
      Value<String?>? firestoreDocId,
      Value<bool>? sincronizado,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return IncumplimientosLocalCompanion(
      id: id ?? this.id,
      usuarioErpId: usuarioErpId ?? this.usuarioErpId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      fechaJornada: fechaJornada ?? this.fechaJornada,
      turno: turno ?? this.turno,
      tipoIncumplimiento: tipoIncumplimiento ?? this.tipoIncumplimiento,
      detalle: detalle ?? this.detalle,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      sincronizado: sincronizado ?? this.sincronizado,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioErpId.present) {
      map['usuario_erp_id'] = Variable<int>(usuarioErpId.value);
    }
    if (nombreUsuario.present) {
      map['nombre_usuario'] = Variable<String>(nombreUsuario.value);
    }
    if (fechaJornada.present) {
      map['fecha_jornada'] = Variable<DateTime>(fechaJornada.value);
    }
    if (turno.present) {
      map['turno'] = Variable<String>(turno.value);
    }
    if (tipoIncumplimiento.present) {
      map['tipo_incumplimiento'] = Variable<String>(tipoIncumplimiento.value);
    }
    if (detalle.present) {
      map['detalle'] = Variable<String>(detalle.value);
    }
    if (dispositivoId.present) {
      map['dispositivo_id'] = Variable<String>(dispositivoId.value);
    }
    if (firestoreDocId.present) {
      map['firestore_doc_id'] = Variable<String>(firestoreDocId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
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
    return (StringBuffer('IncumplimientosLocalCompanion(')
          ..write('id: $id, ')
          ..write('usuarioErpId: $usuarioErpId, ')
          ..write('nombreUsuario: $nombreUsuario, ')
          ..write('fechaJornada: $fechaJornada, ')
          ..write('turno: $turno, ')
          ..write('tipoIncumplimiento: $tipoIncumplimiento, ')
          ..write('detalle: $detalle, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('firestoreDocId: $firestoreDocId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $ProcesosLocalTable procesosLocal = $ProcesosLocalTable(this);
  late final $CajasCambiosLocalTable cajasCambiosLocal =
      $CajasCambiosLocalTable(this);
  late final $TiposParoLocalTable tiposParoLocal = $TiposParoLocalTable(this);
  late final $ChecklistCategoriasLocalTable checklistCategoriasLocal =
      $ChecklistCategoriasLocalTable(this);
  late final $ChecklistItemsLocalTable checklistItemsLocal =
      $ChecklistItemsLocalTable(this);
  late final $CultivosLocalTable cultivosLocal = $CultivosLocalTable(this);
  late final $TractoresLocalTable tractoresLocal = $TractoresLocalTable(this);
  late final $ImplementosLocalTable implementosLocal =
      $ImplementosLocalTable(this);
  late final $TrabajadoresLocalTable trabajadoresLocal =
      $TrabajadoresLocalTable(this);
  late final $LotesLocalTable lotesLocal = $LotesLocalTable(this);
  late final $SectoresLocalTable sectoresLocal = $SectoresLocalTable(this);
  late final $SubprocesosLocalTable subprocesosLocal =
      $SubprocesosLocalTable(this);
  late final $MenusLocalTable menusLocal = $MenusLocalTable(this);
  late final $RegistrosDiariosLocalTable registrosDiariosLocal =
      $RegistrosDiariosLocalTable(this);
  late final $HorometrosLocalTable horometrosLocal =
      $HorometrosLocalTable(this);
  late final $TiemposTurnoLocalTable tiemposTurnoLocal =
      $TiemposTurnoLocalTable(this);
  late final $RegistrosSectoresLocalTable registrosSectoresLocal =
      $RegistrosSectoresLocalTable(this);
  late final $CosechaBinesLocalTable cosechaBinesLocal =
      $CosechaBinesLocalTable(this);
  late final $ParosEquiposLocalTable parosEquiposLocal =
      $ParosEquiposLocalTable(this);
  late final $ChecklistResultadosLocalTable checklistResultadosLocal =
      $ChecklistResultadosLocalTable(this);
  late final $RegistrosVehiculoLocalTable registrosVehiculoLocal =
      $RegistrosVehiculoLocalTable(this);
  late final $CombustibleVehiculoLocalTable combustibleVehiculoLocal =
      $CombustibleVehiculoLocalTable(this);
  late final $PorteroLecturasLocalTable porteroLecturasLocal =
      $PorteroLecturasLocalTable(this);
  late final $SubLaboresLocalTable subLaboresLocal =
      $SubLaboresLocalTable(this);
  late final $MarchasLocalTable marchasLocal = $MarchasLocalTable(this);
  late final $IncumplimientosLocalTable incumplimientosLocal =
      $IncumplimientosLocalTable(this);
  late final OutboxDao outboxDao = OutboxDao(this as AppDatabase);
  late final CatalogoDao catalogoDao = CatalogoDao(this as AppDatabase);
  late final RegistroDao registroDao = RegistroDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        outboxEntries,
        procesosLocal,
        cajasCambiosLocal,
        tiposParoLocal,
        checklistCategoriasLocal,
        checklistItemsLocal,
        cultivosLocal,
        tractoresLocal,
        implementosLocal,
        trabajadoresLocal,
        lotesLocal,
        sectoresLocal,
        subprocesosLocal,
        menusLocal,
        registrosDiariosLocal,
        horometrosLocal,
        tiemposTurnoLocal,
        registrosSectoresLocal,
        cosechaBinesLocal,
        parosEquiposLocal,
        checklistResultadosLocal,
        registrosVehiculoLocal,
        combustibleVehiculoLocal,
        porteroLecturasLocal,
        subLaboresLocal,
        marchasLocal,
        incumplimientosLocal
      ];
}

typedef $$OutboxEntriesTableCreateCompanionBuilder = OutboxEntriesCompanion
    Function({
  Value<int> id,
  Value<String?> registroLocalId,
  required String endpoint,
  required String method,
  required String payloadJson,
  Value<DateTime> timestamp,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
});
typedef $$OutboxEntriesTableUpdateCompanionBuilder = OutboxEntriesCompanion
    Function({
  Value<int> id,
  Value<String?> registroLocalId,
  Value<String> endpoint,
  Value<String> method,
  Value<String> payloadJson,
  Value<DateTime> timestamp,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
});

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroLocalId => $composableBuilder(
      column: $table.registroLocalId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroLocalId => $composableBuilder(
      column: $table.registroLocalId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroLocalId => $composableBuilder(
      column: $table.registroLocalId, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxEntriesTable,
    OutboxEntry,
    $$OutboxEntriesTableFilterComposer,
    $$OutboxEntriesTableOrderingComposer,
    $$OutboxEntriesTableAnnotationComposer,
    $$OutboxEntriesTableCreateCompanionBuilder,
    $$OutboxEntriesTableUpdateCompanionBuilder,
    (
      OutboxEntry,
      BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>
    ),
    OutboxEntry,
    PrefetchHooks Function()> {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> registroLocalId = const Value.absent(),
            Value<String> endpoint = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
          }) =>
              OutboxEntriesCompanion(
            id: id,
            registroLocalId: registroLocalId,
            endpoint: endpoint,
            method: method,
            payloadJson: payloadJson,
            timestamp: timestamp,
            status: status,
            retryCount: retryCount,
            errorMessage: errorMessage,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> registroLocalId = const Value.absent(),
            required String endpoint,
            required String method,
            required String payloadJson,
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
          }) =>
              OutboxEntriesCompanion.insert(
            id: id,
            registroLocalId: registroLocalId,
            endpoint: endpoint,
            method: method,
            payloadJson: payloadJson,
            timestamp: timestamp,
            status: status,
            retryCount: retryCount,
            errorMessage: errorMessage,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxEntriesTable,
    OutboxEntry,
    $$OutboxEntriesTableFilterComposer,
    $$OutboxEntriesTableOrderingComposer,
    $$OutboxEntriesTableAnnotationComposer,
    $$OutboxEntriesTableCreateCompanionBuilder,
    $$OutboxEntriesTableUpdateCompanionBuilder,
    (
      OutboxEntry,
      BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>
    ),
    OutboxEntry,
    PrefetchHooks Function()>;
typedef $$ProcesosLocalTableCreateCompanionBuilder = ProcesosLocalCompanion
    Function({
  Value<int> id,
  required String nombre,
  required String codigo,
  Value<bool> requiereBines,
  Value<bool> activo,
});
typedef $$ProcesosLocalTableUpdateCompanionBuilder = ProcesosLocalCompanion
    Function({
  Value<int> id,
  Value<String> nombre,
  Value<String> codigo,
  Value<bool> requiereBines,
  Value<bool> activo,
});

class $$ProcesosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ProcesosLocalTable> {
  $$ProcesosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiereBines => $composableBuilder(
      column: $table.requiereBines, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));
}

class $$ProcesosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcesosLocalTable> {
  $$ProcesosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiereBines => $composableBuilder(
      column: $table.requiereBines,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));
}

class $$ProcesosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcesosLocalTable> {
  $$ProcesosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<bool> get requiereBines => $composableBuilder(
      column: $table.requiereBines, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$ProcesosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProcesosLocalTable,
    ProcesosLocalData,
    $$ProcesosLocalTableFilterComposer,
    $$ProcesosLocalTableOrderingComposer,
    $$ProcesosLocalTableAnnotationComposer,
    $$ProcesosLocalTableCreateCompanionBuilder,
    $$ProcesosLocalTableUpdateCompanionBuilder,
    (
      ProcesosLocalData,
      BaseReferences<_$AppDatabase, $ProcesosLocalTable, ProcesosLocalData>
    ),
    ProcesosLocalData,
    PrefetchHooks Function()> {
  $$ProcesosLocalTableTableManager(_$AppDatabase db, $ProcesosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcesosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcesosLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcesosLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nombre = const Value.absent(),
            Value<String> codigo = const Value.absent(),
            Value<bool> requiereBines = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              ProcesosLocalCompanion(
            id: id,
            nombre: nombre,
            codigo: codigo,
            requiereBines: requiereBines,
            activo: activo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nombre,
            required String codigo,
            Value<bool> requiereBines = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              ProcesosLocalCompanion.insert(
            id: id,
            nombre: nombre,
            codigo: codigo,
            requiereBines: requiereBines,
            activo: activo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProcesosLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProcesosLocalTable,
    ProcesosLocalData,
    $$ProcesosLocalTableFilterComposer,
    $$ProcesosLocalTableOrderingComposer,
    $$ProcesosLocalTableAnnotationComposer,
    $$ProcesosLocalTableCreateCompanionBuilder,
    $$ProcesosLocalTableUpdateCompanionBuilder,
    (
      ProcesosLocalData,
      BaseReferences<_$AppDatabase, $ProcesosLocalTable, ProcesosLocalData>
    ),
    ProcesosLocalData,
    PrefetchHooks Function()>;
typedef $$CajasCambiosLocalTableCreateCompanionBuilder
    = CajasCambiosLocalCompanion Function({
  Value<int> id,
  required String nombre,
});
typedef $$CajasCambiosLocalTableUpdateCompanionBuilder
    = CajasCambiosLocalCompanion Function({
  Value<int> id,
  Value<String> nombre,
});

class $$CajasCambiosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CajasCambiosLocalTable> {
  $$CajasCambiosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));
}

class $$CajasCambiosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CajasCambiosLocalTable> {
  $$CajasCambiosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));
}

class $$CajasCambiosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CajasCambiosLocalTable> {
  $$CajasCambiosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);
}

class $$CajasCambiosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CajasCambiosLocalTable,
    CajasCambiosLocalData,
    $$CajasCambiosLocalTableFilterComposer,
    $$CajasCambiosLocalTableOrderingComposer,
    $$CajasCambiosLocalTableAnnotationComposer,
    $$CajasCambiosLocalTableCreateCompanionBuilder,
    $$CajasCambiosLocalTableUpdateCompanionBuilder,
    (
      CajasCambiosLocalData,
      BaseReferences<_$AppDatabase, $CajasCambiosLocalTable,
          CajasCambiosLocalData>
    ),
    CajasCambiosLocalData,
    PrefetchHooks Function()> {
  $$CajasCambiosLocalTableTableManager(
      _$AppDatabase db, $CajasCambiosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CajasCambiosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CajasCambiosLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CajasCambiosLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nombre = const Value.absent(),
          }) =>
              CajasCambiosLocalCompanion(
            id: id,
            nombre: nombre,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nombre,
          }) =>
              CajasCambiosLocalCompanion.insert(
            id: id,
            nombre: nombre,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CajasCambiosLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CajasCambiosLocalTable,
    CajasCambiosLocalData,
    $$CajasCambiosLocalTableFilterComposer,
    $$CajasCambiosLocalTableOrderingComposer,
    $$CajasCambiosLocalTableAnnotationComposer,
    $$CajasCambiosLocalTableCreateCompanionBuilder,
    $$CajasCambiosLocalTableUpdateCompanionBuilder,
    (
      CajasCambiosLocalData,
      BaseReferences<_$AppDatabase, $CajasCambiosLocalTable,
          CajasCambiosLocalData>
    ),
    CajasCambiosLocalData,
    PrefetchHooks Function()>;
typedef $$TiposParoLocalTableCreateCompanionBuilder = TiposParoLocalCompanion
    Function({
  Value<int> id,
  required String codigo,
  required String nombre,
  Value<bool> requiereGalones,
  Value<bool> requiereEquipo,
  Value<bool> activo,
});
typedef $$TiposParoLocalTableUpdateCompanionBuilder = TiposParoLocalCompanion
    Function({
  Value<int> id,
  Value<String> codigo,
  Value<String> nombre,
  Value<bool> requiereGalones,
  Value<bool> requiereEquipo,
  Value<bool> activo,
});

class $$TiposParoLocalTableFilterComposer
    extends Composer<_$AppDatabase, $TiposParoLocalTable> {
  $$TiposParoLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiereGalones => $composableBuilder(
      column: $table.requiereGalones,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiereEquipo => $composableBuilder(
      column: $table.requiereEquipo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));
}

class $$TiposParoLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $TiposParoLocalTable> {
  $$TiposParoLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiereGalones => $composableBuilder(
      column: $table.requiereGalones,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiereEquipo => $composableBuilder(
      column: $table.requiereEquipo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));
}

class $$TiposParoLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiposParoLocalTable> {
  $$TiposParoLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<bool> get requiereGalones => $composableBuilder(
      column: $table.requiereGalones, builder: (column) => column);

  GeneratedColumn<bool> get requiereEquipo => $composableBuilder(
      column: $table.requiereEquipo, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$TiposParoLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TiposParoLocalTable,
    TiposParoLocalData,
    $$TiposParoLocalTableFilterComposer,
    $$TiposParoLocalTableOrderingComposer,
    $$TiposParoLocalTableAnnotationComposer,
    $$TiposParoLocalTableCreateCompanionBuilder,
    $$TiposParoLocalTableUpdateCompanionBuilder,
    (
      TiposParoLocalData,
      BaseReferences<_$AppDatabase, $TiposParoLocalTable, TiposParoLocalData>
    ),
    TiposParoLocalData,
    PrefetchHooks Function()> {
  $$TiposParoLocalTableTableManager(
      _$AppDatabase db, $TiposParoLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiposParoLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiposParoLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiposParoLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> codigo = const Value.absent(),
            Value<String> nombre = const Value.absent(),
            Value<bool> requiereGalones = const Value.absent(),
            Value<bool> requiereEquipo = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              TiposParoLocalCompanion(
            id: id,
            codigo: codigo,
            nombre: nombre,
            requiereGalones: requiereGalones,
            requiereEquipo: requiereEquipo,
            activo: activo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String codigo,
            required String nombre,
            Value<bool> requiereGalones = const Value.absent(),
            Value<bool> requiereEquipo = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              TiposParoLocalCompanion.insert(
            id: id,
            codigo: codigo,
            nombre: nombre,
            requiereGalones: requiereGalones,
            requiereEquipo: requiereEquipo,
            activo: activo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TiposParoLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TiposParoLocalTable,
    TiposParoLocalData,
    $$TiposParoLocalTableFilterComposer,
    $$TiposParoLocalTableOrderingComposer,
    $$TiposParoLocalTableAnnotationComposer,
    $$TiposParoLocalTableCreateCompanionBuilder,
    $$TiposParoLocalTableUpdateCompanionBuilder,
    (
      TiposParoLocalData,
      BaseReferences<_$AppDatabase, $TiposParoLocalTable, TiposParoLocalData>
    ),
    TiposParoLocalData,
    PrefetchHooks Function()>;
typedef $$ChecklistCategoriasLocalTableCreateCompanionBuilder
    = ChecklistCategoriasLocalCompanion Function({
  Value<int> id,
  required String nombre,
  Value<int> orden,
});
typedef $$ChecklistCategoriasLocalTableUpdateCompanionBuilder
    = ChecklistCategoriasLocalCompanion Function({
  Value<int> id,
  Value<String> nombre,
  Value<int> orden,
});

class $$ChecklistCategoriasLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistCategoriasLocalTable> {
  $$ChecklistCategoriasLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orden => $composableBuilder(
      column: $table.orden, builder: (column) => ColumnFilters(column));
}

class $$ChecklistCategoriasLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistCategoriasLocalTable> {
  $$ChecklistCategoriasLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orden => $composableBuilder(
      column: $table.orden, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistCategoriasLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistCategoriasLocalTable> {
  $$ChecklistCategoriasLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);
}

class $$ChecklistCategoriasLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChecklistCategoriasLocalTable,
    ChecklistCategoriasLocalData,
    $$ChecklistCategoriasLocalTableFilterComposer,
    $$ChecklistCategoriasLocalTableOrderingComposer,
    $$ChecklistCategoriasLocalTableAnnotationComposer,
    $$ChecklistCategoriasLocalTableCreateCompanionBuilder,
    $$ChecklistCategoriasLocalTableUpdateCompanionBuilder,
    (
      ChecklistCategoriasLocalData,
      BaseReferences<_$AppDatabase, $ChecklistCategoriasLocalTable,
          ChecklistCategoriasLocalData>
    ),
    ChecklistCategoriasLocalData,
    PrefetchHooks Function()> {
  $$ChecklistCategoriasLocalTableTableManager(
      _$AppDatabase db, $ChecklistCategoriasLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistCategoriasLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistCategoriasLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistCategoriasLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nombre = const Value.absent(),
            Value<int> orden = const Value.absent(),
          }) =>
              ChecklistCategoriasLocalCompanion(
            id: id,
            nombre: nombre,
            orden: orden,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nombre,
            Value<int> orden = const Value.absent(),
          }) =>
              ChecklistCategoriasLocalCompanion.insert(
            id: id,
            nombre: nombre,
            orden: orden,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistCategoriasLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ChecklistCategoriasLocalTable,
        ChecklistCategoriasLocalData,
        $$ChecklistCategoriasLocalTableFilterComposer,
        $$ChecklistCategoriasLocalTableOrderingComposer,
        $$ChecklistCategoriasLocalTableAnnotationComposer,
        $$ChecklistCategoriasLocalTableCreateCompanionBuilder,
        $$ChecklistCategoriasLocalTableUpdateCompanionBuilder,
        (
          ChecklistCategoriasLocalData,
          BaseReferences<_$AppDatabase, $ChecklistCategoriasLocalTable,
              ChecklistCategoriasLocalData>
        ),
        ChecklistCategoriasLocalData,
        PrefetchHooks Function()>;
typedef $$ChecklistItemsLocalTableCreateCompanionBuilder
    = ChecklistItemsLocalCompanion Function({
  Value<int> id,
  required int categoriaId,
  Value<String> categoriaNombre,
  required String nombre,
  Value<int> orden,
  Value<String> tipoRegistro,
  Value<bool> activo,
});
typedef $$ChecklistItemsLocalTableUpdateCompanionBuilder
    = ChecklistItemsLocalCompanion Function({
  Value<int> id,
  Value<int> categoriaId,
  Value<String> categoriaNombre,
  Value<String> nombre,
  Value<int> orden,
  Value<String> tipoRegistro,
  Value<bool> activo,
});

class $$ChecklistItemsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsLocalTable> {
  $$ChecklistItemsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoriaId => $composableBuilder(
      column: $table.categoriaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoriaNombre => $composableBuilder(
      column: $table.categoriaNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orden => $composableBuilder(
      column: $table.orden, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoRegistro => $composableBuilder(
      column: $table.tipoRegistro, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));
}

class $$ChecklistItemsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsLocalTable> {
  $$ChecklistItemsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoriaId => $composableBuilder(
      column: $table.categoriaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoriaNombre => $composableBuilder(
      column: $table.categoriaNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orden => $composableBuilder(
      column: $table.orden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoRegistro => $composableBuilder(
      column: $table.tipoRegistro,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistItemsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsLocalTable> {
  $$ChecklistItemsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get categoriaId => $composableBuilder(
      column: $table.categoriaId, builder: (column) => column);

  GeneratedColumn<String> get categoriaNombre => $composableBuilder(
      column: $table.categoriaNombre, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<String> get tipoRegistro => $composableBuilder(
      column: $table.tipoRegistro, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$ChecklistItemsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChecklistItemsLocalTable,
    ChecklistItemsLocalData,
    $$ChecklistItemsLocalTableFilterComposer,
    $$ChecklistItemsLocalTableOrderingComposer,
    $$ChecklistItemsLocalTableAnnotationComposer,
    $$ChecklistItemsLocalTableCreateCompanionBuilder,
    $$ChecklistItemsLocalTableUpdateCompanionBuilder,
    (
      ChecklistItemsLocalData,
      BaseReferences<_$AppDatabase, $ChecklistItemsLocalTable,
          ChecklistItemsLocalData>
    ),
    ChecklistItemsLocalData,
    PrefetchHooks Function()> {
  $$ChecklistItemsLocalTableTableManager(
      _$AppDatabase db, $ChecklistItemsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> categoriaId = const Value.absent(),
            Value<String> categoriaNombre = const Value.absent(),
            Value<String> nombre = const Value.absent(),
            Value<int> orden = const Value.absent(),
            Value<String> tipoRegistro = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              ChecklistItemsLocalCompanion(
            id: id,
            categoriaId: categoriaId,
            categoriaNombre: categoriaNombre,
            nombre: nombre,
            orden: orden,
            tipoRegistro: tipoRegistro,
            activo: activo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int categoriaId,
            Value<String> categoriaNombre = const Value.absent(),
            required String nombre,
            Value<int> orden = const Value.absent(),
            Value<String> tipoRegistro = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              ChecklistItemsLocalCompanion.insert(
            id: id,
            categoriaId: categoriaId,
            categoriaNombre: categoriaNombre,
            nombre: nombre,
            orden: orden,
            tipoRegistro: tipoRegistro,
            activo: activo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistItemsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChecklistItemsLocalTable,
    ChecklistItemsLocalData,
    $$ChecklistItemsLocalTableFilterComposer,
    $$ChecklistItemsLocalTableOrderingComposer,
    $$ChecklistItemsLocalTableAnnotationComposer,
    $$ChecklistItemsLocalTableCreateCompanionBuilder,
    $$ChecklistItemsLocalTableUpdateCompanionBuilder,
    (
      ChecklistItemsLocalData,
      BaseReferences<_$AppDatabase, $ChecklistItemsLocalTable,
          ChecklistItemsLocalData>
    ),
    ChecklistItemsLocalData,
    PrefetchHooks Function()>;
typedef $$CultivosLocalTableCreateCompanionBuilder = CultivosLocalCompanion
    Function({
  Value<int> idErp,
  required String codigoEspecie,
  required String nombreEspecie,
  Value<String?> nombreCultivo,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});
typedef $$CultivosLocalTableUpdateCompanionBuilder = CultivosLocalCompanion
    Function({
  Value<int> idErp,
  Value<String> codigoEspecie,
  Value<String> nombreEspecie,
  Value<String?> nombreCultivo,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});

class $$CultivosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CultivosLocalTable> {
  $$CultivosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoEspecie => $composableBuilder(
      column: $table.codigoEspecie, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombreEspecie => $composableBuilder(
      column: $table.nombreEspecie, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombreCultivo => $composableBuilder(
      column: $table.nombreCultivo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnFilters(column));
}

class $$CultivosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CultivosLocalTable> {
  $$CultivosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoEspecie => $composableBuilder(
      column: $table.codigoEspecie,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombreEspecie => $composableBuilder(
      column: $table.nombreEspecie,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombreCultivo => $composableBuilder(
      column: $table.nombreCultivo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnOrderings(column));
}

class $$CultivosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CultivosLocalTable> {
  $$CultivosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idErp =>
      $composableBuilder(column: $table.idErp, builder: (column) => column);

  GeneratedColumn<String> get codigoEspecie => $composableBuilder(
      column: $table.codigoEspecie, builder: (column) => column);

  GeneratedColumn<String> get nombreEspecie => $composableBuilder(
      column: $table.nombreEspecie, builder: (column) => column);

  GeneratedColumn<String> get nombreCultivo => $composableBuilder(
      column: $table.nombreCultivo, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt, builder: (column) => column);
}

class $$CultivosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CultivosLocalTable,
    CultivosLocalData,
    $$CultivosLocalTableFilterComposer,
    $$CultivosLocalTableOrderingComposer,
    $$CultivosLocalTableAnnotationComposer,
    $$CultivosLocalTableCreateCompanionBuilder,
    $$CultivosLocalTableUpdateCompanionBuilder,
    (
      CultivosLocalData,
      BaseReferences<_$AppDatabase, $CultivosLocalTable, CultivosLocalData>
    ),
    CultivosLocalData,
    PrefetchHooks Function()> {
  $$CultivosLocalTableTableManager(_$AppDatabase db, $CultivosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CultivosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CultivosLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CultivosLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            Value<String> codigoEspecie = const Value.absent(),
            Value<String> nombreEspecie = const Value.absent(),
            Value<String?> nombreCultivo = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              CultivosLocalCompanion(
            idErp: idErp,
            codigoEspecie: codigoEspecie,
            nombreEspecie: nombreEspecie,
            nombreCultivo: nombreCultivo,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          createCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            required String codigoEspecie,
            required String nombreEspecie,
            Value<String?> nombreCultivo = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              CultivosLocalCompanion.insert(
            idErp: idErp,
            codigoEspecie: codigoEspecie,
            nombreEspecie: nombreEspecie,
            nombreCultivo: nombreCultivo,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CultivosLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CultivosLocalTable,
    CultivosLocalData,
    $$CultivosLocalTableFilterComposer,
    $$CultivosLocalTableOrderingComposer,
    $$CultivosLocalTableAnnotationComposer,
    $$CultivosLocalTableCreateCompanionBuilder,
    $$CultivosLocalTableUpdateCompanionBuilder,
    (
      CultivosLocalData,
      BaseReferences<_$AppDatabase, $CultivosLocalTable, CultivosLocalData>
    ),
    CultivosLocalData,
    PrefetchHooks Function()>;
typedef $$TractoresLocalTableCreateCompanionBuilder = TractoresLocalCompanion
    Function({
  Value<int> idErp,
  required String codigoTractor,
  required String descripcion,
  Value<String?> marca,
  Value<String?> modelo,
  Value<String?> matricula,
  Value<String?> codigoInterno,
  Value<String?> zona,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});
typedef $$TractoresLocalTableUpdateCompanionBuilder = TractoresLocalCompanion
    Function({
  Value<int> idErp,
  Value<String> codigoTractor,
  Value<String> descripcion,
  Value<String?> marca,
  Value<String?> modelo,
  Value<String?> matricula,
  Value<String?> codigoInterno,
  Value<String?> zona,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});

class $$TractoresLocalTableFilterComposer
    extends Composer<_$AppDatabase, $TractoresLocalTable> {
  $$TractoresLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoTractor => $composableBuilder(
      column: $table.codigoTractor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoInterno => $composableBuilder(
      column: $table.codigoInterno, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnFilters(column));
}

class $$TractoresLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $TractoresLocalTable> {
  $$TractoresLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoTractor => $composableBuilder(
      column: $table.codigoTractor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoInterno => $composableBuilder(
      column: $table.codigoInterno,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnOrderings(column));
}

class $$TractoresLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $TractoresLocalTable> {
  $$TractoresLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idErp =>
      $composableBuilder(column: $table.idErp, builder: (column) => column);

  GeneratedColumn<String> get codigoTractor => $composableBuilder(
      column: $table.codigoTractor, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<String> get matricula =>
      $composableBuilder(column: $table.matricula, builder: (column) => column);

  GeneratedColumn<String> get codigoInterno => $composableBuilder(
      column: $table.codigoInterno, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt, builder: (column) => column);
}

class $$TractoresLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TractoresLocalTable,
    TractoresLocalData,
    $$TractoresLocalTableFilterComposer,
    $$TractoresLocalTableOrderingComposer,
    $$TractoresLocalTableAnnotationComposer,
    $$TractoresLocalTableCreateCompanionBuilder,
    $$TractoresLocalTableUpdateCompanionBuilder,
    (
      TractoresLocalData,
      BaseReferences<_$AppDatabase, $TractoresLocalTable, TractoresLocalData>
    ),
    TractoresLocalData,
    PrefetchHooks Function()> {
  $$TractoresLocalTableTableManager(
      _$AppDatabase db, $TractoresLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TractoresLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TractoresLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TractoresLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            Value<String> codigoTractor = const Value.absent(),
            Value<String> descripcion = const Value.absent(),
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<String?> matricula = const Value.absent(),
            Value<String?> codigoInterno = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              TractoresLocalCompanion(
            idErp: idErp,
            codigoTractor: codigoTractor,
            descripcion: descripcion,
            marca: marca,
            modelo: modelo,
            matricula: matricula,
            codigoInterno: codigoInterno,
            zona: zona,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          createCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            required String codigoTractor,
            required String descripcion,
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<String?> matricula = const Value.absent(),
            Value<String?> codigoInterno = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              TractoresLocalCompanion.insert(
            idErp: idErp,
            codigoTractor: codigoTractor,
            descripcion: descripcion,
            marca: marca,
            modelo: modelo,
            matricula: matricula,
            codigoInterno: codigoInterno,
            zona: zona,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TractoresLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TractoresLocalTable,
    TractoresLocalData,
    $$TractoresLocalTableFilterComposer,
    $$TractoresLocalTableOrderingComposer,
    $$TractoresLocalTableAnnotationComposer,
    $$TractoresLocalTableCreateCompanionBuilder,
    $$TractoresLocalTableUpdateCompanionBuilder,
    (
      TractoresLocalData,
      BaseReferences<_$AppDatabase, $TractoresLocalTable, TractoresLocalData>
    ),
    TractoresLocalData,
    PrefetchHooks Function()>;
typedef $$ImplementosLocalTableCreateCompanionBuilder
    = ImplementosLocalCompanion Function({
  Value<int> idErp,
  required String codigoImplemento,
  required String descripcion,
  Value<String?> marca,
  Value<String?> modelo,
  Value<String?> codigoInterno,
  Value<String?> zona,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});
typedef $$ImplementosLocalTableUpdateCompanionBuilder
    = ImplementosLocalCompanion Function({
  Value<int> idErp,
  Value<String> codigoImplemento,
  Value<String> descripcion,
  Value<String?> marca,
  Value<String?> modelo,
  Value<String?> codigoInterno,
  Value<String?> zona,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});

class $$ImplementosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ImplementosLocalTable> {
  $$ImplementosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoImplemento => $composableBuilder(
      column: $table.codigoImplemento,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoInterno => $composableBuilder(
      column: $table.codigoInterno, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnFilters(column));
}

class $$ImplementosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ImplementosLocalTable> {
  $$ImplementosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoImplemento => $composableBuilder(
      column: $table.codigoImplemento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoInterno => $composableBuilder(
      column: $table.codigoInterno,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ImplementosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImplementosLocalTable> {
  $$ImplementosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idErp =>
      $composableBuilder(column: $table.idErp, builder: (column) => column);

  GeneratedColumn<String> get codigoImplemento => $composableBuilder(
      column: $table.codigoImplemento, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<String> get codigoInterno => $composableBuilder(
      column: $table.codigoInterno, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt, builder: (column) => column);
}

class $$ImplementosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ImplementosLocalTable,
    ImplementosLocalData,
    $$ImplementosLocalTableFilterComposer,
    $$ImplementosLocalTableOrderingComposer,
    $$ImplementosLocalTableAnnotationComposer,
    $$ImplementosLocalTableCreateCompanionBuilder,
    $$ImplementosLocalTableUpdateCompanionBuilder,
    (
      ImplementosLocalData,
      BaseReferences<_$AppDatabase, $ImplementosLocalTable,
          ImplementosLocalData>
    ),
    ImplementosLocalData,
    PrefetchHooks Function()> {
  $$ImplementosLocalTableTableManager(
      _$AppDatabase db, $ImplementosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImplementosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImplementosLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImplementosLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            Value<String> codigoImplemento = const Value.absent(),
            Value<String> descripcion = const Value.absent(),
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<String?> codigoInterno = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              ImplementosLocalCompanion(
            idErp: idErp,
            codigoImplemento: codigoImplemento,
            descripcion: descripcion,
            marca: marca,
            modelo: modelo,
            codigoInterno: codigoInterno,
            zona: zona,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          createCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            required String codigoImplemento,
            required String descripcion,
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<String?> codigoInterno = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              ImplementosLocalCompanion.insert(
            idErp: idErp,
            codigoImplemento: codigoImplemento,
            descripcion: descripcion,
            marca: marca,
            modelo: modelo,
            codigoInterno: codigoInterno,
            zona: zona,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ImplementosLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ImplementosLocalTable,
    ImplementosLocalData,
    $$ImplementosLocalTableFilterComposer,
    $$ImplementosLocalTableOrderingComposer,
    $$ImplementosLocalTableAnnotationComposer,
    $$ImplementosLocalTableCreateCompanionBuilder,
    $$ImplementosLocalTableUpdateCompanionBuilder,
    (
      ImplementosLocalData,
      BaseReferences<_$AppDatabase, $ImplementosLocalTable,
          ImplementosLocalData>
    ),
    ImplementosLocalData,
    PrefetchHooks Function()>;
typedef $$TrabajadoresLocalTableCreateCompanionBuilder
    = TrabajadoresLocalCompanion Function({
  Value<int> idErp,
  Value<int?> usuarioErpId,
  required String codTrabajador,
  Value<String?> codigoBarra,
  required String nombres,
  required String apellidos,
  Value<String?> dni,
  Value<String> rolApk,
  Value<String?> pinHash,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});
typedef $$TrabajadoresLocalTableUpdateCompanionBuilder
    = TrabajadoresLocalCompanion Function({
  Value<int> idErp,
  Value<int?> usuarioErpId,
  Value<String> codTrabajador,
  Value<String?> codigoBarra,
  Value<String> nombres,
  Value<String> apellidos,
  Value<String?> dni,
  Value<String> rolApk,
  Value<String?> pinHash,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
});

class $$TrabajadoresLocalTableFilterComposer
    extends Composer<_$AppDatabase, $TrabajadoresLocalTable> {
  $$TrabajadoresLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usuarioErpId => $composableBuilder(
      column: $table.usuarioErpId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codTrabajador => $composableBuilder(
      column: $table.codTrabajador, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoBarra => $composableBuilder(
      column: $table.codigoBarra, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombres => $composableBuilder(
      column: $table.nombres, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apellidos => $composableBuilder(
      column: $table.apellidos, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dni => $composableBuilder(
      column: $table.dni, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rolApk => $composableBuilder(
      column: $table.rolApk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnFilters(column));
}

class $$TrabajadoresLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $TrabajadoresLocalTable> {
  $$TrabajadoresLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usuarioErpId => $composableBuilder(
      column: $table.usuarioErpId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codTrabajador => $composableBuilder(
      column: $table.codTrabajador,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoBarra => $composableBuilder(
      column: $table.codigoBarra, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombres => $composableBuilder(
      column: $table.nombres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apellidos => $composableBuilder(
      column: $table.apellidos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dni => $composableBuilder(
      column: $table.dni, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rolApk => $composableBuilder(
      column: $table.rolApk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnOrderings(column));
}

class $$TrabajadoresLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrabajadoresLocalTable> {
  $$TrabajadoresLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idErp =>
      $composableBuilder(column: $table.idErp, builder: (column) => column);

  GeneratedColumn<int> get usuarioErpId => $composableBuilder(
      column: $table.usuarioErpId, builder: (column) => column);

  GeneratedColumn<String> get codTrabajador => $composableBuilder(
      column: $table.codTrabajador, builder: (column) => column);

  GeneratedColumn<String> get codigoBarra => $composableBuilder(
      column: $table.codigoBarra, builder: (column) => column);

  GeneratedColumn<String> get nombres =>
      $composableBuilder(column: $table.nombres, builder: (column) => column);

  GeneratedColumn<String> get apellidos =>
      $composableBuilder(column: $table.apellidos, builder: (column) => column);

  GeneratedColumn<String> get dni =>
      $composableBuilder(column: $table.dni, builder: (column) => column);

  GeneratedColumn<String> get rolApk =>
      $composableBuilder(column: $table.rolApk, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt, builder: (column) => column);
}

class $$TrabajadoresLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrabajadoresLocalTable,
    TrabajadoresLocalData,
    $$TrabajadoresLocalTableFilterComposer,
    $$TrabajadoresLocalTableOrderingComposer,
    $$TrabajadoresLocalTableAnnotationComposer,
    $$TrabajadoresLocalTableCreateCompanionBuilder,
    $$TrabajadoresLocalTableUpdateCompanionBuilder,
    (
      TrabajadoresLocalData,
      BaseReferences<_$AppDatabase, $TrabajadoresLocalTable,
          TrabajadoresLocalData>
    ),
    TrabajadoresLocalData,
    PrefetchHooks Function()> {
  $$TrabajadoresLocalTableTableManager(
      _$AppDatabase db, $TrabajadoresLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrabajadoresLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrabajadoresLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrabajadoresLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            Value<int?> usuarioErpId = const Value.absent(),
            Value<String> codTrabajador = const Value.absent(),
            Value<String?> codigoBarra = const Value.absent(),
            Value<String> nombres = const Value.absent(),
            Value<String> apellidos = const Value.absent(),
            Value<String?> dni = const Value.absent(),
            Value<String> rolApk = const Value.absent(),
            Value<String?> pinHash = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              TrabajadoresLocalCompanion(
            idErp: idErp,
            usuarioErpId: usuarioErpId,
            codTrabajador: codTrabajador,
            codigoBarra: codigoBarra,
            nombres: nombres,
            apellidos: apellidos,
            dni: dni,
            rolApk: rolApk,
            pinHash: pinHash,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          createCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            Value<int?> usuarioErpId = const Value.absent(),
            required String codTrabajador,
            Value<String?> codigoBarra = const Value.absent(),
            required String nombres,
            required String apellidos,
            Value<String?> dni = const Value.absent(),
            Value<String> rolApk = const Value.absent(),
            Value<String?> pinHash = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
          }) =>
              TrabajadoresLocalCompanion.insert(
            idErp: idErp,
            usuarioErpId: usuarioErpId,
            codTrabajador: codTrabajador,
            codigoBarra: codigoBarra,
            nombres: nombres,
            apellidos: apellidos,
            dni: dni,
            rolApk: rolApk,
            pinHash: pinHash,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrabajadoresLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrabajadoresLocalTable,
    TrabajadoresLocalData,
    $$TrabajadoresLocalTableFilterComposer,
    $$TrabajadoresLocalTableOrderingComposer,
    $$TrabajadoresLocalTableAnnotationComposer,
    $$TrabajadoresLocalTableCreateCompanionBuilder,
    $$TrabajadoresLocalTableUpdateCompanionBuilder,
    (
      TrabajadoresLocalData,
      BaseReferences<_$AppDatabase, $TrabajadoresLocalTable,
          TrabajadoresLocalData>
    ),
    TrabajadoresLocalData,
    PrefetchHooks Function()>;
typedef $$LotesLocalTableCreateCompanionBuilder = LotesLocalCompanion Function({
  Value<int> idErp,
  required String loteCodigo,
  required String loteNombre,
  required int fincaIdErp,
  required String fincaNombre,
  Value<String?> sublote,
  Value<double?> areaHa,
  Value<String?> zona,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
  Value<String?> geometriaWkt,
  Value<double?> latitudCentro,
  Value<double?> longitudCentro,
  Value<String?> nombreCultivo,
  Value<String?> colorCultivo,
});
typedef $$LotesLocalTableUpdateCompanionBuilder = LotesLocalCompanion Function({
  Value<int> idErp,
  Value<String> loteCodigo,
  Value<String> loteNombre,
  Value<int> fincaIdErp,
  Value<String> fincaNombre,
  Value<String?> sublote,
  Value<double?> areaHa,
  Value<String?> zona,
  Value<bool> activo,
  Value<DateTime> sincronizadoAt,
  Value<String?> geometriaWkt,
  Value<double?> latitudCentro,
  Value<double?> longitudCentro,
  Value<String?> nombreCultivo,
  Value<String?> colorCultivo,
});

class $$LotesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $LotesLocalTable> {
  $$LotesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loteCodigo => $composableBuilder(
      column: $table.loteCodigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loteNombre => $composableBuilder(
      column: $table.loteNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fincaIdErp => $composableBuilder(
      column: $table.fincaIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fincaNombre => $composableBuilder(
      column: $table.fincaNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sublote => $composableBuilder(
      column: $table.sublote, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get areaHa => $composableBuilder(
      column: $table.areaHa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get geometriaWkt => $composableBuilder(
      column: $table.geometriaWkt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitudCentro => $composableBuilder(
      column: $table.latitudCentro, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitudCentro => $composableBuilder(
      column: $table.longitudCentro,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombreCultivo => $composableBuilder(
      column: $table.nombreCultivo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorCultivo => $composableBuilder(
      column: $table.colorCultivo, builder: (column) => ColumnFilters(column));
}

class $$LotesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $LotesLocalTable> {
  $$LotesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idErp => $composableBuilder(
      column: $table.idErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loteCodigo => $composableBuilder(
      column: $table.loteCodigo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loteNombre => $composableBuilder(
      column: $table.loteNombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fincaIdErp => $composableBuilder(
      column: $table.fincaIdErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fincaNombre => $composableBuilder(
      column: $table.fincaNombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sublote => $composableBuilder(
      column: $table.sublote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get areaHa => $composableBuilder(
      column: $table.areaHa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get geometriaWkt => $composableBuilder(
      column: $table.geometriaWkt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitudCentro => $composableBuilder(
      column: $table.latitudCentro,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitudCentro => $composableBuilder(
      column: $table.longitudCentro,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombreCultivo => $composableBuilder(
      column: $table.nombreCultivo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorCultivo => $composableBuilder(
      column: $table.colorCultivo,
      builder: (column) => ColumnOrderings(column));
}

class $$LotesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $LotesLocalTable> {
  $$LotesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idErp =>
      $composableBuilder(column: $table.idErp, builder: (column) => column);

  GeneratedColumn<String> get loteCodigo => $composableBuilder(
      column: $table.loteCodigo, builder: (column) => column);

  GeneratedColumn<String> get loteNombre => $composableBuilder(
      column: $table.loteNombre, builder: (column) => column);

  GeneratedColumn<int> get fincaIdErp => $composableBuilder(
      column: $table.fincaIdErp, builder: (column) => column);

  GeneratedColumn<String> get fincaNombre => $composableBuilder(
      column: $table.fincaNombre, builder: (column) => column);

  GeneratedColumn<String> get sublote =>
      $composableBuilder(column: $table.sublote, builder: (column) => column);

  GeneratedColumn<double> get areaHa =>
      $composableBuilder(column: $table.areaHa, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt, builder: (column) => column);

  GeneratedColumn<String> get geometriaWkt => $composableBuilder(
      column: $table.geometriaWkt, builder: (column) => column);

  GeneratedColumn<double> get latitudCentro => $composableBuilder(
      column: $table.latitudCentro, builder: (column) => column);

  GeneratedColumn<double> get longitudCentro => $composableBuilder(
      column: $table.longitudCentro, builder: (column) => column);

  GeneratedColumn<String> get nombreCultivo => $composableBuilder(
      column: $table.nombreCultivo, builder: (column) => column);

  GeneratedColumn<String> get colorCultivo => $composableBuilder(
      column: $table.colorCultivo, builder: (column) => column);
}

class $$LotesLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LotesLocalTable,
    LotesLocalData,
    $$LotesLocalTableFilterComposer,
    $$LotesLocalTableOrderingComposer,
    $$LotesLocalTableAnnotationComposer,
    $$LotesLocalTableCreateCompanionBuilder,
    $$LotesLocalTableUpdateCompanionBuilder,
    (
      LotesLocalData,
      BaseReferences<_$AppDatabase, $LotesLocalTable, LotesLocalData>
    ),
    LotesLocalData,
    PrefetchHooks Function()> {
  $$LotesLocalTableTableManager(_$AppDatabase db, $LotesLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LotesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LotesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LotesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            Value<String> loteCodigo = const Value.absent(),
            Value<String> loteNombre = const Value.absent(),
            Value<int> fincaIdErp = const Value.absent(),
            Value<String> fincaNombre = const Value.absent(),
            Value<String?> sublote = const Value.absent(),
            Value<double?> areaHa = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
            Value<String?> geometriaWkt = const Value.absent(),
            Value<double?> latitudCentro = const Value.absent(),
            Value<double?> longitudCentro = const Value.absent(),
            Value<String?> nombreCultivo = const Value.absent(),
            Value<String?> colorCultivo = const Value.absent(),
          }) =>
              LotesLocalCompanion(
            idErp: idErp,
            loteCodigo: loteCodigo,
            loteNombre: loteNombre,
            fincaIdErp: fincaIdErp,
            fincaNombre: fincaNombre,
            sublote: sublote,
            areaHa: areaHa,
            zona: zona,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
            geometriaWkt: geometriaWkt,
            latitudCentro: latitudCentro,
            longitudCentro: longitudCentro,
            nombreCultivo: nombreCultivo,
            colorCultivo: colorCultivo,
          ),
          createCompanionCallback: ({
            Value<int> idErp = const Value.absent(),
            required String loteCodigo,
            required String loteNombre,
            required int fincaIdErp,
            required String fincaNombre,
            Value<String?> sublote = const Value.absent(),
            Value<double?> areaHa = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
            Value<DateTime> sincronizadoAt = const Value.absent(),
            Value<String?> geometriaWkt = const Value.absent(),
            Value<double?> latitudCentro = const Value.absent(),
            Value<double?> longitudCentro = const Value.absent(),
            Value<String?> nombreCultivo = const Value.absent(),
            Value<String?> colorCultivo = const Value.absent(),
          }) =>
              LotesLocalCompanion.insert(
            idErp: idErp,
            loteCodigo: loteCodigo,
            loteNombre: loteNombre,
            fincaIdErp: fincaIdErp,
            fincaNombre: fincaNombre,
            sublote: sublote,
            areaHa: areaHa,
            zona: zona,
            activo: activo,
            sincronizadoAt: sincronizadoAt,
            geometriaWkt: geometriaWkt,
            latitudCentro: latitudCentro,
            longitudCentro: longitudCentro,
            nombreCultivo: nombreCultivo,
            colorCultivo: colorCultivo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LotesLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LotesLocalTable,
    LotesLocalData,
    $$LotesLocalTableFilterComposer,
    $$LotesLocalTableOrderingComposer,
    $$LotesLocalTableAnnotationComposer,
    $$LotesLocalTableCreateCompanionBuilder,
    $$LotesLocalTableUpdateCompanionBuilder,
    (
      LotesLocalData,
      BaseReferences<_$AppDatabase, $LotesLocalTable, LotesLocalData>
    ),
    LotesLocalData,
    PrefetchHooks Function()>;
typedef $$SectoresLocalTableCreateCompanionBuilder = SectoresLocalCompanion
    Function({
  Value<int> id,
  required String nombre,
  required String codigo,
  Value<double?> areaHa,
  Value<String?> zona,
  Value<bool> activo,
});
typedef $$SectoresLocalTableUpdateCompanionBuilder = SectoresLocalCompanion
    Function({
  Value<int> id,
  Value<String> nombre,
  Value<String> codigo,
  Value<double?> areaHa,
  Value<String?> zona,
  Value<bool> activo,
});

class $$SectoresLocalTableFilterComposer
    extends Composer<_$AppDatabase, $SectoresLocalTable> {
  $$SectoresLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get areaHa => $composableBuilder(
      column: $table.areaHa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));
}

class $$SectoresLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $SectoresLocalTable> {
  $$SectoresLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get areaHa => $composableBuilder(
      column: $table.areaHa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get zona => $composableBuilder(
      column: $table.zona, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));
}

class $$SectoresLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectoresLocalTable> {
  $$SectoresLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<double> get areaHa =>
      $composableBuilder(column: $table.areaHa, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$SectoresLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SectoresLocalTable,
    SectoresLocalData,
    $$SectoresLocalTableFilterComposer,
    $$SectoresLocalTableOrderingComposer,
    $$SectoresLocalTableAnnotationComposer,
    $$SectoresLocalTableCreateCompanionBuilder,
    $$SectoresLocalTableUpdateCompanionBuilder,
    (
      SectoresLocalData,
      BaseReferences<_$AppDatabase, $SectoresLocalTable, SectoresLocalData>
    ),
    SectoresLocalData,
    PrefetchHooks Function()> {
  $$SectoresLocalTableTableManager(_$AppDatabase db, $SectoresLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectoresLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SectoresLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectoresLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nombre = const Value.absent(),
            Value<String> codigo = const Value.absent(),
            Value<double?> areaHa = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              SectoresLocalCompanion(
            id: id,
            nombre: nombre,
            codigo: codigo,
            areaHa: areaHa,
            zona: zona,
            activo: activo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nombre,
            required String codigo,
            Value<double?> areaHa = const Value.absent(),
            Value<String?> zona = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              SectoresLocalCompanion.insert(
            id: id,
            nombre: nombre,
            codigo: codigo,
            areaHa: areaHa,
            zona: zona,
            activo: activo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SectoresLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SectoresLocalTable,
    SectoresLocalData,
    $$SectoresLocalTableFilterComposer,
    $$SectoresLocalTableOrderingComposer,
    $$SectoresLocalTableAnnotationComposer,
    $$SectoresLocalTableCreateCompanionBuilder,
    $$SectoresLocalTableUpdateCompanionBuilder,
    (
      SectoresLocalData,
      BaseReferences<_$AppDatabase, $SectoresLocalTable, SectoresLocalData>
    ),
    SectoresLocalData,
    PrefetchHooks Function()>;
typedef $$SubprocesosLocalTableCreateCompanionBuilder
    = SubprocesosLocalCompanion Function({
  Value<int> id,
  required int procesoId,
  required String nombre,
  required String codigo,
  Value<String?> descripcion,
  Value<bool> activo,
});
typedef $$SubprocesosLocalTableUpdateCompanionBuilder
    = SubprocesosLocalCompanion Function({
  Value<int> id,
  Value<int> procesoId,
  Value<String> nombre,
  Value<String> codigo,
  Value<String?> descripcion,
  Value<bool> activo,
});

class $$SubprocesosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $SubprocesosLocalTable> {
  $$SubprocesosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get procesoId => $composableBuilder(
      column: $table.procesoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnFilters(column));
}

class $$SubprocesosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $SubprocesosLocalTable> {
  $$SubprocesosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get procesoId => $composableBuilder(
      column: $table.procesoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombre => $composableBuilder(
      column: $table.nombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigo => $composableBuilder(
      column: $table.codigo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get activo => $composableBuilder(
      column: $table.activo, builder: (column) => ColumnOrderings(column));
}

class $$SubprocesosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubprocesosLocalTable> {
  $$SubprocesosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get procesoId =>
      $composableBuilder(column: $table.procesoId, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);
}

class $$SubprocesosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubprocesosLocalTable,
    SubprocesosLocalData,
    $$SubprocesosLocalTableFilterComposer,
    $$SubprocesosLocalTableOrderingComposer,
    $$SubprocesosLocalTableAnnotationComposer,
    $$SubprocesosLocalTableCreateCompanionBuilder,
    $$SubprocesosLocalTableUpdateCompanionBuilder,
    (
      SubprocesosLocalData,
      BaseReferences<_$AppDatabase, $SubprocesosLocalTable,
          SubprocesosLocalData>
    ),
    SubprocesosLocalData,
    PrefetchHooks Function()> {
  $$SubprocesosLocalTableTableManager(
      _$AppDatabase db, $SubprocesosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubprocesosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubprocesosLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubprocesosLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> procesoId = const Value.absent(),
            Value<String> nombre = const Value.absent(),
            Value<String> codigo = const Value.absent(),
            Value<String?> descripcion = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              SubprocesosLocalCompanion(
            id: id,
            procesoId: procesoId,
            nombre: nombre,
            codigo: codigo,
            descripcion: descripcion,
            activo: activo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int procesoId,
            required String nombre,
            required String codigo,
            Value<String?> descripcion = const Value.absent(),
            Value<bool> activo = const Value.absent(),
          }) =>
              SubprocesosLocalCompanion.insert(
            id: id,
            procesoId: procesoId,
            nombre: nombre,
            codigo: codigo,
            descripcion: descripcion,
            activo: activo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubprocesosLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubprocesosLocalTable,
    SubprocesosLocalData,
    $$SubprocesosLocalTableFilterComposer,
    $$SubprocesosLocalTableOrderingComposer,
    $$SubprocesosLocalTableAnnotationComposer,
    $$SubprocesosLocalTableCreateCompanionBuilder,
    $$SubprocesosLocalTableUpdateCompanionBuilder,
    (
      SubprocesosLocalData,
      BaseReferences<_$AppDatabase, $SubprocesosLocalTable,
          SubprocesosLocalData>
    ),
    SubprocesosLocalData,
    PrefetchHooks Function()>;
typedef $$MenusLocalTableCreateCompanionBuilder = MenusLocalCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  required String titulo,
  Value<String?> icono,
  Value<String?> ruta,
  Value<int> orden,
  required String rol,
});
typedef $$MenusLocalTableUpdateCompanionBuilder = MenusLocalCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  Value<String> titulo,
  Value<String?> icono,
  Value<String?> ruta,
  Value<int> orden,
  Value<String> rol,
});

class $$MenusLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MenusLocalTable> {
  $$MenusLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icono => $composableBuilder(
      column: $table.icono, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ruta => $composableBuilder(
      column: $table.ruta, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orden => $composableBuilder(
      column: $table.orden, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rol => $composableBuilder(
      column: $table.rol, builder: (column) => ColumnFilters(column));
}

class $$MenusLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MenusLocalTable> {
  $$MenusLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icono => $composableBuilder(
      column: $table.icono, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ruta => $composableBuilder(
      column: $table.ruta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orden => $composableBuilder(
      column: $table.orden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rol => $composableBuilder(
      column: $table.rol, builder: (column) => ColumnOrderings(column));
}

class $$MenusLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenusLocalTable> {
  $$MenusLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get icono =>
      $composableBuilder(column: $table.icono, builder: (column) => column);

  GeneratedColumn<String> get ruta =>
      $composableBuilder(column: $table.ruta, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);
}

class $$MenusLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MenusLocalTable,
    MenusLocalData,
    $$MenusLocalTableFilterComposer,
    $$MenusLocalTableOrderingComposer,
    $$MenusLocalTableAnnotationComposer,
    $$MenusLocalTableCreateCompanionBuilder,
    $$MenusLocalTableUpdateCompanionBuilder,
    (
      MenusLocalData,
      BaseReferences<_$AppDatabase, $MenusLocalTable, MenusLocalData>
    ),
    MenusLocalData,
    PrefetchHooks Function()> {
  $$MenusLocalTableTableManager(_$AppDatabase db, $MenusLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenusLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenusLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenusLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String> titulo = const Value.absent(),
            Value<String?> icono = const Value.absent(),
            Value<String?> ruta = const Value.absent(),
            Value<int> orden = const Value.absent(),
            Value<String> rol = const Value.absent(),
          }) =>
              MenusLocalCompanion(
            id: id,
            parentId: parentId,
            titulo: titulo,
            icono: icono,
            ruta: ruta,
            orden: orden,
            rol: rol,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            required String titulo,
            Value<String?> icono = const Value.absent(),
            Value<String?> ruta = const Value.absent(),
            Value<int> orden = const Value.absent(),
            required String rol,
          }) =>
              MenusLocalCompanion.insert(
            id: id,
            parentId: parentId,
            titulo: titulo,
            icono: icono,
            ruta: ruta,
            orden: orden,
            rol: rol,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MenusLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MenusLocalTable,
    MenusLocalData,
    $$MenusLocalTableFilterComposer,
    $$MenusLocalTableOrderingComposer,
    $$MenusLocalTableAnnotationComposer,
    $$MenusLocalTableCreateCompanionBuilder,
    $$MenusLocalTableUpdateCompanionBuilder,
    (
      MenusLocalData,
      BaseReferences<_$AppDatabase, $MenusLocalTable, MenusLocalData>
    ),
    MenusLocalData,
    PrefetchHooks Function()>;
typedef $$RegistrosDiariosLocalTableCreateCompanionBuilder
    = RegistrosDiariosLocalCompanion Function({
  required String id,
  Value<String> numeroRegistro,
  required DateTime fecha,
  Value<String> turno,
  required int procesoId,
  Value<String> procesoNombre,
  Value<String> procesoCodigo,
  required int cultivoIdErp,
  Value<String> cultivoNombreEspecie,
  Value<String> cultivoCodigoEspecie,
  required int operadorIdErp,
  Value<String> operadorCodigo,
  Value<String> operadorNombre,
  Value<int?> supervisorIdErp,
  Value<String?> supervisorCodigo,
  Value<String?> supervisorNombre,
  required int tractorIdErp,
  Value<String> tractorCodigo,
  Value<String> tractorDescripcion,
  Value<int?> implementoIdErp,
  Value<String?> implementoCodigo,
  Value<String?> implementoDescripcion,
  Value<int?> cajaCambiosId,
  Value<String?> cajaCambiosNombre,
  Value<int?> subprocesoId,
  Value<String?> subprocesoNombre,
  Value<DateTime?> jornadaInicioAt,
  Value<DateTime?> jornadaFinAt,
  Value<String> tipoRegistro,
  Value<String> estado,
  Value<String?> observacionesMaq,
  Value<String?> motivoRechazo,
  Value<String?> firmaOperador,
  Value<String?> dispositivoId,
  Value<bool> sincronizado,
  Value<DateTime?> sincronizadoAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$RegistrosDiariosLocalTableUpdateCompanionBuilder
    = RegistrosDiariosLocalCompanion Function({
  Value<String> id,
  Value<String> numeroRegistro,
  Value<DateTime> fecha,
  Value<String> turno,
  Value<int> procesoId,
  Value<String> procesoNombre,
  Value<String> procesoCodigo,
  Value<int> cultivoIdErp,
  Value<String> cultivoNombreEspecie,
  Value<String> cultivoCodigoEspecie,
  Value<int> operadorIdErp,
  Value<String> operadorCodigo,
  Value<String> operadorNombre,
  Value<int?> supervisorIdErp,
  Value<String?> supervisorCodigo,
  Value<String?> supervisorNombre,
  Value<int> tractorIdErp,
  Value<String> tractorCodigo,
  Value<String> tractorDescripcion,
  Value<int?> implementoIdErp,
  Value<String?> implementoCodigo,
  Value<String?> implementoDescripcion,
  Value<int?> cajaCambiosId,
  Value<String?> cajaCambiosNombre,
  Value<int?> subprocesoId,
  Value<String?> subprocesoNombre,
  Value<DateTime?> jornadaInicioAt,
  Value<DateTime?> jornadaFinAt,
  Value<String> tipoRegistro,
  Value<String> estado,
  Value<String?> observacionesMaq,
  Value<String?> motivoRechazo,
  Value<String?> firmaOperador,
  Value<String?> dispositivoId,
  Value<bool> sincronizado,
  Value<DateTime?> sincronizadoAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$RegistrosDiariosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $RegistrosDiariosLocalTable> {
  $$RegistrosDiariosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numeroRegistro => $composableBuilder(
      column: $table.numeroRegistro,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fecha => $composableBuilder(
      column: $table.fecha, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get turno => $composableBuilder(
      column: $table.turno, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get procesoId => $composableBuilder(
      column: $table.procesoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get procesoNombre => $composableBuilder(
      column: $table.procesoNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get procesoCodigo => $composableBuilder(
      column: $table.procesoCodigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cultivoIdErp => $composableBuilder(
      column: $table.cultivoIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cultivoNombreEspecie => $composableBuilder(
      column: $table.cultivoNombreEspecie,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cultivoCodigoEspecie => $composableBuilder(
      column: $table.cultivoCodigoEspecie,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get operadorIdErp => $composableBuilder(
      column: $table.operadorIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operadorCodigo => $composableBuilder(
      column: $table.operadorCodigo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operadorNombre => $composableBuilder(
      column: $table.operadorNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get supervisorIdErp => $composableBuilder(
      column: $table.supervisorIdErp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supervisorCodigo => $composableBuilder(
      column: $table.supervisorCodigo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supervisorNombre => $composableBuilder(
      column: $table.supervisorNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tractorIdErp => $composableBuilder(
      column: $table.tractorIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tractorCodigo => $composableBuilder(
      column: $table.tractorCodigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tractorDescripcion => $composableBuilder(
      column: $table.tractorDescripcion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get implementoIdErp => $composableBuilder(
      column: $table.implementoIdErp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get implementoCodigo => $composableBuilder(
      column: $table.implementoCodigo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get implementoDescripcion => $composableBuilder(
      column: $table.implementoDescripcion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cajaCambiosId => $composableBuilder(
      column: $table.cajaCambiosId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cajaCambiosNombre => $composableBuilder(
      column: $table.cajaCambiosNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subprocesoId => $composableBuilder(
      column: $table.subprocesoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subprocesoNombre => $composableBuilder(
      column: $table.subprocesoNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get jornadaInicioAt => $composableBuilder(
      column: $table.jornadaInicioAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get jornadaFinAt => $composableBuilder(
      column: $table.jornadaFinAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoRegistro => $composableBuilder(
      column: $table.tipoRegistro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get estado => $composableBuilder(
      column: $table.estado, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacionesMaq => $composableBuilder(
      column: $table.observacionesMaq,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivoRechazo => $composableBuilder(
      column: $table.motivoRechazo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firmaOperador => $composableBuilder(
      column: $table.firmaOperador, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RegistrosDiariosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $RegistrosDiariosLocalTable> {
  $$RegistrosDiariosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numeroRegistro => $composableBuilder(
      column: $table.numeroRegistro,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
      column: $table.fecha, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get turno => $composableBuilder(
      column: $table.turno, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get procesoId => $composableBuilder(
      column: $table.procesoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get procesoNombre => $composableBuilder(
      column: $table.procesoNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get procesoCodigo => $composableBuilder(
      column: $table.procesoCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cultivoIdErp => $composableBuilder(
      column: $table.cultivoIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cultivoNombreEspecie => $composableBuilder(
      column: $table.cultivoNombreEspecie,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cultivoCodigoEspecie => $composableBuilder(
      column: $table.cultivoCodigoEspecie,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get operadorIdErp => $composableBuilder(
      column: $table.operadorIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operadorCodigo => $composableBuilder(
      column: $table.operadorCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operadorNombre => $composableBuilder(
      column: $table.operadorNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get supervisorIdErp => $composableBuilder(
      column: $table.supervisorIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supervisorCodigo => $composableBuilder(
      column: $table.supervisorCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supervisorNombre => $composableBuilder(
      column: $table.supervisorNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tractorIdErp => $composableBuilder(
      column: $table.tractorIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tractorCodigo => $composableBuilder(
      column: $table.tractorCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tractorDescripcion => $composableBuilder(
      column: $table.tractorDescripcion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get implementoIdErp => $composableBuilder(
      column: $table.implementoIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get implementoCodigo => $composableBuilder(
      column: $table.implementoCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get implementoDescripcion => $composableBuilder(
      column: $table.implementoDescripcion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cajaCambiosId => $composableBuilder(
      column: $table.cajaCambiosId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cajaCambiosNombre => $composableBuilder(
      column: $table.cajaCambiosNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subprocesoId => $composableBuilder(
      column: $table.subprocesoId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subprocesoNombre => $composableBuilder(
      column: $table.subprocesoNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get jornadaInicioAt => $composableBuilder(
      column: $table.jornadaInicioAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get jornadaFinAt => $composableBuilder(
      column: $table.jornadaFinAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoRegistro => $composableBuilder(
      column: $table.tipoRegistro,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get estado => $composableBuilder(
      column: $table.estado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacionesMaq => $composableBuilder(
      column: $table.observacionesMaq,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivoRechazo => $composableBuilder(
      column: $table.motivoRechazo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firmaOperador => $composableBuilder(
      column: $table.firmaOperador,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RegistrosDiariosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegistrosDiariosLocalTable> {
  $$RegistrosDiariosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get numeroRegistro => $composableBuilder(
      column: $table.numeroRegistro, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get turno =>
      $composableBuilder(column: $table.turno, builder: (column) => column);

  GeneratedColumn<int> get procesoId =>
      $composableBuilder(column: $table.procesoId, builder: (column) => column);

  GeneratedColumn<String> get procesoNombre => $composableBuilder(
      column: $table.procesoNombre, builder: (column) => column);

  GeneratedColumn<String> get procesoCodigo => $composableBuilder(
      column: $table.procesoCodigo, builder: (column) => column);

  GeneratedColumn<int> get cultivoIdErp => $composableBuilder(
      column: $table.cultivoIdErp, builder: (column) => column);

  GeneratedColumn<String> get cultivoNombreEspecie => $composableBuilder(
      column: $table.cultivoNombreEspecie, builder: (column) => column);

  GeneratedColumn<String> get cultivoCodigoEspecie => $composableBuilder(
      column: $table.cultivoCodigoEspecie, builder: (column) => column);

  GeneratedColumn<int> get operadorIdErp => $composableBuilder(
      column: $table.operadorIdErp, builder: (column) => column);

  GeneratedColumn<String> get operadorCodigo => $composableBuilder(
      column: $table.operadorCodigo, builder: (column) => column);

  GeneratedColumn<String> get operadorNombre => $composableBuilder(
      column: $table.operadorNombre, builder: (column) => column);

  GeneratedColumn<int> get supervisorIdErp => $composableBuilder(
      column: $table.supervisorIdErp, builder: (column) => column);

  GeneratedColumn<String> get supervisorCodigo => $composableBuilder(
      column: $table.supervisorCodigo, builder: (column) => column);

  GeneratedColumn<String> get supervisorNombre => $composableBuilder(
      column: $table.supervisorNombre, builder: (column) => column);

  GeneratedColumn<int> get tractorIdErp => $composableBuilder(
      column: $table.tractorIdErp, builder: (column) => column);

  GeneratedColumn<String> get tractorCodigo => $composableBuilder(
      column: $table.tractorCodigo, builder: (column) => column);

  GeneratedColumn<String> get tractorDescripcion => $composableBuilder(
      column: $table.tractorDescripcion, builder: (column) => column);

  GeneratedColumn<int> get implementoIdErp => $composableBuilder(
      column: $table.implementoIdErp, builder: (column) => column);

  GeneratedColumn<String> get implementoCodigo => $composableBuilder(
      column: $table.implementoCodigo, builder: (column) => column);

  GeneratedColumn<String> get implementoDescripcion => $composableBuilder(
      column: $table.implementoDescripcion, builder: (column) => column);

  GeneratedColumn<int> get cajaCambiosId => $composableBuilder(
      column: $table.cajaCambiosId, builder: (column) => column);

  GeneratedColumn<String> get cajaCambiosNombre => $composableBuilder(
      column: $table.cajaCambiosNombre, builder: (column) => column);

  GeneratedColumn<int> get subprocesoId => $composableBuilder(
      column: $table.subprocesoId, builder: (column) => column);

  GeneratedColumn<String> get subprocesoNombre => $composableBuilder(
      column: $table.subprocesoNombre, builder: (column) => column);

  GeneratedColumn<DateTime> get jornadaInicioAt => $composableBuilder(
      column: $table.jornadaInicioAt, builder: (column) => column);

  GeneratedColumn<DateTime> get jornadaFinAt => $composableBuilder(
      column: $table.jornadaFinAt, builder: (column) => column);

  GeneratedColumn<String> get tipoRegistro => $composableBuilder(
      column: $table.tipoRegistro, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get observacionesMaq => $composableBuilder(
      column: $table.observacionesMaq, builder: (column) => column);

  GeneratedColumn<String> get motivoRechazo => $composableBuilder(
      column: $table.motivoRechazo, builder: (column) => column);

  GeneratedColumn<String> get firmaOperador => $composableBuilder(
      column: $table.firmaOperador, builder: (column) => column);

  GeneratedColumn<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => column);

  GeneratedColumn<DateTime> get sincronizadoAt => $composableBuilder(
      column: $table.sincronizadoAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RegistrosDiariosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RegistrosDiariosLocalTable,
    RegistrosDiariosLocalData,
    $$RegistrosDiariosLocalTableFilterComposer,
    $$RegistrosDiariosLocalTableOrderingComposer,
    $$RegistrosDiariosLocalTableAnnotationComposer,
    $$RegistrosDiariosLocalTableCreateCompanionBuilder,
    $$RegistrosDiariosLocalTableUpdateCompanionBuilder,
    (
      RegistrosDiariosLocalData,
      BaseReferences<_$AppDatabase, $RegistrosDiariosLocalTable,
          RegistrosDiariosLocalData>
    ),
    RegistrosDiariosLocalData,
    PrefetchHooks Function()> {
  $$RegistrosDiariosLocalTableTableManager(
      _$AppDatabase db, $RegistrosDiariosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegistrosDiariosLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RegistrosDiariosLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegistrosDiariosLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> numeroRegistro = const Value.absent(),
            Value<DateTime> fecha = const Value.absent(),
            Value<String> turno = const Value.absent(),
            Value<int> procesoId = const Value.absent(),
            Value<String> procesoNombre = const Value.absent(),
            Value<String> procesoCodigo = const Value.absent(),
            Value<int> cultivoIdErp = const Value.absent(),
            Value<String> cultivoNombreEspecie = const Value.absent(),
            Value<String> cultivoCodigoEspecie = const Value.absent(),
            Value<int> operadorIdErp = const Value.absent(),
            Value<String> operadorCodigo = const Value.absent(),
            Value<String> operadorNombre = const Value.absent(),
            Value<int?> supervisorIdErp = const Value.absent(),
            Value<String?> supervisorCodigo = const Value.absent(),
            Value<String?> supervisorNombre = const Value.absent(),
            Value<int> tractorIdErp = const Value.absent(),
            Value<String> tractorCodigo = const Value.absent(),
            Value<String> tractorDescripcion = const Value.absent(),
            Value<int?> implementoIdErp = const Value.absent(),
            Value<String?> implementoCodigo = const Value.absent(),
            Value<String?> implementoDescripcion = const Value.absent(),
            Value<int?> cajaCambiosId = const Value.absent(),
            Value<String?> cajaCambiosNombre = const Value.absent(),
            Value<int?> subprocesoId = const Value.absent(),
            Value<String?> subprocesoNombre = const Value.absent(),
            Value<DateTime?> jornadaInicioAt = const Value.absent(),
            Value<DateTime?> jornadaFinAt = const Value.absent(),
            Value<String> tipoRegistro = const Value.absent(),
            Value<String> estado = const Value.absent(),
            Value<String?> observacionesMaq = const Value.absent(),
            Value<String?> motivoRechazo = const Value.absent(),
            Value<String?> firmaOperador = const Value.absent(),
            Value<String?> dispositivoId = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime?> sincronizadoAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RegistrosDiariosLocalCompanion(
            id: id,
            numeroRegistro: numeroRegistro,
            fecha: fecha,
            turno: turno,
            procesoId: procesoId,
            procesoNombre: procesoNombre,
            procesoCodigo: procesoCodigo,
            cultivoIdErp: cultivoIdErp,
            cultivoNombreEspecie: cultivoNombreEspecie,
            cultivoCodigoEspecie: cultivoCodigoEspecie,
            operadorIdErp: operadorIdErp,
            operadorCodigo: operadorCodigo,
            operadorNombre: operadorNombre,
            supervisorIdErp: supervisorIdErp,
            supervisorCodigo: supervisorCodigo,
            supervisorNombre: supervisorNombre,
            tractorIdErp: tractorIdErp,
            tractorCodigo: tractorCodigo,
            tractorDescripcion: tractorDescripcion,
            implementoIdErp: implementoIdErp,
            implementoCodigo: implementoCodigo,
            implementoDescripcion: implementoDescripcion,
            cajaCambiosId: cajaCambiosId,
            cajaCambiosNombre: cajaCambiosNombre,
            subprocesoId: subprocesoId,
            subprocesoNombre: subprocesoNombre,
            jornadaInicioAt: jornadaInicioAt,
            jornadaFinAt: jornadaFinAt,
            tipoRegistro: tipoRegistro,
            estado: estado,
            observacionesMaq: observacionesMaq,
            motivoRechazo: motivoRechazo,
            firmaOperador: firmaOperador,
            dispositivoId: dispositivoId,
            sincronizado: sincronizado,
            sincronizadoAt: sincronizadoAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> numeroRegistro = const Value.absent(),
            required DateTime fecha,
            Value<String> turno = const Value.absent(),
            required int procesoId,
            Value<String> procesoNombre = const Value.absent(),
            Value<String> procesoCodigo = const Value.absent(),
            required int cultivoIdErp,
            Value<String> cultivoNombreEspecie = const Value.absent(),
            Value<String> cultivoCodigoEspecie = const Value.absent(),
            required int operadorIdErp,
            Value<String> operadorCodigo = const Value.absent(),
            Value<String> operadorNombre = const Value.absent(),
            Value<int?> supervisorIdErp = const Value.absent(),
            Value<String?> supervisorCodigo = const Value.absent(),
            Value<String?> supervisorNombre = const Value.absent(),
            required int tractorIdErp,
            Value<String> tractorCodigo = const Value.absent(),
            Value<String> tractorDescripcion = const Value.absent(),
            Value<int?> implementoIdErp = const Value.absent(),
            Value<String?> implementoCodigo = const Value.absent(),
            Value<String?> implementoDescripcion = const Value.absent(),
            Value<int?> cajaCambiosId = const Value.absent(),
            Value<String?> cajaCambiosNombre = const Value.absent(),
            Value<int?> subprocesoId = const Value.absent(),
            Value<String?> subprocesoNombre = const Value.absent(),
            Value<DateTime?> jornadaInicioAt = const Value.absent(),
            Value<DateTime?> jornadaFinAt = const Value.absent(),
            Value<String> tipoRegistro = const Value.absent(),
            Value<String> estado = const Value.absent(),
            Value<String?> observacionesMaq = const Value.absent(),
            Value<String?> motivoRechazo = const Value.absent(),
            Value<String?> firmaOperador = const Value.absent(),
            Value<String?> dispositivoId = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime?> sincronizadoAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RegistrosDiariosLocalCompanion.insert(
            id: id,
            numeroRegistro: numeroRegistro,
            fecha: fecha,
            turno: turno,
            procesoId: procesoId,
            procesoNombre: procesoNombre,
            procesoCodigo: procesoCodigo,
            cultivoIdErp: cultivoIdErp,
            cultivoNombreEspecie: cultivoNombreEspecie,
            cultivoCodigoEspecie: cultivoCodigoEspecie,
            operadorIdErp: operadorIdErp,
            operadorCodigo: operadorCodigo,
            operadorNombre: operadorNombre,
            supervisorIdErp: supervisorIdErp,
            supervisorCodigo: supervisorCodigo,
            supervisorNombre: supervisorNombre,
            tractorIdErp: tractorIdErp,
            tractorCodigo: tractorCodigo,
            tractorDescripcion: tractorDescripcion,
            implementoIdErp: implementoIdErp,
            implementoCodigo: implementoCodigo,
            implementoDescripcion: implementoDescripcion,
            cajaCambiosId: cajaCambiosId,
            cajaCambiosNombre: cajaCambiosNombre,
            subprocesoId: subprocesoId,
            subprocesoNombre: subprocesoNombre,
            jornadaInicioAt: jornadaInicioAt,
            jornadaFinAt: jornadaFinAt,
            tipoRegistro: tipoRegistro,
            estado: estado,
            observacionesMaq: observacionesMaq,
            motivoRechazo: motivoRechazo,
            firmaOperador: firmaOperador,
            dispositivoId: dispositivoId,
            sincronizado: sincronizado,
            sincronizadoAt: sincronizadoAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RegistrosDiariosLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RegistrosDiariosLocalTable,
        RegistrosDiariosLocalData,
        $$RegistrosDiariosLocalTableFilterComposer,
        $$RegistrosDiariosLocalTableOrderingComposer,
        $$RegistrosDiariosLocalTableAnnotationComposer,
        $$RegistrosDiariosLocalTableCreateCompanionBuilder,
        $$RegistrosDiariosLocalTableUpdateCompanionBuilder,
        (
          RegistrosDiariosLocalData,
          BaseReferences<_$AppDatabase, $RegistrosDiariosLocalTable,
              RegistrosDiariosLocalData>
        ),
        RegistrosDiariosLocalData,
        PrefetchHooks Function()>;
typedef $$HorometrosLocalTableCreateCompanionBuilder = HorometrosLocalCompanion
    Function({
  required String id,
  required String registroId,
  Value<double?> tractorInicio,
  Value<double?> tractorFinal,
  Value<double?> implementoInicio,
  Value<double?> implementoFinal,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HorometrosLocalTableUpdateCompanionBuilder = HorometrosLocalCompanion
    Function({
  Value<String> id,
  Value<String> registroId,
  Value<double?> tractorInicio,
  Value<double?> tractorFinal,
  Value<double?> implementoInicio,
  Value<double?> implementoFinal,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HorometrosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $HorometrosLocalTable> {
  $$HorometrosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tractorInicio => $composableBuilder(
      column: $table.tractorInicio, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tractorFinal => $composableBuilder(
      column: $table.tractorFinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get implementoInicio => $composableBuilder(
      column: $table.implementoInicio,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get implementoFinal => $composableBuilder(
      column: $table.implementoFinal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$HorometrosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $HorometrosLocalTable> {
  $$HorometrosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tractorInicio => $composableBuilder(
      column: $table.tractorInicio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tractorFinal => $composableBuilder(
      column: $table.tractorFinal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get implementoInicio => $composableBuilder(
      column: $table.implementoInicio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get implementoFinal => $composableBuilder(
      column: $table.implementoFinal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$HorometrosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $HorometrosLocalTable> {
  $$HorometrosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<double> get tractorInicio => $composableBuilder(
      column: $table.tractorInicio, builder: (column) => column);

  GeneratedColumn<double> get tractorFinal => $composableBuilder(
      column: $table.tractorFinal, builder: (column) => column);

  GeneratedColumn<double> get implementoInicio => $composableBuilder(
      column: $table.implementoInicio, builder: (column) => column);

  GeneratedColumn<double> get implementoFinal => $composableBuilder(
      column: $table.implementoFinal, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HorometrosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HorometrosLocalTable,
    HorometrosLocalData,
    $$HorometrosLocalTableFilterComposer,
    $$HorometrosLocalTableOrderingComposer,
    $$HorometrosLocalTableAnnotationComposer,
    $$HorometrosLocalTableCreateCompanionBuilder,
    $$HorometrosLocalTableUpdateCompanionBuilder,
    (
      HorometrosLocalData,
      BaseReferences<_$AppDatabase, $HorometrosLocalTable, HorometrosLocalData>
    ),
    HorometrosLocalData,
    PrefetchHooks Function()> {
  $$HorometrosLocalTableTableManager(
      _$AppDatabase db, $HorometrosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HorometrosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HorometrosLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HorometrosLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<double?> tractorInicio = const Value.absent(),
            Value<double?> tractorFinal = const Value.absent(),
            Value<double?> implementoInicio = const Value.absent(),
            Value<double?> implementoFinal = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HorometrosLocalCompanion(
            id: id,
            registroId: registroId,
            tractorInicio: tractorInicio,
            tractorFinal: tractorFinal,
            implementoInicio: implementoInicio,
            implementoFinal: implementoFinal,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            Value<double?> tractorInicio = const Value.absent(),
            Value<double?> tractorFinal = const Value.absent(),
            Value<double?> implementoInicio = const Value.absent(),
            Value<double?> implementoFinal = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HorometrosLocalCompanion.insert(
            id: id,
            registroId: registroId,
            tractorInicio: tractorInicio,
            tractorFinal: tractorFinal,
            implementoInicio: implementoInicio,
            implementoFinal: implementoFinal,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HorometrosLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HorometrosLocalTable,
    HorometrosLocalData,
    $$HorometrosLocalTableFilterComposer,
    $$HorometrosLocalTableOrderingComposer,
    $$HorometrosLocalTableAnnotationComposer,
    $$HorometrosLocalTableCreateCompanionBuilder,
    $$HorometrosLocalTableUpdateCompanionBuilder,
    (
      HorometrosLocalData,
      BaseReferences<_$AppDatabase, $HorometrosLocalTable, HorometrosLocalData>
    ),
    HorometrosLocalData,
    PrefetchHooks Function()>;
typedef $$TiemposTurnoLocalTableCreateCompanionBuilder
    = TiemposTurnoLocalCompanion Function({
  required String id,
  required String registroId,
  Value<String?> horaSalidaTaller,
  Value<String?> horaLlegadaPunto,
  Value<String?> horaSalidaPunto,
  Value<String?> horaLlegadaTaller,
  Value<String?> horaRefrigerio,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$TiemposTurnoLocalTableUpdateCompanionBuilder
    = TiemposTurnoLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<String?> horaSalidaTaller,
  Value<String?> horaLlegadaPunto,
  Value<String?> horaSalidaPunto,
  Value<String?> horaLlegadaTaller,
  Value<String?> horaRefrigerio,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TiemposTurnoLocalTableFilterComposer
    extends Composer<_$AppDatabase, $TiemposTurnoLocalTable> {
  $$TiemposTurnoLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaSalidaTaller => $composableBuilder(
      column: $table.horaSalidaTaller,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaLlegadaPunto => $composableBuilder(
      column: $table.horaLlegadaPunto,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaSalidaPunto => $composableBuilder(
      column: $table.horaSalidaPunto,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaLlegadaTaller => $composableBuilder(
      column: $table.horaLlegadaTaller,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaRefrigerio => $composableBuilder(
      column: $table.horaRefrigerio,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TiemposTurnoLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $TiemposTurnoLocalTable> {
  $$TiemposTurnoLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaSalidaTaller => $composableBuilder(
      column: $table.horaSalidaTaller,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaLlegadaPunto => $composableBuilder(
      column: $table.horaLlegadaPunto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaSalidaPunto => $composableBuilder(
      column: $table.horaSalidaPunto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaLlegadaTaller => $composableBuilder(
      column: $table.horaLlegadaTaller,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaRefrigerio => $composableBuilder(
      column: $table.horaRefrigerio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TiemposTurnoLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiemposTurnoLocalTable> {
  $$TiemposTurnoLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<String> get horaSalidaTaller => $composableBuilder(
      column: $table.horaSalidaTaller, builder: (column) => column);

  GeneratedColumn<String> get horaLlegadaPunto => $composableBuilder(
      column: $table.horaLlegadaPunto, builder: (column) => column);

  GeneratedColumn<String> get horaSalidaPunto => $composableBuilder(
      column: $table.horaSalidaPunto, builder: (column) => column);

  GeneratedColumn<String> get horaLlegadaTaller => $composableBuilder(
      column: $table.horaLlegadaTaller, builder: (column) => column);

  GeneratedColumn<String> get horaRefrigerio => $composableBuilder(
      column: $table.horaRefrigerio, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TiemposTurnoLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TiemposTurnoLocalTable,
    TiemposTurnoLocalData,
    $$TiemposTurnoLocalTableFilterComposer,
    $$TiemposTurnoLocalTableOrderingComposer,
    $$TiemposTurnoLocalTableAnnotationComposer,
    $$TiemposTurnoLocalTableCreateCompanionBuilder,
    $$TiemposTurnoLocalTableUpdateCompanionBuilder,
    (
      TiemposTurnoLocalData,
      BaseReferences<_$AppDatabase, $TiemposTurnoLocalTable,
          TiemposTurnoLocalData>
    ),
    TiemposTurnoLocalData,
    PrefetchHooks Function()> {
  $$TiemposTurnoLocalTableTableManager(
      _$AppDatabase db, $TiemposTurnoLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiemposTurnoLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiemposTurnoLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiemposTurnoLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<String?> horaSalidaTaller = const Value.absent(),
            Value<String?> horaLlegadaPunto = const Value.absent(),
            Value<String?> horaSalidaPunto = const Value.absent(),
            Value<String?> horaLlegadaTaller = const Value.absent(),
            Value<String?> horaRefrigerio = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TiemposTurnoLocalCompanion(
            id: id,
            registroId: registroId,
            horaSalidaTaller: horaSalidaTaller,
            horaLlegadaPunto: horaLlegadaPunto,
            horaSalidaPunto: horaSalidaPunto,
            horaLlegadaTaller: horaLlegadaTaller,
            horaRefrigerio: horaRefrigerio,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            Value<String?> horaSalidaTaller = const Value.absent(),
            Value<String?> horaLlegadaPunto = const Value.absent(),
            Value<String?> horaSalidaPunto = const Value.absent(),
            Value<String?> horaLlegadaTaller = const Value.absent(),
            Value<String?> horaRefrigerio = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TiemposTurnoLocalCompanion.insert(
            id: id,
            registroId: registroId,
            horaSalidaTaller: horaSalidaTaller,
            horaLlegadaPunto: horaLlegadaPunto,
            horaSalidaPunto: horaSalidaPunto,
            horaLlegadaTaller: horaLlegadaTaller,
            horaRefrigerio: horaRefrigerio,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TiemposTurnoLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TiemposTurnoLocalTable,
    TiemposTurnoLocalData,
    $$TiemposTurnoLocalTableFilterComposer,
    $$TiemposTurnoLocalTableOrderingComposer,
    $$TiemposTurnoLocalTableAnnotationComposer,
    $$TiemposTurnoLocalTableCreateCompanionBuilder,
    $$TiemposTurnoLocalTableUpdateCompanionBuilder,
    (
      TiemposTurnoLocalData,
      BaseReferences<_$AppDatabase, $TiemposTurnoLocalTable,
          TiemposTurnoLocalData>
    ),
    TiemposTurnoLocalData,
    PrefetchHooks Function()>;
typedef $$RegistrosSectoresLocalTableCreateCompanionBuilder
    = RegistrosSectoresLocalCompanion Function({
  required String id,
  required String registroId,
  required int loteIdErp,
  Value<String> loteCodigo,
  Value<String> loteNombre,
  Value<String> fincaNombre,
  Value<double?> areaTrabajada,
  Value<String?> observacion,
  Value<int> rowid,
});
typedef $$RegistrosSectoresLocalTableUpdateCompanionBuilder
    = RegistrosSectoresLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<int> loteIdErp,
  Value<String> loteCodigo,
  Value<String> loteNombre,
  Value<String> fincaNombre,
  Value<double?> areaTrabajada,
  Value<String?> observacion,
  Value<int> rowid,
});

class $$RegistrosSectoresLocalTableFilterComposer
    extends Composer<_$AppDatabase, $RegistrosSectoresLocalTable> {
  $$RegistrosSectoresLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loteIdErp => $composableBuilder(
      column: $table.loteIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loteCodigo => $composableBuilder(
      column: $table.loteCodigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loteNombre => $composableBuilder(
      column: $table.loteNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fincaNombre => $composableBuilder(
      column: $table.fincaNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get areaTrabajada => $composableBuilder(
      column: $table.areaTrabajada, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacion => $composableBuilder(
      column: $table.observacion, builder: (column) => ColumnFilters(column));
}

class $$RegistrosSectoresLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $RegistrosSectoresLocalTable> {
  $$RegistrosSectoresLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loteIdErp => $composableBuilder(
      column: $table.loteIdErp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loteCodigo => $composableBuilder(
      column: $table.loteCodigo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loteNombre => $composableBuilder(
      column: $table.loteNombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fincaNombre => $composableBuilder(
      column: $table.fincaNombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get areaTrabajada => $composableBuilder(
      column: $table.areaTrabajada,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacion => $composableBuilder(
      column: $table.observacion, builder: (column) => ColumnOrderings(column));
}

class $$RegistrosSectoresLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegistrosSectoresLocalTable> {
  $$RegistrosSectoresLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<int> get loteIdErp =>
      $composableBuilder(column: $table.loteIdErp, builder: (column) => column);

  GeneratedColumn<String> get loteCodigo => $composableBuilder(
      column: $table.loteCodigo, builder: (column) => column);

  GeneratedColumn<String> get loteNombre => $composableBuilder(
      column: $table.loteNombre, builder: (column) => column);

  GeneratedColumn<String> get fincaNombre => $composableBuilder(
      column: $table.fincaNombre, builder: (column) => column);

  GeneratedColumn<double> get areaTrabajada => $composableBuilder(
      column: $table.areaTrabajada, builder: (column) => column);

  GeneratedColumn<String> get observacion => $composableBuilder(
      column: $table.observacion, builder: (column) => column);
}

class $$RegistrosSectoresLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RegistrosSectoresLocalTable,
    RegistrosSectoresLocalData,
    $$RegistrosSectoresLocalTableFilterComposer,
    $$RegistrosSectoresLocalTableOrderingComposer,
    $$RegistrosSectoresLocalTableAnnotationComposer,
    $$RegistrosSectoresLocalTableCreateCompanionBuilder,
    $$RegistrosSectoresLocalTableUpdateCompanionBuilder,
    (
      RegistrosSectoresLocalData,
      BaseReferences<_$AppDatabase, $RegistrosSectoresLocalTable,
          RegistrosSectoresLocalData>
    ),
    RegistrosSectoresLocalData,
    PrefetchHooks Function()> {
  $$RegistrosSectoresLocalTableTableManager(
      _$AppDatabase db, $RegistrosSectoresLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegistrosSectoresLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RegistrosSectoresLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegistrosSectoresLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<int> loteIdErp = const Value.absent(),
            Value<String> loteCodigo = const Value.absent(),
            Value<String> loteNombre = const Value.absent(),
            Value<String> fincaNombre = const Value.absent(),
            Value<double?> areaTrabajada = const Value.absent(),
            Value<String?> observacion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RegistrosSectoresLocalCompanion(
            id: id,
            registroId: registroId,
            loteIdErp: loteIdErp,
            loteCodigo: loteCodigo,
            loteNombre: loteNombre,
            fincaNombre: fincaNombre,
            areaTrabajada: areaTrabajada,
            observacion: observacion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            required int loteIdErp,
            Value<String> loteCodigo = const Value.absent(),
            Value<String> loteNombre = const Value.absent(),
            Value<String> fincaNombre = const Value.absent(),
            Value<double?> areaTrabajada = const Value.absent(),
            Value<String?> observacion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RegistrosSectoresLocalCompanion.insert(
            id: id,
            registroId: registroId,
            loteIdErp: loteIdErp,
            loteCodigo: loteCodigo,
            loteNombre: loteNombre,
            fincaNombre: fincaNombre,
            areaTrabajada: areaTrabajada,
            observacion: observacion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RegistrosSectoresLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RegistrosSectoresLocalTable,
        RegistrosSectoresLocalData,
        $$RegistrosSectoresLocalTableFilterComposer,
        $$RegistrosSectoresLocalTableOrderingComposer,
        $$RegistrosSectoresLocalTableAnnotationComposer,
        $$RegistrosSectoresLocalTableCreateCompanionBuilder,
        $$RegistrosSectoresLocalTableUpdateCompanionBuilder,
        (
          RegistrosSectoresLocalData,
          BaseReferences<_$AppDatabase, $RegistrosSectoresLocalTable,
              RegistrosSectoresLocalData>
        ),
        RegistrosSectoresLocalData,
        PrefetchHooks Function()>;
typedef $$CosechaBinesLocalTableCreateCompanionBuilder
    = CosechaBinesLocalCompanion Function({
  required String id,
  required String registroId,
  required String franjaHoraria,
  required String turno,
  Value<int> cantidad,
  Value<int> rowid,
});
typedef $$CosechaBinesLocalTableUpdateCompanionBuilder
    = CosechaBinesLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<String> franjaHoraria,
  Value<String> turno,
  Value<int> cantidad,
  Value<int> rowid,
});

class $$CosechaBinesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CosechaBinesLocalTable> {
  $$CosechaBinesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get franjaHoraria => $composableBuilder(
      column: $table.franjaHoraria, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get turno => $composableBuilder(
      column: $table.turno, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cantidad => $composableBuilder(
      column: $table.cantidad, builder: (column) => ColumnFilters(column));
}

class $$CosechaBinesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CosechaBinesLocalTable> {
  $$CosechaBinesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get franjaHoraria => $composableBuilder(
      column: $table.franjaHoraria,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get turno => $composableBuilder(
      column: $table.turno, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cantidad => $composableBuilder(
      column: $table.cantidad, builder: (column) => ColumnOrderings(column));
}

class $$CosechaBinesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CosechaBinesLocalTable> {
  $$CosechaBinesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<String> get franjaHoraria => $composableBuilder(
      column: $table.franjaHoraria, builder: (column) => column);

  GeneratedColumn<String> get turno =>
      $composableBuilder(column: $table.turno, builder: (column) => column);

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);
}

class $$CosechaBinesLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CosechaBinesLocalTable,
    CosechaBinesLocalData,
    $$CosechaBinesLocalTableFilterComposer,
    $$CosechaBinesLocalTableOrderingComposer,
    $$CosechaBinesLocalTableAnnotationComposer,
    $$CosechaBinesLocalTableCreateCompanionBuilder,
    $$CosechaBinesLocalTableUpdateCompanionBuilder,
    (
      CosechaBinesLocalData,
      BaseReferences<_$AppDatabase, $CosechaBinesLocalTable,
          CosechaBinesLocalData>
    ),
    CosechaBinesLocalData,
    PrefetchHooks Function()> {
  $$CosechaBinesLocalTableTableManager(
      _$AppDatabase db, $CosechaBinesLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CosechaBinesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CosechaBinesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CosechaBinesLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<String> franjaHoraria = const Value.absent(),
            Value<String> turno = const Value.absent(),
            Value<int> cantidad = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CosechaBinesLocalCompanion(
            id: id,
            registroId: registroId,
            franjaHoraria: franjaHoraria,
            turno: turno,
            cantidad: cantidad,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            required String franjaHoraria,
            required String turno,
            Value<int> cantidad = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CosechaBinesLocalCompanion.insert(
            id: id,
            registroId: registroId,
            franjaHoraria: franjaHoraria,
            turno: turno,
            cantidad: cantidad,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CosechaBinesLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CosechaBinesLocalTable,
    CosechaBinesLocalData,
    $$CosechaBinesLocalTableFilterComposer,
    $$CosechaBinesLocalTableOrderingComposer,
    $$CosechaBinesLocalTableAnnotationComposer,
    $$CosechaBinesLocalTableCreateCompanionBuilder,
    $$CosechaBinesLocalTableUpdateCompanionBuilder,
    (
      CosechaBinesLocalData,
      BaseReferences<_$AppDatabase, $CosechaBinesLocalTable,
          CosechaBinesLocalData>
    ),
    CosechaBinesLocalData,
    PrefetchHooks Function()>;
typedef $$ParosEquiposLocalTableCreateCompanionBuilder
    = ParosEquiposLocalCompanion Function({
  required String id,
  required String registroId,
  required int tipoParoId,
  Value<String> tipoParoCodigo,
  Value<String> tipoParoNombre,
  Value<String?> motivo,
  Value<String?> equipo,
  required String horaInicio,
  Value<String?> horaFinal,
  Value<double?> galones,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ParosEquiposLocalTableUpdateCompanionBuilder
    = ParosEquiposLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<int> tipoParoId,
  Value<String> tipoParoCodigo,
  Value<String> tipoParoNombre,
  Value<String?> motivo,
  Value<String?> equipo,
  Value<String> horaInicio,
  Value<String?> horaFinal,
  Value<double?> galones,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ParosEquiposLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ParosEquiposLocalTable> {
  $$ParosEquiposLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tipoParoId => $composableBuilder(
      column: $table.tipoParoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoParoCodigo => $composableBuilder(
      column: $table.tipoParoCodigo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoParoNombre => $composableBuilder(
      column: $table.tipoParoNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivo => $composableBuilder(
      column: $table.motivo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipo => $composableBuilder(
      column: $table.equipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaInicio => $composableBuilder(
      column: $table.horaInicio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaFinal => $composableBuilder(
      column: $table.horaFinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get galones => $composableBuilder(
      column: $table.galones, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ParosEquiposLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ParosEquiposLocalTable> {
  $$ParosEquiposLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tipoParoId => $composableBuilder(
      column: $table.tipoParoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoParoCodigo => $composableBuilder(
      column: $table.tipoParoCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoParoNombre => $composableBuilder(
      column: $table.tipoParoNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivo => $composableBuilder(
      column: $table.motivo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipo => $composableBuilder(
      column: $table.equipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaInicio => $composableBuilder(
      column: $table.horaInicio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaFinal => $composableBuilder(
      column: $table.horaFinal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get galones => $composableBuilder(
      column: $table.galones, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ParosEquiposLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParosEquiposLocalTable> {
  $$ParosEquiposLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<int> get tipoParoId => $composableBuilder(
      column: $table.tipoParoId, builder: (column) => column);

  GeneratedColumn<String> get tipoParoCodigo => $composableBuilder(
      column: $table.tipoParoCodigo, builder: (column) => column);

  GeneratedColumn<String> get tipoParoNombre => $composableBuilder(
      column: $table.tipoParoNombre, builder: (column) => column);

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<String> get equipo =>
      $composableBuilder(column: $table.equipo, builder: (column) => column);

  GeneratedColumn<String> get horaInicio => $composableBuilder(
      column: $table.horaInicio, builder: (column) => column);

  GeneratedColumn<String> get horaFinal =>
      $composableBuilder(column: $table.horaFinal, builder: (column) => column);

  GeneratedColumn<double> get galones =>
      $composableBuilder(column: $table.galones, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ParosEquiposLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParosEquiposLocalTable,
    ParosEquiposLocalData,
    $$ParosEquiposLocalTableFilterComposer,
    $$ParosEquiposLocalTableOrderingComposer,
    $$ParosEquiposLocalTableAnnotationComposer,
    $$ParosEquiposLocalTableCreateCompanionBuilder,
    $$ParosEquiposLocalTableUpdateCompanionBuilder,
    (
      ParosEquiposLocalData,
      BaseReferences<_$AppDatabase, $ParosEquiposLocalTable,
          ParosEquiposLocalData>
    ),
    ParosEquiposLocalData,
    PrefetchHooks Function()> {
  $$ParosEquiposLocalTableTableManager(
      _$AppDatabase db, $ParosEquiposLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParosEquiposLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParosEquiposLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParosEquiposLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<int> tipoParoId = const Value.absent(),
            Value<String> tipoParoCodigo = const Value.absent(),
            Value<String> tipoParoNombre = const Value.absent(),
            Value<String?> motivo = const Value.absent(),
            Value<String?> equipo = const Value.absent(),
            Value<String> horaInicio = const Value.absent(),
            Value<String?> horaFinal = const Value.absent(),
            Value<double?> galones = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParosEquiposLocalCompanion(
            id: id,
            registroId: registroId,
            tipoParoId: tipoParoId,
            tipoParoCodigo: tipoParoCodigo,
            tipoParoNombre: tipoParoNombre,
            motivo: motivo,
            equipo: equipo,
            horaInicio: horaInicio,
            horaFinal: horaFinal,
            galones: galones,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            required int tipoParoId,
            Value<String> tipoParoCodigo = const Value.absent(),
            Value<String> tipoParoNombre = const Value.absent(),
            Value<String?> motivo = const Value.absent(),
            Value<String?> equipo = const Value.absent(),
            required String horaInicio,
            Value<String?> horaFinal = const Value.absent(),
            Value<double?> galones = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParosEquiposLocalCompanion.insert(
            id: id,
            registroId: registroId,
            tipoParoId: tipoParoId,
            tipoParoCodigo: tipoParoCodigo,
            tipoParoNombre: tipoParoNombre,
            motivo: motivo,
            equipo: equipo,
            horaInicio: horaInicio,
            horaFinal: horaFinal,
            galones: galones,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ParosEquiposLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParosEquiposLocalTable,
    ParosEquiposLocalData,
    $$ParosEquiposLocalTableFilterComposer,
    $$ParosEquiposLocalTableOrderingComposer,
    $$ParosEquiposLocalTableAnnotationComposer,
    $$ParosEquiposLocalTableCreateCompanionBuilder,
    $$ParosEquiposLocalTableUpdateCompanionBuilder,
    (
      ParosEquiposLocalData,
      BaseReferences<_$AppDatabase, $ParosEquiposLocalTable,
          ParosEquiposLocalData>
    ),
    ParosEquiposLocalData,
    PrefetchHooks Function()>;
typedef $$ChecklistResultadosLocalTableCreateCompanionBuilder
    = ChecklistResultadosLocalCompanion Function({
  required String id,
  required String registroId,
  required int itemId,
  Value<String> itemNombre,
  Value<String> categoriaNombre,
  required String resultado,
  Value<String?> observacion,
  Value<String?> fotoUrl,
  Value<int> rowid,
});
typedef $$ChecklistResultadosLocalTableUpdateCompanionBuilder
    = ChecklistResultadosLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<int> itemId,
  Value<String> itemNombre,
  Value<String> categoriaNombre,
  Value<String> resultado,
  Value<String?> observacion,
  Value<String?> fotoUrl,
  Value<int> rowid,
});

class $$ChecklistResultadosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistResultadosLocalTable> {
  $$ChecklistResultadosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemNombre => $composableBuilder(
      column: $table.itemNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoriaNombre => $composableBuilder(
      column: $table.categoriaNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resultado => $composableBuilder(
      column: $table.resultado, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacion => $composableBuilder(
      column: $table.observacion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnFilters(column));
}

class $$ChecklistResultadosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistResultadosLocalTable> {
  $$ChecklistResultadosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemNombre => $composableBuilder(
      column: $table.itemNombre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoriaNombre => $composableBuilder(
      column: $table.categoriaNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resultado => $composableBuilder(
      column: $table.resultado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacion => $composableBuilder(
      column: $table.observacion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistResultadosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistResultadosLocalTable> {
  $$ChecklistResultadosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemNombre => $composableBuilder(
      column: $table.itemNombre, builder: (column) => column);

  GeneratedColumn<String> get categoriaNombre => $composableBuilder(
      column: $table.categoriaNombre, builder: (column) => column);

  GeneratedColumn<String> get resultado =>
      $composableBuilder(column: $table.resultado, builder: (column) => column);

  GeneratedColumn<String> get observacion => $composableBuilder(
      column: $table.observacion, builder: (column) => column);

  GeneratedColumn<String> get fotoUrl =>
      $composableBuilder(column: $table.fotoUrl, builder: (column) => column);
}

class $$ChecklistResultadosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChecklistResultadosLocalTable,
    ChecklistResultadosLocalData,
    $$ChecklistResultadosLocalTableFilterComposer,
    $$ChecklistResultadosLocalTableOrderingComposer,
    $$ChecklistResultadosLocalTableAnnotationComposer,
    $$ChecklistResultadosLocalTableCreateCompanionBuilder,
    $$ChecklistResultadosLocalTableUpdateCompanionBuilder,
    (
      ChecklistResultadosLocalData,
      BaseReferences<_$AppDatabase, $ChecklistResultadosLocalTable,
          ChecklistResultadosLocalData>
    ),
    ChecklistResultadosLocalData,
    PrefetchHooks Function()> {
  $$ChecklistResultadosLocalTableTableManager(
      _$AppDatabase db, $ChecklistResultadosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistResultadosLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistResultadosLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistResultadosLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<String> itemNombre = const Value.absent(),
            Value<String> categoriaNombre = const Value.absent(),
            Value<String> resultado = const Value.absent(),
            Value<String?> observacion = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistResultadosLocalCompanion(
            id: id,
            registroId: registroId,
            itemId: itemId,
            itemNombre: itemNombre,
            categoriaNombre: categoriaNombre,
            resultado: resultado,
            observacion: observacion,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            required int itemId,
            Value<String> itemNombre = const Value.absent(),
            Value<String> categoriaNombre = const Value.absent(),
            required String resultado,
            Value<String?> observacion = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistResultadosLocalCompanion.insert(
            id: id,
            registroId: registroId,
            itemId: itemId,
            itemNombre: itemNombre,
            categoriaNombre: categoriaNombre,
            resultado: resultado,
            observacion: observacion,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistResultadosLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ChecklistResultadosLocalTable,
        ChecklistResultadosLocalData,
        $$ChecklistResultadosLocalTableFilterComposer,
        $$ChecklistResultadosLocalTableOrderingComposer,
        $$ChecklistResultadosLocalTableAnnotationComposer,
        $$ChecklistResultadosLocalTableCreateCompanionBuilder,
        $$ChecklistResultadosLocalTableUpdateCompanionBuilder,
        (
          ChecklistResultadosLocalData,
          BaseReferences<_$AppDatabase, $ChecklistResultadosLocalTable,
              ChecklistResultadosLocalData>
        ),
        ChecklistResultadosLocalData,
        PrefetchHooks Function()>;
typedef $$RegistrosVehiculoLocalTableCreateCompanionBuilder
    = RegistrosVehiculoLocalCompanion Function({
  required String id,
  required String registroId,
  Value<double?> kmCamionInicio,
  Value<double?> kmCamionFinal,
  Value<double?> kmImplementoInicio,
  Value<double?> kmImplementoFinal,
  Value<String?> horaSalidaBaseTd,
  Value<String?> horaLlegadaZona,
  Value<String?> horaRetornoBase,
  Value<String?> horaLlegadaTaller,
  Value<String?> horaRefrigerio,
  Value<int?> cantidadTancadas,
  Value<String?> observacionesMaq,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$RegistrosVehiculoLocalTableUpdateCompanionBuilder
    = RegistrosVehiculoLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<double?> kmCamionInicio,
  Value<double?> kmCamionFinal,
  Value<double?> kmImplementoInicio,
  Value<double?> kmImplementoFinal,
  Value<String?> horaSalidaBaseTd,
  Value<String?> horaLlegadaZona,
  Value<String?> horaRetornoBase,
  Value<String?> horaLlegadaTaller,
  Value<String?> horaRefrigerio,
  Value<int?> cantidadTancadas,
  Value<String?> observacionesMaq,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$RegistrosVehiculoLocalTableFilterComposer
    extends Composer<_$AppDatabase, $RegistrosVehiculoLocalTable> {
  $$RegistrosVehiculoLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kmCamionInicio => $composableBuilder(
      column: $table.kmCamionInicio,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kmCamionFinal => $composableBuilder(
      column: $table.kmCamionFinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kmImplementoInicio => $composableBuilder(
      column: $table.kmImplementoInicio,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kmImplementoFinal => $composableBuilder(
      column: $table.kmImplementoFinal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaSalidaBaseTd => $composableBuilder(
      column: $table.horaSalidaBaseTd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaLlegadaZona => $composableBuilder(
      column: $table.horaLlegadaZona,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaRetornoBase => $composableBuilder(
      column: $table.horaRetornoBase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaLlegadaTaller => $composableBuilder(
      column: $table.horaLlegadaTaller,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaRefrigerio => $composableBuilder(
      column: $table.horaRefrigerio,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cantidadTancadas => $composableBuilder(
      column: $table.cantidadTancadas,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacionesMaq => $composableBuilder(
      column: $table.observacionesMaq,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RegistrosVehiculoLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $RegistrosVehiculoLocalTable> {
  $$RegistrosVehiculoLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kmCamionInicio => $composableBuilder(
      column: $table.kmCamionInicio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kmCamionFinal => $composableBuilder(
      column: $table.kmCamionFinal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kmImplementoInicio => $composableBuilder(
      column: $table.kmImplementoInicio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kmImplementoFinal => $composableBuilder(
      column: $table.kmImplementoFinal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaSalidaBaseTd => $composableBuilder(
      column: $table.horaSalidaBaseTd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaLlegadaZona => $composableBuilder(
      column: $table.horaLlegadaZona,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaRetornoBase => $composableBuilder(
      column: $table.horaRetornoBase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaLlegadaTaller => $composableBuilder(
      column: $table.horaLlegadaTaller,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaRefrigerio => $composableBuilder(
      column: $table.horaRefrigerio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cantidadTancadas => $composableBuilder(
      column: $table.cantidadTancadas,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacionesMaq => $composableBuilder(
      column: $table.observacionesMaq,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RegistrosVehiculoLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegistrosVehiculoLocalTable> {
  $$RegistrosVehiculoLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<double> get kmCamionInicio => $composableBuilder(
      column: $table.kmCamionInicio, builder: (column) => column);

  GeneratedColumn<double> get kmCamionFinal => $composableBuilder(
      column: $table.kmCamionFinal, builder: (column) => column);

  GeneratedColumn<double> get kmImplementoInicio => $composableBuilder(
      column: $table.kmImplementoInicio, builder: (column) => column);

  GeneratedColumn<double> get kmImplementoFinal => $composableBuilder(
      column: $table.kmImplementoFinal, builder: (column) => column);

  GeneratedColumn<String> get horaSalidaBaseTd => $composableBuilder(
      column: $table.horaSalidaBaseTd, builder: (column) => column);

  GeneratedColumn<String> get horaLlegadaZona => $composableBuilder(
      column: $table.horaLlegadaZona, builder: (column) => column);

  GeneratedColumn<String> get horaRetornoBase => $composableBuilder(
      column: $table.horaRetornoBase, builder: (column) => column);

  GeneratedColumn<String> get horaLlegadaTaller => $composableBuilder(
      column: $table.horaLlegadaTaller, builder: (column) => column);

  GeneratedColumn<String> get horaRefrigerio => $composableBuilder(
      column: $table.horaRefrigerio, builder: (column) => column);

  GeneratedColumn<int> get cantidadTancadas => $composableBuilder(
      column: $table.cantidadTancadas, builder: (column) => column);

  GeneratedColumn<String> get observacionesMaq => $composableBuilder(
      column: $table.observacionesMaq, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RegistrosVehiculoLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RegistrosVehiculoLocalTable,
    RegistrosVehiculoLocalData,
    $$RegistrosVehiculoLocalTableFilterComposer,
    $$RegistrosVehiculoLocalTableOrderingComposer,
    $$RegistrosVehiculoLocalTableAnnotationComposer,
    $$RegistrosVehiculoLocalTableCreateCompanionBuilder,
    $$RegistrosVehiculoLocalTableUpdateCompanionBuilder,
    (
      RegistrosVehiculoLocalData,
      BaseReferences<_$AppDatabase, $RegistrosVehiculoLocalTable,
          RegistrosVehiculoLocalData>
    ),
    RegistrosVehiculoLocalData,
    PrefetchHooks Function()> {
  $$RegistrosVehiculoLocalTableTableManager(
      _$AppDatabase db, $RegistrosVehiculoLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegistrosVehiculoLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RegistrosVehiculoLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegistrosVehiculoLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<double?> kmCamionInicio = const Value.absent(),
            Value<double?> kmCamionFinal = const Value.absent(),
            Value<double?> kmImplementoInicio = const Value.absent(),
            Value<double?> kmImplementoFinal = const Value.absent(),
            Value<String?> horaSalidaBaseTd = const Value.absent(),
            Value<String?> horaLlegadaZona = const Value.absent(),
            Value<String?> horaRetornoBase = const Value.absent(),
            Value<String?> horaLlegadaTaller = const Value.absent(),
            Value<String?> horaRefrigerio = const Value.absent(),
            Value<int?> cantidadTancadas = const Value.absent(),
            Value<String?> observacionesMaq = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RegistrosVehiculoLocalCompanion(
            id: id,
            registroId: registroId,
            kmCamionInicio: kmCamionInicio,
            kmCamionFinal: kmCamionFinal,
            kmImplementoInicio: kmImplementoInicio,
            kmImplementoFinal: kmImplementoFinal,
            horaSalidaBaseTd: horaSalidaBaseTd,
            horaLlegadaZona: horaLlegadaZona,
            horaRetornoBase: horaRetornoBase,
            horaLlegadaTaller: horaLlegadaTaller,
            horaRefrigerio: horaRefrigerio,
            cantidadTancadas: cantidadTancadas,
            observacionesMaq: observacionesMaq,
            sincronizado: sincronizado,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            Value<double?> kmCamionInicio = const Value.absent(),
            Value<double?> kmCamionFinal = const Value.absent(),
            Value<double?> kmImplementoInicio = const Value.absent(),
            Value<double?> kmImplementoFinal = const Value.absent(),
            Value<String?> horaSalidaBaseTd = const Value.absent(),
            Value<String?> horaLlegadaZona = const Value.absent(),
            Value<String?> horaRetornoBase = const Value.absent(),
            Value<String?> horaLlegadaTaller = const Value.absent(),
            Value<String?> horaRefrigerio = const Value.absent(),
            Value<int?> cantidadTancadas = const Value.absent(),
            Value<String?> observacionesMaq = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RegistrosVehiculoLocalCompanion.insert(
            id: id,
            registroId: registroId,
            kmCamionInicio: kmCamionInicio,
            kmCamionFinal: kmCamionFinal,
            kmImplementoInicio: kmImplementoInicio,
            kmImplementoFinal: kmImplementoFinal,
            horaSalidaBaseTd: horaSalidaBaseTd,
            horaLlegadaZona: horaLlegadaZona,
            horaRetornoBase: horaRetornoBase,
            horaLlegadaTaller: horaLlegadaTaller,
            horaRefrigerio: horaRefrigerio,
            cantidadTancadas: cantidadTancadas,
            observacionesMaq: observacionesMaq,
            sincronizado: sincronizado,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RegistrosVehiculoLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RegistrosVehiculoLocalTable,
        RegistrosVehiculoLocalData,
        $$RegistrosVehiculoLocalTableFilterComposer,
        $$RegistrosVehiculoLocalTableOrderingComposer,
        $$RegistrosVehiculoLocalTableAnnotationComposer,
        $$RegistrosVehiculoLocalTableCreateCompanionBuilder,
        $$RegistrosVehiculoLocalTableUpdateCompanionBuilder,
        (
          RegistrosVehiculoLocalData,
          BaseReferences<_$AppDatabase, $RegistrosVehiculoLocalTable,
              RegistrosVehiculoLocalData>
        ),
        RegistrosVehiculoLocalData,
        PrefetchHooks Function()>;
typedef $$CombustibleVehiculoLocalTableCreateCompanionBuilder
    = CombustibleVehiculoLocalCompanion Function({
  required String id,
  required String registroId,
  Value<double?> glns,
  Value<String?> horaInicio,
  Value<String?> horaFinal,
  Value<int> rowid,
});
typedef $$CombustibleVehiculoLocalTableUpdateCompanionBuilder
    = CombustibleVehiculoLocalCompanion Function({
  Value<String> id,
  Value<String> registroId,
  Value<double?> glns,
  Value<String?> horaInicio,
  Value<String?> horaFinal,
  Value<int> rowid,
});

class $$CombustibleVehiculoLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CombustibleVehiculoLocalTable> {
  $$CombustibleVehiculoLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get glns => $composableBuilder(
      column: $table.glns, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaInicio => $composableBuilder(
      column: $table.horaInicio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get horaFinal => $composableBuilder(
      column: $table.horaFinal, builder: (column) => ColumnFilters(column));
}

class $$CombustibleVehiculoLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CombustibleVehiculoLocalTable> {
  $$CombustibleVehiculoLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get glns => $composableBuilder(
      column: $table.glns, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaInicio => $composableBuilder(
      column: $table.horaInicio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get horaFinal => $composableBuilder(
      column: $table.horaFinal, builder: (column) => ColumnOrderings(column));
}

class $$CombustibleVehiculoLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CombustibleVehiculoLocalTable> {
  $$CombustibleVehiculoLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<double> get glns =>
      $composableBuilder(column: $table.glns, builder: (column) => column);

  GeneratedColumn<String> get horaInicio => $composableBuilder(
      column: $table.horaInicio, builder: (column) => column);

  GeneratedColumn<String> get horaFinal =>
      $composableBuilder(column: $table.horaFinal, builder: (column) => column);
}

class $$CombustibleVehiculoLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CombustibleVehiculoLocalTable,
    CombustibleVehiculoLocalData,
    $$CombustibleVehiculoLocalTableFilterComposer,
    $$CombustibleVehiculoLocalTableOrderingComposer,
    $$CombustibleVehiculoLocalTableAnnotationComposer,
    $$CombustibleVehiculoLocalTableCreateCompanionBuilder,
    $$CombustibleVehiculoLocalTableUpdateCompanionBuilder,
    (
      CombustibleVehiculoLocalData,
      BaseReferences<_$AppDatabase, $CombustibleVehiculoLocalTable,
          CombustibleVehiculoLocalData>
    ),
    CombustibleVehiculoLocalData,
    PrefetchHooks Function()> {
  $$CombustibleVehiculoLocalTableTableManager(
      _$AppDatabase db, $CombustibleVehiculoLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CombustibleVehiculoLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CombustibleVehiculoLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CombustibleVehiculoLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<double?> glns = const Value.absent(),
            Value<String?> horaInicio = const Value.absent(),
            Value<String?> horaFinal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CombustibleVehiculoLocalCompanion(
            id: id,
            registroId: registroId,
            glns: glns,
            horaInicio: horaInicio,
            horaFinal: horaFinal,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            Value<double?> glns = const Value.absent(),
            Value<String?> horaInicio = const Value.absent(),
            Value<String?> horaFinal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CombustibleVehiculoLocalCompanion.insert(
            id: id,
            registroId: registroId,
            glns: glns,
            horaInicio: horaInicio,
            horaFinal: horaFinal,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CombustibleVehiculoLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CombustibleVehiculoLocalTable,
        CombustibleVehiculoLocalData,
        $$CombustibleVehiculoLocalTableFilterComposer,
        $$CombustibleVehiculoLocalTableOrderingComposer,
        $$CombustibleVehiculoLocalTableAnnotationComposer,
        $$CombustibleVehiculoLocalTableCreateCompanionBuilder,
        $$CombustibleVehiculoLocalTableUpdateCompanionBuilder,
        (
          CombustibleVehiculoLocalData,
          BaseReferences<_$AppDatabase, $CombustibleVehiculoLocalTable,
              CombustibleVehiculoLocalData>
        ),
        CombustibleVehiculoLocalData,
        PrefetchHooks Function()>;
typedef $$PorteroLecturasLocalTableCreateCompanionBuilder
    = PorteroLecturasLocalCompanion Function({
  required String id,
  required int porteroIdErp,
  Value<int?> tractorIdErp,
  Value<String?> tractorCodigo,
  Value<DateTime?> tractorLeidoAt,
  Value<int?> implementoIdErp,
  Value<String?> implementoCodigo,
  Value<DateTime?> implementoLeidoAt,
  Value<int?> trabajadorIdErp,
  Value<String?> trabajadorCodigo,
  Value<DateTime?> operadorLeidoAt,
  Value<int?> cultivoIdErp,
  Value<String?> cultivoNombre,
  Value<String?> comentario,
  Value<String?> dispositivoId,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$PorteroLecturasLocalTableUpdateCompanionBuilder
    = PorteroLecturasLocalCompanion Function({
  Value<String> id,
  Value<int> porteroIdErp,
  Value<int?> tractorIdErp,
  Value<String?> tractorCodigo,
  Value<DateTime?> tractorLeidoAt,
  Value<int?> implementoIdErp,
  Value<String?> implementoCodigo,
  Value<DateTime?> implementoLeidoAt,
  Value<int?> trabajadorIdErp,
  Value<String?> trabajadorCodigo,
  Value<DateTime?> operadorLeidoAt,
  Value<int?> cultivoIdErp,
  Value<String?> cultivoNombre,
  Value<String?> comentario,
  Value<String?> dispositivoId,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PorteroLecturasLocalTableFilterComposer
    extends Composer<_$AppDatabase, $PorteroLecturasLocalTable> {
  $$PorteroLecturasLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get porteroIdErp => $composableBuilder(
      column: $table.porteroIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tractorIdErp => $composableBuilder(
      column: $table.tractorIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tractorCodigo => $composableBuilder(
      column: $table.tractorCodigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get tractorLeidoAt => $composableBuilder(
      column: $table.tractorLeidoAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get implementoIdErp => $composableBuilder(
      column: $table.implementoIdErp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get implementoCodigo => $composableBuilder(
      column: $table.implementoCodigo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get implementoLeidoAt => $composableBuilder(
      column: $table.implementoLeidoAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trabajadorIdErp => $composableBuilder(
      column: $table.trabajadorIdErp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trabajadorCodigo => $composableBuilder(
      column: $table.trabajadorCodigo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get operadorLeidoAt => $composableBuilder(
      column: $table.operadorLeidoAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cultivoIdErp => $composableBuilder(
      column: $table.cultivoIdErp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cultivoNombre => $composableBuilder(
      column: $table.cultivoNombre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get comentario => $composableBuilder(
      column: $table.comentario, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PorteroLecturasLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $PorteroLecturasLocalTable> {
  $$PorteroLecturasLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get porteroIdErp => $composableBuilder(
      column: $table.porteroIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tractorIdErp => $composableBuilder(
      column: $table.tractorIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tractorCodigo => $composableBuilder(
      column: $table.tractorCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get tractorLeidoAt => $composableBuilder(
      column: $table.tractorLeidoAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get implementoIdErp => $composableBuilder(
      column: $table.implementoIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get implementoCodigo => $composableBuilder(
      column: $table.implementoCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get implementoLeidoAt => $composableBuilder(
      column: $table.implementoLeidoAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trabajadorIdErp => $composableBuilder(
      column: $table.trabajadorIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trabajadorCodigo => $composableBuilder(
      column: $table.trabajadorCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get operadorLeidoAt => $composableBuilder(
      column: $table.operadorLeidoAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cultivoIdErp => $composableBuilder(
      column: $table.cultivoIdErp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cultivoNombre => $composableBuilder(
      column: $table.cultivoNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get comentario => $composableBuilder(
      column: $table.comentario, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PorteroLecturasLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $PorteroLecturasLocalTable> {
  $$PorteroLecturasLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get porteroIdErp => $composableBuilder(
      column: $table.porteroIdErp, builder: (column) => column);

  GeneratedColumn<int> get tractorIdErp => $composableBuilder(
      column: $table.tractorIdErp, builder: (column) => column);

  GeneratedColumn<String> get tractorCodigo => $composableBuilder(
      column: $table.tractorCodigo, builder: (column) => column);

  GeneratedColumn<DateTime> get tractorLeidoAt => $composableBuilder(
      column: $table.tractorLeidoAt, builder: (column) => column);

  GeneratedColumn<int> get implementoIdErp => $composableBuilder(
      column: $table.implementoIdErp, builder: (column) => column);

  GeneratedColumn<String> get implementoCodigo => $composableBuilder(
      column: $table.implementoCodigo, builder: (column) => column);

  GeneratedColumn<DateTime> get implementoLeidoAt => $composableBuilder(
      column: $table.implementoLeidoAt, builder: (column) => column);

  GeneratedColumn<int> get trabajadorIdErp => $composableBuilder(
      column: $table.trabajadorIdErp, builder: (column) => column);

  GeneratedColumn<String> get trabajadorCodigo => $composableBuilder(
      column: $table.trabajadorCodigo, builder: (column) => column);

  GeneratedColumn<DateTime> get operadorLeidoAt => $composableBuilder(
      column: $table.operadorLeidoAt, builder: (column) => column);

  GeneratedColumn<int> get cultivoIdErp => $composableBuilder(
      column: $table.cultivoIdErp, builder: (column) => column);

  GeneratedColumn<String> get cultivoNombre => $composableBuilder(
      column: $table.cultivoNombre, builder: (column) => column);

  GeneratedColumn<String> get comentario => $composableBuilder(
      column: $table.comentario, builder: (column) => column);

  GeneratedColumn<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PorteroLecturasLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PorteroLecturasLocalTable,
    PorteroLecturasLocalData,
    $$PorteroLecturasLocalTableFilterComposer,
    $$PorteroLecturasLocalTableOrderingComposer,
    $$PorteroLecturasLocalTableAnnotationComposer,
    $$PorteroLecturasLocalTableCreateCompanionBuilder,
    $$PorteroLecturasLocalTableUpdateCompanionBuilder,
    (
      PorteroLecturasLocalData,
      BaseReferences<_$AppDatabase, $PorteroLecturasLocalTable,
          PorteroLecturasLocalData>
    ),
    PorteroLecturasLocalData,
    PrefetchHooks Function()> {
  $$PorteroLecturasLocalTableTableManager(
      _$AppDatabase db, $PorteroLecturasLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PorteroLecturasLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PorteroLecturasLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PorteroLecturasLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> porteroIdErp = const Value.absent(),
            Value<int?> tractorIdErp = const Value.absent(),
            Value<String?> tractorCodigo = const Value.absent(),
            Value<DateTime?> tractorLeidoAt = const Value.absent(),
            Value<int?> implementoIdErp = const Value.absent(),
            Value<String?> implementoCodigo = const Value.absent(),
            Value<DateTime?> implementoLeidoAt = const Value.absent(),
            Value<int?> trabajadorIdErp = const Value.absent(),
            Value<String?> trabajadorCodigo = const Value.absent(),
            Value<DateTime?> operadorLeidoAt = const Value.absent(),
            Value<int?> cultivoIdErp = const Value.absent(),
            Value<String?> cultivoNombre = const Value.absent(),
            Value<String?> comentario = const Value.absent(),
            Value<String?> dispositivoId = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PorteroLecturasLocalCompanion(
            id: id,
            porteroIdErp: porteroIdErp,
            tractorIdErp: tractorIdErp,
            tractorCodigo: tractorCodigo,
            tractorLeidoAt: tractorLeidoAt,
            implementoIdErp: implementoIdErp,
            implementoCodigo: implementoCodigo,
            implementoLeidoAt: implementoLeidoAt,
            trabajadorIdErp: trabajadorIdErp,
            trabajadorCodigo: trabajadorCodigo,
            operadorLeidoAt: operadorLeidoAt,
            cultivoIdErp: cultivoIdErp,
            cultivoNombre: cultivoNombre,
            comentario: comentario,
            dispositivoId: dispositivoId,
            sincronizado: sincronizado,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int porteroIdErp,
            Value<int?> tractorIdErp = const Value.absent(),
            Value<String?> tractorCodigo = const Value.absent(),
            Value<DateTime?> tractorLeidoAt = const Value.absent(),
            Value<int?> implementoIdErp = const Value.absent(),
            Value<String?> implementoCodigo = const Value.absent(),
            Value<DateTime?> implementoLeidoAt = const Value.absent(),
            Value<int?> trabajadorIdErp = const Value.absent(),
            Value<String?> trabajadorCodigo = const Value.absent(),
            Value<DateTime?> operadorLeidoAt = const Value.absent(),
            Value<int?> cultivoIdErp = const Value.absent(),
            Value<String?> cultivoNombre = const Value.absent(),
            Value<String?> comentario = const Value.absent(),
            Value<String?> dispositivoId = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PorteroLecturasLocalCompanion.insert(
            id: id,
            porteroIdErp: porteroIdErp,
            tractorIdErp: tractorIdErp,
            tractorCodigo: tractorCodigo,
            tractorLeidoAt: tractorLeidoAt,
            implementoIdErp: implementoIdErp,
            implementoCodigo: implementoCodigo,
            implementoLeidoAt: implementoLeidoAt,
            trabajadorIdErp: trabajadorIdErp,
            trabajadorCodigo: trabajadorCodigo,
            operadorLeidoAt: operadorLeidoAt,
            cultivoIdErp: cultivoIdErp,
            cultivoNombre: cultivoNombre,
            comentario: comentario,
            dispositivoId: dispositivoId,
            sincronizado: sincronizado,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PorteroLecturasLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PorteroLecturasLocalTable,
        PorteroLecturasLocalData,
        $$PorteroLecturasLocalTableFilterComposer,
        $$PorteroLecturasLocalTableOrderingComposer,
        $$PorteroLecturasLocalTableAnnotationComposer,
        $$PorteroLecturasLocalTableCreateCompanionBuilder,
        $$PorteroLecturasLocalTableUpdateCompanionBuilder,
        (
          PorteroLecturasLocalData,
          BaseReferences<_$AppDatabase, $PorteroLecturasLocalTable,
              PorteroLecturasLocalData>
        ),
        PorteroLecturasLocalData,
        PrefetchHooks Function()>;
typedef $$SubLaboresLocalTableCreateCompanionBuilder = SubLaboresLocalCompanion
    Function({
  required String id,
  required String registroId,
  required String sublaborNombre,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SubLaboresLocalTableUpdateCompanionBuilder = SubLaboresLocalCompanion
    Function({
  Value<String> id,
  Value<String> registroId,
  Value<String> sublaborNombre,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SubLaboresLocalTableFilterComposer
    extends Composer<_$AppDatabase, $SubLaboresLocalTable> {
  $$SubLaboresLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sublaborNombre => $composableBuilder(
      column: $table.sublaborNombre,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SubLaboresLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $SubLaboresLocalTable> {
  $$SubLaboresLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sublaborNombre => $composableBuilder(
      column: $table.sublaborNombre,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SubLaboresLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubLaboresLocalTable> {
  $$SubLaboresLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<String> get sublaborNombre => $composableBuilder(
      column: $table.sublaborNombre, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SubLaboresLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubLaboresLocalTable,
    SubLaboresLocalData,
    $$SubLaboresLocalTableFilterComposer,
    $$SubLaboresLocalTableOrderingComposer,
    $$SubLaboresLocalTableAnnotationComposer,
    $$SubLaboresLocalTableCreateCompanionBuilder,
    $$SubLaboresLocalTableUpdateCompanionBuilder,
    (
      SubLaboresLocalData,
      BaseReferences<_$AppDatabase, $SubLaboresLocalTable, SubLaboresLocalData>
    ),
    SubLaboresLocalData,
    PrefetchHooks Function()> {
  $$SubLaboresLocalTableTableManager(
      _$AppDatabase db, $SubLaboresLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubLaboresLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubLaboresLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubLaboresLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<String> sublaborNombre = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubLaboresLocalCompanion(
            id: id,
            registroId: registroId,
            sublaborNombre: sublaborNombre,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            required String sublaborNombre,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubLaboresLocalCompanion.insert(
            id: id,
            registroId: registroId,
            sublaborNombre: sublaborNombre,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubLaboresLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubLaboresLocalTable,
    SubLaboresLocalData,
    $$SubLaboresLocalTableFilterComposer,
    $$SubLaboresLocalTableOrderingComposer,
    $$SubLaboresLocalTableAnnotationComposer,
    $$SubLaboresLocalTableCreateCompanionBuilder,
    $$SubLaboresLocalTableUpdateCompanionBuilder,
    (
      SubLaboresLocalData,
      BaseReferences<_$AppDatabase, $SubLaboresLocalTable, SubLaboresLocalData>
    ),
    SubLaboresLocalData,
    PrefetchHooks Function()>;
typedef $$MarchasLocalTableCreateCompanionBuilder = MarchasLocalCompanion
    Function({
  required String id,
  required String registroId,
  required String marchaCodigo,
  Value<double?> horasUso,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$MarchasLocalTableUpdateCompanionBuilder = MarchasLocalCompanion
    Function({
  Value<String> id,
  Value<String> registroId,
  Value<String> marchaCodigo,
  Value<double?> horasUso,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MarchasLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MarchasLocalTable> {
  $$MarchasLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marchaCodigo => $composableBuilder(
      column: $table.marchaCodigo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get horasUso => $composableBuilder(
      column: $table.horasUso, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MarchasLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MarchasLocalTable> {
  $$MarchasLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marchaCodigo => $composableBuilder(
      column: $table.marchaCodigo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get horasUso => $composableBuilder(
      column: $table.horasUso, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MarchasLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MarchasLocalTable> {
  $$MarchasLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registroId => $composableBuilder(
      column: $table.registroId, builder: (column) => column);

  GeneratedColumn<String> get marchaCodigo => $composableBuilder(
      column: $table.marchaCodigo, builder: (column) => column);

  GeneratedColumn<double> get horasUso =>
      $composableBuilder(column: $table.horasUso, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MarchasLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MarchasLocalTable,
    MarchasLocalData,
    $$MarchasLocalTableFilterComposer,
    $$MarchasLocalTableOrderingComposer,
    $$MarchasLocalTableAnnotationComposer,
    $$MarchasLocalTableCreateCompanionBuilder,
    $$MarchasLocalTableUpdateCompanionBuilder,
    (
      MarchasLocalData,
      BaseReferences<_$AppDatabase, $MarchasLocalTable, MarchasLocalData>
    ),
    MarchasLocalData,
    PrefetchHooks Function()> {
  $$MarchasLocalTableTableManager(_$AppDatabase db, $MarchasLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarchasLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarchasLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarchasLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> registroId = const Value.absent(),
            Value<String> marchaCodigo = const Value.absent(),
            Value<double?> horasUso = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MarchasLocalCompanion(
            id: id,
            registroId: registroId,
            marchaCodigo: marchaCodigo,
            horasUso: horasUso,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String registroId,
            required String marchaCodigo,
            Value<double?> horasUso = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MarchasLocalCompanion.insert(
            id: id,
            registroId: registroId,
            marchaCodigo: marchaCodigo,
            horasUso: horasUso,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MarchasLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MarchasLocalTable,
    MarchasLocalData,
    $$MarchasLocalTableFilterComposer,
    $$MarchasLocalTableOrderingComposer,
    $$MarchasLocalTableAnnotationComposer,
    $$MarchasLocalTableCreateCompanionBuilder,
    $$MarchasLocalTableUpdateCompanionBuilder,
    (
      MarchasLocalData,
      BaseReferences<_$AppDatabase, $MarchasLocalTable, MarchasLocalData>
    ),
    MarchasLocalData,
    PrefetchHooks Function()>;
typedef $$IncumplimientosLocalTableCreateCompanionBuilder
    = IncumplimientosLocalCompanion Function({
  required String id,
  required int usuarioErpId,
  Value<String> nombreUsuario,
  required DateTime fechaJornada,
  Value<String> turno,
  required String tipoIncumplimiento,
  Value<String?> detalle,
  Value<String?> dispositivoId,
  Value<String?> firestoreDocId,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$IncumplimientosLocalTableUpdateCompanionBuilder
    = IncumplimientosLocalCompanion Function({
  Value<String> id,
  Value<int> usuarioErpId,
  Value<String> nombreUsuario,
  Value<DateTime> fechaJornada,
  Value<String> turno,
  Value<String> tipoIncumplimiento,
  Value<String?> detalle,
  Value<String?> dispositivoId,
  Value<String?> firestoreDocId,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$IncumplimientosLocalTableFilterComposer
    extends Composer<_$AppDatabase, $IncumplimientosLocalTable> {
  $$IncumplimientosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usuarioErpId => $composableBuilder(
      column: $table.usuarioErpId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombreUsuario => $composableBuilder(
      column: $table.nombreUsuario, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fechaJornada => $composableBuilder(
      column: $table.fechaJornada, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get turno => $composableBuilder(
      column: $table.turno, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoIncumplimiento => $composableBuilder(
      column: $table.tipoIncumplimiento,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detalle => $composableBuilder(
      column: $table.detalle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firestoreDocId => $composableBuilder(
      column: $table.firestoreDocId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$IncumplimientosLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $IncumplimientosLocalTable> {
  $$IncumplimientosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usuarioErpId => $composableBuilder(
      column: $table.usuarioErpId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombreUsuario => $composableBuilder(
      column: $table.nombreUsuario,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fechaJornada => $composableBuilder(
      column: $table.fechaJornada,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get turno => $composableBuilder(
      column: $table.turno, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoIncumplimiento => $composableBuilder(
      column: $table.tipoIncumplimiento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detalle => $composableBuilder(
      column: $table.detalle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firestoreDocId => $composableBuilder(
      column: $table.firestoreDocId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$IncumplimientosLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncumplimientosLocalTable> {
  $$IncumplimientosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get usuarioErpId => $composableBuilder(
      column: $table.usuarioErpId, builder: (column) => column);

  GeneratedColumn<String> get nombreUsuario => $composableBuilder(
      column: $table.nombreUsuario, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaJornada => $composableBuilder(
      column: $table.fechaJornada, builder: (column) => column);

  GeneratedColumn<String> get turno =>
      $composableBuilder(column: $table.turno, builder: (column) => column);

  GeneratedColumn<String> get tipoIncumplimiento => $composableBuilder(
      column: $table.tipoIncumplimiento, builder: (column) => column);

  GeneratedColumn<String> get detalle =>
      $composableBuilder(column: $table.detalle, builder: (column) => column);

  GeneratedColumn<String> get dispositivoId => $composableBuilder(
      column: $table.dispositivoId, builder: (column) => column);

  GeneratedColumn<String> get firestoreDocId => $composableBuilder(
      column: $table.firestoreDocId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IncumplimientosLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IncumplimientosLocalTable,
    IncumplimientosLocalData,
    $$IncumplimientosLocalTableFilterComposer,
    $$IncumplimientosLocalTableOrderingComposer,
    $$IncumplimientosLocalTableAnnotationComposer,
    $$IncumplimientosLocalTableCreateCompanionBuilder,
    $$IncumplimientosLocalTableUpdateCompanionBuilder,
    (
      IncumplimientosLocalData,
      BaseReferences<_$AppDatabase, $IncumplimientosLocalTable,
          IncumplimientosLocalData>
    ),
    IncumplimientosLocalData,
    PrefetchHooks Function()> {
  $$IncumplimientosLocalTableTableManager(
      _$AppDatabase db, $IncumplimientosLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncumplimientosLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncumplimientosLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncumplimientosLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> usuarioErpId = const Value.absent(),
            Value<String> nombreUsuario = const Value.absent(),
            Value<DateTime> fechaJornada = const Value.absent(),
            Value<String> turno = const Value.absent(),
            Value<String> tipoIncumplimiento = const Value.absent(),
            Value<String?> detalle = const Value.absent(),
            Value<String?> dispositivoId = const Value.absent(),
            Value<String?> firestoreDocId = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncumplimientosLocalCompanion(
            id: id,
            usuarioErpId: usuarioErpId,
            nombreUsuario: nombreUsuario,
            fechaJornada: fechaJornada,
            turno: turno,
            tipoIncumplimiento: tipoIncumplimiento,
            detalle: detalle,
            dispositivoId: dispositivoId,
            firestoreDocId: firestoreDocId,
            sincronizado: sincronizado,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int usuarioErpId,
            Value<String> nombreUsuario = const Value.absent(),
            required DateTime fechaJornada,
            Value<String> turno = const Value.absent(),
            required String tipoIncumplimiento,
            Value<String?> detalle = const Value.absent(),
            Value<String?> dispositivoId = const Value.absent(),
            Value<String?> firestoreDocId = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncumplimientosLocalCompanion.insert(
            id: id,
            usuarioErpId: usuarioErpId,
            nombreUsuario: nombreUsuario,
            fechaJornada: fechaJornada,
            turno: turno,
            tipoIncumplimiento: tipoIncumplimiento,
            detalle: detalle,
            dispositivoId: dispositivoId,
            firestoreDocId: firestoreDocId,
            sincronizado: sincronizado,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IncumplimientosLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $IncumplimientosLocalTable,
        IncumplimientosLocalData,
        $$IncumplimientosLocalTableFilterComposer,
        $$IncumplimientosLocalTableOrderingComposer,
        $$IncumplimientosLocalTableAnnotationComposer,
        $$IncumplimientosLocalTableCreateCompanionBuilder,
        $$IncumplimientosLocalTableUpdateCompanionBuilder,
        (
          IncumplimientosLocalData,
          BaseReferences<_$AppDatabase, $IncumplimientosLocalTable,
              IncumplimientosLocalData>
        ),
        IncumplimientosLocalData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$ProcesosLocalTableTableManager get procesosLocal =>
      $$ProcesosLocalTableTableManager(_db, _db.procesosLocal);
  $$CajasCambiosLocalTableTableManager get cajasCambiosLocal =>
      $$CajasCambiosLocalTableTableManager(_db, _db.cajasCambiosLocal);
  $$TiposParoLocalTableTableManager get tiposParoLocal =>
      $$TiposParoLocalTableTableManager(_db, _db.tiposParoLocal);
  $$ChecklistCategoriasLocalTableTableManager get checklistCategoriasLocal =>
      $$ChecklistCategoriasLocalTableTableManager(
          _db, _db.checklistCategoriasLocal);
  $$ChecklistItemsLocalTableTableManager get checklistItemsLocal =>
      $$ChecklistItemsLocalTableTableManager(_db, _db.checklistItemsLocal);
  $$CultivosLocalTableTableManager get cultivosLocal =>
      $$CultivosLocalTableTableManager(_db, _db.cultivosLocal);
  $$TractoresLocalTableTableManager get tractoresLocal =>
      $$TractoresLocalTableTableManager(_db, _db.tractoresLocal);
  $$ImplementosLocalTableTableManager get implementosLocal =>
      $$ImplementosLocalTableTableManager(_db, _db.implementosLocal);
  $$TrabajadoresLocalTableTableManager get trabajadoresLocal =>
      $$TrabajadoresLocalTableTableManager(_db, _db.trabajadoresLocal);
  $$LotesLocalTableTableManager get lotesLocal =>
      $$LotesLocalTableTableManager(_db, _db.lotesLocal);
  $$SectoresLocalTableTableManager get sectoresLocal =>
      $$SectoresLocalTableTableManager(_db, _db.sectoresLocal);
  $$SubprocesosLocalTableTableManager get subprocesosLocal =>
      $$SubprocesosLocalTableTableManager(_db, _db.subprocesosLocal);
  $$MenusLocalTableTableManager get menusLocal =>
      $$MenusLocalTableTableManager(_db, _db.menusLocal);
  $$RegistrosDiariosLocalTableTableManager get registrosDiariosLocal =>
      $$RegistrosDiariosLocalTableTableManager(_db, _db.registrosDiariosLocal);
  $$HorometrosLocalTableTableManager get horometrosLocal =>
      $$HorometrosLocalTableTableManager(_db, _db.horometrosLocal);
  $$TiemposTurnoLocalTableTableManager get tiemposTurnoLocal =>
      $$TiemposTurnoLocalTableTableManager(_db, _db.tiemposTurnoLocal);
  $$RegistrosSectoresLocalTableTableManager get registrosSectoresLocal =>
      $$RegistrosSectoresLocalTableTableManager(
          _db, _db.registrosSectoresLocal);
  $$CosechaBinesLocalTableTableManager get cosechaBinesLocal =>
      $$CosechaBinesLocalTableTableManager(_db, _db.cosechaBinesLocal);
  $$ParosEquiposLocalTableTableManager get parosEquiposLocal =>
      $$ParosEquiposLocalTableTableManager(_db, _db.parosEquiposLocal);
  $$ChecklistResultadosLocalTableTableManager get checklistResultadosLocal =>
      $$ChecklistResultadosLocalTableTableManager(
          _db, _db.checklistResultadosLocal);
  $$RegistrosVehiculoLocalTableTableManager get registrosVehiculoLocal =>
      $$RegistrosVehiculoLocalTableTableManager(
          _db, _db.registrosVehiculoLocal);
  $$CombustibleVehiculoLocalTableTableManager get combustibleVehiculoLocal =>
      $$CombustibleVehiculoLocalTableTableManager(
          _db, _db.combustibleVehiculoLocal);
  $$PorteroLecturasLocalTableTableManager get porteroLecturasLocal =>
      $$PorteroLecturasLocalTableTableManager(_db, _db.porteroLecturasLocal);
  $$SubLaboresLocalTableTableManager get subLaboresLocal =>
      $$SubLaboresLocalTableTableManager(_db, _db.subLaboresLocal);
  $$MarchasLocalTableTableManager get marchasLocal =>
      $$MarchasLocalTableTableManager(_db, _db.marchasLocal);
  $$IncumplimientosLocalTableTableManager get incumplimientosLocal =>
      $$IncumplimientosLocalTableTableManager(_db, _db.incumplimientosLocal);
}
