------------------------------------------------------------------------------
-- Titulo           : rolp230.4gl - Mantenimiento Novedades Casas Comerciales
-- Elaboracion      : 19-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp230 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_r_rows	ARRAY [1000] OF RECORD 
	n63_cod_almacen		LIKE rolt063.n63_cod_almacen,
	n63_cod_liqrol		LIKE rolt063.n63_cod_liqrol,
	n63_fecha_ini		LIKE rolt063.n63_fecha_ini,
	n63_fecha_fin		LIKE rolt063.n63_fecha_fin
END RECORD 

DEFINE vm_proceso	LIKE rolt005.n05_proceso

DEFINE rm_n00		RECORD LIKE rolt000.*

DEFINE rm_par RECORD
	n63_estado		LIKE rolt063.n63_estado,
	n_estado		VARCHAR(15),
	n63_cod_almacen		LIKE rolt063.n63_cod_almacen,
	n_almacen		LIKE rolt062.n62_nombre,
	n63_cod_liqrol		LIKE rolt063.n63_cod_liqrol,
	n_liqrol		LIKE rolt003.n03_nombre,
	n63_fecha_ini		LIKE rolt063.n63_fecha_ini,
	n63_fecha_fin		LIKE rolt063.n63_fecha_fin
END RECORD

DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER
DEFINE rm_scr, rm_ori ARRAY[1000] OF RECORD 
	n63_cod_trab		LIKE rolt063.n63_cod_trab,
	n_trab			LIKE rolt030.n30_nombres,
	n63_valor		LIKE rolt063.n63_valor
END RECORD	



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp230'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

DEFINE r_n01		RECORD LIKE rolt001.*

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_maxelm	= 1000

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf230_1"
DISPLAY FORM f_rol
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)

INITIALIZE rm_n00.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_moneda_pago IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado parametros generales de roles.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto,
                'Compañía no está activa.', 'stop')
        EXIT PROGRAM
END IF

LET vm_num_rows = 0

MENU 'OPCIONES'
	BEFORE MENU
		CALL mostrar_botones()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Eliminar'
--		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Imprimir'
       	COMMAND KEY('M') 'Mantenimiento' 'Ingresa/Modifica un registro. '
		CALL control_modificacion()
       	COMMAND KEY('E') 'Eliminar' 'Elimina registro corriente. '
		CALL control_eliminacion()
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
		END IF
{
       	COMMAND KEY('U') 'Cerrar' 'Cierra el rol activo. '
		CALL control_cerrar()
		IF rm_par.n63_estado = 'P' THEN
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Cerrar'
		END IF
}
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Eliminar'
--				HIDE OPTION 'Cerrar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Eliminar'
--			SHOW OPTION 'Cerrar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_par.n63_estado = 'A' THEN
			SHOW OPTION 'Eliminar'
--			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Eliminar'
--			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
		END IF
	COMMAND KEY('D') 'Detalle' 'Consulta el detalle del registro actual. '
		CALL control_detalle()
	COMMAND KEY('I') 'Imprimir' 'Imprime un registro. '
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_par.n63_estado = 'A' THEN
			SHOW OPTION 'Eliminar'
--			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Eliminar'
--			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_par.n63_estado = 'A' THEN
			SHOW OPTION 'Eliminar'
--			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Eliminar'
--			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*

INITIALIZE r_n32.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania        = vg_codcia  AND 
		      n32_estado NOT IN ('E', 'F')
		ORDER BY n32_fecha_ini DESC
OPEN q_ultliq 
FETCH q_ultliq INTO r_n32.*
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia AND n05_activo = 'S' 
IF status = NOTFOUND THEN
	IF (r_n32.n32_cod_liqrol = 'ME' OR 
	    r_n32.n32_cod_liqrol = 'Q2') THEN
	   	IF (r_n32.n32_mes_proceso = r_n01.n01_mes_proceso AND
	            r_n32.n32_ano_proceso = r_n01.n01_ano_proceso) THEN
			CALL fl_mostrar_mensaje('Debe ejecutar cierre de mes.', 
                       			'exclamation')                         
                       	RETURN
		END IF
	END IF
