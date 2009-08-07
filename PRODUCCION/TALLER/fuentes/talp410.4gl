--------------------------------------------------------------------------------
-- Titulo           : talp410.4gl - Impresion de Orden de Trabajo
-- Elaboracion      : 31-may-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp403 BD MODULO COMPANIA LOCALIDAD orden  
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_orden		LIKE talt023.t23_orden      
DEFINE vm_num_lineas	SMALLINT

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE vm_lin, vm_skip_lin	SMALLINT

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp410.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
        'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_orden    = arg_val(5)
LET vg_proceso = 'talp403'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE num_lineas		SMALLINT

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 64

INITIALIZE rm_t23.* TO NULL
SELECT * INTO rm_t23.* FROM talt023
	WHERE t23_compania    = vg_codcia
          AND t23_localidad   = vg_codloc
	  AND t23_orden       = vm_orden

IF rm_t23.t23_orden IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto, 'No existe orden.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING rm_z01.*

CALL fl_lee_mecanico(vg_codcia, rm_t23.t23_cod_asesor) RETURNING rm_t03.*
IF rm_t23.t23_cod_asesor IS NULL THEN	
	CALL FGL_WINMESSAGE(vg_producto, 'No existe codigo de asesor.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*                

CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE i 		SMALLINT
DEFINE comando		VARCHAR(100)
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE nom_tarea	LIKE talt007.t07_nombre

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN    
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

START REPORT report_orden TO PIPE comando
OUTPUT TO REPORT report_orden()
FINISH REPORT report_orden

END FUNCTION



REPORT report_orden()
DEFINE mensaje		VARCHAR(80)
DEFINE last_row 	SMALLINT

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
	print 'E';
	print '&l26A'		-- Indica que voy a trabajar con hojas A4
	print '(s1B'		-- Indica que voy a trabajar con semi negritas

	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19)      RETURNING usuario
	LET titulo = 'ORDEN DE TRABAJO '
	
	PRINT COLUMN 1, '&k0S' 
	print column (40 - ((length(titulo CLIPPED) / 2) - 1)), titulo CLIPPED

	print '&k2S' 		-- Letra condensada
	print '(s1B'		-- Indica que voy a trabajar con semi negritas

	PRINT COLUMN 50, '_______________________________________________________________'
	PRINT COLUMN 50, '|Km. Salida Taller:              |Km. Entrada Taller:          '

	PRINT COLUMN 35, 'Cliente: ',  
	      COLUMN 75, '          Fecha: ', DATE(rm_t23.t23_fecing) 
						USING 'dd-mm-yyyy', 
					      1 SPACES, TIME 

--	PRINT COLUMN 01, 
	PRINT COLUMN 35, rm_t23.t23_nom_cliente CLIPPED,
	      COLUMN 75, '       Mecanico: ',  rm_t03.t03_nombres CLIPPED 

	PRINT COLUMN 01, '    Ubicacion del Equipo: '  

	PRINT COLUMN 01, '          Modelo Maquina: ', rm_t23.t23_modelo, 
	      COLUMN 77, '       Modelo Motor: ' 

	PRINT COLUMN 01, '           Serie Maquina: ',                    
	      COLUMN 77, '        Serie Motor: ' 

	PRINT COLUMN 01, '               Horometro: '  

	
	SKIP 1 LINES

{
ON EVERY ROW

	PRINT COLUMN 03, ' Daño Reportado por el Cliente: '
	FOR i = 1 TO 6  
		SKIP 1 LINES
		PRINT "   __________________________________________________________________________________________________________________________"
	END FOR
	SKIP 1 LINES
	PRINT COLUMN 03, ' Daño Encontrado por el Mecanico: '
	FOR i = 1 TO 6  
		SKIP 1 LINES
		PRINT "   __________________________________________________________________________________________________________________________"
	END FOR
	SKIP 1 LINES
	PRINT COLUMN 03, ' Recomendaciones: '
	FOR i = 1 TO 4  
		SKIP 1 LINES
		PRINT "   __________________________________________________________________________________________________________________________"
	END FOR

	SKIP 3 LINES

	print '&k4S' 
	PRINT COLUMN 18, '__________________', 
	      COLUMN 58, '_________________'
	PRINT COLUMN 20, 'FIRMA MECANICO', 
	      COLUMN 60, 'FIRMA CLIENTE'

}

END REPORT



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no ' ||
                            'existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

