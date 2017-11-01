require File.expand_path('../lib/foreman_expire_hosts/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_expire_hosts'
  s.version     = ForemanExpireHosts::VERSION
  s.date        = Date.today.to_s
  s.authors     = ['Nagarjuna Rachaneni', 'Timo Goebel']
  s.email       = ['nn.nagarjuna@gmail.com', 'mail@timogoebel.name']
  s.summary     = 'Foreman plugin for limiting host lifetime'
  s.description = 'This Plugin will add new column expired_on to hosts to limit the lifetime of a host.'
  s.homepage    = 'https://github.com/theforeman/foreman_expire_hosts'
  s.licenses    = ['GPL-3.0']

  s.files =            `git ls-files`.split("\n")
  s.test_files =       `git ls-files test`.split("\n")
  s.extra_rdoc_files = `git ls-files doc`.split("\n") + Dir['README*', 'LICENSE']

  s.require_paths = ['lib']

  s.add_dependency 'bootstrap-datepicker-rails'
  s.add_dependency 'deface'

  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rubocop', '0.51.0'
end
