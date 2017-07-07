--------------------------------------------------------------------------------
-- Titulo           : ctbp106.4gl - Mantenimiento de Cuentas
-- Elaboracion      : 24-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp106 base módulo compañía [cuenta]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b10			RECORD LIKE ctbt010.*
DEFINE vm_num_rows		SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows		SMALLINT
DEFINE vm_r_rows		ARRAY[1500] OF INTEGER
DEFINE vm_cc 			ARRAY[5] OF RECORD
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
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
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
OPEN WINDOW w_ctbf106_1 AT 3, 2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPEN FORM f_ctbf106_1 FROM "../forms/ctbf106_1"
DISPLAY FORM f_ctbf106_1
INITIALIZE rm_b10.* TO NULL
LET vm_num_rows    = 0
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
CLOSE WINDOW w_ctbf106_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_grp		RECORD LIKE ctbt002.*
DEFINE crea			CHAR(1)
DEFINE num_elm		SMALLINT

CALL fl_retorna_usuario()
INITIALIZE rm_b10.*, r_grp.* TO NULL
CLEAR tit_nivel, tit_centro, tit_cta_padre

LET rm_b10.b10_compania		= vg_codcia
LET rm_b10.b10_estado		= 'A'
LET rm_b10.b10_tipo_cta		= NULL
LET rm_b10.b10_tipo_mov		= NULL
LET rm_b10.b10_saldo_ma		= 'N'
LET rm_b10.b10_permite_mov	= 'N'
LET rm_b10.b10_usuario		= vg_usuario
LET rm_b10.b10_fecing		= CURRENT

CALL muestra_estado()
CALL leer_datos('I') RETURNING crea
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET rm_b10.b10_fecing = CURRENT
BEGIN WORK
	INSERT INTO ctbt010 VALUES (rm_b10.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	DISPLAY BY NAME rm_b10.b10_fecing
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	{--
	IF crea = 1 THEN
		CALL crear_cuentas_superiores() RETURNING num_elm
		IF num_elm > 0 THEN
			CALL muestra_cuentas_creadas(num_elm)
		END IF
	END IF
	--}
COMMIT WORK
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE crea		CHAR(1)
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM ctbt010
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_b10.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL leer_datos('M') RETURNING crea
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE ctbt010
	SET b10_descripcion  = rm_b10.b10_descripcion,
		b10_descri_alt   = rm_b10.b10_descri_alt,
		b10_cod_ccosto   = rm_b10.b10_cod_ccosto,
		b10_saldo_ma     = rm_b10.b10_saldo_ma,
		b10_tipo_mov     = rm_b10.b10_tipo_mov,
		b10_permite_mov  = rm_b10.b10_permite_mov,
		b10_cuenta_padre = rm_b10.b10_cuenta_padre
	WHERE CURRENT OF q_up
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ocurrio un ERROR grave al momento de intentar actualizar la cuenta. Por favor llame al Administrador.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
COMMIT WORK
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE cniv_aux     LIKE ctbt001.b01_nivel
DEFINE nniv_aux     LIKE ctbt001.b01_nombre
DEFINE psi_aux      LIKE ctbt001.b01_posicion_i
DEFINE psf_aux      LIKE ctbt001.b01_posicion_f
DEFINE codc_aux		LIKE gent033.g33_cod_ccosto
DEFINE nomc_aux		LIKE gent033.g33_nombre
DEFINE query		VARCHAR(800)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux TO NULL
LET int_flag = 0
IF num_args() = 3 THEN
	CONSTRUCT BY NAME expr_sql ON b10_cuenta, b10_estado, b10_descripcion,
		b10_descri_alt, b10_tipo_cta, b10_tipo_mov, b10_cod_ccosto,
		b10_saldo_ma, b10_permite_mov, b10_cuenta_padre, b10_usuario
		ON KEY(F2)
			IF INFIELD(b10_cuenta) THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, 0)
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
			IF INFIELD(b10_cuentai_padre) THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, 0)
					RETURNING cod_aux, nom_aux
				LET int_flag = 0
				IF cod_aux IS NOT NULL THEN
					DISPLAY cod_aux TO b10_cuenta_padre
					DISPLAY nom_aux TO tit_cta_padre
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
LET query = 'SELECT *, ROWID FROM ctbt010 ',
				'WHERE b10_compania = ', vg_codcia,
				'  AND ', expr_sql CLIPPED,
				' ORDER BY b10_cuenta '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_b10.*, num_reg
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
DEFINE resp			CHAR(6)
DEFINE cuenta		CHAR(12)
DEFINE crear		CHAR(1)
DEFINE tiene_cta	INTEGER
DEFINE query		VARCHAR(400)
DEFINE i, j			SMALLINT
DEFINE r_niv		RECORD LIKE ctbt001.*
DEFINE r_grp		RECORD LIKE ctbt002.*
DEFINE r_gent		RECORD LIKE gent033.*
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE cniv_aux     LIKE ctbt001.b01_nivel
DEFINE nniv_aux     LIKE ctbt001.b01_nombre
DEFINE psi_aux      LIKE ctbt001.b01_posicion_i
DEFINE psf_aux      LIKE ctbt001.b01_posicion_f
DEFINE codc_aux		LIKE gent033.g33_cod_ccosto
DEFINE nomc_aux		LIKE gent033.g33_nombre

