begin work;
select * from gent006 where g06_impresora = "LPR";
select * from gent007 where g07_impresora = "LPR";
unload to "g07.txt" select * from gent007 where g07_impresora = "LPR";
delete from gent007 where g07_impresora = "LPR";
update gent006 set g06_impresora = 'LPSISTEMAS',
		   g06_nombre    = 'SISTEMAS2'
	 where g06_impresora = "LPR";
select * from gent007 where g07_impresora = 'CAKAVIED' into temp t1;
load from "g07.txt" insert into t1;
update t1 set g07_impresora = 'LPSISTEMAS' where g07_impresora = "LPR";
insert into gent007 select * from t1;
drop table t1;
select * from gent006 where g06_impresora = "LPSISTEMAS";
select * from gent007 where g07_impresora = "LPSISTEMAS";
commit work;
