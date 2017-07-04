SELECT z23_localidad AS loc,
	z23_codcli AS cli,
	z23_tipo_trn AS tt,
	z23_num_trn AS num_t,
	z23_tipo_doc AS td,
	z23_num_doc AS num,
	z23_div_doc AS divi,
	z23_tipo_favor AS tf,
	z23_doc_favor AS num_f
	FROM cxct023
	WHERE z23_compania = 999
	INTO TEMP t1;

LOAD FROM "doc_favor_05.unl"
	INSERT INTO t1;

SELECT * FROM t1
	ORDER BY 1, 2, 3;

SELECT z22_compania AS cia,
	loc,
	cli,
	tt,
	num_t,
	td,
	num,
	divi,
	tf,
	num_f,
	z23_valor_cap AS valor,
	MDY(12, 30, 2011) AS fecemi,
	z22_fecing AS fecing,
	"2011-12-30 " || EXTEND(z22_fecing, HOUR TO SECOND) AS fecing2
	FROM t1, cxct023, cxct022
	WHERE z23_compania   = 1
	  AND z23_localidad  = loc
	  AND z23_codcli     = cli
	  AND z23_tipo_trn   = tt
	  AND z23_num_trn    = num_t
	  AND z22_compania   = z23_compania
	  AND z22_localidad  = z23_localidad
	  AND z22_codcli     = z23_codcli
	  AND z22_tipo_trn   = z23_tipo_trn
	  AND z22_num_trn    = z23_num_trn
	INTO TEMP tmp_aj;

DROP TABLE t1;

{--
SELECT * FROM tmp_aj
	ORDER BY 2, 4, 5;

SELECT tt, num_t, valor, fecing, fecing2
	FROM tmp_aj;
--}

SELECT ROUND(SUM(valor), 2) AS total
	FROM tmp_aj;

BEGIN WORK;

	UPDATE cxct022
		SET z22_fecha_emi = (SELECT fecemi
					FROM tmp_aj
					WHERE cia   = z22_compania
					  AND loc   = z22_localidad
					  AND cli   = z22_codcli
					  AND tt    = z22_tipo_trn
					  AND num_t = z22_num_trn),
		    z22_fecing    = (SELECT fecing2
					FROM tmp_aj
					WHERE cia   = z22_compania
					  AND loc   = z22_localidad
					  AND cli   = z22_codcli
					  AND tt    = z22_tipo_trn
					  AND num_t = z22_num_trn)
		WHERE z22_compania = 1
		  AND EXISTS
			(SELECT 1 FROM tmp_aj
				WHERE cia   = z22_compania
				  AND loc   = z22_localidad
				  AND cli   = z22_codcli
				  AND tt    = z22_tipo_trn
				  AND num_t = z22_num_trn);

	DELETE FROM cxct050
		WHERE z50_compania  = 1
		  AND z50_ano       = 2011
		  AND z50_mes       = 12
		  AND z50_saldo_cap > 0
		  AND EXISTS
			(SELECT 1 FROM tmp_aj
				WHERE cia  = z50_compania
				  AND loc  = z50_localidad
				  AND cli  = z50_codcli
				  AND td   = z50_tipo_doc
				  AND num  = z50_num_doc
				  AND divi = z50_dividendo);

	DELETE FROM cxct050
		WHERE z50_compania  = 1
		  AND z50_ano       = 2012
		  AND z50_mes       = 1
		  AND z50_saldo_cap > 0
		  AND EXISTS
			(SELECT 1 FROM tmp_aj
				WHERE cia  = z50_compania
				  AND loc  = z50_localidad
				  AND cli  = z50_codcli
				  AND td   = z50_tipo_doc
				  AND num  = z50_num_doc
				  AND divi = z50_dividendo);

	DELETE FROM cxct051
		WHERE z51_compania = 1
		  AND z51_ano      = 2011
		  AND z51_mes      = 12
		  AND z51_saldo    > 0
		  AND EXISTS
			(SELECT 1 FROM tmp_aj
				WHERE cia   = z51_compania
				  AND loc   = z51_localidad
				  AND cli   = z51_codcli
				  AND tf    = z51_tipo_doc
				  AND num_f = z51_num_doc);

	DELETE FROM cxct051
		WHERE z51_compania = 1
		  AND z51_ano      = 2012
		  AND z51_mes      = 1
		  AND z51_saldo    > 0
		  AND EXISTS
			(SELECT 1 FROM tmp_aj
				WHERE cia   = z51_compania
				  AND loc   = z51_localidad
				  AND cli   = z51_codcli
				  AND tf    = z51_tipo_doc
				  AND num_f = z51_num_doc);

--ROLLBACK WORK;
COMMIT WORK;

DROP TABLE tmp_aj;
