begin work;

select * from srit003 into temp t1;
update t1 set s03_compania = 2 where 1 = 1;
insert into sermaco_gm@segye01:srit003
	select * from t1
		where not exists
			(select 1 from sermaco_gm@segye01:srit003 a
				where a.s03_compania  = t1.s03_compania
				  and a.s03_codigo    = t1.s03_codigo
				  and a.s03_cod_ident = t1.s03_cod_ident);
insert into sermaco_qm@seuio01:srit003
	select * from t1
		where not exists
			(select 1 from sermaco_qm@seuio01:srit003 a
				where a.s03_compania  = t1.s03_compania
				  and a.s03_codigo    = t1.s03_codigo
				  and a.s03_cod_ident = t1.s03_cod_ident);
drop table t1;

select * from srit004 where s04_codigo = 3 into temp t1;
update t1 set s04_compania = 2 where 1 = 1;
insert into sermaco_gm@segye01:srit004 select * from t1;
insert into sermaco_qm@seuio01:srit004 select * from t1;
drop table t1;

select * from srit018 into temp t1;
update t1 set s18_compania = 2 where 1 = 1;
insert into sermaco_gm@segye01:srit018
	select * from t1
		where not exists
			(select 1 from sermaco_gm@segye01:srit018 a
				where a.s18_compania  = t1.s18_compania
				  and a.s18_sec_tran  = t1.s18_sec_tran
				  and a.s18_cod_ident = t1.s18_cod_ident
				  and a.s18_tipo_tran = t1.s18_tipo_tran);
insert into sermaco_qm@seuio01:srit018
	select * from t1
		where not exists
			(select 1 from sermaco_qm@seuio01:srit018 a
				where a.s18_compania  = t1.s18_compania
				  and a.s18_sec_tran  = t1.s18_sec_tran
				  and a.s18_cod_ident = t1.s18_cod_ident
				  and a.s18_tipo_tran = t1.s18_tipo_tran);
drop table t1;

select * from srit019 into temp t1;
update t1 set s19_compania = 2 where 1 = 1;
insert into sermaco_gm@segye01:srit019
	select * from t1
		where not exists
			(select 1 from sermaco_gm@segye01:srit019 a
				where a.s19_compania  = t1.s19_compania
				  and a.s19_sec_tran  = t1.s19_sec_tran
				  and a.s19_cod_ident = t1.s19_cod_ident
				  and a.s19_tipo_comp = t1.s19_tipo_comp
				  and a.s19_tipo_doc  = t1.s19_tipo_doc);
insert into sermaco_qm@seuio01:srit019
	select * from t1
		where not exists
			(select 1 from sermaco_qm@seuio01:srit019 a
				where a.s19_compania  = t1.s19_compania
				  and a.s19_sec_tran  = t1.s19_sec_tran
				  and a.s19_cod_ident = t1.s19_cod_ident
				  and a.s19_tipo_comp = t1.s19_tipo_comp
				  and a.s19_tipo_doc  = t1.s19_tipo_doc);
drop table t1;

select * from srit023 into temp t1;
update t1 set s23_compania = 2 where 1 = 1;
insert into sermaco_gm@segye01:srit023 select * from t1;
insert into sermaco_qm@seuio01:srit023 select * from t1;
drop table t1;

commit work;
