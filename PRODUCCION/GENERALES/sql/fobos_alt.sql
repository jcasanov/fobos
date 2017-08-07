alter table fobos add fb_usar_fechasist char(1) check ('S', 'N');
update fobos set fb_usar_fechasist = 'N'; 
alter table fobos modify fb_usar_fechasist char(1) not null;

alter table fobos add fb_fechasist date;
