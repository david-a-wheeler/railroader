require './lib/railroader/version'
require './gem_common'
gem_priv_key = File.expand_path("~/.ssh/gem-private_key.pem")

Gem::Specification.new do |s|
  s.name = %q{railroader}
  s.version = Railroader::Version
  s.authors = ["Justin Collins"]
  s.email = "gem@railroader.org"
  s.summary = "Security vulnerability scanner for Ruby on Rails."
  s.description = "Railroader detects security vulnerabilities in Ruby on Rails applications via static analysis."
  s.homepage = "http://railroaderscanner.org"
  s.files = ["bin/railroader", "CHANGES.md", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["railroader"]
  s.license = "MIT"
  s.cert_chain  = ['railroader-public_cert.pem']
  s.signing_key = gem_priv_key if File.exist? gem_priv_key and $0 =~ /gem\z/

  if File.exist? 'bundle/load.rb'
    s.files += Dir['bundle/ruby/*/gems/**/*'] + ['bundle/load.rb']
  else
    Railroader::GemDependencies.dev_dependencies(s) unless ENV['BM_PACKAGE']
    Railroader::GemDependencies.base_dependencies(s)
    Railroader::GemDependencies.extended_dependencies(s)
  end
end
