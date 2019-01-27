begin
  Railroader.load_railroader_dependency 'ruby_parser'
  require 'ruby_parser/bm_sexp.rb'
  require 'ruby_parser/bm_sexp_processor.rb'
  require 'railroader/processor'
  require 'railroader/app_tree'
  require 'railroader/file_parser'
  require 'railroader/parsers/template_parser'
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install the appropriate dependency."
  exit(-1)
end

#Scans the Rails application.
class Railroader::Scanner
  attr_reader :options
  RUBY_1_9 = RUBY_VERSION >= "1.9.0"

  #Pass in path to the root of the Rails application
  def initialize options, processor = nil
    @options = options
    @app_tree = Railroader::AppTree.from_options(options)

    if (!@app_tree.root || !@app_tree.exists?("app")) && !options[:force_scan]
      raise Railroader::NoApplication, "Please supply the path to a Rails application (looking in #{@app_tree.root})."
    end

    @processor = processor || Railroader::Processor.new(@app_tree, options)
  end

  #Returns the Tracker generated from the scan
  def tracker
    @processor.tracked_events
  end

  #Process everything in the Rails application
  def process
    Railroader.notify "Processing gems..."
    process_gems
    guess_rails_version
    Railroader.notify "Processing configuration..."
    process_config
    Railroader.notify "Parsing files..."
    parse_files
    Railroader.notify "Processing initializers..."
    process_initializers
    Railroader.notify "Processing libs..."
    process_libs
    Railroader.notify "Processing routes...          "
    process_routes
    Railroader.notify "Processing templates...       "
    process_templates
    Railroader.notify "Processing data flow in templates..."
    process_template_data_flows
    Railroader.notify "Processing models...          "
    process_models
    Railroader.notify "Processing controllers...     "
    process_controllers
    Railroader.notify "Processing data flow in controllers..."
    process_controller_data_flows
    Railroader.notify "Indexing call sites...        "
    index_call_sites
    tracker
  end

  def parse_files
    fp = Railroader::FileParser.new tracker, @app_tree

    files = {
      :initializers => @app_tree.initializer_paths,
      :controllers => @app_tree.controller_paths,
      :models => @app_tree.model_paths
    }

    unless options[:skip_libs]
      files[:libs] = @app_tree.lib_paths
    end

    files.each do |name, paths|
      fp.parse_files paths, name
    end

    template_parser = Railroader::TemplateParser.new(tracker, fp)

    fp.read_files(@app_tree.template_paths, :templates) do |path, contents|
      template_parser.parse_template path, contents
    end

    @file_list = fp.file_list
  end

  #Process config/environment.rb and config/gems.rb
  #
  #Stores parsed information in tracker.config
  def process_config
    if options[:rails3] or options[:rails4] or options[:rails5]
      process_config_file "application.rb"
      process_config_file "environments/production.rb"
    else
      process_config_file "environment.rb"
      process_config_file "gems.rb"
    end

    if @app_tree.exists?("vendor/plugins/rails_xss") or
      options[:rails3] or options[:escape_html]

      tracker.config.escape_html = true
      Railroader.notify "[Notice] Escaping HTML by default"
    end

    if @app_tree.exists? ".ruby-version"
      tracker.config.set_ruby_version @app_tree.read ".ruby-version"
    end
  end

  def process_config_file file
    path = "config/#{file}"

    if @app_tree.exists?(path)
      @processor.process_config(parse_ruby(@app_tree.read(path)), path)
    end

  rescue => e
    Railroader.notify "[Notice] Error while processing #{path}"
    tracker.error e.exception(e.message + "\nwhile processing #{path}"), e.backtrace
  end

  private :process_config_file

  #Process Gemfile
  def process_gems
    gem_files = {}
    if @app_tree.exists? "Gemfile"
      gem_files[:gemfile] = { :src => parse_ruby(@app_tree.read("Gemfile")), :file => "Gemfile" }
    elsif @app_tree.exists? "gems.rb"
      gem_files[:gemfile] = { :src => parse_ruby(@app_tree.read("gems.rb")), :file => "gems.rb" }
    end

    if @app_tree.exists? "Gemfile.lock"
      gem_files[:gemlock] = { :src => @app_tree.read("Gemfile.lock"), :file => "Gemfile.lock" }
    elsif @app_tree.exists? "gems.locked"
      gem_files[:gemlock] = { :src => @app_tree.read("gems.locked"), :file => "gems.locked" }
    end

    if gem_files[:gemfile] or gem_files[:gemlock]
      @processor.process_gems gem_files
    end
  rescue => e
    Railroader.notify "[Notice] Error while processing Gemfile."
    tracker.error e.exception(e.message + "\nWhile processing Gemfile"), e.backtrace
  end

  #Set :rails3/:rails4 option if version was not determined from Gemfile
  def guess_rails_version
    unless tracker.options[:rails3] or tracker.options[:rails4]
      if @app_tree.exists?("script/rails")
        tracker.options[:rails3] = true
        Railroader.notify "[Notice] Detected Rails 3 application"
      elsif @app_tree.exists?("app/channels")
        tracker.options[:rails3] = true
        tracker.options[:rails4] = true
        tracker.options[:rails5] = true
        Railroader.notify "[Notice] Detected Rails 5 application"
      elsif not @app_tree.exists?("script")
        tracker.options[:rails3] = true
        tracker.options[:rails4] = true
        Railroader.notify "[Notice] Detected Rails 4 application"
      end
    end
  end

  #Process all the .rb files in config/initializers/
  #
  #Adds parsed information to tracker.initializers
  def process_initializers
    track_progress @file_list[:initializers] do |init|
      Railroader.debug "Processing #{init[:path]}"
      process_initializer init
    end
  end

  #Process an initializer
  def process_initializer init
    @processor.process_initializer(init.path, init.ast)
  end

  #Process all .rb in lib/
  #
  #Adds parsed information to tracker.libs.
  def process_libs
    if options[:skip_libs]
      Railroader.notify '[Skipping]'
      return
    end

    track_progress @file_list[:libs] do |lib|
      Railroader.debug "Processing #{lib.path}"
      process_lib lib
    end
  end

  #Process a library
  def process_lib lib
    @processor.process_lib lib.ast, lib.path
  end

  #Process config/routes.rb
  #
  #Adds parsed information to tracker.routes
  def process_routes
    if @app_tree.exists?("config/routes.rb")
      begin
        @processor.process_routes parse_ruby(@app_tree.read("config/routes.rb"))
      rescue => e
        tracker.error e.exception(e.message + "\nWhile processing routes.rb"), e.backtrace
        Railroader.notify "[Notice] Error while processing routes - assuming all public controller methods are actions."
        options[:assume_all_routes] = true
      end
    else
      Railroader.notify "[Notice] No route information found"
    end
  end

  #Process all .rb files in controllers/
  #
  #Adds processed controllers to tracker.controllers
  def process_controllers
    track_progress @file_list[:controllers] do |controller|
      Railroader.debug "Processing #{controller.path}"
      process_controller controller
    end
  end

  def process_controller_data_flows
    controllers = tracker.controllers.sort_by { |name, _| name.to_s }

    track_progress controllers, "controllers" do |name, controller|
      Railroader.debug "Processing #{name}"
      controller.src.each do |file, src|
        @processor.process_controller_alias name, src, nil, file
      end
    end

    #No longer need these processed filter methods
    tracker.filter_cache.clear
  end

  def process_controller astfile
    begin
      @processor.process_controller(astfile.ast, astfile.path)
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{astfile.path}"), e.backtrace
    end
  end

  #Process all views and partials in views/
  #
  #Adds processed views to tracker.views
  def process_templates
    templates = @file_list[:templates].sort_by { |t| t[:path] }

    track_progress templates, "templates" do |template|
      Railroader.debug "Processing #{template[:path]}"
      process_template template
    end
  end

  def process_template template
    @processor.process_template(template.name, template.ast, template.type, nil, template.path)
  end

  def process_template_data_flows
    templates = tracker.templates.sort_by { |name, _| name.to_s }

    track_progress templates, "templates" do |name, template|
      Railroader.debug "Processing #{name}"
      @processor.process_template_alias template
    end
  end

  #Process all the .rb files in models/
  #
  #Adds the processed models to tracker.models
  def process_models
    track_progress @file_list[:models] do |model|
      Railroader.debug "Processing #{model[:path]}"
      process_model model[:path], model[:ast]
    end
  end

  def process_model path, ast
    @processor.process_model(ast, path)
  end

  def track_progress list, type = "files"
    total = list.length
    current = 0
    list.each do |item|
      report_progress current, total, type
      current += 1
      yield item
    end
  end

  def report_progress(current, total, type = "files")
    return unless @options[:report_progress]
    $stderr.print " #{current}/#{total} #{type} processed\r"
  end

  def index_call_sites
    tracker.index_call_sites
  end

  def parse_ruby input
    RubyParser.new.parse input
  end
end

# This is to allow operation without loading the Haml library
module Haml; class Error < StandardError; end; end
