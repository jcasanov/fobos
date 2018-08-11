set isolation to dirty read;

select "AF" tt, z22_codcli cod, z01_nomcli[1, 30] cliente, z22_tipo_trn tp,
	z22_num_trn num, round(nvl(sum(z23_valor_cap), 0), 2) saldo,
	z22_compania cia, z22_localidad loc
	from cxct022, cxct023, cxct001
	where z22_compania     = 1
	  and z22_tipo_trn     = "AJ"
	  and z22_num_trn      > 10172
	  and z22_referencia   matches "*APL*"
	  and year(z22_fecing) = 2010
	  and z23_compania     = z22_compania
	  and z23_localidad    = z22_localidad
	  and z23_codcli       = z22_codcli
	  and z23_tipo_trn     = z22_tipo_trn
	  and z23_num_trn      = z22_num_trn
	  and exists (select 1 from cxct021
			where z21_compania         = z23_compania
			  and z21_localidad        = z23_localidad
			  and z21_codcli           = z23_codcli
			  and z21_tipo_doc         = z23_tipo_favor
			  and z21_num_doc          = z23_doc_favor
			  and year(z21_fecha_emi) <= 2006)
	  and z01_codcli       = z22_codcli
	group by 1, 2, 3, 4, 5, 7, 8
union all
select "DE" tt, z22_codcli cod, z01_nomcli[1, 30] cliente, z22_tipo_trn tp,
	z22_num_trn num, round(nvl(sum(z23_valor_cap * (-1)), 0), 2) saldo,
	z22_compania cia, z22_localidad loc
	from cxct022, cxct023, cxct001
	where z22_compania     = 1
	  and z22_tipo_trn     = "AJ"
	  and z22_num_trn      > 10156
	  and year(z22_fecing) = 2010
	  and z23_compania     = z22_compania
	  and z23_localidad    = z22_localidad
	  and z23_codcli       = z22_codcli
	  and z23_tipo_trn     = z22_tipo_trn
	  and z23_num_trn      = z22_num_trn
	  and exists (select 1 from cxct020
			where z20_compania         = z23_compania
			  and z20_localidad        = z23_localidad
			  and z20_codcli           = z23_codcli
			  and z20_tipo_doc         = z23_tipo_doc
			  and z20_num_doc          = z23_num_doc
			  and z20_dividendo        = z23_div_doc
			  and year(z20_fecha_emi) <= 2004)
	  and z01_codcli       = z22_codcli
	group by 1, 2, 3, 4, 5, 7, 8
	into temp t1;

select count(*) tot_trn from t1;

select tt, count(unique cod) tot_reg
	from t1
	group by 1
	order by 1;

select round(sum(saldo), 2) total_gen from t1;

select tt, round(sum(saldo), 2) total_tipo
	from t1
	group by 1
	order by 1;

select tt, cod, cliente, round(nvl(sum(saldo), 0), 2) saldo
	from t1
	group by 1, 2, 3
	order by 1, 3;

select tt, cod, cliente, tp, num, saldo
	from t1
	order by 3, 5;

begin work;

	update cxct022
		set z22_fecha_emi = mdy(12,31,2009),
		    z22_fecing    = extend(mdy(12,31,2009), year to day)
					|| " " ||
					extend(z22_fecing, hour to second)
	where z22_compania = 1
	  and z22_tipo_trn = "AJ"
	  and exists (select 1 from t1
			where cia = z22_compania
			  and loc = z22_localidad
			  and cod = z22_codcli
			  and tp  = z22_tipo_trn
			  and num = z22_num_trn);

--rollback work;
commit work;

drop table t1;
