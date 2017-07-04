{ DATABASE syspgm4gl  delimiter | }

grant dba to "fobos";
grant connect to "public";









 


 

{ TABLE "fobos".source4gl row size = 100 number of columns = 4 index size = 70 }
{ unload file name = sourc00100.unl number of rows = 216 }

create table "fobos".source4gl 
  (
    progname char(10),
    ppath char(40),
    fglsourcename char(10),
    spath char(40)
  )  extent size 20 next size 16 lock mode page;
revoke all on "fobos".source4gl from "public";

{ TABLE "fobos".sourceother row size = 103 number of columns = 5 index size = 70 
              }
{ unload file name = sourc00101.unl number of rows = 0 }

create table "fobos".sourceother 
  (
    progname char(10),
    ppath char(40),
    othersourcename char(10),
    extension char(3),
    spath char(40)
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".sourceother from "public";

{ TABLE "fobos".libraries row size = 59 number of columns = 3 index size = 70 }
{ unload file name = libra00102.unl number of rows = 0 }

create table "fobos".libraries 
  (
    progname char(10),
    ppath char(40),
    libraries char(9)
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".libraries from "public";

{ TABLE "fobos".opts row size = 58 number of columns = 3 index size = 70 }
{ unload file name = opts_00103.unl number of rows = 0 }

create table "fobos".opts 
  (
    progname char(10),
    ppath char(40),
    options char(8)
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".opts from "public";

{ TABLE "fobos".global row size = 100 number of columns = 4 index size = 70 }
{ unload file name = globa00104.unl number of rows = 216 }

create table "fobos".global 
  (
    progname char(10),
    ppath char(40),
    globname char(10),
    gpath char(40)
  )  extent size 20 next size 16 lock mode page;
revoke all on "fobos".global from "public";

{ TABLE "fobos".runner row size = 150 number of columns = 6 index size = 70 }
{ unload file name = runne00105.unl number of rows = 0 }

create table "fobos".runner 
  (
    progname char(10),
    ppath char(40),
    fglgoname char(10),
    fpath char(40),
    db4glname char(10),
    dpath char(40)
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".runner from "public";

{ TABLE "fobos".otherobj row size = 100 number of columns = 4 index size = 70 }
{ unload file name = other00106.unl number of rows = 852 }

create table "fobos".otherobj 
  (
    progname char(10),
    ppath char(40),
    othername char(10),
    opath char(40)
  )  extent size 80 next size 16 lock mode page;
revoke all on "fobos".otherobj from "public";

{ TABLE "fobos".id_prog4gl row size = 11 number of columns = 2 index size = 0 }
{ unload file name = id_pr00107.unl number of rows = 545 }

create table "fobos".id_prog4gl 
  (
    progname char(10),
    crea_4gl char(1) not null ,
    
    check (crea_4gl IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".id_prog4gl from "public";

{ TABLE "fobos".id_prog4js row size = 11 number of columns = 2 index size = 0 }
{ unload file name = id_pr00108.unl number of rows = 546 }

create table "fobos".id_prog4js 
  (
    progname char(10),
    crea_4js char(1) not null ,
    
    check (crea_4js IN ('S' ,'N' ))
  )  extent size 16 next size 16 lock mode page;
revoke all on "fobos".id_prog4js from "public";


grant select on "fobos".source4gl to "public" as "fobos";
grant update on "fobos".source4gl to "public" as "fobos";
grant insert on "fobos".source4gl to "public" as "fobos";
grant delete on "fobos".source4gl to "public" as "fobos";
grant index on "fobos".source4gl to "public" as "fobos";
grant select on "fobos".sourceother to "public" as "fobos";
grant update on "fobos".sourceother to "public" as "fobos";
grant insert on "fobos".sourceother to "public" as "fobos";
grant delete on "fobos".sourceother to "public" as "fobos";
grant index on "fobos".sourceother to "public" as "fobos";
grant select on "fobos".libraries to "public" as "fobos";
grant update on "fobos".libraries to "public" as "fobos";
grant insert on "fobos".libraries to "public" as "fobos";
grant delete on "fobos".libraries to "public" as "fobos";
grant index on "fobos".libraries to "public" as "fobos";
grant select on "fobos".opts to "public" as "fobos";
grant update on "fobos".opts to "public" as "fobos";
grant insert on "fobos".opts to "public" as "fobos";
grant delete on "fobos".opts to "public" as "fobos";
grant index on "fobos".opts to "public" as "fobos";
grant select on "fobos".global to "public" as "fobos";
grant update on "fobos".global to "public" as "fobos";
grant insert on "fobos".global to "public" as "fobos";
grant delete on "fobos".global to "public" as "fobos";
grant index on "fobos".global to "public" as "fobos";
grant select on "fobos".runner to "public" as "fobos";
grant update on "fobos".runner to "public" as "fobos";
grant insert on "fobos".runner to "public" as "fobos";
grant delete on "fobos".runner to "public" as "fobos";
grant index on "fobos".runner to "public" as "fobos";
grant select on "fobos".otherobj to "public" as "fobos";
grant update on "fobos".otherobj to "public" as "fobos";
grant insert on "fobos".otherobj to "public" as "fobos";
grant delete on "fobos".otherobj to "public" as "fobos";
grant index on "fobos".otherobj to "public" as "fobos";
grant select on "fobos".id_prog4gl to "public" as "fobos";
grant update on "fobos".id_prog4gl to "public" as "fobos";
grant insert on "fobos".id_prog4gl to "public" as "fobos";
grant delete on "fobos".id_prog4gl to "public" as "fobos";
grant index on "fobos".id_prog4gl to "public" as "fobos";
grant select on "fobos".id_prog4js to "public" as "fobos";
grant update on "fobos".id_prog4js to "public" as "fobos";
grant insert on "fobos".id_prog4js to "public" as "fobos";
grant delete on "fobos".id_prog4js to "public" as "fobos";
grant index on "fobos".id_prog4js to "public" as "fobos";








 


 


 


 


 


 


revoke usage on language SPL from public ;

grant usage on language SPL to public ;





create index "fobos".i_fglspgm on "fobos".source4gl (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fglspgm1 on "fobos".source4gl (progname) 
    using btree  in datadbs ;
create index "fobos".i_fglopgm on "fobos".sourceother (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fglopgm1 on "fobos".sourceother (progname) 
    using btree  in datadbs ;
create index "fobos".i_fgllibpgm on "fobos".libraries (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fgllibpgm1 on "fobos".libraries (progname) 
    using btree  in datadbs ;
create index "fobos".i_fgloptpgm on "fobos".opts (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fgloptpgm1 on "fobos".opts (progname) using 
    btree  in datadbs ;
create index "fobos".i_fglgpgm on "fobos".global (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fglgpgm1 on "fobos".global (progname) using 
    btree  in datadbs ;
create index "fobos".i_fglrpgm on "fobos".runner (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fglrpgm1 on "fobos".runner (progname) using 
    btree  in datadbs ;
create index "fobos".i_fglobpgm on "fobos".otherobj (ppath,progname) 
    using btree  in datadbs ;
create index "fobos".i_fglobpgm1 on "fobos".otherobj (progname) 
    using btree  in datadbs ;





 

