if SETTINGS[:host_expired_on] and SETTINGS[:host_expired_on][:host_show] and SETTINGS[:host_expired_on][:host_show][:view] == :expired_on_field
  Deface::Override.new(
    :virtual_path => 'hosts/_overview',
    :name         => 'host_expired_on_in_show',
    #:insert_before => "erb[silent]:contains('overview_fields(host).each do |name, value|')",
    :insert_after => "tr:contains('Properties')",
    :text         => "\n   <tr> <td>Expired On</td><td><%= (@host.expired_on ? @host.expired_on.strftime('%d %b %Y') : '') %></td></tr>"
  )
  Deface::Override.new(
    :virtual_path  => 'hosts/show',
    :name          => 'host_expiry_waring_in_show',
    #:insert_before => "erb[loud]:contains('host_title_actions(@host)')",
    :insert_before => '#host-show',
    :text          => "\n   <%= host_expiry_warning_message @host %>"
  )
end
