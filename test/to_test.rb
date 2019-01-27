#This is a utility script for generating tests from reported warnings.
#
#It is not heavily tested. It is mostly for the convenience of coders. Sometimes
#it generates broken code which will need to be fixed manually.
#
#Usage:
#
#  ruby to_test.rb apps/some_app > tests/test_some_app.rb`

# Set paths
$LOAD_PATH.unshift "#{File.expand_path(File.dirname(__FILE__))}/../lib"

require 'railroader'
require 'ruby_parser'
require 'ruby_parser/bm_sexp'
require 'railroader/options'
require 'railroader/report/report_base'

class Railroader::Report::Tests < Railroader::Report::Base
  def generate_report
    counter = 0

    name = camelize File.basename(tracker.app_path)

    output = <<-RUBY
abort "Please run using test/test.rb" unless defined? RailroaderTester

#{name} = RailroaderTester.run_scan "#{File.basename tracker.app_path}", "#{name}"

class #{name}Tests < Test::Unit::TestCase
  include RailroaderTester::FindWarning
  include RailroaderTester::CheckExpected

  def expected
    @expected ||= {
      :controller => #{@checks.controller_warnings.length},
      :model => #{@checks.model_warnings.length},
      :template => #{@checks.template_warnings.length},
      :warning => #{@checks.warnings.length} }
  end

  def report
    #{name}
  end

    RUBY

    output << @checks.all_warnings.map do |w|
      counter += 1

      <<-RUBY
  def test_#{w.warning_type.to_s.downcase.tr(" -", "__")}_#{counter}
    assert_warning :type => #{w.warning_set.inspect},
      :warning_code => #{w.warning_code},
      :fingerprint => #{w.fingerprint.inspect},
      :warning_type => #{w.warning_type.inspect},
      :line => #{w.line.inspect},
      :message => /^#{Regexp.escape w.message[0,40]}/,
      :confidence => #{w.confidence},
      :relative_path => #{w.relative_path.inspect},
      :code => #{w.code},
      :user_input => #{w.user_input.inspect}
  end
      RUBY
    end.join("\n")

    output << "\nend"
  end
end

options, _ = Railroader::Options.parse!(ARGV)

unless options[:app_path]
  if ARGV[-1].nil?
    options[:app_path] = "."
  else
    options[:app_path] = ARGV[-1]
  end
end

tracker = Railroader.run options

puts Railroader::Report::Tests.new(nil, tracker).generate_report
