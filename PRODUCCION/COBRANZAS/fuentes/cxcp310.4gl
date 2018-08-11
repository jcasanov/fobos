--------------------------------------------------------------------------------
-- Titulo           : cxcp310.4gl - Cons. Análisis Cartera Clientes (por fecha)
-- Elaboracion      : 21-Jul-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp310 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE num_doc		INTEGER
DEFINE num_fav		INTEGER
DEFINE num_cli		INTEGER
DEFINE num_max_cli	INTEGER
DEFINE rm_par 		RECORD
				area_n          LIKE gent003.g03_areaneg,
				tit_area        LIKE gent003.g03_nombre,
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				tipcli		LIKE gent012.g12_subtipo,
				localidad	LIKE gent002.g02_localidad,
				zona_cobro	LIKE cxct006.z06_zona_cobro,
				tit_zona_cobro	LIKE cxct006.z06_nombre,
				vendedor	LIKE rept019.r19_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				tit_tipcli	LIKE gent012.g12_nombre,
				ind_venc        CHAR(1),
				fecha_cart	DATE,
				ind_doc		CHAR(1)
			END RECORD
DEFINE rm_par2 		RECORD
				fec_emi_ini	DATE,
				fec_emi_fin	DATE,
				fec_vcto_ini	DATE,
				fec_vcto_fin	DATE,
				incluir_tj	CHAR(1),
				val_cobrar	DECIMAL(12,2)
			END RECORD
DEFINE rm_cli		ARRAY[32766] OF RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				locali		LIKE gent002.g02_localidad,
				tot_pven 	DECIMAL(12,2),
				tot_venc 	DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE tot_1		DECIMAL(14,2)
DEFINE tot_2		DECIMAL(14,2)
DEFINE tot_3		DECIMAL(14,2)
DEFINE vm_fecha_ini	DATE
DEFINE vm_imprimir	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 13 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE tempo_doc 
	(locali		SMALLINT,
	 codcli		INTEGER,
	 nomcli		CHAR(100),
	 localidad	VARCHAR(20,10),
	 por_vencer	DECIMAL(12,2),
	 vencido	DECIMAL(12,2))
OPEN WINDOW w_cxcf310_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxcf310_1"
DISPLAY FORM f_par
LET num_max_cli = 32766
INITIALIZE rm_par.*, rm_par2.*, vm_fecha_ini TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon     = rm_mon.g13_nombre
LET rm_par.ind_venc    = 'T'
LET rm_par.fecha_cart  = vg_fecha
LET rm_par.ind_doc     = 'D'
LET vm_fecha_ini       = rm_z60.z60_fecha_carga
LET vm_imprimir        = 'R'
LET rm_par2.incluir_tj = 'S'
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
	LET rm_par.vendedor     = rm_vend.r01_codigo
	LET rm_par.tit_vendedor = rm_vend.r01_nombres
END IF
CALL mostrar_botones()
IF num_args() >= 5 THEN
	CALL llamada_de_otro_programa()
END IF
CALL control_consulta()
DROP TABLE tempo_doc
CLOSE WINDOW w_cxcf310_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE r_r01		RECORD LIKE rept001.*

LET rm_par.moneda      = arg_val(5)
LET rm_par.ind_venc    = arg_val(6)
LET rm_par.fecha_cart  = arg_val(7)
LET rm_par.area_n      = arg_val(8)
LET rm_par.tipcli      = arg_val(9)
LET rm_par.localidad   = arg_val(10)
LET rm_par.zona_cobro  = arg_val(11)
LET rm_par.vendedor    = arg_val(12)
LET rm_par.ind_doc     = arg_val(13)
IF rm_par.area_n = 0 THEN
	LET rm_par.area_n = NULL
END IF
IF rm_par.tipcli = 0 THEN
	LET rm_par.tipcli = NULL
END IF
IF rm_par.localidad = 0 THEN
	LET rm_par.localidad = NULL
END IF
IF rm_par.zona_cobro = 0 THEN
	LET rm_par.zona_cobro = NULL
END IF
IF rm_par.vendedor = 0 THEN
	LET rm_par.vendedor = NULL
END IF
IF rm_par.area_n IS NOT NULL THEN
	CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n) RETURNING r_g03.*
	IF r_g03.g03_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe area de negocio.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_area = r_g03.g03_nombre 
END IF
IF rm_par.tipcli IS NOT NULL THEN
	CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli) RETURNING r_g12.*
	IF r_g12.g12_tiporeg IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de cliente.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_tipcli = r_g12.g12_nombre 
END IF
IF rm_par.localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_par.localidad) RETURNING r_g02.*
	IF r_g02.g02_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe localidad.', 'stop')
		EXIT PROGRAM
	END IF
	DISPLAY r_g02.g02_nombre TO tit_localidad
END IF
IF rm_par.zona_cobro IS NOT NULL THEN
	CALL fl_lee_zona_cobro(rm_par.zona_cobro) RETURNING r_z06.*
	IF r_z06.z06_zona_cobro IS NULL THEN
		CALL fl_mostrar_mensaje('No existe zona de cobro.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_zona_cobro = r_z06.z06_nombre
END IF
IF rm_par.vendedor IS NOT NULL THEN
	CALL fl_lee_vendedor_rep(vg_codcia, rm_par.vendedor) RETURNING r_r01.*
	IF r_r01.r01_codigo IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de vendedor.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_vendedor = r_r01.r01_nombres
END IF
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

WHILE TRUE
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[6]  = 'DESC'
	LET vm_columna_1 = 6
	LET vm_columna_2 = 1
	IF num_args() = 4 THEN
		CALL lee_parametros() 
		IF int_flag THEN
			RETURN
		END IF
	END IF
	CALL genera_tabla_trabajo_detalle()
	IF num_doc = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE tmp_mov
		IF num_args() >= 5 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CALL genera_tabla_trabajo_resumen()
	IF num_cli = 0 THEN
		DROP TABLE tmp_mov
		IF num_args() >= 5 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CALL muestra_resumen_clientes()
	DELETE FROM tempo_doc
	DROP TABLE tmp_mov
	IF num_args() >= 5 THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tempo_doc

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_se		RECORD LIKE gent012.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE area_aux		LIKE gent003.g03_areaneg
DEFINE tit_area		LIKE gent003.g03_nombre
DEFINE tiporeg		LIKE gent012.g12_tiporeg
DEFINE subtipo		LIKE gent012.g12_subtipo
DEFINE nomtipo		LIKE gent012.g12_nombre
DEFINE nombre		LIKE gent011.g11_nombre
DEFINE fec		DATE
DEFINE num		SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(area_n) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING area_aux, tit_area
			IF area_aux IS NOT NULL THEN
				LET rm_par.area_n   = area_aux
				LET rm_par.tit_area = tit_area
 				DISPLAY BY NAME rm_par.area_n, rm_par.tit_area
			END IF
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, num
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_mon
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(tipcli) THEN
			CALL fl_ayuda_subtipo_entidad('CL') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcli     = subtipo
				LET rm_par.tit_tipcli = nomtipo
				DISPLAY BY NAME rm_par.tipcli, rm_par.tit_tipcli
			END IF
		END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad,
					  r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_par.localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		IF INFIELD(zona_cobro) THEN
			CALL fl_ayuda_zona_cobro('T', 'T')
				RETURNING r_z06.z06_zona_cobro, r_z06.z06_nombre
			IF r_z06.z06_zona_cobro IS NOT NULL THEN
				LET rm_par.zona_cobro     = r_z06.z06_zona_cobro
				LET rm_par.tit_zona_cobro = r_z06.z06_nombre
				DISPLAY BY NAME rm_par.zona_cobro,
						rm_par.tit_zona_cobro
			END IF
		END IF
		IF INFIELD(vendedor) AND (rm_g05.g05_tipo <> 'UF' OR 
			rm_vend.r01_tipo = 'J' OR
			rm_vend.r01_tipo = 'G') THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.vendedor  = r_r01.r01_codigo
				LET rm_par.tit_vendedor = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.vendedor,
						rm_par.tit_vendedor
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_cart
		LET fec = rm_par.fecha_cart
	AFTER FIELD area_n
		IF rm_par.area_n IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area_n)
				RETURNING r_an.*
			IF r_an.g03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe área de negocio', 'exclamation')
				NEXT FIELD area_n
			END IF
			LET rm_par.tit_area = r_an.g03_nombre
			DISPLAY BY NAME rm_par.tit_area
		ELSE
			LET rm_par.tit_area = NULL
			DISPLAY BY NAME rm_par.tit_area
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_mo.*
			IF r_mo.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mo.g13_nombre 
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD tipcli
		IF rm_par.tipcli IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CL', rm_par.tipcli)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cliente', 'exclamation')
				NEXT FIELD tipcli
			END IF
			LET rm_par.tit_tipcli = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcli
		ELSE
			LET rm_par.tit_tipcli = NULL
			DISPLAY BY NAME rm_par.tit_tipcli
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
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
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
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
			LET rm_par.vendedor     = rm_vend.r01_codigo 
			LET rm_par.tit_vendedor = rm_vend.r01_nombres 
			DISPLAY BY NAME rm_par.*
		END IF
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
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
IF rm_par.ind_venc IS NULL THEN
	LET rm_par.ind_venc = 'T'
	DISPLAY BY NAME rm_par.ind_venc
END IF
IF rm_par.vendedor IS NOT NULL THEN
	LET rm_par.ind_doc = 'D'
	DISPLAY BY NAME rm_par.ind_doc
END IF
IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
	RETURN
END IF
CALL fl_hacer_pregunta('Desea filtros adicionales ?', 'No') RETURNING resp
IF resp = 'Yes' THEN
	CALL lee_parametros2()
END IF
LET int_flag = 0

END FUNCTION



FUNCTION lee_parametros2()

OPEN WINDOW w_cxcf310_3 AT 06, 10 WITH FORM "../forms/cxcf310_3" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME rm_par2.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER FIELD fec_emi_ini
		IF rm_par2.fec_emi_ini IS NOT NULL THEN
			IF rm_par2.fec_emi_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de emisión inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD fec_emi_ini
			END IF
		END IF
	AFTER FIELD fec_emi_fin
		IF rm_par2.fec_emi_fin IS NOT NULL THEN
			IF rm_par2.fec_emi_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de emisión final no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD fec_emi_fin
			END IF
		END IF
	AFTER INPUT
		IF rm_par2.fec_emi_ini IS NOT NULL THEN
			IF rm_par2.fec_emi_fin IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de emisión final.', 'exclamation')
				NEXT FIELD fec_emi_fin
			END IF
		END IF
		IF rm_par2.fec_emi_fin IS NOT NULL THEN
			IF rm_par2.fec_emi_ini IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de emisión inicial.', 'exclamation')
				NEXT FIELD fec_emi_fin
			END IF
		END IF
		IF rm_par2.fec_emi_ini > rm_par2.fec_emi_fin THEN
			CALL fl_mostrar_mensaje('La fecha de emisión inicial no puede ser mayor a la fecha de emisión final.', 'exclamation')
			NEXT FIELD fec_emi_ini
		END IF
		IF rm_par2.fec_vcto_ini IS NOT NULL THEN
			IF rm_par2.fec_vcto_fin IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de vencimiento final.', 'exclamation')
				NEXT FIELD fec_vcto_fin
			END IF
		END IF
		IF rm_par2.fec_vcto_fin IS NOT NULL THEN
			IF rm_par2.fec_vcto_ini IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha de vencimiento inicial.', 'exclamation')
				NEXT FIELD fec_vcto_fin
			END IF
		END IF
		IF rm_par2.fec_vcto_ini IS NOT NULL AND
		   rm_par2.fec_vcto_fin IS NOT NULL
		THEN
			IF rm_par2.fec_vcto_ini > rm_par2.fec_vcto_fin THEN
				CALL fl_mostrar_mensaje('La fecha de vencimiento inicial no puede ser mayor a la fecha de vencimiento final.', 'exclamation')
				NEXT FIELD fec_vcto_ini
			END IF
		END IF
