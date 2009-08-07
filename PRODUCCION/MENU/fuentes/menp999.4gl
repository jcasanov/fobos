------------------------------------------------------------------------------er
-- Titulo           : prog.4gl - MENU PRINCIPAL DE FHOBOS
-- Elaboracion      : 10-ago-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun programa.4gl parametro1 parametro2 ...
-- Ultima Correccion: 11-ago-2001
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE ejecuta		CHAR(100)
--DEFINE fondo		CHAR(25)
DEFINE fondo_pp		CHAR(25)
DEFINE a		CHAR(25)

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'menp000'
LET vg_codcia  = 2
LET vm_titprog  = 'MENU PRINCIPAL - PHOBOS'
LET fondo_pp   	= 'phobos_biger'
--LET fondo   	= 'phobos_small'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vm_titprog)
CALL validar_parametros()
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
DISPLAY "Bienvenidos"  	  TO c100   ## Bot�n

LET p = fgl_getkey()

CASE p
	WHEN 1 
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
OPEN FORM f_menf100 FROM '../forms/menf100'

DISPLAY FORM f_menf100
--DISPLAY "Veh�culos" 	TO c1000   ## Bot�n
DISPLAY "Maquinarias" 	TO c1000   ## Bot�n
DISPLAY "Inventarios" 	TO c2000   ## Bot�n
DISPLAY "Talleres"  	TO c3000   ## Bot�n
DISPLAY "Cobranzas"    	TO c4000   ## Bot�n
DISPLAY "Tesorer�a" 	TO c5000   ## Bot�n
DISPLAY "Contabilidad" 	TO c6000   ## Bot�n
DISPLAY "Roles"   	TO c7000   ## Bot�n
DISPLAY "Compras" 	TO c8000   ## Bot�n
DISPLAY "Caja" 		TO c9000   ## Bot�n
--DISPLAY "Caja Chica" 	TO c10000  ## Bot�n
DISPLAY "Generales" 	TO c10000  ## Bot�n

--DISPLAY "vehiculos"   TO c1001   ## Picture 
DISPLAY "maquinarias"   TO c1001   ## Picture 
DISPLAY "repuestos"     TO c2001   ## Picture 
--DISPLAY "talleres"    TO c3001   ## Picture 
DISPLAY "talleres_dit"  TO c3001   ## Picture 
DISPLAY "cobranzas"     TO c4001   ## Picture
DISPLAY "tesoreria"     TO c5001   ## Picture
DISPLAY "contabilidad"  TO c6001   ## Picture
DISPLAY "roles"		TO c7001   ## Picture
DISPLAY "compras"	TO c8001   ## Picture
DISPLAY "caja"		TO c9001   ## Picture
--DISPLAY "caja_chica"	TO c10001  ## Picture
DISPLAY "generales"  	TO c10001  ## Picture

--OPEN WINDOW lwin AT 21,83 WITH 4 ROWS, 20 COLUMNS
--     ATTRIBUTE(BLINK,BOLD,FORM LINE 1)
--     OPEN FORM logo FROM "../forms/logo"
--     DISPLAY FORM logo ATTRIBUTE(BLINK,BOLD)
--     DISPLAY "phobos.bmp" TO F1 ATTRIBUTE(BLINK,REVERSE)

