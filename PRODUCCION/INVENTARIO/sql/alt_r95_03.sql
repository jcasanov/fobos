{--
alter table "fobos".rept095 drop r95_persona_dest;
alter table "fobos".rept095 drop r95_pers_id_dest;
alter table "fobos".rept095 drop r95_punto_lleg;
--}

begin work;

alter table "fobos".rept095
	add (r95_persona_dest varchar(100,40) before r95_num_sri);
alter table "fobos".rept095
	add (r95_pers_id_dest varchar(15,10)  before r95_num_sri);
alter table "fobos".rept095
	add (r95_punto_lleg   varchar(150,80) before r95_num_sri);

select unique r97_compania cia, r97_localidad loc, r97_guia_remision guia,
	g01_razonsocial per_dest, g02_numruc per_id,
	trim(g02_nombre) || ' ' || trim(g02_direccion) punto_lleg
	from rept097, rept019, rept002, gent002, gent001
	where r97_cod_tran  = 'TR'
	  and r19_compania  = r97_compania
	  and r19_localidad = r97_localidad
	  and r19_cod_tran  = r97_cod_tran
	  and r19_num_tran  = r97_num_tran
	  and r02_compania  = r19_compania
	  and r02_codigo    = r19_bodega_dest
	  and g02_compania  = r02_compania
	  and g02_localidad = r02_localidad
	  and g01_compania  = g02_compania
union all
	select unique r96_compania cia, r96_localidad loc,
		r96_guia_remision guia, trim(r19_nomcli) per_dest,
		r19_cedruc per_id, trim(r36_entregar_en) punto_lleg
		from rept096, rept036, rept034, rept019
		where r36_compania    = r96_compania
		  and r36_localidad   = r96_localidad
		  and r36_bodega      = r96_bodega
		  and r36_num_entrega = r96_num_entrega
		  and r34_compania    = r36_compania
		  and r34_localidad   = r36_localidad
		  and r34_bodega      = r36_bodega
		  and r34_num_ord_des = r36_num_ord_des
		  and r19_compania    = r34_compania
		  and r19_localidad   = r34_localidad
		  and r19_cod_tran    = r34_cod_tran
		  and r19_num_tran    = r34_num_tran
	into temp t1;

update rept095
	set r95_persona_dest = (select per_dest from t1
				where cia  = r95_compania
				  and loc  = r95_localidad
				  and guia = r95_guia_remision),
	    r95_pers_id_dest = (select per_id from t1
				where cia  = r95_compania
				  and loc  = r95_localidad
				  and guia = r95_guia_remision),
	    r95_punto_lleg   = (select punto_lleg from t1
				where cia  = r95_compania
				  and loc  = r95_localidad
				  and guia = r95_guia_remision)
	where exists (select cia, loc, guia
			from t1
			where cia  = r95_compania
			  and loc  = r95_localidad
			  and guia = r95_guia_remision);

alter table "fobos".rept095
	modify (r95_persona_dest varchar(100,40) not null);
alter table "fobos".rept095
	modify (r95_pers_id_dest varchar(15,10)  not null);
alter table "fobos".rept095
	modify (r95_punto_lleg   varchar(150,80) not null);

commit work;

drop table t1;
