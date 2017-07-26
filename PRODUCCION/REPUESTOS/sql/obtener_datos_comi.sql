select b.r20_localidad loc, r01_iniciales vend, b.r20_cod_tran tp,
	b.r20_num_tran num, a.r19_codcli codcli, a.r19_nomcli nomcli,
	date(b.r20_fecing) fecha, r10_cod_clase cla, r72_desc_clase clase,
	b.r20_item codigo, r10_nombre item, b.r20_cant_ven cant,
	case when (a.r19_cod_tran = 'FA' and a.r19_tipo_dev = 'DF')
		then nvl((select sum(c.r20_cant_ven) from rept020 c
				where c.r20_compania  = a.r19_compania
				  and c.r20_localidad = a.r19_localidad
				  and c.r20_cod_tran  = a.r19_cod_tran
				  and c.r20_num_tran  = a.r19_num_tran), 0)
		else 0.00
	end dev,
	b.r20_precio pvp, b.r20_descuento porc, r77_multiplic mul,
	(select (select date(z22_fecing)
			from cxct023, cxct022
			where z23_compania  = d.z20_compania
			  and z23_localidad = d.z20_localidad
		  	  and z23_codcli    = d.z20_codcli
		  	  and z23_tipo_doc  = d.z20_tipo_doc
		  	  and z23_num_doc   = d.z20_num_doc
		  	  and z23_div_doc   = d.z20_dividendo
			  and z22_compania  = z23_compania
			  and z22_localidad = z23_localidad
		  	  and z22_codcli    = z23_codcli
		  	  and z22_tipo_trn  = z23_tipo_trn
		  	  and z22_num_trn   = z23_num_trn
			  and z22_fecing    =
				(select max(g.z22_fecing)
					from cxct023 f, cxct022 g
					where f.z23_compania  = d.z20_compania
					  and f.z23_localidad = d.z20_localidad
				  	  and f.z23_codcli    = d.z20_codcli
				  	  and f.z23_tipo_doc  = d.z20_tipo_doc
				  	  and f.z23_num_doc   = d.z20_num_doc
				  	  and f.z23_div_doc   = d.z20_dividendo
					  and g.z22_compania  = f.z23_compania
					  and g.z22_localidad = f.z23_localidad
				  	  and g.z22_codcli    = f.z23_codcli
				  	  and g.z22_tipo_trn  = f.z23_tipo_trn
				  	  and g.z22_num_trn   = f.z23_num_trn))
		from cxct020 d
		where d.z20_compania  = a.r19_compania
		  and d.z20_localidad = a.r19_localidad
		  and d.z20_codcli    = a.r19_codcli
		  and d.z20_cod_tran  = a.r19_cod_tran
		  and d.z20_num_tran  = a.r19_num_tran
		  and d.z20_dividendo = (select max(e.z20_dividendo)
					from cxct020 e
					where e.z20_compania  = d.z20_compania
					  and e.z20_localidad = d.z20_localidad
					  and e.z20_codcli    = d.z20_codcli
					  and e.z20_tipo_doc  = d.z20_tipo_doc
					  and e.z20_num_doc   = d.z20_num_doc))
	from rept019 a, rept020 b, rept001, rept010, rept072, rept077
	where a.r19_compania     = 1
	  and a.r19_localidad    = 1
	  and a.r19_cod_tran     in ('FA', 'DF')
	  and (a.r19_tipo_dev    is null
	   or  a.r19_tipo_dev    = 'DF'
	   or  a.r19_tipo_dev    = 'FA'
	   or  a.r19_tipo_dev    = 'TR')
	  and date(a.r19_fecing) between mdy(12, 01, 2006)
				     and mdy(01, 31, 2007)
	  and r01_compania       = a.r19_compania
	  and r01_codigo         = a.r19_vendedor
	  and b.r20_compania     = a.r19_compania
	  and b.r20_localidad    = a.r19_localidad
	  and b.r20_cod_tran     = a.r19_cod_tran
	  and b.r20_num_tran     = a.r19_num_tran
	  and r10_compania       = b.r20_compania
	  and r10_codigo         = b.r20_item
	  and r72_compania       = r10_compania
	  and r72_linea          = r10_linea
	  and r72_sub_linea      = r10_sub_linea
	  and r72_cod_grupo      = r10_cod_grupo
	  and r72_cod_clase      = r10_cod_clase
	  and r77_compania       = r10_compania
	  and r77_codigo_util    = r10_cod_util
union
select b.r20_localidad loc, r01_iniciales vend, b.r20_cod_tran tp,
	b.r20_num_tran num, a.r19_codcli codcli, a.r19_nomcli nomcli,
	date(b.r20_fecing) fecha, r10_cod_clase cla, r72_desc_clase clase,
	b.r20_item codigo, r10_nombre item, b.r20_cant_ven cant,
	case when (a.r19_cod_tran = 'FA' and a.r19_tipo_dev = 'DF')
		then nvl((select sum(c.r20_cant_ven) from rept020 c
				where c.r20_compania  = a.r19_compania
				  and c.r20_localidad = a.r19_localidad
				  and c.r20_cod_tran  = a.r19_cod_tran
				  and c.r20_num_tran  = a.r19_num_tran), 0)
		else 0.00
	end dev,
	b.r20_precio pvp, b.r20_descuento porc, r77_multiplic mul,
	(select (select date(z22_fecing)
			from cxct023, cxct022
			where z23_compania  = d.z20_compania
			  and z23_localidad = d.z20_localidad
		  	  and z23_codcli    = d.z20_codcli
		  	  and z23_tipo_doc  = d.z20_tipo_doc
		  	  and z23_num_doc   = d.z20_num_doc
		  	  and z23_div_doc   = d.z20_dividendo
			  and z22_compania  = z23_compania
			  and z22_localidad = z23_localidad
		  	  and z22_codcli    = z23_codcli
		  	  and z22_tipo_trn  = z23_tipo_trn
		  	  and z22_num_trn   = z23_num_trn
			  and z22_fecing    =
				(select max(g.z22_fecing)
					from cxct023 f, cxct022 g
					where f.z23_compania  = d.z20_compania
					  and f.z23_localidad = d.z20_localidad
				  	  and f.z23_codcli    = d.z20_codcli
				  	  and f.z23_tipo_doc  = d.z20_tipo_doc
				  	  and f.z23_num_doc   = d.z20_num_doc
				  	  and f.z23_div_doc   = d.z20_dividendo
					  and g.z22_compania  = f.z23_compania
					  and g.z22_localidad = f.z23_localidad
				  	  and g.z22_codcli    = f.z23_codcli
				  	  and g.z22_tipo_trn  = f.z23_tipo_trn
				  	  and g.z22_num_trn   = f.z23_num_trn))
		from cxct020 d
		where d.z20_compania  = a.r19_compania
		  and d.z20_localidad = a.r19_localidad
		  and d.z20_codcli    = a.r19_codcli
		  and d.z20_cod_tran  = a.r19_cod_tran
		  and d.z20_num_tran  = a.r19_num_tran
		  and d.z20_dividendo = (select max(e.z20_dividendo)
					from cxct020 e
					where e.z20_compania  = d.z20_compania
					  and e.z20_localidad = d.z20_localidad
					  and e.z20_codcli    = d.z20_codcli
					  and e.z20_tipo_doc  = d.z20_tipo_doc
					  and e.z20_num_doc   = d.z20_num_doc))
	from acero_gc:rept019 a, acero_gc:rept020 b, acero_gc:rept001,
		acero_gc:rept010, acero_gc:rept072, acero_gc:rept077
	where a.r19_compania     = 1
	  and a.r19_localidad    = 2
	  and a.r19_cod_tran     in ('FA', 'DF')
	  and (a.r19_tipo_dev    is null
	   or  a.r19_tipo_dev    = 'DF'
	   or  a.r19_tipo_dev    = 'FA'
	   or  a.r19_tipo_dev    = 'TR')
	  and date(a.r19_fecing) between mdy(12, 01, 2006)
				     and mdy(01, 31, 2007)
	  and r01_compania       = a.r19_compania
	  and r01_codigo         = a.r19_vendedor
	  and b.r20_compania     = a.r19_compania
	  and b.r20_localidad    = a.r19_localidad
	  and b.r20_cod_tran     = a.r19_cod_tran
	  and b.r20_num_tran     = a.r19_num_tran
	  and r10_compania       = b.r20_compania
	  and r10_codigo         = b.r20_item
	  and r72_compania       = r10_compania
	  and r72_linea          = r10_linea
	  and r72_sub_linea      = r10_sub_linea
	  and r72_cod_grupo      = r10_cod_grupo
	  and r72_cod_clase      = r10_cod_clase
	  and r77_compania       = r10_compania
	  and r77_codigo_util    = r10_cod_util
	into temp t1;
select count(*) tot_reg from t1;
select * from t1;
drop table t1;
