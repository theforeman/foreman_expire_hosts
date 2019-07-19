# frozen_string_literal: true

module ForemanExpireHosts
  module UINotifications
    module Hosts
      class StoppedHost < Base
        def blueprint_name
          'expire_hosts_stopped_host'
        end
      end
    end
  end
end
