Deface::Override.new(
  :virtual_path => 'hosts/show',
  :name => 'host_expiry_waring_in_show',
  :insert_before => '#host-show',
  :partial => 'hosts/expired_message.html.erb'
)
