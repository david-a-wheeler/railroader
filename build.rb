#!/usr/bin/env ruby
puts 'Packaging Railroader gem...'

system 'rm -rf bundle Gemfile.lock railroader-*.gem' and
system 'BM_PACKAGE=true bundle install --standalone'

abort "No bundle installed" unless Dir.exist? 'bundle'

File.delete "bundle/bundler/setup.rb"
Dir.delete "bundle/bundler"

File.open "bundle/load.rb", "w" do |f|
  f.puts "path = File.expand_path('../..', __FILE__)"

  Dir["bundle/ruby/**/lib"].each do |dir|
    f.puts %Q[$:.unshift "\#{path}/#{dir}"]
  end
end

system "BM_PACKAGE=true gem build railroader.gemspec"
