module ForemanExpireHosts
  class SafeDestroy
    # See http://projects.theforeman.org/issues/14702 for reasoning.
    attr_accessor :subject

    def initialize(subject)
      self.subject = subject
    end

    def destroy!
      subject.destroy!
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
  end
end
