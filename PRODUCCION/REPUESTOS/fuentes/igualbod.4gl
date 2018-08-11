DATABASE acero_gm


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base, base1	CHAR(20)



MAIN

	IF num_args() <> 1 AND num_args() <> 2 THEN
		DISPLAY 'Numeros Parametros Incorrectos. Falta SERVIDOR LOCAL o SERVIDOR REMOTO.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	CASE num_args()
		WHEN 1
			CALL ejecutar_proceso_principal1()
		WHEN 2
			CALL ejecutar_proceso_principal2()
	END CASE

END MAIN



FUNCTION ejecutar_proceso_principal1()
DEFINE serv_loc		CHAR(20)

DISPLAY 'Iniciando proceso de Bodegas (Remoto) ...'
LET serv_loc = arg_val(1)
CALL igualar_bodegas_todos_servidores('acero_gm', serv_loc, 1, 'acero_gc',
					'ACGYE02')
CALL igualar_bodegas_todos_servidores('acero_gm', serv_loc, 1, 'acero_qm',
					'ACUIO01')
CALL igualar_bodegas_todos_servidores('acero_gm', serv_loc, 1, 'acero_qs',
					'ACUIO02')

CALL igualar_bodegas_todos_servidores('acero_gc', 'ACGYE02', 2, 'acero_gm',
					serv_loc)
CALL igualar_bodegas_todos_servidores('acero_gc', 'ACGYE02', 2, 'acero_qm',
					'ACUIO01')
CALL igualar_bodegas_todos_servidores('acero_gc', 'ACGYE02', 2, 'acero_qs',
					'ACUIO02')

CALL igualar_bodegas_todos_servidores('acero_qm', 'ACUIO01', 3, 'acero_gm',
					serv_loc)
CALL igualar_bodegas_todos_servidores('acero_qm', 'ACUIO01', 3, 'acero_gc',
					'ACGYE02')
CALL igualar_bodegas_todos_servidores('acero_qm', 'ACUIO01', 3, 'acero_qs',
					'ACUIO02')

CALL igualar_bodegas_todos_servidores('acero_qs', 'ACUIO02', 4, 'acero_gm',
					serv_loc)
CALL igualar_bodegas_todos_servidores('acero_qs', 'ACUIO02', 4, 'acero_gc',
					'ACGYE02')
CALL igualar_bodegas_todos_servidores('acero_qs', 'ACUIO02', 4, 'acero_qm',
					'ACUIO01')
DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION ejecutar_proceso_principal2()
DEFINE serv_loc		CHAR(20)
DEFINE serv_rem		CHAR(20)

DISPLAY 'Iniciando proceso de Bodegas (Local) ...'
LET serv_loc = arg_val(1)
LET serv_rem = arg_val(2)
CALL igualar_bodegas_todos_servidores('acero_gm', serv_loc, 1, 'acero_gc',
					serv_rem)
CALL igualar_bodegas_todos_servidores('acero_gm', serv_loc, 1, 'acero_qm',
					serv_rem)
CALL igualar_bodegas_todos_servidores('acero_gm', serv_loc, 1, 'acero_qs',
					serv_rem)

CALL igualar_bodegas_todos_servidores('acero_gc', serv_rem, 2, 'acero_gm',
					serv_loc)
CALL igualar_bodegas_todos_servidores('acero_gc', serv_rem, 2, 'acero_qm',
					serv_rem)
CALL igualar_bodegas_todos_servidores('acero_gc', serv_rem, 2, 'acero_qs',
					serv_rem)

CALL igualar_bodegas_todos_servidores('acero_qm', serv_rem, 3, 'acero_gm',
					serv_loc)
CALL igualar_bodegas_todos_servidores('acero_qm', serv_rem, 3, 'acero_gc',
					serv_rem)
CALL igualar_bodegas_todos_servidores('acero_qm', serv_rem, 3, 'acero_qs',
					serv_rem)

CALL igualar_bodegas_todos_servidores('acero_qs', serv_rem, 4, 'acero_gm',
					serv_loc)
CALL igualar_bodegas_todos_servidores('acero_qs', serv_rem, 4, 'acero_gc',
					serv_rem)
CALL igualar_bodegas_todos_servidores('acero_qs', serv_rem, 4, 'acero_qm',
					serv_rem)
DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION igualar_bodegas_todos_servidores(bd1, serv1, loc, bd2, serv2)
DEFINE bd1, serv1	CHAR(20)
DEFINE loc		LIKE gent002.g02_localidad
DEFINE bd2, serv2	CHAR(20)

