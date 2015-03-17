$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foreman_expire_hosts/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.name = %q{foreman_expire_hosts}
  s.version     = ForemanExpireHosts::VERSION
  s.authors = ["Nagarjuna Rachaneni"]
  s.email = "nn.nagarjuna@gmail.com"
  s.description = "This Plugin will add new column expired_on to hosts table and input filed to host form"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = Dir["{app,test,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]
  s.homepage = "https://github.com/ingenico-group/foreman_expire_hosts"
  s.licenses = ["MIT"]
  s.summary = "This Plugin will add new column expired_on to hosts table and input filed to host form"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.add_dependency "deface"
end

