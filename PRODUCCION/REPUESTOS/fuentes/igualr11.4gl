DATABASE acero_gm


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base, base1	CHAR(20)



MAIN

	IF num_args() <> 3 AND num_args() <> 4 THEN
		DISPLAY 'Numeros Parametros Incorrectos. Falta SERVIDOR LOCAL o SERVIDOR REMOTO QUE LOC y UNO_TODOS.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	CASE num_args()
		WHEN 3
			CALL ejecutar_proceso_principal1()
		WHEN 4
			CALL ejecutar_proceso_principal2()
	END CASE

END MAIN



FUNCTION ejecutar_proceso_principal1()
DEFINE serv_loc		CHAR(20)

DISPLAY 'Iniciando proceso de igualar rept011 nacional (Remoto) ...'
LET serv_loc = arg_val(1)

IF arg_val(2) = 1 OR arg_val(3) = "T" THEN
	{
	CALL igualar_rept011_todos_servidores('acero_gm', serv_loc,1,'acero_gc',
						'acgye02')
	}
	CALL igualar_rept011_todos_servidores('acero_gm', serv_loc,1,'acero_qm',
						'ACUIO01')
	CALL igualar_rept011_todos_servidores('acero_gm', serv_loc,1,'acero_qs',
						'ACUIO02')
END IF

IF arg_val(2) = 2 OR arg_val(3) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_gc','acgye02',2,'acero_gm',
						serv_loc)
	CALL igualar_rept011_todos_servidores('acero_gc','acgye02',2,'acero_qm',
						'ACUIO01')
	CALL igualar_rept011_todos_servidores('acero_gc','acgye02',2,'acero_qs',
						'ACUIO02')
END IF

IF arg_val(2) = 3 OR arg_val(3) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_qm','ACUIO01',3,'acero_gm',
						serv_loc)
	CALL igualar_rept011_todos_servidores('acero_qm','ACUIO01',3,'acero_gc',
						'acgye02')
	CALL igualar_rept011_todos_servidores('acero_qm','ACUIO01',3,'acero_qs',
						'ACUIO02')
END IF

IF arg_val(2) = 4 OR arg_val(3) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_qs','ACUIO02',4,'acero_gm',
						serv_loc)
	CALL igualar_rept011_todos_servidores('acero_qs','ACUIO02',4,'acero_gc',
						'acgye02')
	CALL igualar_rept011_todos_servidores('acero_qs','ACUIO02',4,'acero_qm',
						'ACUIO01')
END IF

DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION ejecutar_proceso_principal2()
DEFINE serv_loc		CHAR(20)
DEFINE serv_rem		CHAR(20)

DISPLAY 'Iniciando proceso de igualar rept011 nacional (Local) ...'
LET serv_loc = arg_val(1)
LET serv_rem = arg_val(2)

IF arg_val(3) = 1 OR arg_val(4) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_gm', serv_loc,1,'acero_gc',
						serv_rem)
	CALL igualar_rept011_todos_servidores('acero_gm', serv_loc,1,'acero_qm',
						serv_rem)
	CALL igualar_rept011_todos_servidores('acero_gm', serv_loc,1,'acero_qs',
						serv_rem)
END IF

IF arg_val(3) = 2 OR arg_val(4) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_gc', serv_rem,2,'acero_gm',
						serv_loc)
	CALL igualar_rept011_todos_servidores('acero_gc', serv_rem,2,'acero_qm',
						serv_rem)
	CALL igualar_rept011_todos_servidores('acero_gc', serv_rem,2,'acero_qs',
						serv_rem)
END IF

IF arg_val(3) = 3 OR arg_val(4) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_qm', serv_rem,3,'acero_gm',
						serv_loc)
	CALL igualar_rept011_todos_servidores('acero_qm', serv_rem,3,'acero_gc',
						serv_rem)
	CALL igualar_rept011_todos_servidores('acero_qm', serv_rem,3,'acero_qs',
						serv_rem)
END IF

IF arg_val(3) = 4 OR arg_val(4) = "T" THEN
	CALL igualar_rept011_todos_servidores('acero_qs', serv_rem,4,'acero_gm',
						serv_loc)
	CALL igualar_rept011_todos_servidores('acero_qs', serv_rem,4,'acero_gc',
						serv_rem)
	CALL igualar_rept011_todos_servidores('acero_qs', serv_rem,4,'acero_qm',
						serv_rem)
END IF

DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION igualar_rept011_todos_servidores(bd1, serv1, loc, bd2, serv2)
DEFINE bd1, serv1	CHAR(20)
DEFINE loc		LIKE gent002.g02_localidad
DEFINE bd2, serv2	CHAR(20)

