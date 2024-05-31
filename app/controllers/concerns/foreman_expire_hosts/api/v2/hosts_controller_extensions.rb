# frozen_string_literal: true

module ForemanExpireHosts
  module Api
    module V2
      module HostsControllerExtensions
        extend Apipie::DSL::Concern

        update_api(:create, :update) do
          param :host, Hash do
            param :expired_on, String, desc: 'Expiry date'
          end
        end
      end
    end
  end
end
