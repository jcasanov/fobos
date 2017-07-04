select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r19_cod_tran,
	r20_fecing fecha,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta
	from rept019, rept020
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and date(r19_fecing) between mdy(01, 01, 2004) and mdy(12, 31, 2006)
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	group by 1, 2, 3, 4, 5
	into temp t1;
select year(fecha) anio, r19_codcli codcli, r19_nomcli cliente, r19_vendedor,
	nvl(sum(val_vta), 0) valor_vta
	from t1
	group by 1, 2, 3, 4
	into temp t2;
drop table t1;
select anio, codcli, cliente, z01_direccion1 dircli, z01_telefono1 fono,
	r01_nombres vendedor, round(valor_vta, 2) valor_vta
	from t2, cxct001, rept001
	where valor_vta    > 1000
	  and z01_codcli   = codcli
	  and r01_compania = 1
	  and r01_codigo   = r19_vendedor
	into temp temp_vta;
drop table t2;
select anio, round(nvl(sum(valor_vta), 0), 2) tot_anio
	from temp_vta
	group by 1
	order by 1;
select count(unique cliente) tot_cli, anio from temp_vta group by 2;
unload to "clientes_1000.txt" select * from temp_vta order by 1 asc, 3 asc;
drop table temp_vta;
