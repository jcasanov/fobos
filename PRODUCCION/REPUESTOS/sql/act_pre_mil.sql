select 1 cia, r10_codigo item, r10_marca marca,
	r10_precio_mb prec_act, r10_estado est
	from sermaco_qm@seuio01:rept010
	where r10_compania = 2
	  and r10_marca    = "MILWAU"
	  and r10_estado   = "A"
	into temp t1;

select count(*) tot_t1 from t1;

select * from t1
	where not exists
		(select 1 from rept020
			where r20_compania = cia
			  and r20_item     = item)
	into temp tmp_r10;

select count(*) tot_r10 from tmp_r10;

drop table t1;

begin work;

	update rept010
		set r10_precio_ant = r10_precio_mb
		where r10_compania  = 1
		  and r10_codigo   in (select item
					from tmp_r10
					where cia       = r10_compania
					  and item      = r10_codigo
					  and prec_act <> r10_precio_mb
					  and marca     = r10_marca)
		  and r10_estado    = "A"
		  and r10_marca     = "MILWAU";

	update rept010
		set r10_precio_mb   = (select prec_act
					from tmp_r10
					where cia   = r10_compania
					  and item  = r10_codigo),
		    r10_fec_camprec = current
		where r10_compania  = 1
		  and r10_codigo   in (select item
					from tmp_r10
					where cia       = r10_compania
					  and item      = r10_codigo
					  and prec_act <> r10_precio_mb
					  and marca     = r10_marca)
		  and r10_estado    = "A"
		  and r10_marca     = "MILWAU";

	insert into rept087
		select cia, 3, item,
			(select nvl(max(r87_secuencia), 0) + 1
				from rept087
				where r87_compania = cia
				  and r87_item     = item),
			prec_act, r10_precio_ant, "FOBOS", current
			from tmp_r10, rept010
			where r10_compania          = cia
			  and r10_codigo            = item
			  and r10_precio_mb         = prec_act
			  and date(r10_fec_camprec) = today
			  and r10_estado            = "A"
			  and r10_marca             = "MILWAU";

commit work;
--rollback work;

drop table tmp_r10;
