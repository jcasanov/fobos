-- LIBRERIAS GENERALES DEL SISTEMA
GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"


FUNCTION fl_activar_base_datos(base)
DEFINE base		CHAR(20)
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*

CLOSE DATABASE 
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	CALL fgl_winmessage(vg_producto, 'No se pudo abrir base de datos: ' || vg_base, 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'Base de datos ' || base CLIPPED || ' no existe en gent051', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_lee_modulo(modulo)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE r		RECORD LIKE gent050.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent050 WHERE g50_modulo = modulo
RETURN r.*

END FUNCTION



FUNCTION fl_mostrar_mensaje(titulo, mensaje, icono)
DEFINE titulo		CHAR(30)
DEFINE mensaje		CHAR(4096)
DEFINE icono 		CHAR(30)

--#IF fgl_getenv('FGLGUI') = 1 THEN
--#	CALL fgl_winmessage(titulo, mensaje, icono)
--#ELSE
	DISPLAY mensaje
--#END IF

END FUNCTION



FUNCTION fl_lee_compania(cod_cia)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE r		RECORD LIKE gent001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent001 WHERE g01_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_localidad(cod_cia, cod_local)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE r		RECORD LIKE gent002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent002 	
	WHERE g02_compania = cod_cia AND g02_localidad = cod_local
RETURN r.*

END FUNCTION



FUNCTION fl_lee_area_negocio(cod_cia, area_neg)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE area_neg		LIKE gent003.g03_areaneg
DEFINE r		RECORD LIKE gent003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent003
	WHERE g03_compania = cod_cia AND g03_areaneg = area_neg
RETURN r.*

END FUNCTION



FUNCTION fl_lee_grupo_usuario(cod_grupo)
DEFINE cod_grupo	LIKE gent004.g04_grupo
DEFINE r		RECORD LIKE gent004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent004 WHERE g04_grupo = cod_grupo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_usuario(usuario)
DEFINE usuario		LIKE gent005.g05_usuario 
DEFINE r		RECORD LIKE gent005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent005 WHERE g05_usuario = usuario
RETURN r.*

END FUNCTION



FUNCTION fl_lee_impresora(impresora)
DEFINE impresora	LIKE gent006.g06_impresora
DEFINE r		RECORD LIKE gent006.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent006 WHERE g06_impresora = impresora
RETURN r.*

END FUNCTION



FUNCTION fl_lee_banco_general(banco)
DEFINE banco		LIKE gent008.g08_banco
DEFINE r		RECORD LIKE gent008.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent008 WHERE g08_banco = banco
RETURN r.*

END FUNCTION



FUNCTION fl_lee_banco_compania(cod_cia, banco, num_cta)
DEFINE cod_cia		LIKE gent009.g09_compania
DEFINE num_cta		LIKE gent009.g09_numero_cta
DEFINE banco		LIKE gent009.g09_banco
DEFINE r		RECORD LIKE gent009.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent009 
	WHERE g09_compania = cod_cia AND g09_banco = banco AND
	      g09_numero_cta = num_cta
RETURN r.*

END FUNCTION



FUNCTION fl_lee_chequera_cuenta(cod_cia, banco, num_cta)
DEFINE cod_cia		LIKE gent100.g100_compania
DEFINE num_cta		LIKE gent100.g100_numero_cta
DEFINE banco		LIKE gent100.g100_banco
DEFINE r		RECORD LIKE gent100.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent100 
	WHERE g100_compania = cod_cia AND g100_banco = banco AND
	      g100_numero_cta = num_cta
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tarjeta_credito(tarjeta)
DEFINE tarjeta		LIKE gent010.g10_tarjeta
DEFINE r		RECORD LIKE gent010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent010 WHERE g10_tarjeta = tarjeta
RETURN r.*

END FUNCTION



FUNCTION fl_lee_rubro_liquidacion(codrubro)
DEFINE codrubro		LIKE gent017.g17_codrubro
DEFINE r		RECORD LIKE gent017.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent017 
	WHERE g17_codrubro = codrubro
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_cobranzas(cod_cia)
DEFINE cod_cia		LIKE cxct000.z00_compania
DEFINE r		RECORD LIKE cxct000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct000 
	WHERE z00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_comisiones(cod_cia)
DEFINE cod_cia		LIKE cmst000.c00_compania
DEFINE r		RECORD LIKE cmst000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cmst000 WHERE c00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cliente_general(cod_cliente)
DEFINE cod_cliente	LIKE cxct001.z01_codcli
DEFINE r		RECORD LIKE cxct001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct001 WHERE z01_codcli = cod_cliente
RETURN r.*

END FUNCTION


FUNCTION fl_lee_cliente_localidad(cod_cia, cod_loc, cod_cliente)
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc		LIKE cxct002.z02_localidad
DEFINE cod_cliente	LIKE cxct002.z02_codcli
DEFINE r		RECORD LIKE cxct002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct002 WHERE z02_compania = cod_cia
AND z02_localidad = cod_loc
AND z02_codcli = cod_cliente
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cliente_areaneg(cod_cia, cod_loc, cod_area, cod_cliente)
DEFINE cod_cia		LIKE cxct003.z03_compania
DEFINE cod_loc		LIKE cxct003.z03_localidad
DEFINE cod_area		LIKE cxct003.z03_areaneg
DEFINE cod_cliente	LIKE cxct003.z03_codcli
DEFINE r		RECORD LIKE cxct003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct003 WHERE z03_compania = cod_cia
AND z03_localidad = cod_loc
AND z03_areaneg   = cod_area
AND z03_codcli    = cod_cliente
RETURN r.*

END FUNCTION



FUNCTION fl_lee_entidad(entidad)
DEFINE entidad		LIKE gent011.g11_tiporeg
DEFINE r		RECORD LIKE gent011.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent011 WHERE g11_tiporeg = entidad
RETURN r.*

END FUNCTION



FUNCTION fl_lee_subtipo_entidad(entidad, subtipo)
DEFINE entidad		LIKE gent012.g12_tiporeg
DEFINE subtipo		LIKE gent012.g12_subtipo
DEFINE r		RECORD LIKE gent012.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent012 
	WHERE g12_tiporeg = entidad AND g12_subtipo = subtipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_moneda(moneda)
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r		RECORD LIKE gent013.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent013 WHERE g13_moneda = moneda
RETURN r.*

END FUNCTION



FUNCTION fl_lee_factor_moneda(mon_ori, mon_des)
DEFINE mon_ori, mon_des	LIKE gent014.g14_moneda_ori
DEFINE r		RECORD LIKE gent014.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent014 WHERE g14_serial = 
	(SELECT MAX(g14_serial) FROM gent014
		WHERE g14_moneda_ori = mon_ori AND g14_moneda_des = mon_des)
RETURN r.*

END FUNCTION



FUNCTION fl_lee_partida(partida)
DEFINE partida		LIKE gent016.g16_partida
DEFINE r		RECORD LIKE gent016.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent016 WHERE g16_partida = partida
RETURN r.*

END FUNCTION



FUNCTION fl_lee_grupo_linea(cod_cia, grupo_linea)
DEFINE cod_cia		LIKE gent020.g20_compania
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE r		RECORD LIKE gent020.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent020 
	WHERE g20_compania = cod_cia AND g20_grupo_linea = grupo_linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cod_transaccion(cod_tran)
DEFINE cod_tran		LIKE gent021.g21_cod_tran
DEFINE r		RECORD LIKE gent021.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent021 WHERE g21_cod_tran = cod_tran
RETURN r.*

END FUNCTION



FUNCTION fl_lee_subtipo_transaccion(subtipo)
DEFINE subtipo		LIKE gent022.g22_cod_subtipo
DEFINE r		RECORD LIKE gent022.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent022 WHERE g22_cod_subtipo = subtipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_pais(pais)
DEFINE pais		LIKE gent030.g30_pais
DEFINE r		RECORD LIKE gent030.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent030 WHERE g30_pais = pais
RETURN r.*

END FUNCTION



FUNCTION fl_lee_ciudad(ciudad)
DEFINE ciudad		LIKE gent031.g31_ciudad
DEFINE r		RECORD LIKE gent031.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent031 WHERE g31_ciudad = ciudad
RETURN r.*

END FUNCTION



FUNCTION fl_lee_zona_venta(cod_cia, zona)
DEFINE cod_cia		LIKE gent032.g32_compania
DEFINE zona		LIKE gent032.g32_zona_venta
DEFINE r		RECORD LIKE gent032.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent032 
	WHERE g32_compania = cod_cia AND g32_zona_venta = zona
RETURN r.*

END FUNCTION



FUNCTION fl_lee_zona_cobro(zona)
DEFINE zona		LIKE cxct006.z06_zona_cobro
DEFINE r		RECORD LIKE cxct006.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct006 
	WHERE z06_zona_cobro = zona
RETURN r.*

END FUNCTION



FUNCTION fl_lee_documento_deudor_cxc(cod_cia, cod_loc, codcli, tipo_doc, 
		num_doc, dividendo)
DEFINE cod_cia		LIKE cxct020.z20_compania
DEFINE cod_loc		LIKE cxct020.z20_localidad
DEFINE codcli		LIKE cxct020.z20_codcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE r		RECORD LIKE cxct020.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct020 
	WHERE z20_compania  = cod_cia  AND 
	      z20_localidad = cod_loc  AND 
	      z20_codcli    = codcli   AND 
	      z20_tipo_doc  = tipo_doc AND 
	      z20_num_doc   = num_doc  AND 
	      z20_dividendo = dividendo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_documento_favor_cxc(cod_cia, cod_loc, codcli, tipo_doc, num_doc)
DEFINE cod_cia		LIKE cxct021.z21_compania
DEFINE cod_loc		LIKE cxct021.z21_localidad
DEFINE codcli		LIKE cxct021.z21_codcli
DEFINE tipo_doc		LIKE cxct021.z21_tipo_doc
DEFINE num_doc		LIKE cxct021.z21_num_doc
DEFINE r		RECORD LIKE cxct021.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct021 
	WHERE z21_compania  = cod_cia  AND 
	      z21_localidad = cod_loc  AND 
	      z21_codcli    = codcli   AND 
	      z21_tipo_doc  = tipo_doc AND 
	      z21_num_doc   = num_doc 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_solicitud_cobro_cxc(cod_cia, cod_loc, numsol)
DEFINE cod_cia		LIKE cxct024.z24_compania
DEFINE cod_loc		LIKE cxct024.z24_localidad
DEFINE numsol		LIKE cxct024.z24_numero_sol
DEFINE r		RECORD LIKE cxct024.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct024 
	WHERE z24_compania   = cod_cia
	  AND z24_localidad  = cod_loc
	  AND z24_numero_sol = numsol
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cobrador_cxc(cod_cia, codigo)
DEFINE cod_cia		LIKE cxct005.z05_compania
DEFINE codigo		LIKE cxct005.z05_codigo
DEFINE r		RECORD LIKE cxct005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct005 
	WHERE z05_compania = cod_cia
	  AND z05_codigo   = codigo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_transaccion_cxc(cod_cia, cod_loc, codcli, tipo_trn, num_trn)
DEFINE cod_cia		LIKE cxct022.z22_compania
DEFINE cod_loc		LIKE cxct022.z22_localidad
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE r		RECORD LIKE cxct022.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct022 
	WHERE z22_compania  = cod_cia  AND 
	      z22_localidad = cod_loc  AND 
	      z22_codcli    = codcli   AND 
	      z22_tipo_trn  = tipo_trn AND 
	      z22_num_trn   = num_trn 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cheque_fecha_cxc(cod_cia, cod_loc, codcli, banco, num_cta,
				 num_cheque)
DEFINE cod_cia		LIKE cxct026.z26_compania
DEFINE cod_loc		LIKE cxct026.z26_localidad
DEFINE codcli		LIKE cxct026.z26_codcli
DEFINE banco		LIKE cxct026.z26_banco
DEFINE num_cta		LIKE cxct026.z26_num_cta
DEFINE num_cheque	LIKE cxct026.z26_num_cheque
DEFINE r		RECORD LIKE cxct026.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct026 
	WHERE z26_compania   = cod_cia  AND 
	      z26_localidad  = cod_loc  AND 
	      z26_codcli     = codcli   AND 
	      z26_banco      = banco    AND 
	      z26_num_cta    = num_cta  AND 
	      z26_num_cheque = num_cheque
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cheque_protestado_cxc(cod_cia, cod_loc, banco, num_cta, num_cheque, secuencia)
DEFINE cod_cia		LIKE cajt012.j12_compania
DEFINE cod_loc		LIKE cajt012.j12_localidad
DEFINE banco		LIKE cajt012.j12_banco
DEFINE num_cta		LIKE cajt012.j12_num_cta
DEFINE num_cheque	LIKE cajt012.j12_num_cheque
DEFINE secuencia	LIKE cajt012.j12_secuencia
DEFINE r		RECORD LIKE cajt012.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt012 
	WHERE j12_compania   = cod_cia    AND 
	      j12_localidad  = cod_loc    AND 
	      j12_banco      = banco      AND 
	      j12_num_cta    = num_cta    AND 
	      j12_num_cheque = num_cheque AND
	      j12_secuencia  = secuencia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_resumen_saldo_cliente(codcia, codloc, areaneg, codcli, moneda)
DEFINE codcia		LIKE cxct030.z30_compania 
DEFINE codloc		LIKE cxct030.z30_localidad 
DEFINE areaneg		LIKE cxct030.z30_areaneg 
DEFINE codcli		LIKE cxct030.z30_codcli 
DEFINE moneda		LIKE cxct030.z30_moneda 
DEFINE r 		RECORD LIKE cxct030.* 

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct030 
	WHERE z30_compania  = codcia AND
	      z30_localidad = codloc AND
	      z30_areaneg   = areaneg AND
	      z30_codcli    = codcli AND
	      z30_moneda    = moneda
RETURN r.* 

END FUNCTION



FUNCTION fl_lee_resumen_saldo_proveedor(codcia, codloc, codprov, moneda)
DEFINE codcia		LIKE cxpt030.p30_compania 
DEFINE codloc		LIKE cxpt030.p30_localidad 
DEFINE codprov		LIKE cxpt030.p30_codprov 
DEFINE moneda		LIKE cxpt030.p30_moneda 
DEFINE r 		RECORD LIKE cxpt030.* 

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt030 
	WHERE p30_compania  = codcia AND
	      p30_localidad = codloc AND
	      p30_codprov   = codprov AND
	      p30_moneda    = moneda
RETURN r.* 

END FUNCTION



FUNCTION fl_lee_centro_costo(cod_cia, ccosto)
DEFINE cod_cia		LIKE gent033.g33_compania
DEFINE ccosto		LIKE gent033.g33_cod_ccosto
DEFINE r		RECORD LIKE gent033.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent033 
	WHERE g33_compania = cod_cia AND g33_cod_ccosto = ccosto
RETURN r.*

END FUNCTION



FUNCTION fl_lee_departamento(cod_cia, depto)
DEFINE cod_cia		LIKE gent034.g34_compania
DEFINE depto		LIKE gent034.g34_cod_depto
DEFINE r		RECORD LIKE gent034.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent034 
	WHERE g34_compania = cod_cia AND g34_cod_depto = depto
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cod_seccion(cod_cia, seccion)
DEFINE cod_cia		LIKE talt002.t02_compania
DEFINE seccion		LIKE talt002.t02_seccion
DEFINE r		RECORD LIKE talt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt002 
	WHERE t02_compania = cod_cia AND t02_seccion = seccion
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_vehiculo(cod_cia, tipo)
DEFINE cod_cia		LIKE talt004.t04_compania
DEFINE tipo		LIKE talt004.t04_modelo
DEFINE r		RECORD LIKE talt004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt004 
	WHERE t04_compania = cod_cia AND t04_modelo = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_orden_taller(cod_cia, tipo)
DEFINE cod_cia		LIKE talt005.t05_compania
DEFINE tipo		LIKE talt005.t05_tipord
DEFINE r		RECORD LIKE talt005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt005 
	WHERE t05_compania = cod_cia AND t05_tipord = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_subtipo_orden_taller(cod_cia, tipo, subtipo)
DEFINE cod_cia		LIKE talt006.t06_compania
DEFINE tipo		LIKE talt006.t06_tipord
DEFINE subtipo		LIKE talt006.t06_subtipo
DEFINE r		RECORD LIKE talt006.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt006 
	WHERE t06_compania = cod_cia AND t06_tipord = tipo AND
	      t06_subtipo  = subtipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_mecanico(cod_cia, mecanico)
DEFINE cod_cia		LIKE talt003.t03_compania
DEFINE mecanico		LIKE talt003.t03_mecanico
DEFINE r		RECORD LIKE talt003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt003 
	WHERE t03_compania = cod_cia AND t03_mecanico = mecanico
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tarea(cod_cia, modelo, codtarea)
DEFINE cod_cia		LIKE talt007.t07_compania
DEFINE modelo		LIKE talt007.t07_modelo
DEFINE codtarea		LIKE talt007.t07_codtarea
DEFINE r		RECORD LIKE talt007.*
DEFINE r_t35		RECORD LIKE talt035.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt007 
	WHERE t07_compania = cod_cia AND t07_modelo = modelo AND
	      t07_codtarea = codtarea

IF STATUS = NOTFOUND THEN
	INITIALIZE r_t35.* TO NULL
	SELECT * INTO r_t35.* FROM talt035 
		WHERE t35_compania = cod_cia AND t35_codtarea = codtarea
	IF STATUS = NOTFOUND THEN
		RETURN r.*
	END IF

	LET r.t07_compania     = r_t35.t35_compania
	LET r.t07_modelo       = modelo   
	LET r.t07_codtarea     = r_t35.t35_codtarea 
	LET r.t07_nombre       = r_t35.t35_nombre 
	LET r.t07_estado       = r_t35.t35_estado 
	LET r.t07_tipo         = r_t35.t35_tipo 
	LET r.t07_pto_default  = r_t35.t35_pto_default 
	LET r.t07_val_defa_mb  = r_t35.t35_val_defa_mb 
	LET r.t07_val_defa_ma  = r_t35.t35_val_defa_ma 
	LET r.t07_usuario      = r_t35.t35_usuario 
	LET r.t07_fecing       = r_t35.t35_fecing
END IF

RETURN r.*

END FUNCTION



FUNCTION fl_lee_vehiculo_cliente_taller(cod_cia, codcli, modelo, chasis)
DEFINE cod_cia		LIKE talt010.t10_compania
DEFINE codcli		LIKE talt010.t10_codcli
DEFINE modelo		LIKE talt010.t10_modelo
DEFINE chasis		LIKE talt010.t10_chasis
DEFINE r		RECORD LIKE talt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt010 
	WHERE t10_compania = cod_cia AND t10_codcli = codcli AND
	      t10_modelo   = modelo  AND t10_chasis = chasis
RETURN r.*

END FUNCTION



FUNCTION fl_lee_orden_trabajo(cod_cia, cod_loc, orden)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE orden		LIKE talt023.t23_orden
DEFINE r		RECORD LIKE talt023.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt023 
	WHERE t23_compania = cod_cia AND t23_localidad = cod_loc AND
	      t23_orden  = orden
RETURN r.*

END FUNCTION



FUNCTION fl_lee_factura_taller(cod_cia, cod_loc, factura)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE factura		LIKE talt023.t23_num_factura
DEFINE r		RECORD LIKE talt023.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt023 
	WHERE t23_compania = cod_cia AND t23_localidad = cod_loc AND
	      t23_num_factura  = factura
RETURN r.*

END FUNCTION



FUNCTION fl_lee_devolucion_factura_taller(cod_cia, cod_loc, num_dev)
DEFINE cod_cia		LIKE talt028.t28_compania
DEFINE cod_loc		LIKE talt028.t28_localidad
DEFINE num_dev		LIKE talt028.t28_num_dev
DEFINE r		RECORD LIKE talt028.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt028 
	WHERE t28_compania = cod_cia AND t28_localidad = cod_loc AND
	      t28_num_dev  = num_dev
RETURN r.*

END FUNCTION



FUNCTION fl_lee_presupuesto_taller(cod_cia, cod_loc, numpre)
DEFINE cod_cia		LIKE talt020.t20_compania
DEFINE cod_loc		LIKE talt020.t20_localidad
DEFINE numpre		LIKE talt020.t20_numpre
DEFINE r		RECORD LIKE talt020.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt020 
	WHERE t20_compania = cod_cia AND t20_localidad = cod_loc AND
	      t20_numpre   = numpre
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tarea_grado_dificultad(cod_cia, modelo, tarea, grado)
DEFINE cod_cia		LIKE talt009.t09_compania
DEFINE modelo		LIKE talt009.t09_modelo
DEFINE tarea		LIKE talt009.t09_codtarea
DEFINE grado		LIKE talt009.t09_dificultad
DEFINE r		RECORD LIKE talt009.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt009 
	WHERE t09_compania = cod_cia AND t09_modelo = modelo AND
	      t09_codtarea = tarea  AND t09_dificultad = grado
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cabecera_credito_taller(cod_cia, cod_loc, orden)
DEFINE cod_cia		LIKE talt025.t25_compania
DEFINE cod_loc		LIKE talt025.t25_localidad
DEFINE orden		LIKE talt025.t25_orden
DEFINE r		RECORD LIKE talt025.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt025 
	WHERE t25_compania = cod_cia AND t25_localidad = cod_loc AND
	      t25_orden  = orden
RETURN r.*

END FUNCTION



FUNCTION fl_totaliza_orden_taller(r_ord)
DEFINE r_ord		RECORD LIKE talt023.*

LET r_ord.t23_vde_mo_tal = r_ord.t23_val_mo_tal * r_ord.t23_por_mo_tal / 100
LET r_ord.t23_vde_rp_tal = r_ord.t23_val_rp_tal * r_ord.t23_por_rp_tal / 100
LET r_ord.t23_vde_rp_alm = r_ord.t23_val_rp_alm * r_ord.t23_por_rp_alm / 100
CALL fl_retorna_precision_valor(r_ord.t23_moneda, r_ord.t23_vde_mo_tal)
	RETURNING r_ord.t23_vde_mo_tal
CALL fl_retorna_precision_valor(r_ord.t23_moneda, r_ord.t23_vde_rp_tal)
	RETURNING r_ord.t23_vde_rp_tal
CALL fl_retorna_precision_valor(r_ord.t23_moneda, r_ord.t23_vde_rp_alm)
	RETURNING r_ord.t23_vde_rp_alm
LET r_ord.t23_tot_dscto = r_ord.t23_vde_mo_tal + r_ord.t23_vde_rp_tal +
			  r_ord.t23_vde_rp_alm
LET r_ord.t23_tot_bruto = r_ord.t23_val_mo_tal + r_ord.t23_val_mo_ext + 
			  r_ord.t23_val_mo_cti +
                          r_ord.t23_val_rp_tal + r_ord.t23_val_rp_ext + 
			  r_ord.t23_val_rp_cti + r_ord.t23_val_rp_alm +
			  r_ord.t23_val_otros1 + r_ord.t23_val_otros2
LET r_ord.t23_val_impto = (r_ord.t23_tot_bruto - r_ord.t23_tot_dscto) *
			  r_ord.t23_porc_impto / 100
CALL fl_retorna_precision_valor(r_ord.t23_moneda, r_ord.t23_val_impto)
	RETURNING r_ord.t23_val_impto
LET r_ord.t23_tot_neto = r_ord.t23_tot_bruto - r_ord.t23_tot_dscto +
			 r_ord.t23_val_impto
RETURN r_ord.*

END FUNCTION



FUNCTION fl_actualiza_estadisticas_taller(cod_cia, cod_loc, orden, flag)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE orden		LIKE talt023.t23_orden
DEFINE flag		CHAR(1)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_tot		RECORD LIKE talt005.*
DEFINE fecha		DATE
DEFINE fec_anula	DATE
DEFINE num		SMALLINT
DEFINE ano_aux		SMALLINT
DEFINE mes_aux		SMALLINT

SET LOCK MODE TO WAIT 10
CALL fl_lee_orden_trabajo(cod_cia, cod_loc, orden)
	RETURNING r_ord.*
IF r_ord.t23_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Orden: ' || orden || ' no existe', 'exclamation')
	RETURN
END IF
CALL fl_lee_tipo_vehiculo(cod_cia, r_ord.t23_modelo)
	RETURNING r_mod.*
CALL fl_lee_tipo_orden_taller(cod_cia, r_ord.t23_tipo_ot)
	RETURNING r_tot.*
LET fecha = DATE(r_ord.t23_fec_factura)
IF r_tot.t05_factura = 'N' THEN
	LET fecha = DATE(r_ord.t23_fec_cierre)
END IF
LET num = 1
IF flag = 'R' THEN
	IF r_ord.t23_estado = 'D' THEN
		SELECT t28_fec_anula INTO fec_anula FROM talt028
			WHERE t28_compania  = cod_cia AND 
		      	      t28_localidad = cod_loc AND
		              t28_factura   = r_ord.t23_num_factura
		IF status <> NOTFOUND THEN
			LET fecha = fec_anula
		END IF
	END IF
        -- RESTA PORQUE ES DEVOLUCION
	LET num = num * -1
    	LET r_ord.t23_val_mo_tal = r_ord.t23_val_mo_tal * -1
    	LET r_ord.t23_val_mo_ext = r_ord.t23_val_mo_ext * -1
    	LET r_ord.t23_val_mo_cti = r_ord.t23_val_mo_cti * -1
    	LET r_ord.t23_val_rp_tal = r_ord.t23_val_rp_tal * -1
    	LET r_ord.t23_val_rp_ext = r_ord.t23_val_rp_ext * -1
    	LET r_ord.t23_val_rp_cti = r_ord.t23_val_rp_cti * -1
    	LET r_ord.t23_val_rp_alm = r_ord.t23_val_rp_alm * -1
    	LET r_ord.t23_val_otros1 = r_ord.t23_val_otros1 * -1
    	LET r_ord.t23_val_otros2 = r_ord.t23_val_otros2 * -1
    	LET r_ord.t23_vde_mo_tal = r_ord.t23_vde_mo_tal * -1
    	LET r_ord.t23_vde_rp_tal = r_ord.t23_vde_rp_tal * -1
    	LET r_ord.t23_vde_rp_alm = r_ord.t23_vde_rp_alm * -1
    	LET r_ord.t23_val_impto  = r_ord.t23_val_impto  * -1
    	LET r_ord.t23_tot_neto   = r_ord.t23_tot_neto * -1
END IF	
UPDATE talt040 SET 
    t40_num_veh    = t40_num_veh    + num,
    t40_val_mo_tal = t40_val_mo_tal + r_ord.t23_val_mo_tal,
    t40_val_mo_ext = t40_val_mo_ext + r_ord.t23_val_mo_ext,
    t40_val_mo_cti = t40_val_mo_cti + r_ord.t23_val_mo_cti,
    t40_val_rp_tal = t40_val_rp_tal + r_ord.t23_val_rp_tal,
    t40_val_rp_ext = t40_val_rp_ext + r_ord.t23_val_rp_ext,
    t40_val_rp_cti = t40_val_rp_cti + r_ord.t23_val_rp_cti,
    t40_val_rp_alm = t40_val_rp_alm + r_ord.t23_val_rp_alm,
    t40_val_otros1 = t40_val_otros1 + r_ord.t23_val_otros1,
    t40_val_otros2 = t40_val_otros2 + r_ord.t23_val_otros2,
    t40_vde_mo_tal = t40_vde_mo_tal + r_ord.t23_vde_mo_tal,
    t40_vde_rp_tal = t40_vde_rp_tal + r_ord.t23_vde_rp_tal,
    t40_vde_rp_alm = t40_vde_rp_alm + r_ord.t23_vde_rp_alm,
    t40_val_impto  = t40_val_impto  + r_ord.t23_val_impto,
    t40_valor_neto = t40_valor_neto + r_ord.t23_tot_neto
	WHERE t40_compania   = cod_cia		 AND
              t40_localidad  = cod_loc		 AND
              t40_ano	     = YEAR(fecha)	 AND
              t40_mes 	     = MONTH(fecha)	 AND
              t40_tipo_orden = r_ord.t23_tipo_ot AND
              t40_modelo     = r_ord.t23_modelo	 AND
              t40_moneda     = r_ord.t23_moneda
	IF SQLCA.SQLERRD[3] = 0 THEN
		LET mes_aux = MONTH(fecha)
		LET ano_aux = YEAR(fecha)
		INSERT INTO talt040 VALUES (cod_cia, cod_loc, ano_aux,
			mes_aux, r_ord.t23_tipo_ot, r_ord.t23_modelo,
			r_ord.t23_moneda, 1, 
    			r_ord.t23_val_mo_tal,
    			r_ord.t23_val_mo_ext,
    			r_ord.t23_val_mo_cti,
    			r_ord.t23_val_rp_tal,
    			r_ord.t23_val_rp_ext,
    			r_ord.t23_val_rp_cti,
    			r_ord.t23_val_rp_alm,
    			r_ord.t23_val_otros1,
    			r_ord.t23_val_otros2,
    			r_ord.t23_vde_mo_tal,
    			r_ord.t23_vde_rp_tal,
    			r_ord.t23_vde_rp_alm,
    			r_ord.t23_val_impto,
    			r_ord.t23_tot_neto)
	END IF

END FUNCTION



FUNCTION fl_actualiza_estadisticas_mecanicos(cod_cia, cod_loc, orden, flag)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE orden		LIKE talt023.t23_orden
DEFINE flag		CHAR(1)
DEFINE r_ord		RECORD LIKE talt023.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_tot		RECORD LIKE talt005.*
DEFINE fecha		DATE
DEFINE fec_anula	DATE
DEFINE valor		DECIMAL(12,2)
DEFINE mecanico		LIKE talt003.t03_mecanico
DEFINE ano_aux		SMALLINT
DEFINE mes_aux		SMALLINT

SET LOCK MODE TO WAIT
CALL fl_lee_orden_trabajo(cod_cia, cod_loc, orden)
	RETURNING r_ord.*
IF r_ord.t23_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Orden: ' || orden || ' no existe', 'exclamation')
	RETURN
END IF
CALL fl_lee_tipo_vehiculo(cod_cia, r_ord.t23_modelo)
	RETURNING r_mod.*
CALL fl_lee_tipo_orden_taller(cod_cia, r_ord.t23_tipo_ot)
	RETURNING r_tot.*
LET fecha = DATE(r_ord.t23_fec_factura)
IF r_tot.t05_factura = 'N' THEN
	LET fecha = DATE(r_ord.t23_fec_cierre)
END IF
IF flag = 'R' THEN
	IF r_ord.t23_estado = 'D' THEN
		SELECT t28_fec_anula INTO fec_anula FROM talt028
			WHERE t28_compania  = cod_cia AND 
		      	      t28_localidad = cod_loc AND
		              t28_factura   = r_ord.t23_num_factura
		IF status <> NOTFOUND THEN
			LET fecha = fec_anula
		END IF
	END IF
END IF
DECLARE q_hman CURSOR FOR 
	SELECT t24_mecanico, SUM(t24_valor_tarea)
		FROM talt024
		WHERE t24_compania  = cod_cia AND 
		      t24_localidad = cod_loc AND 
		      t24_orden     = orden
		GROUP BY 1
FOREACH q_hman INTO mecanico, valor
	IF flag = 'R' THEN    -- RESTA PORQUE ES DEVOLUCION
    		LET valor = valor * -1
	END IF	
	UPDATE talt041 SET t41_mano_obra = t41_mano_obra + valor
		WHERE t41_compania   = cod_cia		 AND
              	      t41_localidad  = cod_loc		 AND
              	      t41_ano	     = YEAR(fecha)	 AND
              	      t41_mes 	     = MONTH(fecha)	 AND
              	      t41_mecanico   = mecanico       	 AND
              	      t41_modelo     = r_ord.t23_modelo	 AND
              	      t41_moneda     = r_ord.t23_moneda
	IF SQLCA.SQLERRD[3] = 0 THEN
		LET mes_aux = MONTH(fecha)
		LET ano_aux = YEAR(fecha)
		INSERT INTO talt041 VALUES (cod_cia, cod_loc, ano_aux,
			mes_aux, mecanico, r_ord.t23_modelo, 
			r_ord.t23_moneda, valor, 0)
	END IF
END FOREACH

END FUNCTION



FUNCTION fl_lee_vendedor_veh(cod_cia, cod_vend)
DEFINE cod_cia		LIKE veht001.v01_compania
DEFINE cod_vend		LIKE veht001.v01_vendedor
DEFINE r		RECORD LIKE veht001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht001 
	WHERE v01_compania = cod_cia AND v01_vendedor = cod_vend
RETURN r.*

END FUNCTION



FUNCTION fl_lee_bodega_veh(cod_cia, bodega)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE bodega		LIKE veht002.v02_bodega
DEFINE r		RECORD LIKE veht002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht002 
	WHERE v02_compania = cod_cia AND v02_bodega = bodega
RETURN r.*

END FUNCTION



FUNCTION fl_lee_linea_veh(cod_cia, linea)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE linea		LIKE veht003.v03_linea
DEFINE r		RECORD LIKE veht003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht003 
	WHERE v03_compania = cod_cia AND v03_linea = linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cod_vehiculo_veh(cod_cia, cod_loc, codigo_veh)
DEFINE cod_cia		LIKE veht022.v22_compania
DEFINE cod_loc		LIKE veht022.v22_localidad
DEFINE codigo_veh	LIKE veht022.v22_codigo_veh
DEFINE r		RECORD LIKE veht022.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht022 
	WHERE v22_compania = cod_cia AND v22_localidad = cod_loc AND 
	      v22_codigo_veh = codigo_veh
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_vehiculo_veh(cod_cia, tipo_veh)
DEFINE cod_cia		LIKE veht004.v04_compania
DEFINE tipo_veh		LIKE veht004.v04_tipo_veh
DEFINE r		RECORD LIKE veht004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht004 
	WHERE v04_compania = cod_cia AND v04_tipo_veh = tipo_veh
RETURN r.*

END FUNCTION



FUNCTION fl_lee_color_veh(cod_cia, cod_color)
DEFINE cod_cia		LIKE veht005.v05_compania
DEFINE cod_color	LIKE veht005.v05_cod_color
DEFINE r		RECORD LIKE veht005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht005 
	WHERE v05_compania = cod_cia AND v05_cod_color = cod_color
RETURN r.*

END FUNCTION



FUNCTION fl_lee_modelo_veh(cod_cia, modelo)
DEFINE cod_cia		LIKE veht020.v20_compania
DEFINE modelo		LIKE veht020.v20_modelo
DEFINE r		RECORD LIKE veht020.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht020 
	WHERE v20_compania = cod_cia AND v20_modelo = modelo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cabecera_transaccion_veh(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE veht030.v30_compania
DEFINE cod_loc		LIKE veht030.v30_localidad
DEFINE cod_tran		LIKE veht030.v30_cod_tran
DEFINE num_tran		LIKE veht030.v30_num_tran
DEFINE r		RECORD LIKE veht030.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht030 
	WHERE v30_compania = cod_cia AND v30_localidad = cod_loc AND 
	      v30_cod_tran = cod_tran AND v30_num_tran = num_tran
RETURN r.*

END FUNCTION



FUNCTION fl_ver_transaccion_veh(codcia, codloc, cod_tran, num_tran)

DEFINE codcia		LIKE veht030.v30_compania
DEFINE codloc		LIKE veht030.v30_localidad
DEFINE cod_tran		LIKE veht030.v30_cod_tran
DEFINE num_tran		LIKE veht030.v30_num_tran
DEFINE comando		VARCHAR(300)

INITIALIZE comando TO NULL
CASE cod_tran
        WHEN 'FA'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp304 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran
        WHEN 'IM'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp304 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran                     
        WHEN 'CL'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp214 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran
        WHEN 'TR'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp204 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran
        WHEN 'DF'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp207 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran
        WHEN 'DC'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp218 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran
        WHEN 'A+'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp206 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran
        WHEN 'A-'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp206 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', cod_tran, ' ', num_tran                     
        WHEN 'AC'
                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'VEHICULOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun vehp205 ', vg_base, ' ',
                              'VE', codcia, ' ', codloc,
                              ' ', num_tran         
END CASE

IF comando IS NOT NULL THEN
	RUN comando
END IF

END FUNCTION



FUNCTION fl_lee_pedido_veh(cod_cia, cod_loc, pedido)
DEFINE cod_cia		LIKE veht034.v34_compania
DEFINE cod_loc		LIKE veht034.v34_localidad
DEFINE pedido		LIKE veht034.v34_pedido
DEFINE r		RECORD LIKE veht034.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht034 
	WHERE v34_compania = cod_cia AND v34_localidad = cod_loc AND
	      v34_pedido   = pedido
RETURN r.*

END FUNCTION



FUNCTION fl_lee_liquidacion_veh(cod_cia, cod_loc, numliq)
DEFINE cod_cia		LIKE veht036.v36_compania
DEFINE cod_loc		LIKE veht036.v36_localidad
DEFINE numliq		LIKE veht036.v36_numliq
DEFINE r		RECORD LIKE veht036.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht036 
	WHERE v36_compania = cod_cia AND v36_localidad = cod_loc AND
	      v36_numliq   = numliq
RETURN r.*

END FUNCTION



FUNCTION fl_lee_clasificadores_item_rep(cod_cia, cod_item)
DEFINE cod_cia		LIKE rept103.r103_compania
DEFINE cod_item		LIKE rept103.r103_item
DEFINE r			RECORD LIKE rept103.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept103 	
 WHERE r103_compania = cod_cia AND r103_item = cod_item
RETURN r.*

END FUNCTION



FUNCTION fl_lee_liquidacion_rep(cod_cia, cod_loc, numliq)
DEFINE cod_cia		LIKE rept028.r28_compania
DEFINE cod_loc		LIKE rept028.r28_localidad
DEFINE numliq		LIKE rept028.r28_numliq
DEFINE r		RECORD LIKE rept028.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept028   
	WHERE r28_compania = cod_cia AND r28_localidad = cod_loc AND
	      r28_numliq   = numliq
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_vehiculos(cod_cia)
DEFINE cod_cia		LIKE veht000.v00_compania
DEFINE r		RECORD LIKE veht000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht000 
	WHERE v00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_orden_chequeo_veh(cod_cia, cod_loc, orden)
DEFINE cod_cia		LIKE veht038.v38_compania
DEFINE cod_loc		LIKE veht038.v38_localidad
DEFINE orden		LIKE veht038.v38_orden_cheq
DEFINE r		RECORD LIKE veht038.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht038 
	WHERE v38_compania = cod_cia AND v38_localidad = cod_loc AND 
	      v38_orden_cheq = orden
RETURN r.*

END FUNCTION



FUNCTION fl_lee_plan_financiamiento(cod_cia, cod_plan)
DEFINE cod_cia		LIKE veht006.v06_compania
DEFINE cod_plan		LIKE veht006.v06_codigo_plan
DEFINE r		RECORD LIKE veht006.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht006 
	WHERE v06_compania = cod_cia AND v06_codigo_plan = cod_plan
RETURN r.*

END FUNCTION



FUNCTION fl_lee_coeficiente_veh(cod_cia, cod_plan, mes)
DEFINE cod_cia		LIKE veht007.v07_compania
DEFINE cod_plan		LIKE veht007.v07_codigo_plan
DEFINE mes		SMALLINT
DEFINE r		RECORD LIKE veht007.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht007 
	WHERE v07_compania  = cod_cia AND v07_codigo_plan = cod_plan AND
	      v07_num_meses = mes
RETURN r.*

END FUNCTION



FUNCTION fl_lee_reservacion_veh(cod_cia, cod_loc, num_res)
DEFINE cod_cia		LIKE veht033.v33_compania
DEFINE cod_loc		LIKE veht033.v33_localidad
DEFINE num_res		LIKE veht033.v33_num_reserv
DEFINE r		RECORD LIKE veht033.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht033 
	WHERE v33_compania  = cod_cia AND v33_localidad = cod_loc AND
	      v33_num_reserv = num_res
RETURN r.*

END FUNCTION



FUNCTION fl_lee_preventa_veh(cod_cia, cod_loc, preventa)
DEFINE cod_cia		LIKE veht026.v26_compania
DEFINE cod_loc		LIKE veht026.v26_localidad
DEFINE preventa		LIKE veht026.v26_numprev
DEFINE r		RECORD LIKE veht026.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM veht026 
	WHERE v26_compania = cod_cia AND v26_localidad = cod_loc AND
	      v26_numprev  = preventa
RETURN r.*

END FUNCTION



FUNCTION fl_lee_parametro_general_roles()
DEFINE r		RECORD LIKE rolt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt000 
	WHERE n00_serial = (SELECT MAX(n00_serial) FROM rolt000)
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_roles(cod_cia)
DEFINE cod_cia		LIKE rolt001.n01_compania
DEFINE r		RECORD LIKE rolt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt001 
	WHERE n01_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_trabajador_roles(cod_cia, cod_trab)
DEFINE cod_cia		LIKE rolt030.n30_compania
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r		RECORD LIKE rolt030.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt030 
	WHERE n30_compania = cod_cia AND n30_cod_trab = cod_trab
RETURN r.*

END FUNCTION



FUNCTION fl_lee_rubro_roles(cod_rubro)
DEFINE cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE r		RECORD LIKE rolt006.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt006 
	WHERE n06_cod_rubro = cod_rubro
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_valor_rubro_trabajador(cod_cia, cod_rubro, cod_trab)
DEFINE cod_cia		LIKE rolt010.n10_compania
DEFINE cod_rubro	LIKE rolt010.n10_cod_rubro
DEFINE cod_trab		LIKE rolt010.n10_cod_trab
DEFINE r		RECORD LIKE rolt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt010 
	WHERE n10_compania  = cod_cia	
	  AND n10_cod_rubro = cod_rubro
	  AND n10_cod_trab  = cod_trab
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proceso_roles(proceso)
DEFINE proceso		LIKE rolt003.n03_proceso
DEFINE r		RECORD LIKE rolt003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt003 
	WHERE n03_proceso = proceso
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cargo(cod_cia, cargo)
DEFINE cod_cia		LIKE gent035.g35_compania
DEFINE cargo		LIKE gent035.g35_cod_cargo
DEFINE r		RECORD LIKE gent035.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent035 
	WHERE g35_compania = cod_cia AND g35_cod_cargo = cargo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_dia_feriado(dia)
DEFINE dia		LIKE gent036.g36_dia
DEFINE r		RECORD LIKE gent036.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent036 WHERE g36_dia = dia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_doc(tipodoc)
DEFINE tipodoc		LIKE cxct004.z04_tipo_doc
DEFINE r		RECORD LIKE cxct004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct004 WHERE z04_tipo_doc = tipodoc
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proceso(cod_mod, cod_proc)
DEFINE cod_mod		LIKE gent050.g50_modulo
DEFINE cod_proc		LIKE gent054.g54_proceso
DEFINE r		RECORD LIKE gent054.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent054 
	WHERE g54_modulo = cod_mod AND g54_proceso = cod_proc
RETURN r.*

END FUNCTION



FUNCTION fl_lee_bodega_rep(cod_cia, bodega)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r		RECORD LIKE rept002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept002 
	WHERE r02_compania = cod_cia AND r02_codigo = bodega
RETURN r.*

END FUNCTION



FUNCTION fl_lee_linea_rep(cod_cia, linea)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE linea		LIKE rept003.r03_codigo
DEFINE r		RECORD LIKE rept003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept003 
	WHERE r03_compania = cod_cia AND r03_codigo = linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_vendedor_rep(cod_cia, cod_vend)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_vend		LIKE rept001.r01_codigo
DEFINE r		RECORD LIKE rept001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept001 
	WHERE r01_compania = cod_cia AND r01_codigo = cod_vend
RETURN r.*

END FUNCTION



FUNCTION fl_lee_comisionistas(cod_cia, cod_comi)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_comi		LIKE cmst002.c02_codigo
DEFINE r		RECORD LIKE cmst002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cmst002 
	WHERE c02_compania = cod_cia AND c02_codigo = cod_comi
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_item(tipo)
DEFINE tipo		LIKE rept006.r06_codigo
DEFINE r		RECORD LIKE rept006.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept006 
	WHERE r06_codigo = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_indice_rotacion(cod_cia, indice)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE indice		LIKE rept004.r04_rotacion
DEFINE r		RECORD LIKE rept004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept004 
	WHERE r04_compania = cod_cia AND r04_rotacion = indice
RETURN r.*

END FUNCTION



FUNCTION fl_lee_item(cod_cia, item)
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE item		LIKE rept010.r10_codigo     
DEFINE r		RECORD LIKE rept010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept010 
	WHERE r10_compania = cod_cia AND r10_codigo = item
RETURN r.*

END FUNCTION



FUNCTION fl_lee_unidad_medida(codigo)
DEFINE codigo		LIKE rept005.r05_codigo
DEFINE r		RECORD LIKE rept005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept005 
	WHERE r05_codigo = codigo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_configuracion_facturacion()
DEFINE r		RECORD LIKE gent000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent000 
	WHERE g00_serial = (SELECT MAX(g00_serial) FROM gent000)
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r		RECORD LIKE rept019.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept019 
	WHERE r19_compania = cod_cia AND r19_localidad = cod_loc AND 
	      r19_cod_tran = cod_tran AND r19_num_tran = num_tran
RETURN r.*

END FUNCTION



FUNCTION fl_ver_transaccion_rep(codcia, codloc, cod_tran, num_tran)

DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE comando		VARCHAR(300)

INITIALIZE comando TO NULL
CASE cod_tran
	WHEN 'FA'      
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp308 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'IM'        
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp308 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'NE'        
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp422 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'CL'          
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp214 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'IC'          
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp202 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'IX'          
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp202 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'RQ'          
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp215 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'TR'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp216 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'DF'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp217 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'AF'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp217 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'DC'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp218 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'DR'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp219 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'A+'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp212 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'A-'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp212 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'AC'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp213 ', vg_base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
END CASE

IF comando IS NOT NULL THEN
	RUN comando
END IF

END FUNCTION



FUNCTION fl_lee_stock_rep(cod_cia, bodega, item)
DEFINE cod_cia		LIKE rept011.r11_compania
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE item		LIKE rept011.r11_item
DEFINE r		RECORD LIKE rept011.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept011 
	WHERE r11_compania = cod_cia AND r11_bodega = bodega AND
	      r11_item     = item
RETURN r.*

END FUNCTION



{*
 * Funcion que extrae el stock total de un item en todas las bodegas
 * para facturacion de una localidad
 *
 * Parametros: compania, localidad, item, area IN ('R', 'T'),
*}
FUNCTION fl_lee_stock_total_rep(cod_cia, cod_loc, item, area)
DEFINE cod_cia		LIKE rept011.r11_compania
DEFINE cod_loc		LIKE rept002.r02_localidad
DEFINE item		LIKE rept011.r11_item
DEFINE area   		LIKE rept002.r02_area
DEFINE stock		LIKE rept011.r11_stock_act

SELECT SUM(r11_stock_act) INTO stock 
  FROM rept011, rept002 
 WHERE r02_compania  = cod_cia
   AND r02_estado    = 'A'
   AND r02_area      = area
   AND r02_factura   = 'S'
   AND r02_localidad = cod_loc
   AND r11_compania  = r02_compania
   AND r11_bodega    = r02_codigo  
   AND r11_item      = item

IF stock IS NULL THEN
	LET stock = 0
END IF

RETURN stock

END FUNCTION



{*
 * Esta funcion extrae el stock disponible en todas las bodegas de
 * todas las localidades
 *}
FUNCTION fl_lee_stock_total_localidades_rep(cod_cia, item, area)
DEFINE cod_cia		LIKE rept011.r11_compania
DEFINE item			LIKE rept011.r11_item
DEFINE area   		LIKE rept002.r02_area
DEFINE stock		LIKE rept011.r11_stock_act

DEFINE r_g02		RECORD LIKE gent002.*

DECLARE q_stock_disp_loc CURSOR WITH HOLD FOR
	SELECT * FROM gent002 
	 WHERE g02_compania  = cod_cia
	   AND g02_estado    = 'A'

LET stock = 0
FOREACH q_stock_disp_loc INTO r_g02.*
	LET stock = stock + fl_lee_stock_disponible_rep(cod_cia, 
													r_g02.g02_localidad, 
													item, area)
END FOREACH	
FREE q_stock_disp_loc

IF stock IS NULL THEN
	LET stock = 0
END IF

RETURN stock

END FUNCTION



{*
 * Esta es la funcion que se va a usar en la proforma. 
 * El objetivo es mostrar solo el stock disponible, eso es el stock - reservado 
 *}
FUNCTION fl_lee_stock_disponible_rep(cod_cia, cod_loc, item, area)
DEFINE cod_cia		LIKE rept011.r11_compania
DEFINE cod_loc		LIKE rept002.r02_localidad
DEFINE item			LIKE rept011.r11_item
DEFINE area   		LIKE rept002.r02_area
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE x_despachar	LIKE rept011.r11_stock_act
DEFINE reservado	LIKE rept011.r11_stock_act
DEFINE stock_disp	LIKE rept011.r11_stock_act
DEFINE entrega_prv	LIKE rept011.r11_stock_act
	
	CALL fl_lee_stock_total_rep(cod_cia, cod_loc, item, area) RETURNING stock

	SELECT SUM(r116_cantidad) INTO x_despachar
	  FROM rept116
	 WHERE r116_compania  = cod_cia
	   AND r116_localidad = cod_loc
	   AND r116_item      = item	

	IF x_despachar IS NULL THEN
		LET x_despachar = 0
	END IF

	SELECT SUM(r24_cant_ven) INTO reservado
	  FROM rept024, rept023
	 WHERE r24_compania  = cod_cia
	   AND r24_localidad = cod_loc
	   AND r24_item      = item
	   AND r23_compania  = r24_compania
	   AND r23_localidad = r24_localidad
	   AND r23_numprev   = r24_numprev
	   AND r23_estado    = 'P'

	IF reservado IS NULL THEN
		LET reservado = 0
	END IF

    SELECT SUM(r20_cant_ent) INTO entrega_prv
      FROM rept118, rept020
     WHERE r118_compania  = cod_cia
       AND r118_localidad = cod_loc
       AND r118_cod_fact  IS NULL
       AND r118_item_desp = item
       AND r20_compania   = r118_compania
       AND r20_localidad  = r118_localidad
       AND r20_cod_tran   = r118_cod_desp
       AND r20_num_tran   = r118_num_desp
       AND r20_item       = r118_item_desp

	IF entrega_prv IS NULL THEN
		LET entrega_prv = 0
	END IF

	LET stock_disp = stock - x_despachar - (reservado - entrega_prv)

	RETURN stock_disp
END FUNCTION



{*
 * Esta funcion se usa para determinar el stock inicial de un item a una
 * fecha dada es una bodega especifica.
 *}
FUNCTION fl_lee_stock_inicial_item_bd(cod_cia, cod_loc, bodega, item, fecha)
DEFINE cod_cia		LIKE rept100.r100_compania
DEFINE cod_loc		LIKE rept100.r100_localidad
DEFINE item 		LIKE rept100.r100_item
DEFINE bodega 		LIKE rept100.r100_bodega
DEFINE fecha		DATE

DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r100		RECORD LIKE rept100.*

DEFINE te_fecha		DATE
DEFINE cod_tran_ant	LIKE rept020.r20_cod_tran
DEFINE cant 		LIKE rept011.r11_stock_act
DEFINE stock 		LIKE rept011.r11_stock_act

	LET te_fecha = MDY(MONTH(fecha), 1, YEAR(fecha))
	LET te_fecha = te_fecha - 1 UNITS DAY

	SELECT NVL(r31_stock, 0) INTO stock FROM rept031
	 WHERE r31_compania  = cod_cia
	   AND r31_ano		 = YEAR(te_fecha)
	   AND r31_mes		 = MONTH(te_fecha)
	   AND r31_bodega    = bodega 
	   AND r31_item      = item 

	DECLARE q_fecha_1 CURSOR FOR
		SELECT * FROM rept020
		 WHERE r20_compania  = cod_cia
		   AND r20_localidad = cod_loc
		   AND r20_item		 = item
		   AND r20_fecing    BETWEEN EXTEND(te_fecha + 1 UNITS DAY, YEAR TO SECOND)
					 			 AND EXTEND(fecha, YEAR TO SECOND)  

	INITIALIZE cod_tran_ant TO NULL
	FOREACH q_fecha_1 INTO r_r20.*

		CALL fl_lee_cabecera_transaccion_rep(r_r20.r20_compania, 
											 r_r20.r20_localidad, 
                                           	 r_r20.r20_cod_tran, 
											 r_r20.r20_num_tran)
			RETURNING r_r19.*

		IF r_r19.r19_tipo_tran = 'C' THEN
			CONTINUE FOREACH
		END IF
{*
 * Si es FA, DF o AF leo la bodega de la rept100; caso contrario lo leo
 * de la cabecera de la transaccion.
 *}
		IF r_r20.r20_cod_tran = 'FA' OR r_r20.r20_cod_tran = 'DF' OR
		   r_r20.r20_cod_tran = 'AF' 
		THEN
			INITIALIZE r_r100.* TO NULL
			SELECT * FROM rept100
  			 WHERE r100_compania  = r_r20.r20_compania
			   AND r100_localidad = r_r20.r20_localidad
			   AND r100_cod_tran  = r_r20.r20_cod_tran 
			   AND r100_num_tran  = r_r20.r20_num_tran 
			   AND r100_item      = r_r20.r20_item     
			   AND r100_bodega    = bodega

			IF r_r100.r100_compania IS NULL THEN
				CONTINUE FOREACH
			END IF

			CASE r_r19.r19_tipo_tran
				WHEN 'I'
					LET cant = r_r100.r100_cantidad
				WHEN 'E'
					LET cant = r_r100.r100_cantidad * (-1)
			END CASE
		ELSE
			IF r_r19.r19_bodega_ori <> bodega AND r_r19.r19_bodega_dest <> bodega
			THEN
				CONTINUE FOREACH
			END IF

			CASE r_r19.r19_tipo_tran
				WHEN 'T'
					IF r_r19.r19_bodega_ori = bodega THEN
						LET cant = r_r20.r20_cant_ven * (-1)
					ELSE
						IF r_r19.r19_bodega_dest = bodega THEN
							LET cant = r_r20.r20_cant_ven
						END IF
					END IF
				WHEN 'I'
					LET cant = r_r20.r20_cant_ven
				WHEN 'E'
					LET cant = r_r20.r20_cant_ven * (-1)
			END CASE
		END IF

		LET stock = stock + cant
	END FOREACH

	RETURN stock

END FUNCTION



FUNCTION fl_lee_compania_repuestos(cod_cia)
DEFINE cod_cia		LIKE rept000.r00_compania
DEFINE r		RECORD LIKE rept000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept000 
	WHERE r00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_preventa_rep(cod_cia, cod_loc, preventa)
DEFINE cod_cia		LIKE rept023.r23_compania
DEFINE cod_loc		LIKE rept023.r23_localidad
DEFINE preventa		LIKE rept023.r23_numprev
DEFINE r		RECORD LIKE rept023.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept023 
	WHERE r23_compania = cod_cia AND r23_localidad = cod_loc AND
	      r23_numprev  = preventa
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proforma_desde_preventa(codcia, codloc, numprev)
DEFINE codcia		LIKE rept102.r102_compania
DEFINE codloc		LIKE rept102.r102_localidad
DEFINE numprev		LIKE rept102.r102_numprev
DEFINE r			RECORD LIKE rept021.*

	INITIALIZE r.* TO NULL
	SELECT rept021.* INTO r.* FROM rept102, rept021
	 WHERE r102_compania  = codcia 
	   AND r102_localidad = codloc
	   AND r102_numprev   = numprev
       AND r21_compania   = r102_compania
       AND r21_localidad  = r102_localidad
	   AND r21_numprof    = r102_numprof

	RETURN r.*

END FUNCTION



FUNCTION fl_lee_cabecera_credito_rep(cod_cia, cod_loc, preventa)
DEFINE cod_cia		LIKE rept025.r25_compania
DEFINE cod_loc		LIKE rept025.r25_localidad
DEFINE preventa		LIKE rept025.r25_numprev
DEFINE r		RECORD LIKE rept025.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept025 
	WHERE r25_compania = cod_cia AND r25_localidad = cod_loc AND
	      r25_numprev  = preventa
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proforma_rep(cod_cia, cod_loc, numprof)
DEFINE cod_cia		LIKE rept021.r21_compania
DEFINE cod_loc		LIKE rept021.r21_localidad
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE r		RECORD LIKE rept021.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept021 
	WHERE r21_compania = cod_cia AND r21_localidad = cod_loc AND
	      r21_numprof  = numprof
RETURN r.*

END FUNCTION



FUNCTION fl_lee_pedido_rep(cod_cia, cod_loc, pedido)
DEFINE cod_cia		LIKE rept016.r16_compania
DEFINE cod_loc		LIKE rept016.r16_localidad
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE r		RECORD LIKE rept016.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept016 
	WHERE r16_compania = cod_cia AND r16_localidad = cod_loc AND
	      r16_pedido = pedido
RETURN r.*

END FUNCTION



FUNCTION fl_actualiza_estadisticas_item_rep(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r, rx		RECORD LIKE rept012.*
DEFINE rc		RECORD LIKE rept019.*
DEFINE rd		RECORD LIKE rept020.*
DEFINE rt		RECORD LIKE gent021.*
DEFINE i		SMALLINT

SET LOCK MODE TO WAIT 10
CALL fl_lee_cod_transaccion(cod_tran) RETURNING rt.*
IF rt.g21_tipo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Tipo de transacción no existe', 'stop')
	RETURN 0
END IF
IF rt.g21_act_estad <> 'S' THEN
	RETURN 1
END IF
IF rt.g21_tipo <> 'I' AND rt.g21_tipo <> 'E' THEN
	--CALL fgl_winmessage(vg_producto, 'Transacción no es de ingreso ni de egreso de stock', 'stop')
	RETURN 1
END IF
CALL fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rc.*
IF rc.r19_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' || ' no existe ',
			    'stop')
	RETURN 0
END IF	
DECLARE q_dreit CURSOR FOR 
	SELECT * FROM rept020
		WHERE r20_compania  = cod_cia  AND
	              r20_localidad = cod_loc  AND
	              r20_cod_tran  = cod_tran AND
	              r20_num_tran  = num_tran  
LET i = 0
INITIALIZE r.* TO NULL
LET r.r12_compania = cod_cia 
LET r.r12_moneda   = rc.r19_moneda
LET r.r12_fecha    = DATE(rc.r19_fecing)
FOREACH q_dreit INTO rd.*
	LET r.r12_item = rd.r20_item
	LET r.r12_uni_perdi = rd.r20_cant_ped - rd.r20_cant_ven
	LET r.r12_val_venta = (rd.r20_cant_ven * rd.r20_precio) - 
			       rd.r20_val_descto
	IF rt.g21_tipo = 'I' THEN
		LET r.r12_bodega    = rc.r19_bodega_dest
		LET r.r12_uni_venta = 0
		LET r.r12_uni_dev   = rd.r20_cant_ven
		LET r.r12_uni_deman = -1
		LET r.r12_uni_perdi = r.r12_uni_perdi * -1
		LET r.r12_val_dev   = r.r12_val_venta 
		LET r.r12_val_venta = 0
	ELSE
		LET r.r12_bodega = rc.r19_bodega_ori
		LET r.r12_uni_venta = rd.r20_cant_ven
		LET r.r12_uni_dev   = 0
		LET r.r12_uni_deman = 1
		LET r.r12_val_dev   = 0
	END IF
	LET i = i + 1
	WHENEVER ERROR CONTINUE
	DECLARE q_up12 CURSOR FOR SELECT * FROM rept012
		WHERE r12_compania  = r.r12_compania  AND 
		      r12_moneda    = r.r12_moneda    AND 
		      r12_fecha     = r.r12_fecha     AND 
		      r12_bodega    = r.r12_bodega    AND 
		      r12_item      = r.r12_item   
		FOR UPDATE
	OPEN q_up12
	FETCH q_up12 INTO rx.*
	IF status = NOTFOUND THEN
		INSERT INTO rept012 VALUES (r.*)
	ELSE
		IF status < 0 THEN
			CALL fgl_winmessage(vg_producto, 'Debido a un bloqueo no se pudo actualizar estadísticas de items, ejecute el proceso de nuevo', 'stop')
			WHENEVER ERROR STOP
			RETURN 0
		END IF
		WHENEVER ERROR STOP
		UPDATE rept012 SET r12_uni_venta   = r12_uni_venta   + 
				                     r.r12_uni_venta,
				   r12_uni_dev     = r12_uni_dev     +
						     r.r12_uni_dev,
				   r12_uni_deman   = r12_uni_deman   +
						     r.r12_uni_deman,
				   r12_uni_perdi   = r12_uni_perdi   +
						     r.r12_uni_perdi,
				   r12_val_dev     = r12_val_dev     +
						     r.r12_val_dev,
				   r12_val_venta   = r12_val_venta   +
						     r.r12_val_venta 
			WHERE CURRENT OF q_up12
	END IF
	WHENEVER ERROR STOP
END FOREACH
IF i = 0 THEN
	CALL fgl_winmessage(vg_producto, 'Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' ||
			    ' no tiene detalle', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION	



FUNCTION fl_actualiza_acumulados_ventas_veh(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE veht030.v30_compania
DEFINE cod_loc		LIKE veht030.v30_localidad
DEFINE cod_tran		LIKE veht030.v30_cod_tran
DEFINE num_tran		LIKE veht030.v30_num_tran
DEFINE r, rv		RECORD LIKE veht040.*
DEFINE rc		RECORD LIKE veht030.*
DEFINE rd		RECORD LIKE veht031.*
DEFINE rt		RECORD LIKE gent021.*
DEFINE r_veh		RECORD LIKE veht022.*
DEFINE r_mod		RECORD LIKE veht020.*
DEFINE i		SMALLINT

SET LOCK MODE TO WAIT 10
CALL fl_lee_cod_transaccion(cod_tran) RETURNING rt.*
IF rt.g21_tipo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Tipo de transacción no existe', 'stop')
	RETURN 0
END IF 
IF rt.g21_act_estad <> 'S' THEN
	RETURN 1
END IF
IF rt.g21_tipo <> 'I' AND rt.g21_tipo <> 'E' THEN
	--CALL fgl_winmessage(vg_producto, 'Transacción no es de ingreso ni de egreso de stock', 'stop')
	RETURN 1
END IF
CALL fl_lee_cabecera_transaccion_veh(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rc.*
IF rc.v30_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' || ' no existe ',
			    'stop')
	RETURN 0
END IF	
DECLARE q_dvest CURSOR FOR 
	SELECT * FROM veht031
	WHERE v31_compania  = cod_cia  AND
	      v31_localidad = cod_loc  AND
	      v31_cod_tran  = cod_tran AND
	      v31_num_tran  = num_tran  
INITIALIZE r.* TO NULL
LET r.v40_compania = cod_cia
LET r.v40_vendedor = rc.v30_vendedor
LET r.v40_moneda   = rc.v30_moneda
LET r.v40_ano      = YEAR(rc.v30_fecing)
LET r.v40_mes      = MONTH(rc.v30_fecing)
LET i = 0
FOREACH q_dvest INTO rd.*
	LET i = i + 1
	IF rt.g21_tipo = 'I' THEN
		LET r.v40_bodega    = rc.v30_bodega_dest
		LET r.v40_valor     = (rd.v31_precio - rd.v31_val_descto) * -1
		LET r.v40_uni_venta = -1
	ELSE
		LET r.v40_bodega    = rc.v30_bodega_ori
		LET r.v40_valor     = rd.v31_precio - rd.v31_val_descto
		LET r.v40_uni_venta = 1
	END IF
	CALL fl_lee_cod_vehiculo_veh(cod_cia, cod_loc, rd.v31_codigo_veh)
		RETURNING r_veh.*
	CALL fl_lee_modelo_veh(cod_cia, r_veh.v22_modelo)
		RETURNING r_mod.*
	LET r.v40_modelo = r_veh.v22_modelo
	LET r.v40_linea  = r_mod.v20_linea
	WHENEVER ERROR CONTINUE
	DECLARE q_up40 CURSOR FOR SELECT * FROM veht040
		WHERE v40_compania  = r.v40_compania  AND 
		      v40_bodega    = r.v40_bodega    AND 
		      v40_modelo    = r.v40_modelo    AND 
		      v40_linea     = r.v40_linea     AND 
		      v40_vendedor  = r.v40_vendedor  AND 
		      v40_ano       = r.v40_ano       AND 
		      v40_mes       = r.v40_mes       AND
		      v40_moneda    = r.v40_moneda    
		FOR UPDATE
	OPEN q_up40
	FETCH q_up40 INTO rv.*
	IF status = NOTFOUND THEN
		INSERT INTO veht040 VALUES (r.*)
	ELSE
		IF status < 0 THEN
			CALL fgl_winmessage(vg_producto, 'Debido a un bloqueo no se pudo actualizar estadísticas de ventas, ejecute el proceso de nuevo', 'stop')
			WHENEVER ERROR STOP
			RETURN 0
		END IF
		WHENEVER ERROR STOP
		UPDATE veht040 SET v40_uni_venta = v40_uni_venta + 
						   r.v40_uni_venta,
		                   v40_valor     = v40_valor     + r.v40_valor
			WHERE CURRENT OF q_up40
	END IF
	WHENEVER ERROR STOP
END FOREACH
IF i = 0 THEN
	CALL fgl_winmessage(vg_producto, 'Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' || 
			    ' no tiene detalle', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION	



FUNCTION fl_lee_linea_taller(cod_cia, linea)
DEFINE cod_cia		LIKE talt001.t01_compania
DEFINE linea		LIKE talt001.t01_linea
DEFINE r		RECORD LIKE talt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt001 
	WHERE t01_compania = cod_cia AND t01_linea = linea
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_compania_default()
DEFINE cod_cia, cia	LIKE gent001.g01_compania

SELECT g01_compania INTO cod_cia FROM gent001 WHERE g01_principal = 'S'
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No hay compañía principal configurada.', 'stop')
	EXIT PROGRAM
END IF
DECLARE cur_lito CURSOR FOR 
	SELECT UNIQUE g53_compania FROM gent053
		WHERE g53_usuario = vg_usuario
OPEN cur_lito 
FETCH cur_lito INTO cia
IF status = NOTFOUND THEN
	RETURN cod_cia
ELSE
	RETURN cia
END IF

END FUNCTION



FUNCTION fl_retorna_agencia_default(cod_cia)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad

SELECT g02_localidad INTO cod_local FROM gent002
	WHERE g02_compania = cod_cia AND g02_matriz = 'S'
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No hay localidad matriz para compañía: ' || cod_cia, 'stop')
	EXIT PROGRAM
END IF
IF vg_usuario = 'GMOYA' THEN
	LET cod_local = 2
END IF
RETURN cod_local

END FUNCTION



FUNCTION fl_cabecera_pantalla(cod_cia, cod_local, cod_mod, cod_proc)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE cod_mod		LIKE gent050.g50_modulo
DEFINE cod_proc		LIKE gent054.g54_proceso
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*
DEFINE r_proc		RECORD LIKE gent054.*
DEFINE r_mod		RECORD LIKE gent050.*
DEFINE titulo		CHAR(55)

LET vg_proceso  = cod_proc
OPEN WINDOW wt AT 1,2 WITH 1 ROWS, 90 COLUMNS ATTRIBUTE(BORDER)
CALL fl_lee_compania(cod_cia) RETURNING r_cia.*
IF r_cia.g01_compania  IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe código cía. en gent001: ' || cod_cia, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(cod_cia, cod_local) RETURNING r_loc.*
IF r_loc.g02_compania  IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe código localidad. en gent0021: ' || cod_local, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_modulo(cod_mod) RETURNING r_mod.*
IF r_mod.g50_modulo  IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe código módulo en gent050: ' || cod_mod, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso(cod_mod, cod_proc) RETURNING r_proc.*
IF r_proc.g54_proceso IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe código proceso en gent054: ' || cod_proc, 'stop')
	EXIT PROGRAM
END IF
LET titulo = r_cia.g01_abreviacion CLIPPED, " (", r_loc.g02_abreviacion CLIPPED,
	     ")"
DISPLAY titulo AT 1,1 ATTRIBUTE(BLUE)
LET titulo = r_mod.g50_nombre CLIPPED, ": ", r_proc.g54_nombre CLIPPED
LET titulo = fl_justifica_titulo('D', titulo, 55)
DISPLAY titulo AT 1,24 ATTRIBUTE(BLUE)

END FUNCTION



FUNCTION fl_retorna_usuario()
 
SELECT USER INTO vg_usuario FROM dual
IF status = NOTFOUND THEN
	CALL fgl_winmessage('ERROR', 'Tabla dual está vacía', 'stop')
	EXIT PROGRAM
END IF
LET vg_usuario = UPSHIFT(vg_usuario)

END FUNCTION



FUNCTION fl_nivel_isolation()

SET ISOLATION TO DIRTY READ

END FUNCTION



FUNCTION fl_seteos_defaults()
DEFINE resp		CHAR(6)
DEFINE r_usuario        RECORD LIKE gent005.*
DEFINE estado           CHAR(9)
DEFINE clave 	        LIKE gent005.g05_clave

SET ISOLATION TO DIRTY READ
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
CALL fl_marca_registrada_producto()
CALL fl_retorna_usuario()
CALL fl_separador()
IF vg_codcia = 0 OR vg_codcia IS NULL THEN
	LET vg_codcia = fl_retorna_compania_default()
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF vg_codloc = 0 OR vg_codloc IS NULL THEN
	LET vg_codloc = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_control_acceso_procesos(vg_usuario, vg_codcia, vg_modulo, vg_proceso) 
	RETURNING vg_opciones
OPTIONS ACCEPT KEY	F12,
	INPUT WRAP,
	FORM LINE	FIRST + 2,
	MENU LINE	FIRST + 1,
	COMMENT LINE 	LAST - 1,
	PROMPT LINE	LAST,
	MESSAGE LINE	LAST - 2,
	NEXT KEY	F3,	
	PREVIOUS KEY	F4,
	INSERT KEY	F10,
	DELETE KEY	F11

END FUNCTION




FUNCTION fl_control_acceso_procesos(v_usuario, v_codcia, v_modulo, v_proceso) 
DEFINE v_usuario	LIKE gent005.g05_usuario
DEFINE v_codcia		LIKE gent001.g01_compania
DEFINE v_modulo		LIKE gent050.g50_modulo
DEFINE v_proceso	LIKE gent054.g54_proceso
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_g55 	  	RECORD LIKE gent055.*
DEFINE r_g54   		RECORD LIKE gent054.*
DEFINE clave		LIKE gent005.g05_clave

-- El usuario FOBOS no tiene restricciones
IF v_usuario = 'FOBOS' THEN
	RETURN 'SSSSSSSSSSSSSSS'
END IF

CALL fl_lee_usuario(v_usuario) RETURNING r_g05.*
IF r_g05.g05_usuario IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'USUARIO: ' || v_usuario CLIPPED 
	          || ' NO ESTA CONFIGURADO EN EL SISTEMA.'
		  || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	EXIT PROGRAM
END IF
IF r_g05.g05_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'USUARIO: ' || v_usuario CLIPPED 
	          || ' ESTA BLOQUEADO.'
		  || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_modulo(v_modulo) RETURNING r_g50.*
IF r_g50.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'MODULO: ' || v_modulo CLIPPED 
				          || ' NO EXISTE ', 'stop')
	EXIT PROGRAM
END IF
SELECT * FROM gent052 
	WHERE g52_modulo  = v_modulo  AND 
	      g52_usuario = v_usuario AND
          g52_estado  = 'A'
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'USUARIO NO TIENE ACCESO AL MODULO: '
					 || r_g50.g50_nombre CLIPPED 
					 || '. PEDIR AYUDA AL ADMINISTRADOR ',
					 'stop')
	EXIT PROGRAM
END IF
SELECT * FROM gent053 
	WHERE g53_modulo   = v_modulo  AND 
	      g53_usuario  = v_usuario AND
	      g53_compania = v_codcia 
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,'USUARIO NO TIENE ACCESO A LA COMPAÑIA:'
				|| ' ' || rg_cia.g01_abreviacion CLIPPED 
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
IF v_proceso IS NULL THEN
	RETURN 'NNNNNNNNNNNNNNN'
END IF
CALL fl_lee_proceso(v_modulo, v_proceso) RETURNING r_g54.*
IF r_g54.g54_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'PROCESO: ' || v_modulo CLIPPED 
				          || '-' || v_proceso CLIPPED
					  || ' NO EXISTE ', 'stop')
	EXIT PROGRAM
END IF
IF r_g54.g54_estado = 'B' THEN
	CALL fgl_winmessage(vg_producto, 'EL PROCESO: ' 
				|| v_proceso CLIPPED
				|| ' ESTA MARCADO COMO BLOQUEADO.'
				|| ' PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_permisos_usuarios(vg_usuario, vg_codcia, vg_modulo, vg_proceso) 
	RETURNING r_g55.*
IF r_g55.g55_user IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'USTED NO TIENE ACCESO AL PROCESO ' 
				|| v_proceso CLIPPED
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
IF r_g54.g54_estado = 'R' THEN
	OPEN WINDOW w_clave AT 9,20 WITH FORM 
		'../../../PRODUCCION/LIBRERIAS/forms/ayuf126'
 		ATTRIBUTE(FORM LINE FIRST, BORDER, COMMENT LINE LAST)
	LET int_flag = 0
	LET clave = NULL
	INPUT BY NAME clave
	IF int_flag THEN
		EXIT PROGRAM
	END IF
	IF clave = r_g05.g05_clave OR 
		(clave IS NULL AND r_g05.g05_clave IS NULL) THEN
		CLOSE WINDOW w_clave
		RETURN 'NNNNNNNNNNNNNNN'
	END IF
	CALL fgl_winmessage(vg_producto, 'LO SIENTO CLAVE INCORRECTA ',
				'stop')
	EXIT PROGRAM
END IF	

RETURN r_g55.g55_opciones

END FUNCTION



FUNCTION fl_mapear_opciones(opcion)
DEFINE opcion VARCHAR(15)
DEFINE num_op INTEGER

CASE opcion 
	WHEN 'Ejecutar'
		LET num_op = 1
	WHEN 'Ingresar'
		LET num_op = 2
	WHEN 'Modificar'
		LET num_op = 3
	WHEN 'Procesar'
		LET num_op = 3
	WHEN 'Consultar'
		LET num_op = 4
	WHEN 'Eliminar'
		LET num_op = 5
	WHEN 'Bloquear'
		LET num_op = 5
	WHEN 'Imprimir'
		LET num_op = 6 
	OTHERWISE
		LET num_op = 0
END CASE

RETURN num_op

END FUNCTION



{*
 * Funcion para determinar, a partir de la mascara de opciones, si el usuario
 * tiene permiso para una opcion especifica.
 *}
FUNCTION fl_control_permiso_opcion(opcion) 
DEFINE opcion VARCHAR(15)
DEFINE num_op INTEGER

IF vg_opciones IS NULL THEN
	RETURN FALSE
END IF

LET num_op = fl_mapear_opciones(opcion)
IF vg_opciones[num_op] = 'S' THEN
	RETURN TRUE
END IF

RETURN FALSE

END FUNCTION



FUNCTION fl_justifica_titulo(flag, titulo, longitud)
DEFINE flag 		CHAR(1)     -- C Centrar   D Derecha   I Izquierda
DEFINE titulo, aux	CHAR(132)
DEFINE longitud, i, j	SMALLINT
DEFINE max_long      	SMALLINT

LET max_long = 80
IF longitud > max_long OR longitud <= 0 OR LENGTH(titulo) = 0 THEN
	RETURN titulo
END IF
IF flag <> 'C' AND flag <> 'D' AND flag <> 'I' THEN
	RETURN titulo
END IF
LET aux = titulo
FOR i = 1 TO LENGTH(titulo)
	IF titulo[i,i] <> ' ' OR titulo[i,i] <> '' THEN
		EXIT FOR
	END IF
END FOR
IF i <= max_long THEN
	LET aux = titulo[i, max_long]
	IF LENGTH(aux CLIPPED) > longitud THEN
		LET aux = NULL
		FOR i = 1 TO longitud
			LET aux[i,i] = '*'
		END FOR
		RETURN aux
	END IF
END IF
IF flag = 'D' THEN
	FOR i = 1 TO max_long
		LET aux[i,i] = ' '
	END FOR
	LET i = max_long
	FOR j = LENGTH(titulo CLIPPED) TO 1 STEP -1
		LET aux[i,i] = titulo[j,j]
		LET i = i - 1
	END FOR
	RETURN aux[max_long - longitud + 1, max_long]
ELSE
	IF flag = 'C' THEN
		LET i = 0
		IF longitud > LENGTH(aux CLIPPED) THEN
 			LET i = ((longitud - LENGTH(aux CLIPPED)) / 2) + 1
		END IF
		LET aux = i SPACES, aux CLIPPED
		RETURN aux
	ELSE
		RETURN aux[1, longitud]
	END IF
END IF

END FUNCTION



FUNCTION fl_marca_registrada_producto()

SELECT fb_aplicativo INTO vg_producto FROM fobos
IF status = NOTFOUND THEN
	CALL fgl_winmessage('ERROR', 'Tabla fobos está vacía', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_separador()

SELECT fb_separador, fb_dir_fobos INTO vg_separador, vg_dir_fobos FROM fobos
IF status = NOTFOUND THEN
	CALL fgl_winmessage('ERROR', 'Tabla fobos está vacía', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_lee_basedatos(base)
DEFINE base	        LIKE gent051.g51_basedatos
DEFINE r                RECORD LIKE gent051.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent051
        WHERE g51_basedatos = base
RETURN r.*
                                                                                
END FUNCTION



FUNCTION fl_retorna_nombre_mes(mes)
DEFINE mes		SMALLINT

CASE mes
	WHEN 1
		RETURN '     Enero'
	WHEN 2
		RETURN '   Febrero'
	WHEN 3
		RETURN '     Marzo'
	WHEN 4
		RETURN '     Abril'
	WHEN 5
		RETURN '      Mayo'
	WHEN 6
		RETURN '     Junio'
	WHEN 7
		RETURN '     Julio'
	WHEN 8
		RETURN '    Agosto'
	WHEN 9
		RETURN 'Septiembre'
	WHEN 10
		RETURN '   Octubre'
	WHEN 11
		RETURN ' Noviembre'
	WHEN 12
		RETURN ' Diciembre'
	OTHERWISE
		RETURN 'Xxxxxxxxxx'
END CASE

END FUNCTION



FUNCTION fl_lee_configuracion_taller(cod_cia)
DEFINE cod_cia		LIKE talt000.t00_compania
DEFINE r		RECORD LIKE talt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt000 
	WHERE t00_compania = cod_cia 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_orden_compra(cod_cia)
DEFINE cod_cia		LIKE ordt000.c00_compania
DEFINE r		RECORD LIKE ordt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ordt000 WHERE c00_compania = cod_cia 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_retencion(cod_cia, cod_sri, tipo, porcentaje)
DEFINE cod_cia		LIKE ordt002.c02_compania
DEFINE cod_sri		LIKE ordt002.c02_codigo_sri
DEFINE tipo			LIKE ordt002.c02_tipo_ret
DEFINE porcentaje	LIKE ordt002.c02_porcentaje
DEFINE r		RECORD LIKE ordt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ordt002 
 WHERE c02_compania   = cod_cia 
   AND c02_codigo_sri = cod_sri
   AND c02_tipo_ret   = tipo 
   AND c02_porcentaje = porcentaje
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_orden_compra(tipo)
DEFINE tipo		LIKE ordt001.c01_tipo_orden
DEFINE r		RECORD LIKE ordt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ordt001 WHERE c01_tipo_orden = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_orden_compra(cod_cia, cod_loc, compra)
DEFINE cod_cia		LIKE ordt010.c10_compania
DEFINE cod_loc		LIKE ordt010.c10_localidad
DEFINE compra		LIKE ordt010.c10_numero_oc
DEFINE r		RECORD LIKE ordt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ordt010 
	WHERE c10_compania = cod_cia AND c10_localidad = cod_loc AND 
	      c10_numero_oc = compra
RETURN r.*

END FUNCTION



FUNCTION fl_lee_recepcion_orden_compra(cod_cia, cod_loc, compra, num_recep)
DEFINE cod_cia		LIKE ordt013.c13_compania
DEFINE cod_loc		LIKE ordt013.c13_localidad
DEFINE compra		LIKE ordt013.c13_numero_oc
DEFINE num_recep	LIKE ordt013.c13_num_recep
DEFINE r		RECORD LIKE ordt013.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ordt013 
	WHERE c13_compania  = cod_cia AND 
	      c13_localidad = cod_loc AND 
	      c13_numero_oc = compra  AND
	      c13_num_recep = num_recep
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proveedor(cod_prov)
DEFINE cod_prov		LIKE cxpt001.p01_codprov
DEFINE r		RECORD LIKE cxpt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt001 WHERE p01_codprov = cod_prov
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proveedor_localidad(cod_cia, cod_loc, proveedor)
DEFINE cod_cia		LIKE cxpt002.p02_compania
DEFINE cod_loc		LIKE cxpt002.p02_localidad
DEFINE proveedor	LIKE cxpt002.p02_codprov
DEFINE r		RECORD LIKE cxpt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt002 
	WHERE p02_compania  = cod_cia
          AND p02_localidad = cod_loc
          AND p02_codprov   = proveedor
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proveedor_areaneg(cod_cia, cod_loc, cod_area, cod_prov)
DEFINE cod_cia		LIKE cxpt003.p03_compania
DEFINE cod_loc		LIKE cxpt003.p03_localidad
DEFINE cod_area		LIKE cxpt003.p03_areaneg
DEFINE cod_prov		LIKE cxpt003.p03_codprov
DEFINE r		RECORD LIKE cxpt003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt003 
	WHERE p03_compania  = cod_cia
          AND p03_localidad = cod_loc
          AND p03_areaneg   = cod_area
          AND p03_codprov   = cod_prov
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_tesoreria(cod_cia)
DEFINE cod_cia		LIKE cxpt000.p00_compania
DEFINE r		RECORD LIKE cxpt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt000 WHERE p00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_doc_tesoreria(tipodoc)
DEFINE tipodoc		LIKE cxpt004.p04_tipo_doc
DEFINE r		RECORD LIKE cxpt004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt004 WHERE p04_tipo_doc = tipodoc
RETURN r.*

END FUNCTION



FUNCTION fl_lee_documento_deudor_cxp(cod_cia, cod_loc, codprov, tipo_doc, 
		num_doc, dividendo)
DEFINE cod_cia		LIKE cxpt020.p20_compania
DEFINE cod_loc		LIKE cxpt020.p20_localidad
DEFINE codprov		LIKE cxpt020.p20_codprov
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE r		RECORD LIKE cxpt020.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt020 
	WHERE p20_compania  = cod_cia  AND 
	      p20_localidad = cod_loc  AND 
	      p20_codprov   = codprov  AND 
	      p20_tipo_doc  = tipo_doc AND 
	      p20_num_doc   = num_doc  AND 
	      p20_dividendo = dividendo

RETURN r.*

END FUNCTION



FUNCTION fl_lee_documento_favor_cxp(cod_cia, cod_loc, codprov, tipo_doc, num_doc)
DEFINE cod_cia		LIKE cxpt021.p21_compania
DEFINE cod_loc		LIKE cxpt021.p21_localidad
DEFINE codprov		LIKE cxpt021.p21_codprov
DEFINE tipo_doc		LIKE cxpt021.p21_tipo_doc
DEFINE num_doc		LIKE cxpt021.p21_num_doc
DEFINE r		RECORD LIKE cxpt021.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt021 
	WHERE p21_compania  = cod_cia  AND 
	      p21_localidad = cod_loc  AND 
	      p21_codprov   = codprov  AND 
	      p21_tipo_doc  = tipo_doc AND 
	      p21_num_doc   = num_doc 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_transaccion_cxp(cod_cia, cod_loc, codprov, tipo_trn, num_trn)
DEFINE cod_cia		LIKE cxpt022.p22_compania
DEFINE cod_loc		LIKE cxpt022.p22_localidad
DEFINE codprov		LIKE cxpt022.p22_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE r		RECORD LIKE cxpt022.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt022 
	WHERE p22_compania  = cod_cia  AND 
	      p22_localidad = cod_loc  AND 
	      p22_codprov   = codprov  AND 
	      p22_tipo_trn  = tipo_trn AND 
	      p22_num_trn   = num_trn 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_orden_pago_cxp(cod_cia, cod_loc, orden_pago)
DEFINE cod_cia		LIKE cxpt024.p24_compania
DEFINE cod_loc		LIKE cxpt024.p24_localidad
DEFINE orden_pago	LIKE cxpt024.p24_orden_pago
DEFINE r		RECORD LIKE cxpt024.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt024 
	WHERE p24_compania   = cod_cia  AND 
	      p24_localidad  = cod_loc  AND 
	      p24_orden_pago = orden_pago 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_retencion_cxp(cod_cia, cod_loc, num_ret)
DEFINE cod_cia		LIKE cxpt027.p27_compania
DEFINE cod_loc		LIKE cxpt027.p27_localidad
DEFINE num_ret		LIKE cxpt027.p27_num_ret
DEFINE r		RECORD LIKE cxpt027.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxpt027 
	WHERE p27_compania   = cod_cia  AND 
	      p27_localidad  = cod_loc  AND 
	      p27_num_ret    = num_ret 
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_contabilidad(cod_cia)
DEFINE cod_cia		LIKE ctbt000.b00_compania
DEFINE r		RECORD LIKE ctbt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt000 WHERE b00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cuenta(cod_cia, cuenta)
DEFINE cod_cia		LIKE ctbt010.b10_compania
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE r		RECORD LIKE ctbt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt010 
	WHERE b10_compania = cod_cia AND b10_cuenta = cuenta
RETURN r.*

END FUNCTION



FUNCTION fl_lee_nivel_cuenta(nivel)
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE r		RECORD LIKE ctbt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt001 WHERE b01_nivel = nivel
RETURN r.*

END FUNCTION



FUNCTION fl_lee_grupo_cuenta(cod_cia, grupo)
DEFINE cod_cia		LIKE ctbt002.b02_compania
DEFINE grupo		LIKE ctbt002.b02_grupo_cta
DEFINE r		RECORD LIKE ctbt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt002 
	WHERE b02_compania = cod_cia AND b02_grupo_cta = grupo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_comprobante_contable(cod_cia, tipo)
DEFINE cod_cia		LIKE ctbt003.b03_compania
DEFINE tipo		LIKE ctbt003.b03_tipo_comp
DEFINE r		RECORD LIKE ctbt003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt003 
	WHERE b03_compania = cod_cia AND b03_tipo_comp = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_subtipo_comprob_contable(cod_cia, subtipo)
DEFINE cod_cia		LIKE ctbt004.b04_compania
DEFINE subtipo		LIKE ctbt004.b04_subtipo
DEFINE r		RECORD LIKE ctbt004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt004 
	WHERE b04_compania = cod_cia AND b04_subtipo = subtipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_filtro_cuenta(cod_cia, filtro)
DEFINE cod_cia		LIKE ctbt008.b08_compania
DEFINE filtro		LIKE ctbt008.b08_filtro
DEFINE r		RECORD LIKE ctbt008.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt008 
	WHERE b08_compania = cod_cia AND b08_filtro = filtro
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_documento_fuente(tipo)
DEFINE tipo		LIKE ctbt007.b07_tipo_doc
DEFINE r		RECORD LIKE ctbt007.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt007 WHERE b07_tipo_doc = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_comprobante_contable(cod_cia, tipo_comp, num_comp)
DEFINE cod_cia		LIKE ctbt012.b12_compania
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE r		RECORD LIKE ctbt012.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt012 
	WHERE b12_compania = cod_cia AND b12_tipo_comp = tipo_comp AND 
	      b12_num_comp = num_comp
RETURN r.*

END FUNCTION



FUNCTION fl_lee_diario_periodico(codcia, diario)
DEFINE codcia		LIKE ctbt014.b14_compania
DEFINE diario		LIKE ctbt014.b14_codigo
DEFINE r		RECORD LIKE ctbt014.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt014 
	WHERE b14_compania = codcia 
	  AND b14_codigo   = diario

RETURN r.*

END FUNCTION



FUNCTION fl_numera_comprobante_contable(compania, tipo, ano, mes)
DEFINE compania		LIKE ctbt005.b05_compania
DEFINE tipo		LIKE ctbt005.b05_tipo_comp
DEFINE ano, mes		SMALLINT
DEFINE r		RECORD LIKE ctbt005.*
DEFINE numero		INTEGER
DEFINE expr_up		VARCHAR(200)
DEFINE num_format	CHAR(8)
DEFINE ano_char		CHAR(4)
DEFINE existe		SMALLINT

SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
LET existe = 0
WHILE NOT existe
	DECLARE q_ncompt CURSOR 
		FOR SELECT * FROM ctbt005 
			WHERE b05_compania  = compania AND
		              b05_tipo_comp = tipo AND 
		              b05_ano       = ano
		        FOR UPDATE
        OPEN q_ncompt
        FETCH q_ncompt INTO r.*
        IF status = NOTFOUND THEN
		CLOSE q_ncompt
		WHENEVER ERROR STOP
	        INSERT INTO ctbt005 VALUES (compania, tipo, ano, 0,0,0,0,0,0,0,
					    0,0,0,0,0, vg_usuario, CURRENT)
		IF status < 0 THEN
			CALL fgl_winmessage (vg_producto, 'Error al insertar control secuencia en ctbt005', 'exclamation')
			LET numero = -1
			CLOSE q_ncompt
			FREE q_ncompt
			WHENEVER ERROR STOP
			RETURN numero
		END IF
	ELSE
		IF status < 0 THEN
			CALL fgl_winmessage (vg_producto, 'Secuencia está bloqueada por otro proceso', 'exclamation')
			LET numero = -1
			CLOSE q_ncompt
			FREE q_ncompt
			WHENEVER ERROR STOP
			RETURN numero
		END IF
		LET existe = 1
	END IF
END WHILE
CASE mes
	WHEN 1
		LET numero = r.b05_mes01
	WHEN 2
		LET numero = r.b05_mes02
	WHEN 3
		LET numero = r.b05_mes03
	WHEN 4
		LET numero = r.b05_mes04
	WHEN 5
		LET numero = r.b05_mes05
	WHEN 6
		LET numero = r.b05_mes06
	WHEN 7
		LET numero = r.b05_mes07
	WHEN 8
		LET numero = r.b05_mes08
	WHEN 9
		LET numero = r.b05_mes09
	WHEN 10
		LET numero = r.b05_mes10
	WHEN 11
		LET numero = r.b05_mes11
	WHEN 12
		LET numero = r.b05_mes12
END CASE
LET numero = numero + 1
WHENEVER ERROR STOP
LET expr_up = 'UPDATE ctbt005 SET b05_mes', mes USING '&&', ' = ? ',
			' WHERE CURRENT OF q_ncompt '
PREPARE up_sec FROM expr_up
WHENEVER ERROR CONTINUE
EXECUTE up_sec USING numero
IF status < 0 THEN
	CALL fgl_winmessage (vg_producto, 'Error al actualizar secuencia del comprobante', 'exclamation')
	LET numero = -1
	CLOSE q_ncompt
	FREE q_ncompt
	WHENEVER ERROR STOP
	RETURN numero
END IF
WHENEVER ERROR STOP
LET ano_char = ano
LET num_format = ano_char[3,4], mes USING '&&', numero USING '&&&&' 
RETURN num_format

END FUNCTION




FUNCTION fl_mayoriza_comprobante(codcia, tipo, numero, flag_may)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE numero		LIKE ctbt012.b12_num_comp
DEFINE flag_may		CHAR(1)
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE r		RECORD LIKE ctbt012.*
DEFINE rd		RECORD LIKE ctbt013.*
DEFINE r_sal		RECORD LIKE ctbt011.*
DEFINE tipo_cta		CHAR(1)
DEFINE estado		CHAR(1)
DEFINE existe		SMALLINT
DEFINE ano_aux		SMALLINT
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE expr_up		VARCHAR(200)
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE cuenta		LIKE ctbt010.b10_cuenta

IF flag_may <> 'M' AND flag_may <> 'D' THEN
	CALL fgl_winmessage(vg_producto, 'Flag mayorización incorrecto, debe ser M ó D', 'exclamation')
	RETURN
END IF
CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_mcomp CURSOR FOR
	SELECT * FROM ctbt012
		WHERE b12_compania  = codcia AND 
		      b12_tipo_comp = tipo AND 
		      b12_num_comp  = numero
		FOR UPDATE
OPEN q_mcomp
FETCH q_mcomp INTO r.*
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'Comprobante a mayorizar no existe', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF status < 0 THEN
	CALL fgl_winmessage(vg_producto, 'Error al intentar bloquear comprobante para mayorizar', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF YEAR(r.b12_fec_proceso) < r_cia.b00_anopro THEN 
	CALL fgl_winmessage(vg_producto, 'El comprobante pertenece a un año que ya fue cerrado', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
DECLARE q_mdcomp CURSOR FOR 
	SELECT ctbt013.*, b10_tipo_cta FROM ctbt013, ctbt010
		WHERE b13_compania  = codcia AND
		      b13_tipo_comp = tipo   AND
		      b13_num_comp  = numero AND
		      b13_compania  = b10_compania AND
		      b13_cuenta    = b10_cuenta
FOREACH q_mdcomp INTO rd.*, tipo_cta
	LET debito  = 0
	LET credito = 0
	IF rd.b13_valor_base < 0 THEN
		LET credito = rd.b13_valor_base * -1
	ELSE
		LET debito  = rd.b13_valor_base
	END IF
	IF tipo_cta = 'R' THEN
		CALL fl_genera_niveles_mayorizacion(r_cia.b00_cuenta_uti, debito, credito)
	END IF
	CALL fl_genera_niveles_mayorizacion(rd.b13_cuenta, debito, credito)
END FOREACH
DECLARE q_tmay CURSOR FOR SELECT * FROM temp_may
	ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 20
WHENEVER ERROR STOP
FOREACH q_tmay INTO cuenta, debito, credito
	LET existe = 0
	WHILE NOT existe
		WHENEVER ERROR CONTINUE
		DECLARE q_msal CURSOR FOR
			SELECT * FROM ctbt011
				WHERE b11_compania = codcia AND 
		                      b11_moneda   = r_cia.b00_moneda_base AND
		                      b11_ano      = YEAR(r.b12_fec_proceso) AND
		                      b11_cuenta   = cuenta
			        FOR UPDATE
	        OPEN q_msal 
		FETCH q_msal INTO r_sal.*
		IF status = NOTFOUND THEN
			CLOSE q_msal
			WHENEVER ERROR STOP
			LET ano_aux = YEAR(r.b12_fec_proceso)
			INSERT INTO ctbt011 VALUES (codcia, cuenta,
				r_cia.b00_moneda_base, ano_aux,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0,0,0,0,0)
			IF status < 0 THEN
				--DROP TABLE temp_may
				ROLLBACK WORK
				CALL fgl_winmessage(vg_producto, 'Error al crear registro de saldos para la cuenta: ' || cuenta, 'exclamation')
				RETURN
			END IF
		ELSE
			IF status < 0 THEN
				--DROP TABLE temp_may
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fgl_winmessage(vg_producto, 'Cuenta ' || cuenta || ' está bloqueada por otro usuario', 'exclamation')
				RETURN
			END IF
			WHENEVER ERROR STOP
			LET existe = 1
		END IF
	END WHILE
	LET campo_db = 'b11_db_mes_', MONTH(r.b12_fec_proceso) USING '&&'
	LET campo_cr = 'b11_cr_mes_', MONTH(r.b12_fec_proceso) USING '&&'
	IF flag_may = 'D' THEN
		LET debito  = debito  * -1
		LET credito = credito * -1
	END IF
	LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = ', 
					     campo_db, ' + ?, ',
	                                     campo_cr, ' = ', 
					     campo_cr, ' + ? ',
				' WHERE CURRENT OF q_msal' 
	PREPARE up_sal FROM expr_up
	EXECUTE	up_sal USING debito, credito
	IF status < 0 THEN
		--DROP TABLE temp_may
		ROLLBACK WORK
--		WHENEVER ERROR STOP
		CALL fgl_winmessage(vg_producto, 'Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
		RETURN
	END IF
END FOREACH
DROP TABLE temp_may
LET estado = 'M'
IF flag_may = 'D' THEN
	LET estado = 'A'
END IF
WHENEVER ERROR CONTINUE
UPDATE ctbt012 SET b12_estado = estado WHERE CURRENT OF q_mcomp
IF status < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Error al actualizar estado del comprobante ' || tipo || ' ' || numero, 'exclamation')
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION fl_mayorizacion_mes(codcia, moneda, ano, mes)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE moneda		LIKE ctbt012.b12_moneda
DEFINE ano		SMALLINT
DEFINE mes		SMALLINT
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE rd		RECORD LIKE ctbt013.*
DEFINE r_sal		RECORD LIKE ctbt011.*
DEFINE tipo_cta		CHAR(1)
DEFINE existe		SMALLINT
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE expr_up		VARCHAR(200)
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE num_ctas		INTEGER
DEFINE num_act		INTEGER
DEFINE tot_db		DECIMAL(15,2)
DEFINE tot_cr		DECIMAL(15,2)
DEFINE num_row		INTEGER

CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
IF r_cia.b00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF ano < r_cia.b00_anopro THEN 
	CALL fgl_winmessage(vg_producto, 'El año ya está cerrado', 'exclamation')
	RETURN 0
END IF
IF mes < 1 OR mes > 12 THEN 
	CALL fgl_winmessage(vg_producto, 'Mes no está en el rango de 1 a 12', 'exclamation')
	RETURN 0
END IF
IF moneda IS NULL OR (moneda <> r_cia.b00_moneda_base AND 
	moneda <> r_cia.b00_moneda_aux) THEN
	CALL fgl_winmessage(vg_producto, 'Moneda no está configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
BEGIN WORK
WHENEVER ERROR STOP
SELECT * FROM ctbt006 
	WHERE b06_compania = codcia AND 
	      b06_ano      = ano    AND
	      b06_mes      = mes
LET num_row = 0
IF status = NOTFOUND THEN
	INSERT INTO ctbt006 VALUES (codcia, ano, mes, vg_usuario, CURRENT)
	LET num_row = SQLCA.SQLERRD[6]
END IF
ERROR 'Bloqueando maestro de saldos'
LOCK TABLE ctbt011 IN EXCLUSIVE MODE
IF status < 0 THEN
	CALL fgl_winmessage(vg_producto, 'No se pudo bloquear en modo exclusivo maestro de saldos. Asegúrese que nadie esté ingresando/modificando comprobantes en el sistema', 'exclamtion')
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN 0
END IF
WHENEVER ERROR STOP
LET campo_db = 'b11_db_mes_', mes USING '&&'
LET campo_cr = 'b11_cr_mes_', mes USING '&&'
LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = 0, ', 
	                             campo_cr, ' = 0 ' ,
			' WHERE b11_compania = ? AND ',
			'       b11_moneda   = ? AND ',
			'       b11_ano      = ? '
PREPARE up_mesc FROM expr_up
ERROR 'Encerando maestro de saldos'
EXECUTE up_mesc USING codcia, moneda, ano	
DECLARE q_tcomp CURSOR FOR
	SELECT ctbt013.*, b10_tipo_cta FROM ctbt012, ctbt013, ctbt010
		WHERE b12_compania           = codcia AND 
		      YEAR(b12_fec_proceso)  = ano    AND
		      MONTH(b12_fec_proceso) = mes    AND
		      b12_estado <> 'E' AND
		      b12_compania           = b13_compania  AND 
		      b12_tipo_comp          = b13_tipo_comp AND 
		      b12_num_comp           = b13_num_comp  AND
		      b13_compania           = b10_compania  AND
		      b13_cuenta             = b10_cuenta
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
CREATE INDEX i1_temp_may ON temp_may (te_cuenta)
LET num_ctas = 0
LET tot_db = 0
LET tot_cr = 0
FOREACH q_tcomp INTO rd.*, tipo_cta
	ERROR 'Procesando ', mes CLIPPED, '/', ano CLIPPED, 
		  '  cuenta: ', rd.b13_cuenta || '   ', num_ctas
	LET num_ctas = num_ctas + 1
	LET debito  = 0
	LET credito = 0
	IF rd.b13_valor_base < 0 THEN
		LET credito = rd.b13_valor_base * -1
	ELSE
		LET debito  = rd.b13_valor_base
	END IF
	IF tipo_cta = 'R' THEN
		CALL fl_genera_niveles_mayorizacion(r_cia.b00_cuenta_uti, debito, credito)
	END IF
	CALL fl_genera_niveles_mayorizacion(rd.b13_cuenta, debito, credito)
END FOREACH
DECLARE q_tmm CURSOR FOR SELECT * FROM temp_may
	ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
LET num_act = 1
FOREACH q_tmm INTO cuenta, debito, credito
	ERROR 'Mayorizando cuenta: ', cuenta, '  ', num_act
	LET num_act = num_act + 1
	LET existe = 0
	WHILE NOT existe
		DECLARE q_mayc CURSOR FOR
			SELECT * FROM ctbt011
				WHERE b11_compania = codcia AND 
		                      b11_moneda   = moneda AND
		                      b11_ano      = ano    AND
		                      b11_cuenta   = cuenta
			        FOR UPDATE
	        OPEN q_mayc 
		FETCH q_mayc INTO r_sal.*
		IF status = NOTFOUND THEN
			CLOSE q_mayc
			INSERT INTO ctbt011 VALUES (codcia, cuenta,
				moneda, ano,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0,0,0,0,0)
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fgl_winmessage(vg_producto, 'Error al crear registro de saldos para la cuenta: ' || cuenta, 'exclamation')
				RETURN 0
			END IF
		ELSE
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fgl_winmessage(vg_producto, 'Cuenta ' || cuenta || ' está bloqueada por otro usuario', 'exclamation')
				RETURN 0
			END IF
			LET existe = 1
		END IF
	END WHILE
	LET campo_db = 'b11_db_mes_', mes USING '&&'
	LET campo_cr = 'b11_cr_mes_', mes USING '&&'
	LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = ', 
					     campo_db, ' + ?, ',
	                                     campo_cr, ' = ', 
					     campo_cr, ' + ? ',
				' WHERE CURRENT OF q_mayc' 
	PREPARE up_may FROM expr_up
	EXECUTE	up_may USING debito, credito
	IF status < 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fgl_winmessage(vg_producto, 'Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
		RETURN 0
	END IF
END FOREACH
DROP TABLE temp_may
WHENEVER ERROR CONTINUE
--ERROR 'Actualizando estado de comprobantes mayorizados'
UPDATE ctbt012 SET b12_estado = 'M' 
	WHERE b12_compania           = codcia AND 
	      YEAR(b12_fec_proceso)  = ano    AND
	      MONTH(b12_fec_proceso) = mes    AND
	      b12_estado <> 'E'
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fgl_winmessage(vg_producto, 'Error al actualizar estado de los comprobantes mayorizados ', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
DELETE FROM ctbt006 WHERE ROWID = num_row
COMMIT WORK
RETURN 1

END FUNCTION



FUNCTION fl_genera_niveles_mayorizacion(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE i, j		SMALLINT
DEFINE ceros		CHAR(10)
DEFINE rn		RECORD LIKE ctbt001.*

DECLARE q_niv CURSOR FOR SELECT * FROM ctbt001
	ORDER BY b01_nivel DESC
LET i = 0
FOREACH q_niv INTO rn.*
	LET i = i + 1
	IF i = 1 THEN
		CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET cuenta = cuenta[1,rn.b01_posicion_i - 1]
	ELSE
		CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET ceros = NULL
		FOR j = rn.b01_posicion_i TO rn.b01_posicion_f
			LET ceros = ceros CLIPPED, '0'
		END FOR
		LET cuenta[rn.b01_posicion_i, rn.b01_posicion_f] = ceros CLIPPED
	END IF
END FOREACH

END FUNCTION



FUNCTION fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		DECIMAL(14,2)
DEFINE credito		DECIMAL(14,2)

SELECT * FROM temp_may WHERE te_cuenta = cuenta
IF status = NOTFOUND THEN
	INSERT INTO temp_may VALUES(cuenta, debito, credito)	
ELSE
	UPDATE temp_may SET te_debito  = te_debito  + debito,
	                    te_credito = te_credito + credito
		WHERE te_cuenta = cuenta
END IF
			
END FUNCTION



FUNCTION fl_obtiene_saldo_contable(codcia, cuenta, moneda, fecha, flag)
DEFINE codcia		LIKE ctbt011.b11_compania
DEFINE cuenta		LIKE ctbt011.b11_cuenta
DEFINE moneda		LIKE ctbt011.b11_moneda
DEFINE fecha		DATE
DEFINE ano, ano_ant	LIKE ctbt011.b11_ano
DEFINE mes, dia		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_db ARRAY[12] OF LIKE ctbt011.b11_db_mes_01
DEFINE r_cr ARRAY[12] OF LIKE ctbt011.b11_db_mes_01
DEFINE i		SMALLINT
DEFINE saldo, saldo_trn	DECIMAL(16,2)
DEFINE r		RECORD LIKE ctbt010.*
DEFINE r_sal, r_sal1	RECORD LIKE ctbt011.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE fin_mes_current	DATE
DEFINE fin_mes_anterior	DATE
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE dias_ini		SMALLINT
DEFINE dias_fin		SMALLINT
DEFINE factor		SMALLINT

LET ano = YEAR(fecha)
LET mes = MONTH(fecha)
LET dia = DAY(fecha)
CALL fl_lee_compania_contabilidad(codcia) RETURNING r_b00.*
CALL fl_lee_cuenta(codcia, cuenta) RETURNING r.*
IF r.b10_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe cuenta: ' || cuenta, 
		            'exclamation')
	RETURN 0
END IF
LET fin_mes_current  = MDY(mes,1,ano) + 1 UNITS MONTH - 1 UNITS DAY
IF ano = YEAR(TODAY) AND mes = MONTH(TODAY) THEN
	LET fin_mes_current = TODAY
END IF
LET fin_mes_anterior = MDY(mes,1,ano) - 1 UNITS DAY
LET saldo_trn = 0
IF fecha < fin_mes_current THEN
	LET dias_ini = fecha - fin_mes_anterior
	LET dias_fin = fin_mes_current - fecha
	IF dias_ini <= dias_fin THEN
		LET fecha_ini = MDY(mes,1,ano)
		LET fecha_fin = fecha
		LET ano       = YEAR(fin_mes_anterior)
		LET mes       = MONTH(fin_mes_anterior)
		LET factor    = 1
	ELSE
		LET fecha_ini = fecha + 1
		LET fecha_fin = fin_mes_current
		LET factor    = -1
	END IF
	DECLARE cu_netmov CURSOR FOR 
		SELECT * FROM ctbt013
			WHERE b13_compania    = codcia AND 
			      b13_cuenta      = cuenta AND 
			      b13_fec_proceso BETWEEN fecha_ini AND fecha_fin
	FOREACH cu_netmov INTO r_b13.*
		CALL fl_lee_comprobante_contable(codcia, r_b13.b13_tipo_comp, 
			r_b13.b13_num_comp)
			RETURNING r_b12.*
		IF r_b12.b12_estado = 'E' THEN	
			CONTINUE FOREACH
		END IF
		LET saldo_trn = saldo_trn + (r_b13.b13_valor_base * factor)
	END FOREACH
END IF		
LET r_sal1.b11_db_ano_ant = 0
LET r_sal1.b11_cr_ano_ant = 0
LET r_sal1.b11_db_mes_01  = 0
LET r_sal1.b11_db_mes_02  = 0
LET r_sal1.b11_db_mes_03  = 0
LET r_sal1.b11_db_mes_04  = 0
LET r_sal1.b11_db_mes_05  = 0
LET r_sal1.b11_db_mes_06  = 0
LET r_sal1.b11_db_mes_07  = 0
LET r_sal1.b11_db_mes_08  = 0
LET r_sal1.b11_db_mes_09  = 0
LET r_sal1.b11_db_mes_10  = 0
LET r_sal1.b11_db_mes_11  = 0
LET r_sal1.b11_db_mes_12  = 0
LET r_sal1.b11_cr_mes_01  = 0
LET r_sal1.b11_cr_mes_02  = 0
LET r_sal1.b11_cr_mes_03  = 0
LET r_sal1.b11_cr_mes_04  = 0
LET r_sal1.b11_cr_mes_05  = 0
LET r_sal1.b11_cr_mes_06  = 0
LET r_sal1.b11_cr_mes_07  = 0
LET r_sal1.b11_cr_mes_08  = 0
LET r_sal1.b11_cr_mes_09  = 0
LET r_sal1.b11_cr_mes_10  = 0
LET r_sal1.b11_cr_mes_11  = 0
LET r_sal1.b11_cr_mes_12  = 0
SELECT * INTO r_sal.* FROM ctbt011 WHERE b11_compania = codcia AND 
			    b11_cuenta   = cuenta AND
			    b11_moneda   = moneda AND 
			    b11_ano      = ano
IF status = NOTFOUND THEN
	LET r_sal.* = r_sal1.*
END IF
IF r_b00.b00_anopro < ano AND r.b10_tipo_cta <> 'R' THEN
	LET ano_ant = ano - 1
	SELECT b11_compania, b11_cuenta, b11_moneda, 2000,
		SUM(b11_db_ano_ant),
		SUM(b11_cr_ano_ant),
		SUM(b11_db_mes_01),
		SUM(b11_db_mes_02),
		SUM(b11_db_mes_03),
		SUM(b11_db_mes_04),
		SUM(b11_db_mes_05),
		SUM(b11_db_mes_06),
		SUM(b11_db_mes_07),
		SUM(b11_db_mes_08),
		SUM(b11_db_mes_09),
		SUM(b11_db_mes_10),
		SUM(b11_db_mes_11),
		SUM(b11_db_mes_12),
		SUM(b11_cr_mes_01),
		SUM(b11_cr_mes_02),
		SUM(b11_cr_mes_03),
		SUM(b11_cr_mes_04),
		SUM(b11_cr_mes_05),
		SUM(b11_cr_mes_06),
		SUM(b11_cr_mes_07),
		SUM(b11_cr_mes_08),
		SUM(b11_cr_mes_09),
		SUM(b11_cr_mes_10),
		SUM(b11_cr_mes_11),
		SUM(b11_cr_mes_12)
		INTO r_sal1.*
 		FROM ctbt011 
		WHERE b11_compania = codcia AND 
		      b11_cuenta   = cuenta AND
		      b11_moneda   = moneda AND 
		      --b11_ano      = ano_ant
		      b11_ano BETWEEN r_b00.b00_anopro AND ano_ant
		GROUP BY 1,2,3,4
		IF r_sal1.b11_db_ano_ant IS NULL THEN
			LET r_sal1.b11_db_ano_ant = 0
			LET r_sal1.b11_cr_ano_ant = 0
			LET r_sal1.b11_db_mes_01  = 0
			LET r_sal1.b11_db_mes_02  = 0
			LET r_sal1.b11_db_mes_03  = 0
			LET r_sal1.b11_db_mes_04  = 0
			LET r_sal1.b11_db_mes_05  = 0
			LET r_sal1.b11_db_mes_06  = 0
			LET r_sal1.b11_db_mes_07  = 0
			LET r_sal1.b11_db_mes_08  = 0
			LET r_sal1.b11_db_mes_09  = 0
			LET r_sal1.b11_db_mes_10  = 0
			LET r_sal1.b11_db_mes_11  = 0
			LET r_sal1.b11_db_mes_12  = 0
			LET r_sal1.b11_cr_mes_01  = 0
			LET r_sal1.b11_cr_mes_02  = 0
			LET r_sal1.b11_cr_mes_03  = 0
			LET r_sal1.b11_cr_mes_04  = 0
			LET r_sal1.b11_cr_mes_05  = 0
			LET r_sal1.b11_cr_mes_06  = 0
			LET r_sal1.b11_cr_mes_07  = 0
			LET r_sal1.b11_cr_mes_08  = 0
			LET r_sal1.b11_cr_mes_09  = 0
			LET r_sal1.b11_cr_mes_10  = 0
			LET r_sal1.b11_cr_mes_11  = 0
			LET r_sal1.b11_cr_mes_12  = 0
		END IF	
END IF
LET r_sal.b11_db_ano_ant = r_sal.b11_db_ano_ant  +
			   r_sal1.b11_db_ano_ant +
			   r_sal1.b11_db_mes_01  +
			   r_sal1.b11_db_mes_02  +
			   r_sal1.b11_db_mes_03  +
			   r_sal1.b11_db_mes_04  +
			   r_sal1.b11_db_mes_05  +
			   r_sal1.b11_db_mes_06  +
			   r_sal1.b11_db_mes_07  +
			   r_sal1.b11_db_mes_08  +
			   r_sal1.b11_db_mes_09  +
			   r_sal1.b11_db_mes_10  +
			   r_sal1.b11_db_mes_11  +
			   r_sal1.b11_db_mes_12  
LET r_sal.b11_cr_ano_ant = r_sal.b11_cr_ano_ant  +
			   r_sal1.b11_cr_ano_ant +
			   r_sal1.b11_cr_mes_01  +
			   r_sal1.b11_cr_mes_02  +
			   r_sal1.b11_cr_mes_03  +
			   r_sal1.b11_cr_mes_04  +
			   r_sal1.b11_cr_mes_05  +
			   r_sal1.b11_cr_mes_06  +
			   r_sal1.b11_cr_mes_07  +
			   r_sal1.b11_cr_mes_08  +
			   r_sal1.b11_cr_mes_09  +
			   r_sal1.b11_cr_mes_10  +
			   r_sal1.b11_cr_mes_11  +
			   r_sal1.b11_cr_mes_12  
LET r_db[01] = r_sal.b11_db_mes_01
LET r_db[02] = r_sal.b11_db_mes_02
LET r_db[03] = r_sal.b11_db_mes_03
LET r_db[04] = r_sal.b11_db_mes_04
LET r_db[05] = r_sal.b11_db_mes_05
LET r_db[06] = r_sal.b11_db_mes_06
LET r_db[07] = r_sal.b11_db_mes_07
LET r_db[08] = r_sal.b11_db_mes_08
LET r_db[09] = r_sal.b11_db_mes_09
LET r_db[10] = r_sal.b11_db_mes_10
LET r_db[11] = r_sal.b11_db_mes_11
LET r_db[12] = r_sal.b11_db_mes_12
LET r_cr[01] = r_sal.b11_cr_mes_01
LET r_cr[02] = r_sal.b11_cr_mes_02
LET r_cr[03] = r_sal.b11_cr_mes_03
LET r_cr[04] = r_sal.b11_cr_mes_04
LET r_cr[05] = r_sal.b11_cr_mes_05
LET r_cr[06] = r_sal.b11_cr_mes_06
LET r_cr[07] = r_sal.b11_cr_mes_07
LET r_cr[08] = r_sal.b11_cr_mes_08
LET r_cr[09] = r_sal.b11_cr_mes_09
LET r_cr[10] = r_sal.b11_cr_mes_10
LET r_cr[11] = r_sal.b11_cr_mes_11
LET r_cr[12] = r_sal.b11_cr_mes_12
LET saldo = 0
IF flag = 'M' THEN
	LET saldo = saldo + r_db[mes] - r_cr[mes]
ELSE	
	FOR i = 1 TO mes
		LET saldo = saldo + r_db[i] - r_cr[i]
	END FOR
	IF r.b10_tipo_cta <> 'R' THEN
		LET saldo = saldo + r_sal.b11_db_ano_ant - r_sal.b11_cr_ano_ant
	END IF
END IF
LET saldo = saldo + saldo_trn
RETURN saldo

END FUNCTION



FUNCTION fl_saldo_cuenta_utilidad(codcia, moneda, fecha, nivel, ccosto, flag)
DEFINE codcia		LIKE ctbt011.b11_compania
DEFINE moneda		LIKE ctbt011.b11_moneda
DEFINE fecha		DATE
DEFINE nivel		SMALLINT
DEFINE ccosto		LIKE gent033.g33_cod_ccosto
DEFINE cod_ccosto	LIKE gent033.g33_cod_ccosto
DEFINE flag		CHAR(1)
DEFINE saldo, valor	DECIMAL(16,2)
DEFINE cuenta		LIKE ctbt010.b10_cuenta

DECLARE q_picachu CURSOR FOR SELECT b10_cuenta, b10_cod_ccosto FROM ctbt010
	WHERE b10_compania = codcia AND b10_tipo_cta = 'R' AND
	      b10_nivel = nivel
LET saldo = 0
FOREACH q_picachu INTO cuenta, cod_ccosto
	IF ccosto IS NOT NULL THEN
		IF cod_ccosto IS NULL OR ccosto <> cod_ccosto THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_obtiene_saldo_contable(codcia, cuenta, moneda, fecha, flag)
		RETURNING valor
	LET saldo = saldo + valor
END FOREACH
RETURN saldo

END FUNCTION	



FUNCTION fl_lee_compania_activos(cod_cia)
DEFINE cod_cia		LIKE actt000.a00_compania
DEFINE r		RECORD LIKE actt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt000 
	WHERE a00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_compania_caja(cod_cia)
DEFINE cod_cia		LIKE cajt000.j00_compania
DEFINE r		RECORD LIKE cajt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt000 
	WHERE j00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_tipo_pago_caja(cod_cia, tipo)
DEFINE cod_cia		LIKE cajt001.j01_compania
DEFINE tipo		LIKE cajt001.j01_codigo_pago
DEFINE r		RECORD LIKE cajt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt001 
	WHERE j01_compania = cod_cia AND j01_codigo_pago = tipo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_codigo_caja_caja(cod_cia, cod_loc, caja)
DEFINE cod_cia		LIKE cajt002.j02_compania
DEFINE cod_loc		LIKE cajt002.j02_localidad
DEFINE caja		LIKE cajt002.j02_codigo_caja
DEFINE r		RECORD LIKE cajt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt002 
	WHERE j02_compania    = cod_cia AND 
	      j02_localidad   = cod_loc AND 
	      j02_codigo_caja = caja
RETURN r.*

END FUNCTION
 


FUNCTION fl_lee_configuracion_caja_chica(cod_cia, cod_loc, caja)
DEFINE cod_cia		LIKE ccht001.h01_compania
DEFINE cod_loc		LIKE ccht001.h01_localidad
DEFINE caja		LIKE ccht001.h01_caja_chica
DEFINE r		RECORD LIKE ccht001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ccht001 
	WHERE h01_compania   = cod_cia AND 
	      h01_localidad  = cod_loc AND 
	      h01_caja_chica = caja
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cabecera_caja(cod_cia, cod_loc, tipo_fuente, num_fuente)
DEFINE cod_cia		LIKE cajt010.j10_compania
DEFINE cod_loc		LIKE cajt010.j10_localidad
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE r		RECORD LIKE cajt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt010 
	WHERE j10_compania    = cod_cia AND 
	      j10_localidad   = cod_loc AND 
	      j10_tipo_fuente = tipo_fuente AND 
	      j10_num_fuente  = num_fuente
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_caja(cod_cia, cod_loc, usuario)
DEFINE cod_cia		LIKE cajt002.j02_compania
DEFINE cod_loc		LIKE cajt002.j02_localidad
DEFINE usuario		LIKE cajt002.j02_usua_caja
DEFINE r		RECORD LIKE cajt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt002 
	WHERE j02_compania  = cod_cia AND 
	      j02_localidad = cod_loc AND 
	      j02_usua_caja = usuario
RETURN r.*

END FUNCTION



FUNCTION fl_lee_detalle_pago_caja(cod_cia, cod_loc, tipo, numero, secuencia)
DEFINE cod_cia		LIKE cajt011.j11_compania
DEFINE cod_loc		LIKE cajt011.j11_localidad
DEFINE tipo		LIKE cajt011.j11_tipo_fuente
DEFINE numero		LIKE cajt011.j11_num_fuente
DEFINE secuencia	LIKE cajt011.j11_secuencia
DEFINE r		RECORD LIKE cajt011.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt011 
	WHERE j11_compania    = cod_cia AND 
	      j11_localidad   = cod_loc AND 
	      j11_tipo_fuente = tipo    AND
	      j11_num_fuente  = numero  AND
	      j11_secuencia   = secuencia
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_precision_valor(moneda, valor)
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor, val_aux	DECIMAL(16,4)
DEFINE r		RECORD LIKE gent013.*

CALL fl_lee_moneda(moneda) RETURNING r.*
IF r.g13_moneda IS NULL THEN
	CALL fgl_winmessage (vg_producto, 'No existe moneda: ' ||  moneda, 'stop')
	EXIT PROGRAM
END IF
LET val_aux = NULL
SELECT ROUND(valor, r.g13_decimales) INTO val_aux FROM dual  
RETURN val_aux

END FUNCTION



FUNCTION fl_actualiza_control_secuencias(cod_cia, cod_loc, modulo, bodega, tipo)
DEFINE cod_cia		LIKE gent015.g15_compania
DEFINE cod_loc		LIKE gent015.g15_localidad
DEFINE modulo		LIKE gent015.g15_modulo
DEFINE bodega		LIKE gent015.g15_bodega
DEFINE tipo		LIKE gent015.g15_tipo
DEFINE r		RECORD LIKE gent015.* 
DEFINE mensaje		VARCHAR(60)

SET LOCK MODE TO WAIT 5
DECLARE q_csec CURSOR FOR
	SELECT * FROM gent015
	WHERE g15_compania  = cod_cia AND 
	      g15_localidad = cod_loc AND 
	      g15_modulo    = modulo  AND 
	      g15_bodega    = bodega  AND 
	      g15_tipo      = tipo
	FOR UPDATE 
OPEN q_csec
FETCH q_csec INTO r.*
IF status = NOTFOUND THEN
	LET mensaje = 'No existe control secuencia en gent015: ',
		       cod_cia USING '##', ' ', cod_loc USING '##', ' ', 
		       modulo, ' ', bodega, ' ', tipo
	CALL fgl_winmessage (vg_producto, mensaje, 'exclamation')
	LET r.g15_numero = 0
ELSE
	IF status < 0 THEN
		CALL fgl_winmessage (vg_producto, 'Secuencia está bloqueada por otro proceso', 'exclamation')
		LET r.g15_numero = -1
	ELSE
		LET r.g15_numero = r.g15_numero + 1
		UPDATE gent015 SET g15_numero = r.g15_numero
			WHERE CURRENT OF q_csec
		IF status < 0 THEN
			CALL fgl_winmessage (vg_producto, 'No se actualizó control secuencia', 'exclamation')
			LET r.g15_numero = -1
		END IF
	END IF
END IF

SET LOCK MODE TO NOT WAIT
RETURN r.g15_numero

END FUNCTION



FUNCTION fl_mensaje_registro_ingresado()

CALL fgl_winmessage (vg_producto, 'Registro grabado Ok.', 'info')

END FUNCTION



FUNCTION fl_mensaje_registro_modificado()

CALL fgl_winmessage (vg_producto, 'Registro actualizado Ok.', 'info')

END FUNCTION



FUNCTION fl_mensaje_consultar_primero()

CALL fgl_winmessage(vg_producto,'Ejecute una consulta primero', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_bloqueo_otro_usuario()

CALL fgl_winmessage(vg_producto, 'Registro está siendo modificado por otro usuario','exclamation')

END FUNCTION



FUNCTION fl_mensaje_consulta_sin_registros()

CALL fgl_winmessage(vg_producto, 'No se encontraron registros con el criterio indicado', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_estado_bloqueado()

CALL fgl_winmessage(vg_producto, 'Registro está bloqueado', 'exclamation')

END FUNCTION


FUNCTION fl_mensaje_clave_erronea()

CALL fgl_winmessage(vg_producto, 'Clave digitada está errónea', 'exclamation')

END FUNCTION

FUNCTION fl_mensaje_abandonar_proceso()
DEFINE resp		CHAR(6)

CALL fgl_winquestion(vg_producto,'Realmente desea abandonar','No','Yes|No|Cancel','question',1)
	RETURNING resp
RETURN resp

END FUNCTION



FUNCTION fl_mensaje_seguro_ejecutar_proceso()
DEFINE resp		CHAR(6)

CALL fgl_winquestion(vg_producto,'Seguro de ejecutar este proceso','No','Yes|No|Cancel','question',1)
	RETURNING resp
RETURN resp

END FUNCTION



FUNCTION fl_mensaje_arreglo_lleno()
DEFINE resp		CHAR(6)

CALL fgl_winmessage(vg_producto, 'Imposible crear nuevo registro, abandone y vuelva a ejecutar', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_arreglo_incompleto()
DEFINE resp		CHAR(6)

CALL fgl_winmessage(vg_producto, 'No se pudo cargar todo el detalle, corregir dimensión del arreglo', 'stop')

END FUNCTION


---- AYUDAS VARIAS PARA TALLER ----

FUNCTION fl_retorna_saldo_vencido(cod_cia, cod_cliente)
DEFINE cod_cia		LIKE cxct030.z30_compania
DEFINE cod_cliente	LIKE cxct030.z30_codcli
DEFINE saldo_vencido	LIKE cxct030.z30_saldo_venc		
DEFINE moneda		LIKE gent013.g13_moneda

LET saldo_vencido = 0
LET moneda        = NULL
DECLARE q_clivenc CURSOR FOR 
	SELECT z30_moneda, SUM(z30_saldo_venc)
		FROM cxct030
		WHERE z30_compania = cod_cia
	    	  AND z30_codcli   = cod_cliente
		GROUP BY 1
OPEN q_clivenc
FETCH q_clivenc INTO moneda, saldo_vencido
CLOSE q_clivenc
FREE q_clivenc
RETURN moneda, saldo_vencido

END FUNCTION



FUNCTION fl_muestra_repuestos_orden_trabajo(cod_cia, cod_loc, num_ot)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE num_ot, orden	LIKE talt023.t23_orden
DEFINE r_cab		RECORD LIKE rept019.*
DEFINE r_det		RECORD LIKE rept020.*
DEFINE r_item		RECORD LIKE rept010.*
DEFINE rot		RECORD LIKE talt023.*
DEFINE rfd		RECORD LIKE talt028.*
DEFINE num_rows		SMALLINT
DEFINE i, num_rep	SMALLINT
DEFINE campo_orden	SMALLINT
DEFINE tipo_orden	CHAR(4)
DEFINE query		VARCHAR(300)
DEFINE tot_bruto 	DECIMAL(12,2)
DEFINE tot_dscto 	DECIMAL(12,2)
DEFINE tot_neto  	DECIMAL(12,2)
DEFINE tot_impto	DECIMAL(12,2)

-- Modificado por JCM (DEIMOS) para controlar el problema causado por la 
-- version anterior de la base informix que no soporta operaciones o 
-- expresiones dentro de una sentencia INSERT. 
DEFINE valor_bruto	DECIMAL(12,2)

DEFINE r_rep  ARRAY [500] OF RECORD
	fecha		DATE,
	r20_cod_tran	LIKE rept020.r20_cod_tran,	
	r20_num_tran	LIKE rept020.r20_num_tran,	
	r20_item	LIKE rept020.r20_item,	
	r20_cant_ven	LIKE rept020.r20_cant_ven,	
	r20_precio	LIKE rept020.r20_precio,	
	subtotal	DECIMAL(14,2)
	END RECORD

LET num_rows = 500
OPEN WINDOW w_drot AT 6,4 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf300"
	ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
ERROR "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)
CALL fl_lee_orden_trabajo(cod_cia, cod_loc, num_ot) RETURNING rot.*
LET orden = num_ot
WHILE rot.t23_estado = 'D'
	INITIALIZE rfd.* TO NULL
	SELECT * INTO rfd.* FROM talt028
		WHERE t28_compania  = cod_cia AND 
	              t28_localidad = cod_loc AND
	              t28_ot_ant    = orden
	IF status = NOTFOUND THEN
		CALL fgl_winmessage(vg_producto, 'Factura está devuelta y no consta en talt028', 'exclamation')
		CLOSE WINDOW w_drot
		RETURN
	END IF
	CALL fl_lee_orden_trabajo(cod_cia, cod_loc, rfd.t28_ot_nue) RETURNING rot.*
	LET orden = rfd.t28_ot_nue
END WHILE
DISPLAY BY NAME num_ot
DECLARE q_crot CURSOR FOR 
	SELECT * FROM rept019
		WHERE r19_compania    = cod_cia AND
		      r19_localidad   = cod_loc AND  
		      r19_ord_trabajo = orden
CREATE TEMP TABLE temp_drep
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_cod_tran	CHAR(2),
	 te_num_tran	DECIMAL(15,0),
	 te_item	CHAR(15),
	 te_cant_ven	SMALLINT,
	 te_precio 	DECIMAL(14,2),
	 te_subtotal	DECIMAL(14,2))
LET i = 0
LET tot_bruto = 0
LET tot_dscto = 0
LET tot_impto = 0
LET tot_neto  = 0
FOREACH q_crot INTO r_cab.*
	IF rot.t23_estado = 'D' AND r_cab.r19_fecing > rfd.t28_fec_factura THEN
		CONTINUE FOREACH
	END IF
	LET i = i + 1
	IF r_cab.r19_tipo_tran = 'I' THEN
		LET r_cab.r19_tot_bruto = r_cab.r19_tot_bruto * -1
		LET r_cab.r19_tot_dscto = r_cab.r19_tot_dscto * -1
		LET r_cab.r19_tot_neto  = r_cab.r19_tot_neto  * -1
	END IF
	LET tot_bruto = tot_bruto + r_cab.r19_tot_bruto
	LET tot_dscto = tot_dscto + r_cab.r19_tot_dscto
	LET tot_impto = tot_impto + (r_cab.r19_tot_neto - 
			(r_cab.r19_tot_bruto - r_cab.r19_tot_dscto))
	LET tot_neto  = tot_neto  + r_cab.r19_tot_neto 
	DECLARE q_drot CURSOR FOR 
		SELECT * FROM rept020
		WHERE r20_compania    = r_cab.r19_compania  AND
		      r20_localidad   = r_cab.r19_localidad AND
		      r20_cod_tran    = r_cab.r19_cod_tran  AND
		      r20_num_tran    = r_cab.r19_num_tran
	FOREACH q_drot INTO r_det.*
		IF r_cab.r19_tipo_tran = 'I' THEN
			LET r_det.r20_cant_ven = r_det.r20_cant_ven * -1
		END IF
		LET valor_bruto = r_det.r20_precio * r_det.r20_cant_ven
		INSERT INTO temp_drep VALUES (r_cab.r19_fecing, 
			r_cab.r19_cod_tran, r_cab.r19_num_tran, r_det.r20_item,
		        r_det.r20_cant_ven, r_det.r20_precio, 
			valor_bruto)
	END FOREACH
END FOREACH
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_drep
	CLOSE WINDOW w_drot
	RETURN
END IF
DISPLAY 'Fecha'   TO tit_col1
DISPLAY 'Tp'      TO tit_col2
DISPLAY 'Número'  TO tit_col3
DISPLAY 'I t e m' TO tit_col4
DISPLAY 'Cant'    TO tit_col5
DISPLAY 'Precio'  TO tit_col6
DISPLAY 'Total'   TO tit_col7
LET campo_orden = 1
LET tipo_orden  = 'DESC' 
WHILE TRUE
	IF tipo_orden = 'DESC' THEN
		LET tipo_orden = 'ASC'
	ELSE
		LET tipo_orden = 'DESC'
	END IF
	LET query = 'SELECT * FROM temp_drep ORDER BY ', campo_orden, ' ',
			tipo_orden
	PREPARE tot FROM query
	DECLARE q_tot CURSOR FOR tot
	LET i = 1
	FOREACH q_tot INTO r_rep[i].*
		LET i = i + 1
	END FOREACH
	LET int_flag = 0
	DISPLAY BY NAME tot_bruto, tot_dscto, tot_neto, tot_impto,
			r_cab.r19_porc_impto
	LET num_rep = i - 1
	CALL set_count(num_rep)
	DISPLAY ARRAY r_rep TO r_rep.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			CALL fl_lee_item(cod_cia, r_rep[i].r20_item)
				RETURNING r_item.*
			MESSAGE i, ' de ', num_rep, '     ', r_item.r10_nombre
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F15)
			LET campo_orden = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET campo_orden = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET campo_orden = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET campo_orden = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET campo_orden = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET campo_orden = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET campo_orden = 7
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_drot
DROP TABLE temp_drep

END FUNCTION



FUNCTION fl_muestra_mano_obra_orden_trabajo(cod_cia, cod_loc, num_ot)
DEFINE cod_cia		LIKE talt024.t24_compania
DEFINE cod_loc		LIKE talt024.t24_localidad
DEFINE num_ot		LIKE talt024.t24_orden
DEFINE num_rows		SMALLINT
DEFINE i, j, num_mo	SMALLINT
DEFINE campo_orden	SMALLINT
DEFINE tipo_orden	CHAR(4)
DEFINE query		VARCHAR(300)
DEFINE tot_tareas	DECIMAL(12,2)
DEFINE r_mo  ARRAY [100] OF RECORD
	t24_descripcion	LIKE talt024.t24_descripcion,
	t24_puntos_opti	LIKE talt024.t24_puntos_opti,
	t24_puntos_real	LIKE talt024.t24_puntos_real,
	t24_valor_tarea	LIKE talt024.t24_valor_tarea
	END RECORD
DEFINE r_mo1  ARRAY [100] OF RECORD
	descri_tar	LIKE talt024.t24_descripcion,
	nombres		LIKE talt003.t03_nombres
	END RECORD

LET num_rows = 100
OPEN WINDOW w_dmo AT 6,2 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf301"
	ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
ERROR "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)
DISPLAY num_ot TO t24_orden
SELECT t24_codtarea, t24_descripcion, 
       t24_puntos_opti, t24_puntos_real, t24_valor_tarea,
       t24_secuencia, t24_mecanico, t24_ord_compra
	FROM talt024
	WHERE t24_compania  = cod_cia AND
	      t24_localidad = cod_loc AND  
	      t24_orden     = num_ot  AND
	      t24_valor_tarea > 0
	INTO TEMP temp_dmo
DELETE FROM temp_dmo WHERE t24_ord_compra IS NOT NULL
SELECT COUNT(*), SUM(t24_valor_tarea) INTO num_mo, tot_tareas FROM temp_dmo
IF num_mo = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_dmo
	CLOSE WINDOW w_dmo
	RETURN
END IF
DISPLAY 'Descripción'  TO tit_col1
DISPLAY 'T.Opt.'       TO tit_col2
DISPLAY 'T.Real'       TO tit_col3
DISPLAY 'Valor Tarea'  TO tit_col4
LET campo_orden = 5
LET tipo_orden  = 'DESC' 
WHILE TRUE
	IF tipo_orden = 'DESC' THEN
		LET tipo_orden = 'ASC'
	ELSE
		LET tipo_orden = 'DESC'
	END IF
	LET query = 'SELECT t24_descripcion, t24_puntos_opti, ',
			  ' t24_puntos_real, t24_valor_tarea, t24_secuencia, ',
			  ' t24_descripcion, t03_nombres ',
			  ' FROM temp_dmo, talt003 ',
			  ' WHERE t03_compania = ', cod_cia, 
			  ' AND   t03_mecanico = t24_mecanico ',
			  ' ORDER BY ', campo_orden, ' ', tipo_orden
	PREPARE dmo FROM query
	DECLARE q_dmo CURSOR FOR dmo
	LET i = 1
	FOREACH q_dmo INTO r_mo[i].*, j, r_mo1[i].*
		LET i = i + 1
	END FOREACH
	LET int_flag = 0
	DISPLAY BY NAME tot_tareas
	CALL set_count(num_mo)
	DISPLAY ARRAY r_mo TO r_mo.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_mo
			DISPLAY BY NAME r_mo1[i].*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F15)
			LET campo_orden = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET campo_orden = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET campo_orden = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET campo_orden = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET campo_orden = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET campo_orden = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET campo_orden = 7
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_dmo
DROP TABLE temp_dmo

END FUNCTION



FUNCTION fl_muestra_forma_pago_caja(codcia, codloc, areaneg, codcli, tip_doc, 
				 num_doc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tip_doc		LIKE cajt010.j10_tipo_destino
DEFINE num_doc		LIKE cajt010.j10_num_destino
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE r_cp		RECORD LIKE cajt010.*
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_pagc	ARRAY[20] OF RECORD
	j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
	nombre_bt	VARCHAR(20),
	j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
	j11_moneda	LIKE cajt011.j11_moneda,
	j11_valor	LIKE cajt011.j11_valor
	END RECORD

LET max_rows = 20
OPEN WINDOW w_pagc AT 6,10 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf302"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'TP'                  TO tit_col1 
DISPLAY 'Banco/Tarjeta'       TO tit_col2 
DISPLAY 'No. Cheque/Tarjeta'  TO tit_col3
DISPLAY 'Mo.'                 TO tit_col4 
DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe cliente: ' || codcli,
			    'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_nomcli
DISPLAY BY NAME tip_doc, num_doc
LET query = 'SELECT cajt010.*, cajt011.* FROM cajt010, cajt011 ' ||
		' WHERE j10_compania     = ? AND ' || 
	              ' j10_localidad    = ? AND ' ||
	      	      ' j10_areaneg      = ? AND ' ||
	      	      ' j10_tipo_destino = ? AND ' ||
	              ' j10_num_destino  = ? AND ' || 
	      	      ' j10_compania     = j11_compania  AND ' || 
	      	      ' j10_localidad    = j11_localidad AND ' ||
	      	      ' j10_tipo_fuente  = j11_tipo_fuente AND ' ||
	      	      ' j10_num_fuente   = j11_num_fuente '
PREPARE dpagc FROM query
DECLARE q_dpagc CURSOR FOR dpagc
LET i = 0
LET tot_pago = 0
OPEN q_dpagc USING codcia, codloc, areaneg, tip_doc, num_doc
WHILE TRUE
	FETCH q_dpagc INTO r_cp.*, r_dp.*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET i = i + 1
	CALL fl_lee_moneda(r_cp.j10_moneda) RETURNING r_mon.*
	DISPLAY r_mon.g13_nombre TO tit_mon
	DISPLAY r_cp.j10_valor TO tot_pago
	INITIALIZE r_pagc[i].* TO NULL	
	LET r_pagc[i].j11_codigo_pago	= r_dp.j11_codigo_pago
	LET r_pagc[i].j11_num_ch_aut	= r_dp.j11_num_ch_aut
	LET r_pagc[i].j11_moneda	= r_dp.j11_moneda
	LET r_pagc[i].j11_valor		= r_dp.j11_valor
	IF r_dp.j11_codigo_pago = 'CH' OR
		r_dp.j11_codigo_pago = 'DP' THEN
		SELECT g08_nombre INTO r_pagc[i].nombre_bt FROM gent008
			WHERE g08_banco = r_dp.j11_cod_bco_tarj
	END IF
 	IF r_dp.j11_codigo_pago = 'TJ' THEN
		SELECT g10_nombre INTO r_pagc[i].nombre_bt FROM gent010
			WHERE g10_tarjeta = r_dp.j11_cod_bco_tarj
	END IF
	IF i = max_rows THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE q_dpagc
FREE q_dpagc
LET num_rows = i
IF num_rows = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No hay registro de forma de pago en Caja', 'exclamation')
	CLOSE WINDOW w_pagc
	RETURN
END IF
LET int_flag = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_pagc TO r_pagc.*
	BEFORE ROW
		LET i = arr_curr()
		MESSAGE i, ' de ', num_rows
		IF tip_doc = 'PG' THEN
			CALL dialog.keysetlabel("F5","Doc.Cancelados")
		ELSE
			CALL dialog.keysetlabel("F5","")
		END IF
	BEFORE DISPLAY
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		IF tip_doc = 'PG' THEN
			CALL fl_muestra_detalle_pago_ingreso(codcia, codloc, 
				codcli, tip_doc, num_doc, r_cp.j10_moneda)
		END IF
END DISPLAY
CLOSE WINDOW w_pagc

END FUNCTION



FUNCTION fl_muestra_detalle_pago_ingreso(codcia, codloc, codcli, tipo_trn, num_trn,
				      moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_trn		LIKE cxct023.z23_tipo_trn
DEFINE num_trn		LIKE cxct023.z23_num_trn
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i, j	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_valor	DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE moneda        	LIKE gent013.g13_moneda
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_dpc	ARRAY[100] OF RECORD
	z23_tipo_doc	LIKE cxct023.z23_tipo_doc,
	z23_num_doc	LIKE cxct023.z23_num_doc, 
	z23_div_doc	LIKE cxct023.z23_div_doc,
	valor		DECIMAL(14,2)
	END RECORD

LET max_rows = 100
OPEN WINDOW w_dpc AT 5,10 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf303"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Tipo'                TO tit_col1 
DISPLAY 'No. Documento'       TO tit_col2 
DISPLAY 'Div'                 TO tit_col3
DISPLAY 'V a l o r'           TO tit_col4
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe cliente: ' || codcli,
			    'exclamation')
	CLOSE WINDOW w_dpc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_nomcli
DISPLAY BY NAME tipo_trn, num_trn
LET query = 'SELECT z23_tipo_doc, z23_num_doc, z23_div_doc, ' ||
		' z23_valor_cap + z23_valor_int, ' ||
		' z23_orden ' ||
		' FROM cxct023 ',
		' WHERE z23_compania     = ? AND ' || 
	              ' z23_localidad    = ? AND ' ||
	      	      ' z23_codcli       = ? AND ' ||
	      	      ' z23_tipo_trn     = ? AND ' ||
	              ' z23_num_trn      = ? ' ||
		' ORDER BY z23_orden'
PREPARE dpc FROM query
DECLARE q_dpc CURSOR FOR dpc
LET i = 1
LET tot_valor = 0
OPEN q_dpc USING codcia, codloc, codcli, tipo_trn, num_trn
WHILE TRUE
	FETCH q_dpc INTO r_dpc[i].*, j
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET tot_valor = tot_valor + r_dpc[i].valor
	CALL fl_lee_moneda(moneda) RETURNING r_mon.*
	DISPLAY r_mon.g13_nombre TO tit_mon
	LET i = i + 1
	IF i > max_rows THEN
		EXIT WHILE
	END IF
END WHILE
DISPLAY BY NAME tot_valor
LET i = i - 1
CLOSE q_dpc
FREE q_dpc
LET num_rows = i
IF num_rows = 0 THEN
	CALL fgl_winmessage(vg_producto, 'No hay detalle de documentos cancelados', 'exclamation')
	CLOSE WINDOW w_dpc
	RETURN
END IF
LET int_flag = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_dpc TO r_dpc.*
	BEFORE ROW
		LET i = arr_curr()
		MESSAGE i, ' de ', num_rows
	BEFORE DISPLAY
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY
CLOSE WINDOW w_dpc

END FUNCTION



FUNCTION fl_recalcula_saldos_clientes(codcia, codloc)
DEFINE codcia		LIKE cxct020.z20_compania
DEFINE codloc		LIKE cxct020.z20_localidad
DEFINE codcli		LIKE cxct020.z20_codcli

BEGIN WORK
UPDATE cxct030
	SET z30_saldo_venc  = 0, 
	    z30_saldo_xvenc = 0, 
	    z30_saldo_favor = 0
	WHERE z30_compania  = codcia AND
	      z30_localidad = codloc
DECLARE qu_tintin CURSOR FOR 
	SELECT UNIQUE z20_codcli FROM cxct020
		WHERE z20_compania  = codcia AND
	      	      z20_localidad = codloc AND
	      	      z20_saldo_cap + z20_saldo_int > 0
	UNION
	SELECT UNIQUE z21_codcli FROM cxct021
		WHERE z21_compania  = codcia AND
	      	      z21_localidad = codloc AND
	      	      z21_saldo > 0
FOREACH qu_tintin INTO codcli
	CALL fl_genera_saldos_cliente(codcia, codloc, codcli)
END FOREACH
COMMIT WORK

END FUNCTION



FUNCTION fl_genera_saldos_cliente(codcia, codloc, codcli)
DEFINE codcia		LIKE cxct020.z20_compania
DEFINE codloc		LIKE cxct020.z20_localidad
DEFINE codcli		LIKE cxct020.z20_codcli
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE moneda		LIKE cxct020.z20_moneda
DEFINE r		RECORD LIKE cxct030.*
DEFINE rd		RECORD LIKE cxct020.*
DEFINE rg		RECORD LIKE gent000.*
DEFINE valor		DECIMAL(14,2)
DEFINE vencido		DECIMAL(14,2)
DEFINE pvencer		DECIMAL(14,2)
DEFINE i		SMALLINT

UPDATE cxct030
	SET z30_saldo_venc  = 0, 
	    z30_saldo_xvenc = 0, 
	    z30_saldo_favor = 0
	WHERE z30_compania  = codcia AND
	      z30_localidad = codloc AND
	      z30_codcli    = codcli 

DECLARE q_acdo CURSOR FOR SELECT * FROM cxct020
	WHERE z20_compania  = codcia AND
	      z20_localidad = codloc AND
	      z20_codcli    = codcli AND
	      z20_saldo_cap + z20_saldo_int > 0
LET i = 0
FOREACH q_acdo INTO rd.*
	LET i = i + 1
	LET pvencer = rd.z20_saldo_cap + rd.z20_saldo_int
	LET vencido = 0
	IF rd.z20_fecha_vcto - TODAY < 0 THEN
		LET vencido = rd.z20_saldo_cap + rd.z20_saldo_int
		LET pvencer = 0
	END IF
	CALL fl_lee_resumen_saldo_cliente(codcia, codloc, rd.z20_areaneg, 
			rd.z20_codcli, rd.z20_moneda)
		RETURNING r.*
	IF r.z30_compania IS NULL THEN
		INSERT INTO cxct030 VALUES (rd.z20_compania, rd.z20_localidad, 
			rd.z20_areaneg, rd.z20_codcli, rd.z20_moneda, 
			vencido, pvencer, 0)
	ELSE
		UPDATE cxct030 SET z30_saldo_xvenc = z30_saldo_xvenc + pvencer,
				   z30_saldo_venc  = z30_saldo_venc  + vencido
			WHERE z30_compania  = codcia AND
		              z30_localidad = codloc AND
		              z30_areaneg   = rd.z20_areaneg AND
		              z30_codcli    = codcli AND
		              z30_moneda    = rd.z20_moneda
	END IF
END FOREACH
DECLARE q_dant CURSOR FOR SELECT z21_areaneg, z21_moneda, SUM(z21_saldo)
	FROM cxct021
	WHERE z21_compania  = codcia AND
	      z21_localidad = codloc AND
	      z21_codcli    = codcli 
	GROUP BY 1,2
FOREACH q_dant INTO areaneg, moneda, valor
	LET i = i + 1
	CALL fl_lee_resumen_saldo_cliente(codcia, codloc, areaneg, 
					  codcli, moneda)
		RETURNING r.*
	IF r.z30_compania IS NULL THEN
		INSERT INTO cxct030 VALUES (codcia, codloc, areaneg, codcli, 
					    moneda, 0, 0, valor)
	ELSE
		UPDATE cxct030 SET z30_saldo_favor = valor
			WHERE z30_compania  = codcia AND
		              z30_localidad = codloc AND
		              z30_areaneg   = areaneg AND
		              z30_codcli    = codcli AND
		              z30_moneda    = moneda
	END IF
END FOREACH
IF i = 0 THEN
	CALL fl_lee_configuracion_facturacion() RETURNING rg.*
	CALL fl_lee_resumen_saldo_cliente(codcia, codloc, 1, 
					  codcli, rg.g00_moneda_base)
		RETURNING r.*
	IF r.z30_compania IS NULL THEN
		INSERT INTO cxct030 VALUES (codcia, codloc, 1, codcli, 
					    rg.g00_moneda_base, 0, 0, 0)
	END IF
END IF

END FUNCTION



FUNCTION fl_recalcula_saldos_proveedores(codcia, codloc)
DEFINE codcia		LIKE cxpt020.p20_compania
DEFINE codloc		LIKE cxpt020.p20_localidad
DEFINE codprov		LIKE cxpt020.p20_codprov

BEGIN WORK
UPDATE cxpt030
	SET p30_saldo_venc  = 0, 
	    p30_saldo_xvenc = 0, 
	    p30_saldo_favor = 0
	WHERE p30_compania  = codcia AND
	      p30_localidad = codloc
DECLARE qu_guachaso CURSOR FOR 
	SELECT UNIQUE p20_codprov FROM cxpt020
		WHERE p20_compania  = codcia AND
	      	      p20_localidad = codloc AND
	      	      p20_saldo_cap + p20_saldo_int > 0
	UNION
	SELECT UNIQUE p21_codprov FROM cxpt021
		WHERE p21_compania  = codcia AND
	      	      p21_localidad = codloc AND
	      	      p21_saldo > 0
FOREACH qu_guachaso INTO codprov
	CALL fl_genera_saldos_proveedor(codcia, codloc, codprov)
END FOREACH
COMMIT WORK

END FUNCTION



FUNCTION fl_genera_saldos_proveedor(codcia, codloc, codprov)
DEFINE codcia		LIKE cxpt020.p20_compania
DEFINE codloc		LIKE cxpt020.p20_localidad
DEFINE codprov		LIKE cxpt020.p20_codprov
DEFINE moneda		LIKE cxpt020.p20_moneda
DEFINE r		RECORD LIKE cxpt030.*
DEFINE rg		RECORD LIKE gent000.*
DEFINE i		SMALLINT
DEFINE rd		RECORD LIKE cxpt020.*
DEFINE valor		DECIMAL(14,2)
DEFINE vencido		DECIMAL(14,2)
DEFINE pvencer		DECIMAL(14,2)

UPDATE cxpt030
	SET p30_saldo_venc  = 0, 
	    p30_saldo_xvenc = 0, 
	    p30_saldo_favor = 0
	WHERE p30_compania  = codcia AND
	      p30_localidad = codloc AND
	      p30_codprov   = codprov 
DECLARE q_docp CURSOR FOR SELECT * FROM cxpt020
	WHERE p20_compania  = codcia AND
	      p20_localidad = codloc AND
	      p20_codprov   = codprov AND
	      p20_saldo_cap + p20_saldo_int > 0
LET i = 0
FOREACH q_docp INTO rd.*
	LET i = i + 1
	LET pvencer = rd.p20_saldo_cap + rd.p20_saldo_int
	LET vencido = 0
	IF rd.p20_fecha_vcto - TODAY < 0 THEN
		LET vencido = rd.p20_saldo_cap + rd.p20_saldo_int
		LET pvencer = 0
	END IF
	CALL fl_lee_resumen_saldo_proveedor(codcia, codloc, rd.p20_codprov, 
		rd.p20_moneda) RETURNING r.*
	IF r.p30_compania IS NULL THEN
		INSERT INTO cxpt030 VALUES (rd.p20_compania, rd.p20_localidad, 
			rd.p20_codprov, rd.p20_moneda, vencido, pvencer, 0)
	ELSE
		UPDATE cxpt030 SET p30_saldo_xvenc = p30_saldo_xvenc + pvencer,
				   p30_saldo_venc  = p30_saldo_venc  + vencido
			WHERE p30_compania  = codcia AND
		              p30_localidad = codloc AND
		              p30_codprov   = codprov AND
		              p30_moneda    = rd.p20_moneda
	END IF
END FOREACH
DECLARE q_antp CURSOR FOR SELECT p21_moneda, SUM(p21_saldo)
	FROM cxpt021
	WHERE p21_compania  = codcia AND
	      p21_localidad = codloc AND
	      p21_codprov   = codprov 
	GROUP BY 1
FOREACH q_antp INTO moneda, valor
	LET i = i + 1
	CALL fl_lee_resumen_saldo_proveedor(codcia, codloc, codprov, moneda)
		RETURNING r.*
	IF r.p30_compania IS NULL THEN
		INSERT INTO cxpt030 VALUES (codcia, codloc, codprov, moneda, 0,
					    0, valor)
	ELSE
		UPDATE cxpt030 SET p30_saldo_favor = valor
			WHERE p30_compania  = codcia AND
		              p30_localidad = codloc AND
		              p30_codprov   = codprov AND
		              p30_moneda    = moneda
	END IF
END FOREACH
IF i = 0 THEN
	CALL fl_lee_configuracion_facturacion() RETURNING rg.*
	CALL fl_lee_resumen_saldo_proveedor(codcia, codloc, codprov, 
		rg.g00_moneda_base) RETURNING r.*
	IF r.p30_compania IS NULL THEN
		INSERT INTO cxpt030 VALUES (codcia, codloc, codprov, 
				    rg.g00_moneda_base, 0, 0, 0)
	END IF
END IF

END FUNCTION



FUNCTION fl_aplica_documento_favor(cod_cia, cod_loc, codcli, tipo_favor, 
	 num_favor, valor_favor, moneda,areaneg, cod_tran, num_tran)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_compania
DEFINE codcli		LIKE cxct020.z20_codcli
DEFINE tipo_favor	LIKE cxct021.z21_tipo_doc
DEFINE num_favor	LIKE cxct021.z21_num_doc
DEFINE valor_favor	LIKE cxct021.z21_valor
DEFINE cod_tran		LIKE cxct020.z20_cod_tran
DEFINE num_tran		LIKE cxct020.z20_num_tran
DEFINE moneda		LIKE cxct020.z20_moneda
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_caju		RECORD LIKE cxct022.*
DEFINE r_daju		RECORD LIKE cxct023.*
DEFINE r		RECORD LIKE gent014.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE i		SMALLINT
DEFINE num_row		INTEGER
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)

DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxct020 WHERE z20_compania  = cod_cia AND 
	                            z20_localidad = cod_loc AND 
	                            z20_areaneg   = areaneg AND 
	                            z20_cod_tran  = cod_tran AND 
	                            z20_num_tran  = num_tran AND
				    z20_saldo_cap + z20_saldo_int > 0
		FOR UPDATE
INITIALIZE r_doc.* TO NULL
OPEN q_ddev
FETCH q_ddev INTO r_doc.*
CLOSE q_ddev
IF r_doc.z20_codcli IS NOT NULL AND r_doc.z20_codcli <> codcli THEN
	RETURN 0
END IF
INITIALIZE r_caju.* TO NULL
LET r_caju.z22_compania 	= cod_cia
LET r_caju.z22_localidad 	= cod_loc
LET r_caju.z22_codcli 		= codcli
LET r_caju.z22_tipo_trn 	= 'AJ'
LET r_caju.z22_num_trn 		= fl_actualiza_control_secuencias(cod_cia, 
				  cod_loc, 'CO', 'AA', 'AJ')
IF r_caju.z22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_caju.z22_areaneg 		= areaneg
LET r_caju.z22_referencia 	= 'DEV. FACT.: ', cod_tran, ' ', num_tran
LET r_caju.z22_fecha_emi 	= TODAY
LET r_caju.z22_moneda 		= moneda
LET r_caju.z22_paridad 	= 1
IF r_caju.z22_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_caju.z22_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 'No hay factor de conversión','stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_caju.z22_paridad 	= r.g14_tasa
END IF	
LET r_caju.z22_tasa_mora 	= 0
LET r_caju.z22_total_cap 	= 0
LET r_caju.z22_total_int 	= 0
LET r_caju.z22_total_mora	= 0
LET r_caju.z22_cobrador 	= NULL
LET r_caju.z22_subtipo 		= NULL
LET r_caju.z22_origen 		= 'A'
LET r_caju.z22_fecha_elim 	= NULL
LET r_caju.z22_tiptrn_elim 	= NULL
LET r_caju.z22_numtrn_elim 	= NULL
LET r_caju.z22_usuario 		= vg_usuario
LET r_caju.z22_fecing 		= CURRENT
INSERT INTO cxct022 VALUES (r_caju.*)
LET num_row = SQLCA.SQLERRD[6]
LET i = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_doc.*
	LET valor_aplicar = valor_favor - valor_aplicado
	IF valor_aplicar = 0 THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
	LET aplicado_cap  = 0
	LET aplicado_int  = 0
	IF r_doc.z20_saldo_int <= valor_aplicar THEN
		LET aplicado_int = r_doc.z20_saldo_int 
	ELSE
		LET aplicado_int = valor_aplicar
	END IF
	LET valor_aplicar = valor_aplicar - aplicado_int
	IF r_doc.z20_saldo_cap <= valor_aplicar THEN
		LET aplicado_cap = r_doc.z20_saldo_cap 
	ELSE
		LET aplicado_cap = valor_aplicar
	END IF
	LET valor_aplicado = valor_aplicado + aplicado_cap + aplicado_int
	LET r_caju.z22_total_cap        = r_caju.z22_total_cap + 
					  (aplicado_cap * -1)
	LET r_caju.z22_total_int        = r_caju.z22_total_int + 
					  (aplicado_int * -1)
    	LET r_daju.z23_compania 	= cod_cia
    	LET r_daju.z23_localidad 	= cod_loc
    	LET r_daju.z23_codcli 		= r_caju.z22_codcli
    	LET r_daju.z23_tipo_trn 	= r_caju.z22_tipo_trn
    	LET r_daju.z23_num_trn  	= r_caju.z22_num_trn
    	LET r_daju.z23_orden 		= i
    	LET r_daju.z23_areaneg 		= r_caju.z22_areaneg
    	LET r_daju.z23_tipo_doc 	= r_doc.z20_tipo_doc
    	LET r_daju.z23_num_doc 	        = r_doc.z20_num_doc
    	LET r_daju.z23_div_doc 		= r_doc.z20_dividendo
    	LET r_daju.z23_tipo_favor 	= tipo_favor
    	LET r_daju.z23_doc_favor 	= num_favor
    	LET r_daju.z23_valor_cap 	= aplicado_cap * -1
    	LET r_daju.z23_valor_int 	= aplicado_int * -1
    	LET r_daju.z23_valor_mora 	= 0
    	LET r_daju.z23_saldo_cap 	= r_doc.z20_saldo_cap
    	LET r_daju.z23_saldo_int	= r_doc.z20_saldo_int
	INSERT INTO cxct023 VALUES (r_daju.*)
	UPDATE cxct020 SET z20_saldo_cap = z20_saldo_cap - aplicado_cap,
	                   z20_saldo_int = z20_saldo_int - aplicado_int
		WHERE CURRENT OF q_ddev
END FOREACH
IF i = 0 THEN
	DELETE FROM cxct022 WHERE ROWID = num_row
	UPDATE gent015 SET g15_numero = g15_numero - 1
			WHERE CURRENT OF q_csec
ELSE
	UPDATE cxct022 SET z22_total_cap = r_caju.z22_total_cap,
	                   z22_total_int = r_caju.z22_total_int
		WHERE ROWID = num_row
END IF
FREE q_ddev
RETURN valor_aplicado

END FUNCTION



FUNCTION fl_control_reportes()
DEFINE tit_impresion	CHAR(1)
DEFINE r_gen		RECORD LIKE gent007.*
DEFINE r_gen2		RECORD LIKE gent006.*
DEFINE codi_aux		LIKE gent006.g06_impresora
DEFINE nomi_aux		LIKE gent006.g06_nombre
DEFINE comando		VARCHAR(100)


OPEN WINDOW w_for AT 04, 11
        WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf304"
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
INITIALIZE codi_aux, comando TO NULL
LET tit_impresion = 'P'
LET int_flag = 0
INPUT BY NAME tit_impresion, r_gen.g07_impresora
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(g07_impresora) THEN
               		CALL fl_ayuda_impresoras()
                       		RETURNING codi_aux, nomi_aux
       		      	LET int_flag = 0
                      	IF codi_aux IS NOT NULL THEN
                              	LET r_gen.g07_impresora = codi_aux
                               	DISPLAY BY NAME r_gen.g07_impresora
                               	DISPLAY nomi_aux TO g06_nombre
                       	END IF
                END IF
	AFTER FIELD tit_impresion
		IF tit_impresion <> 'I' THEN
			EXIT INPUT
		END IF
	AFTER FIELD g07_impresora
		IF r_gen.g07_impresora IS NOT NULL THEN
			CALL fl_lee_impresora(r_gen.g07_impresora)
				RETURNING r_gen2.*
			IF r_gen2.g06_impresora IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Impresora no existe.','exclamation')
				NEXT FIELD g07_impresora
			END IF
			DISPLAY BY NAME r_gen2.g06_nombre
		ELSE
			CLEAR g06_nombre
		END IF
	AFTER INPUT
		IF tit_impresion = 'I' THEN
			IF r_gen.g07_impresora IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Escoja una Impresora.','exclamation')
				NEXT FIELD g07_impresora
			END IF
		END IF
END INPUT
IF NOT int_flag THEN
	IF tit_impresion = 'I' THEN
		LET comando = 'lpr -P ', r_gen.g07_impresora
	END IF
	IF tit_impresion = 'P' THEN
		LET comando = 'fglpager'
	END IF
	IF tit_impresion = 'A' THEN
		INITIALIZE r_gen2.g06_nombre TO NULL
		OPTIONS INPUT NO WRAP
		INPUT BY NAME r_gen2.g06_nombre
		LET comando = 'cat > ', vg_dir_fobos CLIPPED, vg_separador, 
                                        'reports', vg_separador, 
                                        r_gen2.g06_nombre, '.wri'
	END IF
END IF
CLOSE WINDOW w_for
RETURN comando

END FUNCTION



FUNCTION fl_obtiene_costo_item(cod_cia, moneda, item, cant_ing, costo_ing)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE item		LIKE rept010.r10_codigo
DEFINE cant_ing		INTEGER
DEFINE stock		INTEGER
DEFINE costo_ing	DECIMAL(12,2)
DEFINE costo_act	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_art		RECORD LIKE rept010.*

CALL fl_lee_compania_repuestos(cod_cia) RETURNING r_rep.*
IF r_rep.r00_tipo_costo <> 'P' THEN
	RETURN costo_ing
END IF
SELECT SUM(r11_stock_act) INTO stock FROM rept011 
 WHERE r11_compania  = cod_cia
   AND r11_item      = item
IF stock IS NULL THEN
	LET stock = 0
END IF
{*
 * El stock que se obtiene aqui incluye lo que se esta liquidando
 * porque ya fue recibido.
 * Por ahora si el stock es menor a lo que se esta liquidando entonces
 * se asume cero, de lo contrario se resta. Luego debo verificar los efectos
 * y posiblemente pensarlo mejor.
 *}
IF stock <= cant_ing THEN
	LET stock = 0
ELSE
	LET stock = stock - cant_ing
END IF

CALL fl_lee_item(cod_cia, item) RETURNING r_art.*
IF moneda = rg_gen.g00_moneda_base THEN
	LET costo_act = r_art.r10_costo_mb
ELSE
	LET costo_act = r_art.r10_costo_ma
END IF
LET costo_nue = ((costo_act * stock) + (costo_ing * cant_ing)) / 
		 (stock + cant_ing)
CALL fl_retorna_precision_valor(moneda, costo_nue) RETURNING costo_nue
RETURN costo_nue

END FUNCTION



FUNCTION fl_retorna_letras(moneda, valor)
DEFINE moneda		CHAR(2)
DEFINE valor		DECIMAL(12,2)
DEFINE entero		DECIMAL(10,0)
DEFINE centavos		DECIMAL(2,0)
DEFINE j, k, l, m	SMALLINT
DEFINE renglon		VARCHAR(150)

CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
SELECT TRUNC(valor,0) INTO entero FROM dual
LET centavos = (valor - entero) * 100
CALL fl_algoritmo_conversion_letras(moneda, entero) RETURNING renglon
IF moneda = rg_gen.g00_moneda_base THEN
	LET renglon = renglon CLIPPED, " CON ", centavos USING "&&", " CENTAVOS" 
ELSE
	LET renglon = renglon CLIPPED, ", ", centavos USING "&&", " CENTS" 
END IF
RETURN renglon

END FUNCTION 



FUNCTION fl_algoritmo_conversion_letras(moneda, valor)
DEFINE moneda		CHAR(2)
DEFINE valor		DECIMAL(14,2)
DEFINE valor_char	VARCHAR(15)
DEFINE base_1		CHAR(3)
DEFINE base_2		CHAR(3)
DEFINE base_3		CHAR(3)
DEFINE base_4		CHAR(3)
DEFINE i, k		SMALLINT
DEFINE renglon		VARCHAR(150)

IF valor = 0 THEN
	IF moneda = rg_gen.g00_moneda_base THEN
		LET renglon = "CERO"
	ELSE
		LET renglon = "ZERO"
	END IF
	RETURN renglon
END IF
CALL fl_carga_letras(moneda)
LET renglon    = NULL
LET valor_char = valor USING "&&&&&&&&&&&&.&&"
LET base_1     = valor_char[1,3]
LET base_2     = valor_char[4,6]
LET base_3     = valor_char[7,9]
LET base_4     = valor_char[10,12]
IF base_1 <> "000" THEN
	CALL fl_base_letras(moneda, 0, base_1, renglon) RETURNING renglon
	IF moneda = rg_gen.g00_moneda_base THEN
		LET renglon = renglon CLIPPED, " MIL"
	ELSE
		LET renglon = renglon CLIPPED, " THOUSAND"
	END IF
END IF
IF base_2 <> "000" THEN
	CALL fl_base_letras(moneda, 1, base_2, renglon) RETURNING renglon
	IF moneda = rg_gen.g00_moneda_base THEN
		IF renglon CLIPPED = " UN" THEN
			LET renglon = renglon CLIPPED, " MILLON"
		ELSE
			LET renglon = renglon CLIPPED, " MILLONES"
		END IF
	ELSE
		LET renglon = renglon CLIPPED, " MILLION"
	END IF	
END IF
IF base_3 <> "000" THEN
	CALL fl_base_letras(moneda, 2, base_3, renglon) RETURNING renglon
	IF moneda = rg_gen.g00_moneda_base THEN
		LET renglon = renglon CLIPPED, " MIL"
	ELSE
		LET renglon = renglon CLIPPED, " THOUSAND"
	END IF
END IF
IF base_4 <> "000" THEN
	CALL fl_base_letras(moneda, 3, base_4, renglon)
		RETURNING renglon
END IF
RETURN renglon

END FUNCTION



FUNCTION fl_base_letras(moneda, pos_base, porcion, renglon)
DEFINE moneda		CHAR(2)
DEFINE porcion		CHAR(3)
DEFINE pos_base, last_2	SMALLINT
DEFINE pos1, pos2, pos3	SMALLINT
DEFINE valor_str	CHAR(25)
DEFINE renglon		VARCHAR(150)

LET last_2 = porcion[2,3]
LET pos1 = porcion[1,1]
LET pos2 = porcion[2,2]
LET pos3 = porcion[3,3]
IF pos2 = 0 AND pos3 = 0 AND pos1 = 1 THEN
	IF moneda = rg_gen.g00_moneda_base THEN
		LET renglon = renglon CLIPPED, " CIEN"
	ELSE
		LET renglon = renglon CLIPPED, " ONE HUNDRED"
	END IF		
	RETURN renglon
END IF
IF pos1 <> 0 THEN
	LET valor_str = ag_five[pos1]
	LET renglon = renglon CLIPPED, " ", valor_str
	IF pos2 = 0 AND pos3 = 0 THEN
		RETURN renglon
	END IF
END IF
IF last_2 = 1 AND pos_base = 3 THEN
	IF moneda = rg_gen.g00_moneda_base THEN
		LET renglon = renglon CLIPPED, " UNO"
	ELSE
		LET renglon = renglon CLIPPED, " ONE"
	END IF
	RETURN renglon
END IF
IF last_2 = 21 AND pos_base <> 3 THEN
	IF moneda = rg_gen.g00_moneda_base THEN
		LET renglon = renglon CLIPPED, " ", "VEINTIUN"
	ELSE
		LET renglon = renglon CLIPPED, " ", "TWENTY-ONE"
	END IF
	RETURN renglon
END IF
IF pos2 = 2 AND pos3 <> 0 THEN
	LET valor_str = ag_four[pos3]
	LET renglon = renglon CLIPPED, " ", valor_str
ELSE
	IF pos2 = 0 THEN
		LET valor_str = ag_one[pos3]
		LET renglon = renglon CLIPPED, " ", valor_str
	ELSE
		IF pos2 <> 0 AND pos3 = 0 THEN
			LET valor_str = ag_three[pos2]
			LET renglon = renglon CLIPPED, " ", valor_str
		ELSE
			IF pos2 = 1 AND pos3 <> 0 THEN
				LET valor_str = ag_two[pos3]
				LET renglon = renglon CLIPPED, " ", valor_str
			ELSE
				LET valor_str = ag_three[pos2]
				LET renglon = renglon CLIPPED, " ",valor_str CLIPPED
				IF moneda = rg_gen.g00_moneda_base THEN
					LET renglon = renglon CLIPPED, " Y "
				END IF
				IF pos3 = 1 AND pos_base = 3 THEN
					IF moneda = rg_gen.g00_moneda_base THEN
						LET valor_str = "UNO"
					ELSE			
						LET valor_str = "ONE"
					END IF
				ELSE
					LET valor_str = ag_one[pos3]
				END IF
				LET renglon = renglon CLIPPED, " ", valor_str
			END IF
		END IF
	END IF
END IF
RETURN renglon

END FUNCTION



FUNCTION fl_carga_letras(moneda)
DEFINE moneda		CHAR(2)

IF moneda = rg_gen.g00_moneda_base THEN
	LET ag_one[1] = "UN"
	LET ag_one[2] = "DOS"
	LET ag_one[3] = "TRES"
	LET ag_one[4] = "CUATRO"
	LET ag_one[5] = "CINCO"
	LET ag_one[6] = "SEIS"
	LET ag_one[7] = "SIETE"
	LET ag_one[8] = "OCHO"
	LET ag_one[9] = "NUEVE"

	LET ag_two[1] = "ONCE"
	LET ag_two[2] = "DOCE"
	LET ag_two[3] = "TRECE"
	LET ag_two[4] = "CATORCE"
	LET ag_two[5] = "QUINCE"
	LET ag_two[6] = "DIECISEIS"
	LET ag_two[7] = "DIECISIETE"
	LET ag_two[8] = "DIECIOCHO"
	LET ag_two[9] = "DIECINUEVE"
	
	LET ag_three[1] = "DIEZ"
	LET ag_three[2] = "VEINTE"
	LET ag_three[3] = "TREINTA"
	LET ag_three[4] = "CUARENTA"
	LET ag_three[5] = "CINCUENTA"
	LET ag_three[6] = "SESENTA"
	LET ag_three[7] = "SETENTA"
	LET ag_three[8] = "OCHENTA"
	LET ag_three[9] = "NOVENTA"
	
	LET ag_four[1] = "VEINTIUNO"
	LET ag_four[2] = "VEINTIDOS"
	LET ag_four[3] = "VEINTITRES"
	LET ag_four[4] = "VEINTICUATRO"
	LET ag_four[5] = "VEINTICINCO"
	LET ag_four[6] = "VEINTISEIS"
	LET ag_four[7] = "VEINTISIETE"
	LET ag_four[8] = "VEINTIOCHO"
	LET ag_four[9] = "VEINTINUEVE"

	LET ag_five[1] = "CIENTO"
	LET ag_five[2] = "DOSCIENTOS"
	LET ag_five[3] = "TRESCIENTOS"
	LET ag_five[4] = "CUATROCIENTOS"
	LET ag_five[5] = "QUINIENTOS"
	LET ag_five[6] = "SEISCIENTOS"
	LET ag_five[7] = "SETECIENTOS"
	LET ag_five[8] = "OCHOCIENTOS"
	LET ag_five[9] = "NOVECIENTOS"
ELSE
	LET ag_one[1] = "ONE"
	LET ag_one[2] = "TWO"
	LET ag_one[3] = "THREE"
	LET ag_one[4] = "FOUR"
	LET ag_one[5] = "FIVE"
	LET ag_one[6] = "SIX"
	LET ag_one[7] = "SEVEN"
	LET ag_one[8] = "EIGHT"
	LET ag_one[9] = "NINE"

	LET ag_two[1] = "ELEVEN"
	LET ag_two[2] = "TWELVE"
	LET ag_two[3] = "THIRTEEN"
	LET ag_two[4] = "FOURTEEN"
	LET ag_two[5] = "FITTEEN"
	LET ag_two[6] = "SIXTEEN"
	LET ag_two[7] = "SEVENTEEN"
	LET ag_two[8] = "EIGHTTEEN"
	LET ag_two[9] = "NINETEEN"
	
	LET ag_three[1] = "TEN"
	LET ag_three[2] = "TWENTY"
	LET ag_three[3] = "THIRTY"
	LET ag_three[4] = "FORTY"
	LET ag_three[5] = "FIFTY"
	LET ag_three[6] = "SIXTY"
	LET ag_three[7] = "SEVENTY"
	LET ag_three[8] = "EIGHTY"
	LET ag_three[9] = "NINETY"
	
	LET ag_four[1] = "TWENTY-ONE"
	LET ag_four[2] = "TWENTY-TWO"
	LET ag_four[3] = "TWENTY-THREE"
	LET ag_four[4] = "TWENTY-FOUR"
	LET ag_four[5] = "TWENTY-FIVE"
	LET ag_four[6] = "TWENTY-SIX"
	LET ag_four[7] = "TWENTY-SEVEN"
	LET ag_four[8] = "TWENTY-EIGHT"
	LET ag_four[9] = "TWENTY-NINE"

	LET ag_five[1] = "ONE HUNDRED"
	LET ag_five[2] = "TWO HUNDRED"
	LET ag_five[3] = "THREE HUNDRED"
	LET ag_five[4] = "FOUR HUNDRED"
	LET ag_five[5] = "FIVE HUNDRED"
	LET ag_five[6] = "SIX HUNDRED"
	LET ag_five[7] = "SEVEN HUNDRED"
	LET ag_five[8] = "EIGHT HUNDRED"
	LET ag_five[9] = "NINE HUNDRED"
END IF

END FUNCTION



FUNCTION fl_recalcula_valores_ot(cod_cia, cod_loc, orden)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE orden		LIKE talt023.t23_orden
DEFINE r		RECORD LIKE talt023.*
DEFINE rc		RECORD LIKE ordt010.*
DEFINE rp		RECORD LIKE cxpt002.*
DEFINE rt		RECORD LIKE ordt001.*
DEFINE tipo		LIKE ordt011.c11_tipo
DEFINE valor		DECIMAL(14,2)
DEFINE val_rep		DECIMAL(14,2)
DEFINE val_mo		DECIMAL(14,2)

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE cu_blot CURSOR FOR 
	SELECT * FROM talt023
		WHERE t23_compania  = cod_cia AND 
	              t23_localidad = cod_loc AND 
	              t23_orden     = orden
		FOR UPDATE
OPEN cu_blot
FETCH cu_blot INTO r.*
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No existe O.T. ' || orden, 'stop')
	RETURN
END IF
IF status < 0 THEN
	CALL fgl_winmessage(vg_producto, 'Otro proceso tiene bloqueada ' ||
					 'a la O.T. ' || orden, 'stop')
	RETURN
END IF
WHENEVER ERROR STOP
IF r.t23_estado <> 'A' AND r.t23_estado <> 'C' THEN
	RETURN
END IF
LET r.t23_val_mo_tal = 0
LET r.t23_val_mo_ext = 0
LET r.t23_val_mo_cti = 0
LET r.t23_val_rp_tal = 0
LET r.t23_val_rp_ext = 0
LET r.t23_val_rp_cti = 0
LET r.t23_val_rp_alm = 0
LET r.t23_val_otros1 = 0
--LET r.t23_val_otros2 = 0
SELECT SUM(t24_valor_tarea) INTO r.t23_val_mo_tal FROM talt024
	WHERE t24_compania  = cod_cia AND 
	      t24_localidad = cod_loc AND 
	      t24_orden     = orden   AND	
	      t24_paga_clte = 'S'
IF r.t23_val_mo_tal IS NULL THEN
	LET r.t23_val_mo_tal = 0
END IF
DECLARE cu_derep CURSOR FOR 
	SELECT r19_tipo_tran, SUM(r19_tot_bruto - r19_tot_dscto)
	FROM rept019
	WHERE r19_compania    = cod_cia AND 
	      r19_localidad   = cod_loc AND 
	      r19_ord_trabajo = orden   
	GROUP BY 1
FOREACH cu_derep INTO tipo, valor
	IF tipo = 'I' THEN
		LET valor = valor * -1
	END IF
	LET r.t23_val_rp_alm = r.t23_val_rp_alm + valor
END FOREACH
DECLARE cu_oc CURSOR FOR SELECT * FROM ordt010
	WHERE c10_compania    = cod_cia AND
	      c10_localidad   = cod_loc AND 
	      c10_ord_trabajo = orden
FOREACH cu_oc INTO rc.*
	IF rc.c10_estado <> 'C' THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_tipo_orden_compra(rc.c10_tipo_orden) RETURNING rt.*
	DECLARE cu_doc CURSOR FOR 
	SELECT c11_tipo, SUM((c11_cant_ped * c11_precio) - c11_val_descto)
		FROM ordt011
		WHERE c11_compania  = rc.c10_compania  AND 
		      c11_localidad = rc.c10_localidad AND 
		      c11_numero_oc = rc.c10_numero_oc
		GROUP BY 1
	LET val_rep = 0
	LET val_mo  = 0
	FOREACH cu_doc INTO tipo, valor
		IF tipo = 'B' THEN
			LET val_rep = valor
		ELSE
			LET val_mo  = valor
		END IF
	END FOREACH
	LET val_rep = val_rep + (val_rep * rc.c10_recargo / 100)
	LET val_rep = fl_retorna_precision_valor(rc.c10_moneda, val_rep)
	LET val_mo  = val_mo  + (val_mo  * rc.c10_recargo / 100)
	LET val_mo  = fl_retorna_precision_valor(rc.c10_moneda, val_mo)
	IF rt.c01_bien_serv = 'B' THEN
		LET r.t23_val_rp_tal = r.t23_val_rp_tal + val_rep
	ELSE	
	{
		IF rt.c01_bien_serv = 'I' THEN     -- Son Suministros
			LET r.t23_val_otros2 = r.t23_val_otros2 + 
					       val_rep + val_mo
		ELSE
	}
			CALL fl_lee_proveedor_localidad(cod_cia, cod_loc, rc.c10_codprov)
				RETURNING rp.*
			IF rp.p02_int_ext = 'I' THEN
				LET r.t23_val_mo_cti = r.t23_val_mo_cti + val_mo
				LET r.t23_val_rp_cti = r.t23_val_rp_cti + val_rep
			ELSE
				LET r.t23_val_mo_ext = r.t23_val_mo_ext + val_mo
				LET r.t23_val_rp_ext = r.t23_val_rp_ext + val_rep
			END IF
		--END IF
	END IF
END FOREACH
SELECT SUM(ROUND(t30_tot_gasto + (t30_tot_gasto * t30_recargo / 100),2))
	INTO r.t23_val_otros1
	FROM talt030 
	WHERE t30_compania  = cod_cia AND 
	      t30_localidad = cod_loc AND 
	      t30_num_ot    = orden   AND
	      t30_estado    <> 'E'
-- OJO
IF r.t23_val_otros1 IS NULL THEN
	LET r.t23_val_otros1 = 0
END IF
CALL fl_totaliza_orden_taller(r.*) RETURNING r.*
UPDATE talt023 SET * = r.* WHERE CURRENT OF cu_blot
COMMIT WORK

END FUNCTION



FUNCTION fl_lee_permisos_usuarios(usuario, cod_cia, modulo, proceso)
DEFINE cod_cia          LIKE gent055.g55_compania
DEFINE modulo           LIKE gent055.g55_modulo
DEFINE usuario          LIKE gent055.g55_user
DEFINE proceso          LIKE gent055.g55_proceso
DEFINE r                RECORD LIKE gent055.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent055
        WHERE g55_user          = usuario
          AND g55_compania      = cod_cia
          AND g55_modulo        = modulo
	  AND g55_proceso	= proceso
RETURN r.*
                                                                                
END FUNCTION



FUNCTION fl_lee_gasto_viaje(cod_cia, cod_loc, num_gasto)
DEFINE cod_cia          LIKE talt030.t30_compania
DEFINE cod_loc          LIKE talt030.t30_localidad
DEFINE num_gasto        LIKE talt030.t30_num_gasto
DEFINE r                RECORD LIKE talt030.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt030
	WHERE t30_compania  = cod_cia AND 
	      t30_localidad = cod_loc AND 
	      t30_num_gasto = num_gasto
RETURN r.*

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_rep(cod_cia)
DEFINE cod_cia          LIKE rept000.r00_compania
DEFINE r_rep            RECORD LIKE rept000.*

CALL fl_lee_compania_repuestos(cod_cia) RETURNING r_rep.*
IF MONTH(TODAY) <> r_rep.r00_mespro THEN
	CALL fgl_winmessage(vg_producto, 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Repuestos', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_cxc(cod_cia)
DEFINE cod_cia          LIKE cxct000.z00_compania
DEFINE r_z00            RECORD LIKE cxct000.*

CALL fl_lee_compania_cobranzas(cod_cia) RETURNING r_z00.*
IF MONTH(TODAY) <> r_z00.z00_mespro THEN
	CALL fgl_winmessage(vg_producto, 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Cobranzas', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_cxp(cod_cia)
DEFINE cod_cia          LIKE cxpt000.p00_compania
DEFINE r_p00            RECORD LIKE cxpt000.*

CALL fl_lee_compania_tesoreria(cod_cia) RETURNING r_p00.*
IF MONTH(TODAY) <> r_p00.p00_mespro THEN
	CALL fgl_winmessage(vg_producto, 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Tesorería', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_veh(cod_cia)
DEFINE cod_cia          LIKE veht000.v00_compania
DEFINE r_v00            RECORD LIKE veht000.*

CALL fl_lee_compania_vehiculos(cod_cia) RETURNING r_v00.*
IF MONTH(TODAY) <> r_v00.v00_mespro THEN
	CALL fgl_winmessage(vg_producto, 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Vehículos', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_control_status_caja(cod_cia, cod_loc, tipo)
DEFINE cod_cia          LIKE cajt004.j04_compania
DEFINE cod_loc          LIKE cajt004.j04_localidad
DEFINE tipo		CHAR(1)
DEFINE r_j04		RECORD LIKE cajt004.*
DEFINE query		VARCHAR(200)
DEFINE expr_campo	VARCHAR(30)
DEFINE i, cod_return	SMALLINT
DEFINE cod_caja		LIKE cajt004.j04_codigo_caja

IF tipo = 'P' THEN
	LET expr_campo = 'j02_pre_ventas'
ELSE
	IF tipo = 'O' THEN
		LET expr_campo = 'j02_ordenes'
	ELSE
		IF tipo = 'S' THEN
			LET expr_campo = 'j02_solicitudes'
		ELSE
			EXIT PROGRAM
		END IF
	END IF
END IF
LET query = 'SELECT j02_codigo_caja FROM cajt002 ',
		' WHERE ', expr_campo, ' = "S"'
PREPARE ces FROM query
DECLARE cu_ces CURSOR FOR ces
LET cod_return = 1    -- Se asume que la Caja está aperturada y cerrada
LET i = 0
FOREACH cu_ces INTO cod_caja
	LET i = i + 1
	DECLARE cu_chcj CURSOR FOR SELECT * FROM cajt004
		WHERE j04_compania    = cod_cia  AND 
	      	      j04_localidad   = cod_loc  AND 
	      	      j04_codigo_caja = cod_caja AND
	      	      j04_fecha_aper  = TODAY
		ORDER BY j04_fecing DESC
	OPEN cu_chcj
	FETCH cu_chcj INTO r_j04.*
	IF status = NOTFOUND THEN
		LET cod_return = 2
		CONTINUE FOREACH
	END IF
	IF r_j04.j04_fecha_cierre IS NULL THEN
		LET cod_return = 0    -- La Caja está aperturada y no cerrada
		EXIT FOREACH
	ELSE
		LET cod_return = 1
	END IF
END FOREACH
IF i = 0 THEN
	LET cod_return = 2  -- La Caja no ha sido aperturada
END IF
IF cod_return = 1 THEN
	CALL fgl_winmessage(vg_producto, 'La Caja ya ha sido cerrada', 'stop')
ELSE
	IF cod_return = 2 THEN
		CALL fgl_winmessage(vg_producto, 'La Caja no ha sido aperturada aún', 'stop')
	END IF

END IF
RETURN cod_return

END FUNCTION	 



FUNCTION fl_lee_conciliacion(cod_cia, num_concil)
DEFINE cod_cia		LIKE ctbt030.b30_compania
DEFINE num_concil	LIKE ctbt030.b30_num_concil
DEFINE r		RECORD LIKE ctbt030.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt030 	
	WHERE b30_compania = cod_cia AND b30_num_concil = num_concil
RETURN r.*

END FUNCTION




-- OJO CONTABILIZACION DOC COBRANZAS
FUNCTION fl_contabilizacion_documentos(r_datdoc)
DEFINE r_datdoc		RECORD
				codcia		LIKE gent001.g01_compania,
				cliprov		INTEGER,
				tipo_doc	CHAR(2),
				subtipo		LIKE ctbt012.b12_subtipo,
				moneda		LIKE gent013.g13_moneda,
				paridad		LIKE gent014.g14_tasa,
				valor_doc	DECIMAL(14,2),
				flag_mod	SMALLINT
			END RECORD
DEFINE r_contdoc	ARRAY[100] OF RECORD
				b13_cuenta	LIKE ctbt013.b13_cuenta,
				b13_glosa	LIKE ctbt013.b13_glosa,
				debito		DECIMAL(14,2),
				credito		DECIMAL(14,2)
			END RECORD
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE l		LIKE ctbt013.b13_secuencia
DEFINE i, j, unacuenta	SMALLINT
DEFINE num, maximo	SMALLINT
DEFINE k, salir		SMALLINT
DEFINE valor		DECIMAL(14,2)
DEFINE tot_debito	DECIMAL(14,2)
DEFINE tot_credito	DECIMAL(14,2)
DEFINE dif_cuadre	DECIMAL(14,2)
DEFINE lin_menu		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE a		SMALLINT

LET maximo   = 100
LET lin_menu = 0
LET num_rows = 18
LET num_cols = 80
OPEN WINDOW w_ayuf306 AT 05, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu, BORDER,
	      MESSAGE LINE LAST)
	OPEN FORM f_ayuf306 FROM "../../LIBRERIAS/forms/ayuf306"
-- OJO FALTA ayuf306.per
DISPLAY FORM f_ayuf306
--#DISPLAY 'Cuenta'    TO tit_col1
--#DISPLAY 'G l o s a' TO tit_col2
--#DISPLAY 'Debito'    TO tit_col3
--#DISPLAY 'Credito'   TO tit_col4
FOR i = 1 TO maximo
	INITIALIZE r_contdoc[i].* TO NULL
END FOR
                                                                                
{
CALL fgl_winquestion(vg_producto,'Desea ver contabilizacion generada ?','No','Yes|No|Cancel','question',1)
        RETURNING resp
IF resp <> 'Yes' THEN
	INITIALIZE r_b12.* TO NULL
	LET int_flag = 0
--OJO
	CALL fgl_winmessage(vg_producto, 'No se ha generado contabilizacion. Por favor contabilice este documento manualmente.' || vg_base, 'stop')
	CLOSE WINDOW w_ayuf306
	RETURN r_b12.*, 0
END IF
SELECT MAX(b01_nivel) INTO nivel FROM ctbt001
IF nivel IS NULL THEN
	INITIALIZE r_b12.* TO NULL
	LET int_flag = 1
	CALL fgl_winmessage(vg_producto, 'No existe ningun nivel de cuenta configurado en la compania.' || vg_base, 'stop')
	CLOSE WINDOW w_ayuf306
	RETURN r_b12.*, 0
END IF
}
IF r_datdoc.flag_mod = 1 THEN
	CALL fl_lee_cliente_general(r_datdoc.cliprov) RETURNING r_z01.*
	CALL fl_lee_tipo_doc(r_datdoc.tipo_doc) RETURNING r_z04.*
	DISPLAY r_z01.z01_codcli  TO tit_ccliprov
	DISPLAY r_z01.z01_nomcli  TO tit_ncliprov
	DISPLAY r_datdoc.tipo_doc TO tit_tipo_doc
	DISPLAY r_z04.z04_nombre  TO tit_nombre_doc
END IF
IF r_datdoc.flag_mod = 2 THEN
	CALL fl_lee_proveedor(r_datdoc.cliprov) RETURNING r_p01.*
	CALL fl_lee_tipo_doc_tesoreria(r_datdoc.tipo_doc) RETURNING r_p04.*
	DISPLAY r_p01.p01_codprov TO tit_ccliprov
	DISPLAY r_p01.p01_nomprov TO tit_ncliprov
	DISPLAY r_datdoc.tipo_doc TO tit_tipo_doc
	DISPLAY r_p04.p04_nombre  TO tit_nombre_doc
END IF
DISPLAY r_datdoc.valor_doc TO tit_valor
LET salir = 0
LET num   = 0
CALL set_count(num)
LET int_flag = 0
INPUT ARRAY r_contdoc WITHOUT DEFAULTS FROM r_contdoc.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			INITIALIZE r_b12.* TO NULL
			LET int_flag = 0
			CALL fgl_winmessage(vg_producto, 'No se ha generado contabilización. Por favor contabilice este documento manualmente.' || vg_base, 'stop')
			LET salir = 1
			EXIT INPUT
		END IF
       	ON KEY(F2)
		IF INFIELD(b13_cuenta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET r_contdoc[i].b13_cuenta = r_b10.b10_cuenta
				DISPLAY r_contdoc[i].b13_cuenta TO
					r_contdoc[j].b13_cuenta
				DISPLAY BY NAME r_b10.b10_descripcion
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
       		LET i = arr_curr()
        	LET j = scr_line()
		LET num = arr_count()
		CALL fl_lee_cuenta(vg_codcia, r_contdoc[i].b13_cuenta)
			RETURNING r_b10.*
		DISPLAY BY NAME r_b10.b10_descripcion
		LET tot_debito  = 0
		LET tot_credito = 0
		FOR k = 1 TO num
			LET tot_debito  = tot_debito  + r_contdoc[k].debito
			LET tot_credito = tot_credito + r_contdoc[k].credito
		END FOR
		LET dif_cuadre = tot_debito - tot_credito
		DISPLAY BY NAME dif_cuadre, tot_debito, tot_credito
	BEFORE FIELD debito
		IF r_contdoc[i].debito IS NULL THEN
			LET r_contdoc[i].debito = 0
			DISPLAY r_contdoc[i].debito TO r_contdoc[j].debito
		END IF
	BEFORE FIELD credito
		IF r_contdoc[i].credito IS NULL THEN
			LET r_contdoc[i].credito = 0
			DISPLAY r_contdoc[i].credito TO r_contdoc[j].credito
		END IF
	AFTER FIELD b13_cuenta
		IF r_contdoc[i].b13_cuenta IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, r_contdoc[i].b13_cuenta)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe esta cuenta en la compañía.' || vg_base, 'exclamation')
				NEXT FIELD b13_cuenta
			END IF
			DISPLAY BY NAME r_b10.b10_descripcion
			IF r_b10.b10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b13_cuenta
			END IF
			LET unacuenta = 0
			FOR k = 1 TO num + 1
				IF r_contdoc[i].b13_cuenta =
				   r_contdoc[k].b13_cuenta
				THEN
					LET unacuenta = unacuenta + 1
				END IF
			END FOR
			IF unacuenta > 1 THEN
				CALL fgl_winmessage(vg_producto, 'No puede repetir la misma cuenta.' || vg_base,  'exclamation')
				NEXT FIELD b13_cuenta
			END IF
		ELSE
			CLEAR b10_descripcion
		END IF
	AFTER FIELD debito
		IF r_contdoc[i].debito IS NOT NULL THEN
			IF r_contdoc[i].debito > 0 THEN
				LET r_contdoc[i].credito = 0
				DISPLAY r_contdoc[i].credito TO
					r_contdoc[j].credito
			END IF
		ELSE
			LET r_contdoc[i].debito = 0
		END IF
		DISPLAY r_contdoc[i].debito TO r_contdoc[j].debito
		LET tot_debito  = 0
		LET tot_credito = 0
		FOR k = 1 TO num
			LET tot_debito  = tot_debito  + r_contdoc[k].debito
			LET tot_credito = tot_credito + r_contdoc[k].credito
		END FOR
		LET dif_cuadre = tot_debito - tot_credito
		DISPLAY BY NAME dif_cuadre, tot_debito, tot_credito
	AFTER FIELD credito
		IF r_contdoc[i].credito IS NOT NULL THEN
			IF r_contdoc[i].credito > 0 THEN
				LET r_contdoc[i].debito = 0
				DISPLAY r_contdoc[i].debito TO
					r_contdoc[j].debito
			END IF
		ELSE
			LET r_contdoc[i].credito = 0
		END IF
		DISPLAY r_contdoc[i].credito TO r_contdoc[j].credito
		LET tot_debito  = 0
		LET tot_credito = 0
		FOR k = 1 TO num
			LET tot_debito  = tot_debito  + r_contdoc[k].debito
			LET tot_credito = tot_credito + r_contdoc[k].credito
		END FOR
		LET dif_cuadre = tot_debito - tot_credito
		DISPLAY BY NAME dif_cuadre, tot_debito, tot_credito
	AFTER ROW
        	LET j = scr_line()
		IF r_contdoc[i].debito = 0 AND r_contdoc[i].credito = 0 THEN
			CALL fgl_winmessage(vg_producto, 'No puede dejar una cuenta con valor cero en el debito ni en el credito.' || vg_base, 'exclamation')
			--#NEXT FIELD r_cont_doc[j - 1].debito
			NEXT FIELD debito
		END IF
	AFTER DELETE
		LET num = arr_count()
		LET tot_debito  = 0
		LET tot_credito = 0
		FOR k = 1 TO num
			LET tot_debito  = tot_debito  + r_contdoc[k].debito
			LET tot_credito = tot_credito + r_contdoc[k].credito
		END FOR
		LET dif_cuadre = tot_debito - tot_credito
		DISPLAY BY NAME dif_cuadre, tot_debito, tot_credito
	AFTER INPUT
		LET num = arr_count()
		LET tot_debito  = 0
		LET tot_credito = 0
		FOR k = 1 TO num
			LET tot_debito  = tot_debito  + r_contdoc[k].debito
			LET tot_credito = tot_credito + r_contdoc[k].credito
		END FOR
		LET dif_cuadre = tot_debito - tot_credito
		DISPLAY BY NAME dif_cuadre, tot_debito, tot_credito
		IF dif_cuadre <> 0 THEN
			CALL fgl_winmessage(vg_producto, 'No puede grabar descuadrado el diario contable.' || vg_base , 'exclamation')
			NEXT FIELD b13_cuenta
		END IF
		IF tot_debito <> r_datdoc.valor_doc THEN
			CALL fgl_winmessage(vg_producto, 'El total del debito debe ser igual al valor del documento.' || vg_base, 'exclamation')
			NEXT FIELD debito
		END IF
		IF tot_credito <> r_datdoc.valor_doc THEN
			CALL fgl_winmessage(vg_producto, 'El total del credito debe ser igual al valor del documento.' || vg_base, 'exclamation')
			NEXT FIELD credito
		END IF
END INPUT
IF salir THEN
	CLOSE WINDOW w_ayuf306
	RETURN r_b12.*, 0
END IF
INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = r_datdoc.codcia
LET r_b12.b12_tipo_comp   = 'DC'
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(r_b12.b12_compania,
				r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY))
IF r_b12.b12_num_comp = '0' OR r_b12.b12_num_comp = '-1' THEN
	INITIALIZE r_b12.* TO NULL
	LET int_flag = 1
	CLOSE WINDOW w_ayuf306
	RETURN r_b12.*, 0
END IF
LET r_b12.b12_estado      = 'A'
LET r_b12.b12_subtipo     = r_datdoc.subtipo
LET r_b12.b12_glosa       = 'COMPROBANTE GEN. POR DOC. ', r_datdoc.tipo_doc
IF r_datdoc.flag_mod = 1 THEN
	CALL fl_lee_cliente_general(r_datdoc.cliprov) RETURNING r_z01.*
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' DEL CLIENTE: ',
				r_z01.z01_nomcli CLIPPED
END IF
IF r_datdoc.flag_mod = 2 THEN
	CALL fl_lee_proveedor(r_datdoc.cliprov) RETURNING r_p01.*
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' DEL PROVEEDOR: ',
				r_p01.p01_nomprov CLIPPED
END IF
LET r_b12.b12_benef_che   = NULL
LET r_b12.b12_num_cheque  = NULL
LET r_b12.b12_origen      = 'A'
LET r_b12.b12_moneda      = r_datdoc.moneda
LET r_b12.b12_paridad     = r_datdoc.paridad
LET r_b12.b12_fec_proceso = TODAY
LET r_b12.b12_fec_reversa = NULL
LET r_b12.b12_tip_reversa = NULL
LET r_b12.b12_num_reversa = NULL
LET r_b12.b12_fec_modifi  = NULL
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES(r_b12.*)
FOR l = 1 TO num
	INITIALIZE r_b13.* TO NULL
	LET r_b13.b13_compania    = r_b12.b12_compania
	LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
	LET r_b13.b13_num_comp    = r_b12.b12_num_comp
	LET r_b13.b13_secuencia   = l
	LET r_b13.b13_cuenta      = r_contdoc[l].b13_cuenta
	LET r_b13.b13_tipo_doc    = NULL
	LET r_b13.b13_glosa       = r_contdoc[l].b13_glosa
	LET valor = r_contdoc[l].debito
	IF valor = 0 THEN
		LET valor = r_contdoc[l].credito * (-1)
	END IF
	IF r_b12.b12_moneda = rg_gen.g00_moneda_base THEN
		LET r_b13.b13_valor_base = valor
		LET r_b13.b13_valor_aux  = 0
	ELSE
		LET r_b13.b13_valor_base = valor * r_b12.b12_paridad
		LET r_b13.b13_valor_aux  = valor
	END IF
	LET r_b13.b13_num_concil  = NULL
	LET r_b13.b13_filtro      = NULL
	LET r_b13.b13_fec_proceso = TODAY
	IF r_datdoc.flag_mod = 1 THEN
		LET r_b13.b13_codcli  = r_datdoc.cliprov
		LET r_b13.b13_codprov = NULL
	END IF
	IF r_datdoc.flag_mod = 2 THEN
		LET r_b13.b13_codcli  = NULL
		LET r_b13.b13_codprov = r_datdoc.cliprov
	END IF
	LET r_b13.b13_pedido      = NULL
	INSERT INTO ctbt013 VALUES(r_b13.*)
END FOR
CALL fgl_winmessage(vg_producto, 'Contabilizacion generada Ok.' || vg_base, 'info')
CLOSE WINDOW w_ayuf306
RETURN r_b12.*, 1

END FUNCTION


   
FUNCTION fl_validar_cedruc_dig_ver(tipo_doc, cedruc)
DEFINE tipo_doc		CHAR(1)
DEFINE cedruc		VARCHAR(15)
DEFINE valor		ARRAY[15] OF SMALLINT
DEFINE suma, i, lim	SMALLINT
DEFINE residuo_suma	SMALLINT

LET cedruc = cedruc CLIPPED
LET lim = 10
CASE tipo_doc 
	WHEN 'C'
		IF (LENGTH(cedruc) <> 10) THEN
			CALL fgl_winmessage(vg_producto, 'El número de digitos de cédula es incorrecto.', 'exclamation')
			RETURN 0
		END IF
	WHEN 'R'
		IF (LENGTH(cedruc) <> 13) THEN
			CALL fgl_winmessage(vg_producto, 'El número de digitos de ruc es incorrecto.', 'exclamation')
			RETURN 0
		END IF
	WHEN 'P'
		{*
		 * No se validan pasaportes
		 *}
		RETURN 1	
	OTHERWISE
		CALL fgl_winmessage(vg_producto, 'No es un tipo de documento valido.', 'info')
		RETURN 0
END CASE

IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
	CALL fgl_winmessage(vg_producto, 'Los digitos iniciales de cédula/ruc son incorrectos.', 'exclamation')
	RETURN 0
END IF
IF tipo_doc = 'R' THEN
	IF cedruc[11, 13] <> '001' OR cedruc[11, 12] <> '00' THEN
		CALL fgl_winmessage(vg_producto, 'El número de digitos del ruc es incorrecto.', 'exclamation')
		RETURN 0
	END IF
END IF

FOR i = 1 TO lim
	LET valor[i] = 0
END FOR
LET residuo_suma = NULL
IF cedruc[3, 3] = 9 THEN
	LET valor[1]   = cedruc[1, 1] * 4
	LET valor[2]   = cedruc[2, 2] * 3
	LET valor[3]   = cedruc[3, 3] * 2
	LET valor[4]   = cedruc[4, 4] * 7
	LET valor[5]   = cedruc[5, 5] * 6
	LET valor[6]   = cedruc[6, 6] * 5
	LET valor[7]   = cedruc[7, 7] * 4
	LET valor[8]   = cedruc[8, 8] * 3
	LET valor[9]   = cedruc[9, 9] * 2
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF (cedruc[3, 3] = 6) OR (cedruc[3, 3] = 8) THEN
	LET valor[1]   = cedruc[1, 1] * 3
	LET valor[2]   = cedruc[2, 2] * 2
	LET valor[3]   = cedruc[3, 3] * 7
	LET valor[4]   = cedruc[4, 4] * 6
	LET valor[5]   = cedruc[5, 5] * 5
	LET valor[6]   = cedruc[6, 6] * 4
	LET valor[7]   = cedruc[7, 7] * 3
	LET valor[8]   = cedruc[8, 8] * 2
	LET valor[lim] = cedruc[9, 9]
	LET suma       = 0
	FOR i = 1 TO lim - 2
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF ((cedruc[3, 3] < 3) OR (cedruc[3, 3] > 5)) AND (cedruc[3, 3] <> 7) THEN
	FOR i = 1 TO lim - 1
		LET valor[i] = cedruc[i, i]
		IF (i mod 2) <> 0 THEN
			LET valor[i] = valor[i] * 2
			IF valor[i] > 9 THEN
				LET valor[i] = valor[i] - 9
			END IF
		END IF
	END FOR
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 10 - (suma mod 10)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 10 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
CALL fgl_winmessage(vg_producto, 'El número de cédula/ruc no es valido.', 'exclamation')
RETURN 0

END FUNCTION



------- A partir de aqui las funciones del modulo de servicio post-venta 
------- aka (MAQUINARIAS)

FUNCTION fl_lee_parametros_maq(compania)
DEFINE compania		LIKE maqt000.m00_compania
DEFINE r		RECORD LIKE maqt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM maqt000 WHERE m00_compania = compania
RETURN r.*

END FUNCTION



FUNCTION fl_lee_modelo_maq(cod_cia, modelo)
DEFINE cod_cia		LIKE maqt010.m10_compania
DEFINE modelo		LIKE maqt010.m10_modelo
DEFINE r		RECORD LIKE maqt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM maqt010 
	WHERE m10_compania = cod_cia 
          AND m10_modelo   = modelo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_provincia(provincia)
DEFINE provincia	LIKE maqt001.m01_provincia
DEFINE r		RECORD LIKE maqt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM maqt001 WHERE m01_provincia = provincia

RETURN r.*

END FUNCTION



FUNCTION fl_lee_canton(canton)
DEFINE canton		LIKE maqt002.m02_canton
DEFINE r		RECORD LIKE maqt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM maqt002 WHERE m02_canton = canton

RETURN r.*

END FUNCTION



FUNCTION fl_lee_linea_maq(codcia, linea)
DEFINE codcia		LIKE maqt005.m05_compania
DEFINE linea		LIKE maqt005.m05_linea
DEFINE r		RECORD LIKE maqt005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM maqt005 WHERE m05_compania = codcia
				 AND m05_linea    = linea

RETURN r.*

END FUNCTION



FUNCTION fl_proceso_despues_insertar_linea_tr_rep(codcia, codloc, codtran, numtran, item)
DEFINE codcia		LIKE rept020.r20_compania
DEFINE codloc		LIKE rept020.r20_localidad
DEFINE codtran		LIKE rept020.r20_cod_tran
DEFINE numtran		LIKE rept020.r20_num_tran
DEFINE item			LIKE rept020.r20_item

CASE codtran
	WHEN 'FA'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
	WHEN 'NE'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
	WHEN 'DF'
		CALL fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
	WHEN 'AF'
		CALL fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
	WHEN 'TR'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
		CALL fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
	WHEN 'A+'
		CALL fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
	WHEN 'IX'
		CALL fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
	WHEN 'IC'
		CALL fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
	WHEN 'A-'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
	WHEN 'IM'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
	WHEN 'CL'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
	WHEN 'AC'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
	WHEN 'RQ'
		CALL fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
END CASE

END FUNCTION



FUNCTION fl_bloquea_promocion_por_stock(codcia, codloc, codtran, numtran, item)
DEFINE codcia		LIKE rept020.r20_compania
DEFINE codloc		LIKE rept020.r20_localidad
DEFINE codtran		LIKE rept020.r20_cod_tran
DEFINE numtran		LIKE rept020.r20_num_tran
DEFINE item			LIKE rept020.r20_item

DEFINE stock		LIKE rept011.r11_stock_act

	CALL fl_lee_stock_total_rep(codcia, codloc, item, 'R') RETURNING stock

	UPDATE rept110 SET r110_estado = 'B'
	 WHERE r110_compania      = codcia
	   AND r110_localidad     = codloc
	   AND r110_item          = item
       AND r110_fecha_inicio <= TODAY
	   AND r110_estado        = 'A' 
	   AND r110_stock_limite  >= stock 

END FUNCTION



FUNCTION fl_bloquea_promocion_por_nuevo_ingreso(codcia, codloc, codtran, numtran, item)
DEFINE codcia		LIKE rept020.r20_compania
DEFINE codloc		LIKE rept020.r20_localidad
DEFINE codtran		LIKE rept020.r20_cod_tran
DEFINE numtran		LIKE rept020.r20_num_tran
DEFINE item			LIKE rept020.r20_item

DEFINE r_bori		RECORD LIKE rept002.*
DEFINE r_bdest		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*

	INITIALIZE r_bori.* TO NULL
	INITIALIZE r_bdest.* TO NULL
	INITIALIZE r_r19.* TO NULL
	IF codtran = 'TR' THEN
		CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, codtran, numtran)
			RETURNING r_r19.*

		CALL fl_lee_bodega_rep(r_r19.r19_compania, r_r19.r19_bodega_dest)
			RETURNING r_bdest.*
		-- Si la bodega destino no es de esta localidad, no haga nada
		IF r_bdest.r02_localidad <> codloc THEN
			RETURN
		END IF
		-- Si la bodega destino no es de facturacion, no haga nada
		IF r_bdest.r02_factura = 'N' THEN
			RETURN
		END IF

		CALL fl_lee_bodega_rep(r_r19.r19_compania, r_r19.r19_bodega_ori)
			RETURNING r_bori.*
		-- Si bodegas la bodega destino y origen son de la misma localidad, no haga nada
		IF r_bori.r02_localidad = r_bdest.r02_localidad THEN
			RETURN
		END IF
	END IF

	UPDATE rept110 SET r110_estado = 'B'
	 WHERE r110_compania      = codcia
	   AND r110_localidad     = codloc
	   AND r110_item          = item
       AND r110_fecha_inicio <= TODAY
	   AND r110_estado        = 'A' 
	   AND r110_hasta_ingreso = 'S'

END FUNCTION



FUNCTION fl_obtener_promocion_activa_item(codcia, codloc, item)
DEFINE codcia		LIKE rept110.r110_compania
DEFINE codloc		LIKE rept110.r110_localidad
DEFINE item			LIKE rept110.r110_item

DEFINE query		VARCHAR(1000)

DEFINE r			RECORD LIKE rept110.*

INITIALIZE r.* TO NULL

LET query = 'SELECT FIRST 1 * FROM repv110 ',
			' WHERE r110_compania  = ', codcia,
			'   AND r110_localidad = ', codloc,
			'   AND r110_item      = "', item CLIPPED, '"',
			' ORDER BY r110_fecha_inicio DESC '

PREPARE lib0_cons1 FROM query
EXECUTE lib0_cons1 INTO r.*

RETURN r.*

END FUNCTION



FUNCTION fl_lee_inventario_activo(codcia, bodega)
DEFINE codcia		LIKE rept111.r111_compania
DEFINE bodega		LIKE rept111.r111_bodega
DEFINE r			RECORD LIKE rept111.*

INITIALIZE r.* TO NULL

SELECT * INTO r.* 
  FROM rept111
 WHERE r111_compania = codcia
   AND r111_bodega   = bodega
   AND r111_estado   = 'A'

RETURN r.*

END FUNCTION



FUNCTION fl_lee_factor_importacion_stock_rep(codcia, codclasif)
DEFINE codcia		LIKE rept114.r114_compania
DEFINE codclasif	LIKE rept114.r114_codigo
DEFINE r			RECORD LIKE rept114.*

	INITIALIZE r.* TO NULL
	SELECT * INTO r.* FROM rept114 
	 WHERE r114_compania = codcia 
	   AND r114_codigo   = codclasif 
	RETURN r.*

END FUNCTION



FUNCTION fl_lee_factor_importacion_stock_rep_predeterminado(codcia, flag_ident)
DEFINE codcia		LIKE rept114.r114_compania
DEFINE flag_ident	LIKE rept114.r114_flag_ident
DEFINE r			RECORD LIKE rept114.*

	INITIALIZE r.* TO NULL
	SELECT * INTO r.* FROM rept114 
	 WHERE r114_compania   = codcia 
       AND r114_flag_ident = flag_ident
	   AND r114_default    = 'S' 
	RETURN r.*

END FUNCTION



-- Esta funcion existe para parametrizar a la fuerza ciertos tipos de clientes
-- Se esta usando la tabla de componentes de entidades, donde existe CL como
-- entidad. 
-- El componente, de entidad CL, 5 es venta al costo; y 6 costo FOB 
FUNCTION fl_obtener_precio_tipo_cliente(tipo_clte, precio, costo, fob)
DEFINE tipo_clte	LIKE cxct001.z01_tipo_clte
DEFINE precio		LIKE rept010.r10_precio_mb
DEFINE costo		LIKE rept010.r10_costo_mb
DEFINE fob			LIKE rept010.r10_fob

DEFINE valor		LIKE rept010.r10_precio_mb

CASE tipo_clte
	WHEN 5 
		LET valor = costo		 
	WHEN 6
		LET valor = fob
	OTHERWISE 
		LET valor = precio
END CASE

RETURN valor

END FUNCTION



FUNCTION fl_tipo_cliente_venta_costo_fob(tipo_clte)
DEFINE tipo_clte	LIKE cxct001.z01_tipo_clte

	IF tipo_clte = 5 or tipo_clte = 6 THEN
		RETURN TRUE
	END IF
	
	RETURN FALSE

END FUNCTION



FUNCTION fl_proforma_aprobada(codcia, codloc, numprof)
DEFINE codcia			LIKE rept102.r102_compania
DEFINE codloc			LIKE rept102.r102_localidad
DEFINE numprof			LIKE rept102.r102_numprof
DEFINE preventas		SMALLINT

	SELECT COUNT(*) INTO preventas
	  FROM rept102, rept023
	 WHERE r102_compania  = codcia
	   AND r102_localidad = codloc
	   AND r102_numprof   = numprof
	   AND r23_compania   = r102_compania
	   AND r23_localidad  = r102_localidad
	   AND r23_numprev    = r102_numprev  
	   AND r23_estado     = 'P'

	IF preventas > 0 THEN
		RETURN TRUE 
	ELSE
		RETURN FALSE
	END IF
END FUNCTION



FUNCTION fl_proforma_facturada(codcia, codloc, numprof)
DEFINE codcia			LIKE rept102.r102_compania
DEFINE codloc			LIKE rept102.r102_localidad
DEFINE numprof			LIKE rept102.r102_numprof
DEFINE facturadas		SMALLINT

	SELECT COUNT(*) INTO facturadas
	  FROM rept102, rept023
	 WHERE r102_compania  = codcia
	   AND r102_localidad = codloc
	   AND r102_numprof   = numprof
	   AND r23_compania   = r102_compania
	   AND r23_localidad  = r102_localidad
	   AND r23_numprev    = r102_numprev  
	   AND r23_estado     = 'F'

	IF facturadas > 0 THEN
		RETURN TRUE 
	ELSE
		RETURN FALSE
	END IF
END FUNCTION



FUNCTION fl_proforma_despachada(codcia, codloc, numprof)
DEFINE codcia			LIKE rept102.r102_compania
DEFINE codloc			LIKE rept102.r102_localidad
DEFINE numprof			LIKE rept102.r102_numprof
DEFINE despachos		SMALLINT

	SELECT COUNT(*) INTO despachos
	  FROM rept102, rept023, rept118
	 WHERE r102_compania  = codcia
	   AND r102_localidad = codloc
	   AND r102_numprof   = numprof
	   AND r23_compania   = r102_compania
	   AND r23_localidad  = r102_localidad
	   AND r23_numprev    = r102_numprev  
	   AND r23_estado     = 'P'
           AND r118_compania  = r23_compania
           AND r118_localidad = r23_localidad
           AND r118_numprev   = r23_numprev
           AND r118_cod_fact  IS NULL

	IF despachos > 0 THEN
		RETURN TRUE 
	ELSE
		RETURN FALSE
	END IF
END FUNCTION



FUNCTION fl_sustituido_por(codcia, item)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE item			LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*

DEFINE i, j		SMALLINT
DEFINE max_items 	SMALLINT
DEFINE r_items ARRAY[100] OF RECORD
	cantidad	LIKE rept014.r14_cantidad,
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD

LET max_items = 100

OPEN WINDOW w_sust AT 9,3 WITH 12 ROWS, 75 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 1, BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_sust FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf127'
DISPLAY FORM f_sust

DISPLAY fl_justifica_titulo('D', 'Sustituido', 10) TO lbl_item
DISPLAY 'Cant'		TO bt_canti
DISPLAY 'Sustituto' TO bt_item
DISPLAY 'Fecha'     TO bt_fecha

CALL fl_lee_item(codcia, item) RETURNING r_r10.*

DISPLAY r_r10.r10_codigo TO item1
DISPLAY r_r10.r10_nombre TO n_item1

-- Cursor que obtiene los items sustitutos para este item,
-- es decir, por quienes fue sustituido
DECLARE q_sustitutos2 CURSOR FOR 
	SELECT r14_cantidad, r14_item_nue, r10_nombre, DATE(r14_fecing) 
	  FROM rept014, rept010
	 WHERE r14_compania = r_r10.r10_compania
	   AND r14_item_ant = r_r10.r10_codigo
	   AND r10_compania = r14_compania 
	   AND r10_codigo   = r14_item_nue
		  
LET i = 1
FOREACH q_sustitutos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
LET int_flag = 0

CALL set_count(i)
DISPLAY ARRAY r_items TO ra_items.*

CLOSE WINDOW w_sust

END FUNCTION



FUNCTION fl_cantdev_factura_item(cod_cia, cod_loc, cod_tran, num_tran, item, fecha_hasta)
DEFINE cod_cia		LIKE rept020.r20_compania
DEFINE cod_loc		LIKE rept020.r20_localidad
DEFINE cod_tran		LIKE rept020.r20_cod_tran
DEFINE num_tran		LIKE rept020.r20_num_tran
DEFINE item			LIKE rept020.r20_item	
DEFINE fecha_hasta	DATE

DEFINE cant_dev    	LIKE rept020.r20_cant_dev

{*
 * Si fecha_hasta es NULL saque todas las devoluciones de lo contrario solo 
 * saque hasta esa fecha.
 *
 * OjO, tendre problemas en el 3001. Pero siguiendo la costumbre humana, ya 
 * estare muerto asi que... ahi se va!!!
 * ;)
 *}
IF fecha_hasta IS NULL THEN
	LET fecha_hasta = MDY(12, 31, 3000)
END IF

-- Existen devoluciones?
SELECT SUM(r20_cant_ven) INTO cant_dev
  FROM rept019, rept020
 WHERE r19_compania  = cod_cia
   AND r19_localidad = cod_loc
   AND r19_tipo_dev  = cod_tran
   AND r19_num_dev   = num_tran
   AND DATE(r19_fecing) <= fecha_hasta
   AND r20_compania  = r19_compania
   AND r20_localidad = r19_localidad
   AND r20_cod_tran  = r19_cod_tran
   AND r20_num_tran  = r19_num_tran
   AND r20_item      = item
IF cant_dev IS NULL THEN
	LET cant_dev = 0
END IF
  
RETURN cant_dev

END FUNCTION



FUNCTION fl_lee_actualiza_cheque_cta_cte(codcia, banco, numero_cta)
DEFINE codcia			LIKE gent100.g100_compania
DEFINE banco			LIKE gent100.g100_banco
DEFINE numero_cta		LIKE gent100.g100_numero_cta

DEFINE r_g100			RECORD LIKE gent100.*

INITIALIZE r_g100.* TO NULL

SET LOCK MODE TO WAIT 10

WHENEVER ERROR CONTINUE
DECLARE q_cheq CURSOR FOR
	SELECT * FROM gent100
	 WHERE g100_compania   = codcia
	   AND g100_banco      = banco
	   AND g100_numero_cta = numero_cta
	FOR UPDATE  

OPEN  q_cheq
FETCH q_cheq INTO r_g100.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fgl_winmessage(vg_producto, 'La chequera esta bloqueada por otro usuario.', 'stop')
	RETURN -1
END IF	
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT

IF r_g100.g100_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No hay chequera para esta cuenta.', 'stop')
	RETURN -1
END IF

IF r_g100.g100_cheq_act = r_g100.g100_cheq_fin THEN
	CALL fgl_winmessage(vg_producto, 'No hay cheques disponibles en la chequera.', 'stop')
	RETURN -1
END IF

LET r_g100.g100_cheq_act = r_g100.g100_cheq_act + 1
UPDATE gent100 SET g100_cheq_act = r_g100.g100_cheq_act
 WHERE CURRENT OF q_cheq

RETURN r_g100.g100_cheq_act

END FUNCTION



FUNCTION fl_mensaje_proveedor_documentos_favor(codcia, codloc, codprov)
DEFINE codcia 			LIKE cxpt021.p21_compania
DEFINE codloc 			LIKE cxpt021.p21_localidad
DEFINE codprov 			LIKE cxpt021.p21_codprov

DEFINE n_doc_favor		INTEGER
DEFINE tot_saldo		LIKE cxpt021.p21_valor
DEFINE mensaje			VARCHAR(1000)

INITIALIZE n_doc_favor, tot_saldo TO NULL

SELECT count(*), sum(p21_saldo * p21_paridad)
  INTO n_doc_favor, tot_saldo
  FROM cxpt021
 WHERE p21_compania  = codcia
   AND p21_localidad = codloc
   AND p21_codprov   = codprov
   AND p21_tipo_doc  = 'PA'
   AND p21_saldo     > 0

IF n_doc_favor IS NOT NULL AND n_doc_favor > 0 THEN
	LET mensaje = 'El proveedor tiene ', n_doc_favor CLIPPED, ' documentos a ', 
				  'favor con un saldo total de ', 
				  tot_saldo USING '###,###,##&.&&'
	CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
END IF

END FUNCTION



FUNCTION fl_lee_categoria_cliente_cms(codcia, categoria)
DEFINE codcia		LIKE cmst004.c04_compania
DEFINE categoria	LIKE cmst004.c04_codigo
DEFINE r		RECORD LIKE cmst004.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cmst004 WHERE c04_compania = codcia
				 AND c04_codigo   = categoria
RETURN r.*

END FUNCTION



FUNCTION fl_lee_liquidacion_comisiones(codcia, anio, mes)
DEFINE codcia		LIKE cmst010.c10_compania
DEFINE anio			LIKE cmst010.c10_anio
DEFINE mes 			LIKE cmst010.c10_mes 
DEFINE r		RECORD LIKE cmst010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cmst010 WHERE c10_compania = codcia
				 AND c10_anio   = anio
				 AND c10_mes = mes	
RETURN r.*

END FUNCTION



