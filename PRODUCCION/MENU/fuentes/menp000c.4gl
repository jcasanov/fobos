--------------------------------------------------------------------------------
-- Titulo           : menp000c.4gl - MENU PRINCIPAL DE FHOBOS
-- Elaboracion      : 10-ago-2001
-- Autor            : RCA
-- Formato Ejecucion: fglgo menp000c base modulo
-- Ultima Correccion: 11-ago-2001
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog 	VARCHAR(50)
DEFINE vm_rows 		ARRAY[1000] OF INTEGER  -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current 	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows 	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE ejecuta		CHAR(100)
--DEFINE fondo		CHAR(25)
DEFINE fondo_pp		CHAR(25)
DEFINE fondo_phobos 	CHAR(25)
DEFINE a		CHAR(25)

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/menp000c.err')
--#CALL fgl_init4js()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
     CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_proceso   = 'menp000'
LET vm_titprog   = 'MENU PRINCIPAL - PHOBOS'
LET fondo_pp     = 'phobos_biger'
LET fondo_phobos = 'phobos_titulo'
--LET fondo        = 'phobos_small'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_menu ARRAY[09] OF RECORD
                opcion  CHAR(20)
        END RECORD
DEFINE cod_cia		LIKE gent002.g02_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE a_c, s_c         SMALLINT
DEFINE a		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE titulo		CHAR(54)

OPEN WINDOW w_menu_principal AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf001 FROM '../forms/menf001'
DISPLAY FORM f_menf001
--------------------------------------------------------------
LET r_menu[1].opcion = 'INVENTARIOS'
LET r_menu[2].opcion = 'TALLERES'
LET r_menu[3].opcion = 'CREDITO Y COBRANZAS'
LET r_menu[4].opcion = 'CONTABILIDAD'
LET r_menu[5].opcion = 'TESORERIA'
LET r_menu[6].opcion = 'CAJA'
LET r_menu[7].opcion = 'ORDENES DE COMPRAS'
LET r_menu[8].opcion = 'GENERALES'
LET r_menu[9].opcion = 'SALIR'
CALL set_count(09)

RUN ' umask 0002'
--------------------------------------------------------------
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu TO r_menu.*
                ON KEY(F2)
                        CALL fl_ayuda_compania_principal() RETURNING cod_cia, 
		cod_local
                        IF cod_cia IS NOT NULL THEN
                                LET vg_codcia = cod_cia
                                LET vg_codloc = cod_local
				CALL fl_lee_compania(vg_codcia)
					RETURNING r_g01.*
				CALL fl_lee_localidad(vg_codcia, vg_codloc)
					RETURNING r_g02.*
				LET titulo    = r_g01.g01_abreviacion CLIPPED,
						" (", r_g02.g02_abreviacion
						CLIPPED, ")"
				DISPLAY titulo AT 1, 1
                                --CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
                        END IF
                ON KEY(RETURN)
                        LET a_c = arr_curr()
                        IF a_c = 10 THEN
                                LET int_flag = 1
                        END IF
                        EXIT DISPLAY
--                BEFORE ROW
--                        LET a_c = arr_curr()
--                        LET s_c = scr_line()
--                        IF a_c > 12 THEN
--                                LET int_flag = 2
--                                EXIT DISPLAY
--                        END IF
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c = arr_curr()
                IF a_c = 09 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion(a_c)
                CALL set_count(09)
        END IF
END WHILE
                                                                                
END FUNCTION

--------------------------------------------------------------
 
FUNCTION ejecuta_opcion(i)
DEFINE i                SMALLINT
                                                                                
CASE
        WHEN i = 1
                CALL menu_repuestos()
        WHEN i = 2
                CALL menu_talleres()
        WHEN i = 3
                CALL menu_cobranzas()
        WHEN i = 4
                CALL menu_contabilidad()
        WHEN i = 5
                CALL menu_tesoreria()
        WHEN i = 6
                CALL menu_caja()
        WHEN i = 7
                CALL menu_compras()
        WHEN i = 9
                EXIT PROGRAM
END CASE
                                                                                
END FUNCTION


------------------------ R E P U E S T O S -----------------------
FUNCTION menu_repuestos()
DEFINE r_menu_rep ARRAY[6] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_repuestos AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf002 FROM '../forms/menf002'
DISPLAY FORM f_menf002

LET r_menu_rep[1].opcion   = 'CONFIGURACIONES GENERALES'
LET r_menu_rep[2].opcion   = 'TRANSACCIONES'
LET r_menu_rep[3].opcion   = 'PEDIDOS'
LET r_menu_rep[4].opcion   = 'CONSULTAS'
LET r_menu_rep[5].opcion   = 'REPORTES'
LET r_menu_rep[6].opcion   = 'SALIR'


CALL set_count(6)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_rep TO r_menu_rep.*
                ON KEY(INTERRUPT)
        		LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
        		LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                CALL ejecuta_opcion_repuestos(a_c_2)
                CALL set_count(6)
		IF a_c_2 = 6 THEN
			EXIT WHILE
		END IF

        END IF
END WHILE
CLOSE WINDOW w_menu_repuestos
                                                                                
END FUNCTION
-----------------------------------------------------------

FUNCTION ejecuta_opcion_repuestos(r)
DEFINE r	SMALLINT

CASE r
WHEN 1 
    	CALL menu_configuracion_rep1()
WHEN 2 
  	CALL menu_transacciones_rep1()
WHEN 3 
	CALL menu_pedidos_rep()
WHEN 4 
	CALL menu_consultas_rep()
WHEN 5 
	CALL menu_reportes_rep()
END CASE

END FUNCTION
 


FUNCTION menu_configuracion_rep1() 
DEFINE r_menu_rep1 ARRAY[18] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_repuestos1 AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf003 FROM '../forms/menf003'
DISPLAY FORM f_menf003

LET r_menu_rep1[1].opcion	= "Compañias" 	
LET r_menu_rep1[2].opcion	= "Vendedores" 	
LET r_menu_rep1[3].opcion	= "Bodegas"    
LET r_menu_rep1[4].opcion	= "Líneas"   
LET r_menu_rep1[5].opcion	= "Indice Rotación" 
LET r_menu_rep1[6].opcion	= "Unidades Medida" 
LET r_menu_rep1[7].opcion	= "Tipos de Items" 
LET r_menu_rep1[8].opcion	= "Descuentos" 	
LET r_menu_rep1[9].opcion	= "Equivalencias"
LET r_menu_rep1[10].opcion	= "Sublíneas de Ventas" 
LET r_menu_rep1[11].opcion	= "Grupos de Ventas" 
LET r_menu_rep1[12].opcion	= "Clases de Ventas"
LET r_menu_rep1[13].opcion	= "Marcas de Ventas"
LET r_menu_rep1[14].opcion	= "Códigos Eléctricos" 
LET r_menu_rep1[15].opcion	= "Colores" 	
LET r_menu_rep1[16].opcion	= "Series" 
LET r_menu_rep1[17].opcion	= "Factor Utilidades" 
LET r_menu_rep1[18].opcion	= "SALIR" 	

CALL set_count(18)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_rep1 TO r_menu_rep1.*
                ON KEY(INTERRUPT)
        		LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
        		LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
		IF a_c_2 = 18 THEN
			EXIT WHILE
		END IF
                CALL ejecuta_configuracion_rep2(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_repuestos1
                                                                                
END FUNCTION
-----------------------------------------------------------

FUNCTION ejecuta_configuracion_rep2(c)
DEFINE c        SMALLINT

CASE
WHEN c = 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp100 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp101 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp102 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp103')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp103 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp104')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp104 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp105')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp105 ', vg_base, ' ', 'RE'
	RUN ejecuta
WHEN c = 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp106')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp106 ', vg_base, ' ', 'RE'
	RUN ejecuta
WHEN c = 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp107')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp107 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp109')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp109 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 10
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp110')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp110 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 11
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp111')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp111 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 12
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp112')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp112 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 13
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp113')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp113 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 14
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp114')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp114 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 15
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp115')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp115 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN c = 16
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp116')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp116 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN c = 17
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp117')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp117 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION
 


FUNCTION menu_transacciones_rep1()
DEFINE d		SMALLINT
DEFINE r_menu_rep2	ARRAY[23] OF RECORD
				opcion  CHAR(40)
			END RECORD
