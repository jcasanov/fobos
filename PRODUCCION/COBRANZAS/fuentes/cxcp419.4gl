--------------------------------------------------------------------------------
-- Titulo           : cxcp419.4gl - Listado de Cobranza realizada en un período
-- Elaboracion      : 08-Nov-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp419 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				tipcli		LIKE gent012.g12_subtipo,
				tit_tipcli	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre,
				con_saldo	CHAR(1),
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				zona_venta	LIKE gent032.g32_zona_venta,
				tit_zona_venta	LIKE gent032.g32_nombre,
				zona_cobro	LIKE cxct006.z06_zona_cobro,
				tit_zona_cobro	LIKE cxct006.z06_nombre,
				vendedor	LIKE rept019.r19_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_codigo,
				tit_cobrador	LIKE cxct005.z05_nombres,
				comision	CHAR(2)
			END RECORD
DEFINE vm_fecha_ini	DATE
DEFINE vm_fin_mes	DATE
DEFINE rm_z60		RECORD LIKE cxct060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp419.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp419'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf419_1"
DISPLAY FORM f_par
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda    = rg_gen.g00_moneda_base
LET rm_par.fecha_ini = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET vm_fin_mes       = rm_par.fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET rm_par.fecha_fin = vm_fin_mes
LET rm_par.con_saldo = 'N'
LET rm_par.comision  = 'S'
LET vm_fecha_ini     = rm_z60.z60_fecha_carga
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.tit_mon = r_g13.g13_nombre
WHILE TRUE
	CALL lee_parametros() 
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_imprimir()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g11		RECORD LIKE gent011.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g32		RECORD LIKE gent032.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z05		RECORD LIKE cxct005.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.moneda  = r_g13.g13_moneda
				LET rm_par.tit_mon = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(codcli) THEN
			IF rm_par.localidad IS NULL THEN
				CALL fl_ayuda_cliente_general()
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
							rm_par.localidad)
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
			END IF
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli, rm_par.nomcli
			END IF
		END IF
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING r_g03.g03_areaneg, r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_par.area_n   = r_g03.g03_areaneg
				LET rm_par.tit_area = r_g03.g03_nombre
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
		IF INFIELD(tipcli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre, r_g11.g11_nombre
			IF r_g12.g12_nombre IS NOT NULL THEN
				LET rm_par.tipcli     = r_g12.g12_subtipo
				LET rm_par.tit_tipcli = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
			END IF
		END IF
		IF INFIELD(tipcar) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre, r_g11.g11_nombre
			IF r_g12.g12_nombre IS NOT NULL THEN
				LET rm_par.tipcar     = r_g12.g12_subtipo
				LET rm_par.tit_tipcar = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad,
						rm_par.tit_localidad
			END IF
		END IF
		IF INFIELD(zona_venta) THEN
			CALL fl_ayuda_zona_venta(vg_codcia)
				RETURNING r_g32.g32_zona_venta, r_g32.g32_nombre
			IF r_g32.g32_zona_venta IS NOT NULL THEN
				LET rm_par.zona_venta     = r_g32.g32_zona_venta
				LET rm_par.tit_zona_venta = r_g32.g32_nombre
				DISPLAY BY NAME rm_par.zona_venta,
						rm_par.tit_zona_venta
			END IF
		END IF
		IF INFIELD(zona_cobro) THEN
			CALL fl_ayuda_zona_cobro()
				RETURNING r_z06.z06_zona_cobro, r_z06.z06_nombre
			IF r_z06.z06_zona_cobro IS NOT NULL THEN
				LET rm_par.zona_cobro     = r_z06.z06_zona_cobro
				LET rm_par.tit_zona_cobro = r_z06.z06_nombre
				DISPLAY BY NAME rm_par.zona_cobro,
						rm_par.tit_zona_cobro
			END IF
		END IF
		IF INFIELD(vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.vendedor  = r_r01.r01_codigo
				LET rm_par.tit_vendedor = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.vendedor,
						rm_par.tit_vendedor
			END IF
		END IF
		IF INFIELD(cobrador) THEN
			CALL fl_ayuda_cobradores(vg_codcia, 'T', 'T', 'T')
				RETURNING r_z05.z05_codigo, r_z05.z05_nombres
			IF r_z05.z05_codigo IS NOT NULL THEN
				LET rm_par.cobrador     = r_z05.z05_codigo
				LET rm_par.tit_cobrador = r_z05.z05_nombres
				DISPLAY BY NAME rm_par.cobrador,
						rm_par.tit_cobrador
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda.', 'exclamation')
				NEXT FIELD moneda
			END IF
		ELSE
			LET rm_par.moneda = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
		END IF
		LET rm_par.tit_mon = r_g13.g13_nombre 
		DISPLAY BY NAME rm_par.tit_mon
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la Fecha de Hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor a la Fecha de Inicio de las COBRANZAS en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
		IF rm_par.fecha_fin > vm_fin_mes THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la Fecha de Fin de Mes.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
			IF rm_par.localidad IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia,
							rm_par.localidad,
							r_z01.z01_codcli)
				RETURNING r_z02.*
			IF r_z02.z02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no está activado para esta Localidad.', 'exclamation')
				NEXT FIELD codcli
			END IF
		ELSE
			LET rm_par.nomcli = NULL
			DISPLAY BY NAME rm_par.nomcli
		END IF
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_g03.*
			IF r_g03.g03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe área de negocio.', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_g03.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD tipcli
		IF rm_par.tipcli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_g12.*
			IF r_g12.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cliente.', 'exclamation')
				NEXT FIELD tipcli
			END IF
			LET rm_par.tit_tipcli = r_g12.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		ELSE
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tit_tipcli
		END IF
	AFTER FIELD tipcar
		IF rm_par.tipcar IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_g12.*
			IF r_g12.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cartera.', 'exclamation')
				NEXT FIELD tipcar
			END IF
			LET rm_par.tit_tipcar = r_g12.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
		ELSE
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tit_tipcar
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY BY NAME rm_par.tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			DISPLAY BY NAME rm_par.tit_localidad
		END IF
	AFTER FIELD zona_venta
		IF rm_par.zona_venta IS NOT NULL THEN
			CALL fl_lee_zona_venta(vg_codcia, rm_par.zona_venta)
				RETURNING r_g32.*
			IF r_g32.g32_zona_venta IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Zona de venta no existe.','exclamation')
				NEXT FIELD zona_venta
			END IF
			LET rm_par.tit_zona_venta = r_g32.g32_nombre
			DISPLAY BY NAME rm_par.tit_zona_venta
		ELSE
			LET rm_par.tit_zona_venta = NULL
			DISPLAY BY NAME rm_par.tit_zona_venta
		END IF
	AFTER FIELD zona_cobro
		IF rm_par.zona_cobro IS NOT NULL THEN
			CALL fl_lee_zona_cobro(rm_par.zona_cobro)
				RETURNING r_z06.*
			IF r_z06.z06_zona_cobro IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Zona de cobro no existe.','exclamation')
				NEXT FIELD zona_cobro
			END IF
			LET rm_par.tit_zona_cobro = r_z06.z06_nombre
			DISPLAY BY NAME rm_par.tit_zona_cobro
		ELSE
			LET rm_par.tit_zona_cobro = NULL
			DISPLAY BY NAME rm_par.tit_zona_cobro
		END IF
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe vendedor.','exclamation')
				NEXT FIELD vendedor
			END IF
			LET rm_par.tit_vendedor = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.tit_vendedor
		ELSE
			LET rm_par.tit_vendedor = NULL
			CLEAR tit_vendedor
		END IF
	AFTER FIELD cobrador
		IF rm_par.cobrador IS NOT NULL THEN
			CALL fl_lee_cobrador_cxc(vg_codcia, rm_par.cobrador)
				RETURNING r_z05.*
			IF r_z05.z05_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cobrador.', 'exclamation')
				NEXT FIELD cobrador
			END IF
			LET rm_par.tit_cobrador = r_z05.z05_nombres
			DISPLAY BY NAME rm_par.tit_cobrador
		ELSE
			LET rm_par.tit_cobrador = NULL
			DISPLAY BY NAME rm_par.tit_cobrador
		END IF
	AFTER INPUT 
		IF rm_par.codcli IS NOT NULL THEN
			LET rm_par.tipcli     = NULL
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_aux		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				localidad	LIKE cxct022.z22_localidad,
				cod_vend	LIKE rept001.r01_codigo,
				vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_nombres,
				fec_emi		LIKE cxct020.z20_fecha_emi,
				val_doc		DECIMAL(12,2),
				val_mov		DECIMAL(12,2),
				val_pag		DECIMAL(12,2),
				sal_doc		DECIMAL(12,2)
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE cuantos		INTEGER
DEFINE query		CHAR(3000)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3		VARCHAR(100)

ERROR "Procesando documentos deudores . . . espere por favor." ATTRIBUTE(NORMAL)
CALL generar_tabla_fecha()
IF rm_par.area_n = 1 THEN
	CALL generar_facturas_inv()
	SELECT * FROM tmp_inv INTO TEMP tmp_vta
	DROP TABLE tmp_inv
END IF
IF rm_par.area_n = 2 THEN
	CALL generar_facturas_tal()
	SELECT * FROM tmp_tal INTO TEMP tmp_vta
	DROP TABLE tmp_tal
END IF
IF rm_par.area_n IS NULL THEN
	CALL generar_facturas_inv()
	CALL generar_facturas_tal()
	SELECT * FROM tmp_inv
		UNION
		SELECT * FROM tmp_tal
		INTO TEMP tmp_vta
	DROP TABLE tmp_inv
	DROP TABLE tmp_tal
END IF
DROP TABLE tmp_fec
SELECT COUNT(*) INTO cuantos FROM tmp_vta
IF cuantos = 0 THEN
	DROP TABLE tmp_vta
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET expr1 = NULL
IF rm_par.tipcar IS NOT NULL THEN
	LET expr1 = '   AND z20_cartera   = ', rm_par.tipcar
END IF
LET query = 'SELECT tmp_vta.*, z20_compania cia, z20_localidad loc, ',
			'z20_tipo_doc tp, z20_num_doc num, ',
			'NVL(SUM(z20_saldo_cap + z20_saldo_int), 0) saldo_doc ',
		' FROM tmp_vta, cxct020 ',
		' WHERE z20_compania  = ', vg_codcia,
		'   AND z20_localidad = local ',
		'   AND z20_codcli    = codcli ',
		'   AND z20_cod_tran  = cod_tran ',
		'   AND z20_num_tran  = num_tran ',
		'   AND z20_areaneg   = areaneg ',
		expr1 CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_vta
LET expr1 = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr1 = '   AND z23_codcli        = ', rm_par.codcli
END IF
LET expr2 = NULL
IF rm_par.cobrador IS NOT NULL THEN
	LET expr2 = '   AND z22_cobrador      = ', rm_par.cobrador
END IF
IF rm_par.comision <> 'T' THEN
	LET expr3 = '   AND z05_comision     = "', rm_par.comision, '"'
END IF
LET query = 'SELECT z22_localidad loc_m, z22_codcli cli_m, z23_tipo_doc tp_m, ',
			'z23_num_doc num_m, DATE(z22_fecing) fec_m, ',
			'z22_areaneg area_m, z22_tipo_trn tp_trn, ',
			'NVL(z05_nombres, "SIN COBRADOR") cobrador, ',
			'NVL(SUM(z23_valor_cap + z23_valor_int), 0) val_m, ',
			'MAX(z22_fecing) fecing ',
		' FROM cxct023, cxct022, OUTER cxct005 ',
		' WHERE z23_compania      = ', vg_codcia,
		'   AND z23_localidad     = ', vg_codloc,
		--'   AND z22_tipo_trn     <> "AJ" ',
			expr1 CLIPPED,
		'   AND z23_tipo_doc      = "FA" ',
		'   AND z22_compania      = z23_compania ',
		'   AND z22_localidad     = z23_localidad ',
		'   AND z22_codcli        = z22_codcli ',
		'   AND z22_tipo_trn      = z23_tipo_trn ',
		'   AND z22_num_trn       = z23_num_trn ',
			expr2 CLIPPED,
		'   AND DATE(z22_fecing) <= "', rm_par.fecha_fin, '"',
		'   AND z05_compania      = z22_compania ',
		'   AND z05_codigo        = z22_cobrador ',
			expr3 CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 ',
		' INTO TEMP t2 '
PREPARE exec_t2 FROM query
EXECUTE exec_t2
SELECT codcli, cliente, cod_tran, num_tran, local, cod_ven, vendedor, fecha,
	cobrador, valor_doc, saldo_doc, NVL(SUM(val_m), 0) valor_mov,
	(SELECT MAX(a.fecing)
		FROM t2 a
		WHERE a.loc_m = loc_m
		  AND a.cli_m = cli_m
		  AND a.tp_m  = tp_m
		  AND a.num_m = num_m) fecing
	FROM t1, OUTER t2
	WHERE loc_m                        = local
	  AND cli_m                        = codcli
	  AND tp_m                         = tp
	  AND num_m                        = num
	  --AND EXTEND(fec_m, YEAR TO MONTH) = EXTEND(fecha, YEAR TO MONTH)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13
	INTO TEMP t3
SELECT codcli cli, cliente nom, cod_tran tp, num_tran num, local loc,cod_ven cv,
	vendedor vend, fecha fec, cobrador cobr, valor_doc v_d, saldo_doc s_d,
	NVL(SUM(val_m), 0) valor_pag,
	(SELECT MAX(a.fecing)
		FROM t2 a
		WHERE a.loc_m = loc_m
		  AND a.cli_m = cli_m
		  AND a.tp_m  = tp_m
		  AND a.num_m = num_m) fecing2
	FROM t1, OUTER t2
	WHERE loc_m  = local
	  AND cli_m  = codcli
	  AND tp_m   = tp
	  AND num_m  = num
	  AND tp_trn IN ("PG", "AR")
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13
	INTO TEMP t4
DROP TABLE t1
DROP TABLE t2
SELECT codcli, cliente, cod_tran, num_tran, local, cod_ven, vendedor, cobrador,
	fecha, valor_doc, valor_mov, valor_pag,
	(valor_doc + valor_mov) saldo_doc, fecing2
	FROM t3, t4
	WHERE codcli   = cli
	  AND cod_tran = tp
	  AND num_tran = num
	  AND local    = loc
	  AND cod_ven  = cv
	  AND cobrador = cobr
	INTO TEMP tmp_fact
DROP TABLE t3
DROP TABLE t4
IF rm_par.con_saldo = 'S' THEN
	SELECT * FROM tmp_fact
		WHERE valor_doc + valor_mov = 0
		INTO TEMP t1
	DROP TABLE tmp_fact
	SELECT * FROM t1 INTO TEMP tmp_fact
	DROP TABLE t1
END IF
CALL control_generar_archivo()
DECLARE q_report CURSOR FOR
	SELECT * FROM tmp_fact
		ORDER BY 2, 3, 4, 5, 8, 9
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE tmp_fact
	RETURN
END IF
START REPORT report_list_cobranza TO PIPE comando
LET cuantos = 0
FOREACH q_report INTO r_aux.*
	OUTPUT TO REPORT report_list_cobranza(r_aux.*)
	LET cuantos = 1
END FOREACH
FINISH REPORT report_list_cobranza
DROP TABLE tmp_fact
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



REPORT report_list_cobranza(r_rep)
DEFINE r_rep		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				localidad	LIKE cxct022.z22_localidad,
				cod_vend	LIKE rept001.r01_codigo,
				vendedor	LIKE rept001.r01_nombres,
				cobrador	LIKE cxct005.z05_nombres,
				fec_emi		LIKE cxct020.z20_fecha_emi,
				val_doc		DECIMAL(12,2),
				val_mov		DECIMAL(12,2),
				val_pag		DECIMAL(12,2),
				sal_doc		DECIMAL(12,2)
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE query		CHAR(1200)
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE entro		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 150, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 063, "<< LISTADO DE FACTURA COMISION >>",
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA            : ", rm_par.moneda,
		" ", rm_par.tit_mon,
	      COLUMN 095, "COBRANZA REALIZADA DEL ",
		rm_par.fecha_ini USING 'dd-mm-yyyy', " AL ",
		rm_par.fecha_fin USING 'dd-mm-yyyy'
	IF rm_par.codcli IS NOT NULL THEN
		PRINT COLUMN 015, "** CLIENTE           : ",
			rm_par.codcli USING '<<<<&&', " ",
			rm_par.nomcli CLIPPED
	END IF
	IF rm_par.area_n IS NOT NULL THEN
		PRINT COLUMN 015, "** AREA DE NEGOCIO   : ",
			 rm_par.area_n USING '<&&', " ", rm_par.tit_area;
		IF rm_par.zona_venta IS NOT NULL THEN
			PRINT COLUMN 095, "ZONA DE VENTA  : ",
				rm_par.zona_venta USING '<<<&&', " ",
				rm_par.tit_zona_venta
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.tipcli IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CLIENTE      : ",
			rm_par.tipcli USING '<<&&', " ", rm_par.tit_tipcli;
		IF rm_par.zona_cobro IS NOT NULL THEN
			PRINT COLUMN 095, "ZONA DE COBRO  : ",
				rm_par.zona_cobro USING '<<<&&', " ",
				rm_par.tit_zona_cobro
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.tipcar IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CARTERA      : ",
			rm_par.tipcar USING '<<&&', " ", rm_par.tit_tipcar;
		IF rm_par.vendedor IS NOT NULL THEN
			PRINT COLUMN 095, "VENDEDOR       : ",
				rm_par.vendedor USING '<<<&&', " ",
				rm_par.tit_vendedor
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 015, "** LOCALIDAD         : ",
			rm_par.localidad USING '&&', " ", rm_par.tit_localidad;
		IF rm_par.cobrador IS NOT NULL THEN
			PRINT COLUMN 095, "COBRADOR       : ",
				rm_par.cobrador USING '<<<&&', " ",
				rm_par.tit_cobrador
		ELSE
			PRINT ' '
		END IF
	END IF
	IF rm_par.area_n IS NULL THEN
		IF rm_par.zona_venta IS NOT NULL THEN
			PRINT COLUMN 015, "** ZONA DE VENTA     : ",
				rm_par.zona_venta USING '<<<&&', " ",
				rm_par.tit_zona_venta
		END IF
	END IF
	IF rm_par.tipcli IS NULL THEN
		IF rm_par.zona_cobro IS NOT NULL THEN
			PRINT COLUMN 015, "** ZONA DE COBRO     : ",
				rm_par.zona_cobro USING '<<<&&', " ",
				rm_par.tit_zona_cobro
		END IF
	END IF
	IF rm_par.tipcar IS NULL THEN
		IF rm_par.vendedor IS NOT NULL THEN
			PRINT COLUMN 015, "** VENDEDOR          : ",
				rm_par.vendedor USING '<<<&&', " ",
				rm_par.tit_vendedor
		END IF
	END IF
	IF rm_par.localidad IS NULL THEN
		IF rm_par.cobrador IS NOT NULL THEN
			PRINT COLUMN 015, "** COBRADOR          : ",
				rm_par.cobrador USING '<<<&&', " ",
				rm_par.tit_cobrador
		END IF
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 142, usuario
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 025, "C L I E N T E S",
	      COLUMN 057, "DOCUMENTOS",
	      COLUMN 068, "LC",
	      COLUMN 071, "VENDEDOR",
	      COLUMN 087, "COBRADOR",
	      COLUMN 103, "FECHA EMI.",
	      COLUMN 114, " VALOR DOC.",
	      COLUMN 126, " VALOR MOV.",
	      COLUMN 138, "   VALOR PG",
	      COLUMN 150, " SALDO DOC."
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.codcli		USING "####&&",
	      COLUMN 008, r_rep.nomcli[1, 48]	CLIPPED,
	      COLUMN 057, r_rep.cod_tran, '-',
	      COLUMN 060, r_rep.num_tran	USING "<<<<<<#",
	      COLUMN 068, r_rep.localidad	USING "&&",
	      COLUMN 071, r_rep.vendedor[1, 15]	CLIPPED,
	      COLUMN 087, r_rep.cobrador[1, 15]	CLIPPED,
	      COLUMN 103, r_rep.fec_emi		USING "dd-mm-yyyy",
	      COLUMN 114, r_rep.val_doc		USING "----,--&.##",
	      COLUMN 126, r_rep.val_mov		USING "----,--&.##",
	      COLUMN 138, r_rep.val_pag		USING "----,--&.##",
	      COLUMN 150, r_rep.sal_doc		USING "----,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 114, "-----------",
	      COLUMN 126, "-----------",
	      COLUMN 138, "-----------",
	      COLUMN 150, "-----------"
	PRINT COLUMN 101, "TOTALES ==>  ",
	      COLUMN 114, SUM(r_rep.val_doc)	USING "----,--&.##",
	      COLUMN 126, SUM(r_rep.val_mov)	USING "----,--&.##",
	      COLUMN 138, SUM(r_rep.val_pag)	USING "----,--&.##",
	      COLUMN 150, SUM(r_rep.sal_doc)	USING "----,--&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION generar_tabla_fecha()

SELECT z22_compania cia_fec, z22_localidad loc_fec, z22_codcli cli_fec,
	DATE(z22_fecing) fec_pag, z23_tipo_doc tp_fec, z23_num_doc num_fec,
	z23_div_doc div_fec, z23_tipo_favor tp_fav, z23_doc_favor num_fav
	FROM cxct022, cxct023
	WHERE z22_compania     = vg_codcia
	  AND DATE(z22_fecing) BETWEEN rm_par.fecha_ini AND rm_par.fecha_fin
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
	INTO TEMP t1
SELECT UNIQUE cia_fec, loc_fec, z20_cod_tran cod_t, z20_num_tran num_t,
	z20_areaneg areaneg_fec, fec_pag
	FROM t1, cxct020
	WHERE tp_fec        = "FA"
	  AND z20_compania  = cia_fec
	  AND z20_localidad = loc_fec
	  AND z20_codcli    = cli_fec
	  AND z20_tipo_doc  = tp_fec
	  AND z20_num_doc   = num_fec
	  AND z20_dividendo = div_fec
	UNION
	SELECT UNIQUE cia_fec, loc_fec, z21_cod_tran cod_t, z21_num_tran num_t,
		z21_areaneg areaneg_fec, fec_pag
		FROM t1, cxct021
		WHERE tp_fav        = "NC"
		  AND z21_compania  = cia_fec
		  AND z21_localidad = loc_fec
		  AND z21_codcli    = cli_fec
		  AND z21_tipo_doc  = tp_fav
		  AND z21_num_doc   = num_fav
		  AND z21_cod_tran  IS NOT NULL
	INTO TEMP tmp_fec
DROP TABLE t1

END FUNCTION



FUNCTION generar_facturas_inv()
DEFINE query		CHAR(5000)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3		VARCHAR(100)
DEFINE expr4		VARCHAR(250)
DEFINE tabl1		VARCHAR(30)

IF rm_par.codcli IS NOT NULL THEN
	LET expr1 = '   AND r19_codcli       = ', rm_par.codcli
END IF
IF rm_par.vendedor IS NOT NULL THEN
	LET expr2 = '   AND r19_vendedor     = ', rm_par.vendedor
END IF
IF rm_par.tipcli IS NOT NULL THEN
	LET expr3 = '   AND z01_tipo_clte    = ', rm_par.tipcli
END IF
IF rm_par.zona_venta IS NOT NULL THEN
	LET tabl1 = ', cxct002 '
	LET expr4 = '   AND z02_compania     = r19_compania ',
			'   AND z02_codcli       = z01_codcli ',
			'   AND z02_zona_venta   = ', rm_par.zona_venta
END IF
IF rm_par.zona_cobro IS NOT NULL THEN
	IF rm_par.zona_venta IS NULL THEN
		LET tabl1 = ', cxct002 '
		LET expr4 = '   AND z02_compania     = r19_compania ',
				'   AND z02_codcli       = z01_codcli ',
				'   AND z02_zona_cobro   = ', rm_par.zona_cobro
	ELSE
		LET expr4 = expr4 CLIPPED,
				'   AND z02_zona_cobro   = ', rm_par.zona_cobro
	END IF
END IF
LET query = 'SELECT r19_codcli AS codcli, r19_nomcli AS cliente, ',
			'r19_cod_tran AS cod_tran, r19_num_tran AS num_tran, ',
			'r19_localidad AS local, r19_vendedor AS cod_ven, ',
			'r01_nombres AS vendedor, DATE(r19_fecing) AS fecha, ',
			'(r19_tot_neto - r19_tot_bruto + r19_tot_dscto - ',
			'r19_flete) val_impto, ',
			'CASE WHEN r19_cod_tran = "FA" THEN ',
				'NVL(SUM((r20_cant_ven * r20_precio) - ',
						'r20_val_descto), 0) ',
			'ELSE ',
				'NVL(SUM((r20_cant_ven * r20_precio) - ',
						'r20_val_descto), 0) * (-1) ',
			'END valor_doc, 1 areaneg ',
		' FROM rept019, rept020, rept001, cxct001 ', tabl1 CLIPPED,
		' WHERE r19_compania     = ', vg_codcia,
		'   AND r19_cod_tran     IN ("FA", "DF", "AF") ',
		'   AND r19_moneda       = "', rm_par.moneda, '" ',
			expr1 CLIPPED,
			expr2 CLIPPED,
		'   AND r19_cont_cred    = "R" ',
		'   AND EXISTS ',
			'(SELECT 1 FROM tmp_fec ',
				'WHERE cia_fec     = r19_compania ',
				'  AND loc_fec     = r19_localidad ',
				'  AND cod_t       = r19_cod_tran ',
				'  AND num_t       = r19_num_tran ',
				'  AND areaneg_fec = 1) ',
		'   AND r20_compania     = r19_compania ',
		'   AND r20_localidad    = r19_localidad ',
		'   AND r20_cod_tran     = r19_cod_tran ',
		'   AND r20_num_tran     = r19_num_tran ',
		'   AND r01_compania     = r19_compania ',
		'   AND r01_codigo       = r19_vendedor ',
		'   AND z01_codcli       = r19_codcli ',
			expr3 CLIPPED,
			expr4 CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 '
IF rm_par.localidad IS NOT NULL THEN
	IF tabl1 IS NOT NULL THEN
		LET tabl1 = ', ', retorna_base_loc() CLIPPED, 'cxct002 '
	END IF
	LET query = query CLIPPED,
			' UNION ',
			' SELECT r19_codcli AS codcli, r19_nomcli AS cliente, ',
			'r19_cod_tran AS cod_tran, r19_num_tran AS num_tran, ',
			'r19_localidad AS local, r19_vendedor AS cod_ven, ',
			'r01_nombres AS vendedor, DATE(r19_fecing) AS fecha, ',
			'(r19_tot_neto - r19_tot_bruto + r19_tot_dscto - ',
			'r19_flete) val_impto, ',
			'CASE WHEN r19_cod_tran = "FA" THEN ',
				'NVL(SUM((r20_cant_ven * r20_precio) - ',
						'r20_val_descto), 0) ',
			'ELSE ',
				'NVL(SUM((r20_cant_ven * r20_precio) - ',
						'r20_val_descto), 0) * (-1) ',
			'END valor_doc, 1 areaneg ',
			' FROM ', retorna_base_loc() CLIPPED, 'rept019, ',
				retorna_base_loc() CLIPPED, 'rept020, ',
				retorna_base_loc() CLIPPED, 'rept001, ',
				retorna_base_loc() CLIPPED, 'cxct001 ',
				tabl1 CLIPPED,
			' WHERE r19_compania     = ', vg_codcia,
			'   AND r19_cod_tran     IN ("FA", "DF", "AF") ',
			'   AND r19_moneda       = "', rm_par.moneda, '" ',
				expr1 CLIPPED,
				expr2 CLIPPED,
			'   AND r19_cont_cred    = "R" ',
			'   AND EXISTS ',
				'(SELECT 1 FROM tmp_fec ',
					'WHERE cia_fec     = r19_compania ',
					'  AND loc_fec     = r19_localidad ',
					'  AND cod_t       = r19_cod_tran ',
					'  AND num_t       = r19_num_tran ',
					'  AND areaneg_fec = 1) ',
			'   AND r20_compania     = r19_compania ',
			'   AND r20_localidad    = r19_localidad ',
			'   AND r20_cod_tran     = r19_cod_tran ',
			'   AND r20_num_tran     = r19_num_tran ',
			'   AND r01_compania     = r19_compania ',
			'   AND r01_codigo       = r19_vendedor ',
			'   AND z01_codcli       = r19_codcli ',
				expr3 CLIPPED,
				expr4 CLIPPED,
			' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 '
END IF
LET query = query CLIPPED, ' INTO TEMP t1 '
PREPARE exec_inv FROM query
EXECUTE exec_inv
SELECT codcli, cliente, cod_tran, num_tran, local, cod_ven, vendedor, fecha,
	(val_impto + valor_doc) valor_doc, areaneg
	FROM t1
	INTO TEMP tmp_inv
DROP TABLE t1

END FUNCTION



FUNCTION generar_facturas_tal()
DEFINE query		CHAR(1000)
DEFINE expr1		VARCHAR(100)
DEFINE expr2		VARCHAR(250)
DEFINE tabl1		VARCHAR(30)

SELECT DATE(t23_fec_factura) fecha_tran, t23_num_factura num_tran,
	t23_orden ord_t, t23_tot_bruto valor_mo, t23_tot_bruto valor_fa,
	t23_tot_bruto valor_oc, t23_tot_bruto valor_tot, t23_estado est,
	t23_cod_cliente codcli, t23_nom_cliente nomcli,
	t23_cod_cliente cod_ven, t23_nom_cliente vendedor,
	t23_val_impto val_impto
	FROM talt023
	WHERE t23_compania = 17
	INTO TEMP tmp_det
CALL preparar_tabla_de_trabajo('F', 1)
CALL preparar_tabla_de_trabajo('D', 1)
CALL preparar_tabla_de_trabajo('N', 1)
CALL preparar_tabla_de_trabajo('D', 2)
IF rm_par.tipcli IS NOT NULL THEN
	LET expr1 = '   AND z01_tipo_clte    = ', rm_par.tipcli
END IF
IF rm_par.zona_venta IS NOT NULL THEN
	LET tabl1 = ', cxct002 '
	LET expr2 = '   AND z02_compania     = ', vg_codcia,
			'   AND z02_codcli       = z01_codcli ',
			'   AND z02_zona_venta   = ', rm_par.zona_venta
END IF
IF rm_par.zona_cobro IS NOT NULL THEN
	IF rm_par.zona_venta IS NULL THEN
		LET tabl1 = ', cxct002 '
		LET expr2 = '   AND z02_compania     = ', vg_codcia,
				'   AND z02_codcli       = z01_codcli ',
				'   AND z02_zona_cobro   = ', rm_par.zona_cobro
	ELSE
		LET expr2 = expr2 CLIPPED,
				'   AND z02_zona_cobro   = ', rm_par.zona_cobro
	END IF
END IF
LET query = 'SELECT codcli, nomcli AS cliente, ',
			'CASE WHEN est = "F" THEN "FA" ',
			'     WHEN est = "D" THEN "DF" ',
			'     WHEN est = "N" THEN "AF" ',
			'END AS cod_tran, num_tran, ',
			vg_codloc, ' AS local, cod_ven, vendedor, ',
			'fecha_tran AS fecha, (valor_mo + valor_oc + ',
			'val_impto) valor_doc, 2 areaneg ',
		' FROM tmp_det, cxct001 ', tabl1 CLIPPED,
		' WHERE z01_codcli = codcli ', 
			expr1 CLIPPED,
			expr2 CLIPPED,
		' INTO TEMP tmp_tal '
PREPARE exec_tal FROM query
EXECUTE exec_tal
DROP TABLE tmp_det

END FUNCTION



FUNCTION preparar_tabla_de_trabajo(flag, tr_ant)
DEFINE flag		CHAR(1)
DEFINE tr_ant		SMALLINT
DEFINE factor		CHAR(8)
DEFINE expr_out		CHAR(5)
DEFINE expr_fec1	CHAR(400)
DEFINE expr_fec2	CHAR(400)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_ven		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_fec_inv	VARCHAR(200)
DEFINE expr_dev_inv	VARCHAR(200)
DEFINE query		CHAR(7000)

IF flag = 'F' OR tr_ant = 2 THEN
	--LET expr_fec1 = "   AND DATE(t23_fec_factura) BETWEEN '",
	--		rm_par.fecha_ini, "' AND '", rm_par.fecha_fin, "'"
	LET expr_fec1 =	'   AND EXISTS ',
				'(SELECT 1 FROM tmp_fec ',
					'WHERE cia_fec     = t23_compania ',
					'  AND loc_fec     = t23_localidad ',
					'  AND cod_t       = "FA" ',
					'  AND num_t       = t23_num_factura ',
					'  AND areaneg_fec = 2) '
	LET expr_fec2 = NULL
	LET expr_out  = 'OUTER'
END IF
IF (flag = 'D' OR flag = 'N') AND tr_ant = 1 THEN
	LET expr_out  = NULL
	LET expr_fec1 = NULL
	--LET expr_fec2 = "   AND DATE(t28_fec_anula) BETWEEN '",
	--			rm_par.fecha_ini, "' AND '",
	--			rm_par.fecha_fin, "'"
	LET expr_fec2 =	'   AND EXISTS ',
				'(SELECT 1 FROM tmp_fec ',
					'WHERE cia_fec     = t28_compania ',
					'  AND loc_fec     = t28_localidad ',
					'  AND cod_t       = "FA" ',
					'  AND num_t       = t28_factura ',
					'  AND areaneg_fec = 2) '
END IF
LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = "   AND t23_cod_cliente = ", rm_par.codcli
END IF
CASE tr_ant
	WHEN 1
		LET factor = ' * (-1) '
	WHEN 2
		LET factor = NULL
END CASE
LET expr_est     = "   AND t23_estado    = '", flag, "'"
LET expr_fec_inv = NULL
LET expr_dev_inv = NULL
LET expr_ven     = NULL
IF rm_par.vendedor IS NOT NULL THEN
	LET expr_ven = '   AND t61_cod_vendedor = ', rm_par.vendedor
END IF
LET query = "INSERT INTO tmp_det ",
		"SELECT CASE WHEN t23_estado = 'D' AND ", tr_ant, " = 1 ",
			" THEN (SELECT DATE(t28_fec_anula) ",
				"FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE DATE(t23_fec_factura) ",
			" END, ",
			" CASE WHEN t23_estado = 'D' AND ", tr_ant, " = 1 ",
			" THEN (SELECT t28_num_dev FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE t23_num_factura ",
			" END, ",
			" CASE WHEN t23_estado = 'D' ",
			" THEN (SELECT t28_ot_ant FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE t23_orden ",
			" END, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN (t23_val_mo_tal - t23_vde_mo_tal) ",
			" ELSE (t23_val_mo_tal - t23_vde_mo_tal) ",
							factor CLIPPED,
		" END, ",
		" CASE WHEN t23_estado = 'F' THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ", factor CLIPPED,
		" END tot_oc, ",
		" CASE WHEN t23_estado = 'F' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ",
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran     = 'FA' ",
			"   AND r19_cont_cred    = 'R' ",
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_fec_inv CLIPPED, ") ",
		"      WHEN t23_estado = 'D' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ", factor CLIPPED,
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran    IN ('DF', 'AF') ",
			"   AND r19_cont_cred    = 'R' ",
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_dev_inv CLIPPED, ") ",
		"      ELSE 0 ",
		" END, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN (t23_val_mo_tal - t23_vde_mo_tal) ",
			" ELSE (t23_val_mo_tal - t23_vde_mo_tal) ",
							factor CLIPPED,
		" END + ",
		" CASE WHEN t23_estado = 'F' THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2)),0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ", factor CLIPPED,
		" END + ",
		" CASE WHEN t23_estado = 'F' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ",
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran     = 'FA' ",
			"   AND r19_cont_cred    = 'R' ",
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_fec_inv CLIPPED, ") ",
		"      WHEN t23_estado = 'D' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ", factor CLIPPED,
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran    IN ('DF', 'AF') ",
			"   AND r19_cont_cred    = 'R' ",
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_dev_inv CLIPPED, ") ",
		"      ELSE 0 ",
		" END, ",
		" CASE WHEN ", tr_ant, " = 1 THEN t23_estado ELSE 'F' END, ",
		" t23_cod_cliente, t23_nom_cliente, t61_cod_vendedor, ",
		" r01_nombres, t23_val_impto ",
		" FROM talt023, talt061, rept001, ", expr_out, " talt028 ",
		" WHERE t23_compania   = ", vg_codcia,
		"   AND t23_localidad  = ", vg_codloc,
		expr_cli CLIPPED,
		expr_est CLIPPED,
		"   AND t23_cont_cred  = 'R' ",
		expr_fec1 CLIPPED,
		"   AND t23_compania   = t61_compania ",
		"   AND t23_cod_asesor = t61_cod_asesor ",
		"   AND r01_compania   = t61_compania ",
		"   AND r01_codigo     = t61_cod_vendedor ",
		"   AND t28_compania   = t23_compania ",
		"   AND t28_localidad  = t23_localidad ",
		"   AND t28_factura    = t23_num_factura ",
		expr_fec2 CLIPPED,
		" GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 "
PREPARE cons_tmp FROM query
EXECUTE cons_tmp
IF tr_ant = 2 THEN
	LET query = 'DELETE FROM tmp_det ',
			--' WHERE fecha_tran < "', rm_par.fecha_ini, '"',
			--'    OR fecha_tran > "', rm_par.fecha_fin, '"'
			' WHERE NOT EXISTS ',
				'(SELECT 1 FROM tmp_fec ',
					'WHERE est         = "D" ',
					'  AND num_t       = num_tran ',
					'  AND areaneg_fec = 2) '
	PREPARE cons_del FROM query
	EXECUTE cons_del
	RETURN
END IF
LET query = 'SELECT num_tran num_anu, z21_tipo_doc ',
		' FROM tmp_det, talt028, OUTER cxct021 ',
		' WHERE est           = "D" ',
		'   AND t28_compania  = ', vg_codcia,
		'   AND t28_localidad = ', vg_codloc,
		'   AND t28_num_dev   = num_tran ',
		'   AND z21_compania  = t28_compania ',
		'   AND z21_localidad = t28_localidad ',
		'   AND z21_tipo_doc  = "NC" ',
		'   AND z21_areaneg   = 2 ',
		'   AND z21_cod_tran  = "FA" ',
		'   AND z21_num_tran  = t28_factura ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query 
EXECUTE cons_t2
CASE flag
	WHEN 'N' SELECT * FROM t2 WHERE z21_tipo_doc IS NULL INTO TEMP t3
		 DELETE FROM t2 WHERE z21_tipo_doc IS NULL
	WHEN 'D' DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
END CASE
DROP TABLE t2
IF flag = 'N' THEN
	UPDATE tmp_det SET est = flag WHERE est = "D"
		  AND num_tran = (SELECT num_anu FROM t3
					WHERE num_anu = num_tran)
	DROP TABLE t3
END IF

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)
DEFINE codloc		LIKE gent002.g02_localidad

LET base_loc = NULL
IF vg_codloc = 6 OR vg_codloc = 7 THEN
	RETURN base_loc CLIPPED
END IF
IF rm_par.localidad IS NULL THEN
	RETURN base_loc CLIPPED
END IF
LET codloc = rm_par.localidad
CASE rm_par.localidad
	WHEN 1 LET codloc = 2
	WHEN 3 LET codloc = 4
END CASE
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION



FUNCTION control_generar_archivo()
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar este listado en archivo ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
UNLOAD TO "../../../tmp/cxcp419.unl"
	SELECT * FROM tmp_fact
		ORDER BY 2, 3, 4, 5, 8, 9
RUN "mv ../../../tmp/cxcp419.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"), '/tmp/cxcp419.unl',
		' OK.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION
