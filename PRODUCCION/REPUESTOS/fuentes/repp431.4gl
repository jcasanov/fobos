{*
 * Título	    : repp431.4gl - Reporte de Items x Clasificación
 * Elaboracion      : 14-Sept-2011
 * Autor            : MTP
 * Formato Ejecucion: fglrun repp431 base_datos modulo compañía localidad 
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

DEFINE rm_item ARRAY[1000] OF RECORD
        r10_codigo              LIKE rept010.r10_codigo,
        r10_nombre              LIKE rept010.r10_nombre,
        fob                   DECIMAL(12,2),
        precio                  DECIMAL(12,2),
        stock_disp              LIKE rept011.r11_stock_act,
        r11_stock_act  		LIKE rept011.r11_stock_act,
	valact		        VARCHAR(1)
        END RECORD

DEFINE rm_datos ARRAY[1000] OF RECORD
        margen                  DECIMAL(9,0)
END RECORD
DEFINE rm_par RECORD
        moneda          LIKE gent013.g13_moneda,
        tit_moneda      CHAR(20),
        bodega          LIKE rept002.r02_codigo,
        tit_bodega      VARCHAR(20),
        linea           LIKE rept003.r03_codigo,
	clasif_a        CHAR(1),
        clasif_b        CHAR(1),
        clasif_c        CHAR(1),
        clasif_d        CHAR(1),
        clasif_e        CHAR(1)

END RECORD

DEFINE vm_max_rows      SMALLINT

DEFINE rm_g04           RECORD LIKE gent004.*
DEFINE rm_g05           RECORD LIKE gent005.*
DEFINE vm_query         VARCHAR(1000)

DEFINE vm_param         LIKE rept104.r104_codigo

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp431.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
        CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
        EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp431'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN


FUNCTION funcion_master()
DEFINE r                RECORD LIKE gent000.*
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_rep            RECORD LIKE rept000.*
DEFINE r_bod            RECORD LIKE rept002.*
DEFINE i                SMALLINT

CREATE TEMP TABLE temp_item
        (te_item                CHAR(15),
         te_descripcion 	CHAR(40),
         te_fob               	DECIMAL(14,2),
         te_precio              DECIMAL(14,2),
         te_stock_disp  	INTEGER,
         te_stock               INTEGER,
	 te_abc			VARCHAR(1)	)

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*

INITIALIZE rm_par.* TO NULL
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
LET rm_par.tit_moneda = r_mon.g13_nombre
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_rep.*
LET rm_par.bodega = r_rep.r00_bodega_fact
CALL fl_lee_bodega_rep(vg_codcia, r_rep.r00_bodega_fact) RETURNING r_bod.*
LET rm_par.tit_bodega = r_bod.r02_nombre

LET vm_param = 'ABC'

OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
        ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM f_cons FROM '../forms/repf431_1'
DISPLAY FORM f_cons
LET vm_max_rows = 1000
DISPLAY 'Item'           TO tit_col1
DISPLAY 'Descripción'    TO tit_col2
DISPLAY 'Fob'    	 TO tit_col3
DISPLAY 'Disp.'          TO tit_col5
DISPLAY 'Precio Unit.'   TO tit_col4
DISPLAY 'Stock'          TO tit_col6
DISPLAY 'ABC'            TO tit_col7

WHILE TRUE
        FOR i = 1 TO fgl_scr_size('rm_item')
                CLEAR rm_item[i].*
        END FOR
        CALL lee_parametros1()
        IF int_flag THEN
                RETURN
        END IF
	CALL lee_parametros2()
        IF int_flag THEN
                CONTINUE WHILE
        END IF
        CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp             CHAR(3)
DEFINE mon_aux          LIKE gent013.g13_moneda
DEFINE bod_aux          LIKE rept002.r02_codigo
DEFINE lin_aux          LIKE rept003.r03_codigo
DEFINE tit_aux          VARCHAR(30)
DEFINE num_dec          SMALLINT
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE r_bod            RECORD LIKE rept002.*
DEFINE r_lin            RECORD LIKE rept003.*


INITIALIZE rm_par.* TO NULL
LET rm_par.clasif_a = 'S'
LET rm_par.clasif_b = 'S'
LET rm_par.clasif_c = 'S'
LET rm_par.clasif_d = 'S'
LET rm_par.clasif_e = 'S'
LET int_flag = 0

INPUT BY NAME rm_par.* WITHOUT DEFAULTS
        ON KEY(F2)

                IF infield(moneda) THEN
                        CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux,
                                                          num_dec
                        IF mon_aux IS NOT NULL THEN
                                LET rm_par.moneda     = mon_aux
                                LET rm_par.tit_moneda = tit_aux
                                DISPLAY BY NAME rm_par.*
                        END IF
                END IF

                IF infield(bodega) THEN
                       CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T') RETURNING bod_aux, tit_aux
                        IF bod_aux IS NOT NULL THEN
                                LET rm_par.bodega     = bod_aux
                                LET rm_par.tit_bodega = tit_aux
                                DISPLAY BY NAME rm_par.*
                        END IF
                END IF
		IF infield(linea) THEN
                        CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux, tit_aux
                        IF lin_aux IS NOT NULL THEN
                                LET rm_par.linea = lin_aux
                                DISPLAY BY NAME rm_par.*
                        END IF
                END IF
                LET int_flag = 0

	        AFTER FIELD moneda
                IF rm_par.moneda IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
                        IF r_mon.g13_moneda IS NULL THEN
                              CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
                                NEXT FIELD moneda
                        END IF
                        LET rm_par.tit_moneda = r_mon.g13_nombre
                        DISPLAY BY NAME rm_par.tit_moneda
                ELSE
                        LET rm_par.tit_moneda = NULL
                        CLEAR tit_moneda
                END IF

		AFTER FIELD bodega
                IF rm_par.bodega IS NOT NULL THEN
                        CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega) RETURNING r_bod.*
                        IF r_bod.r02_codigo IS NULL THEN
                              CALL fgl_winmessage(vg_producto, 'Bodega no existe', 'exclamation')
                                NEXT FIELD bodega
                        END IF
                        LET rm_par.tit_bodega = r_bod.r02_nombre
                        DISPLAY BY NAME rm_par.tit_bodega
                ELSE
                        LET rm_par.tit_bodega = NULL
                        CLEAR tit_bodega
                END IF
	        AFTER FIELD linea
                IF rm_par.linea IS NOT NULL THEN
                        CALL fl_lee_linea_rep(vg_codcia, rm_par.linea) RETURNING r_lin.*
                        IF r_lin.r03_codigo IS NULL THEN
                               CALL fgl_winmessage(vg_producto, 'Línea no existe', 'exclamation')
                                NEXT FIELD linea
                        END IF
                END IF

		AFTER INPUT

		IF rm_par.clasif_a = 'N' AND rm_par.clasif_b = 'N' AND rm_par.clasif_c = 'N' AND
                   rm_par.clasif_d = 'N' AND rm_par.clasif_e = 'N'
                THEN
                CALL fgl_winmessage(vg_producto, 'Debe pedir items con alguna clasificacion.',
                                                                                         'exclamation')
                        CONTINUE INPUT
                END IF

