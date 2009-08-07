database deimos

main

begin work
declare q1 cursor for 
	select * from rept028
		where r28_compania  = 1
		  and r28_localidad = 1
		  and r28_numliq    = 1
	for update
open q1
fetch q1

sleep 20

rollback work

end main
