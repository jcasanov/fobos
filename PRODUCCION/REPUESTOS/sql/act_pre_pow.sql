select 2 cia, r10_codigo item, r10_marca marca,
	r10_precio_mb prec_act, r10_estado est
	from sermaco_qm@seuio01:rept010
	where r10_compania = 2
	  and r10_marca    = 'POWERS'
	into temp tmp_r10;

begin work;

	update rept010
		set r10_precio_ant = r10_precio_mb
		where r10_compania  = 2
		  and r10_codigo   in (select item
					from tmp_r10
					where cia       = r10_compania
					  and item      = r10_codigo
					  and est       = 'A'
					  and prec_act <> r10_precio_mb
					  and marca     = r10_marca)
		  and r10_marca     = 'POWERS';

	update rept010
		set r10_precio_mb   = (select prec_act
					from tmp_r10
					where cia   = r10_compania
					  and item  = r10_codigo),
		    r10_fec_camprec = current
		where r10_compania  = 2
		  and r10_codigo   in (select item
					from tmp_r10
					where cia       = r10_compania
					  and item      = r10_codigo
					  and est       = 'A'
					  and prec_act <> r10_precio_mb
					  and marca     = r10_marca)
		  and r10_marca     = 'POWERS';

	insert into rept087
		select cia, 6, item,
			(select nvl(max(r87_secuencia), 0) + 1
				from rept087
				where r87_compania = cia
				  and r87_item     = item),
			prec_act, r10_precio_ant, 'FOBOS', current
			from tmp_r10, rept010
			where est          = 'A'
			  and r10_compania = cia
			  and r10_codigo   = item;

	update rept010
		set r10_estado = 'B',
		    r10_feceli = current
		where r10_compania = 2
		  and r10_codigo   in (select item
					from tmp_r10
					where cia   = r10_compania
					  and item  = r10_codigo
					  and est   = 'B'
					  and marca = r10_marca)
		  and r10_marca    = 'POWERS';

commit work;
--rollback work;

drop table tmp_r10;