DEFINE a_c_2, s_c_2     SMALLINT
DEFINE limite		SMALLINT

OPEN WINDOW w_menu_repuestos2 AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf004 FROM '../forms/menf004'
DISPLAY FORM f_menf004

LET limite                      = 23
LET r_menu_rep2[1].opcion	= "Items"     		
--LET r_menu_rep2[2].opcion	= "Sustituciones"     	
--LET r_menu_rep2[3].opcion	= "Ventas Perdidas"      
--LET r_menu_rep2[4].opcion	= "Actualización V.P."  
LET r_menu_rep2[2].opcion	= "Pre-Venta" 		
LET r_menu_rep2[3].opcion	= "Aprobación Crédito" 
LET r_menu_rep2[4].opcion	= "Ajustes Existencias" 
LET r_menu_rep2[5].opcion	= "Ajustes Costos"  	
LET r_menu_rep2[6].opcion	= "Compra Local"  
--LET r_menu_rep2[10].opcion	= "Ventas al Taller" 
LET r_menu_rep2[7].opcion	= "Transferencias"  	
LET r_menu_rep2[8].opcion	= "Devolución Facturas"  	
LET r_menu_rep2[9].opcion	= "Dev. Compra Local"  
--LET r_menu_rep2[14].opcion	= "Dev. Ventas Taller" 
LET r_menu_rep2[10].opcion	= "Proformas"  		
LET r_menu_rep2[11].opcion	= "Mantenimiento Precios"	
LET r_menu_rep2[12].opcion	= "Actualización Precios"	
LET r_menu_rep2[13].opcion	= "Aprobación Pre-Ventas"
--LET r_menu_rep2[16].opcion	= "Reclasificación Items"
--LET r_menu_rep2[20].opcion	= "Generar Inventario" 
--LET r_menu_rep2[21].opcion	= "Conteo Inventario"
--LET r_menu_rep2[22].opcion	= "Cierre Inventario" 
LET r_menu_rep2[14].opcion	= "Cierre Mensual" 
LET r_menu_rep2[15].opcion	= "Ordenes de Despacho" 	
LET r_menu_rep2[16].opcion	= "Transmisión Transf." 		
LET r_menu_rep2[17].opcion	= "Refacturación" 		
--LET r_menu_rep2[18].opcion	= "Inventario Fis. 2003"
LET r_menu_rep2[18].opcion	= "Inventario Físico"
LET r_menu_rep2[19].opcion	= "Pedido Prov. Locales"
LET r_menu_rep2[20].opcion	= "Traspaso a La Prensa" 		
LET r_menu_rep2[21].opcion	= "Guías de Remisión"
LET r_menu_rep2[22].opcion      = "Corrección GR SRI"
LET r_menu_rep2[23].opcion	= "SALIR" 		

CALL set_count(limite)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_rep2 TO r_menu_rep2.*
                ON KEY(INTERRUPT)
        		LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
        		LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
		IF a_c_2 = limite THEN
			EXIT WHILE
		END IF
                CALL ejecuta_transacciones_rep2(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_repuestos2
                                                                                
END FUNCTION
--------------------------------------------


FUNCTION ejecuta_transacciones_rep2(d)
DEFINE d        SMALLINT


CASE
WHEN d = 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp108')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp108 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
{--
WHEN d = 2
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp200 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN d = 3
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp201 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 4
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp202 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
--}
WHEN d = 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp209')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp209 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp210')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp210 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp212')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp212 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp213')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp213 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp214')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp214 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
{--
WHEN d = 10
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp215 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
--}
WHEN d = 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp216')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp216 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp217')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp217 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp218')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp218 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
{--
WHEN d = 14
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp219 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
--}
WHEN d = 10
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp220')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp220 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 11
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp221')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp221 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN d = 12
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp222')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp222 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN d = 13
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp223')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp223 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
{--
WHEN d = 16
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp224 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 20
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp225 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 21
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp226 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 22
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp227 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
--}
WHEN d = 14
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp229')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp229 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN d = 15
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp231')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp231 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN d = 16
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp666')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp666 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN d = 17
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp237')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp237 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
{--
WHEN d = 18
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp238')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp238 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
--}
WHEN d = 18
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp239')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp239 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN d = 19
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp240')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp240 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN d = 20
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp667')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp667 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN d = 21
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp241')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp241 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN d = 22
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp243')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp243 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 0
	CALL menu_repuestos()
END CASE

END FUNCTION



FUNCTION menu_pedidos_rep()
DEFINE r_menu_rep3 ARRAY[06] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_repuestos3 AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf005 FROM '../forms/menf005'
DISPLAY FORM f_menf005

LET r_menu_rep3[1].opcion	= "Pedidos Sugeridos"  
--LET r_menu_rep3[2].opcion	= "Mantenimiento"  
LET r_menu_rep3[2].opcion	= "Confirmación Pedidos" 	
LET r_menu_rep3[3].opcion	= "Recepción Pedidos" 
LET r_menu_rep3[4].opcion	= "Liquidación Pedidos"
LET r_menu_rep3[5].opcion	= "Cierre Pedidos" 
LET r_menu_rep3[6].opcion	= "SALIR" 	

CALL set_count(06)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_rep3 TO r_menu_rep3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 6 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_pedidos_rep(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_repuestos3
                                                                                
END FUNCTION


--------------------------------------------------------------

FUNCTION ejecuta_pedidos_rep(c)
DEFINE c        SMALLINT
                                                                                
CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp203')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp203 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
{--
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp204')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp204 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
--}
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp205')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp205 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp206')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp206 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp207')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp207 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp208')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp208 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION



FUNCTION menu_consultas_rep()
DEFINE r_menu_rep4	ARRAY[19] OF RECORD
				opcion  CHAR(40)
		        END RECORD
DEFINE a_c_2, s_c_2	SMALLINT


OPEN WINDOW w_menu_repuestos4 AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf006 FROM '../forms/menf006'
DISPLAY FORM f_menf006

LET r_menu_rep4[1].opcion	= "Items" 	
LET r_menu_rep4[2].opcion	= "Utilidad Facturas" 
LET r_menu_rep4[3].opcion	= "Pedidos - Backorders"
LET r_menu_rep4[4].opcion	= "Liquidaciones" 
LET r_menu_rep4[5].opcion	= "Proformas"     
LET r_menu_rep4[6].opcion	= "Kardex de Items"
LET r_menu_rep4[7].opcion	= "Estadística Vendedor" 
LET r_menu_rep4[8].opcion	= "Estadística Facturas" 
LET r_menu_rep4[9].opcion	= "Análisis Ventas Item"
LET r_menu_rep4[10].opcion	= "Det. Transacciónes" 
LET r_menu_rep4[11].opcion	= "Stock sin Ventas"  
LET r_menu_rep4[12].opcion	= "Cons. Ventas Clientes"
LET r_menu_rep4[13].opcion	= "Ordenes de Despacho" 
LET r_menu_rep4[14].opcion	= "Inventario Físico"
LET r_menu_rep4[15].opcion	= "Items Pendientes"   	
LET r_menu_rep4[16].opcion	= "Transferencias"
LET r_menu_rep4[17].opcion	= "Refacturación"
LET r_menu_rep4[18].opcion	= "Guías de Remisión"
LET r_menu_rep4[19].opcion	= "SALIR"

CALL set_count(19)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_rep4 TO r_menu_rep4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 19 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_rep(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_repuestos4
                                                                                
END FUNCTION



-------------------------------------------------------------
FUNCTION ejecuta_consultas_rep(c)
DEFINE c        SMALLINT
                                                                                
CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp300')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp300 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp301')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp301 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp302')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp302 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp303')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp303 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp306')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglgo repp306 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp307')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp307 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp304')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp304 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp305')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp305 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp310')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp310 ', vg_base, ' ', 'RE', vg_codcia
	RUN ejecuta
WHEN 10
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp309')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp309 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 11
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp311')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp311 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 12
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp312')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp312 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 13
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp313')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp313 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 14
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp317')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp317 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 15
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp318')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp318 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 16
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp319')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp319 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 17
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp320')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp320 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 18
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'RE',
						'repp321')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp321 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc
	RUN ejecuta
