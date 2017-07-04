--------------------------------------------------------------------------------
-- Titulo           : ctbp106.4gl - Mantenimiento de Cuentas
-- Elaboracion      : 24-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp106 base módulo compañía [cuenta]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ctb		RECORD LIKE ctbt010.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY[1500] OF INTEGER
DEFINE vm_cc 		ARRAY[5] OF RECORD
				b10_cuenta	LIKE ctbt010.b10_cuenta,
				b10_descripcion	LIKE ctbt010.b10_descripcion
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp106.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp106'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1500
OPEN WINDOW wf AT 3,2 WITH 19 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf106_1"
DISPLAY FORM f_ctb
INITIALIZE rm_ctb.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
		IF num_args() = 4 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_niv		RECORD LIKE ctbt001.*
DEFINE r_grp		RECORD LIKE ctbt002.*
DEFINE crea		CHAR(1)
DEFINE num_elm		SMALLINT
DEFINE max_nivel	LIKE ctbt001.b01_nivel

CALL fl_retorna_usuario()
INITIALIZE rm_ctb.* TO NULL
INITIALIZE r_niv.* TO NULL
INITIALIZE r_grp.* TO NULL
CLEAR tit_nivel
CLEAR tit_centro
LET rm_ctb.b10_compania = vg_codcia
SELECT MAX(b01_nivel) INTO max_nivel FROM ctbt001
IF max_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No hay niveles de cuentas configurado.','stop')
	EXIT PROGRAM
END IF
LET rm_ctb.b10_nivel    = max_nivel
LET rm_ctb.b10_tipo_cta = NULL
LET rm_ctb.b10_tipo_mov = NULL
LET rm_ctb.b10_saldo_ma = 'N'
LET rm_ctb.b10_estado   = 'A'
LET rm_ctb.b10_usuario  = vg_usuario
LET rm_ctb.b10_fecing   = CURRENT
CALL fl_lee_nivel_cuenta(rm_ctb.b10_nivel) RETURNING r_niv.*
IF r_niv.b01_nivel IS NOT NULL THEN
	DISPLAY r_niv.b01_nombre TO tit_nivel
END IF
CALL muestra_estado()
CALL leer_datos('I') RETURNING crea
IF NOT int_flag THEN
	LET rm_ctb.b10_fecing = CURRENT
	BEGIN WORK
	INSERT INTO ctbt010 VALUES (rm_ctb.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	DISPLAY BY NAME rm_ctb.b10_fecing
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	IF crea = 1 THEN
		CALL crear_cuentas_superiores()
			RETURNING num_elm
		IF num_elm > 0 THEN
			CALL muestra_cuentas_creadas(num_elm)
		END IF
	END IF
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE crea		CHAR(1)
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_ctb.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM ctbt010
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ctb.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL leer_datos('M') RETURNING crea
IF NOT int_flag THEN
	UPDATE ctbt010 SET b10_descripcion = rm_ctb.b10_descripcion,
			   b10_descri_alt  = rm_ctb.b10_descri_alt,
			   b10_cod_ccosto  = rm_ctb.b10_cod_ccosto,
			   b10_saldo_ma    = rm_ctb.b10_saldo_ma,
			   b10_tipo_mov    = rm_ctb.b10_tipo_mov
			WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
COMMIT WORK
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE cniv_aux         LIKE ctbt001.b01_nivel
DEFINE nniv_aux         LIKE ctbt001.b01_nombre
DEFINE psi_aux          LIKE ctbt001.b01_posicion_i
DEFINE psf_aux          LIKE ctbt001.b01_posicion_f
DEFINE codc_aux		LIKE gent033.g33_cod_ccosto
DEFINE nomc_aux		LIKE gent033.g33_nombre
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux TO NULL
LET int_flag = 0
IF num_args() = 3 THEN
	CONSTRUCT BY NAME expr_sql ON b10_cuenta, b10_estado, b10_descripcion,
		b10_descri_alt, b10_tipo_cta, b10_tipo_mov, b10_cod_ccosto,
		b10_saldo_ma, b10_usuario
		ON KEY(F2)
			IF INFIELD(b10_cuenta) THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia,6)
					RETURNING cod_aux, nom_aux
				LET int_flag = 0
				IF cod_aux IS NOT NULL THEN
					DISPLAY cod_aux TO b10_cuenta 
					DISPLAY nom_aux TO b10_descripcion
				END IF 
			END IF
			IF INFIELD(b10_nivel) THEN
				CALL fl_ayuda_nivel_cuentas()
					RETURNING cniv_aux, nniv_aux, psi_aux, psf_aux
				LET int_flag = 0
				IF cniv_aux IS NOT NULL THEN
					DISPLAY cniv_aux TO b10_nivel 
					DISPLAY nniv_aux TO tit_nivel
				END IF 
			END IF
			IF INFIELD(b10_cod_ccosto) THEN
				CALL fl_ayuda_ccostos(vg_codcia)
					RETURNING codc_aux, nomc_aux
				LET int_flag = 0
				IF codc_aux IS NOT NULL THEN
					DISPLAY codc_aux TO b10_cod_ccosto 
					DISPLAY nomc_aux TO tit_centro
				END IF 
			END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'b10_cuenta = "', arg_val(4), '"'