END IF
CLEAR FORM
CALL mostrar_botones()

CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current].*)
	END IF
	RETURN
END IF

SELECT n63_estado INTO rm_par.n63_estado FROM rolt063
	WHERE n63_compania    = vg_codcia
	  AND n63_cod_almacen = rm_par.n63_cod_almacen
	  AND n63_cod_liqrol  = rm_par.n63_cod_liqrol  
	  AND n63_fecha_ini   = rm_par.n63_fecha_ini  
	  AND n63_fecha_fin   = rm_par.n63_fecha_fin  
	GROUP BY n63_estado

IF rm_par.n63_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este registro ya ha sido procesado.', 'exclamation')
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current].*)
	END IF
	RETURN
END IF
 
CALL leer_valores('M')
IF int_flag THEN
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current].*)
	END IF
	RETURN
END IF

CALL graba_detalle()

CALL muestra_detalle('C')
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando 		VARCHAR(255)

--	LET comando = 'fglrun rolp430 ', vg_base, ' ', vg_modulo,
--                    ' ', vg_codcia, ' ', rm_par.n63_num_rol

--	RUN comando
                     
END FUNCTION



FUNCTION control_eliminacion()
DEFINE r_n63		RECORD LIKE rolt063.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current].*)

IF rm_par.n63_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF

BEGIN WORK

DELETE FROM rolt063 WHERE n63_compania    = vg_codcia
	              AND n63_cod_almacen = rm_par.n63_cod_almacen
		      AND n63_cod_liqrol  = rm_par.n63_cod_liqrol
		      AND n63_fecha_ini   = rm_par.n63_fecha_ini 
		      AND n63_fecha_fin   = rm_par.n63_fecha_fin 

COMMIT WORK

INITIALIZE rm_par.* TO NULL

CLEAR FORM
CALL mostrar_botones()

LET vm_num_rows = vm_num_rows - 1
LET vm_row_current = 1

CALL muestra_contadores(vm_row_current, vm_num_rows)

CALL fl_mensaje_registro_modificado()

END FUNCTION


{
FUNCTION control_cerrar()
DEFINE r_n63		RECORD LIKE rolt063.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current].*)

IF rm_par.n63_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF

BEGIN WORK

UPDATE rolt063 SET n63_estado = 'P' 
	WHERE n63_compania    = vg_codcia
	  AND n63_cod_almacen = rm_par.n63_cod_almacen
	  AND n63_cod_liqrol  = rm_par.n63_cod_liqrol  
	  AND n63_fecha_ini   = rm_par.n63_fecha_ini  
	  AND n63_fecha_fin   = rm_par.n63_fecha_fin  

COMMIT WORK

CALL mostrar_registro(vm_r_rows[vm_num_rows].*)	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION
}


FUNCTION control_consulta()
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n62		RECORD LIKE rolt062.*
DEFINE r_n63		RECORD LIKE rolt063.*

INITIALIZE rm_par.* TO NULL
LET int_flag = 0
CLEAR FORM
CALL mostrar_botones()
CONSTRUCT BY NAME expr_sql ON n63_estado, n63_cod_almacen, n63_cod_liqrol, 
			      n63_fecha_ini, n63_fecha_fin
	ON KEY(F2)
		IF infield(n63_cod_almacen) THEN
                        CALL fl_ayuda_casas_comerciales(vg_codcia)
                                RETURNING r_n62.n62_cod_almacen,
					  r_n62.n62_nombre 
                        IF r_n62.n62_cod_almacen IS NOT NULL THEN
				LET rm_par.n63_cod_almacen = 
					r_n62.n62_cod_almacen
				LET rm_par.n_almacen = r_n62.n62_nombre
                                DISPLAY BY NAME rm_par.n63_cod_almacen,
						rm_par.n_almacen
                        END IF
                END IF
		IF infield(n63_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_par.n63_cod_liqrol = r_n03.n03_proceso
				LET rm_par.n_liqrol = r_n03.n03_nombre
				DISPLAY BY NAME rm_par.n63_cod_liqrol,
						rm_par.n_liqrol
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current].*)
	ELSE
		CLEAR FORM
		INITIALIZE rm_par.* TO NULL
		CALL mostrar_botones()
	END IF
	RETURN
