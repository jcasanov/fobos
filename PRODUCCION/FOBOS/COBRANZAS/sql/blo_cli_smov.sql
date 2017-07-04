{------------ SOLO PARA RESTAURAR -----------------}
{--
select * from cxct001
	where z01_codcli = -999
	into temp t2;
load from "cli.unl" insert into t2;
select z01_codcli cli, z01_estado est1
	from t2
	into temp t3;
drop table t2;
select cli, est1
	from t3, cxct001
	where cli   = z01_codcli
	  and est1 <> z01_estado
	into temp t4;
drop table t3;
select count(*) tot_t4 from t4;
begin work;
	update cxct001
		set z01_estado = (select est1
					from t4
					where cli = z01_codcli)
		where z01_codcli in (select cli from t4);
commit work;
drop table t4;
--}
{----------------------------------------------}
select z01_codcli cod, z01_nomcli nom, z01_num_doc_id cedruc, z01_estado est
	from cxct001
	where z01_estado = 'A'
	  and not exists
		(select 1 from rept019
			where r19_compania  = 1
			  and r19_localidad = 1
			  and r19_codcli    = z01_codcli)
	  and not exists
		(select 1 from talt023
			where t23_compania    = 1
			  and t23_localidad   = 1
			  and t23_cod_cliente = z01_codcli)
	  and not exists
		(select 1 from rept021
			where r21_compania  = 1
			  and r21_localidad = 1
			  and r21_codcli    = z01_codcli)
	  and not exists
		(select 1 from cxct020
			where z20_compania  = 1
			  and z20_localidad in (1, 2)
			  and z20_codcli    = z01_codcli)
	  and not exists
		(select 1 from cxct021
			where z21_compania  = 1
			  and z21_localidad in (1, 2)
			  and z21_codcli    = z01_codcli)
	  and not exists
		(select 1 from acero_gc:rept019
			where r19_compania  = 1
			  and r19_localidad = 2
			  and r19_codcli    = z01_codcli)
	  and not exists
		(select 1 from acero_gc:rept021
			where r21_compania  = 1
			  and r21_localidad = 2
			  and r21_codcli    = z01_codcli)
	  and not exists
		(select 1 from acero_gc:cxct020
			where z20_compania  = 1
			  and z20_localidad = 2
			  and z20_codcli    = z01_codcli)
	  and not exists
		(select 1 from acero_gc:cxct021
			where z21_compania  = 1
			  and z21_localidad = 2
			  and z21_codcli    = z01_codcli)
	into temp t1;
--select * from t1;
select count(*) tot_reg from t1;
begin work;
	update cxct001
		set z01_estado = 'B'
		where z01_codcli in (select cod from t1);
	update acero_gc@idsgye01:cxct001
		set z01_estado = 'B'
		where z01_codcli in (select cod from t1);
commit work;
drop table t1;
