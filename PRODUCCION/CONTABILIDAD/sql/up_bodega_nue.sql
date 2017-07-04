select * from ctbt040 where b40_compania = 99 into temp t1;

load from "ctbt040.unl" insert into t1;

update t1 set b40_localidad = 1 where 1 = 1;

select t1.*, ctbt040.b40_compania cia
	from t1, outer ctbt040
	where t1.b40_compania    = ctbt040.b40_compania
	  and t1.b40_localidad   = ctbt040.b40_localidad
	  and t1.b40_modulo      = ctbt040.b40_modulo
	  and t1.b40_bodega      = ctbt040.b40_bodega
	  and t1.b40_grupo_linea = ctbt040.b40_grupo_linea
	into temp t2;

delete from t2 where cia is not null;

delete from t1
	where not exists
		(select t2.* from t2
			where t2.b40_compania    = t1.b40_compania
			  and t2.b40_localidad   = t1.b40_localidad
			  and t2.b40_modulo      = t1.b40_modulo
			  and t2.b40_bodega      = t1.b40_bodega
			  and t2.b40_grupo_linea = t1.b40_grupo_linea);

select count(*) tot_reg_ins from t1;
select * from t1;

drop table t2;

begin work;
	insert into ctbt040 select * from t1;
commit work;

drop table t1;
