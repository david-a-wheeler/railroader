require 'railroader/report/report_base'

#Generates a report based on the Tracker and the results of
#Tracker#run_checks. Be sure to +run_checks+ before generating
#a report.
class Railroader::Report
  attr_reader :tracker

  VALID_FORMATS = [:to_html, :to_pdf, :to_csv, :to_json, :to_tabs, :to_hash, :to_s, :to_markdown, :to_codeclimate, :to_plain, :to_text]

  def initialize app_tree, tracker
    @app_tree = app_tree
    @tracker = tracker
  end

  def format format
    reporter = case format
    when :to_codeclimate
      require_report 'codeclimate'
      Railroader::Report::CodeClimate
    when :to_csv
      require_report 'csv'
      Railroader::Report::CSV
    when :to_html
      require_report 'html'
      Railroader::Report::HTML
    when :to_json
      return self.to_json
    when :to_tabs
      require_report 'tabs'
      Railroader::Report::Tabs
    when :to_hash
      require_report 'hash'
      Railroader::Report::Hash
    when :to_markdown
      return self.to_markdown
    when :to_plain, :to_text, :to_s
      return self.to_plain
    when :to_table
      return self.to_table
    when :to_pdf
      raise "PDF output is not yet supported."
    else
      raise "Invalid format: #{format}. Should be one of #{VALID_FORMATS.inspect}"
    end

    generate(reporter)
  end

  def method_missing method, *args
    if VALID_FORMATS.include? method
      format method
    else
      super
    end
  end

  def require_report type
    require "railroader/report/report_#{type}"
  end

  def to_json
    require_report 'json'
    generate Railroader::Report::JSON
  end

  def to_table
    require_report 'table'
    generate Railroader::Report::Table
  end

  def to_markdown
    require_report 'markdown'
    generate Railroader::Report::Markdown
  end

  def to_text
    require_report 'text'
    generate Railroader::Report::Text
  end

  alias to_plain to_text
  alias to_s to_text

  def generate reporter
    reporter.new(@app_tree, @tracker).generate_report
  end
end
