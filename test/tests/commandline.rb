require_relative '../test'
require 'railroader/commandline'

class CLExit < StandardError
  attr_reader :exit_code

  def initialize exit_code, message
    super message

    @exit_code = exit_code
  end
end

class TestCommandline < Railroader::Commandline
  def self.quit exit_code = 0, message = nil
    raise CLExit.new(exit_code, message)
  end
end

class CommandlineTests < Minitest::Test

  # Helper assertions

  def assert_exit exit_code = 0, message = nil
    begin
      yield
    rescue CLExit => e
      assert_equal exit_code, e.exit_code
      assert_equal message, e.message if message
    end
  end

  def assert_stdout message, exit_code = 0
    assert_output message, "" do
      assert_exit exit_code do
        yield
      end
    end
  end

  def assert_stderr message, exit_code = 0
    assert_output "", message do
      assert_exit exit_code do
        yield
      end
    end
  end

  # Helpers

  def cl_with_options *opts
    TestCommandline.start *TestCommandline.parse_options(opts)
  end

  def scan_app *opts
    opts << "#{TEST_PATH}/apps/rails4"
    assert_output do
      cl_with_options *opts
    end
  end

  def setup
    Railroader.debug = false
    Railroader.quiet = false
  end

  # Tests

  def test_nonexistent_scan_path
    assert_exit Railroader::No_App_Found_Exit_Code do
      cl_with_options "/fake_railroader_test_path"
    end
  end

  def test_default_scan_path
    options = {}
    
    TestCommandline.set_options options

    assert_equal ".", options[:app_path]
  end

  def test_list_checks
    assert_stderr /\AAvailable Checks:/ do
      cl_with_options "--checks"
    end
  end

  def test_bad_options
    assert_stderr /\Ainvalid option: --not-a-real-option\nPlease see `railroader --help`/, -1 do
      cl_with_options "--not-a-real-option"
    end
  end

  def test_version
    assert_stdout "railroader #{Railroader::Version}\n" do
      cl_with_options "-v"
    end
  end

  def test_empty_config
    empty_config = "--- {}\n"

    assert_stderr empty_config do
      cl_with_options "-C"
    end
  end

  def test_show_help
    assert_stdout /\AUsage: railroader \[options\] rails\/root\/path/ do
      assert_exit do
        cl_with_options "--help"
      end
    end
  end

  def test_exit_on_warn_default
    assert_exit Railroader::Warnings_Found_Exit_Code do
      scan_app
    end
  end

  def test_no_exit_on_warn
    assert_exit do
      scan_app "--no-exit-on-warn"
    end
  end

  def test_exit_on_warn_no_warnings
    assert_exit do
      scan_app "-t", "None"
    end
  end
end
