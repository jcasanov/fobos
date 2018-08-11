select r21_numprof, r21_cod_tran, r21_num_tran, r21_num_ot, r21_fecing
	from rept021
	where r21_vendedor = 10
	  and date(r21_fecing) between mdy(3,1,2004) and mdy(3,31,2004)
	into temp t1;
delete from t1 where r21_cod_tran is null;
select count(*) from t1 order by 1;
select * from t1 order by 1;
DELETE FROM t1
                WHERE r21_cod_tran = 'FA'
                  AND r21_num_tran IN
                        (SELECT r19_num_tran FROM rept019
                                WHERE r19_compania  = 1
                                  AND r19_localidad = 1
                                  AND r19_cod_tran  = r21_cod_tran
                                  AND r19_num_tran  = r21_num_tran
                                  AND r19_tipo_dev  IN ("DF", "AF"));
select count(*) from t1 order by 1;
select * from t1 order by 1;
drop table t1;
