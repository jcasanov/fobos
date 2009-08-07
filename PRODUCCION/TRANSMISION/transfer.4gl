--------------------------------------------------------------------------------
-- Modificado: Por Nelson Pereda C. el 23/Ago/2004 para que sea a
--             nivel nacional la transmision de transferencia.
--
--
-- fglgo transfer {1, 2, 3, 4, 5, 6} {X}
--
--       1  envio de transferencias desde GYE a UIO
--       2  envio de transferencias desde UIO a GYE
--       X  Es solo utilizado el caso de que se ejecute directamente en lugar
--          del Menu
--------------------------------------------------------------------------------

DATABASE diteca

DEFINE vm_flag		CHAR(1)
DEFINE vm_codcia	INTEGER
DEFINE vm_local_ori	SMALLINT
DEFINE vm_local_des	SMALLINT
DEFINE vm_base_ori	CHAR(25)
DEFINE vm_base_des	CHAR(25)
DEFINE vm_usuario	CHAR(12)
DEFINE vm_transfer	SMALLINT



MAIN

CALL startlog('transfer.err')
LET vm_flag = 0
IF num_args() <> 1 AND num_args() <> 2 THEN
	DISPLAY 'Número de Parametros Incorrectos. Son: Localidad o X'
	EXIT PROGRAM
END IF
LET vm_flag = arg_val(1)
--IF num_args() != 1 OR vm_flag < 1 OR vm_flag > 3 THEN
IF vm_flag < 1 OR vm_flag > 2 THEN
	DISPLAY 'Sintaxis: fglrun transfer {1, 2}'
	SLEEP 3
	EXIT PROGRAM
END IF
LET vm_codcia = 1
CALL control_master_transferencia_entre_localidades()

END MAIN



FUNCTION control_master_transferencia_entre_localidades()
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE a		CHAR(2)

SET ISOLATION TO DIRTY READ
CASE vm_flag 
	WHEN 1
		LET vm_local_ori = 1
		LET vm_local_des = 2
		LET vm_base_ori  = 'diteca@ol_server'
		LET vm_base_des  = 'diteca_qm@ol_serverqm'
	WHEN 2
		LET vm_local_ori = 2
		LET vm_local_des = 1
		LET vm_base_ori  = 'diteca_qm@ol_serverqm'
		LET vm_base_des  = 'diteca@ol_server'
END CASE
CALL muestra_mensaje()
DATABASE vm_base_des
SELECT USER INTO vm_usuario FROM dual
LET vm_usuario = UPSHIFT(vm_usuario)
UNLOAD TO 'rept090.txt'
	SELECT * FROM rept090
		WHERE r90_compania  = vm_codcia AND 
		      r90_localidad = vm_local_ori AND 
		      r90_cod_tran  = 'TR' AND
                      r90_num_tran  =
			(SELECT MAX(r90_num_tran) FROM rept090
				WHERE r90_compania  = vm_codcia AND 
		      		      r90_localidad = vm_local_ori AND 
		      		      r90_cod_tran  = 'TR')
DATABASE vm_base_ori
SELECT * FROM rept090 WHERE r90_compania = 999
	INTO TEMP temp_rept090
LOAD FROM 'rept090.txt' INSERT INTO temp_rept090
SELECT * INTO r_r90.* FROM temp_rept090
IF status = NOTFOUND THEN
	LET r_r90.r90_num_tran = 0
END IF
SELECT r19_num_tran FROM rept019, rept002
	WHERE r19_compania    = vm_codcia AND 
	      r19_localidad   = vm_local_ori AND
              r19_cod_tran    = 'TR' AND
              r19_num_tran    > r_r90.r90_num_tran AND
	      r19_compania    = r02_compania AND 
              r19_bodega_dest = r02_codigo AND
--	      r02_tipo        <> 'S' AND
	      r02_localidad   = vm_local_des
	INTO TEMP te_transf
UNLOAD TO 'transf_cab.txt' 
	SELECT rept019.* FROM rept019
		WHERE r19_compania  = vm_codcia AND 
		      r19_localidad = vm_local_ori AND
                      r19_cod_tran  = 'TR' AND
                      r19_num_tran  IN (SELECT r19_num_tran FROM te_transf)
UNLOAD TO 'transf_det.txt' 
	SELECT rept020.* FROM rept020
		WHERE r20_compania  = vm_codcia AND 
		      r20_localidad = vm_local_ori AND
                      r20_cod_tran  = 'TR' AND
                      r20_num_tran  IN (SELECT r19_num_tran FROM te_transf)
DATABASE vm_base_des
SELECT * FROM rept019 WHERE r19_compania = 999 INTO TEMP temp_rept019
SELECT * FROM rept020 WHERE r20_compania = 999 INTO TEMP temp_rept020
BEGIN WORK
LOAD FROM 'transf_cab.txt' INSERT INTO temp_rept019
LOAD FROM 'transf_det.txt' INSERT INTO temp_rept020
CALL carga_transferencias()
COMMIT WORK
LET vm_transfer = 0
SELECT COUNT(*) INTO vm_transfer FROM temp_rept019 
DISPLAY 'Transferencias transmitidas: ', vm_transfer USING '&<<'
IF num_args() <> 2 THEN
	DISPLAY 'No olvidar desconectar modem.'
	LET a = fgl_getkey()
END IF
RUN ' rm -rf transf_cab.txt'
RUN ' rm -rf transf_det.txt'

END FUNCTION



FUNCTION carga_transferencias()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE r_r02		RECORD LIKE rept002.*

DECLARE qu_tr CURSOR FOR SELECT * FROM temp_rept019
	ORDER BY r19_num_tran
FOREACH qu_tr INTO r_r19.*
	SELECT * INTO r_r02.* FROM rept002
		WHERE r02_compania = r_r19.r19_compania AND
		      r02_codigo   = r_r19.r19_bodega_ori
	IF r_r02.r02_localidad != vm_local_ori THEN
		CONTINUE FOREACH
	END IF 
	SELECT * INTO r_r02.* FROM rept002
		WHERE r02_compania = r_r19.r19_compania AND
		      r02_codigo   = r_r19.r19_bodega_dest
	IF r_r02.r02_localidad != vm_local_des THEN
		CONTINUE FOREACH
	END IF 
	LET r_r19.r19_nomcli   = 'ORIGEN: TR-', r_r19.r19_num_tran 
					       USING '<<<<<<<'
	LET r_r19.r19_dircli   = r_r19.r19_nomcli
	LET vm_transfer = vm_transfer + 1
	DISPLAY 'Transmitiendo: TR-', r_r19.r19_num_tran USING '<<<<<<<'
	INSERT INTO rept091 VALUES (r_r19.*)
	DECLARE qu_dtr CURSOR FOR 
		SELECT * FROM temp_rept020
			WHERE r20_compania  = r_r19.r19_compania  AND 
			      r20_localidad = vm_local_ori AND 
			      r20_cod_tran  = r_r19.r19_cod_tran  AND
			      r20_num_tran  = r_r19.r19_num_tran
			ORDER BY r20_orden
	FOREACH qu_dtr INTO r_r20.*
		INSERT INTO rept092 VALUES (r_r20.*)
	END FOREACH
	INITIALIZE r_r90.* TO NULL
    	LET r_r90.r90_compania 		= vm_codcia
    	LET r_r90.r90_localidad 	= vm_local_ori
    	LET r_r90.r90_cod_tran 		= r_r20.r20_cod_tran
    	LET r_r90.r90_num_tran 		= r_r20.r20_num_tran
    	LET r_r90.r90_fecing 		= r_r20.r20_fecing
    	LET r_r90.r90_locali_fin 	= vm_local_des
    	LET r_r90.r90_fecing_fin 	= CURRENT
	INSERT INTO rept090 VALUES (r_r90.*)
END FOREACH

END FUNCTION



FUNCTION muestra_mensaje()
DEFINE a		CHAR(2)

CLEAR SCREEN
DISPLAY ''
DISPLAY '       Este programa transmite las transferencias entre localidades.'
DISPLAY '       Se puede ejecutar las veces que se desee, ya que controla que'
DISPLAY '       no se transmita dos veces una misma transferencia.'             
DISPLAY '       La información queda grabada en las tablas tenporales:'
DISPLAY '               rept091 (cabecera transacciones) '
DISPLAY '               rept092 (detalle  transacciones) '
DISPLAY ''
DISPLAY '       Posteriormente, cuando los items lleguen a su destino, el bode-'
DISPLAY '       guero ejecutará el proceso final que pondrá en producción, ac -'
DISPLAY '       tualizará stock, y promediará costos en la bodega destino.'
DISPLAY ''
         
IF vm_flag = 1 OR vm_flag = 2 THEN
	DISPLAY 'Conecte modem a Quito y presione <Enter>.'
END IF
DISPLAY ''
--IF num_args() <> 2 THEN
--	LET a = fgl_getkey()
--END IF

END FUNCTION
