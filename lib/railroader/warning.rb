require 'json'
require 'digest/sha2'
require 'railroader/warning_codes'

#The Warning class stores information about warnings
class Railroader::Warning
  attr_reader :called_from, :check, :class, :confidence, :controller,
    :line, :method, :model, :template, :user_input, :user_input_type,
    :warning_code, :warning_set, :warning_type

  attr_accessor :code, :context, :file, :message, :relative_path

  TEXT_CONFIDENCE = {
    0 => "High",
    1 => "Medium",
    2 => "Weak",
  }

  CONFIDENCE = {
    :high => 0,
    :med => 1,
    :medium => 1,
    :low => 2,
    :weak => 2,
  }

  OPTIONS = {
    :called_from => :@called_from,
    :check => :@check,
    :class => :@class,
    :code => :@code,
    :controller => :@controller,
    :file => :@file,
    :gem_info => :@gem_info,
    :line => :@line,
    :link_path => :@link_path,
    :message => :@message,
    :method => :@method,
    :model => :@model,
    :relative_path => :@relative_path,
    :template => :@template,
    :user_input => :@user_input,
    :warning_set => :@warning_set,
    :warning_type => :@warning_type,
  }

  #+options[:result]+ can be a result from Tracker#find_call. Otherwise, it can be +nil+.
  def initialize options = {}
    @view_name = nil

    OPTIONS.each do |key, var|
      self.instance_variable_set(var, options[key])
    end

    self.confidence = options[:confidence]

    result = options[:result]
    if result
      @code ||= result[:call]
      @file ||= result[:location][:file]

      if result[:location][:type] == :template #template result
        @template ||= result[:location][:template]
      else
        @class ||= result[:location][:class]
        @method ||= result[:location][:method]
      end
    end

    if @method.to_s =~ /^fake_filter\d+/
      @method = :before_filter
    end

    if @user_input.is_a? Railroader::BaseCheck::Match
      @user_input_type = @user_input.type
      @user_input = @user_input.match
    elsif @user_input == false
      @user_input = nil
    end

    if not @line
      if @user_input and @user_input.respond_to? :line
        @line = @user_input.line
      elsif @code and @code.respond_to? :line
        @line = @code.line
      end
    end

    if @gem_info
      if @gem_info.is_a? Hash
        @line ||= @gem_info[:line]
        @file ||= @gem_info[:file]
      else
        # Fallback behavior returns just a string for the file name
        @file ||= @gem_info
      end
    end

    unless @warning_set
      if self.model
        @warning_set = :model
      elsif self.template
        @warning_set = :template
        @called_from = self.template.render_path
      elsif self.controller
        @warning_set = :controller
      else
        @warning_set = :warning
      end
    end

    if options[:warning_code]
      @warning_code = Railroader::WarningCodes.code options[:warning_code]
    end

    Railroader.debug("Warning created without warning code: #{options[:warning_code]}") unless @warning_code

    @format_message = nil
    @row = nil
  end

  def hash
    self.to_s.hash
  end

  def eql? other_warning
    self.hash == other_warning.hash
  end

  def confidence= conf
    @confidence = case conf
                  when Integer
                    conf
                  when Symbol
                    CONFIDENCE[conf]
                  else
                    raise "Could not set confidence to `#{conf}`"
                  end

    raise "Could not set confidence to `#{conf}`" unless @confidence
    raise "Invalid confidence: `#{@confidence}`" unless TEXT_CONFIDENCE[@confidence]
  end

  #Returns name of a view, including where it was rendered from
  def view_name(include_renderer = true)
    if called_from and include_renderer
      @view_name = "#{template.name} (#{called_from.last})"
    else
      @view_name = template.name
    end
  end

  #Return String of the code output from the OutputProcessor and
  #stripped of newlines and tabs.
  def format_code strip = true
    format_ruby self.code, strip
  end

  #Return String of the user input formatted and
  #stripped of newlines and tabs.
  def format_user_input strip = true
    format_ruby self.user_input, strip
  end

  def format_with_user_input strip = true, &block
    if self.user_input
      formatted = Railroader::OutputProcessor.new.format(code, self.user_input, &block)
      formatted.gsub!(/(\t|\r|\n)+/, " ") if strip
      formatted
    else
      format_code
    end
  end

  #Return formatted warning message
  def format_message
    return @format_message if @format_message

    @format_message = self.message.dup

    if self.line
      @format_message << " near line #{self.line}"
    end

    if self.code
      @format_message << ": #{format_code}"
    end

    @format_message
  end

  def link
    return @link if @link

    if @link_path
      if @link_path.start_with? "http"
        @link = @link_path
      else
        @link = "https://railroaderscanner.org/docs/warning_types/#{@link_path}"
      end
    else
      warning_path = self.warning_type.to_s.downcase.gsub(/\s+/, '_') + "/"
      @link = "https://railroaderscanner.org/docs/warning_types/#{warning_path}"
    end

    @link
  end

  #Generates a hash suitable for inserting into a table
  def to_row type = :warning
    @row = { "Confidence" => self.confidence,
      "Warning Type" => self.warning_type.to_s,
      "Message" => self.format_message }

    case type
    when :template
      @row["Template"] = self.view_name.to_s
    when :model
      @row["Model"] = self.model.to_s
    when :controller
      @row["Controller"] = self.controller.to_s
    when :warning
      @row["Class"] = self.class.to_s
      @row["Method"] = self.method.to_s
    end

    @row
  end

  def to_s
   output =  "(#{TEXT_CONFIDENCE[self.confidence]}) #{self.warning_type} - #{self.message}"
   output << " near line #{self.line}" if self.line
   output << " in #{self.file}" if self.file
   output << ": #{self.format_code}" if self.code

   output
  end

  def fingerprint
    loc = self.location
    location_string = loc && loc.sort_by { |k, v| k.to_s }.inspect
    warning_code_string = sprintf("%03d", @warning_code)
    code_string = @code.inspect

    Digest::SHA2.new(256).update("#{warning_code_string}#{code_string}#{location_string}#{@relative_path}#{self.confidence}").to_s
  end

  def location include_renderer = true
    case @warning_set
    when :template
      location = { :type => :template, :template => self.view_name(include_renderer) }
    when :model
      location = { :type => :model, :model => self.model }
    when :controller
      location = { :type => :controller, :controller => self.controller }
    when :warning
      if self.class
        location = { :type => :method, :class => self.class, :method => self.method }
      else
        location = nil
      end
    end
  end

  def to_hash
    { :warning_type => self.warning_type,
      :warning_code => @warning_code,
      :fingerprint => self.fingerprint,
      :check_name => self.check.gsub(/^Railroader::Check/, ''),
      :message => self.message,
      :file => self.file,
      :line => self.line,
      :link => self.link,
      :code => (@code && self.format_code(false)),
      :render_path => self.called_from,
      :location => self.location(false),
      :user_input => (@user_input && self.format_user_input(false)),
      :confidence => TEXT_CONFIDENCE[self.confidence]
    }
  end

  def to_json
    JSON.generate self.to_hash
  end

  private

  def format_ruby code, strip
    formatted = Railroader::OutputProcessor.new.format(code)
    formatted.gsub!(/(\t|\r|\n)+/, " ") if strip
    formatted
  end
end

