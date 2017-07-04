rollback work;
begin work;
drop index "fobos".i01_pk_ordt003;
alter table "fobos".ordt003 drop constraint "fobos".pk_ordt003;

alter table "fobos".ordt003
        add (c03_fecha                  date            before c03_estado);

select c03_compania cia, c03_tipo_ret tip_ret, c03_porcentaje porc,
        c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini
        from ordt003
        where c03_compania = 1
        into temp tmp_c03;

update "fobos".ordt003
        set c03_fecha = (select fec_ini
                                from tmp_c03
                                where cia     = c03_compania
                                  and tip_ret = c03_tipo_ret
                                  and porc    = c03_porcentaje
                                  and cod_sri = c03_codigo_sri)
        where c03_compania = 1
          and exists
                (select 1 from tmp_c03
                        where cia     = c03_compania
                          and tip_ret = c03_tipo_ret
                          and porc    = c03_porcentaje
                          and cod_sri = c03_codigo_sri);

alter table "fobos".ordt003 drop c03_fecha_ini_porc;

rename column "fobos".ordt003.c03_fecha to c03_fecha_ini_porc;

alter table "fobos".ordt003
        modify (c03_fecha_ini_porc      date            not null);
create unique index "fobos".i01_pk_ordt003
        on "fobos".ordt003
                (c03_compania, c03_tipo_ret, c03_porcentaje, c03_codigo_sri,
                 c03_fecha_ini_porc)
        in idxdbs;

alter table "fobos".ordt003
        add constraint
                primary key (c03_compania, c03_tipo_ret, c03_porcentaje,
                                c03_codigo_sri, c03_fecha_ini_porc)
                        constraint "fobos".pk_ordt003;

drop table tmp_c03;

insert into "fobos".ordt003
        values (1, 'F', 2.00, 307, mdy(02, 01, 2009), "A",
		"Servicios Prodomina Mano de Obra", null, "N", null, null,
		null, null, "FOBOS", current);

select c03_compania cia, c03_tipo_ret tip_ret, c03_porcentaje porc,
        c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini
        from ordt003
        where c03_compania = 1
        into temp tmp_c03;
select count(p26_orden_pago)
        from cxpt024, cxpt026
        where p24_compania      = 1
          and date(p24_fecing) >= mdy(02,12,2009)
          and p26_compania      = p24_compania
          and p26_localidad     = p24_localidad
          and p26_orden_pago    = p24_orden_pago
union
select count(p26_orden_pago)
        from cxpt024, cxpt026
        where p24_compania     = 1
          and date(p24_fecing) < mdy(02,12,2009)
          and p26_compania     = p24_compania
          and p26_localidad    = p24_localidad
          and p26_orden_pago   = p24_orden_pago;
select p26_compania cia, p26_localidad loc, p26_orden_pago ord_p,
        p26_secuencia sec, p26_tipo_ret tip_ret, p26_porcentaje porc,
        p26_codigo_sri cod_sri, fec_ini
        from cxpt024, cxpt026, tmp_c03
        where p24_compania      = 1
          and date(p24_fecing) >= mdy(02,12,2009)
          and p26_compania      = p24_compania
          and p26_localidad     = p24_localidad
          and p26_orden_pago    = p24_orden_pago
          and tip_ret           = p26_tipo_ret
          and porc              = p26_porcentaje
          and cod_sri           = p26_codigo_sri
          and fec_ini          >= mdy(01,01,2009)
union
select p26_compania cia, p26_localidad loc, p26_orden_pago ord_p,
        p26_secuencia sec, p26_tipo_ret tip_ret, p26_porcentaje porc,
        p26_codigo_sri cod_sri, fec_ini
        from cxpt024, cxpt026, tmp_c03
        where p24_compania     = 1
          and p26_compania     = p24_compania
          and p26_localidad    = p24_localidad
          and p26_orden_pago   = p24_orden_pago
          and tip_ret          = p26_tipo_ret
          and porc             = p26_porcentaje
          and cod_sri          = p26_codigo_sri
          and fec_ini          < mdy(01,01,2009)
        into temp tmp_p26;
drop table tmp_c03;
select cia, loc, ord_p, sec, tip_ret, porc, cod_sri, count(*) tot
	from tmp_p26
	group by 1,2,3,4,5,6,7
	having count(*) > 1
	into temp t1;
select a.* from tmp_p26 a
        where exists (select 1 from t1 b
                        where b.cia      = a.cia
                          and b.loc      = a.loc
                          and b.ord_p    = a.ord_p
                          and b.sec      = a.sec
                          and b.tip_ret  = a.tip_ret
                          and b.porc     = a.porc
                          and b.cod_sri  = a.cod_sri);
drop table t1;
select unique fec_ini
                                        from tmp_p26, cxpt026
                                        where cia     = p26_compania
                                          and loc     = p26_localidad
                                          and ord_p   = p26_orden_pago
                                          and sec     = p26_secuencia
                                          and tip_ret = p26_tipo_ret
                                          and porc    = p26_porcentaje
                                          and cod_sri = p26_codigo_sri;
alter table "fobos".cxpt026
        add (p26_fecha_ini_porc         date            before p26_valor_base);
update "fobos".cxpt026
        set p26_fecha_ini_porc = (select unique fec_ini
                                        from tmp_p26
                                        where cia     = p26_compania
                                          and loc     = p26_localidad
                                          and ord_p   = p26_orden_pago
                                          and sec     = p26_secuencia
                                          and tip_ret = p26_tipo_ret
                                          and porc    = p26_porcentaje
                                          and cod_sri = p26_codigo_sri)
        where p26_compania = 1
          and exists
                (select 1 from tmp_p26
                        where cia     = p26_compania
                          and loc     = p26_localidad
                          and ord_p   = p26_orden_pago
                          and sec     = p26_secuencia
                          and tip_ret = p26_tipo_ret
                          and porc    = p26_porcentaje
                          and cod_sri = p26_codigo_sri);
alter table "fobos".cxpt026
        modify (p26_fecha_ini_porc      date            not null);
rollback work;
--select * from tmp_p26 order by 1,2,3,4,5,6,7,8;
drop table tmp_p26;
