require 'railroader/checks/check_cross_site_scripting'

#Checks for unescaped values in `content_tag`
#
#    content_tag :tag, body
#                       ^-- Unescaped in Rails 2.x
#
#    content_tag, :tag, body, attribute => value
#                                ^-- Unescaped in all versions
#
#    content_tag, :tag, body, attribute => value
#                                            ^
#                                            |
#            Escaped by default, can be explicitly escaped
#            or not by passing in (true|false) as fourth argument
class Railroader::CheckContentTag < Railroader::CheckCrossSiteScripting
  Railroader::Checks.add self

  @description = "Checks for XSS in calls to content_tag"

  def run_check
    @ignore_methods = Set[:button_to, :check_box, :escapeHTML, :escape_once,
                           :field_field, :fields_for, :h, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :mail_to, :radio_button, :select,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :u, :url_for,
                           :will_paginate].merge tracker.options[:safe_methods]

    @known_dangerous = []
    @content_tags = tracker.find_call :target => false, :method => :content_tag

    @models = tracker.models.keys
    @inspect_arguments = tracker.options[:check_arguments]
    @mark = nil

    Railroader.debug "Checking for XSS in content_tag"
    @content_tags.each do |call|
      process_result call
    end

    check_cve_2016_6316
  end

  def process_result result
    return if duplicate? result

    call = result[:call] = result[:call].dup

    args = call.arglist

    tag_name = args[1]
    content = args[2]
    attributes = args[3]
    escape_attr = args[4]

    @matched = false

    #Silly, but still dangerous if someone uses user input in the tag type
    check_argument result, tag_name

    #Versions before 3.x do not escape body of tag, nor does the rails_xss gem
    unless @matched or (tracker.options[:rails3] and not raw? content)
      check_argument result, content
    end

    #Attribute keys are never escaped, so check them for user input
    if not @matched and hash? attributes and not request_value? attributes
      hash_iterate(attributes) do |k, _v|
        check_argument result, k
        return if @matched
      end
    end

    #By default, content_tag escapes attribute values passed in as a hash.
    #But this behavior can be disabled. So only check attributes hash
    #if they are explicitly not escaped.
    if not @matched and attributes and (false? escape_attr or cve_2016_6316?)
      if request_value? attributes or not hash? attributes
        check_argument result, attributes
      else #check hash values
        hash_iterate(attributes) do |_k, v|
          check_argument result, v
          return if @matched
        end
      end
    end
  end

  def check_argument result, exp
    #Check contents of raw() calls directly
    if raw? exp
      arg = process exp.first_arg
    else
      arg = process exp
    end

    if input = has_immediate_user_input?(arg)
      message = "Unescaped #{friendly_type_of input} in content_tag"

      add_result result

      warn :result => result,
        :warning_type => "Cross-Site Scripting",
        :warning_code => :xss_content_tag,
        :message => message,
        :user_input => input,
        :confidence => :high,
        :link_path => "content_tag"

    elsif not tracker.options[:ignore_model_output] and match = has_immediate_model?(arg)
      unless IGNORE_MODEL_METHODS.include? match.method
        add_result result

        if likely_model_attribute? match
          confidence = :high
        else
          confidence = :medium
        end

        warn :result => result,
          :warning_type => "Cross-Site Scripting",
          :warning_code => :xss_content_tag,
          :message => "Unescaped model attribute in content_tag",
          :user_input => match,
          :confidence => confidence,
          :link_path => "content_tag"
      end

    elsif @matched
      return if @matched.type == :model and tracker.options[:ignore_model_output]

      message = "Unescaped #{friendly_type_of @matched} in content_tag"

      add_result result

      warn :result => result,
        :warning_type => "Cross-Site Scripting",
        :warning_code => :xss_content_tag,
        :message => message,
        :user_input => @matched,
        :confidence => :medium,
        :link_path => "content_tag"
    end
  end

  def process_call exp
    if @mark
      actually_process_call exp
    else
      @mark = true
      actually_process_call exp
      @mark = false
    end

    exp
  end

  def check_cve_2016_6316
    if cve_2016_6316?
      confidence = if @content_tags.any?
                     :high
                   else
                     :medium
                   end

      fix_version = case
                    when version_between?("3.0.0", "3.2.22.3")
                      "3.2.22.4"
                    when version_between?("4.0.0", "4.2.7.0")
                      "4.2.7.1"
                    when version_between?("5.0.0", "5.0.0")
                      "5.0.0.1"
                    when (version.nil? and tracker.options[:rails3])
                      "3.2.22.4"
                    when (version.nil? and tracker.options[:rails4])
                      "4.2.7.2"
                    else
                      return
                    end

      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :CVE_2016_6316,
        :message => "Rails #{rails_version} content_tag does not escape double quotes in attribute values (CVE-2016-6316). Upgrade to #{fix_version}",
        :confidence => confidence,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/msg/ruby-security-ann/8B2iV2tPRSE/JkjCJkSoCgAJ"
    end
  end

  def raw? exp
    call? exp and exp.method == :raw
  end

  def cve_2016_6316?
    version_between? "3.0.0", "3.2.22.3" or
    version_between? "4.0.0", "4.2.7.0" or
    version_between? "5.0.0", "5.0.0.0"
  end
end
