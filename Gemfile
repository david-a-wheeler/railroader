source "https://rubygems.org"

gemspec :name => "railroader"

unless ENV['BM_PACKAGE']
  gem "rake", "< 10.2.0"
  gem "codeclimate-test-reporter", group: :test, require: nil
  gem "json", "< 2.0", group: :test, require: nil # For Ruby 1.9.3 https://github.com/colszowka/simplecov/issues/511
  gem 'byebug', '11.0.0'
end
