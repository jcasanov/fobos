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
	CALL fl_mostrar_mensaje('No se pudo abrir base de datos: ' || vg_base, 
		'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No se pudo abrir base de datos: ' || vg_base, 
		'stop')
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



FUNCTION fl_lee_impresora_usr(usuario, impresora)
DEFINE usuario		LIKE gent007.g07_user
DEFINE impresora	LIKE gent007.g07_impresora
DEFINE r		RECORD LIKE gent007.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent007
	WHERE g07_user      = usuario
	  AND g07_impresora = impresora
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



FUNCTION fl_lee_tarjeta_credito(codcia, tarjeta, cod_tarj, cont_cred)
DEFINE codcia		LIKE gent010.g10_compania
DEFINE tarjeta		LIKE gent010.g10_tarjeta
DEFINE cod_tarj		LIKE gent010.g10_cod_tarj
DEFINE cont_cred	LIKE gent010.g10_cont_cred
DEFINE r		RECORD LIKE gent010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.*
	FROM gent010
	WHERE g10_compania  = codcia
	  AND g10_tarjeta   = tarjeta
	  AND g10_cod_tarj  = cod_tarj
	  AND g10_cont_cred = cont_cred
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


FUNCTION fl_lee_capitulo(capitulo)
DEFINE capitulo		LIKE gent038.g38_capitulo
DEFINE r		RECORD LIKE gent038.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent038 WHERE g38_capitulo = capitulo
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



FUNCTION fl_lee_tarea(cod_cia, codtarea)
DEFINE cod_cia		LIKE talt007.t07_compania
DEFINE codtarea		LIKE talt007.t07_codtarea
DEFINE r		RECORD LIKE talt007.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt007 
	WHERE t07_compania = cod_cia AND t07_codtarea = codtarea
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



FUNCTION fl_lee_tarea_grado_dificultad(cod_cia, tarea, grado)
DEFINE cod_cia		LIKE talt009.t09_compania
DEFINE tarea		LIKE talt009.t09_codtarea
DEFINE grado		LIKE talt009.t09_dificultad
DEFINE r		RECORD LIKE talt009.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM talt009 
	WHERE t09_compania = cod_cia AND 
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

--LET r_ord.t23_vde_mo_tal = r_ord.t23_val_mo_tal * r_ord.t23_por_mo_tal / 100
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
			  r_ord.t23_val_rp_cti + r_ord.t23_val_rp_alm 
LET r_ord.t23_val_impto = (r_ord.t23_tot_bruto - r_ord.t23_tot_dscto) *
			  r_ord.t23_porc_impto / 100
CALL fl_retorna_precision_valor(r_ord.t23_moneda, r_ord.t23_val_impto)
	RETURNING r_ord.t23_val_impto
LET r_ord.t23_tot_neto = r_ord.t23_tot_bruto - r_ord.t23_tot_dscto +
			 r_ord.t23_val_impto + r_ord.t23_val_otros1 + 
			 r_ord.t23_val_otros2
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
	CALL fl_mostrar_mensaje('Orden: ' || orden || ' no existe', 'exclamation')
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
	CALL fl_mostrar_mensaje('Orden: ' || orden || ' no existe', 'exclamation')
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
	SELECT t24_mecanico, SUM(t24_valor_tarea - t24_val_descto)
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
DEFINE comando		CHAR(300)

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



FUNCTION fl_lee_roles_usos_varios(cod_cia, num_rol)
DEFINE cod_cia		LIKE rolt043.n43_compania
DEFINE num_rol  	LIKE rolt043.n43_num_rol  
DEFINE r		RECORD LIKE rolt043.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt043 
	WHERE n43_compania = cod_cia
	  AND n43_num_rol  = num_rol
RETURN r.*

END FUNCTION



FUNCTION fl_lee_parametros_club_roles(cod_cia)
DEFINE cod_cia		LIKE rolt060.n60_compania
DEFINE r		RECORD LIKE rolt060.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt060 WHERE n60_compania = cod_cia

RETURN r.*

END FUNCTION



FUNCTION fl_lee_casa_comercial(cod_cia, cod_almacen)
DEFINE cod_cia		LIKE rolt062.n62_compania
DEFINE cod_almacen	LIKE rolt062.n62_cod_almacen
DEFINE r		RECORD LIKE rolt062.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt062 WHERE n62_compania    = cod_cia
				 AND n62_cod_almacen = cod_almacen

RETURN r.*

END FUNCTION



FUNCTION fl_retorna_valor_rubro_trabajador(cod_cia, proceso, cod_rubro,cod_trab)
DEFINE cod_cia		LIKE rolt010.n10_compania
DEFINE proceso		LIKE rolt010.n10_cod_liqrol
DEFINE cod_rubro	LIKE rolt010.n10_cod_rubro
DEFINE cod_trab		LIKE rolt010.n10_cod_trab
DEFINE r		RECORD LIKE rolt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt010 
	WHERE n10_compania   = cod_cia	
	  AND n10_cod_liqrol = proceso
	  AND n10_cod_rubro  = cod_rubro
	  AND n10_cod_trab   = cod_trab
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
DEFINE comando		CHAR(300)
DEFINE run_prog		CHAR(10)
DEFINE base		LIKE gent051.g51_basedatos

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET base = vg_base
SELECT g56_base_datos INTO base FROM gent056
	WHERE g56_compania  = codcia AND 
	      g56_localidad = codloc 
INITIALIZE comando TO NULL
CASE cod_tran
	WHEN 'FA'      
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp308 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'IM'        
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp308 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'CL'          
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp214 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'RQ'          
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp215 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'TR'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp216 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'DF'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp217 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'AF'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp217 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'DC'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp218 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'DR'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp219 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'A+'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp212 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'A-'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp212 ', base, ' ',
			      'RE', codcia, ' ', codloc,
			      ' ', cod_tran, ' ', num_tran   
	WHEN 'AC'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp213 ', base, ' ',
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



FUNCTION fl_actualiza_acumulados_ventas_rep(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r, ra		RECORD LIKE rept060.*
DEFINE rc		RECORD LIKE rept019.*
DEFINE rt		RECORD LIKE gent021.*
DEFINE i		SMALLINT

SET LOCK MODE TO WAIT 10
CALL fl_lee_cod_transaccion(cod_tran) RETURNING rt.*
IF rt.g21_tipo IS NULL THEN
	CALL fl_mostrar_mensaje('Tipo de transacción no existe', 'stop')
	RETURN 0
END IF
IF rt.g21_act_estad <> 'S' THEN
	RETURN 1
END IF
IF rt.g21_tipo <> 'I' AND rt.g21_tipo <> 'E' THEN
	RETURN 1
END IF
CALL fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rc.*
IF rc.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' || ' no existe ',
			    'stop')
	RETURN 0
END IF	
DECLARE q_drest CURSOR FOR 
	SELECT DATE(r20_fecing), r20_bodega, r20_linea, r20_rotacion,
	       SUM((r20_cant_ven * r20_precio) - r20_val_descto),
	       SUM(r20_costo * r20_cant_ven)
	FROM rept020
	WHERE r20_compania  = cod_cia  AND
	      r20_localidad = cod_loc  AND
	      r20_cod_tran  = cod_tran AND
	      r20_num_tran  = num_tran  
	GROUP BY 1,2,3,4
LET i = 0
INITIALIZE r.* TO NULL
LET r.r60_compania = cod_cia
LET r.r60_vendedor = rc.r19_vendedor
LET r.r60_moneda   = rc.r19_moneda
FOREACH q_drest INTO r.r60_fecha, r.r60_bodega, r.r60_linea, r.r60_rotacion, 
		     r.r60_precio, r.r60_costo
	IF rt.g21_tipo = 'I' THEN
		LET r.r60_precio = r.r60_precio * -1
		LET r.r60_costo  = r.r60_costo  * -1
	END IF
	LET i = i + 1
	WHENEVER ERROR CONTINUE
	DECLARE q_up60 CURSOR FOR SELECT * FROM rept060
		WHERE r60_compania  = r.r60_compania  AND 
		      r60_fecha     = r.r60_fecha     AND 
		      r60_bodega    = r.r60_bodega    AND 
		      r60_vendedor  = r.r60_vendedor  AND 
		      r60_moneda    = r.r60_moneda    AND 
		      r60_linea     = r.r60_linea     AND 
		      r60_rotacion  = r.r60_rotacion 
		FOR UPDATE
	OPEN q_up60
	FETCH q_up60 INTO ra.*
	IF status = NOTFOUND THEN
		WHENEVER ERROR STOP
		INSERT INTO rept060 VALUES (r.*)
	ELSE
		IF status < 0 THEN
			CALL fl_mostrar_mensaje('Debido a un bloqueo no se pudo actualizar estadísticas de ventas, ejecute el proceso de nuevo', 'stop')
			WHENEVER ERROR STOP
			RETURN 0
		END IF
		WHENEVER ERROR STOP
		UPDATE rept060 SET r60_precio = r60_precio + r.r60_precio,
		                   r60_costo  = r60_costo  + r.r60_costo
			WHERE CURRENT OF q_up60
	END IF
	WHENEVER ERROR STOP
END FOREACH
IF i = 0 THEN
	CALL fl_mostrar_mensaje('Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' ||
			    ' no tiene detalle', 'stop')
	RETURN 0
END IF
RETURN 1

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
	CALL fl_mostrar_mensaje('Tipo de transacción no existe', 'stop')
	RETURN 0
END IF
IF rt.g21_act_estad <> 'S' THEN
	RETURN 1
END IF
IF rt.g21_tipo <> 'I' AND rt.g21_tipo <> 'E' THEN
	--CALL fl_mostrar_mensaje('Transacción no es de ingreso ni de egreso de stock', 'stop')
	RETURN 1
