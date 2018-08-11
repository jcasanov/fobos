begin work;

	update acero_gm@idsgye01:gent054
		set g54_estado = "R"
		where g54_proceso in ("talp214", "talp215", "repp237",
					"repp245", "repp247");

	update acero_qm@idsuio01:gent054
		set g54_estado = "R"
		where g54_proceso in ("talp214", "talp215", "repp237",
					"repp245", "repp247");

	update acero_qs@idsuio02:gent054
		set g54_estado = "R"
		where g54_proceso in ("talp214", "talp215", "repp237",
					"repp245", "repp247");

commit work;
