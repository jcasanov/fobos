select r34_cod_tran, r34_num_tran, r34_num_ord_des, r34_fecing
	from rept034, rept019
	where r34_compania  = 1
	  and r34_localidad = 2
	  and r34_bodega    = 79
	  and r34_estado    in ('A', 'P')
	  and r19_compania  = r34_compania
	  and r19_localidad = r34_localidad
	  and r19_cod_tran  = r34_cod_tran
	  and r19_num_tran  = r34_num_tran
	  and r19_tipo_dev is null
	order by 4 desc;
