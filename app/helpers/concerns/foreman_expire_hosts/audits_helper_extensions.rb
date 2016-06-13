module ForemanExpireHosts
  module AuditsHelperExtensions
    extend ActiveSupport::Concern

    def destroyed_expired_host_audit_comment_in_list(audit)
      return unless audit.auditable_type.to_s == 'Host' && audit.action == 'destroy' && !audit.comment.blank?
      "<div style='color: #737373;font-size: 14px'>Comment: #{audit.comment}</div>".html_safe
    end

    def destroyed_expired_host_audit_comment_in_show(audit)
      return unless audit.auditable_type.to_s == 'Host' && audit.action == 'destroy' && !audit.comment.blank?
      "<tr><td>Comment</td><td>#{audit.comment}</td></tr>".html_safe
    end
  end
end
