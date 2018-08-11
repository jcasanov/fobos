begin work;

alter table rept016 add r16_numprof INTEGER before r16_usuario;

create index i08_fk_rept016 
on rept016(r16_compania, r16_localidad, r16_numprof) in idxdbs; 

alter table rept016 
add constraint (foreign key (r16_compania, r16_localidad, r16_numprof)
                references rept021);

commit work;
