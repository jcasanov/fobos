alter table rept022 add constraint(
	primary key (r22_compania, r22_localidad, r22_numprof,  r22_orden
		    ) constraint "fobos".pk_rept022
);
