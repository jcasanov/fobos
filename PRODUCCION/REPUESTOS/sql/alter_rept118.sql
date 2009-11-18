begin work;

alter table "fobos".rept118 modify r118_cod_fact char(2);
alter table "fobos".rept118 modify r118_num_fact decimal(15,0);
alter table "fobos".rept118 add r118_numprev integer before r118_cod_fact;

update rept118 set r118_numprev = (select r23_numprev from rept023
									where r23_compania  = r118_compania
									  and r23_localidad = r118_localidad
									  and r23_cod_tran  = r118_cod_fact 
									  and r23_num_tran  = r118_num_fact 
                                    group by 1)
 where 1 = 1;

create index "fobos".i02_fk_rept118 on rept118(r118_compania,
    r118_localidad,r118_numprev,r118_item_fact) in idxdbs;

alter table "fobos".rept118 add constraint (foreign key (r118_compania,
    r118_localidad,r118_numprev,r118_item_fact)
    references "fobos".rept024 );

commit work;
