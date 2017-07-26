--rollback work;
set isolation to dirty read;
begin work;

	update rept021
		set r21_codcli = 47280
		where r21_codcli = 1707610928;

	update rept023
		set r23_codcli = 47280
		where r23_codcli = 1707610928;

	update rept019
		set r19_codcli = 47280
		where r19_codcli = 1707610928;

	update cajt010
		set j10_codcli = 47280
		where j10_codcli = 1707610928;

	update cxct030
		set z30_codcli = 47280
		where z30_codcli = 1707610928;

	update cxct020
		set z20_codcli = 47280
		where z20_codcli = 1707610928;

	update cxct021
		set z21_codcli = 47280
		where z21_codcli = 1707610928;

	update cxct023
		set z23_codcli = 47280
		where z23_codcli = 1707610928;

	update cxct022
		set z22_codcli = 47280
		where z22_codcli = 1707610928;

	update cxct008
		set z08_codcli = 47280
		where z08_codcli = 1707610928;

	update cxct009
		set z09_codcli = 47280
		where z09_codcli = 1707610928;

	delete from cxct002
		where z02_codcli = 1707610928;

	delete from cxct001
		where z01_codcli = 1707610928;

--rollback work;
commit work;
