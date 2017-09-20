--------------------------------------------------------------------------------
-- Titulo           : menp000.4gl - MENU PRINCIPAL DE FHOBOS
-- Elaboracion      : 10-ago-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun menp000 base modulo
-- Ultima Correccion: 11-ago-2001
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows		ARRAY[1000] OF INTEGER 	-- ARREGLO DE ROWID DE FILAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE ejecuta		VARCHAR(200)
--DEFINE fondo		CHAR(25)
DEFINE fondo_pp		CHAR(25)
DEFINE fondo_phobos	CHAR(25)
DEFINE a		CHAR(25)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/menp000.err')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp000'
LET vm_titprog   = 'MENU PRINCIPAL - PHOBOS'
LET fondo_pp     = 'phobos_biger'
LET fondo_phobos = 'phobos_titulo'
--LET fondo   	 = 'phobos_small'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vm_titprog)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL primera_pantalla()

END MAIN



FUNCTION primera_pantalla()
DEFINE p		  SMALLINT

WHILE TRUE
OPEN WINDOW w_primera_pantalla AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf000 FROM '../forms/menf000'
DISPLAY FORM f_menf000
DISPLAY fondo_pp	  TO c000   ## Picture
DISPLAY "Bienvenidos"  	  TO c100   ## Botón

LET p = fgl_getkey()

CASE p
	WHEN 1 
		CLOSE WINDOW w_primera_pantalla
  		CALL funcion_master()
        WHEN 13
                CLOSE WINDOW w_primera_pantalla
                CALL funcion_master()
	WHEN 0 
		--CLOSE WINDOW w_menu_vehiculos
		CLOSE WINDOW w_primera_pantalla
  		EXIT PROGRAM
	WHEN 2016 
		CALL primera_pantalla()
END CASE
END WHILE

END FUNCTION



FUNCTION funcion_master()
DEFINE cod_cia		LIKE gent002.g02_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE a		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_principal AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE LAST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf100 FROM '../forms/menf100r'

DISPLAY FORM f_menf100
--DISPLAY "Vehículos" 	TO c1000   ## Botón
--DISPLAY "Maquinarias" 	TO c1000   ## Botón
DISPLAY "Inventarios" 	TO c2000   ## Botón
DISPLAY "Talleres"  	TO c3000   ## Botón
DISPLAY "Cobranzas"    	TO c4000   ## Botón
DISPLAY "Tesorería" 	TO c5000   ## Botón
DISPLAY "Contabilidad" 	TO c6000   ## Botón
DISPLAY "Nómina"   	TO c7000   ## Botón
DISPLAY "Compras" 	TO c8000   ## Botón
DISPLAY "Caja" 		TO c9000   ## Botón
DISPLAY "Activos Fijos"	TO c10000  ## Botón
DISPLAY "Generales" 	TO c20000  ## Botón
DISPLAY "S.R.I." 	TO c11000  ## Botón
DISPLAY "phobos_titulo" TO c30000  ## Phobos

--DISPLAY "vehiculos"   TO c1001   ## Picture 
--DISPLAY "maquinarias"   TO c1001   ## Picture 
DISPLAY "repuestos"     TO c2001   ## Picture 
DISPLAY "talleres"    	TO c3001   ## Picture 
DISPLAY "talleres_dit"  TO c3001   ## Picture 
DISPLAY "cobranzas"     TO c4001   ## Picture
DISPLAY "tesoreria"     TO c5001   ## Picture
DISPLAY "contabilidad"  TO c6001   ## Picture
DISPLAY "nomina"	TO c7001   ## Picture
DISPLAY "compras"	TO c8001   ## Picture
DISPLAY "caja"		TO c9001   ## Picture
DISPLAY "activos"	TO c10001  ## Picture
DISPLAY "generales"  	TO c20001  ## Picture
DISPLAY "sri"	  	TO c11001  ## Picture

--OPEN WINDOW lwin AT 01,83 WITH 19 ROWS, 20 COLUMNS
--     ATTRIBUTE(BLINK,BOLD,FORM LINE 1)
--     OPEN FORM logo FROM "../forms/logo"
--     DISPLAY FORM logo ATTRIBUTE(BLINK,BOLD)
--     DISPLAY "phobos_titulo.bmp" TO F1 ATTRIBUTE(BLINK,REVERSE)

LET a = fgl_getkey()
IF a = 3001 THEN
	CALL fl_ayuda_compania_principal() RETURNING cod_cia, cod_local
	IF cod_cia IS NOT NULL THEN
               	LET vg_codcia = cod_cia
		LET vg_codloc = cod_local
		CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
	END IF
END IF
{--
IF a = 3010 THEN
	IF fl_control_acceso_proceso_men(vg_usuario, vg_codcia, vg_modulo,
					'menp000')
	THEN
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'MENU', vg_separador, 'fuentes', vg_separador, '; sh -c "fglrun menp000 ', vg_base, ' ', vg_modulo, '"'
		RUN ejecuta
	END IF
END IF
--}
IF a = 26 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'VE') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_vehiculos()
	END IF
END IF
IF a = 25 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'RE') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_repuestos()
	END IF
END IF
IF a = 24 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'TA') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_talleres()
	END IF
END IF
IF a = 23 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'CO') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_cobranzas()
	END IF
END IF
IF a = 22 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'TE') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_tesoreria()
	END IF
END IF
IF a = 21 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'CB') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_contabilidad()
	END IF
END IF
IF a = 20 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'SR') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_sri()
	END IF
END IF
IF a = 19 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'OC') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_compras()
	END IF
END IF
IF a = 18 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'CG') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_caja()
	END IF
END IF
IF a = 17 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'AF') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_activos_fijos()
	END IF
END IF
IF a = 16 THEN
	CLOSE WINDOW w_menu_principal
	EXIT PROGRAM
END IF
IF a = 15 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'GE') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_configuracion_gen()
	END IF
END IF
IF a = 14 THEN
	IF tiene_acceso(vg_usuario, vg_codcia, 'RO') THEN
		CLOSE WINDOW w_menu_principal
		CALL menu_nomina()
	END IF
END IF
IF a = 0 THEN
	CLOSE WINDOW w_menu_principal
	EXIT PROGRAM
END IF
END WHILE
END FUNCTION

------------------------ V E H I C U L O S  -----------------------

FUNCTION menu_vehiculos()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_vehiculos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf101 FROM '../forms/menf101'
DISPLAY FORM f_menf101
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_vehiculos" TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Pedidos"         TO c300   ## Botón
DISPLAY "Consultas"       TO c400   ## Botón
DISPLAY "Reportes"        TO c500   ## Botón
LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_vehiculos
  		CALL menu_configuracion_veh()
	WHEN 2 
		CLOSE WINDOW w_menu_vehiculos
		CALL menu_transacciones_veh()
	WHEN 3 
		CLOSE WINDOW w_menu_vehiculos
		CALL menu_pedidos_veh()
	WHEN 4 
		CLOSE WINDOW w_menu_vehiculos
		CALL menu_consultas_veh()
	WHEN 5 
		CLOSE WINDOW w_menu_vehiculos
		CALL menu_reportes_veh()
	WHEN 0 
		CLOSE WINDOW w_menu_vehiculos
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_vehiculos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_veh()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf102 FROM '../forms/menf102'
DISPLAY FORM f_menf102
--DISPLAY fondo		TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     TO c100   ## Botón 1
DISPLAY "Vend./Bodeg" TO c200   ## Botón 2
DISPLAY "Bodegas"       TO c300   ## Botón 3
DISPLAY "Líneas"   	TO c400   ## Botón 4
DISPLAY "Vehículos"  	TO c500   ## Botón 5
DISPLAY "Colores"     	TO c600   ## Botón 6
DISPLAY "Financiamiento" TO c700  ## Botón 7
DISPLAY "Modelos" 	TO c800   ## Botón 8
DISPLAY "Reservaciones" TO c900   ## Botón 9

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp100 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp101 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp102 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp103 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp104 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp105 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp106 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp107 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp208 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_vehiculos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_veh()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf103 FROM '../forms/menf103'
DISPLAY FORM f_menf103
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Series"     		TO c100   ## Botón 1
DISPLAY "Proformas"     	TO c200   ## Botón 2
DISPLAY "Pre-Ventas"     	TO c300   ## Botón 3
DISPLAY "Transferencias" 	TO c400   ## Botón 4
DISPLAY "Ajustes Costos"       	TO c500   ## Botón 5
DISPLAY "Ajustes Existencias"  	TO c600   ## Botón 6
DISPLAY "Devolución Facturas"  	TO c700   ## Botón 7
DISPLAY "Orden de Chequeos"  	TO c800   ## Botón 8
DISPLAY "Reservaciones"  	TO c900   ## Botón 9
DISPLAY "Aprobación Preventas" 	TO c1000  ## Botón 10

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp108 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp200 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp201 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc, 0
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp204 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp205 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp206 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp207 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp214 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp209 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp216 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_vehiculos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_pedidos_veh()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE e		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_pedidos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf104 FROM '../forms/menf104'
DISPLAY FORM f_menf104
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_pedidos"	        TO a      ## Picture 
DISPLAY "Ingreso Pedidos"     	TO c100   ## Botón 1
DISPLAY "Recepción Pedidos"    	TO c200   ## Botón 2
DISPLAY "Liquidacion"     	TO c300   ## Botón 3
DISPLAY "Cierre Pedidos" 	TO c400   ## Botón 4

LET e = fgl_getkey()

CASE e
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp210 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp211 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp212 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc, 0
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp213 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_pedidos
		CALL menu_vehiculos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_consultas_veh()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf106 FROM '../forms/menf106'
DISPLAY FORM f_menf106
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Estadística Bodegas"   TO c100   ## Botón 1  vehp300
DISPLAY "Estadística Vendedor"  TO c200   ## Botón 2  vehp301
DISPLAY "Estadística Modelo"    TO c300   ## Botón 3  vehp302
DISPLAY "Vehículos Vendidos"	TO c400   ## Botón 4  vehp303
DISPLAY "Modelos"         	TO c500   ## Botón 5  vehp305
DISPLAY "Series"    		TO c600   ## Botón 6  vehp306
DISPLAY "Reservaciones"       	TO c700   ## Botón 7  vehp307
DISPLAY "Pedidos"        	TO c800   ## Botón 8  vehp308
DISPLAY "Liquidaciones"        	TO c900   ## Botón 9  vehp309
DISPLAY "Det. Transacciones"   	TO c1000  ## Botón 10 vehp310

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp300 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp301 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp302 ', vg_base, ' ', 'VE', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp303 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp305 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp306 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp307 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp308 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp309 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp310 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_vehiculos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_veh()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000		char(30)
DEFINE c1100		char(30)
DEFINE c1200		char(30)
DEFINE c1300		char(30)
DEFINE c1400		char(30)
DEFINE c1500		char(30)
DEFINE c1600		char(30)
DEFINE c1700		char(30)
DEFINE c1800		char(30)
DEFINE c1900		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf107 FROM '../forms/menf107'
DISPLAY FORM f_menf107
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Ventas/Devoluciones"	TO c100   ## Botón 1
DISPLAY "Transacciones"     	TO c200   ## Botón 2
DISPLAY "Existencias"     	TO c300   ## Botón 3
DISPLAY "Precios"      		TO c400   ## Botón 4
DISPLAY "Proformas"       	TO c500   ## Botón 5
DISPLAY "Facturación"  		TO c600   ## Botón 6
DISPLAY "Nota de Entrega"  	TO c700   ## Botón 7
DISPLAY "Carta de Venta"  	TO c800   ## Botón 8
DISPLAY "Transferencias"  	TO c900  ## Botón 9
DISPLAY "Ajustes Costo"  	TO c1000  ## Botón 10
DISPLAY "Ajustes Existencia"  	TO c1100  ## Botón 11
DISPLAY "Compra Local"  	TO c1200  ## Botón 12
DISPLAY "Importación"  		TO c1300  ## Botón 13
DISPLAY "Devolución Facturas"  	TO c1400  ## Botón 14
DISPLAY "Reservaciones"  	TO c1500  ## Botón 15
DISPLAY "Pedidos"  		TO c1600  ## Botón 16
DISPLAY "Recepción Pedidos"  	TO c1700  ## Botón 17
DISPLAY "Liquidaciones"  	TO c1800  ## Botón 18
DISPLAY "Orden de Chequeo"  	TO c1900  ## Botón 19

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp400 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp401 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp402 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp403 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp404 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp405 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp406 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp407 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp408 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp409 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp410 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp411 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp412 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp413 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp414 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp415 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 17
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp416 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 18
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp417 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 19
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS', vg_separador, 'fuentes', vg_separador, '; fglrun vehp418 ', vg_base, ' ', 'VE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_vehiculos()
END CASE

