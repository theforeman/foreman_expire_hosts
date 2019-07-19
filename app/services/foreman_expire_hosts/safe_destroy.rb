# frozen_string_literal: true

module ForemanExpireHosts
  class SafeDestroy
    # See http://projects.theforeman.org/issues/14702 for reasoning.
    attr_accessor :subject

    def initialize(subject)
      self.subject = subject
    end

    def destroy!
      # If Katello is installed, we can't just destroy the host
      # but have to delete it the Katello way.
      # See https://community.theforeman.org/t/how-to-properly-destroy-a-content-host/8621
      # for reasoning.
      if subject.is_a?(Host::Base) && with_katello?
        Katello::RegistrationManager.unregister_host(host)
      else
        subject.destroy!
      end
    rescue ActiveRecord::RecordNotDestroyed => e
      message = _('Failed to delete %{class_name} %{subject}: %{message} - Errors: %{errors}') % {
        :class_name => subject.class.name,
        :subject => subject,
        :message => e.message,
        :errors => e.record.errors.full_messages.to_sentence
      }
      Foreman::Logging.exception(message, e)
      false
    end

    private

    def with_katello?
      Katello # rubocop:disable Lint/Void
      true
    rescue StandardError
      false
    end
  end
end
