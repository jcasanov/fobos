------------------------------------------------------------------------------
-- Titulo           : repp432.4gl - Listado De Items Por Clasificación
-- Elaboracion      : 26-Sept-2011
-- Autor            : MTP
-- Formato Ejecucion: fglrun repp432 base módulo compañía moneda bodega
--                                      query [linea clasif_a clasif_b clasif_c clasifd clasif_e
--                                      col1 col2 ordA ordD]
-- Ultima Correccion:
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia           RECORD LIKE gent001.*
DEFINE rm_g04           RECORD LIKE gent004.*
DEFINE rm_g05           RECORD LIKE gent005.*
DEFINE vm_moneda_des    LIKE gent013.g13_nombre
DEFINE vm_max_rows      SMALLINT
DEFINE rm_par           RECORD
                                moneda          LIKE gent013.g13_moneda,
                                bodega          LIKE rept002.r02_codigo,
                                query           VARCHAR(1000),
                                linea           LIKE rept003.r03_codigo,
				clasif_a        CHAR(1),
			        clasif_b        CHAR(1),
			        clasif_c        CHAR(1),
			        clasif_d        CHAR(1),
			        clasif_e        CHAR(1)

                        END RECORD

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp432.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 16  THEN
        -- Validar # parámetros correcto
        CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
        EXIT PROGRAM
END IF
LET vg_base                             = arg_val(1)
LET vg_modulo                           = arg_val(2)
LET vg_codcia                           = arg_val(3)
LET rm_par.moneda                       = arg_val(4)
LET rm_par.bodega                       = arg_val(5)
LET rm_par.query                        = arg_val(6)
LET rm_par.linea                        = arg_val(7)
LET rm_par.clasif_a                     = arg_val(8) 
LET rm_par.clasif_b                     = arg_val(9) 
LET rm_par.clasif_c                     = arg_val(10) 
LET rm_par.clasif_d                     = arg_val(11) 
LET rm_par.clasif_e                     = arg_val(12) 

LET vm_columna_1                        = arg_val(13)
LET vm_columna_2                        = arg_val(14)
LET rm_orden[vm_columna_1]      	= arg_val(15)
LET rm_orden[vm_columna_2]      	= arg_val(16)
LET vg_proceso = 'repp432'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN


FUNCTION funcion_master()
CREATE TEMP TABLE temp_item
        (codigo         CHAR(15),
         nombre         CHAR(40),
         fob            DECIMAL (14,2),
         precio         DECIMAL (14,2),
         te_stock_disp  INTEGER,
         stock          INTEGER,
	 abc		VARCHAR(1)	)

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 08 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
              MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
        ACCEPT KEY      F12
LET vm_max_rows = 2000
CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
CALL control_reporte()

END FUNCTION

FUNCTION control_reporte()
DEFINE i,col            SMALLINT
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE rs               RECORD LIKE rept011.*
DEFINE r_rep            RECORD
                                codigo  LIKE rept010.r10_codigo,
                                nombre  LIKE rept010.r10_nombre,
                                fob     DECIMAL (14,2),
                                precio  DECIMAL (14,2),
                                stock_disp  INTEGER,
                                stock   INTEGER,
				clasif VARCHAR(1)
                        END RECORD
DEFINE comando          VARCHAR(100)
DEFINE query            VARCHAR(1000)
DEFINE te_stock_disp    INTEGER
DEFINE te_abc           VARCHAR(1)
DEFINE inserta_reg      SMALLINT  -- indica que si se puede o no insertar "x" reg  

CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe moneda base.','stop')
        EXIT PROGRAM
