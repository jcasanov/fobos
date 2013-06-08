database acero_gc



main

	call ejecuta_proceso()

end main



function ejecuta_proceso()

begin work
	call cargar_datos_temp()
	call cargar_datos_fijos()
	call asignar_permisos_usr()
commit work
display 'Proceso Terminado  OK.'

end function



function cargar_datos_temp()

select * from gent004 where g04_grupo   = 'ZX'   into temp te_g04
select * from gent005 where g05_usuario = 'CACA' into temp te_g05
select * from gent052 where g52_usuario = 'CACA' into temp te_g52
select * from gent053 where g53_usuario = 'CACA' into temp te_g53
select * from gent054 where g54_proceso = 'caca' into temp te_g54
select * from gent055 where g55_user    = 'CACA' into temp te_g55

display 'cargando los datos en la tablas temporales ...'

load from "sql/gent004.unl" insert into te_g04
load from "sql/gent005.unl" insert into te_g05
load from "sql/gent052.unl" insert into te_g52
load from "sql/gent053.unl" insert into te_g53
load from "sql/gent054.unl" insert into te_g54
load from "sql/gent055.unl" insert into te_g55

display 'cargado los datos en la tablas temporales OK ...'

end function



function cargar_datos_fijos()
define r_g04		record like gent004.*
define r_g05		record like gent005.*
define r_g54		record like gent054.*
define i, j		smallint

declare q_g04 cursor for select * from te_g04
let i = 0
let j = 0
foreach q_g04 into r_g04.*
	select * from gent004 where g04_grupo = r_g04.g04_grupo
	if status = notfound then
		insert into gent004 values(r_g04.*)
		let i = i + 1
	else
		update gent004 set * = r_g04.* where g04_grupo = r_g04.g04_grupo
		let j = j + 1
	end if
end foreach
display 'Se insertaron ', i using "&&", ' y se actualizaron ', j using "&&",
	' GRUPOS en la gent004  OK.'

declare q_g05 cursor for select * from te_g05
let i = 0
let j = 0
foreach q_g05 into r_g05.*
	select * from gent005 where g05_usuario = r_g05.g05_usuario
	if status = notfound then
		insert into gent005 values(r_g05.*)
		let i = i + 1
	else
		update gent005 set * = r_g05.*
			where g05_usuario = r_g05.g05_usuario
		let j = j + 1
	end if
end foreach
display 'Se insertaron ', i using "&&", ' y se actualizaron ', j using "&&",
	' USUARIOS en la gent005  OK.'

declare q_g54 cursor for select * from te_g54
let i = 0
let j = 0
foreach q_g54 into r_g54.*
	select * from gent054
		where g54_modulo  = r_g54.g54_modulo
		  and g54_proceso = r_g54.g54_proceso
	if status = notfound then
		insert into gent054 values(r_g54.*)
		let i = i + 1
	else
		update gent054 set * = r_g54.*
			where g54_modulo  = r_g54.g54_modulo
			  and g54_proceso = r_g54.g54_proceso
		let j = j + 1
	end if
end foreach
display 'Se insertaron ', i using "#&&", ' y se actualizaron ', j using "#&&",
	' PROCESOS en la gent054  OK.'

end function



function asignar_permisos_usr()
define r_g05		record like gent005.*

declare q_usr cursor for select * from te_g05
foreach q_usr into r_g05.*
	delete from gent055 where g55_user    = r_g05.g05_usuario
	delete from gent053 where g53_usuario = r_g05.g05_usuario
	delete from gent052 where g52_usuario = r_g05.g05_usuario
	insert into gent052
		select * from te_g52 where g52_usuario = r_g05.g05_usuario
	insert into gent053
		select * from te_g53 where g53_usuario = r_g05.g05_usuario
	insert into gent055
		select * from te_g55 where g55_user = r_g05.g05_usuario
	display 'Se actualizo los permisos del usuario: ', r_g05.g05_usuario,
		'  OK.'
end foreach

end function
