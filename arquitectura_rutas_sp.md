# Sistema de Rutas y Navegación — AgroMetrics

> Este documento explica **exclusivamente** cómo el APK obtiene, almacena y usa las rutas de navegación del usuario:
> qué SP se consume, cuándo, cómo se guardan los menús localmente y cómo se convierten en pantallas Flutter.

---

## Visión general del flujo

```
USUARIO hace LOGIN
        │
        ▼
1. SP: CLI547_AGMSP_ObtenerDatosUsuario   ← obtiene datos del usuario
        │
        ▼
2. SP: CLI547_AGMSP_SyncCatalogos         ← sincroniza catálogos (incluye TableName='Menu')
   → El servidor devuelve la lista de ítems de menú que el usuario tiene permiso de ver
        │
        ▼
3. MenuModel se guarda en ObjectBox (base de datos local)
        │
        ▼
4. ShellPage / AppDrawer leen los menús desde ObjectBox (sin red)
        │
        ▼
5. El usuario toca una opción → _resolveFlutterRoute() traduce la ruta DB → ruta Flutter
        │
        ▼
6. Navigator.pushNamed(context, '/grupos/menu')   ← navega a la pantalla
```

---

## Paso 1 — Login (quién eres)

**SP:** `CLI547_AGMSP_ObtenerDatosUsuario`

```http
POST {baseUrl}/EjecutarSPERP
Body:
{
  "NombreSP": "CLI547_AGMSP_ObtenerDatosUsuario",
  "Parametros": [
    { "NombreParametro": "Codigo", "Valor": "juan.perez" }
  ]
}
```

Este SP devuelve los datos del perfil del usuario. **No devuelve el menú**, solo el perfil.

---

## Paso 2 — Sincronización del menú (qué puedes ver)

**SP:** `CLI547_AGMSP_SyncCatalogos`  con `TableName = 'Menu'`

```http
POST {baseUrl}/EjecutarSPERP
Body:
{
  "NombreSP": "CLI547_AGMSP_SyncCatalogos",
  "Parametros": [
    { "NombreParametro": "TableName",    "Valor": "Menu" },
    { "NombreParametro": "IdUsuario",    "Valor": 42 },
    { "NombreParametro": "SinceVersion", "Valor": 0 }
  ]
}
```

### Qué devuelve el servidor

El servidor devuelve **la lista de ítems de menú que el usuario tiene permiso de ver**. Si el usuario no tiene acceso a un módulo, ese ítem simplemente no viene en la respuesta.

```json
[
  {
    "Id": 1,
    "Nombre": "Rendimiento",
    "Ruta": "",
    "Icono": "ic_group_packing",
    "Orden": 1,
    "ParentId": null,
    "EsGrupo": true,
    "Estado": "ACTIVO",
    "Componente": "ShellPage",
    "Sistema": "AGM",
    "Version": 5
  },
  {
    "Id": 10,
    "Nombre": "Control de Grupos",
    "Ruta": "grupos_menu",
    "Icono": "ic_perm_group",
    "Orden": 2,
    "ParentId": 1,
    "EsGrupo": false,
    "Estado": "ACTIVO",
    "Componente": "ShellPage",
    "Sistema": "AGM",
    "Version": 5
  },
  {
    "Id": 11,
    "Nombre": "Pallet",
    "Ruta": "pallet_menu",
    "Icono": "ic_rendpalet",
    "Orden": 3,
    "ParentId": 1,
    "EsGrupo": false,
    "Estado": "ACTIVO",
    "Componente": "ShellPage",
    "Sistema": "AGM",
    "Version": 5
  }
]
```

### Campos clave de cada ítem de menú

