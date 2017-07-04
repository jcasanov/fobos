delete from id_prog4js where 1 = 1;
delete from id_prog4gl where 1 = 1;

load from "id_prog4js.unl" insert into id_prog4js;
load from "id_prog4gl.unl" insert into id_prog4gl;