END IF

LET query = 'SELECT n63_cod_almacen, n63_cod_liqrol, ' ||
	    '       n63_fecha_ini, n63_fecha_fin FROM rolt063 ' ||
	    ' WHERE n63_compania = ' || vg_codcia   ||
	    '   AND ' || expr_sql || 
	    ' GROUP BY n63_cod_almacen, n63_cod_liqrol, n63_fecha_ini, ' ||
            '          n63_fecha_fin ' ||
	    ' ORDER BY n63_cod_almacen ASC, n63_cod_liqrol ASC, ' ||
            '          n63_fecha_ini DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	INITIALIZE rm_par.* TO NULL
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL mostrar_botones()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current].*)
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n62		RECORD LIKE rolt062.*

INITIALIZE rm_par.* TO NULL

LET rm_par.n63_estado = 'A'
LET rm_par.n_estado = 'ACTIVO'

CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 WHERE n05_compania = vg_codcia
				     AND n05_activo   = 'S' 

INITIALIZE vm_proceso TO NULL

IF r_n05.n05_compania IS NOT NULL THEN
	LET rm_par.n63_cod_liqrol = r_n05.n05_proceso
	CALL fl_lee_proceso_roles(r_n05.n05_proceso) RETURNING r_n03.*
	LET rm_par.n_liqrol = r_n03.n03_nombre
	LET rm_par.n63_fecha_ini = r_n05.n05_fecini_act
	LET rm_par.n63_fecha_fin = r_n05.n05_fecfin_act

	CALL fl_mostrar_mensaje('Se regenerara la liquidacion para todos los trabajadores que se anadan', 'information')
	LET vm_proceso = rm_par.n63_cod_liqrol
ELSE
	CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
	IF r_n01.n01_rol_quincen = 'S' THEN
		IF day(current) > 15 THEN
			LET rm_par.n63_cod_liqrol = 'Q2'
		ELSE
			LET rm_par.n63_cod_liqrol = 'Q1'
		END IF
	END IF
	IF r_n01.n01_rol_semanal = 'S' THEN
		LET rm_par.n63_cod_liqrol = 'S' || r_n01.n01_sem_proceso 
	END IF
	IF r_n01.n01_rol_mensual = 'S' THEN
		LET rm_par.n63_cod_liqrol = 'ME' 
	END IF

	CALL fl_lee_proceso_roles(rm_par.n63_cod_liqrol) RETURNING r_n03.*
	LET rm_par.n_liqrol       = r_n03.n03_nombre
	CALL fl_retorna_rango_fechas_proceso(
		vg_codcia,
		rm_par.n63_cod_liqrol, 
		r_n01.n01_ano_proceso,
		r_n01.n01_mes_proceso
	) RETURNING rm_par.n63_fecha_ini, rm_par.n63_fecha_fin
END IF

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(n63_cod_almacen, n63_cod_liqrol) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
	                       	CLEAR FORM
				CALL mostrar_botones()
        	               	RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(n63_cod_almacen) THEN
                        CALL fl_ayuda_casas_comerciales(vg_codcia)
                                RETURNING r_n62.n62_cod_almacen,
					  r_n62.n62_nombre 
                        IF r_n62.n62_cod_almacen IS NOT NULL THEN
				LET rm_par.n63_cod_almacen = 
					r_n62.n62_cod_almacen
				LET rm_par.n_almacen = r_n62.n62_nombre
                                DISPLAY BY NAME rm_par.n63_cod_almacen,
						rm_par.n_almacen
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD n63_cod_almacen
		IF rm_par.n63_cod_almacen IS NOT NULL THEN
			CALL fl_lee_casa_comercial(vg_codcia, 
						   rm_par.n63_cod_almacen
						  ) RETURNING r_n62.*	
			IF r_n62.n62_cod_almacen IS NOT NULL THEN
				LET rm_par.n63_cod_almacen = 
					r_n62.n62_cod_almacen
				LET rm_par.n_almacen  = r_n62.n62_nombre
				DISPLAY BY NAME rm_par.n63_cod_almacen,
						rm_par.n_almacen
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_detalle(opcion)
DEFINE opcion 		CHAR(1)

