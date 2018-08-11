select b12_tipo_comp tc, b12_num_comp num, b12_fec_proceso fec_pro,
	b12_fec_modifi fec_mod
	from ctbt012
	where b12_compania           = 1 
	  and year(b12_fec_proceso) in (2011, 2012)
	  and date(b12_fec_modifi)  >= today - 0 units day
union
select b12_tipo_comp tc, b12_num_comp num, b12_fec_proceso fec_pro,
	b12_fec_modifi fec_mod
	from ctbt012
	where b12_compania           = 1 
	  and year(b12_fec_proceso) in (2011, 2012)
	  and date(b12_fecing)      >= today - 0 units day
