--------------------------------------------------------------------------------
-- Titulo               : actp104.4gl -- Mantenimiento de Activos Fijos
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  actp104.4gl base AF compañía 
-- Ultima Corrección    : 09-jun-2003
-- Motivo Corrección    : Revision y Correccion Aceros 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_last_lvl	LIKE ctbt001.b01_nivel
DEFINE rm_a10		RECORD LIKE actt010.* 
DEFINE bien 		ARRAY[1000] OF INTEGER 
DEFINE vm_indice	INTEGER       
DEFINE vm_num_rows      INTEGER      
DEFINE vm_max_rows      INTEGER     
DEFINE vm_programa      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                            
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp104.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN   -- Validar # parámetros correcto
        CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
        EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp104'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()  
END MAIN



FUNCTION funcion_master()
DEFINE vm_bien 	INTEGER
DEFINE vm_rowid	INTEGER

INITIALIZE vm_last_lvl TO NULL
INITIALIZE rm_a10.* TO NULL
LET vm_max_rows = 1000
LET vm_num_rows = 0
LET vm_indice = 0

----------------
CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
        ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST - 2)
OPEN FORM frm_a10 FROM '../forms/actf104_1'
DISPLAY FORM frm_a10

SELECT MAX(b01_nivel) INTO vm_last_lvl FROM ctbt001 
IF vm_last_lvl IS NULL THEN
	CALL fgl_winmessage('FOBOS',
		'No se han configurado los niveles de cuenta.',
		'exclamation')
	EXIT PROGRAM
END IF

CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Orden Compra'
		HIDE OPTION 'Activar/Bloquear'	
		IF num_args() = 4 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Orden Compra'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF

	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Orden Compra'
			SHOW OPTION 'Activar/Bloquear'
		END IF
		IF vm_indice > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_indice = vm_num_rows THEN
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
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Orden Compra'
			SHOW OPTION 'Activar/Bloquear'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Activar/Bloquear'
				HIDE OPTION 'Orden Compra'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Orden Compra'
			SHOW OPTION 'Activar/Bloquear'
		END IF
		IF vm_indice <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_indice > 0 THEN
			CALL lee_muestra_registro(bien[vm_indice])
		END IF

        COMMAND KEY('E') 'Activar/Bloquear' 'Bloquea/Activa registro corriente.'
                IF vm_num_rows > 0 THEN
                        CALL control_bloqueo()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF

	COMMAND KEY('O') 'Orden Compra' 'Ver Orden de Compra.'
		CALL orden_compra()

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_indice < vm_num_rows THEN
			LET vm_indice = vm_indice + 1 
		END IF	

		CALL lee_muestra_registro(bien[vm_indice])
		IF vm_indice = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF

	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_indice > 1 THEN
			LET vm_indice = vm_indice - 1 
		END IF
		CALL lee_muestra_registro(bien[vm_indice])
		IF vm_indice = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF

	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE codbien		LIKE actt010.a10_codigo_bien
DEFINE desc_bien	LIKE actt010.a10_descripcion
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE desc_grupo	LIKE actt001.a01_nombre
DEFINE tipo		LIKE actt010.a10_tipo_act
DEFINE desc_tipo	LIKE actt002.a02_nombre
DEFINE localidad        LIKE gent002.g02_localidad
DEFINE desc_localidad   LIKE gent002.g02_nombre
DEFINE departamento     LIKE gent034.g34_cod_depto
DEFINE desc_depto       LIKE gent034.g34_nombre
DEFINE proveedor     	LIKE cxpt001.p01_codprov
DEFINE desc_proveedor   LIKE cxpt001.p01_nomprov
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nombre_mon       LIKE gent013.g13_nombre
DEFINE decimales   	LIKE gent013.g13_decimales
DEFINE responsable 	LIKE actt003.a03_responsable
DEFINE nombre     	LIKE actt003.a03_nombres
DEFINE r_codigo_bien	RECORD LIKE actt010.*
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)


