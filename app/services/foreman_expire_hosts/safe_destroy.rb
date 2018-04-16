module ForemanExpireHosts
  class SafeDestroy
    # See http://projects.theforeman.org/issues/14702 for reasoning.
    attr_accessor :subject

    def initialize(subject)
      self.subject = subject
    end

    def destroy!
      # If Katello is installed, we can't just destroy the host
      # but have to ask ForemanTasks to do this for us.
      # See https://community.theforeman.org/t/how-to-properly-destroy-a-content-host/8621
      # for reasoning.
      if with_katello?
        ForemanTasks.sync_task(::Actions::Katello::Host::Destroy, subject)
      else
        subject.destroy!
      end
    rescue ActiveRecord::RecordNotDestroyed => invalid
      message = _('Failed to delete %{class_name} %{subject}: %{message} - Errors: %{errors}') % {
        :class_name => subject.class.name,
        :subject => subject,
        :message => invalid.message,
        :errors => invalid.record.errors.full_messages.to_sentence
      }
      Foreman::Logging.exception(message, invalid)
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
