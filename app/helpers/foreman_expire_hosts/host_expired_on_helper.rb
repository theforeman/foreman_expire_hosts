require 'expire_hosts_notifications'
module ForemanExpireHosts
  module HostExpiredOnHelper

    def host_expiry_warning_message(host)
      if host.expired_on
        message = ''
        if (host.expired_on + ExpireHostsNotifications.days_to_delete_after_expired.to_i) < Date.today
          message = 'This host has been expired and needs to be delete manually'
        elsif host.expired_on.to_date < Date.today
          message = "This host has been expired and will be deleted on #{(host.expired_on + ExpireHostsNotifications.days_to_delete_after_expired.to_i).strftime('%d %b %Y')}"
        elsif host.expired_on.to_date == Date.today
          message = 'This host will expire today'
        elsif host.expired_on.to_date <= ExpireHostsNotifications.from_day_to_notify_before_expiry
          message = "This host will expire on #{host.expired_on.strftime('%d %b %Y')}"
        end
        unless message.blank?
          return "<div role='alert' class='alert alert-warning'><span class='glyphicon glyphicon-warning-sign'></span> #{message}</div>".html_safe
        end
      end
      ''
    end

    def destroyed_expired_host_audit_comment_in_list(audit)
      if audit.auditable_type.to_s == 'Host' and audit.action == 'destroy' and !audit.comment.to_s.blank?
        "<div style='color: #737373;font-size: 14px'>Comment: #{audit.comment}</div>".html_safe
      end
    end

    def destroyed_expired_host_audit_comment_in_show(audit)
      if audit.auditable_type.to_s == 'Host' and audit.action == 'destroy' and !audit.comment.to_s.blank?
        "<tr><td>Comment</td><td>#{audit.comment}</td></tr>".html_safe
      end
    end
  end
end



      
    