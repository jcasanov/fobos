{--

** CORRER ESTE SCRIPT SOLO CUANDO ESTE CREADA LA BASE DE DATOS DEL "R4GL"
** ES DECIR CREAR ESTAS TABLAS EN ESA BASE.

--}


drop table id_prog4gl;

drop table id_prog4js;


create table id_prog4gl
	(
		progname		char(10),
		crea_4gl		char(1) not null,
	check (crea_4gl in ('S', 'N'))
	);

create table id_prog4js
	(
		progname		char(10),
		crea_4js		char(1) not null,
	check (crea_4js in ('S', 'N'))
	);


insert into id_prog4gl
	select progname, 'S' from source4gl;

insert into id_prog4js
	select progname, 'S' from source4gl;
