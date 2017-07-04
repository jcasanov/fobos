------------------------------------------------------------------------------
-- Titulo           : rolp130.4gl - Parametros generales para el modulo de
--				    club
-- Elaboracion      : 17-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp130 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS


DEFINE rm_n60		RECORD LIKE rolt060.*
DEFINE rm_par	RECORD 
	n60_tipo_afilia		LIKE rolt060.n60_tipo_afilia,
        n60_rub_aporte		LIKE rolt060.n60_rub_aporte,
	n06_nombre		LIKE rolt006.n06_nombre,
	n60_val_aporte		LIKE rolt060.n60_val_aporte,
	n60_frec_aporte		LIKE rolt060.n60_frec_aporte,
	n60_int_mensual		LIKE rolt060.n60_int_mensual,
	n60_presidente		LIKE rolt060.n60_presidente,
	n60_tesorero		LIKE rolt060.n60_tesorero,
	n60_banco		LIKE rolt060.n60_banco,
	tit_banco		VARCHAR(30),
	n60_numero_cta		LIKE rolt060.n60_numero_cta,
	n60_saldo_cta		LIKE rolt060.n60_saldo_cta,
	n60_usuario		LIKE rolt060.n60_usuario,
	n60_fecing	 	LIKE rolt060.n60_fecing
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'rolp130'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_club AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_club FROM '../forms/rolf130_1'
DISPLAY FORM f_club

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_n60.* TO NULL
CALL muestra_contadores()

CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING rm_n60.*

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		IF rm_n60.n60_compania IS NOT NULL THEN
			HIDE OPTION 'Ingresar'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			HIDE OPTION 'Ingresar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
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
DEFINE r_n30			RECORD LIKE rolt030.*
DEFINE r_n61			RECORD LIKE rolt061.*

CLEAR FORM
INITIALIZE rm_par.* TO NULL

LET rm_par.n60_saldo_cta = 0
LET rm_par.n60_fecing  = CURRENT
LET rm_par.n60_usuario = vg_usuario

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
BEGIN WORK
INSERT INTO rolt060 VALUES (vg_codcia,              rm_par.n60_tipo_afilia, 
                            rm_par.n60_val_aporte,  rm_par.n60_frec_aporte,
			    rm_par.n60_rub_aporte,
			    rm_par.n60_int_mensual, rm_par.n60_presidente,
			    rm_par.n60_tesorero,    rm_par.n60_banco,
			    rm_par.n60_numero_cta,  0,
                            rm_par.n60_usuario,
			    rm_par.n60_fecing)

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows

DECLARE q_afi CURSOR FOR 
        SELECT * FROM rolt030 WHERE n30_compania = vg_codcia 
				     AND n30_estado   = 'A'
FOREACH q_afi INTO r_n30.*
	INITIALIZE r_n61.* TO NULL
	LET r_n61.n61_compania     = vg_codcia
	LET r_n61.n61_cod_trab     = r_n30.n30_cod_trab
	IF r_n30.n30_fecha_reing IS NULL THEN
		LET r_n61.n61_fec_ing_club = r_n30.n30_fecha_ing 
	ELSE
		LET r_n61.n61_fec_ing_club = r_n30.n30_fecha_reing 
	END IF
	LET r_n61.n61_cuota   = rm_par.n60_val_aporte
	LET r_n61.n61_usuario = vg_usuario
	LET r_n61.n61_fecing  = CURRENT
	INSERT INTO rolt061 VALUES (r_n61.*)	
END FOREACH
COMMIT WORK
FREE q_afi

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM rolt060 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_n60.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF  
WHENEVER ERROR STOP

LET rm_par.n60_tipo_afilia = rm_n60.n60_tipo_afilia
LET rm_par.n60_val_aporte  = rm_n60.n60_val_aporte   
LET rm_par.n60_frec_aporte = rm_n60.n60_frec_aporte
LET rm_par.n60_rub_aporte  = rm_n60.n60_rub_aporte
LET rm_par.n60_int_mensual = rm_n60.n60_int_mensual
LET rm_par.n60_presidente  = rm_n60.n60_presidente
LET rm_par.n60_tesorero    = rm_n60.n60_tesorero  
LET rm_par.n60_usuario     = rm_n60.n60_usuario
LET rm_par.n60_fecing      = rm_n60.n60_fecing 

CALL lee_datos()
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	FREE  q_upd
	RETURN
END IF 

LET rm_n60.n60_tipo_afilia = rm_par.n60_tipo_afilia
LET rm_n60.n60_val_aporte  = rm_par.n60_val_aporte   
LET rm_n60.n60_frec_aporte = rm_par.n60_frec_aporte
LET rm_n60.n60_rub_aporte  = rm_par.n60_rub_aporte
LET rm_n60.n60_int_mensual = rm_par.n60_int_mensual
LET rm_n60.n60_presidente  = rm_par.n60_presidente
LET rm_n60.n60_tesorero    = rm_par.n60_tesorero  
LET rm_n60.n60_usuario     = rm_par.n60_usuario
LET rm_n60.n60_fecing      = rm_par.n60_fecing 