LET a = fgl_getkey()
IF a = 26 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_vehiculos()
END IF
IF a = 25 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_repuestos()
END IF
IF a = 24 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_talleres()
END IF
IF a = 23 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_cobranzas()
END IF
IF a = 22 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_tesoreria()
END IF
IF a = 21 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_contabilidad()
END IF
IF a = 20 THEN
--	CLOSE WINDOW w_menu_principal
--	CALL menu_roles()
END IF
IF a = 19 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_compras()
END IF
IF a = 18 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_caja()
END IF
{
IF a = 17 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_caja_chica()
END IF
}
IF a = 17 THEN
	CLOSE WINDOW w_menu_principal
	CALL menu_configuracion_gen()
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Pedidos"         TO c300   ## Bot�n
DISPLAY "Consultas"       TO c400   ## Bot�n
DISPLAY "Reportes"        TO c500   ## Bot�n
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
DISPLAY "Compa��as"     TO c100   ## Bot�n 1
DISPLAY "Vendedores" 	TO c200   ## Bot�n 2
DISPLAY "Bodegas"       TO c300   ## Bot�n 3
DISPLAY "L�neas"   	TO c400   ## Bot�n 4
DISPLAY "Veh�culos"  	TO c500   ## Bot�n 5
DISPLAY "Colores"     	TO c600   ## Bot�n 6
DISPLAY "Financiamiento" TO c700  ## Bot�n 7
DISPLAY "Modelos" 	TO c800   ## Bot�n 8
DISPLAY "Reservaciones" TO c900   ## Bot�n 9

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
DISPLAY "Series"     		TO c100   ## Bot�n 1
DISPLAY "Proformas"     	TO c200   ## Bot�n 2
DISPLAY "Pre-Ventas"     	TO c300   ## Bot�n 3
DISPLAY "Transferencias" 	TO c400   ## Bot�n 4
DISPLAY "Ajustes Costos"       	TO c500   ## Bot�n 5
DISPLAY "Ajustes Existencias"  	TO c600   ## Bot�n 6
DISPLAY "Devoluci�n Facturas"  	TO c700   ## Bot�n 7
DISPLAY "Orden de Chequeos"  	TO c800   ## Bot�n 8
DISPLAY "Reservaciones"  	TO c900   ## Bot�n 9
DISPLAY "Aprobaci�n Preventas" 	TO c1000  ## Bot�n 10

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
DISPLAY "Ingreso Pedidos"     	TO c100   ## Bot�n 1
DISPLAY "Recepci�n Pedidos"    	TO c200   ## Bot�n 2
DISPLAY "Liquidacion"     	TO c300   ## Bot�n 3
DISPLAY "Cierre Pedidos" 	TO c400   ## Bot�n 4

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
DISPLAY "Estad�stica Bodegas"   TO c100   ## Bot�n 1  vehp300
DISPLAY "Estad�stica Vendedor"  TO c200   ## Bot�n 2  vehp301
DISPLAY "Estad�stica Modelo"    TO c300   ## Bot�n 3  vehp302
DISPLAY "Veh�culos Vendidos"	TO c400   ## Bot�n 4  vehp303
DISPLAY "Modelos"         	TO c500   ## Bot�n 5  vehp305
DISPLAY "Series"    		TO c600   ## Bot�n 6  vehp306
DISPLAY "Reservaciones"       	TO c700   ## Bot�n 7  vehp307
DISPLAY "Pedidos"        	TO c800   ## Bot�n 8  vehp308
DISPLAY "Liquidaciones"        	TO c900   ## Bot�n 9  vehp309
DISPLAY "Det. Transacciones"   	TO c1000  ## Bot�n 10 vehp310

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
DISPLAY "Ventas/Devoluciones"	TO c100   ## Bot�n 1
DISPLAY "Transacciones"     	TO c200   ## Bot�n 2
DISPLAY "Existencias"     	TO c300   ## Bot�n 3
DISPLAY "Precios"      		TO c400   ## Bot�n 4
DISPLAY "Proformas"       	TO c500   ## Bot�n 5
DISPLAY "Facturaci�n"  		TO c600   ## Bot�n 6
DISPLAY "Nota de Entrega"  	TO c700   ## Bot�n 7
DISPLAY "Carta de Venta"  	TO c800   ## Bot�n 8
DISPLAY "Transferencias"  	TO c900  ## Bot�n 9
DISPLAY "Ajustes Costo"  	TO c1000  ## Bot�n 10
DISPLAY "Ajustes Existencia"  	TO c1100  ## Bot�n 11
DISPLAY "Compra Local"  	TO c1200  ## Bot�n 12
DISPLAY "Importaci�n"  		TO c1300  ## Bot�n 13
DISPLAY "Devoluci�n Facturas"  	TO c1400  ## Bot�n 14
DISPLAY "Reservaciones"  	TO c1500  ## Bot�n 15
DISPLAY "Pedidos"  		TO c1600  ## Bot�n 16
DISPLAY "Recepci�n Pedidos"  	TO c1700  ## Bot�n 17
DISPLAY "Liquidaciones"  	TO c1800  ## Bot�n 18
DISPLAY "Orden de Chequeo"  	TO c1900  ## Bot�n 19

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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Pedidos"         TO c300   ## Bot�n
DISPLAY "Consultas"       TO c400   ## Bot�n
DISPLAY "Reportes"        TO c500   ## Bot�n

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
		CALL menu_vehiculos()
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
DEFINE c		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf102 FROM '../forms/menf102'
DISPLAY FORM f_menf102
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_configuracion"	TO a      ## Picture 
DISPLAY "Compa��as"     	TO c100   ## Bot�n 1
DISPLAY "Vendedores" 		TO c200   ## Bot�n 2
DISPLAY "Bodegas"       	TO c300   ## Bot�n 3
DISPLAY "L�neas"   		TO c400   ## Bot�n 4
DISPLAY "Indice Rotaci�n"  	TO c500   ## Bot�n 5
DISPLAY "Unidades Medida"     	TO c600   ## Bot�n 6
DISPLAY "Tipos de Items" 	TO c700   ## Bot�n 7
DISPLAY "Descuentos" 		TO c800   ## Bot�n 8
DISPLAY "Equivalencias" 	TO c900   ## Bot�n 9

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp100 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp101 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp102 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp103 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp104 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp105 ', vg_base, ' ', 'RE'
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp106 ', vg_base, ' ', 'RE'
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp107 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp109 ', vg_base, ' ', 'RE', vg_codcia
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
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf108 FROM '../forms/menf108'
DISPLAY FORM f_menf108
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture  
DISPLAY "Items"     		TO c100   ## Bot�n 1  repp108
DISPLAY "Sustituciones"     	TO c200   ## Bot�n 2  repp200
DISPLAY "Ventas Perdidas"       TO c300   ## Bot�n 3  repp201
DISPLAY "Actualizaci�n V.P."    TO c400   ## Bot�n 4  repp202
DISPLAY "Pre-Venta" 		TO c500   ## Bot�n 5  repp209
DISPLAY "Aprobaci�n Cr�dito" 	TO c600   ## Bot�n 6  repp210
DISPLAY "Ajustes Existencias"  	TO c700   ## Bot�n 7  repp212
DISPLAY "Ajustes Costos"  	TO c800   ## Bot�n 8  repp213
DISPLAY "Compra Local"  	TO c900   ## Bot�n 9  repp214
DISPLAY "Ventas al Taller"  	TO c1000  ## Bot�n 10 repp215
DISPLAY "Transferencias"  	TO c1100  ## Bot�n 11 repp216
DISPLAY "Dev. Facturas"  	TO c1200  ## Bot�n 12 repp217
DISPLAY "Dev. Compra Local"  	TO c1300  ## Bot�n 13 repp218
DISPLAY "Dev. Ventas Taller"  	TO c1400  ## Bot�n 14 repp219
DISPLAY "Proformas"  		TO c1500  ## Bot�n 15 repp220
DISPLAY "Mantenimiento Precios"	TO c1600  ## Bot�n 16 repp221
DISPLAY "Actualizaci�n Precios"	TO c1700  ## Bot�n 17 repp222
DISPLAY "Aprobaci�n Pre-Ventas"	TO c1800  ## Bot�n 18 repp223
DISPLAY "Reclasificaci�n Items"	TO c1900  ## Bot�n 19 repp224
DISPLAY "Generar Inventario" 	TO c2000  ## Bot�n 20 repp225
DISPLAY "Conteo Inventario"	TO c2100  ## Bot�n 21 repp226
DISPLAY "Cierre Inventario" 	TO c2200  ## Bot�n 22 repp227
DISPLAY "Cierre Mensual" 	TO c2300  ## Bot�n 22 repp299


LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp108 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp200 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp201 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp202 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp209 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp210 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp212 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp213 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp214 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp215 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp216 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp217 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp218 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp219 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp220 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp221 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 17
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp222 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 18
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp223 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 19
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp224 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 20
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp225 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 21
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp226 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 22
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp227 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 23
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp299 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_transacciones
		CALL menu_repuestos()
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
DEFINE e		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_pedidos AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf109 FROM '../forms/menf109'
DISPLAY FORM f_menf109
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_pedidos"	        TO a      ## Picture 
DISPLAY "Pedidos Sugeridos"    	TO c100   ## Bot�n 1 repp203
DISPLAY "Mantenimiento"  	TO c200   ## Bot�n 2 repp204
DISPLAY "Confirmaci�n Pedidos" 	TO c300   ## Bot�n 3 repp205
DISPLAY "Recepci�n Pedidos" 	TO c400   ## Bot�n 4 repp206
DISPLAY "Liquidaci�n Pedidos" 	TO c500   ## Bot�n 5 repp207
DISPLAY "Cierre Pedidos" 	TO c600   ## Bot�n 6 repp208

LET e = fgl_getkey()

CASE e
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp203 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp204 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp205 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp206 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp207 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
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
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf112 FROM '../forms/menf112'
DISPLAY FORM f_menf112
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Items" 		TO c100   ## Bot�n 1 repp300
DISPLAY "Utilidad Facturas" 	TO c200   ## Bot�n 2 repp301
DISPLAY "Pedidos - Backorders"	TO c300   ## Bot�n 3 repp302
DISPLAY "Liquidaciones" 	TO c400   ## Bot�n 4 repp303
DISPLAY "Proformas"       	TO c500   ## Bot�n 5 repp306
DISPLAY "Kardex de Items"      	TO c600   ## Bot�n 6 repp307
DISPLAY "Estad�stica Vendedor"  TO c700   ## Bot�n 7 repp304
DISPLAY "Estad�stica Facturas"  TO c800   ## Bot�n 8 repp305
DISPLAY "An�lisis Ventas Item"  TO c900   ## Bot�n 9 repp310
DISPLAY "Det. Transacci�nes"    TO c1000  ## Bot�n 10 repp309
DISPLAY "Stock sin Ventas"      TO c1100  ## Bot�n 11 repp311
DISPLAY "Cons. Ventas Clientes" TO c1200  ## Bot�n 12 repp312

