{*
 * Titulo           : cmsp103.4gl - Mantenimiento de clientes x localidad
 *                                  para efecto de pago de comisiones 
 * Elaboracion      : 09-jun-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun cmsp103 base modulo compania 
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER

DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_max_detalles	SMALLINT

	---- CABECERA ----
DEFINE rm_par RECORD
	c02_codigo			LIKE cmst002.c02_codigo,
	c02_nombres			LIKE cmst002.c02_nombres
END RECORD

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[5000] OF RECORD
	c03_codcli			LIKE cmst003.c03_codcli,
	z01_nomcli			LIKE cxct001.z01_nomcli
END RECORD

DEFINE vm_flag_mant		CHAR(1)	   -- FLAG DE MANTENIMIENTO
					   -- 'M' --> MODIFICACION		
					   -- 'C' --> CONSULTA		
DEFINE vm_filas_pant	SMALLINT   -- FILAS EN PANTALLA



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cmsp103.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cmsp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
							-- que luego puede ser reemplazado si se 
                            -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW cmsw103 AT 3,2 WITH 22 ROWS, 65 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM cmsf103 FROM '../forms/cmsf103_1'
DISPLAY FORM cmsf103
CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_max_rows     = 1000
LET vm_max_detalles = 5000
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Ver Detalle'
	COMMAND KEY('M') 'Modificar' 'Modificar un registro.'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
    COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
    	CALL control_consulta()
        IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ver Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Ver Detalle'
            END IF
         ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Avanzar'
         END IF
         IF vm_row_current <= 1 THEN
         	HIDE OPTION 'Retroceder'
         END IF
	COMMAND KEY('V') 'Ver Detalle'   'Muestra anteriores detalles.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Codigo' 		TO tit_col1
DISPLAY 'Nombre' 		TO tit_col2

END FUNCTION



FUNCTION control_ver_detalle()

CALL set_count(vm_num_detalles)
DISPLAY ARRAY r_detalle TO r_detalle.*
	BEFORE DISPLAY
    	CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_modificacion()
DEFINE done				SMALLINT
DEFINE i				SMALLINT

LET vm_flag_mant = 'M'

BEGIN WORK
LOCK TABLE cmst003 IN EXCLUSIVE MODE

LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

DELETE FROM cmst003
 WHERE c03_compania  = vg_codcia
   AND c03_codcomi = rm_par.c02_codigo

LET done = control_ingreso_detalle()
IF done = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Ha ocurrido un error al intentar actualizar los clientes. No se realizará el proceso.','exclamation')
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE i,done 		SMALLINT
DEFINE r_c03		RECORD LIKE cmst003.*
DEFINE r_c03_exist	RECORD LIKE cmst003.*

LET done  = 1

FOR i = 1 TO vm_num_detalles
	INITIALIZE r_c03.*, r_c03_exist.* TO NULL
	LET r_c03.c03_compania = vg_codcia
	LET r_c03.c03_codcomi  = rm_par.c02_codigo
	LET r_c03.c03_codcli   = r_detalle[i].c03_codcli

	SELECT * INTO r_c03_exist.*
	  FROM cmst003
	 WHERE c03_compania = r_c03.c03_compania
	   AND c03_codcomi  = r_c03.c03_codcomi
	   AND c03_codcli   = r_c03.c03_codcli
	IF r_c03_exist.c03_compania IS NULL THEN 
		INSERT INTO cmst003 VALUES(r_c03.*)
	END IF
END FOR 

RETURN done

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j				SMALLINT
DEFINE resp				CHAR(6)

DEFINE r_z01			RECORD LIKE cxct001.*

LET i = 1
LET j = 1

LET int_flag = 0
CALL set_count(vm_num_detalles)
INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		DISPLAY '' AT 21,1
		DISPLAY i, ' de ', arr_count() AT 21, 1 
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT      
		END IF
	ON KEY(F2)
		IF INFIELD(c03_codcli) THEN
			CALL fl_ayuda_cliente_general() RETURNING r_z01.z01_codcli, 
													  r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET r_detalle[i].c03_codcli = r_z01.z01_codcli
				LET r_detalle[i].z01_nomcli = r_z01.z01_nomcli
				DISPLAY r_detalle[i].* TO r_detalle[j].*
			END IF 
        END IF
		LET INT_FLAG = 0
	AFTER FIELD c03_codcli
		IF r_detalle[i].c03_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(r_detalle[i].c03_codcli) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe el cliente.', 'exclamation')
				NEXT FIELD c03_codcli
			END IF

			LET r_detalle[i].c03_codcli = r_z01.z01_codcli
			LET r_detalle[i].z01_nomcli = r_z01.z01_nomcli
			DISPLAY r_detalle[i].* TO r_detalle[j].*
		END IF
	AFTER INPUT
		LET i = arr_count()
END INPUT
DISPLAY '' AT 10,1
IF int_flag THEN
	RETURN 0
END IF

RETURN i

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)
DEFINE r_c02		RECORD LIKE cmst002.* 

CLEAR FORM
CALL control_display_botones()

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON c02_codigo, c02_nombres
	ON KEY(F2)
		IF INFIELD(c02_codigo) THEN
			CALL fl_ayuda_comisionistas(vg_codcia)
				RETURNING r_c02.c02_codigo, r_c02.c02_nombres
			IF r_c02.c02_codigo IS NOT NULL THEN
				DISPLAY BY NAME r_c02.c02_codigo, r_c02.c02_nombres
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT c02_codigo, c02_nombres, ROWID FROM cmst002 ', 
		' WHERE c02_compania  = ', vg_codcia,
		' AND c02_estado = "A" ',
		' AND ', expr_sql CLIPPED,
		' ORDER BY 2 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_par.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	CALL control_display_botones()
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT c02_codigo, c02_nombres INTO rm_par.* 
  FROM cmst002 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_par.*
CALL muestra_contadores()
CALL cargar_clientes(rm_par.c02_codigo)

END FUNCTION



FUNCTION cargar_clientes(codcomi)
DEFINE codcomi		LIKE cmst003.c03_codcomi
DEFINE i			SMALLINT

DECLARE q_comicli CURSOR FOR
	SELECT c03_codcli, z01_nomcli FROM cmst003, cxct001
	 WHERE c03_compania = vg_codcia
	   AND c03_codcomi  = codcomi
	   AND z01_codcli   = c03_codcli
	 ORDER BY z01_nomcli

LET vm_num_detalles = 1
FOREACH q_comicli INTO r_detalle[vm_num_detalles].*
	LET vm_num_detalles = vm_num_detalles + 1
	IF vm_num_detalles > vm_max_detalles THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_detalles = vm_num_detalles - 1

CALL set_count(vm_num_detalles)
DISPLAY ARRAY r_detalle TO r_detalle.*
	BEFORE DISPLAY
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "                                      " AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 55 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