END CASE

END FUNCTION



FUNCTION menu_reportes_rep()
DEFINE r_menu_rep5 ARRAY[11] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_repuestos5 AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf009 FROM '../forms/menf009'
DISPLAY FORM f_menf009

LET r_menu_rep5[1].opcion	= "Facturas/Devolucion"
--LET r_menu_rep5[2].opcion	= "Resúmen de Ventas" 
--LET r_menu_rep5[3].opcion	= "Resúmen Inventario" 
LET r_menu_rep5[2].opcion	= "Existencias"
LET r_menu_rep5[3].opcion	= "Lista de Precios"
--LET r_menu_rep5[6].opcion	= "Pedido Sugerido"
LET r_menu_rep5[4].opcion	= "Pedido Emergencia"
LET r_menu_rep5[5].opcion	= "Impresión Recepción"
--LET r_menu_rep5[6].opcion	= "Liquidación"
--LET r_menu_rep5[10].opcion	= "Comprob. Importación"
--LET r_menu_rep5[11].opcion	= "Proformas"
LET r_menu_rep5[6].opcion	= "Márgenes de Utilidad"
--LET r_menu_rep5[13].opcion	= "Movimientos de Items"
--LET r_menu_rep5[14].opcion	= "Control Inv. Físico"
--LET r_menu_rep5[15].opcion	= "Diferencias"
LET r_menu_rep5[7].opcion	= "Transacciones"
LET r_menu_rep5[8].opcion	= "Nota de Pedido"
LET r_menu_rep5[9].opcion	= "Ubicación de Items"
LET r_menu_rep5[10].opcion	= "Guías de Remisión"
LET r_menu_rep5[11].opcion	= "SALIR"

CALL set_count(11)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_rep5 TO r_menu_rep5.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 11 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_rep(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_repuestos5
                                                                                
END FUNCTION


-------------------------------------------------------------

FUNCTION ejecuta_reportes_rep(c)
DEFINE c        SMALLINT
                                                                                
CASE c
	WHEN 1
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp400')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp400 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	{--
	WHEN 2
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp401 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	WHEN 3
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp402 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	--}
	WHEN 2
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp403')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp403 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 3
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp404')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp404 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	{--
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp405 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	--}
	WHEN 4
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp406')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp406 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
	WHEN 5
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp407')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp407 ', vg_base, ' ', 'RE', vg_codcia
		RUN ejecuta
	{--
	WHEN 6
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp408 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp409 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 11
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp419 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 6
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp420')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp420 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	{--
	WHEN 13
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp421 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 14
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp425 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 15
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp423 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	--}
	WHEN 7
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp430')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp430 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 8
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp426')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp426 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 9
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp427')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp427 ', vg_base, ' ', 'RE', vg_codcia, vg_codloc
		RUN ejecuta
	WHEN 10
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							'RE', 'repp435')
		THEN
			EXIT CASE
		END IF
		LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', vg_separador, 'fuentes', vg_separador, '; fglgo repp435 ', vg_base, ' ', 'RE', vg_codcia, ' ', vg_codloc
		RUN ejecuta
END CASE

END FUNCTION


 
------------------------ T A L L E R E S  -----------------------
FUNCTION menu_talleres()

DEFINE r_menu_tal ARRAY[5] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT     

OPEN WINDOW w_menu_talleres AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf020 FROM '../forms/menf020'
DISPLAY FORM f_menf020

LET r_menu_tal[1].opcion	= "Configuraciones"
LET r_menu_tal[2].opcion	= "Transacciones" 
LET r_menu_tal[3].opcion	= "Consultas"    
LET r_menu_tal[4].opcion	= "Reportes"    
LET r_menu_tal[5].opcion	= "SALIR"    

CALL set_count(5)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tal TO r_menu_tal.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion_taller(a_c_2)
                CALL set_count(5)
        END IF
END WHILE 

CLOSE WINDOW w_menu_talleres

END FUNCTION
-------------------------------------------------------

FUNCTION ejecuta_opcion_taller(r)
DEFINE r        SMALLINT

CASE r    

WHEN 1 
    	CALL menu_configuracion_tal()
WHEN 2 
	CALL menu_transacciones_tal()
WHEN 3 
	CALL menu_consultas_tal()
WHEN 4 
	CALL menu_reportes_tal()
END CASE

END FUNCTION



FUNCTION menu_configuracion_tal()
DEFINE r_menu_tal1 ARRAY[09] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT    

OPEN WINDOW w_menu_configuracion_tal AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf021 FROM '../forms/menf021'
DISPLAY FORM f_menf021

LET r_menu_tal1[1].opcion	= "Compañías"  
LET r_menu_tal1[2].opcion	= "Marcas"  
LET r_menu_tal1[3].opcion	= "Secciones"  
LET r_menu_tal1[4].opcion	= "Técnicos"  
LET r_menu_tal1[5].opcion	= "Modelos"  
LET r_menu_tal1[6].opcion	= "Tipos O. Trabajo"   
LET r_menu_tal1[7].opcion	= "Subtipos O. Trabajo" 
LET r_menu_tal1[8].opcion	= "Tareas" 	
LET r_menu_tal1[9].opcion	= "SALIR" 

CALL set_count(9)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tal1 TO r_menu_tal1.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 9 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_configuracion_tal(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_configuracion_tal

END FUNCTION
------------------------------------------------------------

FUNCTION ejecuta_configuracion_tal(c)
DEFINE c        SMALLINT

CASE c
WHEN 1 
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp100 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp101 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp102 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp103')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp103 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp104')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp104 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp105')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp105 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp106')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp106 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp107')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp107 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION


FUNCTION menu_transacciones_tal()
DEFINE r_menu_tal2 ARRAY[12] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT  

OPEN WINDOW w_menu_transacciones_tal AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf022 FROM '../forms/menf022'
DISPLAY FORM f_menf022

LET r_menu_tal2[1].opcion       = "Presupuestos"
LET r_menu_tal2[2].opcion       = "Tareas / Presupuesto"
LET r_menu_tal2[3].opcion       = "Proformas"
LET r_menu_tal2[4].opcion       = "Ordenes de Trabajo"
LET r_menu_tal2[5].opcion       = "Gastos de viaje"
LET r_menu_tal2[6].opcion       = "Tareas / O. Trabajo"
LET r_menu_tal2[7].opcion       = "Cierre O. Trabajo"
LET r_menu_tal2[8].opcion       = "Reapertura O. Trabajo"
LET r_menu_tal2[9].opcion       = "Forma de Pago"
LET r_menu_tal2[10].opcion      = "Anulación Facturas"
LET r_menu_tal2[11].opcion      = "Refacturación"
LET r_menu_tal2[12].opcion      = "Salir"

CALL set_count(12)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tal2 TO r_menu_tal2.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 12 THEN
                        EXIT WHILE
	END IF
                CALL ejecuta_transacciones_tal(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_transacciones_tal   

END FUNCTION



FUNCTION ejecuta_transacciones_tal(c)
DEFINE c        SMALLINT

CASE c   
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp201')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp201 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp202')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp202 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp213')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp213 ', vg_base, ' ', 'TA', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp204')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp204 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp212')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp212 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp205')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp205 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp206')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp206 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp207')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp207 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp208')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp208 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 10
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp211')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp211 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 11
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp214')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp214 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION


 
FUNCTION menu_consultas_tal()
DEFINE r_menu_tal3	ARRAY[05] OF RECORD
		                opcion  CHAR(40)
		        END RECORD
DEFINE a_c_2, s_c_2	SMALLINT     

OPEN WINDOW w_menu_consultas_tal AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf023 FROM '../forms/menf023'
DISPLAY FORM f_menf023

LET r_menu_tal3[1].opcion       = "Ordenes de Trabajo"
LET r_menu_tal3[2].opcion       = "Estadísticas Facturas"
LET r_menu_tal3[3].opcion       = "Técnicos / Asesores"
LET r_menu_tal3[4].opcion       = "Refacturación"
LET r_menu_tal3[5].opcion       = "Salir"

CALL set_count(05)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tal3 TO r_menu_tal3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_tal(a_c_2)
        END IF     
END WHILE
CLOSE WINDOW w_menu_consultas_tal

END FUNCTION    



