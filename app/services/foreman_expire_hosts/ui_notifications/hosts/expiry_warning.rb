# frozen_string_literal: true

module ForemanExpireHosts
  module UINotifications
    module Hosts
      class ExpiryWarning < Base
        include ActionView::Helpers::DateHelper

        def blueprint_name
          'expire_hosts_expiry_warning'
        end

        private

        # Nag the user about expiring hosts
        def redeliver?
          true
        end

        def message
          N_('%{subject} will expire in %{relative_expiry_time}.')
        end

        def message_variables
          super.merge(:relative_expiry_time => time_ago_in_words(subject.expired_on))
        end
      end
    end
  end
end