LET int_flag = 0
LET crear    = 0
INITIALIZE r_niv.*, r_grp.*, r_gent.*, r_ctb_aux.*, cuenta, cod_aux TO NULL
DISPLAY BY NAME rm_b10.b10_nivel, rm_b10.b10_tipo_cta, rm_b10.b10_tipo_mov,
				rm_b10.b10_usuario, rm_b10.b10_fecing
INPUT BY NAME rm_b10.b10_cuenta, rm_b10.b10_descripcion, rm_b10.b10_descri_alt,
			rm_b10.b10_tipo_mov, rm_b10.b10_nivel, rm_b10.b10_cod_ccosto,
			rm_b10.b10_saldo_ma, rm_b10.b10_permite_mov, rm_b10.b10_cuenta_padre
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_b10.b10_cuenta, rm_b10.b10_descripcion,
						 rm_b10.b10_descri_alt, rm_b10.b10_tipo_mov,
						 rm_b10.b10_nivel, rm_b10.b10_cod_ccosto,
						 rm_b10.b10_saldo_ma, rm_b10.b10_permite_mov,
						 rm_b10.b10_cuenta_padre)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
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
			CALL fl_ayuda_cuenta_contable(vg_codcia, 0)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_b10.b10_cuenta = cod_aux
				DISPLAY BY NAME rm_b10.b10_cuenta
				DISPLAY nom_aux TO b10_descripcion
			END IF 
		END IF
		IF INFIELD(b10_cod_ccosto) THEN
			CALL fl_ayuda_ccostos(vg_codcia) RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				LET rm_b10.b10_cod_ccosto = codc_aux
				DISPLAY BY NAME rm_b10.b10_cod_ccosto 
				DISPLAY nomc_aux TO tit_centro
			END IF 
		END IF
		IF INFIELD(b10_cuenta_padre) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, rm_b10.b10_nivel - 1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_b10.b10_cuenta_padre = cod_aux
				DISPLAY BY NAME rm_b10.b10_cuenta_padre
				DISPLAY nom_aux TO tit_cta_padre
			END IF 
		END IF
	BEFORE FIELD b10_cuenta
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD b10_nivel
		LET cniv_aux = rm_b10.b10_nivel
	AFTER FIELD b10_cuenta
		IF rm_b10.b10_cuenta IS NOT NULL THEN
			CALL fl_lee_grupo_cuenta(vg_codcia,rm_b10.b10_cuenta[1,1])
				RETURNING r_grp.*
			IF r_grp.b02_grupo_cta IS NULL THEN
				CALL fl_mostrar_mensaje('Grupo para está cuenta no existe','exclamation')				
				NEXT FIELD b10_cuenta
			END IF
			CALL fl_lee_cuenta(vg_codcia, rm_b10.b10_cuenta)
				RETURNING r_ctb_aux.*
			IF r_ctb_aux.b10_cuenta IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Cuenta ya existe.','exclamation')
				NEXT FIELD rm_b10.b10_cuenta
			END IF
			SELECT b10_cuenta INTO cuenta
				FROM ctbt010
				WHERE b10_compania = vg_codcia
				  AND b10_cuenta   = rm_b10.b10_cuenta[1,8]
			IF cuenta IS NULL THEN
				LET crear = 1
			ELSE
				LET crear = 0
			END IF
			IF flag_mant = 'I' THEN
				LET rm_b10.b10_tipo_cta = r_grp.b02_tipo_cta 
				LET rm_b10.b10_tipo_mov = r_grp.b02_tipo_mov
				DISPLAY BY NAME rm_b10.b10_tipo_cta, rm_b10.b10_tipo_mov
			END IF
		END IF 
	AFTER FIELD b10_nivel
			IF rm_b10.b10_nivel IS NULL OR flag_mant <> 'I' THEN
				CALL fl_lee_nivel_cuenta(cniv_aux) RETURNING r_niv.*
				LET rm_b10.b10_nivel = cniv_aux
				DISPLAY BY NAME rm_b10.b10_nivel
				DISPLAY r_niv.b01_nombre TO tit_nivel
				IF flag_mant <> 'I' THEN
					CONTINUE INPUT
				END IF
			END IF
			CALL fl_lee_nivel_cuenta(rm_b10.b10_nivel) RETURNING r_niv.*
			IF r_niv.b01_nivel IS NULL THEN
				CALL fl_mostrar_mensaje('Nivel no esta configurado', 'exclamation')
				NEXT FIELD b10_nivel
			END IF
			DISPLAY r_niv.b01_nombre TO tit_nivel
	AFTER FIELD b10_cod_ccosto 
		IF rm_b10.b10_cod_ccosto IS NOT NULL THEN
			CALL fl_lee_centro_costo(vg_codcia, rm_b10.b10_cod_ccosto)
				RETURNING r_gent.*
			IF r_gent.g33_cod_ccosto IS NULL THEN
				CALL fl_mostrar_mensaje('Centro de costo no existe.', 'exclamation')
				NEXT FIELD b10_cod_ccosto
			END IF
			DISPLAY r_gent.g33_nombre TO tit_centro
		ELSE
			CLEAR b10_cod_ccosto, tit_centro
		END IF
	AFTER FIELD b10_cuenta_padre
		IF rm_b10.b10_cuenta_padre IS NOT NULL THEN
			CALL fl_lee_cuenta_padre(vg_codcia, rm_b10.b10_cuenta_padre)
				RETURNING r_ctb_aux.*
			IF r_ctb_aux.b10_cuenta IS NULL THEN
				CALL fl_mostrar_mensaje('Cuenta padre no existe.','exclamation')
				NEXT FIELD b10_cuenta_padre
			END IF
			DISPLAY r_ctb_aux.b10_descripcion TO tit_cta_padre
			IF rm_b10.b10_nivel <= r_ctb_aux.b10_nivel THEN
				CALL fl_mostrar_mensaje('La cuenta padre debe ser un nivel mayor al nivel de la cuenta hija.', 'exclamation')
				NEXT FIELD b10_cuenta_padre
			END IF
		ELSE
			CLEAR tit_cta_padre
		END IF 
	AFTER INPUT
		IF rm_b10.b10_permite_mov = 'S' THEN
			LET query = 'SELECT COUNT(*) tot_cta ',
							'FROM ctbt010 ',
							'WHERE b10_compania = ', vg_codcia,
							'  AND b10_cuenta   LIKE "',
											rm_b10.b10_cuenta CLIPPED, '%" ',
							'  AND b10_nivel    > ', rm_b10.b10_nivel,
							'INTO TEMP t1 '
			PREPARE exec_query FROM query
			EXECUTE exec_query
			SELECT tot_cta INTO tiene_cta FROM t1
			DROP TABLE t1
			IF tiene_cta > 0 THEN
				CALL fl_mostrar_mensaje('La cuenta ingresada no debe tener cuentas de siguiente nivel o cuentas hijas.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_b10.b10_permite_mov = 'N' THEN
			SELECT COUNT(*) INTO tiene_cta
				FROM ctbt013
				WHERE b13_compania = vg_codcia
				  AND b13_cuenta   = rm_b10.b10_cuenta
			IF tiene_cta > 0 THEN
				CALL fl_mostrar_mensaje('La cuenta tiene movimiento, por tal motivo no puede configurarla como de NO MOVIMIENTOS..', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_b10.b10_nivel = 1 AND rm_b10.b10_cuenta_padre IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Las cuentas de nivel 1 no pueden tener una cuenta padre.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
RETURN crear

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



FUNCTION muestra_contadores(row_cur, num_row)
DEFINE row_cur, num_row	SMALLINT

DISPLAY BY NAME row_cur, num_row

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_niv		RECORD LIKE ctbt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_gent		RECORD LIKE gent033.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_b10.* FROM ctbt010 WHERE ROWID=num_registro
	IF STATUS = NOTFOUND THEN
		CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current, 'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_b10.b10_cuenta,
			rm_b10.b10_descripcion,
			rm_b10.b10_descri_alt,
			rm_b10.b10_tipo_cta,
			rm_b10.b10_tipo_mov,
			rm_b10.b10_nivel,
			rm_b10.b10_cod_ccosto,
			rm_b10.b10_saldo_ma,
			rm_b10.b10_permite_mov,
			rm_b10.b10_cuenta_padre,
			rm_b10.b10_usuario,
			rm_b10.b10_fecing
	CALL fl_lee_nivel_cuenta(rm_b10.b10_nivel) RETURNING r_niv.* 
	DISPLAY r_niv.b01_nombre TO tit_nivel
	CALL fl_lee_centro_costo(vg_codcia,rm_b10.b10_cod_ccosto)
		RETURNING r_gent.* 
	DISPLAY r_gent.g33_nombre TO tit_centro
	CALL fl_lee_cuenta_padre(vg_codcia, rm_b10.b10_cuenta_padre)
		RETURNING r_b10.*
	DISPLAY r_b10.b10_descripcion TO tit_cta_padre
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
FETCH q_ba INTO rm_b10.*
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
IF rm_b10.b10_estado = 'A' THEN
	CALL fl_mostrar_mensaje('Cuenta ha sido activada OK.', 'info')
ELSE
	CALL fl_mostrar_mensaje('Cuenta ha sido bloqueada OK.', 'info')
END IF

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_b10.b10_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cta
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_cta
	LET estado = 'A'
END IF
DISPLAY estado TO b10_estado
UPDATE ctbt010 SET b10_estado = estado WHERE CURRENT OF q_ba
LET rm_b10.b10_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_b10.b10_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cta
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_cta
END IF
DISPLAY BY NAME rm_b10.b10_estado

END FUNCTION



FUNCTION crear_cuentas_superiores()
DEFINE i,j		SMALLINT
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*
DEFINE r_ctb_aux2	RECORD LIKE ctbt010.*
DEFINE r_niv_aux	RECORD LIKE ctbt001.*

INITIALIZE r_ctb_aux.*, r_ctb_aux2.*, r_niv_aux.* TO NULL
LET r_ctb_aux.b10_cuenta = rm_b10.b10_cuenta[1,8]
LET r_ctb_aux.b10_nivel = rm_b10.b10_nivel - 1
LET r_ctb_aux.b10_descripcion = rm_b10.b10_descripcion
LET j = 1
WHILE TRUE
	IF r_ctb_aux.b10_nivel > 0 THEN
		INSERT INTO ctbt010 VALUES (vg_codcia,
					r_ctb_aux.b10_cuenta,
					r_ctb_aux.b10_descripcion,
					rm_b10.b10_descri_alt,
					rm_b10.b10_estado,
					rm_b10.b10_tipo_cta,
					rm_b10.b10_tipo_mov,
					r_ctb_aux.b10_nivel,
					rm_b10.b10_cod_ccosto,
					rm_b10.b10_saldo_ma,
					rm_b10.b10_permite_mov,
					rm_b10.b10_cuenta_padre,
					rm_b10.b10_usuario,
					rm_b10.b10_fecing)
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
				CALL fl_mostrar_mensaje('Nivel no configurado.', 'stop')
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