| Campo | Tipo | Significado |
|-------|------|-------------|
| `Id` | int | Identificador único del ítem |
| `Nombre` | string | Texto visible al usuario ("Control de Grupos") |
| `Ruta` | string | **Código** que el APK traduce a ruta Flutter (ej: `"grupos_menu"`) |
| `Icono` | string | Nombre del ícono a mostrar (ej: `"ic_perm_group"`) |
| `Orden` | int | Posición en el menú (se ordena de menor a mayor) |
| `ParentId` | int? | `null` = raíz / número = hijo de ese padre |
| `EsGrupo` | bool | `true` = es carpeta (no tiene ruta propia), `false` = es ítem navegable |
| `Estado` | string | `"ACTIVO"` = se muestra, `"INACTIVO"` = se oculta |
| `Componente` | string | A qué parte del APK pertenece (siempre `"ShellPage"`) |
| `Version` | int | Número de versión para delta-sync (solo se trae lo nuevo) |

### Delta sync (solo trae cambios)

El campo `SinceVersion` controla qué se trae:
- Primera vez → `SinceVersion: 0` → trae todo
- Siguientes veces → se envía la versión máxima guardada localmente → solo trae cambios nuevos

---

## Paso 3 — Almacenamiento en ObjectBox

Los ítems de menú se guardan en `MenuModel` dentro de ObjectBox (base de datos local del dispositivo).

**Código en Flutter:**
```dart
// sync_repository_impl.dart
'Menu': (items) async {
  final count = _upsertBy<MenuModel>(
    box: menuBox,
    fromJson: (m) => MenuModel.fromJson(m),   // ← parsea el JSON del SP
    items: items,
    whereIdEquals: (id) => MenuModel_.id.equals(id),
    jsonPickId: (m) => _pickInt(m, ['Id']),
    jsonPickVersion: (m) => _pickInt(m, ['Version', 'version']),
    getLocalVersion: (x) => x.version,
    carryPk: (a, b) => a.obxId = b.obxId,
  );
  await _saveMaxVersion('Menu', items);  // ← guarda versión para próxima sync
  return count;
},
```

> **Punto clave:** después de la sync, ya **no se vuelve a llamar ningún SP para el menú**. Todo lo siguiente es lectura local de ObjectBox.

---

## Paso 4 — Construcción del árbol de menús

`MenuRepositoryImpl` lee los `MenuModel` de ObjectBox y construye el árbol:

```dart
// menu_repository_impl.dart
Future<List<MenuNode>> getMenuTree() async {
  final all = box.getAll().map((e) => e.toEntity()).toList();

  // 1. Solo los ACTIVOS
  final menus = all
      .where((m) => m.estado.toUpperCase() == 'ACTIVO')
      .toList();

  // 2. Agrupar por parentId
  final byParent = <int?, List<Menu>>{};
  for (final m in menus) {
    byParent.putIfAbsent(m.parentId, () => []).add(m);
  }

  // 3. Ordenar cada nivel por campo 'orden'
  for (final l in byParent.values) {
    l.sort((a, b) => a.orden.compareTo(b.orden));
  }

  // 4. Construir árbol recursivo
  List<MenuNode> build(int? parent) {
    final list = byParent[parent] ?? [];
    return list.map((m) => MenuNode(menu: m, children: build(m.id))).toList();
  }

  // 5. Podar grupos vacíos
  List<MenuNode> prune(List<MenuNode> ns) => ns
      .where((n) => n.menu.esGrupo ? n.children.isNotEmpty : true)
      .map((n) => MenuNode(menu: n.menu, children: prune(n.children)))
      .toList();

  return prune([...build(null), ...build(0)]);
}
```

**Para la barra inferior (ShellPage)** se usan solo los ítems raíz con `componente == 'ShellPage'`:
```dart
Future<List<Menu>> getShellRoots({String componente = 'ShellPage'}) async {
  return all
      .where((m) =>
          m.estado == 'ACTIVO' &&
          m.parentId == null &&          // ← solo raíces
          m.componente.toLowerCase() == 'shellpage')
      .toList()
    ..sort((a, b) => a.orden.compareTo(b.orden));
}
```

---

## Paso 5 — Cómo se muestran en pantalla

### ShellPage (barra inferior / navigation rail)

```dart
// shell_page.dart — initState
_rootsFuture = GetIt.I<GetShellRoots>().call(componente: 'ShellPage');
```