SET ISOLATION TO DIRTY READ
LET codloc = loc
CALL alzar_base_ser(bd1, serv1)
CALL descargar_bodegas(bd1, serv1)
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



FUNCTION descargar_bodegas(bd1, serv1)
DEFINE bd1, serv1	CHAR(20)
DEFINE loc2		LIKE gent002.g02_localidad

DISPLAY ' '
DISPLAY 'Descargando Bodegas de ', bd1 CLIPPED, ' ', serv1 CLIPPED, ' ...'
LET loc2 = 0
IF codloc = 3 THEN
	LET loc2 = 5
END IF
UNLOAD TO "bodega.txt"
	SELECT * FROM rept002
		WHERE r02_compania   = codcia
		  AND r02_localidad IN (codloc, loc2)
DISPLAY 'Descargadas Bodegas de ', bd1 CLIPPED, ' ', serv1 CLIPPED, ' ...'

END FUNCTION



FUNCTION crear_temporal()

DISPLAY ' '
DISPLAY 'Creando tabla temporal de Bodega ...'
SELECT * FROM rept002 WHERE r02_codigo = 'CACA' INTO TEMP tr_bodega
DISPLAY 'Creada tabla temporal de Bodega ...'

END FUNCTION



FUNCTION cargar_temporal()

DISPLAY ' '
DISPLAY 'Cargando tabla temporal de Bodega para el proceso ...'
LOAD FROM "bodega.txt" INSERT INTO tr_bodega
DISPLAY 'Cargada tabla temporal para las Bodegas ...'

END FUNCTION



FUNCTION procesar_tabla(bd1, serv1, bd2, serv2)
DEFINE bd1, serv1	CHAR(20)
DEFINE bd2, serv2	CHAR(20)

DISPLAY ' '
DISPLAY 'Procesando Actualización Bodegas de ', bd1 CLIPPED, ' ', serv1 CLIPPED,
	' en ', bd2 CLIPPED, ' ', serv2 CLIPPED, '. Espere por favor ...'
CALL procesar_bodegas()

END FUNCTION



FUNCTION procesar_bodegas()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE cuanto		INTEGER
DEFINE i, j		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_bodega
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevas Bodegas para procesar ...'
	RETURN
END IF
DECLARE q_bod CURSOR FOR SELECT * FROM tr_bodega
DISPLAY 'Procesando Bodegas ...'
LET i = 0
LET j = 0
FOREACH q_bod INTO r_r02.*
	SELECT * FROM rept002
		WHERE r02_compania = r_r02.r02_compania
		  AND r02_codigo   = r_r02.r02_codigo
	IF STATUS <> NOTFOUND THEN
		UPDATE rept002
			SET r02_nombre  = r_r02.r02_nombre,
			    r02_estado  = r_r02.r02_estado,
			    r02_tipo    = r_r02.r02_tipo,
			    r02_area    = r_r02.r02_area,
			    r02_factura = r_r02.r02_factura
			WHERE r02_compania  = r_r02.r02_compania
			  AND r02_codigo    = r_r02.r02_codigo
			  AND r02_localidad = r_r02.r02_localidad
		IF STATUS = 0 THEN
			DISPLAY 'Actualizando Bodega ', r_r02.r02_codigo
			LET j = j + 1
		END IF
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando Bodega ', r_r02.r02_codigo
	CALL validar_usuario(r_r02.r02_usuario) RETURNING r_r02.r02_usuario
	LET r_r02.r02_fecing = CURRENT
	INSERT INTO rept002 VALUES(r_r02.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Bodegas. OK'
ELSE
	DISPLAY 'No se Inserto ninguna Bodega.'
END IF
IF j > 0 THEN
	DISPLAY 'Se Actualizaron ', j USING "<<<&", ' Bodegas. OK'
ELSE
	DISPLAY 'No se Actualizó ninguna Bodega.'
END IF

END FUNCTION



FUNCTION validar_usuario(usuario)
DEFINE usuario		LIKE gent005.g05_usuario

SELECT * FROM gent005 WHERE g05_usuario = usuario
IF STATUS = NOTFOUND THEN
	LET usuario = 'FOBOS'
END IF
RETURN usuario

END FUNCTION



FUNCTION borrar_tabla_tr()

DISPLAY ' '
DROP TABLE tr_bodega
DISPLAY 'Borrando la tabla temporal ...'
RUN ' rm bodega.txt'

END FUNCTION
