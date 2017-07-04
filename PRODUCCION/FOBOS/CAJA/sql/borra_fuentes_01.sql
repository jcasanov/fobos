BEGIN WORK;
SET LOCK MODE TO WAIT;
SELECT r23_compania cia, r23_localidad loc, r23_numprev num_p
	FROM rept023
	WHERE r23_compania      = 1
	  AND r23_localidad     = 1
	  AND r23_estado       <> "F"
	  AND r23_cod_tran     IS NULL
	  AND DATE(r23_fecing)  < TODAY
	INTO TEMP tmp_r23;
SELECT COUNT(*) cuantos_r23 FROM tmp_r23;
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
SELECT z24_compania cia, z24_localidad loc, z24_numero_sol numsol
	FROM cxct024
	WHERE z24_compania     = 1
	  AND z24_localidad    = 1
	  AND z24_estado       = "A"
	  AND DATE(z24_fecing) < TODAY
	INTO TEMP tmp_z24;
SELECT COUNT(*) cuantos_z24 FROM tmp_z24;
DELETE FROM cxct025 
	WHERE EXISTS
		(SELECT * FROM tmp_z24
			WHERE cia    = cxct025.z25_compania
		  	  AND loc    = cxct025.z25_localidad
		          AND numsol = cxct025.z25_numero_sol);
DELETE FROM cxct024 
	WHERE EXISTS
		(SELECT * FROM tmp_z24
			WHERE cia    = cxct024.z24_compania
		  	  AND loc    = cxct024.z24_localidad
		          AND numsol = cxct024.z24_numero_sol);
DROP TABLE tmp_z24;
SELECT p24_compania cia, p24_localidad loc, p24_orden_pago ord_pag
	FROM cxpt024
	WHERE p24_compania     = 1
	  AND p24_localidad    = 1
	  AND p24_estado       = 'A'
	  AND DATE(p24_fecing) < TODAY
	INTO TEMP tmp_p24;
SELECT COUNT(*) cuantos_p24 FROM tmp_p24;
DELETE FROM cxpt026
	WHERE EXISTS
		(SELECT * FROM tmp_p24
			WHERE tmp_p24.cia     = cxpt026.p26_compania
		  	  AND tmp_p24.loc     = cxpt026.p26_localidad
		          AND tmp_p24.ord_pag = cxpt026.p26_orden_pago);
DELETE FROM cxpt025
	WHERE EXISTS
		(SELECT * FROM tmp_p24
			WHERE tmp_p24.cia     = cxpt025.p25_compania
		  	  AND tmp_p24.loc     = cxpt025.p25_localidad
		          AND tmp_p24.ord_pag = cxpt025.p25_orden_pago);
DELETE FROM cxpt024
	WHERE EXISTS
		(SELECT * FROM tmp_p24
			WHERE tmp_p24.cia     = cxpt024.p24_compania
		  	  AND tmp_p24.loc     = cxpt024.p24_localidad
		          AND tmp_p24.ord_pag = cxpt024.p24_orden_pago);
DROP TABLE tmp_p24;
--ROLLBACK WORK;
COMMIT WORK;