Cada ítem raíz aparece como una pestaña en la barra inferior. Al tocar la pestaña, muestra los hijos como tarjetas en un `GridView`.

### AppDrawer (menú lateral)

El Drawer usa `BlocBuilder<MenuBloc, MenuState>`:
```dart
// app_drawer.dart
BlocBuilder<MenuBloc, MenuState>(
  builder: (context, state) {
    final tree = (state as MenuLoaded).tree;
    // tree = lista de MenuNode con sus hijos
    // Si esGrupo=true → ExpansionTile (carpeta desplegable)
    // Si esGrupo=false → DrawerItem (ítem directo navegable)
  },
)
```

El `MenuBloc` se dispara con `MenuStarted` al iniciar la app, llama `getMenuTree()` y emite `MenuLoaded(tree)`.

---

## Paso 6 — Traducción de ruta DB → ruta Flutter

Este es el paso central. El campo `Ruta` que viene del SP (ej: `"grupos_menu"`) **no es una ruta Flutter directamente**. El APK tiene una función `_resolveFlutterRoute()` que lo traduce:

```dart
String? _resolveFlutterRoute(String ruta) {
  final key = ruta.toLowerCase().trim();
  switch (key) {
    case 'grupos_menu':
    case 'grupo_control':
    case 'control_grupos':      return '/grupos/menu';

    case 'rend_palet':
    case 'pallet_menu':         return '/pallet/menu';

    case 'traza_ubi':           return '/trazabilidad/menu';

    case 'envase_menu':
    case 'rend_envase':         return '/envase/menu';

    case 'rend_tiempocos':
    case 'cosecha_tiempos':     return '/cosecha_tiempos/menu';

    case 'rend_plancosecha':
    case 'plan_cosecha':        return '/planificacion_cosecha/menu';

    case 'movimiento_fruta':
    case 'rend_traslado':       return '/movimiento_fruta/menu';

    case 'rend_bolso':
    case 'cosecha_bolso':       return '/cosecha_bolso/menu';

    case 'control_rendimiento': return '/control_rendimiento/menu';

    case 'fit_menu':
    case 'fitosanitario':       return '/fit/menu';

    case 'fit_historial':       return '/fit/historial';
    case 'fit_alertas':         return '/fit/alertas';
    case 'fit_mapa':            return '/fit/mapa';

    case 'aprobacion_ot':
    case 'orden_aprob':         return '/aprobacion-ot';

    case 'retiro_aplic':        return '/retiro-aplicacion';
    case 'en_proceso':          return '/ot-en-proceso';
    case 'ejecucion_ot':        return '/ot-ejecucion';

    default: return null;  // ← null = "Ruta no implementada"
  }
}
```

### Resultado: si devuelve `null`

```dart
final r = _resolveFlutterRoute(menu.ruta);
if (r != null) {
  Navigator.pushNamed(context, r);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Ruta no implementada')),
  );
}
```

---

## Tabla completa: Ruta DB → Ruta Flutter

| `Ruta` en la DB (viene del SP) | Ruta Flutter en el APK |
|-------------------------------|------------------------|
| `grupos_menu` / `grupo_control` / `control_grupos` | `/grupos/menu` |
| `rend_palet` / `pallet_menu` | `/pallet/menu` |
| `traza_ubi` | `/trazabilidad/menu` |
| `envase_menu` / `rend_envase` / `rend_menu` | `/envase/menu` |
| `rend_tiempocos` / `cosecha_tiempos` / `tiempo_cos_menu` | `/cosecha_tiempos/menu` |
| `rend_plancosecha` / `plan_cosecha` / `plancosecha_menu` | `/planificacion_cosecha/menu` |
| `movimiento_fruta` / `rend_traslado` | `/movimiento_fruta/menu` |
| `rend_bolso` / `cosecha_bolso` | `/cosecha_bolso/menu` |
| `control_rendimiento` | `/control_rendimiento/menu` |
| `fit_menu` / `fitosanitario` | `/fit/menu` |
| `fit_historial` | `/fit/historial` |
| `fit_alertas` | `/fit/alertas` |
| `fit_mapa` | `/fit/mapa` |
| `aprobacion_ot` / `orden_aprob` | `/aprobacion-ot` |
| `retiro_aplic` | `/retiro-aplicacion` |
| `en_proceso` | `/ot-en-proceso` |
| `ejecucion_ot` | `/ot-ejecucion` |
| cualquier otra | `null` → "Ruta no implementada" |