END INPUT

END FUNCTION


FUNCTION lee_parametros2()
DEFINE i                SMALLINT
DEFINE query            VARCHAR(1000)
DEFINE campos           VARCHAR(50)
DEFINE expr_sql         VARCHAR(200)
DEFINE expr_lin         VARCHAR(100)
DEFINE expr_filtro      VARCHAR(150)
DEFINE te_codigo        CHAR(15)
DEFINE te_nombre        CHAR(40)
DEFINE te_fob         	DECIMAL(14,2)
DEFINE te_precio        DECIMAL(14,2)
DEFINE te_abc        	VARCHAR(1)
DEFINE te_stock         INTEGER

DEFINE te_stock_disp    INTEGER
DEFINE rs               RECORD LIKE rept011.*

DEFINE len              SMALLINT
DEFINE expr_stock       VARCHAR(50)
DEFINE tabla_stock      VARCHAR(15)
DEFINE join_stock       VARCHAR(200)
DEFINE expr_sql2        VARCHAR(200)

DEFINE expr_clasif      VARCHAR(200)

DEFINE clasificacion    VARCHAR(200)
DEFINE query1            VARCHAR(1000)

DEFINE e                SMALLINT

DEFINE inserta_reg	SMALLINT

DELETE FROM temp_item

WHENEVER ERROR CONTINUE
DROP TABLE temp_clasif
WHENEVER ERROR STOP

LET int_flag = 0
IF rm_par.moneda = rg_gen.g00_moneda_base THEN
       LET campos = ' r10_fob, r10_precio_mb precio '
ELSE
        LET campos = ' r10_fob, r10_precio_ma precio '
END IF

IF int_flag THEN
        RETURN
END IF
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_lin = ' '
IF rm_par.linea IS NOT NULL THEN
        LET expr_lin = " AND r10_linea = '", rm_par.linea CLIPPED, "'"
END IF

LET query = 'SELECT r10_codigo, r10_nombre,' ,
		'CASE NVL(r105_valor, r104_valor_default) ',
                        '               WHEN 0 THEN "E" ',
                        '               WHEN 1 THEN "A" ',
                        '               WHEN 2 THEN "B" ',
                        '               WHEN 3 THEN "C" ',
                        '               WHEN 4 THEN "D" ',
                        '               ELSE NULL ',
                        '               END as clasif, ', campos ,
                    '  FROM rept010, rept011, rept104, OUTER rept105 ',
                    ' WHERE r10_compania   = ', vg_codcia,
                        expr_lin CLIPPED,
                        '   AND 1=1 ',
                        '   AND r11_compania   = r10_compania ',
                        '   AND r11_item       = r10_codigo ',
                        '   AND r104_compania  = r10_compania ',
                        '   AND r104_codigo    = "', vm_param CLIPPED, '"',
                        '   AND r105_compania  = r104_compania ',
                        '   AND r105_parametro = r104_codigo ',
                        '   AND r105_item      = r10_codigo ',
                        '   AND r105_fecha_fin IS NULL ' 

LET vm_query = query
PREPARE cit FROM query
DECLARE q_cit CURSOR FOR cit
LET i = 0
LET e = 0
LET inserta_reg = 1

FOREACH q_cit INTO te_codigo, te_nombre,te_abc, te_fob, te_precio

	CASE te_abc

		WHEN 'A'
        		IF  rm_par.clasif_a <> 'S' THEN
                        	LET inserta_reg = 0
        	END IF

	        WHEN 'B'
        	        IF  rm_par.clasif_b <> 'S' THEN
                                LET inserta_reg = 0
                	END IF

	        WHEN 'C'
        	        IF  rm_par.clasif_c <> 'S' THEN
                                LET inserta_reg = 0
                        END IF

	        WHEN 'D'
                        IF  rm_par.clasif_d <> 'S' THEN
                                LET inserta_reg = 0
                        END IF

        	WHEN 'E'
                        IF  rm_par.clasif_e <> 'S' THEN
                                LET inserta_reg = 0
                        END IF

	END CASE
  
	IF inserta_reg = 1 THEN
        
		LET i = i + 1
        	IF i > vm_max_rows THEN
                	EXIT FOREACH
	        END IF
	        
		CALL fl_lee_stock_rep(vg_codcia, rm_par.bodega, te_codigo)
                RETURNING rs.*

        	IF rs.r11_stock_act IS NULL THEN
	                LET rs.r11_stock_act = 0
	        END IF

		LET te_stock_disp = fl_lee_stock_disponible_rep(vg_codcia, vg_codloc,te_codigo,
 		'R')
        	IF te_stock_disp < 0 THEN
                	LET te_stock_disp = 0
       		END IF

                INSERT INTO temp_item VALUES (te_codigo, te_nombre, te_fob, te_precio,
                          te_stock_disp, rs.r11_stock_act,te_abc )

	END IF

END FOREACH


SELECT COUNT(*) INTO i FROM temp_item
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        LET int_flag = 1
        RETURN
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION


FUNCTION muestra_consulta()
DEFINE i                SMALLINT
DEFINE j                SMALLINT
DEFINE query            VARCHAR(300)
DEFINE num_rows         INTEGER
DEFINE comando          VARCHAR(1000)
DEFINE sustituye        SMALLINT
DEFINE r_r10            RECORD LIKE rept010.*

FOR i = 1 TO 10
        LET rm_orden[i] = ''
END FOR
LET vm_columna_1 = 7
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'


WHILE TRUE
        LET query = 'SELECT * FROM temp_item ',
                       'ORDER BY ', 
                        vm_columna_1, ' ', rm_orden[vm_columna_1], ',',
                        vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE crep FROM query
        DECLARE q_crep CURSOR FOR crep
        LET i = 1
        FOREACH q_crep INTO rm_item[i].* 	
		LET i = i + 1
		
                IF i > vm_max_rows THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        FREE q_crep
        LET num_rows = i - 1
        CALL set_count(num_rows)
        DISPLAY ARRAY rm_item TO rm_item.*
                BEFORE ROW
                        LET i = arr_curr()
                        CALL fl_lee_item(vg_codcia, rm_item[i].r10_codigo)
                                RETURNING r_r10.*
                        CALL dialog.keysetlabel('F10', 'Imprimir')

                        MESSAGE i, ' de ', num_rows
                BEFORE DISPLAY
                        CALL dialog.keysetlabel("ACCEPT","")
                AFTER DISPLAY
                        CONTINUE DISPLAY
                ON KEY(INTERRUPT)
                        EXIT DISPLAY
                
		ON KEY(F10)
                        FOR j = 1 TO LENGTH (vm_query)
                                IF vm_query [j,j] = '"' THEN
                                        LET vm_query [j,j] = "'"
                                END IF
                        END FOR

			LET comando = 'fglrun repp432 ', vg_base, ' RE ',
                                        vg_codcia, ' ', rm_par.moneda, ' ',
                                        rm_par.bodega, ' "',
                                        vm_query CLIPPED || '"'

                        IF rm_par.linea IS NOT NULL THEN
                                LET comando = comando, ' ', rm_par.linea
	                   ELSE
                                LET comando = comando, ' XX '
                        END IF

                        LET comando = comando, ' ', rm_par.clasif_a
                        LET comando = comando, ' ', rm_par.clasif_b
                        LET comando = comando, ' ', rm_par.clasif_c
                        LET comando = comando, ' ', rm_par.clasif_d
                        LET comando = comando, ' ', rm_par.clasif_e

                        LET comando = comando, ' ', vm_columna_1, ' ',
                                        vm_columna_2, ' ',
                                        rm_orden[vm_columna_1], ' ',
                                        rm_orden[vm_columna_2]

                        RUN comando
                        LET int_flag = 0
        
	END DISPLAY
        
	IF int_flag = 1 THEN
                EXIT WHILE
        END IF

        IF i <> vm_columna_1 THEN
                LET vm_columna_2           = vm_columna_1
                LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
                LET vm_columna_1 = i
        END IF


END WHILE

END FUNCTION


FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
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

