SELECT
 *
FROM rept010
WHERE r10_compania = "22"
INTO TEMP t1;


SELECT 
	r10_compania   cia,
	r10_codigo     cod,
	r10_costo_mb   cmb,
	r10_costult_mb cumb
FROM rept010
WHERE r10_compania = "22"
INTO TEMP t2;

LOAD FROM "rept010_qm_26ene2010.unl" INSERT INTO t1;
INSERT INTO t2 SELECT 
	r10_compania, r10_codigo, r10_costo_mb, r10_costult_mb FROM t1;
--SELECT * FROM t2;
UPDATE rept010
set r10_costo_mb = (SELECT cmb FROM t2
			WHERE   cia      = 1
				AND cia  = r10_compania
				AND cod  = r10_codigo),
    r10_costult_mb = (SELECT cumb FROM t2
			WHERE   cia      = 1
				AND cia  = r10_compania
				AND cod  = r10_codigo)
WHERE
	r10_compania 	= 1
{
	and r10_codigo IN (SELECT cod FROM t2 
		WHERE cia = 1 AND cod = r10_codigo)
}
