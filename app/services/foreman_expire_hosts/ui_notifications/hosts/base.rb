# frozen_string_literal: true

module ForemanExpireHosts
  module UINotifications
    module Hosts
      class Base < ::UINotifications::Hosts::Base
        private

        def create
          return add_notification unless find_notification

          redeliver! if redeliver?
          find_notification
        end

        def add_notification
          ::Notification.create!(
            initiator: initiator,
            subject: subject,
            message: parsed_message,
            audience: audience,
            notification_blueprint: blueprint
          )
        end

        def message
          blueprint.message
        end

        def parsed_message
          ::UINotifications::StringParser.new(
            message,
            message_variables
          ).to_s
        end

        def message_variables
          {
            subject: subject,
            initator: initiator
          }
        end

        def update_notification
          find_notification
            .update(expired_at: blueprint.expired_at, message: parsed_message)
        end

        def redeliver!
          recipients = find_notification.notification_recipients
          recipients.update_all(seen: false)
          recipients.pluck(:user_id).each do |user_id|
            ::UINotifications::CacheHandler.new(user_id).clear
          end
        end

        def redeliver?
          false
        end

        def find_notification
          blueprint.notifications.find_by(subject: subject)
        end

        def blueprint
          @blueprint ||= NotificationBlueprint.find_by(name: blueprint_name)
        end
      end
    end
  end
end