END WHILE
END FUNCTION


------------------------ R E P U E S T O S -----------------------
FUNCTION menu_repuestos()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_repuestos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf110 FROM '../forms/menf110'
DISPLAY FORM f_menf110
--DISPLAY fondo		  TO c000   ## Picture
--DISPLAY "boton_repuestos" TO a      ## Picture 
DISPLAY "boton_invetarios" TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Pedidos"         TO c300   ## Botón
DISPLAY "Consultas"       TO c400   ## Botón
DISPLAY "Reportes"        TO c500   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_repuestos
  		CALL menu_configuracion_rep()
	WHEN 2 
		CLOSE WINDOW w_menu_repuestos
		CALL menu_transacciones_rep()
	WHEN 3 
		CLOSE WINDOW w_menu_repuestos
		CALL menu_pedidos_rep()
	WHEN 4 
		CLOSE WINDOW w_menu_repuestos
		CALL menu_consultas_rep()
	WHEN 5 
		CLOSE WINDOW w_menu_repuestos
		CALL menu_reportes_rep()
	WHEN 0 
		CLOSE WINDOW w_menu_repuestos
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_repuestos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_rep()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE c1200 		char(30)
DEFINE c1300 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf102 FROM '../forms/menf102'
DISPLAY FORM f_menf102
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     	TO c100   ## Botón 1 repp100
DISPLAY "Divisiones" 		TO c200   ## Botón 2 repp101
DISPLAY "Bodegas"       	TO c300   ## Botón 3 repp102
DISPLAY "Líneas"   		TO c400   ## Botón 4 repp103
DISPLAY "Vendedor/Bodeguero"	TO c500   ## Botón 5 repp104
DISPLAY "Grupos"        	TO c600   ## Botón 6 repp105
DISPLAY "Descuentos"     	TO c700   ## Botón 7 repp106
DISPLAY "Clases" 		TO c800   ## Botón 8 repp107
DISPLAY "Codigo Utilidades" 	TO c900   ## Botón 9 repp109
DISPLAY "Marcas"        	TO c1000  ## Botón 10 repp110
DISPLAY "Unidades Medida" 	TO c1100  ## Botón 11 repp111
DISPLAY "Tipos de Items" 	TO c1200  ## Botón 12 repp112
DISPLAY "Indice Rotación" 	TO c1300  ## Botón 13 repp113
DISPLAY "Equivalencias" 	TO c1400  ## Botón 14 repp114
DISPLAY "Colores" 		TO c1500  ## Botón 15 repp115
--DISPLAY "Series"  		TO c1600  ## Botón 16 repp116
DISPLAY "Códigos Eléctricos" 	TO c1600  ## Botón 17 repp117
DISPLAY "Asignar Cod. Util." 	TO c1700  ## Botón 18 repp232
DISPLAY "Tipo Ident. Bodega"	TO c1800  ## Botón 19 repp118
	DISPLAY "Zonas"			TO c1900
	DISPLAY "Sub-Zonas"		TO c2000
	DISPLAY "Transporte"		TO c2100
	DISPLAY "Choferes"		TO c2200
	DISPLAY "Observación"		TO c2300
	DISPLAY "Ayudantes"		TO c2400
	DISPLAY "Empresa Entregas"	TO c2500


LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp100 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp103 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp102 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp110')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp110 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp101 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp111')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp111 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp107')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp107 ', vg_base, ' ',
'RE', vg_codcia              
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp112')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp112 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp117')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp117 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp113')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp113 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp105')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp105 ', vg_base, ' ', 'RE'
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp106')
		THEN
			EXIT CASE
		END IF
	 	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp106 ', vg_base, ' ', 'RE'
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp104 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp109')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp109 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 15
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp115')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp115 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	{--
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp116 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	--}
	WHEN 16
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp114')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp114 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 17
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp232')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp232 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 18
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp118')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp118 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
		WHEN 19
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp119')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp119 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 20
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp120')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp120 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 21
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp121')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp121 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 22
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp122')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp122 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 23
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp123')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp123 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 24
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp124')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp124 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 25
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp125')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp125 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_repuestos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_rep()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE c1200 		char(30)
DEFINE c1300 		char(30)
DEFINE c1400 		char(30)
DEFINE c1500 		char(30)
DEFINE c1600 		char(30)
DEFINE c1700 		char(30)
DEFINE c1800 		char(30)
DEFINE c1900 		char(35)
DEFINE c2000 		char(30)
DEFINE c2100 		char(30)
DEFINE c2200 		char(30)
DEFINE c2300 		char(30)
DEFINE c2400 		char(30)
DEFINE c2500 		char(30)
DEFINE c		CHAR(1)
DEFINE programa		CHAR(7)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf108 FROM '../forms/menf108'
DISPLAY FORM f_menf108
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Proformas"    		TO c100   ## Botón 1  repp220
DISPLAY "Compra Local"     	TO c200   ## Botón 2  repp214
DISPLAY "Transferencias"        TO c300   ## Botón 3  repp216
DISPLAY "Transf. para Fact."	TO c400   ## Botón 4  repp251
--DISPLAY "Pre-Ventas"		TO c400   ## Botón 4  repp209
--DISPLAY "Composicion Item"	TO c400   ## Boton 4 repp248
DISPLAY "Dev. Compra Local"	TO c500   ## Botón 5  repp218
DISPLAY "Items"          	TO c600   ## Botón 6  repp108
DISPLAY "Aprobación Pre-Venta" 	TO c700   ## Botón 7  repp223
DISPLAY "Manejo Especial Items"	TO c800
--DISPLAY "Reclasificación Item" 	TO c900   ## Botón 9  repp224
DISPLAY "Aprobación Crédito"  	TO c1000  ## Botón 9 repp210
--DISPLAY "Mantenimiento Precio" 	TO c1100  ## Botón 10 repp221
DISPLAY "Cambio de Precios" 	TO c1100  ## Botón 10  repp235
DISPLAY "Ajustes Existencias"  	TO c1200  ## Botón 11 repp212
DISPLAY "Devolución Facturas"  	TO c1300  ## Botón 12 repp217
DISPLAY "Ajustes Costos"  	TO c1400  ## Botón 13 repp213
--DISPLAY "Substituciones"	TO c1500  ## Botón 15 repp200
DISPLAY "Ordenes de Despacho" 	TO c1600  ## Botón 14 repp231
--DISPLAY "Ventas Perdidas" 	TO c1700  ## Botón 17 repp201
DISPLAY "Cierre Mensual" 	TO c1800  ## Botón 15 repp229
DISPLAY "Precios Manuales" 	TO c1900  ## Botón 16 repp234
DISPLAY "Transmisión Transf." 	TO c2000  ## Botón 17 repp666
DISPLAY "Reversar Cambio Prec." TO c2100  ## Botón 18 repp236
--DISPLAY "Inventario Fis. 2003"  TO c2200  ## Botón 19 repp238
DISPLAY "Refacturación"         TO c2200  ## Botón 20 repp237
DISPLAY "Inventario Físico"     TO c2300  ## Botón 21 repp239 y repp250
DISPLAY "Pedido Prov. Locales"  TO c2400  ## Botón 22 repp240
DISPLAY "Tr. Bodega Carcelen"  TO c2500  ## Botón 23 repp667
--DISPLAY "Guías de Remisión"     TO c2600  ## Botón 24 repp241
DISPLAY "Logística"             TO c2600  ## Botón 24 repp241
DISPLAY "Cambiar Vendedor"      TO c2700  ## Botón 25 repp242
DISPLAY "Corrección GR SRI"     TO c2800  ## Botón 26 repp243
DISPLAY "Priorizacion Entreg."  TO c2900  ## Boton 27 repp244
DISPLAY "Tansf. Bodega Cont."   TO c3000  ## Boton 28 repp245
DISPLAY "Tansf. Especiales"   TO c3000  ## Boton 28 repp245

--DISPLAY "Tansf. Bodega Cont."   TO c3000  ## Boton 28 repp245

--DISPLAY "Generar Inventario"	TO c1500  ## Botón 15 repp225
--DISPLAY "Ventas al Taller"	TO c1600  ## Botón 16 repp215
--DISPLAY "Conteo Inventario"	TO c1800  ## Botón 18 repp226
--DISPLAY "Dev. Ventas Taller"	TO c1900  ## Botón 19 repp219
--DISPLAY "Cierre Inventario"	TO c2100  ## Botón 21 repp227
--DISPLAY "Actualización V.P." 	TO c2300  ## Botón 23 repp202


LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp220')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp220 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp214')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp214 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp216')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp216 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp251')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp251 ', vg_base, ' ',
'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp218')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp218 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp108')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp108 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp223')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp223 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		CLOSE WINDOW w_menu_transacciones
		CALL menu_composicion_items()
	{--
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp224 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp210 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp221 ', vg_base, ' ',
'RE', vg_codcia
		RUN ejecuta
	--}
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp235')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp235 ', vg_base, ' ',
'RE', vg_codcia
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp212')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp212 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp217')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp217 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp213')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp213 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp200 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	--}
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp231')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp231 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 17
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp201 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 15
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp229')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp229 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 16
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp234')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp234 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 17
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp666')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp666 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 18
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp236')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp236 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	{--
	WHEN 19
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp238')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp238 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	--}
	WHEN 19
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp237')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp237 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 20
		OPEN WINDOW w_tn2 AT 17, 16 WITH 1 ROWS, 51 COLUMNS
			ATTRIBUTE(BORDER)
		WHILE TRUE
			PROMPT 'Inventario Físico: (I) Por Item, (B) Por Bodega: ' FOR CHAR c
			IF c = 'I' OR c = 'B' OR c = 'i' OR c = 'b' THEN
				EXIT WHILE
			END IF
		END WHILE
		--CALL fgl_keysetlabel('RETURN','')
		IF c = 'I' OR c = 'i' THEN
			LET programa = 'repp239'
		ELSE
			LET programa = 'repp250'
		END IF
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', programa)
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ', programa, ' ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 21
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp240')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp240 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 22
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp667')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp667 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 23
		CLOSE WINDOW w_menu_transacciones
		CALL menu_logistica()
	{--
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp241')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp241 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	--}
	WHEN 24
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp242')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp242 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 25
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp243')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp243 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 26
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp244')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp244 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 3014
		CLOSE WINDOW w_menu_transacciones
		CALL menu_transferencias()
		{--
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp245')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp245 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
		--}
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_repuestos()
END CASE
	{--
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp225 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp215 ', vg_base, ' ',
'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 18
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp226 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 19
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp219 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 21
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp227 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 23
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp202 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
END WHILE

END FUNCTION



FUNCTION menu_composicion_items()
DEFINE d		SMALLINT

WHILE TRUE
	OPEN WINDOW w_menu_composicion_items AT 3,2 WITH 22 ROWS, 80 COLUMNS
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
				BORDER, MESSAGE LINE LAST - 2)
	OPEN FORM f_menf165 FROM '../forms/menf165'
	DISPLAY FORM f_menf165
	DISPLAY "boton_transaciones"	TO a
	DISPLAY "Cambio de Código"	TO c100
	DISPLAY "Composición Items"	TO c200
	DISPLAY "Carga Composición"	TO c300
	LET d = fgl_getkey()
	CASE d
		WHEN 1
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp247')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp247 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 2
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp248')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp248 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 3
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp249')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp249 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 0
			CLOSE WINDOW w_menu_composicion_items
			CALL menu_transacciones_rep()
	END CASE
END WHILE

END FUNCTION



FUNCTION menu_logistica()
DEFINE d		SMALLINT

WHILE TRUE
	OPEN WINDOW w_menu_logistica AT 3,2 WITH 22 ROWS, 80 COLUMNS
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
				BORDER, MESSAGE LINE LAST - 2)
	OPEN FORM f_menf166 FROM '../forms/menf166'
	DISPLAY FORM f_menf166
	DISPLAY "boton_transaciones"	TO a
	DISPLAY "Guías de Remisión"	TO c100
	DISPLAY "Control de Ruta"	TO c200
	DISPLAY "Consulta Cont. Ruta"	TO c300
	LET d = fgl_getkey()
	CASE d
		WHEN 1
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp241')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp241 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 2
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp252')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp252 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 3
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp327')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp327 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 0
			CLOSE WINDOW w_menu_logistica
			CALL menu_transacciones_rep()
	END CASE
