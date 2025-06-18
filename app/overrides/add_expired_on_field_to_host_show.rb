# frozen_string_literal: true

Deface::Override.new(
  :virtual_path => 'hosts/show',
  :name => 'host_expiry_warning_in_show',
  :insert_before => '#host-show',
  :partial => 'hosts/expired_message'
)
