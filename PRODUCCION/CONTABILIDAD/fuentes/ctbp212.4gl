--------------------------------------------------------------------------------
-- Titulo           : ctbp212.4gl - Mantenimiento de aux. cont. de impuestos
-- Elaboracion      : 03-Ago-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp212 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b42		RECORD LIKE ctbt042.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp212.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp212'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW w_ctbf212_1 AT 3,2 WITH 19 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPEN FORM f_ctbf212_1 FROM "../forms/ctbf212_1"
DISPLAY FORM f_ctbf212_1
INITIALIZE rm_b42.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
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
	COMMAND KEY('S') 'Salir' 'Salir al menu anterior. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE resul		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

CLEAR FORM
CALL fl_retorna_usuario()
LET vm_flag_mant = 'I'
LET num_aux = 0 
INITIALIZE rm_b42.* TO NULL
LET rm_b42.b42_compania   = vg_codcia
LET rm_b42.b42_localidad  = vg_codloc
CALL fl_lee_compania(rm_b42.b42_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b42.b42_compania, rm_b42.b42_localidad)
	RETURNING r_g02.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL muestra_reg()
	END IF
	RETURN
END IF
INSERT INTO ctbt042 VALUES (rm_b42.*)
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
LET vm_row_current         = vm_num_rows
CALL muestra_reg()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM ctbt042
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_b42.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET vm_flag_mant = 'M'
CALL leer_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_reg()
	RETURN
END IF
UPDATE ctbt042 SET * = rm_b42.* WHERE CURRENT OF q_up
COMMIT WORK
CALL muestra_reg()
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(1500)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad

CLEAR FORM
LET codcia   = vg_codcia
LET codloc   = vg_codloc
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b42_compania, b42_localidad, b42_iva_venta,
	b42_iva_compra, b42_iva_import, b42_retencion, b42_reten_cred,
	b42_flete_comp, b42_otros_comp, b42_cuadre
	ON KEY(F2)
		IF INFIELD(b42_compania) THEN
			CALL fl_ayuda_compania() RETURNING r_g01.g01_compania
			IF r_g01.g01_compania IS NOT NULL THEN
				CALL fl_lee_compania(r_g01.g01_compania)
					RETURNING r_g01.*
				DISPLAY r_g01.g01_compania    TO b42_compania
				DISPLAY r_g01.g01_razonsocial TO tit_compania
			END IF
		END IF
		IF INFIELD(b42_localidad) THEN
			CALL fl_ayuda_localidad(codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02.g02_localidad TO b42_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
		END IF
		IF INFIELD(b42_iva_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_iva_venta
				DISPLAY r_b10.b10_descripcion TO tit_iva_venta
			END IF
		END IF
		IF INFIELD(b42_iva_compra) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_iva_compra
				DISPLAY r_b10.b10_descripcion TO tit_iva_compra
			END IF
		END IF
		IF INFIELD(b42_iva_import) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_iva_import
				DISPLAY r_b10.b10_descripcion TO tit_iva_import
			END IF
		END IF
		IF INFIELD(b42_retencion) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_retencion
				DISPLAY r_b10.b10_descripcion TO tit_retencion
			END IF
		END IF
		IF INFIELD(b42_reten_cred) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_reten_cred
				DISPLAY r_b10.b10_descripcion TO tit_reten_cred
			END IF
		END IF
		IF INFIELD(b42_flete_comp) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_flete_comp
				DISPLAY r_b10.b10_descripcion TO tit_flete_comp
			END IF
		END IF
		IF INFIELD(b42_otros_comp) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_otros_comp
				DISPLAY r_b10.b10_descripcion TO tit_otros_comp
			END IF
		END IF
		IF INFIELD(b42_cuadre) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b42_cuadre
				DISPLAY r_b10.b10_descripcion TO tit_cuadre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD b42_compania
		LET codcia = NULL
		LET codcia = GET_FLDBUF(b42_compania)
		IF codcia IS NULL THEN
			LET codcia = vg_codcia
		END IF
	AFTER FIELD b42_localidad
		LET codloc = NULL
		LET codloc = GET_FLDBUF(b42_localidad)
		IF codloc IS NULL THEN
			LET codloc = vg_codloc
		END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL muestra_reg()
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ctbt042 ',
		' WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2 '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_b42.*, num_reg
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
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET vm_row_current = 1
CALL muestra_reg()

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE codcia		LIKE gent001.g01_compania

LET codcia   = vg_codcia
LET int_flag = 0
INPUT BY NAME rm_b42.b42_compania, rm_b42.b42_localidad, rm_b42.b42_iva_venta,
	rm_b42.b42_iva_compra, rm_b42.b42_iva_import, rm_b42.b42_retencion,
	rm_b42.b42_reten_cred, rm_b42.b42_flete_comp, rm_b42.b42_otros_comp,
	rm_b42.b42_cuadre
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_b42.b42_compania, rm_b42.b42_localidad,
				 rm_b42.b42_iva_venta, rm_b42.b42_iva_compra,
				 rm_b42.b42_iva_import, rm_b42.b42_retencion,
				 rm_b42.b42_reten_cred, rm_b42.b42_flete_comp,
				 rm_b42.b42_otros_comp, rm_b42.b42_cuadre)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF vm_flag_mant = 'I' THEN
			IF INFIELD(b42_compania) THEN
				CALL fl_ayuda_compania()
					RETURNING r_g01.g01_compania
				IF r_g01.g01_compania IS NOT NULL THEN
					CALL fl_lee_compania(r_g01.g01_compania)
						RETURNING r_g01.*
					LET rm_b42.b42_compania =
							r_g01.g01_compania
					LET codcia = rm_b42.b42_compania
					DISPLAY r_g01.g01_compania
						TO b42_compania
					DISPLAY r_g01.g01_razonsocial
						TO tit_compania
				END IF
			END IF
			IF INFIELD(b42_localidad) THEN
				CALL fl_ayuda_localidad(codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_b42.b42_localidad =
							r_g02.g02_localidad
					DISPLAY r_g02.g02_localidad
						TO b42_localidad
					DISPLAY r_g02.g02_nombre
						TO tit_localidad
				END IF
			END IF
		END IF
		IF INFIELD(b42_iva_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_iva_venta = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_iva_venta
				DISPLAY r_b10.b10_descripcion TO tit_iva_venta
			END IF
		END IF
		IF INFIELD(b42_iva_compra) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_iva_compra = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_iva_compra
				DISPLAY r_b10.b10_descripcion TO tit_iva_compra
			END IF
		END IF
		IF INFIELD(b42_iva_import) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_iva_import = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_iva_import
				DISPLAY r_b10.b10_descripcion TO tit_iva_import
			END IF
		END IF
		IF INFIELD(b42_retencion) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_retencion = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_retencion
				DISPLAY r_b10.b10_descripcion TO tit_retencion
			END IF
		END IF
		IF INFIELD(b42_reten_cred) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_reten_cred = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_reten_cred
				DISPLAY r_b10.b10_descripcion TO tit_reten_cred
			END IF
		END IF
		IF INFIELD(b42_flete_comp) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_flete_comp = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_flete_comp
				DISPLAY r_b10.b10_descripcion TO tit_flete_comp
			END IF
		END IF
		IF INFIELD(b42_otros_comp) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_otros_comp = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_otros_comp
				DISPLAY r_b10.b10_descripcion TO tit_otros_comp
			END IF
		END IF
		IF INFIELD(b42_cuadre) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b42.b42_cuadre = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b42_cuadre
				DISPLAY r_b10.b10_descripcion TO tit_cuadre
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD b42_compania
		IF vm_flag_mant = 'M' THEN
			LET codcia = rm_b42.b42_compania
		END IF
	BEFORE FIELD b42_localidad
		IF vm_flag_mant = 'M' THEN
			LET r_g02.g02_localidad = rm_b42.b42_localidad
		END IF
	AFTER FIELD b42_compania
		IF vm_flag_mant = 'M' THEN
			LET rm_b42.b42_compania = codcia
			CALL fl_lee_compania(rm_b42.b42_compania)
				RETURNING r_g01.*
			DISPLAY r_g01.g01_compania    TO b42_compania
			DISPLAY r_g01.g01_razonsocial TO tit_compania
			CONTINUE INPUT
		END IF
		IF rm_b42.b42_compania IS NULL THEN
			LET rm_b42.b42_compania = vg_codcia
		END IF
		CALL fl_lee_compania(rm_b42.b42_compania) RETURNING r_g01.*
		IF r_g01.g01_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esa compania.', 'exclamation')
			NEXT FIELD b42_compania
		END IF
		DISPLAY r_g01.g01_razonsocial TO tit_compania
		IF r_g01.g01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b42_compania
		END IF
	AFTER FIELD b42_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_b42.b42_localidad = r_g02.g02_localidad
			CALL fl_lee_localidad(rm_b42.b42_compania,
						rm_b42.b42_localidad)
				RETURNING r_g02.*
			DISPLAY r_g02.g02_localidad TO b42_localidad
			DISPLAY r_g02.g02_nombre    TO tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_b42.b42_localidad IS NULL THEN
			LET rm_b42.b42_localidad = vg_codloc
		END IF
		CALL fl_lee_localidad(rm_b42.b42_compania, rm_b42.b42_localidad)
			RETURNING r_g02.*
		IF r_g02.g02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
			NEXT FIELD b42_localidad
		END IF
		DISPLAY r_g02.g02_nombre TO tit_localidad
		IF r_g02.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b42_localidad
		END IF
	AFTER FIELD b42_iva_venta
                IF rm_b42.b42_iva_venta IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_iva_venta, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_iva_venta
			END IF
		ELSE
			CLEAR tit_iva_venta
                END IF
	AFTER FIELD b42_iva_compra
                IF rm_b42.b42_iva_compra IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_iva_compra, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_iva_compra
			END IF
		ELSE
			CLEAR tit_iva_compra
                END IF
	AFTER FIELD b42_iva_import
                IF rm_b42.b42_iva_import IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_iva_import, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_iva_import
			END IF
		ELSE
			CLEAR tit_iva_import
                END IF
	AFTER FIELD b42_retencion
                IF rm_b42.b42_retencion IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_retencion, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_retencion
			END IF
		ELSE
			CLEAR tit_retencion
                END IF
	AFTER FIELD b42_reten_cred
                IF rm_b42.b42_reten_cred IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_reten_cred, 5)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_reten_cred
			END IF
		ELSE
			CLEAR tit_reten_cred
                END IF
	AFTER FIELD b42_flete_comp
                IF rm_b42.b42_flete_comp IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_flete_comp, 6)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_flete_comp
			END IF
		ELSE
			CLEAR tit_flete_comp
                END IF
	AFTER FIELD b42_otros_comp
                IF rm_b42.b42_otros_comp IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_otros_comp, 7)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_otros_comp
			END IF
		ELSE
			CLEAR tit_otros_comp
                END IF
	AFTER FIELD b42_cuadre
                IF rm_b42.b42_cuadre IS NOT NULL THEN
			CALL validar_cuenta(rm_b42.b42_cuadre, 8)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b42_cuadre
			END IF
		ELSE
			CLEAR tit_cuadre
                END IF
	AFTER INPUT
		IF vm_flag_mant <> 'I' THEN
			EXIT INPUT
		END IF
		INITIALIZE r_b42.* TO NULL
		SELECT * INTO r_b42.*
			FROM ctbt042
			WHERE b42_compania    = rm_b42.b42_compania
			  AND b42_localidad   = rm_b42.b42_localidad
		IF r_b42.b42_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Esta configuracion contable ya existe.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_b10            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_b10.*