CALL carga_trabajadores(opcion)
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	BEFORE DISPLAY
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		DISPLAY calcula_totales() TO tot_valor
		EXIT DISPLAY
END DISPLAY
	
END FUNCTION



FUNCTION control_detalle()

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

DISPLAY ARRAY rm_scr TO ra_scr.*
	BEFORE DISPLAY
		DISPLAY calcula_totales() TO tot_valor
END DISPLAY

END FUNCTION



FUNCTION graba_detalle()
DEFINE i 		INTEGER
DEFINE r_n63		RECORD LIKE rolt063.*
DEFINE comando		VARCHAR(500)

DELETE FROM rolt063 WHERE n63_compania    = vg_codcia
	              AND n63_cod_almacen = rm_par.n63_cod_almacen
		      AND n63_cod_liqrol  = rm_par.n63_cod_liqrol
		      AND n63_fecha_ini   = rm_par.n63_fecha_ini 
		      AND n63_fecha_fin   = rm_par.n63_fecha_fin 

FOR i = 1 TO vm_numelm
	{
	IF rm_scr[i].n63_valor = 0 THEN
		CONTINUE FOR
	END IF
	}
	BEGIN WORK
	INITIALIZE r_n63.* TO NULL
	LET r_n63.n63_compania    = vg_codcia
	LET r_n63.n63_cod_almacen = rm_par.n63_cod_almacen
	LET r_n63.n63_cod_liqrol  = rm_par.n63_cod_liqrol
	LET r_n63.n63_fecha_ini   = rm_par.n63_fecha_ini
	LET r_n63.n63_fecha_fin   = rm_par.n63_fecha_fin
	LET r_n63.n63_cod_trab    = rm_scr[i].n63_cod_trab
	LET r_n63.n63_estado      = rm_par.n63_estado
	LET r_n63.n63_valor       = rm_scr[i].n63_valor 

	INSERT INTO rolt063 VALUES (r_n63.*)
	COMMIT WORK
	IF rm_scr[i].n63_cod_trab = rm_ori[i].n63_cod_trab AND  
	   rm_scr[i].n63_valor    = rm_ori[i].n63_valor THEN
		CONTINUE FOR
	END IF

	IF vm_proceso[1] = 'S' OR vm_proceso[1] = 'Q' OR vm_proceso[1] = 'M'
	THEN
		LET comando = 'fglrun rolp200 ', vg_base, ' ',
			      vg_modulo, ' ', vg_codcia, ' ',
                              rm_par.n63_cod_liqrol[1], ' ',
			      rm_scr[i].n63_cod_trab, ' ',
                              rm_par.n63_cod_liqrol, ' ',
			      rm_par.n63_fecha_ini, ' ',
			      rm_par.n63_fecha_fin 
	END IF
	IF vm_proceso = 'DC' THEN
		LET comando = 'fglrun rolp221 ', vg_base, ' ',
			      vg_modulo, ' ', vg_codcia, ' ',
			      rm_par.n63_fecha_ini, ' ',
			      rm_par.n63_fecha_fin, ' ', 
			      rm_scr[i].n63_cod_trab, ' G '
	END IF 
	IF vm_proceso = 'DT' THEN
		LET comando = 'fglrun rolp207 ', vg_base, ' ',
			      vg_modulo, ' ', vg_codcia, ' ',
			      rm_par.n63_fecha_ini, ' ',
			      rm_par.n63_fecha_fin, ' ', 
			      rm_scr[i].n63_cod_trab, ' G '
	END IF 
	RUN comando
END FOR

END FUNCTION



FUNCTION leer_valores(opcion)

DEFINE r_n30		RECORD LIKE rolt030.*

DEFINE opcion		CHAR(1)
DEFINE i                INTEGER
DEFINE j                INTEGER
DEFINE salir            INTEGER
DEFINE resp             VARCHAR(6)
DEFINE tot_valor	LIKE rolt063.n63_valor
                                                                                