SET ISOLATION TO DIRTY READ
LET codloc = loc
CALL alzar_base_ser(bd1, serv1)
CALL descargar_rept011(bd1, serv1)
CALL alzar_base_ser(bd2, serv2)
CALL crear_temporal()
CALL cargar_temporal()
BEGIN WORK
	CALL procesar_tabla(bd1, serv1, bd2, serv2)
COMMIT WORK
CALL borrar_tabla_tr()

END FUNCTION



FUNCTION alzar_base_ser(b, s)
DEFINE b, s		CHAR(20)

LET base  = b
LET base1 = base CLIPPED
LET base  = base CLIPPED, '@', s
CALL activar_base()

END FUNCTION



FUNCTION activar_base()
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base1
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION descargar_rept011(bd1, serv1)
DEFINE bd1, serv1	CHAR(20)
DEFINE loc2		LIKE gent002.g02_localidad

DISPLAY ' '
DISPLAY 'Descargando rept011 de ', bd1 CLIPPED, ' ', serv1 CLIPPED, ' ...'
LET loc2 = 0
IF codloc = 3 THEN
	LET loc2 = 5
END IF
UNLOAD TO "rept011.txt"
	SELECT * FROM rept011
		WHERE r11_compania  = codcia
		  AND r11_bodega   IN (SELECT r02_codigo FROM rept002
					WHERE r02_compania   = codcia
					  AND r02_tipo      <> 'S'
					  AND r02_area       = 'R'
					  AND r02_localidad IN (codloc, loc2))
DISPLAY 'Descargada rept011 de ', bd1 CLIPPED, ' ', serv1 CLIPPED, ' ...'

END FUNCTION



FUNCTION crear_temporal()

DISPLAY ' '
DISPLAY 'Creando tabla temporal temp_r11 ...'
SELECT * FROM rept011 WHERE r11_compania = 17 INTO TEMP temp_r11
DISPLAY 'Creada tabla temporal temp_r11 ...'

END FUNCTION



FUNCTION cargar_temporal()

DISPLAY ' '
DISPLAY 'Cargando tabla temporal temp_r11 para el proceso ...'
LOAD FROM "rept011.txt" INSERT INTO temp_r11
DISPLAY 'Cargada tabla temporal temp_r11 ...'

END FUNCTION



FUNCTION procesar_tabla(bd1, serv1, bd2, serv2)
DEFINE bd1, serv1	CHAR(20)
DEFINE bd2, serv2	CHAR(20)

DISPLAY ' '
DISPLAY 'Procesando Actualizaci�n rept011 de ', bd1 CLIPPED, ' ', serv1 CLIPPED,
	' en ', bd2 CLIPPED, ' ', serv2 CLIPPED, '. Espere ...'
CALL procesar_rept011_borrar(bd2, serv2)
CALL procesar_rept011_insertar(bd2, serv2)

END FUNCTION



FUNCTION procesar_rept011_borrar(bd2, serv2)
DEFINE bd2, serv2	CHAR(20)
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r11_t		RECORD LIKE rept011.*
DEFINE loc2		LIKE gent002.g02_localidad
DEFINE fec_i, fec_f	LIKE rept020.r20_fecing
DEFINE cuanto		INTEGER
DEFINE i, j, l		INTEGER

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM temp_r11
IF cuanto = 0 THEN
	DISPLAY 'No hay Items con Stock para procesar ...'
	RETURN
END IF
LET loc2 = 0
IF codloc = 3 THEN
	LET loc2 = 5
END IF
SELECT * FROM rept011
	WHERE r11_compania  = codcia
	  AND r11_bodega   IN (SELECT r02_codigo FROM rept002
				WHERE r02_compania   = codcia
				  AND r02_tipo      <> 'S'
				  AND r02_area       = 'R'
				  AND r02_localidad IN (codloc, loc2))
	INTO TEMP t_rept011
DISPLAY 'Procesando rept011 para borrar en ', bd2 CLIPPED, ' ', serv2 CLIPPED,
	' ...'
DISPLAY '  Total registros en temp_r11 es de ', cuanto USING "<<<<<&"
SELECT COUNT(*) INTO cuanto FROM t_rept011
DISPLAY '  Total registros de rept011 en ', bd2 CLIPPED, ' ', serv2 CLIPPED,
	' es de ', cuanto USING "<<<<<&"
