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
OPEN WINDOW wh AT 16,15 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf007'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Compania'   TO bt_compania
DISPLAY 'Localidad'  TO bt_localidad

LET filas_pant = fgl_scr_size("rh")
LET int_flag = 0
MESSAGE 'Seleccionando datos ...' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
LET query = " SELECT g01_razonsocial, g02_nombre, g01_compania, g02_localidad
		 FROM gent001, gent002 ",
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
        AFTER DISPLAY
                LET salir = 1
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
OPEN WINDOW wh AT 06,39 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf000'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cia TO rh_cia.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
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
OPEN WINDOW wh AT 06,39 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf001'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_loc TO rh_loc.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
                                                                               



FUNCTION fl_ayuda_ciudad(pais)
DEFINE rh ARRAY[100] OF RECORD
   	g31_ciudad      LIKE gent031.g31_ciudad,
        g31_nombre      LIKE gent031.g31_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE pais		LIKE gent031.g31_pais
                                                                                
LET filas_max  = 100
OPEN WINDOW wh AT 06,39 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf002'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                  BORDER) 
LET filas_pant = fgl_scr_size('rh')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
-----
IF pais = '00' THEN
DECLARE qh_ciu1 CURSOR FOR
        SELECT g31_ciudad, g31_nombre FROM gent031
        ORDER BY 2
LET i = 1
FOREACH qh_ciu1 INTO rh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
END IF
----- 
IF pais <> '00' THEN
DECLARE qh_ciu2 CURSOR FOR
        SELECT g31_ciudad, g31_nombre FROM gent031
		WHERE g31_pais = pais
        ORDER BY 2
LET i = 1
FOREACH qh_ciu2 INTO rh[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
END IF
------
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh[1].* TO NULL
        RETURN rh[1].g31_ciudad, rh[1].g31_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh TO rh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

OPEN WINDOW w_impto AT 7,42 
	WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf003"
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
CALL SET_COUNT(i)

DISPLAY ARRAY rh_impto TO rh_imp.*
	ON KEY(RETURN)
		EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_hzonv AT 06,45
 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf005'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_zonv TO rh_zonv.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh AT 06,44
   WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf006'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_pais TO rh_pais.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_mon AT 06,47 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf008'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_mon TO rh_mon.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_cco AT 06,44 
WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf009'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cco TO rh_cco.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_depa AT 06,44
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf010'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_depto')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_depto CURSOR FOR
        SELECT g34_cod_depto, g34_nombre FROM gent034
		WHERE g34_compania = cod_cia
        ORDER BY 1
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_depto TO rh_depto.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_car AT 06,35 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf011'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_cargo')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_cargo CURSOR FOR
        SELECT g35_cod_cargo, g35_nombre FROM gent035
		WHERE g35_compania = cod_cia
        ORDER BY 1
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cargo TO rh_cargo.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_car
IF int_flag THEN
        INITIALIZE rh_cargo[1].* TO NULL
        RETURN rh_cargo[1].g35_cod_cargo, rh_cargo[1].g35_nombre
END IF
LET  i = arr_curr()
RETURN rh_cargo[i].g35_cod_cargo, rh_cargo[i].g35_nombre
END FUNCTION




FUNCTION fl_ayuda_partidas()
DEFINE rh_part ARRAY[500] OF RECORD
        g16_partida       	LIKE gent016.g16_partida,
        g16_nombre      	LIKE gent016.g16_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 500
OPEN WINDOW w_par AT 06,17 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf012'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_part')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_part CURSOR FOR
        SELECT g16_partida, g16_nombre FROM gent016
        ORDER BY 1
LET i = 1
FOREACH qh_part INTO rh_part[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_par
        INITIALIZE rh_part[1].* TO NULL
        RETURN rh_part[1].g16_partida
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_part TO rh_part.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_par
IF int_flag THEN
        INITIALIZE rh_part[1].* TO NULL
        RETURN rh_part[1].g16_partida
END IF
LET  i = arr_curr()
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
OPEN WINDOW wh_area AT 06,44 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf013'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_area TO rh_area.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_area
IF int_flag THEN
        INITIALIZE rh_area[1].* TO NULL
        RETURN rh_area[1].g03_areaneg, rh_area[1].g03_nombre
END IF
LET  i = arr_curr()
RETURN rh_area[i].g03_areaneg, rh_area[i].g03_nombre

END FUNCTION



FUNCTION fl_ayuda_usuarios()
DEFINE rh_usua ARRAY[100] OF RECORD
        g05_usuario       	LIKE gent005.g05_usuario,
        g05_nombres      	LIKE gent005.g05_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_usua AT 06,38 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf014'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_usua')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_usua CURSOR FOR
        SELECT g05_usuario, g05_nombres FROM gent005
        ORDER BY 1
LET i = 1
FOREACH qh_usua INTO rh_usua[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_usua
        INITIALIZE rh_usua[1].* TO NULL
        RETURN rh_usua[1].g05_usuario, rh_usua[1].g05_nombres
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_usua TO rh_usua.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_usua
IF int_flag THEN
        INITIALIZE rh_usua[1].* TO NULL
        RETURN rh_usua[1].g05_usuario, rh_usua[1].g05_nombres
END IF
LET  i = arr_curr()
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
OPEN WINDOW w_grup AT 06,35 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf015'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_grup TO rh_grup.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_grup
IF int_flag THEN
        INITIALIZE rh_grup[1].* TO NULL
        RETURN rh_grup[1].g04_grupo, rh_grup[1].g04_nombre 
END IF
LET  i = arr_curr()
RETURN rh_grup[i].g04_grupo, rh_grup[i].g04_nombre 

END FUNCTION



FUNCTION fl_ayuda_impresoras()
DEFINE rh_impr ARRAY[100] OF RECORD
        g06_impresora       	LIKE gent006.g06_impresora,
        g06_nombre       	LIKE gent006.g06_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_imp AT 06,35 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf016'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_impr')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_impr CURSOR FOR
        SELECT g06_impresora, g06_nombre  FROM gent006
        ORDER BY 1
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_impr TO rh_impr.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_ban AT 06,40 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf017'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_banc TO rh_banc.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_cobr AT 06,35 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf018'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cobr TO rh_cobr.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_cobr
IF int_flag THEN
        INITIALIZE rh_cobr[1].* TO NULL
        RETURN rh_cobr[1].z01_codcli, rh_cobr[1].z01_nomcli 
END IF
LET  i = arr_curr()
RETURN rh_cobr[i].z01_codcli, rh_cobr[i].z01_nomcli 

END FUNCTION




FUNCTION fl_ayuda_tarjeta()
DEFINE rh_tarj ARRAY[100] OF RECORD
        g10_tarjeta       	LIKE gent010.g10_tarjeta,
        g10_nombre       	LIKE gent010.g10_nombre 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_tarj AT 06,39 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf019'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_tarj')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_tarj CURSOR FOR
        SELECT g10_tarjeta, g10_nombre  FROM gent010
        ORDER BY 1
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
        CLOSE WINDOW w_tarj
        INITIALIZE rh_tarj[1].* TO NULL
        RETURN rh_tarj[1].g10_tarjeta, rh_tarj[1].g10_nombre 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tarj TO rh_tarj.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_tarj
IF int_flag THEN
        INITIALIZE rh_tarj[1].* TO NULL
        RETURN rh_tarj[1].g10_tarjeta, rh_tarj[1].g10_nombre 
END IF
LET  i = arr_curr()
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
OPEN WINDOW w_ent AT 06,38 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf020'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ent TO rh_ent.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_subtip AT 06,34 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf021'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subtip TO rh_subtip.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_subtip
IF int_flag THEN
        INITIALIZE rh_subtip[1].*, rh_tipo[1].* TO NULL
        RETURN rh_subtip[1].g12_tiporeg, rh_subtip[1].g12_subtipo, rh_subtip[1].g12_nombre, rh_tipo[1].g11_nombre 
END IF
LET  i = arr_curr()
RETURN rh_subtip[i].g12_tiporeg, rh_subtip[i].g12_subtipo, rh_subtip[i].g12_nombre, rh_tipo[i].g11_nombre 

END FUNCTION



FUNCTION fl_ayuda_cuenta_banco(cod_cia)
DEFINE rh_ctabco ARRAY[100] OF RECORD
	g08_banco		LIKE gent008.g08_banco,
        g08_nombre       	LIKE gent008.g08_nombre,
        g09_tipo_cta       	LIKE gent009.g09_tipo_cta,
        g09_numero_cta       	LIKE gent009.g09_numero_cta 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE gent009.g09_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW w_ctabco AT 06,27 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf022'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_ctabco')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE qh_ctabco CURSOR FOR
        SELECT g08_banco, g08_nombre, g09_tipo_cta, g09_numero_cta  
		FROM gent009, gent008
		WHERE g09_compania = cod_cia
		  AND g09_banco    = g08_banco 
        ORDER BY 1
LET i = 1
FOREACH qh_ctabco INTO rh_ctabco[i].*
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
        RETURN rh_ctabco[1].g08_banco, rh_ctabco[1].g08_nombre, rh_ctabco[1].g09_tipo_cta, rh_ctabco[1].g09_numero_cta 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ctabco TO rh_ctabco.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_ctabco
IF int_flag THEN
        INITIALIZE rh_ctabco[1].* TO NULL
        RETURN rh_ctabco[1].g08_banco, rh_ctabco[1].g08_nombre, rh_ctabco[1].g09_tipo_cta, rh_ctabco[1].g09_numero_cta 
END IF
LET  i = arr_curr()
RETURN rh_ctabco[i].g08_banco, rh_ctabco[i].g08_nombre, rh_ctabco[i].g09_tipo_cta, rh_ctabco[i].g09_numero_cta 

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
OPEN WINDOW w_grulin AT 06,40
        WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf023'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_grulin TO rh_grulin.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
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
OPEN WINDOW w_dias AT 06,32
        WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf024'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_dias TO rh_dias.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_dias