END INPUT
CLOSE WINDOW w_cxcf310_3
RETURN

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(4500)
DEFINE subquery1	CHAR(1500)
DEFINE subquery2	CHAR(500)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5, expr6	CHAR(400)
DEFINE expr7		CHAR(400)
DEFINE expr8, expr9	CHAR(100)
DEFINE expr10		CHAR(200)
DEFINE tabl1, tabl2	VARCHAR(10)
DEFINE tabl3		VARCHAR(20)
DEFINE expr_int		VARCHAR(20)

ERROR "Procesando documentos con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4, expr5, expr6, expr7, tabl1, tabl2, tabl3
	TO NULL
IF rm_par.area_n IS NOT NULL THEN
	LET expr1 = '   AND z20_areaneg    = ', rm_par.area_n
END IF
IF rm_par.moneda IS NOT NULL THEN
	LET expr2 = '   AND z20_moneda     = "', rm_par.moneda, '"'
END IF
IF rm_par.tipcli IS NOT NULL THEN
	LET expr3 = '   AND z01_tipo_clte  = ', rm_par.tipcli
END IF
IF rm_par.localidad IS NOT NULL THEN
	LET expr4 = '   AND z20_localidad  = ', rm_par.localidad
END IF
IF rm_par.zona_cobro IS NOT NULL THEN
	LET tabl1 = ', cxct002 '
	LET expr5 = '   AND z02_compania   = z20_compania ',
			'   AND z02_localidad  = z20_localidad ',
			'   AND z02_codcli     = z01_codcli ',
			'   AND z02_zona_cobro = ', rm_par.zona_cobro
END IF
LET expr_int = ' INTO TEMP tmp_z20 '
IF rm_par.vendedor IS NOT NULL THEN
	LET tabl2 = ', rept019 '
	LET expr6 = '   AND r19_compania     = z20_compania ',
			'   AND r19_localidad    = z20_localidad ',
			'   AND r19_cod_tran     = z20_cod_tran ',
			'   AND r19_num_tran     = z20_num_tran ',
			'   AND r19_vendedor     = ', rm_par.vendedor
	LET tabl3 = ', talt061, talt023 '
	LET expr7 = '   AND t61_compania     = z20_compania ',
			'   AND t61_cod_vendedor = ', rm_par.vendedor,
			'   AND t23_compania     = t61_compania ',
			'   AND t23_localidad    = z20_localidad ',
			'   AND t23_num_factura  = z20_num_tran ',
			'   AND t23_cod_asesor   = t61_cod_asesor '
	LET expr_int = ' INTO TEMP t1 '
END IF
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET query = 'SELECT cxct020.* ',
		' FROM cxct020 ',
		' WHERE z20_compania   = ', vg_codcia,
			expr4 CLIPPED,
			expr1 CLIPPED,
			expr2 CLIPPED,
		'   AND z20_fecha_emi <= "', rm_par.fecha_cart, '"',
		expr_int CLIPPED
PREPARE cons_t1 FROM query
EXECUTE cons_t1
IF rm_par.vendedor IS NOT NULL THEN
	LET query = 'SELECT t1.* FROM t1 ', tabl2 CLIPPED,
			' WHERE z20_areaneg     = 1 ',
			expr6 CLIPPED,
			' UNION ',
			'SELECT t1.* FROM t1 ', tabl3 CLIPPED,
			' WHERE z20_areaneg     = 2 ',
			expr7 CLIPPED,
			' INTO TEMP t2 '
	PREPARE cons_t2 FROM query
	EXECUTE cons_t2
	SELECT * FROM t2 INTO TEMP tmp_z20
	DROP TABLE t1
	DROP TABLE t2
END IF
LET expr8 = NULL
IF rm_par2.fec_emi_ini IS NOT NULL THEN
	LET expr8 = '   AND z20_fecha_emi  BETWEEN "', rm_par2.fec_emi_ini,
					'" AND "', rm_par2.fec_emi_fin, '"'
END IF
LET expr9 = NULL
IF rm_par2.fec_vcto_ini IS NOT NULL THEN
	LET expr9 = '   AND z20_fecha_vcto BETWEEN "', rm_par2.fec_vcto_ini,
					'" AND "', rm_par2.fec_vcto_fin, '"'
END IF
LET expr10 = NULL
IF rm_par2.incluir_tj = 'N' THEN
	LET expr10 = '   AND NOT EXISTS (SELECT g10_codcobr FROM gent010 ',
					' WHERE g10_codcobr = z01_codcli) '
END IF
LET subquery1 = '(SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
			'z23_saldo_int ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM cxct023, cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET query = ' SELECT g02_nombre, z20_localidad, z20_codcli, z20_tipo_doc, ',
			'z20_num_doc, z20_dividendo, z01_nomcli, ',
			'z20_fecha_emi, z20_fecha_vcto, ',
			'(z20_valor_cap + z20_valor_int) valor_doc, ',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) valor_mov, z20_areaneg area_n, ',
			'z20_cod_tran cod_tran, z20_num_tran num_tran ',
		' FROM tmp_z20, gent002, cxct001 ', tabl1 CLIPPED,
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli ',
			expr3 CLIPPED,
			expr5 CLIPPED,
			expr8 CLIPPED,
			expr9 CLIPPED,
			expr10 CLIPPED,
		' INTO TEMP tmp_mov '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_z20
DELETE FROM tmp_mov WHERE valor_mov = 0
SELECT COUNT(*) INTO num_doc FROM tmp_mov 
ERROR ' '
LET num_fav = 0
IF num_doc > 0 AND rm_par.ind_doc = 'T' THEN
	CALL obtener_documentos_a_favor()