END WHILE

END FUNCTION



FUNCTION menu_transferencias()
DEFINE d		SMALLINT

WHILE TRUE
	OPEN WINDOW w_menu_transf AT 3,2 WITH 22 ROWS, 80 COLUMNS
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
				BORDER, MESSAGE LINE LAST - 2)
	OPEN FORM f_menf167 FROM '../forms/menf167'
	DISPLAY FORM f_menf167
	DISPLAY "boton_transaciones"	TO a
	DISPLAY "Tansf. Bodega Cont."   TO c100
	DISPLAY "Tansf. Bodega C.P."    TO c200
	LET d = fgl_getkey()
	CASE d
		WHEN 1
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp245')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp245 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 2
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
								vg_codcia,
								'RE', 'repp253')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp253 ', vg_base, ' "RE" ', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 0
			CLOSE WINDOW w_menu_transf
			CALL menu_transacciones_rep()
	END CASE
END WHILE

END FUNCTION



FUNCTION menu_pedidos_rep()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE e		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_pedidos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf109 FROM '../forms/menf109'
DISPLAY FORM f_menf109
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_pedidos"	        TO a      ## Picture 
DISPLAY "Pedidos Sugeridos"    	TO c100   ## Botón 1 repp203
DISPLAY "Items"			TO c200   ## Boton  8 repp246
DISPLAY "Mantenimiento"  	TO c300   ## Botón 2 repp204
DISPLAY "Nota de Pedido"  	TO c400   ## Botón 3 repp233
DISPLAY "Confirmación Pedidos" 	TO c500   ## Botón 4 repp205
DISPLAY "Recepción Pedidos" 	TO c600   ## Botón 5 repp206
DISPLAY "Liquidación Pedidos" 	TO c700   ## Botón 6 repp207
DISPLAY "Cierre Pedidos" 	TO c800   ## Botón 7 repp208

LET e = fgl_getkey()

CASE e
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp203')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp203 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp246')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp246 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp204 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp233')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp233 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp205')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp205 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp206 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp207')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp207 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp208 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_pedidos
		CALL menu_repuestos()
END CASE
END WHILE

END FUNCTION



FUNCTION menu_consultas_rep()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE c1200 		char(30)
DEFINE c1300 		char(30)
DEFINE c1400 		char(30)
DEFINE c		CHAR(1)
DEFINE programa		CHAR(7)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf112 FROM '../forms/menf112'
DISPLAY FORM f_menf112
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	 TO a      ## Picture 
DISPLAY "Proformas" 	 	 TO c100   ## Botón 1 repp300
DISPLAY "Items"         	 TO c200   ## Botón 2 repp301
DISPLAY "Estadística Facturas"	 TO c300   ## Botón 3 repp302
DISPLAY "Kardex de Items" 	 TO c400   ## Botón 4 repp303
DISPLAY "Utilidad Facturas"      TO c500   ## Botón 5 repp306
DISPLAY "Det. Transacciones"     TO c600   ## Botón 6 repp309
DISPLAY "Estadística Vendedor"   TO c700   ## Botón 7 repp304
DISPLAY "Ordenes de Despacho"    TO c800   ## Botón 8 repp305
DISPLAY "Ventas por Cliente"     TO c900   ## Botón 9 repp310
DISPLAY "Pedidos Backorder"      TO c1000  ## Botón 10 repp309
DISPLAY "Análisis Ventas Items"  TO c1100  ## Botón 11 repp311
DISPLAY "Liquidaciones Import."  TO c1200  ## Botón 12 repp312
DISPLAY "Stock sin Ventas"       TO c1300  ## Botón 13 repp313
DISPLAY "Proformas por Hora"     TO c1400  ## Botón 14 repp315
DISPLAY "Inventario Físico"      TO c1500  ## Botón 15 repp317 y repp325
DISPLAY "Items Pendientes"       TO c1600  ## Botón 16 repp318
DISPLAY "Transferencias"         TO c1700  ## Botón 17 repp319
DISPLAY "Refacturación"          TO c1800  ## Botón 18 repp320
DISPLAY "Guías de Remisión"      TO c1900  ## Botón 19 repp321
DISPLAY "Ventas por Transacc."   TO c2000  ## Boton 21 repp322
DISPLAY "Ventas Items Compues."  TO c2100  ## Boton 22 repp323
DISPLAY "Items Compuestos"       TO c2200  ## Boton 23 repp324
DISPLAY "Facturas Comisión"      TO c2300  ## Boton 24 repp326

LET g = fgl_getkey()
CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp306')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun repp306 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp300 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp305')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp305 ', vg_base, ' ',
'RE', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp307')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp307 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp301')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp301 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp309')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp309 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp304')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp304 ', vg_base, ' ',
'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp313')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp313 ', vg_base, ' ',
'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp312')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp312 ', vg_base, ' ',
'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp302')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp302 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp310')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp310 ', vg_base, ' ',
'RE', vg_codcia
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp303')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp303 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp311')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp311 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp315')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp315 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 15
		OPEN WINDOW w_tn3 AT 09, 26 WITH 1 ROWS, 51 COLUMNS
			ATTRIBUTE(BORDER)
		WHILE TRUE
			PROMPT 'Inventario Físico: (I) Por Item, (B) Por Bodega: ' FOR CHAR c
			IF c = 'I' OR c = 'B' OR c = 'i' OR c = 'b' THEN
				EXIT WHILE
			END IF
		END WHILE
		--CALL fgl_keysetlabel('RETURN','')
		IF c = 'I' OR c = 'i' THEN
			LET programa = 'repp317'
		ELSE
			LET programa = 'repp325'
		END IF
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', programa)
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ', programa CLIPPED, ' ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 16
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp318')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp318 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 17
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp319')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp319 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 18
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp320')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp320 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 19
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp321')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp321 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 20
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp322')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp322 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 21
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp323')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp323 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 22
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp324')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp324 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 23
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp326')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun repp326 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_repuestos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_rep()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000		char(30)
DEFINE c1100		char(30)
DEFINE c1200		char(30)
DEFINE c1300		char(30)
DEFINE c1400		char(30)
DEFINE c1500		char(30)
DEFINE c1600		char(30)
DEFINE c1700		char(30)
DEFINE c1800		char(30)
DEFINE c1900		char(30)
DEFINE c2000		char(30)
DEFINE c2100		char(30)
DEFINE c2200		char(30)
DEFINE c2300		char(30)
DEFINE c2400		char(30)
DEFINE c2500		char(30)
DEFINE c2600		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf113 FROM '../forms/menf113'
DISPLAY FORM f_menf113
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
--DISPLAY "Proformas"             TO c100   ## Botón 1 repp400
DISPLAY "Nota de Pedido"    	TO c100   ## Botón 1 repp401
DISPLAY "Existencias"   	TO c200   ## Botón 2 repp402
DISPLAY "Facturas/Devolución"	TO c300   ## Botón 3 repp403
--DISPLAY "Comprob. Importación" 	TO c500   ## Botón 5 repp404
--DISPLAY "Movimientos de Items" 	TO c600   ## Botón 6 repp405
--DISPLAY "Resumen de Ventas"  	        TO c700   ## Botón 7 repp406
DISPLAY "Impresión Recepción"	TO c400   ## Botón 4 repp407
DISPLAY "Ubicación de Items"    TO c500   ## Botón 5 repp408
DISPLAY "Transacciones" 	TO c600   ## Botón 6 repp409
--DISPLAY "Liquidación" 	 	TO c700   ## Botón 7 repp419
--DISPLAY "Control Inv. Físico" 	TO c1200  ## Botón 12 repp420
DISPLAY "Margenes de Utilidad" 	TO c800   ## Botón 8 repp421
--DISPLAY "Pedido Sugerido"  	TO c1400  ## Botón 14 repp425
--DISPLAY "Resumen Inventario"  	TO c1500  ## Botón 15 repp423
DISPLAY "Lista de Precios"      TO c900   ## Botón 9 repp430
DISPLAY "Pedido Emergencia" 	TO c1000  ## Botón 10 repp426
DISPLAY "Guías de Remisión" 	TO c1100  ## Botón 10 repp435
--DISPLAY "Diferencias"      	TO c1800  ## Botón 18 repp427

LET h = fgl_getkey()

CASE h
	{--
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp419 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	--}
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp426')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp426 ', vg_base, ' ',
'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp403')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp403 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp400 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	{--
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp409 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp421 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp401 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	--}
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp407')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp407 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp427')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp427 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp430')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp430 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp408 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp425 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp420')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp420 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp405 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp402 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp404')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp404 ', vg_base, ' ',
'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 9 
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp406')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp406 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10 
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp435')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp435 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	{--
	WHEN 18
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp423 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_repuestos()
END CASE

END WHILE
END FUNCTION

