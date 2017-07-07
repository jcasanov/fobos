-------------------------------------------------------------------------------
-- Titulo           : ctbp213.4gl - Mantenimiento de aux. cont. vta. taller
-- Elaboracion      : 03-Ago-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp213 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	VARCHAR(400)
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE rm_b43		RECORD LIKE ctbt043.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp213.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp213'
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
OPEN WINDOW w_ctbf213_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPEN FORM f_ctbf213_1 FROM "../forms/ctbf213_1"
DISPLAY FORM f_ctbf213_1
INITIALIZE rm_b43.* TO NULL
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
DEFINE r_g58		RECORD LIKE gent058.*

CLEAR FORM
CALL fl_retorna_usuario()
LET vm_flag_mant = 'I'
LET num_aux = 0 
INITIALIZE rm_b43.* TO NULL
LET rm_b43.b43_compania   = vg_codcia
LET rm_b43.b43_localidad  = vg_codloc
LET rm_b43.b43_porc_impto = rg_gen.g00_porc_impto
CALL fl_lee_compania(rm_b43.b43_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b43.b43_compania, rm_b43.b43_localidad)
	RETURNING r_g02.*
CALL fl_lee_porc_impto(rm_b43.b43_compania, rm_b43.b43_localidad, 'I',
			rm_b43.b43_porc_impto, 'V')
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
INSERT INTO ctbt043 VALUES (rm_b43.*)
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
	SELECT * FROM ctbt043
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_b43.*
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
UPDATE ctbt043 SET * = rm_b43.* WHERE CURRENT OF q_up
COMMIT WORK
CALL muestra_reg()
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(3000)
DEFINE expr_sql		CHAR(2000)
DEFINE num_reg		INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g58		RECORD LIKE gent058.*
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad

CLEAR FORM
LET codcia   = vg_codcia
LET codloc   = vg_codloc
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b43_compania, b43_localidad, b43_grupo_linea,
	b43_porc_impto, b43_vta_mo_tal, b43_vta_mo_ext, b43_vta_mo_cti,
	b43_vta_rp_tal, b43_vta_rp_ext, b43_vta_rp_cti,	b43_vta_rp_alm,
	b43_vta_otros1, b43_vta_otros2, b43_dvt_mo_tal, b43_dvt_mo_ext,
	b43_dvt_mo_cti, b43_dvt_rp_tal, b43_dvt_rp_ext, b43_dvt_rp_cti,
	b43_dvt_rp_alm, b43_dvt_otros1, b43_dvt_otros2, b43_cos_mo_tal,
	b43_cos_mo_ext, b43_cos_mo_cti, b43_cos_rp_tal, b43_cos_rp_ext,
	b43_cos_rp_cti, b43_cos_rp_alm, b43_cos_otros1, b43_cos_otros2,
	b43_pro_mo_tal, b43_pro_mo_ext, b43_pro_mo_cti, b43_pro_rp_tal,
	b43_pro_rp_ext, b43_pro_rp_cti, b43_pro_rp_alm, b43_pro_otros1,
	b43_pro_otros2, b43_des_mo_tal, b43_des_rp_tal, b43_des_rp_alm
	ON KEY(F2)
		IF INFIELD(b43_compania) THEN
			CALL fl_ayuda_compania() RETURNING r_g01.g01_compania
			IF r_g01.g01_compania IS NOT NULL THEN
				CALL fl_lee_compania(r_g01.g01_compania)
					RETURNING r_g01.*
				DISPLAY r_g01.g01_compania    TO b43_compania
				DISPLAY r_g01.g01_razonsocial TO tit_compania
			END IF
		END IF
		IF INFIELD(b43_localidad) THEN
			CALL fl_ayuda_localidad(codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02.g02_localidad TO b43_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
		END IF
		IF INFIELD(b43_grupo_linea) THEN
			CALL fl_ayuda_grupo_lineas(codcia)
				RETURNING r_g20.g20_grupo_linea,r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				DISPLAY r_g20.g20_grupo_linea TO b43_grupo_linea
				DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
			END IF 
		END IF
		IF INFIELD(b43_porc_impto) THEN
			CALL fl_ayuda_porc_impto(codcia, codloc, 'T', 'I', 'V')
				RETURNING r_g58.g58_porc_impto,
					  r_g58.g58_desc_impto
			IF r_g58.g58_porc_impto IS NOT NULL THEN
				DISPLAY r_g58.g58_porc_impto TO b43_porc_impto
				DISPLAY r_g58.g58_desc_impto TO tit_porc_impto
			END IF
		END IF
		IF INFIELD(b43_vta_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_vta_mo_tal
			END IF
		END IF
		IF INFIELD(b43_vta_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_vta_mo_ext
			END IF
		END IF
		IF INFIELD(b43_vta_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_vta_mo_cti
			END IF
		END IF
		IF INFIELD(b43_vta_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_tal
			END IF
		END IF
		IF INFIELD(b43_vta_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_ext
			END IF
		END IF
		IF INFIELD(b43_vta_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_cti
			END IF
		END IF
		IF INFIELD(b43_vta_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_alm
			END IF
		END IF
		IF INFIELD(b43_vta_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_otros1
				DISPLAY r_b10.b10_descripcion TO tit_vta_otros1
			END IF
		END IF
		IF INFIELD(b43_vta_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_vta_otros2
				DISPLAY r_b10.b10_descripcion TO tit_vta_otros2
			END IF
		END IF
		IF INFIELD(b43_dvt_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_tal
			END IF
		END IF
		IF INFIELD(b43_dvt_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_ext
			END IF
		END IF
		IF INFIELD(b43_dvt_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_cti
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_tal
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_ext
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_cti
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_alm
			END IF
		END IF
		IF INFIELD(b43_dvt_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_otros1
				DISPLAY r_b10.b10_descripcion TO tit_dvt_otros1
			END IF
		END IF
		IF INFIELD(b43_dvt_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_otros2
				DISPLAY r_b10.b10_descripcion TO tit_dvt_otros2
			END IF
		END IF
		IF INFIELD(b43_cos_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_cos_mo_tal
			END IF
		END IF
		IF INFIELD(b43_cos_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_cos_mo_ext
			END IF
		END IF
		IF INFIELD(b43_cos_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_cos_mo_cti
			END IF
		END IF
		IF INFIELD(b43_cos_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_tal
			END IF
		END IF
		IF INFIELD(b43_cos_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_ext
			END IF
		END IF
		IF INFIELD(b43_cos_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_cti
			END IF
		END IF
		IF INFIELD(b43_cos_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_alm
			END IF
		END IF
		IF INFIELD(b43_cos_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_otros1
				DISPLAY r_b10.b10_descripcion TO tit_cos_otros1
			END IF
		END IF
		IF INFIELD(b43_cos_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_cos_otros2
				DISPLAY r_b10.b10_descripcion TO tit_cos_otros2
			END IF
		END IF
		IF INFIELD(b43_pro_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_pro_mo_tal
			END IF
		END IF
		IF INFIELD(b43_pro_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_pro_mo_ext
			END IF
		END IF
		IF INFIELD(b43_pro_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_pro_mo_cti
			END IF
		END IF
		IF INFIELD(b43_pro_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_tal
			END IF
		END IF
		IF INFIELD(b43_pro_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_ext
			END IF
		END IF
		IF INFIELD(b43_pro_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_cti
			END IF
		END IF
		IF INFIELD(b43_pro_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_alm
			END IF
		END IF
		IF INFIELD(b43_pro_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_otros1
				DISPLAY r_b10.b10_descripcion TO tit_pro_otros1
			END IF
		END IF
		IF INFIELD(b43_pro_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_pro_otros2
				DISPLAY r_b10.b10_descripcion TO tit_pro_otros2
			END IF
		END IF
		IF INFIELD(b43_des_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_des_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_des_mo_tal
			END IF
		END IF
		IF INFIELD(b43_des_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_des_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_des_rp_tal
			END IF
		END IF
		IF INFIELD(b43_des_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b43_des_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_des_rp_alm
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD b43_compania
		LET codcia = NULL
		LET codcia = GET_FLDBUF(b43_compania)
		IF codcia IS NULL THEN
			LET codcia = vg_codcia
		END IF
	AFTER FIELD b43_localidad
		LET codloc = NULL
		LET codloc = GET_FLDBUF(b43_localidad)
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
LET query = 'SELECT *, ROWID FROM ctbt043 ',
		' WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3, 4 '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_b43.*, num_reg
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
DEFINE r_b43		RECORD LIKE ctbt043.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g58		RECORD LIKE gent058.*
DEFINE codcia		LIKE gent001.g01_compania

LET codcia   = vg_codcia
LET int_flag = 0
INPUT BY NAME rm_b43.b43_compania, rm_b43.b43_localidad, rm_b43.b43_grupo_linea,
	rm_b43.b43_porc_impto, rm_b43.b43_vta_mo_tal, rm_b43.b43_vta_mo_ext,
	rm_b43.b43_vta_mo_cti, rm_b43.b43_vta_rp_tal, rm_b43.b43_vta_rp_ext,
	rm_b43.b43_vta_rp_cti, rm_b43.b43_vta_rp_alm, rm_b43.b43_vta_otros1,
	rm_b43.b43_vta_otros2, rm_b43.b43_dvt_mo_tal, rm_b43.b43_dvt_mo_ext,
	rm_b43.b43_dvt_mo_cti, rm_b43.b43_dvt_rp_tal, rm_b43.b43_dvt_rp_ext,
	rm_b43.b43_dvt_rp_cti, rm_b43.b43_dvt_rp_alm, rm_b43.b43_dvt_otros1,
	rm_b43.b43_dvt_otros2, rm_b43.b43_cos_mo_tal, rm_b43.b43_cos_mo_ext,
	rm_b43.b43_cos_mo_cti, rm_b43.b43_cos_rp_tal, rm_b43.b43_cos_rp_ext,
	rm_b43.b43_cos_rp_cti, rm_b43.b43_cos_rp_alm, rm_b43.b43_cos_otros1,
	rm_b43.b43_cos_otros2, rm_b43.b43_pro_mo_tal, rm_b43.b43_pro_mo_ext,
	rm_b43.b43_pro_mo_cti, rm_b43.b43_pro_rp_tal, rm_b43.b43_pro_rp_ext,
	rm_b43.b43_pro_rp_cti, rm_b43.b43_pro_rp_alm, rm_b43.b43_pro_otros1,
	rm_b43.b43_pro_otros2, rm_b43.b43_des_mo_tal, rm_b43.b43_des_rp_tal,
	rm_b43.b43_des_rp_alm
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_b43.b43_compania, rm_b43.b43_localidad,
				 rm_b43.b43_grupo_linea, rm_b43.b43_porc_impto,
				 rm_b43.b43_vta_mo_tal, rm_b43.b43_vta_mo_ext,
				 rm_b43.b43_vta_mo_cti, rm_b43.b43_vta_rp_tal,
				 rm_b43.b43_vta_rp_ext, rm_b43.b43_vta_rp_cti,
				 rm_b43.b43_vta_rp_alm, rm_b43.b43_vta_otros1,
				 rm_b43.b43_vta_otros2, rm_b43.b43_dvt_mo_tal,
				 rm_b43.b43_dvt_mo_ext, rm_b43.b43_dvt_mo_cti,
				 rm_b43.b43_dvt_rp_tal, rm_b43.b43_dvt_rp_ext,
				 rm_b43.b43_dvt_rp_cti, rm_b43.b43_dvt_rp_alm,
				 rm_b43.b43_dvt_otros1,	rm_b43.b43_dvt_otros2,
				 rm_b43.b43_cos_mo_tal, rm_b43.b43_cos_mo_ext,
				 rm_b43.b43_cos_mo_cti, rm_b43.b43_cos_rp_tal,
				 rm_b43.b43_cos_rp_ext, rm_b43.b43_cos_rp_cti,
				 rm_b43.b43_cos_rp_alm, rm_b43.b43_cos_otros1,
				 rm_b43.b43_cos_otros2, rm_b43.b43_pro_mo_tal,
				 rm_b43.b43_pro_mo_ext,	rm_b43.b43_pro_mo_cti,
				 rm_b43.b43_pro_rp_tal, rm_b43.b43_pro_rp_ext,
				 rm_b43.b43_pro_rp_cti, rm_b43.b43_pro_rp_alm,
				 rm_b43.b43_pro_otros1,	rm_b43.b43_pro_otros2,
				 rm_b43.b43_des_mo_tal, rm_b43.b43_des_rp_tal,
				 rm_b43.b43_des_rp_alm)
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
			IF INFIELD(b43_compania) THEN
				CALL fl_ayuda_compania()
					RETURNING r_g01.g01_compania
				IF r_g01.g01_compania IS NOT NULL THEN
					CALL fl_lee_compania(r_g01.g01_compania)
						RETURNING r_g01.*
					LET rm_b43.b43_compania =
							r_g01.g01_compania
					LET codcia = rm_b43.b43_compania
					DISPLAY r_g01.g01_compania
						TO b43_compania
					DISPLAY r_g01.g01_razonsocial
						TO tit_compania
				END IF
			END IF
			IF INFIELD(b43_localidad) THEN
				CALL fl_ayuda_localidad(codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_b43.b43_localidad =
							r_g02.g02_localidad
					DISPLAY r_g02.g02_localidad
						TO b43_localidad
					DISPLAY r_g02.g02_nombre
						TO tit_localidad
				END IF
			END IF
			IF INFIELD(b43_grupo_linea) THEN
				CALL fl_ayuda_grupo_lineas(codcia)
					RETURNING r_g20.g20_grupo_linea,
						  r_g20.g20_nombre
				IF r_g20.g20_grupo_linea IS NOT NULL THEN
					LET rm_b43.b43_grupo_linea =
							r_g20.g20_grupo_linea
					DISPLAY r_g20.g20_grupo_linea
						TO b43_grupo_linea
					DISPLAY r_g20.g20_nombre
						TO tit_grupo_linea
				END IF 
			END IF
			IF INFIELD(b43_porc_impto) THEN
				CALL fl_ayuda_porc_impto(codcia,
						rm_b43.b43_localidad, 'A', 'I',
						'V')
					RETURNING r_g58.g58_porc_impto,
						  r_g58.g58_desc_impto
				IF r_g58.g58_porc_impto IS NOT NULL THEN
					LET rm_b43.b43_porc_impto =
							r_g58.g58_porc_impto
					DISPLAY r_g58.g58_porc_impto
						TO b43_porc_impto
					DISPLAY r_g58.g58_desc_impto
						TO tit_porc_impto
				END IF
			END IF
		END IF
		IF INFIELD(b43_vta_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_mo_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_vta_mo_tal
			END IF
		END IF
		IF INFIELD(b43_vta_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_mo_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_vta_mo_ext
			END IF
		END IF
		IF INFIELD(b43_vta_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_mo_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_vta_mo_cti
			END IF
		END IF
		IF INFIELD(b43_vta_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_rp_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_tal
			END IF
		END IF
		IF INFIELD(b43_vta_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_rp_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_ext
			END IF
		END IF
		IF INFIELD(b43_vta_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_rp_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_cti
			END IF
		END IF
		IF INFIELD(b43_vta_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_rp_alm = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_vta_rp_alm
			END IF
		END IF
		IF INFIELD(b43_vta_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_otros1 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_otros1
				DISPLAY r_b10.b10_descripcion TO tit_vta_otros1
			END IF
		END IF
		IF INFIELD(b43_vta_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_vta_otros2 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_vta_otros2
				DISPLAY r_b10.b10_descripcion TO tit_vta_otros2
			END IF
		END IF
		IF INFIELD(b43_dvt_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_mo_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_tal
			END IF
		END IF
		IF INFIELD(b43_dvt_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_mo_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_ext
			END IF
		END IF
		IF INFIELD(b43_dvt_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_mo_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_cti
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_rp_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_tal
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_rp_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_ext
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_rp_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_cti
			END IF
		END IF
		IF INFIELD(b43_dvt_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_rp_alm = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_alm
			END IF
		END IF
		IF INFIELD(b43_dvt_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_otros1 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_otros1
				DISPLAY r_b10.b10_descripcion TO tit_dvt_otros1
			END IF
		END IF
		IF INFIELD(b43_dvt_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_dvt_otros2 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_dvt_otros2
				DISPLAY r_b10.b10_descripcion TO tit_dvt_otros2
			END IF
		END IF
		IF INFIELD(b43_cos_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_mo_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_cos_mo_tal
			END IF
		END IF
		IF INFIELD(b43_cos_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_mo_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_cos_mo_ext
			END IF
		END IF
		IF INFIELD(b43_cos_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_mo_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_cos_mo_cti
			END IF
		END IF
		IF INFIELD(b43_cos_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_rp_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_tal
			END IF
		END IF
		IF INFIELD(b43_cos_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_rp_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_ext
			END IF
		END IF
		IF INFIELD(b43_cos_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_rp_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_cti
			END IF
		END IF
		IF INFIELD(b43_cos_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_rp_alm = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_cos_rp_alm
			END IF
		END IF
		IF INFIELD(b43_cos_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_otros1 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_otros1
				DISPLAY r_b10.b10_descripcion TO tit_cos_otros1
			END IF
		END IF
		IF INFIELD(b43_cos_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_cos_otros2 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_cos_otros2
				DISPLAY r_b10.b10_descripcion TO tit_cos_otros2
			END IF
		END IF
		IF INFIELD(b43_pro_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_mo_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_pro_mo_tal
			END IF
		END IF
		IF INFIELD(b43_pro_mo_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_mo_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_mo_ext
				DISPLAY r_b10.b10_descripcion TO tit_pro_mo_ext
			END IF
		END IF
		IF INFIELD(b43_pro_mo_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_mo_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_mo_cti
				DISPLAY r_b10.b10_descripcion TO tit_pro_mo_cti
			END IF
		END IF
		IF INFIELD(b43_pro_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_rp_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_tal
			END IF
		END IF
		IF INFIELD(b43_pro_rp_ext) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_rp_ext = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_ext
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_ext
			END IF
		END IF
		IF INFIELD(b43_pro_rp_cti) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_rp_cti = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_cti
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_cti
			END IF
		END IF
		IF INFIELD(b43_pro_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_rp_alm = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_pro_rp_alm
			END IF
		END IF
		IF INFIELD(b43_pro_otros1) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_otros1 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_otros1
				DISPLAY r_b10.b10_descripcion TO tit_pro_otros1
			END IF
		END IF
		IF INFIELD(b43_pro_otros2) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_pro_otros2 = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_pro_otros2
				DISPLAY r_b10.b10_descripcion TO tit_pro_otros2
			END IF
		END IF
		IF INFIELD(b43_des_mo_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_des_mo_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_des_mo_tal
				DISPLAY r_b10.b10_descripcion TO tit_des_mo_tal
			END IF
		END IF
		IF INFIELD(b43_des_rp_tal) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_des_rp_tal = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_des_rp_tal
				DISPLAY r_b10.b10_descripcion TO tit_des_rp_tal
			END IF
		END IF
		IF INFIELD(b43_des_rp_alm) THEN
			CALL fl_ayuda_cuenta_contable(codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b43.b43_des_rp_alm = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b43_des_rp_alm
				DISPLAY r_b10.b10_descripcion TO tit_des_rp_alm
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD b43_compania
		IF vm_flag_mant = 'M' THEN
			LET codcia = rm_b43.b43_compania
		END IF
	BEFORE FIELD b43_localidad
		IF vm_flag_mant = 'M' THEN
			LET r_g02.g02_localidad = rm_b43.b43_localidad
		END IF
	BEFORE FIELD b43_grupo_linea
		IF vm_flag_mant = 'M' THEN
			LET r_g20.g20_grupo_linea = rm_b43.b43_grupo_linea
		END IF
	BEFORE FIELD b43_porc_impto
		IF vm_flag_mant = 'M' THEN
			LET r_g58.g58_porc_impto = rm_b43.b43_porc_impto
		END IF
	AFTER FIELD b43_compania
		IF vm_flag_mant = 'M' THEN
			LET rm_b43.b43_compania = codcia
			CALL fl_lee_compania(rm_b43.b43_compania)
				RETURNING r_g01.*
			DISPLAY r_g01.g01_compania    TO b43_compania
			DISPLAY r_g01.g01_razonsocial TO tit_compania
			CONTINUE INPUT
		END IF
		IF rm_b43.b43_compania IS NULL THEN
			LET rm_b43.b43_compania = vg_codcia
		END IF
		CALL fl_lee_compania(rm_b43.b43_compania) RETURNING r_g01.*
		IF r_g01.g01_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esa compania.', 'exclamation')
			NEXT FIELD b43_compania
		END IF
		DISPLAY r_g01.g01_razonsocial TO tit_compania
		IF r_g01.g01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b43_compania
		END IF
	AFTER FIELD b43_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_b43.b43_localidad = r_g02.g02_localidad
			CALL fl_lee_localidad(rm_b43.b43_compania,
						rm_b43.b43_localidad)
				RETURNING r_g02.*
			DISPLAY r_g02.g02_localidad TO b43_localidad
			DISPLAY r_g02.g02_nombre    TO tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_b43.b43_localidad IS NULL THEN
			LET rm_b43.b43_localidad = vg_codloc
		END IF
		CALL fl_lee_localidad(rm_b43.b43_compania, rm_b43.b43_localidad)
			RETURNING r_g02.*
		IF r_g02.g02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
			NEXT FIELD b43_localidad
		END IF
		DISPLAY r_g02.g02_nombre TO tit_localidad
		IF r_g02.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b43_localidad
		END IF
	AFTER FIELD b43_grupo_linea
		IF vm_flag_mant = 'M' THEN
			LET rm_b43.b43_grupo_linea = r_g20.g20_grupo_linea
			CALL fl_lee_grupo_linea(rm_b43.b43_compania,
						rm_b43.b43_grupo_linea)
				RETURNING r_g20.*
			DISPLAY r_g20.g20_grupo_linea TO b43_grupo_linea
			DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
			CONTINUE INPUT
		END IF
		IF rm_b43.b43_grupo_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(rm_b43.b43_compania,
						rm_b43.b43_grupo_linea)
				RETURNING r_g20.*
			IF r_g20.g20_grupo_linea IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este grupo de linea.', 'exclamation')
				NEXT FIELD b43_grupo_linea
			END IF
			DISPLAY r_g20.g20_nombre TO tit_grupo_linea
		ELSE
			CLEAR tit_grupo_linea
		END IF
	AFTER FIELD b43_porc_impto
		IF vm_flag_mant = 'M' THEN
			LET rm_b43.b43_porc_impto = r_g58.g58_porc_impto
			CALL fl_lee_porc_impto(rm_b43.b43_compania,
						rm_b43.b43_localidad, 'I',
						rm_b43.b43_porc_impto, 'V')
				RETURNING r_g58.*
			DISPLAY r_g58.g58_porc_impto TO b43_porc_impto
			DISPLAY r_g58.g58_desc_impto TO tit_porc_impto
			CONTINUE INPUT
		END IF
		IF rm_b43.b43_porc_impto IS NOT NULL THEN
			CALL fl_lee_porc_impto(rm_b43.b43_compania,
						rm_b43.b43_localidad, 'I',
						rm_b43.b43_porc_impto, 'V')
				RETURNING r_g58.*
			IF r_g58.g58_porc_impto IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este impuesto.', 'exclamation')
				NEXT FIELD b43_porc_impto
			END IF
			DISPLAY r_g58.g58_desc_impto TO tit_porc_impto
			IF r_g58.g58_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b43_porc_impto
			END IF
			IF r_g58.g58_tipo_impto <> 'I' THEN
				CALL fl_mostrar_mensaje('El tipo de impuesto debe ser IVA.', 'exclamation')
				NEXT FIELD b43_porc_impto
			END IF
			IF r_g58.g58_tipo <> 'V' THEN
				CALL fl_mostrar_mensaje('El tipo debe ser VENTA.', 'exclamation')
				NEXT FIELD b43_porc_impto
			END IF
		ELSE
			CLEAR tit_porc_impto
		END IF
	AFTER FIELD b43_vta_mo_tal
                IF rm_b43.b43_vta_mo_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_mo_tal, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_mo_tal
			END IF
		ELSE
			CLEAR tit_vta_mo_tal
                END IF
	AFTER FIELD b43_vta_mo_ext
                IF rm_b43.b43_vta_mo_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_mo_ext, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_mo_ext
			END IF
		ELSE
			CLEAR tit_vta_mo_ext
                END IF
	AFTER FIELD b43_vta_mo_cti
                IF rm_b43.b43_vta_mo_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_mo_cti, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_mo_cti
			END IF
		ELSE
			CLEAR tit_vta_mo_cti
                END IF
	AFTER FIELD b43_vta_rp_tal
                IF rm_b43.b43_vta_rp_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_rp_tal, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_rp_tal
			END IF
		ELSE
			CLEAR tit_vta_rp_tal
                END IF
	AFTER FIELD b43_vta_rp_ext
                IF rm_b43.b43_vta_rp_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_rp_ext, 5)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_rp_ext
			END IF
		ELSE
			CLEAR tit_vta_rp_ext
                END IF
	AFTER FIELD b43_vta_rp_cti
                IF rm_b43.b43_vta_rp_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_rp_cti, 6)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_rp_cti
			END IF
		ELSE
			CLEAR tit_vta_rp_cti
                END IF
	AFTER FIELD b43_vta_rp_alm
                IF rm_b43.b43_vta_rp_alm IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_rp_alm, 7)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_rp_alm
			END IF
		ELSE
			CLEAR tit_vta_rp_alm
                END IF
	AFTER FIELD b43_vta_otros1
                IF rm_b43.b43_vta_otros1 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_otros1, 8)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_otros1
			END IF
		ELSE
			CLEAR tit_vta_otros1
                END IF
	AFTER FIELD b43_vta_otros2
                IF rm_b43.b43_vta_otros2 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_vta_otros2, 9)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_vta_otros2
			END IF
		ELSE
			CLEAR tit_vta_otros2
                END IF
	AFTER FIELD b43_dvt_mo_tal
                IF rm_b43.b43_dvt_mo_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_mo_tal, 10)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_mo_tal
			END IF
		ELSE
			CLEAR tit_dvt_mo_tal
                END IF
	AFTER FIELD b43_dvt_mo_ext
                IF rm_b43.b43_dvt_mo_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_mo_ext, 11)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_mo_ext
			END IF
		ELSE
			CLEAR tit_dvt_mo_ext
                END IF
	AFTER FIELD b43_dvt_mo_cti
                IF rm_b43.b43_dvt_mo_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_mo_cti, 12)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_mo_cti
			END IF
		ELSE
			CLEAR tit_dvt_mo_cti
                END IF
	AFTER FIELD b43_dvt_rp_tal
                IF rm_b43.b43_dvt_rp_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_rp_tal, 13)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_rp_tal
			END IF
		ELSE
			CLEAR tit_dvt_rp_tal
                END IF
	AFTER FIELD b43_dvt_rp_ext
                IF rm_b43.b43_dvt_rp_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_rp_ext, 14)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_rp_ext
			END IF
		ELSE
			CLEAR tit_dvt_rp_ext
                END IF
	AFTER FIELD b43_dvt_rp_cti
                IF rm_b43.b43_dvt_rp_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_rp_cti, 15)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_rp_cti
			END IF
		ELSE
			CLEAR tit_dvt_rp_cti
                END IF
	AFTER FIELD b43_dvt_rp_alm
                IF rm_b43.b43_dvt_rp_alm IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_rp_alm, 16)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_rp_alm
			END IF
		ELSE
			CLEAR tit_dvt_rp_alm
                END IF
	AFTER FIELD b43_dvt_otros1
                IF rm_b43.b43_dvt_otros1 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_otros1, 17)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_otros1
			END IF
		ELSE
			CLEAR tit_dvt_otros1
                END IF
	AFTER FIELD b43_dvt_otros2
                IF rm_b43.b43_dvt_otros2 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_dvt_otros2, 18)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_dvt_otros2
			END IF
		ELSE
			CLEAR tit_dvt_otros2
                END IF
	AFTER FIELD b43_cos_mo_tal
                IF rm_b43.b43_cos_mo_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_mo_tal, 19)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_mo_tal
			END IF
		ELSE
			CLEAR tit_cos_mo_tal
                END IF
	AFTER FIELD b43_cos_mo_ext
                IF rm_b43.b43_cos_mo_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_mo_ext, 20)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_mo_ext
			END IF
		ELSE
			CLEAR tit_cos_mo_ext
                END IF
	AFTER FIELD b43_cos_mo_cti
                IF rm_b43.b43_cos_mo_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_mo_cti, 21)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_mo_cti
			END IF
		ELSE
			CLEAR tit_cos_mo_cti
                END IF
	AFTER FIELD b43_cos_rp_tal
                IF rm_b43.b43_cos_rp_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_rp_tal, 22)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_rp_tal
			END IF
		ELSE
			CLEAR tit_cos_rp_tal
                END IF
	AFTER FIELD b43_cos_rp_ext
                IF rm_b43.b43_cos_rp_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_rp_ext, 23)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_rp_ext
			END IF
		ELSE
			CLEAR tit_cos_rp_ext
                END IF
	AFTER FIELD b43_cos_rp_cti
                IF rm_b43.b43_cos_rp_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_rp_cti, 24)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_rp_cti
			END IF
		ELSE
			CLEAR tit_cos_rp_cti
                END IF
	AFTER FIELD b43_cos_rp_alm
                IF rm_b43.b43_cos_rp_alm IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_rp_alm, 25)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_rp_alm
			END IF
		ELSE
			CLEAR tit_cos_rp_alm
                END IF
	AFTER FIELD b43_cos_otros1
                IF rm_b43.b43_cos_otros1 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_otros1, 26)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_otros1
			END IF
		ELSE
			CLEAR tit_cos_otros1
                END IF
	AFTER FIELD b43_cos_otros2
                IF rm_b43.b43_cos_otros2 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_cos_otros2, 27)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_cos_otros2
			END IF
		ELSE
			CLEAR tit_cos_otros2
                END IF
	AFTER FIELD b43_pro_mo_tal
                IF rm_b43.b43_pro_mo_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_mo_tal, 28)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_mo_tal
			END IF
		ELSE
			CLEAR tit_pro_mo_tal
                END IF
	AFTER FIELD b43_pro_mo_ext
                IF rm_b43.b43_pro_mo_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_mo_ext, 29)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_mo_ext
			END IF
		ELSE
			CLEAR tit_pro_mo_ext
                END IF
	AFTER FIELD b43_pro_mo_cti
                IF rm_b43.b43_pro_mo_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_mo_cti, 30)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_mo_cti
			END IF
		ELSE
			CLEAR tit_pro_mo_cti
                END IF
	AFTER FIELD b43_pro_rp_tal
                IF rm_b43.b43_pro_rp_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_rp_tal, 31)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_rp_tal
			END IF
		ELSE
			CLEAR tit_pro_rp_tal
                END IF
	AFTER FIELD b43_pro_rp_ext
                IF rm_b43.b43_pro_rp_ext IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_rp_ext, 32)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_rp_ext
			END IF
		ELSE
			CLEAR tit_pro_rp_ext
                END IF
	AFTER FIELD b43_pro_rp_cti
                IF rm_b43.b43_pro_rp_cti IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_rp_cti, 33)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_rp_cti
			END IF
		ELSE
			CLEAR tit_pro_rp_cti
                END IF
	AFTER FIELD b43_pro_rp_alm
                IF rm_b43.b43_pro_rp_alm IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_rp_alm, 34)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_rp_alm
			END IF
		ELSE
			CLEAR tit_pro_rp_alm
                END IF
	AFTER FIELD b43_pro_otros1
                IF rm_b43.b43_pro_otros1 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_otros1, 35)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_otros1
			END IF
		ELSE
			CLEAR tit_pro_otros1
                END IF
	AFTER FIELD b43_pro_otros2
                IF rm_b43.b43_pro_otros2 IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_pro_otros2, 36)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_pro_otros2
			END IF
		ELSE
			CLEAR tit_pro_otros2
                END IF
	AFTER FIELD b43_des_mo_tal
                IF rm_b43.b43_des_mo_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_des_mo_tal, 37)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_des_mo_tal
			END IF
		ELSE
			CLEAR tit_des_mo_tal
                END IF
	AFTER FIELD b43_des_rp_tal
                IF rm_b43.b43_des_rp_tal IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_des_rp_tal, 38)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_des_rp_tal
			END IF
		ELSE
			CLEAR tit_des_rp_tal
                END IF
	AFTER FIELD b43_des_rp_alm
                IF rm_b43.b43_des_rp_alm IS NOT NULL THEN
			CALL validar_cuenta(rm_b43.b43_des_rp_alm, 39)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b43_des_rp_alm
			END IF
		ELSE
			CLEAR tit_des_rp_alm
                END IF
	AFTER INPUT
		IF vm_flag_mant <> 'I' THEN
			EXIT INPUT
		END IF
		INITIALIZE r_b43.* TO NULL
		SELECT * INTO r_b43.*
			FROM ctbt043
			WHERE b43_compania    = rm_b43.b43_compania
			  AND b43_localidad   = rm_b43.b43_localidad
			  AND b43_grupo_linea = rm_b43.b43_grupo_linea
			  AND b43_porc_impto  = rm_b43.b43_porc_impto
		IF r_b43.b43_compania IS NOT NULL THEN
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
	WHEN 01 DISPLAY r_b10.b10_descripcion TO tit_vta_mo_tal
	WHEN 02 DISPLAY r_b10.b10_descripcion TO tit_vta_mo_ext
	WHEN 03 DISPLAY r_b10.b10_descripcion TO tit_vta_mo_cti
	WHEN 04 DISPLAY r_b10.b10_descripcion TO tit_vta_rp_tal
	WHEN 05 DISPLAY r_b10.b10_descripcion TO tit_vta_rp_ext
	WHEN 06 DISPLAY r_b10.b10_descripcion TO tit_vta_rp_cti
	WHEN 07 DISPLAY r_b10.b10_descripcion TO tit_vta_rp_alm
	WHEN 08 DISPLAY r_b10.b10_descripcion TO tit_vta_otros1
	WHEN 09 DISPLAY r_b10.b10_descripcion TO tit_vta_otros2
	WHEN 10 DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_tal
	WHEN 11 DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_ext
	WHEN 12 DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_cti
	WHEN 13 DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_tal
	WHEN 14 DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_ext
	WHEN 15 DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_cti
	WHEN 16 DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_alm
	WHEN 17 DISPLAY r_b10.b10_descripcion TO tit_dvt_otros1
	WHEN 18 DISPLAY r_b10.b10_descripcion TO tit_dvt_otros2
	WHEN 19 DISPLAY r_b10.b10_descripcion TO tit_cos_mo_tal
	WHEN 20 DISPLAY r_b10.b10_descripcion TO tit_cos_mo_ext
	WHEN 21 DISPLAY r_b10.b10_descripcion TO tit_cos_mo_cti
	WHEN 22 DISPLAY r_b10.b10_descripcion TO tit_cos_rp_tal
	WHEN 23 DISPLAY r_b10.b10_descripcion TO tit_cos_rp_ext
	WHEN 24 DISPLAY r_b10.b10_descripcion TO tit_cos_rp_cti
	WHEN 25 DISPLAY r_b10.b10_descripcion TO tit_cos_rp_alm
	WHEN 26 DISPLAY r_b10.b10_descripcion TO tit_cos_otros1
	WHEN 27 DISPLAY r_b10.b10_descripcion TO tit_cos_otros2
	WHEN 28 DISPLAY r_b10.b10_descripcion TO tit_pro_mo_tal
	WHEN 29 DISPLAY r_b10.b10_descripcion TO tit_pro_mo_ext
	WHEN 30 DISPLAY r_b10.b10_descripcion TO tit_pro_mo_cti
	WHEN 31 DISPLAY r_b10.b10_descripcion TO tit_pro_rp_tal
	WHEN 32 DISPLAY r_b10.b10_descripcion TO tit_pro_rp_ext
	WHEN 33 DISPLAY r_b10.b10_descripcion TO tit_pro_rp_cti
	WHEN 34 DISPLAY r_b10.b10_descripcion TO tit_pro_rp_alm
	WHEN 35 DISPLAY r_b10.b10_descripcion TO tit_pro_otros1
	WHEN 36 DISPLAY r_b10.b10_descripcion TO tit_pro_otros2
	WHEN 37 DISPLAY r_b10.b10_descripcion TO tit_des_mo_tal
	WHEN 38 DISPLAY r_b10.b10_descripcion TO tit_des_rp_tal
	WHEN 39 DISPLAY r_b10.b10_descripcion TO tit_des_rp_alm
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

DISPLAY " " TO b43_compania
CLEAR b43_compania
DISPLAY row_current TO vm_row_current3
DISPLAY num_rows    TO vm_num_rows3
DISPLAY row_current TO vm_row_current2
DISPLAY num_rows    TO vm_num_rows2
DISPLAY row_current TO vm_row_current
DISPLAY num_rows    TO vm_num_rows
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g58		RECORD LIKE gent058.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_b43.* FROM ctbt043 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_b43.*
CALL fl_lee_compania(rm_b43.b43_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b43.b43_compania, rm_b43.b43_localidad)
	RETURNING r_g02.*
CALL fl_lee_porc_impto(rm_b43.b43_compania, rm_b43.b43_localidad, 'I',
			rm_b43.b43_porc_impto, 'V')
	RETURNING r_g58.*
CALL fl_lee_grupo_linea(rm_b43.b43_compania, rm_b43.b43_grupo_linea)
	RETURNING r_g20.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
DISPLAY r_g58.g58_desc_impto  TO tit_porc_impto
DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_mo_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_mo_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_mo_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_mo_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_mo_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_mo_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_rp_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_rp_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_rp_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_rp_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_rp_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_rp_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_rp_alm) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_rp_alm
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_otros1) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_otros1
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_vta_otros2) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_vta_otros2
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_mo_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_mo_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_mo_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_mo_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_rp_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_rp_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_rp_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_rp_alm) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_rp_alm
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_otros1) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_otros1
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_dvt_otros2) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_dvt_otros2
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_mo_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_mo_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_mo_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_mo_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_mo_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_mo_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_rp_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_rp_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_rp_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_rp_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_rp_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_rp_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_rp_alm) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_rp_alm
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_otros1) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_otros1
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_cos_otros2) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cos_otros2
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_mo_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_mo_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_mo_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_mo_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_mo_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_mo_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_rp_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_rp_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_rp_ext) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_rp_ext
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_rp_cti) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_rp_cti
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_rp_alm) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_rp_alm
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_otros1) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_otros1
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_pro_otros2) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_pro_otros2
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_des_mo_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_des_mo_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_des_rp_tal) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_des_rp_tal
CALL fl_lee_cuenta(vg_codcia, rm_b43.b43_des_rp_alm) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_des_rp_alm

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
DISPLAY BY NAME rm_b43.b43_compania

END FUNCTION
