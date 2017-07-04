set isolation to dirty read;

select "AF" tt, z22_codcli cod, z01_nomcli[1, 30] cliente, z22_tipo_trn tp,
	z22_num_trn num, round(nvl(sum(z23_valor_cap), 0), 2) saldo,
	z22_compania cia, z22_localidad loc, trim(z22_referencia[1, 25]) refer,
	date(z22_fecing) fec, z23_tipo_doc tip_doc, z23_num_doc num_doc,
	z23_div_doc div_doc
	from cxct022, cxct023, cxct001
	where z22_compania     = 1
	  and z22_tipo_trn     = "AJ"
	  and z22_num_trn      > 12884
	  and year(z22_fecing) = 2011
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
			  and year(z21_fecha_emi)  = 2004)
	  and z01_codcli       = z22_codcli
	group by 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13
union all
select "DE" tt, z22_codcli cod, z01_nomcli[1, 30] cliente, z22_tipo_trn tp,
	z22_num_trn num, round(nvl(sum(z23_valor_cap * (-1)), 0), 2) saldo,
	z22_compania cia, z22_localidad loc, trim(z22_referencia[1, 25]) refer,
	date(z22_fecing) fec, z23_tipo_doc tip_doc, z23_num_doc num_doc,
	z23_div_doc div_doc
	from cxct022, cxct023, cxct001
	where z22_compania     = 1
	  and z22_tipo_trn     = "AJ"
	  and z22_num_trn      > 12884
	  and (z22_referencia  = "PARA CRUZAR INCOBRABLES AÒO 2004"
	   or  z22_referencia  = "PARA CRUZAR INCOBRABLES AÒOS 2004")
	  and year(z22_fecing) = 2011
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
			  and (year(z20_fecha_emi) <= 2004
			   or  z20_fecha_emi       = mdy(02, 21, 2011)))
	  and z01_codcli       = z22_codcli
	  and not exists (select 1 from cxct020
			where z20_compania         = z23_compania
			  and z20_localidad        = 1
			  and z20_codcli           = z23_codcli
			  and z20_tipo_doc         = 'DI'
			  and z20_num_doc          IN (2106, 2110, 2116, 2117)
			  and z20_dividendo        = z23_div_doc)
	group by 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13
	into temp t1;

select count(*) tot_trn from t1;

select tt, count(unique cod) tot_reg
	from t1
	group by 1
	order by 1;

select tt, count(loc) tot_reg_loc
	from t1
	group by 1
	order by 1;

select round(sum(saldo), 2) total_gen from t1;

select tt, round(sum(saldo), 2) total_tipo
	from t1
	group by 1
	order by 1;

select tt, loc, fec, refer, round(nvl(sum(saldo), 0), 2) saldo
	from t1
	group by 1, 2, 3, 4
	order by 1, 2, 3;

select tt, loc, refer, tp, num, saldo
	from t1
	order by 4, 5;

begin work;

	update cxct022
		set z22_fecha_emi = mdy(12, 31, 2010),
		    z22_fecing    = extend(mdy(12, 31, 2010), year to day)
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

	update cxct020
		set z20_fecha_emi  = mdy(12, 30, 2010),
		    z20_fecha_vcto = mdy(12, 31, 2010)
		where z20_compania = 1
		  and z20_tipo_doc = 'DI'
		  and exists (select 1 from t1
				where cia     = z20_compania
				  and loc     = z20_localidad
				  and cod     = z20_codcli
				  and tip_doc = z20_tipo_doc
				  and num_doc = z20_num_doc
				  and div_doc = z20_dividendo);

--rollback work;
commit work;

drop table t1;
