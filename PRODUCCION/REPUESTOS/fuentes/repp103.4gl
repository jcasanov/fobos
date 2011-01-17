
-------------------------------------------------------------------------------
-- Titulo               : repp103.4gl -- Mantenimiento de Lineas de Ventas
-- Elaboración          : 13-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  repp103.4gl base RE 1 
-- Ultima Correción     : 13-sep-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_lven   RECORD LIKE rept003.*
DEFINE rm_lven2  RECORD LIKE rept003.*
DEFINE rm_gven   RECORD LIKE gent020.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_lven AT 3,2 WITH 19 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_lven FROM '../forms/repf103_1'
DISPLAY FORM f_lven
INITIALIZE rm_lven.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		  IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
	  	  END IF
		
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
		   END IF
		
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r03_grupo_linea, r03_codigo, r03_nombre,
		 r03_porc_uti, r03_rentab_min, r03_dcto_tal, r03_dcto_cont, 
		 r03_dcto_cred,
		 r03_area, r03_tipo, r03_estado, r03_usuario, r03_fecing
	ON KEY(F2)
		IF INFIELD(r03_codigo) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     RETURNING rm_lven.r03_codigo, rm_lven.r03_nombre
		     IF rm_lven.r03_codigo IS NOT NULL THEN
			DISPLAY BY NAME rm_lven.r03_codigo, rm_lven.r03_nombre
		     END IF
		END IF
      		IF INFIELD(r03_grupo_linea) THEN
                      CALL fl_ayuda_grupo_lineas(vg_codcia)
                           RETURNING rm_gven.g20_grupo_linea, rm_gven.g20_nombre
                        IF rm_gven.g20_grupo_linea IS NOT NULL THEN
                            LET rm_lven.r03_grupo_linea =rm_gven.g20_grupo_linea
                            DISPLAY BY NAME rm_lven.r03_grupo_linea
                            DISPLAY rm_gven.g20_nombre TO nom_grupo
                        END IF
                END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept003 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_lven CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_lven INTO rm_lven.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_lven.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_lven.r03_compania   = vg_codcia
LET rm_lven.r03_fecing     = CURRENT
LET rm_lven.r03_usuario    = vg_usuario
LET rm_lven.r03_estado     = 'A'
LET rm_lven.r03_tipo       = 'N'
LET rm_lven.r03_area       = 'R'
DISPLAY BY NAME rm_lven.r03_fecing, rm_lven.r03_usuario, rm_lven.r03_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO rept003 VALUES (rm_lven.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
IF rm_lven.r03_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM rept003 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_lven.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET rm_lven2.r03_nombre = rm_lven.r03_nombre
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept003 SET * = rm_lven.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	LIKE rept003.r03_estado

LET int_flag = 0
IF rm_lven.r03_codigo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_lven.r03_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM rept003 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_lven.*
	IF status < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET estado = 'B'
	IF rm_lven.r03_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE rept003 SET r03_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos()
DEFINE           resp           CHAR(6)
DEFINE           codigo		LIKE rept003.r03_codigo
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_lven.r03_grupo_linea, rm_lven.r03_codigo, rm_lven.r03_nombre,
	 rm_lven.r03_porc_uti, rm_lven.r03_rentab_min, rm_lven.r03_dcto_tal, 
	 rm_lven.r03_dcto_cont,
	 rm_lven.r03_dcto_cred,rm_lven.r03_area, rm_lven.r03_tipo
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched( rm_lven.r03_grupo_linea, rm_lven.r03_codigo,
		 rm_lven.r03_nombre, rm_lven.r03_porc_uti, rm_lven.r03_dcto_tal,		 rm_lven.r03_dcto_cont, rm_lven.r03_dcto_cred, rm_lven.r03_rentab_min)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
			END IF
                        RETURN
                END IF       	
	ON KEY(F2)
      		IF INFIELD(r03_grupo_linea) THEN
                      CALL fl_ayuda_grupo_lineas(vg_codcia)
                           RETURNING rm_gven.g20_grupo_linea, rm_gven.g20_nombre
                        IF rm_gven.g20_grupo_linea IS NOT NULL THEN
                            LET rm_lven.r03_grupo_linea =rm_gven.g20_grupo_linea
                            DISPLAY BY NAME rm_lven.r03_grupo_linea
                            DISPLAY rm_gven.g20_nombre TO nom_grupo
                        END IF
                END IF
                LET int_flag = 0
	BEFORE  FIELD r03_codigo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD r03_grupo_linea
               IF rm_lven.r03_grupo_linea IS NOT NULL THEN
		     CALL fl_lee_grupo_linea(vg_codcia,rm_lven.r03_grupo_linea)
		     	RETURNING rm_gven.*
		     IF rm_gven.g20_grupo_linea IS NULL THEN
			   CALL fgl_winmessage(vg_producto, 'No existe el grupo de linea en la compañía ','exclamation')
			   NEXT FIELD r03_grupo_linea
		     END IF
		     DISPLAY rm_gven.g20_nombre TO nom_grupo	
		ELSE 
			CLEAR nom_grupo
		END IF
	AFTER INPUT
                IF vm_flag_mant = 'I' THEN
                    CALL fl_lee_linea_rep(vg_codcia, rm_lven.r03_codigo)
                                RETURNING rm_lven2.*
                        IF rm_lven2.r03_codigo IS NOT NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Línea de venta ya existe en la compañía ','exclamation')
                                NEXT FIELD r03_codigo
                        END IF
                END IF
		IF vm_flag_mant = 'I'
		OR rm_lven2.r03_nombre <> rm_lven.r03_nombre
		THEN
	      		SELECT r03_codigo INTO codigo FROM rept003
	      		WHERE r03_compania = vg_codcia
	      		AND   r03_nombre   = rm_lven.r03_nombre
	      		IF status <> NOTFOUND THEN
                 		CALL fgl_winmessage (vg_producto, 'El nombre de la Línea de Venta ya ha sido asignada al registro de codigo  '|| codigo, 'exclamation')
	         		NEXT FIELD r03_nombre  
              		END IF
             	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_lven.* FROM rept003 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_lven.r03_grupo_linea, rm_lven.r03_codigo, rm_lven.r03_nombre,
	 rm_lven.r03_porc_uti, rm_lven.r03_dcto_tal, rm_lven.r03_dcto_cont,
	 rm_lven.r03_dcto_cred,rm_lven.r03_area, rm_lven.r03_tipo,
	 rm_lven.r03_estado, rm_lven.r03_fecing, rm_lven.r03_usuario,
	 rm_lven.r03_rentab_min
IF rm_lven.r03_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL fl_lee_grupo_linea(vg_codcia, rm_lven.r03_grupo_linea)
RETURNING rm_gven.*
DISPLAY rm_gven.g20_nombre TO nom_grupo

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION

                                                                                
                                                                                
FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
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
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