END IF

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5, expr6	VARCHAR(100)

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4 TO NULL
IF rm_par.moneda IS NOT NULL THEN
	LET expr1 = '   AND z21_moneda     = "', rm_par.moneda, '"'
END IF
IF rm_par.area_n IS NOT NULL THEN
	LET expr2 = '   AND z21_areaneg    = ', rm_par.area_n
END IF
IF rm_par.tipcli IS NOT NULL THEN
	LET expr3 = '   AND z01_tipo_clte  = ', rm_par.tipcli
END IF
IF rm_par.localidad IS NOT NULL THEN
	LET expr4 = '   AND z21_localidad  = ', rm_par.localidad
END IF
LET query = 'SELECT cxct021.* ',
		' FROM cxct021 ',
		' WHERE z21_compania   = ', vg_codcia,
			expr4 CLIPPED,
			expr2 CLIPPED,
			expr1 CLIPPED,
		'   AND z21_fecha_emi <= "', rm_par.fecha_cart, '"',
		' INTO TEMP tmp_z21 '
PREPARE cons_z21 FROM query
EXECUTE cons_z21
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr5 = NULL
IF rm_par2.fec_emi_ini IS NOT NULL THEN
	LET expr5 = '   AND z21_fecha_emi  BETWEEN "', rm_par2.fec_emi_ini,
					'" AND "', rm_par2.fec_emi_fin, '"'
END IF
LET expr6 = NULL
IF rm_par2.incluir_tj = 'N' THEN
	LET expr6 = '   AND NOT EXISTS (SELECT g10_codcobr FROM gent010 ',
					' WHERE g10_codcobr = z01_codcli) '
END IF
LET subquery1 = '(SELECT SUM(z23_valor_cap + z23_valor_int) ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc ',
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn ',
		'   AND z22_num_trn    = z23_num_trn ',
		'   AND z22_fecing     BETWEEN EXTEND(z21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc) '
LET query = 'SELECT z21_localidad, z21_tipo_doc, z21_num_doc, z21_codcli, ',
		' z01_nomcli, z21_fecha_emi, ',
		' NVL(CASE WHEN z21_fecha_emi > "', vm_fecha_ini, '"',
			' THEN z21_valor + ', subquery1 CLIPPED,
			' ELSE ', subquery2 CLIPPED, ' + z21_saldo - ',
				  subquery1 CLIPPED,
		' END, ',
		' CASE WHEN z21_fecha_emi <= "', vm_fecha_ini, '"',
			' THEN z21_saldo - ', subquery2 CLIPPED,
			' ELSE z21_valor',
		' END) * (-1) saldo_mov ',
		' FROM tmp_z21, cxct001 ',
		' WHERE z01_codcli     = z21_codcli ',
			expr3 CLIPPED,
			expr5 CLIPPED,
			expr6 CLIPPED,
		' INTO TEMP tmp_fav '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_z21
DELETE FROM tmp_fav WHERE saldo_mov = 0
SELECT COUNT(*) INTO num_fav FROM tmp_fav
ERROR ' '
IF num_fav = 0 THEN
	DROP TABLE tmp_fav
	RETURN
END IF
SELECT z21_localidad, z21_codcli, z01_nomcli, NVL(SUM(saldo_mov), 0) saldo_fav
	FROM tmp_fav
	GROUP BY 1, 2, 3
	INTO TEMP tmp_sal_fav
DROP TABLE tmp_fav

END FUNCTION



FUNCTION genera_tabla_trabajo_resumen()
DEFINE query		CHAR(1200)
DEFINE subquery		CHAR(800)

ERROR "Generando resumen . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT z20_localidad loc1, z20_codcli cli1, valor_mov sald1 ',
		' FROM tmp_mov ',
		' WHERE z20_fecha_vcto >= "', rm_par.fecha_cart, '"',
		'   AND valor_mov       > 0 ',
		' INTO TEMP t1 '
PREPARE cons_t1_a FROM query
EXECUTE	cons_t1_a
LET query = 'SELECT z20_localidad loc2, z20_codcli cli2, valor_mov sald2 ',
		' FROM tmp_mov ',
		' WHERE z20_fecha_vcto < "', rm_par.fecha_cart, '"',
		'   AND valor_mov      > 0 ',
		' INTO TEMP t2 '
PREPARE cons_t2_a FROM query
EXECUTE	cons_t2_a
CASE rm_par.ind_venc
	WHEN 'P'
		LET subquery = '(SELECT NVL(SUM(sald1), 0) ',
				' FROM t1 ',
				' WHERE cli1 = z20_codcli ',
				'   AND loc1 = z20_localidad), 0 '
	WHEN 'V'
		LET subquery = '0, (SELECT NVL(SUM(sald2), 0) ',
				' FROM t2 ',
				' WHERE cli2 = z20_codcli ',
				'   AND loc2 = z20_localidad) '
	WHEN 'T'
		LET subquery = '(SELECT NVL(SUM(sald1), 0) ',
				' FROM t1 ',
				' WHERE cli1 = z20_codcli ',
				'   AND loc1 = z20_localidad), ',
				'(SELECT NVL(SUM(sald2), 0) ',
				' FROM t2 ',
				' WHERE cli2 = z20_codcli ',
				'   AND loc2 = z20_localidad) '
END CASE
LET query = 'INSERT INTO tempo_doc ',
		' SELECT z20_localidad, z20_codcli, z01_nomcli, g02_nombre, ',
			subquery CLIPPED,
			' FROM tmp_mov ',
			' GROUP BY 1, 2, 3, 4, 5, 6'
PREPARE cons_mov FROM query
EXECUTE cons_mov
DELETE FROM tempo_doc WHERE por_vencer = 0 AND vencido = 0
SELECT COUNT(*) INTO num_cli FROM tempo_doc
ERROR " "
IF num_cli = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF
DROP TABLE t1
DROP TABLE t2

END FUNCTION