FUNCTION ejecuta_consultas_tal(c)
DEFINE c        SMALLINT

CASE c                 
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp300')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp300 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp310')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp310 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp311')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp311 ', vg_base, ' ', 'TA', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp312')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp312 ', vg_base, ' ', 'TA', vg_codcia, ' ', vg_codloc
	RUN ejecuta
END CASE

END FUNCTION



FUNCTION menu_reportes_tal()

DEFINE r_menu_tal4 ARRAY[03] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT     

OPEN WINDOW w_menu_reportes_tal AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf024 FROM '../forms/menf024'
DISPLAY FORM f_menf024

LET r_menu_tal4[1].opcion       = "Valores Facturación"
--LET r_menu_tal4[2].opcion       = "Valores Presupuestos"
LET r_menu_tal4[2].opcion       = "Valores Gastos por O.T."
LET r_menu_tal4[3].opcion       = "Salir"

CALL set_count(03)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tal4 TO r_menu_tal4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 3 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_tal(a_c_2)  
        END IF
END WHILE
CLOSE WINDOW w_menu_reportes_tal

END FUNCTION                         



FUNCTION ejecuta_reportes_tal(c)
DEFINE c        SMALLINT

CASE c         
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp400')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp400 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
{--
WHEN 2
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp401 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
--}
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TA',
						'talp405')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TALLER', vg_separador, 'fuentes', vg_separador, '; fglgo talp405 ', vg_base, ' ', 'TA', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION




------------------------ C O B R A N Z A S  -----------------------
FUNCTION menu_cobranzas()

DEFINE r_menu_cob ARRAY[5] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT       

OPEN WINDOW w_menu_cob AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf030 FROM '../forms/menf030'
DISPLAY FORM f_menf030

LET r_menu_cob[1].opcion        = "CONFIGURACIONES"
LET r_menu_cob[2].opcion        = "TRANSACCIONES"
LET r_menu_cob[3].opcion        = "CONSULTAS"
LET r_menu_cob[4].opcion        = "REPORTES"
LET r_menu_cob[5].opcion        = "SALIR"

CALL set_count(5)
WHILE TRUE             
 LET int_flag = 0
        DISPLAY ARRAY r_menu_cob TO r_menu_cob.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion_cob(a_c_2)
                CALL set_count(5)
        END IF
END WHILE                           
CLOSE WINDOW w_menu_cob

END FUNCTION 



FUNCTION ejecuta_opcion_cob(r)
DEFINE r        SMALLINT

CASE r       
WHEN 1 
    	CALL menu_configuracion_cob()
WHEN 2 
	CALL menu_transacciones_cob()
WHEN 3 
	CALL menu_consultas_cob()
WHEN 4 
	CALL menu_reportes_cob()
END CASE

END FUNCTION



FUNCTION menu_configuracion_cob()

DEFINE r_menu_cob1 ARRAY[07] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT   

OPEN WINDOW w_menu_configuracion_cob AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf031 FROM '../forms/menf031'
DISPLAY FORM f_menf031

LET r_menu_cob1[1].opcion       = "Compañías"
LET r_menu_cob1[2].opcion       = "Clientes Cía. / Loc."
LET r_menu_cob1[3].opcion       = "Doc. / Transacciones"
LET r_menu_cob1[4].opcion       = "Ejecutivos Cuentas"
LET r_menu_cob1[5].opcion       = "Zonas de Cobro"
LET r_menu_cob1[6].opcion       = "Plazos Créditos"
LET r_menu_cob1[7].opcion       = "SALIR"

CALL set_count(7)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cob1 TO r_menu_cob1.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 7 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_configuracion_cob(a_c_2)
        END IF   
END WHILE
CLOSE WINDOW w_menu_configuracion_cob

END FUNCTION                        



FUNCTION ejecuta_configuracion_cob(c)
DEFINE c        SMALLINT

CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp100 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp101 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp102 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp103')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp103 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp104')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp104 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp105')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp105 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION



FUNCTION menu_transacciones_cob()
DEFINE r_menu_cob2 ARRAY[13] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT 

OPEN WINDOW w_menu_transacciones_cob AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf032 FROM '../forms/menf032'
DISPLAY FORM f_menf032

LET r_menu_cob2[1].opcion       = "Documentos Deudores"
LET r_menu_cob2[2].opcion       = "Documentos a Favor"
LET r_menu_cob2[3].opcion       = "Ingresos Ajustes"
LET r_menu_cob2[4].opcion       = "Aplicación NC / PA"
LET r_menu_cob2[5].opcion       = "Autorización Cobro"
LET r_menu_cob2[6].opcion       = "Autorización P.A."
LET r_menu_cob2[7].opcion       = "Cheques Postfechados"
LET r_menu_cob2[8].opcion       = "Cheques Protestados"
LET r_menu_cob2[9].opcion       = "Cierre Mensual"
LET r_menu_cob2[10].opcion      = "Correccion SRI N/D"
LET r_menu_cob2[11].opcion      = "Correccion SRI N/C"
LET r_menu_cob2[12].opcion      = "Digitación Retención"
LET r_menu_cob2[13].opcion      = "SALIR"

CALL set_count(13)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cob2 TO r_menu_cob2.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 13 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_transacciones_cob(a_c_2)
        END IF     
END WHILE
CLOSE WINDOW w_menu_transacciones_cob

END FUNCTION
-----------------------------------------------------------------


FUNCTION ejecuta_transacciones_cob(c)
DEFINE c        SMALLINT

CASE c                     
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp200')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp200 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp201')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp201 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp202')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp202 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp203')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp203 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp204')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp204 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp205')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp205 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp206')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp206 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp207')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp207 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp208')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp208 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 10
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp209')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp209 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 11
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp210')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp210 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 12
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp211')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp211 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION



--------------------------------------------------------------------
FUNCTION menu_consultas_cob()
DEFINE r_menu_cob3 ARRAY[9] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT 

OPEN WINDOW w_menu_consultas_cob AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf033 FROM '../forms/menf033'
DISPLAY FORM f_menf033
LET r_menu_cob3[1].opcion =  "Cheques Postfechados"
LET r_menu_cob3[2].opcion =  "Cheques Protestados"
LET r_menu_cob3[3].opcion =  "Estado de Cuentas"
LET r_menu_cob3[4].opcion =  "Anl. Cartera Clientes"
LET r_menu_cob3[5].opcion =  "Anl. Cartera Detalle"
LET r_menu_cob3[6].opcion =  "Acumulados Cartera"
LET r_menu_cob3[7].opcion =  "Anl. Cobrar vs Pagar"
LET r_menu_cob3[8].opcion =  "Valores a Favor"
LET r_menu_cob3[9].opcion =  "SALIR"

CALL set_count(09)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cob3 TO r_menu_cob3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 9 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_cob(a_c_2)
        END IF     
END WHILE
CLOSE WINDOW w_menu_consultas_cob

END FUNCTION



FUNCTION ejecuta_consultas_cob(g)
DEFINE g		SMALLINT

CASE g
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp303')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp303 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp304')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp304 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp305')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp305 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp306')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp306 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp307')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp307 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp308')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp308 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp309')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp309 ', vg_base, ' ', 'CO', vg_codcia
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp300')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp300 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION




---------------------------------------------------------------
FUNCTION menu_reportes_cob()
DEFINE r_menu_cob4 ARRAY[10] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT        

OPEN WINDOW w_menu_reportes_cob AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf034 FROM '../forms/menf034'
DISPLAY FORM f_menf034

LET r_menu_cob4[1].opcion       = "Detalle Cartera"
LET r_menu_cob4[2].opcion       = "Resumen Cartera"
LET r_menu_cob4[3].opcion       = "List. Transacciones"
LET r_menu_cob4[4].opcion       = "Cheques Postfechados"
LET r_menu_cob4[5].opcion       = "Estado de Cuentas"
LET r_menu_cob4[6].opcion       = "Cheques Protestados"
LET r_menu_cob4[7].opcion       = "List. Retenciones"
LET r_menu_cob4[8].opcion       = "Documentos a Favor"
LET r_menu_cob4[9].opcion       = "Documentos Deudores"
LET r_menu_cob4[10].opcion      = "SALIR"

