------------------------------------------------------------------------------
-- Titulo           : rolp500.4gl - Configuracion Contable Roles
-- Elaboracion      : 23-nov-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun rolp500 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ring  ARRAY[200] OF RECORD
		n50_cod_depto	LIKE gent034.g34_cod_depto,
		tit_depto	CHAR(40),
		n50_aux_cont	LIKE rolt050.n50_aux_cont,
		tit_cuenta	CHAR(30)
	END RECORD
DEFINE rm_regr  ARRAY[200] OF RECORD
		n51_cod_rubro	LIKE rolt051.n51_cod_rubro,
		tit_rubro	CHAR(40),
		n51_aux_cont	LIKE rolt051.n51_aux_cont,
		tit_cuenta	CHAR(30)
	END RECORD
DEFINE rm_rtra  ARRAY[300] OF RECORD
		n52_cod_trab	LIKE rolt030.n30_cod_trab,
		tit_trab	CHAR(40),
		n52_aux_cont	LIKE rolt052.n52_aux_cont,
		tit_cuenta	CHAR(30)
	END RECORD
DEFINE vm_cod_rubro	LIKE rolt006.n06_cod_rubro
DEFINE rm_n54		RECORD LIKE rolt054.*
DEFINE vm_max_ring	SMALLINT
DEFINE vm_max_regr	SMALLINT
DEFINE vm_max_rtra	SMALLINT
DEFINE vm_num_ring	SMALLINT
DEFINE vm_num_regr	SMALLINT
DEFINE vm_num_rtra	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp500.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp500'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
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
LET lin_menu = 0          
LET row_ini  = 3          
LET num_rows = 22         
LET num_cols = 80         
IF vg_gui = 0 THEN        
	LET lin_menu = 1                                                        
	LET row_ini  = 2
	LET num_rows = 22 
	LET num_cols = 78 
END IF                  
OPEN WINDOW w_217 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS            
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
OPEN FORM f_ring FROM '../forms/rolf500_1'
DISPLAY FORM f_ring
CALL display_titulos_rub_ing()
LET vm_max_ring	= 200
LET vm_max_regr	= 200
LET vm_max_rtra	= 300
MENU 'OPCIONES'
	COMMAND KEY('I') 'Aux. Ingresos' 
		'Configuración auxiliares contables para rubros de ingresos.'
		CALL control_rubros_ingresos()
	COMMAND KEY('E') 'Aux. Descuentos' 
		'Configuración auxiliares contables para rubros de descuentos.'
		CALL control_rubros_egresos()
	COMMAND KEY('T') 'Aux. Trabajadores' 
		'Config. auxiliares contables para rubros de descuentos por trabajador.'
		CALL control_rubros_trabajadores()
	COMMAND KEY('P') 'Aux. Pago Efec.' 
		'Auxiliar contable para el pago de nomina en efectivo.'
		CALL control_pago_efectivo()
	COMMAND KEY('S') 'Salir' 'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_rubros_ingresos()

CLEAR FORM
OPEN FORM f_ring FROM '../forms/rolf500_1'
DISPLAY FORM f_ring
WHILE TRUE
	CLEAR FORM
	CALL display_titulos_rub_ing()
	CALL lee_rubro('DI')
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL carga_deptos_rubro_ingreso()
	CALL lee_auxiliares_ingresos()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL grabar_rolt050()
	CALL fl_mensaje_registro_ingresado()
END WHILE

END FUNCTION



FUNCTION control_rubros_egresos()

CLEAR FORM
OPEN FORM f_regr FROM '../forms/rolf500_2'
DISPLAY FORM f_regr
CALL display_titulos_rub_egr()
CALL carga_rubros_egresos()
CALL lee_auxiliares_egresos()
IF int_flag THEN
	RETURN
END IF
CALL grabar_rolt051()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_rubros_trabajadores()

CLEAR FORM
OPEN FORM f_rtra FROM '../forms/rolf500_3'
DISPLAY FORM f_rtra
WHILE TRUE
	CLEAR FORM
	CALL display_titulos_rub_tra()
	CALL lee_rubro('TT')
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL carga_trab_rubro_egresos()
	CALL lee_auxiliares_trabajadores()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL grabar_rolt052()
	CALL fl_mensaje_registro_ingresado()
END WHILE

END FUNCTION



FUNCTION control_pago_efectivo()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE resul		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0          
LET row_ini  = 9          
LET num_rows = 7         
LET num_cols = 73         
IF vg_gui = 0 THEN        
	LET lin_menu = 1                                                        
	LET row_ini  = 2
	LET num_rows = 22 
	LET num_cols = 78 
END IF                  
OPEN WINDOW w_rol_pag AT row_ini, 5 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST)
OPEN FORM f_pago FROM '../forms/rolf500_4'
DISPLAY FORM f_pago
SELECT MAX(b01_nivel) INTO nivel FROM ctbt001
IF nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_n54.* TO NULL
DECLARE q_n54 CURSOR FOR SELECT * FROM rolt054
OPEN q_n54
FETCH q_n54 INTO rm_n54.*
CALL fl_lee_cuenta(vg_codcia, rm_n54.n54_aux_cont) RETURNING r_b10.*
DISPLAY BY NAME r_b10.b10_descripcion
LET int_flag = 0
INPUT BY NAME rm_n54.n54_aux_cont WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n54_aux_cont) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, nivel)
                                RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
                        LET int_flag = 0
                        IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n54.n54_aux_cont = r_b10.b10_cuenta
                                DISPLAY BY NAME rm_n54.n54_aux_cont,
						r_b10.b10_descripcion
                        END IF
                END IF
	AFTER FIELD n54_aux_cont
                IF rm_n54.n54_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_n54.n54_aux_cont, nivel)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n54_aux_cont
			END IF
		ELSE
			CLEAR b10_descripcion
                END IF
END INPUT
IF NOT int_flag THEN
	BEGIN WORK
		DELETE FROM rolt054 WHERE 1 = 1
		INSERT INTO rolt054 VALUES(rm_n54.*)
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
END IF
CLOSE q_n54
FREE q_n54
CLOSE WINDOW w_rol_pag
RETURN

END FUNCTION



FUNCTION validar_cuenta(aux_cont, nivel)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE r_b10            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_b10.*
IF r_b10.b10_cuenta IS NULL  THEN
	CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
DISPLAY BY NAME r_b10.b10_descripcion
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



FUNCTION display_titulos_rub_ing()

DISPLAY 'Cod.'          TO tit_col1
DISPLAY 'Departamento'  TO tit_col2
DISPLAY 'Cuenta'        TO tit_col3
DISPLAY 'Nombre Cuenta' TO tit_col4

END FUNCTION



FUNCTION display_titulos_rub_egr()

DISPLAY 'Cod.'          TO tit_col1
DISPLAY 'Rubro Roles '  TO tit_col2
DISPLAY 'Cuenta'        TO tit_col3
DISPLAY 'Nombre Cuenta' TO tit_col4

END FUNCTION



FUNCTION display_titulos_rub_tra()

DISPLAY 'Cod.'          TO tit_col1
DISPLAY 'Trabajador  '  TO tit_col2
DISPLAY 'Cuenta'        TO tit_col3
DISPLAY 'Nombre Cuenta' TO tit_col4

END FUNCTION



FUNCTION carga_deptos_rubro_ingreso()
DEFINE i		SMALLINT

DECLARE q_depto CURSOR FOR SELECT g34_cod_depto, g34_nombre, '', '' 
	FROM gent034
	WHERE g34_compania = vg_codcia
	ORDER BY 2
LET i = 1
FOREACH q_depto INTO rm_ring[i].*
	LET rm_ring[i].n50_aux_cont = NULL
	SELECT n50_aux_cont, b10_descripcion 
		INTO rm_ring[i].n50_aux_cont, rm_ring[i].tit_cuenta
		FROM rolt050, ctbt010
		WHERE n50_compania  = vg_codcia    AND 
		      n50_cod_rubro = vm_cod_rubro AND 
		      n50_cod_depto = rm_ring[i].n50_cod_depto AND
		      n50_compania  = b10_compania AND
		      n50_aux_cont  = b10_cuenta
	LET i = i + 1
	IF i > vm_max_ring THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ring	= i - 1

END FUNCTION



FUNCTION carga_rubros_egresos()
DEFINE i		SMALLINT

DECLARE q_rubrito CURSOR FOR SELECT n06_cod_rubro, n06_nombre, '', '' 
	FROM rolt006
	WHERE n06_det_tot = 'DE' AND n06_cant_valor = 'V'
	ORDER BY 1
LET i = 1
FOREACH q_rubrito INTO rm_regr[i].*
	LET rm_regr[i].n51_aux_cont = NULL
	SELECT n51_aux_cont, b10_descripcion 
		INTO rm_regr[i].n51_aux_cont, rm_regr[i].tit_cuenta
		FROM rolt051, ctbt010
		WHERE n51_compania  = vg_codcia    AND 
		      n51_cod_rubro = rm_regr[i].n51_cod_rubro AND 
		      n51_compania  = b10_compania AND
		      n51_aux_cont  = b10_cuenta
	LET i = i + 1
	IF i > vm_max_regr THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_regr	= i - 1

END FUNCTION



FUNCTION carga_trab_rubro_egresos()
DEFINE i		SMALLINT

DECLARE q_rtrab CURSOR FOR
	SELECT n30_cod_trab, n30_nombres, '', '' 
		FROM rolt030
		WHERE n30_compania = vg_codcia
		  AND n30_estado   = 'A'
		ORDER BY 2
