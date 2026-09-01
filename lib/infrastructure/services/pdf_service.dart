// lib/infrastructure/services/pdf_service.dart
// =============================================================================
// PDF SERVICE - AgriControl MMA
// Versión Nativa pw.Document — sin WebView, 100% compatible Android 14+
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import 'package:agro_aplicaciones/features/operador/domain/entities/registro_diario.dart';
import 'package:agro_aplicaciones/features/operador/domain/entities/registro_vehiculo.dart';

class PdfService {
  // ============================================================================
  // TRACTOR — MÉTODOS PÚBLICOS
  // ============================================================================

  static Future<void> generarYCompartir(RegistroDiario registro) async {
    try {
      final esVehiculo = registro.tipoRegistro == 'vehiculo';
      final pdf = esVehiculo
          ? await _generarPdfDesdeRegistroDiarioVehiculo(registro)
          : await _generarPdfTractor(registro);
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final fecha = DateFormat('yyyyMMdd').format(registro.fecha);
      final prefix = esVehiculo ? 'MMA_FR013_VEH' : 'MMA_FR004';
      final fileName = '${prefix}_${registro.numeroRegistro}_$fecha.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [share_plus.XFile(file.path, mimeType: 'application/pdf')],
          subject:
              '${esVehiculo ? 'Control Camión' : 'Control Diario'} ${registro.numeroRegistro}',
        ),
      );
    } catch (e) {
      throw Exception('Error generando PDF: $e');
    }
  }

  static Future<void> imprimirPreview(RegistroDiario registro) async {
    final esVehiculo = registro.tipoRegistro == 'vehiculo';
    final pdf = esVehiculo
        ? await _generarPdfDesdeRegistroDiarioVehiculo(registro)
        : await _generarPdfTractor(registro);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ============================================================================
  // VEHÍCULO — MÉTODOS PÚBLICOS
  // ============================================================================

  static Future<void> generarYCompartirVehiculo(
      RegistroVehiculo registro) async {
    final pdf = await _generarPdfVehiculo(registro);
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final fecha = DateFormat('yyyyMMdd').format(registro.fecha);
    final fileName = 'MMA_FR013_VEH_${registro.numeroRegistro}_$fecha.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await share_plus.SharePlus.instance.share(
      share_plus.ShareParams(
        files: [share_plus.XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Control Vehículo ${registro.numeroRegistro}',
      ),
    );
  }

  static Future<void> imprimirPreviewVehiculo(RegistroVehiculo registro) async {
    final pdf = await _generarPdfVehiculo(registro);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ============================================================================
  // FUENTES Y LOGO — cacheados en estático para que la primera carga sea la
  // única lenta; generaciones posteriores son instantáneas.
  // ============================================================================

  static pw.ThemeData? _cachedTheme;
  static pw.MemoryImage? _cachedLogo;
  static bool _logoLoadAttempted = false;

  static Future<pw.ThemeData> _loadTheme() async {
    if (_cachedTheme != null) return _cachedTheme!;
    final results = await Future.wait([
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
      PdfGoogleFonts.notoSansItalic(),
    ]);
    _cachedTheme = pw.ThemeData.withFont(
      base: results[0],
      bold: results[1],
      italic: results[2],
    );
    return _cachedTheme!;
  }

  static Future<pw.MemoryImage?> _loadLogoImage() async {
    if (_logoLoadAttempted) return _cachedLogo;
    _logoLoadAttempted = true;
    try {
      final data = await rootBundle.load('assets/images/ic_launcher2.png');
      _cachedLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      _cachedLogo = null;
    }
    return _cachedLogo;
  }

  // ============================================================================
  // GENERADOR — TRACTOR
  // ============================================================================

  static Future<pw.Document> _generarPdfTractor(RegistroDiario r) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');
    final proc = r.procesoCodigo.toUpperCase();
    final results = await Future.wait([_loadTheme(), _loadLogoImage()]);
    final theme = results[0] as pw.ThemeData;
    final logo = results[1] as pw.MemoryImage?;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        build: (ctx) => [
          _headerTractor(r, fmt, logo),
          pw.SizedBox(height: 4),
          _procesoRow(proc, r.cultivoNombreEspecie),
          pw.SizedBox(height: 4),
          _datosPrincipales(r, fmt),
          pw.SizedBox(height: 4),
          _inicioFinTractor(r),
          if (proc.contains('COSEC')) ...[
            pw.SizedBox(height: 4),
            _binesTable(r),
          ],
          pw.SizedBox(height: 4),
          _parosTable(r),
          pw.SizedBox(height: 4),
          ..._checklistWidgets(r),
          pw.SizedBox(height: 4),
          _observacionesBox(r.observacionesMaq),
          pw.SizedBox(height: 12),
          _firmas(
            ['Firma del Operador', 'Firma del Cliente'],
            firmaOperador: r.firmaOperador != null ? base64Decode(r.firmaOperador!) : null,
          ),
        ],
      ),
    );
    return pdf;
  }

  // ── Header ────────────────────────────────────────────────────────────────
  // Estructura idéntica a plantilla_tractor_conbines.html:
  // Col1: AGROKASA (verde) | Col2: Título centrado | Col3: Código/versión/fecha (3 celdas)

  static pw.Widget _headerTractor(
      RegistroDiario r, DateFormat fmt, pw.MemoryImage? logoImage) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.75)),
      child: pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(70),
          1: pw.FlexColumnWidth(1),
          2: pw.FixedColumnWidth(120),
        },
        border: pw.TableBorder.all(width: 0.75),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(
                child: logoImage != null
                    ? pw.Container(
                        width: 56,
                        height: 42,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    : pw.Text('AGROKASA',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColor.fromHex('#15803d'))),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text('CONTROL DIARIO DE OPERACIONES AGRÍCOLAS',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
            ),
            pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                _headerFormCell('MMA-FR-004', bold: true, borderBottom: true),
                _headerFormCell('Versión: 01', borderBottom: true),
                _headerFormCell('Fecha Aprobación: 02/02/2024'),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _headerFormCell(String text,
      {bool bold = false, bool borderBottom = false}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: pw.BoxDecoration(
        border: borderBottom
            ? const pw.Border(bottom: pw.BorderSide(width: 0.75))
            : null,
      ),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  // ── Proceso ───────────────────────────────────────────────────────────────
  // Réplica exacta de plantilla_tractor_conbines.html:
  // 2 filas de 4 procesos c/u. PROCESO y CULTIVO spanean ambas filas (simulado con Row).

  static pw.Widget _procesoRow(String proc, String? cultivo) {
    final gris = PdfColor.fromHex('#d9d9d9');
    final verde = PdfColor.fromHex('#15803d');

    bool isActive(String key) {
      switch (key) {
        case 'APLIC': return proc.contains('APLIC');
        case 'COSEC': return proc.contains('COSEC');
        case 'PODA':  return proc.contains('PODA');
        case 'RUFA':  return proc.contains('RUFA');
        case 'TRITU': return proc.contains('TRITU');
        case 'CARRE': return proc.contains('CARRE');
        case 'MELAZ': return proc.contains('MELAZ');
        case 'OTRO':  return _isOtroProceso(proc);
        default: return false;
      }
    }

    pw.Widget procItem(String label, String key) {
      final active = isActive(key);
      return pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: const pw.Border(left: pw.BorderSide(width: 0.5)),
            color: active ? verde : PdfColors.white,
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: pw.Center(
            child: pw.Text(label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: active ? PdfColors.white : PdfColors.black,
              )),
          ),
        ),
      );
    }

    // Altura fija: 22+0.5+22 = 44.5px contenido + 1px bordes ≈ 46.
    // Necesario para que crossAxisAlignment.stretch funcione sin "height is infinite".
    return pw.Container(
      height: 46,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Columna PROCESO (spannea ambas filas)
          pw.Container(
            width: 52,
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(width: 0.5)),
            ),
            child: pw.Center(
              child: pw.Text('PROCESO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
          ),
          // Centro: 2 filas de 4 procesos c/u
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  height: 22,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      procItem('APLICACIÓN', 'APLIC'),
                      procItem('PODA', 'PODA'),
                      procItem('TRITURADO', 'TRITU'),
                      procItem('MELAZA', 'MELAZ'),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: PdfColors.black),
                pw.Container(
                  height: 22,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      procItem('COSECHA', 'COSEC'),
                      procItem('RUFA', 'RUFA'),
                      procItem('CARRETEO', 'CARRE'),
                      procItem('OTRO', 'OTRO'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Columna CULTIVO (spannea ambas filas, fondo gris)
          pw.Container(
            width: 100,
            decoration: pw.BoxDecoration(
              color: gris,
              border: const pw.Border(left: pw.BorderSide(width: 0.5)),
            ),
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('CULTIVO',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                pw.SizedBox(height: 3),
                pw.Text(cultivo ?? '',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Datos principales ─────────────────────────────────────────────────────
  // Layout idéntico al HTML: 2 filas × (OPERADOR|val|SUPERVISOR|val|FECHA|val)
  //                                     (TRACTOR |val|IMPLEMENTO|val|HORARIO|val)

  static pw.Widget _datosPrincipales(RegistroDiario r, DateFormat fmt) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(58),   // OPERADOR / TRACTOR
        1: pw.FlexColumnWidth(1.6),
        2: pw.FixedColumnWidth(66),   // SUPERVISOR / IMPLEMENTO
        3: pw.FlexColumnWidth(1.6),
        4: pw.FixedColumnWidth(50),   // FECHA / HORARIO
        5: pw.FlexColumnWidth(0.8),
      },
      children: [
        _row6('OPERADOR:', r.operadorNombre, 'SUPERVISOR:',
            r.supervisorNombre ?? '', 'FECHA:', fmt.format(r.fecha)),
        _row6('TRACTOR:', r.tractorCodigo, 'IMPLEMENTO:',
            r.implementoCodigo ?? '', 'HORARIO:', r.turno.toUpperCase()),
      ],
    );
  }

  // ── Inicio / Fin turno ────────────────────────────────────────────────────
  // Tabla plana de 4 columnas: evita pw.Column dentro de pw.TableRow
  // que causaba "height is infinite" en MultiPage.

  static pw.Widget _inicioFinTractor(RegistroDiario r) {
    final gris = PdfColor.fromHex('#d9d9d9');
    final refrig = r.tiempoTurno?.horaRefrigerio ?? '';
    final rp = refrig.split('-');
    final refrigStr =
        rp.length > 1 ? '${rp[0].trim()} - ${rp[1].trim()}' : refrig;
    final lotes = r.sectores
        .map((s) => s.loteCodigo)
        .where((l) => l.isNotEmpty)
        .join(', ');
    final sectores = r.sectores
        .map((s) => s.loteNombre)
        .where((s) => s.isNotEmpty)
        .join(', ');

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(1.0),
      },
      children: [
        // Cabeceras
        pw.TableRow(children: [
          _grisCell('INICIO DEL TURNO DE TRABAJO', gris, bold: true),
          _grisCell('', gris),
          _grisCell('FIN DEL TURNO DE TRABAJO', gris, bold: true),
          _grisCell('', gris),
        ]),
        // Filas de datos
        _row4('HORÓMETRO TRACTOR INICIO', _fmtNum(r.horometro?.tractorInicio),
            'HORÓMETRO TRACTOR FINAL', _fmtNum(r.horometro?.tractorFinal)),
        _row4(
            'HORÓMETRO IMPLEMENTO INICIO',
            _fmtNum(r.horometro?.implementoInicio),
            'HORÓMETRO IMPLEMENTO FINAL',
            _fmtNum(r.horometro?.implementoFinal)),
        _row4(
            'Hora salida de Taller base / TD',
            r.tiempoTurno?.horaSalidaTaller ?? '',
            'Hora salida del punto de trabajo',
            r.tiempoTurno?.horaSalidaPunto ?? ''),
        _row4(
            'Hora de llegada al punto de trabajo',
            r.tiempoTurno?.horaLlegadaPunto ?? '',
            'Hora llegada a Taller Base / TD',
            r.tiempoTurno?.horaLlegadaTaller ?? ''),
        _row4('Marcha de trabajo (Caja Cambios)', r.cajaCambiosNombre ?? '',
            'Lotes trabajados', lotes.isEmpty ? '-' : lotes),
        _row4('Hora de refrigerio', refrigStr, 'Sectores trabajados',
            sectores.isEmpty ? '-' : sectores),
      ],
    );
  }

  // ── Bines ─────────────────────────────────────────────────────────────────

  static pw.Widget _binesTable(RegistroDiario r) {
    final gris = PdfColor.fromHex('#d9d9d9');

    // Ordenar por franja horaria y filtrar cantidad > 0
    final bines = [...r.bines]
      ..sort((a, b) => a.franjaHoraria.compareTo(b.franjaHoraria));
    final total = bines.fold<int>(0, (s, b) => s + b.cantidad);

    // Si no hay bines, mostrar mensaje
    if (bines.isEmpty) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            color: gris,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
                'SOLO EN CASO DE COSECHA (CONTABILIZAR BINES LLENOS CARGADOS)',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.4)),
            child: pw.Text('Sin bines registrados',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ),
        ],
      );
    }

    // Dividir en dos mitades para layout lado a lado
    final half = (bines.length / 2).ceil();

    // Tabla centrada con ancho fijo proporcional al contenido (no 100% de página)
    const colWidths = {
      0: pw.FixedColumnWidth(80.0),  // horario "06:00 - 07:00"
      1: pw.FixedColumnWidth(52.0),  // cantidad
      2: pw.FixedColumnWidth(80.0),  // horario
      3: pw.FixedColumnWidth(52.0),  // cantidad
      4: pw.FixedColumnWidth(52.0),  // total
    };

    final tableWidget = pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: colWidths,
      children: [
        pw.TableRow(children: [
          _cell('HORARIO', bold: true, align: pw.TextAlign.center),
          _cell('CANTIDAD', bold: true, align: pw.TextAlign.center),
          _cell('HORARIO', bold: true, align: pw.TextAlign.center),
          _cell('CANTIDAD', bold: true, align: pw.TextAlign.center),
          _cell('TOTAL', bold: true, align: pw.TextAlign.center),
        ]),
        for (var i = 0; i < half; i++)
          pw.TableRow(children: [
            _cell(bines[i].franjaHoraria, align: pw.TextAlign.center),
            _cell(bines[i].cantidad > 0 ? '${bines[i].cantidad}' : '',
                align: pw.TextAlign.center),
            i + half < bines.length
                ? _cell(bines[i + half].franjaHoraria,
                    align: pw.TextAlign.center)
                : _cell(''),
            i + half < bines.length
                ? _cell(
                    bines[i + half].cantidad > 0
                        ? '${bines[i + half].cantidad}'
                        : '',
                    align: pw.TextAlign.center)
                : _cell(''),
            i == 0
                ? _cell(total > 0 ? '$total' : '',
                    bold: true, align: pw.TextAlign.center)
                : _cell(''),
          ]),
      ],
    );

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          color: gris,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
              'SOLO EN CASO DE COSECHA (CONTABILIZAR BINES LLENOS CARGADOS)',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ),
        // Centrado: el Align envuelve la tabla de ancho fijo
        pw.Align(alignment: pw.Alignment.center, child: tableWidget),
      ],
    );
  }

  // ── Paros ─────────────────────────────────────────────────────────────────
  // Réplica exacta de plantilla_tractor_conbines.html.
  // pdf 3.10.8 no tiene TableCell.columnSpan → usamos Row+Expanded con flex proporcional.
  // Proporciones de columnas: 16|8|8|6|8|8|16|10|8|8 (suma 96)
  // Sección 1 (cols 0-2=32) | Sección 2 (cols 3-5=22) | Sección 3 (cols 6-9=42)

  static pw.Widget _parosTable(RegistroDiario r) {
    final gris = PdfColor.fromHex('#d9d9d9');

    List<ParoEquipo> byTipo(List<String> kws) => r.paros.where((p) {
          final s = '${p.tipoParoNombre}${p.tipoParoCodigo}'.toLowerCase();
          return kws.any((k) => s.contains(k));
        }).toList();

    final clima  = byTipo(['clim', 'lluv', 'prec']);
    final comb   = byTipo(['comb', 'gaso', 'fuel']);
    final fallas = byTipo(['fall', 'mec', 'avar']);
    final calib  = byTipo(['calib']);
    final charla = byTipo(['charl', 'capac']);

    final clasificados = {...clima, ...comb, ...fallas, ...calib, ...charla};
    final sinClasif = r.paros.where((p) => !clasificados.contains(p)).toList();
    final fallasAll = [...fallas, ...sinClasif];

    ParoEquipo? getAt(List<ParoEquipo> list, int i) =>
        i < list.length ? list[i] : null;

    String hi(ParoEquipo? p)  => p?.horaInicio ?? '';
    String hf(ParoEquipo? p)  => p?.horaFinal ?? '';
    String mot(ParoEquipo? p) => p?.motivo ?? '';
    String eq(ParoEquipo? p)  => p?.equipo ?? '';
    String gln(ParoEquipo? p) =>
        (p?.galones != null) ? _fmtNum(p!.galones) : '';

    pw.Widget dc(String text,
        {pw.TextAlign align = pw.TextAlign.left, bool lastCol = false}) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: lastCol ? pw.BorderSide.none : const pw.BorderSide(width: 0.5),
          ),
        ),
        constraints: const pw.BoxConstraints(minHeight: 18),
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: pw.Text(text,
            textAlign: align, style: const pw.TextStyle(fontSize: 7.5)),
      );
    }

    pw.Widget gc(String text, {bool lastCol = false}) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: gris,
          border: pw.Border(
            right: lastCol ? pw.BorderSide.none : const pw.BorderSide(width: 0.5),
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      );
    }

    // Celda blanca vacía — simula el rowspan vacío del HTML
    pw.Widget ec({bool lastCol = false}) => pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: lastCol ? pw.BorderSide.none : const pw.BorderSide(width: 0.5),
        ),
      ),
      constraints: const pw.BoxConstraints(minHeight: 18),
    );

    pw.Widget divH() => pw.Container(height: 0.5, color: PdfColors.black);
    pw.Widget e(int flex, pw.Widget child) =>
        pw.Expanded(flex: flex, child: child);

    // Filas dinámicas: mínimo 1, máximo lo que haya en cada categoría
    final sec1Rows = [clima.length, comb.length, fallasAll.length]
        .fold(1, (a, b) => b > a ? b : a);
    final sec2Rows = [calib.length, charla.length]
        .fold(1, (a, b) => b > a ? b : a);

    final children = <pw.Widget>[
      // F1: título completo (gris)
      pw.Container(
        color: gris,
        width: double.infinity,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('MOTIVOS DE PARO DE LOS EQUIPOS',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
      ),
      divH(),
      // F2: cabeceras de sección
      pw.Row(children: [
        e(32, gc('FACTOR CLIMÁTICO')),
        e(22, gc('ABASTECIMIENTO COMBUSTIBLE')),
        e(42, gc('FALLAS MECÁNICAS', lastCol: true)),
      ]),
      divH(),
      // F3: cabeceras de columna (10)
      pw.Row(children: [
        e(16, gc('MOTIVO')),
        e(8,  gc('INICIO')),
        e(8,  gc('FINAL')),
        e(6,  gc('GLNS')),
        e(8,  gc('INICIO')),
        e(8,  gc('FINAL')),
        e(16, gc('MOTIVO')),
        e(10, gc('EQUIPO')),
        e(8,  gc('INICIO')),
        e(8,  gc('FINAL', lastCol: true)),
      ]),
    ];

    // Filas de datos sección 1 (clima | comb | fallas) — dinámicas
    for (var i = 0; i < sec1Rows; i++) {
      children.add(divH());
      children.add(pw.Row(children: [
        e(16, dc(mot(getAt(clima, i)))),
        e(8,  dc(hi(getAt(clima, i)),  align: pw.TextAlign.center)),
        e(8,  dc(hf(getAt(clima, i)),  align: pw.TextAlign.center)),
        e(6,  dc(gln(getAt(comb, i)),  align: pw.TextAlign.center)),
        e(8,  dc(hi(getAt(comb, i)),   align: pw.TextAlign.center)),
        e(8,  dc(hf(getAt(comb, i)),   align: pw.TextAlign.center)),
        e(16, dc(mot(getAt(fallasAll, i)))),
        e(10, dc(eq(getAt(fallasAll, i)))),
        e(8,  dc(hi(getAt(fallasAll, i)), align: pw.TextAlign.center)),
        e(8,  dc(hf(getAt(fallasAll, i)), align: pw.TextAlign.center, lastCol: true)),
      ]));
    }

    // Sección 2: CALIBRACIÓN + CHARLAS
    // Últimas 4 cols = celdas blancas vacías (igual que rowspan en HTML)
    children.addAll([
      divH(),
      pw.Row(children: [
        e(32, gc('CALIBRACIÓN DE EQUIPOS')),
        e(22, gc('CHARLAS O CAPACITACIONES')),
        e(16, ec()),
        e(10, ec()),
        e(8,  ec()),
        e(8,  ec(lastCol: true)),
      ]),
      divH(),
      pw.Row(children: [
        e(16, gc('MOTIVO')),
        e(8,  gc('INICIO')),
        e(8,  gc('FINAL')),
        e(6,  gc('MOTIVO')),
        e(8,  gc('INICIO')),
        e(8,  gc('FINAL')),
        e(16, ec()),
        e(10, ec()),
        e(8,  ec()),
        e(8,  ec(lastCol: true)),
      ]),
    ]);

    // Filas de datos sección 2 (calib | charlas) — dinámicas
    for (var i = 0; i < sec2Rows; i++) {
      children.add(divH());
      children.add(pw.Row(children: [
        e(16, dc(mot(getAt(calib, i)))),
        e(8,  dc(hi(getAt(calib, i)),   align: pw.TextAlign.center)),
        e(8,  dc(hf(getAt(calib, i)),   align: pw.TextAlign.center)),
        e(6,  dc(mot(getAt(charla, i)))),
        e(8,  dc(hi(getAt(charla, i)),  align: pw.TextAlign.center)),
        e(8,  dc(hf(getAt(charla, i)),  align: pw.TextAlign.center)),
        e(16, ec()),
        e(10, ec()),
        e(8,  ec()),
        e(8,  ec(lastCol: true)),
      ]));
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: children),
    );
  }

  // ── Checklist ─────────────────────────────────────────────────────────────
  // Réplica exacta de plantilla_tractor_conbines.html:
  // 8 columnas: [INSPECC. TRACTOR = 4 cols] [INSPECC. IMPLEMENTO = 4 cols]
  // Cada lado muestra 2 ítems por fila: ítem|✓|ítem|✓ × 2 lados.
  static List<pw.Widget> _checklistWidgets(RegistroDiario r) {
    final checklist = r.checklist;
    final gris = PdfColor.fromHex('#d9d9d9');

    final headerWidget = pw.Container(
      color: gris,
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('CHECK LIST DIARIO  –  Verificar: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Container(
            width: 14, height: 14,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#bbf7d0'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Center(
              child: pw.Text('B',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#14532d'))),
            ),
          ),
          pw.Text(' Bien    ', style: const pw.TextStyle(fontSize: 8)),
          pw.Container(
            width: 14, height: 14,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#fecaca'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Center(
              child: pw.Text('M',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#7f1d1d'))),
            ),
          ),
          pw.Text(' Mal', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );

    if (checklist.isEmpty) {
      return [
        headerWidget,
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.4)),
          child: pw.Text(
            'Sin datos de checklist',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
      ];
    }

    final grouped = <String, List<ChecklistResultado>>{};
    for (final item in checklist) {
      grouped.putIfAbsent(item.categoriaNombre, () => []).add(item);
    }
    final categories = grouped.entries.toList();

    // 2 categorías lado a lado → 8 columnas, 2 ítems por lado por fila
    // pw.TableCell.columnSpan no existe en pdf 3.10.8 → cabecera sin colspan:
    // col0 = nombre categoría izq, cols 1-3 vacíos; col4 = nombre cat der, cols 5-7 vacíos.
    if (categories.length == 2) {
      final leftItems  = categories[0].value;
      final rightItems = categories[1].value;
      final leftPairs  = (leftItems.length / 2).ceil();
      final rightPairs = (rightItems.length / 2).ceil();
      final maxPairs   = leftPairs > rightPairs ? leftPairs : rightPairs;

      final rows = <pw.TableRow>[
        pw.TableRow(children: [
          _grisCell(categories[0].key.toUpperCase(), gris, bold: true),
          _grisCell('', gris),
          _grisCell('', gris),
          _grisCell('', gris),
          _grisCell(categories[1].key.toUpperCase(), gris, bold: true),
          _grisCell('', gris),
          _grisCell('', gris),
          _grisCell('', gris),
        ]),
      ];

      for (var i = 0; i < maxPairs; i++) {
        final li = i * 2;
        final ri = i * 2;
        final l1 = li < leftItems.length ? leftItems[li] : null;
        final l2 = li + 1 < leftItems.length ? leftItems[li + 1] : null;
        final r1 = ri < rightItems.length ? rightItems[ri] : null;
        final r2 = ri + 1 < rightItems.length ? rightItems[ri + 1] : null;
        rows.add(pw.TableRow(children: [
          _cell(l1?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(l1 != null ? l1.resultado.toLowerCase() : ''),
          _cell(l2?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(l2 != null ? l2.resultado.toLowerCase() : ''),
          _cell(r1?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(r1 != null ? r1.resultado.toLowerCase() : ''),
          _cell(r2?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(r2 != null ? r2.resultado.toLowerCase() : ''),
        ]));
      }

      return [
        headerWidget,
        pw.Table(
          border: pw.TableBorder.all(width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.0),
            1: pw.FixedColumnWidth(18),
            2: pw.FlexColumnWidth(3.0),
            3: pw.FixedColumnWidth(18),
            4: pw.FlexColumnWidth(3.0),
            5: pw.FixedColumnWidth(18),
            6: pw.FlexColumnWidth(3.0),
            7: pw.FixedColumnWidth(18),
          },
          children: rows,
        ),
      ];
    }

    // Fallback: 1 categoría o más de 2 → 4 columnas, 2 ítems por fila
    final widgets = <pw.Widget>[headerWidget];
    for (final entry in categories) {
      final catItems = entry.value;
      final List<pw.TableRow> rows = [
        pw.TableRow(children: [
          _grisCell(entry.key.toUpperCase(), gris, bold: true),
          _grisCell('', gris),
          _grisCell('', gris),
          _grisCell('', gris),
        ]),
      ];
      for (var i = 0; i < catItems.length; i += 2) {
        final a = catItems[i];
        final b = i + 1 < catItems.length ? catItems[i + 1] : null;
        rows.add(pw.TableRow(children: [
          _cell(a.itemNombre, fontSize: 7.5),
          _checkBadge(a.resultado.toLowerCase()),
          _cell(b?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(b != null ? b.resultado.toLowerCase() : ''),
        ]));
      }
      widgets.add(pw.Table(
        border: pw.TableBorder.all(width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.5),
          1: pw.FixedColumnWidth(20),
          2: pw.FlexColumnWidth(3.5),
          3: pw.FixedColumnWidth(20),
        },
        children: rows,
      ));
    }
    return widgets;
  }

  // ── Observaciones / Firmas / Footer ───────────────────────────────────────

  static pw.Widget _observacionesBox(String? texto) {
    final gris = PdfColor.fromHex('#d9d9d9');
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          color: gris,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('Observaciones de la maquinaria:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ),
        pw.Container(
          width: double.infinity,
          height: 40,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.black)),
          child: pw.Text(texto ?? '', style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  static pw.Widget _firmas(List<String> etiquetas, {Uint8List? firmaOperador}) {
    return pw.Row(
      children: etiquetas.asMap().entries
          .map((entry) {
            final isOperadorSlot = entry.key == 0;
            final label = entry.value;
            return pw.Expanded(
              child: pw.Column(children: [
                if (isOperadorSlot && firmaOperador != null)
                  pw.Image(pw.MemoryImage(firmaOperador), height: 36, fit: pw.BoxFit.contain)
                else
                  pw.SizedBox(height: 36),
                pw.Divider(thickness: 1.0, indent: 16, endIndent: 16),
                pw.Text(label,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ]),
            );
          })
          .toList(),
    );
  }

  // ============================================================================
  // GENERADOR — VEHÍCULO desde RegistroDiario (supervisor / historial)
  // ============================================================================

  static Future<pw.Document> _generarPdfDesdeRegistroDiarioVehiculo(
      RegistroDiario r) async {
    final vd = r.vehiculoDetalle;
    final rv = RegistroVehiculo(
      id: r.id,
      numeroRegistro: r.numeroRegistro,
      fecha: r.fecha,
      turno: r.turno,
      procesoNombre: r.procesoNombre,
      procesoCodigo:
          r.procesoCodigo.isNotEmpty ? r.procesoCodigo : r.procesoNombre,
      operadorNombre: r.operadorNombre,
      supervisorNombre: r.supervisorNombre,
      tractorCodigo: r.tractorCodigo,
      tractorDescripcion: r.implementoCodigo ?? '',
      estado: r.estado,
      observacionesMaq: r.observacionesMaq,
      kmCamionInicio: vd?.kmCamionInicio,
      kmCamionFinal: vd?.kmCamionFinal,
      kmImplementoInicio: vd?.kmImplementoInicio,
      kmImplementoFinal: vd?.kmImplementoFinal,
      horaSalidaBase: vd?.horaSalidaBase,
      horaLlegadaZona: vd?.horaLlegadaZona,
      horaRetornoBase: vd?.horaRetornoBase,
      horaLlegadaTaller: vd?.horaLlegadaTaller,
      horaRefrigerio: vd?.horaRefrigerio,
      cantidadTancadas: vd?.cantidadTancadas,
      combustibles: r.combustiblesVehiculo
          .map((c) => CombustibleVehiculo(
                glns: c.glns,
                horaInicio: c.horaInicio,
                horaFinal: c.horaFinal,
              ))
          .toList(),
      paros: r.parosVehiculo
          .map((p) => ParoVehiculo(
                motivo: p.motivo,
                horaInicio: p.horaInicio ?? '',
                horaFinal: p.horaFinal,
              ))
          .toList(),
    );
    return _generarPdfVehiculo(rv,
        checklist: r.checklist,
        cultivoNombre: r.cultivoNombreEspecie.isNotEmpty
            ? r.cultivoNombreEspecie
            : null,
        firmaOperador: r.firmaOperador != null ? base64Decode(r.firmaOperador!) : null);
  }

  // ============================================================================
  // GENERADOR — VEHÍCULO (desde RegistroVehiculo nativo del operador)
  // ============================================================================

  static Future<pw.Document> _generarPdfVehiculo(RegistroVehiculo r,
      {List<ChecklistResultado> checklist = const [],
      String? cultivoNombre,
      Uint8List? firmaOperador}) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');
    final results = await Future.wait([_loadTheme(), _loadLogoImage()]);
    final theme = results[0] as pw.ThemeData;
    final logo = results[1] as pw.MemoryImage?;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        build: (ctx) => [
          _headerVehiculo(r, logo),
          pw.SizedBox(height: 4),
          _procesoVehiculoRow(r, cultivoNombre: cultivoNombre),
          pw.SizedBox(height: 4),
          _datosVehiculo(r, fmt),
          pw.SizedBox(height: 4),
          _inicioFinVehiculo(r),
          pw.SizedBox(height: 4),
          _combustibleFallasTable(r),
          pw.SizedBox(height: 4),
          ..._checklistVehiculoWidgets(checklist),
          pw.SizedBox(height: 4),
          _observacionesBox(r.observacionesMaq),
          pw.SizedBox(height: 12),
          _firmas(['Firma del Operador', 'Firma del Supervisor'], firmaOperador: firmaOperador),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _headerVehiculo(
      RegistroVehiculo r, pw.MemoryImage? logoImage) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.75)),
      child: pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(70),
          1: pw.FlexColumnWidth(1),
          2: pw.FixedColumnWidth(120),
        },
        border: pw.TableBorder.all(width: 0.75),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(
                child: logoImage != null
                    ? pw.Container(
                        width: 56,
                        height: 42,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    : pw.Text('AGROKASA',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColor.fromHex('#15803d'))),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text('CONTROL DIARIO DE OPERACIÓN DE CAMIONES',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
            ),
            pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                _headerFormCell('MMA-FR-013', bold: true, borderBottom: true),
                _headerFormCell('Versión: 01', borderBottom: true),
                _headerFormCell('Fecha Aprobación: 06/06/2025'),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  // Réplica exacta de plantilla_vehiculo.html: 2 filas de procesos con PROCESO y CULTIVO spanneados.
  static pw.Widget _procesoVehiculoRow(RegistroVehiculo r,
      {String? cultivoNombre}) {
    final proc = r.procesoCodigo.toUpperCase();
    final nombre = r.procesoNombre.toUpperCase();
    final gris = PdfColor.fromHex('#d9d9d9');
    final verde = PdfColor.fromHex('#15803d');

    bool isActive(String key) {
      switch (key) {
        case 'REGADO':         return proc.contains('REGAD') || nombre.contains('REGAD');
        case 'MANGUERAS':      return proc.contains('MANG')  || nombre.contains('MANG');
        case 'MATERIALES':     return proc.contains('MATER') || nombre.contains('MATER');
        case 'ABASTECIMIENTO': return proc.contains('ABAST') || nombre.contains('ABAST');
        case 'OTRO':           return _esOtroVehiculo(proc, nombre);
        default: return false;
      }
    }

    pw.Widget procItem(String label, String key) {
      final active = isActive(key);
      return pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: const pw.Border(left: pw.BorderSide(width: 0.5)),
            color: active ? verde : PdfColors.white,
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: pw.Center(
            child: pw.Text(label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: active ? PdfColors.white : PdfColors.black,
              )),
          ),
        ),
      );
    }

    final otroActive = isActive('OTRO');

    return pw.Container(
      height: 46,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // PROCESO (spannea ambas filas)
          pw.Container(
            width: 52,
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(width: 0.5)),
            ),
            child: pw.Center(
              child: pw.Text('PROCESO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
          ),
          // 2 filas de procesos
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  height: 22,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      procItem('REGADO DE CAMINOS', 'REGADO'),
                      procItem('TRASLADO DE MANGUERAS', 'MANGUERAS'),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: PdfColors.black),
                pw.Container(
                  height: 22,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      procItem('TRASLADO DE MATERIALES', 'MATERIALES'),
                      procItem('ABASTECIMIENTO APLICACION', 'ABASTECIMIENTO'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // OTRO — celda completa verde cuando activo (sin cuadro checkbox)
          pw.Container(
            width: 46,
            decoration: pw.BoxDecoration(
              border: const pw.Border(left: pw.BorderSide(width: 0.5)),
              color: otroActive ? verde : null,
            ),
            child: pw.Center(
              child: pw.Text('OTRO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: otroActive ? PdfColors.white : PdfColors.black,
                )),
            ),
          ),
          // CULTIVO — gris con valor visible
          pw.Container(
            width: 90,
            decoration: pw.BoxDecoration(
              color: gris,
              border: const pw.Border(left: pw.BorderSide(width: 0.5)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('CULTIVO',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                if (cultivoNombre != null && cultivoNombre.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(cultivoNombre,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _datosVehiculo(RegistroVehiculo r, DateFormat fmt) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(58),   // OPERADOR / CAMIÓN
        1: pw.FlexColumnWidth(1.6),
        2: pw.FixedColumnWidth(66),   // SUPERVISOR / IMPLEMENTO
        3: pw.FlexColumnWidth(1.6),
        4: pw.FixedColumnWidth(50),   // FECHA / HORARIO
        5: pw.FlexColumnWidth(0.8),
      },
      children: [
        _row6('OPERADOR:', r.operadorNombre, 'SUPERVISOR:',
            r.supervisorNombre ?? '', 'FECHA:', fmt.format(r.fecha)),
        _row6('CAMIÓN:', r.tractorCodigo, 'IMPLEMENTO:', r.tractorDescripcion,
            'HORARIO:', r.turno.toUpperCase()),
      ],
    );
  }

  // Tabla plana 4 columnas — misma razón que _inicioFinTractor:
  // evita pw.Column anidado en pw.TableRow que causa "height is infinite".
  static pw.Widget _inicioFinVehiculo(RegistroVehiculo r) {
    final gris = PdfColor.fromHex('#d9d9d9');
    final refrig = r.horaRefrigerio ?? '';
    final rp = refrig.split('-');
    final refrigStr =
        rp.length > 1 ? '${rp[0].trim()} - ${rp[1].trim()}' : refrig;

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(1.0),
      },
      children: [
        pw.TableRow(children: [
          _grisCell('INICIO DEL TURNO DE TRABAJO', gris, bold: true),
          _grisCell('', gris),
          _grisCell('FIN DEL TURNO DE TRABAJO', gris, bold: true),
          _grisCell('', gris),
        ]),
        _row4('KM / HORÓMETRO CAMIÓN INICIO', _fmtNum(r.kmCamionInicio),
            'KM / HORÓMETRO CAMIÓN FINAL', _fmtNum(r.kmCamionFinal)),
        _row4('HORÓMETRO IMPLEMENTO INICIO', _fmtNum(r.kmImplementoInicio),
            'Hora de Refrigerio', refrigStr),
        _row4('Hora salida de Taller base / TD', r.horaSalidaBase ?? '',
            'Hora retorno hacia base', r.horaRetornoBase ?? ''),
        _row4('Hora llegada a zona de trabajo', r.horaLlegadaZona ?? '',
            'Hora llegada a taller Base', r.horaLlegadaTaller ?? ''),
        _row4('Cantidad tancadas / traslados',
            r.cantidadTancadas?.toString() ?? '', '', ''),
      ],
    );
  }

  static pw.Widget _combustibleFallasTable(RegistroVehiculo r) {
    final gris = PdfColor.fromHex('#d9d9d9');

    // Mínimo 2 filas de datos (como el HTML), más si hay datos reales
    final numRows = [2, r.combustibles.length, r.paros.length]
        .fold(2, (a, b) => b > a ? b : a);

    CombustibleVehiculo? getComb(int i) =>
        i < r.combustibles.length ? r.combustibles[i] : null;
    ParoVehiculo? getParo(int i) =>
        i < r.paros.length ? r.paros[i] : null;

    pw.Widget gc(String text, {bool lastCol = false}) => pw.Container(
      decoration: pw.BoxDecoration(
        color: gris,
        border: pw.Border(
          right: lastCol ? pw.BorderSide.none : const pw.BorderSide(width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
    );

    pw.Widget dc(String text,
        {pw.TextAlign align = pw.TextAlign.left, bool lastCol = false}) =>
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: lastCol ? pw.BorderSide.none : const pw.BorderSide(width: 0.5),
          ),
        ),
        constraints: const pw.BoxConstraints(minHeight: 22),
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: pw.Text(text,
            textAlign: align, style: const pw.TextStyle(fontSize: 7.5)),
      );

    pw.Widget e(int flex, pw.Widget child) =>
        pw.Expanded(flex: flex, child: child);
    pw.Widget divH() => pw.Container(height: 0.5, color: PdfColors.black);

    final children = <pw.Widget>[
      // F1: cabeceras de sección (igual al HTML: ABAST. COMBUSTIBLE | PARO POR FALLAS MECÁNICAS)
      pw.Row(children: [
        e(3, gc('ABAST. COMBUSTIBLE')),
        e(4, gc('PARO POR FALLAS MECÁNICAS', lastCol: true)),
      ]),
      divH(),
      // F2: cabeceras de columna
      pw.Row(children: [
        e(1, gc('GLNS')),
        e(2, gc('INICIO')),
        e(2, gc('FINAL')),
        e(4, gc('MOTIVO')),
        e(2, gc('INICIO')),
        e(2, gc('FINAL', lastCol: true)),
      ]),
    ];

    for (var i = 0; i < numRows; i++) {
      final comb = getComb(i);
      final paro = getParo(i);
      children.add(divH());
      children.add(pw.Row(children: [
        e(1, dc(comb?.glns != null ? _fmtNum(comb!.glns) : '',
            align: pw.TextAlign.center)),
        e(2, dc(comb?.horaInicio ?? '', align: pw.TextAlign.center)),
        e(2, dc(comb?.horaFinal  ?? '', align: pw.TextAlign.center)),
        e(4, dc(paro?.motivo     ?? '')),
        e(2, dc(paro?.horaInicio ?? '', align: pw.TextAlign.center)),
        e(2, dc(paro?.horaFinal  ?? '', align: pw.TextAlign.center, lastCol: true)),
      ]));
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: children),
    );
  }

  // Réplica exacta de plantilla_vehiculo.html:
  // 8 columnas, 4 ítems por fila: ítem|✓|ítem|✓|ítem|✓|ítem|✓
  static List<pw.Widget> _checklistVehiculoWidgets(
      List<ChecklistResultado> checklist) {
    final gris = PdfColor.fromHex('#d9d9d9');

    final grouped = <String, List<ChecklistResultado>>{};
    for (final item in checklist) {
      grouped.putIfAbsent(item.categoriaNombre, () => []).add(item);
    }

    final headerWidget = pw.Container(
      color: gris,
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('CHECK LIST DIARIO  –  Verificar: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Container(
            width: 14, height: 14,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#bbf7d0'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Center(
              child: pw.Text('B',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#14532d'))),
            ),
          ),
          pw.Text(' Bien    ', style: const pw.TextStyle(fontSize: 8)),
          pw.Container(
            width: 14, height: 14,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#fecaca'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Center(
              child: pw.Text('M',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#7f1d1d'))),
            ),
          ),
          pw.Text(' Mal', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );

    if (grouped.isEmpty) {
      return [
        headerWidget,
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.4)),
          child: pw.Text(
            'Sin datos de checklist',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
      ];
    }

    final widgets = <pw.Widget>[headerWidget];

    for (final entry in grouped.entries) {
      final catItems = entry.value;
      // Cabecera: nombre categoría en col 0, cols 1-7 vacías (sin TableCell.columnSpan)
      final List<pw.TableRow> rows = [
        pw.TableRow(children: [
          _grisCell(entry.key.toUpperCase(), gris, bold: true),
          _grisCell('', gris), _grisCell('', gris), _grisCell('', gris),
          _grisCell('', gris), _grisCell('', gris), _grisCell('', gris),
          _grisCell('', gris),
        ]),
      ];
      // 4 ítems por fila en 8 columnas
      for (var i = 0; i < catItems.length; i += 4) {
        final a = catItems[i];
        final b = i + 1 < catItems.length ? catItems[i + 1] : null;
        final c = i + 2 < catItems.length ? catItems[i + 2] : null;
        final d = i + 3 < catItems.length ? catItems[i + 3] : null;
        rows.add(pw.TableRow(children: [
          _cell(a.itemNombre, fontSize: 7.5),
          _checkBadge(a.resultado.toLowerCase()),
          _cell(b?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(b != null ? b.resultado.toLowerCase() : ''),
          _cell(c?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(c != null ? c.resultado.toLowerCase() : ''),
          _cell(d?.itemNombre ?? '', fontSize: 7.5),
          _checkBadge(d != null ? d.resultado.toLowerCase() : ''),
        ]));
      }
      widgets.add(pw.Table(
        border: pw.TableBorder.all(width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.0),
          1: pw.FixedColumnWidth(18),
          2: pw.FlexColumnWidth(3.0),
          3: pw.FixedColumnWidth(18),
          4: pw.FlexColumnWidth(3.0),
          5: pw.FixedColumnWidth(18),
          6: pw.FlexColumnWidth(3.0),
          7: pw.FixedColumnWidth(18),
        },
        children: rows,
      ));
    }

    return widgets;
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  // Fila de 4 celdas: label|valor|label|valor — helper para tablas de inicio/fin.
  static pw.TableRow _row4(String l1, String v1, String l2, String v2) {
    pw.Widget lbl(String t) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(t,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
        );
    pw.Widget val(String t) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(t, style: const pw.TextStyle(fontSize: 7.5)),
        );
    return pw.TableRow(children: [lbl(l1), val(v1), lbl(l2), val(v2)]);
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: fontSize,
        ),
      ),
    );
  }

  static pw.Widget _grisCell(String text, PdfColor color, {bool bold = false}) {
    return pw.Container(
      color: color,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 8,
        ),
      ),
    );
  }

  // 6 columnas: etiqueta bold | valor | etiqueta bold | valor | etiqueta bold | valor
  // Idéntico al layout HTML: OPERADOR|val|SUPERVISOR|val|FECHA|val
  static pw.TableRow _row6(
      String c1, String c2, String c3, String c4, String c5, String c6) {
    pw.Widget labelCell(String t) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(t,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        );
    pw.Widget valueCell(String t) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(t, style: const pw.TextStyle(fontSize: 8)),
        );
    return pw.TableRow(children: [
      labelCell(c1),
      valueCell(c2),
      labelCell(c3),
      valueCell(c4),
      labelCell(c5),
      valueCell(c6),
    ]);
  }

  static String _fmtNum(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  // Badge de color circular para cada resultado del checklist:
  //   BIEN → círculo verde con "B"
  //   MAL  → círculo rojo  con "M"
  //   N/A  → círculo gris  con "N/A"
  //   vacío → círculo con borde gris (no evaluado)
  static pw.Widget _checkBadge(String resultado) {
    if (resultado.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Center(
          child: pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
          ),
        ),
      );
    }

    final isBien = resultado == 'bien';
    final isMal = resultado == 'mal';
    // Fondo claro para que la letra oscura resalte bien
    final bgColor = isBien
        ? PdfColor.fromHex('#bbf7d0')   // verde muy claro
        : isMal
            ? PdfColor.fromHex('#fecaca') // rojo muy claro
            : PdfColor.fromHex('#e5e7eb'); // gris claro
    final textColor = isBien
        ? PdfColor.fromHex('#14532d')   // verde oscuro
        : isMal
            ? PdfColor.fromHex('#7f1d1d') // rojo oscuro
            : PdfColor.fromHex('#374151'); // gris oscuro
    final label = isBien ? 'B' : isMal ? 'M' : 'N/A';
    final width = isBien || isMal ? 15.0 : 20.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(
        child: pw.Container(
          width: width,
          height: 15,
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          ),
          child: pw.Center(
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: textColor,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _isOtroProceso(String p) => ![
        'APLIC',
        'COSEC',
        'PODA',
        'TRITU',
        'RUFA',
        'CARRE',
        'MELAZ'
      ].any((k) => p.contains(k));

  static bool _esOtroVehiculo(String p, [String nombre = '']) =>
      !['REGAD', 'MATER', 'MANG', 'ABAST'].any((k) => p.contains(k) || nombre.contains(k));
}