------------------------ T A L L E R E S  -----------------------
FUNCTION menu_talleres()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_talleres AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf114 FROM '../forms/menf114'
DISPLAY FORM f_menf114
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_talleres"  TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_talleres
    		CALL menu_configuracion_tal()
	WHEN 2 
		CLOSE WINDOW w_menu_talleres
		CALL menu_transacciones_tal()
	WHEN 3 
		CLOSE WINDOW w_menu_talleres
		CALL menu_consultas_tal()
	WHEN 4 
		CLOSE WINDOW w_menu_talleres
		CALL menu_reportes_tal()
	WHEN 0 
		CLOSE WINDOW w_menu_talleres
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_talleres()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_tal()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf115 FROM '../forms/menf115'
DISPLAY FORM f_menf115
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     	TO c100   ## Botón 1 talp100
DISPLAY "Marcas" 		TO c200   ## Botón 2 talp101
DISPLAY "Secciones"       	TO c300   ## Botón 2 talp102
DISPLAY "Técnicos"   		TO c400   ## Botón 3 talp103
DISPLAY "Modelos"		TO c500   ## Botón 5 talp104
DISPLAY "Tipos O. Trabajo"     	TO c600   ## Botón 4 talp105
DISPLAY "Subtipos O. Trabajo" 	TO c700   ## Botón 5 talp106
DISPLAY "Tareas" 		TO c800   ## Botón 6 talp107

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp100 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp101 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp102 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp103 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp104 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp105')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp105 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp106')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp106 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp107')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp107 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_talleres()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_tal()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf116 FROM '../forms/menf116'
DISPLAY FORM f_menf116
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Presupuestos"     	TO c100   ## Botón 1
DISPLAY "Tareas / Presupuesto"  TO c200   ## Botón 2
DISPLAY "Proformas"             TO c300   ## Botón 3
DISPLAY "Ordenes de Trabajo" 	TO c400   ## Botón 4
DISPLAY "Gastos de viaje" 	TO c500   ## Botón 5
DISPLAY "Tareas / O. Trabajo"  	TO c600   ## Botón 6
DISPLAY "Cierre O. Trabajo"  	TO c700   ## Botón 7
DISPLAY "Reapertura O. Trabajo"	TO c800   ## Botón 8
DISPLAY "Forma de Pago"  	TO c900   ## Botón 9
DISPLAY "Anulación Facturas"	TO c1000  ## Botón 10 
DISPLAY "Refacturación"		TO c1100  ## Botón 11 
DISPLAY "Elimin. Ord. Trabajo"  TO c1200  ## Boton 12
DISPLAY "Cierre Mensual"	TO c1300
DISPLAY "Reg. Tec. Equipos"	TO c1400

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp201')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp201 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp202 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp213')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp213 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp212')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp212 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp205')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp205 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp206 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp207')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp207 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp208 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp211')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp211 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp214')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp214 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp215')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp215 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp216')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp216 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp217')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp217 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_talleres()
END CASE

END WHILE
END FUNCTION


FUNCTION menu_consultas_tal()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf118 FROM '../forms/menf118'
DISPLAY FORM f_menf118
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Ordenes de Trabajo"	TO c100   ## Botón 1 talp300
DISPLAY "Estadística Facturas"  TO c200   ## Botón 3 talp310
DISPLAY "Técnicos / Asesores"   TO c300   ## Botón 4 talp311
DISPLAY "Refacturación" 	TO c400   ## Botón 5 talp312
DISPLAY "Transacciones" 	TO c500   ## Botón 6 talp309
DISPLAY "Ventas por Cliente" 	TO c600   ## Botón 7 talp313

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp300 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp310')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp310 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp311')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp311 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp312')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp312 ', vg_base, ' ', 'TA', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp309')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp309 ', vg_base, ' ', 'TA', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp313')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp313 ', vg_base, ' ', 'TA', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_talleres()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_tal()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf119 FROM '../forms/menf119'
DISPLAY FORM f_menf119
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Facturación"		TO c100   ## Botón 1 talp400
--DISPLAY "Presupuestos"    	TO c200   ## Botón 2 talp401
DISPLAY "Gastos por O.T."  	TO c300   ## Botón 3 talp405

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp400 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp401 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TA', 'talp405')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp405 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_talleres()
END CASE

END WHILE
END FUNCTION


------------------------ C O B R A N Z A S  -----------------------
FUNCTION menu_cobranzas()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_cobranzas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf120 FROM '../forms/menf120'
DISPLAY FORM f_menf120
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_cobranzas" TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_cobranzas
    		CALL menu_configuracion_cob()
	WHEN 2 
		CLOSE WINDOW w_menu_cobranzas
		CALL menu_transacciones_cob()
	WHEN 3 
		CLOSE WINDOW w_menu_cobranzas
		CALL menu_consultas_cob()
	WHEN 4 
		CLOSE WINDOW w_menu_cobranzas
		CALL menu_reportes_cob()
	WHEN 0 
		CLOSE WINDOW w_menu_cobranzas
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_cobranzas()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_cob()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf121 FROM '../forms/menf121'
DISPLAY FORM f_menf121
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     	TO c100   ## Botón 1 cxcp100
DISPLAY "Clientes Cia. / Loc." 	TO c200   ## Botón 2 cxcp101
DISPLAY "Doc. / Transacciones"  TO c300   ## Botón 3 cxcp102
DISPLAY "Ejecutivos Cuentas"   	TO c400   ## Botón 4 cxcp103
DISPLAY "Zonas de Cobro"  	TO c500   ## Botón 5 cxcp104
DISPLAY "Plazos Créditos"     	TO c600   ## Botón 6 cxcp105

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp100 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp101 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp102 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp103 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp104 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp105')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp105 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_cobranzas()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_cob()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf122 FROM '../forms/menf122'
DISPLAY FORM f_menf122
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Documentos Deudores"  	TO c100   ## Botón 1 cxcp200
DISPLAY "Documentos a Favor"   	TO c200   ## Botón 2 cxcp201
DISPLAY "Ingreso Ajustes"     	TO c300   ## Botón 3 cxcp202
DISPLAY "Aplicación NC / PA" 	TO c400   ## Botón 4 cxcp203
DISPLAY "Autorización Cobro"    TO c500   ## Botón 5 cxcp204
DISPLAY "Autorización P.A."     TO c600   ## Botón 6 cxcp205
DISPLAY "Cheques Postfechados"  TO c700   ## Botón 7 cxcp206
DISPLAY "Cheques Protestados"   TO c800   ## Botón 8 cxcp207
DISPLAY "Cierre Mensual"	   	TO c900   ## Botón 9 cxcp208
DISPLAY "Correccion SRI N/D"   	TO c1000  ## Botón 10 cxcp209
DISPLAY "Correccion SRI N/C"   	TO c1100  ## Botón 11 cxcp210
DISPLAY "Digitación Retención"  TO c1200  ## Botón 12 cxcp211
DISPLAY "Eli. Retenciones Cli"  TO c1300  ## Boton 13 cxcp212

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp200 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp201')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp201 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp202 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp203')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp203 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp204 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp205')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp205 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp206 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp207')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp207 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp208 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp209')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp209 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp210 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp211')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp211 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp212')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp212 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_cobranzas()
END CASE

END WHILE

END FUNCTION



FUNCTION menu_consultas_cob()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE c1200 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf123 FROM '../forms/menf123'
DISPLAY FORM f_menf123
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Cheques Postfechados" 	TO c100   ## Botón 1  cxcp303
DISPLAY "Cheques Protestados"   TO c200   ## Botón 2  cxcp304
DISPLAY "Estado de Cuentas"     TO c300   ## Botón 3  cxcp305
DISPLAY "Anl. Cartera Cliente"  TO c400   ## Botón 4  cxcp306
DISPLAY "Anl. Cartera Detalle" 	TO c500   ## Botón 5  cxcp307
DISPLAY "Acumulados Cartera" 	TO c600   ## Botón 6  cxcp308
DISPLAY "Anl. Cobrar vs Pagar" 	TO c700   ## Botón 7  cxcp309
DISPLAY "Valores a Favor" 	TO c800   ## Botón 8  cxcp300
DISPLAY "Cartera Cli. x Fecha"  TO c900   ## Botón 9  cxcp310
DISPLAY "Cartera por Edades"    TO c1000  ## Botón 10 cxcp311
DISPLAY "Saldos de Cartera"     TO c1100  ## Botón 11 cxcp312
DISPLAY "Aprobación Crédito"    TO c1200  ## Botón 12 cxcp313
DISPLAY "Estado Cuenta Fecha"	TO c1300  ## Botón 13 cxcp314
DISPLAY "Cartera Det. Fecha"	TO c1400  ## Botón 14 cxcp315
DISPLAY "Venta vs. Cobranza"	TO c1500  ## Botón 15 cxcp316
DISPLAY "Retenciones Cli."	TO c1600  ## Botón 16 cxcp317

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp303')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp303 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp304')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp304 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp305')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp305 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp306')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp306 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp307')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp307 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp308')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp308 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp309')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp309 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp300 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp310')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp310 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp311')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp311 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp312')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp312 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp313')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp313 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp314')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp314 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp315')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp315 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 15
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp316')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp316 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 16
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp317')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp317 ', vg_base, ' ', 'CO', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_cobranzas()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_cob()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf124 FROM '../forms/menf124'
DISPLAY FORM f_menf124
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Detalle Cartera"       TO c100   ## Botón 1  cxcp400
DISPLAY "Resúmen Cartera"       TO c200   ## Botón 2  cxcp401
DISPLAY "List. Transacciones"   TO c300   ## Botón 3  cxcp413
DISPLAY "Cheques Postfechados"  TO c400   ## Botón 4  cxcp408
DISPLAY "Estado de Cuentas"     TO c500   ## Botón 5  cxcp409
DISPLAY "Cheques Protestados"   TO c600   ## Botón 6  cxcp410
DISPLAY "List. Retenciones"     TO c700   ## Botón 7  cxcp416
DISPLAY "Documentos a Favor"    TO c800   ## Botón 8  cxcp411
DISPLAY "Documentos Deudores"   TO c900   ## Botón 9  cxcp412
DISPLAY "Cobranza Realizada"    TO c1000  ## Botón 10 cxcp417
DISPLAY "Facturas Crédito"      TO c1100  ## Botón 11 cxcp418
DISPLAY "Facturas Comisión"     TO c1200  ## Botón 11 cxcp419

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp400 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc, ' > $HOME/tmp/cxcp400.txt'
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp401')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp401 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp413')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp413 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc, ' > $HOME/tmp/cxcp413.txt'
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp408')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp408 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp409')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp409 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp410')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp410 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp416')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp416 ', vg_base, ' ', 'CO', vg_codcia, ' ', vg_codloc, ' > $HOME/tmp/cxcp416.txt'
	 	RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp411')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp411 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	 	RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp412')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp412 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	 	RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp417')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp417 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	 	RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp418')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp418 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	 	RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp419')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxcp419 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	 	RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_cobranzas()
END CASE

END WHILE

END FUNCTION



