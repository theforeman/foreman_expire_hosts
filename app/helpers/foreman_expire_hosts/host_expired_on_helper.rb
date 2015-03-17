require 'expire_hosts_notifications'
module ForemanExpireHosts
  module HostExpiredOnHelper

    def add_host_expired_on_field(host)
      host_expired_on_field = "<div style='display:inline;' id='expired_on'>"+
      "<div class='clearfix'><div class='form-group #{!host.errors[:expired_on].empty? ? 'has-error' : ''}'><label for='expired_on' class='col-md-2 control-label'>Expired On</label><div class='col-md-4'><input type='text' #{host.can_modify_expiry_date? ? "onfocus='show_expired_on_datepicker()'" : "readonly"} size='30' name='host[expired_on]' value='#{(host.expired_on ? host.expired_on.strftime('%d/%m/%Y') : '')}' id='host_expired_on' class='form-control ' autocomplete='off' placeholder='dd/mm/yyyy'><span class='help-block' style='color: #737373'>Host will be deleted automatically on given expired date. Leave blank to keep host forever(until delete manually)</span></div><span class='help-block help-inline'>#{host.errors[:expired_on].to_sentence}</span></div></div>"+
      "</div>"
      host_expired_on_field.html_safe
    end

    def host_expiry_warning_message(host)
    	if host.expired_on
    		message = ""
    		if (host.expired_on + ExpireHostsNotificaions.days_to_delete_after_expired.to_i) < Date.today
    			message = "This host has been expired and needs to be delete manually"
    		elsif host.expired_on.to_date < Date.today
    			message = "This host has been expired and will be deleted on #{(host.expired_on + ExpireHostsNotificaions.days_to_delete_after_expired.to_i).strftime("%d %b %Y")}"
    		elsif host.expired_on.to_date == Date.today
    			message = "This host will expire today"
    		elsif host.expired_on.to_date <= ExpireHostsNotificaions.from_day_to_notify_before_expiry
    			message = "This host will expire on #{host.expired_on.strftime("%d %b %Y")}"    		
    		end
    		unless message.blank?
    			return "<div role='alert' class='alert alert-warning'><span class='glyphicon glyphicon-warning-sign'></span> #{message}</div>".html_safe
    		end
    	end
    	return ""
    end

    def destroyed_expired_host_audit_comment_in_list(audit)
      if audit.auditable_type.to_s == "Host" and audit.action == "destroy" and !audit.comment.to_s.blank?
        return "<div style='color: #737373;font-size: 14px'>Comment: #{audit.comment}</div>".html_safe
      end
    end

    def destroyed_expired_host_audit_comment_in_show(audit)
      if audit.auditable_type.to_s == "Host" and audit.action == "destroy" and !audit.comment.to_s.blank?
        return "<tr><td>Comment</td><td>#{audit.comment}</td></tr>".html_safe
      end
    end   
  end
end



      
    