LET g = fgl_getkey()
CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp300 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp301 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp302 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp303 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp306 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp307 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp304 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp305 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp310 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp309 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp311 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp312 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
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
DISPLAY "Facturas/Devolucion"   TO c100   ## Bot�n 1 repp400
DISPLAY "Res�men de Ventas"    	TO c200   ## Bot�n 2 repp401
DISPLAY "Res�men Inventario"  	TO c300   ## Bot�n 3 repp402
DISPLAY "Existencias"  		TO c400   ## Bot�n 4 repp403
DISPLAY "Precios"       	TO c500   ## Bot�n 5 repp404
DISPLAY "Pedido Sugerido" 	TO c600   ## Bot�n 6 repp405
DISPLAY "Pedido Emergencia"  	TO c700   ## Bot�n 7 repp406
DISPLAY "Impresi�n Recepci�n"	TO c800   ## Bot�n 8 repp407
DISPLAY "Liquidaci�n" 		TO c900   ## Bot�n 9 repp408
DISPLAY "Comprob. Importaci�n" 	TO c1000  ## Bot�n 10 repp409
DISPLAY "Proformas" 	 	TO c1100  ## Bot�n 11 repp419
DISPLAY "M�rgenes de Utilidad" 	TO c1200  ## Bot�n 12 repp420
DISPLAY "Movimientos de Items" 	TO c1300  ## Bot�n 13 repp421
DISPLAY "Control Inv. F�sico"  	TO c1400  ## Bot�n 14 repp425
DISPLAY "Diferencias"	  	TO c1500  ## Bot�n 15 repp423
DISPLAY "Reimp. Transacciones" 	TO c1600  ## Bot�n 16 repp422
DISPLAY "Nota de Pedido" 	TO c1700  ## Bot�n 17 repp426
DISPLAY "Ubicaci�n de Items" 	TO c1800  ## Bot�n 18 repp427

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp400 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp401 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp402 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp403 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp404 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp405 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp406 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp407 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp408 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp409 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp419 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp420 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 13
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp421 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp425 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp423 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp422 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 17
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp426 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 18
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglrun repp427 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Consultas"       TO c300   ## Bot�n
DISPLAY "Reportes"        TO c400   ## Bot�n

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
DISPLAY "Compa��as"     	TO c100   ## Bot�n 1 talp100
DISPLAY "Marcas" 		TO c200   ## Bot�n 2 talp101
DISPLAY "Secciones"       	TO c300   ## Bot�n 3 talp102
DISPLAY "Mec�nicos"   		TO c400   ## Bot�n 4 talp103
DISPLAY "Modelos Veh�culos"  	TO c500   ## Bot�n 5 talp104
DISPLAY "Tipos O. Trabajo"     	TO c600   ## Bot�n 6 talp105
DISPLAY "Subtipos O. Trabajo" 	TO c700   ## Bot�n 7 talp106
DISPLAY "Tareas" 		TO c800   ## Bot�n 8 talp107

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp100 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp101 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp102 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp103 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp104 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp105 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp106 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 8
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
DISPLAY "Veh�culos Clientes"	TO c100   ## Bot�n 1
DISPLAY "Presupuestos"     	TO c200   ## Bot�n 2
DISPLAY "Tareas / Presupuestos" TO c300   ## Bot�n 3
DISPLAY "Materiales / Presup."  TO c400   ## Bot�n 4
DISPLAY "Ordenes de Trabajo" 	TO c500   ## Bot�n 5
DISPLAY "Gastos de viaje" 	TO c1100  ## Bot�n 6
DISPLAY "Tareas / O. Trabajo"  	TO c600   ## Bot�n 7
DISPLAY "Cierre O. Trabajo"  	TO c700   ## Bot�n 8
DISPLAY "Reapertura O. Trabajo"	TO c800   ## Bot�n 9
DISPLAY "Forma de Pago"  	TO c900   ## Bot�n 10
DISPLAY "Anulaci�n Facturas"	TO c1000  ## Bot�n 11 

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp200 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp201 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp202 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp203 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp212 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp205 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp206 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp207 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp208 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp211 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
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
DISPLAY "Ordenes de Trabajo"	TO c100   ## Bot�n 1 talp300
DISPLAY "Estad�stica Facturas"  TO c200   ## Bot�n 3 talp310
DISPLAY "Mec�nicos / Asesores"  TO c300   ## Bot�n 4 talp311

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp300 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp310 ', vg_base, ' ', 'TA', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp311 ', vg_base, ' ', 'TA', vg_codcia
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
DISPLAY "Facturaci�n"		TO c100   ## Bot�n 1 talp400
DISPLAY "Presupuestos"    	TO c200   ## Bot�n 2 talp401
DISPLAY "Gastos por O.T."  	TO c300   ## Bot�n 3 talp405

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp400 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglrun talp401 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Consultas"       TO c300   ## Bot�n
DISPLAY "Reportes"        TO c400   ## Bot�n

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
DISPLAY "Compa��as"     	TO c100   ## Bot�n 1 cxcp100
DISPLAY "Clientes Cia. / Loc." 	TO c200   ## Bot�n 2 cxcp101
DISPLAY "Doc. / Transacciones"  TO c300   ## Bot�n 3 cxcp102
DISPLAY "Ejecutivos Cuentas"   	TO c400   ## Bot�n 4 cxcp103
DISPLAY "Zonas de Cobro"  	TO c500   ## Bot�n 5 cxcp104
DISPLAY "Plazos Cr�ditos"     	TO c600   ## Bot�n 6 cxcp105

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp100 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp101 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp102 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp103 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp104 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 6
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
DEFINE d		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_transacciones AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf122 FROM '../forms/menf122'
DISPLAY FORM f_menf122
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_transaciones"	TO a      ## Picture 
DISPLAY "Documentos Deudores"  	TO c100   ## Bot�n 1 cxcp200
DISPLAY "Documentos a Favor"   	TO c200   ## Bot�n 2 cxcp201
DISPLAY "Ingreso Ajustes"     	TO c300   ## Bot�n 3 cxcp202
DISPLAY "Aplicaci�n NC / PA" 	TO c400   ## Bot�n 4 cxcp203
DISPLAY "Autorizaci�n Cobro"    TO c500   ## Bot�n 5 cxcp204
DISPLAY "Autorizaci�n P.A."     TO c600   ## Bot�n 6 cxcp205
DISPLAY "Cheques Postfechados"  TO c700   ## Bot�n 7 cxcp206
DISPLAY "Cheques Protestados"   TO c800   ## Bot�n 8 cxcp207
DISPLAY "Ciere Mensual"   	TO c900   ## Bot�n 9 cxcp208

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp200 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp201 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp202 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp203 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp204 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp205 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp206 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp207 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp208 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
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
DEFINE g		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_consultas AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf123 FROM '../forms/menf123'
DISPLAY FORM f_menf123
--DISPLAY fondo		  	TO c000   ## Picture
DISPLAY "boton_consultas"	TO a      ## Picture 
DISPLAY "Cheques Postfechados" 	TO c100   ## Bot�n 1  cxcp303
DISPLAY "Cheques Protestados"   TO c200   ## Bot�n 2  cxcp304
DISPLAY "Estado de Cuentas"     TO c300   ## Bot�n 3  cxcp305
DISPLAY "Anl. Cartera Clientes" TO c400   ## Bot�n 4  cxcp306
DISPLAY "Anl. Cartera Detalle" 	TO c500   ## Bot�n 5  cxcp307
DISPLAY "Acumulados Cartera" 	TO c600   ## Bot�n 6  cxcp308
DISPLAY "Anl. Cobrar vs Pagar" 	TO c700   ## Bot�n 7  cxcp309
DISPLAY "Valores a Favor" 	TO c800   ## Bot�n 8  cxcp300

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp303 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp304 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp305 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp306 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp307 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp308 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp309 ', vg_base, ' ', 'CO', vg_codcia
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp300 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
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
DISPLAY "Detalle Cartera"	TO c100   ## Bot�n 1 cxcp400
DISPLAY "Res�men Cartera"     	TO c200   ## Bot�n 2 cxcp401
DISPLAY "Reimp. Transacciones" 	TO c300   ## Bot�n 3 cxcp403
DISPLAY "Cheques Postfechados"  TO c400   ## Bot�n 4 cxcp408
DISPLAY "Estado de Cuentas"  	TO c500   ## Bot�n 5 cxcp409
DISPLAY "Cheques Protestados"  	TO c600   ## Bot�n 6 cxcp410

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp400 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp401 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp402 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp408 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp409 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglrun cxcp410 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Consultas"       TO c300   ## Bot�n
DISPLAY "Reportes"        TO c400   ## Bot�n

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
DISPLAY "Compa��as"     	TO c100   ## Bot�n 1 cxpp100
DISPLAY "Proveedores C�a/Loc" 	TO c200   ## Bot�n 2 cxpp101
DISPLAY "Doc./Transacciones"    TO c300   ## Bot�n 3 cxpp102

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp100 ', vg_base, ' ', 'TE', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp101 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp102 ', vg_base, ' ', 'TE', vg_codcia
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
DISPLAY "Documentos Deudores"  	TO c100   ## Bot�n 1 cxpp200
DISPLAY "Documentos a Favor"   	TO c200   ## Bot�n 2 cxpp201
DISPLAY "Ingreso Ajustes"     	TO c300   ## Bot�n 3 cxpp202
DISPLAY "Aplicaci�n NC / PA" 	TO c400   ## Bot�n 4 cxpp203
DISPLAY "Aut. Pago Facturas"    TO c500   ## Bot�n 5 cxpp204
DISPLAY "Aut. Pago Anticipado"  TO c600   ## Bot�n 6 cxpp205
DISPLAY "Cheques Orden Pago"    TO c700   ## Bot�n 7 cxpp206
DISPLAY "Digitaci�n Retenci�n"  TO c800   ## Bot�n 8 cxpp207
DISPLAY "Cierre Mensual"        TO c900   ## Bot�n 9 cxpp208

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp200 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp201 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp202 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp203 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp204 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp205 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp206 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp207 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp208 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
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
DISPLAY "Estado Cuentas Prov." 	TO c100   ## Bot�n 1  cxpp300
DISPLAY "Anl. Cartera Prov." 	TO c200   ## Bot�n 2  cxpp301
DISPLAY "Anl. Detalle Cartera"	TO c300   ## Bot�n 3  cxpp302
DISPLAY "Acumulados Cartera"    TO c400   ## Bot�n 5  cxpp303
DISPLAY "Valores a Favor"       TO c500   ## Bot�n 5  cxpp305

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp300 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp301 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp302 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp303 ', vg_base, ' ', 'TE', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp305 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
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

