--------------------------------------------------------------------------------
-- Titulo           : ctbp210.4gl - Mantenimiento de aux. cont. de integración
-- Elaboracion      : 10-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp210 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	VARCHAR(400)
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE rm_b40		RECORD LIKE ctbt040.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp210.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp210'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
LET vm_max_rows	= 1000
OPEN WINDOW w_ctbf210_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPEN FORM f_ctbf210_1 FROM "../forms/ctbf210_1"
DISPLAY FORM f_ctbf210_1
CALL fl_retorna_usuario()
MENU 'OPCIONES'
	COMMAND KEY('V') 'Ventas' 'Configuracion Contable Ventas.'
		CALL control_ctbt040()
	COMMAND KEY('C') 'Cobranzas' 'Configuracion Contable Cobranzas.'
		CALL control_ctbt041()
	COMMAND KEY('I') 'Impuestos' 'Configuracion Contable Impuestos.'
		CALL control_ctbt042()
	COMMAND KEY('T') 'Taller' 'Configuracion Contable Ventas Taller.'
		CALL control_ctbt043()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ctbt040()

INITIALIZE rm_b40.* TO NULL
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



FUNCTION control_ctbt041()
DEFINE comando		VARCHAR(250)

IF NOT fl_control_acceso_proceso_men(vg_usuario,vg_codcia, vg_modulo, 'ctbp211')
THEN
	RETURN
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; fglrun ctbp211 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia
RUN comando

END FUNCTION



FUNCTION control_ctbt042()
DEFINE comando		VARCHAR(250)

IF NOT fl_control_acceso_proceso_men(vg_usuario,vg_codcia, vg_modulo, 'ctbp212')
THEN
	RETURN
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; fglrun ctbp212 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia
RUN comando

END FUNCTION



FUNCTION control_ctbt043()
DEFINE comando		VARCHAR(250)

IF NOT fl_control_acceso_proceso_men(vg_usuario,vg_codcia, vg_modulo, 'ctbp213')
THEN
	RETURN
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; fglrun ctbp213 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia
RUN comando

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE resul		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g58		RECORD LIKE gent058.*

CLEAR FORM
LET vm_flag_mant = 'I'
LET num_aux = 0 
INITIALIZE rm_b40.* TO NULL
LET rm_b40.b40_compania   = vg_codcia
LET rm_b40.b40_localidad  = vg_codloc
LET rm_b40.b40_porc_impto = rg_gen.g00_porc_impto
CALL fl_lee_compania(rm_b40.b40_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b40.b40_compania, rm_b40.b40_localidad)
	RETURNING r_g02.*
CALL fl_lee_porc_impto(rm_b40.b40_compania, rm_b40.b40_localidad, 'I',
			rm_b40.b40_porc_impto, 'V')
	RETURNING r_g58.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
DISPLAY r_g58.g58_desc_impto  TO tit_porc_impto
CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL muestra_reg()
	END IF
	RETURN
END IF
INSERT INTO ctbt040 VALUES (rm_b40.*)
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
	SELECT * FROM ctbt040
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_b40.*
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
UPDATE ctbt040 SET * = rm_b40.* WHERE CURRENT OF q_up
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
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g58		RECORD LIKE gent058.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad

CLEAR FORM
LET codcia   = vg_codcia
LET codloc   = vg_codloc
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b40_compania, b40_localidad, b40_modulo,
	b40_bodega, b40_grupo_linea, b40_porc_impto, b40_venta, b40_descuento,
	b40_dev_venta, b40_costo_venta, b40_dev_costo, b40_inventario,
	b40_transito, b40_ajustes, b40_flete
	ON KEY(F2)
		IF INFIELD(b40_compania) THEN
			CALL fl_ayuda_compania() RETURNING r_g01.g01_compania
			IF r_g01.g01_compania IS NOT NULL THEN
				CALL fl_lee_compania(r_g01.g01_compania)
					RETURNING r_g01.*
				DISPLAY r_g01.g01_compania    TO b40_compania
				DISPLAY r_g01.g01_razonsocial TO tit_compania
			END IF
		END IF
		IF INFIELD(b40_localidad) THEN
			CALL fl_ayuda_localidad(codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02.g02_localidad TO b40_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
		END IF
		IF INFIELD(b40_modulo) THEN
			CALL fl_ayuda_modulos()
				RETURNING r_g50.g50_modulo, r_g50.g50_nombre
			IF r_g50.g50_modulo IS NOT NULL THEN
				DISPLAY r_g50.g50_modulo TO b40_modulo
				DISPLAY r_g50.g50_nombre TO tit_modulo
			END IF
		END IF
		IF INFIELD(b40_bodega) THEN
			CALL fl_ayuda_bodegas_rep(codcia, 'T', 'T', 'T','A','T')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				DISPLAY r_r02.r02_codigo TO b40_bodega
				DISPLAY r_r02.r02_nombre TO tit_bodega
			END IF
		END IF
		IF INFIELD(b40_grupo_linea) THEN
			CALL fl_ayuda_grupo_lineas(codcia)
				RETURNING r_g20.g20_grupo_linea,r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				DISPLAY r_g20.g20_grupo_linea TO b40_grupo_linea
				DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
			END IF 
		END IF
		IF INFIELD(b40_porc_impto) THEN
			CALL fl_ayuda_porc_impto(codcia, codloc, 'T', 'I', 'V')
				RETURNING r_g58.g58_porc_impto,
					  r_g58.g58_desc_impto
			IF r_g58.g58_porc_impto IS NOT NULL THEN
				DISPLAY r_g58.g58_porc_impto TO b40_porc_impto
				DISPLAY r_g58.g58_desc_impto TO tit_porc_impto
			END IF
		END IF
		IF INFIELD(b40_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_venta
				DISPLAY r_b10.b10_descripcion TO tit_venta
			END IF
		END IF
		IF INFIELD(b40_descuento) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_descuento
				DISPLAY r_b10.b10_descripcion TO tit_descuento
			END IF
		END IF
		IF INFIELD(b40_dev_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_dev_venta
				DISPLAY r_b10.b10_descripcion TO tit_dev_venta
			END IF
		END IF
		IF INFIELD(b40_costo_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_costo_venta
				DISPLAY r_b10.b10_descripcion TO tit_costo_venta
			END IF
		END IF
		IF INFIELD(b40_dev_costo) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_dev_costo
				DISPLAY r_b10.b10_descripcion TO tit_dev_costo
			END IF
		END IF
		IF INFIELD(b40_inventario) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_inventario
				DISPLAY r_b10.b10_descripcion TO tit_inventario
			END IF
		END IF
		IF INFIELD(b40_transito) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_transito
				DISPLAY r_b10.b10_descripcion TO tit_transito
			END IF
		END IF
		IF INFIELD(b40_ajustes) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_ajustes
				DISPLAY r_b10.b10_descripcion TO tit_ajustes
			END IF
		END IF
		IF INFIELD(b40_flete) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b40_flete
				DISPLAY r_b10.b10_descripcion TO tit_flete
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD b40_compania
		LET codcia = NULL
		LET codcia = GET_FLDBUF(b40_compania)
		IF codcia IS NULL THEN
			LET codcia = vg_codcia
		END IF
	AFTER FIELD b40_localidad
		LET codloc = NULL
		LET codloc = GET_FLDBUF(b40_localidad)
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
LET query = 'SELECT *, ROWID FROM ctbt040 ',
		' WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3, 4, 5, 6 '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_b40.*, num_reg
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
DEFINE r_b40		RECORD LIKE ctbt040.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g58		RECORD LIKE gent058.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE codcia		LIKE gent001.g01_compania

LET codcia   = vg_codcia
LET int_flag = 0
INPUT BY NAME rm_b40.b40_compania, rm_b40.b40_localidad, rm_b40.b40_modulo,
	rm_b40.b40_bodega, rm_b40.b40_grupo_linea, rm_b40.b40_porc_impto,
	rm_b40.b40_venta, rm_b40.b40_descuento, rm_b40.b40_dev_venta,
	rm_b40.b40_costo_venta, rm_b40.b40_dev_costo, rm_b40.b40_inventario,
	rm_b40.b40_transito, rm_b40.b40_ajustes, rm_b40.b40_flete
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_b40.b40_compania, rm_b40.b40_localidad,
				 rm_b40.b40_modulo, rm_b40.b40_bodega,
				 rm_b40.b40_grupo_linea, rm_b40.b40_porc_impto,
				 rm_b40.b40_venta, rm_b40.b40_descuento,
				 rm_b40.b40_dev_venta, rm_b40.b40_costo_venta,
				 rm_b40.b40_dev_costo, rm_b40.b40_inventario,
				 rm_b40.b40_transito, rm_b40.b40_ajustes,
				 rm_b40.b40_flete)
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
			IF INFIELD(b40_compania) THEN
				CALL fl_ayuda_compania()
					RETURNING r_g01.g01_compania
				IF r_g01.g01_compania IS NOT NULL THEN
					CALL fl_lee_compania(r_g01.g01_compania)
						RETURNING r_g01.*
					LET rm_b40.b40_compania =
							r_g01.g01_compania
					LET codcia = rm_b40.b40_compania
					DISPLAY r_g01.g01_compania
						TO b40_compania
					DISPLAY r_g01.g01_razonsocial
						TO tit_compania
				END IF
			END IF
			IF INFIELD(b40_localidad) THEN
				CALL fl_ayuda_localidad(codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_b40.b40_localidad =
							r_g02.g02_localidad
					DISPLAY r_g02.g02_localidad
						TO b40_localidad
					DISPLAY r_g02.g02_nombre
						TO tit_localidad
				END IF
			END IF
			IF INFIELD(b40_modulo) THEN
				CALL fl_ayuda_modulos()
					RETURNING r_g50.g50_modulo,
						  r_g50.g50_nombre
				IF r_g50.g50_modulo IS NOT NULL THEN
					LET rm_b40.b40_modulo = r_g50.g50_modulo
					DISPLAY r_g50.g50_modulo TO b40_modulo
					DISPLAY r_g50.g50_nombre TO tit_modulo
				END IF
			END IF
			IF INFIELD(b40_bodega) THEN
				CALL fl_ayuda_bodegas_rep(codcia, 'T', 'T', 'T',
							'A', 'T')
					RETURNING r_r02.r02_codigo,
						  r_r02.r02_nombre
				IF r_r02.r02_codigo IS NOT NULL THEN
					LET rm_b40.b40_bodega = r_r02.r02_codigo
					DISPLAY r_r02.r02_codigo TO b40_bodega
					DISPLAY r_r02.r02_nombre TO tit_bodega
				END IF
			END IF
			IF INFIELD(b40_grupo_linea) THEN
				CALL fl_ayuda_grupo_lineas(codcia)
					RETURNING r_g20.g20_grupo_linea,
						  r_g20.g20_nombre
				IF r_g20.g20_grupo_linea IS NOT NULL THEN
					LET rm_b40.b40_grupo_linea =
							r_g20.g20_grupo_linea
					DISPLAY r_g20.g20_grupo_linea
						TO b40_grupo_linea
					DISPLAY r_g20.g20_nombre
						TO tit_grupo_linea
				END IF 
			END IF
			IF INFIELD(b40_porc_impto) THEN
				CALL fl_ayuda_porc_impto(codcia,
						rm_b40.b40_localidad, 'A', 'I',
						'V')
					RETURNING r_g58.g58_porc_impto,
						  r_g58.g58_desc_impto
				IF r_g58.g58_porc_impto IS NOT NULL THEN
					LET rm_b40.b40_porc_impto =
							r_g58.g58_porc_impto
					DISPLAY r_g58.g58_porc_impto
						TO b40_porc_impto
					DISPLAY r_g58.g58_desc_impto
						TO tit_porc_impto
				END IF
			END IF
		END IF
		IF INFIELD(b40_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_venta = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_venta
				DISPLAY r_b10.b10_descripcion TO tit_venta
			END IF
		END IF
		IF INFIELD(b40_descuento) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_descuento = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_descuento
				DISPLAY r_b10.b10_descripcion TO tit_descuento
			END IF
		END IF
		IF INFIELD(b40_dev_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_dev_venta = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_dev_venta
				DISPLAY r_b10.b10_descripcion TO tit_dev_venta
			END IF
		END IF
		IF INFIELD(b40_costo_venta) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_costo_venta = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_costo_venta
				DISPLAY r_b10.b10_descripcion TO tit_costo_venta
			END IF
		END IF
		IF INFIELD(b40_dev_costo) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_dev_costo = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_dev_costo
				DISPLAY r_b10.b10_descripcion TO tit_dev_costo
			END IF
		END IF
		IF INFIELD(b40_inventario) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_inventario = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_inventario
				DISPLAY r_b10.b10_descripcion TO tit_inventario
			END IF
		END IF
		IF INFIELD(b40_transito) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_transito = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_transito
				DISPLAY r_b10.b10_descripcion TO tit_transito
			END IF
		END IF
		IF INFIELD(b40_ajustes) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_ajustes = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_ajustes
				DISPLAY r_b10.b10_descripcion TO tit_ajustes
			END IF
		END IF
		IF INFIELD(b40_flete) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b40.b40_flete = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b40_flete
				DISPLAY r_b10.b10_descripcion TO tit_flete
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD b40_compania
		IF vm_flag_mant = 'M' THEN
			LET codcia = rm_b40.b40_compania
		END IF
	BEFORE FIELD b40_localidad
		IF vm_flag_mant = 'M' THEN
			LET r_g02.g02_localidad = rm_b40.b40_localidad
		END IF
	BEFORE FIELD b40_modulo
		IF vm_flag_mant = 'M' THEN
			LET r_g50.g50_modulo = rm_b40.b40_modulo
		END IF
	BEFORE FIELD b40_bodega
		IF vm_flag_mant = 'M' THEN
			LET r_r02.r02_codigo = rm_b40.b40_bodega
		END IF
	BEFORE FIELD b40_grupo_linea
		IF vm_flag_mant = 'M' THEN
			LET r_g20.g20_grupo_linea = rm_b40.b40_grupo_linea
		END IF
	BEFORE FIELD b40_porc_impto
		IF vm_flag_mant = 'M' THEN
			LET r_g58.g58_porc_impto = rm_b40.b40_porc_impto
		END IF
	AFTER FIELD b40_compania
		IF vm_flag_mant = 'M' THEN
			LET rm_b40.b40_compania = codcia
			CALL fl_lee_compania(rm_b40.b40_compania)
				RETURNING r_g01.*
			DISPLAY r_g01.g01_compania    TO b40_compania
			DISPLAY r_g01.g01_razonsocial TO tit_compania
			CONTINUE INPUT
		END IF
		IF rm_b40.b40_compania IS NULL THEN
			LET rm_b40.b40_compania = vg_codcia
		END IF
		CALL fl_lee_compania(rm_b40.b40_compania) RETURNING r_g01.*
		IF r_g01.g01_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esa compania.', 'exclamation')
			NEXT FIELD b40_compania
		END IF
		DISPLAY r_g01.g01_razonsocial TO tit_compania
		IF r_g01.g01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b40_compania
		END IF
	AFTER FIELD b40_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_b40.b40_localidad = r_g02.g02_localidad
			CALL fl_lee_localidad(rm_b40.b40_compania,
						rm_b40.b40_localidad)
				RETURNING r_g02.*
			DISPLAY r_g02.g02_localidad TO b40_localidad
			DISPLAY r_g02.g02_nombre    TO tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_b40.b40_localidad IS NULL THEN
			LET rm_b40.b40_localidad = vg_codloc
		END IF
		CALL fl_lee_localidad(rm_b40.b40_compania, rm_b40.b40_localidad)
			RETURNING r_g02.*
		IF r_g02.g02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
			NEXT FIELD b40_localidad
		END IF
		DISPLAY r_g02.g02_nombre TO tit_localidad
		IF r_g02.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b40_localidad
		END IF
	AFTER FIELD b40_modulo
		IF vm_flag_mant = 'M' THEN
			LET rm_b40.b40_modulo = r_g50.g50_modulo
			CALL fl_lee_modulo(rm_b40.b40_modulo) RETURNING r_g50.*
			DISPLAY r_g50.g50_modulo TO b40_modulo
			DISPLAY r_g50.g50_nombre TO tit_modulo
			CONTINUE INPUT
		END IF
		IF rm_b40.b40_modulo IS NOT NULL THEN
			CALL fl_lee_modulo(rm_b40.b40_modulo) RETURNING r_g50.*
			IF r_g50.g50_modulo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este modulo.', 'exclamation')
				NEXT FIELD b40_modulo
			END IF
			DISPLAY r_g50.g50_nombre TO tit_modulo
			IF r_g50.g50_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b40_modulo
			END IF
		ELSE
			CLEAR tit_modulo
		END IF
	AFTER FIELD b40_bodega
		IF vm_flag_mant = 'M' THEN
			LET rm_b40.b40_bodega = r_r02.r02_codigo
			CALL fl_lee_bodega_rep(rm_b40.b40_compania,
						rm_b40.b40_bodega)
				RETURNING r_r02.*
			DISPLAY r_r02.r02_codigo TO b40_bodega
			DISPLAY r_r02.r02_nombre TO tit_bodega
			CONTINUE INPUT
		END IF
		IF rm_b40.b40_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(rm_b40.b40_compania,
						rm_b40.b40_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta bodega.', 'exclamation')
				NEXT FIELD b40_bodega
			END IF
			DISPLAY r_r02.r02_nombre TO tit_bodega
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b40_bodega
			END IF
			IF r_r02.r02_area = 'T' THEN
				CONTINUE INPUT
			END IF
			IF r_r02.r02_area <> 'R' THEN
				CALL fl_mostrar_mensaje('Esta bodega no es de INVENTARIO.', 'exclamation')
				NEXT FIELD b40_bodega
			END IF
			IF r_r02.r02_factura <> 'S' THEN
				CALL fl_mostrar_mensaje('Esta bodega no es de FACTURACION.', 'exclamation')
				--NEXT FIELD b40_bodega
			END IF
			IF r_r02.r02_tipo = 'L' THEN
				CALL fl_mostrar_mensaje('Esta bodega es LOGICA.', 'exclamation')
				NEXT FIELD b40_bodega
			END IF
		ELSE
			CLEAR tit_bodega
		END IF
	AFTER FIELD b40_grupo_linea
		IF vm_flag_mant = 'M' THEN
			LET rm_b40.b40_grupo_linea = r_g20.g20_grupo_linea
			CALL fl_lee_grupo_linea(rm_b40.b40_compania,
						rm_b40.b40_grupo_linea)
				RETURNING r_g20.*
			DISPLAY r_g20.g20_grupo_linea TO b40_grupo_linea
			DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
			CONTINUE INPUT
		END IF
		IF rm_b40.b40_grupo_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(rm_b40.b40_compania,
						rm_b40.b40_grupo_linea)
				RETURNING r_g20.*
			IF r_g20.g20_grupo_linea IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este grupo de linea.', 'exclamation')
				NEXT FIELD b40_grupo_linea
			END IF
			DISPLAY r_g20.g20_nombre TO tit_grupo_linea
		ELSE
			CLEAR tit_grupo_linea
		END IF
	AFTER FIELD b40_porc_impto
		IF vm_flag_mant = 'M' THEN
			LET rm_b40.b40_porc_impto = r_g58.g58_porc_impto
			CALL fl_lee_porc_impto(rm_b40.b40_compania,
						rm_b40.b40_localidad, 'I',
						rm_b40.b40_porc_impto, 'V')
				RETURNING r_g58.*
			DISPLAY r_g58.g58_porc_impto TO b40_porc_impto
			DISPLAY r_g58.g58_desc_impto TO tit_porc_impto
			CONTINUE INPUT
		END IF
		IF rm_b40.b40_porc_impto IS NOT NULL THEN
			CALL fl_lee_porc_impto(rm_b40.b40_compania,
						rm_b40.b40_localidad, 'I',
						rm_b40.b40_porc_impto, 'V')
				RETURNING r_g58.*
			IF r_g58.g58_porc_impto IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este impuesto.', 'exclamation')
				NEXT FIELD b40_porc_impto
			END IF
			DISPLAY r_g58.g58_desc_impto TO tit_porc_impto
			IF r_g58.g58_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b40_porc_impto
			END IF
			IF r_g58.g58_tipo_impto <> 'I' THEN
				CALL fl_mostrar_mensaje('El tipo de impuesto debe ser IVA.', 'exclamation')
				NEXT FIELD b40_porc_impto
			END IF
			IF r_g58.g58_tipo <> 'V' THEN
				CALL fl_mostrar_mensaje('El tipo debe ser VENTA.', 'exclamation')
				NEXT FIELD b40_porc_impto
			END IF
		ELSE
			CLEAR tit_porc_impto
		END IF
	AFTER FIELD b40_venta
                IF rm_b40.b40_venta IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_venta, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_venta
			END IF
		ELSE
			CLEAR tit_venta
                END IF
	AFTER FIELD b40_descuento
                IF rm_b40.b40_descuento IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_descuento, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_descuento
			END IF
		ELSE
			CLEAR tit_descuento
                END IF
	AFTER FIELD b40_dev_venta
                IF rm_b40.b40_dev_venta IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_dev_venta, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_dev_venta
			END IF
		ELSE
			CLEAR tit_dev_venta
                END IF
	AFTER FIELD b40_costo_venta
                IF rm_b40.b40_costo_venta IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_costo_venta, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_costo_venta
			END IF
		ELSE
			CLEAR tit_costo_venta
                END IF
	AFTER FIELD b40_dev_costo
                IF rm_b40.b40_dev_costo IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_dev_costo, 5)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_dev_costo
			END IF
		ELSE
			CLEAR tit_dev_costo
                END IF
	AFTER FIELD b40_inventario
                IF rm_b40.b40_inventario IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_inventario, 6)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_inventario
			END IF
		ELSE
			CLEAR tit_inventario
                END IF
	AFTER FIELD b40_transito
                IF rm_b40.b40_transito IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_transito, 7)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_transito
			END IF
		ELSE
			CLEAR tit_transito
                END IF
	AFTER FIELD b40_ajustes
                IF rm_b40.b40_ajustes IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_ajustes, 8)
				RETURNING resul
			IF resul = 1 THEN
				CLEAR tit_ajustes
				--NEXT FIELD b40_ajustes
			END IF
		ELSE
			CLEAR tit_ajustes
                END IF
	AFTER FIELD b40_flete
                IF rm_b40.b40_flete IS NOT NULL THEN
			CALL validar_cuenta(rm_b40.b40_flete, 9)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b40_flete
			END IF
		ELSE
			CLEAR tit_flete
                END IF
	AFTER INPUT
		IF vm_flag_mant <> 'I' THEN
			EXIT INPUT
		END IF
		INITIALIZE r_b40.* TO NULL
		SELECT * INTO r_b40.*
			FROM ctbt040
			WHERE b40_compania    = rm_b40.b40_compania
			  AND b40_localidad   = rm_b40.b40_localidad
			  AND b40_modulo      = rm_b40.b40_modulo
			  AND b40_bodega      = rm_b40.b40_bodega
			  AND b40_grupo_linea = rm_b40.b40_grupo_linea
			  AND b40_porc_impto  = rm_b40.b40_porc_impto
		IF r_b40.b40_compania IS NOT NULL THEN
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
	WHEN 1 DISPLAY r_b10.b10_descripcion TO tit_venta
	WHEN 2 DISPLAY r_b10.b10_descripcion TO tit_descuento
	WHEN 3 DISPLAY r_b10.b10_descripcion TO tit_dev_venta
	WHEN 4 DISPLAY r_b10.b10_descripcion TO tit_costo_venta
	WHEN 5 DISPLAY r_b10.b10_descripcion TO tit_dev_costo
	WHEN 6 DISPLAY r_b10.b10_descripcion TO tit_inventario
	WHEN 7 DISPLAY r_b10.b10_descripcion TO tit_transito
	WHEN 8 DISPLAY r_b10.b10_descripcion TO tit_ajustes
	WHEN 9 DISPLAY r_b10.b10_descripcion TO tit_flete
END CASE
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_b10.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del último.', 'exclamation')
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
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g58		RECORD LIKE gent058.*
DEFINE r_r02		RECORD LIKE rept002.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_b40.* FROM ctbt040 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_b40.*
CALL fl_lee_compania(rm_b40.b40_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b40.b40_compania, rm_b40.b40_localidad)
	RETURNING r_g02.*
CALL fl_lee_porc_impto(rm_b40.b40_compania, rm_b40.b40_localidad, 'I',
			rm_b40.b40_porc_impto, 'V')
	RETURNING r_g58.*
CALL fl_lee_modulo(rm_b40.b40_modulo) RETURNING r_g50.*
CALL fl_lee_bodega_rep(rm_b40.b40_compania, rm_b40.b40_bodega) RETURNING r_r02.*
CALL fl_lee_grupo_linea(rm_b40.b40_compania, rm_b40.b40_grupo_linea)
	RETURNING r_g20.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
DISPLAY r_g58.g58_desc_impto  TO tit_porc_impto
DISPLAY r_g50.g50_nombre      TO tit_modulo
DISPLAY r_r02.r02_nombre      TO tit_bodega
DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_venta) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_venta
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_descuento) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_descuento
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_dev_venta) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dev_venta
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_costo_venta) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_costo_venta
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_dev_costo) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dev_costo
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_inventario) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_inventario
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_transito) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_transito
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_ajustes) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_ajustes
CALL fl_lee_cuenta(vg_codcia, rm_b40.b40_flete) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_flete

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION
