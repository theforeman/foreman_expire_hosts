Deface::Override.new(
  :virtual_path  => 'hosts/_list',
  :name          => 'host_list_expiration_js',
  :insert_before => '#confirmation-modal',
  :text          => "<%= stylesheet 'foreman_expire_hosts/application' %><%= javascript 'foreman_expire_hosts/application' %>"
)
