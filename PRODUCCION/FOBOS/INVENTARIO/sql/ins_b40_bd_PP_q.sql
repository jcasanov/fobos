select b40_compania as cia,
	b40_localidad as loc,
	b40_modulo as modu,
	"PP" as bod,
	b40_grupo_linea as grp_lin,
	b40_porc_impto as porc,
	b40_venta as aux_vta,
	b40_descuento as aux_des,
	b40_dev_venta as aux_dev,
	b40_costo_venta aux_cos,
	b40_dev_costo as aux_dev_c,
	b40_inventario as aux_inv,
	b40_transito as aux_tra,
	b40_ajustes as aux_aj,
	b40_flete as aux_fle
	from ctbt040
	where b40_compania = 1
	  and b40_bodega   = "04"
	into temp t1;

begin work;

	insert into ctbt040
		select * from t1;

commit work;

drop table t1;
