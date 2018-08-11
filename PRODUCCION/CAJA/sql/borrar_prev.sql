BEGIN WORK;
{
SELECT * FROM cajt010
	WHERE j10_compania     = 1
	  AND j10_localidad    = 1
	  AND j10_estado      <> 'P'
	  AND j10_tipo_fuente  = 'PR'
	INTO TEMP tmp_j10;
SELECT r23_compania cia, r23_localidad loc, r23_numprev num_p
	FROM tmp_j10, rept023
	WHERE r23_compania      = j10_compania
	  AND r23_localidad     = j10_localidad
	  AND r23_numprev       = j10_num_fuente
	  AND r23_estado       <> "F"
	  AND r23_cod_tran     IS NULL
	  AND DATE(r23_fecing) < TODAY
	INTO TEMP tmp_r23;
DROP TABLE tmp_j10;
}
SELECT r23_compania cia, r23_localidad loc, r23_numprev num_p
	FROM rept023
	WHERE r23_compania      = 1
	  AND r23_localidad     = 1
	  AND r23_numprev      in (59974, 60022)
	  AND r23_estado       <> "F"
	  AND r23_cod_tran     IS NULL
	INTO TEMP tmp_r23;
SELECT COUNT(*) cuantos FROM tmp_r23;
DELETE FROM rept027
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept027.r27_compania
		  	  AND tmp_r23.loc   = rept027.r27_localidad
		          AND tmp_r23.num_p = rept027.r27_numprev);
DELETE FROM rept026
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept026.r26_compania
		  	  AND tmp_r23.loc   = rept026.r26_localidad
		          AND tmp_r23.num_p = rept026.r26_numprev);
DELETE FROM rept025
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept025.r25_compania
		  	  AND tmp_r23.loc   = rept025.r25_localidad
		          AND tmp_r23.num_p = rept025.r25_numprev);
DELETE FROM rept024
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept024.r24_compania
		  	  AND tmp_r23.loc   = rept024.r24_localidad
		          AND tmp_r23.num_p = rept024.r24_numprev);
DELETE FROM rept023 
	WHERE EXISTS
		(SELECT * FROM tmp_r23
			WHERE tmp_r23.cia   = rept023.r23_compania
		  	  AND tmp_r23.loc   = rept023.r23_localidad
		          AND tmp_r23.num_p = rept023.r23_numprev);
UPDATE rept088
	SET r88_numprev_nue = NULL
	WHERE r88_compania     = 1
	  AND r88_localidad    = 1
	  AND r88_numprev_nue IN (SELECT num_p FROM tmp_r23);
DROP TABLE tmp_r23;
--ROLLBACK WORK;
COMMIT WORK;