END IF
CALL fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rc.*
IF rc.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Comprobante ' || cod_tran || ' ' ||
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
	LET r.r12_bodega    = rd.r20_bodega
	IF rt.g21_tipo = 'I' THEN
		LET r.r12_uni_venta = 0
		LET r.r12_uni_dev   = rd.r20_cant_ven
		LET r.r12_uni_deman = -1
		LET r.r12_uni_perdi = r.r12_uni_perdi * -1
		LET r.r12_val_dev   = r.r12_val_venta 
		LET r.r12_val_venta = 0
	ELSE
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
			CALL fl_mostrar_mensaje('Debido a un bloqueo no se pudo actualizar estadísticas de items, ejecute el proceso de nuevo', 'stop')
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
	CALL fl_mostrar_mensaje('Comprobante ' || cod_tran || ' ' ||
			    num_tran USING '###############' ||
			    ' no tiene detalle', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION	



FUNCTION fl_lee_sublinea_rep(cod_cia, linea, sub_linea)
DEFINE cod_cia		LIKE rept070.r70_compania
DEFINE linea		LIKE rept070.r70_linea
DEFINE sub_linea	LIKE rept070.r70_sub_linea
DEFINE r		RECORD LIKE rept070.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept070 	
	WHERE r70_compania  = cod_cia
	  AND r70_linea     = linea
	  AND r70_sub_linea = sub_linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_grupo_rep(cod_cia, linea, sub_linea, cod_grupo)
DEFINE cod_cia		LIKE rept071.r71_compania
DEFINE linea		LIKE rept071.r71_linea
DEFINE sub_linea	LIKE rept071.r71_sub_linea
DEFINE cod_grupo	LIKE rept071.r71_cod_grupo
DEFINE r		RECORD LIKE rept071.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept071 	
	WHERE r71_compania  = cod_cia
	  AND r71_linea     = linea
	  AND r71_sub_linea = sub_linea
	  AND r71_cod_grupo = cod_grupo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_clase_rep(cod_cia, linea, sub_linea, cod_grupo, cod_clase)
DEFINE cod_cia		LIKE rept072.r72_compania
DEFINE linea		LIKE rept072.r72_linea
DEFINE sub_linea	LIKE rept072.r72_sub_linea
DEFINE cod_grupo	LIKE rept072.r72_cod_grupo
DEFINE cod_clase	LIKE rept072.r72_cod_clase
DEFINE r		RECORD LIKE rept072.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept072 	
	WHERE r72_compania  = cod_cia
	  AND r72_linea     = linea
	  AND r72_sub_linea = sub_linea
	  AND r72_cod_grupo = cod_grupo
	  AND r72_cod_clase = cod_clase
RETURN r.*

END FUNCTION



FUNCTION fl_lee_marca_rep(cod_cia, marca)
DEFINE cod_cia		LIKE rept073.r73_compania
DEFINE marca		LIKE rept073.r73_marca
DEFINE r		RECORD LIKE rept073.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept073 	
	WHERE r73_compania = cod_cia AND r73_marca = marca	
RETURN r.*

END FUNCTION



FUNCTION fl_lee_orden_despacho(cod_cia, cod_loc, bodega, num_ord)
DEFINE cod_cia		LIKE rept034.r34_compania
DEFINE cod_loc		LIKE rept034.r34_localidad
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE num_ord		LIKE rept034.r34_num_ord_des
DEFINE r		RECORD LIKE rept034.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept034 	
	WHERE r34_compania    = cod_cia AND r34_localidad = cod_loc AND 
	      r34_bodega      = bodega AND
	      r34_num_ord_des = num_ord
RETURN r.*

END FUNCTION



FUNCTION fl_lee_nota_entrega(cod_cia, cod_loc, bodega, num_ent)
DEFINE cod_cia		LIKE rept036.r36_compania
DEFINE cod_loc		LIKE rept036.r36_localidad
DEFINE bodega		LIKE rept036.r36_bodega
DEFINE num_ent		LIKE rept036.r36_num_ord_des
DEFINE r		RECORD LIKE rept036.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept036 	
	WHERE r36_compania = cod_cia AND r36_localidad   = cod_loc AND 
	      r36_bodega   = bodega  AND r36_num_entrega = num_ent
RETURN r.*

END FUNCTION



FUNCTION fl_lee_nota_pedido_rep(cod_cia, cod_loc, nota)
DEFINE cod_cia		LIKE rept081.r81_compania
DEFINE cod_loc		LIKE rept081.r81_localidad
DEFINE nota		LIKE rept081.r81_pedido
DEFINE r		RECORD LIKE rept081.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept081
	WHERE r81_compania  = cod_cia
	  AND r81_localidad = cod_loc
	  AND r81_pedido    = nota
RETURN r.*

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
	CALL fl_mostrar_mensaje('Tipo de transacción no existe', 'stop')
	RETURN 0
END IF 
IF rt.g21_act_estad <> 'S' THEN
	RETURN 1
END IF
IF rt.g21_tipo <> 'I' AND rt.g21_tipo <> 'E' THEN
	--CALL fl_mostrar_mensaje('Transacción no es de ingreso ni de egreso de stock', 'stop')
	RETURN 1
END IF
CALL fl_lee_cabecera_transaccion_veh(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rc.*
IF rc.v30_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Comprobante ' || cod_tran || ' ' ||
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
			CALL fl_mostrar_mensaje('Debido a un bloqueo no se pudo actualizar estadísticas de ventas, ejecute el proceso de nuevo', 'stop')
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
	CALL fl_mostrar_mensaje('Comprobante ' || cod_tran || ' ' ||
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
DEFINE cod_cia		LIKE gent001.g01_compania

SELECT g01_compania INTO cod_cia FROM gent001 WHERE g01_principal = 'S'
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay compañía principal configurada.', 'stop')
	EXIT PROGRAM
END IF
RETURN cod_cia

END FUNCTION



FUNCTION fl_retorna_agencia_default(cod_cia)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad

SELECT g02_localidad INTO cod_local FROM gent002
	WHERE g02_compania = cod_cia AND g02_matriz = 'S'
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay localidad matriz para compañía: ' || cod_cia, 'stop')
	EXIT PROGRAM
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
DEFINE titulo		CHAR(54)
DEFINE titulo2		VARCHAR(90)
DEFINE usuario		VARCHAR(19)
DEFINE num_row 		SMALLINT

LET vg_proceso  = cod_proc
CALL fl_lee_compania(cod_cia) RETURNING r_cia.*
IF r_cia.g01_compania  IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código cía. en gent001: ' || cod_cia, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(cod_cia, cod_local) RETURNING r_loc.*
IF r_loc.g02_compania  IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código localidad. en gent0021: ' || cod_local, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_modulo(cod_mod) RETURNING r_mod.*
IF r_mod.g50_modulo  IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código módulo en gent050: ' || cod_mod, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso(cod_mod, cod_proc) RETURNING r_proc.*
IF r_proc.g54_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código proceso en gent054: ' || cod_proc, 'stop')
	EXIT PROGRAM
END IF
LET titulo2 = vg_proceso CLIPPED, ' - ', vg_producto CLIPPED
IF vg_proceso[1, 4] = 'menp' THEN
	LET titulo2 = vg_proceso CLIPPED, '  - MENU PRINCIPAL -  ',
			vg_producto CLIPPED
END IF
{--
LET titulo2 = fl_justifica_titulo('D', titulo2, 71)
LET usuario = 'USUARIO: ', vg_usuario CLIPPED
LET usuario = fl_justifica_titulo('I', usuario, 19)
LET titulo2 = usuario, titulo2
--}
LET titulo2 = vg_usuario CLIPPED, ' - ', titulo2 CLIPPED, '  : [ ',
		vg_base CLIPPED, '@', vg_servidor CLIPPED, ' ]'
LET titulo2 = fl_justifica_titulo('I', titulo2, 90)
--#CALL fgl_settitle(titulo2)
LET titulo = r_cia.g01_abreviacion CLIPPED, " (", r_loc.g02_abreviacion CLIPPED,
	     --") - ", vg_usuario[1, 8] CLIPPED
	     ")"
IF vg_gui = 1 THEN
	LET num_row = 1
	OPEN WINDOW wt AT 1,2 WITH 1 ROWS, 90 COLUMNS ATTRIBUTE(BORDER)
	DISPLAY titulo AT num_row,1 ATTRIBUTE(BLUE)
ELSE
	LET num_row = 2
	CALL fgl_drawbox(3,80,1,1)
	DISPLAY titulo AT num_row,2 ATTRIBUTE(BLUE)
END IF
{--
LET titulo = r_mod.g50_nombre CLIPPED, ": ", r_proc.g54_nombre[1, 35] CLIPPED
LET titulo = fl_justifica_titulo('D', titulo, 47)
DISPLAY titulo AT num_row,32 ATTRIBUTE(BLUE)
--}
LET titulo = r_mod.g50_nombre CLIPPED, ": ", r_proc.g54_nombre CLIPPED
LET titulo = fl_justifica_titulo('D', titulo, 54)
DISPLAY titulo AT num_row,25 ATTRIBUTE(BLUE)

END FUNCTION



FUNCTION fl_retorna_usuario()
 
SELECT USER INTO vg_usuario FROM dual
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Tabla dual está vacía', 'stop')
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
LET vg_gui      = FGL_GETENV('FGLGUI')
LET vg_servidor = FGL_GETENV('INFORMIXSERVER')
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
CALL fl_marca_registrada_producto()
CALL fl_retorna_usuario()
CALL fl_retorna_fecha_proceso()
CALL fl_separador()
IF vg_codcia = 0 OR vg_codcia IS NULL THEN
	LET vg_codcia = fl_retorna_compania_default()
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF vg_codloc = 0 OR vg_codloc IS NULL THEN
	LET vg_codloc = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_control_acceso_procesos(vg_usuario, vg_codcia, vg_modulo, vg_proceso) 
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
DEFINE rm_g55   	RECORD LIKE gent055.*
DEFINE r_g54   		RECORD LIKE gent054.*
DEFINE clave		LIKE gent005.g05_clave

CALL fl_lee_usuario(v_usuario) RETURNING r_g05.*
IF r_g05.g05_usuario IS NULL THEN
	CALL fl_mostrar_mensaje('USUARIO: ' || v_usuario CLIPPED 
	          || ' NO ESTA CONFIGURADO EN EL SISTEMA.'
		  || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	EXIT PROGRAM
END IF
IF r_g05.g05_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('USUARIO: ' || v_usuario CLIPPED 
	          || ' ESTA BLOQUEADO.'
		  || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_modulo(v_modulo) RETURNING r_g50.*
IF r_g50.g50_modulo IS NULL THEN
	CALL fl_mostrar_mensaje('MODULO: ' || v_modulo CLIPPED 
				          || ' NO EXISTE ', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso(v_modulo, v_proceso) RETURNING r_g54.*
IF r_g54.g54_modulo IS NULL THEN
	CALL fl_mostrar_mensaje('PROCESO: ' || v_modulo CLIPPED 
				          || '-' || v_proceso CLIPPED
					  || ' NO EXISTE ', 'stop')
	EXIT PROGRAM
END IF
SELECT * FROM gent052 
	WHERE g52_modulo  = v_modulo  AND 
	      g52_usuario = v_usuario
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('USUARIO NO TIENE ACCESO AL MODULO: '
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
	CALL fl_mostrar_mensaje('USUARIO NO TIENE ACCESO A LA COMPAÑIA:'
				|| ' ' || rg_cia.g01_abreviacion CLIPPED 
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
IF r_g54.g54_estado = 'B' THEN
	CALL fl_mostrar_mensaje('EL PROCESO: ' 
				|| v_proceso CLIPPED
				|| ' ESTA MARCADO COMO BLOQUEADO.'
				|| ' PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_permisos_usuarios(vg_usuario, vg_codcia, vg_modulo, vg_proceso) 
	RETURNING rm_g55.*
IF rm_g55.g55_user IS NOT NULL THEN
	CALL fl_mostrar_mensaje('USTED NO TIENE ACCESO AL PROCESO ' 
				|| v_proceso CLIPPED
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
IF r_g54.g54_estado = 'R' THEN
	OPEN WINDOW w_clave AT 9, 20 WITH 7 ROWS, 43 COLUMNS
 		ATTRIBUTE(FORM LINE FIRST, BORDER, COMMENT LINE LAST)
	IF vg_gui = 1 THEN
		OPEN FORM f_ayuf126
			FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf126'
	ELSE
		OPEN FORM f_ayuf126
			FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf126c'
	END IF
	DISPLAY FORM f_ayuf126
	LET int_flag = 0
	LET clave = NULL
	INPUT BY NAME clave
	IF int_flag THEN
		EXIT PROGRAM
	END IF
	IF clave = r_g05.g05_clave OR 
		(clave IS NULL AND r_g05.g05_clave IS NULL) THEN
		CLOSE WINDOW w_clave
		RETURN
	END IF
	CALL fl_mostrar_mensaje('LO SIENTO CLAVE INCORRECTA ',
				'stop')
	EXIT PROGRAM
END IF	
 
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
	CALL fl_mostrar_mensaje('Tabla fobos está vacía', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_separador()

SELECT fb_separador, fb_dir_fobos INTO vg_separador, vg_dir_fobos FROM fobos
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Tabla fobos está vacía', 'stop')
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



FUNCTION fl_lee_configuracion_sri(cod_cia)
DEFINE cod_cia		LIKE srit000.s00_compania
DEFINE r_s00		RECORD LIKE srit000.*

INITIALIZE r_s00.* TO NULL
SELECT * INTO r_s00.*
	FROM srit000 
	WHERE s00_compania = cod_cia 
RETURN r_s00.*

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



FUNCTION fl_lee_tipo_retencion(cod_cia, tipo, porcentaje)
DEFINE cod_cia		LIKE ordt002.c02_compania
DEFINE tipo		LIKE ordt002.c02_tipo_ret
DEFINE porcentaje	LIKE ordt002.c02_porcentaje
DEFINE r		RECORD LIKE ordt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ordt002 
	WHERE c02_compania = cod_cia AND c02_tipo_ret = tipo AND 
	      c02_porcentaje = porcentaje
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



FUNCTION fl_lee_cuenta_padre(cod_cia, cuenta)
DEFINE cod_cia		LIKE ctbt010.b10_compania
DEFINE cuenta		LIKE ctbt010.b10_cuenta_padre
DEFINE r			RECORD LIKE ctbt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.*
	FROM ctbt010 
	WHERE b10_compania = cod_cia
	  AND b10_cuenta   = cuenta
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

DEFINE fecha_actual DATETIME YEAR TO SECOND

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
			LET fecha_actual = fl_current()
	        INSERT INTO ctbt005 VALUES (compania, tipo, ano, 0,0,0,0,0,0,0,
					    0,0,0,0,0, vg_usuario, fecha_actual)
		IF status < 0 THEN
			CALL fl_mostrar_mensaje('Error al insertar control secuencia en ctbt005', 'exclamation')
			LET numero = -1
			CLOSE q_ncompt
			FREE q_ncompt
			WHENEVER ERROR STOP
			RETURN numero
		END IF
	ELSE
		IF status < 0 THEN
			CALL fl_mostrar_mensaje('Secuencia esta bloqueada por otro proceso', 'exclamation')
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
	CALL fl_mostrar_mensaje('Error al actualizar secuencia del comprobante', 'exclamation')
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
	CALL fl_mostrar_mensaje('Flag mayorización incorrecto, debe ser M ó D', 'exclamation')
	RETURN
END IF
CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
IF r_cia.b00_cuenta_uti IS NULL THEN
	CALL fl_mostrar_mensaje('No está configurada la cuenta utilidad presente ejercicio.', 'exclamation')
	RETURN
END IF
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
	CALL fl_mostrar_mensaje('Comprobante a mayorizar no existe', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF status < 0 THEN
	CALL fl_mostrar_mensaje('Error al intentar bloquear comprobante para mayorizar', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF YEAR(r.b12_fec_proceso) < r_cia.b00_anopro THEN 
	CALL fl_mostrar_mensaje('El comprobante pertenece a un año que ya fue cerrado', 'exclamation')
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
FOREACH q_tmay INTO cuenta, debito, credito
	LET existe = 0
	WHILE NOT existe
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
			LET ano_aux = YEAR(r.b12_fec_proceso)
			INSERT INTO ctbt011 VALUES (codcia, cuenta,
				r_cia.b00_moneda_base, ano_aux,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0,0,0,0,0)
			IF status < 0 THEN
				--DROP TABLE temp_may
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Error al crear registro de saldos', 'exclamation')
				RETURN
			END IF
		ELSE
			IF status < 0 THEN
				--DROP TABLE temp_may
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Cuenta ' || cuenta || ' está bloqueada por otro usuario', 'exclamation')
				RETURN
			END IF
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
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
		RETURN
	END IF
END FOREACH
DROP TABLE temp_may
LET estado = 'M'
IF flag_may = 'D' THEN
	LET estado = 'A'
END IF
WHENEVER ERROR CONTINUE
UPDATE ctbt012 SET b12_estado = estado
	WHERE CURRENT OF q_mcomp
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Error al actualizar estado del comprobante ' || tipo || ' ' || numero, 'exclamation')
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION fl_mayoriza_comprobante_ult(codcia, tipo, numero, flag_may)
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
	CALL fl_mostrar_mensaje('Flag mayorización incorrecto, debe ser M ó D', 'exclamation')
	RETURN
END IF
CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
IF r_cia.b00_cuenta_uti IS NULL THEN
	CALL fl_mostrar_mensaje('No está configurada la cuenta utilidad presente ejercicio.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_mcomp2 CURSOR FOR
	SELECT * FROM ctbt012
		WHERE b12_compania  = codcia AND 
		      b12_tipo_comp = tipo AND 
		      b12_num_comp  = numero
		FOR UPDATE
OPEN q_mcomp2
FETCH q_mcomp2 INTO r.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Comprobante a mayorizar no existe', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF status < 0 THEN
	CALL fl_mostrar_mensaje('Error al intentar bloquear comprobante para mayorizar', 'exclamation')
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
DECLARE q_mdcomp2 CURSOR FOR 
	SELECT ctbt013.*, b10_tipo_cta FROM ctbt013, ctbt010
		WHERE b13_compania  = codcia AND
		      b13_tipo_comp = tipo   AND
		      b13_num_comp  = numero AND
		      b13_compania  = b10_compania AND
		      b13_cuenta    = b10_cuenta
FOREACH q_mdcomp2 INTO rd.*, tipo_cta
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
DECLARE q_tmay2 CURSOR FOR SELECT * FROM temp_may
	ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 20
FOREACH q_tmay2 INTO cuenta, debito, credito
	LET existe = 0
	WHILE NOT existe
		DECLARE q_msal2 CURSOR FOR
			SELECT * FROM ctbt011
				WHERE b11_compania = codcia AND 
		                      b11_moneda   = r_cia.b00_moneda_base AND
		                      b11_ano      = YEAR(r.b12_fec_proceso) AND
		                      b11_cuenta   = cuenta
			        FOR UPDATE
	        OPEN q_msal2 
		FETCH q_msal2 INTO r_sal.*
		IF status = NOTFOUND THEN
			CLOSE q_msal2
			LET ano_aux = YEAR(r.b12_fec_proceso)
			INSERT INTO ctbt011 VALUES (codcia, cuenta,
				r_cia.b00_moneda_base, ano_aux,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0,0,0,0,0)
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Error al crear registro de saldos', 'exclamation')
				RETURN
			END IF
		ELSE
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Cuenta ' || cuenta || ' está bloqueada por otro usuario', 'exclamation')
				RETURN
			END IF
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
				' WHERE CURRENT OF q_msal2' 
	PREPARE up_sal2 FROM expr_up
	EXECUTE	up_sal2 USING debito, credito
	IF status < 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
		RETURN
	END IF
END FOREACH
DROP TABLE temp_may
LET estado = 'M'
IF flag_may = 'D' THEN
	LET estado = 'A'
END IF
WHENEVER ERROR CONTINUE
UPDATE ctbt012 SET b12_estado = estado
	WHERE CURRENT OF q_mcomp2
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Error al actualizar estado del comprobante ' || tipo || ' ' || numero, 'exclamation')
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION fl_mayorizacion_mes(codcia, moneda, ano, mes, flag)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE moneda		LIKE ctbt012.b12_moneda
DEFINE ano		SMALLINT
DEFINE mes, flag	SMALLINT
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

DEFINE fecha_actual DATETIME YEAR TO SECOND

CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
IF r_cia.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Compañía no está configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF ano < r_cia.b00_anopro THEN 
	CALL fl_mostrar_mensaje('El ano ya está cerrado', 'exclamation')
	RETURN 0
END IF
IF mes < 1 OR mes > 12 THEN 
	CALL fl_mostrar_mensaje('Mes no está en el rango de 1 a 12', 'exclamation')
	RETURN 0
END IF
IF moneda IS NULL OR (moneda <> r_cia.b00_moneda_base AND 
	moneda <> r_cia.b00_moneda_aux) THEN
	CALL fl_mostrar_mensaje('Moneda no está configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF r_cia.b00_cuenta_uti IS NULL THEN
	CALL fl_mostrar_mensaje('No está configurada la cuenta utilidad presente ejercicio.', 'exclamation')
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
	LET fecha_actual = fl_current()
	INSERT INTO ctbt006 VALUES (codcia, ano, mes, vg_usuario, fecha_actual)
	LET num_row = SQLCA.SQLERRD[6]
END IF
ERROR 'Bloqueando maestro de saldos'
LOCK TABLE ctbt011 IN EXCLUSIVE MODE
IF status < 0 THEN
	CALL fl_mostrar_mensaje('No se pudo bloquear en modo exclusivo maestro de saldos. Asegúrese que nadie esté ingresando/modificando comprobantes en el sistema', 'exclamtion')
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
EXECUTE up_mesc USING codcia, moneda, ano	
DECLARE q_tcomp CURSOR FOR
	SELECT ctbt013.* FROM ctbt012, ctbt013
		WHERE b12_compania           = codcia AND 
		      YEAR(b12_fec_proceso)  = ano    AND
		      MONTH(b12_fec_proceso) = mes    AND
		      b12_estado <> 'E' AND
		      b12_compania           = b13_compania  AND 
		      b12_tipo_comp          = b13_tipo_comp AND 
		      b12_num_comp           = b13_num_comp 
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
CREATE INDEX i1_temp_may ON temp_may (te_cuenta)
LET num_ctas = 0
LET tot_db = 0
LET tot_cr = 0
ERROR 'Encerando maestro de saldos. Por favor espere ...'
FOREACH q_tcomp INTO rd.*
	MESSAGE 'Procesando cuenta: ', rd.b13_cuenta, '   ', num_ctas
	SELECT b10_tipo_cta INTO tipo_cta FROM ctbt010
		WHERE b10_compania = rd.b13_compania AND 
		      b10_cuenta   = rd.b13_cuenta
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Error no existe cuenta: ' || rd.b13_cuenta, 'exclamation')
		RETURN 0
	END IF
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
	MESSAGE 'Mayorizando cuenta: ', cuenta, '  ', num_act, '   ',
		debito, ' ', credito
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
				CALL fl_mostrar_mensaje('Error al crear registro de saldos.' || cuenta, 'exclamation')
				RETURN 0
			END IF
		ELSE
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Cuenta ' || cuenta || ' está bloqueada por otro usuario', 'exclamation')
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
		CALL fl_mostrar_mensaje('Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
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
	CALL fl_mostrar_mensaje('Error al actualizar estado de los comprobantes mayorizados ', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
DELETE FROM ctbt006 WHERE ROWID = num_row
COMMIT WORK
IF flag THEN
	CALL fl_mostrar_mensaje('Mayorización Terminó Correctamente.', 'info')
END IF
RETURN 1

END FUNCTION



FUNCTION fl_genera_niveles_mayorizacion_old(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE i, j, aux	SMALLINT
DEFINE ini, fin 	SMALLINT
DEFINE ceros		CHAR(10)
DEFINE rn		RECORD LIKE ctbt001.*

DECLARE q_niv CURSOR FOR SELECT * FROM ctbt001
	ORDER BY b01_nivel DESC
LET i = 0
FOREACH q_niv INTO rn.*
	LET i = i + 1
	IF i = 1 THEN
		LET aux = rn.b01_posicion_i - 1
		CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET cuenta = cuenta[1, aux]
	ELSE
		CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET ceros = NULL
		FOR j = rn.b01_posicion_i TO rn.b01_posicion_f
			LET ceros = ceros CLIPPED, '0'
		END FOR
		LET ini = rn.b01_posicion_i
		LET fin = rn.b01_posicion_f
		LET cuenta[ini, fin] = ceros CLIPPED
	END IF
END FOREACH

END FUNCTION



FUNCTION fl_genera_niveles_mayorizacion(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE r_b10		RECORD LIKE ctbt010.*

CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
WHILE TRUE
	CALL fl_lee_cuenta(vg_codcia, cuenta) RETURNING r_b10.*
	IF r_b10.b10_cuenta_padre IS NULL THEN
		EXIT WHILE
	END IF
	CALL fl_inserta_temporal_mayorizacion(r_b10.b10_cuenta_padre, debito,
											credito)
	LET cuenta = r_b10.b10_cuenta_padre
END WHILE

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
DEFINE val_db		LIKE ctbt011.b11_db_ano_ant
DEFINE val_cr		LIKE ctbt011.b11_cr_ano_ant
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
	CALL fl_mostrar_mensaje('No existe cuenta: ' || cuenta, 
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
	SELECT * INTO r_sal1.* FROM ctbt011 
		WHERE b11_compania = codcia AND 
		      b11_cuenta   = cuenta AND
		      b11_moneda   = moneda AND 
		      b11_ano      = ano_ant
END IF	
LET val_db = 0
LET val_cr = 0
IF ano_ant >= 2012 AND r_sal1.b11_db_ano_ant = 0 AND r_sal1.b11_cr_ano_ant = 0
THEN
	SELECT b11_db_ano_ant, b11_cr_ano_ant
		INTO val_db, val_cr
		FROM t_bal_gen 
		WHERE b11_compania = codcia
		  AND b11_cuenta   = cuenta
		  AND b11_moneda   = moneda
		  AND b11_ano      = ano_ant
END IF
LET r_sal.b11_db_ano_ant = r_sal.b11_db_ano_ant  + val_db +
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
LET r_sal.b11_cr_ano_ant = r_sal.b11_cr_ano_ant  + val_cr +
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



FUNCTION fl_lee_tipo_pago_caja(cod_cia, tipo, tipo_p)
DEFINE cod_cia		LIKE cajt001.j01_compania
DEFINE tipo		LIKE cajt001.j01_codigo_pago
DEFINE tipo_p		LIKE cajt001.j01_cont_cred
DEFINE r		RECORD LIKE cajt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cajt001 
	WHERE j01_compania    = cod_cia
	  AND j01_codigo_pago = tipo
	  AND j01_cont_cred   = tipo_p
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
	CALL fl_mostrar_mensaje('No existe moneda: ' ||  moneda, 'stop')
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

WHENEVER ERROR CONTINUE
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
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	LET r.g15_numero = 0
ELSE
	IF status < 0 THEN
		CALL fl_mostrar_mensaje('Secuencia está bloqueada por otro proceso', 'exclamation')
		LET r.g15_numero = -1
	ELSE
		LET r.g15_numero = r.g15_numero + 1
		UPDATE gent015 SET g15_numero = r.g15_numero
			WHERE CURRENT OF q_csec
		IF status < 0 THEN
			CALL fl_mostrar_mensaje('No se actualizó control secuencia', 'exclamation')
			LET r.g15_numero = -1
		END IF
	END IF
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
RETURN r.g15_numero

END FUNCTION



FUNCTION fl_retorna_num_tran_activo(codcia, codigo_tran) 
DEFINE codcia 		LIKE actt005.a05_compania
DEFINE codigo_tran	LIKE actt005.a05_codigo_tran
DEFINE numero		LIKE actt005.a05_numero
DEFINE mensaje		VARCHAR(60)

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE up_tact CURSOR FOR
	SELECT a05_numero FROM actt005
		WHERE a05_compania    = codcia
		  AND a05_codigo_tran = codigo_tran
	FOR UPDATE
OPEN up_tact
FETCH up_tact INTO numero
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe control secuencia en actt005: ',
		       codcia USING '<&', ' transacción: ', codigo_tran
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	LET numero = 0
ELSE
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('Secuencia está bloqueada por otro proceso', 'exclamation')
		LET numero = -1
	ELSE
		LET numero = numero + 1
		UPDATE actt005 SET a05_numero = numero
			WHERE CURRENT OF up_tact
		IF STATUS < 0 THEN
			CALL fl_mostrar_mensaje('No se actualizó control secuencia', 'exclamation')
			LET numero = -1
		END IF
	END IF
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
RETURN numero

END FUNCTION



FUNCTION fl_mensaje_registro_ingresado()

CALL fl_mostrar_mensaje('Registro grabado Ok.', 'info')

END FUNCTION



FUNCTION fl_mensaje_registro_modificado()

CALL fl_mostrar_mensaje('Registro actualizado Ok.', 'info')

END FUNCTION



FUNCTION fl_mensaje_consultar_primero()

CALL fl_mostrar_mensaje('Ejecute una consulta primero', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_bloqueo_otro_usuario()

CALL fl_mostrar_mensaje('Registro esta siendo modificado por otro usuario','exclamation')

END FUNCTION



FUNCTION fl_mensaje_consulta_sin_registros()

CALL fl_mostrar_mensaje('No se encontraron registros con el criterio indicado', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_estado_bloqueado()

CALL fl_mostrar_mensaje('Registro esta bloqueado', 'exclamation')

END FUNCTION


FUNCTION fl_mensaje_clave_erronea()

CALL fl_mostrar_mensaje('Clave digitada esta errónea', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_abandonar_proceso()
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Realmente desea abandonar','No')
	RETURNING resp
RETURN resp

END FUNCTION



FUNCTION fl_mensaje_seguro_ejecutar_proceso()
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Seguro de ejecutar este proceso','No')
	RETURNING resp
RETURN resp

END FUNCTION



FUNCTION fl_mensaje_arreglo_lleno()
DEFINE resp		CHAR(6)

CALL fl_mostrar_mensaje('Imposible crear nuevo registro, abandone y vuelva a ejecutar', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_arreglo_incompleto()
DEFINE resp		CHAR(6)

CALL fl_mostrar_mensaje('No se pudo cargar todo el detalle, corregir dimensión del arreglo', 'stop')

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



FUNCTION fl_muestra_repuestos_orden_trabajo(cod_cia, cod_loc, num_ot, tipo)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE num_ot, orden	LIKE talt023.t23_orden
DEFINE r19_porc_impto	LIKE rept019.r19_porc_impto
DEFINE tipo		CHAR(1)
DEFINE r_cab		RECORD LIKE rept019.*
DEFINE r_det		RECORD LIKE rept020.*
DEFINE r		RECORD LIKE gent021.*
DEFINE r_item		RECORD LIKE rept010.*
DEFINE rot		RECORD LIKE talt023.*
DEFINE num_rows		SMALLINT
DEFINE i, num_rep	SMALLINT
DEFINE campo_orden	SMALLINT
DEFINE tipo_orden	CHAR(4)
DEFINE expr_sql		VARCHAR(100)
DEFINE query		CHAR(500)
DEFINE tot_bruto 	DECIMAL(12,2)
DEFINE tot_dscto 	DECIMAL(12,2)
DEFINE tot_sub	 	DECIMAL(12,2)
DEFINE tot_neto  	DECIMAL(12,2)
DEFINE tot_impto	DECIMAL(12,2)

-- Modificado por JCM (DEIMOS) para controlar el problema causado por la 
-- version anterior de la base informix que no soporta operaciones o 
-- expresiones dentro de una sentencia INSERT. 
-- Linea 3436. 
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
IF vg_gui = 1 THEN
	OPEN WINDOW w_drot AT 6,5 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf300"
	ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
ELSE
	OPEN WINDOW w_drot AT 6,3 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf300c"
	ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
END IF
IF vg_gui = 1 THEN
	DISPLAY 'Fecha'   TO tit_col1
	DISPLAY 'Tp'      TO tit_col2
	DISPLAY 'Número'  TO tit_col3
	DISPLAY 'I t e m' TO tit_col4
	DISPLAY 'Cant'    TO tit_col5
	DISPLAY 'Precio'  TO tit_col6
	DISPLAY 'Total'   TO tit_col7
END IF
ERROR "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)
CALL fl_lee_orden_trabajo(cod_cia, cod_loc, num_ot) RETURNING rot.*
LET orden = num_ot
DISPLAY BY NAME num_ot
CASE tipo
	WHEN 'F'
		LET expr_sql = '   AND r19_cod_tran = "FA"'
	WHEN 'D'
		LET expr_sql = '   AND r19_cod_tran IN ("AF", "DF")'
	WHEN 'T'
		LET expr_sql = NULL
END CASE
LET query = 'SELECT * FROM rept019 ',
		' WHERE r19_compania    = ', cod_cia,
		'   AND r19_localidad   = ', cod_loc,
		expr_sql CLIPPED,
		'   AND r19_ord_trabajo = ', orden
PREPARE cons_crot FROM query
DECLARE q_crot CURSOR FOR cons_crot
CREATE TEMP TABLE temp_drep
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_cod_tran	CHAR(2),
	 te_num_tran	DECIMAL(15,0),
	 te_item	CHAR(15),
	 te_cant_ven	DECIMAL(8,2),
	 te_precio 	DECIMAL(14,2),
	 te_subtotal	DECIMAL(14,2))
LET i = 0
LET tot_bruto = 0
LET tot_dscto = 0
LET tot_impto = 0
LET tot_neto  = 0
LET r19_porc_impto = 0
FOREACH q_crot INTO r_cab.*
	IF r_cab.r19_cod_tran = 'FA' OR r_cab.r19_cod_tran = 'DF' OR
	   r_cab.r19_cod_tran = 'AF'
	THEN
		LET r19_porc_impto = r_cab.r19_porc_impto
	END IF
	CALL fl_lee_cod_transaccion(r_cab.r19_cod_tran) RETURNING r.*
	IF r.g21_tipo = 'T' THEN
		CONTINUE FOREACH
	END IF
	LET i = i + 1
	IF r.g21_tipo = 'I' THEN
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
		IF r.g21_tipo = 'I' THEN
			LET r_det.r20_cant_ven = r_det.r20_cant_ven * -1
		END IF
		LET valor_bruto = r_det.r20_precio * r_det.r20_cant_ven
		INSERT INTO temp_drep VALUES (r_cab.r19_fecing, 
			r_cab.r19_cod_tran, r_cab.r19_num_tran, r_det.r20_item,
		        r_det.r20_cant_ven, r_det.r20_precio, 
			valor_bruto)
	END FOREACH
END FOREACH
ERROR "                                          " ATTRIBUTE(NORMAL)
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_drep
	CLOSE WINDOW w_drot
	RETURN
END IF
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
	LET tot_sub = tot_bruto - tot_dscto
	DISPLAY BY NAME tot_bruto, tot_dscto, tot_neto, tot_impto,
			r19_porc_impto, tot_sub
	LET num_rep = i - 1
	CALL set_count(num_rep)
	LET int_flag = 0
	DISPLAY ARRAY r_rep TO r_rep.*
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F5","Transacción")
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL fl_lee_item(cod_cia, r_rep[i].r20_item)
				--#RETURNING r_item.*
			--#MESSAGE i, ' de ', num_rep, '   ', r_item.r10_nombre
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_ver_transaccion_rep(cod_cia, cod_loc,
				r_rep[i].r20_cod_tran, r_rep[i].r20_num_tran)
			LET int_flag = 0
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



FUNCTION fl_muestra_mano_obra_orden_trabajo(cod_cia, cod_loc, num_ot, factor)
DEFINE cod_cia		LIKE talt024.t24_compania
DEFINE cod_loc		LIKE talt024.t24_localidad
DEFINE num_ot		LIKE talt024.t24_orden
DEFINE factor		SMALLINT
DEFINE r_mo		ARRAY [100] OF RECORD
				t24_descripcion	LIKE talt024.t24_descripcion,
				t24_puntos_opti	LIKE talt024.t24_puntos_opti,
				t24_puntos_real	LIKE talt024.t24_puntos_real,
				t24_porc_descto	LIKE talt024.t24_porc_descto,
				t24_valor_tarea	LIKE talt024.t24_valor_tarea
			END RECORD
DEFINE r_mo1		ARRAY [100] OF RECORD
				descri_tar	LIKE talt024.t24_descripcion,
				nombres		LIKE talt003.t03_nombres
			END RECORD
DEFINE num_rows		SMALLINT
DEFINE i, j, num_mo	SMALLINT
DEFINE campo_orden	SMALLINT
DEFINE tipo_orden	CHAR(4)
DEFINE query		CHAR(300)
DEFINE subtotal		DECIMAL(12,2)
DEFINE val_descto	DECIMAL(12,2)
DEFINE tot_tareas	DECIMAL(12,2)

LET num_rows = 100
IF vg_gui = 1 THEN
	OPEN WINDOW w_dmo AT 6,2 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf301"
		ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
ELSE
	OPEN WINDOW w_dmo AT 6,2 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf301c"
		ATTRIBUTE(FORM LINE FIRST, MESSAGE LINE LAST, BORDER)
END IF
ERROR "Seleccionando datos . . . espere por favor" ATTRIBUTE(NORMAL)
DISPLAY num_ot TO t24_orden
SELECT t24_codtarea, t24_descripcion, t24_puntos_opti, t24_puntos_real,
	t24_porc_descto, t24_val_descto, t24_valor_tarea, t24_secuencia,
	t24_mecanico, t24_ord_compra
	FROM talt024
	WHERE t24_compania  = cod_cia
	  AND t24_localidad = cod_loc
	  AND t24_orden     = num_ot
	INTO TEMP temp_dmo
DELETE FROM temp_dmo WHERE t24_ord_compra IS NOT NULL
SELECT COUNT(*), SUM(t24_valor_tarea), SUM(t24_val_descto),
	SUM(t24_valor_tarea - t24_val_descto)
	INTO num_mo, subtotal, val_descto, tot_tareas
	FROM temp_dmo
IF vg_gui = 1 THEN
	DISPLAY 'Descripción'  TO tit_col1
	DISPLAY 'T.Opt.'       TO tit_col2
	DISPLAY 'T.Real'       TO tit_col3
	DISPLAY 'Desc.'        TO tit_col4
	DISPLAY 'Valor Tarea'  TO tit_col5
END IF
IF num_mo = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_dmo
	CLOSE WINDOW w_dmo
	RETURN
END IF
LET campo_orden = 6
LET tipo_orden  = 'DESC' 
WHILE TRUE
	IF tipo_orden = 'DESC' THEN
		LET tipo_orden = 'ASC'
	ELSE
		LET tipo_orden = 'DESC'
	END IF
	LET query = 'SELECT t24_descripcion, t24_puntos_opti, ',
			't24_puntos_real, t24_val_descto, t24_valor_tarea, ',
			't24_secuencia, t24_descripcion, t03_nombres ',
			'FROM temp_dmo, talt003 ',
			'WHERE t03_compania = ', cod_cia,
			'  AND t03_mecanico = t24_mecanico ',
			'ORDER BY ', campo_orden, ' ', tipo_orden
	PREPARE dmo FROM query
	DECLARE q_dmo CURSOR FOR dmo
	LET i = 1
	FOREACH q_dmo INTO r_mo[i].*, j, r_mo1[i].*
		LET r_mo[i].t24_valor_tarea = r_mo[i].t24_valor_tarea * factor
		LET i = i + 1
	END FOREACH
	LET tot_tareas = tot_tareas * factor
	DISPLAY BY NAME subtotal, val_descto, tot_tareas
	LET int_flag = 0
	CALL set_count(num_mo)
	DISPLAY ARRAY r_mo TO r_mo.*
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_mo
			--#DISPLAY BY NAME r_mo1[i].*
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
DEFINE max_rows, i	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(500)
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_cp		RECORD LIKE cajt010.*
DEFINE r_dp		RECORD LIKE cajt011.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE r_pagc	ARRAY[20] OF RECORD
	j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
	nombre_bt	VARCHAR(20),
	j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
	j11_moneda	LIKE cajt011.j11_moneda,
	j11_valor	LIKE cajt011.j11_valor
	END RECORD

LET max_rows = 20
IF vg_gui = 1 THEN
	OPEN WINDOW w_pagc AT 6,10 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf302"
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
ELSE
	OPEN WINDOW w_pagc AT 6,10 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf302c"
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
END IF
IF vg_gui = 1 THEN
	DISPLAY 'TP'                  TO tit_col1 
	DISPLAY 'Banco/Tarjeta'       TO tit_col2 
	DISPLAY 'No. Cheque/Tarjeta'  TO tit_col3
	DISPLAY 'Mo.'                 TO tit_col4 
	DISPLAY 'V a l o r'           TO tit_col5
END IF
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli,
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
 	IF r_dp.j11_codigo_pago[1, 1] = 'T' THEN
		SELECT g10_nombre
			INTO r_pagc[i].nombre_bt
			FROM gent010
			WHERE g10_tarjeta = r_dp.j11_cod_bco_tarj
	ELSE
		IF r_dp.j11_codigo_pago = 'CH' OR
		   r_dp.j11_codigo_pago = 'DP'
		THEN
			SELECT g08_nombre
				INTO r_pagc[i].nombre_bt
				FROM gent008
				WHERE g08_banco = r_dp.j11_cod_bco_tarj
		ELSE
			CALL fl_lee_tipo_pago_caja(vg_codcia,
							r_dp.j11_codigo_pago,
							'R')
				RETURNING r_j01.*
			LET r_pagc[i].nombre_bt = r_j01.j01_nombre
		END IF
	END IF
	IF i = max_rows THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE q_dpagc
FREE q_dpagc
LET num_rows = i
IF num_rows = 0 THEN
	CALL fl_mostrar_mensaje('No hay registro de forma de pago en Caja', 'exclamation')
	CLOSE WINDOW w_pagc
	RETURN
END IF
LET int_flag = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_pagc TO r_pagc.*
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#MESSAGE i, ' de ', num_rows
		--#IF tip_doc = 'PG' THEN
			--#CALL dialog.keysetlabel("F5","Doc.Cancelados")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
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
DEFINE query		CHAR(500)
DEFINE moneda        	LIKE gent013.g13_moneda
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_dpc	ARRAY[100] OF RECORD
	z23_tipo_doc	LIKE cxct023.z23_tipo_doc,
	z23_num_doc	LIKE cxct023.z23_num_doc, 
	z23_div_doc	LIKE cxct023.z23_div_doc,
	valor		DECIMAL(14,2)
	END RECORD

LET max_rows = 100
IF vg_gui = 1 THEN
	OPEN WINDOW w_dpc AT 5,10 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf303"
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
ELSE
	OPEN WINDOW w_dpc AT 5,10 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf303c"
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
END IF
IF vg_gui = 1 THEN
	DISPLAY 'Tipo'                TO tit_col1 
	DISPLAY 'No. Documento'       TO tit_col2 
	DISPLAY 'Div'                 TO tit_col3
	DISPLAY 'V a l o r'           TO tit_col4
END IF
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli,
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
	CALL fl_mostrar_mensaje('No hay detalle de documentos cancelados', 'exclamation')
	CLOSE WINDOW w_dpc
	RETURN
END IF
LET int_flag = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_dpc TO r_dpc.*
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#MESSAGE i, ' de ', num_rows
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
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

SET LOCK MODE TO WAIT
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

SET LOCK MODE TO WAIT
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
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE i		SMALLINT
DEFINE num_row		INTEGER
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)
DEFINE mensaje		VARCHAR(250)

INITIALIZE r_doc.* TO NULL
WHENEVER ERROR CONTINUE
DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxct020
		WHERE z20_compania                  = cod_cia
		  AND z20_localidad                 = cod_loc
		  AND z20_codcli                    = codcli
		  AND z20_areaneg                   = areaneg
		  AND z20_cod_tran                  = cod_tran
		  AND z20_num_tran                  = num_tran
		  AND z20_saldo_cap + z20_saldo_int > 0
	FOR UPDATE
OPEN q_ddev
FETCH q_ddev INTO r_doc.*
IF STATUS < 0 THEN
	--ROLLBACK WORK
	CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
	LET mensaje = 'No se puede aplicar documentos para el cliente: ',
			codcli USING "<<<<<<&", '-', r_z01.z01_nomcli CLIPPED,
			', estan bloqueados los documentos por otro proceso. ',
			'Por favor llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	RETURN -1
END IF
CLOSE q_ddev
IF r_doc.z20_codcli IS NOT NULL AND r_doc.z20_codcli <> codcli THEN
	RETURN 0
END IF
INITIALIZE r_caju.* TO NULL
LET r_caju.z22_compania    = cod_cia
LET r_caju.z22_localidad   = cod_loc
LET r_caju.z22_codcli 	   = codcli
LET r_caju.z22_tipo_trn    = 'AJ'
LET r_caju.z22_num_trn 	   = fl_actualiza_control_secuencias(cod_cia, cod_loc,
							'CO', 'AA', 'AJ')
IF r_caju.z22_num_trn <= 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
LET r_caju.z22_areaneg 	   = areaneg
LET r_caju.z22_referencia  = 'DEV. FACT.: ', cod_tran, ' ',
				num_tran USING '<<<<<&'
LET r_caju.z22_fecha_emi   = TODAY
LET r_caju.z22_moneda 	   = moneda
LET r_caju.z22_paridad 	   = 1
IF r_caju.z22_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_caju.z22_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No hay factor de conversión','stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	LET r_caju.z22_paridad = r.g14_tasa
END IF	
LET r_caju.z22_tasa_mora   = 0
LET r_caju.z22_total_cap   = 0
LET r_caju.z22_total_int   = 0
LET r_caju.z22_total_mora  = 0
LET r_caju.z22_cobrador    = NULL
LET r_caju.z22_subtipo 	   = NULL
LET r_caju.z22_origen 	   = 'A'
LET r_caju.z22_fecha_elim  = NULL
LET r_caju.z22_tiptrn_elim = NULL
LET r_caju.z22_numtrn_elim = NULL
LET r_caju.z22_usuario 	   = vg_usuario
LET r_caju.z22_fecing 	   = fl_current()
INSERT INTO cxct022 VALUES (r_caju.*)
LET num_row = SQLCA.SQLERRD[6]
LET i = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_doc.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET mensaje = 'No se puede ajustar el documento ',
				r_doc.z20_tipo_doc, '-',
				r_doc.z20_num_doc CLIPPED,
				' para el código de cliente ',
				r_doc.z20_codcli USING "<<<<<<&", '.',
				'Por favor llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
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
WHENEVER ERROR STOP
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



FUNCTION fl_control_reportes_extendido()
DEFINE tit_impresion	CHAR(1)
DEFINE r_gen		RECORD LIKE gent007.*
DEFINE r_g07		RECORD LIKE gent007.*
DEFINE r_gen2		RECORD LIKE gent006.*
DEFINE codi_aux		LIKE gent006.g06_impresora
DEFINE nomi_aux		LIKE gent006.g06_nombre
DEFINE comando		VARCHAR(100)
DEFINE row_ini		SMALLINT

LET row_ini = 4
IF vg_gui = 0 THEN
	LET row_ini = 6
END IF
OPEN WINDOW w_forext AT row_ini, 9 WITH 10 ROWS, 63 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf311 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf311"
ELSE
	OPEN FORM f_ayuf311 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf304c"
END IF
DISPLAY FORM f_ayuf311
INITIALIZE codi_aux, comando TO NULL
LET tit_impresion = 'I'
INITIALIZE r_gen.g07_impresora TO NULL
DECLARE qu_repoext CURSOR FOR 
	SELECT g07_impresora FROM gent007 
		WHERE g07_user = vg_usuario AND g07_default = 'S'
OPEN qu_repoext
FETCH qu_repoext INTO r_gen.g07_impresora
CLOSE qu_repoext
CALL fl_lee_impresora(r_gen.g07_impresora) RETURNING r_gen2.*
DISPLAY BY NAME r_gen2.g06_nombre
LET int_flag = 0
INPUT BY NAME tit_impresion, r_gen.g07_impresora
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(g07_impresora) THEN
               		CALL fl_ayuda_impresoras(vg_usuario)
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
		IF tit_impresion = 'P' THEN
                        LET r_gen.g07_impresora = NULL
			CLEAR g07_impresora, g06_nombre
		END IF
	AFTER FIELD g07_impresora
		IF r_gen.g07_impresora IS NOT NULL THEN
			CALL fl_lee_impresora(r_gen.g07_impresora)
				RETURNING r_gen2.*
			IF r_gen2.g06_impresora IS NULL THEN
				CALL fl_mostrar_mensaje('Impresora no existe.','exclamation')
				NEXT FIELD g07_impresora
			END IF
			DISPLAY BY NAME r_gen2.g06_nombre
			CALL fl_lee_impresora_usr(vg_usuario,
							r_gen.g07_impresora)
				RETURNING r_g07.*
			IF r_g07.g07_impresora IS NULL THEN
				CALL fl_mostrar_mensaje('Esta impresora no esta asignada a este usuario.','exclamation')
				NEXT FIELD g07_impresora
			END IF
		ELSE
			CLEAR g06_nombre
		END IF
	AFTER INPUT
		IF tit_impresion = 'I' THEN
			IF r_gen.g07_impresora IS NULL THEN
				CALL fl_mostrar_mensaje('Escoja una Impresora.','exclamation')
				NEXT FIELD g07_impresora
			END IF
		END IF
END INPUT
IF NOT int_flag THEN
	IF tit_impresion = 'I' THEN
		LET comando = 'lpr -o raw -P ', r_gen.g07_impresora
	END IF
	IF tit_impresion = 'P' THEN
		LET comando = 'fglpager'
	END IF
	IF tit_impresion = 'A' THEN
		INITIALIZE r_gen2.g06_nombre TO NULL
		OPTIONS INPUT NO WRAP
		INPUT BY NAME r_gen2.g06_nombre
		LET comando = 'enscript -B -f Courier6.9 -o - | ps2pdf - ', 
					  FGL_GETENV('HOME') CLIPPED, vg_separador, 
                      '/tmp', vg_separador, r_gen2.g06_nombre, '.pdf'
	END IF
END IF
CLOSE WINDOW w_forext
RETURN tit_impresion, comando

END FUNCTION



FUNCTION fl_control_reportes()
DEFINE tit_impresion	CHAR(1)
DEFINE r_gen		RECORD LIKE gent007.*
DEFINE r_g07		RECORD LIKE gent007.*
DEFINE r_gen2		RECORD LIKE gent006.*
DEFINE codi_aux		LIKE gent006.g06_impresora
DEFINE nomi_aux		LIKE gent006.g06_nombre
DEFINE comando		VARCHAR(100)
DEFINE row_ini		SMALLINT

LET row_ini = 4
IF vg_gui = 0 THEN
	LET row_ini = 6
END IF
OPEN WINDOW w_for AT row_ini, 9 WITH 10 ROWS, 63 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf304 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf304"
ELSE
	OPEN FORM f_ayuf304 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf304c"
END IF
DISPLAY FORM f_ayuf304
INITIALIZE codi_aux, comando TO NULL
LET tit_impresion = 'I'
INITIALIZE r_gen.g07_impresora TO NULL
DECLARE qu_refle CURSOR FOR 
	SELECT g07_impresora FROM gent007 
		WHERE g07_user = vg_usuario AND g07_default = 'S'
OPEN qu_refle
FETCH qu_refle INTO r_gen.g07_impresora
CLOSE qu_refle
CALL fl_lee_impresora(r_gen.g07_impresora) RETURNING r_gen2.*
DISPLAY BY NAME r_gen2.g06_nombre
LET int_flag = 0
INPUT BY NAME tit_impresion, r_gen.g07_impresora
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(g07_impresora) THEN
               		CALL fl_ayuda_impresoras(vg_usuario)
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
		IF tit_impresion = 'P' THEN
                        LET r_gen.g07_impresora = NULL
			CLEAR g07_impresora, g06_nombre
		END IF
	AFTER FIELD g07_impresora
		IF r_gen.g07_impresora IS NOT NULL THEN
			CALL fl_lee_impresora(r_gen.g07_impresora)
				RETURNING r_gen2.*
			IF r_gen2.g06_impresora IS NULL THEN
				CALL fl_mostrar_mensaje('Impresora no existe.','exclamation')
				NEXT FIELD g07_impresora
			END IF
			DISPLAY BY NAME r_gen2.g06_nombre
			CALL fl_lee_impresora_usr(vg_usuario,
							r_gen.g07_impresora)
				RETURNING r_g07.*
			IF r_g07.g07_impresora IS NULL THEN
				CALL fl_mostrar_mensaje('Esta impresora no esta asignada a este usuario.','exclamation')
				NEXT FIELD g07_impresora
			END IF
		ELSE
			CLEAR g06_nombre
		END IF
	AFTER INPUT
		IF tit_impresion = 'I' THEN
			IF r_gen.g07_impresora IS NULL THEN
				CALL fl_mostrar_mensaje('Escoja una Impresora.','exclamation')
				NEXT FIELD g07_impresora
			END IF
		END IF
END INPUT
IF NOT int_flag THEN
	IF tit_impresion = 'I' THEN
		LET comando = 'lpr -o raw -P ', r_gen.g07_impresora
	END IF
	IF tit_impresion = 'P' THEN
		LET comando = 'fglpager'
	END IF
END IF
CLOSE WINDOW w_for
RETURN comando

END FUNCTION



FUNCTION fl_obtiene_costo_item(cod_cia, moneda, item, cant_ing, costo_ing)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE item		LIKE rept010.r10_codigo
DEFINE cant_ing		LIKE rept011.r11_stock_act
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE tot_stock	LIKE rept011.r11_stock_act
DEFINE costo_ing	DECIMAL(12,2)
DEFINE costo_act	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_art		RECORD LIKE rept010.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE ciudad		LIKE gent002.g02_ciudad
DEFINE codloc		LIKE gent002.g02_localidad

CALL fl_lee_compania_repuestos(cod_cia) RETURNING r_rep.*
IF r_rep.r00_tipo_costo <> 'P' THEN
	RETURN costo_ing
END IF
CALL fl_lee_localidad(cod_cia, vg_codloc) RETURNING r_g02.*
LET ciudad = r_g02.g02_ciudad
DECLARE qy_gy CURSOR FOR 
	SELECT r02_localidad, r11_stock_act FROM rept011, rept002
	WHERE r11_compania = cod_cia AND 
              r11_item     = item AND
	      r11_compania = r02_compania AND 
	      r11_bodega   = r02_codigo   AND 
              r02_tipo <> 'S' AND 
	      r11_stock_act > 0
LET tot_stock = 0
FOREACH qy_gy INTO codloc, stock
	CALL fl_lee_localidad(cod_cia, codloc) RETURNING r_g02.*
	IF r_g02.g02_ciudad <> ciudad THEN
		CONTINUE FOREACH
	END IF
	LET tot_stock = tot_stock + stock
END FOREACH	
CALL fl_lee_item(cod_cia, item) RETURNING r_art.*
IF moneda = rg_gen.g00_moneda_base THEN
	LET costo_act = r_art.r10_costo_mb
ELSE
	LET costo_act = r_art.r10_costo_ma
END IF
LET costo_nue = ((costo_act * tot_stock) + (costo_ing * cant_ing)) / 
		 (tot_stock + cant_ing)
CALL fl_retorna_precision_valor(moneda, costo_nue) RETURNING costo_nue
RETURN costo_nue

END FUNCTION



FUNCTION fl_obtiene_costo_item_tras(cod_cia, moneda, item, cant_ing, costo_ing)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE item		LIKE rept010.r10_codigo
DEFINE cant_ing		LIKE rept011.r11_stock_act
DEFINE costo_ing	DECIMAL(12,2)
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE tot_stock	LIKE rept011.r11_stock_act
DEFINE costo_act	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_art		RECORD LIKE rept010.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE ciudad		LIKE gent002.g02_ciudad
DEFINE codloc		LIKE gent002.g02_localidad

CALL fl_lee_compania_repuestos(cod_cia) RETURNING r_rep.*
IF r_rep.r00_tipo_costo <> 'P' THEN
	RETURN costo_ing
END IF
CALL fl_lee_localidad(cod_cia, vg_codloc) RETURNING r_g02.*
LET ciudad = r_g02.g02_ciudad
DECLARE qy_gy3 CURSOR FOR 
	SELECT r02_localidad, r11_stock_act
		FROM rept011, rept002
		WHERE r11_compania   = cod_cia
		  AND r11_item       = item
		  AND r11_compania   = r02_compania
		  AND r11_bodega     = r02_codigo
		  AND r02_tipo      <> 'S'
		  AND r11_stock_act  > 0
LET tot_stock = 0
FOREACH qy_gy3 INTO codloc, stock
	CALL fl_lee_localidad(cod_cia, codloc) RETURNING r_g02.*
	IF r_g02.g02_ciudad <> ciudad THEN
		CONTINUE FOREACH
	END IF
	LET tot_stock = tot_stock + stock
END FOREACH	
CALL fl_lee_item(cod_cia, item) RETURNING r_art.*
IF moneda = rg_gen.g00_moneda_base THEN
	LET costo_act = r_art.r10_costo_mb
ELSE
	LET costo_act = r_art.r10_costo_ma
END IF
LET tot_stock = tot_stock - cant_ing
LET costo_nue = ((costo_act * tot_stock) + (costo_ing * cant_ing)) / 
		 (tot_stock + cant_ing)
CALL fl_retorna_precision_valor(moneda, costo_nue) RETURNING costo_nue
RETURN costo_nue

END FUNCTION



FUNCTION fl_obtiene_costo_item_imp(cod_cia, moneda, item, cant_ing, costo_ing)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE item		LIKE rept010.r10_codigo
DEFINE cant_ing		LIKE rept011.r11_stock_act
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE tot_stock	LIKE rept011.r11_stock_act
DEFINE costo_ing	DECIMAL(22,10)
DEFINE costo_act	DECIMAL(22,10)
DEFINE costo_nue	DECIMAL(22,10)
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_art		RECORD LIKE rept010.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE ciudad		LIKE gent002.g02_ciudad
DEFINE codloc		LIKE gent002.g02_localidad

CALL fl_lee_compania_repuestos(cod_cia) RETURNING r_rep.*
IF r_rep.r00_tipo_costo <> 'P' THEN
	RETURN costo_ing
END IF
CALL fl_lee_localidad(cod_cia, vg_codloc) RETURNING r_g02.*
LET ciudad = r_g02.g02_ciudad
DECLARE qy_gy2 CURSOR FOR 
	SELECT r02_localidad, r11_stock_act FROM rept011, rept002
	WHERE r11_compania = cod_cia AND 
              r11_item     = item AND
	      r11_compania = r02_compania AND 
	      r11_bodega   = r02_codigo   AND 
              r02_tipo <> 'S' AND 
	      r11_stock_act > 0
LET tot_stock = 0
FOREACH qy_gy2 INTO codloc, stock
	CALL fl_lee_localidad(cod_cia, codloc) RETURNING r_g02.*
	IF r_g02.g02_ciudad <> ciudad THEN
		CONTINUE FOREACH
	END IF
	LET tot_stock = tot_stock + stock
END FOREACH	
CALL fl_lee_item(cod_cia, item) RETURNING r_art.*
IF moneda = rg_gen.g00_moneda_base THEN
	LET costo_act = r_art.r10_costo_mb
ELSE
	LET costo_act = r_art.r10_costo_ma
END IF
LET costo_nue = ((costo_act * tot_stock) + (costo_ing * cant_ing)) / 
		 (tot_stock + cant_ing)
RETURN costo_nue

END FUNCTION



FUNCTION fl_retorna_letras(moneda, valor)
DEFINE moneda		CHAR(2)
DEFINE valor		DECIMAL(12,2)
DEFINE entero		DECIMAL(10,0)
DEFINE centavos		DECIMAL(2,0)
DEFINE j, k, l, m	SMALLINT
DEFINE renglon		VARCHAR(150)

IF valor IS NULL THEN
	LET valor = 0
END IF
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
SELECT TRUNC(valor,0) INTO entero FROM dual
LET centavos = (valor - entero) * 100
CALL fl_algoritmo_conversion_letras(moneda, entero) RETURNING renglon
IF moneda = rg_gen.g00_moneda_base THEN
	LET renglon = renglon CLIPPED, " DOLARES CON ", centavos USING "&&", 
		      " CENTAVOS" 
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
DEFINE r_t00		RECORD LIKE talt000.*
DEFINE tipo		LIKE ordt011.c11_tipo
DEFINE valor		DECIMAL(14,2)
DEFINE val_rep		DECIMAL(14,2)
DEFINE val_mo		DECIMAL(14,2)

CALL fl_lee_configuracion_taller(cod_cia) RETURNING r_t00.*
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE cu_blot CURSOR FOR 
	SELECT * FROM talt023
		WHERE t23_compania  = cod_cia AND 
	              t23_localidad = cod_loc AND 
	              t23_orden     = orden
		FOR UPDATE
OPEN cu_blot
FETCH cu_blot INTO r.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje( 'No existe O.T. ' || orden, 'stop')
	RETURN
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje( 'Otro proceso tiene bloqueada ' ||
					 'a la O.T. ' || orden, 'stop')
	RETURN
END IF
WHENEVER ERROR STOP
IF r.t23_estado <> 'A' AND r.t23_estado <> 'C' THEN
	ROLLBACK WORK
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
IF r_t00.t00_req_tal = 'S' THEN
	DECLARE cu_derep CURSOR FOR 
		SELECT g21_tipo, SUM(r19_tot_bruto - r19_tot_dscto)
		FROM rept019, gent021
		WHERE r19_compania    = cod_cia AND 
	              r19_localidad   = cod_loc AND 
	              r19_ord_trabajo = orden   AND 
	              g21_cod_tran    = r19_cod_tran AND
	              g21_tipo IN ('I','E')
	        GROUP BY 1
        FOREACH cu_derep INTO tipo, valor
	        IF tipo = 'I' THEN
		        LET valor = valor * -1
	        END IF
	        LET r.t23_val_rp_alm = r.t23_val_rp_alm + valor
        END FOREACH
END IF
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
	SELECT c11_tipo, (c11_cant_ped * c11_precio) - c11_val_descto
		FROM ordt011
		WHERE c11_compania  = rc.c10_compania  AND 
		      c11_localidad = rc.c10_localidad AND 
		      c11_numero_oc = rc.c10_numero_oc
	LET val_rep = 0
	LET val_mo  = 0
	FOREACH cu_doc INTO tipo, valor
		LET valor = valor + (valor * rc.c10_recargo / 100)
		LET valor = fl_retorna_precision_valor(rc.c10_moneda, valor)
		IF tipo = 'B' THEN
			LET val_rep = val_rep + valor
		ELSE
			LET val_mo  = val_mo  + valor
		END IF
	END FOREACH
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
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Inventarios', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_cxc(cod_cia)
DEFINE cod_cia          LIKE cxct000.z00_compania
DEFINE r_z00            RECORD LIKE cxct000.*

CALL fl_lee_compania_cobranzas(cod_cia) RETURNING r_z00.*
IF MONTH(TODAY) <> r_z00.z00_mespro THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Cobranzas', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_cxp(cod_cia)
DEFINE cod_cia          LIKE cxpt000.p00_compania
DEFINE r_p00            RECORD LIKE cxpt000.*

CALL fl_lee_compania_tesoreria(cod_cia) RETURNING r_p00.*
IF MONTH(TODAY) <> r_p00.p00_mespro THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Tesorería', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_veh(cod_cia)
DEFINE cod_cia          LIKE veht000.v00_compania
DEFINE r_v00            RECORD LIKE veht000.*

CALL fl_lee_compania_vehiculos(cod_cia) RETURNING r_v00.*
IF MONTH(TODAY) <> r_v00.v00_mespro THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Vehículos', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_rol(cod_cia)
DEFINE cod_cia          LIKE rolt001.n01_compania
DEFINE r_n01            RECORD LIKE rolt001.*

CALL fl_lee_compania_roles(cod_cia) RETURNING r_n01.*
IF MONTH(TODAY) <> r_n01.n01_mes_proceso THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Nomina.', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_tal(cod_cia)
DEFINE cod_cia		LIKE talt000.t00_compania
DEFINE r_t00		RECORD LIKE talt000.*

CALL fl_lee_configuracion_taller(cod_cia) RETURNING r_t00.*
IF MONTH(TODAY) <> r_t00.t00_mespro THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Taller.', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_sri(cod_cia)
DEFINE cod_cia		LIKE srit000.s00_compania
DEFINE r_s00		RECORD LIKE srit000.*

CALL fl_lee_configuracion_sri(cod_cia) RETURNING r_s00.*
IF MONTH(TODAY) <> r_s00.s00_mes_proceso THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de SRI.', 'stop')
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
	CALL fl_mostrar_mensaje( 'La Caja ya ha sido cerrada', 'stop')
ELSE
	IF cod_return = 2 THEN
		CALL fl_mostrar_mensaje( 'La Caja no ha sido aperturada aún', 'stop')
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



FUNCTION fl_lee_electrico_rep(cod_cia, electrico)
DEFINE cod_cia		LIKE rept074.r74_compania
DEFINE electrico	LIKE rept074.r74_electrico
DEFINE r		RECORD LIKE rept074.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept074 
	WHERE r74_compania  = cod_cia
	  AND r74_electrico = electrico
RETURN r.*

END FUNCTION



FUNCTION fl_lee_color_rep(cod_cia, item, marca, color)
DEFINE cod_cia		LIKE rept075.r75_compania
DEFINE item		LIKE rept075.r75_item
DEFINE marca		LIKE rept075.r75_marca
DEFINE color		LIKE rept075.r75_color
DEFINE r		RECORD LIKE rept075.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept075 
	WHERE r75_compania = cod_cia
	  AND r75_item     = item
	  AND r75_marca	   = marca
	  AND r75_color	   = color
RETURN r.*

END FUNCTION



FUNCTION fl_lee_serie_rep(cod_cia, cod_loc, bodega, item, serie)
DEFINE cod_cia		LIKE rept076.r76_compania
DEFINE cod_loc		LIKE rept076.r76_localidad
DEFINE bodega		LIKE rept076.r76_bodega
DEFINE item		LIKE rept076.r76_item
DEFINE serie		LIKE rept076.r76_serie
DEFINE r		RECORD LIKE rept076.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept076 
	WHERE r76_compania  = cod_cia
	  AND r76_localidad = item
	  AND r76_bodega    = bodega
	  AND r76_item      = item
	  AND r76_serie	    = serie
RETURN r.*

END FUNCTION



FUNCTION fl_lee_factor_utilidad_rep(cod_cia, util)
DEFINE cod_cia		LIKE rept077.r77_compania
DEFINE util		LIKE rept077.r77_codigo_util
DEFINE r		RECORD LIKE rept077.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept077 
	WHERE r77_compania    = cod_cia
	  AND r77_codigo_util = util
RETURN r.*

END FUNCTION



FUNCTION fl_lee_num_sri_gen(cod_cia, cod_loc, tipo_doc, secuencia)
DEFINE cod_cia		LIKE gent037.g37_compania
DEFINE cod_loc		LIKE gent037.g37_localidad
DEFINE tipo_doc		LIKE gent037.g37_tipo_doc
DEFINE secuencia	LIKE gent037.g37_secuencia
DEFINE r		RECORD LIKE gent037.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent037
	WHERE g37_compania  = cod_cia
	  AND g37_localidad = cod_loc
	  AND g37_tipo_doc  = tipo_doc
	  AND g37_secuencia = secuencia
RETURN r.*

END FUNCTION



FUNCTION fl_mostrar_mensaje(texto, tipo_icono)
DEFINE texto		CHAR(400)
DEFINE tipo_icono	CHAR(11)
DEFINE car_lin, i	SMALLINT
DEFINE ind_ini, ind_fin	SMALLINT
DEFINE num_lin, aux	SMALLINT
DEFINE r_lineas	ARRAY[10] OF VARCHAR(60)
DEFINE long_text, key	SMALLINT

IF vg_gui = 1 THEN
	--#CALL fgl_winmessage(vg_producto, texto, tipo_icono)
ELSE
	LET car_lin = 60
	LET num_lin = 1
	LET long_text = LENGTH(texto)
{
	IF long_text <= 80 AND UPSHIFT(tipo_icono) <> 'STOP' AND 
		UPSHIFT(tipo_icono) <> 'INFO' THEN
		ERROR texto ATTRIBUTE(REVERSE, BLINK)
		RETURN
	END IF
}
	LET num_lin = 0
	LET ind_ini = 1
	LET ind_fin = car_lin
	WHILE TRUE
		IF long_text <= car_lin THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto
			EXIT WHILE
		END IF
		IF texto[ind_fin, ind_fin] = ' ' THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto[ind_ini, ind_fin - 1]
			LET ind_ini = ind_fin + 1
			LET ind_fin = ind_fin + car_lin
			IF ind_fin > long_text THEN
				LET num_lin = num_lin + 1
				LET r_lineas[num_lin] = 
					texto[ind_ini, long_text]
				EXIT WHILE
			END IF	
		ELSE
			LET ind_fin = ind_fin - 1
		END IF
	END WHILE		
	LET aux = num_lin + 1
	OPEN WINDOW w_men AT 10,10 WITH aux ROWS, 62 COLUMNS
		ATTRIBUTE(BORDER)
	CASE UPSHIFT(tipo_icono)
		WHEN 'STOP'
			LET aux = (car_lin - 13) / 2
			DISPLAY ' ERROR FATAL ' AT 1, aux ATTRIBUTE(REVERSE)
		WHEN 'INFO'
			LET aux = (car_lin - 7) / 2
			DISPLAY ' AVISO ' AT 1, aux ATTRIBUTE(REVERSE)
		OTHERWISE
			LET aux = (car_lin - 7) / 2
			DISPLAY ' ERROR ' AT 1, aux ATTRIBUTE(REVERSE)
	END CASE
	FOR i = 1 TO num_lin
		LET aux = i + 1
		DISPLAY r_lineas[i] AT aux,2
	END FOR
	LET key = FGL_GETKEY()
	CLOSE WINDOW w_men
END IF

END FUNCTION



FUNCTION fl_hacer_pregunta(texto, resp_default)
DEFINE texto		CHAR(400)
DEFINE resp_default	CHAR(3)
DEFINE resp		CHAR(3)
DEFINE car_lin, i	SMALLINT
DEFINE ind_ini, ind_fin	SMALLINT
DEFINE num_lin, aux	SMALLINT
DEFINE r_lineas	ARRAY[10] OF VARCHAR(60)
DEFINE long_text, key	SMALLINT
DEFINE num_col, pos_y  	SMALLINT
DEFINE opcion		CHAR(1)

IF vg_gui = 1 THEN
	--#CALL fgl_winquestion(vg_producto, texto, resp_default,'Yes|No','question',1) RETURNING resp
ELSE
	LET car_lin = 60
	LET num_lin = 1
	LET texto = texto CLIPPED, '?'
	LET long_text = LENGTH(texto)
	LET num_lin = 0
	LET ind_ini = 1
	LET ind_fin = car_lin
	LET num_col = car_lin + 2
	WHILE TRUE
		IF long_text <= car_lin THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto
			LET num_col = long_text + 2
			EXIT WHILE
		END IF
		IF texto[ind_fin, ind_fin] = ' ' THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto[ind_ini, ind_fin - 1]
			LET ind_ini = ind_fin + 1
			LET ind_fin = ind_fin + car_lin
			IF ind_fin > long_text THEN
				LET num_lin = num_lin + 1
				LET r_lineas[num_lin] = 
					texto[ind_ini, long_text]
				EXIT WHILE
			END IF	
		ELSE
			LET ind_fin = ind_fin - 1
		END IF
	END WHILE		
	LET aux = num_lin + 2
	LET pos_y = (80 - num_col) / 2
	OPEN WINDOW w_preg AT 10,pos_y WITH aux ROWS, num_col COLUMNS
		ATTRIBUTE(BORDER, PROMPT LINE LAST)
	DISPLAY ' PREGUNTA '
	LET aux = (num_col - 10) / 2
	DISPLAY ' PREGUNTA ' AT 1,aux ATTRIBUTE(REVERSE)
	FOR i = 1 TO num_lin
		LET aux = i + 1
		DISPLAY r_lineas[i] AT aux,2
	END FOR
      	LET opcion = "k" 
      	WHILE opcion NOT MATCHES "[SsNn]" 
	 	PROMPT " Presione (S/N) ==> " 
			FOR CHAR opcion   
	     		ON KEY(INTERRUPT)
	     			LET opcion = "q"
	 	END PROMPT
	 	IF opcion IS NULL THEN
	    		LET opcion = "k"
	    		CONTINUE WHILE
	 	END IF
      	END WHILE
      	IF opcion MATCHES "[Ss]" THEN
		LET resp = 'Yes'
	ELSE
		LET resp = 'No'
	END IF
	CLOSE WINDOW w_preg
END IF
RETURN resp

END FUNCTION



FUNCTION fl_validar_parametros()
DEFINE mensaje		VARCHAR(100)

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	LET mensaje = 'No existe módulo: ' || vg_modulo
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	LET mensaje = 'No existe compañía: '|| vg_codcia
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	LET mensaje = 'Compañía no está activa: ' || vg_codcia
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	LET mensaje = 'No existe localidad: ' || vg_codloc
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	LET mensaje = 'Localidad no está activa: '|| vg_codloc
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fl_mostrar_mensaje('Combinación compañía/localidad no existe.', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_visor_teclas_caracter()

OPEN WINDOW w_tf AT 2,5 WITH 18 ROWS, 60 COLUMNS 
	ATTRIBUTE(BORDER)			
DISPLAY ' *** TECLAS FUNCIONALES *** ' AT 1,16 ATTRIBUTE(REVERSE) 
DISPLAY 'Teclas Fijas:' AT 2,2 ATTRIBUTE(REVERSE)	
DISPLAY '<F12>	   Grabar, Aceptar' AT 3,2
DISPLAY  'F12'     AT 3,3 ATTRIBUTE(REVERSE)
DISPLAY '<Delete>  Abandonar consulta-proceso-reporte' AT 4,2
DISPLAY  'Delete'  AT 4,3 ATTRIBUTE(REVERSE)
DISPLAY '<F2>      Lista de Valores' AT 5,2
DISPLAY  'F2'      AT 5,3 ATTRIBUTE(REVERSE)
DISPLAY '<F3>      Ver siguiente desplieque de datos' AT 6,2
DISPLAY  'F3'      AT 6,3 ATTRIBUTE(REVERSE)
DISPLAY '<F4>      Ver anterior desplieque de datos' AT 7,2
DISPLAY  'F4'      AT 7,3 ATTRIBUTE(REVERSE)
--DISPLAY '<F9>      Imprimir' AT 8,2
--DISPLAY  'F9'      AT 8,3 ATTRIBUTE(REVERSE)
DISPLAY '<F10>     Insertar nuevo renglón'   AT 9,2
DISPLAY  'F10'     AT 9,3 ATTRIBUTE(REVERSE)
DISPLAY '<F11>     Borrar renglón corriente' AT 10,2
DISPLAY  'F11'     AT 10,3 ATTRIBUTE(REVERSE)
RETURN 10        -- Retorna el # líneas displayadas.
-- La ventana queda abierta para que el programa que la llama
-- displaye sus teclas respectivas. El programa que la llama 
-- deberá cerrar la ventana.

END FUNCTION



FUNCTION fl_retorna_sublinea_rep(codcia, sub)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE sub		LIKE rept010.r10_sub_linea
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE flag		SMALLINT

LET flag = 1
INITIALIZE r_r70.* TO NULL
DECLARE q_sub CURSOR FOR
		SELECT * FROM rept070
			WHERE r70_compania  = codcia
			  AND r70_sub_linea = sub
OPEN q_sub
FETCH q_sub INTO r_r70.*
IF STATUS = NOTFOUND THEN
	LET flag = 0
END IF 
CLOSE q_sub
RETURN r_r70.*, flag

END FUNCTION



FUNCTION fl_retorna_grupo_rep(codcia, grp)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE grp		LIKE rept010.r10_cod_grupo
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE flag		SMALLINT

LET flag = 1
INITIALIZE r_r71.* TO NULL
DECLARE q_grp CURSOR FOR
		SELECT * FROM rept071
			WHERE r71_compania  = codcia
			  AND r71_cod_grupo = grp
OPEN q_grp
FETCH q_grp INTO r_r71.*
IF STATUS = NOTFOUND THEN
	LET flag = 0
END IF 
CLOSE q_grp
RETURN r_r71.*, flag

END FUNCTION



FUNCTION fl_retorna_clase_rep(codcia, cla)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE cla		LIKE rept010.r10_cod_clase
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE flag		SMALLINT

LET flag = 1
INITIALIZE r_r72.* TO NULL
DECLARE q_cla CURSOR FOR
		SELECT * FROM rept072
			WHERE r72_compania  = codcia
			  AND r72_cod_clase = cla
OPEN q_cla
FETCH q_cla INTO r_r72.*
IF STATUS = NOTFOUND THEN
	LET flag = 0
END IF 
CLOSE q_cla
RETURN r_r72.*, flag

END FUNCTION



FUNCTION fl_valida_decimales_unidad_medida(codcia, item, cantidad)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE item		LIKE rept010.r10_codigo
DEFINE cantidad		DECIMAL(12,2)
DEFINE cant_aux		DECIMAL(10,0)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r05		RECORD LIKE rept005.*

CALL fl_lee_item(codcia, item) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	RETURN cantidad
END IF
CALL fl_lee_unidad_medida(r_r10.r10_uni_med) RETURNING r_r05.*
IF r_r05.r05_decimales = 'N' THEN
	LET cant_aux = cantidad
	RETURN cant_aux
END IF
RETURN cantidad

END FUNCTION



FUNCTION fl_retorna_formato_sec_sri(sec_num, num_dig)
DEFINE sec_num		LIKE gent037.g37_sec_num_sri
DEFINE num_dig		LIKE gent037.g37_num_dig_sri
DEFINE num_for		VARCHAR(10)

CASE num_dig
	WHEN 1
		LET num_for = sec_num USING "&"
	WHEN 2
		LET num_for = sec_num USING "&&"
	WHEN 3
		LET num_for = sec_num USING "&&&"
	WHEN 4
		LET num_for = sec_num USING "&&&&"
	WHEN 5
		LET num_for = sec_num USING "&&&&&"
	WHEN 6
		LET num_for = sec_num USING "&&&&&&"
	WHEN 7
		LET num_for = sec_num USING "&&&&&&&"
	WHEN 8
		LET num_for = sec_num USING "&&&&&&&&"
	WHEN 9
		LET num_for = sec_num USING "&&&&&&&&&"
END CASE
RETURN num_for CLIPPED

END FUNCTION



FUNCTION fl_validacion_num_sri(cod_cia, cod_loc, tipo_doc, cont_cred, num_sri)
DEFINE cod_cia		LIKE gent037.g37_compania
DEFINE cod_loc		LIKE gent037.g37_localidad
DEFINE tipo_doc		LIKE gent037.g37_tipo_doc
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE num_sri_f	LIKE rept038.r38_num_sri
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_g39		RECORD LIKE gent039.*
DEFINE flag, lim	SMALLINT
DEFINE sec_sri		VARCHAR(12)
DEFINE cont		INTEGER

INITIALIZE r_g37.* TO NULL
LET flag = 1
IF tipo_doc = 'FA' OR tipo_doc = 'GR' THEN
	SELECT COUNT(*) INTO cont
		FROM gent037
		WHERE g37_compania   = cod_cia
		  AND g37_localidad  = cod_loc
		  AND g37_tipo_doc   = tipo_doc
		{--
		  AND g37_fecha_emi <= DATE(TODAY)
		  AND g37_fecha_exp >= DATE(TODAY)
		--}
		  AND g37_secuencia IN
			(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = cod_cia
				  AND g37_localidad = cod_loc
				  AND g37_tipo_doc  = tipo_doc)
	IF cont = 1 THEN
		LET cont_cred = "N"
	END IF
END IF
DECLARE q_g37 CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania  =  cod_cia
		  AND g37_localidad =  cod_loc
		  AND g37_tipo_doc  =  tipo_doc
		  AND g37_cont_cred =  cont_cred
		{--
		  AND g37_fecha_emi <= DATE(TODAY)
		  AND g37_fecha_exp >= DATE(TODAY)
		--}
		  AND g37_secuencia IN
			(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = cod_cia
				  AND g37_localidad = cod_loc
				  AND g37_tipo_doc  = tipo_doc)
OPEN q_g37
FETCH q_g37 INTO r_g37.*
IF STATUS = NOTFOUND THEN
	CLOSE q_g37
	FREE q_g37
	CALL fl_mostrar_mensaje('No existe configurado registro del SRI para el tipo de documento ' || tipo_doc || '.','stop')
	LET flag = -1
	RETURN r_g37.*, num_sri, flag
END IF
CALL fl_retorna_formato_sec_sri(r_g37.g37_sec_num_sri + 1,r_g37.g37_num_dig_sri)
	RETURNING sec_sri
CALL fl_lee_num_sri_gen(cod_cia, cod_loc, tipo_doc, r_g37.g37_secuencia)
	RETURNING r_g37.*
IF num_sri IS NULL THEN
	LET num_sri = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			sec_sri
	RETURN r_g37.*, num_sri, flag
END IF
LET lim = 8 + r_g37.g37_num_dig_sri
IF num_sri[4,4] <> "-" THEN
	LET num_sri[5,lim] = num_sri[4,lim]
	LET num_sri[4,4] = '-'
END IF
IF num_sri[8,8] <> "-" THEN
	LET num_sri[9,lim] = num_sri[8,lim]
	LET num_sri[8,8] = '-'
END IF
IF num_sri[1,3] <> r_g37.g37_pref_sucurs THEN
	CALL fl_mostrar_mensaje('No existe para esta localidad el prefijo ' || num_sri[1,3] || ' reconocido para el SRI.','exclamation')
	LET flag = 0
	LET num_sri = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			sec_sri
	RETURN r_g37.*, num_sri, flag
END IF
IF num_sri[5,7] <> r_g37.g37_pref_pto_vta THEN
	CALL fl_mostrar_mensaje('No existe para este punto de venta el prefijo ' || num_sri[5,7] || ' reconocido para el SRI.','exclamation')
	LET flag = 0
	LET num_sri = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			sec_sri
	RETURN r_g37.*, num_sri, flag
END IF
IF LENGTH(num_sri[9,lim]) <> LENGTH(sec_sri) THEN
	CALL fl_mostrar_mensaje('La secuencia del SRI ' || num_sri[9,lim] || ' es incorrecta.','exclamation')
	LET flag = 0
	LET num_sri = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			sec_sri
	RETURN r_g37.*, num_sri, flag
END IF
{--
IF num_sri[9,lim] < sec_sri THEN
	CALL fl_mostrar_mensaje('La secuencia del SRI ' || num_sri[9,lim] || ' ya existe.','exclamation')
	LET flag = 0
	LET num_sri = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			sec_sri
	RETURN r_g37.*, num_sri, flag
END IF
--}
DECLARE q_g39 CURSOR FOR
	SELECT * FROM gent039
		WHERE g39_compania  = r_g37.g37_compania
		  AND g39_localidad = r_g37.g37_localidad
		  AND g39_tipo_doc  = r_g37.g37_tipo_doc
		  AND g39_secuencia = r_g37.g37_secuencia
OPEN q_g39
FETCH q_g39 INTO r_g39.*
IF STATUS = NOTFOUND THEN
	CLOSE q_g39
	FREE q_g39
	CALL fl_mostrar_mensaje('No existe configurado registro del SRI (numeros inicial y final) para el tipo de documento ' || tipo_doc || '.','stop')
	LET flag = -1
	RETURN r_g37.*, num_sri, flag
END IF
CLOSE q_g39
FREE q_g39
IF (r_g37.g37_sec_num_sri + 1) < r_g39.g39_num_sri_ini OR
   (r_g37.g37_sec_num_sri + 1) > r_g39.g39_num_sri_fin
THEN
	LET flag      = -1
	LET num_sri   = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			r_g39.g39_num_sri_ini USING "&&&&&&&"
	LET num_sri_f = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta, '-',
			r_g39.g39_num_sri_fin USING "&&&&&&&"
	CALL fl_mostrar_mensaje('Los formularios del tipo de documento ' || tipo_doc || ' estan terminados. Sec. Inicial: ' || num_sri || ' Sec. Final: ' || num_sri_f || '.', 'stop')
	RETURN r_g37.*, num_sri, flag
END IF
RETURN r_g37.*, num_sri, flag

END FUNCTION



FUNCTION fl_lee_grupo_activo(cod_cia, grupo_act)
DEFINE cod_cia		LIKE actt001.a01_compania
DEFINE grupo_act	LIKE actt001.a01_grupo_act
DEFINE r		RECORD LIKE actt001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt001 
	WHERE a01_compania = cod_cia AND a01_grupo_act = grupo_act
RETURN r.*

END FUNCTION


FUNCTION fl_lee_tipo_activo(cod_cia, tipo_act)
DEFINE cod_cia		LIKE actt002.a02_compania
DEFINE tipo_act		LIKE actt002.a02_tipo_act
DEFINE r		RECORD LIKE actt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt002 
	WHERE a02_compania = cod_cia AND a02_tipo_act = tipo_act
RETURN r.*

END FUNCTION



FUNCTION fl_lee_responsable(cod_cia, responsable)
DEFINE cod_cia		LIKE actt003.a03_compania
DEFINE responsable	LIKE actt003.a03_responsable
DEFINE r		RECORD LIKE actt003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt003 
	WHERE a03_compania = cod_cia AND a03_responsable = responsable
RETURN r.*

END FUNCTION



FUNCTION fl_lee_codigo_bien(cod_cia, codigo_bien)
DEFINE cod_cia		LIKE actt010.a10_compania
DEFINE codigo_bien	LIKE actt010.a10_codigo_bien
DEFINE r		RECORD LIKE actt010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt010 
	WHERE a10_compania = cod_cia AND a10_codigo_bien = codigo_bien
RETURN r.*

END FUNCTION



FUNCTION fl_lee_transaccion_activo(cod_cia, cod_tran, num_tran)
DEFINE cod_cia		LIKE actt012.a12_compania
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE num_tran		LIKE actt012.a12_numero_tran
DEFINE r		RECORD LIKE actt012.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt012 
	WHERE a12_compania    = cod_cia
	  AND a12_codigo_tran = cod_tran
	  AND a12_numero_tran = num_tran
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_relacion_desc_sub(cod_cia, item, cod_desc_item)
DEFINE cod_cia		LIKE rept083.r83_compania
DEFINE item		LIKE rept083.r83_item
DEFINE cod_desc_item	LIKE rept083.r83_cod_desc_item
DEFINE r		RECORD LIKE rept083.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept083
	WHERE r83_compania      = cod_cia
	  AND r83_item          = item
	  AND r83_cod_desc_item = cod_desc_item
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_desc_subtitulo(cod_cia, cod_desc_item)
DEFINE cod_cia		LIKE rept084.r84_compania
DEFINE cod_desc_item	LIKE rept084.r84_cod_desc_item
DEFINE r		RECORD LIKE rept084.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept084
	WHERE r84_compania      = cod_cia
	  AND r84_cod_desc_item = cod_desc_item
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_periodos_semana(cod_cia, ano, mes)
DEFINE cod_cia		LIKE rolt002.n02_compania
DEFINE ano		LIKE rolt002.n02_ano
DEFINE mes		LIKE rolt002.n02_mes
DEFINE r		RECORD LIKE rolt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt002
	WHERE n32_compania = cod_cia
	  AND n32_ano      = ano
	  AND n32_mes      = mes
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_seguros(cod_seg)
DEFINE cod_seg		LIKE rolt013.n13_cod_seguro
DEFINE r		RECORD LIKE rolt013.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt013 WHERE n13_cod_seguro = cod_seg
RETURN r.*

END FUNCTION


  
FUNCTION fl_contabilizacion_documentos(r_datdoc)
DEFINE r_datdoc		RECORD
				codcia		LIKE gent001.g01_compania,
				cliprov		INTEGER,
				tipo_doc	CHAR(2),
				num_doc		VARCHAR(15),
				subtipo		LIKE ctbt012.b12_subtipo,
				moneda		LIKE gent013.g13_moneda,
				paridad		LIKE gent014.g14_tasa,
				valor_doc	DECIMAL(14,2),
				glosa_adi	VARCHAR(90),
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
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET num_rows = 19
	LET num_cols = 78
END IF
OPEN WINDOW w_ayuf306 AT 05, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu, BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf306 FROM "../../LIBRERIAS/forms/ayuf306"
ELSE
	OPEN FORM f_ayuf306 FROM "../../LIBRERIAS/forms/ayuf306c"
END IF
DISPLAY FORM f_ayuf306
--#DISPLAY 'Cuenta'    TO tit_col1
--#DISPLAY 'G l o s a' TO tit_col2
--#DISPLAY 'Debito'    TO tit_col3
--#DISPLAY 'Credito'   TO tit_col4
FOR i = 1 TO maximo
	INITIALIZE r_contdoc[i].* TO NULL
END FOR
CALL fl_hacer_pregunta('Desea generar contabilización para este documento ?','Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	INITIALIZE r_b12.* TO NULL
	LET int_flag = 0
	CALL fl_mostrar_mensaje('No se ha generado contabilización. Por favor contabilice este documento manualmente.', 'exclamation')
	CLOSE WINDOW w_ayuf306
	RETURN r_b12.*, 0
END IF
SELECT MAX(b01_nivel) INTO nivel FROM ctbt001
IF nivel IS NULL THEN
	INITIALIZE r_b12.* TO NULL
	LET int_flag = 1
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	CLOSE WINDOW w_ayuf306
	RETURN r_b12.*, 0
END IF
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
			CALL fl_mostrar_mensaje('No se ha generado contabilización. Por favor contabilice este documento manualmente.', 'exclamation')
			LET salir = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		IF vg_gui = 0 THEN
			CALL fl_visor_teclas_caracter() RETURNING int_flag 
			LET a = FGL_GETKEY()
			CLOSE WINDOW w_tf
			LET int_flag = 0
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
				CALL fl_mostrar_mensaje('No existe esta cuenta en la compañía.', 'exclamation')
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
			{--
			IF unacuenta > 1 THEN
				CALL fl_mostrar_mensaje('No puede repetir la misma cuenta.', 'exclamation')
				NEXT FIELD b13_cuenta
			END IF
			--}
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
			CALL fl_mostrar_mensaje('No puede dejar una cuenta con valor cero en el debito ni en el credito.', 'exclamation')
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
			CALL fl_mostrar_mensaje('No puede grabar descuadrado el diario contable.', 'exclamation')
			NEXT FIELD b13_cuenta
		END IF
		IF tot_debito <> r_datdoc.valor_doc THEN
			CALL fl_mostrar_mensaje('El total del debito debe ser igual al valor del documento.', 'exclamation')
			NEXT FIELD debito
		END IF
		IF tot_credito <> r_datdoc.valor_doc THEN
			CALL fl_mostrar_mensaje('El total del credito debe ser igual al valor del documento.', 'exclamation')
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
LET r_b12.b12_glosa       = 'COMPROBANTE GEN. POR TRN. ', r_datdoc.tipo_doc,
				'-', r_datdoc.num_doc CLIPPED
IF r_datdoc.glosa_adi IS NOT NULL THEN
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' DOC. ',
				r_datdoc.glosa_adi CLIPPED
END IF
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
LET r_b12.b12_fecing      = fl_current()
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
CALL fl_mostrar_mensaje('Contabilizacion generada Ok.', 'info')
CLOSE WINDOW w_ayuf306
RETURN r_b12.*, 1

END FUNCTION


   
FUNCTION fl_retorna_rango_fechas_proceso(codcia, cod_liq, ano, mes)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE ano, mes		SMALLINT
DEFINE r_n02   		RECORD LIKE rolt002.*
DEFINE r_n03   		RECORD LIKE rolt003.*
DEFINE fecha_proceso	DATE
DEFINE fec_ini, fec_fin	DATE

INITIALIZE fec_ini, fec_fin TO NULL
CASE cod_liq
	WHEN 'Q1'
		LET fec_ini  = MDY(mes, 1,  ano)
		LET fec_fin  = MDY(mes, 15, ano)
	WHEN 'Q2'
		LET fec_ini  = MDY(mes, 16, ano)
		LET fec_fin  = MDY(mes, 1,  ano) + 1 UNITS MONTH - 1 UNITS DAY
	WHEN 'ME'
		LET fec_ini  = MDY(mes, 1,  ano)
		LET fec_fin  = fec_ini + 1 UNITS MONTH - 1 UNITS DAY
	WHEN 'UT'
		LET fec_ini  = MDY(1, 1,  ano)
		LET fec_fin  = MDY(12,31, ano)
	OTHERWISE
		IF cod_liq = 'DT' OR cod_liq = 'DC' THEN
			CALL fl_lee_proceso_roles(cod_liq) RETURNING r_n03.*

			IF mes <= r_n03.n03_mes_fin THEN
				IF r_n03.n03_mes_ini > r_n03.n03_mes_fin THEN
        				LET fec_ini = mdy(r_n03.n03_mes_ini, 
						    	  r_n03.n03_dia_ini,
                                       			  (ano - 1))
				ELSE
        				LET fec_ini = mdy(r_n03.n03_mes_ini, 
							  r_n03.n03_dia_ini,
                                	       		  ano)
				END IF
				LET fec_fin = mdy(r_n03.n03_mes_fin, 
						  r_n03.n03_dia_fin,
	                               		  ano)
			ELSE
				IF r_n03.n03_mes_ini > r_n03.n03_mes_fin THEN
        				LET fec_ini = mdy(r_n03.n03_mes_ini, 
						    	  r_n03.n03_dia_ini,
                                       			  ano)
				ELSE
        				LET fec_ini = mdy(r_n03.n03_mes_ini, 
							  r_n03.n03_dia_ini,
                                	       		  (ano + 1))
				END IF
				LET fec_fin = mdy(r_n03.n03_mes_fin, 
						  r_n03.n03_dia_fin,
	                               		  (ano + 1))
			END IF
		END IF
END CASE
IF cod_liq[1,1] = 'S' THEN
	CALL fl_lee_periodos_semana(codcia, ano, mes)
		RETURNING r_n02.*
	CASE cod_liq[2,2]
		WHEN '1'
			LET fec_ini = r_n02.n02_fecha_ini_1
			LET fec_fin = r_n02.n02_fecha_fin_1
		WHEN '2'
			LET fec_ini = r_n02.n02_fecha_ini_2
			LET fec_fin = r_n02.n02_fecha_fin_2
		WHEN '3'
			LET fec_ini = r_n02.n02_fecha_ini_3
			LET fec_fin = r_n02.n02_fecha_fin_3
		WHEN '4'
			LET fec_ini = r_n02.n02_fecha_ini_4
			LET fec_fin = r_n02.n02_fecha_fin_4
		WHEN '5'
			LET fec_ini = r_n02.n02_fecha_ini_5
			LET fec_fin = r_n02.n02_fecha_fin_5
	END CASE
END IF
RETURN fec_ini, fec_fin
	
END FUNCTION



FUNCTION fl_lee_liquidacion_roles(codcia, cod_liqrol, fecha_ini, fecha_fin, 
        	cod_trab)
DEFINE codcia 		LIKE rolt032.n32_compania
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini                                       
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE r_n32		RECORD LIKE rolt032.*

INITIALIZE r_n32.* TO NULL
SELECT * INTO r_n32.* FROM rolt032
	WHERE n32_compania   = codcia     AND 
	      n32_cod_liqrol = cod_liqrol AND 
	      n32_fecha_ini  = fecha_ini  AND 
	      n32_fecha_fin  = fecha_fin  AND 
	      n32_cod_trab   = cod_trab
RETURN r_n32.*

END FUNCTION



FUNCTION fl_lee_seguro_social(cod_seguro)
DEFINE cod_seguro	LIKE rolt013.n13_cod_seguro
DEFINE r_n13		RECORD LIKE rolt013.*

INITIALIZE r_n13.* TO NULL
SELECT * INTO r_n13.* FROM rolt013
	WHERE n13_cod_seguro = cod_seguro
RETURN r_n13.*

END FUNCTION



FUNCTION fl_lee_rubro_liq_trabajador(codcia, cod_liqrol, fecha_ini, fecha_fin,
	 	cod_trab, cod_rubro)                   
DEFINE codcia		LIKE rolt033.n33_compania
DEFINE cod_liqrol	LIKE rolt033.n33_cod_liqrol
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin
DEFINE cod_trab		LIKE rolt033.n33_cod_trab
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE r_n33		RECORD LIKE rolt033.*

INITIALIZE r_n33.* TO NULL
SELECT * INTO r_n33.* FROM rolt033
	WHERE n33_compania   = codcia     AND 
	      n33_cod_liqrol = cod_liqrol AND 
	      n33_fecha_ini  = fecha_ini  AND 
	      n33_fecha_fin  = fecha_fin  AND 
	      n33_cod_trab   = cod_trab   AND
	      n33_cod_rubro  = cod_rubro
RETURN r_n33.*

END FUNCTION



FUNCTION fl_lee_rubro_que_se_calcula(cod_rubro)
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE r_n07		RECORD LIKE rolt007.*

INITIALIZE r_n07.* TO NULL
SELECT * INTO r_n07.* FROM rolt007
	WHERE n07_cod_rubro = cod_rubro
RETURN r_n07.*

END FUNCTION



FUNCTION fl_lee_identidad_rol(flag_ident)
DEFINE flag_ident	LIKE rolt016.n16_flag_ident
DEFINE r_n16		RECORD LIKE rolt016.*

INITIALIZE r_n16.* TO NULL
SELECT * INTO r_n16.* FROM rolt016
	WHERE n16_flag_ident = flag_ident
RETURN r_n16.*

END FUNCTION



FUNCTION fl_lee_cod_sectorial(codcia, anio, sectorial)
DEFINE codcia		LIKE rolt017.n17_compania
DEFINE anio		LIKE rolt017.n17_ano_sect
DEFINE sectorial	LIKE rolt017.n17_sectorial
DEFINE r_n17		RECORD LIKE rolt017.*

INITIALIZE r_n17.* TO NULL
SELECT * INTO r_n17.* FROM rolt017
	WHERE n17_compania  = codcia
	  AND n17_ano_sect  = anio
	  AND n17_sectorial = sectorial
RETURN r_n17.*

END FUNCTION



FUNCTION fl_lee_cab_prestamo_roles(codcia, num_prest)
DEFINE codcia 		LIKE rolt045.n45_compania
DEFINE num_prest	LIKE rolt045.n45_num_prest
DEFINE r_n45		RECORD LIKE rolt045.*

INITIALIZE r_n45.* TO NULL
SELECT * INTO r_n45.* FROM rolt045
	WHERE n45_compania  = codcia    AND 
	      n45_num_prest = num_prest
RETURN r_n45.*

END FUNCTION



FUNCTION fl_lee_cab_prestamo_club(codcia, num_prest)
DEFINE codcia 		LIKE rolt064.n64_compania
DEFINE num_prest	LIKE rolt064.n64_num_prest
DEFINE r_n64		RECORD LIKE rolt064.*

INITIALIZE r_n64.* TO NULL
SELECT * INTO r_n64.* FROM rolt064
	WHERE n64_compania  = codcia    AND 
	      n64_num_prest = num_prest
RETURN r_n64.*

END FUNCTION



FUNCTION fl_lee_cuota_club(cod_cia, cod_trab)
DEFINE cod_cia		LIKE rolt061.n61_compania
DEFINE cod_trab		LIKE rolt061.n61_cod_trab
DEFINE r_n61		RECORD LIKE rolt061.*

INITIALIZE r_n61.* TO NULL
SELECT * INTO r_n61.* FROM rolt061
	WHERE n61_compania = cod_cia
	  AND n61_cod_trab = cod_trab
RETURN r_n61.*

END FUNCTION



FUNCTION fl_lee_prestamo_club(cod_cia, prestamo)
DEFINE cod_cia		LIKE rolt064.n64_compania
DEFINE prestamo		LIKE rolt064.n64_num_prest
DEFINE r_n64		RECORD LIKE rolt064.*

INITIALIZE r_n64.* TO NULL
SELECT * INTO r_n64.* FROM rolt064
	WHERE n64_compania  = cod_cia
	  AND n64_num_prest = prestamo
RETURN r_n64.*

END FUNCTION



FUNCTION fl_verificar_dias_validez_sri(cod_cia, cod_loc, tipo_doc)
DEFINE cod_cia		LIKE gent037.g37_compania
DEFINE cod_loc		LIKE gent037.g37_localidad
DEFINE tipo_doc		LIKE gent037.g37_tipo_doc
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE dias		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE men_doc		VARCHAR(30)
DEFINE icono		VARCHAR(11)

INITIALIZE r_g37.* TO NULL
DECLARE q_g37_v CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania  = cod_cia
		  AND g37_localidad = cod_loc
		  AND g37_tipo_doc  = tipo_doc
		ORDER BY g37_fecha_exp DESC
OPEN q_g37_v
FETCH q_g37_v INTO r_g37.*
IF STATUS = NOTFOUND THEN
	CLOSE q_g37_v
	FREE q_g37_v
 	LET mensaje = 'No existe ninguna configuración para los formularios ',
			'del SRI. Por favor llame al ADMINISTRADOR.'
	LET icono   = 'stop'
	CALL fl_mostrar_mensaje(mensaje, icono)
	RETURN
END IF
LET dias = r_g37.g37_fecha_exp - TODAY
IF dias <= 30 THEN
	CASE tipo_doc
		WHEN 'FA'
			LET men_doc = 'Facturas.'
		WHEN 'NV'
			LET men_doc = 'Notas de Venta.'
		WHEN 'NC'
			LET men_doc = 'Notas de Crédito.'
		WHEN 'ND'
			LET men_doc = 'Notas de Débito.'
		WHEN 'RT'
			LET men_doc = 'Comprobantes de Retención.'
		WHEN 'GR'
			LET men_doc = 'Guías de Remisión.'
		OTHERWISE
			LET men_doc = 'VARIOS.'
	END CASE
	LET mensaje = 'Faltan ', dias USING "<&", ' días para que caduquen'
	LET icono   = 'info'
	IF dias = 1 THEN
		LET mensaje = 'Falta un día para que caduquen'
		LET icono   = 'exclamation'
	END IF
	IF dias = 0 THEN
		LET mensaje = 'Hoy caducan'
		LET icono   = 'stop'
	END IF
	IF dias < 0 THEN
		LET mensaje = 'Hace ',(dias * (-1)) USING "<&",' días caducaron'
		LET icono   = 'stop'
	END IF
 	LET mensaje = mensaje CLIPPED, ' los formularios de ', men_doc CLIPPED,
			' Por favor llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, icono)
END IF
CLOSE q_g37_v
FREE q_g37_v

END FUNCTION



FUNCTION fl_modifica_forma_pago(cod_cia, cod_trab, tipo_pago, bco_empresa, cta_empresa, cta_trabaj)
DEFINE cod_cia		LIKE rolt030.n30_compania
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE tipo_pago	LIKE rolt030.n30_tipo_pago
DEFINE bco_empresa	LIKE rolt030.n30_bco_empresa
DEFINE cta_empresa	LIKE rolt030.n30_cta_empresa
DEFINE cta_trabaj	LIKE rolt030.n30_cta_trabaj

DEFINE r_n30		RECORD LIKE rolt030.*

DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_bco		RECORD LIKE gent009.*
DEFINE r_bco_gen	RECORD LIKE gent008.*
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta

CALL fl_lee_trabajador_roles(cod_cia, cod_trab) RETURNING r_n30.*

LET r_n30.n30_tipo_pago   = tipo_pago
LET r_n30.n30_bco_empresa = bco_empresa
LET r_n30.n30_cta_empresa = cta_empresa
LET r_n30.n30_cta_trabaj  = cta_trabaj

OPEN WINDOW w_fp AT 4,6 WITH 12 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_fp FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf153'
DISPLAY FORM f_fp

CALL fl_lee_banco_general(bco_empresa) RETURNING r_bco_gen.*
DISPLAY r_bco_gen.g08_nombre TO tit_banco

INPUT BY NAME r_n30.n30_cod_trab, r_n30.n30_nombres, r_n30.n30_tipo_pago, 
	      r_n30.n30_bco_empresa, r_n30.n30_cta_empresa, 
	      r_n30.n30_cta_trabaj WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(r_n30.n30_tipo_pago,
			r_n30.n30_bco_empresa, r_n30.n30_cta_empresa,
			r_n30.n30_cta_trabaj)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY (F2)
		IF INFIELD(n30_bco_empresa) THEN
			CALL fl_ayuda_cuenta_banco(cod_cia, 'A') 
                                RETURNING codb_aux, nomb_aux, tipo_aux, num_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
				LET r_n30.n30_bco_empresa = codb_aux
				LET r_n30.n30_cta_empresa = num_aux
                                DISPLAY BY NAME r_n30.n30_bco_empresa
                                DISPLAY nomb_aux TO tit_banco
				DISPLAY BY NAME r_n30.n30_cta_empresa
                        END IF
                END IF
	AFTER FIELD n30_bco_empresa
                IF r_n30.n30_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(r_n30.n30_bco_empresa)
                                RETURNING r_bco_gen.*
			IF r_bco_gen.g08_banco IS NULL THEN
				--#CALL fgl_winmessage(vg_producto,'Banco no existe','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
		ELSE
			CLEAR n30_bco_empresa, tit_banco, n30_cta_empresa
                END IF
	AFTER FIELD n30_cta_empresa
                IF r_n30.n30_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(cod_cia,
					r_n30.n30_bco_empresa,
					r_n30.n30_cta_empresa)
                                RETURNING r_bco.*
			IF r_bco.g09_banco IS NULL THEN
				--#CALL fgl_winmessage(vg_producto,'Banco o Cuenta Corriente no existe en la compañía','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			LET r_n30.n30_cta_empresa = r_bco.g09_numero_cta
			DISPLAY BY NAME r_n30.n30_cta_empresa
                        CALL fl_lee_banco_general(r_n30.n30_bco_empresa)
                                RETURNING r_bco_gen.*
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
			IF r_bco.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n30_bco_empresa
			END IF
		ELSE
			CLEAR n30_cta_empresa
		END IF
	AFTER INPUT
		IF r_n30.n30_tipo_pago = 'E' THEN
			IF r_n30.n30_bco_empresa IS NOT NULL
			OR r_n30.n30_cta_empresa IS NOT NULL THEN
				--#CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago efectivo. Borre el Banco y la cuenta corriente.','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			IF r_n30.n30_cta_trabaj IS NOT NULL THEN	
				--#CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago efectivo. Borre la cuenta del trabajador.','exclamation')
				NEXT FIELD n30_cta_trabaj
			END IF
		END IF
		IF r_n30.n30_tipo_pago = 'C' THEN
			IF r_n30.n30_bco_empresa IS NULL
			OR r_n30.n30_cta_empresa IS NULL THEN
				--#CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago cheque. Ingrese el Banco y la cuenta corriente.','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			IF r_n30.n30_cta_trabaj IS NOT NULL THEN	
				--#CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago cheque. Borre la cuenta del trabajador.','exclamation')
				NEXT FIELD n30_cta_trabaj
			END IF
		END IF
		IF r_n30.n30_tipo_pago = 'T' THEN
			IF r_n30.n30_bco_empresa IS NULL
			OR r_n30.n30_cta_empresa IS NULL THEN
				--#CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago transferencia. Ingrese el Banco y la cuenta corriente.','exclamation')
				NEXT FIELD n30_bco_empresa
			END IF
			IF r_n30.n30_cta_trabaj IS NULL THEN	
				--#CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago transferencia. Ingrese la cuenta del trabajador.','exclamation')
				NEXT FIELD n30_cta_trabaj
			END IF
		END IF
END INPUT
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_fp
	RETURN tipo_pago, bco_empresa, cta_empresa, cta_trabaj
END IF

CLOSE WINDOW w_fp

RETURN r_n30.n30_tipo_pago, r_n30.n30_bco_empresa, r_n30.n30_cta_empresa,
       r_n30.n30_cta_trabaj

END FUNCTION



FUNCTION fl_validar_cedruc_dig_ver(cedruc)
DEFINE cedruc		VARCHAR(15)
DEFINE valor		ARRAY[15] OF SMALLINT
DEFINE suma, i, lim	SMALLINT
DEFINE residuo_suma	SMALLINT

LET lim    = 10
LET cedruc = cedruc CLIPPED
IF (LENGTH(cedruc) <> lim) AND (LENGTH(cedruc) <> 13) THEN
	CALL fl_mostrar_mensaje('El número de digitos de cédula/ruc es incorrecto.', 'exclamation')
	RETURN 0
END IF
IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
	CALL fl_mostrar_mensaje('Los digitos iniciales de cédula/ruc son incorrectos.', 'exclamation')
	RETURN 0
END IF
IF LENGTH(cedruc) = 13 THEN
	IF cedruc[11, 13] <> '001' OR cedruc[11, 12] <> '00' THEN
		CALL fl_mostrar_mensaje('El número de digitos del ruc es incorrecto.', 'exclamation')
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
CALL fl_mostrar_mensaje('El número de cédula/ruc no es valido.', 'exclamation')
RETURN 0

END FUNCTION



FUNCTION fl_lee_datos_aportes_reserva(cod_cia, con_pago)
DEFINE cod_cia		LIKE rolt066.n66_compania
DEFINE con_pago		LIKE rolt066.n66_concepto_pago
DEFINE r_n66		RECORD LIKE rolt066.*

INITIALIZE r_n66.* TO NULL
SELECT * INTO r_n66.* FROM rolt066
	WHERE n66_compania      = cod_cia
	  AND n66_concepto_pago = con_pago
RETURN r_n66.*

END FUNCTION


FUNCTION fl_retorna_proceso_roles_activo(cod_cia)
DEFINE cod_cia		LIKE rolt005.n05_compania
DEFINE r		RECORD LIKE rolt005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt005 WHERE n05_compania = cod_cia
				 AND n05_activo   = 'S' 
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_rubros_club(cod_rub)
DEFINE cod_rub		LIKE rolt067.n67_cod_rubro
DEFINE r		RECORD LIKE rolt067.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt067 WHERE n67_cod_rubro = cod_rub
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_transacciones_club(cod_cia, cod_tran, num_tran)
DEFINE cod_cia		LIKE rolt068.n68_compania
DEFINE num_tran		LIKE rolt068.n68_num_tran
DEFINE cod_tran		LIKE rolt068.n68_cod_tran
DEFINE r		RECORD LIKE rolt068.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt068
	WHERE n68_compania = cod_cia
	  AND n68_cod_tran = cod_tran
	  AND n68_num_tran = num_tran
RETURN r.*

END FUNCTION


  
FUNCTION fl_lee_saldos_club(cod_cia, banco, cuenta, anio, mes)
DEFINE cod_cia		LIKE rolt069.n69_compania
DEFINE banco		LIKE rolt069.n69_banco
DEFINE cuenta		LIKE rolt069.n69_numero_cta
DEFINE anio		LIKE rolt069.n69_anio
DEFINE mes		LIKE rolt069.n69_mes
DEFINE r		RECORD LIKE rolt069.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt069
	WHERE n69_compania   = cod_cia
	  AND n69_banco      = banco
	  AND n69_numero_cta = cuenta
	  AND n69_anio       = anio
	  AND n69_mes        = mes
RETURN r.*

END FUNCTION



FUNCTION fl_lee_poliza_cesantia_activa(cod_cia)
DEFINE cod_cia		LIKE rolt081.n81_compania
DEFINE r		RECORD LIKE rolt081.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt081 
	WHERE n81_compania   = cod_cia
	  AND n81_estado     = 'A'
RETURN r.*

END FUNCTION



FUNCTION fl_lee_poliza_cesantia(cod_cia, num_poliza)
DEFINE cod_cia		LIKE rolt081.n81_compania
DEFINE num_poliza	LIKE rolt081.n81_num_poliza
DEFINE r		RECORD LIKE rolt081.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt081 
	WHERE n81_compania   = cod_cia
	  AND n81_num_poliza = num_poliza
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_anios_meses_dias(fecha1, fecha2)
DEFINE fecha1		DATE
DEFINE fecha2		DATE
DEFINE anios		SMALLINT
DEFINE meses		SMALLINT
DEFINE dias, i		SMALLINT
DEFINE expr_fec		CHAR(200)
DEFINE query		CHAR(600)

IF fecha1 <= fecha2 THEN
	CALL fl_mostrar_mensaje('La primera fecha debe ser mayor a la segunda fecha.', 'exclamation')
	RETURN 0, 0, 0 
END IF
LET anios = YEAR(fecha1) - YEAR(fecha2)
LET expr_fec = ' TRUNC(((DATE("', fecha1, '") - DATE("', fecha2, '")) / ',
		'365 - TRUNC((DATE("', fecha1, '") - DATE("', fecha2, '")) / ',
		'365))'
LET query = 'SELECT ', expr_fec CLIPPED, ' * (365 / 30))',
		' FROM dual'
PREPARE trunc_mes FROM query
EXECUTE trunc_mes INTO meses
LET query = 'SELECT ', expr_fec CLIPPED, ' * 365) - ((', expr_fec CLIPPED,
		' * (365 / 30))) * 30)',
		' FROM dual'
PREPARE trunc_dia FROM query
EXECUTE trunc_dia INTO dias
FOR i = YEAR(fecha2) TO YEAR(fecha1)
	IF ((i MOD 4) <> 0) THEN
		CONTINUE FOR
	END IF
	LET dias = dias + 1
	IF dias > 30 THEN
		LET dias  = 0
		LET meses = meses + 1
		IF meses > 12 THEN
			LET meses = 0
			LET anios = anios + 1
		END IF
	END IF
END FOR
RETURN anios, meses, dias

END FUNCTION



FUNCTION fl_valida_proceso_finiquito_activo(cod_cia) 
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE cod_cia		INTEGER
DEFINE activo 		SMALLINT

LET activo = 0
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 WHERE n05_compania = cod_cia 
				     AND n05_proceso  = 'AF'
				     AND n05_activo = 'S'

IF r_n05.n05_compania IS NOT NULL THEN
	LET activo = 1
END IF

RETURN activo

END FUNCTION



{--
FUNCTION fl_lee_acta_finiquito(codcia, proceso, acta)
DEFINE codcia 		LIKE rolt074.n74_compania
DEFINE proceso 		LIKE rolt074.n74_proceso
DEFINE acta 		LIKE rolt074.n74_num_acta
DEFINE r_n74		RECORD LIKE rolt074.*

INITIALIZE r_n74.* TO NULL
SELECT * INTO r_n74.*
	FROM rolt074
	WHERE n74_compania = codcia
	  AND n74_proceso  = proceso
	  AND n74_num_acta = acta
RETURN r_n74.*

END FUNCTION
--}



FUNCTION fl_lee_vacaciones(cod_cia, cod_proc, cod_trab, per_ini, per_fin)
DEFINE cod_cia		LIKE rolt039.n39_compania
DEFINE cod_proc		LIKE rolt039.n39_proceso
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE per_ini		LIKE rolt039.n39_periodo_ini
DEFINE per_fin		LIKE rolt039.n39_periodo_fin
DEFINE r		RECORD LIKE rolt039.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rolt039
	WHERE n39_compania    = cod_cia
	  AND n39_proceso     = cod_proc
	  AND n39_cod_trab    = cod_trab
	  AND n39_periodo_ini = per_ini
	  AND n39_periodo_fin = per_fin
RETURN r.*

END FUNCTION



FUNCTION fl_control_acceso_proceso_men(v_usuario, v_codcia, v_modulo, v_proceso)
DEFINE v_usuario	LIKE gent005.g05_usuario
DEFINE v_codcia		LIKE gent001.g01_compania
DEFINE v_modulo		LIKE gent050.g50_modulo
DEFINE v_proceso	LIKE gent054.g54_proceso
DEFINE r_g54   		RECORD LIKE gent054.*
DEFINE r_g55   		RECORD LIKE gent055.*
DEFINE r_g57   		RECORD LIKE gent057.*

CALL fl_lee_proceso(v_modulo, v_proceso) RETURNING r_g54.*
IF r_g54.g54_modulo IS NULL THEN
	CALL fl_mostrar_mensaje('PROCESO: ' || v_modulo CLIPPED || '-' || v_proceso CLIPPED || ' NO EXISTE ', 'stop')
	RETURN 0
END IF
IF r_g54.g54_estado = 'B' THEN
	CALL fl_mostrar_mensaje('EL PROCESO: ' || v_proceso CLIPPED || ' ESTA MARCADO COMO BLOQUEADO.' || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	RETURN 0
END IF
CALL fl_lee_permisos_usuarios(v_usuario, v_codcia, v_modulo, v_proceso)
	RETURNING r_g55.*
IF r_g55.g55_user IS NOT NULL THEN
	CALL fl_mostrar_mensaje('USTED NO TIENE ACCESO AL PROCESO ' || v_proceso CLIPPED || '. PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	RETURN 0
END IF
CALL fl_lee_permisos_usuarios_menu(v_usuario, v_codcia, v_modulo, v_proceso)
	RETURNING r_g57.*
IF r_g57.g57_user IS NULL THEN
	CALL fl_mostrar_mensaje('USTED NO TIENE ACCESO AL PROCESO ' || v_proceso CLIPPED || ' DESDE EL MENU. PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fl_lee_permisos_usuarios_menu(usuario, cod_cia, modulo, proceso)
DEFINE usuario          LIKE gent057.g57_user
DEFINE cod_cia          LIKE gent057.g57_compania
DEFINE modulo           LIKE gent057.g57_modulo
DEFINE proceso          LIKE gent057.g57_proceso
DEFINE r                RECORD LIKE gent057.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent057
        WHERE g57_user     = usuario
          AND g57_compania = cod_cia
          AND g57_modulo   = modulo
	  AND g57_proceso  = proceso
RETURN r.*

END FUNCTION



FUNCTION fl_lee_depreciacion_mensual_activo(codcia, codigo_bien, anio, mes)
DEFINE codcia		LIKE actt014.a14_compania
DEFINE codigo_bien	LIKE actt014.a14_codigo_bien
DEFINE anio		LIKE actt014.a14_anio
DEFINE mes		LIKE actt014.a14_mes
DEFINE r		RECORD LIKE actt014.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM actt014
	WHERE a14_compania    = codcia
	  AND a14_codigo_bien = codigo_bien
	  AND a14_anio        = anio
	  AND a14_mes         = mes
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cabecera_transferencia_trans(cod_cia, cod_loc,cod_tran,num_tran)
DEFINE cod_cia		LIKE rept091.r91_compania
DEFINE cod_loc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE r		RECORD LIKE rept091.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept091 
	WHERE r91_compania  = cod_cia
	  AND r91_localidad = cod_loc
	  AND r91_cod_tran  = cod_tran
	  AND r91_num_tran  = num_tran
RETURN r.*

END FUNCTION



FUNCTION fl_obtener_saldo_cuentas_patrimonio(codcia, cuenta, moneda, fecha_ini,
						fecha_fin, flag)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE moneda		LIKE ctbt012.b12_moneda
DEFINE fecha_ini	LIKE ctbt012.b12_fec_proceso
DEFINE fecha_fin	LIKE ctbt012.b12_fec_proceso
DEFINE r_b01		RECORD LIKE ctbt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE flag		CHAR(1)
DEFINE val1, val2	DECIMAL(16,2)
DEFINE cuenta_ini	LIKE ctbt010.b10_cuenta
DEFINE cuenta_fin	LIKE ctbt010.b10_cuenta
DEFINE i, j, ini, fin 	SMALLINT
DEFINE ceros, nueves	CHAR(10)

LET val1       = 0
LET val2       = 0
LET cuenta_ini = cuenta
LET cuenta_fin = cuenta
CALL fl_lee_cuenta(codcia, cuenta) RETURNING r_b10.*
SELECT * INTO r_b01.* FROM ctbt001
	WHERE b01_nivel = (SELECT MAX(b01_nivel) FROM ctbt001)
IF r_b01.b01_nivel > r_b10.b10_nivel THEN
	SELECT * INTO r_b01.*
		FROM ctbt001
		WHERE b01_nivel = r_b10.b10_nivel + 1
	LET ceros  = NULL
	LET nueves = NULL
	FOR j = r_b01.b01_posicion_i TO r_b01.b01_posicion_f
		LET ceros  = ceros CLIPPED, '0'
		LET nueves = nueves CLIPPED, '9'
	END FOR
	LET ini                  = r_b01.b01_posicion_i
	LET fin                  = r_b01.b01_posicion_f
	LET cuenta_ini[ini, fin] = ceros CLIPPED
	LET cuenta_fin[ini, fin] = nueves CLIPPED, '999'
END IF
CASE flag
	WHEN 'A'
		SELECT NVL(SUM(b13_valor_base), 0) INTO val1
			FROM ctbt012, ctbt013
			WHERE b12_compania     = codcia
			  AND b12_estado      <> 'E'
			  AND b12_moneda       = moneda
			  AND b13_compania     = b12_compania
			  AND b13_tipo_comp    = b12_tipo_comp
			  AND b13_num_comp     = b12_num_comp
			  AND b13_cuenta      BETWEEN cuenta_ini AND cuenta_fin
			  AND b13_fec_proceso <= fecha_ini
	WHEN 'S'
		SELECT * FROM ctbt013
			WHERE b13_compania    = codcia
			  AND b13_cuenta      BETWEEN cuenta_ini AND cuenta_fin
			  AND b13_fec_proceso BETWEEN fecha_ini  AND fecha_fin
			INTO TEMP temp_b13
		SELECT NVL(SUM(b13_valor_base), 0) INTO val1
			FROM ctbt012, temp_b13
			WHERE b12_compania     = codcia
			  AND b12_estado       = 'M'
			  AND b12_moneda       = moneda
			  AND b13_compania     = b12_compania
			  AND b13_tipo_comp    = b12_tipo_comp
			  AND b13_num_comp     = b12_num_comp
			  AND b13_valor_base   > 0
		SELECT NVL(SUM(b13_valor_base), 0) INTO val2
			FROM ctbt012, temp_b13
			WHERE b12_compania     = codcia
			  AND b12_estado       = 'M'
			  AND b12_moneda       = moneda
			  AND b13_compania     = b12_compania
			  AND b13_tipo_comp    = b12_tipo_comp
			  AND b13_num_comp     = b12_num_comp
			  AND b13_valor_base  <= 0
		DROP TABLE temp_b13
END CASE
RETURN val1, val2

END FUNCTION



FUNCTION fl_lee_fecha_carga_cxc(cod_cia, cod_loc)
DEFINE cod_cia		LIKE cxct060.z60_compania
DEFINE cod_loc		LIKE cxct060.z60_localidad
DEFINE r_z60		RECORD LIKE cxct060.*

INITIALIZE r_z60.* TO NULL
SELECT * INTO r_z60.* FROM cxct060
	WHERE z60_compania  = cod_cia
	  AND z60_localidad = cod_loc
RETURN r_z60.*

END FUNCTION



FUNCTION fl_control_guia_remision(codcia, codloc, bodega, num_ent, cod_tran,
					num_tran)
DEFINE codcia		LIKE rept095.r95_compania
DEFINE codloc		LIKE rept095.r95_localidad
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE num_ent		LIKE rept036.r36_num_entrega
DEFINE cod_tran		LIKE rept034.r34_cod_tran
DEFINE num_tran		LIKE rept034.r34_num_tran
DEFINE expr_sql		CHAR(300)
DEFINE query		CHAR(1800)
DEFINE resp		CHAR(6)
DEFINE a		INTEGER
DEFINE resul, lim	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE mensaje		VARCHAR(150)
DEFINE cont		INTEGER
DEFINE flag		SMALLINT
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE secuencia	LIKE gent037.g37_secuencia
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE aux_sri		LIKE rept095.r95_num_sri
DEFINE fecha_ini	LIKE rept095.r95_fecha_initras
DEFINE fecha_emi	LIKE rept095.r95_fecha_emi
DEFINE persona_id	LIKE rept095.r95_persona_id
DEFINE pers_id_dest	LIKE rept095.r95_pers_id_dest
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r09		RECORD LIKE rept009.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE r_r97		RECORD LIKE rept097.*
DEFINE r_r108		RECORD LIKE rept108.*
DEFINE r_r109		RECORD LIKE rept109.*

IF num_ent IS NULL AND cod_tran IS NULL THEN
	CALL fl_mostrar_mensaje('No hay ninguna transacción o nota de entrega, para relacionar la guía de remisión.', 'exclamation')
	RETURN 0
END IF
CALL fl_hacer_pregunta('Desea generar también la Guía de Remisión.', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 71
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 6
	LET num_rows = 18
	LET num_cols = 72
END IF
OPEN WINDOW w_ayuf307 AT row_ini, 05 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf307 FROM "../../LIBRERIAS/forms/ayuf307"
ELSE
	OPEN FORM f_ayuf307 FROM "../../LIBRERIAS/forms/ayuf307c"
END IF
DISPLAY FORM f_ayuf307
INITIALIZE r_r95.*, r_r96.*, r_r97.* TO NULL
LET r_r95.r95_motivo        = 'V'
LET r_r95.r95_entre_local   = 'N'
LET r_r95.r95_fecha_initras = TODAY
LET r_r95.r95_fecha_emi     = TODAY
LET r_r95.r95_usuario       = vg_usuario
LET r_r95.r95_fecing        = fl_current()
IF cod_tran = 'TR' THEN
	LET r_r95.r95_motivo = 'N'
	LET expr_sql         = 'SELECT UNIQUE g01_razonsocial per_dest,',
			' g02_numruc per_id,',
			' TRIM(g02_nombre) || " " || TRIM(g02_direccion)',
			' punto_lleg '
	CALL fl_lee_bodega_rep(codcia, bodega) RETURNING r_r02.*
	CALL fl_lee_tipo_ident_bod(r_r02.r02_compania, r_r02.r02_tipo_ident)
		RETURNING r_r09.*
	IF r_r09.r09_tipo_ident = "Y" THEN
		LET expr_sql = 'SELECT UNIQUE r19_nomcli per_dest,',
					' r19_cedruc per_id,',
					' r19_dircli punto_lleg'
	END IF
	LET query = expr_sql CLIPPED,
			' FROM rept019, rept002, gent002, gent001 ',
			' WHERE r19_compania  = ', codcia,
			'   AND r19_localidad = ', codloc,
			'   AND r19_cod_tran  = "', cod_tran, '"',
			'   AND r19_num_tran  = ', num_tran,
			'   AND r02_compania  = r19_compania ',
			'   AND r02_codigo    = r19_bodega_dest ',
			'   AND g02_compania  = r02_compania ',
			'   AND g02_localidad = r02_localidad ',
			'   AND g01_compania  = g02_compania ',
			' INTO TEMP t1 '
	PREPARE tmp_dat FROM query
	EXECUTE tmp_dat
END IF
IF cod_tran = 'FA' THEN
	SELECT UNIQUE TRIM(r19_nomcli) per_dest, r19_cedruc per_id,
		TRIM(r36_entregar_en) punto_lleg
		FROM rept036, rept034, rept019
		WHERE r36_compania    = codcia
                  AND r36_localidad   = codloc
                  AND r36_bodega      = bodega
                  AND r36_num_entrega = num_ent
                  AND r34_compania    = r36_compania
                  AND r34_localidad   = r36_localidad
                  AND r34_bodega      = r36_bodega
                  AND r34_num_ord_des = r36_num_ord_des
                  AND r19_compania    = r34_compania
                  AND r19_localidad   = r34_localidad
                  AND r19_cod_tran    = r34_cod_tran
                  AND r19_num_tran    = r34_num_tran
		INTO TEMP t1
END IF
SELECT per_dest, per_id, punto_lleg
	INTO r_r95.r95_persona_dest, r_r95.r95_pers_id_dest,
		r_r95.r95_punto_lleg
	FROM t1
DROP TABLE t1
--IF cod_tran = 'FA' THEN
SELECT COUNT(*) INTO cont
	FROM gent037
	WHERE g37_compania   = codcia
	  AND g37_localidad  = codloc
	  AND g37_tipo_doc   = "GR"
	  AND g37_secuencia IN
		(SELECT MAX(g37_secuencia)
			FROM gent037
			WHERE g37_compania  = codcia
			  AND g37_localidad = codloc
			  AND g37_tipo_doc  = "GR")
IF cont = 1 THEN
	LET cont_cred = "N"
ELSE
	CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, cod_tran, num_tran)
		RETURNING r_r19.*
	LET cont_cred = 'C'
	IF r_r19.r19_ord_trabajo IS NOT NULL THEN
		LET cont_cred = 'R'
	END IF
END IF
LET query = 'SELECT g37_pref_sucurs || "-" || g37_pref_pto_vta || "-"',
			' || LPAD(g37_sec_num_sri + 1, ',
			'g37_num_dig_sri, 0), g37_autorizacion, ',
			'g37_secuencia ',
		'FROM gent037 ',
		'WHERE g37_compania   = ', codcia,
		'  AND g37_localidad  = ', codloc,
		'  AND g37_tipo_doc   = "GR" ',
  		'  AND g37_cont_cred  = "', cont_cred, '"',
		{--
	  	  AND g37_fecha_emi <= DATE(TODAY)
  		  AND g37_fecha_exp >= DATE(TODAY)
		--}
		'  AND g37_secuencia IN ',
			'(SELECT MAX(g37_secuencia) ',
			'FROM gent037 ',
			'WHERE g37_compania  = ', codcia,
			'  AND g37_localidad = ', codloc,
			'  AND g37_tipo_doc  = "GR") '
PREPARE cons_guia FROM query
DECLARE q_autoriz CURSOR FOR cons_guia
OPEN q_autoriz
FETCH q_autoriz INTO r_r95.r95_num_sri, r_r95.r95_autoriz_sri,
			secuencia
CLOSE q_autoriz
FREE q_autoriz
DECLARE q_autoriz_2 CURSOR FOR
	SELECT g37_autorizacion
		FROM gent037
		WHERE g37_compania   = codcia
		  AND g37_localidad  = codloc
		  AND g37_tipo_doc   = "FA"
		  AND g37_secuencia IN
			(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = codcia
				  AND g37_localidad = codloc
				  AND g37_tipo_doc  = "FA")
OPEN q_autoriz_2
FETCH q_autoriz_2 INTO r_r95.r95_autoriz_sri
CLOSE q_autoriz_2
FREE q_autoriz_2
--END IF
LET r_r95.r95_autoriz_sri = '.'
DISPLAY BY NAME r_r95.r95_motivo, r_r95.r95_usuario, r_r95.r95_fecing
IF vg_gui = 0 THEN
	CASE r_r95.r95_motivo
		WHEN 'V' DISPLAY 'VENTA'       TO tit_motivo
		WHEN 'D' DISPLAY 'DEVOLUCION'  TO tit_motivo
		WHEN 'I' DISPLAY 'IMPORTACION' TO tit_motivo
		WHEN 'N' DISPLAY 'TRANSFERENCIAS ENTRE LOCALIDADES' TO
				tit_motivo
	END CASE
END IF
LET int_flag = 0
INPUT BY NAME r_r95.r95_fecha_initras, r_r95.r95_num_sri,
	r_r95.r95_fecha_fintras, r_r95.r95_motivo, r_r95.r95_fecha_emi,
	r_r95.r95_punto_part, r_r95.r95_persona_guia, r_r95.r95_persona_id,
	r_r95.r95_placa, r_r95.r95_persona_dest, r_r95.r95_pers_id_dest,
	r_r95.r95_punto_lleg, r_r95.r95_proc_orden, r_r95.r95_cod_zona,
	r_r95.r95_cod_subzona
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(r_r95.r95_fecha_initras, r_r95.r95_num_sri,
				 r_r95.r95_fecha_fintras, r_r95.r95_motivo,
				 r_r95.r95_fecha_emi, r_r95.r95_punto_part,
				 r_r95.r95_persona_guia, r_r95.r95_persona_id,
				 r_r95.r95_placa, r_r95.r95_persona_dest,
				 r_r95.r95_pers_id_dest, r_r95.r95_punto_lleg,
				 r_r95.r95_proc_orden, r_r95.r95_cod_zona,
				 r_r95.r95_cod_subzona)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		IF vg_gui = 0 THEN
			CALL fl_visor_teclas_caracter() RETURNING int_flag 
			LET a = FGL_GETKEY()
			CLOSE WINDOW w_tf
			LET int_flag = 0
		END IF
	ON KEY(F2)
		IF INFIELD(r95_cod_zona) THEN
			CALL fl_ayuda_zonas(codcia, codloc, "A")
				RETURNING r_r108.r108_cod_zona,
					  r_r108.r108_descripcion
		      	IF r_r108.r108_cod_zona IS NOT NULL THEN
				LET r_r95.r95_cod_zona = r_r108.r108_cod_zona
				DISPLAY BY NAME r_r95.r95_cod_zona,
						r_r108.r108_descripcion
		      	END IF
		END IF
		IF INFIELD(r95_cod_subzona) AND r_r95.r95_cod_zona IS NOT NULL
		THEN
			CALL fl_ayuda_subzonas(codcia, codloc,
						r_r95.r95_cod_zona, "A")
				RETURNING r_r109.r109_cod_subzona,
					  r_r109.r109_descripcion
		      	IF r_r109.r109_cod_subzona IS NOT NULL THEN
				LET r_r95.r95_cod_subzona =
							r_r109.r109_cod_subzona
				DISPLAY BY NAME r_r95.r95_cod_subzona,
						r_r109.r109_descripcion
		      	END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r95_fecha_initras
		LET fecha_ini = r_r95.r95_fecha_initras
	BEFORE FIELD r95_num_sri
		LET aux_sri = r_r95.r95_num_sri
	BEFORE FIELD r95_fecha_emi
		LET fecha_emi = r_r95.r95_fecha_emi
	BEFORE FIELD r95_persona_id
		LET persona_id = r_r95.r95_persona_id
	BEFORE FIELD r95_pers_id_dest
		LET pers_id_dest = r_r95.r95_pers_id_dest
	AFTER FIELD r95_fecha_initras
		IF r_r95.r95_fecha_initras IS NULL THEN
			LET r_r95.r95_fecha_initras = fecha_ini
			DISPLAY BY NAME r_r95.r95_fecha_initras
		END IF
		IF r_r95.r95_fecha_initras < TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de iniciación del traslado no puede ser menor a la fecha de hoy.', 'exclamation')
			--NEXT FIELD r95_fecha_initras
		END IF
	AFTER FIELD r95_num_sri
		{--
		IF LENGTH(r_r95.r95_num_sri) < 14 THEN
			CALL fl_mostrar_mensaje('El número del SRI ingresado es incorrecto.', 'exclamation')
			NEXT FIELD r95_num_sri
		END IF
		IF r_r95.r95_num_sri[1, 2] <> '00' OR
		   r_r95.r95_num_sri[5, 6] <> '00' THEN
			CALL fl_mostrar_mensaje('El prefijo de venta o del local estan incorrectos en el número del SRI ingresado.', 'exclamation')
			NEXT FIELD r95_num_sri
		END IF
		IF r_r95.r95_num_sri[4, 4] <> '-' OR
		   r_r95.r95_num_sri[8, 8] <> '-' THEN
			CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
			NEXT FIELD r95_num_sri
		END IF
		--}
		IF r_r95.r95_num_sri IS NULL THEN
			LET r_r95.r95_num_sri = aux_sri
			DISPLAY BY NAME r_r95.r95_num_sri
		END IF
		CALL fl_validacion_num_sri(codcia, codloc, "GR", cont_cred,
						r_r95.r95_num_sri)
			RETURNING r_g37.*, r_r95.r95_num_sri, flag
		CASE flag
			WHEN -1
				RETURN 0
			WHEN 0
				LET r_r95.r95_num_sri = aux_sri
				DISPLAY BY NAME r_r95.r95_num_sri
				NEXT FIELD r95_num_sri
		END CASE
		IF aux_sri <> r_r95.r95_num_sri THEN
			SELECT COUNT(*) INTO cont
				FROM rept095
				WHERE r95_compania  = codcia
				  AND r95_localidad = codloc
  				  AND r95_num_sri   = r_r95.r95_num_sri
			IF cont > 0 THEN
				CALL fl_mostrar_mensaje('La secuencia del SRI ' || r_r95.r95_num_sri[9,15] || ' ya existe.','exclamation')
				LET r_r95.r95_num_sri = aux_sri
				DISPLAY BY NAME r_r95.r95_num_sri
				NEXT FIELD r95_num_sri
			END IF
		END IF
	AFTER FIELD r95_fecha_fintras
		IF r_r95.r95_fecha_fintras IS NOT NULL THEN
			IF r_r95.r95_fecha_fintras < TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de terminación del traslado no puede ser menor a la fecha de hoy.', 'exclamation')
				--NEXT FIELD r95_fecha_fintras
			END IF
		END IF
	AFTER FIELD r95_motivo
		IF vg_gui = 0 THEN
			CASE r_r95.r95_motivo
				WHEN 'V' DISPLAY 'VENTA'       TO tit_motivo
				WHEN 'D' DISPLAY 'DEVOLUCION'  TO tit_motivo
				WHEN 'I' DISPLAY 'IMPORTACION' TO tit_motivo
				WHEN 'N' DISPLAY 'TRANSFERENCIAS ENTRE LOCALIDADES' TO tit_motivo
			END CASE
		END IF
		IF cod_tran = 'TR' THEN
			LET r_r95.r95_motivo = 'N'
			DISPLAY BY NAME r_r95.r95_motivo
		END IF
		IF r_r95.r95_motivo = 'N' THEN
			LET r_r95.r95_entre_local = 'S'
		ELSE
			LET r_r95.r95_entre_local = 'N'
		END IF
	AFTER FIELD r95_fecha_emi
		IF r_r95.r95_fecha_emi IS NULL THEN
			LET r_r95.r95_fecha_emi = fecha_emi
			DISPLAY BY NAME r_r95.r95_fecha_emi
		END IF
		IF r_r95.r95_fecha_emi < TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de emisión no puede ser menor a la fecha de hoy.', 'exclamation')
			--NEXT FIELD r95_fecha_emi
		END IF
	AFTER FIELD r95_persona_id
		IF persona_id IS NOT NULL AND r_r95.r95_persona_id IS NULL THEN
			LET r_r95.r95_persona_id = persona_id
			DISPLAY BY NAME r_r95.r95_persona_id
		END IF
		IF r_r95.r95_persona_id IS NOT NULL THEN
			CALL fl_validar_cedruc_dig_ver(r_r95.r95_persona_id)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r95_persona_id
			END IF
		END IF
	AFTER FIELD r95_pers_id_dest
		IF pers_id_dest IS NOT NULL AND r_r95.r95_pers_id_dest IS NULL
		THEN
			LET r_r95.r95_pers_id_dest = pers_id_dest
			DISPLAY BY NAME r_r95.r95_pers_id_dest
		END IF
		IF r_r95.r95_pers_id_dest IS NOT NULL THEN
			CALL fl_validar_cedruc_dig_ver(r_r95.r95_pers_id_dest)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r95_pers_id_dest
			END IF
		END IF
	AFTER FIELD r95_cod_zona
		IF r_r95.r95_cod_zona IS NOT NULL THEN
			CALL fl_lee_zona(codcia, codloc, r_r95.r95_cod_zona)
				RETURNING r_r108.*
			IF r_r108.r108_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Esta Zona no existe en la compañía.', 'exclamation')
				NEXT FIELD r95_cod_zona
			END IF
			IF r_r108.r108_estado = "B" THEN
				CALL fl_mostrar_mensaje('Esta Zona esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r95_cod_zona
			END IF
			LET r_r95.r95_cod_zona = r_r108.r108_cod_zona
		ELSE
			INITIALIZE r_r108.*, r_r109.*, r_r95.r95_cod_zona,
					r_r95.r95_cod_subzona
				TO NULL
		END IF
		DISPLAY BY NAME r_r95.r95_cod_zona, r_r108.r108_descripcion,
				r_r95.r95_cod_subzona, r_r109.r109_descripcion
	AFTER FIELD r95_cod_subzona
		IF r_r95.r95_cod_zona IS NULL THEN
			INITIALIZE r_r109.*, r_r95.r95_cod_subzona TO NULL
			DISPLAY BY NAME r_r95.r95_cod_subzona,
					r_r109.r109_descripcion
			CONTINUE INPUT
		END IF
		IF r_r95.r95_cod_subzona IS NOT NULL THEN
			CALL fl_lee_subzona(codcia, codloc,
						r_r95.r95_cod_zona,
						r_r95.r95_cod_subzona)
				RETURNING r_r109.*
			IF r_r109.r109_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Esta Sub-Zona no existe en la compañía o no esta asociado a ésta zona.', 'exclamation')
				NEXT FIELD r95_cod_subzona
			END IF
			IF r_r109.r109_estado = "B" THEN
				CALL fl_mostrar_mensaje('Esta Sub-Zona esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r95_cod_subzona
			END IF
			LET r_r95.r95_cod_subzona = r_r109.r109_cod_subzona
		ELSE
			INITIALIZE r_r109.*, r_r95.r95_cod_subzona TO NULL
		END IF
		DISPLAY BY NAME r_r95.r95_cod_subzona, r_r109.r109_descripcion
	AFTER INPUT
		IF r_r95.r95_fecha_fintras IS NOT NULL THEN
			IF r_r95.r95_fecha_initras > r_r95.r95_fecha_fintras
			THEN
				CALL fl_mostrar_mensaje('La fecha de iniciación del traslado no puede ser mayor a la fecha de terminación.', 'exclamation')
				NEXT FIELD r95_fecha_initras
			END IF
		END IF
END INPUT
IF int_flag THEN
	LET mensaje = 'No se va a generar la Guía de Remisión.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
	LET int_flag = 0
	CLOSE WINDOW w_ayuf307
	RETURN 0
END IF
CALL fl_lee_localidad(codcia, codloc) RETURNING r_g02.*
LET r_r95.r95_compania    = codcia
LET r_r95.r95_localidad   = codloc
LET r_r95.r95_estado      = 'A'
WHILE TRUE
	SQL
		SELECT NVL(MAX(r95_guia_remision), 0) + 1
			INTO $r_r95.r95_guia_remision
			FROM rept095
			WHERE r95_compania  = $r_r95.r95_compania
			  AND r95_localidad = $r_r95.r95_localidad
	END SQL
	LET r_r95.r95_fecing  = fl_current()
	LET r_r95.r95_num_sri = r_g37.g37_pref_sucurs, "-",
				r_g37.g37_pref_pto_vta, "-",
				r_r95.r95_guia_remision USING "&&&&&&&&&"
	WHENEVER ERROR CONTINUE
	INSERT INTO rept095 VALUES (r_r95.*)
	IF STATUS = 0 THEN
		WHENEVER ERROR STOP
		EXIT WHILE
	END IF
END WHILE
{--
LET lim     = LENGTH(r_r95.r95_num_sri)
LET sec_sri = r_r95.r95_num_sri[9, lim]
UPDATE gent037
	SET g37_sec_num_sri = sec_sri
	WHERE g37_compania     = codcia
	  AND g37_localidad    = codloc
	  AND g37_tipo_doc     = "GR"
	  AND g37_secuencia    = secuencia
	  AND g37_sec_num_sri <= sec_sri
--}
IF num_ent IS NOT NULL THEN
	LET r_r96.r96_compania      = codcia
	LET r_r96.r96_localidad     = codloc
	LET r_r96.r96_guia_remision = r_r95.r95_guia_remision
	LET r_r96.r96_bodega        = bodega
	LET r_r96.r96_num_entrega   = num_ent
	INSERT INTO rept096 VALUES (r_r96.*)
END IF
IF cod_tran IS NOT NULL THEN
	LET r_r97.r97_compania      = codcia
	LET r_r97.r97_localidad     = codloc
	LET r_r97.r97_guia_remision = r_r95.r95_guia_remision
	LET r_r97.r97_cod_tran      = cod_tran
	LET r_r97.r97_num_tran      = num_tran
	INSERT INTO rept097 VALUES (r_r97.*)
END IF
LET int_flag = 0
CLOSE WINDOW w_ayuf307
LET mensaje  = 'Se generó Guía de Remisión No. ', r_r95.r95_num_sri CLIPPED, '.'
		--r_r95.r95_guia_remision USING "<<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
RETURN 1

END FUNCTION



FUNCTION fl_agregar_guia_remision(codcia, codloc, bodega, num_ent, cod_tran,
					num_tran)
DEFINE codcia		LIKE rept095.r95_compania
DEFINE codloc		LIKE rept095.r95_localidad
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE num_ent		LIKE rept036.r36_num_entrega
DEFINE cod_tran		LIKE rept034.r34_cod_tran
DEFINE num_tran		LIKE rept034.r34_num_tran
DEFINE r_r02_1		RECORD LIKE rept002.*
DEFINE r_r02_2		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE r_r97		RECORD LIKE rept097.*
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(150)

IF num_ent IS NULL AND cod_tran IS NULL THEN
	CALL fl_mostrar_mensaje('No hay ninguna transacción o nota de entrega, para relacionar la guía de remisión.', 'exclamation')
	RETURN 0
END IF
IF num_ent IS NOT NULL THEN
	CALL fl_hacer_pregunta('Desea agregar esta nota de entrega a la Guía de Remisión.', 'No')
		RETURNING resp
END IF
IF cod_tran = 'TR' THEN
	CALL fl_hacer_pregunta('Desea agregar esta transferencia a la Guía de Remisión.', 'No')
		RETURNING resp
END IF
IF resp <> 'Yes' THEN
	RETURN 0
END IF
INITIALIZE r_r19.*, r_r95.*, r_r96.*, r_r97.* TO NULL
IF num_ent IS NOT NULL THEN
	DECLARE q_r97 CURSOR FOR
		SELECT rept097.*
			FROM rept097, rept095
			WHERE r97_compania      = codcia
			  AND r97_localidad     = codloc
			  AND r97_cod_tran      = cod_tran
			  AND r97_num_tran      = num_tran
			  AND r95_compania      = r97_compania
			  AND r95_localidad     = r97_localidad
			  AND r95_guia_remision = r97_guia_remision
			  AND r95_estado        = 'A'
	OPEN q_r97
	FETCH q_r97 INTO r_r97.*
	IF r_r97.r97_compania IS NULL THEN
		CALL fl_mostrar_mensaje('La factura de la nota de entrega no tiene guía de remisión.', 'stop')
		RETURN 0
	END IF
END IF
IF cod_tran = 'TR' THEN
	DECLARE q_r95 CURSOR FOR
		SELECT * FROM rept097, rept019, rept095
		WHERE r97_compania      = codcia
		  AND r97_localidad     = codloc
		  AND r97_cod_tran      = cod_tran
		  AND r19_compania      = r97_compania
		  AND r19_localidad     = r97_localidad
		  AND r19_cod_tran      = r97_cod_tran
		  AND r19_num_tran      = r97_num_tran
		  AND r95_compania      = r19_compania
		  AND r95_localidad     = r19_localidad
		  AND r95_guia_remision = r97_guia_remision
		  AND r95_estado        = 'A'
		ORDER BY r95_fecing DESC
	LET resul = 0
	FOREACH q_r95 INTO r_r97.*, r_r19.*, r_r95.*
		CALL fl_lee_bodega_rep(r_r95.r95_compania,r_r19.r19_bodega_dest)
			RETURNING r_r02_1.*
		CALL fl_lee_bodega_rep(codcia, bodega) RETURNING r_r02_2.*
		IF r_r02_1.r02_localidad = r_r02_2.r02_localidad THEN
			LET resul = 1
			EXIT FOREACH
		END IF
	END FOREACH
	IF NOT resul THEN
		CALL fl_mostrar_mensaje('La localidad de la bodega de destino de esta transferencia, no tiene guía de remisión.', 'stop')
		RETURN 0
	END IF
END IF
SELECT * INTO r_r95.*
	FROM rept095
	WHERE r95_compania      = r_r97.r97_compania
	  AND r95_localidad     = r_r97.r97_localidad
	  AND r95_guia_remision = r_r97.r97_guia_remision
	  AND r95_estado        = 'A'
IF num_ent IS NOT NULL THEN
	LET r_r96.r96_compania      = r_r95.r95_compania
	LET r_r96.r96_localidad     = r_r95.r95_localidad
	LET r_r96.r96_guia_remision = r_r95.r95_guia_remision
	LET r_r96.r96_bodega        = bodega
	LET r_r96.r96_num_entrega   = num_ent
	INSERT INTO rept096 VALUES (r_r96.*)
END IF
IF cod_tran = 'TR' THEN
	LET r_r97.r97_compania      = codcia
	LET r_r97.r97_localidad     = codloc
	LET r_r97.r97_guia_remision = r_r95.r95_guia_remision
	LET r_r97.r97_cod_tran      = cod_tran
	LET r_r97.r97_num_tran      = num_tran
	INSERT INTO rept097 VALUES (r_r97.*)
END IF
LET mensaje  = 'Se agregó a Guía de Remisión No. ',r_r95.r95_num_sri CLIPPED,'.'
		--r_r95.r95_guia_remision USING "<<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
RETURN 1

END FUNCTION



FUNCTION fl_ver_guia_remision(codcia, codloc, bodega, num_ent, cod_tran,
				num_tran)
DEFINE codcia		LIKE rept095.r95_compania
DEFINE codloc		LIKE rept095.r95_localidad
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE num_ent		LIKE rept036.r36_num_entrega
DEFINE cod_tran		LIKE rept034.r34_cod_tran
DEFINE num_tran		LIKE rept034.r34_num_tran
DEFINE run_prog		CHAR(10)
DEFINE comando		VARCHAR(200)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_r108		RECORD LIKE rept108.*
DEFINE r_r109		RECORD LIKE rept109.*

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 71
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 6
	LET num_rows = 18
	LET num_cols = 72
END IF
OPEN WINDOW w_ayuf307 AT row_ini, 05 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf307 FROM "../../LIBRERIAS/forms/ayuf307"
ELSE
	OPEN FORM f_ayuf307 FROM "../../LIBRERIAS/forms/ayuf307c"
END IF
DISPLAY FORM f_ayuf307
INITIALIZE r_r95.* TO NULL
IF cod_tran IS NULL THEN
	SELECT rept095.* INTO r_r95.*
		FROM rept096, rept095
		WHERE r96_compania      = codcia
		  AND r96_localidad     = codloc
		  AND r96_bodega        = bodega
		  AND r96_num_entrega   = num_ent
		  AND r95_compania      = r96_compania
		  AND r95_localidad     = r96_localidad
		  AND r95_guia_remision = r96_guia_remision
		  AND r95_estado        <> 'E'
ELSE
	SELECT rept095.* INTO r_r95.*
		FROM rept097, rept095
		WHERE r97_compania      = codcia
		  AND r97_localidad     = codloc
		  AND r97_cod_tran      = cod_tran
		  AND r97_num_tran      = num_tran
		  AND r95_compania      = r97_compania
		  AND r95_localidad     = r97_localidad
		  AND r95_guia_remision = r97_guia_remision
		  AND r95_estado        <> 'E'
END IF
IF r_r95.r95_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe Guía de Remisión.', 'exclamation')
	LET int_flag = 0
	CLOSE WINDOW w_ayuf307
	RETURN
END IF
DISPLAY BY NAME r_r95.r95_fecha_initras,r_r95.r95_num_sri,
		r_r95.r95_fecha_fintras, r_r95.r95_motivo, r_r95.r95_fecha_emi,
		r_r95.r95_punto_part, r_r95.r95_persona_guia,
		r_r95.r95_persona_id, r_r95.r95_persona_dest, r_r95.r95_placa,
		r_r95.r95_pers_id_dest, r_r95.r95_punto_lleg,
		r_r95.r95_proc_orden, r_r95.r95_cod_zona, r_r95.r95_cod_subzona,
		r_r95.r95_usuario, r_r95.r95_fecing
CALL fl_lee_zona(codcia, codloc, r_r95.r95_cod_zona) RETURNING r_r108.*
CALL fl_lee_subzona(codcia, codloc, r_r95.r95_cod_zona, r_r95.r95_cod_subzona)
	RETURNING r_r109.*
DISPLAY BY NAME r_r108.r108_descripcion, r_r109.r109_descripcion
MENU 'OPCIONES'
	COMMAND KEY('I') 'Imprimir' 'Imprime la Guía de Remisión. '
		LET run_prog = '; fglrun '
		IF vg_gui = 0 THEN
			LET run_prog = '; fglgo '
		END IF
		LET comando  = 'cd ..', vg_separador, '..', vg_separador,
				'REPUESTOS', vg_separador, 'fuentes',
				vg_separador, run_prog CLIPPED, ' repp434 ',
				vg_base, ' ', vg_modulo, ' ', codcia, ' ',
				codloc, ' ', r_r95.r95_guia_remision, ' "',
				cod_tran, '"'
		RUN comando
	COMMAND KEY('S') 'Salir' 'Salir al menu anterior. '
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_ayuf307
RETURN

END FUNCTION



FUNCTION fl_lee_configuracion_credito_cxc(cod_cia, cod_loc)
DEFINE cod_cia		LIKE cxct061.z61_compania
DEFINE cod_loc		LIKE cxct061.z61_localidad
DEFINE r_z61		RECORD LIKE cxct061.*

INITIALIZE r_z61.* TO NULL
SELECT * INTO r_z61.*
	FROM cxct061
	WHERE z61_compania  = cod_cia
	  AND z61_localidad = cod_loc
RETURN r_z61.*

END FUNCTION



FUNCTION fl_lee_guias_remision(codcia, codloc, guia)
DEFINE codcia		LIKE rept095.r95_compania
DEFINE codloc		LIKE rept095.r95_localidad
DEFINE guia		LIKE rept095.r95_guia_remision
DEFINE r_r95		RECORD LIKE rept095.*

INITIALIZE r_r95.* TO NULL
SELECT * INTO r_r95.*
	FROM rept095
	WHERE r95_compania      = codcia
	  AND r95_localidad     = codloc
	  AND r95_guia_remision = guia
RETURN r_r95.*

END FUNCTION



FUNCTION fl_lee_conf_adic_rol(codcia)
DEFINE codcia		LIKE rolt090.n90_compania
DEFINE r_n90		RECORD LIKE rolt090.*

INITIALIZE r_n90.* TO NULL
SELECT * INTO r_n90.* FROM rolt090 WHERE n90_compania = codcia
RETURN r_n90.*

END FUNCTION



FUNCTION fl_lee_porc_impto(codcia, codloc, tipo_i, porc, tipo)
DEFINE codcia		LIKE gent058.g58_compania
DEFINE codloc		LIKE gent058.g58_localidad
DEFINE tipo_i		LIKE gent058.g58_tipo_impto
DEFINE porc		LIKE gent058.g58_porc_impto
DEFINE tipo		LIKE gent058.g58_tipo
DEFINE r_g58		RECORD LIKE gent058.*

INITIALIZE r_g58.* TO NULL
SELECT * INTO r_g58.*
	FROM gent058
	WHERE g58_compania   = codcia
	  AND g58_localidad  = codloc
	  AND g58_tipo_impto = tipo_i
	  AND g58_porc_impto = porc
	  AND g58_tipo       = tipo
RETURN r_g58.*

END FUNCTION



FUNCTION fl_lee_conf_ice(codcia, codigo, porc, codimp)
DEFINE codcia		LIKE srit010.s10_compania
DEFINE codigo		LIKE srit010.s10_codigo
DEFINE porc		LIKE srit010.s10_porcentaje_ice
DEFINE codimp		LIKE srit010.s10_codigo_impto
DEFINE r_s10		RECORD LIKE srit010.*

INITIALIZE r_s10.* TO NULL
SELECT * INTO r_s10.*
	FROM srit010
	WHERE s10_compania       = codcia
	  AND s10_codigo         = codigo
	  AND s10_porcentaje_ice = porc
	  AND s10_codigo_impto   = codimp
RETURN r_s10.*

END FUNCTION



FUNCTION fl_determinar_si_es_retencion(codcia, codigo_pago, cont_cred)
DEFINE codcia		LIKE cajt001.j01_compania
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE resul		SMALLINT

DECLARE q_ret1 CURSOR FOR
	SELECT UNIQUE j91_codigo_pago
		FROM cajt091
		WHERE j91_compania    = codcia
		  AND j91_codigo_pago = codigo_pago
		  AND j91_cont_cred   = cont_cred
OPEN q_ret1
FETCH q_ret1
IF STATUS = NOTFOUND THEN
	LET resul = 0
ELSE
	LET resul = 1
END IF
CLOSE q_ret1
FREE q_ret1
RETURN resul

END FUNCTION



FUNCTION fl_lee_codigos_sri(codcia, tipo_ret, porc_ret, cod_sri, fec_ini_por)
DEFINE codcia		LIKE ordt003.c03_compania
DEFINE tipo_ret		LIKE ordt003.c03_tipo_ret
DEFINE porc_ret		LIKE ordt003.c03_porcentaje
DEFINE cod_sri		LIKE ordt003.c03_codigo_sri
DEFINE fec_ini_por	LIKE ordt003.c03_fecha_ini_porc
DEFINE r_c03		RECORD LIKE ordt003.*

INITIALIZE r_c03.* TO NULL
SELECT * INTO r_c03.*
	FROM ordt003
	WHERE c03_compania       = codcia
	  AND c03_tipo_ret       = tipo_ret
	  AND c03_porcentaje     = porc_ret
	  AND c03_codigo_sri     = cod_sri
	  AND c03_fecha_ini_porc = fec_ini_por
RETURN r_c03.*

END FUNCTION



FUNCTION fl_lee_cab_retencion_cli(codcia, codcli, tipo_ret, porc_ret, cod_sri,
				fec_ini_por)
DEFINE codcia		LIKE cxct008.z08_compania
DEFINE codcli		LIKE cxct008.z08_codcli
DEFINE tipo_ret		LIKE cxct008.z08_tipo_ret
DEFINE porc_ret		LIKE cxct008.z08_porcentaje
DEFINE cod_sri		LIKE cxct008.z08_codigo_sri
DEFINE fec_ini_por	LIKE cxct008.z08_fecha_ini_porc
DEFINE r_z08		RECORD LIKE cxct008.*

INITIALIZE r_z08.* TO NULL
SELECT * INTO r_z08.*
	FROM cxct008
	WHERE z08_compania    = codcia
	  AND z08_codcli      = codcli
	  AND z08_tipo_ret    = tipo_ret
	  AND z08_porcentaje  = porc_ret
	  AND z08_codigo_sri  = cod_sri
	  AND z08_fecha_ini_porc = fec_ini_por
RETURN r_z08.*

END FUNCTION



FUNCTION fl_lee_det_retencion_cli(codcia, codcli, tipo_ret, porc_ret, cod_sri,
					fec_ini_por, codigo_pago, cont_cred)
DEFINE codcia		LIKE cxct009.z09_compania
DEFINE codcli		LIKE cxct009.z09_codcli
DEFINE tipo_ret		LIKE cxct009.z09_tipo_ret
DEFINE porc_ret		LIKE cxct009.z09_porcentaje
DEFINE cod_sri		LIKE cxct009.z09_codigo_sri
DEFINE fec_ini_por	LIKE cxct009.z09_fecha_ini_porc
DEFINE codigo_pago	LIKE cxct009.z09_codigo_pago
DEFINE cont_cred	LIKE cxct009.z09_cont_cred
DEFINE r_z09		RECORD LIKE cxct009.*

INITIALIZE r_z09.* TO NULL
SELECT * INTO r_z09.*
	FROM cxct009
	WHERE z09_compania    = codcia
	  AND z09_codcli      = codcli
	  AND z09_tipo_ret    = tipo_ret
	  AND z09_porcentaje  = porc_ret
	  AND z09_codigo_sri  = cod_sri
	  AND z09_fecha_ini_porc = fec_ini_por
	  AND z09_codigo_pago = codigo_pago
	  AND z09_cont_cred   = cont_cred
RETURN r_z09.*

END FUNCTION



FUNCTION fl_lee_det_tipo_ret_caja(codcia, codigo_pago, cont_cred, tipo_ret,
					porc_ret)
DEFINE codcia		LIKE cajt091.j91_compania
DEFINE codigo_pago	LIKE cajt091.j91_codigo_pago
DEFINE cont_cred	LIKE cajt091.j91_cont_cred
DEFINE tipo_ret		LIKE cajt091.j91_tipo_ret
DEFINE porc_ret		LIKE cajt091.j91_porcentaje
DEFINE r_j91		RECORD LIKE cajt091.*

INITIALIZE r_j91.* TO NULL
SELECT * INTO r_j91.*
	FROM cajt091
	WHERE j91_compania    = codcia
	  AND j91_codigo_pago = codigo_pago
	  AND j91_cont_cred   = cont_cred
	  AND j91_tipo_ret    = tipo_ret
	  AND j91_porcentaje  = porc_ret
RETURN r_j91.*

END FUNCTION



FUNCTION fl_solo_numeros(cadena)
DEFINE cadena		VARCHAR(255)
DEFINE resul, i		SMALLINT

LET resul = 1
FOR i = 1 TO LENGTH(cadena)
	IF (cadena[i, i] < '0') OR (cadena[i, i] > '9') THEN
		LET resul = 0
		EXIT FOR
	END IF
END FOR
RETURN resul

END FUNCTION



FUNCTION fl_lee_codigo_sri_def(codcia, tipo_ret, porc, cliprov)
DEFINE codcia		LIKE srit025.s25_compania
DEFINE tipo_ret		LIKE srit025.s25_tipo_ret
DEFINE porc		LIKE srit025.s25_porcentaje
DEFINE cliprov		LIKE srit025.s25_cliprov
DEFINE r_s25		RECORD LIKE srit025.*

INITIALIZE r_s25.* TO NULL
DECLARE q_s25 CURSOR FOR
	SELECT * FROM srit025
		WHERE s25_compania   = codcia
		  AND s25_tipo_ret   = tipo_ret
		  AND s25_porcentaje = porc
		  AND s25_cliprov    = cliprov
OPEN q_s25
FETCH q_s25 INTO r_s25.*
CLOSE q_s25
FREE q_s25
RETURN r_s25.*

END FUNCTION



FUNCTION fl_lee_tipo_arch_iess(codcia, codigo_arch, tipo_arch)
DEFINE codcia		LIKE rolt022.n22_compania
DEFINE codigo_arch	LIKE rolt022.n22_codigo_arch
DEFINE tipo_arch	LIKE rolt022.n22_tipo_arch
DEFINE r_n22		RECORD LIKE rolt022.*

INITIALIZE r_n22.* TO NULL
SELECT * INTO r_n22.*
	FROM rolt022
	WHERE n22_compania    = codcia
	  AND n22_codigo_arch = codigo_arch
	  AND n22_tipo_arch   = tipo_arch
RETURN r_n22.*

END FUNCTION



FUNCTION fl_lee_causa_arch_iess(codcia, codigo_arch, tipo_arch, tipo_causa,
				secuen)
DEFINE codcia		LIKE rolt023.n23_compania
DEFINE codigo_arch	LIKE rolt023.n23_codigo_arch
DEFINE tipo_arch	LIKE rolt023.n23_tipo_arch
DEFINE tipo_causa	LIKE rolt023.n23_tipo_causa
DEFINE secuen		LIKE rolt023.n23_secuencia
DEFINE r_n23		RECORD LIKE rolt023.*

INITIALIZE r_n23.* TO NULL
SELECT * INTO r_n23.*
	FROM rolt023
	WHERE n23_compania    = codcia
	  AND n23_codigo_arch = codigo_arch
	  AND n23_tipo_arch   = tipo_arch
	  AND n23_tipo_causa  = tipo_causa
	  AND n23_secuencia   = secuen
RETURN r_n23.*

END FUNCTION



FUNCTION fl_lee_caus_ori_pag_arch_iess(codcia, codigo_arch, tipo_arch,
					tipo_seg_pag, tipo)
DEFINE codcia		LIKE rolt024.n24_compania
DEFINE codigo_arch	LIKE rolt024.n24_codigo_arch
DEFINE tipo_arch	LIKE rolt024.n24_tipo_arch
DEFINE tipo_seg_pag	LIKE rolt024.n24_tipo_seg_pag
DEFINE tipo		LIKE rolt024.n24_tipo
DEFINE r_n24		RECORD LIKE rolt024.*

INITIALIZE r_n24.* TO NULL
SELECT * INTO r_n24.*
	FROM rolt024
	WHERE n24_compania     = codcia
	  AND n24_codigo_arch  = codigo_arch
	  AND n24_tipo_arch    = tipo_arch
	  AND n24_tipo_seg_pag = tipo_seg_pag
	  AND n24_tipo         = tipo
RETURN r_n24.*

END FUNCTION



FUNCTION fl_lee_tipo_empl_arch_iess(codcia, codigo_arch, tipo_arch,
					tipo_emp_rel, tipo)
DEFINE codcia		LIKE rolt025.n25_compania
DEFINE codigo_arch	LIKE rolt025.n25_codigo_arch
DEFINE tipo_arch	LIKE rolt025.n25_tipo_arch
DEFINE tipo_emp_rel	LIKE rolt025.n25_tipo_emp_rel
DEFINE tipo		LIKE rolt025.n25_tipo
DEFINE r_n25		RECORD LIKE rolt025.*

INITIALIZE r_n25.* TO NULL
SELECT * INTO r_n25.*
	FROM rolt025
	WHERE n25_compania     = codcia
	  AND n25_codigo_arch  = codigo_arch
	  AND n25_tipo_arch    = tipo_arch
	  AND n25_tipo_emp_rel = tipo_emp_rel
	  AND n25_tipo         = tipo
RETURN r_n25.*

END FUNCTION



FUNCTION fl_digito_bodega_contrato(codcia, bod1, bod2)
DEFINE codcia		LIKE rept002.r02_compania
DEFINE bod1, bod2	LIKE rept002.r02_codigo
DEFINE r_r02_1, r_r02_2	RECORD LIKE rept002.*

CALL fl_lee_bodega_rep(codcia, bod1) RETURNING r_r02_1.*
CALL fl_lee_bodega_rep(codcia, bod2) RETURNING r_r02_2.*
IF r_r02_1.r02_tipo_ident = 'C' THEN
	RETURN 1
END IF
IF r_r02_2.r02_tipo_ident = 'C' THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_lee_estado_activos(codcia, estado)
DEFINE codcia		LIKE actt006.a06_compania
DEFINE estado		LIKE actt006.a06_estado
DEFINE r_a06		RECORD LIKE actt006.*

INITIALIZE r_a06.* TO NULL
SELECT * INTO r_a06.*
	FROM actt006
	WHERE a06_compania = codcia
	  AND a06_estado   = estado
RETURN r_a06.*

END FUNCTION



FUNCTION fl_lee_tipo_tran_act(tipo_tran)
DEFINE tipo_tran	LIKE actt004.a04_codigo_proc
DEFINE r_a04		RECORD LIKE actt004.*

INITIALIZE r_a04.* TO NULL
SELECT * INTO r_a04.*
	FROM actt004
	WHERE a04_codigo_proc = tipo_tran
RETURN r_a04.*

END FUNCTION



FUNCTION fl_retorna_expr_estado_act(codcia, estado, flag)
DEFINE codcia		LIKE actt006.a06_compania
DEFINE estado		LIKE actt006.a06_estado
DEFINE flag		SMALLINT
DEFINE long		SMALLINT
DEFINE expr_est		VARCHAR(200)

LET expr_est = NULL
IF estado <> 'T' THEN
	IF estado <> 'X' THEN
		LET expr_est = '   AND a10_estado = "', estado, '"'
	ELSE
		LET expr_est = '   AND a10_estado IN ("N", "R", "E", "S", "V",',
							' "D", "C") '
	END IF
ELSE
	DECLARE ex_est CURSOR FOR
		SELECT a06_estado
			FROM actt006
			WHERE a06_compania = codcia
	LET expr_est = '   AND a10_estado IN ('
	FOREACH ex_est INTO estado
		IF flag THEN
			IF estado = 'A' OR estado = 'B' THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF estado = 'X' OR estado = 'T' THEN
			CONTINUE FOREACH
		END IF
		LET expr_est = expr_est CLIPPED, ' "', estado, '",'
	END FOREACH
	LET long     = LENGTH(expr_est)
	LET expr_est = expr_est[1, long - 1] CLIPPED, ') '
END IF
RETURN expr_est

END FUNCTION



FUNCTION fl_valida_numeros(numero)
DEFINE numero		VARCHAR(30)
DEFINE resul, i, j, lim	SMALLINT

LET resul = 1
LET lim   = LENGTH(numero)
FOR i = 1 TO lim
	IF i = lim AND numero[i, i] = ' ' THEN
		EXIT FOR
	END IF
	IF numero[i, i] < '0' OR numero[i, i] > '9' THEN
		CALL fl_mostrar_mensaje('Digite solo numeros.', 'exclamation')
		LET resul = 0
		EXIT FOR
	END IF
END FOR
RETURN resul

END FUNCTION



FUNCTION fl_generar_nueva_fecha_z22(r_z22, numsol)
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE numsol		LIKE cxct024.z24_numero_sol
DEFINE r_reg		RECORD
				num_id		INTEGER,
				cia		LIKE cxct022.z22_compania,
				loc		LIKE cxct022.z22_localidad,
				codcli		LIKE cxct022.z22_codcli,
				tip_tr		LIKE cxct022.z22_tipo_trn,
				num_tr		LIKE cxct022.z22_num_trn,
				fecing		LIKE cxct022.z22_fecing
			END RECORD
DEFINE intentos		SMALLINT
DEFINE expr_sol		VARCHAR(100)
DEFINE query		CHAR(4000)

--display ' cli ', r_z22.z22_codcli, ' ', r_z22.z22_tipo_trn, ' ', r_z22.z22_num_trn, '  numsol = ', numsol
LET expr_sol = NULL
IF numsol > 0 THEN
	LET expr_sol = '   AND z25_numero_sol = ', numsol
END IF
LET query = 'SELECT a.ROWID num_id, a.z22_compania cia, a.z22_localidad loc, ',
			'a.z22_codcli codcli, a.z22_tipo_trn tip_tr, ',
			'a.z22_num_trn num_tr, a.z22_fecing fecing',
		' FROM cxct023 b, cxct022 a ',
		' WHERE b.z23_compania  = ', r_z22.z22_compania,
		'   AND b.z23_localidad = ', r_z22.z22_localidad,
		'   AND b.z23_codcli    = ', r_z22.z22_codcli,
		'   AND EXISTS ',
			'(SELECT 1 FROM cxct025 ',
				'WHERE z25_compania   = b.z23_compania ',
				'  AND z25_localidad  = b.z23_localidad ',
				expr_sol CLIPPED,
				'  AND z25_codcli     = b.z23_codcli ',
				'  AND z25_tipo_doc   = b.z23_tipo_doc ',
				'  AND z25_num_doc    = b.z23_num_doc ',
				'  AND z25_dividendo  = b.z23_div_doc) ',
		'   AND a.z22_compania  = b.z23_compania ',
		'   AND a.z22_localidad = b.z23_localidad ',
		'   AND a.z22_codcli    = b.z23_codcli ',
		'   AND a.z22_tipo_trn  = b.z23_tipo_trn ',
		'   AND a.z22_num_trn   = b.z23_num_trn ',
		'   AND a.ROWID        >= ',
			'(SELECT MAX(c.ROWID) ',
			'FROM cxct023 d, cxct022 c ',
			'WHERE d.z23_compania  = a.z22_compania ',
			'  AND d.z23_localidad = a.z22_localidad ',
			'  AND d.z23_codcli    = a.z22_codcli ',
			'  AND d.z23_tipo_trn  = a.z22_tipo_trn ',
			'  AND d.z23_num_trn   = a.z22_num_trn ',
			'  AND EXISTS ',
				'(SELECT 1 FROM cxct025 ',
				'WHERE z25_compania   = d.z23_compania ',
				'  AND z25_localidad  = d.z23_localidad ',
				expr_sol CLIPPED,
				'  AND z25_codcli     = d.z23_codcli ',
				'  AND z25_tipo_doc   = d.z23_tipo_doc ',
				'  AND z25_num_doc    = d.z23_num_doc ',
				'  AND z25_dividendo  = d.z23_div_doc) ',
		'   AND c.z22_compania  = d.z23_compania ',
		'   AND c.z22_localidad = d.z23_localidad ',
		'   AND c.z22_codcli    = d.z23_codcli ',
		'   AND c.z22_tipo_trn  = "', r_z22.z22_tipo_trn, '"',
		'   AND c.z22_num_trn   = ', r_z22.z22_num_trn, ') ',
		' INTO TEMP t1 '
PREPARE exec_t1_fec FROM query 
EXECUTE exec_t1_fec
SELECT a.num_id n_id, a.tip_tr t_tr, a.num_tr n_tr, a.fecing fec
	FROM t1 a
	WHERE a.num_id = (SELECT MIN(b.num_id) FROM t1 b)
	INTO TEMP t2
SELECT * FROM t1
	WHERE fecing >= (SELECT UNIQUE fec FROM t2)
	  --AND num_id NOT IN (SELECT n_id FROM t2)
	INTO TEMP t3
DROP TABLE t1
DECLARE q_fec_ult CURSOR WITH HOLD FOR
	SELECT * FROM t3
		ORDER BY num_id
--display 'antes foreach '
FOREACH q_fec_ult INTO r_reg.*
	SELECT * FROM t2
		WHERE fec > r_reg.fecing 
	IF STATUS = NOTFOUND THEN
--display r_reg.*
		CONTINUE FOREACH
	END IF
	SELECT fec INTO r_reg.fecing FROM t2
	LET r_reg.fecing = r_reg.fecing + 1 UNITS SECOND
	BEGIN WORK
		LET intentos = 1
		WHILE intentos <= 3
			WHENEVER ERROR CONTINUE
			SET LOCK MODE TO WAIT 1
			UPDATE cxct022
				SET z22_fecing = r_reg.fecing
				WHERE z22_compania  = r_reg.cia
				  AND z22_localidad = r_reg.loc
				  AND z22_codcli    = r_reg.codcli
				  AND z22_tipo_trn  = r_reg.tip_tr
				  AND z22_num_trn   = r_reg.num_tr
			IF STATUS <> 0 THEN
				LET intentos = intentos + 1
				CONTINUE WHILE
			END IF
			WHENEVER ERROR STOP
		END WHILE
		IF intentos > 3 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('La fecha de esta transaccion de Cobranzas esta incorrecta. Por favor llame al ADMINISTRADOR.', 'stop')
			EXIT FOREACH
		END IF
	COMMIT WORK
END FOREACH
DROP TABLE t2
DROP TABLE t3
--display ' '

END FUNCTION



FUNCTION fl_lee_composicion_cab(codcia, codloc, item_comp)
DEFINE codcia		LIKE rept046.r46_compania
DEFINE codloc		LIKE rept046.r46_localidad
DEFINE item_comp	LIKE rept046.r46_item_comp
DEFINE r_r46		RECORD LIKE rept046.*

INITIALIZE r_r46.* TO NULL
DECLARE q_r46_2 CURSOR FOR
	SELECT * FROM rept046
		WHERE r46_compania  = codcia
		  AND r46_localidad = codloc
		  AND r46_item_comp = item_comp
		ORDER BY r46_item_comp
OPEN q_r46_2
FETCH q_r46_2 INTO r_r46.*
CLOSE q_r46_2
FREE q_r46_2
RETURN r_r46.*

END FUNCTION



FUNCTION fl_lee_composicion_cab3(codcia, codloc, compos)
DEFINE codcia		LIKE rept046.r46_compania
DEFINE codloc		LIKE rept046.r46_localidad
DEFINE compos		LIKE rept046.r46_composicion
DEFINE r_r46		RECORD LIKE rept046.*

INITIALIZE r_r46.* TO NULL
DECLARE q_r46 CURSOR FOR
	SELECT * FROM rept046
		WHERE r46_compania    = codcia
		  AND r46_localidad   = codloc
		  AND r46_composicion = compos
		ORDER BY r46_composicion
OPEN q_r46
FETCH q_r46 INTO r_r46.*
CLOSE q_r46
FREE q_r46
RETURN r_r46.*

END FUNCTION



FUNCTION fl_lee_composicion_cab2(codcia, codloc, compos, item_comp)
DEFINE codcia		LIKE rept046.r46_compania
DEFINE codloc		LIKE rept046.r46_localidad
DEFINE compos		LIKE rept046.r46_composicion
DEFINE item_comp	LIKE rept046.r46_item_comp
DEFINE r_r46		RECORD LIKE rept046.*

INITIALIZE r_r46.* TO NULL
SELECT * INTO r_r46.*
	FROM rept046
	WHERE r46_compania    = codcia
	  AND r46_localidad   = codloc
	  AND r46_composicion = compos
	  AND r46_item_comp   = item_comp
RETURN r_r46.*

END FUNCTION



FUNCTION fl_lee_tipo_ident_bod(codcia, tipo)
DEFINE codcia		LIKE rept009.r09_compania
DEFINE tipo		LIKE rept009.r09_tipo_ident
DEFINE r_r09		RECORD LIKE rept009.*

INITIALIZE r_r09.* TO NULL
SELECT * INTO r_r09.*
	FROM rept009
	WHERE r09_compania   = codcia
	  AND r09_tipo_ident = tipo
RETURN r_r09.*

END FUNCTION



FUNCTION fl_item_tiene_movimientos(codcia, item)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE item		LIKE rept010.r10_codigo
DEFINE cuantos		INTEGER
DEFINE resul		SMALLINT
DEFINE codloc		LIKE gent002.g02_localidad

LET codloc = vg_codloc
IF vg_codloc = 3 THEN
	LET codloc = 5
END IF
SELECT COUNT(*)
	INTO cuantos
	FROM rept020
	WHERE r20_compania   = codcia
	  AND r20_localidad IN (vg_codloc, codloc)
	  AND r20_item       = item
LET resul = 0
IF cuantos > 0 THEN
	LET resul = 1
END IF
RETURN resul

END FUNCTION



FUNCTION fl_lee_transaccion_remota(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE rept090.r90_compania
DEFINE cod_loc		LIKE rept090.r90_localidad
DEFINE cod_tran		LIKE rept090.r90_cod_tran
DEFINE num_tran		LIKE rept090.r90_num_tran
DEFINE r		RECORD LIKE rept090.*

INITIALIZE r.* TO NULL
--IF cod_tran <> 'TR' THEN
IF cod_loc = 0 THEN
	CASE vg_codloc
		WHEN 1 LET cod_loc = 3
		WHEN 3 LET cod_loc = 1
		WHEN 4 LET cod_loc = 3
	END CASE
END IF
SELECT * INTO r.*
	FROM rept090
	WHERE r90_compania  = cod_cia
	  AND r90_localidad = cod_loc
	  AND r90_cod_tran  = cod_tran
	  AND r90_num_tran  = num_tran
RETURN r.*

END FUNCTION



FUNCTION fl_lee_transaccion_cab_rem(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE rept091.r91_compania
DEFINE cod_loc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE r		RECORD LIKE rept091.*

INITIALIZE r.* TO NULL
SELECT * INTO r.*
	FROM rept091
	WHERE r91_compania  = cod_cia
	  AND r91_localidad = cod_loc
	  AND r91_cod_tran  = cod_tran
	  AND r91_num_tran  = num_tran
RETURN r.*

END FUNCTION



FUNCTION fl_lee_zona(codcia, codloc, zona)
DEFINE codcia		LIKE rept108.r108_compania
DEFINE codloc		LIKE rept108.r108_localidad
DEFINE zona		LIKE rept108.r108_cod_zona
DEFINE r_r108		RECORD LIKE rept108.*

INITIALIZE r_r108.* TO NULL
SELECT * INTO r_r108.*
	FROM rept108
	WHERE r108_compania  = codcia
	  AND r108_localidad = codloc
	  AND r108_cod_zona  = zona
RETURN r_r108.*

END FUNCTION



FUNCTION fl_lee_subzona(codcia, codloc, zona, subzona)
DEFINE codcia		LIKE rept109.r109_compania
DEFINE codloc		LIKE rept109.r109_localidad
DEFINE zona		LIKE rept109.r109_cod_zona
DEFINE subzona		LIKE rept109.r109_cod_subzona
DEFINE r_r109		RECORD LIKE rept109.*

INITIALIZE r_r109.* TO NULL
SELECT * INTO r_r109.*
	FROM rept109
	WHERE r109_compania    = codcia
	  AND r109_localidad   = codloc
	  AND r109_cod_zona    = zona
	  AND r109_cod_subzona = subzona
RETURN r_r109.*

END FUNCTION



FUNCTION fl_lee_transporte(codcia, codloc, trans)
DEFINE codcia		LIKE rept110.r110_compania
DEFINE codloc		LIKE rept110.r110_localidad
DEFINE trans		LIKE rept110.r110_cod_trans
DEFINE r_r110		RECORD LIKE rept110.*

INITIALIZE r_r110.* TO NULL
SELECT * INTO r_r110.*
	FROM rept110
	WHERE r110_compania  = codcia
	  AND r110_localidad = codloc
	  AND r110_cod_trans = trans
RETURN r_r110.*

END FUNCTION



FUNCTION fl_lee_chofer(codcia, codloc, trans, chofer)
DEFINE codcia		LIKE rept111.r111_compania
DEFINE codloc		LIKE rept111.r111_localidad
DEFINE trans		LIKE rept111.r111_cod_trans
DEFINE chofer		LIKE rept111.r111_cod_chofer
DEFINE r_r111		RECORD LIKE rept111.*

INITIALIZE r_r111.* TO NULL
SELECT * INTO r_r111.*
	FROM rept111
	WHERE r111_compania   = codcia
	  AND r111_localidad  = codloc
	  AND r111_cod_trans  = trans
	  AND r111_cod_chofer = chofer
RETURN r_r111.*

END FUNCTION



FUNCTION fl_lee_observacion(codcia, codloc, obser)
DEFINE codcia		LIKE rept112.r112_compania
DEFINE codloc		LIKE rept112.r112_localidad
DEFINE obser		LIKE rept112.r112_cod_obser
DEFINE r_r112		RECORD LIKE rept112.*

INITIALIZE r_r112.* TO NULL
SELECT * INTO r_r112.*
	FROM rept112
	WHERE r112_compania  = codcia
	  AND r112_localidad = codloc
	  AND r112_cod_obser  = obser
RETURN r_r112.*

END FUNCTION



FUNCTION fl_lee_hoja_de_ruta(codcia, codloc, num_hojrut)
DEFINE codcia		LIKE rept113.r113_compania
DEFINE codloc		LIKE rept113.r113_localidad
DEFINE num_hojrut	LIKE rept113.r113_num_hojrut
DEFINE r_r113		RECORD LIKE rept113.*

INITIALIZE r_r113.* TO NULL
SELECT * INTO r_r113.*
	FROM rept113
	WHERE r113_compania   = codcia
	  AND r113_localidad  = codloc
	  AND r113_num_hojrut = num_hojrut
RETURN r_r113.*

END FUNCTION



FUNCTION fl_lee_ayudante(codcia, codloc, trans, ayud)
DEFINE codcia		LIKE rept115.r115_compania
DEFINE codloc		LIKE rept115.r115_localidad
DEFINE trans		LIKE rept115.r115_cod_trans
DEFINE ayud		LIKE rept115.r115_cod_ayud
DEFINE r_r115		RECORD LIKE rept115.*

INITIALIZE r_r115.* TO NULL
SELECT * INTO r_r115.*
	FROM rept115
	WHERE r115_compania  = codcia
	  AND r115_localidad = codloc
	  AND r115_cod_trans = trans
	  AND r115_cod_ayud  = ayud
RETURN r_r115.*

END FUNCTION



FUNCTION fl_lee_cia_entrega(codcia, codloc, trans)
DEFINE codcia		LIKE rept116.r116_compania
DEFINE codloc		LIKE rept116.r116_localidad
DEFINE trans		LIKE rept116.r116_cia_trans
DEFINE r_r116		RECORD LIKE rept116.*

INITIALIZE r_r116.* TO NULL
SELECT * INTO r_r116.*
	FROM rept116
	WHERE r116_compania  = codcia
	  AND r116_localidad = codloc
	  AND r116_cia_trans = trans
RETURN r_r116.*

END FUNCTION



FUNCTION fl_lee_division_politica(pais, divi_poli)
DEFINE pais		LIKE gent025.g25_pais
DEFINE divi_poli	LIKE gent025.g25_divi_poli
DEFINE r_g25		RECORD LIKE gent025.*

INITIALIZE r_g25.* TO NULL
SELECT * INTO r_g25.*
	FROM gent025
	WHERE g25_pais      = pais
	  AND g25_divi_poli = divi_poli
RETURN r_g25.*

END FUNCTION



FUNCTION fl_retorna_fecha_proceso()

INITIALIZE vg_fecha TO NULL
SELECT fb_fechasist INTO vg_fecha FROM fobos WHERE fb_usar_fechasist = 'S' 
IF vg_fecha IS NULL THEN
	LET vg_fecha = TODAY
END IF

END FUNCTION



FUNCTION fl_current()
DEFINE fechatexto   VARCHAR(25)
DEFINE fechahora    VARCHAR(25)

LET fechatexto = CURRENT, ''
LET fechahora = YEAR(vg_fecha)  USING '&&&&', '-',
                MONTH(vg_fecha) USING '&&', '-',
                DAY(vg_fecha)   USING '&&', ' ',
                fechatexto[12,19]

RETURN fechahora

END FUNCTION
