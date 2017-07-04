database aceros


define base		char(20)
define usr1		like gent005.g05_usuario
define usr2		like gent005.g05_usuario



main

	if num_args() <> 3 then
		display 'Número de parametros incorrectos.'
		display 'Base Usuario1 Usuario2.'
		exit program
	end if
	let base = arg_val(1)
	let usr1 = arg_val(2)
	let usr2 = arg_val(3)
	call activar_base()
	call validar_paramentros()
	call asigna_permisos_usr()

end main



function activar_base()
define r_g51		record like gent051.*

close database
whenever error continue
database base
if status < 0 then
	display 'No se pudo abrir base de datos: ', base
	exit program
end if
whenever error stop
initialize r_g51.* to null
select * into r_g51.* from gent051
	where g51_basedatos = base
if r_g51.g51_basedatos is null then
	display 'No existe base de datos: ', base
	exit program
end if

end function



function validar_paramentros()

call validar_usr(usr1)
call validar_usr(usr2)

end function



function validar_usr(usr)
define usr		like gent005.g05_usuario
define r_g05		record like gent005.*

initialize r_g05.* to null
select * into r_g05.* from gent005 where g05_usuario = usr
if r_g05.g05_usuario is null then
	display 'El Usuario: ', usr, ' no existe en la base de datos ', base,'.'
	exit program
end if

end function



function asigna_permisos_usr()

begin work

delete from gent055 where g55_user    = usr1
delete from gent053 where g53_usuario = usr1
delete from gent052 where g52_usuario = usr1

select * from gent052 where g52_usuario = usr2 into temp t1
select * from gent053 where g53_usuario = usr2 into temp t2
select * from gent055 where g55_user    = usr2 into temp t3

update t1 set g52_usuario = usr1 where 1 = 1
update t2 set g53_usuario = usr1 where 1 = 1
update t3 set g55_user    = usr1 where 1 = 1

insert into gent052 select * from t1
insert into gent053 select * from t2
insert into gent055 select * from t3

commit work

display 'Usuario: ', usr1, ' actualizado con los mismos permisos del Usuario: ',
	usr2, '  OK.'

end function