CALL set_count(10)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cob4 TO r_menu_cob4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 10 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_cob(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_reportes_cob 

END FUNCTION

------------------------------------------------------------

FUNCTION ejecuta_reportes_cob(c)
DEFINE c        SMALLINT

CASE c                       
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp400')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp400 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp401')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp401 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp413')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp413 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp408')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp408 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp409')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp409 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp410')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp410 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp416')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp416 ', vg_base, ' ', 'CO', vg_codcia, ' ', vg_codloc
 	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp411')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp411 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
 	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO',
						'cxcp412')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', vg_separador, 'fuentes', vg_separador, '; fglgo cxcp412 ', vg_base, ' ', 'CO', vg_codcia, vg_codloc
 	RUN ejecuta
END CASE

END FUNCTION



 
------------------------ T E S O R E R I A  -----------------------
FUNCTION menu_tesoreria()

DEFINE r_menu_tes ARRAY[5] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_tesoreria AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf050 FROM '../forms/menf050'
DISPLAY FORM f_menf050

LET r_menu_tes[1].opcion        = "CONFIGURACIONES"
LET r_menu_tes[2].opcion        = "TRANSACCIONES"
LET r_menu_tes[3].opcion        = "CONSULTAS"
LET r_menu_tes[4].opcion        = "REPORTES"
LET r_menu_tes[5].opcion        = "SALIR"

CALL set_count(5)                    
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tes TO r_menu_tes.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion_tesoreria(a_c_2)
                CALL set_count(5)
        END IF
END WHILE         
CLOSE WINDOW w_menu_tesoreria

END FUNCTION




-------------------------------------------------------------------
FUNCTION ejecuta_opcion_tesoreria(r)
DEFINE r        SMALLINT

CASE r         
WHEN 1 
    	CALL menu_configuracion_tes()
WHEN 2 
	CALL menu_transacciones_tes()
WHEN 3 
	CALL menu_consultas_tes()
WHEN 4 
	CALL menu_reportes_tes()
END CASE

END FUNCTION



-----------------------------------------------------------------
FUNCTION menu_configuracion_tes()

DEFINE r_menu_tes1 ARRAY[04] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_configuracion_tes AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf051 FROM '../forms/menf051'
DISPLAY FORM f_menf051

LET r_menu_tes1[1].opcion       = "Compañías"
LET r_menu_tes1[2].opcion       = "Proveedores Cía/Loc"
LET r_menu_tes1[3].opcion       = "Doc./Transacciones"
LET r_menu_tes1[4].opcion       = "SALIR"

CALL set_count(4)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tes1 TO r_menu_tes1.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 4 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_configuracion_tes(a_c_2)
        END IF
END WHILE    
CLOSE WINDOW w_menu_configuracion_tes

END FUNCTION



------------------------------------------------------
FUNCTION ejecuta_configuracion_tes(c)
DEFINE c        SMALLINT

CASE c                      
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp100 ', vg_base, ' ', 'TE', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp101 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp102 ', vg_base, ' ', 'TE', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION




--------------------------------------------------------------------
FUNCTION menu_transacciones_tes()

DEFINE r_menu_tes2 ARRAY[10] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_transacciones_tes AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf052 FROM '../forms/menf052'
DISPLAY FORM f_menf052

LET r_menu_tes2[1].opcion       = "Documentos Deudores"
LET r_menu_tes2[2].opcion       = "Documentos a Favor"
LET r_menu_tes2[3].opcion       = "Ingreso Ajustes"
LET r_menu_tes2[4].opcion       = "Aplicación NC / PA"
LET r_menu_tes2[5].opcion       = "Aut. Pago Facturas"
LET r_menu_tes2[6].opcion       = "Aut. Pago Anticipado"
LET r_menu_tes2[7].opcion       = "Cheques Orden Pago"
LET r_menu_tes2[8].opcion       = "Digitación Retención"
LET r_menu_tes2[9].opcion       = "Cierre Mensual"
LET r_menu_tes2[10].opcion      = "SALIR"

CALL set_count(10)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tes2 TO r_menu_tes2.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 10 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_transacciones_tes(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_transacciones_tes         
END FUNCTION

-----------------------------------------------------------------
FUNCTION ejecuta_transacciones_tes(c)
DEFINE c        SMALLINT

CASE c               
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp200')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp200 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp201')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp201 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp202')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp202 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp203')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp203 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp204')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp204 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp205')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp205 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp206')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp206 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp207')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp207 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp208')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp208 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION




-----------------------------------------------------------------
FUNCTION menu_consultas_tes()

DEFINE r_menu_tes3 ARRAY[07] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT 

OPEN WINDOW w_menu_consultas_tes AT 4,2 WITH 20 ROWS,78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf053 FROM '../forms/menf053'
DISPLAY FORM f_menf053

LET r_menu_tes3[1].opcion       = "Estado Cuentas Prov."
LET r_menu_tes3[2].opcion       = "Anl. Cartera Prov."
LET r_menu_tes3[3].opcion       = "Anl. Detalle Cartera"
LET r_menu_tes3[4].opcion       = "Acumulados Cartera"
LET r_menu_tes3[5].opcion       = "Retenciones Proveedor"
LET r_menu_tes3[6].opcion       = "Valores a Favor"
LET r_menu_tes3[7].opcion       = "SALIR"

CALL set_count(07)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tes3 TO r_menu_tes3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 7 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_tes(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_consultas_tes

END FUNCTION




------------------------------------------------------------
FUNCTION ejecuta_consultas_tes(c)
DEFINE c        SMALLINT

CASE c                 
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp300')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp300 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp301')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp301 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp302')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp302 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp303')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp303 ', vg_base, ' ', 'TE', vg_codcia
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp304')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp304 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp305')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp305 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION




------------------------------------------------------------------
FUNCTION menu_reportes_tes()

DEFINE r_menu_tes4 ARRAY[08] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT 

OPEN WINDOW w_menu_reportes_tes AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf054 FROM '../forms/menf054'
DISPLAY FORM f_menf054

LET r_menu_tes4[1].opcion       = "Detalle Cartera" 
LET r_menu_tes4[2].opcion       = "Resúmen Cartera" 
LET r_menu_tes4[3].opcion       = "List. Transacciones" 
LET r_menu_tes4[4].opcion       = "Estado de Cuentas" 
LET r_menu_tes4[5].opcion       = "Listado Retenciones" 
LET r_menu_tes4[6].opcion       = "Documentos a Favor" 
LET r_menu_tes4[7].opcion       = "Documentos Deudores" 
LET r_menu_tes4[8].opcion       = "SALIR" 

CALL set_count(08)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_tes4 TO r_menu_tes4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 8 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_tes(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_reportes_tes

END FUNCTION




------------------------------------------------------------
FUNCTION ejecuta_reportes_tes(c)
DEFINE c        SMALLINT

CASE c                     
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp400')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp400 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp401')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp401 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp408')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp408 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp407')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp407 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp410')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp410 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc, ' > cxpp410.txt'
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp411')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp411 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'TE',
						'cxpp412')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA', vg_separador, 'fuentes', vg_separador, '; fglgo cxpp412 ', vg_base, ' ', 'TE', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION
 


------------------------ C O N T A B I L I D A D  -----------------------

FUNCTION menu_contabilidad()

DEFINE r_menu_cont ARRAY[5] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT 

OPEN WINDOW w_menu_contabilidad AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf040 FROM '../forms/menf040'
DISPLAY FORM f_menf040

LET r_menu_cont[1].opcion        = "CONFIGURACIONES"
LET r_menu_cont[2].opcion        = "TRANSACCIONES"
LET r_menu_cont[3].opcion        = "CONSULTAS"
LET r_menu_cont[4].opcion        = "REPORTES"
LET r_menu_cont[5].opcion        = "SALIR"

CALL set_count(5)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cont TO r_menu_cont.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion_contabilidad(a_c_2)
                CALL set_count(5)
        END IF
END WHILE                
CLOSE WINDOW w_menu_contabilidad
END FUNCTION

-------------------------------------------------------------------

FUNCTION ejecuta_opcion_contabilidad(r)
DEFINE r        SMALLINT

CASE r                       
WHEN 1 
    	CALL menu_configuracion_con()
WHEN 2 
	CALL menu_transacciones_con()
WHEN 3 
	CALL menu_consultas_con()
WHEN 4 
	CALL menu_reportes_con()
END CASE

END FUNCTION


-------------------------------------------------------------
FUNCTION menu_configuracion_con()

DEFINE r_menu_cont1 ARRAY[10] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT      


OPEN WINDOW w_menu_configuracion_cont AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf041 FROM '../forms/menf041'
DISPLAY FORM f_menf041

LET r_menu_cont1[1].opcion       = "Compañías"
LET r_menu_cont1[2].opcion       = "Niveles Plan Cuentas"
LET r_menu_cont1[3].opcion       = "Grupos Cuentas"
LET r_menu_cont1[4].opcion       = "Tipos Comprobantes"
LET r_menu_cont1[5].opcion       = "Subtipos Comprobantes"
LET r_menu_cont1[6].opcion       = "Tipos Doc. Fuentes"
LET r_menu_cont1[7].opcion       = "Mantenimientos Cuentas"
LET r_menu_cont1[8].opcion       = "Distribución Cuentas"
LET r_menu_cont1[9].opcion       = "Filtros / Análisis"
LET r_menu_cont1[10].opcion      = "SALIR"

CALL set_count(10)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cont1 TO r_menu_cont1.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 10 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_configuracion_cont(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_configuracion_cont
END FUNCTION






------------------------------------------------------

FUNCTION ejecuta_configuracion_cont(c)
DEFINE c        SMALLINT

CASE c                                 
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp100 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp101 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp102 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp103')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp103 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp104')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp104 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp105')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp105 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp106')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp106 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp107')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp107 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp108')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp108 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION



-------------------------------------------------------------------
FUNCTION menu_transacciones_con()

DEFINE r_menu_cont2 ARRAY[09] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_transacciones_cont AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf042 FROM '../forms/menf042'
DISPLAY FORM f_menf042

LET r_menu_cont2[1].opcion       = "Bloqueos Meses"
LET r_menu_cont2[2].opcion       = "Diarios Contables"
LET r_menu_cont2[3].opcion       = "Diarios Periódicos"
LET r_menu_cont2[4].opcion       = "Remayorización Mes"
LET r_menu_cont2[5].opcion       = "Cierre Mensual"
LET r_menu_cont2[6].opcion       = "Reapertura de Mes"
LET r_menu_cont2[7].opcion       = "Gen. D. Periódicos"
LET r_menu_cont2[8].opcion       = "Conciliación Banco"
LET r_menu_cont2[9].opcion       = "SALIR"

CALL set_count(09)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cont2 TO r_menu_cont2.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 9 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_transacciones_cont(a_c_2)
        END IF
END WHILE                
CLOSE WINDOW w_menu_transacciones_cont

END FUNCTION




-----------------------------------------------------------------
FUNCTION ejecuta_transacciones_cont(c)
DEFINE c        SMALLINT

CASE c             
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp200')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp200 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp201')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp201 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp202')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp202 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp204')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp204 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp206')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp206 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp205')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp205 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp208')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp208 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp203')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp203 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION




--------------------------------------------------------------------
FUNCTION menu_consultas_con()

DEFINE r_menu_cont3 ARRAY[09] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_consultas_cont AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf043 FROM '../forms/menf043'
DISPLAY FORM f_menf043

LET r_menu_cont3[1].opcion       = "Plan de Cuentas"
LET r_menu_cont3[2].opcion       = "Movimientos Cuentas"
LET r_menu_cont3[3].opcion       = "Balance General"
LET r_menu_cont3[4].opcion       = "Pérdidas y Ganancias"
LET r_menu_cont3[5].opcion       = "Consulta Genérica"
LET r_menu_cont3[6].opcion       = "Anl. Gráfico Cuentas"
LET r_menu_cont3[7].opcion       = "Saldos de Bancos"
LET r_menu_cont3[8].opcion       = "Balance Comprobacion"
LET r_menu_cont3[9].opcion       = "SALIR"

CALL set_count(09)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cont3 TO r_menu_cont3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 9 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_cont(a_c_2)
        END IF
END WHILE    
CLOSE WINDOW w_menu_consultas_cont

END FUNCTION




------------------------------------------------------------
FUNCTION ejecuta_consultas_cont(c)
DEFINE c        SMALLINT

CASE c                     
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp301')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp301 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp302')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp302 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp305')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp305 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp306')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp306 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp308')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp308 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp307')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp307 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp309')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp309 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp310')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp310 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION




-----------------------------------------------------------------------
FUNCTION menu_reportes_con()

DEFINE r_menu_cont4 ARRAY[08] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT    

OPEN WINDOW w_menu_reportes_cont AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf044 FROM '../forms/menf044'
DISPLAY FORM f_menf044

LET r_menu_cont4[1].opcion       = "Balance Comprobación"
LET r_menu_cont4[2].opcion       = "Balance General"
LET r_menu_cont4[3].opcion       = "Pérdidas y Ganancias"
LET r_menu_cont4[4].opcion       = "Plan de Cuentas"
LET r_menu_cont4[5].opcion       = "Movimientos de cuentas"
--LET r_menu_cont4[6].opcion       = "Control Comprobantes"
LET r_menu_cont4[6].opcion       = "Diarios Contables"
LET r_menu_cont4[7].opcion       = "Mov. Ctas. x Filtro"
LET r_menu_cont4[8].opcion       = "SALIR"

CALL set_count(08)
                       
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_cont4 TO r_menu_cont4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 8 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_cont(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_reportes_cont
END FUNCTION

------------------------------------------------------------

FUNCTION ejecuta_reportes_cont(c)
DEFINE c        SMALLINT

CASE c                   
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp401')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp401 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp402')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp402 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp403')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp403 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp404')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp404 ', vg_base, ' ', 'CB', vg_codcia
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp405')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp405 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
{--
WHEN 6
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp406 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
--}
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp408')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp408 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CB',
						'ctbp409')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD', vg_separador, 'fuentes', vg_separador, '; fglgo ctbp409 ', vg_base, ' ', 'CB', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION





 
------------------------ C O M P R A S  -----------------------
FUNCTION menu_compras()

DEFINE r_menu_com ARRAY[5] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_compras AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf070 FROM '../forms/menf070'
DISPLAY FORM f_menf070

LET r_menu_com[1].opcion        = "CONFIGURACIONES"
LET r_menu_com[2].opcion        = "TRANSACCIONES"
LET r_menu_com[3].opcion        = "CONSULTAS"
LET r_menu_com[4].opcion        = "REPORTES"
LET r_menu_com[5].opcion        = "SALIR"

CALL set_count(5)
WHILE TRUE          
 LET int_flag = 0
        DISPLAY ARRAY r_menu_com TO r_menu_com.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion_compras(a_c_2)
                CALL set_count(5)
        END IF
END WHILE
CLOSE WINDOW w_menu_compras
END FUNCTION

-------------------------------------------------------------------

FUNCTION ejecuta_opcion_compras(r)
DEFINE r        SMALLINT

CASE r                       
WHEN 1 
    	CALL menu_configuracion_com()
WHEN 2 
	CALL menu_transacciones_com()
WHEN 3 
	CALL menu_consultas_com()
WHEN 4 
	CALL menu_reportes_com()
END CASE

END FUNCTION



-------------------------------------------------------------------
FUNCTION menu_configuracion_com()

DEFINE r_menu_com1 ARRAY[04] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_configuracion_com AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf071 FROM '../forms/menf071'
DISPLAY FORM f_menf071

LET r_menu_com1[1].opcion       = "Compañías"
LET r_menu_com1[2].opcion       = "Tipos de O. Compras"
LET r_menu_com1[3].opcion       = "Porcentaje Retención"
LET r_menu_com1[4].opcion       = "SALIR"