LET i = 1
FOREACH q_rtrab INTO rm_rtra[i].*
	LET rm_rtra[i].n52_aux_cont = NULL
	SELECT n52_aux_cont, b10_descripcion 
		INTO rm_rtra[i].n52_aux_cont, rm_rtra[i].tit_cuenta
		FROM rolt052, ctbt010
		WHERE n52_compania  = vg_codcia    AND 
		      n52_cod_rubro = vm_cod_rubro AND 
		      n52_cod_trab  = rm_rtra[i].n52_cod_trab AND
		      n52_compania  = b10_compania AND
		      n52_aux_cont  = b10_cuenta
	LET i = i + 1
	IF i > vm_max_rtra THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rtra	= i - 1

END FUNCTION


FUNCTION lee_rubro(flag_rubro)
DEFINE flag_rubro	LIKE rolt006.n06_det_tot
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE etiqueta 	CHAR(9)

OPTIONS INPUT NO WRAP
LET int_flag = 0
LET vm_cod_rubro = NULL
INPUT BY NAME vm_cod_rubro WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		RETURN
	ON KEY(F2)
		CALL fl_ayuda_rubros_generales_roles('00', 
				'V', 'T', 'T', 'T', 'T')
			RETURNING r_n06.n06_cod_rubro, r_n06.n06_nombre
		IF r_n06.n06_cod_rubro IS NOT NULL THEN
			LET vm_cod_rubro = r_n06.n06_cod_rubro
			DISPLAY BY NAME vm_cod_rubro, r_n06.n06_nombre
		END IF
		LET int_flag = 0
	AFTER FIELD vm_cod_rubro
		IF vm_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(vm_cod_rubro)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NULL THEN
				CALL fl_mostrar_mensaje('Rubro de roles no existe.','exclamation')
				NEXT FIELD vm_cod_rubro
			END IF
			DISPLAY BY NAME r_n06.n06_nombre
			IF r_n06.n06_estado = 'B' THEN
				CALL fl_mostrar_mensaje('El rubro esta bloqueado.', 'exclamation')
				NEXT FIELD vm_cod_rubro
			END IF
			IF flag_rubro <> 'TT' THEN
				IF r_n06.n06_det_tot <> flag_rubro OR
				   r_n06.n06_cant_valor <> 'V'
				THEN
					LET etiqueta = 'descuento'
					IF flag_rubro = 'DI' THEN
						LET etiqueta = 'ingreso'
					END IF
					CALL fl_mostrar_mensaje('Rubro debe ser de ' || etiqueta || ' y de valor.', 'exclamation')
					NEXT FIELD vm_cod_rubro
				END IF
			ELSE
				IF (r_n06.n06_det_tot <> 'DI' AND
				    r_n06.n06_det_tot <> 'DE') OR
				    r_n06.n06_cant_valor <> 'V'
				THEN
					CALL fl_mostrar_mensaje('Rubro debe ser de ingreso o descuento, y de valor.', 'exclamation')
					NEXT FIELD vm_cod_rubro
				END IF
			END IF
		ELSE
			CLEAR n06_nombre
		END IF
END INPUT

END FUNCTION



FUNCTION lee_auxiliares_ingresos()
DEFINE i, j		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*

WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_ring)
	OPTIONS INSERT KEY F15,
		DELETE KEY F16
	INPUT ARRAY rm_ring WITHOUT DEFAULTS FROM rm_ring.*	
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
		BEFORE INSERT	
			LET int_flag = 2
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		ON KEY(F2)
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_ring[i].n50_aux_cont = r_b10.b10_cuenta
				DISPLAY rm_ring[i].n50_aux_cont TO 
					rm_ring[j].n50_aux_cont
			END IF 
		AFTER FIELD n50_aux_cont
			IF rm_ring[i].n50_aux_cont IS NOT NULL THEN
				CALL fl_lee_cuenta(vg_codcia, rm_ring[i].n50_aux_cont)
					RETURNING r_b10.*
				IF r_b10.b10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Cuenta no existe.', 'exclamation')
					NEXT FIELD n50_aux_cont
				END IF
				LET rm_ring[i].tit_cuenta = r_b10.b10_descripcion 
				DISPLAY rm_ring[i].tit_cuenta TO
					rm_ring[j].tit_cuenta
				IF r_b10.b10_permite_mov = 'N' THEN
					CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
					NEXT FIELD n50_aux_cont
				END IF
			ELSE
				LET rm_ring[i].tit_cuenta = NULL
				CLEAR rm_ring[j].tit_cuenta
			END IF
	END INPUT
	IF int_flag <= 1 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_auxiliares_egresos()
DEFINE i, j		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*

WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_regr)
	OPTIONS INSERT KEY F15,
		DELETE KEY F16
	INPUT ARRAY rm_regr WITHOUT DEFAULTS FROM rm_regr.*	
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
		BEFORE INSERT	
			LET int_flag = 2
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		ON KEY(F2)
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_regr[i].n51_aux_cont = r_b10.b10_cuenta
				DISPLAY rm_regr[i].n51_aux_cont TO 
					rm_regr[j].n51_aux_cont
			END IF 
		AFTER FIELD n51_aux_cont
			IF rm_regr[i].n51_aux_cont IS NOT NULL THEN
				CALL fl_lee_cuenta(vg_codcia, rm_regr[i].n51_aux_cont)
					RETURNING r_b10.*
				IF r_b10.b10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Cuenta no existe.', 'exclamation')
					NEXT FIELD n51_aux_cont
				END IF
				LET rm_regr[i].tit_cuenta = r_b10.b10_descripcion 
				DISPLAY rm_regr[i].tit_cuenta TO
					rm_regr[j].tit_cuenta
				IF r_b10.b10_permite_mov = 'N' THEN
					CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
					NEXT FIELD n51_aux_cont
				END IF
			ELSE
				LET rm_regr[i].tit_cuenta = NULL
				CLEAR rm_regr[j].tit_cuenta
			END IF
	END INPUT
	IF int_flag <= 1 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_auxiliares_trabajadores()
DEFINE i, j		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*

WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_rtra)
	OPTIONS INSERT KEY F15,
		DELETE KEY F16
	INPUT ARRAY rm_rtra WITHOUT DEFAULTS FROM rm_rtra.*	
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
		BEFORE INSERT	
			LET int_flag = 2
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		ON KEY(F2)
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_ayuda_cuenta_contable(vg_codcia, 6)
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_rtra[i].n52_aux_cont = r_b10.b10_cuenta
				LET rm_rtra[i].tit_cuenta   =
							r_b10.b10_descripcion 
				DISPLAY rm_rtra[i].n52_aux_cont TO 
					rm_rtra[j].n52_aux_cont
				DISPLAY rm_rtra[i].tit_cuenta TO 
					rm_rtra[j].tit_cuenta
			END IF 
		AFTER FIELD n52_aux_cont
			IF rm_rtra[i].n52_aux_cont IS NOT NULL THEN
				CALL fl_lee_cuenta(vg_codcia, rm_rtra[i].n52_aux_cont)
					RETURNING r_b10.*
				IF r_b10.b10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Cuenta no existe.', 'exclamation')
					NEXT FIELD n52_aux_cont
				END IF
				LET rm_rtra[i].tit_cuenta = r_b10.b10_descripcion 
				DISPLAY rm_rtra[i].tit_cuenta TO
					rm_rtra[j].tit_cuenta
				IF r_b10.b10_permite_mov = 'N' THEN
					CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
					NEXT FIELD n52_aux_cont
				END IF
			ELSE
				LET rm_rtra[i].tit_cuenta = NULL
				CLEAR rm_rtra[j].tit_cuenta
			END IF
	END INPUT
	IF int_flag <= 1 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION grabar_rolt050()
DEFINE i		SMALLINT

DELETE FROM rolt050
	WHERE n50_compania  = vg_codcia AND
	      n50_cod_rubro = vm_cod_rubro
FOR i = 1 TO vm_num_ring 
	IF rm_ring[i].n50_aux_cont IS NULL THEN
		CONTINUE FOR
	END IF
	INSERT INTO rolt050 VALUES (vg_codcia, vm_cod_rubro, 
				    rm_ring[i].n50_cod_depto,
				    rm_ring[i].n50_aux_cont)
END FOR

END FUNCTION



FUNCTION grabar_rolt051()
DEFINE i		SMALLINT

DELETE FROM rolt051
	WHERE n51_compania = vg_codcia
FOR i = 1 TO vm_num_regr 
	IF rm_regr[i].n51_aux_cont IS NULL THEN
		CONTINUE FOR
	END IF
	INSERT INTO rolt051 VALUES (vg_codcia, rm_regr[i].n51_cod_rubro,
				    rm_regr[i].n51_aux_cont)
END FOR

END FUNCTION



FUNCTION grabar_rolt052()
DEFINE i		SMALLINT

DELETE FROM rolt052
	WHERE n52_compania  = vg_codcia AND
	      n52_cod_rubro = vm_cod_rubro
FOR i = 1 TO vm_num_rtra 
	IF rm_rtra[i].n52_aux_cont IS NULL THEN
		CONTINUE FOR
	END IF
	INSERT INTO rolt052 VALUES (vg_codcia, vm_cod_rubro, 
				    rm_rtra[i].n52_cod_trab,
				    rm_rtra[i].n52_aux_cont)
END FOR

END FUNCTION



