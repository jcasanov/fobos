--------------------------------------------------------------------------------
-- Titulo           : cxpp211.4gl - Correccion Facturas de Proveedor
-- Elaboracion      : 25-Feb-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp211 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p33			RECORD LIKE cxpt033.*
DEFINE vm_rows			ARRAY[10000] OF INTEGER
DEFINE vm_row_current		SMALLINT
DEFINE vm_num_rows		SMALLINT
DEFINE vm_max_rows		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp211.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN     -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag
IF int_flag THEN
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_cxpp211 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf211_1 FROM '../forms/cxpf211_1'
ELSE
	OPEN FORM f_cxpf211_1 FROM '../forms/cxpf211_1c'
END IF
DISPLAY FORM f_cxpf211_1
LET vm_max_rows    = 10000
LET vm_num_rows    = 0
LET vm_row_current = 0
INITIALIZE rm_p33.* TO NULL
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Orden Compra'
		HIDE OPTION 'Compra Local'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
                CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Orden Compra'
			IF rm_p33.p33_num_tran IS NOT NULL THEN
				SHOW OPTION 'Compra Local'
			ELSE
				HIDE OPTION 'Compra Local'
			END IF
		END IF
                IF vm_row_current > 1 THEN
                        SHOW OPTION 'Retroceder'
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Orden Compra'
			IF rm_p33.p33_num_tran IS NOT NULL THEN
				SHOW OPTION 'Compra Local'
			ELSE
				HIDE OPTION 'Compra Local'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Orden Compra'
				HIDE OPTION 'Compra Local'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Orden Compra'
			IF rm_p33.p33_num_tran IS NOT NULL THEN
				SHOW OPTION 'Compra Local'
			ELSE
				HIDE OPTION 'Compra Local'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('O') 'Orden Compra' 	'Ver orden de compra.'
		CALL orden_compra()
	COMMAND KEY('L') 'Compra Local' 	'Ver compra local.'
		CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						rm_p33.p33_cod_tran,
						rm_p33.p33_num_tran)
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU

END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE rm_p33.* TO NULL
LET rm_p33.p33_compania  = vg_codcia
LET rm_p33.p33_localidad = vg_codloc
LET rm_p33.p33_usuario   = vg_usuario
LET rm_p33.p33_fecing    = CURRENT
DISPLAY BY NAME rm_p33.p33_fecing, rm_p33.p33_usuario
CALL lee_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
BEGIN WORK
	IF NOT cambio_datos_factura() THEN
		ROLLBACK WORK
		CLEAR FORM
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
	WHENEVER ERROR CONTINUE
	WHILE TRUE
		SQL
			SELECT NVL(MAX(p33_secuencia), 0) + 1
				INTO $rm_p33.p33_secuencia
				FROM cxpt033
				WHERE p33_compania  = $rm_p33.p33_compania
				  AND p33_localidad = $rm_p33.p33_localidad
				  AND p33_numero_oc = $rm_p33.p33_numero_oc
		END SQL
		SELECT * FROM cxpt033
			WHERE p33_compania  = rm_p33.p33_compania
			  AND p33_localidad = rm_p33.p33_localidad
			  AND p33_numero_oc = rm_p33.p33_numero_oc
			  AND p33_secuencia = rm_p33.p33_secuencia
		IF STATUS <> NOTFOUND THEN
			CONTINUE WHILE
		END IF
		LET rm_p33.p33_fecing = CURRENT
		INSERT INTO cxpt033 VALUES (rm_p33.*)
		LET num_reg = SQLCA.SQLERRD[6]
		EXIT WHILE
	END WHILE
	WHENEVER ERROR STOP
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = num_reg
LET vm_row_current       = vm_num_rows
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Factura cambiado numero y/o proveedor.', 'info')

END FUNCTION



FUNCTION control_consulta()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON p33_numero_oc, p33_num_tran, p33_cod_prov_ant,
	p33_nom_prov_ant, p33_num_fac_ant, p33_num_aut_ant, p33_fec_cad_ant,
	p33_cod_prov_nue, p33_num_fac_nue, p33_num_aut_nue, p33_fec_cad_nue,
	p33_usuario, p33_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(p33_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 0,
							0, 'C', '00', 'T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET rm_p33.p33_numero_oc = r_c10.c10_numero_oc
				DISPLAY BY NAME rm_p33.p33_numero_oc
			END IF
		END IF
		IF INFIELD(p33_num_tran) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,'CL')
				RETURNING r_r19.r19_cod_tran,
						r_r19.r19_num_tran,
						r_r19.r19_nomcli
			IF r_r19.r19_num_tran IS NOT NULL THEN
				LET rm_p33.p33_num_tran = r_r19.r19_num_tran
				DISPLAY BY NAME rm_p33.p33_num_tran
			END IF
		END IF
		IF INFIELD(p33_cod_prov_ant) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_p33.p33_cod_prov_ant = r_p01.p01_codprov
				DISPLAY BY NAME rm_p33.p33_cod_prov_ant
			END IF
		END IF
		IF INFIELD(p33_cod_prov_nue) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_p33.p33_cod_prov_nue = r_p01.p01_codprov
				DISPLAY BY NAME rm_p33.p33_cod_prov_nue
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM cxpt033 ',
		' WHERE p33_compania  = ', vg_codcia,
		'   AND p33_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY p33_secuencia ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_p33.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CLEAR FORM
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE resp		CHAR(6)
DEFINE lim		SMALLINT

