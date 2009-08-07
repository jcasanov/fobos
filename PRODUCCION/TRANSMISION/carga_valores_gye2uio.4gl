DATABASE diteca
DEFINE vg_codcia		LIKE gent001.g01_compania
DEFINE vg_codloc		LIKE gent002.g02_localidad
DEFINE local_dest		LIKE gent002.g02_localidad
DEFINE vm_base_ori		CHAR(25)
DEFINE vm_base_des		CHAR(25)

MAIN

CALL startlog('errores')
LET vg_codcia  = 1
LET vg_codloc  = 1      
IF num_args() <> 1 THEN
	DISPLAY 'Sintaxis: fglrun baja_valores local_dest '
	EXIT PROGRAM
END IF 
LET local_dest = arg_val(1)

LET vm_base_ori  = 'diteca@ol_server'
CASE local_dest
        WHEN 2
                LET vm_base_des  = 'diteca_qm@ol_serverqm'
END CASE

CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r93		RECORD LIKE rept093.*

SELECT * INTO r_g02.* FROM gent002 
	WHERE g02_compania = vg_codcia AND g02_matriz = 'S' 
IF status = NOTFOUND THEN
	DISPLAY 'No existe localidad matriz en compania: ', vg_codcia
	EXIT PROGRAM
END IF

{*
 * Primero descargo los items con fob > 0 en la base diteca (Matriz)
 * en el archivo rept093
 *}
DATABASE vm_base_ori

DELETE FROM rept093
DELETE FROM rept094

DISPLAY 'Cargando nuevo fob...'

UNLOAD TO 'rept093.txt'
SELECT r10_compania, r10_codigo, r10_fob
  FROM rept010
 WHERE r10_compania = vg_codcia
   AND r10_fob > 0 

{*
 * Luego conecto a la base de la localidad destino 
 *}
DATABASE vm_base_des

{*
 * Se carga los items y sus valores en la rept093
 *}

DISPLAY 'Encerando items...'

DECLARE q_r10 CURSOR FOR SELECT * FROM rept010 WHERE r10_fob > 0

FOREACH q_r10 INTO r_r10.*
	UPDATE rept010 SET r10_fob = 0
	 WHERE r10_compania = r_r10.r10_compania
           AND r10_codigo   = r_r10.r10_codigo
END FOREACH

DISPLAY 'Cargando datos de la 93'
DELETE FROM rept093
DELETE FROM rept094
LOAD FROM 'rept093.txt' INSERT INTO rept093
	
{*
 * Se actualizan los datos, si el item de la rept093 no esta en la rept010
 * se graba en la rept094 para sincronizar luego los items
 *}
DISPLAY 'Actualizando datos...'
DECLARE q_rept093 CURSOR FOR SELECT * FROM rept093
FOREACH q_rept093 INTO r_r93.*
	SELECT * FROM rept010
	 WHERE r10_compania = r_r93.r93_compania
	   AND r10_codigo   = r_r93.r93_item

	IF STATUS = NOTFOUND THEN
		INSERT INTO rept094 VALUES (r_r93.r93_compania, 
                                            r_r93.r93_item)
	ELSE
		UPDATE rept010 SET r10_fob = r_r93.r93_fob
		 WHERE r10_compania = r_r93.r93_compania 
		   AND r10_codigo   = r_r93.r93_item 
	END IF
END FOREACH

{*
 * Descargo para sincronizar y regreso a la base original
 *}
UNLOAD TO 'rept094.txt' SELECT * FROM rept094

DATABASE vm_base_ori

SELECT * FROM rept010 WHERE r10_compania = 99 INTO TEMP te_rept010
LOAD FROM 'rept094.txt' INSERT INTO rept094

INSERT INTO te_rept010
SELECT rept010.* FROM rept010, rept094
 WHERE r10_compania = r94_compania
   AND r10_codigo   = r94_item   

UNLOAD TO 'te_rept010.txt' SELECT * FROM te_rept010 

{*
 * Vuelvo a la base de la localidad destino 
 *}
DATABASE vm_base_des

SELECT * FROM rept010 WHERE r10_compania = 99 INTO TEMP te_rept010
LOAD FROM 'te_rept010.txt' INSERT INTO te_rept010

DECLARE q_rept010 CURSOR FOR SELECT * FROM te_rept010 

FOREACH q_rept010 INTO r_r10.*
	WHENEVER ERROR CONTINUE
display 'insertando nuevos items: ', r_r10.r10_codigo
	INSERT INTO rept010 VALUES(r_r10.*)
	WHENEVER ERROR STOP
END FOREACH

RUN 'rm -f rept093.txt'
RUN 'rm -f rept094.txt'
RUN 'rm -f te_rept010.txt'

END FUNCTION