------------------------ T E S O R E R I A  -----------------------
FUNCTION menu_tesoreria()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_tesoreria AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf125 FROM '../forms/menf125'
DISPLAY FORM f_menf125
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_tesoreria" TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_tesoreria
    		CALL menu_configuracion_tes()
	WHEN 2 
		CLOSE WINDOW w_menu_tesoreria
		CALL menu_transacciones_tes()
	WHEN 3 
		CLOSE WINDOW w_menu_tesoreria
		CALL menu_consultas_tes()
	WHEN 4 
		CLOSE WINDOW w_menu_tesoreria
		CALL menu_reportes_tes()
	WHEN 0 
		CLOSE WINDOW w_menu_tesoreria
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_tesoreria()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_tes()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf126 FROM '../forms/menf126'
DISPLAY FORM f_menf126
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     	TO c100   ## Botón 1 cxpp100
DISPLAY "Proveedores Cía/Loc" 	TO c200   ## Botón 2 cxpp101
DISPLAY "Doc./Transacciones"    TO c300   ## Botón 3 cxpp102
DISPLAY "Porcentaje Retención" TO c400   ## Botón 3 ordp102
DISPLAY "Lista Precios Prov." TO c500   ## Botón 4 ordp103

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp100 ', vg_base, ' ', 'TE', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp101 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp102 ', vg_base, ' ', 'TE', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp102 ', vg_base, ' ', 'OC', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp103 ', vg_base, ' ', 'OC', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_tesoreria()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_tes()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1001 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf127 FROM '../forms/menf127'
DISPLAY FORM f_menf127
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Documentos Deudores"  	TO c100   ## Botón 1 cxpp200
DISPLAY "Documentos a Favor"   	TO c200   ## Botón 2 cxpp201
DISPLAY "Ingreso Ajustes"     	TO c300   ## Botón 3 cxpp202
DISPLAY "Aplicación NC / PA" 	TO c400   ## Botón 4 cxpp203
DISPLAY "Aut. Pago Facturas"    TO c500   ## Botón 5 cxpp204
DISPLAY "Aut. Pago Anticipado"  TO c600   ## Botón 6 cxpp205
DISPLAY "Cheques Orden Pago"    TO c700   ## Botón 7 cxpp206
DISPLAY "Digitación Retención"  TO c800   ## Botón 8 cxpp207
DISPLAY "Cierre Mensual"        TO c900   ## Botón 9 cxpp208
DISPLAY "Corrección Ret. SRI"   TO c1000  ## Botón 10 cxpp209
DISPLAY "Ingreso de Facturas"   TO c1100  ## Botón 11 cxpp210
DISPLAY "Correccion Facturas"   TO c1200

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp200 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp201')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp201 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp202 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp203')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp203 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp204 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp205')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp205 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp206 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp207')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp207 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp208 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp209')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp209 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp210 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp211')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp211 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_tesoreria()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_consultas_tes()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf128 FROM '../forms/menf128'
DISPLAY FORM f_menf128
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Estado Cuentas Prov." 	TO c100   ## Botón 1  cxpp300
DISPLAY "Anl. Cartera Prov." 	TO c200   ## Botón 2  cxpp301
DISPLAY "Anl. Detalle Cartera"	TO c300   ## Botón 3  cxpp302
DISPLAY "Acumulados Cartera"    TO c400   ## Botón 4  cxpp303
DISPLAY "Retenciones Prov."     TO c500   ## Botón 5  cxpp304
DISPLAY "Valores a Favor"       TO c600   ## Botón 6  cxpp305
DISPLAY "Cartera Prov x Fecha"  TO c700   ## Botón 7  cxpp310
DISPLAY "Cartera por Edades"    TO c800   ## Botón 8  cxpp311
--DISPLAY "Saldos de Cartera"     TO c900   ## Botón 9  cxpp312
DISPLAY "Estado Cuenta Fecha"	TO c900   ## Botón 10 cxpp314
DISPLAY "Cartera Det. Fecha"	TO c1000  ## Botón 11 cxpp315

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp300 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp301')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp301 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp302')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp302 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp303')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp303 ', vg_base, ' ', 'TE', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp304')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp304 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp305')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp305 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp310')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp310 ', vg_base, ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp311')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp311 ', vg_base, ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	{--
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp312')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp312 ', vg_base, ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	--}
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp314')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp314 ', vg_base, ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp315')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp315 ', vg_base, ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_tesoreria()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_tes()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000		char(30)
DEFINE c1100		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf129 FROM '../forms/menf129'
DISPLAY FORM f_menf129
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture

DISPLAY "Detalle Cartera"       TO c100   ## Botón 1 cxpp400
DISPLAY "Resúmen Cartera"       TO c200   ## Botón 2 cxpp401
DISPLAY "List. Transacciones"   TO c300   ## Botón 3 cxpp408
DISPLAY "Estado de Cuentas"     TO c400   ## Botón 4 cxpp407
DISPLAY "Listado Retenciones"   TO c500   ## Botón 5 cxpp410
DISPLAY "Documentos a Favor"    TO c600   ## Botón 6 cxpp411
DISPLAY "Documentos Deudores"   TO c700   ## Botón 7 cxpp412
DISPLAY "Pagos Realizados"      TO c800   ## Botón 8 cxpp413

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp400 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp401')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp401 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp408')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp408 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp407')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp407 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp410')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun cxpp410 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc, ' > cxpp410.txt'
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp411')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp411 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp412')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp412 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp413')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp413 ', vg_base, ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_tesoreria()
END CASE

END WHILE
END FUNCTION



------------------------ C O N T A B I L I D A D  -----------------------
FUNCTION menu_contabilidad()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_contabilidad AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf130 FROM '../forms/menf130'
DISPLAY FORM f_menf130
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_cobranzas" TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_contabilidad
    		CALL menu_configuracion_con()
	WHEN 2 
		CLOSE WINDOW w_menu_contabilidad
		CALL menu_transacciones_con()
	WHEN 3 
		CLOSE WINDOW w_menu_contabilidad
		CALL menu_consultas_con()
	WHEN 4 
		CLOSE WINDOW w_menu_contabilidad
		CALL menu_reportes_con()
	WHEN 0 
		CLOSE WINDOW w_menu_contabilidad
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_cobranzas()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_con()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf131 FROM '../forms/menf131'
DISPLAY FORM f_menf131
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     	TO c100   ## Botón 1 ctbp100
DISPLAY "Niveles Plan Cuentas" 	TO c200   ## Botón 2 ctbp101
DISPLAY "Grupos Cuentas"	TO c300   ## Botón 3 ctbp102
DISPLAY "Tipos Comprobantes"   	TO c400   ## Botón 4 ctbp103
DISPLAY "Subtipos Comprobantes"	TO c500   ## Botón 5 ctbp104
DISPLAY "Tipos Doc. Fuentes"   	TO c600   ## Botón 6 ctbp105
DISPLAY "Mantenimiento Cuentas"	TO c700   ## Botón 7 ctbp106
DISPLAY "Distribución Cuentas"  TO c800   ## Botón 8 ctbp107
DISPLAY "Filtros / Analisis"	TO c900   ## Botón 9 ctbp108
DISPLAY "Conf. Contable Vtas."	TO c1000  ## Boton ctbp210
DISPLAY "Impuestos"             TO c1100  ## Boton genp143

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp100 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp101 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp102 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp103 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp104 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp105')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp105 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp106')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp106 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp107')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp107 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp108')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp108 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp210 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp143')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp143 ', vg_base, ' ', 'GE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_contabilidad()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_con()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf132 FROM '../forms/menf132'
DISPLAY FORM f_menf132
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Bloqueo Meses"   	TO c100   ## Botón 1 ctbp200
DISPLAY "Diarios Contables"   	TO c200   ## Botón 2 ctbp201
DISPLAY "Diarios Periódicos"   	TO c300   ## Botón 3 ctbp202
DISPLAY "Remayorización Mes"	TO c400   ## Botón 4 ctbp204
DISPLAY "Cierre Mensual"	TO c500   ## Botón 5 ctbp206
DISPLAY "Reapertura de Mes" 	TO c600   ## Botón 6 ctbp205
DISPLAY "Gen. D. Periódicos" 	TO c700   ## Botón 7 ctbp208
DISPLAY "Conciliación Banco"  	TO c800   ## Botón 8 ctbp203
DISPLAY "Cierre Anual"		TO c900   ## Botón 9 ctbp209

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp200 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp201')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp201 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp202 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp204 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp206 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp205')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp205 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp208 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp203')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp203 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp209')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp209 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_contabilidad()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_consultas_con()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf133 FROM '../forms/menf133'
DISPLAY FORM f_menf133
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Plan de Cuentas" 	TO c100   ## Botón 1  ctbp301
DISPLAY "Movimientos Cuentas"   TO c200   ## Botón 2  ctbp302
DISPLAY "Balance General"       TO c300   ## Botón 3  ctbp305
DISPLAY "Perdidas y Ganancias"  TO c400   ## Botón 4  ctbp306
DISPLAY "Consulta Genérica" 	TO c500   ## Botón 5  ctbp308
DISPLAY "Anl. Gràfico Cuentas" 	TO c600   ## Botón 6  ctbp307
DISPLAY "Saldos de Bancos" 	TO c700   ## Botón 7  ctbp309
DISPLAY "Balance Comprobacion"  TO c800   ## Botón 8  ctbp310
DISPLAY "Consulta Documentos"   TO c900   ## Boton 9  cxcp318

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp301')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp301 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp302')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp302 ', vg_base, ' ', 'CB', vg_codcia, ' > ctbp302.txt'
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp305')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp305 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp306')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp306 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp308')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp308 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp307')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp307 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp309')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp309 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp310')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp310 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp318')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp318 ', vg_base, ' ', 'CO', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_contabilidad()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_con()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf134 FROM '../forms/menf134'
DISPLAY FORM f_menf134
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Balance Comprobación"  TO c100   ## Botón 1 ctbp401
DISPLAY "Balance General"   	TO c200   ## Botón 2 ctbp402
DISPLAY "Pérdidas y Ganancias" 	TO c300   ## Botón 3 ctbp403
DISPLAY "Plan de Cuentas"  	TO c400   ## Botón 4 ctbp404
DISPLAY "Movimiento de Cuentas"	TO c500   ## Botón 5 ctbp405
--DISPLAY "Control Comprobantes" 	TO c600   ## Botón 6 ctbp406
DISPLAY "Conciliación Banco"	TO c700   ## Botón 7 ctbp408
DISPLAY "Mov. Ctas. x Filtro"   TO c800   ## Botón 8 ctbp409

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp401')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp401 ', vg_base, ' ', 'CB', vg_codcia, ' > $HOME/tmp/ctbp401.txt '
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp402')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp402 ', vg_base, ' ', 'CB', vg_codcia, ' > $HOME/tmp/ctbp402.txt '
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp403')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp403 ', vg_base, ' ', 'CB', vg_codcia, ' > $HOME/tmp/ctbp403.txt '
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp404')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp404 ', vg_base, ' ', 'CB', vg_codcia, ' > $HOME/tmp/ctbp404.txt '
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp405')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp405 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc, ' > $HOME/tmp/ctbp405.txt '
		RUN ejecuta
	{--
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp406 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp408')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp408 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CB', 'ctbp409')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ctbp409 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc, ' > $HOME/tmp/ctbp409.txt '
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_contabilidad()
END CASE

END WHILE
END FUNCTION


------------------------ C O M P R A S  -----------------------
FUNCTION menu_compras()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_compras AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf135 FROM '../forms/menf135'
DISPLAY FORM f_menf135
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_compras"   TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_compras
    		CALL menu_configuracion_com()
	WHEN 2 
		CLOSE WINDOW w_menu_compras
		CALL menu_transacciones_com()
	WHEN 3 
		CLOSE WINDOW w_menu_compras
		CALL menu_consultas_com()
	WHEN 4 
		CLOSE WINDOW w_menu_compras
		CALL menu_reportes_com()
	WHEN 0 
		CLOSE WINDOW w_menu_compras
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_compras()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_com()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf136 FROM '../forms/menf136'
DISPLAY FORM f_menf136
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compañías"     	TO c100   ## Botón 1 ordp100
DISPLAY "Tipos de O. Compras" 	TO c200   ## Botón 2 ordp101

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp100 ', vg_base, ' ', 'OC', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp101 ', vg_base, ' ', 'OC', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_compras()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_com()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf137 FROM '../forms/menf137'
DISPLAY FORM f_menf137
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Ingreso O. Compras"   	TO c100   ## Botón 1 ordp200
DISPLAY "Ingreso de Facturas"   TO c200  ## Botón 11 cxpp210
DISPLAY "Aprobación O. Compras" TO c300   ## Botón 1 ordp201
DISPLAY "Recepción  O. Compras"	TO c400   ## Botón 2 ordp202
DISPLAY "Anulación Recepción"	TO c500   ## Botón 3 ordp204

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp200 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'TE', 'cxpp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp210 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp201')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp201 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp202 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp204 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_compras()
END CASE

END WHILE
END FUNCTION


