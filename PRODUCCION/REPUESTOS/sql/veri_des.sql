{
select r19_cod_tran, r19_num_tran, r19_tot_dscto, sum(r20_val_descto)
	from rept019, rept020
	where r19_compania = 1 and r19_localidad = 1 and
		r19_cod_tran in ('FA','DF') and
		r19_compania = r20_compania and
		r19_localidad= r20_localidad and
		r19_cod_tran = r20_cod_tran and
		r19_num_tran = r20_num_tran
	group by 1,2,3
	having r19_tot_dscto <> sum(r20_val_descto)
}

select r20_cod_tran, r20_num_tran, r20_descuento, r20_val_descto,
	round(r20_cant_ven * r20_precio * r20_descuento / 100,2)
	from rept020
	where r20_cod_tran in ('FA','DF') and r20_descuento > 0 and
		r20_val_descto <>
		round(r20_cant_ven * r20_precio * r20_descuento / 100,2);

select r19_tot_bruto, r19_tot_dscto,
	round((r19_tot_bruto - r19_tot_dscto) +
	((r19_tot_bruto - r19_tot_dscto) * r19_porc_impto / 100), 2) ,
	r19_tot_neto from rept019
	where r19_cod_tran in ('FA','DF')
	and    r19_tot_neto <>
	round((r19_tot_bruto - r19_tot_dscto) +
	((r19_tot_bruto - r19_tot_dscto) * r19_porc_impto / 100), 2)
