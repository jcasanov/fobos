begin work;

	insert into cxct000
		select * from jadesa:cxct000;

	insert into cxct004
		select * from jadesa:cxct004;

	insert into cxct005
		select * from jadesa:cxct005;

	insert into cxct006
		select * from jadesa:cxct006;

--rollback work;
commit work;