DISPLAY "Detalle Cartera"	TO c100   ## Bot�n 1 cxpp400
DISPLAY "Res�men Cartera"     	TO c200   ## Bot�n 2 cxpp401
DISPLAY "Reimp. Transacciones" 	TO c300   ## Bot�n 3 cxpp408
DISPLAY "Retenciones"		TO c400   ## Bot�n 4 cxpp405
DISPLAY "Estado de Cuentas" 	TO c500   ## Bot�n 5 cxpp407
DISPLAY "Listado Retenciones" 	TO c600   ## Bot�n 6 cxpp410

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp400 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp401 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp408 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp405 ', vg_base, ' ', 'TE', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp407 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglrun cxpp410 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Consultas"       TO c300   ## Bot�n
DISPLAY "Reportes"        TO c400   ## Bot�n

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
DISPLAY "Compa��as"     	TO c100   ## Bot�n 1 ctbp100
DISPLAY "Niveles Plan Cuentas" 	TO c200   ## Bot�n 2 ctbp101
DISPLAY "Grupos Cuentas"	TO c300   ## Bot�n 3 ctbp102
DISPLAY "Tipos Comprobantes"   	TO c400   ## Bot�n 4 ctbp103
DISPLAY "Subtipos Comprobantes"	TO c500   ## Bot�n 5 ctbp104
DISPLAY "Tipos Doc. Fuentes"   	TO c600   ## Bot�n 6 ctbp105
DISPLAY "Mantenimiento Cuentas"	TO c700   ## Bot�n 7 ctbp106
DISPLAY "Distribuci�n Cuentas"  TO c800   ## Bot�n 8 ctbp107
DISPLAY "Filtros / An�lisis" TO c900   ## Bot�n 9 ctbp108

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp100 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp101 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp102 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp103 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp104 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp105 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp106 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp107 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp108 ', vg_base, ' ', 'CB', vg_codcia
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
DISPLAY "Bloqueo Meses"   	TO c100   ## Bot�n 1 ctbp200
DISPLAY "Diarios Contables"   	TO c200   ## Bot�n 2 ctbp201
DISPLAY "Diarios Peri�dicos"   	TO c300   ## Bot�n 3 ctbp202
DISPLAY "Remayorizaci�n Mes"	TO c400   ## Bot�n 4 ctbp204
DISPLAY "Cierre Mensual"	TO c500   ## Bot�n 5 ctbp206
DISPLAY "Reapertura de Mes" 	TO c600   ## Bot�n 6 ctbp205
DISPLAY "Gen. D. Peri�dicos" 	TO c700   ## Bot�n 7 ctbp208

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp200 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp201 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp202 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp204 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp206 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp205 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp208 ', vg_base, ' ', 'CB', vg_codcia
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
DISPLAY "Plan de Cuentas" 	TO c100   ## Bot�n 1  ctbp301
DISPLAY "Movimientos Cuentas"   TO c200   ## Bot�n 2  ctbp302
DISPLAY "Balance General"       TO c300   ## Bot�n 3  ctbp305
DISPLAY "Perdidas y Ganancias"  TO c400   ## Bot�n 4  ctbp306
DISPLAY "Consulta Gen�rica" 	TO c500   ## Bot�n 5  ctbp308

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp301 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp302 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp305 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp306 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp308 ', vg_base, ' ', 'CB', vg_codcia
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
DISPLAY "Balance Comprobaci�n"  TO c100   ## Bot�n 1 ctbp401
DISPLAY "Balance General"   	TO c200   ## Bot�n 2 ctbp402
DISPLAY "P�rdidas y Ganancias" 	TO c300   ## Bot�n 3 ctbp403
DISPLAY "Plan de Cuentas"  	TO c400   ## Bot�n 4 ctbp404
DISPLAY "Movimiento de Cuentas"	TO c500   ## Bot�n 5 ctbp405
DISPLAY "Control Comprobantes" 	TO c600   ## Bot�n 6 ctbp406
DISPLAY "Diarios Contables"	TO c700   ## Bot�n 7 ctbp408

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp401 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp402 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp403 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp404 ', vg_base, ' ', 'CB', vg_codcia
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp405 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp406 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglrun ctbp408 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Consultas"       TO c300   ## Bot�n
DISPLAY "Reportes"        TO c400   ## Bot�n

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
DISPLAY "Compa��as"     	TO c100   ## Bot�n 1 ordp100
DISPLAY "Tipos de O. Compras" 	TO c200   ## Bot�n 2 ordp101
DISPLAY "Porcentaje Retenci�n" TO c300   ## Bot�n 3 ordp102

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp100 ', vg_base, ' ', 'OC', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp101 ', vg_base, ' ', 'OC', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp102 ', vg_base, ' ', 'OC', vg_codcia
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
DISPLAY "Ingreso O. Compras"   	TO c100   ## Bot�n 1 ordp200
DISPLAY "Aprobaci�n O. Compras" TO c200   ## Bot�n 1 ordp201
DISPLAY "Recepci�n  O. Compras"	TO c300   ## Bot�n 2 ordp202
DISPLAY "Anulaci�n Recepci�n"	TO c400   ## Bot�n 3 ordp204

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp200 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp201 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp202 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
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
DISPLAY "Consulta O. Compras"   TO c100   ## Bot�n 1  ordp300
--DISPLAY "Esd�sticas de Compras"	TO c200   ## Bot�n 2  ordp301

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp300 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp301 ', vg_base, ' ', 'OC', vg_codcia
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
DISPLAY "Impresi�n O. Compras"	TO c100   ## Bot�n 1 ordp400
DISPLAY "Detalle O. Compras"  	TO c200   ## Bot�n 2 ordp401
DISPLAY "Recepci�n O. Compras" 	TO c300   ## Bot�n 3 ordp402

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp400 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp401 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglrun ordp402 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
		RUN ejecuta
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
DISPLAY "Configuraciones" TO c100   ## Bot�n
DISPLAY "Transacciones"   TO c200   ## Bot�n
DISPLAY "Consultas"       TO c300   ## Bot�n
DISPLAY "Reportes"        TO c400   ## Bot�n

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
DISPLAY "Par�metros Generales"	TO c100   ## Bot�n 1 cajp100
DISPLAY "Tipos Formas Pagos" 	TO c200   ## Bot�n 2 cajp101
DISPLAY "Mantenimiento Cajas"   TO c300   ## Bot�n 3 cajp102

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp100 ', vg_base, ' ', 'CG', vg_codcia
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp101 ', vg_base, ' ', 'CG', vg_codcia
		RUN ejecuta
	WHEN 3
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
DISPLAY "Apertura de Caja"   	TO c100   ## Bot�n 1 cajp200
DISPLAY "Reapertura de Caja" 	TO c200   ## Bot�n 2 cajp201
DISPLAY "Cierres de Caja"   	TO c300   ## Bot�n 2 cajp202
DISPLAY "Ingresos de Caja"	TO c400   ## Bot�n 4 cajp203
DISPLAY "Otros Ingresos"	TO c500   ## Bot�n 5 cajp206
DISPLAY "Egresos de Caja"	TO c600   ## Bot�n 6 cajp207
DISPLAY "Eliminaci�n I. Caja"	TO c700   ## Bot�n 7 cajp208

