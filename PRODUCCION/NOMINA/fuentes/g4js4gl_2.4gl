database syspgm4gl


define prog		varchar(4)



main
	
	if num_args() <> 1 then
		exit program
	end if
	let prog = arg_val(1)
	call ejecuta_comp_prog()

end main



function ejecuta_comp_prog()
define r_id4js		record like id_prog4js.*
define r_id4gl		record like id_prog4gl.*
define cont_4js		integer
define cont_4gl		integer
define i, lim		integer

select count(*) into cont_4js from id_prog4js where progname[1, 4] = prog
select count(*) into cont_4gl from id_prog4gl where progname[1, 4] = prog
if cont_4js = 0 and cont_4gl = 0 then
	display 'No hay registros de programas a compilar en las tablas de id.'
	exit program
end if
declare q_4js cursor for
	select * from id_prog4js where progname[1, 4] = prog order by progname
declare q_4gl cursor for
	select * from id_prog4gl where progname[1, 4] = prog order by progname
let lim = cont_4js
if cont_4js < cont_4gl then
	let lim = cont_4gl
end if
open q_4js
open q_4gl
for i = 1 to lim
	if cont_4js > 0 then
		fetch q_4js into r_id4js.*
		call comp_prog(1, r_id4js.progname, r_id4js.crea_4js)
	end if
	if cont_4gl > 0 then
		fetch q_4gl into r_id4gl.*
		call comp_prog(2, r_id4gl.progname, r_id4gl.crea_4gl)
	end if
end for
close q_4js
close q_4gl

end function



function comp_prog(opcion, progname, crear)
define opcion		smallint
define progname		varchar(10)
define crear		char(1)
define compil		varchar(50)

case opcion
	when 1
		let compil = 'fglrun compilar '
	when 2
		let compil = 'fglgo compilar_4gl '
end case
let compil = compil clipped, ' ', progname clipped, '.4gl ', crear
run compil clipped

end function
