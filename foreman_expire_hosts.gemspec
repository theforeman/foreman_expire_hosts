# frozen_string_literal: true

require File.expand_path('lib/foreman_expire_hosts/version', __dir__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_expire_hosts'
  s.version     = ForemanExpireHosts::VERSION
  s.date        = Date.today.to_s
  s.authors     = ['Nagarjuna Rachaneni', 'Timo Goebel']
  s.email       = ['nn.nagarjuna@gmail.com', 'mail@timogoebel.name']
  s.summary     = 'Foreman plugin for limiting host lifetime'
  s.description = <<~DESC
    A Foreman plugin that allows hosts to expire at a configurable date.
    Hosts will be shut down and automatically deleted after a grace period.
  DESC
  s.homepage    = 'https://github.com/theforeman/foreman_expire_hosts'
  s.licenses    = ['GPL-3.0']

  s.files       = Dir['{app,config,db,extra,lib,locale}/**/*'] + ['LICENSE', 'README.md']
  s.test_files  = Dir['test/**/*']

  s.require_paths = ['lib']

  s.add_dependency 'deface'

  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rubocop', '~> 0.80.0'
  s.add_development_dependency 'rubocop-minitest', '~> 0.7.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.5.2'
  s.add_development_dependency 'rubocop-rails', '~> 2.4.2'
end