FUNCTION menu_consultas_com()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf138 FROM '../forms/menf138'
DISPLAY FORM f_menf138
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Consulta O. Compras"   TO c100   ## Botón 1  ordp300
--DISPLAY "Esdísticas de Compras"	TO c200   ## Botón 2  ordp301
DISPLAY "Compras Proveedores"  TO c200   ## Botón 2  ordp302

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp300 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp302')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp302 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_compras()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_com()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf139 FROM '../forms/menf139'
DISPLAY FORM f_menf139
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Impresión O. Compras"	TO c100   ## Botón 1 ordp400
DISPLAY "Detalle O. Compras"  	TO c200   ## Botón 2 ordp401
--DISPLAY "Recepción O. Compras" 	TO c300   ## Botón 3 ordp402

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp400 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'OC', 'ordp401')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun ordp401 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc, ' > ordp401.txt'
		RUN ejecuta
	{--
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp402 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_compras()
END CASE

END WHILE
END FUNCTION



------------------------ C A J A  -----------------------
FUNCTION menu_caja()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_caja AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf140 FROM '../forms/menf140'
DISPLAY FORM f_menf140
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_caja"      TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_caja
    		CALL menu_configuracion_caj()
	WHEN 2 
		CLOSE WINDOW w_menu_caja
		CALL menu_transacciones_caj()
	WHEN 3 
		CLOSE WINDOW w_menu_caja
		CALL menu_consultas_caj()
	WHEN 4 
		CLOSE WINDOW w_menu_caja
		CALL menu_reportes_caj()
	WHEN 0 
		CLOSE WINDOW w_menu_caja
  		CALL funcion_master()
	WHEN 2016 
		CALL menu_caja()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_caj()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf141 FROM '../forms/menf141'
DISPLAY FORM f_menf141
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Parámetros Generales"	TO c100   ## Botón 1 cajp100
DISPLAY "Tipos Formas Pagos" 	TO c200   ## Botón 2 cajp101
DISPLAY "Mantenimiento Cajas"   TO c300   ## Botón 3 cajp102

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp100 ', vg_base, ' ', 'CG', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp101 ', vg_base, ' ', 'CG', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp102 ', vg_base, ' ', 'CG', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_caja()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_caj()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf142 FROM '../forms/menf142'
DISPLAY FORM f_menf142
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Apertura de Caja"   	TO c100   ## Botón 1 cajp200
DISPLAY "Reapertura de Caja" 	TO c200   ## Botón 2 cajp201
DISPLAY "Cierres de Caja"   	TO c300   ## Botón 2 cajp202
DISPLAY "Ingresos de Caja"	TO c400   ## Botón 4 cajp203
DISPLAY "Otros Ingresos"	TO c500   ## Botón 5 cajp206
DISPLAY "Egresos de Caja"	TO c600   ## Botón 6 cajp207
DISPLAY "Eliminación I. Caja"	TO c700   ## Botón 7 cajp208
DISPLAY "Corrección Fact SRI"	TO c800   ## Botón 8 cajp209
DISPLAY "Corrección NV SRI"	TO c900   ## Botón 9 cajp210
DISPLAY "Modific. Ret. Cli."  TO c1000  ## Boton 10 cajp211
DISPLAY "Digitacion Ret. Cli."  TO c1100  ## Boton 11 cxcp211
DISPLAY "Eli. Retenciones Cli"  TO c1200  ## Boton 12 cxcp212

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp200 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp201')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp201 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp202 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp203')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp203 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp206 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp207')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp207 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp208 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp209')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp209 ', vg_base, ' ', 'CG', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp210 ', vg_base, ' ', 'CG', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp211')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp211 ', vg_base, ' ', 'CG', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp211')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp211 ', vg_base, ' ', 'CO', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CO', 'cxcp212')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp212 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_caja()
END CASE

END WHILE
END FUNCTION


FUNCTION menu_consultas_caj()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf143 FROM '../forms/menf143'
DISPLAY FORM f_menf143
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Transacciones Caja"   	TO c100   ## Botón 1  cajp300
DISPLAY "Cierres Caja"   	TO c200   ## Botón 2  cajp301

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp300 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp301')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp301 ', vg_base, ' CG ', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_caja()
END CASE

END WHILE
END FUNCTION


FUNCTION menu_reportes_caj()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf144 FROM '../forms/menf144'
DISPLAY FORM f_menf144
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Valores Recaudados" 	TO c100   ## Botón 2 cajp402
DISPLAY "Egresos de Caja" 	TO c200   ## Botón 3 cajp405

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp402')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp402 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'CG', 'cajp405')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp405 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_caja()
END CASE

END WHILE
END FUNCTION


------------------------ C A J A  C H I C A  -----------------------

FUNCTION menu_caja_chica()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf141 FROM '../forms/menf145'
DISPLAY FORM f_menf141
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Parámetros Generales"	TO c100   ## Botón 1 ccht000
DISPLAY "Configuración" 	TO c200   ## Botón 2 ccht001
DISPLAY "Cuentas Deudoras" 	TO c300   ## Botón 3 ccht003

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CCHICA', vg_separador, 'fuentes', vg_separador, '; fglrun cchp100 ', vg_base, ' ', 'CH', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CCHICA', vg_separador, 'fuentes', vg_separador, '; fglrun cchp101 ', vg_base, ' ', 'CH', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CCHICA', vg_separador, 'fuentes', vg_separador, '; fglrun cchp103 ', vg_base, ' ', 'CH', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL funcion_master()
END CASE

END WHILE
END FUNCTION


------------------------ G E N E R A L E S   -----------------------
FUNCTION menu_configuracion_gen()
DEFINE c100             char(30)
DEFINE c200             char(30)
DEFINE c300             char(30)
DEFINE c400             char(30)
DEFINE c500             char(30)
DEFINE c600             char(30)
DEFINE c700             char(30)
DEFINE c800             char(30)
DEFINE c900             char(30)
DEFINE c1000            char(30)
DEFINE c1100            char(30)
DEFINE c1200            char(30)
DEFINE c1300            char(30)
DEFINE c1400            char(30)
DEFINE c1500            char(30)
DEFINE c1600            char(30)
DEFINE c1700            char(30)
DEFINE c1800            char(30)
DEFINE c1900            char(30)
DEFINE c2000            char(30)
DEFINE c2100            char(30)
DEFINE c2200            char(30)
DEFINE c2300            char(30)
DEFINE c2400            char(30)
DEFINE c2500            char(30)
DEFINE c2600            char(30)
DEFINE c2700            char(30)
DEFINE c2800            char(30)
DEFINE c2900            char(30)
DEFINE c3000            char(30)
DEFINE c3100            char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf146 FROM '../forms/menf146'
DISPLAY FORM f_menf146
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_generales"	TO a      ## Picture 
DISPLAY "Parámetros Generales"	TO c100   ## Botón 1  genp100
DISPLAY "Compañías"	 	TO c200   ## Botón 2  genp101
DISPLAY "Localidades"		TO c300   ## Botón 3  genp102
DISPLAY "Areas de Negocios" 	TO c400   ## Botón 4  genp103
DISPLAY "Grupos de Usuarios"    TO c500   ## Botón 5  genp104
DISPLAY "Impresoras"    	TO c600   ## Botón 6  genp105
DISPLAY "Bancos Generales"   	TO c700   ## Botón 7  genp106
DISPLAY "Cuentas Corrientes"    TO c800   ## Botón 8  genp107
DISPLAY "Tarjetas Crédito"      TO c900   ## Botón 9  genp108
DISPLAY "Entidades Sistema" 	TO c1000  ## Botón 10 genp109
DISPLAY "Componentes Sistema"   TO c1100  ## Botón 11 genp110
DISPLAY "Monedas"	        TO c1200  ## Botón 12 genp111
DISPLAY "Factores Conversión"   TO c1300  ## Botón 13 genp112
DISPLAY "Control Secuencias" 	TO c1400  ## Botón 14 genp113
DISPLAY "Partida Arancelaria" 	TO c1500  ## Botón 15 genp114
DISPLAY "Rubros Liquidación" 	TO c1600  ## Botón 16 genp115
DISPLAY "Guías de Remisión" 	TO c1700  ## Botón 17 genp116
DISPLAY "Grupos Líneas Ventas" 	TO c1800  ## Botón 18 genp117
DISPLAY "Transacciones/Módulos" TO c1900  ## Botón 19 genp118
DISPLAY "Subtipo Transacción"   TO c2000  ## Botón 20 genp119
DISPLAY "Paises"	        TO c2100  ## Botón 21 genp120
DISPLAY "Ciudades"         	TO c2200  ## Botón 22 genp121
DISPLAY "Zonas de Venta "       TO c2300  ## Botón 23 genp122
DISPLAY "Centros de Costos"     TO c2400  ## Botón 24 genp123
DISPLAY "Departamentos"         TO c2500  ## Botón 25 genp124
DISPLAY "Cargos" 		TO c2600  ## Botón 26 genp125
DISPLAY "Dias Feriados" 	TO c2700  ## Botón 27 genp126
--DISPLAY "Módulos/Bases Datos"   TO c2800  ## Botón 28 genp127
DISPLAY "Procesos por Módulos"  TO c2900  ## Botón 29 genp128
DISPLAY "Usuarios Modulo/Cía"   TO c3000  ## Botón 30 genp129
--DISPLAY "Asignación Procesos"   TO c3100  ## Botón 31 genp130
DISPLAY "Permisos x Usuarios"   TO c3100  ## Botón 31 genp140

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp100 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp101 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp102 ', vg_base, ' ', 'GE ', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp103 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp104 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp105')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp105 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp106')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp106 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp107')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp107 ', vg_base, ' ', 'GE ', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp108')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp108 ', vg_base, ' ', 'GE ', vg_codcia
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp109')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp109 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp110')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp110 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp111')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp111 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp112')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp112 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp113')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp113 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 15
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp114')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp114 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 16
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp115')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp115 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 17
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp116')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp116 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 18
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp117')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp117 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 19
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp118')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp118 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 20
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp119')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp119 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 21
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp120')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp120 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 22
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp121')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp121 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 24
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp122')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp122 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 25
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp123')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp123 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3019
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp124')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp124 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3020
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp125')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp125 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3021
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp126')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp126 ', vg_base, ' ', 'GE'
		RUN ejecuta
	{--
	WHEN 3022
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp127 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	--}
	WHEN 3022
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp128')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp128 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3023
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp129')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp129 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3024
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'GE', 'genp140')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp140 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	{--
	WHEN 3025
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp130 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	--}
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL funcion_master()
END CASE

END WHILE
END FUNCTION



------------------------ A C T I V O S --------------------------
FUNCTION menu_activos_fijos()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_activos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf147 FROM '../forms/menf147'
DISPLAY FORM f_menf147
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_activos"   TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Transacciones"   TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_activos
    		CALL menu_configuracion_act()
	WHEN 2 
		CLOSE WINDOW w_menu_activos
		CALL menu_transacciones_act()
	WHEN 3 
		CLOSE WINDOW w_menu_activos
		CALL menu_consultas_act()
	WHEN 4 
		CLOSE WINDOW w_menu_activos
		CALL menu_reportes_act()
	WHEN 0 
		CLOSE WINDOW w_menu_activos
   		CALL funcion_master()
	WHEN 2016 
		CALL menu_activos_fijos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_act()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf148 FROM '../forms/menf148'
DISPLAY FORM f_menf148
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Parámetros Compañía"	TO c100   ## Botón 1 actp100
DISPLAY "Grupos Activos Fijos" 	TO c200   ## Botón 2 actp101
DISPLAY "Tipos  Activos Fijos"  TO c300   ## Botón 3 actp102
DISPLAY "Responsables Activos"  TO c400   ## Botón 4 actp103
DISPLAY "Mantenimiento Activos"  TO c500   ## Botón 5 actp104
DISPLAY "Distribución Activos"  TO c600   ## Botón 6 actp105
DISPLAY "Tipos Trans. Activos"   TO c700  ## Boton 7 actp106
DISPLAY "Estado Activos Fijos"   TO c800  ## Boton 8 actp107

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp100 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp101 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp102 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp103 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp104 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp105')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp105 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp106')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp106 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp107')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp107 ', vg_base, ' ', 'AF', ' ', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_activos_fijos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_consultas_act()