UPDATE rolt060 SET * = rm_n60.* WHERE CURRENT OF q_upd
UPDATE rolt061 SET n61_cuota = rm_par.n60_val_aporte
	WHERE n61_compania = vg_codcia
	  AND n61_fec_sal_club IS NULL
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n06		RECORD LIKE rolt006.*

LET INT_FLAG = 0

INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(n60_banco) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_par.n60_banco  = r_g08.g08_banco
				LET rm_par.tit_banco = r_g08.g08_nombre
				DISPLAY BY NAME rm_par.n60_banco,
						rm_par.tit_banco
			END IF
		END IF
		IF INFIELD(n60_rub_aporte) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T', 'T', 
				'S', 'T', 'T') RETURNING r_n06.n06_cod_rubro,
							 r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_par.n60_rub_aporte =
						r_n06.n06_cod_rubro
				LET rm_par.n06_nombre =
						r_n06.n06_nombre
				DISPLAY BY NAME rm_par.n60_rub_aporte,
						rm_par.n06_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n60_banco
		IF rm_par.n60_banco IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL fl_lee_banco_general(rm_par.n60_banco)
			RETURNING r_g08.*
		IF r_g08.g08_banco IS NOT NULL THEN
			LET rm_par.n60_banco  = r_g08.g08_banco
			LET rm_par.tit_banco = r_g08.g08_nombre
			DISPLAY BY NAME rm_par.n60_banco, rm_par.tit_banco
		END IF
	AFTER FIELD n60_rub_aporte
		IF rm_par.n60_rub_aporte IS NULL THEN
			CLEAR n06_nombre
			CONTINUE INPUT
		END IF
		CALL fl_lee_rubro_roles(rm_par.n60_rub_aporte) RETURNING r_n06.*
		IF r_n06.n06_cod_rubro IS NULL THEN
			CALL fl_mostrar_mensaje('Rubro no existe.', 'exclamation')
			NEXT FIELD n60_rub_aporte
		END IF
		IF r_n06.n06_estado = 'B' THEN
			CALL fl_mostrar_mensaje('Rubro esta bloqueado.', 'exclamation')
			NEXT FIELD n60_rub_aporte
		END IF
		LET rm_par.n06_nombre = r_n06.n06_nombre
		DISPLAY BY NAME rm_par.n60_rub_aporte, rm_par.n06_nombre 	
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE resp 		CHAR(6)
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n06		RECORD LIKE rolt006.*

CLEAR FORM
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON n60_tipo_afilia, n60_rub_aporte, 
			      n60_val_aporte, n60_frec_aporte,
			      n60_int_mensual, n60_presidente, n60_tesorero,
                              n60_banco,       n60_numero_cta, n60_usuario
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(n60_tipo_afilia, n60_val_aporte, 
				     n60_rub_aporte,
				     n60_frec_aporte, n60_int_mensual, 
                                     n60_presidente,  n60_tesorero,
				     n60_banco,       n60_numero_cta,
                                     n60_usuario) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(n60_banco) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_par.n60_banco  = r_g08.g08_banco
				LET rm_par.tit_banco = r_g08.g08_nombre
				DISPLAY BY NAME rm_par.n60_banco,
						rm_par.tit_banco
			END IF
		END IF
		IF INFIELD(n60_rub_aporte) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T', 'T', 
				'S', 'T', 'T') RETURNING r_n06.n06_cod_rubro,
							 r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_par.n60_rub_aporte =
						r_n06.n06_cod_rubro
				LET rm_par.n06_nombre =
						r_n06.n06_nombre
				DISPLAY BY NAME rm_par.n60_rub_aporte,
						rm_par.n06_nombre
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rolt060 WHERE n60_compania = ', vg_codcia, 
		' AND ', expr_sql, ' ORDER BY 1' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_n60.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	LET vm_num_rows = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n06		RECORD LIKE rolt006.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_n60.* FROM rolt060 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET rm_par.n60_tipo_afilia = rm_n60.n60_tipo_afilia
LET rm_par.n60_val_aporte  = rm_n60.n60_val_aporte   
LET rm_par.n60_frec_aporte = rm_n60.n60_frec_aporte
LET rm_par.n60_rub_aporte  = rm_n60.n60_rub_aporte
LET rm_par.n60_int_mensual = rm_n60.n60_int_mensual
LET rm_par.n60_presidente  = rm_n60.n60_presidente 
LET rm_par.n60_tesorero    = rm_n60.n60_tesorero   
LET rm_par.n60_banco       = rm_n60.n60_banco
LET rm_par.n60_numero_cta  = rm_n60.n60_numero_cta
LET rm_par.n60_saldo_cta   = rm_n60.n60_saldo_cta
LET rm_par.n60_usuario     = rm_n60.n60_usuario
LET rm_par.n60_fecing      = rm_n60.n60_fecing 

CALL fl_lee_banco_general(rm_par.n60_banco) RETURNING r_g08.*
LET rm_par.tit_banco = r_g08.g08_nombre

CALL fl_lee_rubro_roles(rm_par.n60_rub_aporte) RETURNING r_n06.*
LET rm_par.n06_nombre = r_n06.n06_nombre

DISPLAY BY NAME rm_par.*

CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION
