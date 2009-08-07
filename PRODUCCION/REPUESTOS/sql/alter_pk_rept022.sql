alter table rept022 drop constraint pk_rept022;
drop index i01_pk_rept022;
create unique index i01_pk_rept022 ON rept022(r22_compania, r22_localidad,
					      r22_numprof,  r22_orden
) in idxdbs;