END IF
LET query = 'SELECT *, ROWID FROM ctbt010 WHERE b10_compania = ' ||
		vg_codcia || ' AND ' || expr_sql || ' ORDER BY 2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_ctb.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos (flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE cuenta		CHAR(12)
DEFINE crear		CHAR(1)
DEFINE i,j		SMALLINT
DEFINE r_niv		RECORD LIKE ctbt001.*
DEFINE r_grp		RECORD LIKE ctbt002.*
DEFINE r_gent		RECORD LIKE gent033.*
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE cniv_aux         LIKE ctbt001.b01_nivel
DEFINE nniv_aux         LIKE ctbt001.b01_nombre
DEFINE psi_aux          LIKE ctbt001.b01_posicion_i
DEFINE psf_aux          LIKE ctbt001.b01_posicion_f
DEFINE codc_aux		LIKE gent033.g33_cod_ccosto
DEFINE nomc_aux		LIKE gent033.g33_nombre

LET int_flag = 0
LET crear = 0
INITIALIZE r_niv.* TO NULL
INITIALIZE r_grp.* TO NULL
INITIALIZE r_gent.* TO NULL
INITIALIZE r_ctb_aux.* TO NULL
INITIALIZE cuenta TO NULL
INITIALIZE cod_aux TO NULL
DISPLAY BY NAME rm_ctb.b10_nivel, rm_ctb.b10_tipo_cta, rm_ctb.b10_tipo_mov,
		rm_ctb.b10_usuario, rm_ctb.b10_fecing
INPUT BY NAME rm_ctb.b10_cuenta,
	rm_ctb.b10_descripcion,
	rm_ctb.b10_descri_alt,
	rm_ctb.b10_tipo_mov,
	rm_ctb.b10_cod_ccosto,
	rm_ctb.b10_saldo_ma
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        IF field_touched(rm_ctb.b10_cuenta,
		rm_ctb.b10_descripcion,
		rm_ctb.b10_descri_alt,
		rm_ctb.b10_cod_ccosto,
		rm_ctb.b10_saldo_ma)
        THEN
               	LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
              	IF resp = 'Yes' THEN
			LET int_flag = 1
                       	CLEAR FORM
                       	RETURN crear
                END IF
	ELSE
		RETURN crear
	END IF
	ON KEY(F2)
	IF INFIELD(b10_cuenta) THEN
		CALL fl_ayuda_cuenta_contable(vg_codcia,6)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			LET rm_ctb.b10_cuenta = cod_aux
			DISPLAY BY NAME rm_ctb.b10_cuenta 
			DISPLAY nom_aux TO b10_descripcion
		END IF 
	END IF
	IF INFIELD(b10_cod_ccosto) THEN
		CALL fl_ayuda_ccostos(vg_codcia)
			RETURNING codc_aux, nomc_aux
		LET int_flag = 0
		IF codc_aux IS NOT NULL THEN
			LET rm_ctb.b10_cod_ccosto = codc_aux
			DISPLAY BY NAME rm_ctb.b10_cod_ccosto 
			DISPLAY nomc_aux TO tit_centro
		END IF 
	END IF
	BEFORE FIELD b10_cuenta
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD b10_cuenta
		IF rm_ctb.b10_cuenta IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_ctb.b10_nivel)
				RETURNING r_niv.*
			IF r_niv.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Nivel no esta configurado','stop')
				EXIT PROGRAM
			END IF
			LET j = comprobar_nivel(rm_ctb.b10_cuenta, 12)
			IF j = 1 THEN
				NEXT FIELD rm_ctb.b10_cuenta
			END IF
			CALL fl_lee_grupo_cuenta(vg_codcia,rm_ctb.b10_cuenta[1,1])
				RETURNING r_grp.*
			IF r_grp.b02_grupo_cta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Grupo para está cuenta no existe','exclamation')				
				NEXT FIELD rm_ctb.b10_cuenta
			END IF
			IF length(rm_ctb.b10_cuenta) < r_niv.b01_posicion_i THEN
				CALL fgl_winmessage(vg_producto,'Número de cuenta debe ser del nivel 6','exclamation')
				NEXT FIELD rm_ctb.b10_cuenta
			END IF
			CALL fl_lee_cuenta(vg_codcia,rm_ctb.b10_cuenta)
				RETURNING r_ctb_aux.*
			IF r_ctb_aux.b10_cuenta IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Cuenta ya existe','exclamation')
				NEXT FIELD rm_ctb.b10_cuenta
			ELSE
				SELECT b10_cuenta INTO cuenta FROM ctbt010
				  WHERE b10_compania = vg_codcia AND 
					b10_cuenta = rm_ctb.b10_cuenta[1,8]
				IF cuenta IS NULL THEN
					LET crear = 1
				ELSE
					LET crear = 0
				END IF
			END IF
			IF flag_mant = 'I' THEN
				LET rm_ctb.b10_tipo_cta = r_grp.b02_tipo_cta 
				LET rm_ctb.b10_tipo_mov = r_grp.b02_tipo_mov
				DISPLAY BY NAME rm_ctb.b10_nivel, 
					rm_ctb.b10_tipo_cta, rm_ctb.b10_tipo_mov
			END IF
		END IF 
	AFTER FIELD b10_cod_ccosto 
		IF rm_ctb.b10_cod_ccosto IS NOT NULL THEN
		       CALL fl_lee_centro_costo(vg_codcia,rm_ctb.b10_cod_ccosto)
				RETURNING r_gent.* 
			IF r_gent.g33_cod_ccosto IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Centro de costo no existe','exclamation')
				NEXT FIELD b10_cod_ccosto
			ELSE
				DISPLAY r_gent.g33_nombre TO tit_centro
			END IF
		ELSE
			CLEAR b10_cod_ccosto
			CLEAR tit_centro
		END IF
END INPUT
RETURN crear

END FUNCTION



FUNCTION comprobar_nivel(cuenta, tot_pos)
DEFINE r_nv		RECORD LIKE ctbt001.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE ceros,i,tot_pos	SMALLINT
DEFINE ind		SMALLINT

IF cuenta[1,1] = 0 THEN
	CALL fgl_winmessage(vg_producto,'Número de cuenta no puede comenzar con cero','exclamation')
	RETURN 1
END IF
FOR i = 2 TO 5
	INITIALIZE r_nv.* TO NULL
	CALL fl_lee_nivel_cuenta(i) RETURNING r_nv.*
	LET ceros = 0
	FOR ind = r_nv.b01_posicion_i TO r_nv.b01_posicion_f
		IF cuenta[ind,ind] = 0 THEN
			LET ceros = ceros + 1
		END IF
	END FOR
	IF ceros = (r_nv.b01_posicion_f - r_nv.b01_posicion_i) + 1 THEN
		LET ceros = 0
		FOR ind = (r_nv.b01_posicion_f + 1) TO tot_pos
			IF cuenta[ind,ind] <> 0 THEN
				LET ceros = ceros + 1
			END IF
		END FOR
		IF ceros <> 0 THEN
			CALL fgl_winmessage(vg_producto,'Número de cuenta estáa incorrecto','exclamation')
			RETURN 1
		END IF 
	END IF