LET d = fgl_getkey()

CASE d
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp200 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp201 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp202 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp203 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp206 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp207 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp208 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
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
DISPLAY "Transacciones Caja"   	TO c100   ## Bot�n 1  cajp300

LET g = fgl_getkey()

CASE g
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp300 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
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
DEFINE c300 		char(30)
DEFINE c400 		char(30)
DEFINE c500 		char(30)
DEFINE c600 		char(30)
DEFINE h		SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_reportes AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf144 FROM '../forms/menf144'
DISPLAY FORM f_menf144
--DISPLAY fondo			TO c000   ## Picture
DISPLAY "boton_reportes"	TO a      ## Picture 
DISPLAY "Valores Recaudados" 	TO c100   ## Bot�n 2 cajp402
DISPLAY "Egresos de Caja" 	TO c200   ## Bot�n 3 cajp405

LET h = fgl_getkey()

CASE h
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglrun cajp402 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 2
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
DISPLAY "Par�metros Generales"	TO c100   ## Bot�n 1 ccht000
DISPLAY "Configuraci�n" 	TO c200   ## Bot�n 2 ccht001
DISPLAY "Cuentas Deudoras" 	TO c300   ## Bot�n 3 ccht003

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
DISPLAY "Par�metros Generales"	TO c100   ## Bot�n 1  genp100
DISPLAY "Compa��as"	 	TO c200   ## Bot�n 2  genp101
DISPLAY "Localidades"		TO c300   ## Bot�n 3  genp102
DISPLAY "Areas de Negocios" 	TO c400   ## Bot�n 4  genp103
DISPLAY "Grupos de Usuarios"    TO c500   ## Bot�n 5  genp104
DISPLAY "Impresoras"    	TO c600   ## Bot�n 6  genp105
DISPLAY "Bancos Generales"   	TO c700   ## Bot�n 7  genp106
DISPLAY "Cuentas Corrientes"    TO c800   ## Bot�n 8  genp107
DISPLAY "Tarjetas Cr�dito"      TO c900   ## Bot�n 9  genp108
DISPLAY "Entidades Sistema" 	TO c1000  ## Bot�n 10 genp109
DISPLAY "Componentes Sistema"   TO c1100  ## Bot�n 11 genp110
DISPLAY "Monedas"	        TO c1200  ## Bot�n 12 genp111
DISPLAY "Factores Conversi�n"   TO c1300  ## Bot�n 13 genp112
DISPLAY "Control Secuencias" 	TO c1400  ## Bot�n 14 genp113
DISPLAY "Partida Arancelaria" 	TO c1500  ## Bot�n 15 genp114
DISPLAY "Rubros Liquidaci�n" 	TO c1600  ## Bot�n 16 genp115
DISPLAY "Gu�as de Remisi�n" 	TO c1700  ## Bot�n 17 genp116
DISPLAY "Grupos L�neas Ventas" 	TO c1800  ## Bot�n 18 genp117
DISPLAY "Transacciones/M�dulos" TO c1900  ## Bot�n 19 genp118
DISPLAY "Subtipo Transacci�n"   TO c2000  ## Bot�n 20 genp119
DISPLAY "Paises"	        TO c2100  ## Bot�n 21 genp120
DISPLAY "Ciudades"         	TO c2200  ## Bot�n 22 genp121
DISPLAY "Zonas de Venta "       TO c2300  ## Bot�n 23 genp122
DISPLAY "Centros de Costos"     TO c2400  ## Bot�n 24 genp123
DISPLAY "Departamentos"         TO c2500  ## Bot�n 25 genp124
DISPLAY "Cargos" 		TO c2600  ## Bot�n 26 genp125
DISPLAY "Dias Feriados" 	TO c2700  ## Bot�n 27 genp126
DISPLAY "M�dulos/Bases Datos"   TO c2800  ## Bot�n 28 genp127
DISPLAY "Procesos por M�dulos"  TO c2900  ## Bot�n 29 genp128
DISPLAY "Usuarios Modulo/C�a"   TO c3000  ## Bot�n 30 genp129
DISPLAY "Asignaci�n Procesos"   TO c3100  ## Bot�n 31 genp130

LET c = fgl_getkey()

CASE c
	WHEN 1
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp100 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp101 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp102 ', vg_base, ' ', 'GE ', vg_codcia
		RUN ejecuta
	WHEN 4
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp103 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 5
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp104 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp105 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 7
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp106 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 8
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp107 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 9
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp108 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp109 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp110 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 12
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp111 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 13
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp112 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp113 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp114 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 16
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp115 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 17
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp116 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 18
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp117 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 19
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp118 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 20
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp119 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 21
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp120 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 22
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp121 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 24
		DISPLAY 'Boton 23 genp122 Tecla = ', c
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp122 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 25
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp123 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3019
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp124 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3020
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp125 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3021
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp126 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3022
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp127 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 3023
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp128 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3024
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp129 ', vg_base, ' ', 'GE'
		RUN ejecuta
	WHEN 3025
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglrun genp130 ', vg_base, ' ', 'GE', vg_codcia
		RUN ejecuta
	WHEN 0
		CLOSE WINDOW w_menu_configuracion
		CALL funcion_master()
END CASE

END WHILE
END FUNCTION



------------------------- FUNCIONES VARIAS --------------------------

FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
 
