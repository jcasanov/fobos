------------------------------------------------------------------------------
-- Titulo           : ctbp301.4gl - Consulta del plan de cuentas
-- Elaboracion      : 10-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp301 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_ctb		RECORD LIKE ctbt010.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_moneda	LIKE ctbt011.b11_moneda
DEFINE vm_anio		SMALLINT
DEFINE vm_mes		SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				b10_cuenta	LIKE ctbt010.b10_cuenta,
				b10_descripcion	LIKE ctbt010.b10_descripcion,
				tit_saldo	DECIMAL(14,2)
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ctbp301'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 1000
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf301_1"
DISPLAY FORM f_ctb
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_sql         VARCHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE fecha		DATE

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY BY NAME vm_moneda
DISPLAY r_mon.g13_nombre TO tit_moneda_des
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag THEN
		EXIT WHILE
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET col          = 1
	WHILE TRUE
		LET query = 'SELECT b10_cuenta, b10_descripcion ',
				'FROM ctbt010 ',
				'WHERE b10_compania = ', vg_codcia,
				'  AND ', expr_sql CLIPPED,
				" ORDER BY ", vm_columna_1, ' ',
					rm_orden[vm_columna_1],
			        	', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].b10_cuenta,
				rm_det[vm_num_det].b10_descripcion
			IF vm_anio IS NOT NULL THEN
				LET fecha = MDY(vm_mes, 1, vm_anio) +
					    1 UNITS MONTH - 1 UNITS DAY
				CALL fl_obtiene_saldo_contable(vg_codcia,
						rm_det[vm_num_det].b10_cuenta,
						vm_moneda, fecha, 'A')
					RETURNING rm_det[vm_num_det].tit_saldo
			ELSE
				LET rm_det[vm_num_det].tit_saldo = NULL
			END IF
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			EXIT WHILE
		END IF
		IF vm_anio IS NULL THEN
			DISPLAY '            ' TO tit_col3
		ELSE
			DISPLAY 'Saldo Cuenta' TO tit_col3
		END IF
		CALL set_count(vm_num_det)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			BEFORE DISPLAY
				CALL dialog.keysetlabel('ACCEPT','')
			BEFORE ROW
				LET j = arr_curr()
				LET l = scr_line()
				CALL muestra_contadores_det(j)
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL ver_cuenta(j)
				LET int_flag = 0
			ON KEY(F6)
				CALL ver_movimientos(j)
				LET int_flag = 0
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
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
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE expr_sql		VARCHAR(600)
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE cniv_aux         LIKE ctbt001.b01_nivel
DEFINE nniv_aux         LIKE ctbt001.b01_nombre
DEFINE psi_aux          LIKE ctbt001.b01_posicion_i
DEFINE psf_aux          LIKE ctbt001.b01_posicion_f

OPTIONS INPUT NO WRAP
CLEAR tit_nivel
INITIALIZE expr_sql, cod_aux, cniv_aux TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b10_nivel, b10_cuenta, b10_descripcion
	ON KEY(INTERRUPT)
		RETURN expr_sql
	ON KEY(F2)
		IF INFIELD(b10_nivel) THEN
			CALL fl_ayuda_nivel_cuentas()
				RETURNING cniv_aux, nniv_aux, psi_aux, psf_aux
			LET int_flag = 0
			IF cniv_aux IS NOT NULL THEN
				DISPLAY cniv_aux TO b10_nivel 
				DISPLAY nniv_aux TO tit_nivel
			END IF 
		END IF
		IF INFIELD(b10_cuenta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia,6)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO b10_cuenta 
				DISPLAY nom_aux TO b10_descripcion
			END IF 
		END IF
	AFTER CONSTRUCT
		CALL lee_parametros2()
		IF int_flag THEN
			OPTIONS INPUT NO WRAP
			NEXT FIELD b10_nivel
		END IF
END CONSTRUCT
RETURN expr_sql

END FUNCTION



FUNCTION lee_parametros2()
DEFINE mes_des		CHAR(11)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales

OPTIONS INPUT WRAP
INITIALIZE mone_aux TO NULL
LET int_flag = 0
INPUT BY NAME vm_moneda, vm_anio, vm_mes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		RETURN
	ON KEY(F2)
		IF INFIELD(vm_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET vm_moneda = mone_aux
                               	DISPLAY BY NAME vm_moneda
                               	DISPLAY nomm_aux TO tit_moneda_des
                       	END IF
                END IF
		IF INFIELD(vm_mes) THEN
			CALL mostrar_meses()
			IF vm_mes IS NOT NULL THEN
				DISPLAY BY NAME vm_mes
				CALL fl_retorna_nombre_mes(vm_mes)
					RETURNING mes_des
				DISPLAY mes_des TO tit_mes_des
			END IF
                END IF
	AFTER FIELD vm_moneda
               	IF vm_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(vm_moneda) RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
                               	NEXT FIELD vm_moneda
                       	END IF
               	ELSE
                       	LET vm_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(vm_moneda) RETURNING r_mon.*
                       	DISPLAY BY NAME vm_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda_des
	AFTER FIELD vm_mes
		IF vm_mes IS NOT NULL THEN
			IF vm_mes < 1 OR vm_mes > 12 THEN
				CALL fgl_winmessage(vg_producto,'Mes está incorrecto.','exclamation')
				NEXT FIELD vm_mes
			END IF
			CALL fl_retorna_nombre_mes(vm_mes) RETURNING mes_des
			DISPLAY mes_des TO tit_mes_des
		ELSE
			CLEAR tit_mes_des
		END IF
	AFTER INPUT
		IF vm_anio IS NOT NULL THEN
			IF vm_mes IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresar también el mes.','exclamation')
				NEXT FIELD vm_mes
			END IF
		END IF
		IF vm_mes IS NOT NULL THEN
			IF vm_anio IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresar también el año.','exclamation')
				NEXT FIELD vm_anio
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION mostrar_meses()
DEFINE i,j		SMALLINT
DEFINE r_meses		ARRAY [12] OF RECORD
				tit_mes		SMALLINT,
				tit_mes_des	CHAR(11)
			END RECORD

OPEN WINDOW w_mes AT 07,61
        WITH FORM '../forms/ctbf301_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0,
                   BORDER)
DISPLAY 'No.' TO tit_col4
DISPLAY 'Mes' TO tit_col5
FOR i = 1 TO 12
	LET r_meses[i].tit_mes = i
	CALL fl_retorna_nombre_mes(i) RETURNING r_meses[i].tit_mes_des
END FOR
CALL set_count(12)
LET int_flag = 0
DISPLAY ARRAY r_meses TO r_meses.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER DISPLAY
		LET vm_mes = r_meses[i].tit_mes
END DISPLAY
CLOSE WINDOW w_mes
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR b10_nivel, tit_nivel, b10_cuenta, b10_descripcion, vm_moneda, 
	tit_moneda_des, vm_anio, vm_mes, tit_mes_des
INITIALIZE rm_ctb.*, vm_moneda, vm_mes, vm_anio TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 4, 60
DISPLAY cor, " de ", vm_num_det AT 4, 64

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

DISPLAY 'Cuenta'       TO tit_col1
DISPLAY 'Descripción'  TO tit_col2
DISPLAY 'Saldo Cuenta' TO tit_col3

END FUNCTION



FUNCTION ver_cuenta(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, '; fglrun ctbp106 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', '"', rm_det[i].b10_cuenta, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_movimientos(i)
DEFINE fecha_fin	DATE
DEFINE i		SMALLINT

IF vm_anio IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Esta cuenta no tiene saldo y movimientos.','exclamation')
	RETURN
END IF
IF vm_mes = 12 THEN
	LET fecha_fin = mdy(1,1,vm_anio + 1) - 1
ELSE
	LET fecha_fin = mdy(vm_mes + 1,1,vm_anio) - 1
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, '; fglrun ctbp302 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', '', rm_det[i].b10_cuenta, '',
	' ', mdy(vm_mes,1,vm_anio), ' ', fecha_fin, ' ', '', vm_moneda, ''
display vm_nuevoprog
RUN vm_nuevoprog

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
