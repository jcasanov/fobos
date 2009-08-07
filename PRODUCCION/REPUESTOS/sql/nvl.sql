begin;

create function nvl_jcm(i1 integer, i2 integer) returning integer 

define d integer;

if i1 is null then
	let d=i2;
else
	let d=i1;
end if;

return d;
end function;

select nvl_jcm(sum(r20_precio), -1) from rept020
 where r20_compania = 99;

rollback work;