LET int_flag = 0 
INPUT BY NAME rm_p33.p33_numero_oc, rm_p33.p33_cod_prov_nue,
	rm_p33.p33_num_fac_nue, rm_p33.p33_num_aut_nue, rm_p33.p33_fec_cad_nue
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_p33.p33_numero_oc, rm_p33.p33_cod_prov_nue,
				 rm_p33.p33_num_fac_nue, rm_p33.p33_num_aut_nue,
				 rm_p33.p33_fec_cad_nue)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(p33_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 0,
							0, 'C', '00', 'T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET rm_p33.p33_numero_oc = r_c10.c10_numero_oc
				DISPLAY BY NAME rm_p33.p33_numero_oc
			END IF
		END IF
		IF INFIELD(p33_cod_prov_nue) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_p33.p33_cod_prov_nue = r_p01.p01_codprov
				LET rm_p33.p33_nom_prov_nue = r_p01.p01_nomprov
				DISPLAY BY NAME rm_p33.p33_cod_prov_nue,
						rm_p33.p33_nom_prov_nue
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD p33_numero_oc
		IF rm_p33.p33_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
							rm_p33.p33_numero_oc)
				RETURNING r_c10.*
			IF r_c10.c10_numero_oc IS NULL THEN
				CALL fl_mostrar_mensaje('Orden de Compra no existe.', 'exclamation')
				NEXT FIELD p33_numero_oc
			END IF
			IF r_c10.c10_estado <> 'C' THEN
				CALL fl_mostrar_mensaje('Estado Orden de Compra debe ser CERRADO.', 'exclamation')
				NEXT FIELD p33_numero_oc
			END IF
			CALL datos_oc(r_c10.*, 1)
		ELSE
			CALL datos_oc(r_c10.*, 0)
		END IF
	AFTER FIELD p33_cod_prov_nue
		IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_p33.p33_cod_prov_nue)
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('Codigo de Proveedor no existe.', 'exclamation')
				NEXT FIELD p33_cod_prov_nue
			END IF
			IF r_p01.p01_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('Estado Codigo de Proveedor debe ser ACTIVO.', 'exclamation')
				NEXT FIELD p33_cod_prov_nue
			END IF
			LET rm_p33.p33_nom_prov_nue = r_p01.p01_nomprov
		ELSE
			LET rm_p33.p33_nom_prov_nue = NULL
		END IF
		DISPLAY BY NAME rm_p33.p33_nom_prov_nue
	AFTER FIELD p33_num_fac_nue
		IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
			IF LENGTH(rm_p33.p33_num_fac_nue) < 14 THEN
				CALL fl_mostrar_mensaje('El número del documento ingresado es incorrecto.', 'exclamation')
				NEXT FIELD p33_num_fac_nue
			END IF
			IF rm_p33.p33_num_fac_nue[4, 4] <> '-' OR
			   rm_p33.p33_num_fac_nue[8, 8] <> '-' THEN
				CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
				NEXT FIELD p33_num_fac_nue
			END IF
			IF LENGTH(rm_p33.p33_num_fac_nue[1, 7]) <> 7 THEN
				CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
				NEXT FIELD p33_num_fac_nue
			END IF
			IF NOT fl_valida_numeros(rm_p33.p33_num_fac_nue[1, 3])
			THEN
				NEXT FIELD p33_num_fac_nue
			END IF
			IF NOT fl_valida_numeros(rm_p33.p33_num_fac_nue[5, 7])
			THEN
				NEXT FIELD p33_num_fac_nue
			END IF
			LET lim = LENGTH(rm_p33.p33_num_fac_nue)
			IF NOT fl_valida_numeros(rm_p33.p33_num_fac_nue[9, lim])
			THEN
				NEXT FIELD p33_num_fac_nue
			END IF
		END IF
	AFTER FIELD p33_fec_cad_nue
		IF rm_p33.p33_fec_cad_nue IS NOT NULL THEN
			CALL retorna_fin_mes(rm_p33.p33_fec_cad_nue)
				RETURNING rm_p33.p33_fec_cad_nue
			DISPLAY BY NAME rm_p33.p33_fec_cad_nue
		END IF
	AFTER FIELD p33_num_aut_nue
		IF rm_p33.p33_num_aut_nue IS NOT NULL THEN
			IF LENGTH(rm_p33.p33_num_aut_nue) <> 10 THEN
				CALL fl_mostrar_mensaje('Numero de Autorizacion no tiene completo el numero de digitos.', 'exclamation')
				NEXT FIELD p33_num_aut_nue
			END IF
			IF rm_p33.p33_num_aut_nue[1, 1] <> '1' THEN
				CALL fl_mostrar_mensaje('Numero de Autorizacion es incorrecto.', 'exclamation')
				NEXT FIELD p33_num_aut_nue
			END IF
			IF NOT fl_valida_numeros(rm_p33.p33_num_aut_nue) THEN
				NEXT FIELD p33_num_aut_nue
			END IF
		END IF
	AFTER INPUT
		IF rm_p33.p33_cod_prov_nue IS NULL AND
		   rm_p33.p33_nom_prov_nue IS NULL AND
		   rm_p33.p33_num_fac_nue  IS NULL AND
		   rm_p33.p33_num_aut_nue  IS NULL AND
		   rm_p33.p33_fec_cad_nue  IS NULL
		THEN
			CALL fl_mostrar_mensaje('Debe al menos cambiar un dato de la factura.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION datos_oc(r_c10, flag)
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE flag		SMALLINT
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r19		RECORD LIKE rept019.*

LET rm_p33.p33_cod_prov_ant = NULL
LET rm_p33.p33_nom_prov_ant = NULL
LET rm_p33.p33_num_fac_ant  = NULL
LET rm_p33.p33_num_aut_ant  = NULL
LET rm_p33.p33_fec_cad_ant  = NULL
LET rm_p33.p33_cod_tran     = NULL
LET rm_p33.p33_num_tran     = NULL
IF NOT flag THEN
	LET rm_p33.p33_cod_prov_nue = NULL
	LET rm_p33.p33_nom_prov_nue = NULL
	LET rm_p33.p33_num_fac_nue  = NULL
	LET rm_p33.p33_num_aut_nue  = NULL
	LET rm_p33.p33_fec_cad_nue  = NULL
	DISPLAY BY NAME rm_p33.p33_cod_prov_ant, rm_p33.p33_nom_prov_ant,
			rm_p33.p33_num_fac_ant, rm_p33.p33_num_aut_ant,
			rm_p33.p33_fec_cad_ant, rm_p33.p33_num_tran,
			rm_p33.p33_cod_prov_nue, rm_p33.p33_nom_prov_nue,
			rm_p33.p33_num_fac_nue, rm_p33.p33_num_aut_nue,
			rm_p33.p33_fec_cad_nue
	RETURN
END IF
LET rm_p33.p33_cod_prov_ant = r_c10.c10_codprov
CALL fl_lee_proveedor(rm_p33.p33_cod_prov_ant) RETURNING r_p01.*
LET rm_p33.p33_nom_prov_ant = r_p01.p01_nomprov
INITIALIZE r_c13.*, r_r19.* TO NULL
DECLARE q_p33 CURSOR FOR
        SELECT * FROM ordt013
               WHERE c13_compania  = r_c10.c10_compania
                 AND c13_localidad = r_c10.c10_localidad
                 AND c13_numero_oc = r_c10.c10_numero_oc
		 AND c13_estado    = "A"
OPEN q_p33
FETCH q_p33 INTO r_c13.*
CLOSE q_p33
FREE q_p33
LET rm_p33.p33_num_fac_ant  = r_c13.c13_num_guia
LET rm_p33.p33_num_aut_ant  = r_c13.c13_num_aut
LET rm_p33.p33_fec_cad_ant  = r_c13.c13_fecha_cadu
DECLARE q_r19 CURSOR FOR
        SELECT * FROM rept019
               WHERE r19_compania   = r_c10.c10_compania
                 AND r19_localidad  = r_c10.c10_localidad
                 AND r19_oc_interna = r_c10.c10_numero_oc
OPEN q_r19
FETCH q_r19 INTO r_r19.*
CLOSE q_r19
FREE q_r19
IF r_r19.r19_compania IS NOT NULL THEN
	LET rm_p33.p33_cod_tran = r_r19.r19_cod_tran
	LET rm_p33.p33_num_tran = r_r19.r19_num_tran
ELSE
	LET rm_p33.p33_cod_tran = NULL
	LET rm_p33.p33_num_tran = NULL
END IF
DISPLAY BY NAME rm_p33.p33_cod_prov_ant, rm_p33.p33_nom_prov_ant,
		rm_p33.p33_num_fac_ant, rm_p33.p33_num_aut_ant,
		rm_p33.p33_fec_cad_ant, rm_p33.p33_num_tran

END FUNCTION



FUNCTION cambio_datos_factura()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE serie_comp	LIKE ordt013.c13_serie_comp
DEFINE query		CHAR(2500)
DEFINE expr_pro		VARCHAR(300)
DEFINE expr_num		VARCHAR(300)
DEFINE expr_aut		VARCHAR(100)
DEFINE expr_fec		VARCHAR(100)
DEFINE resul		SMALLINT

LET resul = 0
ERROR 'Iniciando Actualizacion... Por favor espere'
LET serie_comp = NULL
IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
	LET serie_comp = rm_p33.p33_num_fac_nue[1, 3],
				rm_p33.p33_num_fac_nue[5, 7]
END IF
IF rm_p33.p33_num_tran IS NOT NULL AND rm_p33.p33_num_fac_nue IS NOT NULL THEN
	ERROR 'Actualizando registro en rept019...       '
	WHENEVER ERROR CONTINUE
	UPDATE rept019
		SET r19_oc_externa = rm_p33.p33_num_fac_nue
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = 'CL'
		  AND r19_num_tran  = rm_p33.p33_num_tran
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en la Compra Local. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
END IF
IF rm_p33.p33_num_fac_nue IS NOT NULL OR rm_p33.p33_cod_prov_nue IS NOT NULL
THEN
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'c10_factura = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = ' c10_codprov = ', rm_p33.p33_cod_prov_nue
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en ordt010...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE ordt010 ',
			' SET ', expr_num CLIPPED,
				 expr_pro CLIPPED,
			' WHERE c10_compania  = ', vg_codcia,
			'   AND c10_localidad = ', vg_codloc,
			'   AND c10_numero_oc = ', rm_p33.p33_numero_oc
	PREPARE act_c10 FROM query
	EXECUTE act_c10
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en la Orden de Compra. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
END IF
IF rm_p33.p33_num_fac_nue IS NOT NULL OR rm_p33.p33_num_aut_nue IS NOT NULL OR
   rm_p33.p33_fec_cad_nue IS NOT NULL
THEN
	CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_p33.p33_numero_oc)
		RETURNING r_c10.*
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'c13_factura    = "',
					rm_p33.p33_num_fac_nue CLIPPED, '", ',
				'     c13_num_guia   = "',
					rm_p33.p33_num_fac_nue CLIPPED, '", ',
				'     c13_serie_comp = "', serie_comp CLIPPED,
							'"'
	END IF
	LET expr_aut = NULL
	IF rm_p33.p33_num_aut_nue IS NOT NULL THEN
		LET expr_aut = ' c13_num_aut = "',
					rm_p33.p33_num_aut_nue CLIPPED, '"'
	END IF
	LET expr_fec = NULL
	IF rm_p33.p33_fec_cad_nue IS NOT NULL THEN
		LET expr_fec = ' c13_fecha_cadu = "',
					rm_p33.p33_fec_cad_nue CLIPPED, '"'
	END IF
	IF expr_num IS NOT NULL AND
	  (expr_aut IS NOT NULL OR expr_fec IS NOT NULL)
	THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	IF expr_aut IS NOT NULL AND expr_fec IS NOT NULL THEN
		LET expr_aut = expr_aut CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en ordt013...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE ordt013 ',
			' SET ', expr_num CLIPPED,
				expr_aut CLIPPED,
				expr_fec CLIPPED,
			' WHERE c13_compania  = ', vg_codcia,
			'   AND c13_localidad = ', vg_codloc,
			'   AND c13_numero_oc = ', rm_p33.p33_numero_oc,
			'   AND c13_estado    = "A" '
	PREPARE act_c13 FROM query
	EXECUTE act_c13
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en la Recepcion Orden de Compra. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
END IF
IF serie_comp IS NOT NULL OR rm_p33.p33_num_aut_nue IS NOT NULL THEN
	LET expr_num = NULL
	IF serie_comp IS NOT NULL THEN
		LET expr_num = 'p01_serie_comp = "', serie_comp CLIPPED,'"'
	END IF
	LET expr_aut = NULL
	IF rm_p33.p33_num_aut_nue IS NOT NULL THEN
		LET expr_aut = ' p01_num_aut = "',
					rm_p33.p33_num_aut_nue CLIPPED, '"'
	END IF
	IF expr_num IS NOT NULL AND expr_aut IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en cxpt001...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE cxpt001 ',
			' SET ', expr_num CLIPPED,
				expr_aut CLIPPED,
			' WHERE p01_codprov = ', rm_p33.p33_cod_prov_ant
	PREPARE act_p01 FROM query
	EXECUTE act_p01
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar la autorizacion y la serie del comprobante en el Proveedor. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
END IF
IF rm_p33.p33_num_fac_nue IS NULL AND rm_p33.p33_cod_prov_nue IS NULL THEN
	RETURN 1
END IF
INITIALIZE r_c10.* TO NULL
DECLARE q_p20 CURSOR FOR
	SELECT p20_codprov
		FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = rm_p33.p33_cod_prov_ant
		  AND p20_tipo_doc  = "FA"
		  AND p20_num_doc   = rm_p33.p33_num_fac_ant
OPEN q_p20
FETCH q_p20 INTO r_c10.c10_codprov
CLOSE q_p20
FREE q_p20
ERROR ' '
ERROR 'Chequeando si no existe algun pago...'
INITIALIZE r_p23.* TO NULL
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = vg_codcia
		  AND p23_localidad = vg_codloc
		  AND p23_codprov   = r_c10.c10_codprov
		  AND p23_tipo_doc  = "FA"
		  AND p23_num_doc   = rm_p33.p33_num_fac_ant
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'p20_num_doc = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = 'p20_codprov = ', rm_p33.p33_cod_prov_nue
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en cxpt020...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE cxpt020 ',
			' SET ', expr_num CLIPPED,
				expr_pro CLIPPED,
			' WHERE p20_compania  = ', vg_codcia,
			'   AND p20_localidad = ', vg_codloc,
			'   AND p20_codprov   = ', r_c10.c10_codprov,
			'   AND p20_tipo_doc  = "FA" ',
			'   AND p20_num_doc   = "',
					rm_p33.p33_num_fac_ant CLIPPED, '"'
	PREPARE act_p20 FROM query
	EXECUTE act_p20
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en el Documento de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
END IF
IF r_p23.p23_compania IS NOT NULL THEN
	ERROR ' '
	ERROR 'Actualizando tablas del pago y contabilizacion...'
	SELECT * FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_c10.c10_codprov
		  AND p20_tipo_doc  = "FA"
		  AND p20_num_doc   = rm_p33.p33_num_fac_ant
		INTO TEMP tmp_p20
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'p20_num_doc = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = ' p20_codprov = ',
					rm_p33.p33_cod_prov_nue
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	LET query = 'UPDATE tmp_p20 ',
			' SET ', expr_num CLIPPED,
				expr_pro CLIPPED,
			' WHERE p20_compania  = ', vg_codcia,
			'   AND p20_localidad = ', vg_codloc,
			'   AND p20_codprov   = ', r_c10.c10_codprov,
			'   AND p20_tipo_doc  = "FA" ',
			'   AND p20_num_doc   = "',
					rm_p33.p33_num_fac_ant CLIPPED, '"'
	PREPARE act_p20_2 FROM query
	EXECUTE act_p20_2
	ERROR 'Insertando registro en cxpt020...'
	WHENEVER ERROR CONTINUE
	INSERT INTO cxpt020 SELECT * FROM tmp_p20
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede crear la factura como Documento de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
		DROP TABLE tmp_p20
		RETURN resul
	END IF
	WHENEVER ERROR STOP
	DROP TABLE tmp_p20
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'p23_num_doc = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = ' p23_codprov = ',
					rm_p33.p33_cod_prov_nue
		ERROR 'Actualizando registro en cxpt022...'
		SELECT UNIQUE cxpt022.*
			FROM cxpt023, cxpt022
			WHERE p23_compania  = vg_codcia
			  AND p23_localidad = vg_codloc
			  AND p23_codprov   = r_c10.c10_codprov
			  AND p23_tipo_doc  = 'FA'
			  AND p23_num_doc   = rm_p33.p33_num_fac_ant
			  AND p22_compania  = p23_compania
			  AND p22_localidad = p23_localidad
			  AND p22_codprov   = p23_codprov
			  AND p22_tipo_trn  = p23_tipo_trn
			  AND p22_num_trn   = p23_num_trn
			INTO TEMP tmp_p22
		SELECT p22_compania cia, p22_localidad loc, p22_codprov prov,
			p22_tipo_trn tt, p22_num_trn num_t
			FROM tmp_p22
			INTO TEMP t1
		UPDATE tmp_p22
			SET p22_codprov = rm_p33.p33_cod_prov_nue
			WHERE 1 = 1
		WHENEVER ERROR CONTINUE
		INSERT INTO cxpt022 SELECT * FROM tmp_p22
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			DROP TABLE tmp_p22
			CALL fl_mostrar_mensaje('No se puede cambiar el Proveedor en el Movimiento de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
			RETURN resul
		END IF
		DROP TABLE tmp_p22
		WHENEVER ERROR STOP
		ERROR 'Actualizando registro en cxpt024...'
		WHENEVER ERROR CONTINUE
		UPDATE cxpt024
			SET p24_codprov = rm_p33.p33_cod_prov_nue
			WHERE p24_compania    = vg_codcia
			  AND p24_localidad   = vg_codloc
			  AND p24_orden_pago IN
				(SELECT UNIQUE p25_orden_pago
					FROM cxpt025
					WHERE p25_compania  = p24_compania
					  AND p25_localidad = p24_localidad
					  AND p25_codprov   = p24_codprov
					  AND p25_tipo_doc  = 'FA'
					  AND p25_num_doc   =
							rm_p33.p33_num_fac_ant)
			  AND p24_codprov     = r_c10.c10_codprov
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se puede cambiar el Proveedor en la Orden de Pago de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
			RETURN resul
		END IF
		ERROR 'Actualizando registro en cxpt027...'
		WHENEVER ERROR CONTINUE
		UPDATE cxpt027
			SET p27_codprov = rm_p33.p33_cod_prov_nue
			WHERE p27_compania   = vg_codcia
			  AND p27_localidad  = vg_codloc
			  AND p27_num_ret   IN
				(SELECT UNIQUE p28_num_ret
					FROM cxpt028
					WHERE p28_compania  = p27_compania
					  AND p28_localidad = p27_localidad
					  AND p28_codprov   = p27_codprov
					  AND p28_tipo_doc  = "FA"
					  AND p28_num_doc   =
							rm_p33.p33_num_fac_ant)
			  AND p27_codprov    = r_c10.c10_codprov
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se puede cambiar el Proveedor en la Retencion. Llame al ADMINISTRADOR.', 'stop')
			RETURN resul
		END IF
		WHENEVER ERROR STOP
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en cxpt023...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE cxpt023 ',
			' SET ', expr_num CLIPPED,
				expr_pro CLIPPED,
			' WHERE p23_compania  = ', vg_codcia,
			'   AND p23_localidad = ', vg_codloc,
			'   AND p23_codprov   = ', r_c10.c10_codprov,
			'   AND p23_tipo_doc  = "FA" ',
			'   AND p23_num_doc   = "',
					rm_p33.p33_num_fac_ant CLIPPED, '"'
	PREPARE act_p23 FROM query
	EXECUTE act_p23
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en el Movimiento de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		WHENEVER ERROR CONTINUE
		DELETE FROM cxpt022
			WHERE EXISTS
				(SELECT * FROM t1
				WHERE t1.cia   = cxpt022.p22_compania
				  AND t1.loc   = cxpt022.p22_localidad
				  AND t1.prov  = cxpt022.p22_codprov
				  AND t1.tt    = cxpt022.p22_tipo_trn
				  AND t1.num_t = cxpt022.p22_num_trn)
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			DROP TABLE t1
			CALL fl_mostrar_mensaje('No se puede Eliminar la cabecera del Movimiento de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
			RETURN resul
		END IF
		WHENEVER ERROR STOP
		DROP TABLE t1
	END IF
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'p25_num_doc = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = ' p25_codprov = ', rm_p33.p33_cod_prov_nue
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en cxpt025...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE cxpt025 ',
			' SET ', expr_num CLIPPED,
				expr_pro CLIPPED,
			' WHERE p25_compania  = ', vg_codcia,
			'   AND p25_localidad = ', vg_codloc,
			'   AND p25_codprov   = ', r_c10.c10_codprov,
			'   AND p25_tipo_doc  = "FA" ',
			'   AND p25_num_doc   = "',
					rm_p33.p33_num_fac_ant CLIPPED, '"'
	PREPARE act_p25 FROM query
	EXECUTE act_p25
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en Orden de Pago de Tesoreria. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'p28_num_doc = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = ' p28_codprov = ', rm_p33.p33_cod_prov_nue
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en cxpt028...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE cxpt028 ',
			' SET ', expr_num CLIPPED,
				expr_pro CLIPPED,
			' WHERE p28_compania  = ', vg_codcia,
			'   AND p28_localidad = ', vg_codloc,
			'   AND p28_codprov   = ', r_c10.c10_codprov,
			'   AND p28_tipo_doc  = "FA" ',
			'   AND p28_num_doc   = "',
					rm_p33.p33_num_fac_ant CLIPPED, '"'
	PREPARE act_p28 FROM query
	EXECUTE act_p28
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en la Retencion. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
	LET expr_num = NULL
	IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
		LET expr_num = 'p41_num_doc = "',rm_p33.p33_num_fac_nue CLIPPED,
						'"'
	END IF
	LET expr_pro = NULL
	IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
		LET expr_pro = ' p41_codprov = ', rm_p33.p33_cod_prov_nue
	END IF
	IF expr_num IS NOT NULL AND expr_pro IS NOT NULL THEN
		LET expr_num = expr_num CLIPPED, ', '
	END IF
	ERROR 'Actualizando registro en cxpt041...'
	WHENEVER ERROR CONTINUE
	LET query = 'UPDATE cxpt041 ',
			' SET ', expr_num CLIPPED,
				expr_pro CLIPPED,
			' WHERE p41_compania  = ', vg_codcia,
			'   AND p41_localidad = ', vg_codloc,
			'   AND p41_codprov   = ', r_c10.c10_codprov,
			'   AND p41_tipo_doc  = "FA" ',
			'   AND p41_num_doc   = "',
					rm_p33.p33_num_fac_ant CLIPPED, '"'
	PREPARE act_p41 FROM query
	EXECUTE act_p41
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cambiar el numero de factura en el enlace Tesoreria/Contabilidad. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
	ERROR 'Borrando registro en cxpt020 de factura anterior...'
	WHENEVER ERROR CONTINUE
	DELETE FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_c10.c10_codprov
		  AND p20_tipo_doc  = "FA"
		  AND p20_num_doc   = rm_p33.p33_num_fac_ant
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede Eliminar el documento anterior. Llame al ADMINISTRADOR.', 'stop')
		RETURN resul
	END IF
	WHENEVER ERROR STOP
END IF
ERROR 'Actualizando glosa diarios contables...'
LET expr_num = 'b12_glosa glosa '
IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
	LET expr_num = 'REPLACE(b12_glosa, "', rm_p33.p33_num_fac_ant CLIPPED,
					'", "', rm_p33.p33_num_fac_nue CLIPPED,
				'") glosa '
END IF
LET query = 'SELECT b12_compania cia, b12_tipo_comp tp, b12_num_comp num, ',
			'b12_benef_che ben_che, ',
			expr_num CLIPPED,
		' FROM ctbt012 ',
		' WHERE b12_compania = ', rm_p33.p33_compania,
		'   AND b12_glosa    LIKE "%', rm_p33.p33_num_fac_ant CLIPPED,
					'%"',
		' INTO TEMP tmp_b12 '
PREPARE exec_b12_1 FROM query
EXECUTE exec_b12_1
LET expr_num = 'b13_glosa glosa '
IF rm_p33.p33_num_fac_nue IS NOT NULL THEN
	LET expr_num = 'REPLACE(b13_glosa, "', rm_p33.p33_num_fac_ant CLIPPED,
					'", "', rm_p33.p33_num_fac_nue CLIPPED,
				'") glosa '
END IF
LET query = 'SELECT b13_compania cia, b13_tipo_comp tp, b13_num_comp num, ',
			'b13_secuencia sec, b13_cuenta cta, b13_codprov prov, ',
			expr_num CLIPPED,
		' FROM ctbt013 ',
		' WHERE b13_compania = ', rm_p33.p33_compania,
		'   AND b13_glosa    LIKE "%', rm_p33.p33_num_fac_ant CLIPPED,
					'%"',
		' INTO TEMP tmp_b13 '
PREPARE exec_b13_1 FROM query
EXECUTE exec_b13_1
IF rm_p33.p33_cod_prov_nue IS NOT NULL THEN
	LET query = 'SELECT cia, tp, num, ',
				'CASE WHEN ben_che IS NOT NULL THEN "',
					rm_p33.p33_nom_prov_nue CLIPPED, '" ',
				'END ben_che, ',
			'REPLACE(glosa, "', rm_p33.p33_nom_prov_ant CLIPPED,
				'", "', rm_p33.p33_nom_prov_nue CLIPPED,
				'") glosa',
			' FROM tmp_b12 ',
			' INTO TEMP t1 '
	PREPARE exec_b12_2 FROM query
	EXECUTE exec_b12_2
	DROP TABLE tmp_b12
	SELECT * FROM t1 INTO TEMP tmp_b12
	DROP TABLE t1
	LET query = 'SELECT cia, tp, num, sec, cta, ', rm_p33.p33_cod_prov_nue,
				' prov, REPLACE(glosa, "',
					rm_p33.p33_nom_prov_ant[1, 19] CLIPPED,
				'", "', rm_p33.p33_nom_prov_nue[1, 19] CLIPPED,
				'") glosa',
			' FROM tmp_b13 ',
			' INTO TEMP t1 '
	PREPARE exec_b13_2 FROM query
	EXECUTE exec_b13_2
	DROP TABLE tmp_b13
	LET query = 'SELECT cia, tp, num, sec, cta, prov, ',
				'REPLACE(glosa, "',
					rm_p33.p33_nom_prov_ant[1, 20] CLIPPED,
				'", "', rm_p33.p33_nom_prov_nue[1, 20] CLIPPED,
				'") glosa',
			' FROM t1 ',
			' INTO TEMP t2 '
	PREPARE exec_b13_3 FROM query
	EXECUTE exec_b13_3
	DROP TABLE t1
	LET query = 'SELECT cia, tp, num, sec, cta, prov, ',
				'REPLACE(glosa, "(',
					rm_p33.p33_cod_prov_ant USING "<<<<&",
				')", "(', rm_p33.p33_cod_prov_nue USING "<<<<&",
				')") glosa',
			' FROM t2 ',
			' INTO TEMP t3 '
	PREPARE exec_b13_4 FROM query
	EXECUTE exec_b13_4
	DROP TABLE t2
	SELECT * FROM t3 INTO TEMP tmp_b13
	DROP TABLE t3
END IF
WHENEVER ERROR CONTINUE
UPDATE ctbt012
	SET b12_glosa     = (SELECT glosa
				FROM tmp_b12
				WHERE cia = b12_compania
				  AND tp  = b12_tipo_comp
				  AND num = b12_num_comp),
	    b12_benef_che = (SELECT ben_che
				FROM tmp_b12
				WHERE cia = b12_compania
				  AND tp  = b12_tipo_comp
				  AND num = b12_num_comp)
	WHERE b12_compania = rm_p33.p33_compania
	  AND EXISTS (SELECT 1 FROM tmp_b12
			WHERE cia = b12_compania
			  AND tp  = b12_tipo_comp
			  AND num = b12_num_comp)
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar la Glosa en la cabecera de los Diarios Contables. Llame al ADMINISTRADOR.', 'stop')
	DROP TABLE tmp_b12
	RETURN resul
END IF
WHENEVER ERROR STOP
DROP TABLE tmp_b12
WHENEVER ERROR CONTINUE
UPDATE ctbt013
	SET b13_glosa   = (SELECT glosa
				FROM tmp_b13
				WHERE cia = b13_compania
				  AND tp  = b13_tipo_comp
				  AND num = b13_num_comp
				  AND sec = b13_secuencia
				  AND cta = b13_cuenta),
	    b13_codprov = (SELECT prov
				FROM tmp_b13
				WHERE cia = b13_compania
				  AND tp  = b13_tipo_comp
				  AND num = b13_num_comp
				  AND sec = b13_secuencia
				  AND cta = b13_cuenta)
	WHERE b13_compania = rm_p33.p33_compania
	  AND EXISTS (SELECT 1 FROM tmp_b13
			WHERE cia = b13_compania
			  AND tp  = b13_tipo_comp
			  AND num = b13_num_comp
			  AND sec = b13_secuencia
			  AND cta = b13_cuenta)
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar la Glosa en el detalle de los Diarios Contables. Llame al ADMINISTRADOR.', 'stop')
	DROP TABLE tmp_b13
	RETURN resul
END IF
WHENEVER ERROR STOP
DROP TABLE tmp_b13
LET resul = 1
RETURN resul

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_p33.* FROM cxpt033 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
DISPLAY BY NAME rm_p33.p33_numero_oc, rm_p33.p33_cod_prov_ant,
		rm_p33.p33_nom_prov_ant, rm_p33.p33_num_fac_ant,
		rm_p33.p33_num_aut_ant, rm_p33.p33_fec_cad_ant,
		rm_p33.p33_num_tran, rm_p33.p33_cod_prov_nue,
		rm_p33.p33_nom_prov_nue, rm_p33.p33_num_fac_nue,
		rm_p33.p33_num_aut_nue, rm_p33.p33_fec_cad_nue,
		rm_p33.p33_usuario, rm_p33.p33_fecing
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION retorna_fin_mes(fecha)
DEFINE fecha		DATE
DEFINE mes, anio	SMALLINT

LET mes  = MONTH(fecha) + 1
LET anio = YEAR(fecha)
IF mes > 12 THEN
	LET mes  = 1
	LET anio = anio + 1
END IF
LET fecha = MDY(mes, 01, anio) - 1 UNITS DAY
RETURN fecha

END FUNCTION



FUNCTION orden_compra()
DEFINE param		VARCHAR(100)

LET param = vg_codloc, ' ', rm_p33.p33_numero_oc
CALL ejecuta_comando('COMPRAS', 'OC', 'ordp200', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(20)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)
DEFINE command 		VARCHAR(255) 
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command = 'cd ..', vg_separador, '..', vg_separador, modulo, 
	           vg_separador, 'fuentes', vg_separador, run_prog, 
		   prog, ' ', vg_base, ' ', mod, ' ', vg_codcia, ' ',
		param CLIPPED
RUN command

END FUNCTION
