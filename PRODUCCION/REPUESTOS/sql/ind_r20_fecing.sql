begin;

create function tms2date(fecing datetime year to second) 
returning date with (not variant)

define d date;

let d = date(fecing);
return d;
end function;

create index i01_oq_rept020 
 on rept020 (r20_compania, r20_localidad, tms2date(r20_fecing));

commit work;