---

## Estructura del árbol de menú (ejemplo real)

```
Rendimiento (esGrupo=true, parentId=null)
├── Control de Grupos  (Ruta="grupos_menu"  → /grupos/menu)
├── Pallet             (Ruta="pallet_menu"  → /pallet/menu)
├── Envase             (Ruta="envase_menu"  → /envase/menu)
└── Trazabilidad       (Ruta="traza_ubi"   → /trazabilidad/menu)

Fitosanitario (esGrupo=true, parentId=null)
├── Misiones           (Ruta="fit_menu"     → /fit/menu)
├── Historial          (Ruta="fit_historial"→ /fit/historial)
└── Alertas            (Ruta="fit_alertas"  → /fit/alertas)
```

Los nodos con `esGrupo=true` son **carpetas** (no se pueden tocar directamente). Solo los nodos con `esGrupo=false` tienen ruta y llevan a una pantalla.

---

## Resumen: qué SP controla las rutas

| SP | Momento | Qué aporta a las rutas |
|----|---------|------------------------|
| `CLI547_AGMSP_SyncCatalogos` con `TableName='Menu'` | Al sincronizar (post-login o manual) | **Entrega la lista de menús que el usuario puede ver** — esto determina a qué módulos puede acceder |
| `CLI547_AGMSP_ObtenerDatosUsuario` | Al hacer login | Identifica al usuario (no controla rutas directamente) |

> **El SP `CLI547_AGMSP_SyncCatalogos` (Menu) es el único que controla qué rutas ve el usuario.**
> Si el servidor no incluye un ítem de menú para ese usuario, esa opción no existe en el APK.

---

## Para replicar en otro proyecto Flutter

1. Llamar `CLI547_AGMSP_SyncCatalogos` con `TableName='Menu'` después del login.
2. Guardar los ítems en una tabla local (ObjectBox, SQLite, etc.) con los campos: `Id`, `Nombre`, `Ruta`, `ParentId`, `EsGrupo`, `Estado`, `Orden`, `Componente`.
3. Al construir el menú, leer solo los registros con `Estado='ACTIVO'`, ordenar por `Orden`, armar árbol por `ParentId`.
4. Agregar una función `resolveRoute(String ruta)` que mapee el código de ruta del servidor a la ruta Flutter real (`/grupos/menu`, etc.).
5. Si `resolveRoute` devuelve `null`, mostrar "No disponible" en lugar de navegar.
6. Para agregar un nuevo módulo: el backend agrega el ítem en la tabla de menús con su `Ruta` (ej: `"nuevo_modulo"`), y en el APK se agrega un `case 'nuevo_modulo': return '/nuevo_modulo/menu';` en `resolveRoute`.



