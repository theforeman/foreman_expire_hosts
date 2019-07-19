# frozen_string_literal: true

[
  {
    group: _('Hosts'),
    name: 'expire_hosts_expiry_warning',
    message: _('%{subject} will expire soon.'),
    level: 'info',
    actions:
    {
      links:
      [
        path_method: :host_path,
        title: _('Details')
      ]
    }
  },
  {
    group: _('Hosts'),
    name: 'expire_hosts_stopped_host',
    message: _('%{subject} was stopped because it expired.'),
    level: 'info',
    actions:
    {
      links:
      [
        path_method: :host_path,
        title: _('Details')
      ]
    }
  }
].each { |blueprint| UINotifications::Seed.new(blueprint).configure }
