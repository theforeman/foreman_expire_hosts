Foreman::Application.routes.draw do
  post 'expired_hosts/select_multiple_expiration' => 'hosts#select_multiple_expiration', as: 'select_multiple_expiration_hosts'
  post 'expired_hosts/update_multiple_expiration' => 'hosts#update_multiple_expiration', as: 'update_multiple_expiration_hosts'
end
