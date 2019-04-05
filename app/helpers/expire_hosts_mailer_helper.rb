module ExpireHostsMailerHelper
  def relative_date(date, opts = {})
    return _('N/A') if date.blank?

    opts[:tense] ||= :future if Date.today < date
    opts[:tense] ||= :past if Date.today > date

    if opts[:tense] == :future
      _('in %s') % (time_ago_in_words date)
    elsif opts[:tense] == :past
      _('%s ago') % (time_ago_in_words date)
    else
      _('today')
    end
  end
end
