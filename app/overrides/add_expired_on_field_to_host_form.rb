
  Deface::Override.new(
    :virtual_path => 'hosts/_form',
    :name         => 'host_form_expired_on_field',
    :insert_after => "div#model_name",
    :partial      => 'hosts/expired_on_field',
  )