DEFINE c100 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf149 FROM '../forms/menf149'
DISPLAY FORM f_menf149
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Activos Fijos" 	TO c100   ## Boton 1  actp300
DISPLAY "Movimientos"	 	TO c200   ## Boton 2  actp301
DISPLAY "Transacciones"	 	TO c300   ## Boton 3  actp302
DISPLAY "Depreciaciones" 	TO c400   ## Boton 4  actp303
DISPLAY "Saldo Por Grupo"	TO c500   ## Boton 5  actp304

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp300 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp301')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp301 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp302')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp302 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp303')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp303 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp304')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp304 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_activos_fijos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_act()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf150 FROM '../forms/menf150'
DISPLAY FORM f_menf150
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Transferencias"   	TO c100   ## Botón 1 actp200
DISPLAY "Venta / Baja"   	TO c200   ## Botón 2 actp202
DISPLAY "Cierre Mensual" 	TO c300   ## Botón 3 actp204

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp200 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp202')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp202 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp204 ', vg_base, ' ', 'AF', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_activos_fijos()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_act()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf151 FROM '../forms/menf151'
DISPLAY FORM f_menf151
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Activos Fijos" 	TO c100   ## Botón 2 actp400
DISPLAY "Depreciación Activos" 	TO c200   ## Botón 3 actp401

LET h = fgl_getkey()

CASE h
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; fglrun actp400 ', vg_base, ' ', 'AF', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'AF', 'actp401')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'ACTIVOS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun actp401 ', vg_base, ' ', 'AF', vg_codcia, vg_codloc, ' > $HOME/tmp/actp401.txt '
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_activos_fijos()
END CASE

END WHILE
END FUNCTION

------------------------ N O M I N A -----------------------

FUNCTION menu_nomina()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_nomina AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf152 FROM '../forms/menf152'
DISPLAY FORM f_menf152
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_nomina"    TO a      ## Picture 
DISPLAY "Configuraciones" TO c100   ## Botón
DISPLAY "Procesos"        TO c200   ## Botón
DISPLAY "Consultas"       TO c300   ## Botón
DISPLAY "Reportes"        TO c400   ## Botón

LET b = fgl_getkey()

CASE b
	WHEN 1 
		CLOSE WINDOW w_menu_nomina
    		CALL menu_configuracion_nom()
	WHEN 2 
		CLOSE WINDOW w_menu_nomina
		CALL menu_transacciones_nom()
	WHEN 3 
		CLOSE WINDOW w_menu_nomina
		CALL menu_consultas_nom()
	WHEN 4 
		CLOSE WINDOW w_menu_nomina
		CALL menu_reportes_nom()
	WHEN 0 
		CLOSE WINDOW w_menu_nomina
   		CALL funcion_master()
	WHEN 2016 
		CALL menu_nomina()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_configuracion_nom()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE c1200 		char(30)
DEFINE c1300 		char(30)
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf153 FROM '../forms/menf153'
DISPLAY FORM f_menf153
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Parametros Compañía"	TO c100   ## Botón 1 rolp100
DISPLAY "Compañías Nómina" 	TO c200   ## Botón 2 rolp101
DISPLAY "Impuesto a la Renta"  	TO c300   ## Botón 3 rolp102
DISPLAY "Rubros Generales"  	TO c400   ## Botón 4 rolp103
DISPLAY "Asignación Rubros"  	TO c500   ## Botón 5 rolp104
--DISPLAY "Rubros de Cálculo"  	TO c600   ## Botón 6 rolp105
DISPLAY "Rubros Fijos"  	TO c700   ## Botón 6 rolp106
DISPLAY "Procesos de Roles"  	TO c800   ## Botón 7 rolp107
DISPLAY "Empleados"  		TO c900   ## Botón 8 rolp108
DISPLAY "Sectoriales"  		TO c1000  ## Botón 9 rolp109
DISPLAY "Seguros"  		TO c1100  ## Botón 10 rolp110
DISPLAY "Integración Contable"	TO c1200  ## Botón 11 rolp500
DISPLAY "Sueldos Empleados" 	TO c1300  ## Botón 12 rolp111
DISPLAY "Conf. Contable Adic." 	TO c1400  ## Botón 13 rolp112
DISPLAY "Conf. Adicional Nom." 	TO c1500  ## Botón 14 rolp113

LET c = fgl_getkey()

CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp100')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp100 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp101')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp101 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp102')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp102 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp103')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp103 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp104')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp104 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	{--
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp105 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	--}
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp106')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp106 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp107')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp107 ', vg_base, ' ', 'RO'
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp108')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp108 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp109')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp109 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp110')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp110 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp500')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp500 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp111')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp111 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp112')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp112 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp113')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp113 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL menu_nomina()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_transacciones_nom()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf154 FROM '../forms/menf154'
DISPLAY FORM f_menf154
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Liquidación Roles"	TO c100   ## Botón 1  menu 
DISPLAY "Prestamos Empresa"    	TO c200   ## Botón 2  menu
DISPLAY "Cierre Mensual" 	TO c300   ## Botón 3  rolp251
DISPLAY "Liquidación Décimos"   TO c400   ## Botón 4  menu
DISPLAY "Fondo Reserva" 	TO c500   ## Botón 5  rolp210 
DISPLAY "Roles Usos Varios"	TO c600   ## Botón 6  rolp212 
DISPLAY "Proceso Jubilados" 	TO c700   ## Botón 7  rolp208 
DISPLAY "Distrib. Utilidades"  	TO c800   ## Botón 8  rolp222 
DISPLAY "Fondo Cesantia"  	TO c900   ## Botón 9  menu 
DISPLAY "Proceso Vacaciones"  	TO c1000  ## Botón 10 menu
DISPLAY "Impuesto A La Renta" 	TO c1100  ## Botón 11 rolp250
DISPLAY "Acta de Finiquito" 	TO c1200  ## Botón 11 rolp233
DISPLAY "Genera Archivo IESS"   TO c1300  ## Boton 12 rolp257
DISPLAY "Contabilización Rol" 	TO c1400  ## Botón 13 rolp501

LET d = fgl_getkey()

CASE d
	WHEN 1
		CLOSE WINDOW w_menu_transacciones 
		CALL menu_liquidacion_roles()
	WHEN 2
		CLOSE WINDOW w_menu_transacciones 
		CALL menu_anticipos()
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp251')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp251 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		CLOSE WINDOW w_menu_transacciones 
		CALL menu_liquidacion_decimos()
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp210')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp210 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp212')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp212 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp208')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp208 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp222')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp222 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 9
		CLOSE WINDOW w_menu_transacciones 
		CALL menu_fondo_cesantia()
	WHEN 10
		CLOSE WINDOW w_menu_transacciones 
		CALL menu_vacaciones()
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp250')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp250 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp233')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp233 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 13
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp257')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp257 ', vg_base, ' ', 'RO', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 14
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp501')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp501 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_nomina()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_consultas_nom()
DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf155 FROM '../forms/menf155'
DISPLAY FORM f_menf155
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
#DISPLAY "Acumulados Cía/Dpto"	TO c100   ## Botón 1 rolp300
#DISPLAY "Análisis por Rubros"  	TO c200   ## Botón 3 rolp301
DISPLAY "Empleados"   		TO c300   ## Botón 4 rolp302
DISPLAY "Liquidaciones"   	TO c400   ## Botón 5 rolp303
DISPLAY "Anticipos"   	 	TO c500   ## Botón 6 rolp304
DISPLAY "Distrib. Int. Poliza" 	TO c600   ## Botón 7 rolp340
DISPLAY "Acum. Fondo Cesantia" 	TO c700   ## Botón 8 rolp341
DISPLAY "Valores por Rubro"  	TO c800   ## Botón 9 rolp305
DISPLAY "Totales por Empleado"  TO c900   ## Boton 10 rolp307

LET g = fgl_getkey()

CASE g
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp300')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp300 ', vg_base, ' ', 'RO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp301')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp301 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp302')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp302 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp303')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp303 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp304')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp304 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp340')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp340 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp341')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp341 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp305')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp305 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp307')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp307 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_consultas
		CALL menu_nomina()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_reportes_nom()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE c700 		char(30)
DEFINE c800 		char(30)
DEFINE c900 		char(30)
DEFINE c1000 		char(30)
DEFINE c1100 		char(30)
DEFINE c1200 		char(30)
DEFINE c1300 		char(30)
DEFINE c1400 		char(30)
DEFINE c1500 		char(30)
DEFINE c1600 		char(30)
DEFINE c1700 		char(30)
DEFINE c1800 		char(30)
DEFINE c1900 		char(30)
DEFINE c2000 		char(30)
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf156 FROM '../forms/menf156'
DISPLAY FORM f_menf156
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture  
DISPLAY "Trabajadores"		TO c100   ## Botón 1  rolp400
--DISPLAY "Valores Rubros Fijos"	TO c200   ## Botón 2  rolp401
--DISPLAY "Rubros Generales"     	TO c300   ## Botón 3  rolp402
DISPLAY "Nómina por Tipo Pago"	TO c400   ## Botón 4  rolp403
--DISPLAY "Liquidaciones Rubros" 	TO c500   ## Botón 5  rolp404
--DISPLAY "Recibo Pago Jub." 	TO c500   ## Botón 5  rolp404
DISPLAY "Recibo de Pago Liq." 	TO c600   ## Botón 6  rolp405
DISPLAY "Carta al Banco" 	TO c700   ## Botón 7  rolp406
--DISPLAY "Listado Provisiones"  	TO c800   ## Botón 8  rolp407
DISPLAY "Planilla I.E.S.S."  	TO c900   ## Botón 9  rolp408
--DISPLAY "Control Décimos"  	TO c1000  ## Botón 10 rolp409
--DISPLAY "Liquidación Décimos"	TO c1100  ## Botón 11 rolp410
--DISPLAY "Control F. Reserva"	TO c1200  ## Botón 12 rolp411
DISPLAY "Planilla F. Reserva"	TO c1300  ## Botón 13 rolp412
--DISPLAY "Impuesto a la Renta"	TO c1400  ## Botón 14 rolp413
--DISPLAY "Planilla Imp. Renta" 	TO c1500  ## Botón 15 rolp414
--DISPLAY "Liq. Usos Varios"     	TO c1600  ## Botón 16 rolp415
DISPLAY "List. Ing/Dscto Nom." 	TO c1700  ## Botón 17 rolp416
DISPLAY "Recibo de Pago Dec." 	TO c1800  ## Botón 18 rolp410
DISPLAY "Recibo de Pago Uti." 	TO c1900  ## Botón 19 rolp420
DISPLAY "Proyección Jubilados" 	TO c2000  ## Botón 20 rolp422
DISPLAY "List. Revisión Datos" 	TO c2100  ## Botón 21 rolp423
DISPLAY "List. Tot. Empleados" 	TO c2200  ## Botón 22 rolp460


LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp400 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	{--
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp401 ', vg_base, ' ', 'RO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp402 ', vg_base, ' ', 'RO', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp403')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp403 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	{--
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp404 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	--}
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp405')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp405 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp406')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp406 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	{--
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp407 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	--}
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp408')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun rolp408 ', vg_base, ' ', 'RO', vg_codcia, ' > aporte_iess.txt'
		RUN ejecuta
	{--
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp409 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp410 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp411 ', vg_base, ' ', 'RO', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp412')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun rolp412 ', vg_base, ' ', 'RO', vg_codcia, ' > fondo_reser.txt'
		RUN ejecuta
	{--
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp413 ', vg_base, ' ', 'RO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp414 ', vg_base, ' ', 'RO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp415 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	--}
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp416')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun rolp416 ', vg_base, ' RO ', vg_codcia, ' > $HOME/tmp/rolp416.txt '
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp410')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp410 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp420')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp420 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp422')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp422 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp423')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp423 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp460')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp460 ', vg_base, ' ', 'RO', vg_codcia, ' > empleados.xml'
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_reportes
		CALL menu_nomina()
