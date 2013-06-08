------------------------------------------------------------------------------
-- Titulo           : ctbp309.4gl - Consulta de saldos de bancos
-- Elaboracion      : 16-ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp309 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_ctb2		RECORD LIKE ctbt012.*
DEFINE rm_ctb3		RECORD LIKE ctbt013.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_cuenta	ARRAY[50] OF RECORD
				cuenta		LIKE gent009.g09_aux_cont,
				tit_cuenta	VARCHAR(70)
			END RECORD
DEFINE rm_det		ARRAY[50] OF RECORD
				b10_descripcion LIKE gent008.g08_nombre,
				tit_saldo_ini	DECIMAL(14,2),
				tit_debito	DECIMAL(14,2),
				tit_credito	DECIMAL(14,2),
				tit_saldo	DECIMAL(14,2)
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp309.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp309'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CREATE TEMP TABLE temp_saldos(
	descripcion	VARCHAR(30),
	saldo_ini	DECIMAL(14,2),
	debito		DECIMAL(14,2),
	credito		DECIMAL(14,2),
	saldo_fin	DECIMAL(14,2),
	cuenta		CHAR(12),
	cuenta_des	VARCHAR(70))
CALL fl_nivel_isolation()
LET vm_max_det = 50
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf309_1"
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
DEFINE query2		VARCHAR(1000)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE nom_banco	LIKE gent008.g08_nombre
DEFINE fecha		DATE
DEFINE debito		DECIMAL(14,2)
DEFINE credito		DECIMAL(14,2)

LET vm_fecha_ini       = TODAY
LET vm_fecha_fin       = TODAY
LET rm_ctb2.b12_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_ctb2.b12_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY BY NAME rm_ctb2.b12_moneda, vm_fecha_ini, vm_fecha_fin
DISPLAY r_mon.g13_nombre TO tit_moneda
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET query = 'SELECT * FROM gent009 ',
			'WHERE g09_compania = ', vg_codcia
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET vm_num_det = 1
	FOREACH q_deto INTO r_g09.*
		LET query2 = 'SELECT * FROM ctbt013 ',
				'WHERE b13_compania = ', vg_codcia,
				'  AND b13_cuenta   = "',r_g09.g09_aux_cont,'"',
				'  AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
				'" AND "', vm_fecha_fin, '"',
				' ORDER BY b13_fec_proceso '
		PREPARE deto2 FROM query2
		DECLARE q_deto2 CURSOR FOR deto2
		LET debito  = 0
		LET credito = 0
		FOREACH q_deto2 INTO rm_ctb3.*
			CALL fl_lee_comprobante_contable(vg_codcia,
					rm_ctb3.b13_tipo_comp,
					rm_ctb3.b13_num_comp)
				RETURNING r_b12.*
			IF r_b12.b12_estado = "E"
			  OR r_b12.b12_moneda <> rm_ctb2.b12_moneda THEN
				CONTINUE FOREACH
			END IF
			CALL obtener_valores_deb_cre(debito, credito)
				RETURNING debito, credito
		END FOREACH
		LET vm_cuenta[vm_num_det].cuenta   = r_g09.g09_aux_cont
		CALL nombre_banco(r_g09.g09_banco, r_g09.g09_tipo_cta,
				r_g09.g09_numero_cta)
			RETURNING vm_cuenta[vm_num_det].tit_cuenta, nom_banco
		LET rm_det[vm_num_det].b10_descripcion = nom_banco
		LET fecha = vm_fecha_ini - 1 UNITS DAY
		CALL fl_obtiene_saldo_contable(vg_codcia,
				vm_cuenta[vm_num_det].cuenta,
				rm_ctb2.b12_moneda, fecha, 'A')
			RETURNING rm_det[vm_num_det].tit_saldo_ini
		LET rm_det[vm_num_det].tit_debito  = debito 
		LET rm_det[vm_num_det].tit_credito = credito
		LET rm_det[vm_num_det].tit_saldo   =
			rm_det[vm_num_det].tit_saldo_ini +
			rm_det[vm_num_det].tit_debito + 
			rm_det[vm_num_det].tit_credito
		INSERT INTO temp_saldos
			VALUES (rm_det[vm_num_det].b10_descripcion,
				rm_det[vm_num_det].tit_saldo_ini,
				rm_det[vm_num_det].tit_debito,
				rm_det[vm_num_det].tit_credito,
				rm_det[vm_num_det].tit_saldo,
				vm_cuenta[vm_num_det].*)
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CALL set_count(vm_num_det)
	CALL sacar_total()
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 5
	LET vm_columna_2 = 1
	LET col          = 5
	WHILE TRUE
		LET query = 'SELECT * FROM temp_saldos ',
			     " ORDER BY ", vm_columna_1, ' ',
				rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ',
				rm_orden[vm_columna_2]
		PREPARE cons FROM query
		DECLARE q_cons CURSOR FOR cons
		LET i = 1
		FOREACH q_cons INTO rm_det[i].*, vm_cuenta[i].*
			LET i = i + 1
			IF i > vm_num_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
			BEFORE ROW
				LET j = arr_curr()
				LET l = scr_line()
				CALL muestra_contadores_det(j)
				DISPLAY BY NAME vm_cuenta[j].tit_cuenta
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL ver_movimientos(j)
				LET int_flag = 0
			ON KEY(F6)
				CALL imprimir(vm_columna_1 + 1,
			        	      vm_columna_2 + 1,
					      rm_orden[vm_columna_1],
					      rm_orden[vm_columna_2])
				LET int_flag = 0
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F18)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F19)
				LET col = 5
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
	DELETE FROM temp_saldos
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE fecha_fin	DATE

INITIALIZE mone_aux, r_mon.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_ctb2.b12_moneda, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(rm_ctb2.b12_moneda) THEN
       	       		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
    			LET int_flag = 0
               	       	IF mone_aux IS NOT NULL THEN
                      	      	LET rm_ctb2.b12_moneda = mone_aux
                       		DISPLAY BY NAME rm_ctb2.b12_moneda
                       		DISPLAY nomm_aux TO tit_moneda
                       	END IF
       	        END IF
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD b12_moneda
            	IF rm_ctb2.b12_moneda IS NOT NULL THEN
	        	CALL fl_lee_moneda(rm_ctb2.b12_moneda)
				RETURNING r_mon.*
	              	IF r_mon.g13_moneda IS NULL THEN
 	                      	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
        	               	NEXT FIELD b12_moneda
                       	END IF
	        ELSE
        	       	LET rm_ctb2.b12_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_ctb2.b12_moneda)
				RETURNING r_mon.*
	               	DISPLAY BY NAME rm_ctb2.b12_moneda
        	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_fin < vm_fecha_ini THEN
			CALL fgl_winmessage(vg_producto,'La fecha final debe ser mayor a la fecha de inicial.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
END INPUT

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR b12_moneda, tit_moneda, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_ctb2.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
CLEAR tit_total_ini, tit_total_deb, tit_total_cre, tit_total_fin, tit_cuenta
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 4, 66
DISPLAY cor, " de ", vm_num_det AT 4, 70

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

DISPLAY 'Bancos' 	TO tit_col1
DISPLAY 'Saldo Inicial' TO tit_col2
DISPLAY 'Débitos'       TO tit_col3
DISPLAY 'Créditos'      TO tit_col4
DISPLAY 'Saldo Final'   TO tit_col5

END FUNCTION



FUNCTION ver_movimientos(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, '; fglrun ctbp302 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', '"', vm_cuenta[i].cuenta, '"',
	' ', vm_fecha_ini, ' ', vm_fecha_fin, ' ', '"', rm_ctb2.b12_moneda, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprimir(col1, col2, ord1, ord2)
DEFINE col1, col2	SMALLINT
DEFINE ord1, ord2	CHAR(4)

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, '; fglrun ctbp407 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' "', rm_ctb2.b12_moneda, '" ',
	vm_fecha_ini, ' ', vm_fecha_fin, ' ', col1, ' ', col2, ' "', ord1,
	'" "', ord2, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION obtener_valores_deb_cre(deb, cred)
DEFINE deb		DECIMAL(14,2)
DEFINE cred		DECIMAL(14,2)

IF rm_ctb2.b12_moneda = rg_gen.g00_moneda_base THEN
	IF rm_ctb3.b13_valor_base >= 0 THEN
		LET deb  = deb  + rm_ctb3.b13_valor_base
	ELSE
		LET cred = cred + rm_ctb3.b13_valor_base
	END IF
ELSE
	IF rm_ctb3.b13_valor_aux >= 0 THEN
		LET deb  = deb  + rm_ctb3.b13_valor_aux
	ELSE
		LET cred = cred + rm_ctb3.b13_valor_aux
	END IF
END IF
RETURN deb, cred

END FUNCTION



FUNCTION sacar_total()
DEFINE tit_total_ini	DECIMAL(14,2)
DEFINE tit_total_deb	DECIMAL(14,2)
DEFINE tit_total_cre	DECIMAL(14,2)
DEFINE tit_total_fin	DECIMAL(14,2)
DEFINE i		SMALLINT

LET tit_total_ini = 0
LET tit_total_deb = 0
LET tit_total_cre = 0
LET tit_total_fin = 0
FOR i = 1 TO vm_num_det
	LET tit_total_ini = tit_total_ini + rm_det[i].tit_saldo_ini
	LET tit_total_deb = tit_total_deb + rm_det[i].tit_debito
	LET tit_total_cre = tit_total_cre + rm_det[i].tit_credito
	LET tit_total_fin = tit_total_fin + rm_det[i].tit_saldo
END FOR
DISPLAY BY NAME tit_total_ini, tit_total_deb, tit_total_cre, tit_total_fin

END FUNCTION



FUNCTION nombre_banco(banco, tipo_cta, numero)
DEFINE banco		LIKE gent009.g09_banco
DEFINE tipo_cta		LIKE gent009.g09_tipo_cta
DEFINE numero		LIKE gent009.g09_numero_cta
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE tipo_des		VARCHAR(10)
DEFINE descrip		VARCHAR(70)

CALL fl_lee_banco_general(banco) RETURNING r_g08.*
LET tipo_des = 'Cta. Aho. '
IF tipo_cta = 'C' THEN
	LET tipo_des = 'Cta. Cte. '
END IF
LET descrip = r_g08.g08_nombre CLIPPED, ' (', tipo_des CLIPPED, ' ',
		numero CLIPPED, ')' 
RETURN descrip, r_g08.g08_nombre

END FUNCTION
