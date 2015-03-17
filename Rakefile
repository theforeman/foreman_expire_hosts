# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "foreman_expire_hosts"
  gem.homepage = "https://github.com/ingenico-group/foreman_expire_hosts"
  gem.license = "MIT"
  gem.summary = %Q{This Plugin will add new column expired_on to hosts table and input filed to host form }
  gem.description = %Q{This Plugin will add new column expired_on to hosts table and input filed to host form}
  gem.email = "nn.nagarjuna@gmail.com"
  gem.authors = ["Nagarjuna Rachaneni"]
  # dependencies defined in Gemfile
end

task :default => :test