FUNCTION muestra_resumen_clientes()
DEFINE orden		CHAR(40)
DEFINE query		CHAR(700)
DEFINE expr		VARCHAR(100)
DEFINE i, col		INTEGER

CALL mostrar_botones()
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	SELECT codcli, nomcli, locali,
		NVL(SUM(por_vencer + vencido), 0) saldo_deu,
		NVL(SUM(por_vencer + vencido), 0) saldo_fav
		FROM tempo_doc
		GROUP BY 1, 2, 3
		INTO TEMP tmp_sal_deu
	UPDATE tmp_sal_deu SET saldo_fav = 0
	INSERT INTO tmp_sal_deu
		SELECT z21_codcli, z01_nomcli, z21_localidad, 0.00,
			NVL(SUM(saldo_fav), 0) saldo_fav
			FROM tmp_sal_fav
			GROUP BY 1, 2, 3, 4
	SELECT codcli, nomcli, locali, NVL(SUM(saldo_deu), 0) saldo_deu,
		NVL(SUM(saldo_fav), 0) saldo_fav
		FROM tmp_sal_deu
		GROUP BY 1, 2, 3
		INTO TEMP tmp_cli_car
	DROP TABLE tmp_sal_deu
	DROP TABLE tmp_sal_fav
END IF
LET expr = NULL
IF rm_par2.val_cobrar IS NOT NULL THEN
	LET expr = ' HAVING SUM(por_vencer + vencido) >= ', rm_par2.val_cobrar
END IF
WHILE TRUE
	LET query = "SELECT codcli, nomcli, locali, SUM(por_vencer),",
			" SUM(vencido), SUM(por_vencer + vencido) ",
			" FROM tempo_doc ",
			" GROUP BY 1, 2, 3",
			expr CLIPPED
	IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
		LET expr = NULL
		IF rm_par2.val_cobrar IS NOT NULL THEN
			LET expr = ' WHERE saldo_deu + NVL(saldo_fav, 0) >= ',
					rm_par2.val_cobrar
		END IF
		LET query = "SELECT codcli, nomcli, locali, saldo_deu, ",
				"NVL(saldo_fav, 0), saldo_deu + ",
				"NVL(saldo_fav, 0) ",
			" FROM tmp_cli_car ",
			expr CLIPPED
	END IF
	LET query = query CLIPPED,
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons FROM query
	DECLARE q_cons CURSOR FOR cons
	LET i     = 1
	LET tot_1 = 0
	LET tot_2 = 0
	LET tot_3 = 0
	FOREACH q_cons INTO rm_cli[i].*
		LET tot_1 = tot_1 + rm_cli[i].tot_pven
		LET tot_2 = tot_2 + rm_cli[i].tot_venc
		LET tot_3 = tot_3 + rm_cli[i].tot_saldo
		LET i     = i + 1
		IF i > num_max_cli THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_cli = i - 1
	CALL set_count(num_cli)
	DISPLAY BY NAME tot_1, tot_2, tot_3
	LET int_flag = 0
	DISPLAY ARRAY rm_cli TO rm_cli.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_documentos(i)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_estado_cuenta(i)
			LET int_flag = 0
		ON KEY(F7)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F8)
			CALL control_generar_archivo()
			LET int_flag = 0
		ON KEY(F9)
			IF rm_par.fecha_cart = vg_fecha AND rm_par.ind_venc = 'V'
			THEN
				CALL generar_pdf()
				LET int_flag = 0
			END IF
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F8","Archivo")
			--#IF rm_par.fecha_cart = vg_fecha AND
				--#rm_par.ind_venc = 'V'
			--#THEN
				--#CALL dialog.keysetlabel("F9","PDF")
			--#ELSE
				--#CALL dialog.keysetlabel("F9","")
			--#END IF
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY i       TO num_row
			DISPLAY num_cli TO max_row
		AFTER DISPLAY 
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	DROP TABLE tmp_cli_car
END IF

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Código'	TO tit_col1
DISPLAY 'C l i e n t e'	TO tit_col2
DISPLAY 'LC'		TO tit_col3
DISPLAY 'Por Vencer'	TO tit_col4
DISPLAY 'Valor Vencido'	TO tit_col5
DISPLAY 'Val. a Cobrar'	TO tit_col6
CASE rm_par.ind_venc
	WHEN 'P'
		DISPLAY '' TO tit_col5
	WHEN 'V'
		DISPLAY '' TO tit_col4
END CASE
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	DISPLAY 'Total Deudor'	TO tit_col4
	CASE rm_par.ind_venc
		WHEN 'P'
			DISPLAY 'Por Vencer'	TO tit_col4
		WHEN 'V'
			DISPLAY 'Total Vencido'	TO tit_col4
	END CASE
	DISPLAY 'Total A Favor'	TO tit_col5
	DISPLAY 'Cartera Total'	TO tit_col6
END IF

END FUNCTION



FUNCTION muestra_documentos(i)
DEFINE i		INTEGER
DEFINE comando		VARCHAR(400)
DEFINE expr_ven		VARCHAR(20)
DEFINE area		LIKE gent003.g03_areaneg

LET area = 0
IF rm_par.area_n IS NOT NULL THEN
	LET area = rm_par.area_n
END IF
LET expr_ven = ' ', vm_fecha_ini, ' F '
IF rm_par.vendedor IS NOT NULL THEN
	LET expr_ven = ' ', rm_par.vendedor, ' "V"'
END IF
LET comando = 'fglrun cxcp315 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_par.moneda, ' ', rm_par.ind_venc, ' ',
		rm_par.ind_doc, ' "N" "N" ', rm_par.fecha_cart, ' ', area,
		' 0 0 ', rm_cli[i].locali, ' ', rm_cli[i].codcli,
		expr_ven CLIPPED
