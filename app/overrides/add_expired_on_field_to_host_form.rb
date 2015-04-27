if SETTINGS[:host_expired_on] and SETTINGS[:host_expired_on][:host_form] and SETTINGS[:host_expired_on][:host_form][:view] == :expired_on_input_field

  after = SETTINGS[:host_expired_on][:host_form][:after]
  Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name         => 'host_form_expired_on_field',
    :insert_after => "div##{after}",
    :partial      => 'hosts/expired_on_field',
  )
end