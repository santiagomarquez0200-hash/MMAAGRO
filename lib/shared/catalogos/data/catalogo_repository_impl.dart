import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'package:agro_aplicaciones/core/network/network_info.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/entities/catalogo.dart';
import 'package:agro_aplicaciones/shared/catalogos/domain/repositories/catalogo_repository.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';
import 'package:agro_aplicaciones/infrastructure/network/erp_api_client.dart';

const _tag = 'CatalogoRepo';

class CatalogoRepositoryImpl implements CatalogoRepository {
  final ErpApiClient _erp;
  final AppDatabase _db;
  final NetworkInfo _networkInfo;

  const CatalogoRepositoryImpl({
    required ErpApiClient erp,
    required AppDatabase db,
    required NetworkInfo networkInfo,
  })  : _erp = erp,
        _db = db,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<Proceso>>> getProcesos() async {
    try {
      // Leemos con customSelect para incluir tipo_registro, que se gestiona fuera
      // del companion generado y requiere acceso SQL directo.
      // Si la columna no existe todavía (raro, beforeOpen la crea siempre),
      // el catch fallback devuelve todos los procesos con tipo 'tractor'.
      try {
        final rows = await _db.customSelect(
          'SELECT id, nombre, codigo, requiere_bines, activo, '
          "COALESCE(tipo_registro, 'tractor') AS tipo_registro "
          'FROM procesos_local ORDER BY nombre',
        ).get();
        return Right(rows.map((r) => Proceso(
              id: r.read<int>('id'),
              nombre: r.read<String>('nombre'),
              codigo: r.read<String>('codigo'),
              requiereBines: r.read<int>('requiere_bines') == 1,
              activo: r.read<int>('activo') == 1,
              tipoRegistro: r.read<String>('tipo_registro'),
            )).toList());
      } catch (_) {
        // Fallback al DAO generado — devuelve todos los procesos como 'tractor'
        // para que el usuario nunca vea un selector vacío.
        final rows = await _db.catalogoDao.getProcesos();
        return Right(rows.map((r) => Proceso(
              id: r.id,
              nombre: r.nombre,
              codigo: r.codigo,
              requiereBines: r.requiereBines,
              activo: r.activo,
              tipoRegistro: 'tractor',
            )).toList());
      }
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Cultivo>>> getCultivos() async {
    try {
      final rows = await _db.catalogoDao.getCultivos();
      return Right(rows.map(_cultivoFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Tractor>>> getTractores() async {
    try {
      final rows = await _db.catalogoDao.getTractores();
      return Right(rows.map(_tractorFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Implemento>>> getImplementos() async {
    try {
      final rows = await _db.catalogoDao.getImplementos();
      return Right(rows.map(_implementoFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Trabajador>>> getTrabajadores() async {
    try {
      final rows = await _db.catalogoDao.getTrabajadores();
      return Right(rows.map(_trabajadorFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Vehiculo>>> getVehiculos() async {
    try {
      final rows = await _db.customSelect(
        'SELECT id_erp, codigo_vehiculo, descripcion, marca, modelo, matricula, codigo_interno, activo FROM vehiculos_local ORDER BY codigo_vehiculo',
      ).get();
      return Right(rows
          .map((r) => Vehiculo(
                idErp: r.read<int>('id_erp'),
                codigoVehiculo: r.read<String>('codigo_vehiculo'),
                descripcion: r.read<String>('descripcion'),
                marca: r.readNullable<String>('marca'),
                modelo: r.readNullable<String>('modelo'),
                matricula: r.readNullable<String>('matricula'),
                codigoInterno: r.readNullable<String>('codigo_interno'),
                activo: r.read<int>('activo') == 1,
              ))
          .toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sincronizarCatalogos() async {
    try {
      if (!await _networkInfo.isConnected) {
        debugPrint('[$_tag] sin conexion, sync omitido');
        return const Left(NetworkFailure());
      }

      debugPrint('[$_tag] llamando al SP de sincronizacion completa...');
      final catalogos = await _erp.syncAllCatalogos();

      debugPrint('[$_tag] claves devueltas por el SP: ${catalogos.keys.toList()}');
      for (final entry in catalogos.entries) {
        debugPrint('[$_tag] "${entry.key}": ${entry.value.length} registros'
            '${entry.value.isNotEmpty ? " | 1ra fila: ${entry.value[0]}" : ""}');
      }

      await _guardarCultivos(catalogos['cultivos'] ?? []);
      await _guardarTractores(catalogos['tractores'] ?? []);
      await _guardarImplementos(catalogos['implementos'] ?? []);
      await _guardarVehiculos(catalogos['vehiculos'] ?? []);
      await _guardarTrabajadores(catalogos['trabajadores'] ?? []);
      await _guardarLotes(catalogos['lotes'] ?? []);
      // Geometrías de sublote — debe ir después de _guardarLotes para que las
      // filas de lotes_local ya existan y el UPDATE pueda aplicar la geometría.
      await _guardarGeometriasLotesKmz(catalogos['lotes_kmz'] ?? []);
      await _guardarProcesos(catalogos['procesos'] ?? []);
      await _guardarCajasCambios(catalogos['cajas_cambios'] ?? []);
      await _guardarTiposParos(catalogos['tipos_paro'] ?? []);
      await _guardarChecklistItems(catalogos['checklist_items'] ?? []);
      await _guardarSubprocesos(catalogos['subprocesos'] ?? []);
      await _guardarUltimoHorometroTractores(
          catalogos['ultimo_horometro_tractores'] ?? []);
      await _guardarFallasMecanicas(catalogos['fallas_mecanicas'] ?? []);

      debugPrint('[$_tag] sync completado');
      return const Right(null);
    } catch (e, st) {
      debugPrint('[$_tag] error en sync de catalogos: $e\n$st');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Guarda cada catalogo descargado del ERP en SQLite.

  Future<void> _guardarCultivos(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('cultivos: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'cultivos: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    await _db.catalogoDao.upsertCultivos(data.map((r) {
      // SQL devuelve NombreEspecie sin alias (PascalCase), con fallback snake_case
      final especie =
          (r['NombreEspecie'] ?? r['nombre_especie'])?.toString() ?? '';
      return CultivosLocalCompanion(
        idErp: Value(r['cultivo_id_erp'] as int),
        codigoEspecie: Value(especie),
        nombreEspecie: Value(especie),
        nombreCultivo: Value(r['nombre_cultivo']?.toString()),
      );
    }).toList());
  }

  Future<void> _guardarTractores(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('tractores: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'tractores: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    await _db.catalogoDao.upsertTractores(data
        .map((r) => TractoresLocalCompanion(
              idErp: Value(r['tractor_id_erp'] as int),
              codigoTractor: Value(r['codigo_tractor']?.toString() ?? ''),
              descripcion: Value(
                  (r['descripcion'] ?? r['Descripcion'])?.toString() ?? ''),
              marca: Value((r['marca'] ?? r['Marca'])?.toString()),
              modelo: Value((r['modelo'] ?? r['Modelo'])?.toString()),
              matricula: Value((r['matricula'] ?? r['Matricula'])?.toString()),
              codigoInterno: Value(
                  (r['codigo_interno'] ?? r['CodigoInterno'] ?? r['Codigo'])
                      ?.toString()),
              zona: const Value(null),
            ))
        .toList());
  }

  Future<void> _guardarImplementos(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('implementos: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'implementos: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    await _db.catalogoDao.upsertImplementos(data
        .map((r) => ImplementosLocalCompanion(
              idErp: Value(r['implemento_id_erp'] as int),
              codigoImplemento: Value(r['codigo_implemento']?.toString() ?? ''),
              descripcion: Value(
                  (r['descripcion'] ?? r['Descripcion'])?.toString() ?? ''),
              marca: Value((r['marca'] ?? r['Marca'])?.toString()),
              modelo: Value((r['modelo'] ?? r['Modelo'])?.toString()),
              codigoInterno: Value(
                  (r['codigo_interno'] ?? r['CodigoInterno'] ?? r['Codigo'])
                      ?.toString()),
              zona: const Value(null),
            ))
        .toList());
  }

  Future<void> _guardarVehiculos(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('vehiculos: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'vehiculos: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    for (final r in data) {
      final idErp = r['implemento_id_erp'];
      if (idErp == null) continue;
      await _db.customUpdate(
        '''INSERT OR REPLACE INTO vehiculos_local
           (id_erp, codigo_vehiculo, descripcion, marca, modelo, matricula, codigo_interno, activo)
           VALUES (?, ?, ?, ?, ?, ?, ?, 1)''',
        variables: [
          Variable.withInt(idErp as int),
          Variable.withString(r['codigo_implemento']?.toString() ?? ''),
          Variable.withString(
              (r['descripcion'] ?? r['Descripcion'])?.toString() ?? ''),
          Variable(r['marca']?.toString()),
          Variable(r['modelo']?.toString()),
          Variable(r['matricula']?.toString()),
          Variable(r['codigo_interno']?.toString()),
        ],
        updateKind: UpdateKind.insert,
      );
    }
  }

  Future<void> _guardarTrabajadores(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('trabajadores: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'trabajadores: ${data.length} registros | cols: ${data.isNotEmpty ? data[0].keys.toList() : []}',
        name: _tag);
    // LOG DE DIAGNÓSTICO: primeros 3 trabajadores para verificar mapping
    for (final r in data.take(3)) {
      developer.log(
        '[SYNC-TRAB] trabajador_id_erp=${r['trabajador_id_erp']} '
        'usuario_id_erp=${r['usuario_id_erp']} '
        'CodigoUsuario=${r['CodigoUsuario']} '
        'cod_trabajador=${r['cod_trabajador']}',
        name: _tag,
      );
    }
    final existentes = await _db.catalogoDao.getTrabajadores();
    final pinesGuardados = {for (final t in existentes) t.idErp: t.pinHash};
    await _db.catalogoDao.upsertTrabajadores(data.map((r) {
      final idErp = r['trabajador_id_erp'] as int;
      final usuarioErpId = r['usuario_id_erp'] as int?;
      final codigoLogin = r['CodigoUsuario']?.toString() ?? '';
      final codigoBarra = r['cod_trabajador']?.toString();
      developer.log(
        '[SYNC-TRAB] guardando idErp=$idErp usuarioErpId=$usuarioErpId '
        'codTrabajador="$codigoLogin" codigoBarra="$codigoBarra"',
        name: _tag,
      );
      return TrabajadoresLocalCompanion(
        idErp: Value(idErp),
        usuarioErpId: Value(usuarioErpId),
        codTrabajador: Value(codigoLogin),
        codigoBarra: Value(codigoBarra),
        nombres: Value(r['nombre_completo']?.toString() ?? ''),
        apellidos: const Value(''),
        dni: const Value(null),
        rolApk: const Value('operador'),
        pinHash: Value(pinesGuardados[idErp]),
      );
    }).toList());
  }

  /// Guarda las geometrías WKT de los sublotes (catálogo lotes_kmz).
  /// Hace UPDATE sobre las filas ya existentes en lotes_local — por eso debe
  /// ejecutarse después de _guardarLotes.
  Future<void> _guardarGeometriasLotesKmz(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('lotes_kmz: 0 registros — sin geometrías', name: _tag);
      return;
    }
    developer.log(
        'lotes_kmz: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);

    int actualizados = 0;
    for (final r in data) {
      // El SP devuelve Id = cuLP.Id (id del sublote en ERP) — corresponde a idErp
      final idSublote = r['Id'];
      if (idSublote == null) continue;

      final geometriaWkt = r['GeometriaWKT']?.toString();
      // Solo actualizar si hay geometría real — sublotes sin coordenadas se
      // dejan con geometria_wkt = NULL para que no rompan el PIP.
      if (geometriaWkt == null || geometriaWkt.isEmpty) continue;

      final latitudCentro  = _toDouble(r['LatitudCentro']);
      final longitudCentro = _toDouble(r['LongitudCentro']);
      final nombreCultivo  = r['NombreCultivo']?.toString();
      final colorCultivo   = r['ColorCultivo']?.toString();

      await _db.customStatement(
        'UPDATE lotes_local SET '
        'geometria_wkt = ?, latitud_centro = ?, longitud_centro = ?, '
        'nombre_cultivo = ?, color_cultivo = ? '
        'WHERE id_erp = ?',
        [geometriaWkt, latitudCentro, longitudCentro,
         nombreCultivo, colorCultivo, idSublote],
      );
      actualizados++;
    }

    developer.log(
        'lotes_kmz: $actualizados sublotes con geometría actualizados',
        name: _tag);
  }

  /// Convierte un valor dinámico del JSON a double de forma segura.
  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString());
  }

  Future<void> _guardarLotes(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('lotes: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'lotes: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);

    debugPrint('[Catalogo Sync] guardando ${data.length} lotes...');
    if (data.isNotEmpty) {
      final first = data[0];
      debugPrint(
          '   muestra del primer registro: Lote=${first['lote_codigo']}, Sublote=${first['sublote']}, Area=${first['hectareas_sublote']}');
    }

    final loteRows = <LotesLocalCompanion>[];
    final sectorMap = <int, SectoresLocalCompanion>{};
    for (final r in data) {
      final fincaIdRaw = r['finca_id_erp'];
      if (fincaIdRaw == null) continue;
      final fincaId = fincaIdRaw as int;
      final fincaCod = r['lote_codigo']?.toString() ?? fincaId.toString();

      // Los lotes U- son los que usa el sistema actual, el campo lote_codigo ya trae ese formato.
      sectorMap[fincaId] = SectoresLocalCompanion(
        id: Value(fincaId),
        nombre: Value(fincaCod),
        codigo: Value(fincaCod),
        zona: const Value(null),
      );

      // LEFT JOIN: una finca sin sublotes devuelve lote_id_erp = null.
      // En ese caso registramos el sector pero no creamos fila de lote.
      final loteIdErpRaw = r['lote_id_erp'];
      if (loteIdErpRaw == null) continue;

      final areaHa =
          double.tryParse(r['hectareas_sublote']?.toString() ?? '') ??
              double.tryParse(r['area_ha']?.toString() ?? '');

      loteRows.add(LotesLocalCompanion(
        idErp: Value(loteIdErpRaw as int),
        loteCodigo: Value(fincaCod),
        loteNombre: Value(r['sublote']?.toString() ?? ''),
        fincaIdErp: Value(fincaId),
        fincaNombre: Value(fincaCod),
        sublote: Value(r['sublote']?.toString()),
        areaHa: Value(areaHa),
        zona: const Value(null),
      ));
    }
    await _db.catalogoDao.upsertSectores(sectorMap.values.toList());
    await _db.catalogoDao.upsertLotes(loteRows);
    debugPrint('[Catalogo Sync] lotes y sectores guardados localmente');
  }

  Future<void> _guardarProcesos(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('procesos: 0 registros del backend', name: _tag);
      return;
    }
    developer.log(
        'procesos: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    // Borrar antes de insertar: garantiza que el catálogo local refleje
    // exactamente lo que el SP devuelve (sin procesos obsoletos de versiones anteriores).
    await _db.catalogoDao.deleteAllProcesos();
    await _db.catalogoDao.upsertProcesos(data
        .map((r) => ProcesosLocalCompanion(
              id: Value(r['proceso_id'] as int),
              nombre: Value(r['nombre']?.toString() ?? ''),
              codigo: Value(r['codigo']?.toString() ?? ''),
              requiereBines: Value(_toBool(r['requiere_bines'])),
            ))
        .toList());

    // tipo_registro no está en el companion generado (necesitaría build_runner),
    // así que lo escribimos con SQL directo después del upsert.
    for (final r in data) {
      final id = r['proceso_id'] as int;
      final tipo = r['tipo_registro']?.toString() ?? 'tractor';
      try {
        await _db.customStatement(
          "UPDATE procesos_local SET tipo_registro = ? WHERE id = ?",
          [tipo, id],
        );
      } catch (_) {}
    }
  }

  Future<void> _guardarCajasCambios(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('cajas_cambios: 0 registros del backend', name: _tag);
      return;
    }
    developer.log(
        'cajas_cambios: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    await _db.catalogoDao.upsertCajasCambios(data
        .map((r) => CajasCambiosLocalCompanion(
              id: Value(r['caja_id'] as int),
              nombre: Value(r['nombre']?.toString() ?? ''),
            ))
        .toList());
  }

  Future<void> _guardarTiposParos(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('tipos_paro: 0 registros del backend', name: _tag);
      return;
    }
    developer.log(
        'tipos_paro: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    await _db.catalogoDao.upsertTiposParo(data
        .map((r) => TiposParoLocalCompanion(
              id: Value(r['tipo_paro_id'] as int),
              codigo: Value(r['codigo']?.toString() ?? ''),
              nombre: Value(r['nombre']?.toString() ?? ''),
              requiereGalones: Value(_toBool(r['requiere_galones'])),
              requiereEquipo: Value(_toBool(r['requiere_equipo'])),
            ))
        .toList());
  }

  Future<void> _guardarChecklistItems(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('checklist_items: 0 registros del backend', name: _tag);
      return;
    }
    developer.log(
        'checklist_items: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    // Borrar primero evita items huérfanos cuando el ERP reasigna IDs
    await _db.catalogoDao.deleteAllChecklistItems();
    int? asInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    bool asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      return value?.toString().toLowerCase() == 'true' || value == '1';
    }

    final rows = <ChecklistItemsLocalCompanion>[];
    for (final r in data) {
      // Acepta tanto los alias snake_case del SP como los alias de la consulta
      // directa: ItemId, CategoriaId, Categoria, Item y OrdenItem.
      final itemId = asInt(r['item_id'] ?? r['ItemId']);
      final categoriaId = asInt(r['categoria_id'] ?? r['CategoriaId']);
      if (itemId == null || categoriaId == null) {
        developer.log('checklist item ignorado por IDs inválidos: $r',
            name: _tag);
        continue;
      }
      rows.add(ChecklistItemsLocalCompanion(
        id: Value(itemId),
        categoriaId: Value(categoriaId),
        categoriaNombre: Value(
            (r['categoria'] ?? r['Categoria'])?.toString() ?? ''),
        nombre: Value((r['item_nombre'] ?? r['Item'])?.toString() ?? ''),
        orden: Value(asInt(r['orden'] ?? r['OrdenItem']) ?? 0),
        tipoRegistro: Value(
            (r['tipo_registro'] ?? r['TipoRegistro'])?.toString() ?? 'tractor'),
        activo: Value(asBool(r['activo'] ?? r['Activo'] ?? true)),
      ));
    }
    await _db.catalogoDao.upsertChecklistItems(rows);
  }

  Future<void> _guardarUltimoHorometroTractores(
      List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('ultimo_horometro_tractores: 0 registros del ERP',
          name: _tag);
      return;
    }
    developer.log(
        'ultimo_horometro_tractores: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    for (final r in data) {
      // El ERP identifica los registros de horómetro por CÓDIGO de tractor
      // (string, e.g. "T-001"), no por ID entero. Se acepta tanto
      // 'codigo_tractor' como 'tractor_id_erp' para cubrir variantes del SP.
      final codigoTractor =
          (r['codigo_tractor'] ?? r['tractor_id_erp'])?.toString();
      if (codigoTractor == null || codigoTractor.isEmpty) continue;
      final implementoIdErpRaw = r['implemento_id_erp'] ?? r['implemento_id'];
      final implementoIdErp = implementoIdErpRaw != null
          ? (implementoIdErpRaw as num).toInt()
          : null;
      final codigoImplemento =
          (r['codigo_implemento'] ?? r['implemento_codigo'])?.toString();
      await _db.customUpdate(
        '''INSERT OR REPLACE INTO ultimo_horometro_tractores_local
           (tractor_id_erp, horometro_final, implemento_final,
            implemento_id_erp, codigo_implemento, ultima_fecha, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, strftime('%s','now') * 1000)''',
        variables: [
          Variable.withString(codigoTractor),
          Variable(r['ultimo_horometro_final'] != null
              ? (r['ultimo_horometro_final'] as num).toDouble()
              : null),
          Variable(r['ultimo_implemento_final'] != null
              ? (r['ultimo_implemento_final'] as num).toDouble()
              : null),
          Variable(implementoIdErp),
          Variable(codigoImplemento),
          Variable(r['ultima_fecha']?.toString()),
        ],
        updateKind: UpdateKind.insert,
      );
    }
  }

  Future<void> _guardarSubprocesos(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('subprocesos: 0 registros del backend', name: _tag);
      return;
    }
    developer.log(
        'subprocesos: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    await _db.catalogoDao.upsertSubprocesos(data
        .map((r) => SubprocesosLocalCompanion(
              id: Value(r['id'] as int),
              procesoId: Value(r['proceso_id'] as int),
              nombre: Value(r['nombre']?.toString() ?? ''),
              codigo: Value(r['codigo']?.toString() ?? ''),
              descripcion: Value(r['descripcion']?.toString()),
            ))
        .toList());
  }

  // Lectura desde SQLite local — estas implementan la interfaz del repositorio.

  @override
  Future<Either<Failure, List<Subproceso>>> getSubprocesos(
      {int? procesoId}) async {
    try {
      final rows = await _db.catalogoDao.getSubprocesos(procesoId: procesoId);
      return Right(rows.map(_subprocesoFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CajaCambios>>> getCajasCambios() async {
    try {
      final rows = await _db.catalogoDao.getCajasCambios();
      return Right(rows.map(_cajaFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TipoParo>>> getTiposParos() async {
    try {
      final rows = await _db.catalogoDao.getTiposParo();
      return Right(rows.map(_tipoParoFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Lote>>> getLotes({int? fincaIdErp}) async {
    try {
      final rows = await _db.catalogoDao.getLotes(fincaIdErp: fincaIdErp);
      return Right(rows.map(_loteFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChecklistItem>>> getChecklistItems() async {
    try {
      final rows = await _db.catalogoDao.getChecklistItems();
      return Right(rows.map(_checklistItemFromRow).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Sector>>> getSectoresConLotes() async {
    try {
      final sectores = await _db.catalogoDao.getSectores();
      final result = <Sector>[];
      for (final s in sectores) {
        final loteRows = await _db.catalogoDao.getLotes(fincaIdErp: s.id);
        result.add(Sector(
          id: s.id,
          nombre: s.nombre,
          codigo: s.codigo,
          areaHa: s.areaHa,
          zona: s.zona,
          activo: s.activo,
          lotes: loteRows.map(_loteFromRow).toList(),
        ));
      }
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // El ERP puede devolver 0/1 o true/false para campos booleanos.
  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    return false;
  }

  // Conversión de filas de la BD local a las entidades del dominio.

  Subproceso _subprocesoFromRow(SubprocesosLocalData r) => Subproceso(
      id: r.id,
      procesoId: r.procesoId,
      nombre: r.nombre,
      codigo: r.codigo,
      descripcion: r.descripcion,
      activo: r.activo);

  Cultivo _cultivoFromRow(CultivosLocalData r) => Cultivo(
      idErp: r.idErp,
      codigoEspecie: r.codigoEspecie,
      nombreEspecie: r.nombreEspecie,
      nombreCultivo: r.nombreCultivo,
      activo: r.activo);

  Tractor _tractorFromRow(TractoresLocalData r) => Tractor(
      idErp: r.idErp,
      codigoTractor: r.codigoTractor,
      descripcion: r.descripcion,
      marca: r.marca,
      modelo: r.modelo,
      matricula: r.matricula,
      codigoInterno: r.codigoInterno,
      zona: r.zona,
      activo: r.activo);

  Implemento _implementoFromRow(ImplementosLocalData r) => Implemento(
      idErp: r.idErp,
      codigoImplemento: r.codigoImplemento,
      descripcion: r.descripcion,
      marca: r.marca,
      modelo: r.modelo,
      codigoInterno: r.codigoInterno,
      zona: r.zona,
      activo: r.activo);

  Trabajador _trabajadorFromRow(TrabajadoresLocalData r) => Trabajador(
      idErp: r.idErp,
      codTrabajador: r.codTrabajador,
      nombres: r.nombres,
      apellidos: r.apellidos,
      dni: r.dni,
      rolApk: r.rolApk,
      pinHash: r.pinHash,
      activo: r.activo);

  CajaCambios _cajaFromRow(CajasCambiosLocalData r) =>
      CajaCambios(id: r.id, nombre: r.nombre);

  TipoParo _tipoParoFromRow(TiposParoLocalData r) => TipoParo(
      id: r.id,
      codigo: r.codigo,
      nombre: r.nombre,
      requiereGalones: r.requiereGalones,
      requiereEquipo: r.requiereEquipo,
      activo: r.activo);

  ChecklistItem _checklistItemFromRow(ChecklistItemsLocalData r) =>
      ChecklistItem(
          id: r.id,
          categoriaId: r.categoriaId,
          categoriaNombre: r.categoriaNombre,
          nombre: r.nombre,
          orden: r.orden,
          tipoRegistro: r.tipoRegistro,
          activo: r.activo);

  Lote _loteFromRow(LotesLocalData r) => Lote(
      idErp: r.idErp,
      loteCodigo: r.loteCodigo,
      loteNombre: r.loteNombre,
      fincaIdErp: r.fincaIdErp,
      fincaNombre: r.fincaNombre,
      sublote: r.sublote,
      areaHa: r.areaHa,
      zona: r.zona,
      activo: r.activo);

  // Para el flujo del portero, que escanea QR/barcode y necesita resolver el id.

  @override
  Future<Either<Failure, Trabajador?>> buscarTrabajadorPorCodigo(
      String codigo) async {
    try {
      final row = await _db.catalogoDao.getTrabajadorByCodigoScanner(codigo);
      return Right(row != null ? _trabajadorFromRow(row) : null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tractor?>> buscarTractorPorCodigo(
      String codigo) async {
    try {
      final row = await _db.catalogoDao.getTractorByCodigoScanner(codigo);
      return Right(row != null ? _tractorFromRow(row) : null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Implemento?>> buscarImplementoPorCodigo(
      String codigo) async {
    try {
      final row = await _db.catalogoDao.getImplementoByCodigoScanner(codigo);
      return Right(row != null ? _implementoFromRow(row) : null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<int> countUltimoHorometroTractores() async {
    final rows = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM ultimo_horometro_tractores_local',
    ).get();
    return (rows.first.data['c'] as int?) ?? 0;
  }

  @override
  Future<Either<Failure, List<FallaMecanica>>> getFallasMecanicas() async {
    try {
      final rows = await _db.customSelect(
        '''SELECT id, codigo, nombre,
                  COALESCE(categoria, 'MECANICO') AS categoria,
                  componentes_afectados
           FROM fallas_mecanicas_local
           ORDER BY categoria, nombre''',
      ).get();
      return Right(rows
          .map((r) => FallaMecanica(
                id: r.read<int>('id'),
                codigo: r.read<String>('codigo'),
                nombre: r.read<String>('nombre'),
                categoria: r.read<String>('categoria'),
                componentesAfectados: () {
                  final v = r.readNullable<String>('componentes_afectados');
                  return (v == null || v.isEmpty) ? null : v;
                }(),
              ))
          .toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<int> countFallasMecanicas() async {
    try {
      final rows = await _db.customSelect(
        'SELECT COUNT(*) AS c FROM fallas_mecanicas_local',
      ).get();
      return (rows.first.data['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _guardarFallasMecanicas(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      developer.log('fallas_mecanicas: 0 registros del ERP', name: _tag);
      return;
    }
    developer.log(
        'fallas_mecanicas: ${data.length} registros | cols: ${data[0].keys.toList()}',
        name: _tag);
    for (final r in data) {
      final id = r['falla_id'];
      if (id == null) continue;
      await _db.customUpdate(
        '''INSERT OR REPLACE INTO fallas_mecanicas_local
               (id, codigo, nombre, categoria, componentes_afectados)
           VALUES (?, ?, ?, ?, ?)''',
        variables: [
          Variable.withInt(id as int),
          Variable.withString(r['codigo']?.toString() ?? ''),
          Variable.withString(r['nombre']?.toString() ?? ''),
          Variable.withString(r['categoria']?.toString() ?? 'MECANICO'),
          Variable.withString(r['componentes_afectados']?.toString() ?? ''),
        ],
        updateKind: UpdateKind.insert,
      );
    }
  }
}
