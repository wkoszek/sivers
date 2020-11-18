define(«m4_NOTFOUND», «
	status := 404;
	js := '{}';
»)dnl
define(«m4_ERRVARS», «
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
»)dnl
define(«m4_ERRCATCH», «
EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);
»)dnl
