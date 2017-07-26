--------------------------------------------------------------------------------
-- Titulo           : repp120.4gl - Mantenimiento Sub-Zonas
-- Elaboracion      : 17-jul-2013
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp120 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[1000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE rm_r109		RECORD LIKE rept109.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp120.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp120'
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
LET vm_max_rows = 1000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 2
	LET num_rows = 22
	LET num_cols = 78
END IF                  
OPEN WINDOW w_repp120_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf120_1 FROM '../forms/repf120_1'
ELSE
	OPEN FORM f_repf120_1 FROM '../forms/repf120_1c'
END IF
DISPLAY FORM f_repf120_1
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
	COMMAND KEY('I') 'Ingresar' 	'Ingresar nuevos registros.'
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
        COMMAND KEY('M') 'Modificar'	'Modifica el registro actual.'
		CALL control_modificacion()
        COMMAND KEY('C') 'Consultar'    'Consultar un registro.'
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
        COMMAND KEY('B') 'Bloquear/Activar'	'Bloquea o Activa un registro.'
		CALL control_bloquear_activar()
	COMMAND KEY('A') 'Avanzar' 	'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 	'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    	'Salir del programa.'
		EXIT MENU
END MENU
CLOSE WINDOW w_repp120_1
EXIT PROGRAM

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_r109.* TO NULL
LET rm_r109.r109_compania  = vg_codcia
LET rm_r109.r109_localidad = vg_codloc
LET rm_r109.r109_estado    = "A"
LET rm_r109.r109_usuario   = vg_usuario
LET rm_r109.r109_fecing    = CURRENT
DISPLAY BY NAME rm_r109.r109_usuario, rm_r109.r109_fecing
CALL muestra_estado()
CALL lee_cabecera('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
BEGIN WORK
WHILE TRUE
	SELECT NVL(MAX(r109_cod_subzona) + 1, 1)
		INTO rm_r109.r109_cod_subzona
		FROM rept109
		WHERE r109_compania  = rm_r109.r109_compania
		  AND r109_localidad = rm_r109.r109_localidad
		  AND r109_cod_zona  = rm_r109.r109_cod_zona
	LET rm_r109.r109_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO rept109 VALUES (rm_r109.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		WHENEVER ERROR STOP
		EXIT WHILE
	END IF
END WHILE
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows  = 1
ELSE
	LET vm_num_rows  = vm_num_rows + 1
END IF
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = num_aux
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r109.r109_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_modif CURSOR FOR
	SELECT * FROM rept109
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
OPEN q_modif
FETCH q_modif INTO rm_r109.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de esta sub-zona. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_cabecera('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_salir()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE rept109
	SET * = rm_r109.*
	WHERE CURRENT OF q_modif
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR el registro de esta sub-zona. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1000)
DEFINE query		CHAR(2000)
DEFINE r_g25		RECORD LIKE gent025.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_r108		RECORD LIKE rept108.*
DEFINE r_r109		RECORD LIKE rept109.*

CLEAR FORM
INITIALIZE rm_r109.*, r_g25.*, r_g30.*, r_g31.*, r_r108.*, r_r109.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r109_estado, r109_cod_zona, r109_cod_subzona,
	r109_descripcion, r109_pais, r109_divi_poli, r109_ciudad,
	r109_horas_entr, r109_usuario, r109_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(r109_cod_zona) THEN
			CALL fl_ayuda_zonas(vg_codcia, vg_codloc, "T")
				RETURNING r_r108.r108_cod_zona,
					  r_r108.r108_descripcion
		      	IF r_r108.r108_cod_zona IS NOT NULL THEN
				DISPLAY r_r108.r108_cod_zona TO r109_cod_zona
				DISPLAY BY NAME r_r108.r108_descripcion
		      	END IF
		END IF
		IF INFIELD(r109_cod_subzona) AND
		   r_r108.r108_cod_zona IS NOT NULL
		THEN
			CALL fl_ayuda_subzonas(vg_codcia, vg_codloc,
						r_r108.r108_cod_zona, "T")
				RETURNING r_r109.r109_cod_subzona,
					  r_r109.r109_descripcion
		      	IF r_r109.r109_cod_subzona IS NOT NULL THEN
				DISPLAY BY NAME r_r109.r109_cod_subzona,
						r_r109.r109_descripcion
		      	END IF
		END IF
		IF INFIELD(r109_pais) THEN
			CALL fl_ayuda_pais()
				RETURNING r_g30.g30_pais, r_g30.g30_nombre
		      	IF r_g30.g30_pais IS NOT NULL THEN
				DISPLAY r_g30.g30_pais TO r109_pais
				DISPLAY BY NAME r_g30.g30_nombre
		      	END IF
		END IF
		IF INFIELD(r109_divi_poli) AND r_g30.g30_pais IS NOT NULL THEN
			CALL fl_ayuda_division_politica(r_g30.g30_pais)
				RETURNING r_g25.g25_divi_poli, r_g25.g25_nombre
			IF r_g25.g25_divi_poli IS NOT NULL THEN
				DISPLAY r_g25.g25_divi_poli TO r109_divi_poli
				DISPLAY BY NAME r_g25.g25_nombre
			END IF
		END IF
		IF INFIELD(r109_ciudad) AND r_g25.g25_divi_poli IS NOT NULL THEN
			CALL fl_ayuda_ciudad(r_g30.g30_pais,r_g25.g25_divi_poli)
				RETURNING r_g31.g31_ciudad, r_g31.g31_nombre
			IF r_g31.g31_ciudad IS NOT NULL THEN
				DISPLAY r_g31.g31_ciudad TO r109_ciudad
				DISPLAY BY NAME r_g31.g31_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r109_cod_zona
		LET rm_r109.r109_cod_zona = GET_FLDBUF(r109_cod_zona)
		IF rm_r109.r109_cod_zona IS NOT NULL THEN
			CALL fl_lee_zona(vg_codcia, vg_codloc,
						rm_r109.r109_cod_zona)
				RETURNING r_r108.*
			IF r_r108.r108_cod_zona IS NULL THEN
				CALL fl_mostrar_mensaje('Esta zona no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_cod_zona
			END IF
			LET rm_r109.r109_cod_zona = r_r108.r108_cod_zona
		ELSE
			INITIALIZE r_r108.*, r_r109.*, rm_r109.r109_cod_subzona
				TO NULL
		END IF
		DISPLAY BY NAME r_r108.r108_descripcion,
				rm_r109.r109_cod_subzona,
				r_r109.r109_descripcion
	AFTER FIELD r109_cod_subzona
		LET rm_r109.r109_cod_subzona = GET_FLDBUF(r109_cod_subzona)
		IF rm_r109.r109_cod_subzona IS NOT NULL THEN
			CALL fl_lee_subzona(vg_codcia, vg_codloc,
						rm_r109.r109_cod_zona,
						rm_r109.r109_cod_subzona)
				RETURNING r_r109.*
			IF r_r109.r109_cod_zona IS NULL THEN
				CALL fl_mostrar_mensaje('Esta subzona no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_cod_subzona
			END IF
			LET rm_r109.r109_cod_subzona = r_r109.r109_cod_subzona
		ELSE
			INITIALIZE r_r109.* TO NULL
		END IF
		DISPLAY BY NAME r_r109.r109_descripcion
	AFTER FIELD r109_pais
		LET rm_r109.r109_pais = GET_FLDBUF(r109_pais)
		IF rm_r109.r109_pais IS NOT NULL THEN
			CALL fl_lee_pais(rm_r109.r109_pais) RETURNING r_g30.*
			IF r_g30.g30_pais IS NULL THEN
				CALL fl_mostrar_mensaje('Este pais no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_pais
			END IF
			LET rm_r109.r109_pais = r_g30.g30_pais
		ELSE
			INITIALIZE r_g30.*, r_g25.*, r_g31.*,
					rm_r109.r109_divi_poli,
					rm_r109.r109_ciudad
				TO NULL
		END IF
		DISPLAY BY NAME r_g30.g30_nombre, rm_r109.r109_divi_poli,
				r_g25.g25_nombre, rm_r109.r109_ciudad,
				r_g31.g31_nombre
	AFTER FIELD r109_divi_poli
		LET rm_r109.r109_pais = GET_FLDBUF(r109_pais)
		IF rm_r109.r109_pais IS NULL THEN
			INITIALIZE r_g25.*, r_g31.*, rm_r109.r109_divi_poli,
					rm_r109.r109_ciudad
				TO NULL
			DISPLAY BY NAME rm_r109.r109_divi_poli,r_g25.g25_nombre,
					rm_r109.r109_ciudad, r_g31.g31_nombre
			CONTINUE CONSTRUCT
		END IF
		LET rm_r109.r109_divi_poli = GET_FLDBUF(r109_divi_poli)
		IF rm_r109.r109_divi_poli IS NOT NULL THEN
			CALL fl_lee_division_politica(rm_r109.r109_pais,
							rm_r109.r109_divi_poli)
				RETURNING r_g25.*
			IF r_g25.g25_divi_poli IS NULL THEN
				CALL fl_mostrar_mensaje('Esta division politica no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_divi_poli
			END IF
			LET rm_r109.r109_divi_poli = r_g25.g25_divi_poli
		ELSE
			INITIALIZE r_g25.*, r_g31.*, rm_r109.r109_divi_poli,
					rm_r109.r109_ciudad
				TO NULL
		END IF
		DISPLAY BY NAME rm_r109.r109_divi_poli, r_g25.g25_nombre,
				rm_r109.r109_ciudad, r_g31.g31_nombre
	AFTER FIELD r109_ciudad
		LET rm_r109.r109_divi_poli = GET_FLDBUF(r109_divi_poli)
		IF rm_r109.r109_divi_poli IS NULL THEN
			INITIALIZE r_g31.*, rm_r109.r109_ciudad TO NULL
			DISPLAY BY NAME rm_r109.r109_ciudad, r_g31.g31_nombre
			CONTINUE CONSTRUCT
		END IF
		LET rm_r109.r109_ciudad = GET_FLDBUF(r109_ciudad)
		IF rm_r109.r109_ciudad IS NOT NULL THEN
			CALL fl_lee_ciudad(rm_r109.r109_ciudad)
				RETURNING r_g31.*
			IF r_g31.g31_ciudad IS NULL THEN
				CALL fl_mostrar_mensaje('Esta ciudad no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_divi_poli
			END IF
			LET rm_r109.r109_ciudad = r_g31.g31_ciudad
		ELSE
			INITIALIZE r_g31.*, rm_r109.r109_ciudad TO NULL
		END IF
		DISPLAY BY NAME rm_r109.r109_ciudad, r_g31.g31_nombre
END CONSTRUCT
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept109 ',
		' WHERE r109_compania  = ', vg_codcia,
		'   AND r109_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r109.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_bloquear_activar()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)
DEFINE estado		LIKE rept109.r109_estado

CALL lee_muestra_registro(vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_bloact CURSOR FOR
	SELECT * FROM rept109
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
OPEN q_bloact
FETCH q_bloact INTO rm_r109.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de esta sub-zona. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
LET estado  = 'B'
LET mensaje = 'Seguro de BLOQUEAR'
IF rm_r109.r109_estado <> 'A' THEN
	LET mensaje = 'Seguro de ACTIVAR'
	LET estado  = 'A'
END IF
LET mensaje = mensaje CLIPPED, ' de este registro ?'
CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE rept109
	SET r109_estado = estado
	WHERE CURRENT OF q_bloact
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo BLOQUEAR/ACTIVAR el registro de esta sub-zona. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET mensaje = 'El registro ha sido ACTIVADO OK.'
IF rm_r109.r109_estado <> 'A' THEN
	LET mensaje = 'El registro ha sido BLOQUEADO OK.'
END IF
CALL fl_mostrar_mensaje(mensaje, 'info')

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



FUNCTION muestra_estado()
DEFINE tit_estado	VARCHAR(15)

LET tit_estado = NULL
CASE rm_r109.r109_estado
	WHEN 'A' LET tit_estado = 'ACTIVO'
	WHEN 'B' LET tit_estado = 'BLOQUEADO'
END CASE
DISPLAY BY NAME rm_r109.r109_estado, tit_estado

END FUNCTION



FUNCTION lee_cabecera(flag)
DEFINE flag		CHAR(1)
DEFINE r_g25		RECORD LIKE gent025.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_r108		RECORD LIKE rept108.*
DEFINE subzona		LIKE rept109.r109_cod_subzona
DEFINE resp		CHAR(6)

INITIALIZE r_g25.*, r_g30.*, r_g31.*, r_r108.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_r109.r109_cod_zona, rm_r109.r109_descripcion,rm_r109.r109_pais,
	rm_r109.r109_divi_poli, rm_r109.r109_ciudad, rm_r109.r109_horas_entr
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_r109.r109_cod_zona,rm_r109.r109_descripcion,
				 rm_r109.r109_pais, rm_r109.r109_divi_poli,
				 rm_r109.r109_ciudad, rm_r109.r109_horas_entr)
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
	ON KEY(F2)
		IF INFIELD(r109_cod_zona) AND flag = 'I' THEN
			CALL fl_ayuda_zonas(vg_codcia, vg_codloc, "A")
				RETURNING r_r108.r108_cod_zona,
					  r_r108.r108_descripcion
		      	IF r_r108.r108_cod_zona IS NOT NULL THEN
				LET rm_r109.r109_cod_zona = r_r108.r108_cod_zona
				DISPLAY BY NAME rm_r109.r109_cod_zona,
						r_r108.r108_descripcion
		      	END IF
		END IF
		IF INFIELD(r109_pais) THEN
			CALL fl_ayuda_pais()
				RETURNING r_g30.g30_pais, r_g30.g30_nombre
		      	IF r_g30.g30_pais IS NOT NULL THEN
				LET rm_r109.r109_pais = r_g30.g30_pais
				DISPLAY BY NAME rm_r109.r109_pais,
						r_g30.g30_nombre
		      	END IF
		END IF
		IF INFIELD(r109_divi_poli) AND r_g30.g30_pais IS NOT NULL THEN
			CALL fl_ayuda_division_politica(r_g30.g30_pais)
				RETURNING r_g25.g25_divi_poli, r_g25.g25_nombre
			IF r_g25.g25_divi_poli IS NOT NULL THEN
				LET rm_r109.r109_divi_poli = r_g25.g25_divi_poli
				DISPLAY BY NAME rm_r109.r109_divi_poli,
						r_g25.g25_nombre
			END IF
		END IF
		IF INFIELD(r109_ciudad) AND r_g25.g25_divi_poli IS NOT NULL THEN
			CALL fl_ayuda_ciudad(r_g30.g30_pais,r_g25.g25_divi_poli)
				RETURNING r_g31.g31_ciudad, r_g31.g31_nombre
			IF r_g31.g31_ciudad IS NOT NULL THEN
				LET rm_r109.r109_ciudad = r_g31.g31_ciudad
				DISPLAY BY NAME rm_r109.r109_ciudad,
						r_g31.g31_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD r109_cod_zona
		IF flag = 'M' THEN
			LET r_r108.r108_cod_zona = rm_r109.r109_cod_zona
		END IF
	AFTER FIELD r109_cod_zona
		IF flag = 'M' THEN
			LET rm_r109.r109_cod_zona = r_r108.r108_cod_zona
			DISPLAY BY NAME rm_r109.r109_cod_zona
			CONTINUE INPUT
		END IF
		IF rm_r109.r109_cod_zona IS NOT NULL THEN
			CALL fl_lee_zona(vg_codcia, vg_codloc,
						rm_r109.r109_cod_zona)
				RETURNING r_r108.*
			IF r_r108.r108_cod_zona IS NULL THEN
				CALL fl_mostrar_mensaje('Esta zona no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_cod_zona
			END IF
			IF r_r108.r108_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Esta zona esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r109_cod_zona
			END IF
		ELSE
			INITIALIZE r_r108.* TO NULL
		END IF
		DISPLAY BY NAME r_r108.r108_descripcion
	AFTER FIELD r109_descripcion
		IF rm_r109.r109_descripcion IS NOT NULL THEN
			LET subzona = NULL
			SELECT r109_cod_subzona
				INTO subzona
				FROM rept109
				WHERE r109_compania    = vg_codcia
				  AND r109_localidad   = vg_codloc
				  AND r109_descripcion =rm_r109.r109_descripcion
				  AND r109_estado      = 'A'
			IF (subzona IS NOT NULL AND
			   (rm_r109.r109_cod_subzona IS NULL OR
			    subzona <> rm_r109.r109_cod_subzona))
			THEN
				CALL fl_mostrar_mensaje('Ya existe esta descripción de Sub-Zona en la compañía.', 'exclamation')
				NEXT FIELD r109_descripcion
			END IF
		END IF
	AFTER FIELD r109_pais
		IF rm_r109.r109_pais IS NOT NULL THEN
			CALL fl_lee_pais(rm_r109.r109_pais) RETURNING r_g30.*
			IF r_g30.g30_pais IS NULL THEN
				CALL fl_mostrar_mensaje('Este pais no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_pais
			END IF
		ELSE
			INITIALIZE r_g30.*, r_g25.*, r_g31.*,
					rm_r109.r109_divi_poli,
					rm_r109.r109_ciudad
				TO NULL
		END IF
		DISPLAY BY NAME r_g30.g30_nombre, rm_r109.r109_divi_poli,
				r_g25.g25_nombre, rm_r109.r109_ciudad,
				r_g31.g31_nombre
	AFTER FIELD r109_divi_poli
		IF rm_r109.r109_pais IS NULL THEN
			INITIALIZE r_g25.*, r_g31.*, rm_r109.r109_divi_poli,
					rm_r109.r109_ciudad
				TO NULL
			DISPLAY BY NAME rm_r109.r109_divi_poli,r_g25.g25_nombre,
					rm_r109.r109_ciudad, r_g31.g31_nombre
			CONTINUE INPUT
		END IF
		IF rm_r109.r109_divi_poli IS NOT NULL THEN
			CALL fl_lee_division_politica(rm_r109.r109_pais,
							rm_r109.r109_divi_poli)
				RETURNING r_g25.*
			IF r_g25.g25_divi_poli IS NULL THEN
				CALL fl_mostrar_mensaje('Esta division politica no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_divi_poli
			END IF
		ELSE
			INITIALIZE r_g25.*, r_g31.*, rm_r109.r109_divi_poli,
					rm_r109.r109_ciudad
				TO NULL
		END IF
		DISPLAY BY NAME rm_r109.r109_divi_poli, r_g25.g25_nombre,
				rm_r109.r109_ciudad, r_g31.g31_nombre
	AFTER FIELD r109_ciudad
		IF rm_r109.r109_divi_poli IS NULL THEN
			INITIALIZE r_g31.*, rm_r109.r109_ciudad TO NULL
			DISPLAY BY NAME rm_r109.r109_ciudad, r_g31.g31_nombre
			CONTINUE INPUT
		END IF
		IF rm_r109.r109_ciudad IS NOT NULL THEN
			CALL fl_lee_ciudad(rm_r109.r109_ciudad)
				RETURNING r_g31.*
			IF r_g31.g31_ciudad IS NULL THEN
				CALL fl_mostrar_mensaje('Esta ciudad no existe en la compañía.', 'exclamation')
				NEXT FIELD r109_divi_poli
			END IF
		ELSE
			INITIALIZE r_g31.*, rm_r109.r109_ciudad TO NULL
		END IF
		DISPLAY BY NAME rm_r109.r109_ciudad, r_g31.g31_nombre
	AFTER INPUT
		IF rm_r109.r109_divi_poli IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la División Política.', 'exclamation')
			NEXT FIELD r109_divi_poli
		END IF
		IF rm_r109.r109_ciudad IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la Ciudad.', 'exclamation')
			NEXT FIELD r109_ciudad
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_salir()

IF vm_num_rows = 0 THEN
	CLEAR FORM
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_g25		RECORD LIKE gent025.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_r108		RECORD LIKE rept108.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r109.* FROM rept109 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
DISPLAY BY NAME rm_r109.r109_estado, rm_r109.r109_cod_zona,
		rm_r109.r109_cod_subzona, rm_r109.r109_descripcion,
		rm_r109.r109_pais, rm_r109.r109_divi_poli, rm_r109.r109_ciudad,
		rm_r109.r109_horas_entr, rm_r109.r109_usuario,
		rm_r109.r109_fecing
CALL fl_lee_zona(vg_codcia, vg_codloc, rm_r109.r109_cod_zona) RETURNING r_r108.*
CALL fl_lee_pais(rm_r109.r109_pais) RETURNING r_g30.*
CALL fl_lee_division_politica(rm_r109.r109_pais, rm_r109.r109_divi_poli)
	RETURNING r_g25.*
CALL fl_lee_ciudad(rm_r109.r109_ciudad) RETURNING r_g31.*
DISPLAY BY NAME r_r108.r108_descripcion, r_g30.g30_nombre, r_g25.g25_nombre,
		r_g31.g31_nombre
CALL muestra_estado()
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION
