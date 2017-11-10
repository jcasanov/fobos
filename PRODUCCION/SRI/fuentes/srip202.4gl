--------------------------------------------------------------------------------
-- Titulo              : srip202.4gl -- Mantenimiento anexo de compras
-- Elaboración         : 02-Jun-2007
-- Autor               : NPC
-- Formato de Ejecución: fglrun srip202 Base Modulo Compañía Localidad
-- Ultima Correción    : 
-- Motivo Corrección   : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD
						anio_ini	SMALLINT,
						mes_ini		SMALLINT,
						anio_fin	SMALLINT,
						mes_fin		SMALLINT,
						col_ord		SMALLINT
					END RECORD
DEFINE rm_colord	ARRAY[33] OF RECORD
						num_cols	SMALLINT,
						des_cols	VARCHAR(40)
					END RECORD
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
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
DEFINE fecha		DATE

CALL fl_nivel_isolation()
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 8
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_srif202_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_srif202_1 FROM '../forms/srif202_1'
ELSE
	OPEN FORM f_srif202_1 FROM '../forms/srif202_1c'
END IF
DISPLAY FORM f_srif202_1
INITIALIZE rm_par.* TO NULL
LET fecha = MDY(MONTH(vg_fecha), 01, YEAR(vg_fecha)) -- 1 UNITS DAY
LET rm_par.anio_ini = YEAR(fecha)
LET rm_par.mes_ini  = MONTH(fecha)
LET rm_par.anio_fin = YEAR(fecha)
LET rm_par.mes_fin  = MONTH(fecha)
LET rm_par.col_ord  = 1
CALL cargar_ordamiento()
DISPLAY rm_colord[rm_par.col_ord].des_cols TO tit_col_ord
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ejecuta_proceso(1)
	CALL ejecuta_proceso(2)
	CALL fl_mostrar_mensaje('Archivo Generado OK.', 'info')
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp      	CHAR(6)
DEFINE ano_i, ano_f	SMALLINT
DEFINE mes_i, mes_f	SMALLINT
DEFINE fec_ini, fec_fin	DATE
DEFINE col		SMALLINT
DEFINE des		VARCHAR(40)