END FOR
IF cuenta[9,12] = '0000' THEN
	CALL fgl_winmessage(vg_producto,'Número de cuenta auxiliar no puede terminar con 4 ceros','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_niv		RECORD LIKE ctbt001.*
DEFINE r_gent		RECORD LIKE gent033.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_ctb.* FROM ctbt010 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_ctb.b10_cuenta,
			rm_ctb.b10_descripcion,
			rm_ctb.b10_descri_alt,
			rm_ctb.b10_tipo_cta,
			rm_ctb.b10_tipo_mov,
			rm_ctb.b10_nivel,
			rm_ctb.b10_cod_ccosto,
			rm_ctb.b10_saldo_ma,
			rm_ctb.b10_usuario,
                        rm_ctb.b10_fecing
	CALL fl_lee_nivel_cuenta(rm_ctb.b10_nivel) RETURNING r_niv.* 
	DISPLAY r_niv.b01_nombre TO tit_nivel
	CALL fl_lee_centro_costo(vg_codcia,rm_ctb.b10_cod_ccosto)
	RETURNING r_gent.* 
	DISPLAY r_gent.g33_nombre TO tit_centro
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM ctbt010
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_ctb.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET int_flag = 0
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
CALL bloquea_activa_registro()
COMMIT WORK
IF rm_ctb.b10_estado = 'A' THEN
	CALL fl_mostrar_mensaje('Cuenta ha sido activada OK.', 'info')
ELSE
	CALL fl_mostrar_mensaje('Cuenta ha sido bloqueada OK.', 'info')
END IF

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_ctb.b10_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cta
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_cta
	LET estado = 'A'
END IF
DISPLAY estado TO b10_estado
UPDATE ctbt010 SET b10_estado = estado WHERE CURRENT OF q_ba
LET rm_ctb.b10_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_ctb.b10_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cta
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_cta
END IF
DISPLAY BY NAME rm_ctb.b10_estado

END FUNCTION



FUNCTION crear_cuentas_superiores()
DEFINE i,j		SMALLINT
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*
DEFINE r_ctb_aux2	RECORD LIKE ctbt010.*
DEFINE r_niv_aux	RECORD LIKE ctbt001.*

INITIALIZE r_ctb_aux.* TO NULL
INITIALIZE r_ctb_aux2.* TO NULL
INITIALIZE r_niv_aux.* TO NULL
LET r_ctb_aux.b10_cuenta = rm_ctb.b10_cuenta[1,8]
LET r_ctb_aux.b10_nivel = rm_ctb.b10_nivel - 1
LET r_ctb_aux.b10_descripcion = rm_ctb.b10_descripcion
LET j = 1
WHILE TRUE
	IF r_ctb_aux.b10_nivel > 0 THEN
		INSERT INTO ctbt010 VALUES (vg_codcia,
					r_ctb_aux.b10_cuenta,
					r_ctb_aux.b10_descripcion,
					rm_ctb.b10_descri_alt,
					rm_ctb.b10_estado,
					rm_ctb.b10_tipo_cta,
					rm_ctb.b10_tipo_mov,
					r_ctb_aux.b10_nivel,
					rm_ctb.b10_cod_ccosto,
					rm_ctb.b10_saldo_ma,
					rm_ctb.b10_usuario,
					rm_ctb.b10_fecing)
		LET vm_cc[j].b10_cuenta = r_ctb_aux.b10_cuenta
		LET vm_cc[j].b10_descripcion = r_ctb_aux.b10_descripcion
		LET j = j + 1
		CALL fl_lee_nivel_cuenta(r_ctb_aux.b10_nivel)
			RETURNING r_niv_aux.*
		IF r_niv_aux.b01_nivel IS NOT NULL THEN
			FOR i = r_niv_aux.b01_posicion_i TO r_niv_aux.b01_posicion_f
				LET r_ctb_aux.b10_cuenta[i,i] = 0
			END FOR
			CALL fl_lee_cuenta(vg_codcia,r_ctb_aux.b10_cuenta)
				RETURNING r_ctb_aux2.*
			IF r_ctb_aux2.b10_cuenta IS NOT NULL THEN
				LET j = j - 1
				RETURN j
			END IF
			LET r_ctb_aux.b10_nivel = r_ctb_aux.b10_nivel - 1
		ELSE
			IF r_ctb_aux.b10_nivel <> 0 THEN
				CALL fgl_winmessage(vg_producto,'Nivel no configurado','stop')
				EXIT PROGRAM
			END IF
			LET j = j - 1
			RETURN j
		END IF
	ELSE
		LET j = j - 1
		RETURN j
	END IF
END WHILE	

END FUNCTION



FUNCTION muestra_cuentas_creadas(num_elm)
DEFINE num_elm,i		SMALLINT

OPEN WINDOW w_cc AT 06,23 WITH FORM '../forms/ctbf106_2'
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
        	BORDER)
CALL set_count(num_elm)
LET int_flag = 0
INPUT ARRAY vm_cc 
	WITHOUT DEFAULTS FROM vm_cc.*
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT','')
		--#CALL dialog.keysetlabel('DELETE','')
	BEFORE ROW
		LET i = arr_curr()
		IF i > num_elm THEN
			CALL dialog.setcurrline(i-1,i-1)
		END IF
	AFTER FIELD b10_descripcion
		LET i = arr_curr()
		IF vm_cc[i].b10_descripcion IS NULL THEN
			NEXT FIELD b10_descripcion
		END IF 
END INPUT
IF NOT int_flag THEN
	FOR i = 1 TO num_elm
		UPDATE ctbt010 SET b10_descripcion = vm_cc[i].b10_descripcion
			WHERE b10_compania = vg_codcia AND 
			      b10_cuenta   = vm_cc[i].b10_cuenta
	END FOR
END IF
CLOSE WINDOW w_cc
IF int_flag THEN
	INITIALIZE vm_cc.* TO NULL
	RETURN 
END IF
LET num_elm = arr_curr()

END FUNCTION