END IF
LET vm_moneda_des = r_mon.g13_nombre
WHILE TRUE
        CALL fl_control_reportes() RETURNING comando
        IF int_flag THEN
                EXIT WHILE
        END IF
        CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

        PREPARE cit FROM rm_par.query
        DECLARE q_cit CURSOR FOR cit
        LET i = 0
	LET inserta_reg = 1
        FOREACH q_cit INTO r_rep.codigo,r_rep.nombre, r_rep.clasif, r_rep.fob,r_rep.precio

          	CASE r_rep.clasif 
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

                	CALL fl_lee_stock_rep(vg_codcia, rm_par.bodega, r_rep.codigo)
                        RETURNING rs.*
	                IF rs.r11_stock_act IS NULL THEN
        	                LET rs.r11_stock_act = 0
				LET r_rep.stock= 0
			  ELSE
				LET r_rep.stock= rs.r11_stock_act	
                	END IF

			LET te_stock_disp = fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, r_rep.codigo, 'R')
		        IF te_stock_disp < 0 THEN
        			LET te_stock_disp = 0
				LET r_rep.stock_disp=0
			  ELSE
				LET r_rep.stock_disp=te_stock_disp
		        END IF

        	        LET i = i + 1
			IF i > vm_max_rows THEN
                        	EXIT FOREACH
	                END IF

        	        INSERT INTO temp_item VALUES (r_rep.codigo, r_rep.nombre,
                                        r_rep.fob, r_rep.precio,
                                        te_stock_disp, rs.r11_stock_act,r_rep.clasif)
		END IF

        END FOREACH
        
	LET query = 'SELECT * FROM temp_item ',
                ' ORDER BY ',
                vm_columna_1, ' ', rm_orden[vm_columna_1], ',',
                vm_columna_2, ' ', rm_orden[vm_columna_2]
        START REPORT rep_items TO PIPE comando
        PREPARE crep FROM query
        DECLARE q_crep CURSOR FOR crep
        FOREACH q_crep INTO r_rep.*
                OUTPUT TO REPORT rep_items (r_rep.*)
        END FOREACH
        DELETE FROM temp_item
        FINISH REPORT rep_items
END WHILE

END FUNCTION

REPORT rep_items(r_rep)

DEFINE r_rep            RECORD

	codigo		LIKE rept010.r10_codigo,
        nombre  	LIKE rept010.r10_nombre,
        fob     	DECIMAL (14,2),
        precio  	DECIMAL (14,2),
        stock_disp  	INTEGER,
        stock   	INTEGER,
        clasif		VARCHAR(1)

END RECORD

DEFINE stock            LIKE rept011.r11_stock_act
DEFINE r_r02            RECORD LIKE rept002.* --bodegas
DEFINE r_r03            RECORD LIKE rept003.* --lineas
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT

OUTPUT
        TOP MARGIN      1
        LEFT MARGIN     1
        RIGHT MARGIN    90
        BOTTOM MARGIN   4
        PAGE LENGTH     66
FORMAT

PAGE HEADER
        print '^[E'; print '^[&l26A';   -- Indica que voy a trabajar con hojas A4
        print '^[&k4S'                  -- Letra (12 cpi)
        LET modulo  = "Módulo: Repuestos"
        LET long    = LENGTH(modulo)
        LET usuario = 'Usuario: ', vg_usuario
        CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
        CALL fl_justifica_titulo('I', 'LISTADO DE ITEMS POR CLASIFICACION', 80)
                RETURNING titulo
        CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega)
                RETURNING r_r02.*

        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 70, "Página: ", PAGENO USING "&&&"
        PRINT COLUMN 1, modulo CLIPPED,
              COLUMN 32, titulo CLIPPED,
              COLUMN 74, UPSHIFT(vg_proceso)
        PRINT COLUMN 20, "** Moneda         : ", rm_par.moneda, " ",
                                                vm_moneda_des
        PRINT COLUMN 20, "** Bodega         : ", rm_par.bodega, " ",
                                                r_r02.r02_nombre
        IF rm_par.linea <> 'XX' THEN
                CALL fl_lee_linea_rep(vg_codcia, rm_par.linea)
                        RETURNING r_r03.*
	 PRINT COLUMN 20, "** Línea         : ", rm_par.linea, " ",
                                                r_r03.r03_nombre
        END IF
        
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
              COLUMN 62, usuario
        SKIP 1 LINES
        print '^[&k4S'                  -- Letra condensada (12 cpi)
        PRINT COLUMN 1,   "Item",
              COLUMN 17,  "Descripción",
              COLUMN 40,  "Fob",
              COLUMN 54,  "Precio Unit.",
              COLUMN 68,  "Disp.",
              COLUMN 76,  "Stock",
              COLUMN 84,  "ABC"
        PRINT "-----------------------------------------------------------------------------------------"

ON EVERY ROW
        NEED 2 LINES
        PRINT COLUMN 1,   r_rep.codigo,
              COLUMN 17,  r_rep.nombre[1,20],
              COLUMN 38,  r_rep.fob  USING "---,---,--&.##",
              COLUMN 52,  r_rep.precio USING "---,---,--&.##",
              COLUMN 70,  r_rep.stock_disp USING "###&",
              COLUMN 77,  r_rep.stock  USING "###&",
              COLUMN 85,  r_rep.clasif  
ON LAST ROW

END REPORT



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
