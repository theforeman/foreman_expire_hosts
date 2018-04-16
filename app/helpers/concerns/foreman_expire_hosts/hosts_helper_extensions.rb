module ForemanExpireHosts
  module HostsHelperExtensions
    extend ActiveSupport::Concern

    module Overrides
      def multiple_actions
        actions = super
        actions << [_('Change Expiration'), select_multiple_expiration_hosts_path] if authorized_for(:controller => :hosts, :action => :select_multiple_expiration)
        actions
      end
    end

    included do
      prepend Overrides
    end

    def host_expiry_warning_message(host)
      return nil unless host.expires?
      if host.expired_past_grace_period?
        message = _('This host has expired %s ago and needs to be deleted manually.') % time_ago_in_words(host.expired_on)
      elsif host.expired?
        message = _('This host has expired %{time_ago} ago and will be deleted on %{delete_date}.') % { :delete_date => l(host.expiration_grace_period_end_date), :time_ago => time_ago_in_words(host.expired_on) }
      elsif host.expires_today?
        message = _('This host will expire today.')
      elsif host.pending_expiration?
        message = _('This host will expire in %{distance_of_time} (on %{expire_date}).') % { :expire_date => l(host.expired_on), :distance_of_time => future_time_in_words(host.expired_on) }
      end
      message
    end

    def future_time_in_words(to_time, options = {})
      distance_of_time_in_words(to_time, Time.current, options)
    end

    def input_group_addon(content, options = {})
      content_tag :span, class: 'input-group-addon' do
        content_tag :span, content, options
      end
    end

    def datepicker_f(form, attr, options = {})
      field(form, attr, options) do
        addClass options, 'form-control'
        date = f.text_field attr, options
        addon = input_group_addon('', :class => 'glyphicon glyphicon-calendar')
        input_group date, addon
      end
    end
  end
end