IF r_b10.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1 DISPLAY r_b10.b10_descripcion TO tit_iva_venta
	WHEN 2 DISPLAY r_b10.b10_descripcion TO tit_iva_compra
	WHEN 3 DISPLAY r_b10.b10_descripcion TO tit_iva_import
	WHEN 4 DISPLAY r_b10.b10_descripcion TO tit_retencion
	WHEN 5 DISPLAY r_b10.b10_descripcion TO tit_reten_cred
	WHEN 6 DISPLAY r_b10.b10_descripcion TO tit_flete_comp
	WHEN 7 DISPLAY r_b10.b10_descripcion TO tit_otros_comp
	WHEN 8 DISPLAY r_b10.b10_descripcion TO tit_cuadre
END CASE
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_b10.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY row_current TO vm_row_current
DISPLAY num_rows    TO vm_num_rows
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_b42.* FROM ctbt042 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_b42.*
CALL fl_lee_compania(rm_b42.b42_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b42.b42_compania, rm_b42.b42_localidad)
	RETURNING r_g02.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_iva_venta) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_iva_venta
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_iva_compra) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_iva_compra
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_iva_import) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_iva_import
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_retencion) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_retencion
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_reten_cred) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_reten_cred
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_flete_comp) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_flete_comp
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_otros_comp) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_otros_comp
CALL fl_lee_cuenta(vg_codcia, rm_b42.b42_cuadre) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cuadre

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION
