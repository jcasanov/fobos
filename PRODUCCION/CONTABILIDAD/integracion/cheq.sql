{
select r19_cod_tran, r19_num_tran, r19_fecing, r40_tipo_comp, r40_num_comp
	from rept040, acero_gc:rept019
	where r19_localidad = 2 and
		r19_cod_tran in ('FA','DF','AF') and
		r19_compania  = r40_compania and
	  	r19_localidad = r40_localidad and
		r19_cod_tran  = r40_cod_tran and
		r19_num_tran  = r40_num_tran
	order by 3 desc
}
select r19_cod_tran, r19_num_tran, r19_fecing from acero_gc:rept019
	order by 3 desc