CLEAR FORM
INITIALIZE rm_a10.* TO NULL
IF num_args() <> 4 THEN
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON a10_codigo_bien, a10_estado,    
	a10_descripcion, a10_grupo_act, a10_tipo_act, a10_anos_util,
	a10_porc_deprec, a10_modelo, a10_serie, a10_locali_ori, 
	a10_numero_oc, a10_localidad, a10_cod_depto, a10_codprov,
	a10_fecha_comp, a10_moneda, a10_paridad, a10_valor, a10_valor_mb,  
	a10_responsable, a10_fecha_baja, a10_val_dep_mb, a10_val_dep_ma, 
	a10_tot_dep_mb, a10_tot_dep_ma, a10_tot_reexpr, a10_tot_dep_ree,
 	a10_usuario

	ON KEY(F2)
		IF INFIELD(a10_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia, NULL, NULL, 'T', 0)
				RETURNING codbien, desc_bien
			IF codbien IS NOT NULL THEN
				LET rm_a10.a10_codigo_bien = codbien
				LET rm_a10.a10_descripcion = desc_bien
				DISPLAY BY NAME rm_a10.a10_codigo_bien	
				DISPLAY BY NAME rm_a10.a10_descripcion	
			ELSE
                                CALL fgl_winmessage(vg_producto,
                                     'No existe Activo Fijo',
                                                'exclamation')
                                NEXT FIELD a10_codigo_bien
			END IF 
		END IF
	

		IF INFIELD(a10_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
				RETURNING grupo, desc_grupo
			IF grupo IS NOT NULL THEN
				LET rm_a10.a10_grupo_act = grupo
				DISPLAY BY NAME rm_a10.a10_grupo_act
				DISPLAY desc_grupo TO desc_grupo_act
			END IF 
		END IF
	

		IF INFIELD(a10_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
							rm_a10.a10_grupo_act)
				RETURNING tipo, desc_tipo
			IF tipo IS NOT NULL THEN
				LET rm_a10.a10_tipo_act = tipo
				DISPLAY BY NAME rm_a10.a10_tipo_act
				DISPLAY desc_tipo TO desc_tipo_act
			END IF
		END IF 


		IF INFIELD(a10_locali_ori) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING localidad, desc_localidad
			IF localidad IS NOT NULL THEN
				LET rm_a10.a10_locali_ori = localidad
				DISPLAY BY NAME rm_a10.a10_locali_ori
				DISPLAY desc_localidad TO desc_locali_ori
			END IF 
		END IF 


		IF INFIELD(a10_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING localidad, desc_localidad
			IF localidad IS NOT NULL THEN
				LET rm_a10.a10_localidad = localidad
				DISPLAY BY NAME rm_a10.a10_localidad
				DISPLAY desc_localidad TO desc_localidad
			END IF 
		END IF

		IF INFIELD(a10_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
				RETURNING departamento, desc_depto
			IF departamento IS NOT NULL THEN
				LET rm_a10.a10_cod_depto = departamento
				DISPLAY BY NAME rm_a10.a10_cod_depto
				DISPLAY desc_depto TO desc_depto
			END IF 
		END IF

		IF INFIELD(a10_codprov) THEN
			CALL fl_ayuda_proveedores() 
				RETURNING proveedor, desc_proveedor
			IF proveedor IS NOT NULL THEN
				LET rm_a10.a10_codprov = proveedor
				DISPLAY BY NAME rm_a10.a10_codprov
				DISPLAY desc_proveedor TO desc_prov
			END IF 
		END IF

		IF INFIELD(a10_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING moneda, nombre_mon, decimales
			IF moneda IS NOT NULL THEN
				LET rm_a10.a10_moneda = moneda
				DISPLAY BY NAME rm_a10.a10_moneda
				DISPLAY nombre_mon TO desc_moneda
			END IF 
		END IF


		IF INFIELD(a10_responsable) THEN
			CALL fl_ayuda_responsable(vg_codcia) 
				RETURNING responsable, nombre 
			IF responsable IS NOT NULL THEN
				LET rm_a10.a10_responsable = responsable
				DISPLAY BY NAME rm_a10.a10_responsable
				DISPLAY nombre TO desc_responsable
			END IF 
		END IF

		LET int_flag = 0
{
        AFTER FIELD a10_codigo_bien
		LET rm_a10.a10_codigo_bien = get_fldbuf(a10_codigo_bien)
                IF  rm_a10.a10_codigo_bien IS NOT NULL THEN
                        CALL fl_lee_codigo_bien(vg_codcia,
                                        rm_a10.a10_codigo_bien)
                                RETURNING r_codigo_bien.*
                        IF r_codigo_bien.a10_codigo_bien IS NULL THEN
                                CALL fgl_winmessage(vg_producto,
                                     'No existe Activo Fijo',
                                                'exclamation')
                                NEXT FIELD a10_codigo_bien
                        ELSE
                                DISPLAY r_codigo_bien.a10_descripcion
                                        TO desc_tipo_act
                        END IF
                ELSE
                        CLEAR desc_tipo_act
                END IF
}
	AFTER FIELD a10_grupo_act
		LET rm_a10.a10_grupo_act = GET_FLDBUF(a10_grupo_act)
END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(bien[vm_indice])
	ELSE
		CALL muestra_estado()
		CLEAR a10_estado, desc_estado
	END IF
	RETURN
END IF
ELSE
	LET expr_sql = 'a10_codigo_bien = ', arg_val(4)
END IF
LET query = 'SELECT *, ROWID ',
		' FROM actt010 ',
		' WHERE a10_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
	    ' ORDER BY 2'
PREPARE cons FROM query
DECLARE q_act CURSOR FOR cons
LET vm_num_rows = 1

FOREACH q_act INTO rm_a10.*, bien[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
        CLEAR FORM
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_indice = 0
	CALL muestra_contadores()
        RETURN
END IF
LET vm_indice = 1
CALL muestra_contadores()
CALL lee_muestra_registro(bien[vm_indice])

END FUNCTION


FUNCTION control_inicializa_valores()

	LET rm_a10.a10_paridad = 0
	LET rm_a10.a10_valor = 0
	LET rm_a10.a10_valor_mb = 0  
	LET rm_a10.a10_val_dep_mb = 0 
	LET rm_a10.a10_val_dep_ma = 0 
	LET rm_a10.a10_tot_dep_mb = 0 
	LET rm_a10.a10_tot_dep_ma = 0 
	LET rm_a10.a10_tot_reexpr = 0 
	LET rm_a10.a10_tot_dep_ree = 0

END FUNCTION



FUNCTION control_ingreso()
DEFINE maximo		LIKE actt010.a10_codigo_bien

OPTIONS INPUT WRAP, ACCEPT KEY F12
CLEAR FORM
INITIALIZE rm_a10.* TO NULL
LET vm_flag_mant        = 'I'
LET rm_a10.a10_fecing   = CURRENT
LET rm_a10.a10_usuario  = vg_usuario
LET rm_a10.a10_compania = vg_codcia
LET rm_a10.a10_estado   = 'A'

DISPLAY BY NAME rm_a10.a10_usuario,	
		rm_a10.a10_fecing, 
		rm_a10.a10_estado

CALL control_inicializa_valores()
CALL muestra_contadores()
CALL muestra_estado()
CALL lee_datos()
IF NOT int_flag THEN
	SELECT MAX(a10_codigo_bien)
		INTO maximo
		FROM actt010 
		WHERE a10_compania = vg_codcia
	IF maximo IS NULL THEN
		LET maximo  = 0
	END IF
	LET rm_a10.a10_codigo_bien = maximo + 1 
	INSERT INTO actt010 VALUES (rm_a10.*) 

	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET bien[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_indice = vm_num_rows
	CALL muestra_contadores()
	CALL lee_muestra_registro(bien[vm_indice])
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(bien[vm_indice])
	ELSE
		CALL muestra_estado()
		CLEAR a10_estado, desc_estado
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE flag		CHAR(1)

IF rm_a10.a10_estado <> 'A' AND rm_a10.a10_estado <> 'S' THEN
	CALL fl_mostrar_mensaje('Solo se puede modificar un Bien si esta Activo o tiene Stock.', 'exclamation')
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR 
	SELECT * FROM actt010
		WHERE ROWID = bien[vm_indice]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_a10.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF rm_a10.a10_estado = 'A' THEN
	CALL lee_datos()
END IF
IF rm_a10.a10_estado = 'S' THEN
	CALL lee_datos_stock()
END IF
IF NOT int_flag THEN
    	UPDATE actt010 SET * = rm_a10.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
END IF
CALL lee_muestra_registro(bien[vm_indice])

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_grupo          RECORD LIKE actt001.*
DEFINE r_tipo        	RECORD LIKE actt002.*
DEFINE r_localidad      RECORD LIKE gent002.*
DEFINE r_departamento   RECORD LIKE gent034.*
DEFINE r_proveedor      RECORD LIKE cxpt001.*
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_responsable	RECORD LIKE actt003.*
DEFINE codbien		LIKE actt010.a10_codigo_bien
DEFINE desc_bien	LIKE actt010.a10_descripcion
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE desc_grupo	LIKE actt001.a01_nombre
DEFINE tipo		LIKE actt010.a10_tipo_act
DEFINE desc_tipo	LIKE actt002.a02_nombre
DEFINE localidad        LIKE gent002.g02_localidad
DEFINE desc_localidad   LIKE gent002.g02_nombre
DEFINE departamento     LIKE gent034.g34_cod_depto
DEFINE desc_depto       LIKE gent034.g34_nombre
DEFINE proveedor     	LIKE cxpt001.p01_codprov
DEFINE desc_proveedor   LIKE cxpt001.p01_nomprov
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nombre_mon       LIKE gent013.g13_nombre
DEFINE decimales   	LIKE gent013.g13_decimales
DEFINE responsable 	LIKE actt003.a03_responsable
DEFINE nombre     	LIKE actt003.a03_nombres
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE r_mon_par        RECORD LIKE gent014.*
DEFINE r_codigo_bien	RECORD LIKE actt010.*
DEFINE r_p02		RECORD LIKE cxpt002.*


CALL fl_lee_moneda(rg_gen.g00_moneda_base)           -- PARA OBTENER EL NOMBRE
        RETURNING rm_g13.*

LET int_flag = 0 
INPUT BY NAME  rm_a10.a10_codigo_bien, rm_a10.a10_estado,    
	rm_a10.a10_descripcion, rm_a10.a10_grupo_act, rm_a10.a10_tipo_act,
	rm_a10.a10_anos_util, rm_a10.a10_porc_deprec, rm_a10.a10_modelo, 
	rm_a10.a10_serie, rm_a10.a10_locali_ori, rm_a10.a10_numero_oc, 
	rm_a10.a10_localidad, rm_a10.a10_cod_depto, rm_a10.a10_codprov,
	rm_a10.a10_fecha_comp, rm_a10.a10_moneda, rm_a10.a10_paridad, 
	rm_a10.a10_valor, rm_a10.a10_valor_mb, rm_a10.a10_responsable, 
	rm_a10.a10_fecha_baja, rm_a10.a10_val_dep_mb, rm_a10.a10_val_dep_ma, 
	rm_a10.a10_tot_dep_mb, rm_a10.a10_tot_dep_ma, rm_a10.a10_tot_reexpr,
	rm_a10.a10_tot_dep_ree, rm_a10.a10_usuario, rm_a10.a10_fecing
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		 IF field_touched(a10_codigo_bien, a10_estado, a10_descripcion,
			a10_grupo_act, a10_tipo_act, a10_anos_util,
			a10_porc_deprec, a10_modelo, a10_serie, a10_locali_ori, 
			a10_numero_oc, a10_localidad, a10_cod_depto,
			a10_codprov, a10_fecha_comp, a10_moneda, a10_paridad, 
			a10_valor, a10_valor_mb, a10_responsable, 
			a10_fecha_baja, a10_val_dep_mb, a10_val_dep_ma, 
			a10_tot_dep_mb, a10_tot_dep_ma, a10_tot_reexpr, 
			a10_tot_dep_ree, a10_usuario, a10_fecing)
		  THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
                                CLEAR FORM
				EXIT INPUT
                        END IF
                ELSE
                        CLEAR FORM
			EXIT INPUT
                END IF       	

	ON KEY(F2)
		IF INFIELD(a10_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
				RETURNING grupo, desc_grupo
			IF grupo IS NOT NULL THEN
				LET rm_a10.a10_grupo_act = grupo
				DISPLAY BY NAME rm_a10.a10_grupo_act
				DISPLAY desc_grupo TO desc_grupo_act
			END IF 
		END IF
	
		IF INFIELD(a10_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
							rm_a10.a10_grupo_act)
				RETURNING tipo, desc_tipo
			IF tipo IS NOT NULL THEN
				LET rm_a10.a10_tipo_act = tipo
				DISPLAY BY NAME rm_a10.a10_tipo_act
				DISPLAY desc_tipo TO desc_tipo_act
			END IF
		END IF 

		IF INFIELD(a10_locali_ori) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING localidad, desc_localidad
			IF localidad IS NOT NULL THEN
				LET rm_a10.a10_locali_ori = localidad
				DISPLAY BY NAME rm_a10.a10_locali_ori
				DISPLAY desc_localidad TO desc_locali_ori
			END IF 
		END IF 

		IF INFIELD(a10_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING localidad, desc_localidad
			IF localidad IS NOT NULL THEN
				LET rm_a10.a10_localidad = localidad
				DISPLAY BY NAME rm_a10.a10_localidad
				DISPLAY desc_localidad TO desc_localidad
			END IF 
		END IF

		IF INFIELD(a10_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia) 
				RETURNING departamento, desc_depto
			IF departamento IS NOT NULL THEN
				LET rm_a10.a10_cod_depto = departamento
				DISPLAY BY NAME rm_a10.a10_cod_depto
				DISPLAY desc_depto TO desc_depto
			END IF 
		END IF

		IF INFIELD(a10_codprov) THEN
			CALL fl_ayuda_proveedores() 
				RETURNING proveedor, desc_proveedor
			IF proveedor IS NOT NULL THEN
				LET rm_a10.a10_codprov = proveedor
				DISPLAY BY NAME rm_a10.a10_codprov
				DISPLAY desc_proveedor TO desc_prov
			END IF 
		END IF
		
		IF INFIELD(a10_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING moneda, nombre_mon, decimales
			IF moneda IS NOT NULL THEN
				LET rm_a10.a10_moneda = moneda
				DISPLAY BY NAME rm_a10.a10_moneda
				DISPLAY nombre_mon TO desc_moneda
			END IF 
		END IF

		IF INFIELD(a10_responsable) THEN
			CALL fl_ayuda_responsable(vg_codcia) 
				RETURNING responsable, nombre 
			IF responsable IS NOT NULL THEN
				LET rm_a10.a10_responsable = responsable
				DISPLAY BY NAME rm_a10.a10_responsable
				DISPLAY nombre TO desc_responsable
			END IF 
		END IF

		LET int_flag = 0

	AFTER FIELD a10_codigo_bien
		IF rm_a10.a10_codigo_bien IS NOT NULL THEN
                        CALL fl_lee_codigo_bien(vg_codcia,
                                        rm_a10.a10_codigo_bien)
                                RETURNING r_codigo_bien.*
                        IF r_codigo_bien.a10_codigo_bien IS NULL THEN
                                CALL fgl_winmessage(vg_producto,
                                     'No existe Activo Fijo',
                                                'exclamation')
                                NEXT FIELD a10_codigo_bien
                        END IF
                        DISPLAY BY NAME r_codigo_bien.a10_descripcion 
                ELSE
                        CLEAR desc_tipo_act
		END IF

	AFTER FIELD a10_descripcion
		IF rm_a10.a10_descripcion IS NOT NULL THEN
			IF vm_flag_mant = 'M' THEN
				SELECT a10_descripcion FROM actt010 
					WHERE a10_descripcion =  
						rm_a10.a10_descripcion
					and ROWID <> bien[vm_indice]
			ELSE
				SELECT a10_descripcion FROM actt010
					WHERE a10_descripcion = 
						rm_a10.a10_descripcion
			END IF
			IF status <> NOTFOUND THEN
				CALL fgl_winmessage(vg_producto,
					'El nombre está repetido', 'info')
				NEXT FIELD a10_descripcion
			END IF
		END IF

	AFTER FIELD a10_grupo_act
		IF rm_a10.a10_grupo_act IS NOT NULL THEN
			CALL fl_lee_grupo_activo(vg_codcia, 
					rm_a10.a10_grupo_act)
				RETURNING r_grupo.* 
			IF r_grupo.a01_grupo_act IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe grupo de activo.',
						'exclamation')
				NEXT FIELD a10_grupo_act
			END IF	
			IF r_grupo.a01_grupo_act = 5 THEN
				CALL fl_mostrar_mensaje('No puede escojer este grupo de activo fijos. CONSULTE CON EL ADMINISTRADOR.', 'exclamation')
				NEXT FIELD a10_grupo_act
			END IF	
			DISPLAY r_grupo.a01_nombre TO desc_grupo_act
			DISPLAY r_grupo.a01_anos_util   TO a10_anos_util
			DISPLAY r_grupo.a01_porc_deprec TO a10_porc_deprec
                        DISPLAY BY NAME rm_a10.a10_tipo_act
			LET rm_a10.a10_moneda = rm_g13.g13_moneda 
			DISPLAY  BY NAME rm_a10.a10_moneda
		ELSE
			CLEAR desc_grupo_act
		END IF

	BEFORE FIELD a10_tipo_act
		LET rm_a10.a10_anos_util   = r_grupo.a01_anos_util
		LET rm_a10.a10_porc_deprec = r_grupo.a01_porc_deprec

	AFTER FIELD a10_tipo_act
		IF rm_a10.a10_tipo_act IS NOT NULL THEN
			CALL fl_lee_tipo_activo(vg_codcia, 
					rm_a10.a10_tipo_act)
				RETURNING r_tipo.*
			IF r_tipo.a02_tipo_act IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe tipo de activo.',
						'exclamation')
				NEXT FIELD a10_tipo_act
			END IF	
			IF r_tipo.a02_grupo_act = 5 THEN
				CALL fl_mostrar_mensaje('No puede escojer este tipo de activo fijos. CONSULTE CON EL ADMINISTRADOR.', 'exclamation')
				NEXT FIELD a10_tipo_act
			END IF	
			DISPLAY r_tipo.a02_nombre TO desc_tipo_act
		ELSE
			CLEAR desc_tipo_act
		END IF


        AFTER FIELD a10_anos_util
		IF rm_a10.a10_anos_util IS NOT NULL THEN
			LET rm_a10.a10_porc_deprec = 
				(100/rm_a10.a10_anos_util)
				DISPLAY BY NAME rm_a10.a10_porc_deprec
		END IF


	AFTER FIELD a10_locali_ori
		IF rm_a10.a10_locali_ori IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, 
					rm_a10.a10_locali_ori)
				RETURNING r_localidad.*
			IF r_localidad.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe localidad.',
						'exclamation')
				NEXT FIELD a10_locali_ori
			ELSE
				DISPLAY r_localidad.g02_nombre 
					TO desc_locali_ori
			END IF	
		ELSE
			CLEAR desc_locali_ori
		END IF


	AFTER FIELD a10_localidad
		IF rm_a10.a10_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, 
					rm_a10.a10_localidad)
				RETURNING r_localidad.*
			IF r_localidad.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe tipo de localidad.',
						'exclamation')
				NEXT FIELD a10_localidad
			ELSE
				DISPLAY r_localidad.g02_nombre 
					TO desc_localidad
			END IF	
		ELSE
			CLEAR desc_localidad
		END IF


	AFTER FIELD a10_cod_depto
		IF rm_a10.a10_cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, 
					rm_a10.a10_cod_depto)
				RETURNING r_departamento.*
			IF r_departamento.g34_cod_depto IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe departamento.',
						'exclamation')
				NEXT FIELD a10_cod_depto
			ELSE
				DISPLAY r_departamento.g34_nombre
					 TO desc_depto
			END IF	
		ELSE
			CLEAR desc_depto
		END IF

	AFTER FIELD a10_codprov
		IF rm_a10.a10_codprov IS NOT NULL THEN
			IF rm_a10.a10_locali_ori IS NULL THEN
				CALL fl_mostrar_mensaje('Ingrese primero la localidad.', 'exclamation')
				NEXT FIELD a10_codprov
			END IF
			CALL fl_lee_proveedor(rm_a10.a10_codprov)
				RETURNING r_proveedor.*
			IF r_proveedor.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe proveedor.',
						'exclamation')
				NEXT FIELD a10_codprov
			END IF	
			DISPLAY r_proveedor.p01_nomprov TO desc_prov
			IF r_proveedor.p01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD a10_codprov
                        END IF		 
			CALL fl_lee_proveedor_localidad(vg_codcia,
							rm_a10.a10_locali_ori,
							rm_a10.a10_codprov)
		 		RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no esta activado para esta localidad.','exclamation')
				NEXT FIELD a10_codprov
			END IF
		ELSE
			CLEAR desc_prov
		END IF
	
	AFTER FIELD a10_moneda
		IF rm_a10.a10_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_a10.a10_moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe moneda.',
						'exclamation')
				NEXT FIELD a10_moneda
			ELSE
				DISPLAY r_moneda.g13_nombre
					 TO desc_moneda
                       		 IF r_moneda.g13_estado = 'B' THEN
                                	CALL fl_mensaje_estado_bloqueado()
                                	NEXT FIELD a10_moneda
                        	END IF
			    IF rm_a10.a10_moneda = rm_g13.g13_moneda THEN
				LET rm_a10.a10_paridad = 1
				DISPLAY BY NAME rm_a10.a10_paridad 
			    ELSE
                                CALL fl_lee_factor_moneda(rm_a10.a10_moneda,
        				                  rm_g13.g13_moneda)
                                        RETURNING r_mon_par.*
                                IF r_mon_par.g14_serial IS NULL THEN
                                    CALL fgl_winmessage(vg_producto,'La paridad para esta moneda no existe.','exclamation')
                                    NEXT FIELD a10_moneda
				ELSE
                       		    LET rm_a10.a10_paridad = r_mon_par.g14_tasa
                        	    DISPLAY BY NAME rm_a10.a10_paridad
                                END IF
			    END IF
			END IF	
		ELSE
			CLEAR desc_moneda
		END IF

	AFTER FIELD a10_responsable
		IF rm_a10.a10_responsable IS NOT NULL THEN
			CALL fl_lee_responsable(vg_codcia, 
					rm_a10.a10_responsable)
				RETURNING r_responsable.*
			IF r_responsable.a03_responsable IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe responsable.',
						'exclamation')
				NEXT FIELD a10_responsable
			ELSE
				DISPLAY r_responsable.a03_nombres
					 TO desc_responsable
			END IF	
		ELSE
			CLEAR desc_responsable
		END IF