IF int_flag THEN
        INITIALIZE rh_dias[1].* TO NULL
        RETURN rh_dias[1].g36_dia, rh_dias[1].g36_referencia
END IF
LET  i = arr_curr()
        RETURN rh_dias[i].g36_dia, rh_dias[i].g36_referencia

END FUNCTION




FUNCTION fl_ayuda_guias_remision()
DEFINE rh_guia ARRAY[100] OF RECORD
        g19_codigo         	LIKE gent019.g19_codigo,
        g19_nombre	        LIKE gent019.g19_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_guia AT 06,39
        WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf025'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_guia')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_guia CURSOR FOR
        SELECT g19_codigo, g19_nombre  FROM gent019
        ORDER BY 1
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
        RETURN rh_guia[1].g19_codigo, rh_guia[1].g19_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_guia TO rh_guia.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_guia
IF int_flag THEN
        INITIALIZE rh_guia[1].* TO NULL
        RETURN rh_guia[1].g19_codigo, rh_guia[1].g19_nombre
END IF
LET  i = arr_curr()
RETURN rh_guia[i].g19_codigo, rh_guia[i].g19_nombre

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
OPEN WINDOW w_base AT 06,35
        WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf026'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_base TO rh_base.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
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
OPEN WINDOW w_modu AT 06,37
        WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf027'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_modu TO rh_modu.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
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

