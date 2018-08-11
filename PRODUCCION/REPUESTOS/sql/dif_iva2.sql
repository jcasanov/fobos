set isolation to dirty read;
select r19_codcli codcli_c, r19_cod_tran, r19_num_tran,
	case when r19_cod_tran = 'FA' then
		nvl(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) -
			r19_flete, 0)
	else
		nvl(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) -
			r19_flete, 0) * (-1)
	end val_iva_c
	from rept019
	where r19_cod_tran in ('FA', 'DF', 'AF')
	  and extend(r19_fecing, year to month) =
		extend(mdy(05, 01, 2006), year to month)
	into temp caca;
select codcli_c, nvl(sum(val_iva_c), 0) val_iva_c
	from caca
	group by 1
	into temp t1;
drop table caca;
select r19_codcli codcli_d, r20_cod_tran, r20_num_tran,
	case when r20_cod_tran = 'FA' then
		nvl(round(sum((r20_cant_ven * r20_precio) - r20_val_descto),
			2), 0) * 0.12
	else
		nvl(round(sum((r20_cant_ven * r20_precio) - r20_val_descto),
			2), 0) * (-0.12)
	end val_iva_d
	from rept020, rept019
	where r20_cod_tran in ('FA', 'DF', 'AF')
	  and extend(r20_fecing, year to month) =
		extend(mdy(05, 01, 2006), year to month)
	  and r19_compania  = r20_compania
	  and r19_localidad = r20_localidad
	  and r19_cod_tran  = r20_cod_tran
	  and r19_num_tran  = r20_num_tran
	group by 1, 2, 3
	into temp caca;
select codcli_d, nvl(sum(val_iva_d), 0) val_iva_d
	from caca
	group by 1
	into temp t2;
drop table caca;
select codcli_c cliente, round(val_iva_c, 2) val_iva_c,
	round(val_iva_d, 4) val_iva_d
	from t1, t2
	where codcli_c   = codcli_d
	  and val_iva_c <> val_iva_d
	into temp t3;
drop table t1;
drop table t2;
select count(*) tot_cli from t3;
select z01_num_doc_id cedruc, val_iva_c, val_iva_d,
	round(val_iva_c - val_iva_d, 4) diferen
	from t3, cxct001
	where z01_codcli = cliente
	  and abs(val_iva_c - val_iva_d) > 1
	order by 1;
select nvl(round(sum(val_iva_c), 2), 0) tot_c,
	nvl(round(sum(val_iva_d), 2), 0) tot_d
	from t3
	into temp t4;
drop table t3;
select tot_c, tot_d, round(tot_c - tot_d, 2) diferencia from t4;
drop table t4;