END INPUT

END FUNCTION



FUNCTION lee_datos_stock()
DEFINE resp      	CHAR(6)
DEFINE r_a01        	RECORD LIKE actt001.*
DEFINE r_a02        	RECORD LIKE actt002.*
DEFINE r_a03		RECORD LIKE actt003.*
DEFINE grupo_act	LIKE actt010.a10_grupo_act
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE desc_grupo	LIKE actt001.a01_nombre
DEFINE tipo		LIKE actt010.a10_tipo_act
DEFINE desc_tipo	LIKE actt002.a02_nombre
DEFINE responsable 	LIKE actt003.a03_responsable
DEFINE nombre     	LIKE actt003.a03_nombres

IF rm_a10.a10_tot_dep_mb <> 0 THEN
	LET grupo_act = rm_a10.a10_grupo_act
END IF
LET int_flag = 0 
INPUT BY NAME rm_a10.a10_descripcion, rm_a10.a10_grupo_act, rm_a10.a10_tipo_act,
	rm_a10.a10_responsable
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF field_touched(rm_a10.a10_descripcion, rm_a10.a10_grupo_act,
				 rm_a10.a10_tipo_act, rm_a10.a10_responsable)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				EXIT INPUT
			END IF
		ELSE
                        CLEAR FORM
			EXIT INPUT
                END IF       	
	ON KEY(F2)
		IF INFIELD(a10_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
				RETURNING grupo, desc_grupo
			IF grupo IS NOT NULL THEN
				LET rm_a10.a10_grupo_act = grupo
				DISPLAY BY NAME rm_a10.a10_grupo_act
				DISPLAY desc_grupo TO desc_grupo_act
			END IF 
		END IF
		IF INFIELD(a10_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
							rm_a10.a10_grupo_act) 
				RETURNING tipo, desc_tipo
			IF tipo IS NOT NULL THEN
				LET rm_a10.a10_tipo_act = tipo
				DISPLAY BY NAME rm_a10.a10_tipo_act
				DISPLAY desc_tipo TO desc_tipo_act
			END IF
		END IF 
		IF INFIELD(a10_responsable) THEN
			CALL fl_ayuda_responsable(vg_codcia) 
				RETURNING responsable, nombre 
			IF responsable IS NOT NULL THEN
				LET rm_a10.a10_responsable = responsable
				DISPLAY BY NAME rm_a10.a10_responsable
				DISPLAY nombre TO desc_responsable
			END IF 
		END IF
		LET int_flag = 0
	AFTER FIELD a10_descripcion
		IF rm_a10.a10_descripcion IS NOT NULL THEN
			IF vm_flag_mant = 'M' THEN
				SELECT a10_descripcion FROM actt010 
					WHERE a10_descripcion =  
						rm_a10.a10_descripcion
					and ROWID <> bien[vm_indice]
			ELSE
				SELECT a10_descripcion FROM actt010
					WHERE a10_descripcion = 
						rm_a10.a10_descripcion
			END IF
			IF status <> NOTFOUND THEN
				CALL fgl_winmessage(vg_producto,
					'El nombre está repetido', 'info')
				NEXT FIELD a10_descripcion
			END IF
		END IF
	AFTER FIELD a10_grupo_act
		IF rm_a10.a10_grupo_act IS NOT NULL THEN
			IF rm_a10.a10_tot_dep_mb = 0 THEN
				CALL fl_lee_grupo_activo(vg_codcia, 
							rm_a10.a10_grupo_act)
					RETURNING r_a01.* 
				IF r_a01.a01_grupo_act IS NULL THEN
					CALL fgl_winmessage(vg_producto,'No existe grupo de activo.','exclamation')
					NEXT FIELD a10_grupo_act
				END IF	
				DISPLAY r_a01.a01_nombre TO desc_grupo_act
				LET rm_a10.a10_anos_util = r_a01.a01_anos_util
				LET rm_a10.a10_porc_deprec =
							r_a01.a01_porc_deprec
				DISPLAY r_a01.a01_anos_util   TO a10_anos_util
				DISPLAY r_a01.a01_porc_deprec TO a10_porc_deprec
			END IF
		ELSE
			CLEAR desc_grupo_act
		END IF
		IF rm_a10.a10_tot_dep_mb <> 0 THEN
			LET rm_a10.a10_grupo_act = grupo_act
			CALL fl_lee_grupo_activo(vg_codcia,rm_a10.a10_grupo_act)
				RETURNING r_a01.* 
			DISPLAY r_a01.a01_nombre TO desc_grupo_act
		END IF
	AFTER FIELD a10_tipo_act
		IF rm_a10.a10_tipo_act IS NOT NULL THEN
			CALL fl_lee_tipo_activo(vg_codcia, 
					rm_a10.a10_tipo_act)
				RETURNING r_a02.*
			IF r_a02.a02_tipo_act IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe tipo de activo.',
						'exclamation')
				NEXT FIELD a10_tipo_act
			END IF	
			DISPLAY r_a02.a02_nombre TO desc_tipo_act
		ELSE
			CLEAR desc_tipo_act
		END IF
	AFTER FIELD a10_responsable
		IF rm_a10.a10_responsable IS NOT NULL THEN
			CALL fl_lee_responsable(vg_codcia,
						rm_a10.a10_responsable)
				RETURNING r_a03.*
			IF r_a03.a03_responsable IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						'No existe responsable.',
						'exclamation')
				NEXT FIELD a10_responsable
			END IF	
			DISPLAY r_a03.a03_nombres TO desc_responsable
		ELSE
			CLEAR desc_responsable
		END IF
END INPUT

END FUNCTION



FUNCTION control_bloqueo()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)

IF rm_a10.a10_estado <> 'A' AND rm_a10.a10_estado <> 'B' THEN
	CALL fl_mostrar_mensaje('El Estado del Codigo del Bien debe ser ACTIVO o BLOQUEADO.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_eli CURSOR FOR
	SELECT * FROM actt010
		WHERE ROWID = bien[vm_indice]
	FOR UPDATE
OPEN q_eli
FETCH q_eli INTO rm_a10.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET int_flag = 0
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(bien[vm_indice])
	RETURN
END IF
LET mensaje = 'Codigo del Bien se ha '
CASE rm_a10.a10_estado
	WHEN 'A'
		LET rm_a10.a10_estado = 'B'
		LET mensaje           = mensaje CLIPPED, ' Bloqueado. OK'
	WHEN 'B'
		LET rm_a10.a10_estado = 'A' 
		LET mensaje           = mensaje CLIPPED, ' Activado. OK'
END CASE
CALL muestra_estado()
UPDATE actt010
	SET a10_estado = rm_a10.a10_estado
	WHERE CURRENT OF q_eli
COMMIT WORK
CALL lee_muestra_registro(bien[vm_indice])
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_a01          RECORD LIKE actt001.*
DEFINE r_a02        	RECORD LIKE actt002.*
DEFINE r_localidad      RECORD LIKE gent002.*
DEFINE r_departamento   RECORD LIKE gent034.*
DEFINE r_proveedor      RECORD LIKE cxpt001.*
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_a03	RECORD LIKE actt003.*

IF vm_num_rows < 1 THEN
	CLEAR FORM
	RETURN
END IF

SELECT * INTO rm_a10.* FROM actt010 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
	RETURN
END IF


DISPLAY BY NAME  rm_a10.a10_codigo_bien, rm_a10.a10_estado,    
	rm_a10.a10_descripcion, rm_a10.a10_grupo_act, rm_a10.a10_tipo_act, 
	rm_a10.a10_anos_util, rm_a10.a10_porc_deprec, rm_a10.a10_modelo, 
	rm_a10.a10_serie, rm_a10.a10_locali_ori, rm_a10.a10_numero_oc, 
	rm_a10.a10_localidad, rm_a10.a10_cod_depto, rm_a10.a10_codprov,
	rm_a10.a10_fecha_comp, rm_a10.a10_moneda, rm_a10.a10_paridad, 
	rm_a10.a10_valor, rm_a10.a10_valor_mb, rm_a10.a10_responsable, 
	rm_a10.a10_fecha_baja, rm_a10.a10_val_dep_mb, rm_a10.a10_val_dep_ma, 
	rm_a10.a10_tot_dep_mb, rm_a10.a10_tot_dep_ma, rm_a10.a10_tot_reexpr, 
	rm_a10.a10_tot_dep_ree, rm_a10.a10_usuario, rm_a10.a10_fecing

CLEAR desc_estado, desc_grupo_act, desc_tipo_act, desc_locali_ori,
	desc_localidad, desc_depto, desc_prov, desc_moneda, desc_responsable

CALL fl_lee_grupo_activo(vg_codcia, rm_a10.a10_grupo_act)
	RETURNING r_a01.*
	DISPLAY r_a01.a01_nombre TO desc_grupo_act

CALL fl_lee_tipo_activo(vg_codcia, rm_a10.a10_tipo_act)
	RETURNING r_a02.*
	DISPLAY r_a02.a02_nombre TO desc_tipo_act

CALL fl_lee_localidad(vg_codcia, rm_a10.a10_locali_ori)
	RETURNING r_localidad.*
	DISPLAY r_localidad.g02_nombre TO desc_locali_ori

CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad)
	RETURNING r_localidad.*
	DISPLAY r_localidad.g02_nombre TO desc_localidad

CALL fl_lee_departamento(vg_codcia, rm_a10.a10_cod_depto)
	RETURNING r_departamento.*
	DISPLAY r_departamento.g34_nombre TO desc_depto

CALL fl_lee_proveedor(rm_a10.a10_codprov)
	RETURNING r_proveedor.*
	DISPLAY r_proveedor.p01_nomprov TO desc_prov

CALL fl_lee_moneda(rm_a10.a10_moneda)
	RETURNING r_moneda.*
	DISPLAY r_moneda.g13_nombre TO desc_moneda

CALL fl_lee_responsable(vg_codcia, rm_a10.a10_responsable)
	RETURNING r_a03.*
	DISPLAY r_a03.a03_nombres TO desc_responsable

CALL muestra_contadores()
CALL muestra_estado()

END FUNCTION


                                                                                
FUNCTION muestra_contadores()

DISPLAY "  " TO desc_estado
CLEAR desc_estado
DISPLAY vm_indice, vm_num_rows TO actual2, final2
DISPLAY vm_indice, vm_num_rows TO actual, final

END FUNCTION



FUNCTION muestra_estado()
DEFINE r_a06		RECORD LIKE actt006.*

CALL fl_lee_estado_activos(vg_codcia, rm_a10.a10_estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
END IF
DISPLAY BY NAME rm_a10.a10_estado
DISPLAY r_a06.a06_descripcion TO desc_estado

END FUNCTION



FUNCTION orden_compra()
DEFINE command_line	VARCHAR(255)
DEFINE run_prog		VARCHAR(10)

IF rm_a10.a10_numero_oc IS NULL THEN
	CALL fl_mostrar_mensaje('Este Bien no tiene una orden de compra asociada.', 'exclamation')
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_line = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS',
			vg_separador, 'fuentes', vg_separador, run_prog,
			'ordp200 ', vg_base, ' ', 'OC', ' ', vg_codcia,
			' ', vg_codloc, ' ', rm_a10.a10_numero_oc
RUN command_line

END FUNCTION