IF rm_par2.fec_emi_ini IS NOT NULL AND rm_par2.fec_vcto_ini IS NOT NULL THEN
	LET comando = comando CLIPPED, ' ', rm_par2.incluir_tj, ' ',
			rm_par2.fec_emi_ini, ' ', rm_par2.fec_emi_fin, ' ',
			rm_par2.fec_vcto_ini, ' ', rm_par2.fec_vcto_fin
END IF
IF rm_par2.fec_emi_ini IS NOT NULL AND rm_par2.fec_vcto_ini IS NULL THEN
	LET comando = comando CLIPPED, ' ', rm_par2.incluir_tj, ' ',
			rm_par2.fec_emi_ini, ' ', rm_par2.fec_emi_fin, ' 0 0 '
END IF
IF rm_par2.fec_emi_ini IS NULL AND rm_par2.fec_vcto_ini IS NOT NULL THEN
	LET comando = comando CLIPPED, ' ', rm_par2.incluir_tj, ' 0 0 ',
			rm_par2.fec_vcto_ini, ' ', rm_par2.fec_vcto_fin
END IF
RUN comando

END FUNCTION



FUNCTION muestra_estado_cuenta(i)
DEFINE i		INTEGER
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE comando          VARCHAR(100)

LET codloc = 0
IF rm_par.localidad IS NOT NULL THEN
	LET codloc = rm_par.localidad
END IF
LET comando = 'fglrun cxcp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', ' ', rm_par.moneda, ' ', rm_par.fecha_cart, ' ',
		rm_par.ind_venc, ' ', 0.01, ' "N" ', codloc, ' ',
		rm_cli[i].codcli
RUN comando

END FUNCTION



FUNCTION retorna_tipo()
DEFINE aux_i		CHAR(1)

IF rm_par.ind_doc = 'D' THEN
	CALL lee_datos_tipo() RETURNING aux_i
ELSE
	LET vm_imprimir = 'R'
	LET int_flag    = 0
END IF
RETURN aux_i

END FUNCTION



FUNCTION lee_datos_tipo()
DEFINE aux_i		CHAR(1)

OPEN WINDOW w_cxcf310_2 AT 06, 26 WITH FORM "../forms/cxcf310_2" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET aux_i    = vm_imprimir
LET int_flag = 0
INPUT BY NAME vm_imprimir
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET vm_imprimir = aux_i
		LET int_flag    = 1
		EXIT INPUT
END INPUT
CLOSE WINDOW w_cxcf310_2
RETURN aux_i

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		INTEGER
DEFINE aux_i		CHAR(1)

CALL retorna_tipo() RETURNING aux_i
IF int_flag THEN
	RETURN
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	LET vm_imprimir = aux_i
	RETURN
END IF
START REPORT report_list_cliente TO PIPE comando
FOR i = 1 TO num_cli
	OUTPUT TO REPORT report_list_cliente(i)
END FOR
FINISH REPORT report_list_cliente

END FUNCTION



