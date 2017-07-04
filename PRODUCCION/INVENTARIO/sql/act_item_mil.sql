set isolation to dirty read;

select r10_compania cia, r10_codigo item, r10_nombre descripcion,
	r10_linea division, r10_sub_linea linea, r10_cod_grupo grupo,
	r10_cod_clase clase, r10_cod_util util
	from acero_qm@idsuio01:rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	  and r10_marca    = 'MILWAU'
	into temp tmp_uio;

select count(*) item_uio from tmp_uio;

select item, r10_codigo, r10_marca, r10_estado
	from tmp_uio, outer rept010
	where r10_compania  = cia
	  and r10_codigo    = item
	  and r10_marca     = 'MILWAU'
	into temp t1;

select count(*) item_gye from t1;

select * from t1 where r10_estado = 'B';

delete from t1 where r10_marca is not null;

select count(*) item_gye from t1;

select * from t1;

drop table t1;

select item, r10_codigo, r10_marca, r10_linea div_gye, r10_sub_linea lin_gye,
	r10_cod_grupo gru_gye, r10_cod_clase cla_gye, r10_nombre
	from tmp_uio, outer rept010
	where r10_compania  = cia
	  and r10_codigo    = item
	  and r10_marca     = 'MILWAU'
	into temp t1;

select item, clase
	from tmp_uio
	where not exists
		(select 1 from t1
			where div_gye    = division
			  and lin_gye    = linea
			  and gru_gye    = grupo
			  and cla_gye    = clase
			  and r10_codigo = item);

unload to "item_mil.unl"
	select a.item, a.descripcion, b.r10_nombre desc_gye
		from tmp_uio a, t1 b
		where a.item         = b.item
		  and a.descripcion <> b.r10_nombre
		order by 1;

--select 

select unique util
	from tmp_uio
	where not exists
		(select 1 from rept077
			where r77_compania  = cia
			  and r77_codigo_util = util);

{
begin work;

	update rept010
		set r10_nombre    = (select descripcion
					from tmp_uio
					where cia  = r10_compania
					  and item = r10_codigo),
		    r10_cod_clase = (select clase
					from tmp_uio
					where cia  = r10_compania
					  and item = r10_codigo),
		    r10_cod_util = (select util
					from tmp_uio
					where cia  = r10_compania
					  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_codigo   in (select item from tmp_uio)
	  and r10_estado    = 'A';

rollback work;
}

drop table tmp_uio;
