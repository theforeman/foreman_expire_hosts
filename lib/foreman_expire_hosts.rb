require 'foreman_expire_hosts/engine'
require 'rails'
module ForemanExpireHosts
	class Railtie < Rails::Railtie
		railtie_name :foreman_expire_hosts

		# rake_tasks do
		# 	load "tasks/expired_hosts.rake"
		# end
	end
end
