select a.p22_compania cia, a.p22_localidad loc, a.p22_codprov codp,
	a.p22_tipo_trn tp, a.p22_num_trn num,
	extend(a.p22_fecing, year to day) fecha,
	extend(c.p20_fecha_emi, year to day) fec_doc,
	nvl((select max(extend(d.p22_fecing, year to day))
		from cxpt023 e, cxpt022 d
		where e.p23_compania     = b.p23_compania
		  and e.p23_localidad    = b.p23_localidad
		  and e.p23_codprov      = b.p23_codprov
		  and e.p23_tipo_doc     = b.p23_tipo_doc
		  and e.p23_num_doc      = b.p23_num_doc
		  and e.p23_div_doc      = b.p23_div_doc
		  and d.p22_compania     = e.p23_compania
		  and d.p22_localidad    = e.p23_localidad
		  and d.p22_codprov      = e.p23_codprov
		  and d.p22_tipo_trn     = e.p23_tipo_trn
		  and d.p22_num_trn      = e.p23_num_trn
		  and date(d.p22_fecing) < mdy(09, 28, 2009)),
	extend(mdy(01, 30, 2009), year to day)) ult_f,
	(select count(*)
		from cxpt023 e
		where e.p23_compania  = b.p23_compania
		  and e.p23_localidad = b.p23_localidad
		  and e.p23_codprov   = b.p23_codprov
		  and e.p23_tipo_doc  = b.p23_tipo_doc
		  and e.p23_num_doc   = b.p23_num_doc
		  and e.p23_div_doc   = b.p23_div_doc) t_mov
	from cxpt022 a, cxpt023 b, cxpt020 c
	where a.p22_compania      = 1
	  and a.p22_localidad     = 1
	  and a.p22_tipo_trn      = 'AJ'
	  and date(a.p22_fecing) >= mdy(09, 28, 2009)
	  and b.p23_compania      = a.p22_compania
	  and b.p23_localidad     = a.p22_localidad
	  and b.p23_codprov       = a.p22_codprov
	  and b.p23_tipo_trn      = a.p22_tipo_trn
	  and b.p23_num_trn       = a.p22_num_trn
	  and c.p20_compania      = b.p23_compania
	  and c.p20_localidad     = b.p23_localidad
	  and c.p20_codprov       = b.p23_codprov
	  and c.p20_tipo_doc      = b.p23_tipo_doc
	  and c.p20_num_doc       = b.p23_num_doc
	  and c.p20_dividendo     = b.p23_div_doc
	  and c.p20_fecha_emi    <= mdy(06, 30, 2009)
	  and not exists
		(select 1 from cxpt040
			where p40_compania  = a.p22_compania
			  and p40_localidad = a.p22_localidad
			  and p40_codprov   = a.p22_codprov
			  and p40_tipo_doc  = a.p22_tipo_trn
			  and p40_num_doc   = a.p22_num_trn)
	into temp t1;
delete from t1
	where year(fec_doc) = 2009
	  and ult_f         between mdy(07, 01, 2009)
				and mdy(09, 27, 2009);
select count(*) tot_t1 from t1;
select count(*) tot_anio, t_mov, year(fec_doc) anio
	from t1
	group by 2, 3
	order by 3 desc, 2;
--select * from t1 where year(fec_doc) = 2009 order by 6;
--select * from t1 order by 6;
begin work;
	update cxpt022
		set p22_fecing = "2009-01-30 " ||
				extend(p22_fecing, hour to hour) || ":" ||
				extend(p22_fecing, minute to minute) || ":" ||
				extend(p22_fecing, second to second)
		where exists
			(select cia, loc, codp, tp, num
				from t1
				where cia  = p22_compania
				  and loc  = p22_localidad
				  and codp = p22_codprov
				  and tp   = p22_tipo_trn
				  and num  = p22_num_trn
				  and year(fec_doc) < 2009);
	update cxpt022
		set p22_fecing = "2009-06-30 " ||
				extend(p22_fecing, hour to hour) || ":" ||
				extend(p22_fecing, minute to minute) || ":" ||
				extend(p22_fecing, second to second)
		where exists
			(select cia, loc, codp, tp, num
				from t1
				where cia  = p22_compania
				  and loc  = p22_localidad
				  and codp = p22_codprov
				  and tp   = p22_tipo_trn
				  and num  = p22_num_trn
				  and year(fec_doc) = 2009);
--rollback work;
commit work;
drop table t1;