REPORT report_list_cliente(i)
DEFINE i		INTEGER
DEFINE query		VARCHAR(600)
DEFINE expr_fec		VARCHAR(100)
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE tit_imprimir	VARCHAR(10)
DEFINE tot_val		DECIMAL(14,2)
DEFINE tot_sal		DECIMAL(14,2)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z20		RECORD LIKE cxct020.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CASE vm_imprimir
		WHEN 'R' LET tit_imprimir = 'RESUMIDO'
		WHEN 'D' LET tit_imprimir = 'DETALLADO'
	END CASE
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 027, "ANALISIS CARTERA DE CLIENTES",
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	IF rm_par.area_n IS NOT NULL THEN
		PRINT COLUMN 015, "** AREA DE NEGOCIO: ",
			 rm_par.area_n USING '<<&', " ", rm_par.tit_area
	END IF
	PRINT COLUMN 015, "** MONEDA         : ", rm_par.moneda,
		" ", rm_par.tit_mon
	IF rm_par.tipcli IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CLIENTE   : ",
			rm_par.tipcli USING '<<<&', " ", rm_par.tit_tipcli
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
			RETURNING r_g02.*
		PRINT COLUMN 015, "** LOCALIDAD      : ",
			rm_par.localidad USING '&&', " ", r_g02.g02_nombre
	END IF
	IF rm_par.zona_cobro IS NOT NULL THEN
		PRINT COLUMN 015, "** ZONA DE COBRO  : ",
			rm_par.zona_cobro USING '<<<&', " ",
			rm_par.tit_zona_cobro
	END IF
	IF rm_par.vendedor IS NOT NULL THEN
		PRINT COLUMN 015, "** VENDEDOR       : ",
			rm_par.vendedor USING '<<&', " ",
			rm_par.tit_vendedor
	END IF
	PRINT COLUMN 015, "** TIPO DE VENCTO.: ", rm_par.ind_venc, " ",
		retorna_tipo_vencto(rm_par.ind_venc),
	      COLUMN 053, "** TIPO REPORTE: ", vm_imprimir, ' ',
			tit_imprimir CLIPPED
	PRINT COLUMN 015, "** POR COBRAR AL  : ",
		rm_par.fecha_cart USING 'dd-mm-yyyy'
	IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
		PRINT COLUMN 056, "INCLUIDO EL SALDO A FAVOR"
	ELSE
		PRINT " "
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 015, "C L I E N T E S",
	      COLUMN 037, "LC";
	IF rm_par.ind_doc <> 'T' THEN
		PRINT COLUMN 040, "V. POR VENCER",
		      COLUMN 054, "VALOR VENCIDO",
		      COLUMN 068, "  VALOR PAGAR"
	ELSE
		CASE rm_par.ind_venc
			WHEN 'P'
				PRINT COLUMN 040, "V. POR VENCER";
			WHEN 'V'
				PRINT COLUMN 040, "VALOR VENCIDO";
			WHEN 'T'
				PRINT COLUMN 040, " TOTAL DEUDOR";
		END CASE
		PRINT COLUMN 054, "TOTAL A FAVOR",
		      COLUMN 068, "CARTERA TOTAL"
	END IF
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_cli[i].codcli		USING "#&&&&&",
	      COLUMN 008, rm_cli[i].nomcli[1, 28]	CLIPPED,
	      COLUMN 037, rm_cli[i].locali		USING "&&",
	      COLUMN 040, rm_cli[i].tot_pven		USING "--,---,--&.##",
	      COLUMN 054, rm_cli[i].tot_venc		USING "--,---,--&.##",
	      COLUMN 068, rm_cli[i].tot_saldo		USING "--,---,--&.##"
	IF vm_imprimir = 'D' THEN
		SKIP 1 LINES
		PRINT COLUMN 011, 'TD',
		      COLUMN 014, 'NUMERO DOC.',
		      COLUMN 026, 'LC',
		      COLUMN 029, 'FECHA VCTO',
		      COLUMN 040, '   VALOR DOC.',
		      COLUMN 054, '   SALDO DOC.'
		CASE rm_par.ind_venc
			WHEN 'V'
				LET expr_fec = '   AND z20_fecha_vcto  < "',
						rm_par.fecha_cart, '"'
			WHEN 'P'
				LET expr_fec = '   AND z20_fecha_vcto >= "',
						rm_par.fecha_cart, '"'
			OTHERWISE
				LET expr_fec = NULL
		END CASE
		LET query = 'SELECT z20_tipo_doc, z20_num_doc, z20_dividendo,',
				' z20_localidad, z20_fecha_vcto, valor_doc,',
				' valor_mov ',
				' FROM tmp_mov ',
				' WHERE z20_localidad   = ', rm_cli[i].locali,
				'   AND z20_codcli      = ', rm_cli[i].codcli,
				expr_fec CLIPPED,
				' ORDER BY z20_fecha_vcto '
		PREPARE cons_docs FROM query
		DECLARE q_docs CURSOR FOR cons_docs
		LET tot_val = 0
		LET tot_sal = 0
		FOREACH q_docs INTO r_z20.z20_tipo_doc, r_z20.z20_num_doc,
				r_z20.z20_dividendo, r_z20.z20_localidad,
				r_z20.z20_fecha_vcto, r_z20.z20_valor_cap,
				r_z20.z20_saldo_cap
			LET tot_val = tot_val + r_z20.z20_valor_cap
			LET tot_sal = tot_sal + r_z20.z20_saldo_cap
			PRINT COLUMN 011, r_z20.z20_tipo_doc,
			      COLUMN 014,r_z20.z20_num_doc USING "<<<<<<&", '-',
				r_z20.z20_dividendo USING "<&&",
			      COLUMN 026, r_z20.z20_localidad USING "&&",
			      COLUMN 029, r_z20.z20_fecha_vcto
							USING "dd-mm-yyyy",
			      COLUMN 040, r_z20.z20_valor_cap
							USING "--,---,--&.##",
			      COLUMN 054, r_z20.z20_saldo_cap
							USING "--,---,--&.##"
		END FOREACH
		PRINT COLUMN 040, "-------------",
		      COLUMN 054, "-------------"
		PRINT COLUMN 024, "TOT. DOCS. ==>  ",
		      COLUMN 040, tot_val		USING "--,---,--&.##",
		      COLUMN 054, tot_sal		USING "--,---,--&.##"
		SKIP 1 LINES
	END IF
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 040, "-------------",
	      COLUMN 054, "-------------",
	      COLUMN 068, "-------------"
	PRINT COLUMN 027, "TOTALES ==>  ",
	      COLUMN 040, tot_1				USING "--,---,--&.##",
	      COLUMN 054, tot_2				USING "--,---,--&.##",
	      COLUMN 068, tot_3				USING "--,---,--&.##"

END REPORT



FUNCTION retorna_tipo_vencto(tipo)
DEFINE tipo		CHAR(1)
DEFINE tipo_nom		VARCHAR(10)

CASE tipo
	WHEN 'P'
		LET tipo_nom = 'POR VENCER'
	WHEN 'V'
		LET tipo_nom = 'VENCIDOS'
	WHEN 'T'
		LET tipo_nom = 'T O D O S'
END CASE
RETURN tipo_nom

END FUNCTION



FUNCTION control_generar_archivo()
DEFINE mensaje		VARCHAR(200)
DEFINE query		CHAR(4000)
DEFINE expr		VARCHAR(100)
DEFINE expr_fec		VARCHAR(100)
DEFINE aux_i		CHAR(1)

CALL retorna_tipo() RETURNING aux_i
IF int_flag THEN
	RETURN
END IF
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	LET expr = NULL
	IF rm_par2.val_cobrar IS NOT NULL THEN
		LET expr = ' WHERE saldo_deu + NVL(saldo_fav, 0) >= ',
				rm_par2.val_cobrar
	END IF
	LET query = "SELECT codcli, nomcli, locali, saldo_deu, ",
			"NVL(saldo_fav, 0) saldo_fav, saldo_deu + ",
			"NVL(saldo_fav, 0) cart_tot ",
		" FROM tmp_cli_car ",
		expr CLIPPED,
		" INTO TEMP t1 "
	PREPARE exec_t1 FROM query
	EXECUTE exec_t1
	UNLOAD TO "../../../tmp/cxcp310.unl"
		SELECT codcli, nomcli, locali, saldo_deu, saldo_fav, cart_tot
			FROM t1
			ORDER BY 4 DESC, 1 DESC
	DROP TABLE t1
