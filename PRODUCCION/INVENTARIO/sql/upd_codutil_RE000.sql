
select uio.r10_codigo cod, uio.r10_cod_util cutil from acero_qm@idsuio01:rept010 uio
where
	uio.r10_compania = 1 AND
	uio.r10_codigo IN (
		select gye.r10_codigo from acero_gm@idsgye01:rept010 gye
		where  gye.r10_cod_util = "RE000"
			and gye.r10_estado = "A"
			and gye.r10_compania = 1

)
INTO TEMP t1;

SELECT count(*) FROM t1;
BEGIN WORK;
UPDATE acero_gm@idsgye01:rept010
SET
	r10_cod_util = (SELECT cutil FROM t1 WHERE r10_codigo = cod)
WHERE
	r10_compania = 1
	and r10_estado = "A"
	and r10_cod_util = "RE000"
	and r10_codigo IN (SELECT cod FROM t1);
COMMIT WORK;

DROP TABLE t1;
