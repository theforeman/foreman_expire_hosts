function show_expired_on_datepicker(){	
	var today = new Date();
	$('#host_expired_on').datepicker({
		autoclose: true,
		orientation: 'top left',
		format: 'dd/mm/yyyy',
		clearBtn: true,
		startDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()+1)
	});
	$('#host_expired_on').datepicker('show')

	append_shortcuts();
}

var shortcuts = {"1 day": 1, "1 week": 7, "1 month": 30, "1 year": 365, "3 days": 3,  "3 weeks": 21,  "3 months": 90}

function append_shortcuts(){
	if($(".datepicker-days #datepicker_shortcuts").length == 0){
		var shortcuts_html = "<div id='datepicker_shortcuts'><div>"
		var shortcut_item = 1
		$.each( shortcuts, function( lable, days ) {
			var today = new Date();
			today.setDate(today.getDate() + days);
			if(shortcut_item == 5){
				shortcuts_html += "</div><div style='padding-top: 3px'>"
			}
			shortcuts_html += "<a style='width: 65px;' class='btn btn-default btn-xs' role='button' title='"+$.fn.datepicker.dates.en.monthsShort[today.getMonth()]+" "+today.getDate()+" "+ today.getFullYear()+"' onclick='populate_date_from_days("+days+")'>"+lable+"</a>&nbsp;"
			shortcut_item += 1
		});
		shortcuts_html += "</div></div>"
		$(".datepicker-days table").before(shortcuts_html)
	}
}

function populate_date_from_days(shortcut_days){
	var today = new Date();
	today.setDate(today.getDate() + shortcut_days);
	$('#host_expired_on').datepicker('setDate', today);
	$('#host_expired_on').datepicker('remove');
	//$('#host_expired_on').val(today.getDate()+'/'+(today.getMonth()+1)+'/'+today.getFullYear())
	//$('#host_expired_on').datepicker('hide')
}