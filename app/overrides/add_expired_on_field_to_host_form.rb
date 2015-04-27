if SETTINGS[:host_expired_on] and SETTINGS[:host_expired_on][:host_form] and SETTINGS[:host_expired_on][:host_form][:view] == :expired_on_input_field

  after = SETTINGS[:host_expired_on][:host_form][:after]
  Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name         => 'host_form_expired_on_field',
    :insert_after => "div##{after}",
    :text         => "\n   <%= add_host_expired_on_field @host %>"
  )
  Deface::Override.new(
    :virtual_path => 'hosts/_progress',
    :name         => 'host_expire_bootstrap_datepicker',
    :insert_after => 'div#host-progress',
    :partial      => '/hosts/host_expire_bootstrap_datepicker_assets'
  )

end