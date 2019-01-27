require_relative '../test'
require 'json'

class JSONCompareTests < Minitest::Test
  include RailroaderTester::DiffHelper

  def setup
    @path = File.expand_path "#{TEST_PATH}/apps/rails3.2"
    @json_path = File.join @path, "doesnt_exist", "report.json"
    teardown # just to be sure
    Railroader.run :app_path => @path, :output_files => [@json_path]
    @report = JSON.parse File.read(@json_path)
  end

  def teardown
    File.delete @json_path if File.exist? @json_path
    Dir.delete File.dirname(@json_path) if Dir.exist? File.dirname(@json_path)
  end

  def update_json
    File.open @json_path, "w" do |f|
      f.puts @report.to_json
    end
  end

  def diff
    @diff = Railroader.compare :app_path => @path, :previous_results_json => @json_path
  end

  def test_sanity
    diff

    assert_fixed 0
    assert_new 0
  end
end