CREATE PROCEDURE dbo.CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO
    @IdUsuario INT,
    @SinceVersion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @zona_maq NVARCHAR(50) = 'PISCO';
    DECLARE @zona_per NVARCHAR(20) = 'PCO';

    -- Cultivos: el mapper del APK lee cultivo_id_erp y nombre_cultivo.
    SELECT 'cultivos' AS catalogo, (
        SELECT
            eb.Id            AS cultivo_id_erp,
            eb.NombreComun   AS nombre_cultivo,
            eb.NombreEspecie AS nombre_especie,
            eb.NombreGenero  AS nombre_genero,
            eb.Grupo         AS grupo,
            eb.SubGrupo      AS sub_grupo
        FROM EspeciesBotanicas eb
        ORDER BY eb.NombreComun
        FOR JSON PATH
    ) AS datos;

    -- Tractores y camiones: prefijo T% cubre ambos tipos en Pisco.
    SELECT 'tractores' AS catalogo, (
        SELECT
            m.Id            AS tractor_id_erp,
            m.Identificacion AS codigo_tractor,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'T%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Implementos: mismo patrón que tractores, prefijo I%.
    SELECT 'implementos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'I%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Vehiculos: mismo patrón que tractores, prefijo V%.
    SELECT 'vehiculos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE '%V%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Trabajadores
    SELECT 'trabajadores' AS catalogo, (
        SELECT
            t.Id AS trabajador_id_erp,
            u.Id AS usuario_id_erp,
            u.Codigo AS CodigoUsuario,
            SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS cod_trabajador,
            CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS nombre_completo
        FROM sujetos s
        INNER JOIN trabajadores t ON s.Id = t.Id_Sujeto
        INNER JOIN Usuarios u ON u.id_sujeto = s.Id
        INNER JOIN DireccionesSujeto ds ON ds.Id_Sujeto = s.Id
        INNER JOIN direcciones d ON ds.Id_Direccion = d.Id
        INNER JOIN Zonas z ON d.Id_Zona = z.Id
        WHERE z.Nombre = @zona_maq
        ORDER BY s.PrimerApellido, s.SegundoApellido, s.Nombre
        FOR JSON PATH
    ) AS datos;

    -- Lotes
    SELECT 'lotes' AS catalogo, (
        SELECT
            f.Id AS finca_id_erp,
            f.Codigo AS lote_codigo,
            CAST(f.SuperficieCultivable / 10000.0 AS DECIMAL(10,2)) AS hectareas_lote,
            c.Id AS lote_id_erp,
            TRIM(c.Descripcion) AS sublote,
            CAST(c.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas_sublote
        FROM Fincas f
        INNER JOIN Zonas z ON f.Id_zona = z.Id
        LEFT JOIN Cultivos c ON c.Id_finca = f.Id
        WHERE z.Codigo = @zona_per
          AND (f.Codigo LIKE 'U-%' OR f.Codigo LIKE '%P_A%' OR f.Id = 640)
        ORDER BY f.Codigo, TRIM(c.Descripcion)
        FOR JSON PATH
    ) AS datos;

    -- Procesos de tractor
    SELECT 'procesos' AS catalogo, (
        SELECT
            p.id                    AS proceso_id,
            p.codigo,
            p.nombre,
            p.requiere_bines,
            p.requiere_sublabores,
            p.tipo_registro
        FROM dbo.CLI547_AGM_MMA_PROCESOS p
        WHERE p.activo = 1
          AND p.tipo_registro = 'tractor'
        ORDER BY p.nombre
        FOR JSON PATH
    ) AS datos;

    -- Cajas de cambio (marchas de trabajo)
    SELECT 'cajas_cambios' AS catalogo, (
        SELECT id AS caja_id, nombre
        FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- Tipos de paro
    SELECT 'tipos_paro' AS catalogo, (
        SELECT id AS tipo_paro_id, codigo, nombre, requiere_galones, requiere_equipo
        FROM dbo.CLI547_AGM_MMA_TIPOS_PARO
        WHERE activo = 1
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- Checklist items
    SELECT 'checklist_items' AS catalogo, (
        SELECT
            ci.id            AS item_id,
            ci.categoria_id,
            cc.nombre        AS categoria,
            ci.nombre        AS item_nombre,
            ci.orden,
            ci.tipo_registro
        FROM dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO ci
        INNER JOIN dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS cc ON cc.id = ci.categoria_id
        WHERE ci.activo = 1
        ORDER BY cc.orden, ci.orden
        FOR JSON PATH
    ) AS datos;

    -- Último horómetro por tractor
    SELECT 'ultimo_horometro_tractores' AS catalogo, (
        SELECT
            t.tractor_id_erp,
            t.implemento_id_erp,
            t.codigo_tractor,
            t.codigo_implemento,
            t.ultimo_horometro_final,
            t.ultimo_implemento_final,
            t.ultima_fecha
        FROM
        (
            SELECT
                rd.tractor_id_erp,
                rd.implemento_id_erp,
                COALESCE(rd.codigo_tractor_snapshot COLLATE Modern_Spanish_CI_AS, m.Identificacion COLLATE Modern_Spanish_CI_AS) AS codigo_tractor,
                COALESCE(rd.codigo_implemento_snapshot COLLATE Modern_Spanish_CI_AS, m.Identificacion COLLATE Modern_Spanish_CI_AS) AS codigo_implemento,
                h.tractor_final                    AS ultimo_horometro_final,
                h.implemento_final                 AS ultimo_implemento_final,
                CONVERT(VARCHAR(10), rd.fecha, 23) AS ultima_fecha,
                ROW_NUMBER() OVER (PARTITION BY rd.tractor_id_erp ORDER BY rd.fecha DESC, h.updated_at DESC) AS rn
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd
            INNER JOIN dbo.CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = rd.id
            LEFT JOIN dbo.Maquinaria m ON m.Id = rd.tractor_id_erp
            WHERE rd.tractor_id_erp IS NOT NULL
              AND h.tractor_final IS NOT NULL
              AND rd.estado IN ('completado','aprobado')
        ) t
        WHERE t.rn = 1
        ORDER BY t.tractor_id_erp, t.implemento_id_erp
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- 🔥 CATÁLOGO DE FALLAS MECÁNICAS ACTUALIZADO (incluye categoria y aplicacion)
    -- =========================================================================
    SELECT 'fallas_mecanicas' AS catalogo, (
        SELECT
            id AS falla_id,
            codigo,
            nombre,
            categoria,
            aplicacion
        FROM dbo.CLI547_AGM_MMA_FALLAS_MECANICAS
        WHERE activo = 1
        ORDER BY nombre
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- 🧭 CATÁLOGO DE NAVEGACIÓN (menú móvil) con permisos del usuario
    -- =========================================================================
    SELECT 'navegacion' AS catalogo, (
        SELECT DISTINCT
            n.Id,
            n.Nombre,
            n.Ruta,
            n.Icono,
            n.Orden,
            n.ParentId,
            n.EsGrupo,
            n.Estado,
            c.Nombre AS Componente,
            s.Nombre AS Sistema,
            n.Version
        FROM dbo.CLI547_AGM_Navegacion n
        JOIN dbo.CLI547_AGM_Componentes c ON c.Id = n.IdComponente
        JOIN dbo.CLI547_AGM_Sistemas s ON s.Id = n.IdSistema
        WHERE n.Id IN (
            SELECT pu.IdNavegacion
            FROM dbo.CLI547_AGM_PermisosUsuario pu
            WHERE pu.IdUsuario = @IdUsuario
              AND pu.Acceso = 'PERMITIDO'
            UNION
            SELECT pn.IdNavegacion
            FROM dbo.CLI547_AGM_PermisosNavegacion pn
            WHERE pn.IdRol IN (
                SELECT ur.Id_Roles
                FROM dbo.Usuarios_Roles ur
                WHERE ur.Id_Usuarios = @IdUsuario
            )
              AND pn.Acceso = 'PERMITIDO'
              AND NOT EXISTS (
                  SELECT 1
                  FROM dbo.CLI547_AGM_PermisosUsuario pu
                  WHERE pu.IdUsuario = @IdUsuario
                    AND pu.IdNavegacion = pn.IdNavegacion
              )
        )
        AND n.Estado = 'ACTIVO'
        AND s.Nombre = 'AgroMetrics Móvil'
        AND (@SinceVersion IS NULL OR n.Version > @SinceVersion)
        ORDER BY n.ParentId, n.Orden, n.Nombre
        FOR JSON PATH
    ) AS datos;

END;
GO

SE ACTUALIZO NUESTRO SP QUE CONSUMIAMOS PARA QUE PODAMOS CONSUMIR EL MENU OSE LA NAVEGACION DEL USUARIO PREVIO QUE INICIA SESSION OK 