END CASE

END WHILE
END FUNCTION


------------------------ C L U B ---------------------------

FUNCTION menu_club()

DEFINE c100 		char(30)
DEFINE c200 		char(30)
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE b		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_club AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf157 FROM '../forms/menf157'
DISPLAY FORM f_menf157
--DISPLAY fondo		  TO c000   ## Picture
DISPLAY "boton_club"      TO a      ## Picture 
DISPLAY "Parámetros Club"	TO c100   ## Botón 1 rolp130
DISPLAY "Casas Comerciales" 	TO c200   ## Botón 2 rolp131
DISPLAY "Mant. Planilla Club"	TO c300   ## Botón 3 rolp230
DISPLAY "Mant. Prestamos Club" 	TO c400   ## Botón 4 rolp231
DISPLAY "Trabajadores Afilia."	TO c500   ## Botón 5 rolp330
DISPLAY "Planilla del Club"	TO c600   ## Botón 6 rolp430
DISPLAY "Consulta de Prestamos" TO c700   ## Botón 7 rolp331
DISPLAY "Estado de Cuenta"	TO c800   ## Botón 8 rolp332
DISPLAY "Ing./Egr. Banco"	TO c900   ## Botón 8 rolp232

LET b = fgl_getkey()

CASE b
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp130')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp130 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp131')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp131 ', vg_base, ' ', 'RO', ' ', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp230')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp230 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp231')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp231 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp330')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp330 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp430')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp430 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp331')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp331 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp332')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp332 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp232')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp232 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_club
		CALL menu_transacciones_nom()
END CASE
END WHILE
END FUNCTION



FUNCTION menu_liquidacion_roles()
DEFINE d		SMALLINT
DEFINE c		CHAR(1)
DEFINE programa		CHAR(7)

WHILE TRUE
OPEN WINDOW w_menu_liq_roles AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf158 FROM '../forms/menf158'
DISPLAY FORM f_menf158
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Generaci¢n"		TO c100   ## Botón 1 rolp200
DISPLAY "Mantenimiento"     	TO c200   ## Botón 2 rolp201 y rolp202 
DISPLAY "Calculo"	 	TO c300   ## Botón 3 rolp203
DISPLAY "Cierre"   		TO c400   ## Botón 4 rolp204
DISPLAY "Reapertura"	 	TO c500   ## Botón 5 rolp205 
DISPLAY "Cons. Liquidaciones"  	TO c600   ## Botón 6 rolp303
DISPLAY "Recibo De Pago"   	TO c700   ## Botón 8 rolp405
DISPLAY "N¢mina Por Tipo Pago" 	TO c800   ## Botón 7 rolp403
DISPLAY "List. Ing/Dscto Nom." 	TO c900   ## Botón 9 rolp416
DISPLAY "List. Tot. Empleados" 	TO c1000  ## Botón 10 rolp460
DISPLAY "Valores por Rubro"  	TO c1100  ## Botón 11 rolp305
DISPLAY "Datos para el Rol"  	TO c1200  ## Botón 112 rolp256

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp200')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp200 ', vg_base, ' ', 'RO', vg_codcia, ' Q '
		RUN ejecuta
	WHEN 2
		OPEN WINDOW w_tn AT 9,8 WITH 1 ROWS, 65 COLUMNS
			ATTRIBUTE(BORDER)
		WHILE TRUE
			PROMPT 'Mantenimiento Novedades: (R) Por Rubro, (T) Por Trabajador: ' FOR CHAR c
			IF c = 'R' OR c = 'T' OR c = 'r' OR c = 't' THEN
				EXIT WHILE
			END IF
		END WHILE
		--CALL fgl_keysetlabel('RETURN','')
		IF c = 'R' OR c = 'r' THEN
			LET programa = 'rolp201'
		ELSE
			LET programa = 'rolp202'
		END IF
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', programa)
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun ', programa, ' ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp203')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp203 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp204')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp204 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp205')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp205 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp303')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp303 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp405')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp405 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp403')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp403 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp416')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun rolp416 ', vg_base, ' RO ', vg_codcia, ' > $HOME/tmp/rolp416.txt '
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp460')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp460 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 11
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp305')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp305 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 12
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp256')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp256 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_liq_roles
		CALL menu_transacciones_nom()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_liquidacion_decimos()

DEFINE d		SMALLINT
DEFINE c		CHAR(1)

WHILE TRUE
OPEN WINDOW w_menu_liq_decimos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf159 FROM '../forms/menf159'
DISPLAY FORM f_menf159
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Generar Dec. Tercero"	TO c100   ## Botón 1 rolp206
DISPLAY "Mant. Dec. Tercero"   	TO c200   ## Botón 2 rolp207 
DISPLAY "Generar Dec. Cuarto" 	TO c300   ## Botón 3 rolp220
DISPLAY "Mant. Dec. Cuarto"	TO c400   ## Botón 4 rolp221
DISPLAY "Recibos De Pago"	TO c500   ## Botón 5 rolp410

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp206')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp206 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp207')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp207 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp220')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp220 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp221')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp221 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp410')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp410 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_liq_decimos
		CALL menu_transacciones_nom()
END CASE

END WHILE
END FUNCTION



FUNCTION menu_fondo_cesantia()

DEFINE d		SMALLINT
DEFINE c		CHAR(1)

WHILE TRUE
OPEN WINDOW w_menu_fondo_cesantia AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf160 FROM '../forms/menf160'
DISPLAY FORM f_menf160
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Mantenimiento P¢liza"	TO c100   ## Botón 1 rolp241
DISPLAY "Distrib. Intereses"   	TO c200   ## Botón 2 rolp240  
DISPLAY "Retiro Fondo"		TO c300   ## Botón 3 rolp242
DISPLAY "Cons. Distrib. Int."	TO c400   ## Botón 4 rolp340
DISPLAY "Acum. Fondo Cesan."	TO c500   ## Botón 5 rolp341
DISPLAY "List. Aport. Mensual"  TO c600   ## Botón 6 rolp442

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp241')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp241 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp240')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp240 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp242')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp242 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp340')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp340 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp341')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp341 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp442')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp442 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_fondo_cesantia
		CALL menu_transacciones_nom()
END CASE

END WHILE

END FUNCTION



FUNCTION menu_anticipos()
DEFINE d		SMALLINT
DEFINE c		CHAR(1)

WHILE TRUE
OPEN WINDOW w_menu_ant AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf162 FROM '../forms/menf162'
DISPLAY FORM f_menf162
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Anticipos"		TO c100   ## Botón 1 rolp214
DISPLAY "Cancelar Dividendo"	TO c200   ## Botón 2 rolp255
DISPLAY "Consulta Anticipos"	TO c300   ## Botón 3 rolp304
DISPLAY "Listado Anticipos"	TO c400   ## Botón 4 rolp461
DISPLAY "Movimiento Anticipos"	TO c500   ## Boton 5 rolp306

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp214')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp214 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp255')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp255 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp304')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp304 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp461')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp461 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp306')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp306 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_ant
		CALL menu_transacciones_nom()
END CASE

END WHILE

END FUNCTION



FUNCTION menu_vacaciones()
DEFINE d		SMALLINT
DEFINE c		CHAR(1)

WHILE TRUE
OPEN WINDOW w_menu_vaca AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf161 FROM '../forms/menf161'
DISPLAY FORM f_menf161
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Anticipos"		TO c100   ## Botón 1 rolp253
DISPLAY "Vacaciones"		TO c200   ## Botón 2 rolp252
DISPLAY "Días de Gozo" 		TO c300   ## Botón 3 rolp254
DISPLAY "Consulta"     		TO c400   ## Botón 4 rolp350

LET d = fgl_getkey()

CASE d
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp253')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp253 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp252')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp252 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp254')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp254 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RO', 'rolp350')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA', vg_separador, 'fuentes', vg_separador, '; fglrun rolp350 ', vg_base, ' ', 'RO', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_vaca
		CALL menu_transacciones_nom()
END CASE

END WHILE

END FUNCTION



FUNCTION menu_sri()
DEFINE c		SMALLINT

WHILE TRUE
	OPEN WINDOW w_menu_sri AT 3,2 WITH 22 ROWS, 80 COLUMNS
		ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
			  BORDER, MESSAGE LINE LAST - 2) 
	OPEN FORM f_menf163 FROM '../forms/menf163'
	DISPLAY FORM f_menf163
	DISPLAY "boton_sri"		TO a      ## Picture 
	DISPLAY "Anexo Ventas"		TO c100   ## Botón 1 srip201
	DISPLAY "Anexo Compras"		TO c200   ## Botón 2 srip202
	--DISPLAY "Control Doc. SRI"	TO c300   ## Botón 3 genp141
	--DISPLAY "Control Sec. SRI"	TO c400   ## Botón 4 genp142
	DISPLAY "Control Sec. SRI"	TO c300   ## Botón 3 genp144
	DISPLAY "Config.Codigos SRI"	TO c400   ## Botón 4 srip204
	DISPLAY "Gen. Doc. Elec."	TO c500   ## Botón 5 srip205
	LET c = fgl_getkey()
	CASE c
		WHEN 1
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'SR', 'srip201')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun srip201 ', vg_base, ' ', 'SR', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 2
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'SR', 'srip202')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun srip202 ', vg_base, ' ', 'SR', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		{--
		WHEN 3 
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'GE', 'genp141')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp141 ', vg_base, ' ', 'GE', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 4
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'GE', 'genp142')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp142 ', vg_base, ' ', 'GE', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		--}
		WHEN 3
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'GE', 'genp144')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp144 ', vg_base, ' ', 'GE', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 4
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'SR', 'srip204')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador, 'fuentes', vg_separador, '; fglrun srip204 ', vg_base, ' ', 'SR', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 5
			IF NOT fl_control_acceso_proceso_men(vg_usuario,
						vg_codcia, 'SR', 'srip205')
			THEN
				EXIT CASE
			END IF
			LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglrun srip205 ', vg_base, ' ', 'SR', vg_codcia, ' ', vg_codloc
			RUN ejecuta
		WHEN 0 
			CLOSE WINDOW w_menu_sri
	  		CALL funcion_master()
		WHEN 2016 
			CALL menu_sri()
	END CASE
END WHILE

END FUNCTION



------------------------- FUNCIONES VARIAS --------------------------
FUNCTION tiene_acceso(v_usuario, v_codcia, v_modulo) 
DEFINE v_usuario	LIKE gent005.g05_usuario
DEFINE v_codcia		LIKE gent001.g01_compania
DEFINE v_modulo		LIKE gent050.g50_modulo
DEFINE r_g50		RECORD LIKE gent050.*

CALL fl_lee_modulo(v_modulo) RETURNING r_g50.*
IF r_g50.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'MODULO: ' || v_modulo CLIPPED 
				          || ' NO EXISTE ', 'stop')
	RETURN 0
END IF
SELECT * FROM gent052 
	WHERE g52_modulo  = v_modulo  AND 
	      g52_usuario = v_usuario AND
	      g52_estado = 'A'
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'USUARIO NO TIENE ACCESO AL MODULO: '
					 || r_g50.g50_nombre CLIPPED 
					 || '. PEDIR AYUDA AL ADMINISTRADOR ',
					 'stop')
	RETURN 0
END IF
SELECT * FROM gent053 
	WHERE g53_modulo   = v_modulo  AND 
	      g53_usuario  = v_usuario AND
	      g53_compania = v_codcia 
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,'USUARIO NO TIENE ACCESO A LA COMPAÑIA:'
				|| ' ' || rg_cia.g01_abreviacion CLIPPED 
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION
