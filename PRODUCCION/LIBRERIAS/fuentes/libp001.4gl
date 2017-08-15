GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

FUNCTION fl_ayuda_compania_principal()
DEFINE rh ARRAY[100] OF RECORD
        g01_razonsocial      	LIKE gent001.g01_razonsocial,
        g02_nombre 		LIKE gent002.g02_nombre
        END RECORD
DEFINE ra ARRAY[100] OF RECORD	
        g01_compania      	LIKE gent001.g01_compania,
        g02_localidad		LIKE gent002.g02_localidad
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query    CHAR(500)               ## Contiene todo el query preparado
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE r_g05            RECORD LIKE gent005.*
                                                                                
LET filas_max  = 100
OPEN WINDOW wh AT 06, 13 WITH 12 ROWS, 66 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf007 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf007'
ELSE
	OPEN FORM f_ayuf007 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf007c'
END IF
DISPLAY FORM f_ayuf007
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Compania'   TO bt_compania
--#DISPLAY 'Localidad'  TO bt_localidad

LET filas_pant = fgl_scr_size("rh")
LET int_flag = 0
MESSAGE 'Seleccionando datos ...' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
LET query = " SELECT g01_razonsocial, g02_nombre, g01_compania, g02_localidad ",
		 " FROM gent001, gent002 ",
  	    " WHERE g01_compania =  g02_compania " ,
            'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                   ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE cialoc FROM query
DECLARE qh CURSOR FOR cialoc
CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
LET i = 1
FOREACH qh INTO rh[i].*, ra[i].*
	IF r_g05.g05_tipo IS NULL OR r_g05.g05_tipo <> 'AG' THEN
		SELECT UNIQUE g53_compania FROM gent053 
			WHERE g53_usuario  = vg_usuario AND 
		      	      g53_compania = ra[i].g01_compania
		IF status = NOTFOUND THEN
			CONTINUE FOREACH
		END IF
	END IF
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh[1].*, ra[1] TO NULL
        RETURN ra[1].g01_compania, ra[1].g02_localidad
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh TO rh.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
        ON KEY(F15)
                LET col = 1
                EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
IF vg_gui = 0 THEN
	LET salir = 1
END IF
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh[1].*, ra[1] TO NULL
        RETURN ra[1].g01_compania, ra[1].g02_localidad
END IF
LET  i = arr_curr()
RETURN ra[i].g01_compania, ra[i].g02_localidad

END FUNCTION



FUNCTION fl_ayuda_compania()
DEFINE rh_cia ARRAY[100] OF RECORD
        g01_compania            LIKE gent001.g01_compania,
        g01_razonsocial         LIKE gent001.g01_razonsocial
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE cod_cia          LIKE gent001.g01_compania
DEFINE j        SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf000 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf000'
ELSE
	OPEN FORM f_ayuf000 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf000c'
END IF
DISPLAY FORM f_ayuf000
LET filas_pant = fgl_scr_size('rh_cia')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_cia CURSOR FOR
        SELECT g01_compania, g01_razonsocial FROM gent001
        ORDER BY 1
LET i = 1
FOREACH qh_cia INTO rh_cia[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh_cia[1].* TO NULL
        RETURN rh_cia[1].g01_compania
                                                                                
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cia TO rh_cia.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_cia[1].* TO NULL
        RETURN rh_cia[1].g01_compania
END IF
LET  i = arr_curr()
RETURN rh_cia[i].g01_compania

END FUNCTION



FUNCTION fl_ayuda_localidad(cod_cia)
DEFINE rh_loc ARRAY[100] OF RECORD
        g02_localidad      	LIKE gent002.g02_localidad,
        g02_nombre      	LIKE gent002.g02_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE cod_cia		LIKE gent002.g02_compania
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf001 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf001'
ELSE
	OPEN FORM f_ayuf001 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf001c'
END IF
DISPLAY FORM f_ayuf001
LET filas_pant = fgl_scr_size('rh_loc')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_loc CURSOR FOR
        SELECT g02_localidad, g02_nombre FROM gent002
		WHERE g02_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH qh_loc INTO rh_loc[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh_loc[1].* TO NULL
        RETURN rh_loc[1].g02_localidad, rh_loc[1].g02_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_loc TO rh_loc.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_loc[1].* TO NULL
        RETURN rh_loc[1].g02_localidad, rh_loc[1].g02_nombre
END IF
LET  i = arr_curr()
--RETURN rh_loc[i].g02_localidad/
RETURN rh_loc[i].g02_localidad, rh_loc[i].g02_nombre
END FUNCTION
                                                                               



FUNCTION fl_ayuda_ciudad(pais, divi_poli)
DEFINE pais		LIKE gent031.g31_pais
DEFINE divi_poli	LIKE gent031.g31_divi_poli
DEFINE rh ARRAY[500] OF RECORD
   	g31_ciudad      LIKE gent031.g31_ciudad,
        g31_nombre      LIKE gent031.g31_nombre
        END RECORD
DEFINE i, j             SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE query		CHAR(600)
DEFINE expr_pai		VARCHAR(100)
DEFINE expr_div		VARCHAR(100)

LET filas_max  = 500
OPEN WINDOW wh AT 06, 39 WITH 15 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf002 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf002'
ELSE
	OPEN FORM f_ayuf002 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf002c'
END IF
DISPLAY FORM f_ayuf002
LET filas_pant = fgl_scr_size('rh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
-----
LET expr_pai = NULL
IF pais > 0 THEN
	LET expr_pai = 'WHERE g31_pais = ', pais
END IF
LET expr_div = NULL
IF divi_poli > 0 AND pais = 0 THEN
	LET expr_div = 'WHERE g31_divi_poli = ', divi_poli
END IF
IF divi_poli > 0 AND pais > 0 THEN
	LET expr_div = '  AND g31_divi_poli = ', divi_poli
END IF
LET query = 'SELECT g31_ciudad, g31_nombre ',
		'FROM gent031 ',
		expr_pai CLIPPED,
		expr_div CLIPPED,
		' ORDER BY 2 '
PREPARE cons_cui FROM query
DECLARE qh_ciu1 CURSOR FOR cons_cui
LET i = 1
FOREACH qh_ciu1 INTO rh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
----- 
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh[1].* TO NULL
        RETURN rh[1].g31_ciudad, rh[1].g31_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh TO rh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh[1].* TO NULL
        RETURN rh[1].g31_ciudad, rh[1].g31_nombre
END IF
LET  i = arr_curr()
RETURN rh[i].g31_ciudad, rh[i].g31_nombre

END FUNCTION
                                                                         


FUNCTION fl_ayuda_imptos()

DEFINE rh_impto	ARRAY[1000] OF RECORD
		g00_serial	LIKE gent000.g00_serial,
		g00_porc_impto	LIKE gent000.g00_porc_impto,
		g00_label_impto	LIKE gent000.g00_label_impto
END RECORD
DEFINE i 		SMALLINT
DEFINE j	SMALLINT

LET INT_FLAG = 0

DECLARE reg_impto CURSOR FOR 
	SELECT g00_serial, g00_porc_impto, g00_label_impto 
          FROM gent000 ORDER BY 1

LET i = 1
FOREACH reg_impto INTO rh_impto[i].*
	LET i = i + 1
	IF i > 1000 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
	INITIALIZE rh_impto[1].* TO NULL
	RETURN rh_impto[1].g00_serial, rh_impto[1].g00_porc_impto,
               rh_impto[1].g00_label_impto
END IF

OPEN WINDOW w_impto AT 07, 40 WITH 15 ROWS, 39 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf003 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf003"
ELSE
	OPEN FORM f_ayuf003 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf003c"
END IF
DISPLAY FORM f_ayuf003
CALL SET_COUNT(i)

DISPLAY ARRAY rh_impto TO rh_imp.*
	ON KEY(RETURN)
		EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_impto

IF NOT INT_FLAG THEN
	LET i = ARR_CURR()
ELSE
	LET i = 1
	INITIALIZE rh_impto[1].* TO NULL
END IF	
RETURN rh_impto[i].g00_serial, rh_impto[i].g00_porc_impto,
               rh_impto[i].g00_label_impto

END FUNCTION



FUNCTION fl_ayuda_zona_venta(cod_cia)
DEFINE rh_zonv ARRAY[100] OF RECORD
   	g32_zona_venta      	LIKE gent032.g32_zona_venta,
        g32_nombre      	LIKE gent032.g32_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE gent032.g32_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW w_hzonv AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf005 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf005'
ELSE
	OPEN FORM f_ayuf005 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf005c'
END IF
DISPLAY FORM f_ayuf005
LET filas_pant = fgl_scr_size('rh_zonv')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_znv CURSOR FOR
        SELECT g32_zona_venta, g32_nombre FROM gent032
	WHERE g32_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_znv INTO rh_zonv[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
--LET vg_codcia = 1
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_hzonv
        INITIALIZE rh_zonv[1].* TO NULL
        RETURN rh_zonv[1].g32_zona_venta, rh_zonv[1].g32_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_zonv TO rh_zonv.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_hzonv
IF int_flag THEN
        INITIALIZE rh_zonv[1].* TO NULL
        RETURN rh_zonv[1].g32_zona_venta, rh_zonv[1].g32_nombre
END IF
LET  i = arr_curr()
RETURN rh_zonv[i].g32_zona_venta, rh_zonv[i].g32_nombre

END FUNCTION


FUNCTION fl_ayuda_pais()
DEFINE rh_pais ARRAY[100] OF RECORD
        g30_pais      	LIKE gent030.g30_pais,
        g30_nombre      LIKE gent030.g30_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf006 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf006'
ELSE
	OPEN FORM f_ayuf006 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf006c'
END IF
DISPLAY FORM f_ayuf006
LET filas_pant = fgl_scr_size('rh_pais')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_pais CURSOR FOR
        SELECT g30_pais, g30_nombre FROM gent030
        ORDER BY 1
LET i = 1
FOREACH q_pais INTO rh_pais[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh_pais[1].* TO NULL
        RETURN rh_pais[1].g30_pais, rh_pais[i].g30_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_pais TO rh_pais.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_pais[1].* TO NULL
        RETURN rh_pais[1].g30_pais, rh_pais[1].g30_nombre
END IF
LET  i = arr_curr()
RETURN rh_pais[i].g30_pais, rh_pais[i].g30_nombre
                                                                                
END FUNCTION




FUNCTION fl_ayuda_monedas()
DEFINE rh_mon  ARRAY[100] OF RECORD 
        g13_moneda      LIKE gent013.g13_moneda,
        g13_nombre      LIKE gent013.g13_nombre,
        g13_simbolo     LIKE gent013.g13_simbolo
        END RECORD
DEFINE rh_dec	ARRAY[100] OF RECORD 
 	g13_decimales	LIKE gent013.g13_decimales	
	END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_mon AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf008 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf008'
ELSE
	OPEN FORM f_ayuf008 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf008c'
END IF
DISPLAY FORM f_ayuf008
LET filas_pant = fgl_scr_size('rh_mon')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_mon CURSOR FOR
        SELECT 	g13_moneda, g13_nombre, g13_simbolo, 
		g13_decimales
 		FROM gent013
		WHERE  g13_estado = 'A'
        ORDER BY 2
LET i = 1
FOREACH q_mon INTO rh_mon[i].*, rh_dec[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_mon
        INITIALIZE rh_mon[1].*, rh_dec[1] TO NULL
        RETURN 	rh_mon[1].g13_moneda, rh_mon[1].g13_nombre, 
		rh_dec[1].g13_decimales 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_mon TO rh_mon.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_mon
IF int_flag THEN
        INITIALIZE rh_mon[1].*, rh_dec[1] TO NULL
        RETURN 	rh_mon[1].g13_moneda, rh_mon[1].g13_nombre, 
		rh_dec[1].g13_decimales 
END IF
LET  i = arr_curr()
RETURN 	rh_mon[i].g13_moneda, rh_mon[i].g13_nombre, 
	rh_dec[i].g13_decimales 
                                                                                
END FUNCTION
                                                                                
                                                                                

FUNCTION fl_ayuda_ccostos(cod_cia)
DEFINE rh_cco ARRAY[100] OF RECORD
        g33_cod_ccosto      	LIKE gent033.g33_cod_ccosto,
        g33_nombre      	LIKE gent033.g33_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE gent033.g33_compania	
                                                                                
LET filas_max  = 100
OPEN WINDOW w_cco AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf009 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf009'
ELSE
	OPEN FORM f_ayuf009 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf009c'
END IF
DISPLAY FORM f_ayuf009
LET filas_pant = fgl_scr_size('rh_cco')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_cco CURSOR FOR
        SELECT g33_cod_ccosto, g33_nombre FROM gent033
		WHERE g33_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH qh_cco INTO rh_cco[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_cco
        INITIALIZE rh_cco[1].* TO NULL
        RETURN rh_cco[1].g33_cod_ccosto, rh_cco[1].g33_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cco TO rh_cco.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_cco
IF int_flag THEN
        INITIALIZE rh_cco[1].* TO NULL
        RETURN rh_cco[1].g33_cod_ccosto, rh_cco[1].g33_nombre
END IF
LET  i = arr_curr()
RETURN rh_cco[i].g33_cod_ccosto, rh_cco[i].g33_nombre
END FUNCTION




FUNCTION fl_ayuda_departamentos(cod_cia)
DEFINE rh_depto ARRAY[100] OF RECORD
        g34_cod_depto      	LIKE gent034.g34_cod_depto,
        g34_nombre      	LIKE gent034.g34_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE gent034.g34_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_depa AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf010 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf010'
ELSE
	OPEN FORM f_ayuf010 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf010c'
END IF
DISPLAY FORM f_ayuf010
LET filas_pant = fgl_scr_size('rh_depto')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_depto CURSOR FOR
        SELECT g34_cod_depto, g34_nombre FROM gent034
		WHERE g34_compania = cod_cia
        ORDER BY 2
LET i = 1
FOREACH qh_depto INTO rh_depto[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_depa
        INITIALIZE rh_depto[1].* TO NULL
        RETURN rh_depto[1].g34_cod_depto, rh_depto[1].g34_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_depto TO rh_depto.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_depa
IF int_flag THEN
        INITIALIZE rh_depto[1].* TO NULL
        RETURN rh_depto[1].g34_cod_depto, rh_depto[1].g34_nombre
END IF
LET  i = arr_curr()
RETURN rh_depto[i].g34_cod_depto, rh_depto[i].g34_nombre
END FUNCTION



FUNCTION fl_ayuda_cargos(cod_cia)
DEFINE rh_cargo ARRAY[100] OF RECORD
        g35_cod_cargo       	LIKE gent035.g35_cod_cargo,
        g35_nombre      	LIKE gent035.g35_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE gent035.g35_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW w_car AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf011 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf011'
ELSE
	OPEN FORM f_ayuf011 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf011c'
END IF
DISPLAY FORM f_ayuf011
LET filas_pant = fgl_scr_size('rh_cargo')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_cargo CURSOR FOR
        SELECT g35_cod_cargo, g35_nombre FROM gent035
		WHERE g35_compania = cod_cia
        ORDER BY 2
LET i = 1
FOREACH qh_cargo INTO rh_cargo[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_car
        INITIALIZE rh_cargo[1].* TO NULL
        RETURN rh_cargo[1].g35_cod_cargo, rh_cargo[1].g35_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cargo TO rh_cargo.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_car
IF int_flag THEN
        INITIALIZE rh_cargo[1].* TO NULL
        RETURN rh_cargo[1].g35_cod_cargo, rh_cargo[1].g35_nombre
END IF
LET  i = arr_curr()
RETURN rh_cargo[i].g35_cod_cargo, rh_cargo[i].g35_nombre
END FUNCTION




FUNCTION fl_ayuda_partidas(cap)
DEFINE rh_part		ARRAY[1000] OF RECORD
				g16_niv_par	LIKE gent016.g16_niv_par,
        			g16_partida	LIKE gent016.g16_partida,
			        g16_desc_par	LIKE gent016.g16_desc_par 
		        END RECORD
DEFINE i                SMALLINT
DEFINE expr_sql		VARCHAR(100)	## Contiene el CONSTRUCT del usuario
DEFINE query		VARCHAR(255)	## Contiene todo el query preparado
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE cap		LIKE gent016.g16_capitulo
                                                                                
LET filas_max = 1000
OPEN WINDOW w_par AT 06, 13 WITH 15 ROWS, 66 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf012 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf012'
ELSE
	OPEN FORM f_ayuf012 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf012c'
END IF
DISPLAY FORM f_ayuf012
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Nivel'   TO tit_nivel
--#DISPLAY 'Partida' TO tit_partida
--#DISPLAY 'Nombre'  TO tit_nombre
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON g16_niv_par, g16_partida, g16_desc_par
	IF int_flag THEN
		CLOSE WINDOW w_par
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 2
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
-----
	WHILE NOT salir
	IF cap IS NOT NULL THEN
	LET query = 'SELECT g16_niv_par,g16_partida,g16_desc_par FROM gent016 ',
                                 ' WHERE g16_capitulo  = "', cap, '"',
				 ' AND  ', expr_sql CLIPPED,
		                    ' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',
					rm_orden[vm_columna_2] CLIPPED
	ELSE
	LET query = 'SELECT g16_niv_par,g16_partida,g16_desc_par FROM gent016 ',
				 ' WHERE ', expr_sql CLIPPED,
		                    ' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',
					rm_orden[vm_columna_2] CLIPPED
	END IF
		PREPARE part FROM query
		DECLARE q_part CURSOR FOR part
		LET i = 1
		FOREACH q_part INTO rh_part[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
                	LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_part TO rh_part.*
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
        	                LET col = 2
		  	         EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
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
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	LET filas_pant = fgl_scr_size('rh_part')
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_part[i].* TO NULL
			CLEAR rh_part[i].*
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_par
		EXIT WHILE
	END IF
END WHILE
IF int_flag THEN
        INITIALIZE rh_part[1].* TO NULL
        RETURN rh_part[1].g16_partida
END IF
LET i = arr_curr()
RETURN rh_part[i].g16_partida

END FUNCTION



FUNCTION fl_ayuda_areaneg(cod_cia)
DEFINE rh_area ARRAY[100] OF RECORD
        g03_areaneg       	LIKE gent003.g03_areaneg,
        g03_nombre      	LIKE gent003.g03_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE gent003.g03_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_area AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf013 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf013'
ELSE
	OPEN FORM f_ayuf013 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf013c'
END IF
DISPLAY FORM f_ayuf013
LET filas_pant = fgl_scr_size('rh_area')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_area CURSOR FOR
        SELECT g03_areaneg, g03_nombre FROM gent003
		WHERE g03_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH qh_area INTO rh_area[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_area
        INITIALIZE rh_area[1].* TO NULL
        RETURN rh_area[1].g03_areaneg, rh_area[1].g03_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_area TO rh_area.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_area
IF int_flag THEN
        INITIALIZE rh_area[1].* TO NULL
        RETURN rh_area[1].g03_areaneg, rh_area[1].g03_nombre
END IF
LET  i = arr_curr()
RETURN rh_area[i].g03_areaneg, rh_area[i].g03_nombre

END FUNCTION



FUNCTION fl_ayuda_usuarios(estado)
DEFINE estado		LIKE gent005.g05_estado
DEFINE rh_usua		ARRAY[1000] OF RECORD
				g05_usuario	LIKE gent005.g05_usuario,
				g05_nombres	LIKE gent005.g05_nombres,
				g05_grupo	LIKE gent005.g05_grupo,
				g05_tipo	LIKE gent005.g05_tipo,
				g05_estado	LIKE gent005.g05_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_g05		RECORD LIKE gent005.*

LET max_row = 1000
LET num_fil = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW w_usua AT 06, 27 WITH num_fil ROWS, 52 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf014 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf014'
ELSE
	OPEN FORM f_ayuf014 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf014c'
END IF
DISPLAY FORM f_ayuf014
LET filas_pant = fgl_scr_size('rh_usua')
--#DISPLAY "Usuario"	TO tit_col1
--#DISPLAY "Nombre"	TO tit_col2
--#DISPLAY "GR"		TO tit_col3
--#DISPLAY "TP"		TO tit_col4
--#DISPLAY "E"		TO tit_col5
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND g05_estado   = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON g05_usuario, g05_nombres,
						g05_grupo, g05_tipo
		IF int_flag THEN
			CLOSE WINDOW w_usua
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM gent005 ',
				'WHERE ', expr_sql CLIPPED, ' ',
					expr_est CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1],
					', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE quer_usua FROM query
		DECLARE qh_usua CURSOR FOR quer_usua
		LET i = 1
		FOREACH qh_usua INTO r_g05.*
			LET rh_usua[i].g05_usuario = r_g05.g05_usuario
			LET rh_usua[i].g05_nombres = r_g05.g05_nombres
			LET rh_usua[i].g05_grupo   = r_g05.g05_grupo
			LET rh_usua[i].g05_tipo    = r_g05.g05_tipo
			LET rh_usua[i].g05_estado  = r_g05.g05_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i     = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_usua TO rh_usua.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_usua[i].*
				END FOR
				EXIT DISPLAY
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
				LET col = 5
				EXIT DISPLAY
			ON KEY(F19)
				IF estado = 'T' THEN
					LET col = 4
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_usua
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_usua[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_usua[1].* TO NULL
	RETURN rh_usua[1].g05_usuario, rh_usua[1].g05_nombres
END IF
LET i = arr_curr()
RETURN rh_usua[i].g05_usuario, rh_usua[i].g05_nombres

END FUNCTION



FUNCTION fl_ayuda_grupos_usuarios()
DEFINE rh_grup ARRAY[100] OF RECORD
        g04_grupo       	LIKE gent004.g04_grupo,
        g04_nombre       	LIKE gent004.g04_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_grup AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf015 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf015'
ELSE
	OPEN FORM f_ayuf015 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf015c'
END IF
DISPLAY FORM f_ayuf015
LET filas_pant = fgl_scr_size('rh_grup')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_grup CURSOR FOR
        SELECT g04_grupo, g04_nombre  FROM gent004
        ORDER BY 1
LET i = 1
FOREACH qh_grup INTO rh_grup[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_grup
        INITIALIZE rh_grup[1].* TO NULL
        RETURN rh_grup[1].g04_grupo, rh_grup[1].g04_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_grup TO rh_grup.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_grup
IF int_flag THEN
        INITIALIZE rh_grup[1].* TO NULL
        RETURN rh_grup[1].g04_grupo, rh_grup[1].g04_nombre 
END IF
LET  i = arr_curr()
RETURN rh_grup[i].g04_grupo, rh_grup[i].g04_nombre 

END FUNCTION



FUNCTION fl_ayuda_impresoras(usuario)
DEFINE rh_impr		ARRAY[100] OF RECORD
		        	g06_impresora	LIKE gent006.g06_impresora,
			        g06_nombre	LIKE gent006.g06_nombre 
		        END RECORD
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE query		VARCHAR(255)
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_imp AT 06, 38 WITH 15 ROWS, 41 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf016 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf016'
ELSE
	OPEN FORM f_ayuf016 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf016c'
END IF
DISPLAY FORM f_ayuf016
LET filas_pant = fgl_scr_size('rh_impr')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET query = 'SELECT g06_impresora, g06_nombre '
IF usuario <> 'TODAS' THEN
	LET query = query CLIPPED,
			' FROM gent007, gent006 ',
			' WHERE g07_user     = "', usuario, '"',
		  	'  AND g07_impresora = g06_impresora ',
        		' ORDER BY 1'
ELSE
	LET query = query CLIPPED,
			' FROM gent006 ',
        		' ORDER BY 1'
END IF
PREPARE impr FROM query
DECLARE qh_impr CURSOR FOR impr
LET i = 1
FOREACH qh_impr INTO rh_impr[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_imp
        INITIALIZE rh_impr[1].* TO NULL
        RETURN rh_impr[1].g06_impresora, rh_impr[1].g06_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_impr TO rh_impr.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_imp
IF int_flag THEN
        INITIALIZE rh_impr[1].* TO NULL
        RETURN rh_impr[1].g06_impresora, rh_impr[1].g06_nombre 
END IF
LET  i = arr_curr()
RETURN rh_impr[i].g06_impresora, rh_impr[i].g06_nombre 

END FUNCTION



FUNCTION fl_ayuda_bancos()
DEFINE rh_banc ARRAY[100] OF RECORD
        g08_banco       	LIKE gent008.g08_banco,
        g08_nombre       	LIKE gent008.g08_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_ban AT 06, 39 WITH 15 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf017 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf017'
ELSE
	OPEN FORM f_ayuf017 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf017c'
END IF
DISPLAY FORM f_ayuf017
LET filas_pant = fgl_scr_size('rh_banc')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_banc CURSOR FOR
        SELECT g08_banco, g08_nombre  FROM gent008
        ORDER BY 2
LET i = 1
FOREACH qh_banc INTO rh_banc[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_ban
        INITIALIZE rh_banc[1].* TO NULL
        RETURN rh_banc[1].g08_banco, rh_banc[1].g08_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_banc TO rh_banc.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_ban
IF int_flag THEN
        INITIALIZE rh_banc[1].* TO NULL
        RETURN rh_banc[1].g08_banco, rh_banc[1].g08_nombre 
END IF
LET  i = arr_curr()
RETURN rh_banc[i].g08_banco, rh_banc[i].g08_nombre 

END FUNCTION


FUNCTION fl_ayuda_cod_cobranzas()
DEFINE rh_cobr ARRAY[100] OF RECORD
        z01_codcli       	LIKE cxct001.z01_codcli,
        z01_nomcli       	LIKE cxct001.z01_nomcli 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_cobr AT 06, 38 WITH 15 ROWS, 41 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf018 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf018'
ELSE
	OPEN FORM f_ayuf018 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf018c'
END IF
DISPLAY FORM f_ayuf018
LET filas_pant = fgl_scr_size('rh_cobr')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_cobr CURSOR FOR
        SELECT z01_codcli, z01_nomcli  FROM cxct001
        ORDER BY 1
LET i = 1
FOREACH qh_cobr INTO rh_cobr[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_cobr
        INITIALIZE rh_cobr[1].* TO NULL
        RETURN rh_cobr[1].z01_codcli, rh_cobr[1].z01_nomcli 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cobr TO rh_cobr.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_cobr
IF int_flag THEN
        INITIALIZE rh_cobr[1].* TO NULL
        RETURN rh_cobr[1].z01_codcli, rh_cobr[1].z01_nomcli 
END IF
LET  i = arr_curr()
RETURN rh_cobr[i].z01_codcli, rh_cobr[i].z01_nomcli 

END FUNCTION




FUNCTION fl_ayuda_tarjeta(codcia, cont_cred, estado)
DEFINE codcia		LIKE gent010.g10_compania
DEFINE cont_cred	LIKE gent010.g10_cont_cred
DEFINE estado		LIKE gent010.g10_estado
DEFINE rh_tarj		ARRAY[100] OF RECORD
				g10_tarjeta	LIKE gent010.g10_tarjeta,
				g10_nombre	LIKE gent010.g10_nombre,
				g10_cont_cred	LIKE gent010.g10_cont_cred,
				g10_estado	LIKE gent010.g10_estado
        		END RECORD
DEFINE i, j, filas_max	SMALLINT        ## No. elementos del arreglo
DEFINE expr_sql		CHAR(400)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1500)	## Contiene todo el query preparado
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE expr_concre	VARCHAR(100)
DEFINE expr_estado	VARCHAR(100)
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
                                                                                
LET filas_max = 100
OPEN WINDOW w_tarj AT 06, 36 WITH 14 ROWS, 43 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf019 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf019'
ELSE
	OPEN FORM f_ayuf019 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf019c'
END IF
DISPLAY FORM f_ayuf019
LET filas_pant = fgl_scr_size('rh_tarj')
IF vg_gui = 1 THEN
	DISPLAY "Codigo"	 TO tit_col1
	DISPLAY "Nombre Tarjeta" TO tit_col2
	DISPLAY "T"              TO tit_col3
	DISPLAY "E"              TO tit_col4
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		DISPLAY estado TO g10_estado
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON g10_tarjeta, g10_nombre,
						g10_cont_cred
		IF int_flag THEN
			CLOSE WINDOW w_tarj
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_estado = NULL
	IF estado <> 'T' THEN
		LET expr_estado = '   AND g10_estado    = "', estado, '"'
	END IF
	LET expr_concre = NULL
	IF cont_cred <> 'T' THEN
		LET expr_concre = '   AND g10_cont_cred = "', cont_cred, '"'
	END IF
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT g10_tarjeta, g10_nombre, g10_cont_cred, ',
					'g10_estado',
				' FROM gent010 ',
				' WHERE g10_compania  = ', codcia,
				expr_estado CLIPPED,
				expr_concre CLIPPED,
				'   AND ', expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
						rm_orden[vm_columna_1], ', ',
						vm_columna_2, ' ',
						rm_orden[vm_columna_2]
		PREPARE cons_tarj FROM query
		DECLARE qh_tarj CURSOR FOR cons_tarj
		LET i = 1
		FOREACH qh_tarj INTO rh_tarj[i].*
		        LET i = i + 1
		        IF i > filas_max THEN
		                EXIT FOREACH
		        END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		MESSAGE "                                           "
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_tarj TO rh_tarj.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_tarj[i].* TO NULL
			CLEAR rh_tarj[i].*
		END FOR
		CLEAR num_rows, max_rows
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_tarj
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
        INITIALIZE rh_tarj[1].* TO NULL
        RETURN rh_tarj[1].g10_tarjeta, rh_tarj[1].g10_nombre 
END IF
LET i = arr_curr()
RETURN rh_tarj[i].g10_tarjeta, rh_tarj[i].g10_nombre 

END FUNCTION



FUNCTION fl_ayuda_entidad()
DEFINE rh_ent ARRAY[100] OF RECORD
        g11_tiporeg       	LIKE gent011.g11_tiporeg,
        g11_nombre       	LIKE gent011.g11_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_ent AT 06, 38 WITH 15 ROWS, 41 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf020 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf020'
ELSE
	OPEN FORM f_ayuf020 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf020c'
END IF
DISPLAY FORM f_ayuf020
LET filas_pant = fgl_scr_size('rh_ent')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_ent CURSOR FOR
        SELECT g11_tiporeg, g11_nombre  FROM gent011
        ORDER BY 1
LET i = 1
FOREACH qh_ent INTO rh_ent[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_ent
        INITIALIZE rh_ent[1].* TO NULL
        RETURN rh_ent[1].g11_tiporeg, rh_ent[1].g11_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ent TO rh_ent.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_ent
IF int_flag THEN
        INITIALIZE rh_ent[1].* TO NULL
        RETURN rh_ent[1].g11_tiporeg, rh_ent[1].g11_nombre 
END IF
LET  i = arr_curr()
RETURN rh_ent[i].g11_tiporeg, rh_ent[i].g11_nombre 

END FUNCTION



FUNCTION fl_ayuda_subtipo_entidad(entidad)
DEFINE rh_subtip ARRAY[100] OF RECORD
        g12_tiporeg       	LIKE gent012.g12_tiporeg,
        g12_subtipo       	LIKE gent012.g12_subtipo,
        g12_nombre       	LIKE gent012.g12_nombre 
        END RECORD
DEFINE rh_tipo ARRAY[100] OF RECORD
        g11_nombre       	LIKE gent011.g11_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE entidad		LIKE gent012.g12_tiporeg
                                                                                
LET filas_max  = 100
OPEN WINDOW w_subtip AT 06, 31 WITH 15 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf021 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf021'
ELSE
	OPEN FORM f_ayuf021 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf021c'
END IF
DISPLAY FORM f_ayuf021
LET filas_pant = fgl_scr_size('rh_subtip')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_subtip CURSOR FOR
        SELECT g12_tiporeg, g12_subtipo, g12_nombre, g11_nombre 
		FROM gent012, gent011
		WHERE g12_tiporeg = g11_tiporeg
		  AND g12_tiporeg = entidad
        ORDER BY 1
LET i = 1
FOREACH qh_subtip INTO rh_subtip[i].*, rh_tipo[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_subtip
        INITIALIZE rh_subtip[1].*, rh_tipo[1].* TO NULL
        RETURN rh_subtip[1].g12_tiporeg, rh_subtip[1].g12_subtipo, rh_subtip[1].g12_nombre, rh_tipo[1].g11_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subtip TO rh_subtip.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_subtip
IF int_flag THEN
        INITIALIZE rh_subtip[1].*, rh_tipo[1].* TO NULL
        RETURN rh_subtip[1].g12_tiporeg, rh_subtip[1].g12_subtipo,
		rh_subtip[1].g12_nombre, rh_tipo[1].g11_nombre 
END IF
LET  i = arr_curr()
RETURN rh_subtip[i].g12_tiporeg, rh_subtip[i].g12_subtipo,
	rh_subtip[i].g12_nombre, rh_tipo[i].g11_nombre 

END FUNCTION



FUNCTION fl_ayuda_cuenta_banco(cod_cia, estado)
DEFINE cod_cia		LIKE gent009.g09_compania
DEFINE estado		LIKE gent009.g09_estado
DEFINE rh_ctabco	ARRAY[500] OF RECORD
				g08_banco	LIKE gent008.g08_banco,
				g08_nombre	LIKE gent008.g08_nombre,
				g09_tipo_cta	LIKE gent009.g09_tipo_cta,
				g09_numero_cta	LIKE gent009.g09_numero_cta,
				g09_estado	LIKE gent009.g09_estado,
				g09_aux_cont	LIKE gent009.g09_aux_cont,
				b10_estado	LIKE ctbt010.b10_estado
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(600)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW w_ctabco AT 06, 10 WITH num_fil ROWS, 69 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf022 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf022'
ELSE
	OPEN FORM f_ayuf022 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf022c'
END IF
DISPLAY FORM f_ayuf022
--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY 'Nombre Banco'	TO tit_col2
--#DISPLAY "T"			TO tit_col3
--#DISPLAY "Cuenta Banco"	TO tit_col4
--#DISPLAY "E"			TO tit_col5
--#DISPLAY "Cuenta Cont."	TO tit_col6
--#DISPLAY "E"			TO tit_col7
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND g09_estado = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON g08_banco, g08_nombre,
				g09_tipo_cta, g09_numero_cta, g09_estado,
				g09_aux_cont, b10_estado
		IF int_flag THEN
			CLOSE WINDOW w_ctabco
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 2
	LET vm_columna_2 = 4
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT g08_banco, g08_nombre, g09_tipo_cta, ',
					'g09_numero_cta, g09_estado, ',
					'g09_aux_cont, b10_estado ',
				' FROM gent009, gent008, ctbt010 ',
				' WHERE g09_compania = ', cod_cia,
				expr_est CLIPPED,
				'   AND g09_banco    = g08_banco ',
				'   AND b10_compania = g09_compania ',
				'   AND b10_cuenta   = g09_aux_cont ',
				'   AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE ctabco FROM query
		DECLARE qh_ctabco CURSOR FOR ctabco
		LET i = 1
		FOREACH qh_ctabco INTO rh_ctabco[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE '                                           '
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_ctabco TO rh_ctabco.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_ctabco[i].*
				END FOR
				EXIT DISPLAY
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
			ON KEY(F20)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F21)
				LET col = 7
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_ctabco
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_ctabco[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ctabco[1].* TO NULL
	RETURN rh_ctabco[1].g08_banco, rh_ctabco[1].g08_nombre,
		rh_ctabco[1].g09_tipo_cta, rh_ctabco[1].g09_numero_cta 
END IF
LET i = arr_curr()
RETURN rh_ctabco[i].g08_banco, rh_ctabco[i].g08_nombre,
	rh_ctabco[i].g09_tipo_cta, rh_ctabco[i].g09_numero_cta 

END FUNCTION



FUNCTION fl_ayuda_grupo_lineas(cod_cia)
DEFINE rh_grulin ARRAY[100] OF RECORD
        g20_grupo_linea         LIKE gent020.g20_grupo_linea,
        g20_nombre	        LIKE gent020.g20_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        	SMALLINT
DEFINE cod_cia		LIKE gent020.g20_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW w_grulin AT 06, 40 WITH 15 ROWS, 39 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf023 FROM'../../../PRODUCCION/LIBRERIAS/forms/ayuf023'
ELSE
	OPEN FORM f_ayuf023 FROM'../../../PRODUCCION/LIBRERIAS/forms/ayuf023c'
END IF
DISPLAY FORM f_ayuf023
LET filas_pant = fgl_scr_size('rh_grulin')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_grulin CURSOR FOR
        SELECT g20_grupo_linea, g20_nombre  FROM gent020
                WHERE g20_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH qh_grulin INTO rh_grulin[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_grulin
        INITIALIZE rh_grulin[1].* TO NULL
        RETURN rh_grulin[1].g20_grupo_linea, rh_grulin[1].g20_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_grulin TO rh_grulin.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_grulin
IF int_flag THEN
        INITIALIZE rh_grulin[1].* TO NULL
        RETURN rh_grulin[1].g20_grupo_linea, rh_grulin[1].g20_nombre
END IF
LET  i = arr_curr()
RETURN rh_grulin[i].g20_grupo_linea, rh_grulin[i].g20_nombre
                                                                                
END FUNCTION



FUNCTION fl_ayuda_dias_feriados()
DEFINE rh_dias ARRAY[100] OF RECORD
        g36_dia         	LIKE gent036.g36_dia,
        g36_referencia	        LIKE gent036.g36_referencia
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_dias AT 06, 33 WITH 15 ROWS, 46 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf024 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf024'
ELSE
	OPEN FORM f_ayuf024 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf024c'
END IF
DISPLAY FORM f_ayuf024
LET filas_pant = fgl_scr_size('rh_dias')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_dias CURSOR FOR
        SELECT g36_dia, g36_referencia  FROM gent036
        ORDER BY 1
LET i = 1
FOREACH qh_dias INTO rh_dias[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_dias
        INITIALIZE rh_dias[1].* TO NULL
        RETURN rh_dias[1].g36_dia, rh_dias[1].g36_referencia
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_dias TO rh_dias.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_dias
IF int_flag THEN
        INITIALIZE rh_dias[1].* TO NULL
        RETURN rh_dias[1].g36_dia, rh_dias[1].g36_referencia
END IF
LET  i = arr_curr()
        RETURN rh_dias[i].g36_dia, rh_dias[i].g36_referencia

END FUNCTION




FUNCTION fl_ayuda_guias_remision(codcia, codloc, estado)
DEFINE codcia		LIKE rept095.r95_compania
DEFINE codloc		LIKE rept095.r95_localidad
DEFINE estado		LIKE rept095.r95_estado
DEFINE rh_guia 		ARRAY[10000] OF RECORD
			r95_guia_remision	LIKE rept095.r95_guia_remision,
			r95_num_sri		LIKE rept095.r95_num_sri,
			r95_persona_dest	LIKE rept095.r95_persona_dest,
			r95_fecha_emi		LIKE rept095.r95_fecha_emi,
			r95_motivo		LIKE rept095.r95_motivo,
			r95_estado		LIKE rept095.r95_estado
        		END RECORD
DEFINE i, j, col, salir	SMALLINT
DEFINE filas_max	SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant	SMALLINT        ## No. elementos de cada pantalla
DEFINE query		CHAR(2000)	## Contiene todo el query preparado
DEFINE expr_sql		CHAR(800)
DEFINE expr_rut		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col_ini		SMALLINT
DEFINE fil_max		SMALLINT
DEFINE col_max		SMALLINT
DEFINE primera		SMALLINT
DEFINE comando          VARCHAR(250)
DEFINE run_prog		CHAR(10)

LET filas_max = 10000
LET col_ini   = 05
LET fil_max   = 14
LET col_max   = 74
IF vg_gui = 0 THEN
	LET col_ini = 15
	LET fil_max = 16
	LET col_max = 73
END IF
OPEN WINDOW w_guia AT 06, col_ini WITH fil_max ROWS, col_max COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf025 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf025'
ELSE
	OPEN FORM f_ayuf025 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf025c'
END IF
DISPLAY FORM f_ayuf025
--#DISPLAY 'Guía'		TO tit_col1
--#DISPLAY 'Número SRI'		TO tit_col2
--#DISPLAY 'Destinatario'	TO tit_col3
--#DISPLAY 'Fecha Emi.'		TO tit_col4
--#DISPLAY 'M'			TO tit_col5
--#DISPLAY 'E'			TO tit_col6
LET filas_pant = fgl_scr_size('rh_guia')
LET expr_est = NULL
LET expr_rut = NULL
IF estado <> 'T' THEN
	IF estado = 'R' THEN
		LET expr_rut = '   AND NOT EXISTS ',
					'(SELECT 1 FROM rept114 ',
				'WHERE r114_compania      = r95_compania ',
				'  AND r114_localidad     = r95_localidad ',
				'  AND r114_guia_remision = r95_guia_remision ',
				'  AND r114_estado        = "E")'
		LET estado   = 'C'
	END IF
	LET expr_est = '   AND r95_estado    = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	--IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r95_guia_remision, r95_num_sri,
				r95_persona_dest, r95_fecha_emi, r95_motivo
		IF int_flag THEN
			CLOSE WINDOW w_guia
			EXIT WHILE
		END IF
	{--
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	--}
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 4
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1] = 'DESC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT r95_guia_remision, r95_num_sri, ",
				"r95_persona_dest, r95_fecha_emi, r95_motivo, ",
				"r95_estado ",
				" FROM rept095 ",
				" WHERE r95_compania  = ", codcia, 
				"   AND r95_localidad = ", codloc,
				expr_est CLIPPED,
				"  AND ", expr_sql CLIPPED,
				expr_rut CLIPPED,
			" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
		PREPARE guiasrep FROM query
		DECLARE qh_guia CURSOR FOR guiasrep
		LET i = 1
		FOREACH qh_guia INTO rh_guia[i].*
	        	LET i = i + 1
		        IF i > filas_max THEN
		                EXIT FOREACH
	        	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
		        CALL fl_mensaje_consulta_sin_registros()
		        CLOSE WINDOW w_guia
		        INITIALIZE rh_guia[1].* TO NULL
		        RETURN rh_guia[1].r95_guia_remision
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_guia TO rh_guia.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_guia[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F5)
				LET run_prog = '; fglrun '
				IF vg_gui = 0 THEN
					LET run_prog = '; fglgo '
				END IF
				LET comando  = 'cd ..', vg_separador, '..',
						vg_separador, 'REPUESTOS',
						vg_separador, 'fuentes',
						vg_separador, run_prog CLIPPED,
						' repp241 ', vg_base, ' ',
						vg_modulo, ' ', codcia, ' ',
						codloc, ' ',
						rh_guia[j].r95_guia_remision
				RUN comando
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
		        ON KEY(F20)
				IF estado = 'T' THEN
		        	        LET col = 6
			                EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE  j, ' de ', i
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('RETURN', '')
				--#CALL dialog.keysetlabel('F5','Guía Remisión')
		        --#AFTER DISPLAY
		                --#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_guia
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_guia[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
        INITIALIZE rh_guia[1].* TO NULL
        RETURN rh_guia[1].r95_guia_remision
END IF
LET i = arr_curr()
RETURN rh_guia[i].r95_guia_remision

END FUNCTION




FUNCTION fl_ayuda_base_datos()
DEFINE rh_base ARRAY[100] OF RECORD
        g51_basedatos         	LIKE gent051.g51_basedatos,
        g51_nombre	        LIKE gent051.g51_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_base AT 06, 39 WITH 15 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf026 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf026'
ELSE
	OPEN FORM f_ayuf026 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf026c'
END IF
DISPLAY FORM f_ayuf026
LET filas_pant = fgl_scr_size('rh_base')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_base CURSOR FOR
        SELECT g51_basedatos, g51_nombre  FROM gent051
        ORDER BY 1
LET i = 1
FOREACH qh_base INTO rh_base[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_base
        INITIALIZE rh_base[1].* TO NULL
        RETURN rh_base[1].g51_basedatos, rh_base[1].g51_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_base TO rh_base.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_base
IF int_flag THEN
        INITIALIZE rh_base[1].* TO NULL
        RETURN rh_base[1].g51_basedatos, rh_base[1].g51_nombre
END IF
LET  i = arr_curr()
        RETURN rh_base[i].g51_basedatos, rh_base[i].g51_nombre

END FUNCTION



FUNCTION fl_ayuda_modulos()
DEFINE rh_modu ARRAY[100] OF RECORD
        g50_modulo         	LIKE gent050.g50_modulo,
        g50_nombre	        LIKE gent050.g50_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_modu AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf027 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf027'
ELSE
	OPEN FORM f_ayuf027 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf027c'
END IF
DISPLAY FORM f_ayuf027
LET filas_pant = fgl_scr_size('rh_modu')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_modu CURSOR FOR
        SELECT g50_modulo, g50_nombre  FROM gent050
        ORDER BY 1
LET i = 1
FOREACH qh_modu INTO rh_modu[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_modu
        INITIALIZE rh_modu[1].* TO NULL
        RETURN rh_modu[1].g50_modulo, rh_modu[1].g50_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_modu TO rh_modu.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_modu
IF int_flag THEN
        INITIALIZE rh_modu[1].* TO NULL
        RETURN rh_modu[1].g50_modulo, rh_modu[1].g50_nombre
END IF
LET  i = arr_curr()
        RETURN rh_modu[i].g50_modulo, rh_modu[i].g50_nombre

END FUNCTION



FUNCTION fl_ayuda_cuenta_contable(cod_cia, nivel)
## cuando sea ingreso de cuenta el parametro nivel será = 0, en modificacion
## de cuentas parametro nivel será = 6

## Si el parámetro es -1 se mostrarán las cuentas que permitan movimiento sin
## importar el nivel

DEFINE rh_ctacon ARRAY[1000] OF RECORD
	b10_cuenta	LIKE ctbt010.b10_cuenta,
	b10_descripcion	LIKE ctbt010.b10_descripcion
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE ctbt010.b10_compania
DEFINE nivel		LIKE ctbt010.b10_nivel
DEFINE expr_nivel	CHAR(25)
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_ctacon AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf028 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf028'
ELSE
	OPEN FORM f_ayuf028 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf028c'
END IF
DISPLAY FORM f_ayuf028
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Cuenta'      TO bt_cuenta
--#DISPLAY 'Descripción' TO bt_descripcion

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON b10_cuenta, b10_descripcion
	IF int_flag THEN
		CLOSE WINDOW w_ctacon
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_nivel = " 1 = 1 "
	IF nivel = -1 THEN
		LET expr_nivel = " b10_permite_mov = 'S' "
	ELSE
		IF nivel <> 0 THEN
			LET expr_nivel = " b10_nivel =  ", nivel 
		END IF
	END IF
-----------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT b10_cuenta, b10_descripcion FROM ctbt010 ",
				" WHERE b10_compania = ", cod_cia," AND ", 
				" b10_estado = 'A' AND ",	
				 expr_nivel, " AND ",
				 expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE ctacon FROM query
	DECLARE q_ctacon CURSOR FOR ctacon
	LET i = 1
	FOREACH q_ctacon INTO rh_ctacon[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_ctacon TO rh_ctacon.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF int_flag = 4 THEN
	FOR i = 1 TO filas_pant
		INITIALIZE rh_ctacon[i].* TO NULL
		CLEAR rh_ctacon[i].*
	END FOR
END IF
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_ctacon
	EXIT WHILE
END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ctacon[1].* TO NULL
	RETURN rh_ctacon[1].*
END IF
LET i = arr_curr()
RETURN rh_ctacon[i].*

END FUNCTION



FUNCTION fl_ayuda_procesos(modulo)
DEFINE rh_proc ARRAY[100] OF RECORD
        g54_modulo	        LIKE gent054.g54_modulo,
        g54_proceso         	LIKE gent054.g54_proceso,
        g54_nombre	        LIKE gent054.g54_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        	SMALLINT
DEFINE modulo		LIKE gent054.g54_modulo
                                                                                
LET filas_max  = 100
OPEN WINDOW w_proc AT 06, 20 WITH 15 ROWS, 59 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf029 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf029'
ELSE
	OPEN FORM f_ayuf029 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf029c'
END IF
DISPLAY FORM f_ayuf029
LET filas_pant = fgl_scr_size('rh_proc')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
IF modulo IS NOT NULL THEN
	DECLARE qh_proc1 CURSOR FOR
        	SELECT g54_modulo, g54_proceso, g54_nombre FROM gent054
			WHERE g54_modulo = modulo
        	ORDER BY 1
	LET i = 1
	FOREACH qh_proc1 INTO rh_proc[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
        	END IF
	END FOREACH
END IF

IF modulo IS NULL THEN
	DECLARE qh_proc2 CURSOR FOR
        	SELECT g54_modulo, g54_proceso, g54_nombre FROM gent054
        	ORDER BY 1
	LET i = 1
	FOREACH qh_proc2 INTO rh_proc[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
        	END IF
	END FOREACH
END IF 
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_proc
        INITIALIZE rh_proc[1].* TO NULL
        RETURN rh_proc[1].g54_modulo, rh_proc[1].g54_proceso, rh_proc[1].g54_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_proc TO rh_proc.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_proc
IF int_flag THEN
        INITIALIZE rh_proc[1].* TO NULL
        RETURN rh_proc[1].g54_modulo, rh_proc[1].g54_proceso, rh_proc[1].g54_nombre
END IF
LET  i = arr_curr()
RETURN rh_proc[i].g54_modulo, rh_proc[i].g54_proceso, rh_proc[i].g54_nombre

END FUNCTION



FUNCTION fl_ayuda_bodegas_rep(r_par)
DEFINE r_par		RECORD
				cod_cia 	LIKE rept002.r02_compania,
				cod_loc 	CHAR(1),
				estado 		LIKE rept002.r02_estado,
				tipo_bod 	LIKE rept002.r02_tipo,
				area 		LIKE rept002.r02_area,
				factura 	LIKE rept002.r02_factura,
				tipo_ident 	LIKE rept002.r02_tipo_ident
			END RECORD
DEFINE rh_bode		ARRAY[200] OF RECORD
   				r02_codigo	LIKE rept002.r02_codigo,
			        r02_nombre	LIKE rept002.r02_nombre,
			        g02_abreviacion	LIKE gent002.g02_abreviacion
		        END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT
DEFINE query		CHAR(1000)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_are		VARCHAR(100)
DEFINE expr_fac		VARCHAR(100)
DEFINE expr_t_i		VARCHAR(100)

LET fil_ini = 6
LET col_ini = 32
LET fil_fin = 14
LET col_fin = 47
IF vg_gui = 0 THEN
	LET fil_ini = 5
	LET col_ini = 31
	LET fil_fin = 16
	LET col_fin = 48
END IF
OPEN WINDOW wh_bode AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf030 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf030'
ELSE
	OPEN FORM f_ayuf030 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf030c'
END IF
DISPLAY FORM f_ayuf030
--#DISPLAY "BD"		TO tit_col1
--#DISPLAY "Nombre"	TO tit_col2
--#DISPLAY "Localidad"	TO tit_col3
LET filas_max  = 200
LET filas_pant = fgl_scr_size('rh_bode')
LET int_flag   = 0
CASE r_par.cod_loc
	WHEN 'G'
		LET expr_loc = '   AND r02_localidad IN (1, 2, 6) '
	WHEN 'Q'
		LET expr_loc = '   AND r02_localidad IN (3, 4, 5, 7) '
	WHEN 'U'
		LET expr_loc = '   AND r02_localidad IN (3, 5) '
	WHEN 'T'
		LET expr_loc = '   AND r02_localidad IS NOT NULL '
	OTHERWISE
		IF r_par.cod_loc < '0' OR r_par.cod_loc > '9' THEN
			CALL fl_mostrar_mensaje('La Localidad solo puede ser 1, 2, 3, 4, 5, 6, 7, G, Q, U o T.', 'info')
			CLOSE WINDOW wh_bode
			INITIALIZE rh_bode[1].* TO NULL
			RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
		END IF
END CASE
IF r_par.cod_loc >= '0' AND r_par.cod_loc <= '9' THEN
	LET expr_loc = '   AND r02_localidad = ', r_par.cod_loc
END IF
CASE r_par.estado
	WHEN 'A'
		LET expr_est = '   AND r02_estado    = "A" '
	WHEN 'B'
		LET expr_est = '   AND r02_estado    = "B" '
	WHEN 'T'
		LET expr_est = '   AND r02_estado    IN ("A", "B") '
	OTHERWISE
		CALL fl_mostrar_mensaje('El Estado solo puede ser A, B o T.', 'info')
		CLOSE WINDOW wh_bode
		INITIALIZE rh_bode[1].* TO NULL
		RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END CASE
CASE r_par.tipo_bod
	WHEN 'F'
		LET expr_tip = '   AND r02_tipo     = "F" '
	WHEN 'L'
		LET expr_tip = '   AND r02_tipo     = "L" '
	WHEN 'S'
		LET expr_tip = '   AND r02_tipo     = "S" '
	WHEN '1'	-- TIPO PARA BODEGAS FISICAS Y LOGICAS
		LET expr_tip = '   AND r02_tipo     IN ("F", "L") '
	WHEN '2'	-- TIPO PARA BODEGAS DE FACTURACION
		LET expr_tip = '   AND r02_tipo     IN ("F", "S") '
	WHEN '3'	-- TIPO PARA BODEGAS LOGICAS Y SIN STOCK
		LET expr_tip = '   AND r02_tipo     IN ("L", "S") '
	WHEN 'T'
		LET expr_tip = '   AND r02_tipo     IN ("F", "L", "S") '
	OTHERWISE
		CALL fl_mostrar_mensaje('El Tipo de Bodega solo puede ser F, L, S, 1, 2, 3, o T.', 'info')
		CLOSE WINDOW wh_bode
		INITIALIZE rh_bode[1].* TO NULL
		RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END CASE
CASE r_par.area
	WHEN 'R'
		LET expr_are = '   AND r02_area      = "R" '
	WHEN 'T'
		LET expr_are = '   AND r02_area      = "T" '
	WHEN 'A'
		LET expr_are = '   AND r02_area      IN ("R", "T") '
	OTHERWISE
		CALL fl_mostrar_mensaje('El Area solo puede ser R, T o A.', 'info')
		CLOSE WINDOW wh_bode
		INITIALIZE rh_bode[1].* TO NULL
		RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END CASE
CASE r_par.factura
	WHEN 'S'
		LET expr_fac = '   AND r02_factura   = "S" '
	WHEN 'N'
		LET expr_fac = '   AND r02_factura   = "N" '
	WHEN 'T'
		LET expr_fac = '   AND r02_factura   IN ("S", "N") '
	OTHERWISE
		CALL fl_mostrar_mensaje('El flag de Facturación solo puede ser S, N o T.', 'info')
		CLOSE WINDOW wh_bode
		INITIALIZE rh_bode[1].* TO NULL
		RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END CASE
IF r_par.tipo_ident >= '0' AND r_par.tipo_ident <= '9' THEN
	CASE r_par.tipo_ident
		WHEN '0'
			LET expr_t_i = '   AND r02_tipo_ident IN ("V", "I") '
		WHEN '1'
			LET expr_t_i = '   AND r02_tipo_ident IN ("V", "I", ',
								'"R") '
		WHEN '2'
			LET expr_t_i = '   AND r02_tipo_ident IN ("V", "I", ',
								'"R", "C") '
		WHEN '3'
			LET expr_t_i = '   AND r02_tipo_ident IN ("V", "R") '
		WHEN '4'
			LET expr_t_i = '   AND r02_tipo_ident IN ("C", "R") '
		WHEN '5'
			LET expr_t_i = '   AND r02_tipo_ident IN ("C", "V") '
		WHEN '6'
			LET expr_t_i = '   AND r02_tipo_ident IN ("V", "X") '
		WHEN '7'
			LET expr_t_i = '   AND r02_tipo_ident IN ("Y", "V") '
		OTHERWISE
			CALL fl_mostrar_mensaje('El tipo identificacion de bodega solo puede ser C, R, I o V.', 'info')
			CLOSE WINDOW wh_bode
			INITIALIZE rh_bode[1].* TO NULL
			RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
	END CASE
ELSE
	LET expr_t_i = '   AND r02_tipo_ident = "', r_par.tipo_ident, '"'
END IF
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1           = 1
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = 'SELECT r02_codigo, r02_nombre, g02_abreviacion',
			' FROM rept002, gent002 ',
			' WHERE r02_compania  = ', r_par.cod_cia,
			expr_est CLIPPED,
			expr_tip CLIPPED,
			expr_are CLIPPED,
			expr_fac CLIPPED,
			expr_loc CLIPPED,
			expr_t_i CLIPPED,
			'   AND g02_compania  = r02_compania ',
			'   AND g02_localidad = r02_localidad ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons_bode FROM query
	DECLARE q_bode CURSOR FOR cons_bode
	LET i = 1
	FOREACH q_bode INTO rh_bode[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY rh_bode TO rh_bode.*
		ON KEY(RETURN)
                       	LET salir = 1
                       	EXIT DISPLAY
		ON KEY(F15)
                       	LET col = 1
                       	EXIT DISPLAY
               	ON KEY(F16)
                       	LET col = 2
                       	EXIT DISPLAY
               	ON KEY(F17)
                       	LET col = 3
                       	EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
               	--#AFTER DISPLAY
                       	--#LET salir = 1
	END DISPLAY
       	IF int_flag = 1 AND col IS NULL THEN
               	EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
               	INITIALIZE col TO NULL
       	END IF
END WHILE
CLOSE WINDOW wh_bode
IF int_flag THEN
       	INITIALIZE rh_bode[1].* TO NULL
        RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END IF
LET i = arr_curr()
RETURN rh_bode[i].r02_codigo, rh_bode[i].r02_nombre

END FUNCTION



FUNCTION fl_ayuda_lineas_rep(cod_cia)
DEFINE rh_linea ARRAY[100] OF RECORD
   	r03_codigo      	LIKE rept003.r03_codigo,
        r03_nombre      	LIKE rept003.r03_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE rept003.r03_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_linea AT 06, 43 WITH 15 ROWS, 36 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf031 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf031'
ELSE
	OPEN FORM f_ayuf031 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf031c'
END IF
DISPLAY FORM f_ayuf031
LET filas_pant = fgl_scr_size('rh_linea')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_linea CURSOR FOR
        SELECT r03_codigo, r03_nombre FROM rept003
	WHERE r03_compania = cod_cia
	  AND r03_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_linea INTO rh_linea[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_linea
        INITIALIZE rh_linea[1].* TO NULL
        RETURN rh_linea[1].r03_codigo, rh_linea[1].r03_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_linea TO rh_linea.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_linea
IF int_flag THEN
        INITIALIZE rh_linea[1].* TO NULL
        RETURN rh_linea[1].r03_codigo, rh_linea[1].r03_nombre
END IF
LET  i = arr_curr()
RETURN rh_linea[i].r03_codigo, rh_linea[i].r03_nombre

END FUNCTION



FUNCTION fl_ayuda_clases(cod_cia)
DEFINE rh_clase ARRAY[100] OF RECORD
   	r04_rotacion      	LIKE rept004.r04_rotacion,
        r04_nombre      	LIKE rept004.r04_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept004.r04_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_clase AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf032 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf032'
ELSE
	OPEN FORM f_ayuf032 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf032c'
END IF
DISPLAY FORM f_ayuf032
LET filas_pant = fgl_scr_size('rh_clase')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_clase CURSOR FOR
        SELECT r04_rotacion, r04_nombre FROM rept004
	WHERE r04_compania = cod_cia
	  AND r04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_clase INTO rh_clase[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_clase
        INITIALIZE rh_clase[1].* TO NULL
        RETURN rh_clase[1].r04_rotacion, rh_clase[1].r04_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_clase TO rh_clase.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_clase
IF int_flag THEN
        INITIALIZE rh_clase[1].* TO NULL
        RETURN rh_clase[1].r04_rotacion, rh_clase[1].r04_nombre
END IF
LET  i = arr_curr()
RETURN rh_clase[i].r04_rotacion, rh_clase[i].r04_nombre

END FUNCTION




FUNCTION fl_ayuda_tipo_item()
DEFINE rh_tipitem ARRAY[100] OF RECORD
   	r06_codigo      	LIKE rept006.r06_codigo,
        r06_nombre      	LIKE rept006.r06_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_tipitem AT 06, 56 WITH 15 ROWS, 23 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf033 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf033'
ELSE
	OPEN FORM f_ayuf033 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf033c'
END IF
DISPLAY FORM f_ayuf033
LET filas_pant = fgl_scr_size('rh_tipitem')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_tipitem CURSOR FOR
        SELECT r06_codigo, r06_nombre FROM rept006
        ORDER BY 1
LET i = 1
FOREACH q_tipitem INTO rh_tipitem[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tipitem
        INITIALIZE rh_tipitem[1].* TO NULL
        RETURN rh_tipitem[1].r06_codigo, rh_tipitem[1].r06_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipitem TO rh_tipitem.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tipitem
IF int_flag THEN
        INITIALIZE rh_tipitem[1].* TO NULL
        RETURN rh_tipitem[1].r06_codigo, rh_tipitem[1].r06_nombre
END IF
LET  i = arr_curr()
RETURN rh_tipitem[i].r06_codigo, rh_tipitem[i].r06_nombre

END FUNCTION



FUNCTION fl_ayuda_tipo_tran(tipo)
DEFINE rh_tiptran ARRAY[100] OF RECORD
   	g21_cod_tran      	LIKE gent021.g21_cod_tran,
        g21_nombre      	LIKE gent021.g21_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE tipo		LIKE gent021.g21_tipo                                                                                
LET filas_max  = 100
OPEN WINDOW wh_tiptran AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf034 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf034'
ELSE
	OPEN FORM f_ayuf034 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf034c'
END IF
DISPLAY FORM f_ayuf034
LET filas_pant = fgl_scr_size('rh_tiptran')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF tipo ='N' THEN
DECLARE q_tiptran1 CURSOR FOR
 	SELECT g21_cod_tran, g21_nombre FROM gent021
        			WHERE g21_estado = 'A'
        				ORDER BY 1
	LET i = 1
	FOREACH q_tiptran1 INTO rh_tiptran[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
IF tipo ='I' THEN
DECLARE q_tiptran2 CURSOR FOR
        SELECT g21_cod_tran, g21_nombre FROM gent021
                                WHERE g21_estado = 'A'
				  AND g21_tipo = 'E'
                                        ORDER BY 1 
	LET i = 1
	FOREACH q_tiptran2 INTO rh_tiptran[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
IF tipo ='E' THEN
DECLARE q_tiptran3 CURSOR FOR
	SELECT g21_cod_tran, g21_nombre FROM gent021
				WHERE g21_estado = 'A'
				  AND g21_tipo = 'I'
					ORDER BY 1 
	LET i = 1
	FOREACH q_tiptran3 INTO rh_tiptran[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
        END IF
	END FOREACH
END IF

LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tiptran
        INITIALIZE rh_tiptran[1].* TO NULL
        RETURN rh_tiptran[1].g21_cod_tran, rh_tiptran[1].g21_nombre  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tiptran TO rh_tiptran.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tiptran
IF int_flag THEN
        INITIALIZE rh_tiptran[1].* TO NULL
        RETURN rh_tiptran[1].g21_cod_tran, rh_tiptran[1].g21_nombre
END IF
LET  i = arr_curr()
RETURN rh_tiptran[i].g21_cod_tran, rh_tiptran[i].g21_nombre

END FUNCTION




FUNCTION fl_ayuda_subtipo_tran(tipo)
DEFINE rh_subtran ARRAY[100] OF RECORD
   	g22_cod_tran      	LIKE gent022.g22_cod_tran,
   	g22_cod_subtipo      	LIKE gent022.g22_cod_subtipo,
        g22_nombre      	LIKE gent022.g22_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE tipo		LIKE gent022.g22_cod_tran
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_subtran AT 06, 39 WITH 15 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf035 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf035'
ELSE
	OPEN FORM f_ayuf035 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf035c'
END IF
DISPLAY FORM f_ayuf035
LET filas_pant = fgl_scr_size('rh_subtran')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF tipo IS NOT NULL THEN
	DECLARE q_subtran1 CURSOR FOR
        	SELECT g22_cod_tran, g22_cod_subtipo, g22_nombre
		  FROM gent022
         	WHERE g22_estado = 'A'
	   	  AND g22_cod_tran = tipo
         	ORDER BY 1
	LET i = 1
	FOREACH q_subtran1 INTO rh_subtran[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
ELSE
	DECLARE q_subtran2 CURSOR FOR
        	SELECT g22_cod_tran, g22_cod_subtipo, g22_nombre
		  FROM gent022
         	WHERE g22_estado = 'A'
         	ORDER BY 1
	LET i = 1
	FOREACH q_subtran2 INTO rh_subtran[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_subtran
        INITIALIZE rh_subtran[1].* TO NULL
        RETURN 	rh_subtran[1].g22_cod_tran, rh_subtran[1].g22_cod_subtipo,
		rh_subtran[1].g22_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subtran TO rh_subtran.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_subtran
IF int_flag THEN
        INITIALIZE rh_subtran[1].* TO NULL
        RETURN 	rh_subtran[1].g22_cod_tran, rh_subtran[1].g22_cod_subtipo,
		rh_subtran[1].g22_nombre
END IF
LET  i = arr_curr()
RETURN 	rh_subtran[i].g22_cod_tran, rh_subtran[i].g22_cod_subtipo,
	rh_subtran[i].g22_nombre

END FUNCTION





FUNCTION fl_ayuda_rubros()
DEFINE rh_rubros ARRAY[100] OF RECORD
   	g17_codrubro      	LIKE gent017.g17_codrubro,
        g17_nombre      	LIKE gent017.g17_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_rubros AT 06, 42 WITH 15 ROWS, 37 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf036 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf036'
ELSE
	OPEN FORM f_ayuf036 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf036c'
END IF
DISPLAY FORM f_ayuf036
LET filas_pant = fgl_scr_size('rh_rubros')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_rubros CURSOR FOR
        SELECT g17_codrubro, g17_nombre FROM gent017
        ORDER BY 2
LET i = 1
FOREACH q_rubros INTO rh_rubros[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_rubros
        INITIALIZE rh_rubros[1].* TO NULL
        RETURN rh_rubros[1].g17_codrubro, rh_rubros[1].g17_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_rubros TO rh_rubros.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_rubros
IF int_flag THEN
        INITIALIZE rh_rubros[1].* TO NULL
        RETURN rh_rubros[1].g17_codrubro, rh_rubros[1].g17_nombre
END IF
LET  i = arr_curr()
RETURN rh_rubros[i].g17_codrubro, rh_rubros[i].g17_nombre

END FUNCTION



FUNCTION fl_ayuda_vendedores(cod_cia, estado, tipo_vend)
DEFINE cod_cia 		LIKE rept001.r01_compania
DEFINE estado 		LIKE rept001.r01_estado
DEFINE tipo_vend 	LIKE rept001.r01_tipo
DEFINE rh_vend		ARRAY[200] OF RECORD
   				r01_codigo	LIKE rept001.r01_codigo,
			        r01_nombres	LIKE rept001.r01_nombres,
			        r01_iniciales	LIKE rept001.r01_iniciales,
			        r01_user_owner	LIKE rept001.r01_user_owner
		        END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)

LET fil_ini = 6
LET col_ini = 27
LET fil_fin = 14
LET col_fin = 52
IF vg_gui = 0 THEN
	LET fil_ini = 5
	LET col_ini = 26
	LET fil_fin = 16
	LET col_fin = 53
END IF
OPEN WINDOW wh_vend AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf038 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf038'
ELSE
	OPEN FORM f_ayuf038 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf038c'
END IF
DISPLAY FORM f_ayuf038
--#DISPLAY "Cod."	TO tit_col1
--#DISPLAY "Nombres"	TO tit_col2
--#DISPLAY "Ini."	TO tit_col3
--#DISPLAY "Usuario"	TO tit_col4
LET filas_max  = 200
LET filas_pant = fgl_scr_size('rh_vend')
LET int_flag   = 0
CASE estado
	WHEN 'A'
		LET expr_est = '   AND r01_estado   = "A" '
	WHEN 'B'
		LET expr_est = '   AND r01_estado   = "B" '
	WHEN 'T'
		LET expr_est = '   AND r01_estado   IN ("A", "B") '
	OTHERWISE
		CALL fl_mostrar_mensaje('El Estado solo puede ser A, B o T.', 'info')
		CLOSE WINDOW wh_vend
		INITIALIZE rh_vend[1].* TO NULL
		RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END CASE
CASE tipo_vend
	WHEN 'I'
		LET expr_tip = '   AND r01_tipo     = "I" '
	WHEN 'E'
		LET expr_tip = '   AND r01_tipo     = "E" '
	WHEN 'B'
		LET expr_tip = '   AND r01_tipo     = "B" '
	WHEN 'J'
		LET expr_tip = '   AND r01_tipo     = "J" '
	WHEN 'G'
		LET expr_tip = '   AND r01_tipo     = "G" '
	WHEN 'V'
		LET expr_tip = '   AND r01_tipo     IN ("I","E") '
	WHEN 'A'
		LET expr_tip = '   AND r01_tipo     IN ("J","G") '
	WHEN 'M'
		LET expr_tip = '   AND r01_tipo     IN ("B","J","G") '
	WHEN 'F'
		LET expr_tip = '   AND r01_tipo     IN ("I","E","J","G") '
	WHEN 'T'
		LET expr_tip = '   AND r01_tipo     IN ("I","E","B","J","G") '
	OTHERWISE
		CALL fl_mostrar_mensaje('El Tipo de Vendedor solo puede ser A, I, E, B, J, G, V, M, F o T.', 'info')
		CLOSE WINDOW wh_vend
		INITIALIZE rh_vend[1].* TO NULL
		RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END CASE
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1           = 2
LET vm_columna_2           = 1
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = 'SELECT r01_codigo, r01_nombres, r01_iniciales,',
			' r01_user_owner ',
			' FROM rept001 ',
			' WHERE r01_compania = ', cod_cia,
			expr_est CLIPPED,
			expr_tip CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons_vend FROM query
	DECLARE q_vend CURSOR FOR cons_vend
	LET i = 1
	FOREACH q_vend INTO rh_vend[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY rh_vend TO rh_vend.*
		ON KEY(RETURN)
                       	LET salir = 1
                       	EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
               	--#AFTER DISPLAY
                       	--#LET salir = 1
	END DISPLAY
       	IF int_flag = 1 AND col IS NULL THEN
               	EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
               	INITIALIZE col TO NULL
       	END IF
END WHILE
CLOSE WINDOW wh_vend
IF int_flag THEN
       	INITIALIZE rh_vend[1].* TO NULL
        RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END IF
LET i = arr_curr()
RETURN rh_vend[i].r01_codigo, rh_vend[i].r01_nombres

END FUNCTION



FUNCTION fl_ayuda_codigo_empleado(cod_cia)
DEFINE rh_codigo_empleado ARRAY[1000] OF RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_estado	LIKE rolt030.n30_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE actt010.a10_compania
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codigo_empleado AT 06, 35 WITH 15 ROWS, 44 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf039 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf039'
ELSE
	OPEN FORM f_ayuf039 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf039c'
END IF
DISPLAY FORM f_ayuf039
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'    	TO bt_codigo
--#DISPLAY 'Nombres' 	TO bt_nombres
--#DISPLAY 'E'	 	TO bt_estado

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n30_cod_trab, n30_nombres, n30_estado
	IF int_flag THEN
		CLOSE WINDOW w_codigo_empleado
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------------
LET vm_columna_1 = 2
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT n30_cod_trab, n30_nombres, n30_estado ",
				" FROM rolt030 ",
				" WHERE n30_compania = ", cod_cia,
				--"   AND n30_estado   <> 'I' ",
				"   AND ", expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE codigo_empleado FROM query
	DECLARE q_codigo_empleado CURSOR FOR codigo_empleado
	LET i = 1
	FOREACH q_codigo_empleado INTO rh_codigo_empleado[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_codigo_empleado TO rh_codigo_empleado.*
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF int_flag = 4 THEN
	FOR i = 1 TO filas_pant
		INITIALIZE rh_codigo_empleado[i].* TO NULL
		CLEAR rh_codigo_empleado[i].*
	END FOR
END IF
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_codigo_empleado
	EXIT WHILE
END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codigo_empleado[1].* TO NULL
	RETURN rh_codigo_empleado[1].n30_cod_trab,
		rh_codigo_empleado[1].n30_nombres
END IF
LET i = arr_curr()
RETURN rh_codigo_empleado[i].n30_cod_trab, rh_codigo_empleado[i].n30_nombres

END FUNCTION



-- OjO: No usar esta ayuda, NO VALE
FUNCTION fl_ayuda_trabajadores(cod_cia)
DEFINE rh_trab ARRAY[100] OF RECORD
   	n30_cod_trab      	LIKE rolt030.n30_cod_trab,
        n30_nombres      	LIKE rolt030.n30_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia 		LIKE rolt030.n30_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_trab AT 06,27
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf039'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_trab')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_trab CURSOR FOR
        SELECT n30_cod_trab, n30_nombres FROM rolt030
	WHERE n30_compania = cod_cia
        ORDER BY 2
LET i = 1
FOREACH q_trab INTO rh_trab[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_trab
        INITIALIZE rh_trab[1].* TO NULL
        RETURN rh_trab[1].n30_cod_trab, rh_trab[1].n30_nombres
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_trab TO rh_trab.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_trab
IF int_flag THEN
        INITIALIZE rh_trab[1].* TO NULL
        RETURN rh_trab[1].n30_cod_trab, rh_trab[1].n30_nombres
END IF
LET  i = arr_curr()
RETURN rh_trab[i].n30_cod_trab, rh_trab[i].n30_nombres

END FUNCTION



FUNCTION fl_ayuda_zona_cobro(comision, estado)
DEFINE comision		LIKE cxct006.z06_comision
DEFINE estado		LIKE cxct006.z06_estado
DEFINE rh_zoncob	ARRAY[1000] OF RECORD
				z06_zona_cobro	LIKE cxct006.z06_zona_cobro,
				z06_nombre	LIKE cxct006.z06_nombre,
				z06_comision	LIKE cxct006.z06_comision,
				z06_estado	LIKE cxct006.z06_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_com		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_z06		RECORD LIKE cxct006.*

LET max_row = 1000
LET num_fil = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_zoncob AT 06, 34 WITH num_fil ROWS, 45 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf037 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf037'
ELSE
	OPEN FORM f_ayuf037 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf037c'
END IF
DISPLAY FORM f_ayuf037
LET filas_pant = fgl_scr_size('rh_zoncob')
--#DISPLAY "Zona"		TO tit_col1
--#DISPLAY "Descripcion"	TO tit_col2
--#DISPLAY "C"			TO tit_col3
--#DISPLAY "E"			TO tit_col4
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND z06_estado   = "', estado, '"'
END IF
LET expr_com = NULL
IF comision <> 'T' THEN
	LET expr_com = '   AND z06_comision = "', comision, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON z06_zona_cobro, z06_nombre,
						z06_comision
		IF int_flag THEN
			CLOSE WINDOW wh_zoncob
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 2
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM cxct006 ',
				'WHERE ', expr_sql CLIPPED, ' ',
					expr_est CLIPPED,
					expr_com CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1],
					', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE zoncob FROM query
		DECLARE q_zoncob CURSOR FOR zoncob
		LET i = 1
		FOREACH q_zoncob INTO r_z06.*
			LET rh_zoncob[i].z06_zona_cobro = r_z06.z06_zona_cobro
			LET rh_zoncob[i].z06_nombre     = r_z06.z06_nombre
			LET rh_zoncob[i].z06_comision   = r_z06.z06_comision
			LET rh_zoncob[i].z06_estado     = r_z06.z06_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i     = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_zoncob TO rh_zoncob.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_zoncob[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				IF comision = 'T' THEN
					LET col = 3
					EXIT DISPLAY
				END IF
			ON KEY(F18)
				IF estado = 'T' THEN
					LET col = 4
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_zoncob
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_zoncob[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_zoncob[1].* TO NULL
	RETURN rh_zoncob[1].z06_zona_cobro, rh_zoncob[1].z06_nombre
END IF
LET i = arr_curr()
RETURN rh_zoncob[i].z06_zona_cobro, rh_zoncob[i].z06_nombre

END FUNCTION



FUNCTION fl_ayuda_cobradores(cod_cia, tipo, comision, estado)
DEFINE cod_cia 		LIKE cxct005.z05_compania
DEFINE tipo		LIKE cxct005.z05_tipo
DEFINE comision		LIKE cxct005.z05_comision
DEFINE estado		LIKE cxct005.z05_estado
DEFINE rh_cobra		ARRAY[1000] OF RECORD
				z05_codigo	LIKE cxct005.z05_codigo,
				z05_nombres	LIKE cxct005.z05_nombres,
				z05_codrol	LIKE cxct005.z05_codrol,
				z05_tipo	LIKE cxct005.z05_tipo,
				z05_comision	LIKE cxct005.z05_comision,
				z05_estado	LIKE cxct005.z05_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_com		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_z05		RECORD LIKE cxct005.*

LET max_row = 1000
LET num_fil = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_cobra AT 06, 27 WITH num_fil ROWS, 52 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf040 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf040'
ELSE
	OPEN FORM f_ayuf040 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf040c'
END IF
DISPLAY FORM f_ayuf040
LET filas_pant = fgl_scr_size('rh_cobra')
--#DISPLAY "Codigo"		 TO tit_col1
--#DISPLAY "Cobrador/Recaudador" TO tit_col2
--#DISPLAY "C.Rol"		 TO tit_col3
--#DISPLAY "T"			 TO tit_col4
--#DISPLAY "C"			 TO tit_col5
--#DISPLAY "E"			 TO tit_col6
LET expr_tip = NULL
IF tipo <> 'T' THEN
	LET expr_tip = '   AND z05_tipo     = "', tipo, '"'
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND z05_estado   = "', estado, '"'
END IF
LET expr_com = NULL
IF comision <> 'T' THEN
	LET expr_com = '   AND z05_comision = "', comision, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON z05_codigo, z05_nombres,
						z05_codrol, z05_tipo,
						z05_comision
		IF int_flag THEN
			CLOSE WINDOW wh_cobra
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 2
	LET vm_columna_2 = 5
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM cxct005 ',
				'WHERE z05_compania = ', cod_cia,
					expr_tip CLIPPED,
					expr_est CLIPPED,
					expr_com CLIPPED,
				'  AND ', expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1],
					', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		PREPARE cobra FROM query
		DECLARE q_cobra CURSOR FOR cobra
		LET i = 1
		FOREACH q_cobra INTO r_z05.*
			LET rh_cobra[i].z05_codigo   = r_z05.z05_codigo
			LET rh_cobra[i].z05_nombres  = r_z05.z05_nombres
			LET rh_cobra[i].z05_codrol   = r_z05.z05_codrol
			LET rh_cobra[i].z05_tipo     = r_z05.z05_tipo
			LET rh_cobra[i].z05_comision = r_z05.z05_comision
			LET rh_cobra[i].z05_estado   = r_z05.z05_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i     = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_cobra TO rh_cobra.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_cobra[i].*
				END FOR
				EXIT DISPLAY
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
			ON KEY(F20)
				LET col = 6
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_cobra
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_cobra[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cobra[1].* TO NULL
	RETURN rh_cobra[1].z05_codigo, rh_cobra[1].z05_nombres
END IF
LET i = arr_curr()
RETURN rh_cobra[i].z05_codigo, rh_cobra[i].z05_nombres

END FUNCTION



FUNCTION fl_ayuda_plazos_credito(cod_cia)
DEFINE rh_cred ARRAY[100] OF RECORD
   	z07_serial      	LIKE cxct007.z07_serial,
        z07_monto_ini      	LIKE cxct007.z07_monto_ini,
        z07_monto_fin      	LIKE cxct007.z07_monto_fin
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia 		LIKE cxct007.z07_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_cred AT 06, 33 WITH 15 ROWS, 46 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf041 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf041'
ELSE
	OPEN FORM f_ayuf041 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf041c'
END IF
DISPLAY FORM f_ayuf041
LET filas_pant = fgl_scr_size('rh_cred')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_cred CURSOR FOR
        SELECT z07_serial, z07_monto_ini, z07_monto_fin FROM cxct007
	WHERE  z07_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_cred INTO rh_cred[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_cred
        INITIALIZE rh_cred[1].* TO NULL
        RETURN 	rh_cred[1].z07_serial, rh_cred[1].z07_monto_ini, 
		rh_cred[1].z07_monto_fin
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cred TO rh_cred.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_cred
IF int_flag THEN
        INITIALIZE rh_cred[1].* TO NULL
        RETURN 	rh_cred[1].z07_serial, rh_cred[1].z07_monto_ini, 
		rh_cred[1].z07_monto_fin
END IF
LET  i = arr_curr()
        RETURN 	rh_cred[i].z07_serial, rh_cred[i].z07_monto_ini, 
		rh_cred[i].z07_monto_fin

END FUNCTION



FUNCTION fl_ayuda_tipo_documento_cobranzas(tipo)
DEFINE rh_tipdoc ARRAY[1000] OF RECORD
   	z04_tipo_doc      	LIKE cxct004.z04_tipo_doc,
        z04_nombre      	LIKE cxct004.z04_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE tipo		LIKE cxct004.z04_tipo
                                                                                
LET filas_max  = 1000
OPEN WINDOW wh_tipdoc AT 06, 53 WITH 15 ROWS, 26 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf042 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf042'
ELSE
	OPEN FORM f_ayuf042 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf042c'
END IF
DISPLAY FORM f_ayuf042
LET filas_pant = fgl_scr_size('rh_tipdoc')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
-------------
IF tipo = 'D' THEN   ## PARA TIPO DEUDORES
DECLARE q_tipdoc1 CURSOR FOR
        SELECT z04_tipo_doc, z04_nombre FROM cxct004
	WHERE z04_tipo = tipo
	  AND z04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdoc1 INTO rh_tipdoc[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF tipo = 'F' THEN   ## PARA TIPO A FAVOR
DECLARE q_tipdoc2 CURSOR FOR
        SELECT z04_tipo_doc, z04_nombre FROM cxct004
        WHERE z04_tipo = tipo
	  AND z04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdoc2 INTO rh_tipdoc[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF tipo = 'T' THEN   ## PARA TIPO TRANSACCIONES
DECLARE q_tipdoc3 CURSOR FOR
        SELECT z04_tipo_doc, z04_nombre FROM cxct004
        WHERE z04_tipo = tipo
	  AND z04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdoc3 INTO rh_tipdoc[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF tipo = '0' THEN   ## PARA TODOS LOS DOCUMENTOS
DECLARE q_tipdoc4 CURSOR FOR
        SELECT z04_tipo_doc, z04_nombre FROM cxct004
	 WHERE z04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdoc4 INTO rh_tipdoc[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
-------------
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tipdoc
        INITIALIZE rh_tipdoc[1].* TO NULL
        RETURN 	rh_tipdoc[1].z04_tipo_doc, rh_tipdoc[1].z04_nombre  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipdoc TO rh_tipdoc.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tipdoc
IF int_flag THEN
        INITIALIZE rh_tipdoc[1].* TO NULL
        RETURN 	rh_tipdoc[1].z04_tipo_doc, rh_tipdoc[1].z04_nombre  
END IF
LET  i = arr_curr()
RETURN 	rh_tipdoc[i].z04_tipo_doc, rh_tipdoc[i].z04_nombre  

END FUNCTION



FUNCTION fl_ayuda_unidad_medida()
DEFINE rh_unimed ARRAY[100] OF RECORD
   	r05_codigo      	LIKE rept005.r05_codigo,
        r05_siglas      	LIKE rept005.r05_siglas 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_unimed AT 06, 59 WITH 15 ROWS, 20 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf043 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf043'
ELSE
	OPEN FORM f_ayuf043 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf043c'
END IF
DISPLAY FORM f_ayuf043
LET filas_pant = fgl_scr_size('rh_unimed')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_unimed CURSOR FOR
        SELECT r05_codigo, r05_siglas FROM rept005
        ORDER BY 1
LET i = 1
FOREACH q_unimed INTO rh_unimed[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_unimed
        INITIALIZE rh_unimed[1].* TO NULL
        RETURN 	rh_unimed[1].r05_codigo, rh_unimed[1].r05_siglas  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_unimed TO rh_unimed.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_unimed
IF int_flag THEN
        INITIALIZE rh_unimed[1].* TO NULL
        RETURN 	rh_unimed[1].r05_codigo, rh_unimed[1].r05_siglas  
END IF
LET  i = arr_curr()
RETURN 	rh_unimed[i].r05_codigo, rh_unimed[i].r05_siglas  

END FUNCTION


 
FUNCTION fl_ayuda_maestro_items(cod_cia,linea)
DEFINE rh_items ARRAY[1000] OF RECORD
   	r10_codigo      	LIKE rept010.r10_codigo,
   	r10_nombre      	LIKE rept010.r10_nombre 
	END RECORD
DEFINE i		SMALLINT
DEFINE criterio	CHAR(500)	## Contiene el CONSTRUCT del usuario
DEFINE sentencia	CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia, cia	LIKE rept010.r10_compania
DEFINE linea 		LIKE rept010.r10_linea
DEFINE expr_linea	CHAR(25)
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT NO WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_items AT 06, 20 WITH 15 ROWS, 60 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST,
                   BORDER)
IF vg_gui = 1 THEN 
	OPEN FORM f_ayuf044 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf044'
ELSE
	OPEN FORM f_ayuf044 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf044c'
END IF
DISPLAY FORM f_ayuf044
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Código'      TO bt_codigo
--#DISPLAY 'Descripción' TO bt_nombre
CREATE TEMP TABLE te_item99 
	(te_codigo		CHAR(15),
	 te_nombre		VARCHAR(40))
WHILE TRUE
	DELETE FROM te_item99
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON r10_codigo, r10_nombre
	IF int_flag THEN
		CLOSE WINDOW w_items
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
--------------
	LET expr_linea = " 1 = 1 "
	IF linea <> "TODOS"  THEN
		LET expr_linea = " r10_linea =  '", linea CLIPPED, "'"  
	END IF
--------------
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET sentencia = " INSERT INTO te_item99 ",
				" SELECT r10_codigo, r10_nombre ",
				" FROM rept010 ",
				" WHERE r10_compania = ", cod_cia, " AND ", 
				 expr_linea, " AND ", 
				 criterio CLIPPED
	PREPARE barry FROM sentencia
	EXECUTE barry
{
	DECLARE q_barry CURSOR FOR barry 
	LET i = 1 
	FOREACH q_barry INTO rh_items[1].* 
		INSERT INTO te_item99 VALUES (rh_items[1].*)
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF i - 1 = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
}
                                                                                
LET salir = 0
WHILE NOT salir

	LET sentencia = "SELECT * FROM te_item99 ",
                    ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                     ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE hit FROM sentencia
	DECLARE q_items CURSOR FOR hit
	LET i = 1
	FOREACH q_items INTO rh_items[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_items TO rh_items.*
		ON KEY(F2)
			LET int_flag = 4
			FOR i = 1 TO filas_pant
				CLEAR rh_items[i].*
			END FOR
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
	IF vg_gui = 0 THEN
	        LET salir = 1
	END IF
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
	CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_items
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_items[i].*
END FOR
END WHILE
DROP TABLE te_item99
IF int_flag <> 0 THEN
	INITIALIZE rh_items[1].* TO NULL
	RETURN rh_items[1].*
END IF
LET i = arr_curr()
RETURN rh_items[i].*

END FUNCTION
 



FUNCTION fl_ayuda_companias_taller()
DEFINE rh_ciatal ARRAY[100] OF RECORD
        t00_compania       	LIKE talt000.t00_compania,
        g01_razonsocial       	LIKE gent001.g01_razonsocial 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_ciatal AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf045 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf045'
ELSE
	OPEN FORM f_ayuf045 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf045c'
END IF
DISPLAY FORM f_ayuf045
LET filas_pant = fgl_scr_size('rh_ciatal')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_ciatal CURSOR FOR
        SELECT t00_compania, g01_razonsocial
		FROM talt000, gent001
		WHERE t00_compania = g01_compania
		  AND g01_estado <> 'B'
        ORDER BY 1
LET i = 1
FOREACH qh_ciatal INTO rh_ciatal[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_ciatal
        INITIALIZE rh_ciatal[1].* TO NULL
        RETURN rh_ciatal[1].t00_compania, rh_ciatal[1].g01_razonsocial
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciatal TO rh_ciatal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_ciatal
IF int_flag THEN
        INITIALIZE rh_ciatal[1].* TO NULL
        RETURN rh_ciatal[1].t00_compania, rh_ciatal[1].g01_razonsocial
END IF
LET  i = arr_curr()
RETURN rh_ciatal[i].t00_compania, rh_ciatal[i].g01_razonsocial

END FUNCTION


 

FUNCTION fl_ayuda_bodegas_veh(cod_cia)
DEFINE rh_bodveh ARRAY[100] OF RECORD
   	v02_bodega      	LIKE veht002.v02_bodega,
        v02_nombre      	LIKE veht002.v02_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht002.v02_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_bodveh AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf046 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf046'
ELSE
	OPEN FORM f_ayuf046 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf046c'
END IF
DISPLAY FORM f_ayuf046
LET filas_pant = fgl_scr_size('rh_bodveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_bodveh CURSOR FOR
        SELECT v02_bodega, v02_nombre FROM veht002
	WHERE v02_compania = cod_cia
	AND v02_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_bodveh INTO rh_bodveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_bodveh
        INITIALIZE rh_bodveh[1].* TO NULL
        RETURN rh_bodveh[1].v02_bodega, rh_bodveh[1].v02_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_bodveh TO rh_bodveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_bodveh
IF int_flag THEN
        INITIALIZE rh_bodveh[1].* TO NULL
        RETURN rh_bodveh[1].v02_bodega, rh_bodveh[1].v02_nombre
END IF
LET  i = arr_curr()
RETURN rh_bodveh[i].v02_bodega, rh_bodveh[i].v02_nombre

END FUNCTION

 

FUNCTION fl_ayuda_secciones_taller(cod_cia)
DEFINE rh_sectal ARRAY[100] OF RECORD
   	t02_seccion      	LIKE talt002.t02_seccion,
        t02_nombre      	LIKE talt002.t02_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt002.t02_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_sectal AT 06, 40 WITH 15 ROWS, 39 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf047 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf047'
ELSE
	OPEN FORM f_ayuf047 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf047c'
END IF
DISPLAY FORM f_ayuf047
LET filas_pant = fgl_scr_size('rh_sectal')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_sectal CURSOR FOR
        SELECT t02_seccion, t02_nombre FROM talt002
	WHERE t02_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_sectal INTO rh_sectal[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_sectal
        INITIALIZE rh_sectal[1].* TO NULL
        RETURN rh_sectal[1].t02_seccion, rh_sectal[1].t02_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_sectal TO rh_sectal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_sectal
IF int_flag THEN
        INITIALIZE rh_sectal[1].* TO NULL
        RETURN rh_sectal[1].t02_seccion, rh_sectal[1].t02_nombre
END IF
LET  i = arr_curr()
RETURN rh_sectal[i].t02_seccion, rh_sectal[i].t02_nombre

END FUNCTION

 


FUNCTION fl_ayuda_mecanicos(cod_cia, tipo)
DEFINE cod_cia		LIKE talt003.t03_compania
DEFINE tipo		LIKE talt003.t03_tipo
DEFINE rh_mectal	ARRAY[1000] OF RECORD
   				t03_mecanico	LIKE talt003.t03_mecanico,
			        t03_nombres	LIKE talt003.t03_nombres,
			        t03_iniciales	LIKE talt003.t03_iniciales,
			        t03_codrol	LIKE talt003.t03_codrol
		        END RECORD
DEFINE i, j, filas_max	SMALLINT        ## No. elementos del arreglo
DEFINE expr_sql		CHAR(400)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1500)	## Contiene todo el query preparado
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE expr_tipo	VARCHAR(100)
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_max = 1000
OPEN WINDOW wh_mectal AT 06, 31 WITH 14 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf048 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf048'
ELSE
	OPEN FORM f_ayuf048 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf048c'
END IF
DISPLAY FORM f_ayuf048
LET filas_pant = fgl_scr_size('rh_mectal')
IF vg_gui = 1 THEN
	DISPLAY "Codigo"	 TO tit_col1
	DISPLAY "Tecnico/Asesor" TO tit_col2
	DISPLAY "Ini"            TO tit_col3
	DISPLAY "C. Rol"         TO tit_col4
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON t03_mecanico, t03_nombres,
						t03_iniciales, t03_codrol
		IF int_flag THEN
			CLOSE WINDOW wh_mectal
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_tipo = NULL
	IF tipo <> 'T' THEN
		LET expr_tipo = "   AND t03_tipo     = '", tipo, "'"
	END IF
	LET vm_columna_1 = 2
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT t03_mecanico, t03_nombres, t03_iniciales, ",
					"t03_codrol ",
				" FROM talt003 ",
				" WHERE t03_compania = ", cod_cia,
				expr_tipo CLIPPED,
				"   AND ", expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
						rm_orden[vm_columna_1], ', ',
						vm_columna_2, ' ',
						rm_orden[vm_columna_2]
		PREPARE mecase FROM query
		DECLARE q_mectal CURSOR FOR mecase
		LET i = 1
		FOREACH q_mectal INTO rh_mectal[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
        		CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		MESSAGE "                                           "
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_mectal TO rh_mectal.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_mectal[i].* TO NULL
			CLEAR rh_mectal[i].*
		END FOR
		CLEAR num_rows, max_rows
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_mectal
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_mectal[1].* TO NULL
	RETURN rh_mectal[1].t03_mecanico, rh_mectal[1].t03_nombres
END IF
LET i = arr_curr()
RETURN rh_mectal[i].t03_mecanico, rh_mectal[i].t03_nombres

END FUNCTION

 


FUNCTION fl_ayuda_tipos_vehiculos(cod_cia)
DEFINE rh_tipveh ARRAY[300] OF RECORD
   	t04_modelo      	LIKE talt004.t04_modelo,
        t04_linea	      	LIKE talt004.t04_linea
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt004.t04_compania
                                                                                
LET filas_max  = 300
OPEN WINDOW wh_tipveh AT 06,52
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf049'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_tipveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_tipveh CURSOR FOR
        SELECT t04_modelo, t04_linea FROM talt004
	WHERE t04_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_tipveh INTO rh_tipveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tipveh
        INITIALIZE rh_tipveh[1].* TO NULL
        RETURN rh_tipveh[1].t04_modelo, rh_tipveh[1].t04_linea 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipveh TO rh_tipveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tipveh
IF int_flag THEN
        INITIALIZE rh_tipveh[1].* TO NULL
        RETURN rh_tipveh[1].t04_modelo, rh_tipveh[1].t04_linea 
END IF
LET  i = arr_curr()
RETURN rh_tipveh[i].t04_modelo, rh_tipveh[i].t04_linea 

END FUNCTION

 
 
 
FUNCTION fl_ayuda_marcas_taller(cod_cia)
DEFINE rh_martal ARRAY[100] OF RECORD
   	t01_linea	      	LIKE talt001.t01_linea,
        t01_nombre	      	LIKE talt001.t01_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt004.t04_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_martal AT 06, 48 WITH 15 ROWS, 31 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf050 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf050'
ELSE
	OPEN FORM f_ayuf050 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf050c'
END IF
DISPLAY FORM f_ayuf050
LET filas_pant = fgl_scr_size('rh_martal')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_martal CURSOR FOR
        SELECT t01_linea, t01_nombre FROM talt001
	WHERE t01_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_martal INTO rh_martal[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_martal
        INITIALIZE rh_martal[1].* TO NULL
        RETURN rh_martal[1].t01_linea, rh_martal[1].t01_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_martal TO rh_martal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_martal
IF int_flag THEN
        INITIALIZE rh_martal[1].* TO NULL
        RETURN rh_martal[1].t01_linea, rh_martal[1].t01_nombre 
END IF
LET  i = arr_curr()
RETURN rh_martal[i].t01_linea, rh_martal[i].t01_nombre 

END FUNCTION

 

  
FUNCTION fl_ayuda_subtipo_orden(cod_cia, tipo_ot)
DEFINE rh_subord ARRAY[100] OF RECORD
        t05_nombre       	LIKE talt005.t05_nombre,
        t06_subtipo       	LIKE talt006.t06_subtipo,
        t06_nombre       	LIKE talt006.t06_nombre 
        END RECORD
DEFINE rh_tipord ARRAY[100] OF RECORD
        t05_tipord        	LIKE talt005.t05_tipord 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt006.t06_compania
DEFINE tipo_ot		LIKE talt006.t06_tipord
                                                                                
LET filas_max  = 100
OPEN WINDOW w_subord AT 06, 31 WITH 15 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf051 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf051' 
ELSE
	OPEN FORM f_ayuf051 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf051c' 
END IF
DISPLAY FORM f_ayuf051
LET filas_pant = fgl_scr_size('rh_subord')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_subord CURSOR FOR
        SELECT t05_nombre, t06_subtipo, t06_nombre  
		FROM talt005, talt006
	       WHERE t05_compania = t06_compania
	         AND t06_compania = cod_cia
		 AND t06_tipord = tipo_ot
		 AND t05_tipord = t06_tipord
        ORDER BY 1
LET i = 1
FOREACH qh_subord INTO rh_subord[i].*, rh_tipord[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_subord
        INITIALIZE rh_subord[1].*, rh_tipord[1].* TO NULL
        RETURN 	rh_tipord[1].t05_tipord, 
		rh_subord[1].t06_subtipo, rh_subord[1].t06_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subord TO rh_subord.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_subord
IF int_flag THEN
        INITIALIZE rh_subord[1].*, rh_tipord[1].* TO NULL
        RETURN 	rh_tipord[1].t05_tipord, 
		rh_subord[1].t06_subtipo, rh_subord[1].t06_nombre
END IF
LET  i = arr_curr()
RETURN 	rh_tipord[i].t05_tipord, 
	rh_subord[i].t06_subtipo, rh_subord[i].t06_nombre

END FUNCTION



FUNCTION fl_ayuda_tipo_orden_trabajo(cod_cia)
DEFINE rh_torden ARRAY[100] OF RECORD
   	t05_tipord	      	LIKE talt005.t05_tipord,
        t05_nombre	      	LIKE talt005.t05_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia 		LIKE talt005.t05_compania                                                                                
LET filas_max  = 100
OPEN WINDOW wh_torden AT 06, 47 WITH 15 ROWS, 32 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf053 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf053'
ELSE
	OPEN FORM f_ayuf053 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf053c'
END IF
DISPLAY FORM f_ayuf053
LET filas_pant = fgl_scr_size('rh_torden')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_torden CURSOR FOR
        SELECT t05_tipord, t05_nombre FROM talt005
		WHERE t05_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_torden INTO rh_torden[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_torden
        INITIALIZE rh_torden[1].* TO NULL
        RETURN rh_torden[1].t05_tipord, rh_torden[1].t05_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_torden TO rh_torden.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_torden
IF int_flag THEN
        INITIALIZE rh_torden[1].* TO NULL
        RETURN rh_torden[1].t05_tipord, rh_torden[1].t05_nombre 
END IF
LET  i = arr_curr()
RETURN rh_torden[i].t05_tipord, rh_torden[i].t05_nombre 

END FUNCTION

 



FUNCTION fl_ayuda_tipos_veh(cod_cia)
DEFINE rh_tipoveh ARRAY[100] OF RECORD
   	v04_tipo_veh      	LIKE veht004.v04_tipo_veh,
        v04_nombre	      	LIKE veht004.v04_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht004.v04_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_tipoveh AT 06,52
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf054'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_tipoveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_tipoveh CURSOR FOR
        SELECT v04_tipo_veh, v04_nombre FROM veht004
	WHERE v04_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_tipoveh INTO rh_tipoveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tipoveh
        INITIALIZE rh_tipoveh[1].* TO NULL
        RETURN rh_tipoveh[1].v04_tipo_veh, rh_tipoveh[1].v04_nombre 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipoveh TO rh_tipoveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tipoveh
IF int_flag THEN
        INITIALIZE rh_tipoveh[1].* TO NULL
        RETURN rh_tipoveh[1].v04_tipo_veh, rh_tipoveh[1].v04_nombre 
END IF
LET  i = arr_curr()
RETURN rh_tipoveh[i].v04_tipo_veh, rh_tipoveh[i].v04_nombre 

END FUNCTION

 


FUNCTION fl_ayuda_colores(cod_cia)
DEFINE rh_color ARRAY[100] OF RECORD
   	v05_cod_color      	LIKE veht005.v05_cod_color,
        v05_descri_base	      	LIKE veht005.v05_descri_base
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht005.v05_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_color AT 06,43
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf055'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_color')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_color CURSOR FOR
        SELECT v05_cod_color, v05_descri_base FROM veht005
	WHERE v05_compania = cod_cia
        ORDER BY 2
LET i = 1
FOREACH q_color INTO rh_color[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_color
        INITIALIZE rh_color[1].* TO NULL
        RETURN rh_color[1].v05_cod_color, rh_color[1].v05_descri_base 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_color TO rh_color.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_color
IF int_flag THEN
        INITIALIZE rh_color[1].* TO NULL
        RETURN rh_color[1].v05_cod_color, rh_color[1].v05_descri_base 
END IF
LET  i = arr_curr()
RETURN rh_color[i].v05_cod_color, rh_color[i].v05_descri_base 

END FUNCTION

 

FUNCTION fl_ayuda_cliente_general()
DEFINE rh_cligen ARRAY[10000] OF RECORD
	z01_codcli	LIKE cxct001.z01_codcli,
        z01_nomcli	LIKE cxct001.z01_nomcli,
        z01_estado	LIKE cxct001.z01_estado
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cligen AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf052 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf052'
ELSE
	OPEN FORM f_ayuf052 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf052c'
END IF
DISPLAY FORM f_ayuf052
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Cliente'    TO bt_cliente
--#DISPLAY 'E'		TO bt_estado

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z01_codcli, z01_nomcli, z01_estado
	IF int_flag THEN
		CLOSE WINDOW w_cligen
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT z01_codcli, z01_nomcli, z01_estado FROM cxct001 ",
				--" WHERE z01_estado =  'A'", " AND ", 
				" WHERE ", expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cligen FROM query
	DECLARE q_cligen CURSOR FOR cligen
	LET i = 1
	FOREACH q_cligen INTO rh_cligen[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		LET i = 0
		LET salir = 0
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cligen TO rh_cligen.*
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_cligen[i].*
                        END FOR
                        EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                --#AFTER DISPLAY
                	--#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_cligen
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_cligen[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cligen[1].* TO NULL
	RETURN rh_cligen[1].z01_codcli, rh_cligen[1].z01_nomcli
END IF
LET i = arr_curr()
RETURN rh_cligen[i].z01_codcli, rh_cligen[i].z01_nomcli

END FUNCTION



FUNCTION fl_ayuda_orden_trabajo(cod_cia, cod_loc, estado)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE estado		LIKE talt023.t23_estado
DEFINE rh_ordtal	ARRAY[10000] OF RECORD
				t23_orden	LIKE talt023.t23_orden,
				t23_cod_cliente	LIKE talt023.t23_cod_cliente,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente,
				t23_val_mo_tal	LIKE talt023.t23_val_mo_tal,
				tot_oc		DECIMAL(14,2),
				tot_fa		DECIMAL(14,2),
				tot_ot		DECIMAL(14,2),
				t23_estado	LIKE talt023.t23_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(400)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(6000)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE expr_estado	CHAR(45)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE ini_fil, num_fil	SMALLINT
DEFINE ini_col, num_col	SMALLINT
DEFINE tot_neto		DECIMAL(14,2)
DEFINE total_oc		DECIMAL(14,2)
DEFINE total_fa		DECIMAL(14,2)
DEFINE total_ot		DECIMAL(14,2)

LET filas_max  = 10000
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
LET ini_fil = 06
LET ini_col = 02
LET num_fil = 17
LET num_col = 79
IF vg_gui = 0 THEN
	LET ini_fil = 05
	LET ini_col = 02
	LET num_fil = 18
	LET num_col = 77
END IF
OPEN WINDOW w_ordtal AT ini_fil, ini_col WITH num_fil ROWS, num_col COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf056 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf056'
ELSE
	OPEN FORM f_ayuf056 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf056c'
END IF
DISPLAY FORM f_ayuf056
LET filas_pant = fgl_scr_size('rh_ordtal')
--#DISPLAY "Ord T."		TO tit_col1
--#DISPLAY "Cod C."		TO tit_col2
--#DISPLAY "Cliente"		TO tit_col3
--#DISPLAY "Total MO"		TO tit_col4
--#DISPLAY "Total OC"		TO tit_col5
--#DISPLAY "Tot. FA/PR"		TO tit_col6
--#DISPLAY "Total OT"		TO tit_col7
--#DISPLAY "E"			TO tit_col8
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_orden, t23_cod_cliente,
			t23_nom_cliente, t23_val_mo_tal
	IF int_flag THEN
		CLOSE WINDOW w_ordtal
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " t23_estado  = '", estado, "'"  
	END IF
	IF estado = 'T' THEN
		LET expr_estado = " t23_estado   IN ('A','C','F','E','D')"
	END IF
	LET vm_columna_1           = 1
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT t23_orden, t23_cod_cliente, ",
				" t23_nom_cliente, t23_val_mo_tal, ",
				"(SELECT NVL(SUM((c11_precio - c11_val_descto)",
				" * (1 + c10_recargo / 100)), 0) ",
				" FROM ordt010, ordt011 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c11_compania    = c10_compania ",
				"   AND c11_localidad   = c10_localidad ",
				"   AND c11_numero_oc   = c10_numero_oc ",
				"   AND c11_tipo        = 'S') + ",
				"(SELECT NVL(SUM(((c11_cant_ped * c11_precio)",
				" - c11_val_descto) * (1 + c10_recargo / 100))",
				", 0) ",
				" FROM ordt010, ordt011 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c11_compania    = c10_compania ",
				"   AND c11_localidad   = c10_localidad ",
				"   AND c11_numero_oc   = c10_numero_oc ",
				"   AND c11_tipo        = 'B') + ",
				"t23_val_rp_tal + t23_val_rp_ext + ",
				"t23_val_rp_cti + t23_val_otros2, ",
			" CASE WHEN t23_estado = 'A' OR t23_estado = 'C' THEN ",
				" (SELECT NVL(SUM(r21_tot_bruto - ",
						"r21_tot_dscto), 0) ",
				" FROM rept021 ",
				" WHERE r21_compania  = t23_compania ",
				"   AND r21_localidad = t23_localidad ",
				"   AND r21_num_ot    = t23_orden) ",
			"      WHEN t23_estado = 'F' OR t23_estado = 'D' THEN ",
				" (SELECT NVL(SUM(r19_tot_bruto - ",
						"r19_tot_dscto), 0) ",
				" FROM rept019 ",
				" WHERE r19_compania    = t23_compania ",
				"   AND r19_localidad   = t23_localidad ",
				"   AND r19_cod_tran    = 'FA' ",
				"   AND r19_ord_trabajo = t23_orden) ",
			"      ELSE 0.00 ",
			" END, ",
				" t23_val_mo_tal + ",
				"(SELECT NVL(SUM((c11_precio - c11_val_descto)",
				" * (1 + c10_recargo / 100)), 0) ",
				" FROM ordt010, ordt011 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c11_compania    = c10_compania ",
				"   AND c11_localidad   = c10_localidad ",
				"   AND c11_numero_oc   = c10_numero_oc ",
				"   AND c11_tipo        = 'S') + ",
				"(SELECT NVL(SUM(((c11_cant_ped * c11_precio)",
				" - c11_val_descto) * (1 + c10_recargo / 100))",
				", 0) ",
				" FROM ordt010, ordt011 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c11_compania    = c10_compania ",
				"   AND c11_localidad   = c10_localidad ",
				"   AND c11_numero_oc   = c10_numero_oc ",
				"   AND c11_tipo        = 'B') + ",
				" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
				" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
				       "t23_val_rp_cti + t23_val_otros2) ",
				" ELSE 0.00 ",
				" END + ",
			" CASE WHEN t23_estado = 'A' OR t23_estado = 'C' THEN ",
				" (SELECT NVL(SUM(r21_tot_bruto - ",
						"r21_tot_dscto), 0) ",
				" FROM rept021 ",
				" WHERE r21_compania  = t23_compania ",
				"   AND r21_localidad = t23_localidad ",
				"   AND r21_num_ot    = t23_orden) ",
			"      WHEN t23_estado = 'F' OR t23_estado = 'D' THEN ",
				" (SELECT NVL(SUM(r19_tot_bruto - ",
						"r19_tot_dscto), 0) ",
				" FROM rept019 ",
				" WHERE r19_compania    = t23_compania ",
				"   AND r19_localidad   = t23_localidad ",
				"   AND r19_cod_tran    = 'FA' ",
				"   AND r19_ord_trabajo = t23_orden) ",
			"      ELSE 0.00 ",
			" END, t23_estado ",
				" FROM talt023 ",
				" WHERE t23_compania  = ", cod_cia,
				"   AND t23_localidad = ", cod_loc,
				"   AND ", expr_estado CLIPPED,
				"   AND ", expr_sql CLIPPED,
				" GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 ",
                    		" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE ordtal FROM query
		DECLARE q_ordtal CURSOR FOR ordtal
		LET i        = 1
		LET tot_neto = 0
		LET total_oc = 0
		LET total_fa = 0
		LET total_ot = 0
		FOREACH q_ordtal INTO rh_ordtal[i].*
			LET tot_neto = tot_neto + rh_ordtal[i].t23_val_mo_tal
			LET total_oc = total_oc + rh_ordtal[i].tot_oc
			LET total_fa = total_fa + rh_ordtal[i].tot_fa
			LET total_ot = total_ot + rh_ordtal[i].tot_ot
			LET i        = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		DISPLAY BY NAME tot_neto, total_oc, total_fa, total_ot
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_ordtal TO rh_ordtal.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
                		EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
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
	                ON KEY(F20)
        	                LET col = 6
                	        EXIT DISPLAY
	                ON KEY(F21)
        	                LET col = 7
                	        EXIT DISPLAY
	                ON KEY(F22)
				IF estado = 'T' THEN
	        	                LET col = 8
        	        	        EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
				--#DISPLAY rh_ordtal[j].t23_nom_cliente
					--#TO tit_cliente
	                --#AFTER DISPLAY
        	                --#LET salir = 1
		END DISPLAY
        	IF int_flag = 4 OR int_flag = 1 THEN
                	EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
        	        IF rm_orden[vm_columna_1] = 'ASC' THEN
                	        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
	                INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_ordtal[i].* TO NULL
			CLEAR rh_ordtal[i].*, tot_neto, total_oc, total_fa,
				total_ot, tit_cliente
		END FOR
	END IF
	IF NOT salir THEN
       		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_ordtal
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ordtal[1].* TO NULL
	RETURN rh_ordtal[1].t23_orden, rh_ordtal[1].t23_nom_cliente
END IF
LET i = arr_curr()
RETURN rh_ordtal[i].t23_orden, rh_ordtal[i].t23_nom_cliente

END FUNCTION



FUNCTION fl_ayuda_vendedores_veh(cod_cia)
DEFINE rh_venveh ARRAY[100] OF RECORD
   	v01_vendedor      	LIKE veht001.v01_vendedor,
        v01_nombres      	LIKE veht001.v01_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE cod_cia 		LIKE veht001.v01_compania
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_venveh AT 06,45
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf057'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Nombre'     TO bt_nombre

LET filas_pant = fgl_scr_size('rh_venveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET query = " SELECT v01_vendedor, v01_nombres FROM veht001 ",
			" WHERE v01_compania =  ", cod_cia, 
	  		 " AND v01_estado = 'A' " , 
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE venveh FROM query
DECLARE q_venveh CURSOR FOR venveh
--------------
LET i = 1
FOREACH q_venveh INTO rh_venveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_venveh
        INITIALIZE rh_venveh[1].* TO NULL
        RETURN rh_venveh[1].v01_vendedor, rh_venveh[1].v01_nombres
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_venveh TO rh_venveh.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
        ON KEY(F15)
                LET col = 1
                EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_venveh
IF int_flag THEN
        INITIALIZE rh_venveh[1].* TO NULL
        RETURN rh_venveh[1].v01_vendedor, rh_venveh[1].v01_nombres
END IF
LET  i = arr_curr()
RETURN rh_venveh[i].v01_vendedor, rh_venveh[i].v01_nombres

END FUNCTION



FUNCTION fl_ayuda_lineas_veh(cod_cia)
DEFINE rh_linveh ARRAY[100] OF RECORD
   	v03_linea	      	LIKE veht003.v03_linea,
        v03_nombre      	LIKE veht003.v03_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE rept003.r03_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_linveh AT 06,42
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf058'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_linveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_linveh CURSOR FOR
        SELECT v03_linea, v03_nombre FROM veht003
	 WHERE v03_compania = cod_cia
	   AND v03_estado = 'A'
         ORDER BY 1
LET i = 1
FOREACH q_linveh INTO rh_linveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_linveh
        INITIALIZE rh_linveh[1].* TO NULL
        RETURN rh_linveh[1].v03_linea, rh_linveh[1].v03_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_linveh TO rh_linveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_linveh
IF int_flag THEN
        INITIALIZE rh_linveh[1].* TO NULL
        RETURN rh_linveh[1].v03_linea, rh_linveh[1].v03_nombre
END IF
LET  i = arr_curr()
RETURN rh_linveh[i].v03_linea, rh_linveh[i].v03_nombre

END FUNCTION



FUNCTION fl_ayuda_tempario(cod_cia, estado)
DEFINE cod_cia		LIKE talt007.t07_compania
DEFINE estado		LIKE talt007.t07_estado
DEFINE rh_tarea		ARRAY[1000] OF RECORD
				t07_codtarea	LIKE talt007.t07_codtarea,
				t07_nombre 	LIKE talt007.t07_nombre,
				t07_dscmax_ger 	LIKE talt007.t07_dscmax_ger,
				t07_dscmax_jef 	LIKE talt007.t07_dscmax_jef,
				t07_dscmax_ven 	LIKE talt007.t07_dscmax_ven,
				t07_modif_desc 	LIKE talt007.t07_modif_desc,
				t07_tipo 	LIKE talt007.t07_tipo,
				t07_estado 	LIKE talt007.t07_estado
			END RECORD
DEFINE i, j, filas_max	SMALLINT        ## No. elementos del arreglo
DEFINE expr_sql		CHAR(400)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1500)	## Contiene todo el query preparado
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE expr_estado	VARCHAR(100)
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_max = 1000
OPEN WINDOW w_tarea AT 06, 10 WITH 16 ROWS, 69 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf059 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf059'  
ELSE
	OPEN FORM f_ayuf059 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf059c' 
END IF
DISPLAY FORM f_ayuf059
LET filas_pant = fgl_scr_size('rh_tarea')
IF vg_gui = 1 THEN
	DISPLAY "Tarea"		 TO tit_col1
	DISPLAY "Descripcion"	 TO tit_col2
	DISPLAY "% D.G"		 TO tit_col3
	DISPLAY "% D.J"		 TO tit_col4
	DISPLAY "% D.V"		 TO tit_col5
	DISPLAY "M"              TO tit_col6
	DISPLAY "T"              TO tit_col7
	DISPLAY "E"              TO tit_col8
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		DISPLAY estado TO t07_estado
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON t07_codtarea, t07_nombre,
				t07_dscmax_ger, t07_dscmax_jef, t07_dscmax_ven,
				t07_modif_desc, t07_tipo
		IF int_flag THEN
			CLOSE WINDOW w_tarea
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_estado = NULL
	IF estado <> 'T' THEN
		LET expr_estado = '   AND t07_estado   = "', estado, '"'
	END IF
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT t07_codtarea, t07_nombre, t07_dscmax_ger, ",
					"t07_dscmax_jef, t07_dscmax_ven, ",
					"t07_modif_desc, t07_tipo, t07_estado ",
				" FROM talt007 ",
				" WHERE t07_compania = ", cod_cia, 
				expr_estado CLIPPED,
		  		"   AND ", expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
						rm_orden[vm_columna_1], ', ',
						vm_columna_2, ' ',
						rm_orden[vm_columna_2]
		PREPARE tarea FROM query
		DECLARE q_tarea CURSOR FOR tarea
		LET i = 1
		FOREACH q_tarea INTO rh_tarea[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
        		CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		MESSAGE "                                           "
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_tarea TO rh_tarea.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
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
			ON KEY(F20)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F21)
				LET col = 7
				EXIT DISPLAY
			ON KEY(F22)
				LET col = 8
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
				--#DISPLAY rh_tarea[j].t07_nombre TO descripcion
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_tarea[i].* TO NULL
			CLEAR rh_tarea[i].*
		END FOR
		CLEAR descripcion, num_rows, max_rows
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_tarea
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tarea[1].* TO NULL
	RETURN rh_tarea[1].t07_codtarea, rh_tarea[1].t07_nombre
END IF
LET i = arr_curr()
RETURN rh_tarea[i].t07_codtarea, rh_tarea[i].t07_nombre

END FUNCTION



FUNCTION fl_ayuda_tipos_ordenes_compras(estado)
DEFINE estado		LIKE ordt001.c01_estado
DEFINE rh_oc		ARRAY[500] OF RECORD
				c01_tipo_orden	LIKE ordt001.c01_tipo_orden,
				c01_nombre	LIKE ordt001.c01_nombre,
				c01_estado	LIKE ordt001.c01_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_s23		RECORD LIKE srit023.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_hoc AT 06, 29 WITH num_fil ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf060 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf060'
ELSE
	OPEN FORM f_ayuf060 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf060c'
END IF
DISPLAY FORM f_ayuf060
--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY "E"			TO tit_col3
LET expr_est = ' WHERE 1 = 1 '
IF estado <> 'T' THEN
	LET expr_est = ' WHERE c01_estado = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON c01_tipo_orden, c01_nombre
		IF int_flag THEN
			CLOSE WINDOW wh_hoc
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 2
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM ordt001 ',
			expr_est CLIPPED, ' AND ',
			expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE hoc FROM query
		DECLARE q_hoc CURSOR FOR hoc
		LET i = 1
		FOREACH q_hoc INTO r_c01.*
			INITIALIZE r_s23.* TO NULL
			DECLARE q_s23 CURSOR FOR
				SELECT * FROM srit023
				WHERE s23_compania   = vg_codcia
				  AND s23_tipo_orden = r_c01.c01_tipo_orden
				  AND s23_tributa    = 'S'
			OPEN q_s23
			FETCH q_s23 INTO r_s23.*
			CLOSE q_s23
			FREE q_s23
			IF r_s23.s23_compania IS NULL THEN
				CONTINUE FOREACH
			END IF
			LET rh_oc[i].c01_tipo_orden = r_c01.c01_tipo_orden
			LET rh_oc[i].c01_nombre     = r_c01.c01_nombre
			LET rh_oc[i].c01_estado     = r_c01.c01_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE '                                           '
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_oc TO rh_oc.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_oc[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 3
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_hoc
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_oc[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_oc[1].* TO NULL
        RETURN rh_oc[1].c01_tipo_orden, rh_oc[1].c01_nombre
END IF
LET i = arr_curr()
RETURN rh_oc[i].c01_tipo_orden, rh_oc[i].c01_nombre

END FUNCTION



FUNCTION fl_ayuda_cliente_orden_trabajo(cod_cia, cod_loc)
DEFINE rh_cliord ARRAY[1000] OF RECORD
	t23_cod_cliente	LIKE talt023.t23_cod_cliente,
	t23_nom_cliente LIKE talt023.t23_nom_cliente 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cliord AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf061 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf061'
ELSE
	OPEN FORM f_ayuf061 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf061c'
END IF
DISPLAY FORM f_ayuf061
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_cod_cliente, t23_nom_cliente
	IF int_flag THEN
		CLOSE WINDOW w_cliord
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT unique(t23_cod_cliente), t23_nom_cliente FROM talt023 ",
				"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				expr_sql CLIPPED,
				' ORDER BY 2'
	PREPARE cliord FROM query
	DECLARE q_cliord CURSOR FOR cliord
	LET i = 1
	FOREACH q_cliord INTO rh_cliord[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliord TO rh_cliord.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_cliord
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_cliord[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cliord[1].* TO NULL
	RETURN rh_cliord[1].*
END IF
LET i = arr_curr()
RETURN rh_cliord[i].*

END FUNCTION



FUNCTION fl_ayuda_planes_finan_veh(cod_cia)
DEFINE rh_plafin ARRAY[100] OF RECORD
   	v06_codigo_plan      	LIKE veht006.v06_codigo_plan,
        v06_nonbre_plan      	LIKE veht006.v06_nonbre_plan
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht006.v06_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_plafin AT 06,43
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf062'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_plafin')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_plafin CURSOR FOR
        SELECT v06_codigo_plan, v06_nonbre_plan FROM veht006
	WHERE v06_compania = cod_cia
	AND v06_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_plafin INTO rh_plafin[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_plafin
        INITIALIZE rh_plafin[1].* TO NULL
        RETURN rh_plafin[1].v06_codigo_plan, rh_plafin[1].v06_nonbre_plan
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_plafin TO rh_plafin.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_plafin
IF int_flag THEN
        INITIALIZE rh_plafin[1].* TO NULL
        RETURN rh_plafin[1].v06_codigo_plan, rh_plafin[1].v06_nonbre_plan
END IF
LET  i = arr_curr()
RETURN rh_plafin[i].v06_codigo_plan, rh_plafin[i].v06_nonbre_plan

END FUNCTION


 
FUNCTION fl_ayuda_cliente_estadistico_tal(cod_cia, cod_loc)
DEFINE rh_cliest ARRAY[100] OF RECORD
   	t23_codcli_est      	LIKE talt023.t23_codcli_est,
	z01_nomcli		LIKE cxct001.z01_nomcli 
        END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cliest AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf064 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf064'
ELSE
	OPEN FORM f_ayuf064 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf064c'
END IF
DISPLAY FORM f_ayuf064
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_codcli_est, z01_nomcli
	IF int_flag THEN
		CLOSE WINDOW w_cliest
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT unique(t23_codcli_est), z01_nomcli ",
			" FROM talt023, cxct001 ",
				"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				"t23_codcli_est = z01_codcli ", " AND ",
				expr_sql CLIPPED,
				' ORDER BY 2'
	PREPARE cliest FROM query
	DECLARE q_cliest CURSOR FOR cliest
	LET i = 1
	FOREACH q_cliest INTO rh_cliest[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliest TO rh_cliest.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_cliest
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_cliest[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cliest[1].* TO NULL
	RETURN rh_cliest[1].*
END IF
LET i = arr_curr()
RETURN rh_cliest[i].*

END FUNCTION



FUNCTION fl_ayuda_modelos_veh(cod_cia)
DEFINE rh_modveh ARRAY[300] OF RECORD
   	v20_modelo      	LIKE veht020.v20_modelo,
        v20_linea	      	LIKE veht020.v20_linea
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht020.v20_compania
                                                                                
LET filas_max  = 300
OPEN WINDOW wh_modveh AT 06,53
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf065'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_modveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_modveh CURSOR FOR
        SELECT v20_modelo, v20_linea FROM veht020
	WHERE v20_compania = cod_cia
        ORDER BY 2,1
LET i = 1
FOREACH q_modveh INTO rh_modveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_modveh
        INITIALIZE rh_modveh[1].* TO NULL
        RETURN rh_modveh[1].v20_modelo, rh_modveh[1].v20_linea
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_modveh TO rh_modveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_modveh
IF int_flag THEN
        INITIALIZE rh_modveh[1].* TO NULL
        RETURN rh_modveh[1].v20_modelo, rh_modveh[1].v20_linea
END IF
LET  i = arr_curr()
RETURN rh_modveh[i].v20_modelo, rh_modveh[i].v20_linea

END FUNCTION

 
 
FUNCTION fl_ayuda_proveedores()
DEFINE rh_provee	ARRAY[10000] OF RECORD
				p01_codprov    	LIKE cxpt001.p01_codprov,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				p01_estado	LIKE cxpt001.p01_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_provee AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf066 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf066'
ELSE
	OPEN FORM f_ayuf066 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf066c'
END IF
DISPLAY FORM f_ayuf066
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Proveedor'  TO bt_proveedor
--#DISPLAY 'E'		TO bt_estado
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p01_codprov, p01_nomprov, p01_estado
	IF int_flag THEN
		CLOSE WINDOW w_provee
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT p01_codprov, p01_nomprov, p01_estado ",
				" FROM cxpt001 ",
				--"WHERE p01_estado =  'A'", " AND ",
				" WHERE ", expr_sql CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE provee FROM query
		DECLARE q_provee CURSOR FOR provee
		LET i = 1
		FOREACH q_provee INTO rh_provee[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_provee TO rh_provee.*
			ON KEY(RETURN)
				LET salir = 1
                		EXIT DISPLAY
			ON KEY(F2)
        	                LET int_flag = 4
                	        FOR i = 1 TO filas_pant
	                                CLEAR rh_provee[i].*
	                        END FOR
	                        EXIT DISPLAY
	                ON KEY(F15)
	                        LET col = 1
	                        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
        	        	--#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
        	        EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
                	END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
        	                LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
        	        INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_provee
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_provee[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_provee[1].* TO NULL
	RETURN rh_provee[1].p01_codprov, rh_provee[1].p01_nomprov
END IF
LET i = arr_curr()
RETURN rh_provee[i].p01_codprov, rh_provee[i].p01_nomprov

END FUNCTION
 

FUNCTION fl_ayuda_dcto_lineas_rep(cod_cia)
DEFINE rh_dctorep ARRAY[100] OF RECORD
   	r07_serial      	LIKE rept007.r07_serial,
        r07_linea	      	LIKE rept007.r07_linea,
	r03_nombre		LIKE rept003.r03_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept007.r07_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_dctorep AT 06, 32 WITH 15 ROWS, 47 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf067 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf067'
ELSE
	OPEN FORM f_ayuf067 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf067c'
END IF
DISPLAY FORM f_ayuf067
LET filas_pant = fgl_scr_size('rh_dctorep')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_dctorep CURSOR FOR
        SELECT r07_serial, r07_linea, r03_nombre FROM rept007, rept003
	WHERE r07_compania = cod_cia
	  AND r07_compania = r03_compania
	  AND r07_linea	   = r03_codigo
	  AND r03_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_dctorep INTO rh_dctorep[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_dctorep
        INITIALIZE rh_dctorep[1].* TO NULL
        RETURN 	rh_dctorep[1].r07_serial, rh_dctorep[1].r07_linea,
        	rh_dctorep[1].r03_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_dctorep TO rh_dctorep.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_dctorep
IF int_flag THEN
        INITIALIZE rh_dctorep[1].* TO NULL
        RETURN 	rh_dctorep[1].r07_serial, rh_dctorep[1].r07_linea,
        	rh_dctorep[1].r03_nombre
END IF
LET  i = arr_curr()
RETURN rh_dctorep[i].r07_serial, rh_dctorep[i].r07_linea,
       rh_dctorep[i].r03_nombre

END FUNCTION

 
 
FUNCTION fl_ayuda_dcto_indice(cod_cia)
DEFINE rh_dctoind ARRAY[100] OF RECORD
   	r08_serial      	LIKE rept008.r08_serial,
        r08_rotacion	      	LIKE rept008.r08_rotacion,
	r04_nombre		LIKE rept004.r04_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept008.r08_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_dctoind AT 06, 42 WITH 15 ROWS, 37 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf068 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf068'
ELSE
	OPEN FORM f_ayuf068 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf068c'
END IF
DISPLAY FORM f_ayuf068
LET filas_pant = fgl_scr_size('rh_dctoind')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_dctoind CURSOR FOR
        SELECT r08_serial, r08_rotacion, r04_nombre FROM rept008, rept004
	WHERE r08_compania = cod_cia
	  AND r08_compania = r04_compania
	  AND r08_rotacion = r04_rotacion 
        ORDER BY 1
LET i = 1
FOREACH q_dctoind INTO rh_dctoind[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_dctoind
        INITIALIZE rh_dctoind[1].* TO NULL
        RETURN 	rh_dctoind[1].r08_serial, rh_dctoind[1].r08_rotacion,
        	rh_dctoind[1].r04_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_dctoind TO rh_dctoind.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_dctoind
IF int_flag THEN
        INITIALIZE rh_dctoind[1].* TO NULL
        RETURN 	rh_dctoind[1].r08_serial, rh_dctoind[1].r08_rotacion,
        	rh_dctoind[1].r04_nombre
END IF
LET  i = arr_curr()
RETURN 	rh_dctoind[i].r08_serial, rh_dctoind[i].r08_rotacion,
 	rh_dctoind[i].r04_nombre

END FUNCTION

 

FUNCTION fl_ayuda_chasis_cliente(cod_cia, estado)

DEFINE rh_chasis ARRAY[1000] OF RECORD
        t10_modelo      LIKE talt010.t10_modelo,
        t10_chasis      LIKE talt010.t10_chasis,
        t10_placa       LIKE talt010.t10_placa, 
        t10_color       LIKE talt010.t10_color 
        END RECORD
DEFINE rh_chacli ARRAY[1000] OF RECORD
	t10_codcli	LIKE talt010.t10_codcli,
	t23_nom_cliente LIKE talt023.t23_nom_cliente 
        END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE expr_estado	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(600)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt010.t10_compania
DEFINE estado		LIKE talt010.t10_estado

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_chasis AT 06, 10 WITH 15 ROWS, 69 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf069 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf069'
ELSE
	OPEN FORM f_ayuf069 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf069c'
END IF
DISPLAY FORM f_ayuf069
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z01_nomcli, t10_modelo, t10_chasis, t10_placa, t10_color
	IF int_flag THEN
		CLOSE WINDOW w_chasis
		EXIT WHILE
	END IF
----------
	MESSAGE "Seleccionando datos .."
	LET expr_estado = " 1 = 1 "
	IF estado = "T"  THEN
		LET expr_estado = " t10_estado IN ('A','B')"  
	END IF
	IF estado = "A"  THEN
		LET expr_estado = " t10_estado = 'A'"  
	END IF
	IF estado = "B"  THEN
		LET expr_estado = " t10_estado = 'B'"  
	END IF
----------
	LET query = "SELECT t10_modelo, t10_chasis, t10_placa, t10_color, t10_codcli, z01_nomcli FROM talt010, cxct001 ",
			"WHERE t10_compania =  ", cod_cia, " AND ",
			"t10_codcli = z01_codcli ", " AND ",
			expr_estado, " AND ",
			expr_sql CLIPPED 
	PREPARE chasis FROM query
	DECLARE q_chasis CURSOR FOR chasis
	LET i = 1
	FOREACH q_chasis INTO rh_chasis[i].*, rh_chacli[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_chasis TO rh_chasis.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i, '       ', rh_chacli[j].t23_nom_cliente
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_chasis
		EXIT WHILE
	END IF
	CLEAR z01_nomcli
	FOR i = 1 TO filas_pant
		CLEAR rh_chasis[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_chasis[1].*, rh_chacli[1].* TO NULL
	RETURN rh_chasis[1].*, rh_chacli[1].*
END IF
LET  i = arr_curr()
RETURN rh_chasis[i].*, rh_chacli[i].*

END FUNCTION
    



FUNCTION fl_ayuda_placa_cliente(cod_cia, cod_loc)

DEFINE rh_placa ARRAY[1000] OF RECORD
	t23_placa	LIKE talt023.t23_placa,
	t23_nom_cliente LIKE talt023.t23_nom_cliente 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_placa AT 06,28 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf070'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_placa, t23_nom_cliente
	IF int_flag THEN
		CLOSE WINDOW w_placa
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT unique(t23_placa), t23_nom_cliente FROM talt023 ",
				"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				expr_sql CLIPPED,
				' ORDER BY 2'
	PREPARE placa FROM query
	DECLARE q_placa CURSOR FOR placa
	LET i = 1
	FOREACH q_placa INTO rh_placa[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_placa TO rh_placa.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_placa
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_placa[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_placa[1].* TO NULL
	RETURN rh_placa[1].*
END IF
LET  i = arr_curr()
RETURN rh_placa[i].*

END FUNCTION
 



FUNCTION fl_ayuda_codigo_vehcli(cod_cia, cod_loc)

DEFINE rh_codveh ARRAY[1000] OF RECORD
	t23_modelo	LIKE talt023.t23_modelo,
	t23_nom_cliente LIKE talt023.t23_nom_cliente 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codveh AT 06,13 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf071'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_modelo, t23_nom_cliente
	IF int_flag THEN
		CLOSE WINDOW w_codveh
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT unique(t23_modelo), t23_nom_cliente FROM talt023 ",
				"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				expr_sql CLIPPED,
				' ORDER BY 2'
	PREPARE codveh FROM query
	DECLARE q_codveh CURSOR FOR codveh
	LET i = 1
	FOREACH q_codveh INTO rh_codveh[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_codveh TO rh_codveh.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_codveh
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_codveh[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codveh[1].* TO NULL
	RETURN rh_codveh[1].*
END IF
LET  i = arr_curr()
RETURN rh_codveh[i].*

END FUNCTION
 



FUNCTION fl_ayuda_nivel_cuentas()
DEFINE rh_nivcta ARRAY[100] OF RECORD
   	b01_nivel	      	LIKE ctbt001.b01_nivel,
        b01_nombre	      	LIKE ctbt001.b01_nombre,
	b01_posicion_i		LIKE ctbt001.b01_posicion_i,
	b01_posicion_f		LIKE ctbt001.b01_posicion_f
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_nivcta AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf072 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf072'
ELSE
	OPEN FORM f_ayuf072 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf072c'
END IF
DISPLAY FORM f_ayuf072
LET filas_pant = fgl_scr_size('rh_nivcta')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_nivcta CURSOR FOR
        SELECT b01_nivel, b01_nombre, b01_posicion_i, b01_posicion_f
		 FROM ctbt001
        ORDER BY 1
LET i = 1
FOREACH q_nivcta INTO rh_nivcta[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_nivcta
        INITIALIZE rh_nivcta[1].* TO NULL
        RETURN 	rh_nivcta[1].b01_nivel, rh_nivcta[1].b01_nombre,
         	rh_nivcta[1].b01_posicion_i, rh_nivcta[1].b01_posicion_f 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_nivcta TO rh_nivcta.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_nivcta
IF int_flag THEN
        INITIALIZE rh_nivcta[1].* TO NULL
        RETURN 	rh_nivcta[1].b01_nivel, rh_nivcta[1].b01_nombre,
         	rh_nivcta[1].b01_posicion_i, rh_nivcta[1].b01_posicion_f 
END IF
LET  i = arr_curr()
RETURN 	rh_nivcta[i].b01_nivel, rh_nivcta[i].b01_nombre,
      	rh_nivcta[i].b01_posicion_i, rh_nivcta[i].b01_posicion_f 

END FUNCTION

 

FUNCTION fl_ayuda_facturas_tal(cod_cia, cod_loc, estado)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE estado  		LIKE talt023.t23_estado
DEFINE rh_factal	ARRAY[4000] OF RECORD
				t23_num_factura	LIKE talt023.t23_num_factura,
				t23_orden	LIKE talt023.t23_orden,
				t23_numpre	LIKE talt023.t23_numpre,
				t23_nom_cliente LIKE talt023.t23_nom_cliente 
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(800)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE ini_col, num_col	SMALLINT
DEFINE num_fil		SMALLINT

LET filas_max = 4000
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
LET ini_col = 16
LET num_fil = 15
LET num_col = 64
IF vg_gui = 0 THEN
	LET ini_col = 14
	LET num_fil = 16
	LET num_col = 65
END IF
OPEN WINDOW w_factal AT 06, ini_col WITH num_fil ROWS, num_col COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf073 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf073'
ELSE
	OPEN FORM f_ayuf073 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf073c'
END IF
DISPLAY FORM f_ayuf073
LET filas_pant = fgl_scr_size('rh_factal')
--#DISPLAY "Factura"	TO tit_col1
--#DISPLAY "O.T."	TO tit_col2
--#DISPLAY "Presup."	TO tit_col3
--#DISPLAY "Cliente"	TO tit_col4
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_num_factura, t23_orden, t23_numpre,
					t23_nom_cliente
	IF int_flag THEN
		CLOSE WINDOW w_factal
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	IF estado = 'T' THEN
		LET expr_estado = " 1 = 1 "
	END IF
	IF estado <> 'T' THEN
		LET expr_estado = " t23_estado = '", estado, "'"
	END IF
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'DESC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
	LET query = "SELECT t23_num_factura, t23_orden, t23_numpre, ",
			"t23_nom_cliente ",
			"FROM talt023 ",
			"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				"t23_num_factura IS NOT NULL", " AND ",
				expr_estado, " AND ",
				expr_sql CLIPPED,
                    	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE factal FROM query
	DECLARE q_factal CURSOR FOR factal
	LET i = 1
	FOREACH q_factal INTO rh_factal[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		LET salir = 0
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_factal TO rh_factal.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
               		LET salir    = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET salir = 1
               		EXIT DISPLAY
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		--#AFTER DISPLAY
        	        --#LET salir = 1
	END DISPLAY
        	IF int_flag = 4 OR int_flag = 1 THEN
                	EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
        	        IF rm_orden[vm_columna_1] = 'ASC' THEN
                	        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
	                INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_factal[i].* TO NULL
			CLEAR rh_factal[i].*
		END FOR
	END IF
	IF NOT salir THEN
       		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_factal
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_factal[1].* TO NULL
	RETURN rh_factal[1].t23_num_factura, rh_factal[1].t23_nom_cliente
END IF
LET i = arr_curr()
RETURN rh_factal[i].t23_num_factura, rh_factal[i].t23_nom_cliente

END FUNCTION
 


FUNCTION fl_ayuda_orden_chequeo(cod_cia, cod_loc, estado)

DEFINE rh_ordche ARRAY[1000] OF RECORD
	v38_orden_cheq	LIKE veht038.v38_orden_cheq,
	v38_estado 	LIKE veht038.v38_estado 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_estado 	CHAR(35)	
DEFINE cod_cia		LIKE veht038.v38_compania
DEFINE cod_loc		LIKE veht038.v38_localidad
DEFINE estado		LIKE veht038.v38_estado
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_ordche AT 06,60 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf074'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'O. Chequeo'     TO bt_orden
DISPLAY 'E'              TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON v38_orden_cheq, v38_estado
	IF int_flag THEN
		CLOSE WINDOW w_ordche
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
----------
	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " v38_estado  = '", estado, "'"  
	END IF
	IF estado = 'T' THEN
		LET expr_estado = " v38_estado   IN ('A','P','B')"
	END IF
----------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT v38_orden_cheq, v38_estado FROM veht038 ",
				"WHERE v38_compania =  ", cod_cia, " AND ",
				"v38_localidad = ", cod_loc, " AND ",
				expr_estado, " AND ",
				expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE ordche FROM query
	DECLARE q_ordche CURSOR FOR ordche
	LET i = 1
	FOREACH q_ordche INTO rh_ordche[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_ordche TO rh_ordche.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_ordche
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_ordche[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ordche[1].* TO NULL
	RETURN rh_ordche[1].*
END IF
LET  i = arr_curr()
RETURN rh_ordche[i].*

END FUNCTION
 

 
FUNCTION fl_ayuda_grupo_cuentas(cod_cia)
DEFINE rh_gructa ARRAY[100] OF RECORD
   	b02_grupo_cta	      	LIKE ctbt002.b02_grupo_cta,
        b02_nombre	      	LIKE ctbt002.b02_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE ctbt002.b02_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_gructa AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf075 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf075'
ELSE
	OPEN FORM f_ayuf075 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf075c'
END IF
DISPLAY FORM f_ayuf075
LET filas_pant = fgl_scr_size('rh_gructa')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_gructa CURSOR FOR
        SELECT b02_grupo_cta, b02_nombre
		 FROM ctbt002
        ORDER BY 1
LET i = 1
FOREACH q_gructa INTO rh_gructa[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_gructa
        INITIALIZE rh_gructa[1].* TO NULL
        RETURN 	rh_gructa[1].b02_grupo_cta, rh_gructa[1].b02_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_gructa TO rh_gructa.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_gructa
IF int_flag THEN
        INITIALIZE rh_gructa[1].* TO NULL
        RETURN 	rh_gructa[1].b02_grupo_cta, rh_gructa[1].b02_nombre 
END IF
LET  i = arr_curr()
RETURN 	rh_gructa[i].b02_grupo_cta, rh_gructa[i].b02_nombre 

END FUNCTION

 

FUNCTION fl_ayuda_tipos_comprobantes(cod_cia)
DEFINE rh_tipcomp ARRAY[100] OF RECORD
   	b03_tipo_comp	      	LIKE ctbt003.b03_tipo_comp,
        b03_nombre	      	LIKE ctbt003.b03_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE ctbt003.b03_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_tipcomp AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf076 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf076'
ELSE
	OPEN FORM f_ayuf076 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf076c'
END IF
DISPLAY FORM f_ayuf076
LET filas_pant = fgl_scr_size('rh_tipcomp')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_tipcomp CURSOR FOR
        SELECT b03_tipo_comp, b03_nombre
		 FROM ctbt003
        ORDER BY 1
LET i = 1
FOREACH q_tipcomp INTO rh_tipcomp[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tipcomp
        INITIALIZE rh_tipcomp[1].* TO NULL
        RETURN 	rh_tipcomp[1].b03_tipo_comp, rh_tipcomp[1].b03_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipcomp TO rh_tipcomp.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tipcomp
IF int_flag THEN
        INITIALIZE rh_tipcomp[1].* TO NULL
        RETURN 	rh_tipcomp[1].b03_tipo_comp, rh_tipcomp[1].b03_nombre 
END IF
LET  i = arr_curr()
RETURN 	rh_tipcomp[i].b03_tipo_comp, rh_tipcomp[i].b03_nombre 

END FUNCTION

 

FUNCTION fl_ayuda_subtipos_comprobantes(cod_cia)
DEFINE rh_stipcomp ARRAY[100] OF RECORD
   	b04_subtipo	      	LIKE ctbt004.b04_subtipo,
        b04_nombre	      	LIKE ctbt004.b04_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE ctbt004.b04_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_stipcomp AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf077 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf077'
ELSE
	OPEN FORM f_ayuf077 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf077c'
END IF
DISPLAY FORM f_ayuf077
LET filas_pant = fgl_scr_size('rh_stipcomp')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_stipcomp CURSOR FOR
        SELECT b04_subtipo, b04_nombre
		 FROM ctbt004
		 WHERE b04_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_stipcomp INTO rh_stipcomp[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_stipcomp
        INITIALIZE rh_stipcomp[1].* TO NULL
        RETURN 	rh_stipcomp[1].b04_subtipo, rh_stipcomp[1].b04_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_stipcomp TO rh_stipcomp.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_stipcomp
IF int_flag THEN
        INITIALIZE rh_stipcomp[1].* TO NULL
        RETURN 	rh_stipcomp[1].b04_subtipo, rh_stipcomp[1].b04_nombre 
END IF
LET  i = arr_curr()
RETURN 	rh_stipcomp[i].b04_subtipo, rh_stipcomp[i].b04_nombre 

END FUNCTION

 

FUNCTION fl_ayuda_serie_veh(cod_cia, cod_loc, bodega)

DEFINE rh_serveh ARRAY[1000] OF RECORD
	v22_codigo_veh 		LIKE veht022.v22_codigo_veh,
	v22_chasis	 	LIKE veht022.v22_chasis,
	v22_modelo	 	LIKE veht022.v22_modelo,
	v22_cod_color	 	LIKE veht022.v22_cod_color,
	v22_estado	 	LIKE veht022.v22_estado 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(500)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht022.v22_compania
DEFINE cod_loc		LIKE veht022.v22_localidad
DEFINE bodega		LIKE veht022.v22_bodega
DEFINE expr_bodega	CHAR(25)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_serveh AT 06,16 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf078'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 1
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Serie'      TO bt_serie
--#DISPLAY 'Modelo'     TO bt_modelo
--#DISPLAY 'Color'      TO bt_color
--#DISPLAY 'E'          TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	v22_codigo_veh, v22_chasis, 
					v22_modelo, v22_cod_color, v22_estado
	IF int_flag THEN
		CLOSE WINDOW w_serveh
		EXIT WHILE
	END IF
----------
	MESSAGE "Seleccionando datos .."
	LET expr_bodega = " 1 = 1 "
	IF bodega <> "00"  THEN
		LET expr_bodega = " v22_bodega =  '", bodega CLIPPED, "'"  
	END IF
----------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT v22_codigo_veh, v22_chasis, v22_modelo, ",
			" v22_cod_color, v22_estado FROM veht022 ", 
			"WHERE v22_compania  =  ", cod_cia, " AND ",
			"  v22_localidad =  ", cod_loc, " AND ",
			"  v22_estado NOT IN ('F','B') ", " AND ",
			expr_bodega,  " AND ",
			expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE serveh FROM query
	DECLARE q_serveh CURSOR FOR serveh
	LET i = 1
	FOREACH q_serveh INTO rh_serveh[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
--------------
	DISPLAY ARRAY rh_serveh TO rh_serveh.*
		ON KEY(F2)
			LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_serveh[i].*
                        END FOR
			EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
        CLOSE WINDOW w_serveh
        EXIT WHILE
END IF
IF salir THEN
        EXIT WHILE
END IF
FOR i = 1 TO filas_pant
        CLEAR rh_serveh[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_serveh[1].* TO NULL
	RETURN rh_serveh[1].*
END IF
LET  i = arr_curr()
RETURN rh_serveh[i].*

END FUNCTION
 

 
FUNCTION fl_ayuda_tipos_documentos_fuentes()
DEFINE rh_docbco ARRAY[100] OF RECORD
   	b07_tipo_doc	      	LIKE ctbt007.b07_tipo_doc,
        b07_nombre	      	LIKE ctbt007.b07_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_docbco AT 06, 48 WITH 15 ROWS, 31 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf079 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf079'
ELSE
	OPEN FORM f_ayuf079 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf079c'
END IF
DISPLAY FORM f_ayuf079
LET filas_pant = fgl_scr_size('rh_docbco')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_docbco CURSOR FOR
        SELECT b07_tipo_doc, b07_nombre
		 FROM ctbt007
                 WHERE b07_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_docbco INTO rh_docbco[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_docbco
        INITIALIZE rh_docbco[1].* TO NULL
        RETURN 	rh_docbco[1].b07_tipo_doc, rh_docbco[1].b07_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_docbco TO rh_docbco.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_docbco
IF int_flag THEN
        INITIALIZE rh_docbco[1].* TO NULL
        RETURN 	rh_docbco[1].b07_tipo_doc, rh_docbco[1].b07_nombre 
END IF
LET  i = arr_curr()
RETURN 	rh_docbco[i].b07_tipo_doc, rh_docbco[i].b07_nombre 

END FUNCTION

 

FUNCTION fl_ayuda_ventas_perdidas(cod_cia)

DEFINE rh_vtaper ARRAY[1000] OF RECORD
	r13_serial 		LIKE rept013.r13_serial,
	r13_item 		LIKE rept013.r13_item,
	r10_nombre 		LIKE rept010.r10_nombre 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(500)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept013.r13_compania
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_vtaper AT 06, 24 WITH 15 ROWS, 55 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf080 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf080'
ELSE
	OPEN FORM f_ayuf080 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf080c'
END IF
DISPLAY FORM f_ayuf080
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY '#'           TO bt_serial
--#DISPLAY 'Item'        TO bt_item
--#DISPLAY 'Descripción' TO bt_nombre

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	r13_serial, r13_item, r10_nombre  
	IF int_flag THEN
		CLOSE WINDOW w_vtaper
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT r13_serial, r13_item, ",
			" r10_nombre FROM rept013, rept010 ",
			"WHERE r13_compania =  ", cod_cia, 
			"  AND r13_compania = r10_compania ", 
			"  AND r13_item     = r10_codigo ", " AND ",
			expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2],
                           ', ', vm_columna_3, ' ', rm_orden[vm_columna_3]
	PREPARE vtaper FROM query
	DECLARE q_vtaper CURSOR FOR vtaper
	LET i = 1
	FOREACH q_vtaper INTO rh_vtaper[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
-------------
	DISPLAY ARRAY rh_vtaper TO rh_vtaper.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_vtaper[i].*
                        END FOR
                        EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4   OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_vtaper
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_vtaper[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_vtaper[1].* TO NULL
	RETURN rh_vtaper[1].*
END IF
LET  i = arr_curr()
RETURN rh_vtaper[i].*

END FUNCTION
 



FUNCTION fl_ayuda_cambio_precios(cod_cia, estado)
DEFINE rh_campre ARRAY[100] OF RECORD
   	r32_numreg	      	LIKE rept032.r32_numreg,
   	r32_porc_fact	      	LIKE rept032.r32_porc_fact,
   	r32_linea	      	LIKE rept032.r32_linea,
   	r32_usuario	      	LIKE rept032.r32_usuario 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept032.r32_compania
DEFINE estado		LIKE rept032.r32_estado
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_campre AT 06, 39 WITH 15 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf081 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf081'
ELSE
	OPEN FORM f_ayuf081 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf081c'
END IF
DISPLAY FORM f_ayuf081
LET filas_pant = fgl_scr_size('rh_campre')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF estado = 'T' THEN 
DECLARE q_campre1 CURSOR FOR
        SELECT r32_numreg, r32_porc_fact, r32_linea, r32_usuario
		 FROM rept032
                 WHERE r32_compania = cod_cia 
        ORDER BY 1
LET i = 1
FOREACH q_campre1 INTO rh_campre[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF estado = 'A' THEN 
DECLARE q_campre2 CURSOR FOR
        SELECT r32_numreg, r32_porc_fact, r32_linea, r32_usuario
		 FROM rept032
                 WHERE r32_compania = cod_cia 
		   AND r32_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_campre2 INTO rh_campre[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_campre
        INITIALIZE rh_campre[1].* TO NULL
        RETURN 	rh_campre[1].r32_numreg, rh_campre[1].r32_porc_fact,
         	rh_campre[1].r32_linea,  rh_campre[1].r32_usuario 
		
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_campre TO rh_campre.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_campre
IF int_flag THEN
        INITIALIZE rh_campre[1].* TO NULL
        RETURN 	rh_campre[1].r32_numreg, rh_campre[1].r32_porc_fact,
         	rh_campre[1].r32_linea,  rh_campre[1].r32_usuario 
END IF
LET  i = arr_curr()
RETURN 	rh_campre[i].r32_numreg, rh_campre[i].r32_porc_fact,
      	rh_campre[i].r32_linea,  rh_campre[i].r32_usuario 

END FUNCTION

 
 
FUNCTION fl_reservaciones(cod_cia, cod_loc)

DEFINE rh_reser ARRAY[1000] OF RECORD
	v33_num_reserv 		LIKE veht033.v33_num_reserv,
	v33_codigo_veh 		LIKE veht033.v33_codigo_veh,
	v33_vendedor 		LIKE veht001.v01_nombres
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(500)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht033.v33_compania
DEFINE cod_loc		LIKE veht033.v33_localidad
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_reser AT 06,28 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf083'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Reserva'     TO bt_reserva
--#DISPLAY 'Vehículo'    TO bt_codigo
--#DISPLAY 'Vendedor'    TO bt_vendedor

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON v33_num_reserv,v33_codigo_veh,v01_nombres	
	IF int_flag THEN
		CLOSE WINDOW w_reser
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT v33_num_reserv, v33_codigo_veh, v01_nombres ",
			" FROM veht033, veht001 ",
			"WHERE v33_compania =  ", cod_cia, " AND ",
			"  v33_localidad    =  ", cod_loc, " AND ",
			"  v33_compania = v01_compania ", " AND ",
			"  v33_vendedor = v01_vendedor ", " AND ",
			expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE reser FROM query
	DECLARE q_reser CURSOR FOR reser
	LET i = 1
	FOREACH q_reser INTO rh_reser[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_reser TO rh_reser.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 1
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
		--#AFTER DISPLAY
			--#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
        CLOSE WINDOW w_reser 
        EXIT WHILE
END IF
IF salir THEN
        EXIT WHILE
END IF
FOR i = 1 TO filas_pant
        CLEAR rh_reser[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_reser[1].* TO NULL
	RETURN rh_reser[1].*
END IF
LET  i = arr_curr()
RETURN rh_reser[i].*

END FUNCTION



FUNCTION fl_ayuda_codigos_filtros(cod_cia)
DEFINE rh_filtro ARRAY[100] OF RECORD
   	b08_filtro	      	LIKE ctbt008.b08_filtro,
        b08_nombre	      	LIKE ctbt008.b08_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE ctbt008.b08_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_filtro AT 06, 46 WITH 15 ROWS, 33 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf084 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf084'
ELSE
	OPEN FORM f_ayuf084 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf084c'
END IF
DISPLAY FORM f_ayuf084
LET filas_pant = fgl_scr_size('rh_filtro')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_filtro CURSOR FOR
        SELECT b08_filtro, b08_nombre
		 FROM ctbt008
                 WHERE b08_compania = cod_cia
		   AND b08_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_filtro INTO rh_filtro[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_filtro
        INITIALIZE rh_filtro[1].* TO NULL
        RETURN 	rh_filtro[1].b08_filtro, rh_filtro[1].b08_nombre 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_filtro TO rh_filtro.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_filtro
IF int_flag THEN
        INITIALIZE rh_filtro[1].* TO NULL
        RETURN 	rh_filtro[1].b08_filtro, rh_filtro[1].b08_nombre 
END IF
LET  i = arr_curr()
RETURN 	rh_filtro[i].b08_filtro, rh_filtro[i].b08_nombre 

END FUNCTION

 

FUNCTION fl_ayuda_tipo_documento_tesoreria(tipo)
DEFINE rh_tipdocte ARRAY[1000] OF RECORD
   	p04_tipo_doc      	LIKE cxpt004.p04_tipo_doc,
        p04_nombre      	LIKE cxpt004.p04_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE tipo		LIKE cxpt004.p04_tipo
                                                                                
LET filas_max  = 1000
OPEN WINDOW wh_tipdocte AT 06, 53 WITH 15 ROWS, 26 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf085 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf085'
ELSE
	OPEN FORM f_ayuf085 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf085c'
END IF
DISPLAY FORM f_ayuf085
LET filas_pant = fgl_scr_size('rh_tipdocte')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
-------------
IF tipo = 'D' THEN   ## PARA TIPO DEUDORES
DECLARE q_tipdocte1 CURSOR FOR
        SELECT p04_tipo_doc, p04_nombre FROM cxpt004
	WHERE p04_tipo = tipo
	  AND p04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdocte1 INTO rh_tipdocte[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF tipo = 'F' THEN   ## PARA TIPO A FAVOR
DECLARE q_tipdocte2 CURSOR FOR
        SELECT p04_tipo_doc, p04_nombre FROM cxpt004
        WHERE p04_tipo = tipo
	  AND p04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdocte2 INTO rh_tipdocte[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF tipo = 'T' THEN   ## PARA TIPO TRANSACCIONES
DECLARE q_tipdocte3 CURSOR FOR
        SELECT p04_tipo_doc, p04_nombre FROM cxpt004
        WHERE p04_tipo = tipo
	  AND p04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdocte3 INTO rh_tipdocte[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF

IF tipo = '0' THEN   ## PARA TODOS LOS DOCUMENTOS
DECLARE q_tipdocte4 CURSOR FOR
        SELECT p04_tipo_doc, p04_nombre FROM cxpt004
	 WHERE p04_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_tipdocte4 INTO rh_tipdocte[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
-------------
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_tipdocte
        INITIALIZE rh_tipdocte[1].* TO NULL
        RETURN 	rh_tipdocte[1].p04_tipo_doc, rh_tipdocte[1].p04_nombre  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipdocte TO rh_tipdocte.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_tipdocte
IF int_flag THEN
        INITIALIZE rh_tipdocte[1].* TO NULL
        RETURN 	rh_tipdocte[1].p04_tipo_doc, rh_tipdocte[1].p04_nombre  
END IF
LET  i = arr_curr()
RETURN 	rh_tipdocte[i].p04_tipo_doc, rh_tipdocte[i].p04_nombre  

END FUNCTION



FUNCTION fl_ayuda_serie_veh_todos(cod_cia, cod_loc, bodega)

DEFINE rh_serveh_all ARRAY[1000] OF RECORD
	v22_codigo_veh 		LIKE veht022.v22_codigo_veh,
	v22_chasis	 	LIKE veht022.v22_chasis,
	v22_modelo	 	LIKE veht022.v22_modelo,
	v22_cod_color	 	LIKE veht022.v22_cod_color,
	v22_estado	 	LIKE veht022.v22_estado 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(500)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht022.v22_compania
DEFINE cod_loc		LIKE veht022.v22_localidad
DEFINE bodega		LIKE veht022.v22_bodega
DEFINE expr_bodega	CHAR(25)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_serveh_all AT 06,16 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf086'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Serie'      TO bt_serie
--#DISPLAY 'Modelo'     TO bt_modelo
--#DISPLAY 'Color'      TO bt_color
--#DISPLAY 'E'          TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	v22_codigo_veh, v22_chasis, 
					v22_modelo, v22_cod_color, v22_estado
	IF int_flag THEN
		CLOSE WINDOW w_serveh_all
		EXIT WHILE
	END IF
----------
	MESSAGE "Seleccionando datos .."
	LET expr_bodega = " 1 = 1 "
	IF bodega <> "00"  THEN
		LET expr_bodega = " v22_bodega =  '", bodega CLIPPED, "'"  
	END IF
----------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT v22_codigo_veh, v22_chasis, ",
			" v22_modelo, v22_cod_color,",
			" v22_estado FROM veht022 ", 
			"WHERE v22_compania =  ", cod_cia, " AND ",
			"  v22_localidad    =  ", cod_loc, " AND ",
			"  v22_estado NOT IN ('F') ", " AND ",
			expr_bodega,  " AND ",
			expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]

	PREPARE serveh_all FROM query
	DECLARE q_serveh_all CURSOR FOR serveh_all
	LET i = 1
	FOREACH q_serveh_all INTO rh_serveh_all[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
-------------
	DISPLAY ARRAY rh_serveh_all TO rh_serveh_all.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
        CLOSE WINDOW w_serveh_all
        EXIT WHILE
END IF
IF salir THEN
        EXIT WHILE
END IF
FOR i = 1 TO filas_pant
        CLEAR rh_serveh_all[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_serveh_all[1].* TO NULL
	RETURN rh_serveh_all[1].*
END IF
LET  i = arr_curr()
RETURN rh_serveh_all[i].*

END FUNCTION
 


FUNCTION fl_ayuda_doc_favor_cob(cod_cia, cod_loc, cod_area, cod_cli, cod_doc)
DEFINE rh_favorcob	ARRAY[10000] OF RECORD
			        z01_nomcli     	LIKE cxct001.z01_nomcli,
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				z21_saldo	LIKE cxct021.z21_saldo,
				z21_moneda	LIKE cxct021.z21_moneda,
				g03_abreviacion	LIKE gent003.g03_abreviacion
			END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_area 	CHAR(45)	
DEFINE expr_cliente 	CHAR(45)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxct021.z21_compania
DEFINE cod_loc		LIKE cxct021.z21_localidad
DEFINE cod_area		LIKE cxct021.z21_areaneg
DEFINE cod_cli		LIKE cxct021.z21_codcli
DEFINE cod_doc		LIKE cxct021.z21_tipo_doc
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col, salir	SMALLINT
DEFINE tit_total	DECIMAL(12,2)

LET filas_max = 10000
OPEN WINDOW wh_favorcob AT 06, 12 WITH 16 ROWS, 67 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf087 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf087'
ELSE
	OPEN FORM f_ayuf087 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf087c'
END IF
DISPLAY FORM f_ayuf087
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Cliente'     TO bt_cliente
--#DISPLAY 'TP'          TO bt_tipo
--#DISPLAY 'Número'      TO bt_numero
--#DISPLAY 'Saldo'       TO bt_saldo
--#DISPLAY 'Mo'          TO bt_moneda
--#DISPLAY 'Area'        TO bt_area
LET filas_pant = fgl_scr_size('rh_favorcob')
LET int_flag   = 0
MESSAGE 'Seleccionando datos..' 
IF cod_doc IS NULL THEN
	LET expr_tipo = " 1 = 1 "
   ELSE
	LET expr_tipo = " z21_tipo_doc = '", cod_doc, "'"
END IF
IF cod_doc = '00' THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_doc IS NULL  THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_area IS NULL THEN
	LET expr_area = " 1 = 1 "
   ELSE
   	LET expr_area = " z21_areaneg = ", cod_area
END IF
IF cod_cli IS NULL THEN
	LET expr_cliente = " 1 = 1 "
   ELSE
   	LET expr_cliente = " z21_codcli = ", cod_cli
END IF
LET vm_columna_1           = 4
LET vm_columna_2           = 1
LET rm_orden[vm_columna_1] = 'DESC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir 
	LET query = "SELECT z01_nomcli, z21_tipo_doc, z21_num_doc, z21_saldo,", 
			" z21_moneda, g03_abreviacion ",
			" FROM cxct021, cxct001, gent003 ",
       	        	" WHERE z21_compania  = ", cod_cia,
			"   AND g03_compania  = ", cod_cia,
  			"   AND z21_compania  = g03_compania ",
			"   AND z21_localidad = ", cod_loc,
			"   AND z21_areaneg   = g03_areaneg ",
			"   AND z21_codcli    = z01_codcli ",
			"   AND ", expr_cliente, 
			"   AND ", expr_tipo, 
			"   AND ", expr_area, 
			" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE favorcob FROM query
	DECLARE q_favorcob CURSOR FOR favorcob
	LET i         = 1
	LET tit_total = 0
	FOREACH q_favorcob INTO rh_favorcob[i].*
		LET tit_total = tit_total + rh_favorcob[i].z21_saldo
	        LET i         = i + 1
	        IF i > filas_max THEN
	                EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
	        CALL fl_mensaje_consulta_sin_registros()
	        CLOSE WINDOW wh_favorcob
	        INITIALIZE rh_favorcob[1].* TO NULL
	        RETURN rh_favorcob[1].z01_nomcli, rh_favorcob[1].z21_tipo_doc,
			rh_favorcob[1].z21_num_doc, rh_favorcob[1].z21_saldo,
			rh_favorcob[1].z21_moneda,rh_favorcob[1].g03_abreviacion
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	DISPLAY BY NAME tit_total
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY rh_favorcob TO rh_favorcob.*
	        ON KEY(RETURN)
	        	LET salir = 1
	                EXIT DISPLAY
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
	        ON KEY(F20)
	                LET col = 6
	                EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE  j, ' de ', i
		--#AFTER DISPLAY
	        	--#LET salir = 1
	END DISPLAY
	IF int_flag AND col IS NULL THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
CLOSE WINDOW wh_favorcob
IF int_flag THEN
        INITIALIZE rh_favorcob[1].* TO NULL
        RETURN rh_favorcob[1].z01_nomcli, rh_favorcob[1].z21_tipo_doc,
		rh_favorcob[1].z21_num_doc, rh_favorcob[1].z21_saldo,
		rh_favorcob[1].z21_moneda, rh_favorcob[1].g03_abreviacion
END IF
LET i = arr_curr()
RETURN rh_favorcob[i].z01_nomcli, rh_favorcob[i].z21_tipo_doc,
	rh_favorcob[i].z21_num_doc, rh_favorcob[i].z21_saldo,
	rh_favorcob[i].z21_moneda, rh_favorcob[i].g03_abreviacion

END FUNCTION

 

FUNCTION fl_ayuda_distribucion_cuentas(cod_cia)
DEFINE rh_distcta ARRAY[100] OF RECORD
   	b16_cta_master      	LIKE ctbt016.b16_cta_master,
        b10_descripcion		LIKE ctbt010.b10_descripcion		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE ctbt016.b16_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_distcta AT 06, 24 WITH 15 ROWS, 55 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf088 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf088'
ELSE
	OPEN FORM f_ayuf088 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf088c'
END IF
DISPLAY FORM f_ayuf088
LET filas_pant = fgl_scr_size('rh_distcta')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_distcta CURSOR FOR
        SELECT unique(b16_cta_master), b10_descripcion FROM ctbt016, ctbt010
		WHERE b16_compania   = b10_compania
		  AND b16_cta_master = b10_cuenta
		  AND b10_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_distcta INTO rh_distcta[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_distcta
        INITIALIZE rh_distcta[1].* TO NULL
        RETURN 	rh_distcta[1].b16_cta_master, rh_distcta[1].b10_descripcion  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_distcta TO rh_distcta.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_distcta
IF int_flag THEN
        INITIALIZE rh_distcta[1].* TO NULL
        RETURN 	rh_distcta[1].b16_cta_master, rh_distcta[1].b10_descripcion  
END IF
LET  i = arr_curr()
RETURN 	rh_distcta[i].b16_cta_master, rh_distcta[i].b10_descripcion  

END FUNCTION



FUNCTION fl_ayuda_companias_compras()
DEFINE rh_ciacom ARRAY[100] OF RECORD
   	c00_compania      	LIKE ordt000.c00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciacom AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf089 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf089'
ELSE
	OPEN FORM f_ayuf089 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf089c'
END IF
DISPLAY FORM f_ayuf089
LET filas_pant = fgl_scr_size('rh_ciacom')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciacom CURSOR FOR
        SELECT c00_compania, g01_razonsocial FROM ordt000, gent001
		WHERE c00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciacom INTO rh_ciacom[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciacom
        INITIALIZE rh_ciacom[1].* TO NULL
        RETURN 	rh_ciacom[1].c00_compania, rh_ciacom[1].g01_razonsocial  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacom TO rh_ciacom.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciacom
IF int_flag THEN
        INITIALIZE rh_ciacom[1].* TO NULL
        RETURN 	rh_ciacom[1].c00_compania, rh_ciacom[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciacom[i].c00_compania, rh_ciacom[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_companias_contabilidad()
DEFINE rh_ciacon ARRAY[100] OF RECORD
   	b00_compania      	LIKE ctbt000.b00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciacon AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf090 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf090'
ELSE
	OPEN FORM f_ayuf090 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf090c'
END IF
DISPLAY FORM f_ayuf090
LET filas_pant = fgl_scr_size('rh_ciacon')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciacon CURSOR FOR
        SELECT b00_compania, g01_razonsocial FROM ctbt000, gent001
		WHERE b00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciacon INTO rh_ciacon[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciacon
        INITIALIZE rh_ciacon[1].* TO NULL
        RETURN 	rh_ciacon[1].b00_compania, rh_ciacon[1].g01_razonsocial  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacon TO rh_ciacon.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciacon
IF int_flag THEN
        INITIALIZE rh_ciacon[1].* TO NULL
        RETURN 	rh_ciacon[1].b00_compania, rh_ciacon[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciacon[i].b00_compania, rh_ciacon[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_companias_tesoreria()
DEFINE rh_ciates ARRAY[100] OF RECORD
   	p00_compania      	LIKE cxpt000.p00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciates AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf091 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf091'
ELSE
	OPEN FORM f_ayuf091 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf091c'
END IF
DISPLAY FORM f_ayuf091
LET filas_pant = fgl_scr_size('rh_ciates')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciates CURSOR FOR
        SELECT p00_compania, g01_razonsocial FROM cxpt000, gent001
		WHERE p00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciates INTO rh_ciates[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciates
        INITIALIZE rh_ciates[1].* TO NULL
        RETURN 	rh_ciates[1].p00_compania, rh_ciates[1].g01_razonsocial  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciates TO rh_ciates.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciates
IF int_flag THEN
        INITIALIZE rh_ciates[1].* TO NULL
        RETURN 	rh_ciates[1].p00_compania, rh_ciates[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciates[i].p00_compania, rh_ciates[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_companias_roles()
DEFINE rh_ciarol ARRAY[100] OF RECORD
   	n01_compania      	LIKE rolt001.n01_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciarol AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf092'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_ciarol')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciarol CURSOR FOR
        SELECT n01_compania, g01_razonsocial FROM rolt001, gent001
		WHERE n01_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciarol INTO rh_ciarol[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciarol
        INITIALIZE rh_ciarol[1].* TO NULL
        RETURN 	rh_ciarol[1].n01_compania, rh_ciarol[1].g01_razonsocial  
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciarol TO rh_ciarol.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciarol
IF int_flag THEN
        INITIALIZE rh_ciarol[1].* TO NULL
        RETURN 	rh_ciarol[1].n01_compania, rh_ciarol[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciarol[i].n01_compania, rh_ciarol[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_companias_activos()
DEFINE rh_ciaact ARRAY[100] OF RECORD
   	a00_compania      	LIKE actt000.a00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciaact AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf093'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_ciaact')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciaact CURSOR FOR
        SELECT a00_compania, g01_razonsocial FROM actt000, gent001
		WHERE a00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciaact INTO rh_ciaact[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciaact
        INITIALIZE rh_ciaact[1].* TO NULL
        RETURN 	rh_ciaact[1].a00_compania, rh_ciaact[1].g01_razonsocial  
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciaact TO rh_ciaact.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciaact
IF int_flag THEN
        INITIALIZE rh_ciaact[1].* TO NULL
        RETURN 	rh_ciaact[1].a00_compania, rh_ciaact[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciaact[i].a00_compania, rh_ciaact[i].g01_razonsocial  

END FUNCTION




FUNCTION fl_ayuda_companias_cajagen()
DEFINE rh_ciacajg ARRAY[100] OF RECORD
   	j00_compania      	LIKE cajt000.j00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciacajg AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf094 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf094'
ELSE
	OPEN FORM f_ayuf094 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf094c'
END IF
DISPLAY FORM f_ayuf094
LET filas_pant = fgl_scr_size('rh_ciacajg')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciacajg CURSOR FOR
        SELECT j00_compania, g01_razonsocial FROM cajt000, gent001
		WHERE j00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciacajg INTO rh_ciacajg[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciacajg
        INITIALIZE rh_ciacajg[1].* TO NULL
        RETURN 	rh_ciacajg[1].j00_compania, rh_ciacajg[1].g01_razonsocial  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacajg TO rh_ciacajg.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciacajg
IF int_flag THEN
        INITIALIZE rh_ciacajg[1].* TO NULL
        RETURN 	rh_ciacajg[1].j00_compania, rh_ciacajg[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciacajg[i].j00_compania, rh_ciacajg[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_forma_pago(cod_cia, cont_cred, estado, reten)
DEFINE cod_cia		LIKE cajt001.j01_compania
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE estado		LIKE cajt001.j01_estado
DEFINE reten		LIKE cajt001.j01_retencion
DEFINE rh_forpago	ARRAY[1000] OF RECORD
				j01_codigo_pago	LIKE cajt001.j01_codigo_pago,
				j01_nombre	LIKE cajt001.j01_nombre,
				j01_cont_cred	LIKE cajt001.j01_cont_cred,
				j01_estado	LIKE cajt001.j01_estado
			END RECORD
DEFINE query		CHAR(1100)
DEFINE expr_sql		CHAR(600)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_ret		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_pant = 10
LET max_row    = 1000
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_forpago AT 06, 44 WITH num_fil ROWS, 35 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf095 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf095'
ELSE
	OPEN FORM f_ayuf095 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf095c'
END IF
DISPLAY FORM f_ayuf095
--#DISPLAY "Codigo"		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY "T"			TO tit_col3
--#DISPLAY "E"			TO tit_col4
LET primera  = 1
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND j01_estado      = "', estado, '"'
END IF
LET expr_tip = NULL
IF cont_cred <> 'T' THEN
	LET expr_tip = '   AND j01_cont_cred   = "', cont_cred, '"'
END IF
LET expr_ret = NULL
IF reten <> 'T' THEN
	LET expr_ret = '   AND j01_retencion   = "', reten, '"'
END IF
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON j01_codigo_pago, j01_nombre,
			j01_cont_cred, j01_estado
		IF int_flag THEN
			CLOSE WINDOW wh_forpago
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT j01_codigo_pago, j01_nombre,',
					' j01_cont_cred, j01_estado ',
			' FROM cajt001 ',
			' WHERE j01_compania = ', cod_cia,
				expr_est CLIPPED,
				expr_tip CLIPPED,
				expr_ret CLIPPED,
			'   AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE forpag FROM query
		DECLARE q_forpag CURSOR FOR forpag
		LET i = 1
		FOREACH q_forpag INTO rh_forpago[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i     = 0
			LET salir = 1
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE '                                           '
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_forpago TO rh_forpago.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_forpago[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_forpago
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_forpago[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_forpago[1].* TO NULL
        RETURN rh_forpago[1].j01_codigo_pago, rh_forpago[1].j01_nombre,
		rh_forpago[1].j01_cont_cred
END IF
LET i = arr_curr()
RETURN rh_forpago[i].j01_codigo_pago, rh_forpago[i].j01_nombre,
	rh_forpago[i].j01_cont_cred

END FUNCTION



FUNCTION fl_ayuda_cajas(cod_cia, cod_loc)
DEFINE cod_cia		LIKE cajt002.j02_compania
DEFINE cod_loc		LIKE cajt002.j02_localidad
DEFINE rh_cajas		ARRAY[100] OF RECORD
			   	j02_codigo_caja	LIKE cajt002.j02_codigo_caja,
			        j02_nombre_caja	LIKE cajt002.j02_nombre_caja,
			        j02_usua_caja	LIKE cajt002.j02_usua_caja
			END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max	SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant	SMALLINT        ## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT
DEFINE query		CHAR(600)

LET fil_ini = 6
LET col_ini = 40
LET fil_fin = 14
LET col_fin = 39
IF vg_gui = 0 THEN
	LET fil_ini = 5
	LET col_ini = 39
	LET fil_fin = 16
	LET col_fin = 40
END IF
OPEN WINDOW wh_cajas AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf096 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf096'
ELSE
	OPEN FORM f_ayuf096 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf096c'
END IF
DISPLAY FORM f_ayuf096
--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY "Descripción"	TO tit_col2
--#DISPLAY "Usuario"		TO tit_col3
LET filas_max  = 100
LET filas_pant = fgl_scr_size('rh_cajas')
LET int_flag   = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1           = 1
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = 'SELECT j02_codigo_caja, j02_nombre_caja, j02_usua_caja ',
			' FROM cajt002 ',
			' WHERE j02_compania  = ', cod_cia,
			'   AND j02_localidad = ', cod_loc,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons_caj FROM query
	DECLARE q_cajas CURSOR FOR cons_caj
	LET i = 1
	FOREACH q_cajas INTO rh_cajas[i].*
	        LET i = i + 1
	        IF i > filas_max THEN
	                EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
	        CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY rh_cajas TO rh_cajas.*
		ON KEY(RETURN)
                       	LET salir = 1
                       	EXIT DISPLAY
		ON KEY(F15)
                       	LET col = 1
                       	EXIT DISPLAY
               	ON KEY(F16)
                       	LET col = 2
                       	EXIT DISPLAY
               	ON KEY(F17)
                       	LET col = 3
                       	EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
               	--#AFTER DISPLAY
                       	--#LET salir = 1
	END DISPLAY
       	IF int_flag = 1 AND col IS NULL THEN
               	EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
               	INITIALIZE col TO NULL
       	END IF
END WHILE
CLOSE WINDOW wh_cajas
IF int_flag THEN
        INITIALIZE rh_cajas[1].* TO NULL
        RETURN rh_cajas[1].j02_codigo_caja, rh_cajas[1].j02_nombre_caja
END IF
LET i = arr_curr()
RETURN rh_cajas[i].j02_codigo_caja, rh_cajas[i].j02_nombre_caja  

END FUNCTION



FUNCTION fl_ayuda_subtipo_cartera()
DEFINE rh_subcar ARRAY[100] OF RECORD
        g12_subtipo       	LIKE gent012.g12_subtipo,
        g12_nombre       	LIKE gent012.g12_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_subcar AT 06, 40 WITH 15 ROWS, 39 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf097 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf097'
ELSE
	OPEN FORM f_ayuf097 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf097c'
END IF
DISPLAY FORM f_ayuf097
LET filas_pant = fgl_scr_size('rh_subcar')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_subcar CURSOR FOR
        SELECT g12_subtipo, g12_nombre
		FROM gent012
		WHERE g12_tiporeg =  'CR'
        ORDER BY 1
LET i = 1
FOREACH qh_subcar INTO rh_subcar[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_subcar
        INITIALIZE rh_subcar[1].* TO NULL
        RETURN rh_subcar[1].g12_subtipo, rh_subcar[1].g12_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subcar TO rh_subcar.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_subcar
IF int_flag THEN
        INITIALIZE rh_subcar[1].* TO NULL
        RETURN rh_subcar[1].g12_subtipo, rh_subcar[1].g12_nombre
END IF
LET  i = arr_curr()
RETURN rh_subcar[i].g12_subtipo, rh_subcar[i].g12_nombre

END FUNCTION



FUNCTION fl_ayuda_cliente_localidad(cod_cia, cod_loc)
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc 		LIKE cxct002.z02_localidad
DEFINE rh_cliloc	ARRAY[10000] OF RECORD
				z02_codcli	LIKE cxct002.z02_codcli,
       				z01_nomcli	LIKE cxct001.z01_nomcli,
				z01_num_doc_id	LIKE cxct001.z01_num_doc_id,
			        z01_estado	LIKE cxct001.z01_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cliloc AT 06, 11 WITH 15 ROWS, 68 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf098 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf098'
ELSE
	OPEN FORM f_ayuf098 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf098c'
END IF
DISPLAY FORM f_ayuf098
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'         TO bt_codigo
--#DISPLAY 'Nombre Cliente' TO bt_nombre
--#DISPLAY 'Cedula/RUC'     TO bt_cedruc
--#DISPLAY 'E'		    TO bt_estado

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z02_codcli, z01_nomcli, z01_num_doc_id,
					z01_estado
	IF int_flag THEN
		CLOSE WINDOW w_cliloc
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT z02_codcli, z01_nomcli, z01_num_doc_id,z01_estado ",
			" FROM cxct001, cxct002 ",
			" WHERE z02_compania  = ",  cod_cia, 
			"   AND z02_localidad = ",  cod_loc, 
			"   AND z02_codcli    =  z01_codcli", 
			--"   AND z01_estado    =  'A'",
			"   AND ", expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cliloc FROM query
	DECLARE q_cliloc CURSOR FOR cliloc
	LET i = 1
	FOREACH q_cliloc INTO rh_cliloc[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliloc TO rh_cliloc.*
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_cliloc[i].*
                        END FOR
                        EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_cliloc
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_cliloc[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cliloc[1].* TO NULL
	RETURN rh_cliloc[1].z02_codcli, rh_cliloc[1].z01_nomcli
END IF
LET  i = arr_curr()
RETURN rh_cliloc[i].z02_codcli, rh_cliloc[i].z01_nomcli

END FUNCTION



FUNCTION fl_ayuda_proveedores_localidad(cod_cia, cod_loc)
DEFINE cod_cia		LIKE cxpt002.p02_compania
DEFINE cod_loc		LIKE cxpt002.p02_localidad
DEFINE rh_provloc	ARRAY[10000] OF RECORD
				p02_codprov	LIKE cxpt002.p02_codprov,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				p01_num_doc	LIKE cxpt001.p01_num_doc,
			        p01_estado	LIKE cxpt001.p01_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_provloc AT 06, 11 WITH 15 ROWS, 68 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf099 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf099'
ELSE
	OPEN FORM f_ayuf099 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf099c'
END IF
DISPLAY FORM f_ayuf099
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Código'           TO bt_codigo
--#DISPLAY 'Nombre Proveedor' TO bt_nombre
--#DISPLAY 'Cedula/RUC'       TO bt_cedruc
--#DISPLAY 'E'		      TO bt_estado
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p02_codprov, p01_nomprov, p01_num_doc,
					p01_estado
	IF int_flag THEN
		CLOSE WINDOW w_provloc
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT p02_codprov, p01_nomprov, p01_num_doc, ",
				" p01_estado ",
				" FROM cxpt002, cxpt001 ",
				" WHERE p02_compania  = ", cod_cia,
				"   AND p02_localidad = ", cod_loc,
				"   AND p02_codprov   = p01_codprov ",
				--"  AND p01_estado =  'A'",
				"   AND ", expr_sql CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE provloc FROM query
		DECLARE q_provloc CURSOR FOR provloc
		LET i = 1
		FOREACH q_provloc INTO rh_provloc[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
                	LET i = 0
	                LET salir = 0
        	        EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_provloc TO rh_provloc.*
			ON KEY(RETURN)
        	                LET salir = 1
                	        EXIT DISPLAY
			ON KEY(F2)
        	                LET int_flag = 4
                	        FOR i = 1 TO filas_pant
                        	        CLEAR rh_provloc[i].*
	                        END FOR
        	                EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
        	        END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
        	                LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF i = 0 THEN
	        CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
	        CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_provloc
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_provloc[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_provloc[1].* TO NULL
	RETURN rh_provloc[1].p02_codprov, rh_provloc[1].p01_nomprov
END IF
LET i = arr_curr()
RETURN rh_provloc[i].p02_codprov, rh_provloc[i].p01_nomprov

END FUNCTION
 


FUNCTION fl_ayuda_companias_cobranzas()
DEFINE rh_ciacob ARRAY[100] OF RECORD
   	z00_compania      	LIKE cxct000.z00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciacob AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf100 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf100'
ELSE
	OPEN FORM f_ayuf100 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf100c'
END IF
DISPLAY FORM f_ayuf100
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciacob CURSOR FOR
        SELECT z00_compania, g01_razonsocial FROM cxct000, gent001
		WHERE z00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciacob INTO rh_ciacob[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciacob
        INITIALIZE rh_ciacob[1].* TO NULL
        RETURN 	rh_ciacob[1].z00_compania, rh_ciacob[1].g01_razonsocial  
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacob TO rh_ciacob.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciacob
IF int_flag THEN
        INITIALIZE rh_ciacob[1].* TO NULL
        RETURN 	rh_ciacob[1].z00_compania, rh_ciacob[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciacob[i].z00_compania, rh_ciacob[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_companias_vehiculos()
DEFINE rh_ciaveh ARRAY[100] OF RECORD
   	v00_compania      	LIKE veht000.v00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciaveh AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf101'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_ciaveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_ciaveh CURSOR FOR
        SELECT v00_compania, g01_razonsocial FROM veht000, gent001
		WHERE z00_compania   = g01_compania
        ORDER BY 1
LET i = 1
FOREACH q_ciaveh INTO rh_ciaveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_ciaveh
        INITIALIZE rh_ciaveh[1].* TO NULL
        RETURN 	rh_ciaveh[1].v00_compania, rh_ciaveh[1].g01_razonsocial  
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciaveh TO rh_ciaveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciaveh
IF int_flag THEN
        INITIALIZE rh_ciaveh[1].* TO NULL
        RETURN 	rh_ciaveh[1].v00_compania, rh_ciaveh[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciaveh[i].v00_compania, rh_ciaveh[i].g01_razonsocial  

END FUNCTION



FUNCTION fl_ayuda_pedidos_vehiculos(cod_cia, cod_loc, tipo)
DEFINE rh_pedveh ARRAY[100] OF RECORD
   	v34_pedido      	LIKE veht034.v34_pedido,
        v34_estado      	LIKE veht034.v34_estado, 
        v34_fec_envio      	LIKE veht034.v34_fec_envio, 
        v34_fec_llegada      	LIKE veht034.v34_fec_llegada  
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht034.v34_compania
DEFINE cod_loc		LIKE veht034.v34_localidad
DEFINE tipo		LIKE veht034.v34_estado
DEFINE expr_tipo 	CHAR(55)	
DEFINE query		CHAR(500)
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_pedveh AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf102'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_pedveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF tipo = 'P' THEN
	LET expr_tipo = " v34_estado IN ('A','R','L','P')"
END IF
IF tipo = 'R' THEN
	LET expr_tipo = " v34_estado IN ('A','R')"
END IF
IF tipo = 'L' THEN
	LET expr_tipo = " v34_estado IN ('R','L')"
END IF 
LET query = "SELECT v34_pedido, v34_estado, v34_fec_envio, v34_fec_llegada ",
 		" FROM veht034 ",
		" WHERE v34_compania  = ", cod_cia," AND ",
		"       v34_localidad = ", cod_loc," AND ",
		expr_tipo CLIPPED,
		' ORDER BY 1'
PREPARE pedveh FROM query
DECLARE q_pedveh CURSOR FOR pedveh
LET i = 1
FOREACH q_pedveh INTO rh_pedveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_pedveh
        INITIALIZE rh_pedveh[1].* TO NULL
        RETURN 	rh_pedveh[1].v34_pedido,    rh_pedveh[1].v34_estado,
        	rh_pedveh[1].v34_fec_envio, rh_pedveh[1].v34_fec_llegada 
	     
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_pedveh TO rh_pedveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_pedveh
IF int_flag THEN
        INITIALIZE rh_pedveh[1].* TO NULL
        RETURN 	rh_pedveh[1].v34_pedido,    rh_pedveh[1].v34_estado,
        	rh_pedveh[1].v34_fec_envio, rh_pedveh[1].v34_fec_llegada 
END IF
LET  i = arr_curr()
RETURN 	rh_pedveh[i].v34_pedido,    rh_pedveh[i].v34_estado,
       	rh_pedveh[i].v34_fec_envio, rh_pedveh[i].v34_fec_llegada 

END FUNCTION



FUNCTION fl_ayuda_serie_veh_facturados(cod_cia, cod_loc)

DEFINE rh_vehfac ARRAY[1000] OF RECORD
	v30_codcli 		LIKE veht030.v30_codcli,
	z01_nomcli		LIKE cxct001.z01_nomcli,
	v22_codigo_veh		LIKE veht022.v22_codigo_veh,
	v22_modelo		LIKE veht022.v22_modelo 
	END RECORD
DEFINE i		SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht022.v22_compania
DEFINE cod_loc		LIKE veht022.v22_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_vehfac AT 06,13 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf103'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	v30_codcli, z01_nomcli, 
					v22_codigo_veh, v22_modelo
	IF int_flag THEN
		CLOSE WINDOW w_vehfac
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
--------------
	LET query = " SELECT v30_codcli, z01_nomcli, v22_codigo_veh, v22_modelo ",
  			" FROM veht022, veht030, cxct001 ",
		     " WHERE v22_compania = ", cod_cia,
			" AND v22_localidad= ", cod_loc,
			" AND v30_compania = ", cod_cia,
			" AND v30_localidad= ", cod_loc,
   			" AND v22_compania = v30_compania ",
   			" AND v22_localidad= v30_localidad ",
   			" AND v22_cod_tran = v30_cod_tran ",
   			" AND v22_num_tran = v30_num_tran ",
   			" AND v22_estado = 'F' ",
   			" AND v30_codcli = z01_codcli ",
			" AND ", expr_sql CLIPPED,
			" ORDER BY 2"
--------------
	PREPARE vehfac FROM query
	DECLARE q_vehfac CURSOR FOR vehfac 
	LET i = 1
	FOREACH q_vehfac INTO rh_vehfac[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_vehfac TO rh_vehfac.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_vehfac
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_vehfac[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_vehfac[1].*  TO NULL
	RETURN rh_vehfac[1].*
END IF
LET  i = arr_curr()
RETURN rh_vehfac[i].*

END FUNCTION
 


FUNCTION fl_ayuda_liquidacion_vehiculos(cod_cia, cod_loc)
DEFINE rh_liqveh ARRAY[100] OF RECORD
   	v36_pedido	      	LIKE veht036.v36_pedido,
   	v36_numliq	      	LIKE veht036.v36_numliq,
   	v36_estado	      	LIKE veht036.v36_estado 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE veht036.v36_compania
DEFINE cod_loc		LIKE veht036.v36_localidad
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_liqveh AT 06,52
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf104'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_liqveh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_liqveh CURSOR FOR
        SELECT v36_pedido, v36_numliq, v36_estado FROM veht036
        ORDER BY 2
LET i = 1
FOREACH q_liqveh INTO rh_liqveh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_liqveh
        INITIALIZE rh_liqveh[1].* TO NULL
        RETURN 	rh_liqveh[1].v36_pedido, rh_liqveh[1].v36_numliq,
		rh_liqveh[1].v36_estado  
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_liqveh TO rh_liqveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_liqveh
IF int_flag THEN
        INITIALIZE rh_liqveh[1].* TO NULL
        RETURN 	rh_liqveh[1].v36_pedido, rh_liqveh[1].v36_numliq,
		rh_liqveh[1].v36_estado  
END IF
LET  i = arr_curr()
RETURN 	rh_liqveh[i].v36_pedido, rh_liqveh[i].v36_numliq,
	rh_liqveh[i].v36_estado  

END FUNCTION




FUNCTION fl_ayuda_maestro_items_stock(cod_cia, grupo, bodega)
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE bodega	 	LIKE rept011.r11_bodega
DEFINE grupo		LIKE rept003.r03_grupo_linea
DEFINE rh_reppre	ARRAY[15000] OF RECORD
				r10_sec_item	LIKE rept010.r10_sec_item,
			   	r10_codigo      LIKE rept010.r10_codigo,
   				r10_nombre      LIKE rept010.r10_nombre,
			--   	r10_linea  	LIKE rept010.r10_linea,
			   	r10_precio_mb   LIKE rept010.r10_precio_mb,
				r11_bodega	LIKE rept011.r11_bodega,
		   		r11_stock_act   LIKE rept011.r11_stock_act 
			END RECORD
DEFINE rh_lin		ARRAY[15000] OF LIKE rept010.r10_linea
DEFINE i, j		SMALLINT
DEFINE criterio		CHAR(600)	## Contiene el CONSTRUCT del usuario
--DEFINE criterio2	CHAR(100)	## Contiene el CONSTRUCT del stock
DEFINE query		CHAR(1200)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_sub		RECORD LIKE rept070.*
DEFINE r_grp		RECORD LIKE rept071.*
DEFINE r_cla		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
--DEFINE expr_outer	CHAR(10)
DEFINE expr_bodega	CHAR(100)
DEFINE expr_linea	CHAR(100)
DEFINE expr_sublinea	CHAR(100)
DEFINE expr_grupo	CHAR(100)
DEFINE expr_clase	CHAR(100)
DEFINE expr_marca	CHAR(100)
DEFINE flag		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max = 15000
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_reppre AT 05, 03 WITH 18 ROWS, 76 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf105 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf105'
ELSE
	OPEN FORM f_ayuf105 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf105c'
END IF
DISPLAY FORM f_ayuf105
LET filas_pant = fgl_scr_size('rh_reppre')
IF vg_gui = 1 THEN
	DISPLAY 'Sec'         TO tit_col1
	DISPLAY 'Codigo'      TO tit_col2
	DISPLAY 'Descripcion' TO tit_col3
	DISPLAY 'Precio'      TO tit_col4
	DISPLAY 'Bd'          TO tit_col5
	DISPLAY 'Stock'       TO tit_col6
END IF
LET r_r10.r10_linea = NULL
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	INPUT BY NAME r_r10.r10_linea, r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
		r_r10.r10_cod_clase, r_r10.r10_marca
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
		ON KEY(F2)
			IF INFIELD(r10_linea) THEN
		     		CALL fl_ayuda_lineas_rep(cod_cia)
		     			RETURNING r_r03.r03_codigo, r_r03.r03_nombre
		     		IF r_r03.r03_codigo IS NOT NULL THEN
					LET r_r10.r10_linea = r_r03.r03_codigo
					DISPLAY BY NAME r_r10.r10_linea
					DISPLAY r_r03.r03_nombre TO descri_linea
		     		END IF
			END IF
			IF INFIELD(r10_sub_linea) THEN
				CALL fl_ayuda_sublinea_rep(cod_cia,
								r_r10.r10_linea)
		  		RETURNING r_sub.r70_sub_linea,
					  r_sub.r70_desc_sub
				IF r_sub.r70_sub_linea IS NOT NULL THEN
					LET r_r10.r10_sub_linea =
							r_sub.r70_sub_linea
					DISPLAY BY NAME r_r10.r10_sub_linea
					DISPLAY r_sub.r70_desc_sub TO descri_sub_linea
		   		END IF
			END IF
			IF INFIELD(r10_cod_grupo) THEN
				CALL fl_ayuda_grupo_ventas_rep(cod_cia,
							r_r10.r10_linea,
							r_r10.r10_sub_linea)
		     			RETURNING r_grp.r71_cod_grupo,
						  r_grp.r71_desc_grupo
				IF r_grp.r71_cod_grupo IS NOT NULL THEN
					LET r_r10.r10_cod_grupo =
							r_grp.r71_cod_grupo
					DISPLAY BY NAME r_r10.r10_cod_grupo
					DISPLAY r_grp.r71_desc_grupo TO descri_cod_grupo
		     		END IF
			END IF
			IF INFIELD(r10_cod_clase) THEN
				CALL fl_ayuda_clase_ventas_rep(cod_cia,
							r_r10.r10_linea,
							r_r10.r10_sub_linea,
							r_r10.r10_cod_grupo)
			     		RETURNING r_cla.r72_cod_clase,
					   	  r_cla.r72_desc_clase
			     	IF r_cla.r72_cod_clase IS NOT NULL THEN
					LET r_r10.r10_cod_clase =
							r_cla.r72_cod_clase
					DISPLAY BY NAME r_r10.r10_cod_clase
					DISPLAY r_cla.r72_desc_clase TO descri_cod_clase
			     	END IF
			END IF
			IF INFIELD(r10_marca) THEN
				CALL fl_ayuda_marcas_rep_asignadas(cod_cia, 
					r_r10.r10_cod_clase)
		  			RETURNING r_r73.r73_marca
				IF r_r73.r73_compania IS NOT NULL THEN
					LET r_r10.r10_marca = r_r73.r73_marca
					DISPLAY BY NAME r_r10.r10_marca
		   		END IF
			END IF
        	        LET int_flag = 0
		AFTER FIELD r10_linea
			IF r_r10.r10_linea IS NOT NULL THEN
				CALL fl_lee_linea_rep(cod_cia, r_r10.r10_linea)
					RETURNING r_r03.*
				IF r_r03.r03_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Division no existe.','exclamation')
					NEXT FIELD r10_linea
				END IF
				DISPLAY r_r03.r03_nombre TO descri_linea
			ELSE
				CLEAR descri_linea
			END IF
		AFTER FIELD r10_sub_linea 
			IF r_r10.r10_sub_linea IS NOT NULL THEN
{--
				IF r_r10.r10_linea IS NULL THEN
					CALL fl_mostrar_mensaje('Digite division primero.','exclamation')
					LET r_r10.r10_sub_linea = NULL
					CLEAR r10_sub_linea
					NEXT FIELD r10_linea
				END IF	
				CALL fl_lee_sublinea_rep(cod_cia, r_r10.r10_linea, r_r10.r10_sub_linea)
					RETURNING r_sub.*
--}
				CALL fl_retorna_sublinea_rep(cod_cia,
							r_r10.r10_sub_linea)
					RETURNING r_sub.*, flag
				IF flag = 0 THEN
					IF r_sub.r70_compania IS NULL THEN
						CALL fl_mostrar_mensaje('Linea no existe.','exclamation')
						NEXT FIELD r10_sub_linea
					END IF
				END IF
				DISPLAY r_sub.r70_desc_sub TO descri_sub_linea
			ELSE
				CLEAR descri_sub_linea
			END IF
		AFTER FIELD r10_cod_grupo 
			IF r_r10.r10_cod_grupo IS NOT NULL THEN
{--
				IF r_r10.r10_sub_linea IS NULL THEN
					CALL fl_mostrar_mensaje('Digite linea primero.','exclamation')
					LET r_r10.r10_cod_grupo = NULL
					CLEAR r10_cod_grupo
					NEXT FIELD r10_sub_linea
				END IF	
				CALL fl_lee_grupo_rep(cod_cia, r_r10.r10_linea, r_r10.r10_sub_linea, r_r10.r10_cod_grupo)
					RETURNING r_grp.*
--}
				CALL fl_retorna_grupo_rep(cod_cia,
							r_r10.r10_cod_grupo)
					RETURNING r_grp.*, flag
				IF flag = 0 THEN
					IF r_grp.r71_compania IS NULL THEN
						CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
						NEXT FIELD r10_cod_grupo
					END IF
				END IF
				DISPLAY r_grp.r71_desc_grupo TO descri_cod_grupo
			ELSE
				CLEAR descri_cod_grupo
			END IF
		AFTER FIELD r10_cod_clase 
			IF r_r10.r10_cod_clase IS NOT NULL THEN
{--
				IF r_r10.r10_cod_grupo IS NULL THEN
					CALL fl_mostrar_mensaje('Digite grupo primero.','exclamation')
					LET r_r10.r10_cod_clase = NULL
					CLEAR r10_cod_clase
					NEXT FIELD r10_cod_grupo
				END IF	
				CALL fl_lee_clase_rep(cod_cia, r_r10.r10_linea, r_r10.r10_sub_linea, r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
					RETURNING r_cla.*
--}
				CALL fl_retorna_clase_rep(cod_cia,
							r_r10.r10_cod_clase)
					RETURNING r_cla.*, flag
				IF flag = 0 THEN
					IF r_cla.r72_compania IS NULL THEN
						CALL fl_mostrar_mensaje('Clase no existe.','exclamation')
						NEXT FIELD r10_cod_clase
					END IF
				END IF
				DISPLAY r_cla.r72_desc_clase TO descri_cod_clase
			ELSE
				CLEAR descri_cod_clase
			END IF
		AFTER FIELD r10_marca 
			IF r_r10.r10_marca IS NOT NULL THEN
				CALL fl_lee_marca_rep(cod_cia, r_r10.r10_marca)
					RETURNING r_r73.*
				IF r_r73.r73_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Marca no existe.','exclamation')
					NEXT FIELD r10_marca
				END IF
				DISPLAY r_r73.r73_desc_marca TO descri_marca
			ELSE
				CLEAR descri_marca
			END IF
	END INPUT
	IF int_flag THEN
		INITIALIZE rh_reppre[1].* TO NULL
		CLOSE WINDOW w_reppre
		RETURN rh_reppre[1].r10_codigo, rh_reppre[1].r10_nombre,
		rh_lin[1], rh_reppre[1].r10_precio_mb, rh_reppre[1].r11_bodega,
		rh_reppre[1].r11_stock_act
	END IF
	--OPTIONS INPUT NO WRAP
	CONSTRUCT BY NAME criterio ON 	r10_sec_item, r10_codigo, r10_nombre, 
 					r10_precio_mb, r11_bodega, r11_stock_act
		BEFORE CONSTRUCT
			IF bodega <> '00' THEN
				DISPLAY bodega TO r11_bodega
			END IF
--			DISPLAY "> 0" TO r11_stock_act
	END CONSTRUCT
	IF int_flag THEN
		CLOSE WINDOW w_reppre
		EXIT WHILE
	END IF
	{--
	CONSTRUCT BY NAME criterio2 ON r11_stock_act
	IF int_flag THEN
		INITIALIZE rh_reppre[1].* TO NULL
		CLOSE WINDOW w_reppre
		RETURN rh_reppre[1].r10_codigo, rh_reppre[1].r10_nombre,
		rh_lin[1], rh_reppre[1].r10_precio_mb, rh_reppre[1].r11_bodega,
		rh_reppre[1].r11_stock_act
	END IF
	OPTIONS INPUT WRAP
	--}
	MESSAGE "Seleccionando datos .."
	LET expr_linea = NULL
	IF r_r10.r10_linea IS NOT NULL THEN
		LET expr_linea = ' AND r10_linea = "',
					r_r10.r10_linea CLIPPED, '"'
	END IF
	LET expr_sublinea = NULL
	IF r_r10.r10_sub_linea IS NOT NULL THEN
		LET expr_sublinea = ' AND r10_sub_linea = "',
					r_r10.r10_sub_linea CLIPPED, '"'
	END IF
	LET expr_grupo = NULL
	IF r_r10.r10_cod_grupo IS NOT NULL THEN
		LET expr_grupo = ' AND r10_cod_grupo = "',
					r_r10.r10_cod_grupo CLIPPED, '"'
	END IF
	LET expr_clase = NULL
	IF r_r10.r10_cod_clase IS NOT NULL THEN
		LET expr_clase = ' AND r10_cod_clase = "',
					r_r10.r10_cod_clase CLIPPED, '"'
	END IF
	LET expr_marca = NULL
	IF r_r10.r10_marca IS NOT NULL THEN
		LET expr_marca = ' AND r10_marca = "', r_r10.r10_marca CLIPPED, '"'
	END IF
	{--
	LET expr_outer = NULL
	IF criterio2 = ' 1=1 ' THEN
		LET expr_outer = ' OUTER '
	END IF
	--}
	LET vm_columna_1           = 1
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
        	LET query = "SELECT r10_sec_item, r10_codigo, r10_nombre,",
				" r10_linea, r10_precio_mb, r11_bodega,",
				" r11_stock_act",
				--" FROM rept010, ", expr_outer CLIPPED,
					--" rept011 ",
				" FROM rept010, OUTER rept011 ",
	                        " WHERE r10_compania  = ", cod_cia,
				"   AND r10_estado   <> 'B' ",
				"   AND r10_compania  = r11_compania ",
				"   AND r10_codigo    = r11_item ",  
				expr_linea CLIPPED,
				expr_sublinea CLIPPED,
				expr_grupo CLIPPED,
				expr_clase CLIPPED,
				expr_marca CLIPPED,
				"   AND ", criterio CLIPPED,
	                    	" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE reppre FROM query
		DECLARE q_reppre CURSOR FOR reppre
		LET i = 1
		FOREACH q_reppre INTO rh_reppre[i].r10_sec_item,
					rh_reppre[i].r10_codigo,
					rh_reppre[i].r10_nombre, rh_lin[i],
					rh_reppre[i].r10_precio_mb,
					rh_reppre[i].r11_bodega,
					rh_reppre[i].r11_stock_act
			IF rh_reppre[i].r11_stock_act IS NULL THEN
				LET rh_reppre[i].r11_stock_act = 0
			END IF
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		DISPLAY rh_reppre[1].r10_nombre TO tit_descripcion
		LET int_flag = 0
		DISPLAY ARRAY rh_reppre TO rh_reppre.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
	               		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	               		EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
			ON KEY(F5)
				LET j = arr_curr()
				DISPLAY rh_reppre[j].r10_nombre TO
					tit_descripcion
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
        	        	LET col = 5
	                        EXIT DISPLAY
		        ON KEY(F19)
        		        LET col = 6
                        	EXIT DISPLAY
		        ON KEY(F20)
        		        LET col = 7
                	        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
				--#DISPLAY rh_reppre[j].r10_nombre TO
					--#tit_descripcion
				--#CALL dialog.keysetlabel("F5","")
			--#AFTER DISPLAY
	        	        --#LET salir = 1
		END DISPLAY
        	IF int_flag = 4 OR int_flag = 1 THEN
                	EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
        	        IF rm_orden[vm_columna_1] = 'ASC' THEN
                	        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
	                INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_reppre[i].* TO NULL
			CLEAR rh_reppre[i].*, tit_descripcion
		END FOR
	END IF
	IF NOT salir THEN
       		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_reppre
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_reppre[1].* TO NULL
	RETURN rh_reppre[1].r10_codigo, rh_reppre[1].r10_nombre,
		rh_lin[1], rh_reppre[1].r10_precio_mb, rh_reppre[1].r11_bodega,
		rh_reppre[1].r11_stock_act
END IF
LET  i = arr_curr()
RETURN rh_reppre[i].r10_codigo, rh_reppre[i].r10_nombre,
       rh_lin[i], rh_reppre[i].r10_precio_mb, rh_reppre[i].r11_bodega,
       rh_reppre[i].r11_stock_act

END FUNCTION



FUNCTION fl_ayuda_preventas_rep(cod_cia, cod_loc, estado)

DEFINE rh_prerep ARRAY[1000] OF RECORD
	r23_numprev	LIKE rept023.r23_numprev,
	r23_nomcli	LIKE rept023.r23_nomcli, 
	r23_estado	LIKE rept023.r23_estado
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_estado	CHAR(25)
DEFINE cod_cia		LIKE rept023.r23_compania
DEFINE cod_loc		LIKE rept023.r23_localidad
DEFINE estado		LIKE rept023.r23_estado
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_prerep AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf106 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf106'
ELSE
	OPEN FORM f_ayuf106 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf106c'
END IF
DISPLAY FORM f_ayuf106
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Número'     TO bt_numero
--#DISPLAY 'Cliente'    TO bt_cliente
--#DISPLAY 'E'          TO bt_estado

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r23_numprev, r23_nomcli, r23_estado
	IF int_flag THEN
		CLOSE WINDOW w_prerep
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
----------
	LET expr_estado = " 1 = 1 "
	## Estado 'M' para preventas Modificables
	IF estado = 'M' THEN
		LET expr_estado = " r23_estado  IN ('A','P') "
	END IF
	IF  estado <> 'M' THEN
		LET expr_estado = " r23_estado  = '", estado, "'"  
	END IF
----------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT r23_numprev, r23_nomcli, r23_estado FROM rept023 ",
				"WHERE r23_compania =  ", cod_cia, " AND ",
				"r23_localidad = ", cod_loc, " AND ",
				 expr_estado, " AND ",
				 expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2],
                           ', ', vm_columna_3, ' ', rm_orden[vm_columna_3]
	PREPARE prerep FROM query
	DECLARE q_prerep CURSOR FOR prerep
	LET i = 1
	FOREACH q_prerep INTO rh_prerep[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
------------------
	DISPLAY ARRAY rh_prerep TO rh_prerep.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_prerep[i].*
                        END FOR
                        EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_prerep
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_prerep[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_prerep[1].* TO NULL
	RETURN rh_prerep[1].*
END IF
LET  i = arr_curr()
RETURN rh_prerep[i].*

END FUNCTION



FUNCTION fl_ayuda_preventas_veh(cod_cia, cod_loc, estado)

DEFINE rh_preveh ARRAY[1000] OF RECORD
	v26_numprev	LIKE veht026.v26_numprev,
	z01_nomcli	LIKE cxct001.z01_nomcli, 
	v26_estado	LIKE veht026.v26_estado
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_estado	CHAR(45)
DEFINE cod_cia		LIKE rept023.r23_compania
DEFINE cod_loc		LIKE rept023.r23_localidad
DEFINE estado		LIKE rept023.r23_estado
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_preveh AT 06,27 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf107'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Número'     TO bt_orden
DISPLAY 'Cliente'    TO bt_cliente
DISPLAY 'E'          TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON v26_numprev, z01_nomcli, v26_estado
	IF int_flag THEN
		CLOSE WINDOW w_preveh
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
----------
	LET expr_estado = " 1 = 1 "
	## Estado 'M' para preventas todas
	IF estado = 'M' THEN
		LET expr_estado = " v26_estado  IN ('A','P','B','F') "
	END IF
	IF  estado <> 'M' THEN
		LET expr_estado = " v26_estado  = '", estado, "'"  
	END IF
----------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT v26_numprev, z01_nomcli, v26_estado FROM veht026, cxct001 ",
				"WHERE v26_compania =  ", cod_cia, " AND ",
				"v26_localidad   = ", cod_loc,     " AND ",
				"v26_codcli      = z01_codcli ",   " AND ",
				 expr_estado CLIPPED, " AND ",
				 expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE preveh FROM query
	DECLARE q_preveh CURSOR FOR preveh
	LET i = 1
	FOREACH q_preveh INTO rh_preveh[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_preveh TO rh_preveh.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
        CLOSE WINDOW w_preveh
        EXIT WHILE
END IF
IF salir THEN
        EXIT WHILE
END IF
FOR i = 1 TO filas_pant
        CLEAR rh_preveh[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_preveh[1].* TO NULL
	RETURN rh_preveh[1].*
END IF
LET  i = arr_curr()
RETURN rh_preveh[i].*

END FUNCTION




FUNCTION fl_ayuda_proformas_rep(cod_cia, cod_loc)

DEFINE rh_prorep ARRAY[1000] OF RECORD
	r21_numprof	LIKE rept021.r21_numprof,
	r21_nomcli	LIKE rept021.r21_nomcli  
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_estado	CHAR(25)
DEFINE cod_cia		LIKE rept021.r21_compania
DEFINE cod_loc		LIKE rept021.r21_localidad
DEFINE r_vend		RECORD LIKE rept001.*
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE expr_vend 	CHAR(30)

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
DECLARE qu_ace CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_ace 
INITIALIZE r_vend.* TO NULL
FETCH qu_ace INTO r_vend.*
IF status = NOTFOUND THEN
END IF		
LET expr_vend = ' 1 = 1 '
IF r_vend.r01_tipo <> 'J' THEN
	LET expr_vend = ' r21_vendedor = ', r_vend.r01_codigo
END IF
LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_prorep AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf108 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf108'
ELSE
	OPEN FORM f_ayuf108 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf108c'
END IF
DISPLAY FORM f_ayuf108
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r21_numprof, r21_nomcli
	IF int_flag THEN
		CLOSE WINDOW w_prorep
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT r21_numprof, r21_nomcli FROM rept021 ",
				"WHERE r21_compania =  ", cod_cia, " AND ",
				"r21_localidad = ", cod_loc, " AND ",
				 expr_vend CLIPPED, ' AND ',
				 expr_sql CLIPPED,
				" ORDER BY 1"
	PREPARE prorep FROM query
	DECLARE q_prorep CURSOR FOR prorep
	LET i = 1
	FOREACH q_prorep INTO rh_prorep[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_prorep TO rh_prorep.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_prorep
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_prorep[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_prorep[1].* TO NULL
	RETURN rh_prorep[1].*
END IF
LET  i = arr_curr()
RETURN rh_prorep[i].*

END FUNCTION



FUNCTION fl_ayuda_numero_fuente_caja(cod_cia, cod_loc, tip_fue)
DEFINE cod_cia		LIKE rept021.r21_compania
DEFINE cod_loc		LIKE rept021.r21_localidad
DEFINE tip_fue		LIKE cajt010.j10_tipo_fuente
DEFINE rh_numfue	ARRAY[20000] OF RECORD
				j10_tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				j10_num_fuente	LIKE cajt010.j10_num_fuente,
				numero		VARCHAR(5),
				j10_codcli	LIKE cajt010.j10_codcli,
				j10_nomcli	LIKE cajt010.j10_nomcli,
				j10_valor	LIKE cajt010.j10_valor,
				j10_estado	LIKE cajt010.j10_estado
			END RECORD
DEFINE vendedor		ARRAY[20000] OF LIKE rept001.r01_nombres
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(400)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(2000)	## Contiene todo el query preparado
DEFINE expr_estado	VARCHAR(100)
DEFINE campo1, campo2	CHAR(700)
DEFINE tit_col3		CHAR(10)
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE total		DECIMAL(14,2)

LET filas_max  = 20000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_numfue AT 06, 06 WITH 15 ROWS, 74 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf109 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf109'
ELSE
	OPEN FORM f_ayuf109 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf109c'
END IF
DISPLAY FORM f_ayuf109
IF vg_gui = 1 THEN
	DISPLAY "TP"		TO tit_col1
	DISPLAY "Número"	TO tit_col2
	LET tit_col3 = '.'
	CASE tip_fue
		WHEN 'PR' LET tit_col3 = 'No.OT'
		WHEN 'SC' LET tit_col3 = 'Area'
	END CASE
	DISPLAY BY NAME tit_col3
	IF tip_fue <> 'PR' AND tip_fue <> 'SC' THEN
		DISPLAY '' TO tit_col3
	END IF
	DISPLAY "Cod Cli"	TO tit_col4
	DISPLAY "C l i e n t e"	TO tit_col5
	DISPLAY "Valor"		TO tit_col6
	DISPLAY "E"		TO tit_col7
END IF
LET expr_estado = NULL
## Vía tip_fue = 'EC' se buscarán con Estado 'P,E' para los egresos
IF tip_fue = 'EC' THEN
	LET expr_estado = "  AND j10_estado  IN ('P','E') "
ELSE
	LET expr_estado = "  AND j10_estado  IN ('A') "
END IF
LET campo1 = "'' num, "
LET campo2 = "'' vend "
CASE tip_fue
	WHEN 'OT'
		LET campo2 = "(SELECT r01_nombres ",
				"FROM talt023, talt061, rept001 ",
				"WHERE t23_compania   = j10_compania ",
				"  AND t23_localidad  = j10_localidad ",
				"  AND t23_orden      = j10_num_fuente ",
				"  AND t61_compania   = t23_compania ",
				"  AND t61_cod_asesor = t23_cod_asesor ",
				"  AND r01_compania   = t61_compania ",
				"  AND r01_codigo     = t61_cod_vendedor) vend "
	WHEN 'PR'
		LET campo1 = "(SELECT r23_num_ot ",
				"FROM rept023 ",
				"WHERE r23_compania  = j10_compania ",
				"  AND r23_localidad = j10_localidad ",
				"  AND r23_numprev   = j10_num_fuente) num, "
		LET campo2 = "(SELECT r01_nombres ",
				"FROM rept023, rept001 ",
				"WHERE r23_compania  = j10_compania ",
				"  AND r23_localidad = j10_localidad ",
				"  AND r23_numprev   = j10_num_fuente ",
				"  AND r01_compania  = r23_compania ",
				"  AND r01_codigo    = r23_vendedor) vend "
	WHEN 'SC'
		LET campo1 = "(SELECT g03_abreviacion[1, 3] ",
				"FROM gent003 ",
				"WHERE g03_compania = j10_compania ",
				"  AND g03_areaneg  = j10_areaneg) num, "
END CASE
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		IF vg_gui = 1 THEN
			DISPLAY tip_fue TO j10_tipo_fuente
		END IF
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON j10_num_fuente, j10_codcli,
						j10_nomcli, j10_valor
		IF int_flag THEN
			CLOSE WINDOW w_numfue
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT j10_tipo_fuente, j10_num_fuente, ",
					campo1 CLIPPED, " j10_codcli, ",
					"j10_nomcli, j10_valor, j10_estado, ",
					campo2 CLIPPED, " ",
				"FROM cajt010 ",
				"WHERE j10_compania    = ", cod_cia,
				"  AND j10_localidad   = ", cod_loc,
				"  AND j10_tipo_fuente = '", tip_fue, "'",
				expr_estado CLIPPED,
				"  AND ", expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
						rm_orden[vm_columna_1], ', ',
						vm_columna_2, ' ',
						rm_orden[vm_columna_2]
		PREPARE numfue FROM query
		DECLARE q_numfue CURSOR FOR numfue
		LET i     = 1
		LET total = 0
		FOREACH q_numfue INTO rh_numfue[i].*, vendedor[i]
			LET total = total + rh_numfue[i].j10_valor
			LET i     = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		MESSAGE "                                           "
		DISPLAY BY NAME total
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_numfue TO rh_numfue.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				IF tip_fue = 'PR' OR tip_fue = 'SC' THEN
					LET col = 3
					EXIT DISPLAY
				END IF
			ON KEY(F18)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F19)
				LET col = 5
				EXIT DISPLAY
			ON KEY(F20)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F21)
				LET col = 7
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_rows
				--#DISPLAY i TO max_rows
				--#DISPLAY BY NAME vendedor[j]
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_numfue[i].* TO NULL
			CLEAR rh_numfue[i].*
		END FOR
		CLEAR total, num_rows, max_rows, vendedor
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_numfue
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_numfue[1].* TO NULL
	RETURN rh_numfue[1].j10_num_fuente, rh_numfue[1].j10_nomcli,
		rh_numfue[1].j10_valor
END IF
LET i = arr_curr()
RETURN rh_numfue[i].j10_num_fuente, rh_numfue[i].j10_nomcli,
	rh_numfue[i].j10_valor

END FUNCTION




FUNCTION fl_ayuda_maestro_items_stock_sinlinea(cod_cia, bodega)
DEFINE rh_repsin ARRAY[1000] OF RECORD
   	r10_codigo      	LIKE rept010.r10_codigo,
   	r10_nombre      	LIKE rept010.r10_nombre,
   	r10_linea  	    	LIKE rept010.r10_linea,
   	r10_precio_mb      	LIKE rept010.r10_precio_mb,
	r11_bodega		LIKE rept011.r11_bodega,
   	r11_stock_act      	LIKE rept011.r11_stock_act 
	END RECORD
DEFINE i		SMALLINT
DEFINE criterio	CHAR(600)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(600)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE bodega	 	LIKE rept011.r11_bodega
DEFINE expr_bodega	CHAR(100)
DEFINE j		SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_repsin AT 06, 06 WITH 15 ROWS, 73 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf110 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf110'
ELSE
	OPEN FORM f_ayuf110 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf110c'
END IF
DISPLAY FORM f_ayuf110
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON 	r10_codigo, r10_nombre, r10_linea,
 					r10_precio_mb, r11_bodega,
					r11_stock_act
		BEFORE CONSTRUCT
			IF bodega <> '00' THEN
				DISPLAY bodega TO r11_bodega
			END IF
			DISPLAY "> 0" TO r11_stock_act
	END CONSTRUCT
	IF int_flag THEN
		CLOSE WINDOW w_repsin
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
---------
        LET query = "SELECT r10_codigo, r10_nombre, r10_linea, r10_precio_mb, r11_bodega, r11_stock_act  FROM rept010, rept011 ",
                                " WHERE r10_compania = ", cod_cia, " AND ",
			 	" r11_compania = ",       cod_cia, " AND ",	
                                " r10_compania = r11_compania",    " AND ",
                                " r10_codigo = r11_item",          " AND ",
                                " r11_bodega = '", bodega,"'",     " AND ",
                                 criterio CLIPPED
---------
	PREPARE repsin FROM query
	DECLARE q_repsin CURSOR FOR repsin
	LET i = 1
	FOREACH q_repsin INTO rh_repsin[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_repsin TO rh_repsin.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_repsin
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_repsin[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_repsin[1].* TO NULL
	RETURN rh_repsin[1].*
END IF
LET  i = arr_curr()
RETURN rh_repsin[i].*

END FUNCTION



FUNCTION fl_ayuda_transaccion_rep(cod_cia, cod_loc, tip_tran)
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE tip_tran		LIKE rept019.r19_cod_tran
DEFINE rh_transac	ARRAY[10000] OF RECORD
			   	r19_cod_tran   	LIKE rept019.r19_cod_tran,
			   	r19_num_tran   	LIKE rept019.r19_num_tran,
			   	r19_nomcli     	LIKE rept019.r19_nomcli,
			   	r19_referencia	LIKE rept019.r19_referencia
			END RECORD
DEFINE expr_tran	VARCHAR(100)
DEFINE criterio		CHAR(600)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(800)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT

LET fil_ini = 6
LET col_ini = 13
LET fil_fin = 14
LET col_fin = 66
IF vg_gui = 0 THEN
	LET fil_ini = 5
	LET col_ini = 12
	LET fil_fin = 16
	LET col_fin = 67
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_transac AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf111 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf111'
ELSE
	OPEN FORM f_ayuf111 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf111c'
END IF
DISPLAY FORM f_ayuf111
LET filas_max  = 10000
LET filas_pant = fgl_scr_size('rh_transac')
--#DISPLAY 'TP'		TO tit_col1
--#DISPLAY 'Número'	TO tit_col2
IF tip_tran = "FA" OR tip_tran = "DF" OR tip_tran = "AF" THEN
	--#DISPLAY 'Cliente'	TO tit_col3
ELSE
	IF tip_tran = "CL" OR tip_tran = "DC" THEN
		--#DISPLAY 'Proveedor' TO tit_col3
	ELSE
		--#DISPLAY 'Nombre'    TO tit_col3
	END IF
END IF
--#DISPLAY 'Referencia'	TO tit_col4
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	IF tip_tran <> '00' THEN 
		DISPLAY tip_tran TO r19_cod_tran
	END IF
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON r19_num_tran, r19_nomcli, r19_referencia
	IF int_flag THEN
		CLOSE WINDOW w_transac
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
	LET expr_tran = NULL
	IF tip_tran <> '00' THEN 
		LET expr_tran = "   AND r19_cod_tran  = '", tip_tran, "'"
	END IF
	LET vm_columna_1           = 2
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT r19_cod_tran, r19_num_tran, r19_nomcli, ",
					" r19_referencia ",
				" FROM rept019",
				" WHERE r19_compania  = ", cod_cia,
				"   AND r19_localidad = ", cod_loc,
				expr_tran CLIPPED,
				"   AND ", criterio CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE transac1 FROM query
		DECLARE q_transac1 CURSOR FOR transac1
		LET i = 1
		FOREACH q_transac1 INTO rh_transac[i].*
	        	LET i = i + 1
	        	IF i > filas_max THEN
	                	EXIT FOREACH
	       	 	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			LET i     = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                      "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_transac TO rh_transac.*
			ON KEY(F2)
				LET int_flag = 4
		                FOR i = 1 TO filas_pant
                	                CLEAR rh_transac[i].*
	                        END FOR
				EXIT DISPLAY
			ON KEY(RETURN)
                        	LET salir = 1
                        	EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
                	--#AFTER DISPLAY
                        	--#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
        	END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
                        	LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                       		LET vm_columna_1           = col
                	END IF
                	IF rm_orden[vm_columna_1] = 'ASC' THEN
                        	LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
                	INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_transac
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_transac[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_transac[1].* TO NULL
	RETURN rh_transac[1].r19_cod_tran, rh_transac[1].r19_num_tran,
		rh_transac[1].r19_nomcli 
END IF
LET i = arr_curr()
RETURN rh_transac[i].r19_cod_tran, rh_transac[i].r19_num_tran,
	rh_transac[i].r19_nomcli 

END FUNCTION



FUNCTION fl_ayuda_venta_taller_rep(cod_cia, cod_loc, tip_tran)
DEFINE rh_vtatal ARRAY[1000] OF RECORD
   	r19_cod_tran      	LIKE rept019.r19_cod_tran,
   	r19_num_tran      	LIKE rept019.r19_num_tran,
   	r19_nomcli  	    	LIKE rept019.r19_nomcli 
	END RECORD
DEFINE i		SMALLINT
DEFINE criterio	CHAR(600)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(600)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE j		SMALLINT
DEFINE tip_tran		LIKE rept019.r19_cod_tran

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_vtatal AT 06, 16 WITH 15 ROWS, 63 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf112 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf112'
ELSE
	OPEN FORM f_ayuf112 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf112c'
END IF
DISPLAY FORM f_ayuf112
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON 	r19_num_tran, r19_nomcli
	IF int_flag THEN
		CLOSE WINDOW w_vtatal
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
-----------

# Solo interesean las facturas (FA) y las requisiciones (RQ)
# Si por algun error se envía otro tipo de transacción como
# parámetro se mostrarán todos las facturas y requisiciones
IF tip_tran = '00' OR (tip_tran <> 'FA' AND tip_tran <> 'RQ') THEN 
        LET query = "SELECT r19_cod_tran, r19_num_tran, r19_nomcli ",
		    "	FROM rept019",
                                " WHERE r19_compania = ", cod_cia, " AND ",
			 	" r19_localidad = ",      cod_loc, " AND ",	
		   "(r19_cod_tran = 'FA' OR r19_cod_tran = 'RQ') AND ",
                  "r19_ord_trabajo IS NOT NULL AND ",
                                 criterio CLIPPED,  
        			" ORDER BY 1, 2 "
	PREPARE vtatal1 FROM query
	DECLARE q_vtatal1 CURSOR FOR vtatal1
	LET i = 1
	FOREACH q_vtatal1 INTO rh_vtatal[i].*
	        LET i = i + 1
	        IF i > filas_max THEN
	                EXIT FOREACH
	        END IF
	END FOREACH
END IF
---------
IF tip_tran = 'FA' OR tip_tran = 'RQ' THEN 
        LET query = "SELECT r19_cod_tran, r19_num_tran, r19_nomcli ",
		    "	FROM rept019",
                                " WHERE r19_compania = ", cod_cia, " AND ",
			 	" r19_localidad = ",      cod_loc, " AND ",	
		  " r19_cod_tran  = '", tip_tran, "' AND ",
                  "r19_ord_trabajo IS NOT NULL AND ",
                                 criterio CLIPPED,  
        			" ORDER BY 1, 2 "
	PREPARE vtatal2 FROM query
	DECLARE q_vtatal2 CURSOR FOR vtatal2
	LET i = 1
	FOREACH q_vtatal2 INTO rh_vtatal[i].*
	        LET i = i + 1
	        IF i > filas_max THEN
	                EXIT FOREACH
	        END IF
	END FOREACH
END IF
---------
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_vtatal TO rh_vtatal.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_vtatal
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_vtatal[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_vtatal[1].* TO NULL
	RETURN rh_vtatal[1].*
END IF
LET  i = arr_curr()
RETURN rh_vtatal[i].*

END FUNCTION



FUNCTION fl_ayuda_pedidos_rep(cod_cia, cod_loc, estado, tipo)
DEFINE rh_pedrep ARRAY[300] OF RECORD
   	r16_pedido      	LIKE rept016.r16_pedido,
	p01_nomprov		LIKE cxpt001.p01_nomprov,
        r16_estado      	LIKE rept016.r16_estado,
	r16_tipo		LIKE rept016.r16_tipo 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept016.r16_compania
DEFINE cod_loc		LIKE rept016.r16_localidad
DEFINE estado		LIKE rept016.r16_estado
DEFINE tipo		LIKE rept016.r16_tipo
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_estado 	CHAR(45)	
DEFINE query		CHAR(500)
                                                                                
LET filas_max  = 300
OPEN WINDOW wh_pedrep AT 06, 18 WITH 15 ROWS, 61 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf113 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf113'
ELSE
	OPEN FORM f_ayuf113 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf113c'
END IF
DISPLAY FORM f_ayuf113
LET filas_pant = fgl_scr_size('rh_pedrep')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF estado = 'A' THEN
	LET expr_estado = " r16_estado = ", "'A'"
END IF
IF estado = 'R' THEN
	LET expr_estado = " r16_estado = ", "'R'"
END IF
IF estado = 'L' THEN
	LET expr_estado = " r16_estado = ", "'L'"
END IF
IF estado = 'P' THEN
	LET expr_estado = " r16_estado = ", "'P'"
END IF
IF estado = 'C' THEN
	LET expr_estado = " r16_estado = ", "'C'"
END IF
IF estado = 'T' THEN
	LET expr_estado = " r16_estado IN ('A','R','L','P','C')"
END IF 
IF estado = 'Z' THEN
	LET expr_estado = " r16_estado IN ('R','C','P')"
END IF

IF tipo = 'S' THEN
	LET expr_tipo = " r16_tipo = ", "'S'"
END IF
IF tipo = 'E' THEN
	LET expr_tipo = " r16_tipo = ", "'E'"
END IF
IF tipo <> 'S' AND tipo <> 'E' THEN
	LET expr_tipo = " r16_tipo IN ('E','S')"
END IF 
LET query = "SELECT r16_pedido, p01_nomprov, r16_estado, r16_tipo FROM rept016, cxpt001 ",
		" WHERE r16_compania = ", cod_cia," AND ",
		" r16_localidad = ", cod_loc,     " AND ",
		" r16_proveedor =  p01_codprov ", " AND ",
		expr_estado CLIPPED, ' AND ',
		expr_tipo CLIPPED,
		' ORDER BY 1'
PREPARE pedrep FROM query
DECLARE q_pedrep CURSOR FOR pedrep
LET i = 1
FOREACH q_pedrep INTO rh_pedrep[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_pedrep
        INITIALIZE rh_pedrep[1].* TO NULL
        RETURN  rh_pedrep[1].r16_pedido
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_pedrep TO rh_pedrep.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_pedrep
IF int_flag THEN
        INITIALIZE rh_pedrep[1].* TO NULL
        RETURN  rh_pedrep[1].r16_pedido
END IF
LET  i = arr_curr()
RETURN  rh_pedrep[i].r16_pedido

END FUNCTION



FUNCTION fl_ayuda_liquidacion_rep(cod_cia, cod_loc, estado)
DEFINE rh_liqrep ARRAY[100] OF RECORD
   	r28_numliq      	LIKE rept028.r28_numliq,
   	r29_pedido      	LIKE rept029.r29_pedido,
        r28_estado      	LIKE rept028.r28_estado 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept028.r28_compania
DEFINE cod_loc		LIKE rept028.r28_localidad
DEFINE estado		LIKE rept028.r28_estado
DEFINE expr_estado 	CHAR(35)	
DEFINE query		CHAR(600)
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_liqrep AT 07, 41 WITH 15 ROWS, 30 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf114 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf114'
ELSE
	OPEN FORM f_ayuf114 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf114c'
END IF
DISPLAY FORM f_ayuf114
LET filas_pant = fgl_scr_size('rh_liqrep')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF estado = 'A' THEN
	LET expr_estado = " r28_estado = ", "'A'"
END IF
IF estado = 'P' THEN
	LET expr_estado = " r28_estado = ", "'P'"
END IF
IF estado <> 'A' AND estado <> 'P' THEN
	LET expr_estado = " r28_estado IN ('A','P')"
END IF 

LET query = "SELECT r28_numliq, r29_pedido, r28_estado FROM rept028, rept029 ",
		" WHERE r28_compania = ", cod_cia," AND ",
		" r28_localidad = ", cod_loc,     " AND ",
		expr_estado CLIPPED, 
                ' AND r28_compania  = r29_compania ',
                ' AND r28_localidad = r29_localidad ',
                ' AND r28_numliq    = r29_numliq    ',
		' ORDER BY 1'
PREPARE liqrep FROM query
DECLARE q_liqrep CURSOR FOR liqrep
LET i = 1
FOREACH q_liqrep INTO rh_liqrep[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_liqrep
        INITIALIZE rh_liqrep[1].* TO NULL
        RETURN  rh_liqrep[1].r28_numliq
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_liqrep TO rh_liqrep.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_liqrep
IF int_flag THEN
        INITIALIZE rh_liqrep[1].* TO NULL
        RETURN  rh_liqrep[1].r28_numliq
END IF
LET  i = arr_curr()
RETURN  rh_liqrep[i].r28_numliq

END FUNCTION



FUNCTION fl_ayuda_ordenes_compra(cod_cia, cod_loc, tipo, departamento, estado,
					modulo, ingresa) 
DEFINE cod_cia		LIKE ordt010.c10_compania
DEFINE cod_loc		LIKE ordt010.c10_localidad
DEFINE tipo	 	LIKE ordt010.c10_tipo_orden
DEFINE departamento 	LIKE ordt010.c10_cod_depto
DEFINE estado	 	LIKE ordt010.c10_estado
DEFINE modulo		LIKE ordt001.c01_modulo
DEFINE ingresa		LIKE ordt001.c01_ing_bodega
DEFINE rh_ordcom	ARRAY[10000] OF RECORD
			   	c10_numero_oc  	LIKE ordt010.c10_numero_oc,
			   	c01_nombre     	LIKE ordt001.c01_nombre,
			   	c10_ord_trabajo	LIKE ordt010.c10_ord_trabajo,
				c10_fecing	DATE,
			   	g34_nombre     	LIKE gent034.g34_nombre,
			   	c10_solicitado 	LIKE ordt010.c10_solicitado,
			   	c10_estado 	LIKE ordt010.c10_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE criterio		CHAR(700)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE expr_tipo	CHAR(50)
DEFINE expr_depto	CHAR(50)
DEFINE expr_estado	CHAR(50)
DEFINE expr_modulo	CHAR(50)
DEFINE expr_ingresa	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE ini_fil, num_fil	SMALLINT
DEFINE ini_col, num_col	SMALLINT

LET filas_max = 10000
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
LET ini_fil = 06
LET ini_col = 02
LET num_fil = 15
LET num_col = 79
IF vg_gui = 0 THEN
	LET ini_fil = 05
	LET ini_col = 02
	LET num_fil = 16
	LET num_col = 78
END IF
OPEN WINDOW w_ordcom AT ini_fil, ini_col WITH num_fil ROWS, num_col COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf115 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf115'
ELSE
	OPEN FORM f_ayuf115 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf115c'
END IF
DISPLAY FORM f_ayuf115
LET filas_pant = fgl_scr_size('rh_ordcom')
--#DISPLAY 'Ord. C.'		TO tit_col1
--#DISPLAY 'Tipo Ord. Comp.'	TO tit_col2
--#DISPLAY 'Ord. T.'		TO tit_col3
--#DISPLAY 'Fecha O.C.'		TO tit_col4
--#DISPLAY 'Departamento'	TO tit_col5
--#DISPLAY 'Solicitado Por'	TO tit_col6
--#DISPLAY 'E'			TO tit_col7
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON c10_numero_oc, c01_nombre,c10_ord_trabajo,
			g34_nombre, c10_solicitado
	IF int_flag THEN
		CLOSE WINDOW w_ordcom
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	IF tipo <> 0 THEN
		LET expr_tipo = " c10_tipo_orden =  ", tipo 
	END IF
	IF tipo = 0 THEN
		LET expr_tipo = " 1 = 1 "
	END IF
	IF departamento = 0 THEN
		LET expr_depto = " 1 = 1 "
	END IF
	IF departamento <> 0 THEN
		LET expr_depto = " c10_cod_depto =  ", departamento 
	END IF
	IF estado = 'T' THEN
		LET expr_estado = " 1 = 1 "
	END IF
	IF estado <> 'T' THEN
		LET expr_estado = " c10_estado = '", estado, "'"
	END IF
	IF modulo = '00' THEN
		LET expr_modulo = " 1 = 1 "
	END IF
	IF modulo <> '00' THEN
		LET expr_modulo = " c01_modulo = '", modulo, "'"
	END IF
	IF ingresa = 'T' THEN
		LET expr_ingresa = " 1 = 1 "
	END IF
	IF ingresa <> 'T' THEN
		LET expr_ingresa = " c01_ing_bodega = '", ingresa, "'"
	END IF
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
        	LET query = "SELECT c10_numero_oc, c01_nombre, ",
				"c10_ord_trabajo, DATE(c10_fecing), ",
				"g34_nombre, c10_solicitado, c10_estado ",
				" FROM ordt010, ordt001, gent034 ",
				" WHERE c10_compania   = ", cod_cia,
				"   AND c10_localidad  = ", cod_loc,
				"   AND ", expr_tipo CLIPPED,
				"   AND ", expr_depto CLIPPED,
				"   AND ", expr_estado CLIPPED,
				"   AND ", expr_modulo CLIPPED,
				"   AND ", expr_ingresa CLIPPED,
			        "   AND c01_tipo_orden = c10_tipo_orden ",
				"   AND g34_compania   = c10_compania ",
				"   AND g34_cod_depto  = c10_cod_depto ",
				"   AND ", criterio CLIPPED,
	                 	" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE ordcom FROM query
		DECLARE q_ordcom CURSOR FOR ordcom
		LET i = 1
		FOREACH q_ordcom INTO rh_ordcom[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_ordcom TO rh_ordcom.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
                		EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
				IF tipo = 0 THEN
        	                	LET col = 2
	                	        EXIT DISPLAY
				END IF
	                ON KEY(F17)
        	                LET col = 3
                	        EXIT DISPLAY
	                ON KEY(F18)
        	                LET col = 4
                	        EXIT DISPLAY
	                ON KEY(F19)
				IF departamento = 0 THEN
        	                	LET col = 5
	                	        EXIT DISPLAY
				END IF
	                ON KEY(F20)
        	                LET col = 6
                	        EXIT DISPLAY
	                ON KEY(F21)
				IF estado = 'T' THEN
        	                	LET col = 7
	                	        EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
        	                --#LET salir = 1
		END DISPLAY
        	IF int_flag = 4 OR int_flag = 1 THEN
                	EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
        	        IF rm_orden[vm_columna_1] = 'ASC' THEN
                	        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
	                INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_ordcom[i].* TO NULL
			CLEAR rh_ordcom[i].*
		END FOR
	END IF
	IF NOT salir THEN
       		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_ordcom
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ordcom[1].* TO NULL
	RETURN rh_ordcom[1].c10_numero_oc
END IF
LET  i = arr_curr()
RETURN rh_ordcom[i].c10_numero_oc

END FUNCTION



FUNCTION fl_ayuda_transaccion_cob(cod_cia, cod_loc)
DEFINE rh_trancob ARRAY[1000] OF RECORD
	z22_tipo_trn		LIKE cxct022.z22_tipo_trn,
	z22_num_trn		LIKE cxct022.z22_num_trn,
        z01_nomcli      	LIKE cxct001.z01_nomcli 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_sql 	CHAR(100)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxct022.z22_compania
DEFINE cod_loc		LIKE cxct022.z22_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_trancob AT 06, 27 WITH 15 ROWS, 52 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf116 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf116'
ELSE
	OPEN FORM f_ayuf116 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf116c'
END IF
DISPLAY FORM f_ayuf116
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z22_tipo_trn, z22_num_trn, z01_nomcli
	IF int_flag THEN
		CLOSE WINDOW w_trancob
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT z22_tipo_trn, z22_num_trn, z01_nomcli FROM cxct022, cxct001 ",
			"WHERE z22_compania =  ", cod_cia, " AND ",
			"z22_localidad = ", cod_loc, 	   " AND ",
			"z22_codcli = z01_codcli",         " AND ",
			 expr_sql CLIPPED,
			" ORDER BY 1"
	PREPARE trancob FROM query
	DECLARE q_trancob CURSOR FOR trancob
	LET i = 1
	FOREACH q_trancob INTO rh_trancob[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_trancob TO rh_trancob.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_trancob
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_trancob[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_trancob[1].* TO NULL
	RETURN rh_trancob[1].z22_num_trn
END IF
LET  i = arr_curr()
RETURN rh_trancob[i].z22_num_trn

END FUNCTION



FUNCTION fl_ayuda_doc_deudores_cob(cod_cia, cod_loc, cod_area, cod_cli, cod_doc)
DEFINE rh_deudacob	ARRAY[10000] OF RECORD
				z01_nomcli	LIKE cxct001.z01_nomcli,
				z20_tipo_doc	LIKE cxct020.z20_tipo_doc,
				z20_num_doc	LIKE cxct020.z20_num_doc,
				z20_dividendo	LIKE cxct020.z20_dividendo,
				z20_saldo	LIKE cxct020.z20_saldo_cap,
				z20_moneda	LIKE cxct020.z20_moneda,
				g03_abreviacion	LIKE gent003.g03_abreviacion
		        END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_area 	CHAR(45)	
DEFINE expr_cliente 	CHAR(45)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxct020.z20_compania
DEFINE cod_loc		LIKE cxct020.z20_localidad
DEFINE cod_area		LIKE cxct020.z20_areaneg
DEFINE cod_cli		LIKE cxct020.z20_codcli
DEFINE cod_doc		LIKE cxct020.z20_tipo_doc
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col, salir	SMALLINT
DEFINE tit_total	DECIMAL(12,2)

LET filas_max = 10000
OPEN WINDOW wh_deudacob AT 06, 02 WITH 15 ROWS, 77 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf117 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf117'
ELSE
	OPEN FORM f_ayuf117 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf117c'
END IF
DISPLAY FORM f_ayuf117
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Cliente'     TO bt_cliente
--#DISPLAY 'TP'          TO bt_tipo
--#DISPLAY 'Número'      TO bt_numero
--#DISPLAY 'Div'         TO bt_dividendo
--#DISPLAY 'Saldo'       TO bt_saldo
--#DISPLAY 'Mo'          TO bt_moneda
--#DISPLAY 'Area'        TO bt_area
LET filas_pant = fgl_scr_size('rh_deudacob')
LET int_flag   = 0
MESSAGE 'Seleccionando datos..' 
IF cod_doc = '00' THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_doc IS NULL  THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_doc <> '00' THEN
	LET expr_tipo = " z20_tipo_doc = '", cod_doc, "'"
END IF

IF cod_area IS NULL THEN
	LET expr_area = " 1 = 1 "
   ELSE
   	LET expr_area = " z20_areaneg = ", cod_area
END IF
IF cod_cli IS NULL THEN
	LET expr_cliente = " 1 = 1 "
   ELSE
   	LET expr_cliente = " z20_codcli = ", cod_cli
END IF
LET vm_columna_1           = 5
LET vm_columna_2           = 1
LET rm_orden[vm_columna_1] = 'DESC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir 
	LET query = "SELECT z01_nomcli, z20_tipo_doc, z20_num_doc, ",
			"z20_dividendo, (z20_saldo_cap + z20_saldo_int), ",
			"z20_moneda, g03_abreviacion ",
			"FROM cxct020, cxct001, gent003 ",
			"WHERE z20_compania  = ", cod_cia,
			"  AND g03_compania  = ", cod_cia,
			"  AND z20_compania  = g03_compania ",
			"  AND z20_localidad = ", cod_loc,
			"  AND z20_areaneg   = g03_areaneg ",
			"  AND z20_codcli    = z01_codcli ",
			"  AND ", expr_cliente,
			"  AND ", expr_tipo,
			"  AND ", expr_area,
			" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE deudacob FROM query
	DECLARE q_deudacob CURSOR FOR deudacob
	LET i         = 1
	LET tit_total = 0
	FOREACH q_deudacob INTO rh_deudacob[i].*
		LET tit_total = tit_total + rh_deudacob[i].z20_saldo
	        LET i         = i + 1
	        IF i > filas_max THEN
        	        EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CLOSE WINDOW wh_deudacob
		INITIALIZE rh_deudacob[1].* TO NULL
		RETURN rh_deudacob[1].z01_nomcli, rh_deudacob[1].z20_tipo_doc,
			rh_deudacob[1].z20_num_doc,rh_deudacob[1].z20_dividendo,
			rh_deudacob[1].z20_saldo, rh_deudacob[1].z20_moneda,
			rh_deudacob[1].g03_abreviacion
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	DISPLAY BY NAME tit_total
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_deudacob TO rh_deudacob.*
	        ON KEY(RETURN)
	        	LET salir = 1
	                EXIT DISPLAY
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
	        ON KEY(F20)
	                LET col = 6
	                EXIT DISPLAY
	        ON KEY(F21)
	                LET col = 7
	                EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE  j, ' de ', i
		--#AFTER DISPLAY
	        	--#LET salir = 1
	END DISPLAY
	IF int_flag AND col IS NULL THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
CLOSE WINDOW wh_deudacob
IF int_flag THEN
	INITIALIZE rh_deudacob[1].* TO NULL
	RETURN rh_deudacob[1].z01_nomcli, rh_deudacob[1].z20_tipo_doc,
		rh_deudacob[1].z20_num_doc, rh_deudacob[1].z20_dividendo,
		rh_deudacob[1].z20_saldo, rh_deudacob[1].z20_moneda,
		rh_deudacob[1].g03_abreviacion
END IF
LET i = arr_curr()
RETURN rh_deudacob[i].z01_nomcli, rh_deudacob[i].z20_tipo_doc,
	rh_deudacob[i].z20_num_doc, rh_deudacob[i].z20_dividendo,
	rh_deudacob[i].z20_saldo, rh_deudacob[i].z20_moneda,
	rh_deudacob[i].g03_abreviacion

END FUNCTION


 
FUNCTION fl_ayuda_doc_deudores_tes(cod_cia, cod_loc, cod_prov, cod_doc)
DEFINE rh_deudates ARRAY[1000] OF RECORD
        p01_nomprov      	LIKE cxpt001.p01_nomprov,
	p20_tipo_doc		LIKE cxpt020.p20_tipo_doc,
	p20_num_doc		LIKE cxpt020.p20_num_doc,
	p20_dividendo		LIKE cxpt020.p20_dividendo,
	p20_saldo_cap		LIKE cxpt020.p20_saldo_cap,
	p20_moneda		LIKE cxpt020.p20_moneda 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_proveedor 	CHAR(45)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxpt020.p20_compania
DEFINE cod_loc		LIKE cxpt020.p20_localidad
DEFINE cod_prov		LIKE cxpt020.p20_codprov
DEFINE cod_doc		LIKE cxpt020.p20_tipo_doc

LET filas_max  = 1000
OPEN WINDOW wh_deudates AT 06, 05 WITH 15 ROWS, 74 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf118 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf118'
ELSE
	OPEN FORM f_ayuf118 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf118c'
END IF
DISPLAY FORM f_ayuf118
LET filas_pant = fgl_scr_size('rh_deudates')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 

IF cod_doc = '00' THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_doc IS NULL  THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_doc <> '00' THEN
	LET expr_tipo = " p20_tipo_doc = '", cod_doc, "'"
END IF

IF cod_prov IS NULL THEN
	LET expr_proveedor = " 1 = 1 "
   ELSE
   	LET expr_proveedor = " p20_codprov = ", cod_prov
END IF
 
LET query =   "	SELECT 	p01_nomprov, p20_tipo_doc, ",
		" p20_num_doc, p20_dividendo, p20_saldo_cap,  p20_moneda ",
		" FROM   cxpt020, cxpt001",
               	" WHERE  p20_compania = ", cod_cia,
		" AND  p20_localidad= ", cod_loc,
		" AND  p20_codprov   =   p01_codprov ",
		" AND ", expr_proveedor, 
		" AND ", expr_tipo, 
        	' ORDER BY 2 '
PREPARE deudates FROM query
DECLARE q_deudates CURSOR FOR deudates
LET i = 1
FOREACH q_deudates INTO rh_deudates[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_deudates
        INITIALIZE rh_deudates[1].* TO NULL
        RETURN  rh_deudates[1].p01_nomprov,
	        rh_deudates[1].p20_tipo_doc, rh_deudates[1].p20_num_doc,
		rh_deudates[1].p20_dividendo,
	        rh_deudates[1].p20_saldo_cap,rh_deudates[1].p20_moneda 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_deudates TO rh_deudates.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_deudates
IF int_flag THEN
        INITIALIZE rh_deudates[1].* TO NULL
        RETURN  rh_deudates[1].p01_nomprov,
	        rh_deudates[1].p20_tipo_doc, rh_deudates[1].p20_num_doc,
		rh_deudates[1].p20_dividendo,
	        rh_deudates[1].p20_saldo_cap,rh_deudates[1].p20_moneda 
END IF
LET  i = arr_curr()
RETURN  rh_deudates[i].p01_nomprov,
        rh_deudates[i].p20_tipo_doc, rh_deudates[i].p20_num_doc,
	rh_deudates[i].p20_dividendo,
        rh_deudates[i].p20_saldo_cap,rh_deudates[i].p20_moneda 

END FUNCTION

 

FUNCTION fl_ayuda_doc_favor_tes(cod_cia, cod_loc, cod_prov, cod_doc)
DEFINE rh_favortes	ARRAY[10000] OF RECORD
				p01_nomprov    	LIKE cxpt001.p01_nomprov,
				p21_tipo_doc	LIKE cxpt021.p21_tipo_doc,
				p21_num_doc	LIKE cxpt021.p21_num_doc,
				p21_saldo	LIKE cxpt021.p21_saldo,
				p21_moneda	LIKE cxpt021.p21_moneda 
			END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_area 	CHAR(45)	
DEFINE expr_proveedor 	CHAR(45)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxpt021.p21_compania
DEFINE cod_loc		LIKE cxpt021.p21_localidad
DEFINE cod_prov		LIKE cxpt021.p21_codprov
DEFINE cod_doc		LIKE cxpt021.p21_tipo_doc
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col, salir	SMALLINT
DEFINE tit_total	DECIMAL(12,2)

LET filas_max = 10000
OPEN WINDOW wh_favortes AT 06, 19 WITH 16 ROWS, 60 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf119 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf119'
ELSE
	OPEN FORM f_ayuf119 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf119c'
END IF
DISPLAY FORM f_ayuf119
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Proveedor'   TO bt_proveedor
--#DISPLAY 'TP'          TO bt_tipo
--#DISPLAY 'Número'      TO bt_numero
--#DISPLAY 'Saldo'       TO bt_saldo
--#DISPLAY 'Mo'          TO bt_moneda
LET filas_pant = fgl_scr_size('rh_favortes')
LET int_flag   = 0
MESSAGE 'Seleccionando datos..' 
IF cod_doc IS NULL THEN
	LET expr_tipo = " 1 = 1 "
   ELSE
	LET expr_tipo = " p21_tipo_doc = '", cod_doc, "'"
END IF
IF cod_doc = '00' THEN
	LET expr_tipo = " 1 = 1 "
END IF
IF cod_prov IS NULL THEN
	LET expr_proveedor = " 1 = 1 "
   ELSE
   	LET expr_proveedor = " p21_codprov = ", cod_prov
END IF
LET vm_columna_1           = 4
LET vm_columna_2           = 1
LET rm_orden[vm_columna_1] = 'DESC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir 
	LET query = "SELECT p01_nomprov, p21_tipo_doc, p21_num_doc, p21_saldo,",
				" p21_moneda ",
			" FROM cxpt021, cxpt001 ",
	               	" WHERE p21_compania  = ", cod_cia,
			"   AND p21_localidad = ", cod_loc,
			"   AND p21_codprov   = p01_codprov ",
			"   AND ", expr_proveedor, 
			"   AND ", expr_tipo, 
			" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE favortes FROM query
	DECLARE q_favortes CURSOR FOR favortes
	LET i         = 1
	LET tit_total = 0
	FOREACH q_favortes INTO rh_favortes[i].*
		LET tit_total = tit_total + rh_favortes[i].p21_saldo
	        LET i         = i + 1
	        IF i > filas_max THEN
	                EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
	        CALL fl_mensaje_consulta_sin_registros()
	        CLOSE WINDOW wh_favortes
	        INITIALIZE rh_favortes[1].* TO NULL
		RETURN rh_favortes[1].p01_nomprov, rh_favortes[1].p21_tipo_doc,
			rh_favortes[1].p21_num_doc, rh_favortes[1].p21_saldo,
			rh_favortes[1].p21_moneda
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	DISPLAY BY NAME tit_total
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY rh_favortes TO rh_favortes.*
	        ON KEY(RETURN)
	        	LET salir = 1
	                EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE  j, ' de ', i
		--#AFTER DISPLAY
	        	--#LET salir = 1
	END DISPLAY
	IF int_flag AND col IS NULL THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
CLOSE WINDOW wh_favortes
IF int_flag THEN
        INITIALIZE rh_favortes[1].* TO NULL
	RETURN rh_favortes[1].p01_nomprov, rh_favortes[1].p21_tipo_doc,
		rh_favortes[1].p21_num_doc, rh_favortes[1].p21_saldo,
		rh_favortes[1].p21_moneda
END IF
LET i = arr_curr()
RETURN rh_favortes[i].p01_nomprov, rh_favortes[i].p21_tipo_doc,
	rh_favortes[i].p21_num_doc, rh_favortes[i].p21_saldo,
	rh_favortes[i].p21_moneda

END FUNCTION

 

FUNCTION fl_ayuda_transaccion_tes(cod_cia, cod_loc)
DEFINE rh_trantes ARRAY[1000] OF RECORD
	p22_tipo_trn		LIKE cxpt022.p22_tipo_trn,
	p22_num_trn		LIKE cxpt022.p22_num_trn,
        p01_nomprov      	LIKE cxpt001.p01_nomprov 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_sql 	CHAR(100)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxpt022.p22_compania
DEFINE cod_loc		LIKE cxpt022.p22_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_trantes AT 06, 27 WITH 15 ROWS, 52 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf120 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf120'
ELSE
	OPEN FORM f_ayuf120 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf120c'
END IF
DISPLAY FORM f_ayuf120
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p22_tipo_trn, p22_num_trn, p01_nomprov
	IF int_flag THEN
		CLOSE WINDOW w_trantes
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT p22_tipo_trn, p22_num_trn, p01_nomprov FROM cxpt022, cxpt001 ",
			"WHERE p22_compania =  ", cod_cia, " AND ",
			"p22_localidad = ", cod_loc, 	   " AND ",
			"p22_codprov = p01_codprov",       " AND ",
			 expr_sql CLIPPED,
			" ORDER BY 1"
	PREPARE trantes FROM query
	DECLARE q_trantes CURSOR FOR trantes
	LET i = 1
	FOREACH q_trantes INTO rh_trantes[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_trantes TO rh_trantes.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_trantes
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_trantes[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_trantes[1].* TO NULL
	RETURN rh_trantes[1].p22_num_trn
END IF
LET  i = arr_curr()
RETURN rh_trantes[i].p22_num_trn

END FUNCTION



FUNCTION fl_ayuda_retenciones(cod_cia, codigo_pago, estado)
DEFINE cod_cia		LIKE ordt002.c02_compania
DEFINE codigo_pago	LIKE cajt091.j91_codigo_pago
DEFINE estado		LIKE ordt002.c02_estado
DEFINE rh_ret		ARRAY[500] OF RECORD
				c02_tipo_ret	LIKE ordt002.c02_tipo_ret,
				c02_porcentaje	LIKE ordt002.c02_porcentaje,
				c02_nombre	LIKE ordt002.c02_nombre,
				c02_tipo_fuente	LIKE ordt002.c02_tipo_fuente,
				c02_estado	LIKE ordt002.c02_estado
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_sql		CHAR(600)
DEFINE tabla		CHAR(15)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_pag		VARCHAR(250)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_ret AT 06, 42 WITH num_fil ROWS, 37 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf121 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf121'
ELSE
	OPEN FORM f_ayuf121 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf121c'
END IF
DISPLAY FORM f_ayuf121
--#DISPLAY "R"			TO tit_col1
--#DISPLAY "%"			TO tit_col2
--#DISPLAY 'Descripción'	TO tit_col3
--#DISPLAY "T"			TO tit_col4
--#DISPLAY "E"			TO tit_col5
LET primera  = 1
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND c02_estado      = "', estado, '"'
END IF
LET tabla    = NULL
LET expr_pag = NULL
IF codigo_pago IS NOT NULL THEN
	LET tabla    = ', cajt091'
	LET expr_pag = '   AND j91_compania    = c02_compania ',
			'   AND j91_codigo_pago = "', codigo_pago, '"',
			--'   AND j91_cont_cred   = ',
			'   AND j91_tipo_ret    = c02_tipo_ret ',
			'   AND j91_porcentaje  = c02_porcentaje '
END IF
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON c02_tipo_ret, c02_porcentaje,
			c02_nombre, c02_tipo_fuente, c02_estado
		IF int_flag THEN
			CLOSE WINDOW wh_ret
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT UNIQUE c02_tipo_ret, c02_porcentaje,',
				' c02_nombre, c02_tipo_fuente, c02_estado ',
			' FROM ordt002', tabla CLIPPED,
			' WHERE c02_compania = ', cod_cia,
				expr_est CLIPPED,
				expr_pag CLIPPED,
			'   AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE ret FROM query
		DECLARE q_ret CURSOR FOR ret
		LET i = 1
		FOREACH q_ret INTO rh_ret[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i     = 0
			LET salir = 1
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE '                                           '
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_ret TO rh_ret.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_ret[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ret
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_ret[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ret[1].* TO NULL
        RETURN rh_ret[1].c02_tipo_ret, rh_ret[1].c02_porcentaje,
               rh_ret[1].c02_nombre
END IF
LET i = arr_curr()
RETURN rh_ret[i].c02_tipo_ret, rh_ret[i].c02_porcentaje,
       rh_ret[i].c02_nombre

END FUNCTION



FUNCTION fl_ayuda_casas_comerciales(cod_cia)
DEFINE cod_cia			INTEGER
DEFINE rh_almacen ARRAY[100] OF RECORD
        n62_cod_almacen       	LIKE rolt062.n62_cod_almacen,
        n62_nombre      	LIKE rolt062.n62_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_almacen AT 06, 38 WITH 15 ROWS, 41 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf150 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf150'
ELSE
	OPEN FORM f_ayuf150 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf150c'
END IF
DISPLAY FORM f_ayuf150
LET filas_pant = fgl_scr_size('rh_almacen')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_almacen CURSOR FOR
        SELECT n62_cod_almacen, n62_nombre FROM rolt062
		WHERE n62_compania = cod_cia
  	        ORDER BY 1
LET i = 1
FOREACH qh_almacen INTO rh_almacen[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_almacen
        INITIALIZE rh_almacen[1].* TO NULL
        RETURN rh_almacen[1].n62_cod_almacen, rh_almacen[1].n62_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_almacen TO rh_almacen.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_almacen
IF int_flag THEN
        INITIALIZE rh_almacen[1].* TO NULL
        RETURN rh_almacen[1].n62_cod_almacen, rh_almacen[1].n62_nombre
END IF
LET  i = arr_curr()
RETURN rh_almacen[i].n62_cod_almacen, rh_almacen[i].n62_nombre

END FUNCTION



FUNCTION fl_ayuda_procesos_roles()
DEFINE rh_procesos_roles ARRAY[1000] OF RECORD
				n03_proceso	LIKE rolt003.n03_proceso,
				n03_nombre	LIKE rolt003.n03_nombre
			END RECORD
DEFINE i, j, col, salir	SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE actt010.a10_compania
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE primera		SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_procesos_roles AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf122 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf122'
ELSE
	OPEN FORM f_ayuf122 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf122c'
END IF
DISPLAY FORM f_ayuf122
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Proceso'       	 TO bt_proceso
--#DISPLAY 'Descripcion'	 TO bt_descripcion
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON n03_proceso, n03_nombre
		IF int_flag THEN
			CLOSE WINDOW w_procesos_roles
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 2
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT n03_proceso, n03_nombre ",
				" FROM rolt003 ",
				" WHERE n03_estado = 'A'",
				"   AND ", expr_sql CLIPPED,
                    		"ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",
					rm_orden[vm_columna_2]
		PREPARE procesos_roles FROM query
		DECLARE q_procesos_roles CURSOR FOR procesos_roles
		LET i = 1
		FOREACH q_procesos_roles INTO rh_procesos_roles[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
        	IF i = 0 THEN
                	CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
        	        EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_procesos_roles TO rh_procesos_roles.*
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
                	ON KEY(F15)
                        	LET col = 1
	                        EXIT DISPLAY
        	        ON KEY(F16)
                	        LET col = 2
                        	EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			ON KEY(RETURN)
				LET salir = 1
                		EXIT DISPLAY
	                --#AFTER DISPLAY
        	                --#LET salir = 1
		END DISPLAY
        	IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
	                EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
        	                LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
        	        IF rm_orden[vm_columna_1] = 'ASC' THEN
                	        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
        	        INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_procesos_roles[i].* TO NULL
			CLEAR rh_procesos_roles[i].*
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_procesos_roles
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_procesos_roles[1].* TO NULL
	RETURN rh_procesos_roles[1].*
END IF
LET i = arr_curr()
RETURN rh_procesos_roles[i].n03_proceso, rh_procesos_roles[i].n03_nombre

END FUNCTION
 


FUNCTION fl_ayuda_rubros_generales_roles(det_tot, can_val, calculo, ing_usu, imprime, con_col)
DEFINE rh_rubrol ARRAY[200] OF RECORD
        n06_cod_rubro      	LIKE rolt006.n06_cod_rubro,
	n06_nombre		LIKE rolt006.n06_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE det_tot		LIKE rolt006.n06_det_tot
DEFINE can_val		LIKE rolt006.n06_cant_valor
DEFINE calculo		LIKE rolt006.n06_calculo
DEFINE ing_usu		LIKE rolt006.n06_ing_usuario
DEFINE imprime		LIKE rolt006.n06_imprime_0
DEFINE con_col		LIKE rolt006.n06_cont_colect
DEFINE expr_det_tot	CHAR(50)
DEFINE expr_can_val	CHAR(50)
DEFINE expr_calculo	CHAR(50)
DEFINE expr_ing_usu	CHAR(50)
DEFINE expr_imprime	CHAR(50)
DEFINE expr_con_col	CHAR(50)


LET filas_max  = 200
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_rubrol AT 06,23 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf123'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
--#DISPLAY "Cod."		TO bt_codigo
--#DISPLAY "Descripcion"	TO bt_nombre
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n06_cod_rubro, n06_nombre
	IF int_flag THEN
		CLOSE WINDOW w_rubrol
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_det_tot = " 1 = 1 "
	IF det_tot <> '00' THEN
		LET expr_det_tot = " n06_det_tot = '", det_tot, "'"
	END IF
	LET expr_can_val = " 1 = 1 "
	IF can_val <> 'T' THEN
		LET expr_can_val = " n06_cant_valor = '", can_val, "'"
	END IF
	LET expr_calculo = " 1 = 1 "
	IF calculo <> 'T' THEN
		LET expr_calculo = " n06_calculo = '", calculo, "'"
	END IF
	LET expr_ing_usu = " 1 = 1 "
	IF ing_usu <> 'T' THEN
		LET expr_ing_usu = " n06_ing_usuario = '", ing_usu, "'"
	END IF
	LET expr_imprime = " 1 = 1 "
	IF imprime <> 'T' THEN
		LET expr_imprime = " n06_imprime_0 = '", imprime, "'"
	END IF
	LET expr_con_col = " 1 = 1 "
	IF con_col <> 'T' THEN
		LET expr_con_col = " n06_cont_colect = '", con_col, "'"
	END IF

	LET query = "SELECT n06_cod_rubro, n06_nombre FROM rolt006 ",
				" WHERE n06_estado = 'A' AND ",	
				 expr_det_tot CLIPPED, " AND ",
				 expr_can_val CLIPPED, " AND ",
				 expr_calculo CLIPPED, " AND ",
				 expr_ing_usu CLIPPED, " AND ",
				 expr_imprime CLIPPED, " AND ",
				 expr_con_col CLIPPED, " AND ",
				 expr_sql CLIPPED ,
				 ' ORDER BY 2'
	PREPARE rubrol FROM query
	DECLARE q_rubrol CURSOR FOR rubrol
	LET i = 1
	FOREACH q_rubrol INTO rh_rubrol[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_rubrol TO rh_rubrol.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY

	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_rubrol
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_rubrol[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_rubrol[1].* TO NULL
	RETURN rh_rubrol[1].*
END IF
LET  i = arr_curr()
RETURN rh_rubrol[i].*

END FUNCTION



FUNCTION fl_ayuda_ordenes_pago_prov(cod_cia, cod_loc, estado)
DEFINE rh_pagprov ARRAY[1000] OF RECORD
        p24_orden_pago      	LIKE cxpt024.p24_orden_pago,
	p01_nomprov		LIKE cxpt001.p01_nomprov 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE cxpt024.p24_compania
DEFINE cod_loc		LIKE cxpt024.p24_localidad
DEFINE estado		LIKE cxpt024.p24_estado
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_pagprov AT 06, 41 WITH 15 ROWS, 38 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf124 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf124'
ELSE
	OPEN FORM f_ayuf124 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf124c'
END IF
DISPLAY FORM f_ayuf124
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Orden'     TO bt_orden
--#DISPLAY 'Proveedor' TO bt_proveedor
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p24_orden_pago, p01_nomprov
	IF int_flag THEN
		CLOSE WINDOW w_pagprov
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " p24_estado = '", estado, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT p24_orden_pago, p01_nomprov FROM cxpt024, cxpt001 ",
			"WHERE p24_compania =  ", cod_cia, " AND ",
			"p24_localidad = ", cod_loc, 	   " AND ",
			"p24_codprov = p01_codprov ", 	   " AND ",
				 expr_estado CLIPPED,      " AND ",
				 expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE pagprov FROM query
        DECLARE q_pagprov CURSOR FOR pagprov
        LET i = 1
        FOREACH q_pagprov INTO rh_pagprov[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
        
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_pagprov TO rh_pagprov.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_pagprov[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_pagprov
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_pagprov[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_pagprov[1].* TO NULL
	RETURN rh_pagprov[1].p24_orden_pago
END IF
LET  i = arr_curr()
RETURN rh_pagprov[i].p24_orden_pago

END FUNCTION



FUNCTION fl_ayuda_ubicaciones(cod_cia, bodega)
DEFINE rh_ubica ARRAY[1000] OF RECORD
        r11_ubicacion      	LIKE rept011.r11_ubicacion 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept011.r11_compania
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_ubica AT 06,42 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf125'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
		   
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

DISPLAY 'Ubicacion'     TO bt_orden
		   
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r11_ubicacion
	IF int_flag THEN
		CLOSE WINDOW w_ubica
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r11_ubicacion FROM rept011 ",
			"WHERE r11_compania =  ", cod_cia, " AND ",
			"r11_bodega = ", bodega, 	   " AND ",
				 expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE ubica FROM query
        DECLARE q_ubica CURSOR FOR ubica
        LET i = 1
        FOREACH q_ubica INTO rh_ubica[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
        
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_ubica TO rh_ubica.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_ubica[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_ubica
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_ubica[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ubica[1].* TO NULL
	RETURN rh_ubica[1].r11_ubicacion
END IF
LET  i = arr_curr()
RETURN rh_ubica[i].r11_ubicacion

END FUNCTION



FUNCTION fl_ayuda_sublinea_rep(cod_cia, linea)
DEFINE rh_sublin	ARRAY[500] OF RECORD
			        r70_sub_linea	LIKE rept070.r70_sub_linea,
				r70_desc_sub	LIKE rept070.r70_desc_sub, 
				r03_nombre	LIKE rept003.r03_nombre
		        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept070.r70_compania
DEFINE linea		LIKE rept070.r70_linea
--DEFINE nom_linea	LIKE rept003.r03_nombre
DEFINE expr_linea	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 500
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_sublin AT 06, 12 WITH 15 ROWS, 67 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf127 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf127'
ELSE
	OPEN FORM f_ayuf127 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf127c'
END IF
DISPLAY FORM f_ayuf127
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Sub Línea'     TO bt_sublinea
--#DISPLAY 'Descripción'   TO bt_descripcion
--#DISPLAY 'Línea'         TO bt_linea
		   
WHILE TRUE
{--
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r70_sub_linea, r70_desc_sub
	IF int_flag THEN
		CLOSE WINDOW w_sublin
		EXIT WHILE
	END IF
--}
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_linea = " 1 = 1 "
	IF linea IS NOT NULL THEN
		LET expr_linea = " r70_linea = '", linea, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r70_sub_linea, r70_desc_sub, r03_nombre FROM rept070, rept003 ",
			"WHERE r70_compania =  ", cod_cia, " AND ",
			"r70_compania = r03_compania", 	   " AND ",
			"r70_linea = r03_codigo ", 	   " AND ",
				 --expr_sql CLIPPED ,        " AND ",
				 expr_linea CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE sublin FROM query
        DECLARE q_sublin CURSOR FOR sublin
        LET i = 1
        FOREACH q_sublin INTO rh_sublin[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_sublin TO rh_sublin.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_sublin[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF NOT salir AND int_flag = 4 THEN
        --CONTINUE WHILE
        EXIT WHILE
END IF
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_sublin
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_sublin[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_sublin[1].* TO NULL
	RETURN rh_sublin[1].r70_sub_linea, rh_sublin[1].r70_desc_sub 
END IF
LET  i = arr_curr()
RETURN rh_sublin[i].r70_sub_linea, rh_sublin[i].r70_desc_sub 

END FUNCTION



FUNCTION fl_ayuda_grupo_ventas_rep(cod_cia, linea, sublinea)
DEFINE rh_codgrupo	ARRAY[500] OF RECORD
        			r71_cod_grupo	LIKE rept071.r71_cod_grupo,
				r71_desc_grupo	LIKE rept071.r71_desc_grupo 
        		END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept071.r71_compania
DEFINE linea		LIKE rept071.r71_linea
DEFINE sublinea		LIKE rept071.r71_sub_linea
DEFINE expr_linea	CHAR(50)
DEFINE expr_grupo	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 500
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codgrupo AT 06, 29 WITH 15 ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf128 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf128'
ELSE
	OPEN FORM f_ayuf128 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf128c'
END IF
DISPLAY FORM f_ayuf128
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Grupo'         TO bt_grupo
--#DISPLAY 'Descripción'   TO bt_descripcion
		   
WHILE TRUE
{--
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r71_cod_grupo, r71_desc_grupo
	IF int_flag THEN
		CLOSE WINDOW w_codgrupo
		EXIT WHILE
	END IF
--}
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_linea = " 1 = 1 "
	IF linea IS NOT NULL THEN
		LET expr_linea = " r71_linea = '", linea, "'"
	END IF
	LET expr_grupo = " 1 = 1 "
	IF sublinea IS NOT NULL THEN
		LET expr_grupo = " r71_sub_linea = '", sublinea, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r71_cod_grupo, r71_desc_grupo ",
			"FROM rept071, rept070 ",
			"WHERE r71_compania =  ", cod_cia, " AND ",
			"r71_compania  = r70_compania",   " AND ",
			"r71_linea     = r70_linea ",  " AND ",
			"r71_sub_linea = r70_sub_linea ",  " AND ",
				 --expr_sql CLIPPED ,        " AND ",
				 expr_linea CLIPPED ,	   " AND ",
				 expr_grupo CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE codgrupo FROM query
        DECLARE q_codgrupo CURSOR FOR codgrupo
        LET i = 1
        FOREACH q_codgrupo INTO rh_codgrupo[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_codgrupo TO rh_codgrupo.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_codgrupo[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF NOT salir AND int_flag = 4 THEN
        --CONTINUE WHILE
	EXIT WHILE
END IF
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_codgrupo
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_codgrupo[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codgrupo[1].* TO NULL
	RETURN rh_codgrupo[1].r71_cod_grupo, rh_codgrupo[1].r71_desc_grupo
END IF
LET  i = arr_curr()
RETURN rh_codgrupo[i].r71_cod_grupo, rh_codgrupo[i].r71_desc_grupo

END FUNCTION

 

FUNCTION fl_ayuda_clase_ventas_rep(cod_cia, linea, sublinea, codgrupo)
DEFINE rh_codclase ARRAY[1000] OF RECORD
        r72_cod_clase      	LIKE rept072.r72_cod_clase,
	r72_desc_clase		LIKE rept072.r72_desc_clase 
	END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept072.r72_compania
DEFINE linea 		LIKE rept072.r72_linea
DEFINE sublinea 	LIKE rept072.r72_sub_linea
DEFINE codgrupo 	LIKE rept072.r72_cod_grupo
DEFINE expr_linea	CHAR(50)
DEFINE expr_sublinea	CHAR(50)
DEFINE expr_clase	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codclase AT 06, 16 WITH 15 ROWS, 63 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf129 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf129'
ELSE
	OPEN FORM f_ayuf129 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf129c'
END IF
DISPLAY FORM f_ayuf129
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Clase'         TO bt_clase
--#DISPLAY 'Descripción'   TO bt_descripcion
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r72_cod_clase, r72_desc_clase
	IF int_flag THEN
		CLOSE WINDOW w_codclase
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_linea = " 1 = 1 "
	IF linea IS NOT NULL THEN
		LET expr_linea = " r72_linea = '", linea, "'"
	END IF
	LET expr_sublinea = " 1 = 1 "
	IF sublinea IS NOT NULL THEN
		LET expr_sublinea = " r72_sub_linea = '", sublinea, "'"
	END IF
	LET expr_clase = " 1 = 1 "
	IF codgrupo IS NOT NULL THEN
		LET expr_clase = " r72_cod_grupo = '", codgrupo, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r72_cod_clase, r72_desc_clase FROM rept072, rept071 ",
			"WHERE r72_compania =  ", cod_cia, " AND ",
			"r72_compania = r71_compania", 	   " AND ",
			"r72_cod_grupo = r71_cod_grupo ",  " AND ",
				 expr_sql CLIPPED ,        " AND ",
				 expr_linea CLIPPED ,      " AND ",
				 expr_sublinea CLIPPED ,   " AND ",
				 expr_clase CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE codclase FROM query
        DECLARE q_codclase CURSOR FOR codclase
        LET i = 1
        FOREACH q_codclase INTO rh_codclase[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_codclase TO rh_codclase.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_codclase[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_codclase
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_codclase[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codclase[1].* TO NULL
	RETURN rh_codclase[1].r72_cod_clase, rh_codclase[1].r72_desc_clase
END IF
LET  i = arr_curr()
RETURN rh_codclase[i].r72_cod_clase, rh_codclase[i].r72_desc_clase

END FUNCTION



FUNCTION fl_ayuda_marcas_rep(cod_cia)
DEFINE rh_marcasrep ARRAY[500] OF RECORD
   	r73_marca      	 	LIKE rept073.r73_marca,
        r73_desc_marca      	LIKE rept073.r73_desc_marca
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE cod_cia 		LIKE veht001.v01_compania
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
                                                                                
LET filas_max  = 500
OPEN WINDOW wh_marcasrep AT 06, 41 WITH 15 ROWS, 38 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf130 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf130'
ELSE
	OPEN FORM f_ayuf130 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf130c'
END IF
DISPLAY FORM f_ayuf130
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Nombre'     TO bt_nombre

LET filas_pant = fgl_scr_size('rh_marcasrep')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET query = " SELECT r73_marca, r73_desc_marca FROM rept073 ",
			" WHERE r73_compania =  ", cod_cia, 
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE marcasrep FROM query
DECLARE q_marcasrep CURSOR FOR marcasrep
--------------
LET i = 1
FOREACH q_marcasrep INTO rh_marcasrep[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_marcasrep
        INITIALIZE rh_marcasrep[1].* TO NULL
        RETURN rh_marcasrep[1].r73_marca
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_marcasrep TO rh_marcasrep.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
        ON KEY(F15)
                LET col = 1
                EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_marcasrep
IF int_flag THEN
        INITIALIZE rh_marcasrep[1].* TO NULL
        RETURN rh_marcasrep[1].r73_marca
END IF
LET  i = arr_curr()
RETURN rh_marcasrep[i].r73_marca

END FUNCTION



FUNCTION fl_ayuda_marcas_rep_asignadas(cod_cia, clase)
DEFINE rh_marcasrep ARRAY[500] OF RECORD
   	r73_marca      	 	LIKE rept073.r73_marca,
        r73_desc_marca      	LIKE rept073.r73_desc_marca
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE cod_cia 		LIKE veht001.v01_compania
DEFINE clase		LIKE rept072.r72_cod_clase
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE expr_clase       CHAR(80)
                                                                                
LET filas_max  = 500
OPEN WINDOW wh_marcasrep AT 06, 41 WITH 15 ROWS, 38 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf130 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf130'
ELSE
	OPEN FORM f_ayuf130 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf130c'
END IF
DISPLAY FORM f_ayuf130
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Nombre'     TO bt_nombre

LET filas_pant = fgl_scr_size('rh_marcasrep')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET expr_clase = ' AND  1 = 1 '
IF clase IS NOT NULL THEN
	LET expr_clase = " AND r10_cod_clase = '", clase CLIPPED, "' "
END IF
LET query = " SELECT UNIQUE r10_marca, r73_desc_marca FROM rept010, rept073 ",
		" WHERE r10_compania =  ", cod_cia, " AND ",
		"       r10_compania = r73_compania ",
		expr_clase, 
		" AND r10_marca = r73_marca ",
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE chepo FROM query
DECLARE q_chepo CURSOR FOR chepo
--------------
LET i = 1
FOREACH q_chepo INTO rh_marcasrep[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_marcasrep
        INITIALIZE rh_marcasrep[1].* TO NULL
        RETURN rh_marcasrep[1].r73_marca
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_marcasrep TO rh_marcasrep.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
        ON KEY(F15)
                LET col = 1
                EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_marcasrep
IF int_flag THEN
        INITIALIZE rh_marcasrep[1].* TO NULL
        RETURN rh_marcasrep[1].r73_marca
END IF
LET  i = arr_curr()
RETURN rh_marcasrep[i].r73_marca

END FUNCTION



FUNCTION fl_ayuda_orden_despacho(cod_cia, cod_loc, bodega, estado)
DEFINE rh_orddespacho ARRAY[1000] OF RECORD
        r34_num_ord_des      	LIKE rept034.r34_num_ord_des,
	r34_cod_tran		LIKE rept034.r34_cod_tran, 
	r34_num_tran		LIKE rept034.r34_num_tran,
	r34_fec_estrega		LIKE rept034.r34_fec_entrega,
	r34_entregar_a		LIKE rept034.r34_entregar_a,
	r34_bodega		LIKE rept034.r34_bodega
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept034.r34_compania
DEFINE cod_loc		LIKE rept034.r34_localidad
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE estado 		LIKE rept034.r34_estado
DEFINE expr_despacho	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE vm_columna_6     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_orddespacho AT 06, 07 WITH 15 ROWS, 72 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf131 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf131'
ELSE
	OPEN FORM f_ayuf131 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf131c'
END IF
DISPLAY FORM f_ayuf131
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Orden'      TO bt_orden
--#DISPLAY 'TP'		TO bt_tipo
--#DISPLAY 'Factura'    TO bt_factura
--#DISPLAY 'Fecha'  	TO bt_fecha
--#DISPLAY 'Cliente' 	TO bt_cliente
--#DISPLAY 'Bd'  	TO bt_bodega
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r34_num_ord_des, r34_cod_tran,
        			      r34_num_tran,    r34_fec_entrega,  
				      r34_entregar_a,  r34_bodega 
	IF int_flag THEN
		CLOSE WINDOW w_orddespacho
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_despacho = " 1 = 1 "
	IF estado IS NOT NULL  THEN
		LET expr_despacho = " r34_estado = '", estado, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET vm_columna_4 = 4
LET vm_columna_5 = 5
LET vm_columna_6 = 6
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r34_num_ord_des, r34_cod_tran, r34_num_tran, r34_fec_entrega, r34_entregar_a, r34_bodega FROM rept034 ",
			"WHERE r34_compania =  ", cod_cia, " AND ",
				 expr_sql CLIPPED ,        " AND ",
				 expr_despacho CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE orddespacho FROM query
        DECLARE q_orddespacho CURSOR FOR orddespacho
        LET i = 1
        FOREACH q_orddespacho INTO rh_orddespacho[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_orddespacho TO rh_orddespacho.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_orddespacho[i].*
                        END FOR
                        EXIT DISPLAY
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
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_orddespacho
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_orddespacho[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_orddespacho[1].* TO NULL
	RETURN rh_orddespacho[1].r34_bodega,  
	       rh_orddespacho[1].r34_num_ord_des 
END IF
LET  i = arr_curr()
RETURN rh_orddespacho[i].r34_bodega,  
       rh_orddespacho[i].r34_num_ord_des 

END FUNCTION



FUNCTION fl_ayuda_conciliacion(cod_cia, estado)
DEFINE rh_concilia ARRAY[1000] OF RECORD
        b30_num_concil      	LIKE ctbt030.b30_num_concil,
        b30_estado      	LIKE ctbt030.b30_estado,
	g08_nombre		LIKE gent008.g08_nombre, 
	b30_numero_cta		LIKE ctbt030.b30_numero_cta,
	b30_aux_cont		LIKE ctbt030.b30_aux_cont 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE cod_cia 		LIKE ctbt030.b30_compania
DEFINE estado		LIKE ctbt030.b30_estado
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
                                                                                
LET filas_max  = 1000
OPEN WINDOW wh_concilia AT 06, 19 WITH 15 ROWS, 60 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf132 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf132'
ELSE
	OPEN FORM f_ayuf132 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf132c'
END IF
DISPLAY FORM f_ayuf132
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Número'     TO bt_numero
--#DISPLAY 'Estado'     TO bt_estado
--#DISPLAY 'Banco'      TO bt_banco
--#DISPLAY 'Cuenta'     TO bt_cuenta
--#DISPLAY 'Auxiliar'   TO bt_auxiliar

LET filas_pant = fgl_scr_size('rh_concilia')
LET int_flag = 0
-----------
	LET expr_estado = " 1 = 1 "
	IF estado IS NOT NULL  THEN
		LET expr_estado = " b30_estado = '", estado, "'"
	END IF
-----------
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET vm_columna_4 = 4
LET vm_columna_5 = 5
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET query = " SELECT b30_num_concil, b30_estado, g08_nombre, b30_numero_cta, b30_aux_cont  FROM ctbt030, gent008 ",
			" WHERE b30_compania =  ", cod_cia, " AND ",
			" b30_banco = g08_banco ", " AND ",
			" b30_num_concil <> 0 ", " AND ", 
			 expr_estado CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE concilia FROM query
DECLARE q_concilia CURSOR FOR concilia
--------------

LET i = 1
FOREACH q_concilia INTO rh_concilia[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_concilia
        INITIALIZE rh_concilia[1].* TO NULL
        RETURN rh_concilia[1].b30_num_concil
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_concilia TO rh_concilia.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
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
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_concilia
IF int_flag THEN
        INITIALIZE rh_concilia[1].* TO NULL
        RETURN rh_concilia[1].b30_num_concil
END IF
LET  i = arr_curr()
RETURN rh_concilia[i].b30_num_concil

END FUNCTION



FUNCTION fl_ayuda_electrico_rep(cod_cia, estado)
DEFINE rh_electrico ARRAY[1000] OF RECORD
        r74_electrico      	LIKE rept074.r74_electrico,
	r74_descripcion		LIKE rept074.r74_descripcion,  
	r74_estado		LIKE rept074.r74_estado  
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept074.r74_compania
DEFINE estado		LIKE rept074.r74_estado
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE vm_columna_6     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_electrico AT 06, 04 WITH 15 ROWS, 60 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf133 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf133'
ELSE
	OPEN FORM f_ayuf133 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf133c'
END IF
DISPLAY FORM f_ayuf133
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Eléctrico'        		TO bt_codigo
--#DISPLAY 'Descripción Eléctrico'	TO bt_descripcion
--#DISPLAY 'Estado'  			TO bt_estado
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r74_electrico, 	r74_descripcion,
        			      r74_estado
	IF int_flag THEN
		CLOSE WINDOW w_electrico
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " r74_estado = '", estado, "'"
	END IF
	
---------------
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET vm_columna_3 = 4
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r74_electrico, r74_descripcion, ",
			" r74_estado FROM rept074 ",
			"WHERE r74_compania =  ", cod_cia, " AND ",
				 expr_sql CLIPPED ,        " AND ",
				 expr_estado CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE electrico FROM query
        DECLARE q_electrico CURSOR FOR electrico
        LET i = 1
        FOREACH q_electrico INTO rh_electrico[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_electrico TO rh_electrico.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_electrico[i].*
                        END FOR
                        EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_electrico
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_electrico[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_electrico[1].* TO NULL
	RETURN rh_electrico[1].r74_electrico, rh_electrico[1].r74_descripcion  
END IF
LET  i = arr_curr()
RETURN rh_electrico[i].r74_electrico, rh_electrico[i].r74_descripcion  

END FUNCTION



FUNCTION fl_ayuda_color_rep(cod_cia, item, marca, estado)
DEFINE rh_color ARRAY[1000] OF RECORD
        r75_color      		LIKE rept075.r75_color,
	r75_descripcion		LIKE rept075.r75_descripcion,  
	r75_estado		LIKE rept075.r75_estado  
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept075.r75_compania
DEFINE item		LIKE rept075.r75_item
DEFINE marca		LIKE rept075.r75_marca
DEFINE estado		LIKE rept075.r75_estado
DEFINE expr_item	CHAR(50)
DEFINE expr_marca	CHAR(50)
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE vm_columna_6     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_color AT 06, 22 WITH 15 ROWS, 57 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf134 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf134'
ELSE
	OPEN FORM f_ayuf134 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf134c'
END IF
DISPLAY FORM f_ayuf134
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Código'        	TO bt_color
--#DISPLAY 'Descripción Color'	TO bt_descripcion
--#DISPLAY 'Estado'  		TO bt_estado
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r75_color, r75_descripcion, r75_estado
	IF int_flag THEN
		CLOSE WINDOW w_color
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_item = " 1 = 1 "
	IF item IS NOT NULL THEN
		LET expr_item = " r75_item = '", item, "'"
	END IF
	LET expr_marca = " 1 = 1 "
	IF marca IS NOT NULL THEN
		LET expr_marca = " r75_marca = '", marca, "'"
	END IF
	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " r75_estado = '", estado, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r75_color, r75_descripcion, r75_estado ",
			"FROM rept075 ",
			"WHERE r75_compania =  ", cod_cia, " AND ",
				 expr_sql CLIPPED ,        " AND ",
				 expr_item CLIPPED ,       " AND ",
				 expr_marca CLIPPED ,      " AND ",
				 expr_estado CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE colores FROM query
        DECLARE q_color_pant CURSOR FOR colores
        LET i = 1
        FOREACH q_color_pant INTO rh_color[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_color TO rh_color.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_color[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)	
			LET col = 2  
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF vg_gui = 0 THEN
        	LET salir = 1
	END IF
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_color
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_color[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_color[1].* TO NULL
	RETURN rh_color[1].r75_color, rh_color[1].r75_descripcion  
END IF
LET  i = arr_curr()
RETURN rh_color[i].r75_color, rh_color[i].r75_descripcion  

END FUNCTION



FUNCTION fl_ayuda_serie_rep(cod_cia, cod_loc, bodega, item, estado)
DEFINE rh_serie ARRAY[1000] OF RECORD
	r76_item		LIKE rept076.r76_item,  
	r10_nombre		LIKE rept010.r10_nombre,  
        r76_serie      		LIKE rept076.r76_serie,
	r76_fecing		LIKE rept076.r76_fecing  
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept076.r76_compania
DEFINE cod_loc		LIKE rept076.r76_localidad
DEFINE bodega		LIKE rept076.r76_bodega
DEFINE item		LIKE rept076.r76_item
DEFINE estado		LIKE rept076.r76_estado
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE expr_bodega	CHAR(50)
DEFINE expr_item	CHAR(50)
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE vm_columna_6     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_serie AT 06, 2 WITH 15 ROWS, 78 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf135 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf135'
ELSE
	OPEN FORM f_ayuf135 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf135c'
END IF
DISPLAY FORM f_ayuf135
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Item'		TO bt_item
--#DISPLAY 'Descripción'	TO bt_descripcion
--#DISPLAY 'Series' 	   	TO bt_serie
--#DISPLAY 'Fecha Ingreso'	TO bt_fecha
		   
WHILE TRUE
{--
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r76_item, r76_serie, r76_fecing
	IF int_flag THEN
		CLOSE WINDOW w_serie
		EXIT WHILE
	END IF
--}
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_bodega = " 1 = 1 "
	IF bodega IS NOT NULL THEN
		LET expr_bodega = " r76_bodega = '", bodega, "'"
	END IF
	LET expr_item = " 1 = 1 "
	IF item IS NOT NULL THEN
		LET expr_item = " r76_item = '", item, "'"
	END IF
	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " r76_estado = '", estado, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r76_item, r76_serie, r76_fecing ",
			"FROM rept076 ",
			"WHERE r76_compania =  ", cod_cia, " AND ",
				 expr_bodega CLIPPED ,     " AND ",
				 expr_item CLIPPED ,       " AND ",
				 expr_estado CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE series FROM query
        DECLARE q_series CURSOR FOR series
        LET i = 1
        FOREACH q_series INTO rh_serie[i].r76_item, rh_serie[i].r76_serie,
				rh_serie[i].r76_fecing
		CALL fl_lee_item(cod_cia, rh_serie[i].r76_item)
			RETURNING r_r10.*
		LET rh_serie[i].r10_nombre = r_r10.r10_nombre
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_serie TO rh_serie.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_serie[i].*
                        END FOR
                        EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF vg_gui = 0 THEN
        	LET salir = 1
	END IF
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_serie
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_serie[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_serie[1].* TO NULL
	RETURN rh_serie[1].r76_serie, rh_serie[1].r76_fecing  
END IF
LET  i = arr_curr()
RETURN rh_serie[i].r76_serie, rh_serie[i].r76_fecing  

END FUNCTION
 


FUNCTION fl_ayuda_factor_utilidad_rep(cod_cia)
DEFINE rh_factor ARRAY[1000] OF RECORD
        r77_codigo_util   	LIKE rept077.r77_codigo_util,
	r77_multiplic		LIKE rept077.r77_multiplic,  
	r77_dscmax_ger		LIKE rept077.r77_dscmax_ger,
	r77_dscmax_jef		LIKE rept077.r77_dscmax_jef,
	r77_dscmax_ven		LIKE rept077.r77_dscmax_ven
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept077.r77_compania
DEFINE expr_item	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE vm_columna_6     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_factor_utl AT 06, 33 WITH 15 ROWS, 46 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf136 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf136'
ELSE
	OPEN FORM f_ayuf136 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf136c'
END IF
DISPLAY FORM f_ayuf136
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Código'    	TO bt_codigo_util
--#DISPLAY 'Multip.'	TO bt_multiplic
--#DISPLAY 'D. Ger.'  	TO bt_dscmax_ger
--#DISPLAY 'D. Jef.'  	TO bt_dscmax_jef
--#DISPLAY 'D. Ven.'  	TO bt_dscmax_ven
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r77_codigo_util, r77_multiplic,
			r77_dscmax_ger, r77_dscmax_jef, r77_dscmax_ven
	IF int_flag THEN
		CLOSE WINDOW w_factor_utl
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_item = " 1 = 1 "
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r77_codigo_util, r77_multiplic, r77_dscmax_ger, ",
			"r77_dscmax_jef, r77_dscmax_ven ",
			"FROM rept077 ",
			"WHERE r77_compania =  ", cod_cia, " AND ",
				 expr_sql CLIPPED ,        " AND ",
				 expr_item CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE factor_util FROM query
        DECLARE q_factor_util CURSOR FOR factor_util
        LET i = 1
        FOREACH q_factor_util INTO rh_factor[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_factor TO rh_factor.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_factor[i].*
                        END FOR
                        EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF vg_gui = 0 THEN
        	LET salir = 1
	END IF
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_factor_utl
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_factor[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_factor[1].* TO NULL
	RETURN rh_factor[1].r77_codigo_util
END IF
LET  i = arr_curr()
RETURN rh_factor[i].r77_codigo_util

END FUNCTION



FUNCTION fl_ayuda_grupo_activo(cod_cia)
DEFINE rh_grupoact	ARRAY[50] OF RECORD
				a01_grupo_act	LIKE actt001.a01_grupo_act,
				a01_nombre	LIKE actt001.a01_nombre
			END RECORD
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE actt001.a01_compania
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_max  = 50
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_grupoact AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf137 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf137'
ELSE
	OPEN FORM f_ayuf137 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf137c'
END IF
DISPLAY FORM f_ayuf137
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Grupo'       TO bt_grupoact
--#DISPLAY 'Descripción' TO bt_nombre
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON a01_grupo_act, a01_nombre
		IF int_flag THEN
			CLOSE WINDOW w_grupoact
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	-----------------
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT a01_grupo_act, a01_nombre FROM actt001 ",
				" WHERE a01_compania = ", cod_cia," AND ", 
				 expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE grupoact FROM query
		DECLARE q_grupoact CURSOR FOR grupoact
		LET i = 1
		FOREACH q_grupoact INTO rh_grupoact[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
        	IF i = 0 THEN
	                CALL fl_mensaje_consulta_sin_registros()
        	        LET salir = 0
                	EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		---------------
		DISPLAY ARRAY rh_grupoact TO rh_grupoact.*
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
        	                LET col = 2
                	        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			ON KEY(RETURN)
				LET salir = 1
        	        	EXIT DISPLAY
	                --#AFTER DISPLAY
        	                --#LET salir = 1
		END DISPLAY
        	IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
	                EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
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
	                INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_grupoact[i].* TO NULL
			CLEAR rh_grupoact[i].*
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_grupoact
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_grupoact[1].* TO NULL
	RETURN rh_grupoact[1].*
END IF
LET i = arr_curr()
RETURN rh_grupoact[i].a01_grupo_act, rh_grupoact[i].a01_nombre

END FUNCTION
 


FUNCTION fl_ayuda_tipo_activo(cod_cia, grupo)
DEFINE cod_cia		LIKE actt002.a02_compania
DEFINE grupo		LIKE actt002.a02_grupo_act
DEFINE rh_tipoact	ARRAY[1000] OF RECORD
				a02_grupo_act	LIKE actt002.a02_grupo_act,
				a02_tipo_act	LIKE actt002.a02_tipo_act,
				a02_nombre	LIKE actt002.a02_nombre
			END RECORD
DEFINE i, j, col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1500)	## Contiene todo el query preparado
DEFINE expr_grp		VARCHAR(100)
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPEN WINDOW w_tipoact AT 06, 38 WITH 14 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf138 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf138'
ELSE
	OPEN FORM f_ayuf138 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf138c'
END IF
DISPLAY FORM f_ayuf138
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'GR'   	 TO tit_col1
--#DISPLAY 'Tipo'   	 TO tit_col2
--#DISPLAY 'Descripcion' TO tit_col3
LET expr_grp = NULL
IF grupo IS NOT NULL THEN
	LET expr_grp = '   AND a02_grupo_act = ', grupo
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON a02_tipo_act, a02_nombre
		IF int_flag THEN
			CLOSE WINDOW w_tipoact
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT a02_grupo_act, a02_tipo_act, a02_nombre',
				' FROM actt002 ',
				' WHERE a02_compania  = ', cod_cia,
					expr_grp CLIPPED,
				'   AND ', expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE tipoact FROM query
		DECLARE q_tipoact CURSOR FOR tipoact
		LET i = 1
		FOREACH q_tipoact INTO rh_tipoact[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		MESSAGE "                                           "
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_tipoact TO rh_tipoact.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_tipoact[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 3
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_tipoact[i].* TO NULL
			CLEAR rh_tipoact[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_tipoact
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tipoact[1].* TO NULL
	RETURN rh_tipoact[1].a02_tipo_act, rh_tipoact[1].a02_nombre
END IF
LET i = arr_curr()
RETURN rh_tipoact[i].a02_tipo_act, rh_tipoact[i].a02_nombre

END FUNCTION

 

FUNCTION fl_ayuda_responsable(cod_cia)

DEFINE rh_responsable ARRAY[1000] OF RECORD
	a03_responsable	LIKE actt003.a03_responsable,
	a03_nombres	LIKE actt003.a03_nombres
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE actt003.a03_compania
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_responsable AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf139 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf139'
ELSE
	OPEN FORM f_ayuf139 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf139c'
END IF
DISPLAY FORM f_ayuf139
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'       	 TO bt_codigo
--#DISPLAY 'Nombres'		 TO bt_nombres

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON a03_responsable, a03_nombres
	IF int_flag THEN
		CLOSE WINDOW w_responsable
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT a03_responsable, a03_nombres FROM actt003 ",
				" WHERE a03_compania = ", cod_cia," AND ", 
				 expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE responsable FROM query
	DECLARE q_responsable CURSOR FOR responsable
	LET i = 1
	FOREACH q_responsable INTO rh_responsable[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_responsable TO rh_responsable.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF int_flag = 4 THEN
	FOR i = 1 TO filas_pant
		INITIALIZE rh_responsable[i].* TO NULL
		CLEAR rh_responsable[i].*
	END FOR
END IF
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_responsable
	EXIT WHILE
END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_responsable[1].* TO NULL
	RETURN rh_responsable[1].*
END IF
LET  i = arr_curr()
RETURN rh_responsable[i].a03_responsable, rh_responsable[i].a03_nombres

END FUNCTION
 


FUNCTION fl_ayuda_codigo_bien(cod_cia, grupo, tipo, estado, flag)
DEFINE cod_cia		LIKE actt010.a10_compania
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE tipo		LIKE actt010.a10_tipo_act
DEFINE estado		LIKE actt010.a10_estado
DEFINE flag		SMALLINT
DEFINE rh_codigo_bien	ARRAY[10000] OF RECORD
				a10_grupo_act	LIKE actt010.a10_grupo_act,
				a10_tipo_act	LIKE actt010.a10_tipo_act,
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_estado	LIKE actt010.a10_estado
			END RECORD
DEFINE i, j, col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1500)	## Contiene todo el query preparado
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPEN WINDOW w_codigo_bien AT 06, 19 WITH 14 ROWS, 60 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf140 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf140'
ELSE
	OPEN FORM f_ayuf140 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf140c'
END IF
DISPLAY FORM f_ayuf140
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'GR'   	 TO tit_col1
--#DISPLAY 'Tipo'   	 TO tit_col2
--#DISPLAY 'Codigo'   	 TO tit_col3
--#DISPLAY 'Descripcion' TO tit_col4
--#DISPLAY 'E'		 TO tit_col5
LET expr_grp = NULL
IF grupo IS NOT NULL THEN
	LET expr_grp = '   AND a10_grupo_act = ', grupo
END IF
LET expr_tip = NULL
IF tipo IS NOT NULL THEN
	LET expr_tip = '   AND a10_tipo_act  = ', tipo
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON a10_codigo_bien, a10_descripcion
		IF int_flag THEN
			CLOSE WINDOW w_codigo_bien
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 2
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT a10_grupo_act, a10_tipo_act, ',
				'a10_codigo_bien, a10_descripcion, a10_estado ',
				'FROM actt010 ',
				' WHERE a10_compania  = ', cod_cia,
					expr_grp CLIPPED,
					expr_tip CLIPPED,
					fl_retorna_expr_estado_act(cod_cia,
								estado, flag),
				'   AND ', expr_sql CLIPPED,
				' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE codigo_bien FROM query
		DECLARE q_codigo_bien CURSOR FOR codigo_bien
		LET i = 1
		FOREACH q_codigo_bien INTO rh_codigo_bien[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			EXIT WHILE
		END IF
		MESSAGE "                                           "
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_codigo_bien TO rh_codigo_bien.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_codigo_bien[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_codigo_bien[i].* TO NULL
			CLEAR rh_codigo_bien[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_codigo_bien
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codigo_bien[1].* TO NULL
	RETURN rh_codigo_bien[1].a10_codigo_bien,
		rh_codigo_bien[1].a10_descripcion
END IF
LET i = arr_curr()
RETURN rh_codigo_bien[i].a10_codigo_bien, rh_codigo_bien[i].a10_descripcion

END FUNCTION
 


FUNCTION fl_ayuda_capitulo()

DEFINE rh_capitulo ARRAY[1000] OF RECORD
	g38_capitulo	LIKE gent038.g38_capitulo,
	g38_desc_cap	LIKE gent038.g38_desc_cap
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE actt010.a10_compania
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_capitulo AT 06, 36 WITH 15 ROWS, 43 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf141 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf141'
ELSE
	OPEN FORM f_ayuf141 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf141c'
END IF
DISPLAY FORM f_ayuf141
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Capítulo'       	 TO bt_capitulo
--#DISPLAY 'Descripción'	 TO bt_descripcion

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON g38_capitulo, g38_desc_cap
	IF int_flag THEN
		CLOSE WINDOW w_capitulo
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT g38_capitulo, g38_desc_cap FROM gent038 ",
				" WHERE " , expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE capitulo FROM query
	DECLARE q_capitulo CURSOR FOR capitulo
	LET i = 1
	FOREACH q_capitulo INTO rh_capitulo[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_capitulo TO rh_capitulo.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF int_flag = 4 THEN
	FOR i = 1 TO filas_pant
		INITIALIZE rh_capitulo[i].* TO NULL
		CLEAR rh_capitulo[i].*
	END FOR
END IF
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_capitulo
	EXIT WHILE
END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_capitulo[1].* TO NULL
	RETURN rh_capitulo[1].*
END IF
LET  i = arr_curr()
RETURN rh_capitulo[i].g38_capitulo, rh_capitulo[i].g38_desc_cap

END FUNCTION



FUNCTION fl_ayuda_mostrar_meses()
DEFINE i		SMALLINT
DEFINE r_meses		ARRAY [12] OF RECORD
				tit_mes		SMALLINT,
				tit_mes_des	CHAR(11)
			END RECORD

OPEN WINDOW w_mes AT 06, 60
        WITH FORM '../../LIBRERIAS/forms/ayuf305'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
DISPLAY 'No.' TO tit_col1
DISPLAY 'Mes' TO tit_col2
FOR i = 1 TO 12
	LET r_meses[i].tit_mes = i
	CALL fl_retorna_nombre_mes(i) RETURNING r_meses[i].tit_mes_des
END FOR
CALL set_count(12)
LET int_flag = 0
DISPLAY ARRAY r_meses TO r_meses.*
	ON KEY(INTERRUPT)
		LET i = arr_curr()
		LET r_meses[i].tit_mes     = NULL
		LET r_meses[i].tit_mes_des = NULL
		EXIT DISPLAY
	ON KEY(RETURN)
		LET i = arr_curr()
		EXIT DISPLAY
	--#AFTER DISPLAY
		--#LET i = arr_curr()
END DISPLAY
CLOSE WINDOW w_mes
RETURN r_meses[i].*

END FUNCTION



FUNCTION fl_ayuda_tran_activos(cod_cia, cod_tran)
DEFINE cod_cia		LIKE actt012.a12_compania
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE rh_tran_activos	ARRAY[1000] OF RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_codigo_bien	LIKE actt012.a12_codigo_bien,
			        a12_referencia	LIKE actt012.a12_referencia
			END RECORD
DEFINE i		SMALLINT
DEFINE expr_tran	CHAR(100)
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(600)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_tran_activos AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf142 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf142'
ELSE
	OPEN FORM f_ayuf142 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf142c'
END IF
DISPLAY FORM f_ayuf142
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Tp'	       	 TO bt_codigo_tran
--#DISPLAY 'Número'    	 TO bt_numero_tran
--#DISPLAY 'Activo'    	 TO bt_codigo_bien
--#DISPLAY 'Referencia'	 TO bt_referencia
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	a12_numero_tran, a12_codigo_bien, 
					a12_referencia
	IF int_flag THEN
		CLOSE WINDOW w_tran_activos
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------------
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col, expr_tran TO NULL
	IF cod_tran <> 'T' THEN
		LET expr_tran = '  AND a12_codigo_tran = "', cod_tran, '"'
	END IF
	LET salir = 0

	WHILE NOT salir
	LET query = "SELECT a12_codigo_tran, a12_numero_tran, a12_codigo_bien,",
			" a12_referencia ",
			" FROM actt012 ",
			" WHERE a12_compania = ", cod_cia,
				 expr_tran CLIPPED,
			" AND ", expr_sql CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE tran_activos FROM query
	DECLARE q_tran_activos CURSOR FOR tran_activos
	LET i = 1
	FOREACH q_tran_activos INTO rh_tran_activos[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_tran_activos TO rh_tran_activos.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
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
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
	END WHILE

	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_tran_activos[i].* TO NULL
			CLEAR rh_tran_activos[i].*
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_tran_activos
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tran_activos[1].* TO NULL
	RETURN rh_tran_activos[1].*
END IF
LET  i = arr_curr()
RETURN rh_tran_activos[i].*

END FUNCTION
 

FUNCTION fl_ayuda_subtitulos(cia)
DEFINE rh_subtitulos ARRAY[1000] OF RECORD
        r83_cod_desc_item  	LIKE rept083.r83_cod_desc_item,
--        r83_item    	  	LIKE rept083.r83_item,
	r84_descripcion		LIKE rept084.r84_descripcion  
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE cia		LIKE rept083.r83_compania
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
                                                                                
LET filas_max  = 1000
OPEN WINDOW wh_subtitulos AT 06, 19  WITH 15 ROWS, 60 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf143 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf143'
ELSE
	OPEN FORM f_ayuf143 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf143c'
END IF
DISPLAY FORM f_ayuf143
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Sec'        TO bt_cod_desc_item
--##DISPLAY 'Item'       TO bt_item
--#DISPLAY 'Descripción'TO bt_descripcion

LET filas_pant = fgl_scr_size('rh_subtitulos')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
--LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
--LET query = " SELECT r83_cod_desc_item, r83_item, r84_descripcion ",
LET query = " SELECT r84_cod_desc_item, r84_descripcion ",
			" FROM rept084 ",
			" WHERE r84_compania =  ", vg_codcia, --" AND ",
			--" r83_compania = r84_compania ", " AND ",
			--" r83_cod_desc_item = r84_cod_desc_item ", 
                    "ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
                           ", ", vm_columna_2, " ", rm_orden[vm_columna_2]
PREPARE subtitulos FROM query
DECLARE q_subtitulos CURSOR FOR subtitulos
--------------

LET i = 1
FOREACH q_subtitulos INTO rh_subtitulos[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_subtitulos
        INITIALIZE rh_subtitulos[1].* TO NULL
        RETURN rh_subtitulos[1].r83_cod_desc_item
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subtitulos TO rh_subtitulos.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
	ON KEY(F15)
		LET col = 1
		EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	ON KEY(F17)	
		LET col = 3  
		EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_subtitulos
IF int_flag THEN
        INITIALIZE rh_subtitulos[1].* TO NULL
        RETURN rh_subtitulos[1].r83_cod_desc_item
END IF
LET  i = arr_curr()
RETURN rh_subtitulos[i].r83_cod_desc_item

END FUNCTION



FUNCTION fl_ayuda_nota_pedido(cia)
DEFINE rh_notapedido ARRAY[1000] OF RECORD
        r81_pedido  		LIKE rept081.r81_pedido,
	r81_nom_prov		LIKE rept081.r81_nom_prov  
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE cia		LIKE rept083.r83_compania
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
                                                                                
LET filas_max  = 1000
OPEN WINDOW wh_notapedido AT 06, 12  WITH 15 ROWS, 67 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf144 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf144'
ELSE
	OPEN FORM f_ayuf144 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf144c'
END IF
DISPLAY FORM f_ayuf144
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Pedido'        TO bt_pedido
--#DISPLAY 'Proveedor'     TO bt_proveedor

LET filas_pant = fgl_scr_size('rh_notapedido')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET query = " SELECT r81_pedido, r81_nom_prov ",
			" FROM rept081 ",
			" WHERE r81_compania =  ", vg_codcia, 
                    "ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
                           ", ", vm_columna_2, " ", rm_orden[vm_columna_2]
PREPARE notapedido FROM query
DECLARE q_notapedido CURSOR FOR notapedido
--------------

LET i = 1
FOREACH q_notapedido INTO rh_notapedido[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_notapedido
        INITIALIZE rh_notapedido[1].* TO NULL
        RETURN rh_notapedido[1].r81_pedido,rh_notapedido[1].r81_nom_prov
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_notapedido TO rh_notapedido.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
	ON KEY(F15)
		LET col = 1
		EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_notapedido
IF int_flag THEN
        INITIALIZE rh_notapedido[1].* TO NULL
        RETURN rh_notapedido[1].r81_pedido,rh_notapedido[1].r81_nom_prov
END IF
LET  i = arr_curr()
RETURN rh_notapedido[i].r81_pedido,rh_notapedido[i].r81_nom_prov

END FUNCTION



FUNCTION fl_ayuda_presupuestos_taller(cod_cia, cod_loc, estado)
DEFINE cod_cia		LIKE talt020.t20_compania
DEFINE cod_loc		LIKE talt020.t20_localidad
DEFINE estado		LIKE talt020.t20_estado
DEFINE rh_pretal	ARRAY[10000] OF RECORD
			        t20_numpre	LIKE talt020.t20_numpre,
			        t20_cod_cliente	LIKE talt020.t20_cod_cliente,
			        t20_nom_cliente	LIKE talt020.t20_nom_cliente
		        END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE expr_estado      CHAR(65)
DEFINE query		CHAR(800)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE ini_col, num_col	SMALLINT

LET filas_max  = 10000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
LET ini_col = 16
LET num_col = 63
IF vg_gui = 1 THEN
	LET ini_col = 22
	LET num_col = 58
END IF
OPEN WINDOW w_pretal AT 06, ini_col WITH 15 ROWS, num_col COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf063 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf063'
ELSE
	OPEN FORM f_ayuf063 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf063c'
END IF
DISPLAY FORM f_ayuf063
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Presup'    	 TO bt_presupuesto
--#DISPLAY 'Cliente'   	 TO bt_cliente
--#DISPLAY 'Nombre'    	 TO bt_nombre
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	t20_numpre, t20_cod_cliente, 
					t20_nom_cliente
	IF int_flag THEN
		CLOSE WINDOW w_pretal
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------------
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col, expr_estado TO NULL
-------
        LET expr_estado = " 1 = 1 "
        IF estado = 'A' THEN
                LET expr_estado = " t20_estado  = '", estado, "'"
        END IF
        IF estado = 'P' THEN
                LET expr_estado = " t20_estado  = '", estado, "'"
        END IF
        IF estado = 'T' THEN
                LET expr_estado = " t20_estado   IN ('A','P')"
        END IF
----------
	LET salir = 0

	WHILE NOT salir
	LET query = "SELECT t20_numpre, t20_cod_cliente, t20_nom_cliente ",
			" FROM talt020 ",
			" WHERE t20_compania  = ", cod_cia,
			"   AND t20_localidad = ", cod_loc,
		        "   AND ", expr_estado,
			"   AND ", expr_sql CLIPPED ,
                    " ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
                           ", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE pretal FROM query
	DECLARE q_pretal CURSOR FOR pretal
	LET i = 1
	FOREACH q_pretal INTO rh_pretal[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_pretal TO rh_pretal.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
                	LET salir    = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
	END WHILE

	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_pretal[i].* TO NULL
			CLEAR rh_pretal[i].*
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_pretal
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_pretal[1].* TO NULL
	RETURN rh_pretal[1].*
END IF
LET  i = arr_curr()
RETURN rh_pretal[i].*

END FUNCTION



FUNCTION fl_ayuda_seguros(estado)
DEFINE estado		LIKE rolt013.n13_estado
DEFINE rh_seguro	ARRAY[100] OF RECORD
				n13_cod_seguro	LIKE rolt013.n13_cod_seguro,
				n13_descripcion	LIKE rolt013.n13_descripcion,
				n13_porc_trab	LIKE rolt013.n13_porc_trab
			END RECORD
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_tran		CHAR(30)
DEFINE expr_sql		CHAR(300)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_seguro AT 06, 32 WITH 15 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf145 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf145'
ELSE
	OPEN FORM f_ayuf145 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf145c'
END IF
DISPLAY FORM f_ayuf145
LET filas_max = 100
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Código'		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY '%'			TO tit_col3
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n13_cod_seguro, n13_descripcion,
					n13_porc_trab
	IF int_flag THEN
		CLOSE WINDOW w_seguro
		EXIT WHILE
	END IF
	CASE estado
		WHEN 'A'
			LET expr_tran = ' n13_estado = "A"'
		WHEN 'B'
			LET expr_tran = ' n13_estado = "B"'
		WHEN 'T'
			LET expr_tran = ' n13_estado IN ("A", "B")'
	END CASE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n13_cod_seguro, n13_descripcion, ',
				' n13_porc_trab ',
				' FROM rolt013 ',
				' WHERE ', expr_tran CLIPPED,
				'   AND ', expr_sql CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE seguro FROM query
		DECLARE q_seguro CURSOR FOR seguro
		LET i = 1
		FOREACH q_seguro INTO rh_seguro[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_seguro TO rh_seguro.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_seguro')
			CLEAR rh_seguro[i].*
			INITIALIZE rh_seguro[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_seguro
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_seguro[1].* TO NULL
	RETURN rh_seguro[1].n13_cod_seguro, rh_seguro[1].n13_descripcion
END IF
LET i = arr_curr()
RETURN rh_seguro[i].n13_cod_seguro, rh_seguro[i].n13_descripcion

END FUNCTION



FUNCTION fl_ayuda_anticipos(cia, estado)
DEFINE rh_prestamo	ARRAY[1000] OF RECORD
				n45_num_prest	LIKE rolt045.n45_num_prest,
				n30_nombres	LIKE rolt030.n30_nombres,
				n45_estado	LIKE rolt045.n45_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE cia		LIKE rolt045.n45_compania
DEFINE estado		LIKE rolt045.n45_estado
DEFINE expr_sql		CHAR(500)
DEFINE expr_tranado	CHAR(300)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_prestamo AT 06, 31 WITH 15 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf146 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf146'
ELSE
	OPEN FORM f_ayuf146 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf146c'
END IF
DISPLAY FORM f_ayuf146
LET filas_max = 1000
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Anticipo'	TO tit_col1
--#DISPLAY 'Empleado'	TO tit_col2
--#DISPLAY 'E'		TO tit_col3
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n45_num_prest, n30_nombres, n45_estado
	IF int_flag THEN
		CLOSE WINDOW w_prestamo
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
----------
        IF estado = 'X' THEN
                LET expr_tranado = " 1 = 1 "
        END IF
        IF estado <> 'X' THEN
                LET expr_tranado = " n45_estado = '", estado, "'"
        END IF
----------
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n45_num_prest, n30_nombres, ',
				' n45_estado ',
				' FROM rolt045, rolt030 ',
			 	' WHERE n45_compania =  ', cia, 
				'   AND n45_compania = n30_compania ', 
				'   AND n45_cod_trab = n30_cod_trab ', 
				'   AND ', expr_tranado, 
				'   AND ', expr_sql CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE prestamo FROM query
		DECLARE q_prestamo CURSOR FOR prestamo
		LET i = 1
		FOREACH q_prestamo INTO rh_prestamo[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_prestamo TO rh_prestamo.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_prestamo')
			CLEAR rh_prestamo[i].*
			INITIALIZE rh_prestamo[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_prestamo
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_prestamo[1].* TO NULL
	RETURN rh_prestamo[1].n45_num_prest
END IF
LET i = arr_curr()
RETURN rh_prestamo[i].n45_num_prest

END FUNCTION



FUNCTION fl_ayuda_identidad_rol()
DEFINE rh_identidad	ARRAY[100] OF RECORD
				n16_flag_ident	LIKE rolt016.n16_flag_ident,
				n16_descripcion	LIKE rolt016.n16_descripcion
			END RECORD
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_sql		CHAR(500)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_identidad AT 06, 43 WITH 15 ROWS, 36 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf147 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf147'
ELSE
	OPEN FORM f_ayuf147 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf147c'
END IF
DISPLAY FORM f_ayuf147
LET filas_max = 100
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'ID'			TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n16_flag_ident, n16_descripcion
	IF int_flag THEN
		CLOSE WINDOW w_identidad
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n16_flag_ident, n16_descripcion ',
				' FROM rolt016 ',
			 	' WHERE ', expr_sql CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE identidad FROM query
		DECLARE q_identidad CURSOR FOR identidad
		LET i = 1
		FOREACH q_identidad INTO rh_identidad[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_identidad TO rh_identidad.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_identidad')
			CLEAR rh_identidad[i].*
			INITIALIZE rh_identidad[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_identidad
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_identidad[1].* TO NULL
	RETURN rh_identidad[1].n16_flag_ident, rh_identidad[1].n16_descripcion
END IF
LET i = arr_curr()
RETURN rh_identidad[i].n16_flag_ident, rh_identidad[i].n16_descripcion

END FUNCTION



FUNCTION fl_ayuda_roles_usos_varios(cod_cia, estado)
DEFINE rh_usos_varios ARRAY[100] OF RECORD
   	n43_num_rol       	LIKE rolt043.n43_num_rol,  
        n43_titulo       	LIKE rolt043.n43_titulo,
	n43_estado		LIKE rolt043.n43_estado
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE cod_cia 		LIKE rolt043.n43_compania
DEFINE estado		CHAR(1)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE expr_tranado	VARCHAR(100)
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_usos_varios AT 06,35
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf148'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Nombre'     TO bt_nombre
--#DISPLAY 'Estado'     TO bt_estado

LET filas_pant = fgl_scr_size('rh_usos_varios')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET expr_tranado = ""
IF estado = 'T' THEN
	LET expr_tranado = " AND n43_estado = '", estado, "'" 
END IF
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET query = " SELECT n43_num_rol, n43_titulo, n43_estado FROM rolt043 ",
			" WHERE n43_compania =  ", cod_cia, expr_tranado, 
                    ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                            ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE usos_varios FROM query
DECLARE q_usos_varios CURSOR FOR usos_varios
--------------
LET i = 1
FOREACH q_usos_varios INTO rh_usos_varios[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_usos_varios
        INITIALIZE rh_usos_varios[1].* TO NULL
        RETURN rh_usos_varios[1].n43_num_rol, rh_usos_varios[1].n43_titulo
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_usos_varios TO rh_usos_varios.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
        ON KEY(F15)
                LET col = 1
                EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
        ON KEY(F17)
                LET col = 3
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_usos_varios
IF int_flag THEN
        INITIALIZE rh_usos_varios[1].* TO NULL
	RETURN rh_usos_varios[1].n43_num_rol, rh_usos_varios[1].n43_titulo
END IF
LET  i = arr_curr()
RETURN rh_usos_varios[i].n43_num_rol, rh_usos_varios[i].n43_titulo

END FUNCTION



FUNCTION fl_ayuda_sectorial(codcia, ano_sect, tipo)
DEFINE codcia		LIKE rolt017.n17_compania
DEFINE ano_sect		LIKE rolt017.n17_ano_sect
DEFINE tipo		CHAR(1)
DEFINE rh_sectorial	ARRAY[200] OF RECORD
				n17_sectorial	LIKE rolt017.n17_sectorial,
				n17_descripcion	LIKE rolt017.n17_descripcion,
				n17_valor	LIKE rolt017.n17_valor
			END RECORD
DEFINE ano_aux		LIKE rolt017.n17_ano_sect
DEFINE i, j		SMALLINT
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(500)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT NO WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_sectorial AT 06, 12 WITH 15 ROWS, 68 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf149 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf149'
ELSE
	OPEN FORM f_ayuf149 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf149c'
END IF
DISPLAY FORM f_ayuf149
LET filas_max = 200
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Código'		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY 'Valor'		TO tit_col3
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	IF tipo = 'C' THEN
		LET int_flag = 0
		INPUT BY NAME ano_sect
			WITHOUT DEFAULTS
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT INPUT
			BEFORE FIELD ano_sect
				LET ano_aux = ano_sect
			AFTER FIELD ano_sect
				IF ano_sect IS NULL THEN
					LET ano_sect = ano_aux
					DISPLAY BY NAME ano_sect
				END IF
		END INPUT
		IF int_flag THEN
			CLOSE WINDOW w_sectorial
			EXIT WHILE
		END IF
	ELSE
		DISPLAY BY NAME ano_sect
	END IF
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n17_sectorial, n17_descripcion, n17_valor
	IF int_flag THEN
		CLOSE WINDOW w_sectorial
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n17_sectorial, n17_descripcion, ',
				' n17_valor ',
				' FROM rolt017 ',
				' WHERE n17_compania = ', codcia,
				'   AND n17_ano_sect = ', ano_sect,
				'   AND ', expr_sql CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE sectorial FROM query
		DECLARE q_sectorial CURSOR FOR sectorial
		LET i = 1
		FOREACH q_sectorial INTO rh_sectorial[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_sectorial TO rh_sectorial.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_sectorial')
			CLEAR rh_sectorial[i].*
			INITIALIZE rh_sectorial[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_sectorial
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE ano_sect, rh_sectorial[1].* TO NULL
	RETURN ano_sect, rh_sectorial[1].n17_sectorial,
		rh_sectorial[1].n17_descripcion
END IF
LET i = arr_curr()
RETURN ano_sect, rh_sectorial[i].n17_sectorial, rh_sectorial[i].n17_descripcion

END FUNCTION



FUNCTION fl_ayuda_anticipos_club(cia, estado)
DEFINE rh_prestamo	ARRAY[1000] OF RECORD
				n64_num_prest	LIKE rolt064.n64_num_prest,
				n30_nombres	LIKE rolt030.n30_nombres,
				n64_estado	LIKE rolt064.n64_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE cia		LIKE rolt064.n64_compania
DEFINE estado		LIKE rolt064.n64_estado
DEFINE expr_sql		CHAR(500)
DEFINE expr_tranado	CHAR(300)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_prestamo AT 06, 31 WITH 15 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
OPEN FORM f_ayuf151 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf151'
DISPLAY FORM f_ayuf151
LET filas_max = 1000
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Préstamo'		TO tit_col1
--#DISPLAY 'Empleado'		TO tit_col2
--#DISPLAY 'Estado'		TO tit_col3
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n64_num_prest, n30_nombres,
					n64_estado
	IF int_flag THEN
		CLOSE WINDOW w_prestamo
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
----------
        IF estado = 'T' THEN
                LET expr_tranado = " 1 = 1 "
        END IF
        IF estado <> 'T' THEN
                LET expr_tranado = " n64_estado = '", estado, "'"
        END IF
----------
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n64_num_prest, n30_nombres, ',
				' n64_estado ',
				' FROM rolt064, rolt030 ',
			 	' WHERE n64_compania =  ', cia, 
				'   AND ', expr_tranado CLIPPED, 
				'   AND ', expr_sql CLIPPED,
				'   AND n30_compania = n64_compania ', 
				'   AND n30_cod_trab = n64_cod_trab ', 
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE prestamo_club FROM query
		DECLARE q_prestamo_club CURSOR FOR prestamo_club
		LET i = 1
		FOREACH q_prestamo_club INTO rh_prestamo[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_prestamo TO rh_prestamo.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_prestamo')
			CLEAR rh_prestamo[i].*
			INITIALIZE rh_prestamo[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_prestamo
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_prestamo[1].* TO NULL
	RETURN rh_prestamo[1].n64_num_prest
END IF
LET i = arr_curr()
RETURN rh_prestamo[i].n64_num_prest

END FUNCTION



FUNCTION fl_ayuda_afiliados_club(cod_cia)

DEFINE rh_codigo_empleado ARRAY[1000] OF RECORD
	n30_cod_trab	LIKE rolt030.n30_cod_trab,
	n30_nombres	LIKE rolt030.n30_nombres
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE actt010.a10_compania
DEFINE j		SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codigo_empleado AT 06, 37 WITH 15 ROWS, 42 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
OPEN FORM f_ayuf152 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf152'
DISPLAY FORM f_ayuf152
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'       	TO bt_codigo
--#DISPLAY 'Nombres'	 	TO bt_nombres

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n30_cod_trab, n30_nombres
	IF int_flag THEN
		CLOSE WINDOW w_codigo_empleado
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-----------------
LET vm_columna_1 = 2
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT n30_cod_trab, n30_nombres FROM rolt030 ",
				" WHERE n30_compania = ", cod_cia, 
				"   AND n30_estado   = 'A' AND ",
				 expr_sql CLIPPED ,
                    ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE afiliado_club FROM query
	DECLARE q_afiliado_club CURSOR FOR afiliado_club
	LET i = 1
	FOREACH q_afiliado_club INTO rh_codigo_empleado[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
        IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET salir = 0
                EXIT WHILE
        END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
---------------
	DISPLAY ARRAY rh_codigo_empleado TO rh_codigo_empleado.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF int_flag = 4 THEN
	FOR i = 1 TO filas_pant
		INITIALIZE rh_codigo_empleado[i].* TO NULL
		CLEAR rh_codigo_empleado[i].*
	END FOR
END IF
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_codigo_empleado
	EXIT WHILE
END IF
END WHILE
FREE q_afiliado_club

IF int_flag <> 0 THEN
	INITIALIZE rh_codigo_empleado[1].* TO NULL
	RETURN rh_codigo_empleado[1].*
END IF
LET  i = arr_curr()
RETURN rh_codigo_empleado[i].n30_cod_trab, rh_codigo_empleado[i].n30_nombres

END FUNCTION



FUNCTION fl_ayuda_rubros_club(estado)
DEFINE estado		LIKE rolt067.n67_estado
DEFINE rh_rubro_club	ARRAY[100] OF RECORD
				n67_cod_rubro	LIKE rolt067.n67_cod_rubro,
				n67_nombre	LIKE rolt067.n67_nombre,
				n67_flag_ident	LIKE rolt067.n67_flag_ident
			END RECORD
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_tran		CHAR(30)
DEFINE expr_sql		CHAR(300)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_rub_club AT 06, 36 WITH 15 ROWS, 44 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf154 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf154'
ELSE
	OPEN FORM f_ayuf154 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf154c'
END IF
DISPLAY FORM f_ayuf154
LET filas_max = 100
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Código'		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY 'I'			TO tit_col3
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n67_cod_rubro, n67_nombre,
					n67_flag_ident
	IF int_flag THEN
		CLOSE WINDOW w_rub_club
		EXIT WHILE
	END IF
	CASE estado
		WHEN 'A'
			LET expr_tran = ' n67_estado = "A"'
		WHEN 'B'
			LET expr_tran = ' n67_estado = "B"'
		WHEN 'T'
			LET expr_tran = ' n67_estado IN ("A", "B")'
	END CASE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n67_cod_rubro, n67_nombre, ',
				' n67_flag_ident ',
				' FROM rolt067 ',
				' WHERE ', expr_tran CLIPPED,
				'   AND ', expr_sql CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE rubro_club FROM query
		DECLARE q_rubro_club CURSOR FOR rubro_club
		LET i = 1
		FOREACH q_rubro_club INTO rh_rubro_club[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_rubro_club TO rh_rubro_club.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_rubro_club')
			CLEAR rh_rubro_club[i].*
			INITIALIZE rh_rubro_club[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_rub_club
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_rubro_club[1].* TO NULL
	RETURN rh_rubro_club[1].n67_cod_rubro, rh_rubro_club[1].n67_nombre
END IF
LET i = arr_curr()
RETURN rh_rubro_club[i].n67_cod_rubro, rh_rubro_club[i].n67_nombre

END FUNCTION



FUNCTION fl_ayuda_transacciones_club(cod_cia, cod_tran)
DEFINE cod_cia		LIKE rolt068.n68_compania
DEFINE cod_tran		LIKE rolt068.n68_cod_tran
DEFINE rh_tran_club	ARRAY[1000] OF RECORD
				n68_cod_tran	LIKE rolt068.n68_cod_tran,
				n68_num_tran	LIKE rolt068.n68_num_tran,
				n30_nombres	LIKE rolt030.n30_nombres,
				n68_valor	LIKE rolt068.n68_valor
			END RECORD
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_tran	CHAR(30)
DEFINE tabla		CHAR(20)
DEFINE expr_sql		CHAR(500)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_rub_club AT 06, 18 WITH 15 ROWS, 62 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf155 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf155'
ELSE
	OPEN FORM f_ayuf155 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf155c'
END IF
DISPLAY FORM f_ayuf155
LET filas_max = 1000
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'TR'		TO tit_col1
--#DISPLAY 'Número'	TO tit_col2
--#DISPLAY 'Empleado'	TO tit_col3
--#DISPLAY 'Valor'	TO tit_col4
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET tabla = ' , OUTER rolt030 '
	DISPLAY cod_tran TO n68_cod_tran
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n68_num_tran, n30_nombres, n68_valor
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		AFTER CONSTRUCT
			LET nombres = get_fldbuf(n30_nombres)
			IF nombres IS NOT NULL THEN
				LET tabla = ' , rolt030 '
			END IF
	END CONSTRUCT
	IF int_flag THEN
		CLOSE WINDOW w_rub_club
		EXIT WHILE
	END IF
	CASE cod_tran
		WHEN 'IN'
			LET expr_tran = ' n68_cod_tran = "IN"'
		WHEN 'EG'
			LET expr_tran = ' n68_cod_tran = "EG"'
	END CASE
	IF cod_tran IS NULL THEN
		LET expr_tran = ' n68_cod_tran IN ("IN", "EG")'
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n68_cod_tran, n68_num_tran, n30_nombres, ',
				' n68_valor ',
				' FROM rolt068 ', tabla CLIPPED,
				' WHERE n68_compania = ', cod_cia,
				'   AND ', expr_tran CLIPPED,
				'   AND n68_compania = n30_compania ',
				'   AND n68_cod_trab = n30_cod_trab ',
				'   AND ', expr_sql CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE tran_club FROM query
		DECLARE q_tran_club CURSOR FOR tran_club
		LET i = 1
		FOREACH q_tran_club INTO rh_tran_club[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
	        IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET salir = 0
	                EXIT WHILE
	        END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_tran_club TO rh_tran_club.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_tran_club')
			CLEAR rh_tran_club[i].*
			INITIALIZE rh_tran_club[i].* TO NULL
		END FOR
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_rub_club
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tran_club[1].* TO NULL
	RETURN rh_tran_club[1].n68_cod_tran, rh_tran_club[1].n68_num_tran
END IF
LET i = arr_curr()
RETURN rh_tran_club[i].n68_cod_tran, rh_tran_club[i].n68_num_tran

END FUNCTION



FUNCTION fl_ayuda_cuenta_banco_club(cod_cia)
DEFINE rh_ctabco ARRAY[100] OF RECORD
	n69_banco		LIKE rolt069.n69_banco,
        g08_nombre       	LIKE gent008.g08_nombre,
        n69_numero_cta       	LIKE rolt069.n69_numero_cta 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE rolt069.n69_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW w_ctabco AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf156 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf156'
END IF
DISPLAY FORM f_ayuf156
LET filas_pant = fgl_scr_size('rh_ctabco')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_ctabco1 CURSOR FOR
        SELECT DISTINCT n69_banco, g08_nombre, n69_numero_cta  
		FROM rolt069, gent008
		WHERE n69_compania = cod_cia
		  AND g08_banco    = n69_banco 
        ORDER BY 2
LET i = 1
FOREACH qh_ctabco1 INTO rh_ctabco[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_ctabco
        INITIALIZE rh_ctabco[1].* TO NULL
        RETURN rh_ctabco[1].n69_banco, rh_ctabco[1].g08_nombre, rh_ctabco[1].n69_numero_cta 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ctabco TO rh_ctabco.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_ctabco
IF int_flag THEN
        INITIALIZE rh_ctabco[1].* TO NULL
        RETURN rh_ctabco[1].n69_banco, rh_ctabco[1].g08_nombre, rh_ctabco[1].n69_numero_cta 
END IF
LET  i = arr_curr()
RETURN rh_ctabco[i].n69_banco, rh_ctabco[i].g08_nombre, rh_ctabco[i].n69_numero_cta 

END FUNCTION



FUNCTION fl_ayuda_poliza_fondo_cen(cia, estado)
DEFINE rh_poliza	ARRAY[1000] OF RECORD
				n81_num_poliza	LIKE rolt081.n81_num_poliza,
				n81_fec_vcto	LIKE rolt081.n81_fec_vcto,
				n81_moneda	LIKE rolt081.n81_moneda,
				capital		DECIMAL(14,2),
				n81_val_int	LIKE rolt081.n81_val_int,
				n81_val_dscto	LIKE rolt081.n81_val_dscto,
				n81_estado	LIKE rolt081.n81_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE cia		LIKE rolt081.n81_compania
DEFINE estado		LIKE rolt081.n81_estado
DEFINE expr_sql		CHAR(500)
DEFINE expr_estado	CHAR(300)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE filas_max	SMALLINT
DEFINE salir		SMALLINT

OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_poliza AT 06, 04 WITH 15 ROWS, 76 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf157 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf157'
ELSE
	OPEN FORM f_ayuf157 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf157c'
END IF
DISPLAY FORM f_ayuf157
LET filas_max = 1000
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
CREATE TEMP TABLE tmp_poliza(
		poliza		CHAR(15),
		fec_vcto	DATE,
		moneda		CHAR(2),
		capital		DECIMAL(14,2),
		interes		DECIMAL(14,2),
		descuento	DECIMAL(14,2),
		estado		CHAR(1)
	)
--#DISPLAY 'No. Poliza'	TO tit_col1
--#DISPLAY 'Fec Vcto'	TO tit_col2
--#DISPLAY 'Mo'		TO tit_col3
--#DISPLAY 'Capital'	TO tit_col4
--#DISPLAY 'Interés'	TO tit_col5
--#DISPLAY 'Descuento'	TO tit_col6
--#DISPLAY 'E'		TO tit_col7
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n81_num_poliza, n81_fec_vcto, n81_moneda,
					n81_val_int, n81_val_dscto, n81_estado
	IF int_flag THEN
		CLOSE WINDOW w_poliza
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
----------
        IF estado = 'T' THEN
                LET expr_estado = " 1 = 1 "
        END IF
        IF estado <> 'T' THEN
                LET expr_estado = " n81_estado = '", estado, "'"
        END IF
----------
	LET query = 'SELECT n81_num_poliza, n81_fec_vcto, n81_moneda, ',
			' (n81_cap_trab + n81_cap_patr + n81_cap_int + ',
			'  n81_cap_dscto) capital, n81_val_int, n81_val_dscto,',			' n81_estado ',
			' FROM rolt081 ',
		 	' WHERE n81_compania =  ', cia, 
			'   AND ', expr_estado, 
			'   AND ', expr_sql CLIPPED
	PREPARE poliza FROM query
	DECLARE q_poliza CURSOR FOR poliza
	OPEN q_poliza
	FETCH q_poliza INTO rh_poliza[i].*
	IF STATUS = NOTFOUND THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET salir = 0
		CLOSE q_poliza
		FREE q_poliza
		CONTINUE WHILE
	END IF
	FOREACH q_poliza INTO rh_poliza[i].*
		INSERT INTO tmp_poliza VALUES (rh_poliza[i].*)
	END FOREACH
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM tmp_poliza ',
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2, ' ',rm_orden[vm_columna_2]
		PREPARE poliza1 FROM query
		DECLARE q_poliza1 CURSOR FOR poliza1
		LET i = 1
		FOREACH q_poliza1 INTO rh_poliza[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_poliza TO rh_poliza.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				EXIT DISPLAY
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
	                ON KEY(F20)
	                        LET col = 6
	                        EXIT DISPLAY
	                ON KEY(F21)
	                        LET col = 7
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                        --#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
	                IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
	                        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO fgl_scr_size('rh_poliza')
			CLEAR rh_poliza[i].*
			INITIALIZE rh_poliza[i].* TO NULL
		END FOR
		CLOSE q_poliza1
		FREE q_poliza1
		DELETE FROM tmp_poliza
	END IF
	IF NOT salir THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE q_poliza1
		FREE q_poliza1
		DELETE FROM tmp_poliza
		CLOSE WINDOW w_poliza
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_poliza[1].* TO NULL
	DROP TABLE tmp_poliza
	RETURN rh_poliza[1].n81_num_poliza
END IF
DROP TABLE tmp_poliza
LET i = arr_curr()
RETURN rh_poliza[i].n81_num_poliza

END FUNCTION



{--
FUNCTION fl_ayuda_motivos_salida_trabajador()
DEFINE rh_motiv ARRAY[50] OF RECORD
        n74_serial            LIKE rolt074.n74_serial,
        n74_descripcion       LIKE rolt074.n74_descripcion
        END RECORD
DEFINE i                SMALLINT
DEFINE j        	SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
                                                                                
LET filas_max  = 50
OPEN WINDOW wh AT 06, 39 WITH 12 ROWS, 40 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
OPEN FORM f_ayuf158 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf158'
DISPLAY FORM f_ayuf158
LET filas_pant = fgl_scr_size('rh_motiv')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_motiv CURSOR FOR
        SELECT n74_serial, n74_descripcion FROM rolt074
        ORDER BY 1
LET i = 1
FOREACH qh_motiv INTO rh_motiv[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh_motiv[1].* TO NULL
        RETURN rh_motiv[1].*
END IF

CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_motiv TO rh_motiv.*
        ON KEY(RETURN)
                EXIT DISPLAY
        --#BEFORE ROW
                --#LET j = arr_curr()
                --#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_motiv[1].* TO NULL
        RETURN rh_motiv[1].*
END IF
LET  i = arr_curr()
RETURN rh_motiv[i].*

END FUNCTION
--}



FUNCTION fl_ayuda_refacturacion_rep(cod_cia, cod_loc)
DEFINE cod_cia		LIKE rept088.r88_compania
DEFINE cod_loc		LIKE rept088.r88_localidad
DEFINE rh_refinv	ARRAY[10000] OF RECORD
			   	r88_cod_fact   	 LIKE rept088.r88_cod_fact,
			   	r88_num_fact   	 LIKE rept088.r88_num_fact,
			   	r88_num_fact_nue LIKE rept088.r88_num_fact_nue,
				r88_fecing	 DATE,
			   	r88_nomcli_nue 	 LIKE rept088.r88_nomcli_nue,
			   	r88_motivo_refact LIKE rept088.r88_motivo_refact
			END RECORD
DEFINE criterio		CHAR(600)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1200)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT

LET fil_ini = 06
LET col_ini = 05
LET fil_fin = 14
LET col_fin = 74
IF vg_gui = 0 THEN
	LET fil_ini = 05
	LET col_ini = 04
	LET fil_fin = 16
	LET col_fin = 75
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_refinv AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf159 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf159'
ELSE
	OPEN FORM f_ayuf159 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf159c'
END IF
DISPLAY FORM f_ayuf159
LET filas_max  = 10000
LET filas_pant = fgl_scr_size('rh_refinv')
--#DISPLAY 'TP'				TO tit_col1
--#DISPLAY 'FA. Ori.'			TO tit_col2
--#DISPLAY 'FA. Nue.'			TO tit_col3
--#DISPLAY 'Fec. Ref.'			TO tit_col4
--#DISPLAY 'Cliente'			TO tit_col5
--#DISPLAY 'Motivo Refacturación'	TO tit_col6
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON r88_num_fact, r88_num_fact_nue,
					r88_nomcli_nue, r88_motivo_refact
	IF int_flag THEN
		CLOSE WINDOW w_refinv
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
	LET vm_columna_1           = 2
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'DESC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT r88_cod_fact, r88_num_fact, ",
				"r88_num_fact_nue, DATE(r88_fecing), ",
				"r88_nomcli_nue, r88_motivo_refact ",
				" FROM rept088",
				" WHERE r88_compania  = ", cod_cia,
				"   AND r88_localidad = ", cod_loc,
				"   AND ", criterio CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE refinv FROM query
		DECLARE q_refinv CURSOR FOR refinv
		LET i = 1
		FOREACH q_refinv INTO rh_refinv[i].*
	        	LET i = i + 1
	        	IF i > filas_max THEN
	                	EXIT FOREACH
	       	 	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			LET i     = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                      "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_refinv TO rh_refinv.*
			ON KEY(F2)
				LET int_flag = 4
		                FOR i = 1 TO filas_pant
                	                CLEAR rh_refinv[i].*
	                        END FOR
				EXIT DISPLAY
			ON KEY(RETURN)
                        	LET salir = 1
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
                	ON KEY(F20)
                        	LET col = 6
                        	EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
                	--#AFTER DISPLAY
                        	--#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
        	END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
                        	LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                       		LET vm_columna_1           = col
                	END IF
                	IF rm_orden[vm_columna_1] = 'ASC' THEN
                        	LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
                	INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_refinv
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_refinv[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_refinv[1].* TO NULL
	RETURN rh_refinv[1].r88_cod_fact, rh_refinv[1].r88_num_fact,
		rh_refinv[1].r88_num_fact_nue 
END IF
LET i = arr_curr()
RETURN rh_refinv[i].r88_cod_fact, rh_refinv[i].r88_num_fact,
	rh_refinv[i].r88_num_fact_nue 

END FUNCTION



FUNCTION fl_ayuda_solicitudes_cobro(cod_cia, cod_loc, tipo)
DEFINE cod_cia		LIKE cxct024.z24_compania
DEFINE cod_loc		LIKE cxct024.z24_localidad
DEFINE tipo		LIKE cxct024.z24_tipo
DEFINE rh_solcob	ARRAY[10000] OF RECORD
			   	z24_localidad	LIKE cxct024.z24_localidad,
			   	z24_numero_sol	LIKE cxct024.z24_numero_sol,
			   	z24_areaneg	LIKE cxct024.z24_areaneg,
			   	z01_nomcli	LIKE cxct001.z01_nomcli,
				z24_fecing	DATE,
			   	z24_total_cap	LIKE cxct024.z24_total_cap,
				z24_estado	LIKE cxct024.z24_estado
			END RECORD
DEFINE criterio		CHAR(600)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1200)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT
DEFINE tit_total	DECIMAL(12,2)

LET fil_ini = 06
LET col_ini = 05
LET fil_fin = 16
LET col_fin = 74
IF vg_gui = 0 THEN
	LET fil_ini = 05
	LET col_ini = 04
	LET fil_fin = 17
	LET col_fin = 75
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_solcob AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf160 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf160'
ELSE
	OPEN FORM f_ayuf160 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf160c'
END IF
DISPLAY FORM f_ayuf160
LET filas_max  = 10000
LET filas_pant = fgl_scr_size('rh_solcob')
--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY 'Número'		TO tit_col2
--#DISPLAY 'AN'			TO tit_col3
--#DISPLAY 'C l i e n t e'	TO tit_col4
--#DISPLAY 'Fecha Sol.'		TO tit_col5
--#DISPLAY 'Valor'		TO tit_col6
--#DISPLAY 'E'			TO tit_col7
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON z24_numero_sol, z24_areaneg, z01_nomcli,
					z24_total_cap, z24_estado
	IF int_flag THEN
		CLOSE WINDOW w_solcob
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
	LET vm_columna_1           = 5
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT z24_localidad, z24_numero_sol, ",
				"z24_areaneg, z01_nomcli, DATE(z24_fecing), ",
				"z24_total_cap, z24_estado ",
				" FROM cxct024, cxct001",
				" WHERE z24_compania  = ", cod_cia,
				"   AND z24_localidad = ", cod_loc,
				"   AND z24_tipo      = '", tipo, "'",
				"   AND z01_codcli    = z24_codcli ",
				"   AND ", criterio CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE solcob FROM query
		DECLARE q_solcob CURSOR FOR solcob
		LET i         = 1
		LET tit_total = 0
		FOREACH q_solcob INTO rh_solcob[i].*
			LET tit_total = tit_total + rh_solcob[i].z24_total_cap
	        	LET i         = i + 1
	        	IF i > filas_max THEN
	                	EXIT FOREACH
	       	 	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			LET i     = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                      "
		END IF
		DISPLAY BY NAME tit_total
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_solcob TO rh_solcob.*
			ON KEY(F2)
				LET int_flag = 4
		                FOR i = 1 TO filas_pant
                	                CLEAR rh_solcob[i].*
	                        END FOR
				EXIT DISPLAY
			ON KEY(RETURN)
                        	LET salir = 1
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
                	ON KEY(F20)
                        	LET col = 6
                        	EXIT DISPLAY
                	ON KEY(F21)
                        	LET col = 7
                        	EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
                	--#AFTER DISPLAY
                        	--#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
        	END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
                        	LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                       		LET vm_columna_1           = col
                	END IF
                	IF rm_orden[vm_columna_1] = 'ASC' THEN
                        	LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
                	INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_solcob
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_solcob[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_solcob[1].* TO NULL
	RETURN rh_solcob[1].z24_numero_sol
END IF
LET i = arr_curr()
RETURN rh_solcob[i].z24_numero_sol

END FUNCTION



FUNCTION fl_ayuda_cheques_postfechados(cod_cia, cod_loc, codcli)
DEFINE cod_cia		LIKE cxct026.z26_compania
DEFINE cod_loc		LIKE cxct026.z26_localidad
DEFINE codcli		LIKE cxct026.z26_codcli
DEFINE rh_chepos	ARRAY[10000] OF RECORD
			   	z26_fecha_cobro	LIKE cxct026.z26_fecha_cobro,
			   	z26_referencia	LIKE cxct026.z26_referencia,
			   	z26_banco	LIKE cxct026.z26_banco,
				z26_num_cheque	LIKE cxct026.z26_num_cheque,
			   	z26_num_cta	LIKE cxct026.z26_num_cta,
				z26_valor	LIKE cxct026.z26_valor
			END RECORD
DEFINE query		CHAR(1200)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT
DEFINE tit_total	DECIMAL(12,2)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE g08_nombre	ARRAY[10000] OF LIKE gent008.g08_nombre

LET fil_ini = 05
LET col_ini = 02
LET fil_fin = 18
LET col_fin = 80
IF vg_gui = 0 THEN
	LET fil_ini = 03
	LET col_ini = 02
	LET fil_fin = 20
	LET col_fin = 77
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_chepos AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf161 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf161'
ELSE
	OPEN FORM f_ayuf161 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf161c'
END IF
DISPLAY FORM f_ayuf161
LET filas_max  = 10000
LET filas_pant = fgl_scr_size('rh_chepos')
--#DISPLAY 'Fecha Cob.'	TO tit_col1
--#DISPLAY 'Referencia'	TO tit_col2
--#DISPLAY 'Bco'	TO tit_col3
--#DISPLAY 'No. Cheque'	TO tit_col4
--#DISPLAY 'No. Cuenta'	TO tit_col5
--#DISPLAY 'Valor'	TO tit_col6
SELECT * INTO r_z01.* FROM cxct001 WHERE z01_codcli = codcli
DISPLAY BY NAME r_z01.z01_codcli, r_z01.z01_nomcli
MESSAGE "Seleccionando datos .."
LET vm_columna_1           = 1
LET vm_columna_2           = 6
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'DESC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = "SELECT z26_fecha_cobro, z26_referencia, z26_banco,",
			" z26_num_cheque, z26_num_cta, NVL(SUM(z26_valor), 0), g08_nombre ",
			" FROM cxct026, gent008 ",
			" WHERE z26_compania  = ", cod_cia,
			"   AND z26_localidad = ", cod_loc,
			"   AND z26_codcli    = ", codcli,
			"   AND z26_estado    = 'A' ",
			"   AND g08_banco     = z26_banco ",
			" GROUP BY 1, 2, 3, 4, 5, 7 ",
			" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE chepos FROM query
	DECLARE q_chepos CURSOR FOR chepos
	LET i         = 1
	LET tit_total = 0
	FOREACH q_chepos INTO rh_chepos[i].*, g08_nombre[i]
		LET tit_total = tit_total + rh_chepos[i].z26_valor
        	LET i         = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
       	 	END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		LET salir = 0
		LET i     = 0
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                      "
	END IF
	DISPLAY BY NAME tit_total
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_chepos TO rh_chepos.*
		ON KEY(F2)
			LET int_flag = 4
	                FOR i = 1 TO filas_pant
               	                CLEAR rh_chepos[i].*
                        END FOR
			EXIT DISPLAY
		ON KEY(RETURN)
                       	LET salir = 1
                       	EXIT DISPLAY
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
               	ON KEY(F20)
                       	LET col = 6
                       	EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#DISPLAY BY NAME g08_nombre[j]
			--#MESSAGE j, ' de ', i
               	--#AFTER DISPLAY
                       	--#LET salir = 1
	END DISPLAY
       	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
               	EXIT WHILE
       	END IF
       	IF col IS NOT NULL AND NOT salir THEN
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
               	INITIALIZE col TO NULL
       	END IF
END WHILE
CLOSE WINDOW w_chepos
IF int_flag <> 0 THEN
	INITIALIZE rh_chepos[1].* TO NULL
	RETURN rh_chepos[1].z26_banco, rh_chepos[1].z26_num_cheque,
		rh_chepos[1].z26_num_cta, rh_chepos[1].z26_valor
END IF
LET i = arr_curr()
RETURN rh_chepos[i].z26_banco, rh_chepos[i].z26_num_cheque,
	rh_chepos[i].z26_num_cta, rh_chepos[i].z26_valor

END FUNCTION



FUNCTION fl_ayuda_refacturacion_tal(cod_cia, cod_loc)
DEFINE cod_cia		LIKE talt060.t60_compania
DEFINE cod_loc		LIKE talt060.t60_localidad
DEFINE rh_reftal	ARRAY[10000] OF RECORD
			   	t60_fac_ant	 LIKE talt060.t60_fac_ant,
			   	t60_fac_nue	 LIKE talt060.t60_fac_nue,
				t60_fecing	 DATE,
			   	t60_nomcli_nue	 LIKE talt060.t60_nomcli_nue,
			   	t60_motivo_refact LIKE talt060.t60_motivo_refact
			END RECORD
DEFINE criterio		CHAR(600)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(1200)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT

LET fil_ini = 06
LET col_ini = 05
LET fil_fin = 14
LET col_fin = 74
IF vg_gui = 0 THEN
	LET fil_ini = 05
	LET col_ini = 04
	LET fil_fin = 16
	LET col_fin = 75
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_reftal AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf162 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf162'
ELSE
	OPEN FORM f_ayuf162 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf162c'
END IF
DISPLAY FORM f_ayuf162
LET filas_max  = 10000
LET filas_pant = fgl_scr_size('rh_reftal')
--#DISPLAY 'FA. Ori.'			TO tit_col1
--#DISPLAY 'FA. Nue.'			TO tit_col2
--#DISPLAY 'Fec. Ref.'			TO tit_col3
--#DISPLAY 'Cliente'			TO tit_col4
--#DISPLAY 'Motivo Refacturación'	TO tit_col5
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON t60_fac_ant, t60_fac_nue,
					t60_nomcli_nue, t60_motivo_refact
	IF int_flag THEN
		CLOSE WINDOW w_reftal
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'DESC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT t60_fac_ant, t60_fac_nue, ",
				"DATE(t60_fecing), t60_nomcli_nue, ",
				"t60_motivo_refact ",
				" FROM talt060 ",
				" WHERE t60_compania  = ", cod_cia,
				"   AND t60_localidad = ", cod_loc,
				"   AND ", criterio CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE reftal FROM query
		DECLARE q_reftal CURSOR FOR reftal
		LET i = 1
		FOREACH q_reftal INTO rh_reftal[i].*
	        	LET i = i + 1
	        	IF i > filas_max THEN
	                	EXIT FOREACH
	       	 	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			LET i     = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                      "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_reftal TO rh_reftal.*
			ON KEY(F2)
				LET int_flag = 4
		                FOR i = 1 TO filas_pant
                	                CLEAR rh_reftal[i].*
	                        END FOR
				EXIT DISPLAY
			ON KEY(RETURN)
                        	LET salir = 1
                        	EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
                	--#AFTER DISPLAY
                        	--#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
        	END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
                        	LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                       		LET vm_columna_1           = col
                	END IF
                	IF rm_orden[vm_columna_1] = 'ASC' THEN
                        	LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
                	INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_reftal
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_reftal[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_reftal[1].* TO NULL
	RETURN rh_reftal[1].t60_fac_ant, rh_reftal[1].t60_fac_nue 
END IF
LET i = arr_curr()
RETURN rh_reftal[i].t60_fac_ant, rh_reftal[i].t60_fac_nue 

END FUNCTION



FUNCTION fl_ayuda_cliente_localidad_cobrar(cod_cia, cod_loc, flag)
DEFINE rh_cliloc	ARRAY[30000] OF RECORD
				z02_codcli	LIKE cxct002.z02_codcli,
       				z01_nomcli	LIKE cxct001.z01_nomcli,
				z01_num_doc_id	LIKE cxct001.z01_num_doc_id,
				total_cxc	DECIMAL(14,2)
			END RECORD
DEFINE flag		CHAR(1)
DEFINE i, j, col, salir	SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(800)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc 		LIKE cxct002.z02_localidad
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE expr_col		VARCHAR(50)
DEFINE tabla		VARCHAR(10)
DEFINE expr_whe		VARCHAR(200)
DEFINE expr_hav		VARCHAR(100)
DEFINE total_gen	DECIMAL(14,2)

LET filas_max  = 30000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_clicob AT 06, 02 WITH 16 ROWS, 77 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf163 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf163'
ELSE
	OPEN FORM f_ayuf163 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf163c'
END IF
DISPLAY FORM f_ayuf163
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Código'         TO bt_codigo
--#DISPLAY 'Nombre Cliente' TO bt_nombre
--#DISPLAY 'Cedula/RUC'     TO bt_cedruc
--#DISPLAY 'Total Cob.'     TO bt_total
CASE flag
	WHEN 'D'
		LET expr_col = "SUM(z20_saldo_cap + z20_saldo_int)"
		LET tabla    = 'cxct020'
		LET expr_whe = "   AND z20_compania  = z02_compania ",
				"   AND z20_localidad = z02_localidad ",
				"   AND z20_codcli    = z02_codcli "
		LET expr_hav = " HAVING ", expr_col CLIPPED, " > 0 "
	WHEN 'F'
		LET expr_col = "SUM(z21_saldo)"
		LET tabla    = 'cxct021'
		LET expr_whe = "   AND z21_compania  = z02_compania ",
				"   AND z21_localidad = z02_localidad ",
				"   AND z21_codcli    = z02_codcli "
		LET expr_hav = " HAVING ", expr_col CLIPPED, " > 0 "
END CASE
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z02_codcli, z01_nomcli, z01_num_doc_id
	IF int_flag THEN
		CLOSE WINDOW w_clicob
		EXIT WHILE
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 4
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'DESC'
	LET rm_orden[vm_columna_2]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT z02_codcli, z01_nomcli, z01_num_doc_id, ",
				expr_col CLIPPED,
				" FROM cxct001, cxct002, ", tabla CLIPPED,
				" WHERE z02_compania  = ", cod_cia, 
				"   AND z02_localidad = ", cod_loc, 
				"   AND z02_codcli    = z01_codcli ",
				"   AND ", expr_sql CLIPPED,
				expr_whe CLIPPED,
				" GROUP BY 1, 2, 3 ",
				expr_hav CLIPPED,
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE cliloc_2 FROM query
		DECLARE q_cliloc_2 CURSOR FOR cliloc_2
		LET i         = 1
		LET total_gen = 0
		FOREACH q_cliloc_2 INTO rh_cliloc[i].*
			LET total_gen = total_gen + rh_cliloc[i].total_cxc
			LET i         = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	                CALL fl_mensaje_consulta_sin_registros()
	                LET i = 0
	                LET salir = 0
	                EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		DISPLAY BY NAME total_gen
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_cliloc TO rh_cliloc.*
			ON KEY(RETURN)
	                        LET salir = 1
	                        EXIT DISPLAY
			ON KEY(F2)
	                        LET int_flag = 4
	                        FOR i = 1 TO filas_pant
	                                CLEAR rh_cliloc[i].*
        	                END FOR
	                        EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
        	        --#AFTER DISPLAY
                	        --#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
        	        IF col <> vm_columna_1 THEN
                	        LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
	        CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
	        CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_clicob
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_cliloc[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cliloc[1].* TO NULL
	RETURN rh_cliloc[1].z02_codcli, rh_cliloc[1].z01_nomcli
END IF
LET i = arr_curr()
RETURN rh_cliloc[i].z02_codcli, rh_cliloc[i].z01_nomcli

END FUNCTION



FUNCTION fl_ayuda_sustentos_sri(codcia)
DEFINE codcia		LIKE srit006.s06_compania
DEFINE rh_sust		ARRAY [200] OF RECORD
				s06_codigo	LIKE srit006.s06_codigo,
				s06_descripcion	LIKE srit006.s06_descripcion
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE num_row, max_row	SMALLINT
DEFINE i, j, col, salir	SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(800)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc 		LIKE cxct002.z02_localidad
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE expr_col		VARCHAR(50)

IF vg_gui = 0 THEN
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 5
LET num_rows = 15
LET num_cols = 76
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_sustsri AT row_ini, 04 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu, BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf164 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf164"
ELSE
	OPEN FORM f_ayuf164 FROM "../../../PRODUCCION/LIBRERIAS/forms/ayuf164c"
END IF
DISPLAY FORM f_ayuf164
LET filas_pant = 10
LET max_row    = 200
FOR i = 1 TO filas_pant
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY "CD"		TO tit_col1
--#DISPLAY "Descrpcion"	TO tit_col2
WHILE TRUE
MESSAGE 'Seleccionando datos . . . espere por favor.'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = 'SELECT s06_codigo, s06_descripcion ',
			' FROM srit006 ',
			' WHERE s06_compania = ', codcia,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons_sust FROM query
	DECLARE q_sust CURSOR FOR cons_sust
	LET num_row = 1
	FOREACH q_sust INTO rh_sust[num_row].*
		LET num_row = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	IF num_row = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET num_row = 1
		LET salir = 0
		EXIT WHILE
	END IF
	MESSAGE "                                           "
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY rh_sust TO rh_sust.*
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_cliloc[i].*
       	                END FOR
                        EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#DISPLAY i       TO num_row
			--#DISPLAY num_row TO max_row
		--#AFTER DISPLAY
			--#LET salir = 1
	END DISPLAY
        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_sustsri
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_sust[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_sust[1].* TO NULL
	RETURN rh_sust[1].s06_codigo, rh_sust[1].s06_descripcion
END IF
LET i = arr_curr()
RETURN rh_sust[i].s06_codigo, rh_sust[i].s06_descripcion

END FUNCTION



FUNCTION fl_ayuda_proceso_adic_rol(cod_cia, tipo_proc)
DEFINE cod_cia		LIKE rolt091.n91_compania
DEFINE tipo_proc	LIKE rolt091.n91_proceso
DEFINE rh_proceso	ARRAY[10000] OF RECORD
			   	n91_proceso   	LIKE rolt091.n91_proceso,
			   	n91_num_ant   	LIKE rolt091.n91_num_ant,
			   	n30_nombres    	LIKE rolt030.n30_nombres,
			   	n91_valor_ant	LIKE rolt091.n91_valor_ant
			END RECORD
DEFINE expr_tran	VARCHAR(100)
DEFINE total		DECIMAL(12,2)
DEFINE criterio		CHAR(600)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(800)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT

LET fil_ini = 6
LET col_ini = 13
LET fil_fin = 16
LET col_fin = 66
IF vg_gui = 0 THEN
	LET fil_ini = 5
	LET col_ini = 12
	LET fil_fin = 18
	LET col_fin = 67
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_proceso AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf165 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf165'
ELSE
	OPEN FORM f_ayuf165 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf165c'
END IF
DISPLAY FORM f_ayuf165
LET filas_max  = 10000
LET filas_pant = fgl_scr_size('rh_proceso')
--#DISPLAY 'TP'		TO tit_col1
--#DISPLAY 'Número'	TO tit_col2
--#DISPLAY 'Empleados'	TO tit_col3
--#DISPLAY 'Valor'	TO tit_col4
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	IF tipo_proc <> '00' THEN 
		DISPLAY tipo_proc TO n91_proceso
	END IF
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON n91_num_ant, n30_nombres, n91_valor_ant
	IF int_flag THEN
		CLOSE WINDOW w_proceso
		EXIT WHILE
	END IF
	MESSAGE "Seleccionando datos .."
	LET expr_tran = NULL
	IF tipo_proc <> '00' THEN 
		LET expr_tran = "   AND n91_proceso  = '", tipo_proc, "'"
	END IF
	LET vm_columna_1           = 2
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT n91_proceso, n91_num_ant, n30_nombres, ",
					" n91_valor_ant ",
				" FROM rolt091, rolt030 ",
				" WHERE n91_compania  = ", cod_cia,
				expr_tran CLIPPED,
				"   AND ", criterio CLIPPED,
				"   AND n30_compania  = n91_compania ",
				"   AND n30_cod_trab  = n91_cod_trab ",
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE proces1 FROM query
		DECLARE q_proces1 CURSOR FOR proces1
		LET i     = 1
		LET total = 0
		FOREACH q_proces1 INTO rh_proceso[i].*
			LET total = total + rh_proceso[i].n91_valor_ant
	        	LET i     = i + 1
	        	IF i > filas_max THEN
	                	EXIT FOREACH
	       	 	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			LET i     = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                      "
		END IF
		DISPLAY BY NAME total
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_proceso TO rh_proceso.*
			ON KEY(F2)
				LET int_flag = 4
		                FOR i = 1 TO filas_pant
                	                CLEAR rh_proceso[i].*
	                        END FOR
				EXIT DISPLAY
			ON KEY(RETURN)
                        	LET salir = 1
                        	EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
                	--#AFTER DISPLAY
                        	--#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
        	END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
                        	LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                       		LET vm_columna_1           = col
                	END IF
                	IF rm_orden[vm_columna_1] = 'ASC' THEN
                        	LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
                	INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_proceso
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_proceso[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_proceso[1].* TO NULL
	RETURN rh_proceso[1].n91_proceso
END IF
LET i = arr_curr()
RETURN rh_proceso[i].n91_proceso

END FUNCTION

 

FUNCTION fl_ayuda_tipo_factura_cxp()
DEFINE rh_fact		ARRAY[500] OF RECORD
				c01_tipo_orden	LIKE ordt001.c01_tipo_orden,
			        c01_nombre	LIKE ordt001.c01_nombre,
			        c01_estado	LIKE ordt001.c01_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 500
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_factcxp AT 06, 29 WITH 14 ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf166 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf166'
ELSE
	OPEN FORM f_ayuf166 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf166c'
END IF
DISPLAY FORM f_ayuf166
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'Tipo'		TO tit_col1
--#DISPLAY 'Descripcion'	TO tit_col2
--#DISPLAY 'E'			TO tit_col3
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	---------------
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT c01_tipo_orden, c01_nombre, c01_estado ",
				" FROM ordt001 ",
				" WHERE c01_estado  = 'A'",
				"   AND (c01_modulo IS NULL",
				"    OR  c01_modulo = 'OC' ",
				"    OR  c01_modulo = 'TE') ",
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2,' ', rm_orden[vm_columna_2]
		PREPARE factcxp FROM query
		DECLARE q_factcxp CURSOR FOR factcxp
		LET i = 1
		FOREACH q_factcxp INTO rh_fact[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
        		CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_fact TO rh_fact.*
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
	                        LET int_flag = 4
	                        FOR i = 1 TO filas_pant
	                                CLEAR rh_fact[i].*
	                        END FOR
	                        EXIT DISPLAY
	                ON KEY(F15)
	                        LET col = 1
	                        EXIT DISPLAY
	                ON KEY(F16)
	                        LET col = 2
	                        EXIT DISPLAY
	                ON KEY(F17)
	                        LET col = 3
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                	--#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
        	        IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
        	                LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                	        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF i = 0 THEN
	        EXIT WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
	        CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_factcxp
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_fact[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_fact[1].* TO NULL
	RETURN rh_fact[1].c01_tipo_orden, rh_fact[1].c01_nombre
END IF
LET i = arr_curr()
RETURN rh_fact[i].c01_tipo_orden, rh_fact[i].c01_nombre

END FUNCTION

 

FUNCTION fl_ayuda_porc_impto(codcia, codloc, estado, tipo_i, tipo)
DEFINE codcia		LIKE gent058.g58_compania
DEFINE codloc		LIKE gent058.g58_localidad
DEFINE estado		LIKE gent058.g58_estado
DEFINE tipo_i		LIKE gent058.g58_tipo_impto
DEFINE tipo		LIKE gent058.g58_tipo
DEFINE rh_porc_impto	ARRAY[500] OF RECORD
				g58_localidad	LIKE gent058.g58_localidad,
				g58_porc_impto	LIKE gent058.g58_porc_impto,
			        g58_desc_impto	LIKE gent058.g58_desc_impto,
			        g58_tipo_impto	LIKE gent058.g58_tipo_impto,
			        g58_tipo	LIKE gent058.g58_tipo,
			        g58_estado	LIKE gent058.g58_estado
			END RECORD
DEFINE i, j		SMALLINT
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_tip2	VARCHAR(100)
DEFINE query		CHAR(800)
DEFINE filas_max	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 500
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_porc_impto AT 06, 29 WITH 14 ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf167 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf167'
ELSE
	OPEN FORM f_ayuf167 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf167c'
END IF
DISPLAY FORM f_ayuf167
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY '%'			TO tit_col2
--#DISPLAY 'Descripcion'	TO tit_col3
--#DISPLAY 'T'			TO tit_col4
--#DISPLAY 'C'			TO tit_col5
--#DISPLAY 'E'			TO tit_col6
LET expr_tip = NULL
IF tipo_i <> 'T' THEN
	LET expr_tip = "   AND g58_tipo_impto = '", tipo_i, "'"
END IF
LET expr_tip2 = NULL
IF tipo <> 'T' THEN
	LET expr_tip2 = "   AND g58_tipo       = '", tipo, "'"
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = "   AND g58_estado     = '", estado, "'"
END IF
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	---------------
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT g58_localidad, g58_porc_impto, ",
				"g58_desc_impto, g58_tipo_impto, g58_tipo, ",
				"g58_estado ",
				" FROM gent058 ",
				" WHERE g58_compania   = ", codcia,
				"   AND g58_localidad  = ", codloc,
				expr_tip CLIPPED,
				expr_tip2 CLIPPED,
				expr_est CLIPPED,
                    		' ORDER BY ', vm_columna_1, ' ',
					rm_orden[vm_columna_1], ', ',
					vm_columna_2,' ', rm_orden[vm_columna_2]
		PREPARE porc_impto FROM query
		DECLARE q_porc_impto CURSOR FOR porc_impto
		LET i = 1
		FOREACH q_porc_impto INTO rh_porc_impto[i].*
			LET i = i + 1
			IF i > filas_max THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
        		CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                                           "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_porc_impto TO rh_porc_impto.*
			ON KEY(RETURN)
				LET salir = 1
	                	EXIT DISPLAY
			ON KEY(F2)
	                        LET int_flag = 4
	                        FOR i = 1 TO filas_pant
	                                CLEAR rh_porc_impto[i].*
	                        END FOR
	                        EXIT DISPLAY
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
	                ON KEY(F20)
	                        LET col = 6
	                        EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
	                --#AFTER DISPLAY
	                	--#LET salir = 1
		END DISPLAY
	        IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
	                EXIT WHILE
	        END IF
	        IF col IS NOT NULL AND NOT salir THEN
        	        IF col <> vm_columna_1 THEN
	                        LET vm_columna_2           = vm_columna_1
        	                LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                	        LET vm_columna_1           = col
	                END IF
	                IF rm_orden[vm_columna_1] = 'ASC' THEN
	                        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
	                        LET rm_orden[vm_columna_1] = 'ASC'
	                END IF
	                INITIALIZE col TO NULL
	        END IF
	END WHILE
	IF i = 0 THEN
	        EXIT WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
	        CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_porc_impto
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_porc_impto[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_porc_impto[1].* TO NULL
	RETURN rh_porc_impto[1].g58_porc_impto, rh_porc_impto[1].g58_desc_impto
END IF
LET i = arr_curr()
RETURN rh_porc_impto[i].g58_porc_impto, rh_porc_impto[i].g58_desc_impto

END FUNCTION
 


FUNCTION fl_ayuda_rubros_dias_tiempos()
DEFINE rh_rubrol	ARRAY[200] OF RECORD
			        n06_cod_rubro   LIKE rolt006.n06_cod_rubro,
				n06_nombre	LIKE rolt006.n06_nombre 
		        END RECORD
DEFINE i, j		SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE query		CHAR(1000)	## Contiene todo el query preparado

LET filas_max  = 200
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_rubrol2 AT 06,23 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf123'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
--#DISPLAY "Cod."		TO bt_codigo
--#DISPLAY "Descripcion"	TO bt_nombre
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT n06_cod_rubro, n06_nombre ",
			" FROM rolt006 ",
			" WHERE n06_estado      = 'A' ",
			"   AND n06_ing_usuario = 'S' ",	
			"   AND n06_calculo     = 'N' ",
			"   AND (n06_flag_ident IN ('H5', 'H1', 'C1', 'MU') ",
			"    OR  n06_cod_rubro  IN ",
				"(SELECT n08_rubro_base ",
					"FROM rolt006 a, rolt008 ",
					"WHERE a.n06_flag_ident = 'DT' ",
					"  AND a.n06_estado     = 'A' ",
					"  AND n08_cod_rubro    = ",
							"a.n06_cod_rubro)) ",
			" ORDER BY 2"
	PREPARE rubrol2 FROM query
	DECLARE q_rubrol2 CURSOR FOR rubrol2
	LET i = 1
	FOREACH q_rubrol2 INTO rh_rubrol[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_rubrol TO rh_rubrol.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		ON KEY(RETURN)
                	EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_rubrol2
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_rubrol[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_rubrol[1].* TO NULL
	RETURN rh_rubrol[1].*
END IF
LET i = arr_curr()
RETURN rh_rubrol[i].*

END FUNCTION



FUNCTION fl_valor_ganado_liquidacion(cod_cia, proc, cod_trab, fec_ini, fec_fin)
DEFINE cod_cia		LIKE rolt032.n32_compania
DEFINE proc		LIKE rolt003.n03_proceso
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin
DEFINE proc_aux		LIKE rolt003.n03_proceso
DEFINE fecha, fecha_aux	LIKE rolt032.n32_fecha_fin
DEFINE fec, fec2	LIKE rolt032.n32_fecha_fin
DEFINE valor		LIKE rolt032.n32_tot_gan
DEFINE rh_liqgan	ARRAY[960] OF RECORD
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_gan	DECIMAL(14,4)
			END RECORD
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g35		RECORD LIKE gent035.*
DEFINE r_n00		RECORD LIKE rolt000.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n07		RECORD LIKE rolt007.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n90		RECORD LIKE rolt090.*
DEFINE anio_i, anio_f	SMALLINT
DEFINE primera, dias	SMALLINT
DEFINE filas_pant, an_a	SMALLINT
DEFINE num_row, max_row	SMALLINT
DEFINE tot_gan_g	DECIMAL(14,4)
DEFINE val_gan_g	DECIMAL(14,4)
DEFINE val_adi		DECIMAL(14,4)
DEFINE comando          VARCHAR(250)
DEFINE num_dias		INTEGER
DEFINE dias_adi, d_a	INTEGER
DEFINE dias_anio	INTEGER
DEFINE valor_fec, dia	INTEGER
DEFINE fact, aux_f	DECIMAL(16,9)
DEFINE query		CHAR(4000)
DEFINE expr_sql1	VARCHAR(250)
DEFINE expr_sql2	VARCHAR(250)
DEFINE creo_tmp		SMALLINT

LET max_row    = 960
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_liqgan AT 04,13 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf168'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "LQ"			TO tit_col1
--#DISPLAY "Fecha Ini."		TO tit_col2
--#DISPLAY "Fecha Fin."		TO tit_col3
--#DISPLAY "Total Ganado"	TO tit_col4
--#DISPLAY "Subtotal"		TO tit_col5
CALL fl_lee_parametro_general_roles() RETURNING r_n00.*
CALL fl_lee_conf_adic_rol(cod_cia) RETURNING r_n90.*
LET anio_i   = YEAR(fec_ini)
LET proc_aux = NULL
IF proc = 'AV' THEN
	LET proc_aux = proc
	LET proc     = 'VA'
END IF
CALL fl_lee_trabajador_roles(cod_cia, cod_trab) RETURNING r_n30.*
IF proc = 'VA' OR proc = 'VP' THEN
	LET dias_adi = YEAR(fec_fin) - YEAR(r_n30.n30_fecha_ing)
	LET an_a     = dias_adi
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET dias_adi = YEAR(fec_fin) - YEAR(r_n30.n30_fecha_reing)
	END IF
	LET dias_adi = dias_adi - r_n00.n00_ano_adi_vac + 1
	IF dias_adi > r_n00.n00_dias_vacac THEN
		LET dias_adi = r_n00.n00_dias_vacac
	END IF
	IF dias_adi > 0 THEN
		LET fecha_aux = fec_fin - 1 UNITS YEAR + 1 UNITS DAY
	END IF
	LET d_a = dias_adi
END IF
IF proc = 'FR' THEN
	LET valor_fec = (fec_fin - r_n30.n30_fecha_ing) + 1
	IF YEAR(fec_fin) > YEAR(fec_ini) + 1 THEN
		LET valor_fec = ((DATE(fec_ini + 1 UNITS YEAR - 1 UNITS DAY)) -
				r_n30.n30_fecha_ing) + 1
	END IF
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET valor_fec = (fec_fin - r_n30.n30_fecha_reing) + 1
		IF YEAR(fec_fin) > YEAR(fec_ini) + 1 THEN
			LET valor_fec = ((DATE(fec_ini + 1 UNITS YEAR
					- 1 UNITS DAY))
					- r_n30.n30_fecha_reing) + 1
		END IF
	END IF
	LET fecha_aux = fec_ini
	CALL fl_lee_proceso_roles(proc) RETURNING r_n03.*
	IF fec_ini >= MDY(07, 01, 2009) THEN
		CASE r_n03.n03_frecuencia
			WHEN 'A' LET dias_anio = r_n90.n90_dias_anio
			WHEN 'M' LET dias_anio = r_n00.n00_dias_mes
		END CASE
	ELSE
		LET dias_anio = r_n90.n90_dias_anio
	END IF
	LET valor_fec = valor_fec - dias_anio
	IF valor_fec > 0 AND valor_fec < r_n90.n90_dias_anio THEN
		LET fec_ini = r_n30.n30_fecha_ing
		IF r_n30.n30_fecha_reing IS NOT NULL THEN
			LET fec_ini = r_n30.n30_fecha_reing
		END IF
		LET dia = 1
		IF DAY(fec_ini) >= 15 THEN
			LET dia = 16
		END IF
		IF fec_ini >= MDY(07, 01, 2009) THEN
			CASE r_n03.n03_frecuencia
				WHEN 'A' LET fec_ini = MDY(MONTH(fec_ini), dia,
							YEAR(fec_ini) + 1)
				WHEN 'M' LET fec_ini = MDY(MONTH(fec_fin), dia,
							YEAR(fec_fin))
			END CASE
		ELSE
			LET fec_ini = MDY(MONTH(fec_ini), dia,YEAR(fec_ini) + 1)
		END IF
	END IF
END IF
CASE proc
	WHEN 'VA'
		LET fact = 24
	WHEN 'VP'
		LET fact = 24
	WHEN 'DT'
		LET fact = 12
	WHEN 'DC'
		SELECT COUNT(*) INTO fact
			FROM rolt032
			WHERE n32_compania    = cod_cia
			  AND n32_cod_liqrol IN ("Q1", "Q2")
			  AND n32_fecha_ini  >= fec_ini
			  AND n32_fecha_fin  <= fec_fin
			  AND n32_cod_trab    = cod_trab
			  AND n32_estado     <> "E"
		IF fact = 0 THEN
			LET fact = 1
		END IF
		LET expr_sql1 = '  AND n36_fecha_ini >= "', fec_ini, '"',
				'  AND n36_fecha_fin <= "', fec_fin, '"'
		LET expr_sql2 = NULL
		LET fecha_aux = NULL
		SELECT MAX(n36_fecha_fin)
			INTO fecha_aux
			FROM rolt036
			WHERE n36_compania = cod_cia
			  AND n36_proceso  = proc
			  AND n36_cod_trab = cod_trab
		LET aux_f     = fact
		IF fact > 24 THEN
			SELECT n36_ano_proceso a_d, n36_fecha_ini f_ini,
				n36_fecha_fin f_fin
				FROM rolt036
				WHERE n36_compania = cod_cia
				  AND n36_proceso  = proc
				  AND n36_cod_trab = cod_trab
				INTO TEMP t1
			LET expr_sql1 = '  AND n36_ano_proceso = ',
					'NVL((SELECT a_d FROM t1 ',
						'WHERE a_d = n32_ano_proceso ',
						'  AND n32_fecha_fin ',
						'BETWEEN f_ini AND f_fin ), ',
						'n32_ano_proceso + 1) '
			LET expr_sql2 = '  AND a.n32_fecha_ini  > ',
					'(SELECT MAX(f_fin) FROM t1) '
			LET creo_tmp  = 1
			SELECT MAX(f_fin) INTO fecha_aux FROM t1
			SELECT COUNT(*) INTO aux_f
				FROM rolt032
				WHERE n32_compania    = cod_cia
				  AND n32_cod_liqrol IN ("Q1", "Q2")
				  AND n32_fecha_ini  >= fecha_aux
				  AND n32_cod_trab    = cod_trab
				  AND n32_estado     <> "E"
		END IF
		IF (YEAR(fec_ini) = YEAR(r_n30.n30_fecha_ing) AND
		   YEAR(fec_fin) = YEAR(r_n30.n30_fecha_ing) + 1) OR (fact > 24)
		THEN
			LET fact = 24
		END IF
	WHEN 'FR'
		LET fact = 12
END CASE
LET query = 'SELECT n32_cod_liqrol, n32_fecha_ini, n32_fecha_fin, ',
		'NVL(CASE WHEN "', proc, '" <> "DC" THEN n32_tot_gan END, ',
			'NVL((SELECT SUM(n36_ganado_real) ',
				'FROM rolt036 ',
				'WHERE n36_compania    = ', cod_cia,
				'  AND n36_proceso     = "', proc, '"',
				expr_sql1 CLIPPED,
				'  AND n36_cod_trab    = ', cod_trab, '), ',
				'NVL((SELECT (n03_valor / ',
				'(SELECT n90_dias_anio FROM rolt090 ',
					'WHERE n90_compania = ',cod_cia,')) * ',
			'(DATE((SELECT MAX(a.n32_fecha_fin) ',
				' FROM rolt032 a ',
				' WHERE a.n32_compania    = ', cod_cia,
				'   AND a.n32_cod_liqrol IN ("Q1", "Q2") ',
				expr_sql2 CLIPPED,
				'   AND a.n32_cod_trab    = ', cod_trab,')) - ',
			'DATE(NVL((SELECT MAX(n36_fecha_fin) + 1 UNITS DAY ',
				' FROM rolt036 ',
				' WHERE n36_compania   = ', cod_cia,
				'   AND n36_proceso    = "', proc, '"',
				'   AND n36_cod_trab   = ', cod_trab, '),',
				' DATE((SELECT MDY(n03_mes_ini, n03_dia_ini,',
					' CASE WHEN "', proc, '" <> "DC" ',
						'THEN YEAR("', vg_fecha, '") - 1 ',
						'ELSE YEAR("', vg_fecha, '") ',
					' END) ',
					' FROM rolt003 ',
					' WHERE n03_proceso = "', proc, '")))',
					') + 1) ',
				'FROM rolt003 ',
				'WHERE n03_proceso = "', proc,'"), 0))) ',
			'tot_gan, 0.00 val_pro ',
		' FROM rolt032 ',
		' WHERE n32_compania    = ', cod_cia,
		'   AND n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND n32_fecha_ini  >= "', fec_ini, '"',
		'   AND n32_fecha_fin  <= "', fec_fin, '"',
		'   AND n32_cod_trab    = ', cod_trab,
		'   AND n32_estado     <> "E" '
IF (fec_fin - fec_ini) > r_n90.n90_dias_anio AND proc = 'DC' AND
   YEAR(fec_fin) <> 2008
THEN
	LET query = query CLIPPED,
		' UNION ALL ',
		' SELECT n32_cod_liqrol, n32_fecha_ini, n32_fecha_fin, ',
			'200.00 tot_gan, 0.00 val_pro ',
		' FROM rolt032 ',
		' WHERE n32_compania    = ', cod_cia,
		'   AND n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND n32_fecha_ini  >= MDY(03, 01, 2007) ',
		'   AND n32_fecha_ini  <= MDY(03, 31, 2007) ',
		'   AND n32_cod_trab    = ', cod_trab,
		'   AND n32_estado     <> "E" '
END IF
LET query = query CLIPPED, ' INTO TEMP tmp_pro_rol '
PREPARE cons_liqgan FROM query
EXECUTE cons_liqgan
DECLARE q_liqgan CURSOR FOR SELECT * FROM tmp_pro_rol ORDER BY n32_fecha_ini ASC
LET num_row   = 1
LET tot_gan_g = 0
LET val_gan_g = 0
LET primera   = 1
IF proc = 'DC' THEN
	LET an_a = YEAR(fec_ini) + 1
END IF
FOREACH q_liqgan INTO rh_liqgan[num_row].*
	IF proc = 'FR' THEN
		IF DAY(fec_ini) <> 1 AND primera THEN
			LET fecha = MDY(MONTH(fec_ini), 01, YEAR(fec_ini))
					+ 1 UNITS MONTH - 1 UNITS DAY
			SELECT NVL(n32_tot_gan, 0)
				INTO valor
				FROM rolt032
				WHERE n32_compania   = cod_cia
				  AND n32_cod_liqrol =
					rh_liqgan[num_row].n32_cod_liqrol
				  AND n32_fecha_ini  = fec_ini
				  AND n32_fecha_fin  = fecha
				  AND n32_cod_trab   = cod_trab
			LET rh_liqgan[num_row].n32_tot_gan =
					rh_liqgan[num_row].n32_tot_gan - valor
			SELECT NVL(SUM(n32_tot_gan), 0)
				INTO valor
				FROM rolt032
				WHERE n32_compania     = cod_cia
				  AND n32_cod_liqrol  IN ("Q1", "Q2")
				  AND n32_cod_trab     = cod_trab
				  AND n32_ano_proceso  = YEAR(fec_ini)
				  AND n32_mes_proceso  = MONTH(fec_ini)
				  AND n32_estado       = "C"
			IF vg_codloc <> 1 OR fecha > MDY(06, 30, 2009) THEN
				CALL fl_lee_trabajador_roles(cod_cia, cod_trab)
					RETURNING r_n30.*
				LET fec = MDY(MONTH(r_n30.n30_fecha_ing),
						DAY(r_n30.n30_fecha_ing),
						YEAR(fecha))
				IF r_n30.n30_fecha_reing IS NOT NULL THEN
					LET fec = MDY(
						MONTH(r_n30.n30_fecha_reing),
						DAY(r_n30.n30_fecha_reing),
						YEAR(fecha))
				END IF
				CALL fl_lee_proceso_roles(proc)
					RETURNING r_n03.*
				CASE r_n03.n03_frecuencia
					WHEN 'A' LET fec_ini = fec
					WHEN 'M' LET fec_ini = MDY(MONTH(fecha),
								DAY(fec),
								YEAR(fecha))
				END CASE
				LET num_dias  = (fecha - fec_ini) + 1
				LET fecha_aux = MDY(MONTH(fec_ini), 01,
							YEAR(fec_ini))
				SELECT NVL(SUM(n32_tot_gan), 0)
					INTO valor
					FROM rolt032
					WHERE n32_compania     = cod_cia
					  AND n32_cod_liqrol  IN ("Q1", "Q2")
					  AND n32_cod_trab     = cod_trab
					  AND n32_fecha_ini   >= fecha_aux
					  AND n32_fecha_fin   <= fecha
					  AND n32_estado       = "C"
				LET dias = DAY(fecha)
				IF MONTH(fecha) = 2 THEN
					LET dias = 30
				END IF
				LET rh_liqgan[num_row].n32_tot_gan =
						rh_liqgan[num_row].n32_tot_gan +
						((valor / dias) * num_dias)
			ELSE
				LET num_dias = fec_ini - fecha_aux
				IF num_dias > 180 THEN
					IF num_dias < 300 THEN
						LET fec_ini = MDY(12,
							DAY(fec_ini),
							YEAR(fec_ini) - 1)
					ELSE
						LET fec_ini = MDY(01, 01,
							YEAR(fec_ini))
							- 1 UNITS DAY
					END IF
					LET num_dias = fec_ini - fecha_aux
					IF num_dias > 180 THEN
						LET num_dias = 180
					END IF
				END IF
				LET rh_liqgan[num_row].n32_tot_gan =
						rh_liqgan[num_row].n32_tot_gan +
						(valor * (num_dias / 360))
			END IF
			LET primera = 0
		END IF
	END IF
	IF proc = 'DC' THEN
		LET fact = (fec_fin - fec_ini) + 1
		IF fact > r_n90.n90_dias_anio + 1 THEN
			SELECT n36_fecha_ini, n36_fecha_fin
				INTO fec, fec2
				FROM rolt036
				WHERE n36_compania        = cod_cia
				  AND n36_proceso         = proc
				  AND YEAR(n36_fecha_fin) = an_a
				  AND n36_cod_trab        = cod_trab
			LET fact = (fec2 - fec) + 1
			IF fact > r_n90.n90_dias_anio + 1 THEN
				LET fact = r_n90.n90_dias_anio
			END IF
			IF rh_liqgan[num_row].n32_fecha_fin >= fec AND
			   rh_liqgan[num_row].n32_fecha_fin <= fec2
			THEN
				LET an_a = an_a + 1
			ELSE
				LET an_a =YEAR(rh_liqgan[num_row].n32_fecha_fin)
			END IF
		END IF
		LET r_n03.n03_valor = rh_liqgan[num_row].n32_tot_gan
		IF (rh_liqgan[num_row].n32_fecha_fin > fecha_aux OR
		    fecha_aux IS NULL) AND YEAR(fec_fin) <> 2008
		THEN
			CALL fl_lee_proceso_roles(proc) RETURNING r_n03.*
		END IF
		LET rh_liqgan[num_row].valor_gan = (r_n03.n03_valor / fact) *
					((rh_liqgan[num_row].n32_fecha_fin -
					rh_liqgan[num_row].n32_fecha_ini) + 1)
	ELSE
		IF proc <> 'FR' THEN
			INITIALIZE r_n39.* TO NULL
			IF proc = 'VA' OR proc = 'VP' THEN
				DECLARE q_vac CURSOR FOR
					SELECT * FROM rolt039
					WHERE n39_compania     = cod_cia
					  AND n39_cod_trab     = cod_trab
					  AND n39_periodo_fin >=
						rh_liqgan[num_row].n32_fecha_fin
					ORDER BY n39_periodo_fin ASC
				OPEN q_vac
				FETCH q_vac INTO r_n39.*
				CLOSE q_vac
				FREE q_vac
				IF r_n39.n39_compania IS NOT NULL THEN
					IF r_n39.n39_proceso <> proc THEN
						CONTINUE FOREACH
					END IF
				ELSE
					IF proc = 'VP' AND
					   rh_liqgan[num_row].n32_fecha_fin > vg_fecha
					THEN
						CONTINUE FOREACH
					END IF
				END IF
			END IF
			LET rh_liqgan[num_row].valor_gan =
					rh_liqgan[num_row].n32_tot_gan / fact
			IF r_n39.n39_compania IS NOT NULL THEN
				IF DATE(r_n39.n39_fecing) >= MDY(04, 16, 2009)
				THEN
					LET r_n39.n39_valor_vaca =
						r_n39.n39_valor_vaca / fact
					IF r_n39.n39_valor_vaca >
					   rh_liqgan[num_row].valor_gan
					THEN
					LET rh_liqgan[num_row].valor_gan =
						rh_liqgan[num_row].valor_gan +
						(r_n39.n39_valor_vaca -
						 rh_liqgan[num_row].valor_gan)
					END IF
				END IF
			END IF
		ELSE
			CALL fl_lee_proceso_roles(proc) RETURNING r_n03.*
			IF rh_liqgan[num_row].n32_fecha_fin > MDY(07, 31, 2009)
			THEN
				CASE r_n03.n03_frecuencia
					WHEN 'A'
					LET rh_liqgan[num_row].valor_gan =
						rh_liqgan[num_row].n32_tot_gan
						/ fact
					WHEN 'M'
					INITIALIZE r_n06.* TO NULL
					SELECT * INTO r_n06.*
						FROM rolt006
						WHERE n06_flag_ident = 'FM'
						  AND n06_estado     = 'A'
					CALL fl_lee_rubro_que_se_calcula(
							r_n06.n06_cod_rubro)
						RETURNING r_n07.*
					LET rh_liqgan[num_row].valor_gan =
						rh_liqgan[num_row].n32_tot_gan *
						r_n07.n07_factor / 100
				END CASE
			ELSE
				LET rh_liqgan[num_row].valor_gan =
					rh_liqgan[num_row].n32_tot_gan / fact
			END IF
		END IF
	END IF
	IF ((proc = 'VA' OR proc = 'VP') AND dias_adi > 0 AND
	     rh_liqgan[num_row].n32_fecha_ini >= fecha_aux) OR an_a > 1
	THEN
		IF r_n39.n39_dias_adi IS NOT NULL THEN
			IF rh_liqgan[num_row].n32_fecha_fin <= vg_fecha THEN
				LET dias_adi = r_n39.n39_dias_adi
			END IF
		ELSE
			LET dias_adi = d_a
		END IF
		LET val_adi = ((rh_liqgan[num_row].valor_gan /
				  r_n00.n00_dias_vacac) * dias_adi)
		LET rh_liqgan[num_row].valor_gan =rh_liqgan[num_row].valor_gan +
						val_adi
		IF r_n39.n39_compania IS NOT NULL THEN
			IF DATE(r_n39.n39_fecing) >= MDY(04, 16, 2009)
			THEN
				LET r_n39.n39_valor_adic =
						r_n39.n39_valor_adic / fact
				IF r_n39.n39_valor_adic > val_adi THEN
					LET rh_liqgan[num_row].valor_gan =
						rh_liqgan[num_row].valor_gan +
						(r_n39.n39_valor_adic - val_adi)
				END IF
			END IF
		END IF
	END IF
	LET tot_gan_g = tot_gan_g + rh_liqgan[num_row].n32_tot_gan
	LET val_gan_g = val_gan_g + rh_liqgan[num_row].valor_gan
	LET num_row   = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
DROP TABLE tmp_pro_rol
IF creo_tmp THEN
	DROP TABLE t1
END IF
LET num_row = num_row - 1
IF num_row = 0 THEN
       	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_liqgan
	RETURN
END IF
CALL fl_lee_departamento(cod_cia, r_n30.n30_cod_depto) RETURNING r_g34.*
CALL fl_lee_cargo(cod_cia, r_n30.n30_cod_cargo) RETURNING r_g35.*
IF proc_aux IS NOT NULL THEN
	LET proc = proc_aux
END IF
CALL fl_lee_proceso_roles(proc) RETURNING r_n03.*
LET anio_f = YEAR(fec_fin)
DISPLAY BY NAME	r_n30.n30_cod_trab, r_n30.n30_nombres, r_n30.n30_cod_cargo,
		r_g35.g35_nombre, r_n30.n30_cod_depto, r_g34.g34_nombre,
		r_n03.n03_proceso, r_n03.n03_nombre_abr, anio_i, anio_f,
		tot_gan_g, val_gan_g
LET max_row = num_row
CALL set_count(max_row)
LET int_flag = 0
DISPLAY ARRAY rh_liqgan TO rh_liqgan.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
				'NOMINA', vg_separador, 'fuentes', vg_separador,
				'; fglrun rolp108 ', vg_base, ' RO ', vg_codcia,
				' ', cod_trab
		RUN comando
		LET int_flag = 0
	ON KEY(F6)
		LET num_row = arr_curr()
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
				'NOMINA', vg_separador, 'fuentes', vg_separador,
				'; fglrun rolp303 ', vg_base, ' RO ', vg_codcia,
				' "', rh_liqgan[num_row].n32_cod_liqrol, '" ',
				'"', rh_liqgan[num_row].n32_fecha_ini, '" ',
				'"', rh_liqgan[num_row].n32_fecha_fin, '" "N" ',
				r_n30.n30_cod_depto, ' ', cod_trab
		RUN comando
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW
		--#LET num_row = arr_curr()
		--#DISPLAY BY NAME num_row, max_row
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLOSE WINDOW w_liqgan
RETURN

END FUNCTION



FUNCTION fl_ayuda_porc_ice(codcia)
DEFINE codcia		LIKE srit010.s10_compania
DEFINE rh_por_ice		ARRAY[500] OF RECORD
				s10_codigo	LIKE srit010.s10_codigo,
				s10_porcentaje_ice LIKE srit010.s10_porcentaje_ice,
				s10_codigo_impto LIKE srit010.s10_codigo_impto,
				s10_descripcion	LIKE srit010.s10_descripcion
			END RECORD
DEFINE query		CHAR(800)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_por_ice AT 06, 13 WITH num_fil ROWS, 66 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf169 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf169'
ELSE
	OPEN FORM f_ayuf169 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf169c'
END IF
DISPLAY FORM f_ayuf169
--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY "%"			TO tit_col2
--#DISPLAY "Cod.Imp."		TO tit_col3
--#DISPLAY 'Descripción'	TO tit_col4
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT s10_codigo, s10_porcentaje_ice, ',
				's10_codigo_impto, s10_descripcion',
			' FROM srit010 ',
			' WHERE s10_compania = ', codcia,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE por_ice FROM query
		DECLARE q_por_ice CURSOR FOR por_ice
		LET i = 1
		FOREACH q_por_ice INTO rh_por_ice[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE '                                           '
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_por_ice TO rh_por_ice.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_por_ice[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		EXIT WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_por_ice
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_por_ice[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_por_ice[1].* TO NULL
        RETURN rh_por_ice[1].s10_codigo, rh_por_ice[1].s10_porcentaje_ice,
		rh_por_ice[1].s10_codigo_impto
END IF
LET i = arr_curr()
RETURN rh_por_ice[i].s10_codigo, rh_por_ice[i].s10_porcentaje_ice,
	rh_por_ice[i].s10_codigo_impto

END FUNCTION



FUNCTION fl_ayuda_codigos_sri(codcia, tipo_ret, porc_ret, estado,codigo_cp,flag)
DEFINE codcia		LIKE ordt003.c03_compania
DEFINE tipo_ret		LIKE ordt003.c03_tipo_ret
DEFINE porc_ret		LIKE ordt003.c03_porcentaje
DEFINE estado		LIKE ordt003.c03_estado
DEFINE codigo_cp	INTEGER
DEFINE flag		CHAR(1)
DEFINE rh_sri		ARRAY[1500] OF RECORD
			c03_codigo_sri		LIKE ordt003.c03_codigo_sri,
			c03_concepto_ret	LIKE ordt003.c03_concepto_ret,
			c03_fecha_ini_porc	LIKE ordt003.c03_fecha_ini_porc,
			c03_fecha_fin_porc	LIKE ordt003.c03_fecha_fin_porc,
			c03_tipo_fuente		LIKE ordt003.c03_tipo_fuente,
			c03_estado		LIKE ordt003.c03_estado,
			imp_asig		CHAR(1)
			END RECORD
DEFINE query		CHAR(1200)
DEFINE campo		VARCHAR(100)
DEFINE tabla		VARCHAR(25)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_por		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_join	CHAR(300)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE r_c02		RECORD LIKE ordt002.*

LET filas_pant = 10
LET max_row    = 1500
LET ini_rows   = 04
LET num_rows   = 18
LET num_cols   = 79
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 18
	LET num_cols = 78
END IF
OPEN WINDOW wh_sri AT ini_rows, 02 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf170 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf170'
ELSE
	OPEN FORM f_ayuf170 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf170c'
END IF
DISPLAY FORM f_ayuf170
--#DISPLAY 'Código'		TO tit_col1 
--#DISPLAY 'Concepto'		TO tit_col2 
--#DISPLAY 'Fecha Ini.'		TO tit_col3 
--#DISPLAY 'Fecha Fin.'		TO tit_col4 
--#DISPLAY 'T'			TO tit_col5 
--#DISPLAY 'E'			TO tit_col6 
--#DISPLAY 'A'			TO tit_col7 
DISPLAY tipo_ret TO c03_tipo_ret
DISPLAY porc_ret TO c03_porcentaje
INITIALIZE r_c02.* TO NULL
SELECT * INTO r_c02.*
	FROM ordt002
	WHERE c02_compania    = codcia
	  AND c02_tipo_ret    = tipo_ret
	  AND c02_porcentaje  = porc_ret
DISPLAY BY NAME r_c02.c02_nombre
IF r_c02.c02_nombre IS NULL THEN
	DISPLAY 'T O D O S' TO c02_nombre
END IF
LET expr_tip = NULL
IF tipo_ret IS NOT NULL AND r_c02.c02_compania IS NOT NULL THEN
	LET expr_tip = '   AND c03_tipo_ret   = "', tipo_ret, '"'
END IF
LET expr_por = NULL
IF porc_ret IS NOT NULL AND r_c02.c02_compania IS NOT NULL THEN
	LET expr_por = '   AND c03_porcentaje = ', porc_ret
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND c03_estado     = "', estado, '"'
END IF
CASE flag
	WHEN 'C'
		LET campo = ', CASE WHEN z08_codcli IS NOT NULL ',
					' THEN "S" ',
					' ELSE "N" ',
				' END '
		LET tabla = ', OUTER cxct008'
		LET expr_join = '   AND z08_compania   = c03_compania ',
				'   AND z08_codcli     = ', codigo_cp,
				'   AND z08_tipo_ret   = c03_tipo_ret ',
				'   AND z08_porcentaje = c03_porcentaje ',
				'   AND z08_codigo_sri = c03_codigo_sri ',
			'   AND z08_fecha_ini_porc = c03_fecha_ini_porc '
	WHEN 'P'
		LET campo = ', CASE WHEN p05_codprov IS NOT NULL ',
					' THEN "S" ',
					' ELSE "N" ',
				' END '
		LET tabla = ', OUTER cxpt005'
		LET expr_join = '   AND p05_compania   = c03_compania ',
				'   AND p05_codprov    = ', codigo_cp,
				'   AND p05_tipo_ret   = c03_tipo_ret ',
				'   AND p05_porcentaje = c03_porcentaje ',
				'   AND p05_codigo_sri = c03_codigo_sri ',
			'   AND p05_fecha_ini_porc = c03_fecha_ini_porc '
	WHEN 'T'
		LET campo     = ', "N" '
		LET tabla     = NULL
		LET expr_join = NULL
END CASE
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	IF flag = 'T' THEN
		LET vm_columna_1 = 3
	ELSE
		LET vm_columna_1 = 6
	END IF
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT c03_codigo_sri, c03_concepto_ret,',
				' c03_fecha_ini_porc, c03_fecha_fin_porc,',
				' c03_tipo_fuente, c03_estado ', campo CLIPPED,
			' FROM ordt003 ', tabla CLIPPED,
			' WHERE c03_compania   = ', codcia,
			'   AND c03_fecha_fin_porc IS NULL ',
				expr_tip CLIPPED,
				expr_por CLIPPED,
				expr_est CLIPPED,
				expr_join CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE sri FROM query
		DECLARE q_sri CURSOR FOR sri
		LET i = 1
		FOREACH q_sri INTO rh_sri[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_sri TO rh_sri.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_sri[i].*
				END FOR
				EXIT DISPLAY
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
			ON KEY(F20)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F21)
				LET col = 7
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
				--#DISPLAY rh_sri[j].c03_concepto_ret TO
					--#concepto
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_sri[i].* TO NULL
			CLEAR rh_sri[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_sri
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_sri[1].* TO NULL
        RETURN rh_sri[1].c03_codigo_sri, rh_sri[1].c03_concepto_ret,
		rh_sri[1].c03_fecha_ini_porc
END IF
LET i = arr_curr()
RETURN rh_sri[i].c03_codigo_sri, rh_sri[i].c03_concepto_ret,
	rh_sri[i].c03_fecha_ini_porc

END FUNCTION



FUNCTION fl_ver_comprobantes_emitidos_caja(tipo_fuente, num_fuente,tipo_destino,
						num_destino, codcli)
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE num_destino	LIKE cajt010.j10_num_destino
DEFINE codcli		LIKE cajt010.j10_codcli	
DEFINE rs		RECORD LIKE cxct024.*	
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = NULL
CASE tipo_fuente
	WHEN 'PV'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'vehp304 ', vg_base, ' ',
			      'VE', vg_codcia, ' ', vg_codloc,
			      ' ', tipo_destino, ' ', num_destino
	WHEN 'PR'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp308 ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc,
			      ' ', tipo_destino, ' ', num_destino
	WHEN 'OT'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp308 ', vg_base, ' ',
			      'TA ', vg_codcia, ' ', vg_codloc, ' ', num_destino
	WHEN 'SC'
		CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,num_fuente)
			RETURNING rs.*
		CASE rs.z24_tipo 
			WHEN 'P'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cxcp202 ', vg_base, ' ',
			      'CO ', vg_codcia, ' ', vg_codloc, ' ', 
			      codcli, ' ', tipo_destino, ' ', num_destino
			WHEN 'A'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cxcp201 ', vg_base, ' ',
			      'CO ', vg_codcia, ' ', vg_codloc, ' ', 
			      codcli, ' ', tipo_destino, ' ', num_destino
		END CASE
	WHEN 'EC'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'CAJA', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cajp207 ', vg_base, ' ',
			      'CG ', vg_codcia, ' ', vg_codloc, ' ',  
			      tipo_fuente, num_fuente
END CASE
IF comando IS NOT NULL THEN
	RUN comando
END IF

END FUNCTION



FUNCTION fl_ayuda_tipo_arch_iess(codcia)
DEFINE codcia		LIKE rolt022.n22_compania
DEFINE rh_tip_arch_iess	ARRAY[50] OF RECORD
				n22_codigo_arch	LIKE rolt022.n22_codigo_arch,
				n22_tipo_arch	LIKE rolt022.n22_tipo_arch,
				n22_descripcion	LIKE rolt022.n22_descripcion,
				n22_proceso	LIKE rolt022.n22_proceso,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr
			END RECORD
DEFINE nom		ARRAY[50] OF LIKE rolt022.n22_nombre_arch
DEFINE query		CHAR(1200)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 50
LET ini_rows   = 06
LET num_rows   = 16
LET num_cols   = 71
IF vg_gui = 0 THEN
	LET ini_rows = 07
	LET num_rows = 15
	LET num_cols = 72
END IF
OPEN WINDOW wh_tip_arch_iess AT ini_rows, 08
	WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf171 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf171'
ELSE
	OPEN FORM f_ayuf171 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf171c'
END IF
DISPLAY FORM f_ayuf171
--#DISPLAY 'Código'		TO tit_col1 
--#DISPLAY 'Tipo'		TO tit_col2 
--#DISPLAY 'Descripcion'	TO tit_col3 
--#DISPLAY 'CP'			TO tit_col4 
--#DISPLAY 'Proceso'		TO tit_col5 
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 3
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT n22_codigo_arch, n22_tipo_arch,',
				' n22_descripcion, n22_proceso,',
				' n03_nombre_abr, n22_nombre_arch ',
			' FROM rolt022, OUTER rolt003 ',
			' WHERE n22_compania = ', codcia,
			'   AND n03_proceso  = n22_proceso ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE tip_arch_iess FROM query
		DECLARE q_tip_arch_iess CURSOR FOR tip_arch_iess
		LET i = 1
		FOREACH q_tip_arch_iess INTO rh_tip_arch_iess[i].*, nom[i]
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_tip_arch_iess TO rh_tip_arch_iess.*
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_tip_arch_iess[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
				--#DISPLAY nom[j] TO n22_nombre_arch
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_tip_arch_iess
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_tip_arch_iess[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tip_arch_iess[1].* TO NULL
        RETURN rh_tip_arch_iess[1].n22_codigo_arch,
		rh_tip_arch_iess[1].n22_tipo_arch
END IF
LET i = arr_curr()
RETURN rh_tip_arch_iess[i].n22_codigo_arch, rh_tip_arch_iess[i].n22_tipo_arch

END FUNCTION



FUNCTION fl_ayuda_codigos_sri_gen(codcia, estado)
DEFINE codcia		LIKE ordt003.c03_compania
DEFINE estado		LIKE ordt003.c03_estado
DEFINE rh_sri		ARRAY[1500] OF RECORD
			c03_codigo_sri		LIKE ordt003.c03_codigo_sri,
			c03_concepto_ret	LIKE ordt003.c03_concepto_ret,
			c03_fecha_ini_porc	LIKE ordt003.c03_fecha_ini_porc,
			c03_tipo_fuente		LIKE ordt003.c03_tipo_fuente,
			c03_estado		LIKE ordt003.c03_estado
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 1500
LET ini_rows   = 04
LET num_rows   = 16
LET num_cols   = 65
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 16
	LET num_cols = 66
END IF
OPEN WINDOW wh_sri2 AT ini_rows, 14 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf172 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf172'
ELSE
	OPEN FORM f_ayuf172 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf172c'
END IF
DISPLAY FORM f_ayuf172
--#DISPLAY 'Código'		TO tit_col1 
--#DISPLAY 'Concepto'		TO tit_col2 
--#DISPLAY 'Fecha Ini.'		TO tit_col3 
--#DISPLAY 'T'			TO tit_col4 
--#DISPLAY 'E'			TO tit_col5 
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '   AND c03_estado     = "', estado, '"'
END IF
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT UNIQUE c03_codigo_sri, c03_concepto_ret,',
				' c03_fecha_ini_porc, c03_tipo_fuente,',
				' c03_estado ',
			' FROM ordt003 ',
			' WHERE c03_compania   = ', codcia,
			'   AND c03_fecha_fin_porc IS NULL ',
				expr_est CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE sri2 FROM query
		DECLARE q_sri2 CURSOR FOR sri2
		LET i = 1
		FOREACH q_sri2 INTO rh_sri[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_sri TO rh_sri.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
                		LET salir    = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_sri[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
				--#DISPLAY rh_sri[j].c03_concepto_ret TO
					--#concepto
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_sri[i].* TO NULL
			CLEAR rh_sri[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_sri2
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_sri[1].* TO NULL
        RETURN rh_sri[1].c03_codigo_sri, rh_sri[1].c03_concepto_ret,
		rh_sri[1].c03_fecha_ini_porc
END IF
LET i = arr_curr()
RETURN rh_sri[i].c03_codigo_sri, rh_sri[i].c03_concepto_ret,
	rh_sri[i].c03_fecha_ini_porc

END FUNCTION



FUNCTION fl_ayuda_estado_activos(codcia, tipo)
DEFINE codcia		LIKE actt006.a06_compania
DEFINE tipo		SMALLINT
DEFINE rh_estado	ARRAY[50] OF RECORD
				a06_estado	LIKE actt006.a06_estado,
				a06_descripcion	LIKE actt006.a06_descripcion
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 50
LET ini_rows   = 04
LET num_rows   = 15
LET num_cols   = 33
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 16
	LET num_cols = 34
END IF
OPEN WINDOW wh_ayuf173 AT ini_rows, 46 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf173 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf173'
ELSE
	OPEN FORM f_ayuf173 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf173c'
END IF
DISPLAY FORM f_ayuf173
--#DISPLAY 'E'			TO tit_col1 
--#DISPLAY 'Descripcion'	TO tit_col2 
LET expr_est = NULL
IF tipo THEN
	LET expr_est = '   AND a06_estado   NOT IN ("A", "B")'
END IF
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT a06_estado, CASE WHEN ', tipo,
					' = 0 OR a06_estado <> "S" ',
					'THEN a06_descripcion ',
					'ELSE "DEPRECIANDOSE" ',
				'END ',
			' FROM actt006 ',
			' WHERE a06_compania = ', codcia,
			expr_est CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE actest FROM query
		DECLARE q_actest CURSOR FOR actest
		LET i = 1
		FOREACH q_actest INTO rh_estado[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_estado TO rh_estado.*
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_estado[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_estado[i].* TO NULL
			CLEAR rh_estado[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ayuf173
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_estado[1].* TO NULL
	RETURN rh_estado[1].a06_estado, rh_estado[1].a06_descripcion
END IF
LET i = arr_curr()
RETURN rh_estado[i].a06_estado, rh_estado[i].a06_descripcion

END FUNCTION



FUNCTION fl_ayuda_tipo_trans_act(estado)
DEFINE estado		LIKE actt004.a04_estado
DEFINE rh_tipo_tr_af	ARRAY[50] OF RECORD
				a04_codigo_proc	LIKE actt004.a04_codigo_proc,
				a04_nombre	LIKE actt004.a04_nombre,
				a04_estado	LIKE actt004.a04_estado,
				a04_periocidad	LIKE actt004.a04_periocidad
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 50
LET ini_rows   = 04
LET num_rows   = 15
LET num_cols   = 35
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 16
	LET num_cols = 36
END IF
OPEN WINDOW wh_ayuf174 AT ini_rows, 44 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf174 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf174'
ELSE
	OPEN FORM f_ayuf174 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf174c'
END IF
DISPLAY FORM f_ayuf174
--#DISPLAY 'TP'			TO tit_col1 
--#DISPLAY 'Descripcion'	TO tit_col2 
--#DISPLAY 'E'			TO tit_col3 
--#DISPLAY 'P'			TO tit_col4 
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	LET expr_est = NULL
	IF estado <> 'T' THEN
		LET expr_est = ' WHERE a04_estado = "', estado, '"'
	END IF
	WHILE NOT salir
		LET query = 'SELECT a04_codigo_proc, a04_nombre, a04_estado, ',
				'a04_periocidad ',
			' FROM actt004 ',
			expr_est CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE acttiptr FROM query
		DECLARE q_acttiptr CURSOR FOR acttiptr
		LET i = 1
		FOREACH q_acttiptr INTO rh_tipo_tr_af[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_tipo_tr_af TO rh_tipo_tr_af.*
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_tipo_tr_af[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_tipo_tr_af[i].* TO NULL
			CLEAR rh_tipo_tr_af[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ayuf174
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tipo_tr_af[1].* TO NULL
	RETURN rh_tipo_tr_af[1].a04_codigo_proc, rh_tipo_tr_af[1].a04_nombre
END IF
LET i = arr_curr()
RETURN rh_tipo_tr_af[i].a04_codigo_proc, rh_tipo_tr_af[i].a04_nombre

END FUNCTION



FUNCTION fl_ayuda_items_compuestos(codcia, codloc, tipo)
DEFINE codcia		LIKE rept046.r46_compania
DEFINE codloc		LIKE rept046.r46_localidad
DEFINE tipo		CHAR(1)
DEFINE rh_item_comp	ARRAY[10000] OF RECORD
				composicion	LIKE rept046.r46_composicion,
				item_comp	LIKE rept046.r46_item_comp,
				desc_comp	LIKE rept046.r46_desc_comp,
				estado		VARCHAR(15)
			END RECORD
DEFINE query		CHAR(2500)
DEFINE expr_sql		CHAR(500)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 10000
LET ini_rows   = 04
LET num_rows   = 14
LET num_cols   = 64
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 15
	LET num_cols = 78
END IF
OPEN WINDOW wh_ayuf175 AT ini_rows, 16 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf175 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf175'
ELSE
	OPEN FORM f_ayuf175 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf175c'
END IF
DISPLAY FORM f_ayuf175
--#DISPLAY 'Comp.'	 TO tit_col1 
--#DISPLAY 'Item'	 TO tit_col2 
--#DISPLAY 'Descripción' TO tit_col3 
--#DISPLAY 'Estado'	 TO tit_col4 
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET expr_sql = NULL
	IF tipo = 'I' THEN
		LET expr_sql = '  AND NOT EXISTS ',
				'(SELECT 1 FROM rept020 ',
					'WHERE r20_compania  = r46_compania ',
					'  AND r20_localidad = r46_localidad ',
					'  AND r20_item      = r46_item_comp) '
	END IF
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT 0, r10_codigo, r10_nombre, ',
					'"EN PROCESO" ',
				'FROM rept010 ',
				'WHERE r10_compania    = ', codcia,
				'  AND r10_estado      = "B" ',
				'  AND r10_costo_mb    < 0 ',
				'  AND r10_comentarios MATCHES "$*SID*"',
				'  AND NOT EXISTS ',
					'(SELECT 1 FROM rept046 ',
					'WHERE r46_compania  = r10_compania ',
					'  AND r46_item_comp = r10_codigo) ',
			'UNION ',
			'SELECT r46_composicion, ',
					'r46_item_comp, r46_desc_comp, ',
					'CASE WHEN r46_estado = "C" ',
						'THEN "COMPUESTO" ',
						'ELSE "EN PROCESO" ',
					'END ',
				'FROM rept046 ',
				'WHERE r46_compania    = ', codcia,
				'  AND r46_localidad   = ', codloc,
				expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_item_comp FROM query
		DECLARE q_cons_item_comp CURSOR FOR cons_item_comp
		LET i = 1
		FOREACH q_cons_item_comp INTO rh_item_comp[i].*
			IF rh_item_comp[i].composicion = 0 THEN
				LET rh_item_comp[i].composicion = NULL
			END IF
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_item_comp TO rh_item_comp.*
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_item_comp[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_item_comp[i].* TO NULL
			CLEAR rh_item_comp[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ayuf175
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_item_comp[1].* TO NULL
	RETURN rh_item_comp[1].composicion, rh_item_comp[1].item_comp,
		rh_item_comp[1].desc_comp
END IF
LET i = arr_curr()
RETURN rh_item_comp[i].composicion, rh_item_comp[i].item_comp,
	rh_item_comp[i].desc_comp

END FUNCTION



FUNCTION fl_ejecuta_reporte_pdf(codloc, prog_web, explorador)
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE prog_web		CHAR(195)
DEFINE explorador	CHAR(1)
DEFINE comando		CHAR(256)
DEFINE exec_expl	CHAR(19)
DEFINE serv		CHAR(4)
DEFINE err_flag		INTEGER
DEFINE sesionid		INTEGER

SQL
	SELECT (sid + pid + uid)
		INTO $sesionid
		FROM sysmaster:syssessions
		WHERE sid = DBINFO("sessionid")
END SQL
LET serv = '4'
CASE codloc
	WHEN 1 LET serv = '4.1'
	WHEN 3 LET serv = '1.11'
	WHEN 5 LET serv = '1.11'
END CASE
CASE explorador
	WHEN 'F' LET exec_expl = 'firefox -new-window'
	WHEN 'I' LET exec_expl = 'iexplore -new'
END CASE
LET comando = "cmd /C start /B ", exec_expl CLIPPED, " http://192.168.",
		serv CLIPPED, ":8080/", prog_web CLIPPED,
		"%26sesid=", sesionid USING "<<<<<<&", "%26usr=",
		DOWNSHIFT(vg_usuario) CLIPPED
--#CALL WinExec(comando) RETURNING err_flag

END FUNCTION



FUNCTION fl_ayuda_tipo_ident_bod(codcia, estado)
DEFINE codcia		LIKE rept009.r09_compania
DEFINE estado		LIKE rept009.r09_estado
DEFINE rh_tipo_ident	ARRAY[50] OF RECORD
				r09_tipo_ident	LIKE rept009.r09_tipo_ident,
				r09_descripcion	LIKE rept009.r09_descripcion,
				r09_estado	LIKE rept009.r09_estado
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT

LET filas_pant = 10
LET max_row    = 50
LET ini_rows   = 04
LET num_rows   = 15
LET num_cols   = 47
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 16
	LET num_cols = 48
END IF
OPEN WINDOW wh_ayuf176 AT ini_rows, 32 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf176 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf176'
ELSE
	OPEN FORM f_ayuf176 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf176c'
END IF
DISPLAY FORM f_ayuf176
--#DISPLAY 'T'			TO tit_col1 
--#DISPLAY 'Descripcion'	TO tit_col2 
--#DISPLAY 'E'			TO tit_col3 
WHILE TRUE
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	LET expr_est = NULL
	IF estado <> 'T' THEN
		LET expr_est = ' WHERE r09_estado = "', estado, '"'
	END IF
	WHILE NOT salir
		LET query = 'SELECT r09_tipo_ident, r09_descripcion,r09_estado',
			' FROM rept009 ',
			expr_est CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE tipoident FROM query
		DECLARE q_tipoident CURSOR FOR tipoident
		LET i = 1
		FOREACH q_tipoident INTO rh_tipo_ident[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_tipo_ident TO rh_tipo_ident.*
			ON KEY(RETURN)
				LET salir = 1
				DISPLAY j TO num_row
				DISPLAY i TO max_row
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_tipo_ident[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 3
				EXIT DISPLAY
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF int_flag = 4 THEN
		FOR i = 1 TO filas_pant
			INITIALIZE rh_tipo_ident[i].* TO NULL
			CLEAR rh_tipo_ident[i].*
		END FOR
	END IF
	IF NOT salir THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ayuf176
		EXIT WHILE
	END IF
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tipo_ident[1].* TO NULL
	RETURN rh_tipo_ident[1].r09_tipo_ident, rh_tipo_ident[1].r09_descripcion
END IF
LET i = arr_curr()
RETURN rh_tipo_ident[i].r09_tipo_ident, rh_tipo_ident[i].r09_descripcion

END FUNCTION



FUNCTION fl_ayuda_transaccion_remota(cod_cia, tip_tran)
DEFINE cod_cia		LIKE rept090.r90_compania
DEFINE tip_tran		LIKE rept090.r90_cod_tran
DEFINE cod_loc		LIKE rept090.r90_localidad
DEFINE rh_transac	ARRAY[20000] OF RECORD
			   	r90_cod_tran   	LIKE rept090.r90_cod_tran,
			   	r90_num_tran   	LIKE rept090.r90_num_tran,
			   	r91_nomcli     	LIKE rept091.r91_nomcli,
			   	r90_fecing	DATE,
				g02_abreviacion	LIKE gent002.g02_abreviacion
			END RECORD
DEFINE rh_loc		ARRAY[20000] OF LIKE rept090.r90_localidad
DEFINE expr_tran	VARCHAR(100)
DEFINE criterio		CHAR(800)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(2500)	## Contiene todo el query preparado
DEFINE filas_max, i, j	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE fil_ini, fil_fin	SMALLINT
DEFINE col_ini, col_fin	SMALLINT
DEFINE primera		SMALLINT

LET fil_ini = 6
LET col_ini = 12
LET fil_fin = 14
LET col_fin = 67
IF vg_gui = 0 THEN
	LET fil_ini = 5
	LET col_ini = 11
	LET fil_fin = 16
	LET col_fin = 68
END IF
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12
OPEN WINDOW w_ayuf177 AT fil_ini, col_ini WITH fil_fin ROWS, col_fin COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf177 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf177'
ELSE
	OPEN FORM f_ayuf177 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf177c'
END IF
DISPLAY FORM f_ayuf177
LET filas_max  = 20000
LET filas_pant = fgl_scr_size('rh_transac')
--#DISPLAY 'TP'		TO tit_col1
--#DISPLAY 'Número'	TO tit_col2
IF tip_tran = "FA" OR tip_tran = "DF" OR tip_tran = "AF" THEN
	--#DISPLAY 'Cliente'	TO tit_col3
ELSE
	IF tip_tran = "CL" OR tip_tran = "DC" THEN
		--#DISPLAY 'Proveedor'   TO tit_col3
	ELSE
		--#DISPLAY 'Descripcion' TO tit_col3
	END IF
END IF
--#DISPLAY 'Fecha'	TO tit_col4
--#DISPLAY 'Localidad'	TO tit_col5
LET primera = 1
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	IF tip_tran <> '00' THEN 
		DISPLAY tip_tran TO r90_cod_tran
	END IF
	IF NOT primera THEN
		LET int_flag = 0
		CONSTRUCT BY NAME criterio ON r90_num_tran, r91_nomcli,
				r90_fecing, g02_abreviacion
		IF int_flag THEN
			CLOSE WINDOW w_ayuf177
			EXIT WHILE
		END IF
	ELSE
		LET criterio = " 1 = 1 "
	END IF
	LET primera = 0
	MESSAGE "Seleccionando datos .."
	LET expr_tran = NULL
	IF tip_tran <> '00' THEN 
		LET expr_tran = "   AND r90_cod_tran  = '", tip_tran, "'"
	END IF
	LET vm_columna_1           = 2
	LET vm_columna_2           = 4
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT UNIQUE r90_cod_tran, r90_num_tran, ",
					"CASE WHEN r90_cod_tran IN ('FA', ",
						"'DF', 'AF', 'DC', 'CL') ",
						"THEN r91_nomcli ",
						"ELSE r91_referencia ",
					"END, ",
					"DATE(r90_fecing), g02_abreviacion, ",
					"r90_localidad ",
				" FROM rept090, rept091, rept092, gent002",
				" WHERE r90_compania  = ", cod_cia,
				expr_tran CLIPPED,
				"   AND ", criterio CLIPPED,
				"   AND r91_compania  = r90_compania ",
				"   AND r91_localidad = r90_localidad ",
				"   AND r91_cod_tran  = r90_cod_tran ",
				"   AND r91_num_tran  = r90_num_tran ",
				"   AND r92_compania  = r91_compania ",
				"   AND r92_localidad = r91_localidad ",
				"   AND r92_cod_tran  = r91_cod_tran ",
				"   AND r92_num_tran  = r91_num_tran ",
				"   AND r92_cant_ven  > ",
					"NVL((SELECT SUM(r68_cantidad) ",
					"FROM rept068 ",
					"WHERE r68_compania  = r92_compania ",
					"  AND r68_localidad = r92_localidad ",
					"  AND r68_cod_tran  = r92_cod_tran ",
					"  AND r68_num_tran  = r92_num_tran),0) ",
				"   AND g02_compania  = r91_compania ",
				"   AND g02_localidad = r91_localidad ",
				" ORDER BY ", vm_columna_1, " ",
					rm_orden[vm_columna_1], ", ",
					vm_columna_2, " ",rm_orden[vm_columna_2]
		PREPARE transac1_2 FROM query
		DECLARE q_transac1_2 CURSOR FOR transac1_2
		LET i = 1
		FOREACH q_transac1_2 INTO rh_transac[i].*, rh_loc[i]
	        	LET i = i + 1
	        	IF i > filas_max THEN
	                	EXIT FOREACH
	       	 	END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			LET salir = 0
			LET i     = 0
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			MESSAGE "                      "
		END IF
		CALL set_count(i)
		LET int_flag = 0
		DISPLAY ARRAY rh_transac TO rh_transac.*
			ON KEY(F2)
				LET int_flag = 4
		                FOR i = 1 TO filas_pant
                	                CLEAR rh_transac[i].*
	                        END FOR
				EXIT DISPLAY
			ON KEY(RETURN)
                        	LET salir = 1
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#MESSAGE j, ' de ', i
                	--#AFTER DISPLAY
                        	--#LET salir = 1
		END DISPLAY
        	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                	EXIT WHILE
        	END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
                        	LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
                       		LET vm_columna_1           = col
                	END IF
                	IF rm_orden[vm_columna_1] = 'ASC' THEN
                        	LET rm_orden[vm_columna_1] = 'DESC'
                	ELSE
                        	LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
                	INITIALIZE col TO NULL
        	END IF
	END WHILE
	IF i = 0 THEN
        	CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_ayuf177
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_transac[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_transac[1].*, rh_loc[1] TO NULL
	RETURN rh_loc[1], rh_transac[1].r90_cod_tran,rh_transac[1].r90_num_tran,
		rh_transac[1].r91_nomcli
END IF
LET i = arr_curr()
RETURN rh_loc[i], rh_transac[i].r90_cod_tran, rh_transac[i].r90_num_tran,
	rh_transac[i].r91_nomcli

END FUNCTION



FUNCTION fl_ayuda_zonas(codcia, codloc, estado)
DEFINE codcia		LIKE rept108.r108_compania
DEFINE codloc		LIKE rept108.r108_localidad
DEFINE estado		LIKE rept108.r108_estado
DEFINE rh_zona		ARRAY[500] OF RECORD
				r108_cod_zona	LIKE rept108.r108_cod_zona,
				r108_descripcion LIKE rept108.r108_descripcion,
				r108_estado	LIKE rept108.r108_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r108		RECORD LIKE rept108.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_zona AT 06, 29 WITH num_fil ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf178 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf178'
ELSE
	OPEN FORM f_ayuf178 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf178c'
END IF
DISPLAY FORM f_ayuf178
--#DISPLAY "Zona"		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY "E"			TO tit_col3
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r108_estado   = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r108_cod_zona, r108_descripcion
		IF int_flag THEN
			CLOSE WINDOW wh_zona
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 5
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM rept108 ',
				'WHERE r108_compania  = ', codcia,
				'  AND r108_localidad = ', codloc,
				expr_est CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_zona FROM query
		DECLARE q_cons_zona CURSOR FOR cons_zona
		LET i = 1
		FOREACH q_cons_zona INTO r_r108.*
			LET rh_zona[i].r108_cod_zona    = r_r108.r108_cod_zona
			LET rh_zona[i].r108_descripcion =r_r108.r108_descripcion
			LET rh_zona[i].r108_estado      = r_r108.r108_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_zona TO rh_zona.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_zona[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 5
				EXIT DISPLAY
			ON KEY(F17)
				IF estado = 'T' THEN
					LET col = 4
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_zona
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_zona[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_zona[1].* TO NULL
        RETURN rh_zona[1].r108_cod_zona, rh_zona[1].r108_descripcion
END IF
LET i = arr_curr()
RETURN rh_zona[i].r108_cod_zona, rh_zona[i].r108_descripcion

END FUNCTION



FUNCTION fl_ayuda_subzonas(codcia, codloc, zona, estado)
DEFINE codcia		LIKE rept109.r109_compania
DEFINE codloc		LIKE rept109.r109_localidad
DEFINE zona		LIKE rept109.r109_cod_zona
DEFINE estado		LIKE rept109.r109_estado
DEFINE rh_subzona	ARRAY[500] OF RECORD
				r109_cod_zona	LIKE rept109.r109_cod_zona,
				r109_cod_subzona LIKE rept109.r109_cod_subzona,
				r109_descripcion LIKE rept109.r109_descripcion,
				r109_estado	LIKE rept109.r109_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_zon		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r109		RECORD LIKE rept109.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_subzona AT 06, 25 WITH num_fil ROWS, 54 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf179 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf179'
ELSE
	OPEN FORM f_ayuf179 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf179c'
END IF
DISPLAY FORM f_ayuf179
--#DISPLAY "Zona"		TO tit_col1
--#DISPLAY "Sub."		TO tit_col2
--#DISPLAY 'Descripción'	TO tit_col3
--#DISPLAY "E"			TO tit_col4
LET expr_zon = NULL
IF zona <> 0 THEN
	LET expr_zon = '  AND r109_cod_zona = ', zona
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r109_estado   = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r109_cod_zona, r109_cod_subzona,
						r109_descripcion
		IF int_flag THEN
			CLOSE WINDOW wh_subzona
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 6
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM rept109 ',
				'WHERE r109_compania  = ', codcia,
				'  AND r109_localidad = ', codloc,
				expr_zon CLIPPED,
				expr_est CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_subzona FROM query
		DECLARE q_cons_subzona CURSOR FOR cons_subzona
		LET i = 1
		FOREACH q_cons_subzona INTO r_r109.*
			LET rh_subzona[i].r109_cod_zona    = r_r109.r109_cod_zona
			LET rh_subzona[i].r109_cod_subzona =r_r109.r109_cod_subzona
			LET rh_subzona[i].r109_descripcion =r_r109.r109_descripcion
			LET rh_subzona[i].r109_estado      = r_r109.r109_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_subzona TO rh_subzona.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_subzona[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F18)
				IF estado = 'T' THEN
					LET col = 5
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_subzona
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_subzona[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_subzona[1].* TO NULL
        RETURN rh_subzona[1].r109_cod_subzona, rh_subzona[1].r109_descripcion
END IF
LET i = arr_curr()
RETURN rh_subzona[i].r109_cod_subzona, rh_subzona[i].r109_descripcion

END FUNCTION



FUNCTION fl_ayuda_transporte(codcia, codloc, estado)
DEFINE codcia		LIKE rept110.r110_compania
DEFINE codloc		LIKE rept110.r110_localidad
DEFINE estado		LIKE rept110.r110_estado
DEFINE rh_trans		ARRAY[500] OF RECORD
				r110_cod_trans	LIKE rept110.r110_cod_trans,
				r110_descripcion LIKE rept110.r110_descripcion,
				r110_estado	LIKE rept110.r110_estado
			END RECORD
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r110		RECORD LIKE rept110.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_trans AT 06, 29 WITH num_fil ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf180 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf180'
ELSE
	OPEN FORM f_ayuf180 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf180c'
END IF
DISPLAY FORM f_ayuf180
--#DISPLAY "Tran"		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY "E"			TO tit_col3
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r110_estado   = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r110_cod_trans, r110_descripcion
		IF int_flag THEN
			CLOSE WINDOW wh_trans
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 5
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM rept110 ',
				'WHERE r110_compania  = ', codcia,
				'  AND r110_localidad = ', codloc,
				expr_est CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_trans FROM query
		DECLARE q_cons_trans CURSOR FOR cons_trans
		LET i = 1
		FOREACH q_cons_trans INTO r_r110.*
			LET rh_trans[i].r110_cod_trans   = r_r110.r110_cod_trans
			LET rh_trans[i].r110_descripcion=r_r110.r110_descripcion
			LET rh_trans[i].r110_estado      = r_r110.r110_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_trans TO rh_trans.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_trans[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 5
				EXIT DISPLAY
			ON KEY(F17)
				IF estado = 'T' THEN
					LET col = 4
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_trans
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_trans[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_trans[1].* TO NULL
        RETURN rh_trans[1].r110_cod_trans, rh_trans[1].r110_descripcion
END IF
LET i = arr_curr()
RETURN rh_trans[i].r110_cod_trans, rh_trans[i].r110_descripcion

END FUNCTION



FUNCTION fl_ayuda_chofer(codcia, codloc, trans, estado)
DEFINE codcia		LIKE rept111.r111_compania
DEFINE codloc		LIKE rept111.r111_localidad
DEFINE trans		LIKE rept111.r111_cod_trans
DEFINE estado		LIKE rept111.r111_estado
DEFINE rh_chofer	ARRAY[500] OF RECORD
				r111_cod_trans	LIKE rept111.r111_cod_trans,
				r111_cod_chofer LIKE rept111.r111_cod_chofer,
				r111_nombre	LIKE rept111.r111_nombre,
				r111_estado	LIKE rept111.r111_estado
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_sql		CHAR(400)
DEFINE expr_tra		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r111		RECORD LIKE rept111.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_chofer AT 06, 25 WITH num_fil ROWS, 54 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf181 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf181'
ELSE
	OPEN FORM f_ayuf181 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf181c'
END IF
DISPLAY FORM f_ayuf181
--#DISPLAY "Tran"	TO tit_col1
--#DISPLAY "Cod."	TO tit_col2
--#DISPLAY 'Nombre'	TO tit_col3
--#DISPLAY "E"		TO tit_col4
LET expr_tra = NULL
IF trans <> 0 THEN
	LET expr_tra = '  AND r111_cod_trans = ', trans
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r111_estado    = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r111_cod_trans, r111_cod_chofer,
						r111_nombre
		IF int_flag THEN
			CLOSE WINDOW wh_chofer
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 6
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM rept111 ',
				'WHERE r111_compania  = ', codcia,
				'  AND r111_localidad = ', codloc,
				expr_tra CLIPPED,
				expr_est CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_chofer FROM query
		DECLARE q_cons_chofer CURSOR FOR cons_chofer
		LET i = 1
		FOREACH q_cons_chofer INTO r_r111.*
			LET rh_chofer[i].r111_cod_trans  = r_r111.r111_cod_trans
			LET rh_chofer[i].r111_cod_chofer =r_r111.r111_cod_chofer
			LET rh_chofer[i].r111_nombre     = r_r111.r111_nombre
			LET rh_chofer[i].r111_estado     = r_r111.r111_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_chofer TO rh_chofer.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_chofer[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F18)
				IF estado = 'T' THEN
					LET col = 5
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_chofer
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_chofer[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_chofer[1].* TO NULL
        RETURN rh_chofer[1].r111_cod_chofer, rh_chofer[1].r111_nombre
END IF
LET i = arr_curr()
RETURN rh_chofer[i].r111_cod_chofer, rh_chofer[i].r111_nombre

END FUNCTION



FUNCTION fl_ayuda_obsers(codcia, codloc, tipo, estado)
DEFINE codcia		LIKE rept112.r112_compania
DEFINE codloc		LIKE rept112.r112_localidad
DEFINE tipo		LIKE rept112.r112_tipo
DEFINE estado		LIKE rept112.r112_estado
DEFINE rh_obser		ARRAY[500] OF RECORD
				r112_cod_obser	LIKE rept112.r112_cod_obser,
				r112_descripcion LIKE rept112.r112_descripcion,
				r112_tipo	LIKE rept112.r112_tipo,
				r112_estado	LIKE rept112.r112_estado
			END RECORD
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(800)
DEFINE expr_tip		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r112		RECORD LIKE rept112.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_obser AT 06, 27 WITH num_fil ROWS, 52 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf182 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf182'
ELSE
	OPEN FORM f_ayuf182 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf182c'
END IF
DISPLAY FORM f_ayuf182
--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY 'Observación'	TO tit_col2
--#DISPLAY "T"			TO tit_col3
--#DISPLAY "E"			TO tit_col4
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r112_estado   = "', estado, '"'
END IF
LET expr_tip = NULL
IF tipo <> 'T' THEN
	LET expr_tip = '  AND r112_tipo     = "', tipo, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r112_cod_obser, r112_descripcion
		IF int_flag THEN
			CLOSE WINDOW wh_obser
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 5
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM rept112 ',
				'WHERE r112_compania  = ', codcia,
				'  AND r112_localidad = ', codloc,
				expr_est CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_obser FROM query
		DECLARE q_cons_obser CURSOR FOR cons_obser
		LET i = 1
		FOREACH q_cons_obser INTO r_r112.*
			LET rh_obser[i].r112_cod_obser   = r_r112.r112_cod_obser
			LET rh_obser[i].r112_descripcion=r_r112.r112_descripcion
			LET rh_obser[i].r112_tipo        = r_r112.r112_tipo
			LET rh_obser[i].r112_estado      = r_r112.r112_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_obser TO rh_obser.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_obser[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 5
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F18)
				IF estado = 'T' THEN
					LET col = 4
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_obser
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_obser[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_obser[1].* TO NULL
        RETURN rh_obser[1].r112_cod_obser, rh_obser[1].r112_descripcion
END IF
LET i = arr_curr()
RETURN rh_obser[i].r112_cod_obser, rh_obser[i].r112_descripcion

END FUNCTION



FUNCTION fl_ayuda_hoja_ruta(codcia, codloc, estado)
DEFINE codcia		LIKE rept113.r113_compania
DEFINE codloc		LIKE rept113.r113_localidad
DEFINE estado		LIKE rept113.r113_estado
DEFINE rh_hojrut	ARRAY[10000] OF RECORD
				r113_num_hojrut	LIKE rept113.r113_num_hojrut,
				r110_descripcion LIKE rept110.r110_descripcion,
				r111_nombre	LIKE rept111.r111_nombre,
				r113_observacion LIKE rept113.r113_observacion,
				r113_fecha	LIKE rept113.r113_fecha,
				r113_estado	LIKE rept113.r113_estado
			END RECORD
DEFINE query		CHAR(2000)
DEFINE expr_sql		CHAR(800)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r113		RECORD LIKE rept113.*

LET filas_pant = 10
LET max_row    = 10000
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_hojrut AT 06, 02 WITH num_fil ROWS, 78 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf183 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf183'
ELSE
	OPEN FORM f_ayuf183 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf183c'
END IF
DISPLAY FORM f_ayuf183
--#DISPLAY "Hoja Ruta"		TO tit_col1
--#DISPLAY "Transporte"		TO tit_col2
--#DISPLAY "Chofer"		TO tit_col3
--#DISPLAY "Observación"	TO tit_col4
--#DISPLAY "Fecha"		TO tit_col5
--#DISPLAY "E"			TO tit_col6
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r113_estado    = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r113_num_hojrut, r113_fecha,
						r113_observacion
		IF int_flag THEN
			CLOSE WINDOW wh_hojrut
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 5
	LET vm_columna_2 = 1
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT r113_num_hojrut, r110_descripcion, ',
				'r111_nombre, r113_observacion, r113_fecha, ',
				'r113_estado ',
				'FROM rept113, rept110, rept111 ',
				'WHERE r113_compania   = ', codcia,
				'  AND r113_localidad  = ', codloc,
				expr_est CLIPPED,
				'  AND r110_compania   = r113_compania ',
				'  AND r110_localidad  = r113_localidad ',
				'  AND r110_cod_trans  = r113_cod_trans ',
				'  AND r111_compania   = r113_compania ',
				'  AND r111_localidad  = r113_localidad ',
				'  AND r111_cod_trans  = r113_cod_trans ',
				'  AND r111_cod_chofer = r113_cod_chofer ',
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_hojrut FROM query
		DECLARE q_cons_hojrut CURSOR FOR cons_hojrut
		LET i = 1
		FOREACH q_cons_hojrut INTO rh_hojrut[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_hojrut TO rh_hojrut.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_hojrut[i].*
				END FOR
				EXIT DISPLAY
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
			ON KEY(F20)
				IF estado = 'T' THEN
					LET col = 6
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_hojrut
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_hojrut[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_hojrut[1].* TO NULL
        RETURN rh_hojrut[1].r113_num_hojrut
END IF
LET i = arr_curr()
RETURN rh_hojrut[i].r113_num_hojrut

END FUNCTION



FUNCTION fl_ayuda_ayudante(codcia, codloc, trans, estado)
DEFINE codcia		LIKE rept115.r115_compania
DEFINE codloc		LIKE rept115.r115_localidad
DEFINE trans		LIKE rept115.r115_cod_trans
DEFINE estado		LIKE rept115.r115_estado
DEFINE rh_ayudante	ARRAY[500] OF RECORD
				r115_cod_trans	LIKE rept115.r115_cod_trans,
				r115_cod_ayud	LIKE rept115.r115_cod_ayud,
				r115_nombre	LIKE rept115.r115_nombre,
				r115_estado	LIKE rept115.r115_estado
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_sql		CHAR(400)
DEFINE expr_tra		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT
DEFINE r_r115		RECORD LIKE rept115.*

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_ayud AT 06, 25 WITH num_fil ROWS, 54 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf184 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf184'
ELSE
	OPEN FORM f_ayuf184 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf184c'
END IF
DISPLAY FORM f_ayuf184
--#DISPLAY "Tran"	TO tit_col1
--#DISPLAY "Cod."	TO tit_col2
--#DISPLAY 'Nombre'	TO tit_col3
--#DISPLAY "E"		TO tit_col4
LET expr_tra = NULL
IF trans <> 0 THEN
	LET expr_tra = '  AND r115_cod_trans = ', trans
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r115_estado    = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r115_cod_trans, r115_cod_ayud,
						r115_nombre
		IF int_flag THEN
			CLOSE WINDOW wh_ayud
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 6
	LET vm_columna_2 = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT * FROM rept115 ',
				'WHERE r115_compania  = ', codcia,
				'  AND r115_localidad = ', codloc,
				expr_tra CLIPPED,
				expr_est CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_ayud FROM query
		DECLARE q_cons_ayud CURSOR FOR cons_ayud
		LET i = 1
		FOREACH q_cons_ayud INTO r_r115.*
			LET rh_ayudante[i].r115_cod_trans  = r_r115.r115_cod_trans
			LET rh_ayudante[i].r115_cod_ayud   =r_r115.r115_cod_ayud
			LET rh_ayudante[i].r115_nombre     = r_r115.r115_nombre
			LET rh_ayudante[i].r115_estado     = r_r115.r115_estado
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_ayudante TO rh_ayudante.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_ayudante[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 6
				EXIT DISPLAY
			ON KEY(F18)
				IF estado = 'T' THEN
					LET col = 5
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ayud
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_ayudante[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ayudante[1].* TO NULL
        RETURN rh_ayudante[1].r115_cod_ayud, rh_ayudante[1].r115_nombre
END IF
LET i = arr_curr()
RETURN rh_ayudante[i].r115_cod_ayud, rh_ayudante[i].r115_nombre

END FUNCTION



FUNCTION fl_ayuda_cia_entrega(codcia, codloc, tipo, estado)
DEFINE codcia		LIKE rept116.r116_compania
DEFINE codloc		LIKE rept116.r116_localidad
DEFINE tipo		LIKE rept116.r116_tipo
DEFINE estado		LIKE rept116.r116_estado
DEFINE rh_cia_ent	ARRAY[500] OF RECORD
				r116_cia_trans	LIKE rept116.r116_cia_trans,
				r116_razon_soc	LIKE rept116.r116_razon_soc,
				tit_estado	VARCHAR(10),
				r116_estado	LIKE rept116.r116_estado
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_sql		CHAR(400)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_tip		VARCHAR(100)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 14
IF vg_gui = 0 THEN
	LET num_fil = 15
END IF
OPEN WINDOW wh_ciaent AT 06, 25 WITH num_fil ROWS, 54 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf185 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf185'
ELSE
	OPEN FORM f_ayuf185 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf185c'
END IF
DISPLAY FORM f_ayuf185
--#DISPLAY "Cod."	TO tit_col1
--#DISPLAY 'Nombre'	TO tit_col2
--#DISPLAY "Tipo"	TO tit_col3
--#DISPLAY "E"		TO tit_col4
LET expr_tip = NULL
IF tipo <> 'T' THEN
	LET expr_tip = '  AND r116_tipo      = "', tipo, '"'
END IF
LET expr_est = NULL
IF estado <> 'T' THEN
	LET expr_est = '  AND r116_estado    = "', estado, '"'
END IF
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON r116_cia_trans, r116_razon_soc
		IF int_flag THEN
			CLOSE WINDOW wh_ciaent
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT r116_cia_trans, r116_razon_soc, ',
				'CASE WHEN r116_tipo = "E" THEN "EXTERNO" ',
				'     WHEN r116_tipo = "I" THEN "INTERNO" ',
				'END, ',
				'r116_estado ',
				'FROM rept116 ',
				'WHERE r116_compania  = ', codcia,
				'  AND r116_localidad = ', codloc,
				expr_est CLIPPED,
				expr_tip CLIPPED,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_ciaent FROM query
		DECLARE q_cons_ciaent CURSOR FOR cons_ciaent
		LET i = 1
		FOREACH q_cons_ciaent INTO rh_cia_ent[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_cia_ent TO rh_cia_ent.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_cia_ent[i].*
				END FOR
				EXIT DISPLAY
			ON KEY(F15)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F17)
				IF tipo = 'T' THEN
					LET col = 3
					EXIT DISPLAY
				END IF
			ON KEY(F18)
				IF estado = 'T' THEN
					LET col = 4
					EXIT DISPLAY
				END IF
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_ciaent
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_cia_ent[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cia_ent[1].* TO NULL
        RETURN rh_cia_ent[1].r116_cia_trans, rh_cia_ent[1].r116_razon_soc
END IF
LET i = arr_curr()
RETURN rh_cia_ent[i].r116_cia_trans, rh_cia_ent[i].r116_razon_soc

END FUNCTION



FUNCTION fl_ayuda_division_politica(pais)
DEFINE pais		LIKE gent025.g25_pais
DEFINE rh_div_pol	ARRAY[500] OF RECORD
				g25_divi_poli	LIKE gent025.g25_divi_poli,
				g25_nombre	LIKE gent025.g25_nombre,
				g25_region	LIKE gent025.g25_region,
				g25_siglas	LIKE gent025.g25_siglas
			END RECORD
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE query		CHAR(1000)
DEFINE expr_sql		CHAR(400)
DEFINE i, j, max_row	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE num_fil		SMALLINT
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE primera		SMALLINT

LET filas_pant = 10
LET max_row    = 500
LET num_fil    = 15
IF vg_gui = 0 THEN
	LET num_fil = 16
END IF
OPEN WINDOW wh_divpol AT 06, 21 WITH num_fil ROWS, 58 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf186 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf186'
ELSE
	OPEN FORM f_ayuf186 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf186c'
END IF
DISPLAY FORM f_ayuf186
INITIALIZE r_g30.* TO NULL
SELECT * INTO r_g30.*
	FROM gent030
	WHERE g30_pais = pais
DISPLAY pais TO g25_pais
DISPLAY BY NAME r_g30.g30_nombre
--#DISPLAY "Cod."	TO tit_col1
--#DISPLAY 'Nombre'	TO tit_col2
--#DISPLAY "Región"	TO tit_col3
--#DISPLAY "Sig."	TO tit_col4
LET primera = 1
WHILE TRUE
	IF NOT primera THEN
		MESSAGE 'Digite condicion-búsqueda y presione (F12)'
		LET int_flag = 0
		CONSTRUCT BY NAME expr_sql ON g25_divi_poli, g25_nombre,
						g25_region, g25_siglas
		IF int_flag THEN
			CLOSE WINDOW wh_divpol
			EXIT WHILE
		END IF
	ELSE
		LET expr_sql = ' 1 = 1'
	END IF
	LET primera = 0
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET rm_orden[vm_columna_1] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT g25_divi_poli, g25_nombre, g25_region, ',
					'g25_siglas ',
				'FROM gent025 ',
				'WHERE g25_pais = ', pais,
				'  AND ', expr_sql CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE cons_divpol FROM query
		DECLARE q_cons_divpol CURSOR FOR cons_divpol
		LET i = 1
		FOREACH q_cons_divpol INTO rh_div_pol[i].*
			LET i = i + 1
			IF i > max_row THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN	
		        CALL fl_mensaje_consulta_sin_registros()
			LET i = 0
			LET salir = 1
			EXIT WHILE
		END IF
		MESSAGE '                                           '
		LET int_flag = 0
		CALL set_count(i)
		DISPLAY ARRAY rh_div_pol TO rh_div_pol.*
			ON KEY(RETURN)
				LET salir = 1
				EXIT DISPLAY
			ON KEY(F2)
				LET int_flag = 4
				FOR i = 1 TO filas_pant
					CLEAR rh_div_pol[i].*
				END FOR
				EXIT DISPLAY
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
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#DISPLAY j TO num_row
				--#DISPLAY i TO max_row
			--#AFTER DISPLAY
				--#LET salir = 1
		END DISPLAY
		IF int_flag = 4 OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
			IF col <> vm_columna_1 THEN
				LET vm_columna_2           = vm_columna_1
				LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
				LET vm_columna_1           = col
			END IF
			IF rm_orden[vm_columna_1] = 'ASC' THEN
				LET rm_orden[vm_columna_1] = 'DESC'
			ELSE
				LET rm_orden[vm_columna_1] = 'ASC'
			END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
		CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
		CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW wh_divpol
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_div_pol[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_div_pol[1].* TO NULL
        RETURN rh_div_pol[1].g25_divi_poli, rh_div_pol[1].g25_nombre
END IF
LET i = arr_curr()
RETURN rh_div_pol[i].g25_divi_poli, rh_div_pol[i].g25_nombre

END FUNCTION
