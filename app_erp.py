import streamlit as st
import requests
import pandas as pd
from datetime import datetime

# Configuración de la página
st.set_page_config(page_title="ERPagro API Manager", layout="wide")

# Credenciales y URL (Ambiente de Pruebas)
URL_BASE = "https://agkwebagro.agrokasa.pe/WSRESTMovilidadERPPruebas/api"
HEADERS_AUTH = {
    "username": "PCO_AUX.INFO_1",
    "password": "Agk.2025..$"
}

# --- Título Principal ---
st.title("🚜 Interfaz de Ejecución ERPagro")
st.markdown("Gestión de Procedimientos Almacenados y Reportes")

# --- Creación de Pestañas ---
tab1, tab2 = st.tabs(["🔑 Autenticación (Token)", "📊 Reporte de Usuarios"])

# --- PESTAÑA 1: GENERAR TOKEN ---
with tab1:
    st.header("Obtener Acceso")
    if st.button("Generar Token de Sesión"):
        try:
            response = requests.post(f"{URL_BASE}/login/authenticate", headers=HEADERS_AUTH)
            if response.status_code == 200:
                # Almacenamos el token en la sesión de Streamlit
                st.session_state['token'] = response.json()
                st.success("✅ Token generado con éxito")
                st.info("Este token permite ejecutar procedimientos en la pestaña 'Reporte de Usuarios'.")
                st.code(st.session_state['token'], language="text")
            else:
                st.error(f"Error {response.status_code}: {response.text}")
        except Exception as e:
            st.error(f"Error de conexión: {e}")

# --- PESTAÑA 2: EJECUTAR PROCEDIMIENTO ---
with tab2:
    st.header("Configuración del Procedimiento")
    
    if 'token' not in st.session_state:
        st.warning("⚠️ No se detectó un token activo. Ve a la pestaña 'Generar Token' primero.")
    else:
        # Nombre del SP ajustable
        nombre_sp_input = st.text_input("Nombre del Procedimiento Almacenado:", value="sp_usuarios_sistema_creados")
        
        st.subheader("Parámetros del SP")
        st.info("Se enviarán parámetros NULL automáticamente para evitar errores de conteo.")

        if st.button("🚀 Ejecutar y Mostrar Tabla"):
            nombre_sp_limpio = nombre_sp_input.strip()
            token = st.session_state['token']
            
            # 1. Construcción de Headers (Exactamente como tu ejemplo JS)
            headers_sp = {
                'accept': 'application/json',
                'Authorization': f"Bearer {token}",
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
            
            # 2. Construcción del Payload (Basado en tu objeto requestBody)
            # Enviamos 'None' en Python para que en el JSON final sea 'null'
            payload = {
                "NombreSP": nombre_sp_limpio,
                "TipoRespuesta": 0,
                "EntidadMapa": "",
                "Parametros": [
                    { "NombreParametro": None },
                    { "NombreParametro": None }
                ]
            }

            with st.spinner(f'Consultando {nombre_sp_limpio}...'):
                try:
                    # Usamos el parámetro 'json' de requests para enviar el diccionario como JSON válido
                    res = requests.post(f"{URL_BASE}/EjecutarSPERP", headers=headers_sp, json=payload)
                    
                    if res.status_code == 200:
                        data = res.json()
                        
                        if data and len(data) > 0:
                            st.success(f"✅ Registros obtenidos: {len(data)}")
                            
                            # Convertimos a DataFrame y mostramos
                            df = pd.DataFrame(data)
                            st.dataframe(df, use_container_width=True)
                            
                            # Opción de descarga
                            csv = df.to_csv(index=False).encode('utf-8')
                            st.download_button(
                                label="📥 Descargar Reporte en CSV",
                                data=csv,
                                file_name=f"{nombre_sp_limpio}_{datetime.now().strftime('%H%M%S')}.csv",
                                mime="text/csv"
                            )
                        else:
                            st.info("El SP se ejecutó pero no devolvió datos (posiblemente no hay registros).")
                    
                    elif res.status_code == 400:
                        st.error("❌ Error 400: Parámetros inválidos o número de parámetros incorrecto.")
                        st.json(res.json()) # Ver detalle del error del servidor
                        
                    elif res.status_code == 401:
                        st.error("🔒 Token expirado o inválido. Genera uno nuevo en la pestaña 1.")
                    else:
                        st.error(f"Error {res.status_code}: {res.text}")
                        
                except Exception as e:
                    st.error(f"Error al conectar con la API: {e}")

# --- Footer ---
st.markdown("---")
st.caption("ERPagro Manager | Ambiente de Pruebas | 2026")