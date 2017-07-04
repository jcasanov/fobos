drop table tmp_blitz;

create table "fobos".tmp_blitz

	(

		items		char(15)

	) in datadbs lock mode row;

revoke all on "fobos".tmp_blitz from "public";

load from "items_blitz.unl" insert into tmp_blitz;