SELECT a.*, b.r11_compania cia, b.r11_bodega bod, b.r11_item b
	FROM t_rept011 a, OUTER temp_r11 b
	WHERE a.r11_compania = b.r11_compania
	  AND a.r11_bodega   = b.r11_bodega
	  AND a.r11_item     = b.r11_item
	INTO TEMP temp_t1
DECLARE q_bod CURSOR FOR SELECT * FROM temp_t1 WHERE cia IS NULL
LET i     = 0
LET j     = 0
LET l     = 0
LET fec_i = EXTEND(MDY(12, 31, 2002), YEAR TO SECOND)
LET fec_f = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR + 59 UNITS MINUTE
		+ 59 UNITS SECOND  
FOREACH q_bod INTO r_r11.*
	LET i = i + 1
	SELECT COUNT(*) INTO cuanto
		FROM rept020
		WHERE r20_compania   = codcia
		  AND r20_localidad IN (codloc, loc2)
		  AND r20_bodega     = r_r11.r11_bodega
		  AND r20_item       = r_r11.r11_item
		  AND r20_fecing    BETWEEN fec_i AND fec_f
	IF cuanto > 0 THEN
		DISPLAY 'No se Borrar� registro rept011 en ', bd2 CLIPPED, ' ',
			serv2 CLIPPED, ': ', r_r11.r11_bodega, ' ',
			r_r11.r11_item CLIPPED, ' tiene movimientos.'
		LET l = l + 1
		CONTINUE FOREACH
	END IF
	DELETE FROM rept011
		WHERE r11_compania = r_r11.r11_compania
		  AND r11_bodega   = r_r11.r11_bodega
		  AND r11_item     = r_r11.r11_item
	IF STATUS = 0 THEN
		DISPLAY 'Borrando registro rept011 en ', bd2 CLIPPED, ' ',
			serv2 CLIPPED, ': ', r_r11.r11_bodega, ' ',
			r_r11.r11_item CLIPPED
		LET j = j + 1
	END IF
END FOREACH
DROP TABLE temp_t1
DISPLAY 'Se Procesaron ', i USING "<<<<<&", ' registros rept011. OK'
IF j > 0 THEN
	DISPLAY 'Se Borraron ', j USING "<<<&", ' registros en rept011. OK'
ELSE
	DISPLAY 'No se Borr� ningun registros en la rept011. OK'
END IF
IF l > 0 THEN
	DISPLAY 'No se Borraron ', l USING "<<<&", ' reg. en rept011 con movimientos. OK'
END IF

END FUNCTION



FUNCTION procesar_rept011_insertar(bd2, serv2)
DEFINE bd2, serv2	CHAR(20)
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r11_t		RECORD LIKE rept011.*
DEFINE loc2		LIKE gent002.g02_localidad
DEFINE cuanto		INTEGER
DEFINE i, j		INTEGER

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM temp_r11
IF cuanto = 0 THEN
	DISPLAY 'No hay Items con Stock para procesar ...'
	RETURN
END IF
LET loc2 = 0
IF codloc = 3 THEN
	LET loc2 = 5
END IF
SELECT a.*, b.r11_compania cia, b.r11_bodega bod, b.r11_item b
	FROM temp_r11 a, OUTER t_rept011 b
	WHERE a.r11_compania = b.r11_compania
	  AND a.r11_bodega   = b.r11_bodega
	  AND a.r11_item     = b.r11_item
	INTO TEMP temp_t1
DECLARE q_bod2 CURSOR FOR SELECT * FROM temp_t1 WHERE cia IS NULL
DISPLAY 'Procesando temp_r11 para insertar en rept011 ...'
LET i = 0
LET j = 0
FOREACH q_bod2 INTO r_r11.*
	LET i = i + 1
	INSERT INTO rept011 VALUES(r_r11.*)
	IF STATUS = 0 THEN
		DISPLAY 'Insertando registro rept011 en ', bd2 CLIPPED, ' ',
			serv2 CLIPPED, ': ', r_r11.r11_bodega, ' ',
			r_r11.r11_item CLIPPED
		LET j = j + 1
	END IF
END FOREACH
DROP TABLE t_rept011
DROP TABLE temp_t1
DISPLAY 'Se Procesaron ', i USING "<<<<<&", ' registros rept011. OK'
IF j > 0 THEN
	DISPLAY 'Se Insertaron ', j USING "<<<&", ' registros en rept011. OK'
ELSE
	DISPLAY 'No se Insert� ningun registros en la rept011. OK'
END IF

END FUNCTION



FUNCTION borrar_tabla_tr()

DISPLAY ' '
DROP TABLE temp_r11
DISPLAY 'Borrando la tabla temporal ...'
RUN ' rm rept011.txt'

END FUNCTION