CALL set_count(4)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_com1 TO r_menu_com1.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 4 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_configuracion_com(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_configuracion_com 

END FUNCTION




------------------------------------------------------
FUNCTION ejecuta_configuracion_com(c)
DEFINE c        SMALLINT

CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp100 ', vg_base, ' ', 'OC', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp101 ', vg_base, ' ', 'OC', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp102 ', vg_base, ' ', 'OC', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION



-----------------------------------------------------------------------
FUNCTION menu_transacciones_com()

DEFINE r_menu_com2 ARRAY[05] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_transacciones_com AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf072 FROM '../forms/menf072'
DISPLAY FORM f_menf072

LET r_menu_com2[1].opcion       = "Ingreso O. Compras"
LET r_menu_com2[2].opcion       = "Aprobación O. Compras"
LET r_menu_com2[3].opcion       = "Recepción  O. Compras"
LET r_menu_com2[4].opcion       = "Anulación Recepción"
LET r_menu_com2[5].opcion       = "SALIR"

CALL set_count(05)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_com2 TO r_menu_com2.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_transacciones_com(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_transacciones_com
END FUNCTION

-----------------------------------------------------------------
FUNCTION ejecuta_transacciones_com(c)
DEFINE c        SMALLINT

CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp200')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp200 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp201')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp201 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp202')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp202 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp204')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp204 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION





---------------------------------------------------------------------
FUNCTION menu_consultas_com()

DEFINE r_menu_com3 ARRAY[04] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_consultas_com AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf073 FROM '../forms/menf073'
DISPLAY FORM f_menf073

LET r_menu_com3[1].opcion       = "Consulta O. Compras"
LET r_menu_com3[2].opcion       = "Esdísticas de Compras"
LET r_menu_com3[3].opcion       = "Compras Proveedores"
LET r_menu_com3[4].opcion       = "SALIR"

CALL set_count(04)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_com3 TO r_menu_com3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 4 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_com(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_consultas_com

END FUNCTION



------------------------------------------------------------
FUNCTION ejecuta_consultas_com(c)
DEFINE c        SMALLINT

CASE c                

WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp300')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp300 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp302')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp302 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
END CASE

END FUNCTION




--------------------------------------------------------------------------
FUNCTION menu_reportes_com()

DEFINE r_menu_com4 ARRAY[03] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_reportes_com AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf074 FROM '../forms/menf074'
DISPLAY FORM f_menf074

LET r_menu_com4[1].opcion       = "Impresión O. Compras"
LET r_menu_com4[2].opcion       = "Detalle O. Compras"
LET r_menu_com4[3].opcion       = "SALIR"

CALL set_count(03)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_com4 TO r_menu_com4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 4 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_com(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_reportes_com

END FUNCTION




------------------------------------------------------------
FUNCTION ejecuta_reportes_com(c)
DEFINE c        SMALLINT

CASE c             
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp400')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; fglgo ordp400 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'OC',
						'ordp401')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS', vg_separador, 'fuentes', vg_separador, '; umask 0002; fglgo ordp401 ', vg_base, ' ', 'OC', vg_codcia, vg_codloc, ' > ordp401.txt'
	RUN ejecuta
END CASE

END FUNCTION






------------------------ C A J A  -----------------------
FUNCTION menu_caja()

DEFINE r_menu_caj ARRAY[5] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_caja AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf060 FROM '../forms/menf060'
DISPLAY FORM f_menf060

LET r_menu_caj[1].opcion	= "CONFIGURACIONES" 
LET r_menu_caj[2].opcion	= "TRANSACCIONES"  
LET r_menu_caj[3].opcion	= "CONSULTAS"     
LET r_menu_caj[4].opcion	= "REPORTES"     
LET r_menu_caj[5].opcion	= "SALIR"     

CALL set_count(5)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_caj TO r_menu_caj.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 5 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_opcion_caja(a_c_2)
		CALL set_count(5)
        END IF
END WHILE
CLOSE WINDOW w_menu_caja
                                                                                
END FUNCTION

-------------------------------------------------------------------

FUNCTION ejecuta_opcion_caja(r)
DEFINE r        SMALLINT

CASE r
WHEN 1 
    	CALL menu_configuracion_caj()
WHEN 2 
  	CALL menu_transacciones_caj()
WHEN 3 
  	CALL menu_consultas_caj()
WHEN 4 
	CALL menu_reportes_caj()
END CASE

END FUNCTION



FUNCTION menu_configuracion_caj()

DEFINE r_menu_caj1 ARRAY[04] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_configuracion_caj AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf061 FROM '../forms/menf061'
DISPLAY FORM f_menf061

LET r_menu_caj1[1].opcion	= "Parámetros Generales"
LET r_menu_caj1[2].opcion	= "Tipos Formas Pagos" 
LET r_menu_caj1[3].opcion	= "Mantenimiento Cajas" 
LET r_menu_caj1[4].opcion	= "SALIR" 

CALL set_count(4)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_caj1 TO r_menu_caj1.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 4 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_configuracion_caj(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_configuracion_caj
                                                                                
END FUNCTION

------------------------------------------------------

FUNCTION ejecuta_configuracion_caj(c)
DEFINE c        SMALLINT
                                                                                
CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp100')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp100 ', vg_base, ' ', 'CG', vg_codcia
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp101')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp101 ', vg_base, ' ', 'CG', vg_codcia
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp102')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp102 ', vg_base, ' ', 'CG', vg_codcia
	RUN ejecuta
END CASE

END FUNCTION


FUNCTION menu_transacciones_caj()
DEFINE r_menu_caj2 ARRAY[11] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_transacciones_caj AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_menf062 FROM '../forms/menf062'
DISPLAY FORM f_menf062

LET r_menu_caj2[01].opcion	= "Apertura de Caja" 
LET r_menu_caj2[02].opcion	= "Reapertura de Caja" 
LET r_menu_caj2[03].opcion	= "Cierres de Caja"   
LET r_menu_caj2[04].opcion	= "Ingresos de Caja"
LET r_menu_caj2[05].opcion	= "Otros Ingresos"
LET r_menu_caj2[06].opcion	= "Egresos de Caja"
LET r_menu_caj2[07].opcion	= "Eliminación I. Caja"	
LET r_menu_caj2[08].opcion	= "Corrección Fact SRI"
LET r_menu_caj2[09].opcion	= "Corrección NV SRI"
LET r_menu_caj2[10].opcion	= "Digitacion Ret. Cli."	
LET r_menu_caj2[11].opcion	= "SALIR"	

CALL set_count(11)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_caj2 TO r_menu_caj2.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 11 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_transacciones_caj(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_transacciones_caj

END FUNCTION

-----------------------------------------------------------------
FUNCTION ejecuta_transacciones_caj(c)
DEFINE c        SMALLINT
                                                                                
CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp200')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp200 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp201')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp201 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 3
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp202')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp202 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 4
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp203')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp203 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 5
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp206')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp206 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 6
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp207')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp207 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 7
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp208')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp208 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 8
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp209')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp209 ', vg_base, ' ', 'CG', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 9
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp210')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp210 ', vg_base, ' ', 'CG', vg_codcia, ' ', vg_codloc
	RUN ejecuta
WHEN 10
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp211')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp211 ', vg_base, ' ', 'CG', vg_codcia, ' ', vg_codloc
	RUN ejecuta
END CASE

END FUNCTION


FUNCTION menu_consultas_caj()

DEFINE r_menu_caj3 ARRAY[03] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_consultas_caj AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf063 FROM '../forms/menf063'
DISPLAY FORM f_menf063

LET r_menu_caj3[1].opcion	= "Transacciones Caja" 
LET r_menu_caj3[2].opcion	= "Cierres Caja" 
LET r_menu_caj3[3].opcion	= "SALIR" 

CALL set_count(03)
WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_caj3 TO r_menu_caj3.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 3 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_consultas_caj(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_consultas_caj

END FUNCTION

------------------------------------------------------------

FUNCTION ejecuta_consultas_caj(c)
DEFINE c        SMALLINT
                                                                                
CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp300')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp300 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp301')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp301 ', vg_base, ' CG ', vg_codcia, ' ', vg_codloc
	RUN ejecuta
END CASE

END FUNCTION



FUNCTION menu_reportes_caj()

DEFINE r_menu_caj4 ARRAY[03] OF RECORD
                opcion  CHAR(40)
        END RECORD
DEFINE a_c_2, s_c_2         SMALLINT

OPEN WINDOW w_menu_reportes_caj AT 4,2 WITH 20 ROWS, 78 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf064 FROM '../forms/menf064'
DISPLAY FORM f_menf064

LET r_menu_caj4[1].opcion	= "Valores Recaudados"
LET r_menu_caj4[2].opcion	= "Egresos de Caja" 
LET r_menu_caj4[3].opcion	= "SALIR" 

CALL set_count(03)

WHILE TRUE
        LET int_flag = 0
        DISPLAY ARRAY r_menu_caj4 TO r_menu_caj4.*
                ON KEY(INTERRUPT)
                        LET int_flag = 1
                        EXIT DISPLAY
                ON KEY(RETURN)
                        LET int_flag = 0
                        EXIT DISPLAY
        END DISPLAY
        IF int_flag = 1 THEN
                EXIT WHILE
        END IF
        IF int_flag = 0 THEN
                LET a_c_2 = arr_curr()
                IF a_c_2 = 3 THEN
                        EXIT WHILE
                END IF
                CALL ejecuta_reportes_caj(a_c_2)
        END IF
END WHILE
CLOSE WINDOW w_menu_reportes_caj
                                                                                
END FUNCTION

------------------------------------------------------------

FUNCTION ejecuta_reportes_caj(c)
DEFINE c        SMALLINT
                                                                                
CASE c
WHEN 1
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp402')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp402 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta
WHEN 2
	IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CG',
						'cajp405')
	THEN
		EXIT CASE
	END IF
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador, 'fuentes', vg_separador, '; fglgo cajp405 ', vg_base, ' ', 'CG', vg_codcia, vg_codloc
	RUN ejecuta

