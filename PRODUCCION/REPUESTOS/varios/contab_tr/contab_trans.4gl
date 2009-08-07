DATABASE diteca
GLOBALS "globales.4gl"


DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE rm_crep		RECORD LIKE rept019.*

DEFINE vm_modulo	CHAR(2)
DEFINE vm_tipo_comp	CHAR(2)
DEFINE vm_indice	INTEGER

DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran

define i		integer
define j		integer
define k		integer
define m		integer


define vm_r19	ARRAY[10000] of record like rept019.*


main
define r_r19		record like rept019.*
define r_r40		record like rept040.*
define total_reg	INTEGER

define num_tran		char(10)
define faltan		char(10)

if num_args() <> 2 then
	display 'numero de parametros incorrectos.'
	exit program
end if

let vg_codcia = arg_val(1)
let vg_codloc = arg_val(2)


declare q_t cursor for
	select * from rept019 
		where r19_compania = vg_codcia
		  and r19_localidad = vg_codloc
		  and r19_cod_tran  = 'TR'
		  and date(r19_fecing) between mdy(5,  1, 2004) 
                                           and mdy(10, 20, 2004)  

select count(*) into total_reg from rept019
		where r19_compania = vg_codcia
		  and r19_localidad = vg_codloc
		  and r19_cod_tran  = 'TR'
		  and date(r19_fecing) between mdy(5,  1, 2004) 
                                           and mdy(10, 20, 2004)  

let j = total_reg / 10

let i =  0 
let k = 1;
foreach q_t into vm_r19[k].*
	let k = k + 1
end foreach
let k = k - 1


display 'total de registros a procesar: ', total_reg
for m = 1 to k
	let r_r19.* = vm_r19[m].*
	if i = j then
--		let num_tran r_r19.r19_num_tran using '
		display 'procesando Transferencia # ', r_r19.r19_num_tran using '######', 
			' -- (faltan ', total_reg using '######', ' transacciones)'
		let total_reg = total_reg - i 
		let i = 0
	end if

	declare q_r40 cursor for
		select * from rept040
		 where r40_compania  = r_r19.r19_compania
		   and r40_localidad = r_r19.r19_localidad
		   and r40_cod_tran  = r_r19.r19_cod_tran
		   and r40_num_tran  = r_r19.r19_num_tran

	initialize r_r40.* to null
	open  q_r40	
	fetch q_r40 into r_r40.*	
	close q_r40
	free  q_r40

	if r_r40.r40_compania is null then
display ' contabilizando.. TR - ', r_r19.r19_num_tran
		call fl_control_master_contab_repuestos(r_r19.r19_compania,
							r_r19.r19_localidad,
							r_r19.r19_cod_tran,
							r_r19.r19_num_tran)
	end if

	let i = i + 1
end for

end main

