select z02_zona_venta zon_vta, z02_zona_cobro zon_cob
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "cobradores_gye.unl" insert into t1;

begin work;

	update cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where zon_vta = z02_zona_venta)
		where z02_compania    = 1
		  and z02_zona_venta in (select zon_vta from t1);

commit work;

drop table t1;