ELSE
	CASE vm_imprimir
		WHEN 'R'
			UNLOAD TO "../../../tmp/cxcp310.unl"
				SELECT codcli, nomcli, localidad,
						SUM(por_vencer), SUM(vencido),
						SUM(por_vencer + vencido)
					FROM tempo_doc
					GROUP BY 1, 2, 3
					ORDER BY 4 DESC, 1 DESC
		WHEN 'D'
			CASE rm_par.ind_venc
				WHEN 'V'
					LET expr_fec =
						' WHERE z20_fecha_vcto  < "',
							rm_par.fecha_cart, '"'
				WHEN 'P'
					LET expr_fec =
						' WHERE z20_fecha_vcto >= "',
							rm_par.fecha_cart, '"'
				OTHERWISE
					LET expr_fec = NULL
			END CASE
			LET query = 'SELECT z20_codcli cod, z20_tipo_doc tip, ',
						'z20_num_doc num, ',
						'z20_dividendo divi, ',
						'z20_localidad local, ',
						'z20_fecha_emi fec_e, ',
						'z20_fecha_vcto fec_v, ',
						'valor_doc v_doc, ',
						'valor_mov v_mov, ',
			' CASE WHEN area_n = 1 THEN ',
				'CASE WHEN (z20_localidad <> 2 AND z20_localidad <> 4)',
				' THEN ',
				' (SELECT r38_num_sri ',
					' FROM rept038 ',
					' WHERE r38_compania  = ', vg_codcia,
					'   AND r38_localidad = z20_localidad ',
					'   AND r38_tipo_fuente = "PR" ',
					'   AND r38_cod_tran  = cod_tran ',
					'   AND r38_num_tran  = num_tran) ',
				' WHEN NOT (z20_localidad <> 2 AND z20_localidad <> 4)',
				' THEN ',
				' (SELECT r38_num_sri ',
					' FROM ',
					retorna_base_loc() CLIPPED, 'rept038 ',
					' WHERE r38_compania  = ', vg_codcia,
					'   AND r38_localidad = z20_localidad ',
					'   AND r38_tipo_fuente = "PR" ',
					'   AND r38_cod_tran  = cod_tran ',
					'   AND r38_num_tran  = num_tran) ',
				' END ',
			' WHEN area_n = 2 THEN ',
				' (SELECT r38_num_sri ',
					' FROM rept038 ',
					' WHERE r38_compania  = ', vg_codcia,
					'   AND r38_localidad = z20_localidad ',
					'   AND r38_tipo_fuente = "OT" ',
					'   AND r38_cod_tran  = cod_tran ',
					'   AND r38_num_tran  = num_tran) ',
			' END num_sri, ',
			' CASE WHEN area_n = 1 THEN ',
				'CASE WHEN (z20_localidad <> 2 AND z20_localidad <> 4)',
				' THEN ',
				' (SELECT r01_nombres ',
					' FROM rept019, rept001 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = z20_localidad ',
					'   AND r19_cod_tran  = cod_tran ',
					'   AND r19_num_tran  = num_tran ',
					'   AND r01_compania  = r19_compania ',
					'   AND r01_codigo    = r19_vendedor) ',
				' WHEN NOT (z20_localidad <> 2 AND z20_localidad <> 4)',
				' THEN ',
				' (SELECT r01_nombres ',
					' FROM ',
					retorna_base_loc() CLIPPED, 'rept019, ',
					retorna_base_loc() CLIPPED, 'rept001 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = z20_localidad ',
					'   AND r19_cod_tran  = cod_tran ',
					'   AND r19_num_tran  = num_tran ',
					'   AND r01_compania  = r19_compania ',
					'   AND r01_codigo    = r19_vendedor) ',
				' END ',
			' WHEN area_n = 2 THEN ',
				' (SELECT r01_nombres ',
					' FROM talt023, talt061, rept001 ',
					' WHERE t23_compania    = ', vg_codcia,
					'   AND t23_localidad  = z20_localidad',
					'   AND t23_num_factura = num_tran ',
					'   AND t61_compania    = t23_compania',
					'   AND t61_cod_asesor=t23_cod_asesor ',
					'   AND r01_compania  = t61_compania ',
					'   AND r01_codigo = t61_cod_vendedor)',
			' END vendedor, ',
			' CASE WHEN area_n = 1 THEN "INVENTARIO" ',
			'      WHEN area_n = 2 THEN "TALLER" ',
			' END area_n, ',
			' CASE WHEN z20_fecha_vcto > "', rm_par.fecha_cart, '"',
				' THEN z20_fecha_vcto - "', rm_par.fecha_cart,
					'"',
				' ELSE ("', rm_par.fecha_cart,
					'" - z20_fecha_vcto) * (-1) ',
			' END dias, ',
			' CASE WHEN z20_fecha_vcto > "', rm_par.fecha_cart, '"',
				' THEN "POR VENCER" ',
			'      WHEN z20_fecha_vcto < "', rm_par.fecha_cart, '"',
				' THEN "VENCIDO" ',
				' ELSE "VENCE HOY" ',
			' END venc_por ',
					' FROM tmp_mov ',
					expr_fec CLIPPED,
					' INTO TEMP t1 '
			PREPARE exec_t1_a FROM query
			EXECUTE exec_t1_a
			UNLOAD TO "../../../tmp/cxcp310.unl"
				SELECT codcli, nomcli, localidad, area_n,
						vendedor, tip, num_sri, num,
						divi, fec_e, fec_v, venc_por,
						dias, v_doc, v_mov
					FROM tempo_doc, t1
					WHERE local = locali
					  AND cod   = codcli
					ORDER BY vendedor, fec_v, nomcli
			DROP TABLE t1
	END CASE
END IF
RUN "mv ../../../tmp/cxcp310.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"), '/tmp/cxcp310.unl',
		' OK.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION generar_pdf()
DEFINE codigo		LIKE rept001.r01_codigo
DEFINE comando		CHAR(256)

LET codigo = rm_par.vendedor
IF codigo IS NULL THEN
	LET codigo = 0
END IF
LET comando = "ecvc.jsp?prm_vendedor=", codigo USING "<<<<<<&"
CALL fl_ejecuta_reporte_pdf(vg_codloc, comando, 'F')

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)
DEFINE codloc		LIKE gent002.g02_localidad

LET base_loc = NULL
IF vg_codloc = 6 OR vg_codloc = 7 THEN
	RETURN base_loc CLIPPED
END IF
LET codloc = vg_codloc
CASE vg_codloc
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
