SELECT r73_marca marca
	FROM rept073
	WHERE r73_compania = 999
	INTO TEMP tmp_mar;

LOAD FROM "marcas_fob.unl" INSERT INTO tmp_mar;

SELECT r10_compania cia, r10_codigo item, r10_fob pfob
	FROM acero_qm@idsuio01:rept010
	WHERE r10_compania  = 1
	  --AND r10_estado    = "A"
	  AND r10_marca    IN (SELECT marca FROM tmp_mar)
	{--
	  AND r10_marca    IN ("MYERS", "GRUNDF", "MARKGR", "MARKPE", "F.P.S.",
				"FRANKL", "ENERPA", "ARMSTR", "MILWAU",
				"POWERS", "WELLMA", "KLINGE", "RIDGID", "KITO",
				"GORMAN", "INSINK")
	--}
	INTO TEMP tmp_fob;

UPDATE acero_gm@idsgye01:rept010
	SET r10_fob = (SELECT pfob
			FROM tmp_fob
			WHERE cia  = r10_compania
			  AND item = r10_codigo)
	WHERE r10_compania  = 1
	  AND r10_codigo   IN
		(SELECT item
			FROM tmp_fob
			WHERE cia   = r10_compania
			  AND pfob <> r10_fob);

{
UPDATE acero_gm@acuiopr:rept010
	SET r10_fob = (SELECT pfob
			FROM tmp_fob
			WHERE cia  = r10_compania
			  AND item = r10_codigo)
	WHERE r10_compania  = 1
	  AND r10_codigo   IN
		(SELECT item
			FROM tmp_fob
			WHERE cia   = r10_compania
			  AND pfob <> r10_fob);
}

DROP TABLE tmp_fob;
DROP TABLE tmp_mar;