LET int_flag = 0 
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_par.*) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(col_ord) THEN
			CALL tipo_ordenamiento() RETURNING col, des
			LET int_flag = 0
			IF col IS NOT NULL THEN
				LET rm_par.col_ord = col
			ELSE
				LET des = rm_colord[rm_par.col_ord].des_cols
			END IF
			DISPLAY BY NAME rm_par.col_ord
			DISPLAY des TO tit_col_ord
		END IF
	BEFORE FIELD anio_ini
		LET ano_i = rm_par.anio_ini
	BEFORE FIELD mes_ini
		LET mes_i = rm_par.mes_ini
	BEFORE FIELD anio_fin
		LET ano_f = rm_par.anio_fin
	BEFORE FIELD mes_fin
		LET mes_f = rm_par.mes_fin
	AFTER FIELD anio_ini
		IF rm_par.anio_ini IS NULL THEN
			LET rm_par.anio_ini = ano_i
			DISPLAY BY NAME rm_par.anio_ini
		END IF
	AFTER FIELD mes_ini
		IF rm_par.mes_ini IS NULL THEN
			LET rm_par.mes_ini = mes_i
			DISPLAY BY NAME rm_par.mes_ini
		END IF
	AFTER FIELD anio_fin
		IF rm_par.anio_fin IS NULL THEN
			LET rm_par.anio_fin = ano_f
			DISPLAY BY NAME rm_par.anio_fin
		END IF
	AFTER FIELD mes_fin
		IF rm_par.mes_fin IS NULL THEN
			LET rm_par.mes_fin = mes_f
			DISPLAY BY NAME rm_par.mes_fin
		END IF
	AFTER FIELD col_ord
		IF rm_par.col_ord IS NOT NULL THEN
			DISPLAY rm_colord[rm_par.col_ord].num_cols
				TO col_ord
			DISPLAY rm_colord[rm_par.col_ord].des_cols
				TO tit_col_ord
		ELSE
			CLEAR tit_col_ord
		END IF
	AFTER INPUT
		LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
		LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fec_ini > fec_fin THEN
			CALL fl_mostrar_mensaje('El período inicial no puede ser mayor al período final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_ordamiento()

LET rm_colord[01].num_cols = 1
LET rm_colord[01].des_cols = 'Numero Retencion'
LET rm_colord[02].num_cols = 2
LET rm_colord[02].des_cols = 'Modulo'
LET rm_colord[03].num_cols = 3
LET rm_colord[03].des_cols = 'Sustento'
LET rm_colord[04].num_cols = 4
LET rm_colord[04].des_cols = 'Idtipo'
LET rm_colord[05].num_cols = 5
LET rm_colord[05].des_cols = 'Idprov'
LET rm_colord[06].num_cols = 6
LET rm_colord[06].des_cols = 'TC'
LET rm_colord[07].num_cols = 7
LET rm_colord[07].des_cols = 'Establecimiento'
LET rm_colord[08].num_cols = 8
LET rm_colord[08].des_cols = 'P. Emision'
LET rm_colord[09].num_cols = 9
LET rm_colord[09].des_cols = 'Secuencia'
LET rm_colord[10].num_cols = 10
LET rm_colord[10].des_cols = 'Autorizacion'
LET rm_colord[11].num_cols = 11
LET rm_colord[11].des_cols = 'Fecha_reg'
LET rm_colord[12].num_cols = 12
LET rm_colord[12].des_cols = 'Fecha_emi'
LET rm_colord[13].num_cols = 13
LET rm_colord[13].des_cols = 'Fecha_cad'
LET rm_colord[14].num_cols = 14
LET rm_colord[14].des_cols = 'Base_sin'
LET rm_colord[15].num_cols = 15
LET rm_colord[15].des_cols = 'Base_con'
LET rm_colord[16].num_cols = 16
LET rm_colord[16].des_cols = 'Base_ice'
LET rm_colord[17].num_cols = 17
LET rm_colord[17].des_cols = 'Porc_iva'
LET rm_colord[18].num_cols = 18
LET rm_colord[18].des_cols = 'Porc_ice'
LET rm_colord[19].num_cols = 19
LET rm_colord[19].des_cols = 'Monto_iva'
LET rm_colord[20].num_cols = 20
LET rm_colord[20].des_cols = 'Monto_ice'
LET rm_colord[21].num_cols = 21
LET rm_colord[21].des_cols = 'BienesBase'
LET rm_colord[22].num_cols = 22
LET rm_colord[22].des_cols = 'BienesPorc'
LET rm_colord[23].num_cols = 23
LET rm_colord[23].des_cols = 'BienesValor'
LET rm_colord[24].num_cols = 24
LET rm_colord[24].des_cols = 'ServiciosBase'
LET rm_colord[25].num_cols = 25
LET rm_colord[25].des_cols = 'ServiciosPorc'
LET rm_colord[26].num_cols = 26
LET rm_colord[26].des_cols = 'ServiciosValor'
LET rm_colord[27].num_cols = 27
LET rm_colord[27].des_cols = 'Nom_mes'
LET rm_colord[28].num_cols = 28
LET rm_colord[28].des_cols = 'Anio_reg'
LET rm_colord[29].num_cols = 29
LET rm_colord[29].des_cols = 'Usuario'
LET rm_colord[30].num_cols = 30
LET rm_colord[30].des_cols = 'Proveedor'
LET rm_colord[31].num_cols = 31
LET rm_colord[31].des_cols = 'Nom_Prov'
LET rm_colord[32].num_cols = 32
LET rm_colord[32].des_cols = 'Tipo'
LET rm_colord[33].num_cols = 33
LET rm_colord[33].des_cols = 'Numero'
--LET rm_colord[34].num_cols = 34
--LET rm_colord[34].des_cols = 'Dividendo'
LET num_row                = 33
LET max_row                = 33

END FUNCTION



FUNCTION tipo_ordenamiento()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols, i	SMALLINT
DEFINE num_aux		SMALLINT
DEFINE des_aux		VARCHAR(40)

LET lin_menu = 0
LET row_ini  = 7
LET num_rows = 14
LET num_cols = 26
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 6
	LET num_rows = 15
	LET num_cols = 27
END IF
OPEN WINDOW w_srif202_2 AT row_ini, 44 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_srif202_2 FROM '../forms/srif202_2'
ELSE
	OPEN FORM f_srif202_2 FROM '../forms/srif202_2c'
END IF
DISPLAY FORM f_srif202_2
--#DISPLAY "Col."		TO tit_col1
--#DISPLAY "Descripcion"	TO tit_col2
CALL set_count(num_row)
LET int_flag = 0
DISPLAY ARRAY rm_colord TO rm_colord.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
       	ON KEY(RETURN)   
		--#LET i = arr_curr()	
       	        EXIT DISPLAY  
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
END DISPLAY
CLOSE WINDOW w_srif202_2
IF int_flag THEN
	INITIALIZE num_aux, des_aux TO NULL
	RETURN num_aux, des_aux
END IF
LET i = arr_curr()
RETURN rm_colord[i].num_cols, rm_colord[i].des_cols

END FUNCTION



FUNCTION ejecuta_proceso(flag)
DEFINE flag		SMALLINT
DEFINE comando		VARCHAR(400)
DEFINE archivo		VARCHAR(100)
DEFINE long, posi	SMALLINT
DEFINE anio, mes	SMALLINT

FOR anio = rm_par.anio_ini TO rm_par.anio_fin
	FOR mes = rm_par.mes_ini TO rm_par.mes_fin
		LET archivo = ' > anexo_compras_'
		IF flag = 2 THEN
			LET archivo = archivo CLIPPED, 'prov_'
		END IF
		LET archivo = archivo CLIPPED, mes USING "&&", '-',
				anio USING "&&&&", '_', vg_codloc USING "&&",
				'.xml ' 
		LET posi    = 4
		LET comando = 'cd ..', vg_separador, '..', vg_separador, 'SRI',
				vg_separador, 'fuentes', vg_separador,
				'; umask 0002; fglrun srip203 ', vg_base, ' "',
				vg_modulo, '" ', vg_codcia, ' ', vg_codloc, ' ',
				anio, ' ', mes, ' ',
				rm_colord[rm_par.col_ord].num_cols
		IF flag = 2 THEN
			LET comando = comando CLIPPED, ' X '
		END IF
		LET comando = comando CLIPPED, ' ', archivo CLIPPED
		RUN comando
		LET long    = LENGTH(archivo)
		LET archivo = 'unix2dos ', archivo[posi, long] CLIPPED
		RUN archivo
		LET posi    = 10
		LET long    = LENGTH(archivo)
		LET archivo = 'mv ', archivo[posi, long] CLIPPED, ' $HOME/tmp/'
		RUN archivo
	END FOR
END FOR

END FUNCTION
