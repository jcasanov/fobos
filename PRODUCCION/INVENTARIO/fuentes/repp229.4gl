--------------------------------------------------------------------------------
-- Titulo               : repp229.4gl -- CIERRE MENSUAL DE REPUESTOS
-- Elaboración          : 30-abr-2002
-- Autor                : GVA
-- Formato de Ejecución : fglrun repp229 base modulo compañia localidad
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_anio		VARCHAR(4)
DEFINE vm_mes		VARCHAR(2)
DEFINE rm_r00		RECORD LIKE rept000.*



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF

LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_codloc	= arg_val(4)

LET vg_proceso	= 'repp229'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE resp 		VARCHAR(6)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE mens_mes 	VARCHAR(20)

CALL fl_nivel_isolation()

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 8
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp229 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_229 FROM '../forms/repf229_1'
ELSE
	OPEN FORM f_229 FROM '../forms/repf229_1c'
END IF
DISPLAY FORM f_229
CLEAR FORM

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe configuración para esta compania.','stop')
	CALL fl_mostrar_mensaje('No existe configuración para esta compania.','stop')
	EXIT PROGRAM
END IF

IF rm_r00.r00_anopro IS NULL THEN 
	LET vm_anio = YEAR(TODAY)
	LET vm_mes  = MONTH(TODAY)
ELSE
	LET vm_anio = rm_r00.r00_anopro
	LET vm_mes  = rm_r00.r00_mespro
END IF

DISPLAY BY NAME vm_anio, vm_mes

LET mens_mes = fl_retorna_nombre_mes(vm_mes)
DISPLAY mens_mes TO nom_mes

MENU 'OPCIONES'
	COMMAND KEY('C') 'Cerrar Mes'
		--CALL fgl_winquestion(vg_producto,'Está seguro que desea realizar el cierre del mes de INVENTARIO.','No','Yes|No|Cancel','question',1)
		CALL fl_hacer_pregunta('Está seguro que desea realizar el cierre del mes de INVENTARIO.','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			IF NOT validar_mes(vm_anio, vm_mes) THEN
				RETURN
			END IF
			IF control_cerrar_mes() THEN
				HIDE OPTION 'Cerrar Mes'
			END IF
		END IF 

	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION validar_mes(anho, mes)

DEFINE mes,anho		SMALLINT

DEFINE dia, mes2, anho2	SMALLINT
DEFINE fecha		DATE

IF anho < YEAR(TODAY) THEN
	RETURN 1
ELSE
	IF mes < MONTH(TODAY) THEN
		RETURN 1
	END IF
END IF

IF mes = 12 THEN
	LET mes2  = 1
	LET anho2 = anho + 1
ELSE
	LET mes2  = mes + 1
	LET anho2 = anho
END IF

LET fecha = mdy(mes2, 1, anho2)
LET fecha = fecha - 1

IF TODAY < fecha THEN
	--CALL fgl_winmessage(vg_producto,'Aún no se puede cerrar el mes.','exclamation')
	CALL fl_mostrar_mensaje('Aún no se puede cerrar el mes.','exclamation')
	RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION control_cerrar_mes()
DEFINE expr_sql 	CHAR(500)

BEGIN WORK

INITIALIZE rm_r00.* TO NULL

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_rept000 CURSOR FOR
	SELECT * FROM rept000 WHERE r00_compania = vg_codcia
	FOR UPDATE
OPEN  q_rept000
FETCH q_rept000 INTO rm_r00.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	SET LOCK MODE TO NOT WAIT
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
SET LOCK MODE TO NOT WAIT

DELETE FROM rept031 WHERE r31_compania = vg_codcia
		      AND r31_ano      = vm_anio
		      AND r31_mes      = vm_mes

LET expr_sql = 'INSERT INTO rept031 ',
		'SELECT r11_compania,', vm_anio, ',', vm_mes,
		', r11_bodega, r11_item, r11_stock_act,',
		'r10_costo_mb, r10_costo_ma, r10_precio_mb,',
		'r10_precio_ma',
		' FROM rept011, rept010 ',
		'WHERE r11_compania  =',vg_codcia,
		'  AND r11_stock_act > 0',
		'  AND r10_compania  = r11_compania',
		'  AND r10_codigo    = r11_item'

PREPARE sentencia FROM expr_sql
EXECUTE sentencia

IF status < 0 THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'Error... Proceso no se realizo.','exclamation')
	CALL fl_mostrar_mensaje('Error... Proceso no se realizo.','exclamation')
	RETURN 0
END IF

IF vm_mes = 12 THEN
	LET vm_mes  = 1
	LET vm_anio = vm_anio + 1
ELSE
	LET vm_mes  = vm_mes + 1
END IF

UPDATE rept000 SET r00_mespro = vm_mes, r00_anopro = vm_anio 
	WHERE CURRENT OF q_rept000 

COMMIT WORK
--CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')
CALL fl_mostrar_mensaje('Proceso realizado Ok.','info')
RETURN 1

END FUNCTION
