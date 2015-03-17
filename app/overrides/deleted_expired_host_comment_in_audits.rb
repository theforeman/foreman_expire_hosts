Deface::Override.new(
	:virtual_path => "audits/_list",
	:name => "deleted_expired_host_audit_comment_in_list",
	:insert_bottom => "div.row div.audit-content", #"erb[loud]:contains('link_to(audit_title(audit), audit_path(audit))')",
	:text => "\n <%= destroyed_expired_host_audit_comment_in_list(audit) %>"
	)

Deface::Override.new(
	:virtual_path => "audits/show",
	:name => "deleted_expired_host_audit_comment_in_show",
	:insert_bottom => "div#tab1 table",
	:text => "\n <%= destroyed_expired_host_audit_comment_in_show(@audit) %>"
	)