OPEN WINDOW w_ctacon AT 06,27 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf028'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Cuenta'      TO bt_cuenta
DISPLAY 'Descripción' TO bt_descripcion

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON b10_cuenta, b10_descripcion
	IF int_flag THEN
		INITIALIZE rh_ctacon[1].* TO NULL
		CLOSE WINDOW w_ctacon
		RETURN rh_ctacon[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_nivel = " 1 = 1 "
	IF nivel <> 0 THEN
		LET expr_nivel = " b10_nivel =  ", nivel 
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
IF NOT salir THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_ctacon
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_ctacon[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ctacon[1].* TO NULL
	RETURN rh_ctacon[1].*
END IF
LET  i = arr_curr()
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
OPEN WINDOW w_proc AT 06,19
        WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf029'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_proc TO rh_proc.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_proc
IF int_flag THEN
        INITIALIZE rh_proc[1].* TO NULL
        RETURN rh_proc[1].g54_modulo, rh_proc[1].g54_proceso, rh_proc[1].g54_nombre
END IF
LET  i = arr_curr()
RETURN rh_proc[i].g54_modulo, rh_proc[i].g54_proceso, rh_proc[i].g54_nombre

END FUNCTION



FUNCTION fl_ayuda_bodegas_rep(cod_cia, indicador) ## indicador T ó F 
DEFINE rh_bode ARRAY[100] OF RECORD	          ## Todas ó sólo de Facturación
   	r02_codigo      	LIKE rept002.r02_codigo,
        r02_nombre      	LIKE rept002.r02_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE rept002.r02_compania
DEFINE indicador	LIKE rept002.r02_factura
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_bode AT 06,44
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf030'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_bode')
LET int_flag = 0

MESSAGE 'Seleccionando datos..' 
IF indicador ='F' THEN
DECLARE q_bode1 CURSOR FOR
        SELECT r02_codigo, r02_nombre FROM rept002
	WHERE r02_compania = cod_cia
        AND r02_factura = 'S'
	AND r02_estado = 'A'
        ORDER BY 1
	LET i = 1
	FOREACH q_bode1 INTO rh_bode[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
IF indicador ='T' THEN
DECLARE q_bode2 CURSOR FOR
        SELECT r02_codigo, r02_nombre FROM rept002
	WHERE r02_compania = vg_codcia
	AND r02_estado = 'A'
        ORDER BY 1
	LET i = 1
	FOREACH q_bode2 INTO rh_bode[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_bode
        INITIALIZE rh_bode[1].* TO NULL
        RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_bode TO rh_bode.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_bode
IF int_flag THEN
        INITIALIZE rh_bode[1].* TO NULL
        RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END IF
LET  i = arr_curr()
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
OPEN WINDOW wh_linea AT 06,42
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf031'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_linea TO rh_linea.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_clase AT 06,44
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf032'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_clase TO rh_clase.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_tipitem AT 06,56
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf033'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipitem TO rh_tipitem.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_tiptran AT 06,44
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf034'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tiptran TO rh_tiptran.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_subtran AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf035'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subtran TO rh_subtran.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_rubros AT 06,43
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf036'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_rubros TO rh_rubros.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_rubros
IF int_flag THEN
        INITIALIZE rh_rubros[1].* TO NULL
        RETURN rh_rubros[1].g17_codrubro, rh_rubros[1].g17_nombre
END IF
LET  i = arr_curr()
RETURN rh_rubros[i].g17_codrubro, rh_rubros[i].g17_nombre

END FUNCTION




FUNCTION fl_ayuda_zona_cobro()
DEFINE rh_zoncob ARRAY[100] OF RECORD
   	z06_zona_cobro      	LIKE cxct006.z06_zona_cobro,
        z06_nombre      	LIKE cxct006.z06_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_zoncob AT 06,43
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf037'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_zoncob')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_zoncob CURSOR FOR
        SELECT z06_zona_cobro, z06_nombre FROM cxct006
        ORDER BY 2
LET i = 1
FOREACH q_zoncob INTO rh_zoncob[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_zoncob
        INITIALIZE rh_zoncob[1].* TO NULL
        RETURN rh_zoncob[1].z06_zona_cobro, rh_zoncob[1].z06_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_zoncob TO rh_zoncob.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_zoncob
IF int_flag THEN
        INITIALIZE rh_zoncob[1].* TO NULL
        RETURN rh_zoncob[1].z06_zona_cobro, rh_zoncob[1].z06_nombre
END IF
LET  i = arr_curr()
RETURN rh_zoncob[i].z06_zona_cobro, rh_zoncob[i].z06_nombre

END FUNCTION



FUNCTION fl_ayuda_vendedores(cod_cia)
DEFINE rh_vend ARRAY[100] OF RECORD
   	r01_codigo      	LIKE rept001.r01_codigo,
        r01_nombres      	LIKE rept001.r01_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia 		LIKE rept001.r01_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_vend AT 06,43
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf038'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_vend')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_vend CURSOR FOR
        SELECT r01_codigo, r01_nombres FROM rept001
		WHERE r01_compania = cod_cia
		  AND r01_estado = 'A'
        ORDER BY 2
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
        CLOSE WINDOW wh_vend
        INITIALIZE rh_vend[1].* TO NULL
        RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_vend TO rh_vend.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_vend
IF int_flag THEN
        INITIALIZE rh_vend[1].* TO NULL
        RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END IF
LET  i = arr_curr()
RETURN rh_vend[i].r01_codigo, rh_vend[i].r01_nombres

END FUNCTION




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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_trab
IF int_flag THEN
        INITIALIZE rh_trab[1].* TO NULL
        RETURN rh_trab[1].n30_cod_trab, rh_trab[1].n30_nombres
END IF
LET  i = arr_curr()
RETURN rh_trab[i].n30_cod_trab, rh_trab[i].n30_nombres

END FUNCTION




FUNCTION fl_ayuda_cobradores(cod_cia)
DEFINE rh_cobra ARRAY[100] OF RECORD
   	z05_codigo      	LIKE cxct005.z05_codigo,
        z05_nombres      	LIKE cxct005.z05_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia 		LIKE cxct005.z05_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_cobra AT 06,27
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf040'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_cobra')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_cobra CURSOR FOR
        SELECT z05_codigo, z05_nombres FROM cxct005
	WHERE  z05_compania = cod_cia
        ORDER BY 2
LET i = 1
FOREACH q_cobra INTO rh_cobra[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_cobra
        INITIALIZE rh_cobra[1].* TO NULL
        RETURN rh_cobra[1].z05_codigo, rh_cobra[1].z05_nombres
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cobra TO rh_cobra.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_cobra
IF int_flag THEN
        INITIALIZE rh_cobra[1].* TO NULL
        RETURN rh_cobra[1].z05_codigo, rh_cobra[1].z05_nombres
END IF
LET  i = arr_curr()
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
OPEN WINDOW wh_cred AT 06,33
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf041'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cred TO rh_cred.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_tipdoc AT 06,53
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf042'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipdoc TO rh_tipdoc.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_unimed AT 06,60
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf043'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_unimed TO rh_unimed.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

OPEN WINDOW w_items AT 06,20 
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf044'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
                   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

DISPLAY 'Código'      TO bt_codigo
DISPLAY 'Descripción' TO bt_nombre
CREATE TEMP TABLE te_item99 
	(te_codigo		CHAR(15),
	 te_nombre		VARCHAR(40))
WHILE TRUE
	DELETE FROM te_item99
	MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON r10_codigo, r10_nombre
	IF int_flag THEN
		INITIALIZE rh_items[1].* TO NULL
		CLOSE WINDOW w_items
		DROP TABLE te_item99
		RETURN rh_items[1].*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                	EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
LET  i = arr_curr()
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
OPEN WINDOW w_ciatal AT 06,39 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf045'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciatal TO rh_ciatal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_bodveh AT 06,44
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf046'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_bodveh TO rh_bodveh.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_sectal AT 06,41
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf047'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_sectal TO rh_sectal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
DEFINE rh_mectal ARRAY[100] OF RECORD
   	t03_mecanico      	LIKE talt003.t03_mecanico,
        t03_nombres      	LIKE talt003.t03_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt003.t03_compania
DEFINE tipo		LIKE talt003.t03_tipo
DEFINE expr_tipo 	CHAR(25)	
DEFINE query		CHAR(500)
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_mectal AT 06,41
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf048'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_mectal')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF tipo = 'A' THEN
	LET expr_tipo = " t03_tipo = ", "'A'"
END IF
IF tipo = 'M' THEN
	LET expr_tipo = " t03_tipo = ", "'M'"
END IF
IF tipo <> 'A' AND tipo <> 'M' THEN
	LET expr_tipo = " t03_tipo IN ('M','A')"
END IF 
LET query = "SELECT t03_mecanico, t03_nombres FROM talt003 ",
		" WHERE t03_compania = ", cod_cia,
		" AND ", expr_tipo CLIPPED,
		' ORDER BY 2'
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
        CLOSE WINDOW wh_mectal
        INITIALIZE rh_mectal[1].* TO NULL
        RETURN rh_mectal[1].t03_mecanico, rh_mectal[1].t03_nombres
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_mectal TO rh_mectal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_mectal
IF int_flag THEN
        INITIALIZE rh_mectal[1].* TO NULL
        RETURN rh_mectal[1].t03_mecanico, rh_mectal[1].t03_nombres
END IF
LET  i = arr_curr()
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_martal AT 06,47
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf050'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
        CLOSE WINDOW wh_tipveh
        INITIALIZE rh_martal[1].* TO NULL
        RETURN rh_martal[1].t01_linea, rh_martal[1].t01_nombre 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_martal TO rh_martal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW w_subord AT 06,32 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf051' 
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subord TO rh_subord.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_torden AT 06,48
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf053'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_torden TO rh_torden.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

DEFINE rh_cligen ARRAY[1000] OF RECORD
	z01_codcli	LIKE cxct001.z01_codcli,
        z01_nomcli	LIKE cxct001.z01_nomcli
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

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cligen AT 06,26 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf052'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Código'     TO bt_codigo
DISPLAY 'Cliente'    TO bt_cliente

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z01_codcli, z01_nomcli
	IF int_flag THEN
		INITIALIZE rh_cligen[1].* TO NULL
		CLOSE WINDOW w_cligen
		RETURN rh_cligen[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT z01_codcli, z01_nomcli FROM cxct001 ",
				" WHERE z01_estado =  'A'", " AND ", 
				 expr_sql CLIPPED,
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cligen TO rh_cligen.*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
                AFTER DISPLAY
                	LET salir = 1
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
	RETURN rh_cligen[1].*
END IF
LET  i = arr_curr()
RETURN rh_cligen[i].*

END FUNCTION



FUNCTION fl_ayuda_orden_trabajo(cod_cia, cod_loc, estado)

DEFINE rh_ordtal ARRAY[1000] OF RECORD
	t23_orden	LIKE talt023.t23_orden,
	t23_nom_cliente LIKE talt023.t23_nom_cliente 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_estado	CHAR(45)
DEFINE cod_cia		LIKE talt023.t23_compania
DEFINE cod_loc		LIKE talt023.t23_localidad
DEFINE estado		LIKE talt023.t23_estado

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_ordtal AT 06,26 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf056'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_orden, t23_nom_cliente
	IF int_flag THEN
		INITIALIZE rh_ordtal[1].* TO NULL
		CLOSE WINDOW w_ordtal
		RETURN rh_ordtal[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
-------
	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " t23_estado  = '", estado, "'"  
	END IF
	IF estado = 'T' THEN
		LET expr_estado = " t23_estado   IN ('A','C','F','E','D')"
	END IF
----------
	LET query = "SELECT t23_orden, t23_nom_cliente FROM talt023 ",
				"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				 expr_estado, " AND ",
				 expr_sql CLIPPED,
				" ORDER BY 1"
	PREPARE ordtal FROM query
	DECLARE q_ordtal CURSOR FOR ordtal
	LET i = 1
	FOREACH q_ordtal INTO rh_ordtal[i].*
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
	DISPLAY ARRAY rh_ordtal TO rh_ordtal.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_ordtal
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_ordtal[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_ordtal[1].* TO NULL
	RETURN rh_ordtal[1].*
END IF
LET  i = arr_curr()
RETURN rh_ordtal[i].*

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
                                                                                
DISPLAY 'Código'     TO bt_codigo
DISPLAY 'Nombre'     TO bt_nombre

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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
	BEFORE DISPLAY
		CALL dialog.keysetlabel('RETURN', '')
        AFTER DISPLAY
                LET salir = 1
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_linveh
IF int_flag THEN
        INITIALIZE rh_linveh[1].* TO NULL
        RETURN rh_linveh[1].v03_linea, rh_linveh[1].v03_nombre
END IF
LET  i = arr_curr()
RETURN rh_linveh[i].v03_linea, rh_linveh[i].v03_nombre

END FUNCTION



FUNCTION fl_ayuda_tempario(cod_cia, modelo)

DEFINE rh_tarea ARRAY[1000] OF RECORD
	t07_codtarea	LIKE talt007.t07_codtarea,
	t07_nombre 	LIKE talt007.t07_nombre 
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE expr_sql2	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt007.t07_compania
DEFINE modelo		LIKE talt007.t07_modelo

DEFINE tarea		LIKE talt035.t35_codtarea
DEFINE nombre		LIKE talt035.t35_nombre
DEFINE op		CHAR(8)

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_tarea AT 06,14 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf059'  
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	DISPLAY modelo TO t07_modelo 
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t07_codtarea, t07_nombre
		AFTER CONSTRUCT
			LET tarea  = GET_FLDBUF(t07_codtarea)
			LET nombre = GET_FLDBUF(t07_nombre)
	END CONSTRUCT
	IF int_flag THEN
		INITIALIZE rh_tarea[1].* TO NULL
		CLOSE WINDOW w_tarea
		RETURN rh_tarea[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

{
	FOR i = 1 TO LENGTH(expr_sql) - 3
		IF expr_sql[i, i+3] = 't07' THEN
			LET expr_sql2 = expr_sql2, 't35'
display '1', expr_sql2
		ELSE
			LET expr_sql2 = expr_sql2, expr_sql[i, i+3] 
display '2', expr_sql2
		END IF
	END FOR
}
	LET expr_sql2 = ' '             
	IF tarea IS NOT NULL THEN
		FOR i = 1 TO LENGTH(tarea)
			LET op = '='
			IF tarea[i,i] = '*' THEN
				LET op = 'matches'
			END IF 
		END FOR
		LET expr_sql2 = expr_sql2 CLIPPED, 
				' AND t35_codtarea ', op, ' "', tarea CLIPPED, '" '
	END IF
	IF nombre IS NOT NULL THEN
		FOR i = 1 TO LENGTH(nombre)
			LET op = '='
			IF nombre[i,i] = '*' THEN
				LET op = 'matches'
			END IF 
		END FOR
		LET expr_sql2 = expr_sql2 CLIPPED,
				' AND t35_nombre ', op, ' "', nombre CLIPPED, '" '
	END IF

	LET query = "SELECT t07_codtarea, t07_nombre FROM talt007 ",
				" WHERE t07_compania =  ", cod_cia, 
		  		 " AND t07_modelo ='", modelo CLIPPED, 
		  		 "' AND t07_estado =  'A' AND ", 
				expr_sql CLIPPED,
		     " UNION ",
           	  "SELECT t35_codtarea, t35_nombre FROM talt035 ",
				" WHERE t35_compania =  ", cod_cia, 
		  		" AND t35_estado =  'A' ", 
				expr_sql2 CLIPPED,
				' ORDER BY 1'
display query
	PREPARE tarea FROM query
	DECLARE q_tarea CURSOR FOR tarea
	LET i = 1
	FOREACH q_tarea   INTO rh_tarea[i].*
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
	DISPLAY ARRAY rh_tarea TO rh_tarea.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_tarea
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_tarea[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_tarea[1].* TO NULL
	RETURN rh_tarea[1].*
END IF
LET  i = arr_curr()
RETURN rh_tarea[i].*

END FUNCTION


FUNCTION fl_ayuda_tipos_ordenes_compras()
DEFINE i		SMALLINT
DEFINE rh_oc ARRAY[50] OF RECORD
	c01_tipo_orden		LIKE ordt001.c01_tipo_orden,
	c01_nombre		LIKE ordt001.c01_nombre
	END RECORD

OPEN WINDOW wh_hoc AT 06,51
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf060'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
DECLARE q_hoc CURSOR FOR
	SELECT c01_tipo_orden, c01_nombre FROM ordt001 ORDER BY 1
LET i = 1
FOREACH q_hoc INTO rh_oc[i].*
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i = 0 THEN	
        CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW wh_hoc
        RETURN rh_oc[1].c01_tipo_orden, rh_oc[1].c01_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_oc TO rh_oc.*
CLOSE WINDOW wh_hoc
IF int_flag THEN
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

OPEN WINDOW w_cliord AT 06,27 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf061'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_cod_cliente, t23_nom_cliente
	IF int_flag THEN
		INITIALIZE rh_cliord[1].* TO NULL
		CLOSE WINDOW w_cliord
		RETURN rh_cliord[1].*
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliord TO rh_cliord.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
LET  i = arr_curr()
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_plafin
IF int_flag THEN
        INITIALIZE rh_plafin[1].* TO NULL
        RETURN rh_plafin[1].v06_codigo_plan, rh_plafin[1].v06_nonbre_plan
END IF
LET  i = arr_curr()
RETURN rh_plafin[i].v06_codigo_plan, rh_plafin[i].v06_nonbre_plan

END FUNCTION

 

FUNCTION fl_ayuda_presupuestos_taller(cod_cia, cod_loc, estado)
DEFINE rh_pretal ARRAY[100] OF RECORD
   	t20_numpre      	LIKE talt020.t20_numpre,
        t23_cod_cliente		LIKE talt023.t23_cod_cliente,
	t23_nom_cliente		LIKE talt023.t23_nom_cliente 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE talt020.t20_compania
DEFINE cod_loc		LIKE talt020.t20_localidad
DEFINE expr_estado 	CHAR(35)	
DEFINE estado		LIKE talt020.t20_estado
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_pretal AT 06,32
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf063'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_pretal')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
-----------
IF estado = 'A' THEN 
DECLARE q_pretal1 CURSOR FOR
        SELECT t20_numpre, t23_cod_cliente, t23_nom_cliente 
		FROM talt020, talt023
		WHERE t20_compania  = cod_cia
		  AND t20_localidad = cod_loc
		  AND t23_compania  = cod_cia
		  AND t23_localidad = cod_loc
		  AND t20_compania  = t23_compania
		  AND t20_localidad = t23_localidad
		  AND t23_numpre    = t20_numpre
		  AND t23_orden     = t20_orden
		  AND t20_estado    = estado 
        ORDER BY 1
LET i = 1
FOREACH q_pretal1 INTO rh_pretal[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF estado = 'P' THEN 
DECLARE q_pretal2 CURSOR FOR
        SELECT t20_numpre, t23_cod_cliente, t23_nom_cliente 
		FROM talt020, talt023
		WHERE t20_compania  = cod_cia
		  AND t20_localidad = cod_loc
		  AND t23_compania  = cod_cia
		  AND t23_localidad = cod_loc
		  AND t20_compania  = t23_compania
		  AND t20_localidad = t23_localidad
		  AND t23_numpre    = t20_numpre
		  AND t23_orden     = t20_orden
		  AND t20_estado    = estado 
        ORDER BY 1
LET i = 1
FOREACH q_pretal2 INTO rh_pretal[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
IF estado = 'T' THEN 
DECLARE q_pretal3 CURSOR FOR
        SELECT t20_numpre, t23_cod_cliente, t23_nom_cliente 
		FROM talt020, talt023
		WHERE t20_compania  = cod_cia
		  AND t20_localidad = cod_loc
		  AND t23_compania  = cod_cia
		  AND t23_localidad = cod_loc
		  AND t20_compania  = t23_compania
		  AND t20_localidad = t23_localidad
		  AND t23_numpre    = t20_numpre
		  AND t23_orden     = t20_orden
		  AND t20_estado    IN ('A','P')
        ORDER BY 1
LET i = 1
FOREACH q_pretal3 INTO rh_pretal[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
END IF
-----------
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_pretal
        INITIALIZE rh_pretal[1].* TO NULL
        RETURN 	rh_pretal[1].t20_numpre, rh_pretal[1].t23_cod_cliente,
		rh_pretal[1].t23_nom_cliente
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_pretal TO rh_pretal.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_pretal
IF int_flag THEN
        INITIALIZE rh_pretal[1].* TO NULL
        RETURN 	rh_pretal[1].t20_numpre, rh_pretal[1].t23_cod_cliente,
		rh_pretal[1].t23_nom_cliente
END IF
LET  i = arr_curr()
        RETURN 	rh_pretal[i].t20_numpre, rh_pretal[i].t23_cod_cliente,
		rh_pretal[i].t23_nom_cliente

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

OPEN WINDOW w_cliest AT 06,38 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf064'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_codcli_est, z01_nomcli
	IF int_flag THEN
		INITIALIZE rh_cliest[1].* TO NULL
		CLOSE WINDOW w_cliest
		RETURN rh_cliest[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT unique(t23_codcli_est), z01_nomcli 
			FROM talt023, cxct001 ",
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliest TO rh_cliest.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
LET  i = arr_curr()
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

DEFINE rh_provee ARRAY[1000] OF RECORD
   	p01_codprov      	LIKE cxpt001.p01_codprov,
	p01_nomprov		LIKE cxpt001.p01_nomprov 
        END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_provee AT 06,32 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf066'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p01_codprov, p01_nomprov
	IF int_flag THEN
		INITIALIZE rh_provee[1].* TO NULL
		CLOSE WINDOW w_provee
		RETURN rh_provee[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT p01_codprov, p01_nomprov 
			FROM cxpt001 ",
				"WHERE p01_estado =  'A'", " AND ",
				expr_sql CLIPPED,
				' ORDER BY 2'
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
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_provee TO rh_provee.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
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
	RETURN rh_provee[1].*
END IF
LET  i = arr_curr()
RETURN rh_provee[i].*

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
OPEN WINDOW wh_dctorep AT 06,41
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf067'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_dctorep TO rh_dctorep.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_dctoind AT 06,41
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf068'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_dctoind TO rh_dctoind.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

OPEN WINDOW w_chasis AT 06,11 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf069'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z01_nomcli, t10_modelo, t10_chasis, t10_placa, t10_color
	IF int_flag THEN
		INITIALIZE rh_chasis[1].* TO NULL
		CLOSE WINDOW w_chasis
		RETURN rh_chasis[1].*, rh_chacli[1].*
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_chasis TO rh_chasis.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i, '       ', rh_chacli[j].t23_nom_cliente
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
		INITIALIZE rh_placa[1].* TO NULL
		CLOSE WINDOW w_placa
		RETURN rh_placa[1].*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
		INITIALIZE rh_codveh[1].* TO NULL
		CLOSE WINDOW w_codveh
		RETURN rh_codveh[1].*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
OPEN WINDOW wh_nivcta AT 06,37
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf072'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_nivcta TO rh_nivcta.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

DEFINE rh_factal ARRAY[1000] OF RECORD
	t23_num_factura	LIKE talt023.t23_num_factura,
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
DEFINE estado  		LIKE talt023.t23_estado
DEFINE expr_estado	CHAR(50)

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_factal AT 06,32 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf073'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t23_num_factura, t23_nom_cliente
	IF int_flag THEN
		INITIALIZE rh_factal[1].* TO NULL
		CLOSE WINDOW w_factal
		RETURN rh_factal[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	IF estado = 'T' THEN
		LET expr_estado = " 1 = 1 "
	END IF
	IF estado <> 'T' THEN
		LET expr_estado = " t23_estado = '", estado, "'"
	END IF
	LET query = "SELECT t23_num_factura, t23_nom_cliente FROM talt023 ",
				"WHERE t23_compania =  ", cod_cia, " AND ",
				"t23_localidad = ", cod_loc, " AND ",
				"t23_num_factura IS NOT NULL", " AND ",
				expr_estado, " AND ",
				expr_sql CLIPPED,
				' ORDER BY 1'
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
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_factal TO rh_factal.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_factal
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_factal[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_factal[1].* TO NULL
	RETURN rh_factal[1].*
END IF
LET  i = arr_curr()
RETURN rh_factal[i].*

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
		INITIALIZE rh_ordche[1].* TO NULL
		CLOSE WINDOW w_ordche
		RETURN rh_ordche[1].*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                	EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
OPEN WINDOW wh_gructa AT 06,45
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf075'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_gructa TO rh_gructa.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_tipcomp AT 06,45
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf076'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_tipcomp')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_tipcomp CURSOR FOR
        SELECT b03_tipo_comp, b03_nombre
		 FROM ctbt003
		 WHERE b03_compania = cod_cia
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipcomp TO rh_tipcomp.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_stipcomp AT 06,45
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf077'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_stipcomp TO rh_stipcomp.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
                                                                                
DISPLAY 'Código'     TO bt_codigo
DISPLAY 'Serie'      TO bt_serie
DISPLAY 'Modelo'     TO bt_modelo
DISPLAY 'Color'      TO bt_color
DISPLAY 'E'          TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	v22_codigo_veh, v22_chasis, 
					v22_modelo, v22_cod_color, v22_estado
	IF int_flag THEN
		INITIALIZE rh_serveh[1].* TO NULL
		CLOSE WINDOW w_serveh
		RETURN rh_serveh[1].*
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
	LET query = "SELECT v22_codigo_veh, v22_chasis,
			v22_modelo, v22_cod_color,
			v22_estado FROM veht022 ", 
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
                ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
OPEN WINDOW wh_docbco AT 06,48
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf079'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_docbco TO rh_docbco.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

OPEN WINDOW w_vtaper AT 06,25 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf080'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY '#'           TO bt_serial
DISPLAY 'Item'        TO bt_item
DISPLAY 'Descripción' TO bt_nombre

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	r13_serial, r13_item, r10_nombre  
	IF int_flag THEN
		INITIALIZE rh_vtaper[1].* TO NULL
		CLOSE WINDOW w_vtaper
		RETURN rh_vtaper[1].*
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
	LET query = "SELECT r13_serial, r13_item,
			r10_nombre FROM rept013, rept010 ",
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
OPEN WINDOW wh_campre AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf081'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_campre TO rh_campre.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
                                                                                
DISPLAY 'Reserva'     TO bt_reserva
DISPLAY 'Vehículo'    TO bt_codigo
DISPLAY 'Vendedor'    TO bt_vendedor

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON v33_num_reserv,v33_codigo_veh,v01_nombres	
	IF int_flag THEN
		INITIALIZE rh_reser[1].* TO NULL
		CLOSE WINDOW w_reser
		RETURN rh_reser[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT v33_num_reserv, v33_codigo_veh, v01_nombres
			FROM veht033, veht001 ",
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
			LET salir = 1
                	EXIT DISPLAY
		AFTER DISPLAY
			LET salir = 1
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
OPEN WINDOW wh_filtro AT 06,46
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf084'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_filtro TO rh_filtro.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_tipdocte AT 06,53
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf085'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_tipdocte TO rh_tipdocte.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
                                                                                
DISPLAY 'Código'     TO bt_codigo
DISPLAY 'Serie'      TO bt_serie
DISPLAY 'Modelo'     TO bt_modelo
DISPLAY 'Color'      TO bt_color
DISPLAY 'E'          TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON 	v22_codigo_veh, v22_chasis, 
					v22_modelo, v22_cod_color, v22_estado
	IF int_flag THEN
		INITIALIZE rh_serveh_all[1].* TO NULL
		CLOSE WINDOW w_serveh_all
		RETURN rh_serveh_all[1].*
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
	LET query = "SELECT v22_codigo_veh, v22_chasis,
			v22_modelo, v22_cod_color,
			v22_estado FROM veht022 ", 
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
                ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
 


-- NO UTILIZAR ESTA AYUDA PRARA HACER OTRA
FUNCTION fl_ayuda_doc_favor_cob(cod_cia, cod_loc, cod_area, cod_cli, cod_doc)
DEFINE rh_favorcob ARRAY[100] OF RECORD
        z01_nomcli      	LIKE cxct001.z01_nomcli,
	z21_tipo_doc		LIKE cxct021.z21_tipo_doc,
	z21_num_doc		LIKE cxct021.z21_num_doc,
	z21_saldo		LIKE cxct021.z21_saldo,
	z21_moneda		LIKE cxct021.z21_moneda,
	g03_abreviacion		LIKE gent003.g03_abreviacion
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
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
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 100
OPEN WINDOW wh_favorcob AT 06,12
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf087'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Cliente'     TO bt_cliente
DISPLAY 'TP'          TO bt_tipo
DISPLAY 'Número'      TO bt_numero
DISPLAY 'Saldo'       TO bt_saldo
DISPLAY 'Mo'          TO bt_moneda
DISPLAY 'Area'        TO bt_area

LET filas_pant = fgl_scr_size('rh_favorcob')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
IF cod_doc IS NULL THEN
	LET expr_tipo = " 1 = 1 "
   ELSE
	LET expr_tipo = " z21_tipo_doc = '", cod_doc, "'"
END IF
{
IF cod_doc = 'NC' THEN
	LET expr_tipo = " z21_tipo_doc = ", "'NC'"
END IF
IF cod_doc = 'PA' THEN
	LET expr_tipo = " z21_tipo_doc = ", "'PA'"
END IF
}
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
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir 
LET query =   "	SELECT 	z01_nomcli, z21_tipo_doc, 
		z21_num_doc,z21_saldo,  z21_moneda, g03_abreviacion
		FROM   cxct021, cxct001, gent003
               	WHERE  z21_compania = ", cod_cia,
		" AND  g03_compania = ", cod_cia,
  		" AND  z21_compania =    g03_compania ",
		" AND  z21_localidad= ", cod_loc,
		" AND  z21_areaneg  =    g03_areaneg ",
		" AND  z21_codcli   =    z01_codcli ",
		" AND ", expr_cliente, 
		" AND ", expr_tipo, 
		" AND ", expr_area, 
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE favorcob FROM query
DECLARE q_favorcob CURSOR FOR favorcob
LET i = 1
FOREACH q_favorcob INTO rh_favorcob[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_favorcob
        INITIALIZE rh_favorcob[1].* TO NULL
        RETURN  rh_favorcob[1].z01_nomcli,
	        rh_favorcob[1].z21_tipo_doc, rh_favorcob[1].z21_num_doc,
	        rh_favorcob[1].z21_saldo,    rh_favorcob[1].z21_moneda,
		rh_favorcob[1].g03_abreviacion
END IF
CALL set_count(i)
LET int_flag = 0
---------------
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
	AFTER DISPLAY
        	LET salir = 1
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
CLOSE WINDOW wh_favorcob
IF int_flag THEN
        INITIALIZE rh_favorcob[1].* TO NULL
        RETURN  rh_favorcob[1].z01_nomcli,
	        rh_favorcob[1].z21_tipo_doc,  rh_favorcob[1].z21_num_doc,
	        rh_favorcob[1].z21_saldo,     rh_favorcob[1].z21_moneda,
		rh_favorcob[1].g03_abreviacion
END IF
LET  i = arr_curr()
RETURN  rh_favorcob[i].z01_nomcli,
        rh_favorcob[i].z21_tipo_doc,  rh_favorcob[i].z21_num_doc,
        rh_favorcob[i].z21_saldo,     rh_favorcob[i].z21_moneda,
	rh_favorcob[i].g03_abreviacion

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
OPEN WINDOW wh_distcta AT 06,24
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf088'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_distcta TO rh_distcta.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_ciacom AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf089'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacom TO rh_ciacom.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_ciacon AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf090'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacon TO rh_ciacon.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_ciates AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf091'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciates TO rh_ciates.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
OPEN WINDOW wh_ciacajg AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf094'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacajg TO rh_ciacajg.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_ciacajg
IF int_flag THEN
        INITIALIZE rh_ciacajg[1].* TO NULL
        RETURN 	rh_ciacajg[1].j00_compania, rh_ciacajg[1].g01_razonsocial  
END IF
LET  i = arr_curr()
RETURN 	rh_ciacajg[i].j00_compania, rh_ciacajg[i].g01_razonsocial  

END FUNCTION




FUNCTION fl_ayuda_forma_pago(cod_cia)
DEFINE cod_cia		LIKE cajt001.j01_compania
DEFINE rh_forpago ARRAY[100] OF RECORD
   	j01_codigo_pago      	LIKE cajt001.j01_codigo_pago,
        j01_nombre		LIKE cajt001.j01_nombre		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_forpago AT 06,49
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf095'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_forpago')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_forpago CURSOR FOR
        SELECT j01_codigo_pago, j01_nombre FROM cajt001
		WHERE j01_compania = cod_cia
        ORDER BY 1
LET i = 1
FOREACH q_forpago INTO rh_forpago[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_forpago
        INITIALIZE rh_forpago[1].* TO NULL
        RETURN 	rh_forpago[1].j01_codigo_pago, rh_forpago[1].j01_nombre  
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_forpago TO rh_forpago.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_forpago
IF int_flag THEN
        INITIALIZE rh_forpago[1].* TO NULL
        RETURN 	rh_forpago[1].j01_codigo_pago, rh_forpago[1].j01_nombre  
END IF
LET  i = arr_curr()
RETURN 	rh_forpago[i].j01_codigo_pago, rh_forpago[i].j01_nombre  

END FUNCTION



FUNCTION fl_ayuda_cajas(cod_cia, cod_loc)
DEFINE rh_cajas ARRAY[100] OF RECORD
   	j02_codigo_caja      	LIKE cajt002.j02_codigo_caja,
        j02_nombre_caja		LIKE cajt002.j02_nombre_caja		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE cajt002.j02_compania
DEFINE cod_loc		LIKE cajt002.j02_localidad
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_cajas AT 06,48
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf096'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_cajas')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_cajas CURSOR FOR
        SELECT j02_codigo_caja, j02_nombre_caja FROM cajt002
		WHERE j02_compania  = cod_cia
		  AND j02_localidad = cod_loc
        ORDER BY 1
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
        CLOSE WINDOW wh_cajas
        INITIALIZE rh_cajas[1].* TO NULL
        RETURN 	rh_cajas[1].j02_codigo_caja, rh_cajas[1].j02_nombre_caja  
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cajas TO rh_cajas.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_cajas
IF int_flag THEN
        INITIALIZE rh_cajas[1].* TO NULL
        RETURN 	rh_cajas[1].j02_codigo_caja, rh_cajas[1].j02_nombre_caja  
END IF
LET  i = arr_curr()
RETURN 	rh_cajas[i].j02_codigo_caja, rh_cajas[i].j02_nombre_caja  

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
OPEN WINDOW w_subcar AT 06,41 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf097'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_subcar TO rh_subcar.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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

DEFINE rh_cliloc ARRAY[1000] OF RECORD
	z02_codcli	LIKE cxct002.z02_codcli,
        z01_nomcli	LIKE cxct001.z01_nomcli
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc 		LIKE cxct002.z02_localidad
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cliloc AT 06,29 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf098'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Código'         TO bt_codigo
DISPLAY 'Nombre Cliente' TO bt_nombre

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z02_codcli, z01_nomcli
	IF int_flag THEN
		INITIALIZE rh_cliloc[1].* TO NULL
		CLOSE WINDOW w_cliloc
		RETURN rh_cliloc[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT z02_codcli, z01_nomcli FROM cxct001, cxct002 ",
				" WHERE z02_compania  = ",  cod_cia, 
				"   AND z02_localidad =",  cod_loc, 
				"   AND z02_codcli =  z01_codcli AND ", 
				"  z01_estado =  'A'", " AND ", 
				 expr_sql CLIPPED,
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliloc TO rh_cliloc.*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
	RETURN rh_cliloc[1].*
END IF
LET  i = arr_curr()
RETURN rh_cliloc[i].*

END FUNCTION



FUNCTION fl_ayuda_proveedores_localidad(cod_cia, cod_loc)

DEFINE rh_provloc ARRAY[1000] OF RECORD
   	p02_codprov      	LIKE cxpt002.p02_codprov,
	p01_nomprov		LIKE cxpt001.p01_nomprov 
        END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE cxpt002.p02_compania
DEFINE cod_loc		LIKE cxpt002.p02_localidad

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_provloc AT 06,32 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf099'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p02_codprov, p01_nomprov
	IF int_flag THEN
		INITIALIZE rh_provloc[1].* TO NULL
		CLOSE WINDOW w_provloc
		RETURN rh_provloc[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT p02_codprov, p01_nomprov 
			FROM cxpt002, cxpt001 ",
				"WHERE p02_compania  = ", cod_cia,
				"  AND p02_localidad = ", cod_loc,
				"  AND p02_codprov   = p01_codprov ",
				"  AND p01_estado =  'A'", " AND ",
				expr_sql CLIPPED,
				' ORDER BY 2'
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
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_provloc TO rh_provloc.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
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
	RETURN rh_provloc[1].*
END IF
LET  i = arr_curr()
RETURN rh_provloc[i].*

END FUNCTION
 


FUNCTION fl_ayuda_companias_cobranzas()
DEFINE rh_ciacob ARRAY[100] OF RECORD
   	z00_compania      	LIKE cxct000.z00_compania,
        g01_razonsocial		LIKE gent001.g01_razonsocial		 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_ciacob AT 06,39
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf100'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_ciacob')
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ciacob TO rh_ciacob.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
		INITIALIZE rh_vehfac[1].* TO NULL
		CLOSE WINDOW w_vehfac
		RETURN rh_vehfac[1].*
	END IF
	MESSAGE "Seleccionando datos .."
--------------
	LET query = " SELECT v30_codcli, z01_nomcli, v22_codigo_veh, v22_modelo
  			FROM veht022, veht030, cxct001 ",
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
DEFINE rh_reppre ARRAY[1000] OF RECORD
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
DEFINE grupo		LIKE rept003.r03_grupo_linea
DEFINE expr_bodega	CHAR(100)
DEFINE j		SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_reppre AT 06,07 
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf105'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
                   BORDER)
WHILE TRUE
	MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON 	r10_codigo, r10_nombre, r10_linea,
 					r10_precio_mb, r11_bodega,
					r11_stock_act
		BEFORE CONSTRUCT
			IF bodega <> '00' THEN
				DISPLAY bodega TO r11_bodega
			END IF
--			DISPLAY "> 0" TO r11_stock_act
	END CONSTRUCT
	IF int_flag THEN
		INITIALIZE rh_reppre[1].* TO NULL
		CLOSE WINDOW w_reppre
		RETURN rh_reppre[1].*
	END IF
	MESSAGE "Seleccionando datos .."
---------
{
        LET query = "SELECT r10_codigo, r10_nombre, r10_linea, r10_precio_mb, r11_bodega, r11_stock_act  FROM rept003, gent020, rept010, rept011 ",
                                " WHERE r03_compania = ", cod_cia, " AND ",
                                " g20_compania = ",       cod_cia, " AND ",
                                " r03_compania = g20_compania",    " AND ",
				" g20_grupo_linea = '", grupo,"'", " AND ",
                                " r03_compania = r10_compania ",   " AND ",
                                " r10_compania = r11_compania",    " AND ",
                                " r10_codigo = r11_item",          " AND ",
                                " r03_codigo = r10_linea",         " AND ",
                                " r03_grupo_linea = '", grupo,"'", " AND ",
                                " r11_bodega = '", bodega,"'",     " AND ",
                                 criterio CLIPPED
}
        LET query = "SELECT r10_codigo, r10_nombre, r10_linea, r10_precio_mb, r11_bodega, r11_stock_act  FROM rept010, rept011 ",
                                " WHERE r10_compania = ", cod_cia, " AND ",
                                " r10_compania = r11_compania",    " AND ",
                                " r10_codigo = r11_item",          " AND ",
                                " r11_bodega = '", bodega,"'",     " AND ",
                                " r10_linea IN ",
			        " (SELECT r03_codigo FROM rept003 ",
				" WHERE r03_compania = ", cod_cia, " AND ",
                                " r03_grupo_linea = '", grupo,"')", " AND ",
                                 criterio CLIPPED
---------
	PREPARE reppre FROM query
	DECLARE q_reppre CURSOR FOR reppre
	LET i = 1
	FOREACH q_reppre INTO rh_reppre[i].*
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
	DISPLAY ARRAY rh_reppre TO rh_reppre.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_reppre
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_reppre[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_reppre[1].* TO NULL
	RETURN rh_reppre[1].*
END IF
LET  i = arr_curr()
RETURN rh_reppre[i].*

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

OPEN WINDOW w_prerep AT 06,26 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf106'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Número'     TO bt_numero
DISPLAY 'Cliente'    TO bt_cliente
DISPLAY 'E'          TO bt_estado

WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r23_numprev, r23_nomcli, r23_estado
	IF int_flag THEN
		INITIALIZE rh_prerep[1].* TO NULL
		CLOSE WINDOW w_prerep
		RETURN rh_prerep[1].*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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
		INITIALIZE rh_preveh[1].* TO NULL
		CLOSE WINDOW w_preveh
		RETURN rh_preveh[1].*
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
                ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1
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

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_prorep AT 06,23 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf108'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r21_numprof, r21_nomcli
	IF int_flag THEN
		INITIALIZE rh_prorep[1].* TO NULL
		CLOSE WINDOW w_prorep
		RETURN rh_prorep[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT r21_numprof, r21_nomcli FROM rept021 ",
				"WHERE r21_compania =  ", cod_cia, " AND ",
				"r21_localidad = ", cod_loc, " AND ",
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_prorep TO rh_prorep.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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

DEFINE rh_numfue ARRAY[1000] OF RECORD
	j10_num_fuente	LIKE cajt010.j10_num_fuente,
	j10_nomcli	LIKE cajt010.j10_nomcli,
	j10_valor	LIKE cajt010.j10_valor 
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
DEFINE tip_fue		LIKE cajt010.j10_tipo_fuente

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_numfue AT 06,18 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf109'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON j10_num_fuente, j10_nomcli, j10_valor
	IF int_flag THEN
		INITIALIZE rh_numfue[1].* TO NULL
		CLOSE WINDOW w_numfue
		RETURN rh_numfue[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET expr_estado = " 1 = 1 "
	## Vía tip_fue = 'EC' se buscarán con Estado 'P,E' para los egresos
	IF tip_fue = 'EC' THEN
			LET expr_estado = " j10_estado  IN ('P','E') "
		ELSE
			LET expr_estado = " j10_estado  IN ('A') "
	END IF
	LET query = "SELECT j10_num_fuente, j10_nomcli, j10_valor FROM cajt010 ",
			"WHERE j10_compania =  ", cod_cia, " AND ",
			"j10_localidad = ", cod_loc, 	   " AND ",
			"j10_tipo_fuente = '", tip_fue,"'"," AND ",
			 expr_estado CLIPPED, " AND ",
--			"j10_estado = 'A'", " AND ",
			 expr_sql CLIPPED,
			" ORDER BY 1"
	PREPARE numfue FROM query
	DECLARE q_numfue CURSOR FOR numfue
	LET i = 1
	FOREACH q_numfue INTO rh_numfue[i].*
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
	DISPLAY ARRAY rh_numfue TO rh_numfue.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_numfue
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_numfue[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_numfue[1].* TO NULL
	RETURN rh_numfue[1].*
END IF
LET  i = arr_curr()
RETURN rh_numfue[i].*
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

OPEN WINDOW w_repsin AT 06,07 
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf110'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
                   BORDER)
WHILE TRUE
	MESSAGE "Digite condicion-búsqueda y presione (F12)"
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
		INITIALIZE rh_repsin[1].* TO NULL
		CLOSE WINDOW w_repsin
		RETURN rh_repsin[1].*
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_repsin TO rh_repsin.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
DEFINE rh_transac ARRAY[1000] OF RECORD
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

OPEN WINDOW w_transac AT 06,17 
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf111'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
                   BORDER)
WHILE TRUE
	MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON r19_cod_tran, r19_num_tran, r19_nomcli
	IF int_flag THEN
		INITIALIZE rh_transac[1].* TO NULL
		CLOSE WINDOW w_transac
		RETURN rh_transac[1].*
	END IF
	MESSAGE "Seleccionando datos .."
-----------
IF tip_tran = '00' THEN 
        LET query = "SELECT r19_cod_tran, r19_num_tran, r19_nomcli FROM rept019",
                                " WHERE r19_compania = ", cod_cia, " AND ",
			 	" r19_localidad = ",      cod_loc, " AND ",	
                                 criterio CLIPPED,  
        			" ORDER BY 2 "
	PREPARE transac1 FROM query
	DECLARE q_transac1 CURSOR FOR transac1
	LET i = 1
	FOREACH q_transac1 INTO rh_transac[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
       	 	END IF
	END FOREACH
END IF
---------
IF tip_tran <> '00' THEN 
        LET query = "SELECT r19_cod_tran, r19_num_tran, r19_nomcli FROM rept019",
                                " WHERE r19_compania = ", cod_cia, " AND ",
			 	" r19_localidad = ",      cod_loc, " AND ",	
		 		" r19_cod_tran  = '", tip_tran,"'"," AND ",
                                 criterio CLIPPED, 
        			" ORDER BY 2 "
	PREPARE transac2 FROM query
	DECLARE q_transac2 CURSOR FOR transac2
	LET i = 1
	FOREACH q_transac2 INTO rh_transac[i].*
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
		CLOSE WINDOW w_transac
		INITIALIZE rh_transac[1].* TO NULL
		RETURN  rh_transac[1].r19_cod_tran, rh_transac[1].r19_num_tran,
			rh_transac[1].r19_nomcli 
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_transac TO rh_transac.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
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
	RETURN rh_transac[1].*
END IF
LET  i = arr_curr()
RETURN rh_transac[i].*

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

OPEN WINDOW w_vtatal AT 06,17 
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf112'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
                   BORDER)
WHILE TRUE
	MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON 	r19_num_tran, r19_nomcli
	IF int_flag THEN
		INITIALIZE rh_vtatal[1].* TO NULL
		CLOSE WINDOW w_vtatal
		RETURN rh_vtatal[1].*
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_vtatal TO rh_vtatal.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
OPEN WINDOW wh_pedrep AT 06,18
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf113'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_pedrep TO rh_pedrep.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
DEFINE rh_liqrep ARRAY[1000] OF RECORD
   	r28_numliq      	LIKE rept028.r28_numliq,
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
DEFINE query		CHAR(500)
                                                                                
LET filas_max  = 1000
OPEN WINDOW wh_liqrep AT 06,61
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf114'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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

LET query = "SELECT r28_numliq, r28_estado FROM rept028 ",
		" WHERE r28_compania = ", cod_cia," AND ",
		" r28_localidad = ", cod_loc,     " AND ",
		expr_estado CLIPPED, 
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_liqrep TO rh_liqrep.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_liqrep
IF int_flag THEN
        INITIALIZE rh_liqrep[1].* TO NULL
        RETURN  rh_liqrep[1].r28_numliq
END IF
LET  i = arr_curr()
RETURN  rh_liqrep[i].r28_numliq

END FUNCTION



FUNCTION fl_ayuda_ordenes_compra(cod_cia, cod_loc, tipo, departamento, estado, modulo, ingresa) 
DEFINE rh_ordcom ARRAY[1000] OF RECORD
   	c10_numero_oc      	LIKE ordt010.c10_numero_oc,
   	c01_nombre      	LIKE ordt001.c01_nombre,
   	g34_nombre  	    	LIKE gent034.g34_nombre,
   	c10_solicitado      	LIKE ordt010.c10_solicitado 
	END RECORD
DEFINE i		SMALLINT
DEFINE criterio	CHAR(700)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(700)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE cod_cia		LIKE ordt010.c10_compania
DEFINE cod_loc		LIKE ordt010.c10_localidad
DEFINE tipo	 	LIKE ordt010.c10_tipo_orden
DEFINE departamento 	LIKE ordt010.c10_cod_depto
DEFINE estado	 	LIKE ordt010.c10_estado
DEFINE modulo		LIKE ordt001.c01_modulo
DEFINE ingresa		LIKE ordt001.c01_ing_bodega
DEFINE expr_tipo	CHAR(50)
DEFINE expr_depto	CHAR(50)
DEFINE expr_estado	CHAR(50)
DEFINE expr_modulo	CHAR(50)
DEFINE expr_ingresa	CHAR(50)
DEFINE j		SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_ordcom AT 06,03 
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf115'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE 16, MESSAGE LINE 16,
                   BORDER)
WHILE TRUE
	MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	CONSTRUCT BY NAME criterio ON 	c10_numero_oc, c01_nombre,
					g34_nombre, c10_solicitado
	IF int_flag THEN
		INITIALIZE rh_ordcom[1].* TO NULL
		CLOSE WINDOW w_ordcom
		RETURN rh_ordcom[1].c10_numero_oc
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
---------
        LET query = "SELECT c10_numero_oc, c01_nombre, g34_nombre, c10_solicitado  FROM ordt010, ordt001, gent034 ",
                  " WHERE c10_compania = ", cod_cia, " AND ",
                  " c10_localidad = ",  cod_loc,     " AND ",
                  " c10_tipo_orden = c01_tipo_orden"," AND ",
                  " c10_compania = g34_compania",    " AND ",
                  " c10_cod_depto = g34_cod_depto",  " AND ",
		  expr_tipo,                         " AND ", 
		  expr_depto,                        " AND ", 
		  expr_estado,                       " AND ", 
		  expr_modulo,                       " AND ", 
		  expr_ingresa,                      " AND ", 
                  criterio CLIPPED
---------
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
		CONTINUE WHILE
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_ordcom TO rh_ordcom.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_ordcom
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_ordcom[i].*
	END FOR
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

OPEN WINDOW w_trancob AT 06,28 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf116'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z22_tipo_trn, z22_num_trn, z01_nomcli
	IF int_flag THEN
		INITIALIZE rh_trancob[1].* TO NULL
		CLOSE WINDOW w_trancob
		RETURN rh_trancob[1].z22_num_trn
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_trancob TO rh_trancob.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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
DEFINE rh_deudacob ARRAY[100] OF RECORD
	z01_nomcli              LIKE cxct001.z01_nomcli,
	z20_tipo_doc		LIKE cxct020.z20_tipo_doc,
	z20_num_doc		LIKE cxct020.z20_num_doc,
	z20_dividendo		LIKE cxct020.z20_dividendo,
	z20_saldo    		LIKE cxct020.z20_saldo_cap,
	z20_moneda		LIKE cxct020.z20_moneda,
	g03_abreviacion		LIKE gent003.g03_abreviacion
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_area 	CHAR(45)	
DEFINE expr_cliente 	CHAR(45)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxct020.z20_compania
DEFINE cod_loc		LIKE cxct020.z20_localidad
DEFINE cod_area		LIKE cxct020.z20_areaneg
DEFINE cod_cli		LIKE cxct020.z20_codcli
DEFINE cod_doc		LIKE cxct020.z20_tipo_doc

LET filas_max  = 100
OPEN WINDOW wh_deudacob AT 06,02
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf117'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_deudacob')
LET int_flag = 0
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
 
LET query =   "	SELECT 	z01_nomcli, z20_tipo_doc, 
		z20_num_doc, z20_dividendo, (z20_saldo_cap + z20_saldo_int),  z20_moneda, g03_abreviacion
		FROM   cxct020, cxct001, gent003
               	WHERE  z20_compania = ", cod_cia,
		" AND  g03_compania = ", cod_cia,
  		" AND  z20_compania =    g03_compania ",
		" AND  z20_localidad= ", cod_loc,
		" AND  z20_areaneg  =    g03_areaneg ",
		" AND  z20_codcli   =    z01_codcli ",
		" AND ", expr_cliente, 
		" AND ", expr_tipo, 
		" AND ", expr_area, 
        	' ORDER BY 2 '
PREPARE deudacob FROM query
DECLARE q_deudacob CURSOR FOR deudacob
LET i = 1
FOREACH q_deudacob INTO rh_deudacob[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_deudacob
        INITIALIZE rh_deudacob[1].* TO NULL
        RETURN  rh_deudacob[1].z01_nomcli,
	        rh_deudacob[1].z20_tipo_doc, rh_deudacob[1].z20_num_doc,
		rh_deudacob[1].z20_dividendo,
	        rh_deudacob[1].z20_saldo    ,rh_deudacob[1].z20_moneda,
		rh_deudacob[1].g03_abreviacion
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_deudacob TO rh_deudacob.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_deudacob
IF int_flag THEN
        INITIALIZE rh_deudacob[1].* TO NULL
        RETURN  rh_deudacob[1].z01_nomcli,
	        rh_deudacob[1].z20_tipo_doc,  rh_deudacob[1].z20_num_doc,
		rh_deudacob[1].z20_dividendo,
	        rh_deudacob[1].z20_saldo    , rh_deudacob[1].z20_moneda,
		rh_deudacob[1].g03_abreviacion
END IF
LET  i = arr_curr()
RETURN  rh_deudacob[i].z01_nomcli,
        rh_deudacob[i].z20_tipo_doc,  rh_deudacob[i].z20_num_doc,
	rh_deudacob[i].z20_dividendo,
        rh_deudacob[i].z20_saldo    , rh_deudacob[i].z20_moneda,
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
OPEN WINDOW wh_deudates AT 06,06
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf118'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
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
 
LET query =   "	SELECT 	p01_nomprov, p20_tipo_doc, 
		p20_num_doc, p20_dividendo, p20_saldo_cap,  p20_moneda
		FROM   cxpt020, cxpt001
               	WHERE  p20_compania = ", cod_cia,
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
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_deudates TO rh_deudates.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
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
DEFINE rh_favortes ARRAY[100] OF RECORD
        p01_nomprov      	LIKE cxpt001.p01_nomprov,
	p21_tipo_doc		LIKE cxpt021.p21_tipo_doc,
	p21_num_doc		LIKE cxpt021.p21_num_doc,
	p21_saldo		LIKE cxpt021.p21_saldo,
	p21_moneda		LIKE cxpt021.p21_moneda 
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_tipo 	CHAR(45)	
DEFINE expr_area 	CHAR(45)	
DEFINE expr_proveedor 	CHAR(45)	
DEFINE query		CHAR(550)
DEFINE cod_cia		LIKE cxpt021.p21_compania
DEFINE cod_loc		LIKE cxpt021.p21_localidad
DEFINE cod_prov		LIKE cxpt021.p21_codprov
DEFINE cod_doc		LIKE cxpt021.p21_tipo_doc

LET filas_max  = 100
OPEN WINDOW wh_favortes AT 06,20
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf119'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_favortes')
LET int_flag = 0
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
 
LET query =   "	SELECT 	p01_nomprov, p21_tipo_doc, 
		p21_num_doc, p21_saldo,  p21_moneda
		FROM   cxpt021, cxpt001
               	WHERE  p21_compania = ", cod_cia,
		" AND  p21_localidad= ", cod_loc,
		" AND  p21_codprov  =    p01_codprov ",
		" AND ", expr_proveedor, 
		" AND ", expr_tipo, 
        	' ORDER BY 2 '
PREPARE favortes FROM query
DECLARE q_favortes CURSOR FOR favortes
LET i = 1
FOREACH q_favortes INTO rh_favortes[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_favortes
        INITIALIZE rh_favortes[1].* TO NULL
        RETURN  rh_favortes[1].p01_nomprov,
	        rh_favortes[1].p21_tipo_doc, rh_favortes[1].p21_num_doc,
	        rh_favortes[1].p21_saldo,    rh_favortes[1].p21_moneda 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_favortes TO rh_favortes.*
        ON KEY(RETURN)
                EXIT DISPLAY
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_favortes
IF int_flag THEN
        INITIALIZE rh_favortes[1].* TO NULL
        RETURN  rh_favortes[1].p01_nomprov,
	        rh_favortes[1].p21_tipo_doc,  rh_favortes[1].p21_num_doc,
	        rh_favortes[1].p21_saldo,     rh_favortes[1].p21_moneda 
END IF
LET  i = arr_curr()
RETURN  rh_favortes[i].p01_nomprov,
        rh_favortes[i].p21_tipo_doc,  rh_favortes[i].p21_num_doc,
        rh_favortes[i].p21_saldo,     rh_favortes[i].p21_moneda 

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

OPEN WINDOW w_trantes AT 06,28 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf120'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p22_tipo_trn, p22_num_trn, p01_nomprov
	IF int_flag THEN
		INITIALIZE rh_trantes[1].* TO NULL
		CLOSE WINDOW w_trantes
		RETURN rh_trantes[1].p22_num_trn
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
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_trantes TO rh_trantes.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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



FUNCTION fl_ayuda_retenciones(cod_cia)
DEFINE i		SMALLINT
DEFINE rh_ret ARRAY[50] OF RECORD
	c02_tipo_ret		LIKE ordt002.c02_tipo_ret,
	c02_porcentaje		LIKE ordt002.c02_porcentaje,
	c02_nombre		LIKE ordt002.c02_nombre
	END RECORD
DEFINE cod_cia		LIKE ordt002.c02_compania

OPEN WINDOW wh_ret AT 06,44
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf121'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
DECLARE q_ret CURSOR FOR
	SELECT c02_tipo_ret, c02_porcentaje, c02_nombre 
		FROM ordt002 
		WHERE c02_compania = cod_cia
		  AND c02_estado = 'A'
		ORDER BY 1
LET i = 1
FOREACH q_ret INTO rh_ret[i].*
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i = 0 THEN	
        CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW wh_ret
        RETURN rh_ret[1].c02_tipo_ret, rh_ret[1].c02_porcentaje,
               rh_ret[1].c02_nombre
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_ret TO rh_ret.*
CLOSE WINDOW wh_ret
IF int_flag THEN
	INITIALIZE rh_ret[1].* TO NULL
        RETURN rh_ret[1].c02_tipo_ret, rh_ret[1].c02_porcentaje,
               rh_ret[1].c02_nombre
END IF
LET i = arr_curr()
RETURN rh_ret[i].c02_tipo_ret, rh_ret[i].c02_porcentaje,
       rh_ret[i].c02_nombre

END FUNCTION




FUNCTION fl_ayuda_procesos_roles()
DEFINE i		SMALLINT
DEFINE rh_prorol ARRAY[100] OF RECORD
	n03_proceso		LIKE rolt003.n03_proceso,
	n03_nombre		LIKE rolt003.n03_nombre 
	END RECORD

OPEN WINDOW wh_prorol AT 06,46
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf122'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
DECLARE q_prorol CURSOR FOR
	SELECT n03_proceso, n03_nombre
		FROM rolt003 
		WHERE n03_estado = 'A'
		ORDER BY 1
LET i = 1
FOREACH q_prorol INTO rh_prorol[i].*
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i = 0 THEN	
        CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW wh_prorol
        RETURN rh_prorol[1].n03_proceso, rh_prorol[1].n03_nombre 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_prorol TO rh_prorol.*
CLOSE WINDOW wh_prorol
IF int_flag THEN
	INITIALIZE rh_prorol[1].* TO NULL
        RETURN rh_prorol[1].n03_proceso, rh_prorol[1].n03_nombre 
END IF
LET i = arr_curr()
RETURN rh_prorol[i].n03_proceso, rh_prorol[i].n03_nombre 

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

OPEN WINDOW w_rubrol AT 06,25 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf123'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n06_cod_rubro, n06_nombre
	IF int_flag THEN
		INITIALIZE rh_rubrol[1].* TO NULL
		CLOSE WINDOW w_rubrol
		RETURN rh_rubrol[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_det_tot = " 1 = 1 "
	IF det_tot <> '00' THEN
		LET expr_det_tot = " n06_det_tot = '", det_tot, "'"
	END IF
	LET expr_can_val = " 1 = 1 "
	IF can_val <> 'T' THEN
		LET expr_can_val = " n06_can_val = '", can_val, "'"
	END IF
	LET expr_calculo = " 1 = 1 "
	IF calculo <> 'T' THEN
		LET expr_calculo = " n06_calculo = '", calculo, "'"
	END IF
	LET expr_ing_usu = " 1 = 1 "
	IF ing_usu <> 'T' THEN
		LET expr_ing_usu = " n06_ing_usu = '", ing_usu, "'"
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
				 ' ORDER BY 1'
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
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

OPEN WINDOW w_pagprov AT 06,42 
	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf124'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 16,
		   BORDER)
		   
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

DISPLAY 'Orden'     TO bt_orden
DISPLAY 'Proveedor' TO bt_proveedor
		   
WHILE TRUE
	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON p24_orden_pago, p01_nomprov
	IF int_flag THEN
		INITIALIZE rh_pagprov[1].* TO NULL
		CLOSE WINDOW w_pagprov
		RETURN rh_pagprov[1].p24_orden_pago 
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1

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
		INITIALIZE rh_ubica[1].* TO NULL
		CLOSE WINDOW w_ubica
		RETURN rh_ubica[1].r11_ubicacion 
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
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                AFTER DISPLAY
                        LET salir = 1

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
OPEN WINDOW wh_concilia AT 06,20
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf132'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Número'     TO bt_numero
DISPLAY 'Estado'     TO bt_estado
DISPLAY 'Banco'      TO bt_banco
DISPLAY 'Cuenta'     TO bt_cuenta
DISPLAY 'Auxiliar'   TO bt_auxiliar

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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
        AFTER DISPLAY
                LET salir = 1
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



------- A partir de aqui las funciones del modulo de servicio post-venta 
------- aka (MAQUINARIAS)

FUNCTION fl_ayuda_modelos_lineas_maq(cod_cia)
DEFINE cod_cia 		LIKE maqt010.m10_compania
DEFINE rh_modmaq ARRAY[300] OF RECORD
        m10_linea	      	LIKE maqt010.m10_linea,
	m05_nombre		LIKE maqt005.m05_nombre,
   	m10_modelo      	LIKE maqt010.m10_modelo,
	m10_descripcion		LIKE maqt010.m10_descripcion
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
                                                                                
LET filas_max  = 300
OPEN WINDOW wh_modmaq AT 06,20
 	WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf400'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
DISPLAY 'Línea '      TO bt_linea
DISPLAY 'Nombre'      TO bt_nomblinea
DISPLAY 'Modelo'      TO bt_modelo
DISPLAY 'Descripción' TO bt_descmodelo

LET filas_pant = fgl_scr_size('rh_modmaq')
LET int_flag = 0

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET vm_columna_4 = 4
LET vm_columna_5 = 5
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir

	MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON m10_linea, m05_nombre, m10_modelo, m10_descripcion
	IF int_flag THEN
		INITIALIZE rh_modmaq[1].* TO NULL
		CLOSE WINDOW wh_modmaq
		RETURN rh_modmaq[1].*
	END IF

	MESSAGE 'Seleccionando datos..' 
--------------
LET query = " SELECT m10_linea, m05_nombre, m10_modelo, m10_descripcion ", 
	    "   FROM maqt010, maqt005 ",
	    "  WHERE m10_compania =  ", cod_cia, 
            "    AND m05_compania = m10_compania ", 
            "    AND m05_linea    = m10_linea ", 
            "    AND ", expr_sql CLIPPED ,
            "  ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
                     ", ", vm_columna_2, " ", rm_orden[vm_columna_2]

PREPARE query_model FROM query
DECLARE q_model CURSOR FOR query_model
--------------

LET i = 1
FOREACH q_model INTO rh_modmaq[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_modmaq
        INITIALIZE rh_modmaq[1].* TO NULL
        RETURN rh_modmaq[1].* 
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_modmaq TO rh_modmaq.*
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
	BEFORE ROW
		LET j = arr_curr()
		MESSAGE  j, ' de ', i
        AFTER DISPLAY
                LET salir = 1
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
CLOSE WINDOW wh_modmaq
IF int_flag THEN
        INITIALIZE rh_modmaq[1].* TO NULL
        RETURN rh_modmaq[1].*
END IF
LET  i = arr_curr()
RETURN rh_modmaq[i].*

END FUNCTION



FUNCTION fl_ayuda_provincias()
DEFINE rh_provi ARRAY[30] OF RECORD
        m01_provincia           LIKE maqt001.m01_provincia,
        m01_nombre              LIKE maqt001.m01_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        SMALLINT
                                                                                
LET filas_max  = 30
OPEN WINDOW wh AT 06,39 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf401'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_provi')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'
DECLARE qh_provi CURSOR FOR
        SELECT m01_provincia, m01_nombre FROM maqt001
        ORDER BY 2
LET i = 1
FOREACH qh_provi INTO rh_provi[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh_provi[1].* TO NULL
        RETURN rh_provi[1].*
                                                                                
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_provi TO rh_provi.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_provi[1].* TO NULL
        RETURN rh_provi[1].*
END IF
LET  i = arr_curr()
RETURN rh_provi[i].*

END FUNCTION



FUNCTION fl_ayuda_cantones(provincia)
DEFINE rh_aux  ARRAY[250] OF LIKE maqt001.m01_provincia
DEFINE rh_cant ARRAY[250] OF RECORD
        m01_nombre	        LIKE maqt001.m01_nombre,
	m02_canton		LIKE maqt002.m02_canton,
        m02_nombre              LIKE maqt002.m02_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j        SMALLINT
DEFINE provincia        LIKE maqt002.m02_provincia
DEFINE query		VARCHAR(250)
DEFINE expr_provi	VARCHAR(50)
                                                                                
LET filas_max  = 250
OPEN WINDOW wh AT 06,39 WITH FORM '../../../PRODUCCION/LIBRERIAS/forms/ayuf402'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST -1, MESSAGE LINE LAST,
                   BORDER)
LET filas_pant = fgl_scr_size('rh_cant')
LET int_flag = 0
MESSAGE 'Seleccionando datos..'

LET expr_provi = ' '
IF provincia IS NOT NULL THEN
	LET expr_provi = ' AND m01_provincia = ', provincia	
END IF

LET query = 'SELECT m02_provincia, m01_nombre, m02_canton, m02_nombre ',
            '  FROM maqt001, maqt002 ',
            ' WHERE m02_provincia = m01_provincia ',
	    expr_provi,
            ' ORDER BY 2, 4 '

PREPARE stmnt_canton FROM query 
DECLARE qh_cant CURSOR FOR stmnt_canton

LET i = 1
FOREACH qh_cant INTO rh_aux[i], rh_cant[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh
        INITIALIZE rh_aux[1], rh_cant[1].* TO NULL
        RETURN rh_aux[1], rh_cant[1].*
                                                                                
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_cant TO rh_cant.*
        ON KEY(RETURN)
                EXIT DISPLAY
        BEFORE ROW
                LET j = arr_curr()
                MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh
IF int_flag THEN
        INITIALIZE rh_aux[1], rh_cant[1].* TO NULL
        RETURN rh_aux[1], rh_cant[1].*
END IF
LET  i = arr_curr()
RETURN rh_aux[i], rh_cant[i].*

END FUNCTION