END CASE

END FUNCTION


{
------------------------ C A J A  C H I C A  -----------------------

FUNCTION menu_caja_chica()

DEFINE c100 	char(30)
DEFINE c200 	char(30)
DEFINE c300 	char(30)
DEFINE c	SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf141 FROM '../forms/menf145'
DISPLAY FORM f_menf141
--DISPLAY fondo		TO c000   ## Picture
DISPLAY "boton_configuracion"TO a      ## Picture 
DISPLAY "Parámetros Generales"TO c100   ## Botón 1 ccht000
DISPLAY "Configuración" TO c200   ## Botón 2 ccht001
DISPLAY "Cuentas Deudoras" TO c300   ## Botón 3 ccht003

LET c = fgl_getkey()

CASE c
WHEN 1
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CCHICA', vg_separador, 'fuentes', vg_separador, '; fglgo cchp100 ', vg_base, ' ', 'CH', vg_codcia
	RUN ejecuta
WHEN 2
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CCHICA', vg_separador, 'fuentes', vg_separador, '; fglgo cchp101 ', vg_base, ' ', 'CH', vg_codcia
	RUN ejecuta
WHEN 3
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'CCHICA', vg_separador, 'fuentes', vg_separador, '; fglgo cchp103 ', vg_base, ' ', 'CH', vg_codcia
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
DEFINE c	SMALLINT

WHILE TRUE
OPEN WINDOW w_menu_configuracion AT 3,2 WITH 22 ROWS, 80 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE FIRST,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_menf146 FROM '../forms/menf146'
DISPLAY FORM f_menf146
--DISPLAY fondo		TO c000   ## Picture
DISPLAY "boton_generales"TO a      ## Picture 
DISPLAY "Parámetros Generales"TO c100   ## Botón 1  genp100
DISPLAY "Compañías" 	TO c200   ## Botón 2  genp101
DISPLAY "Localidades"	TO c300   ## Botón 3  genp102
DISPLAY "Areas de Negocios" TO c400   ## Botón 4  genp103
DISPLAY "Grupos de Usuarios"    TO c500   ## Botón 5  genp104
DISPLAY "Impresoras"    TO c600   ## Botón 6  genp105
DISPLAY "Bancos Generales"   TO c700   ## Botón 7  genp106
DISPLAY "Cuentas Corrientes"    TO c800   ## Botón 8  genp107
DISPLAY "Tarjetas Crédito"      TO c900   ## Botón 9  genp108
DISPLAY "Entidades Sistema" TO c1000  ## Botón 10 genp109
DISPLAY "Componentes Sistema"   TO c1100  ## Botón 11 genp110
DISPLAY "Monedas"        TO c1200  ## Botón 12 genp111
DISPLAY "Factores Conversión"   TO c1300  ## Botón 13 genp112
DISPLAY "Control Secuencias" TO c1400  ## Botón 14 genp113
DISPLAY "Partida Arancelaria" TO c1500  ## Botón 15 genp114
DISPLAY "Rubros Liquidación" TO c1600  ## Botón 16 genp115
DISPLAY "Guías de Remisión" TO c1700  ## Botón 17 genp116
DISPLAY "Grupos Líneas Ventas" TO c1800  ## Botón 18 genp117
DISPLAY "Transacciones/Módulos" TO c1900  ## Botón 19 genp118
DISPLAY "Subtipo Transacción"   TO c2000  ## Botón 20 genp119
DISPLAY "Paises"        TO c2100  ## Botón 21 genp120
DISPLAY "Ciudades"         TO c2200  ## Botón 22 genp121
DISPLAY "Zonas de Venta "       TO c2300  ## Botón 23 genp122
DISPLAY "Centros de Costos"     TO c2400  ## Botón 24 genp123
DISPLAY "Departamentos"         TO c2500  ## Botón 25 genp124
DISPLAY "Cargos" 	TO c2600  ## Botón 26 genp125
DISPLAY "Dias Feriados" TO c2700  ## Botón 27 genp126
DISPLAY "Módulos/Bases Datos"   TO c2800  ## Botón 28 genp127
DISPLAY "Procesos por Módulos"  TO c2900  ## Botón 29 genp128
DISPLAY "Usuarios Modulo/Cía"   TO c3000  ## Botón 30 genp129
DISPLAY "Asignación Procesos"   TO c3100  ## Botón 31 genp130

LET c = fgl_getkey()

CASE c
WHEN 1
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp100 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 2
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp101 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 3
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp102 ', vg_base, ' ', 'GE ', vg_codcia
	RUN ejecuta
WHEN 4
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp103 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 5
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp104 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 6
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp105 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 7
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp106 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 8
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp107 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 9
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp108 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 10
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp109 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 11
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp110 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 12
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp111 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 13
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp112 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 14
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp113 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 15
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp114 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 16
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp115 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 17
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp116 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 18
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp117 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 19
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp118 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 20
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp119 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 21
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp120 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 22
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp121 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 24
	DISPLAY 'Boton 23 genp122 Tecla = ', c
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp122 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 25
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp123 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 3019
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp124 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 3020
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp125 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 3021
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp126 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 3022
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp127 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 3023
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp128 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 3024
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp129 ', vg_base, ' ', 'GE'
	RUN ejecuta
WHEN 3025
	LET ejecuta = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES', vg_separador, 'fuentes', vg_separador, '; fglgo genp130 ', vg_base, ' ', 'GE', vg_codcia
	RUN ejecuta
WHEN 0
	CLOSE WINDOW w_menu_configuracion
	CALL funcion_master()
END CASE

END WHILE
END FUNCTION
}


------------------------- FUNCIONES VARIAS --------------------------

FUNCTION tiene_acceso(v_usuario, v_codcia, v_modulo) 
DEFINE v_usuario	LIKE gent005.g05_usuario
DEFINE v_codcia		LIKE gent001.g01_compania
DEFINE v_modulo		LIKE gent050.g50_modulo
DEFINE r_g50		RECORD LIKE gent050.*

CALL fl_lee_modulo(v_modulo) RETURNING r_g50.*
IF r_g50.g50_modulo IS NULL THEN
CALL fl_mostrar_mensaje('MODULO: ' || v_modulo CLIPPED || ' NO EXISTE ', 'stop')
RETURN 0
END IF
SELECT * FROM gent052 
WHERE g52_modulo  = v_modulo  AND 
      g52_usuario = v_usuario AND
      g52_estado = 'A'
IF status = NOTFOUND THEN
CALL fl_mostrar_mensaje('USUARIO NO TIENE ACCESO AL MODULO: '
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
CALL fl_mostrar_mensaje('USUARIO NO TIENE ACCESO A LA COMPAÑIA:'
			|| ' ' || rg_cia.g01_abreviacion CLIPPED 
			|| '. PEDIR AYUDA AL ADMINISTRADOR ',
			'stop')
RETURN 0
END IF
RETURN 1

END FUNCTION
