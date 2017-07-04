select "UIO" local, r72_desc_clase clase, r10_codigo item,
	r10_nombre descripcion, r10_precio_mb prec_vta,
	r11_stock_act stock
	from rept010, rept072, rept011
	where r10_compania  = 999
	  and r10_marca     = "MARKPE"
	  and r72_compania  = r10_compania
	  and r72_linea     = r10_linea
	  and r72_sub_linea = r10_sub_linea
	  and r72_cod_grupo = r10_cod_grupo
	  and r72_cod_clase = r10_cod_clase
	  and r11_compania  = r10_compania
	  and r11_item      = r10_codigo
	into temp t1;
load from "stock_marpe_01.unl" insert into t1;
load from "stock_marpe_02.unl" insert into t1;
load from "stock_marpe_03.unl" insert into t1;
load from "stock_marpe_04.unl" insert into t1;
load from "stock_marpe_05.unl" insert into t1;
select count(*) tot_reg from t1;
select local, clase, item, descripcion, prec_vta, nvl(sum(stock), 0) stock
	from t1
	group by 1, 2, 3, 4, 5
	into temp t2;
drop table t1;
unload to "stock_markpe.unl" select * from t2;
drop table t2;