LET int_flag = 0

CALL carga_trabajadores(opcion)
                                                                                
OPTIONS
        INSERT KEY F30,
        DELETE KEY F31
                                                                                
LET salir = 0
WHILE (salir = 0)
CALL set_count(vm_numelm)
INPUT ARRAY rm_scr WITHOUT DEFAULTS FROM ra_scr.*
        ON KEY(INTERRUPT)
                LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                        LET int_flag = 1
                        EXIT INPUT
                END IF
        BEFORE INPUT
                --#CALL dialog.keysetlabel('INSERT','')
                --#CALL dialog.keysetlabel('DELETE','')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		DISPLAY calcula_totales() TO tot_valor
        BEFORE ROW
                LET i = arr_curr()
                LET j = scr_line()
        BEFORE INSERT
                LET salir = 0
                EXIT INPUT
        AFTER FIELD n63_valor
                IF rm_scr[i].n63_valor IS NULL THEN
			NEXT FIELD n63_valor
		END IF
                IF rm_scr[i].n63_valor IS NOT NULL THEN
                        IF rm_scr[i].n63_valor < 0 THEN
                                NEXT FIELD n63_valor
                        END IF
                END IF
		DISPLAY calcula_totales() TO tot_valor
        AFTER INPUT
		LET tot_valor = calcula_totales() 		
		DISPLAY BY NAME tot_valor
		IF tot_valor = 0 THEN
			CALL fl_mostrar_mensaje('No se puede grabar si no ingresa detalles.', 'stop')
			CONTINUE INPUT 
		END IF
                LET salir = 1
END INPUT
IF int_flag = 1 THEN
        LET salir = 1
END IF
                                                                                
END WHILE

END FUNCTION



FUNCTION carga_trabajadores(opcion)
DEFINE opcion 		CHAR(1)
DEFINE query		VARCHAR(1500)
DEFINE tabla_rolt063	VARCHAR(25)
DEFINE join_rolt063	VARCHAR(300)
DEFINE campo_rolt063    VARCHAR(50)

CASE opcion
	WHEN 'C'
		LET campo_rolt063 = ' n63_valor '
		LET tabla_rolt063 = ', rolt063 '
		LET join_rolt063 =  ' AND n63_compania = n30_compania ',
				    ' AND n63_cod_almacen = ', 
						rm_par.n63_cod_almacen,
                                    ' AND n63_cod_liqrol  = "', 
						rm_par.n63_cod_liqrol, '"',
				    ' AND n63_fecha_ini = mdy(',
					month(rm_par.n63_fecha_ini), ',',
					day(rm_par.n63_fecha_ini), ',',
					year(rm_par.n63_fecha_ini), ') ', 
				    ' AND n63_fecha_fin = mdy(',
					month(rm_par.n63_fecha_fin), ',',
					day(rm_par.n63_fecha_fin), ',',
					year(rm_par.n63_fecha_fin), ') ', 
            			    ' AND n63_cod_trab = n30_cod_trab'
	WHEN 'M'
		LET campo_rolt063 = ' nvl(n63_valor, 0) '
		LET tabla_rolt063 = ', OUTER rolt063 '
		LET join_rolt063 =  ' AND n63_compania = n30_compania ',
				    ' AND n63_cod_almacen = ', 
						rm_par.n63_cod_almacen,
                                    ' AND n63_cod_liqrol  = "', 
						rm_par.n63_cod_liqrol, '"',
				    ' AND n63_fecha_ini = mdy(',
					month(rm_par.n63_fecha_ini), ',',
					day(rm_par.n63_fecha_ini), ',',
					year(rm_par.n63_fecha_ini), ') ', 
				    ' AND n63_fecha_fin = mdy(',
					month(rm_par.n63_fecha_fin), ',',
					day(rm_par.n63_fecha_fin), ',',
					year(rm_par.n63_fecha_fin), ') ', 
            			    ' AND n63_cod_trab = n30_cod_trab'
	WHEN 'I'
		LET campo_rolt063 = ' 0 '
		LET tabla_rolt063 = ' '
		LET join_rolt063  = ' '
END CASE

LET query = 'SELECT n30_cod_trab, n30_nombres, ', campo_rolt063 CLIPPED,
            '	FROM rolt030 ',  tabla_rolt063 CLIPPED,
            '	WHERE n30_compania   = ', vg_codcia,
            '	  AND n30_estado     = "A" ',
            '     AND n30_fecha_ing  <= TODAY ',
	    join_rolt063 CLIPPED,
		' UNION ',
		'SELECT n30_cod_trab, n30_nombres, ', campo_rolt063 CLIPPED,
            '	FROM rolt030 ',  tabla_rolt063 CLIPPED,
            '	WHERE n30_compania   = ', vg_codcia,
            '	  AND n30_estado     = "A" ',
            '     AND n30_fecha_reing  <= TODAY ',
	    join_rolt063 CLIPPED,
            '	ORDER BY n30_nombres '

PREPARE cons1 FROM query
DECLARE q_trab CURSOR FOR cons1

LET vm_numelm = 1
FOREACH q_trab INTO rm_scr[vm_numelm].*
	IF rm_scr[vm_numelm].n63_valor IS NULL THEN
		LET rm_scr[vm_numelm].n63_valor = 0
	END IF
	LET rm_ori[vm_numelm].* = rm_scr[vm_numelm].*
        LET vm_numelm = vm_numelm + 1
        IF vm_numelm > vm_maxelm THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
FREE q_trab

LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION calcula_totales()
DEFINE i                INTEGER
DEFINE valor            LIKE rolt063.n63_valor
DEFINE tot_valor        LIKE rolt063.n63_valor
                                                                                
LET tot_valor = 0
FOR i = 1 TO vm_numelm
	LET valor = rm_scr[i].n63_valor
	IF valor IS NULL THEN
		LET valor = 0
	END IF
        LET tot_valor = tot_valor + valor
END FOR
                                                                                
RETURN tot_valor
                                                                                
END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION

                                                                                

FUNCTION mostrar_botones()
                                                                                
DISPLAY 'Código'                TO bt_cod_trab
DISPLAY 'Nombre Trabajador'     TO bt_nom_trab
DISPLAY 'Valor'                 TO bt_valor
                                                                                
END FUNCTION
               


FUNCTION mostrar_registro(cod_almacen, cod_liqrol, fecha_ini, fecha_fin)
DEFINE cod_almacen	LIKE rolt063.n63_cod_almacen
DEFINE cod_liqrol	LIKE rolt063.n63_cod_liqrol
DEFINE fecha_ini	LIKE rolt063.n63_fecha_ini
DEFINE fecha_fin	LIKE rolt063.n63_fecha_fin

DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n62		RECORD LIKE rolt062.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

INITIALIZE rm_par.* TO NULL

SELECT n63_estado INTO rm_par.n63_estado FROM rolt063
	WHERE n63_compania    = vg_codcia
	  AND n63_cod_almacen = cod_almacen
	  AND n63_cod_liqrol  = cod_liqrol  
	  AND n63_fecha_ini   = fecha_ini  
	  AND n63_fecha_fin   = fecha_fin  
	GROUP BY n63_estado

LET rm_par.n63_cod_almacen = cod_almacen
LET rm_par.n63_cod_liqrol  = cod_liqrol
LET rm_par.n63_fecha_ini   = fecha_ini
LET rm_par.n63_fecha_fin   = fecha_fin
CASE rm_par.n63_estado  
	WHEN 'A' 
		LET rm_par.n_estado = 'ACTIVO'
	WHEN 'P' 
		LET rm_par.n_estado = 'PROCESADO'
END CASE

CALL fl_lee_casa_comercial(vg_codcia, rm_par.n63_cod_almacen) RETURNING r_n62.* 
LET rm_par.n_almacen    = r_n62.n62_nombre
CALL fl_lee_proceso_roles(rm_par.n63_cod_liqrol) RETURNING r_n03.* 
LET rm_par.n_liqrol     = r_n03.n03_nombre

DISPLAY BY NAME	rm_par.*

CALL muestra_detalle('C')

END FUNCTION
