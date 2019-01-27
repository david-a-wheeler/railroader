Brakeman.load_brakeman_dependency 'highline'

class Brakeman::Report::Text < Brakeman::Report::Base
  def generate_report
    HighLine.use_color = !!tracker.options[:output_color]
    summary_option = tracker.options[:summary_only]
    @output_string = "\n"

    unless summary_option == :no_summary
      add_chunk generate_header
      add_chunk generate_overview
      add_chunk generate_warning_overview
    end

    if summary_option == :summary_only or summary_option == true
      return @output_string
    end

    add_chunk generate_controllers if tracker.options[:debug] or tracker.options[:report_routes]
    add_chunk generate_templates if tracker.options[:debug]
    add_chunk generate_obsolete
    add_chunk generate_errors 
    add_chunk generate_warnings
  end

  def add_chunk chunk, out = @output_string
    if chunk and not chunk.empty?
      if chunk.is_a? Array
        chunk = chunk.join("\n")
      end

      out << chunk << "\n\n"
    end
  end

  def generate_header
    [
      header("Brakeman Report"), 
      label("Application Path", tracker.app_path),
      label("Rails Version", rails_version),
      label("Brakeman Version", Brakeman::Version),
      label("Scan Date", tracker.start_time),
      label("Duration", "#{tracker.duration} seconds"),
      label("Checks Run", checks.checks_run.sort.join(", "))
    ]
  end

  def generate_overview
    overview = [
      header("Overview"),
      label('Controllers', tracker.controllers.length),
      label('Models', tracker.models.length - 1),
      label('Templates', number_of_templates(@tracker)),
      label('Errors', tracker.errors.length),
      label('Security Warnings', all_warnings.length)
    ]

    unless ignored_warnings.empty?
      overview << label('Ignored Warnings', ignored_warnings.length)
    end

    overview
  end

  def generate_warning_overview
    warning_types = warnings_summary
    warning_types.delete :high_confidence

    warning_types.sort_by { |t, c| t }.map do |type, count|
      label(type, count)
    end.unshift(header('Warning Types'))
  end

  def generate_warnings
    if tracker.filtered_warnings.empty?
      HighLine.color("No warnings found", :bold, :green)
    else
      warnings = tracker.filtered_warnings.sort_by do |w|
        [w.confidence, w.warning_type, w.fingerprint]
      end.map do |w|
        output_warning w
      end

      double_space "Warnings", warnings
    end
  end

  def generate_errors
    return if tracker.errors.empty?
    full_trace = tracker.options[:debug]

    errors = tracker.errors.map do |e|
      trace = if full_trace
        e[:backtrace].join("\n")
      else
        e[:backtrace][0]
      end

      [
        label("Error", e[:error]),
        label("Location", trace)
      ]
    end

    double_space "Errors", errors
  end

  def generate_obsolete
    return if tracker.unused_fingerprints.empty?

    [header("Obsolete Ignore Entries")] + tracker.unused_fingerprints
  end

  def generate_templates
    out_processor = Brakeman::OutputProcessor.new

    template_rows = {}
    tracker.templates.each do |name, template|
      template.each_output do |out|
        out = out_processor.format out
        template_rows[name] ||= []
        template_rows[name] << out.gsub("\n", ";").gsub(/\s+/, " ")
      end
    end

    double_space "Template Output", template_rows.sort_by { |name, value| name.to_s }.map { |template|
      [HighLine.new.color(template.first.to_s << "\n", :cyan)] + template[1]
    }.compact
  end

  def output_warning w
    out = [
      label('Confidence', confidence(w.confidence)),
      label('Category', w.warning_type.to_s),
      label('Check', w.check.gsub(/^Brakeman::Check/, '')),
      label('Message', w.message)
    ]

    if w.code
      out << label('Code', format_code(w))
    end

    out << label('File', warning_file(w))

    if w.line
      out << label('Line', w.line)
    end

    out
  end

  def double_space title, values
    values = values.map { |v| v.join("\n") }.join("\n\n")
    [header(title), values]
  end

  def format_code w
    if @highlight_user_input and w.user_input
      w.format_with_user_input do |exp, text|
        HighLine.new.color(text, :yellow)
      end
    else
      w.format_code
    end
  end

  def confidence c
    case c
    when 0
      HighLine.new.color("High", :red)
    when 1
      HighLine.new.color("Medium", :yellow)
    when 2
      HighLine.new.color("Weak", :none)
    end
  end

  def label l, value, color = :green
    "#{HighLine.new.color(l, color)}: #{value}"
  end

  def header text
    HighLine.new.color("== #{text} ==\n", :bold, :magenta)
  end

  # ONLY used for generate_controllers to avoid duplication
  def render_array name, cols, values, locals
    controllers = values.map do |name, parent, includes, routes|
      c = [ label("Controller", name) ]
      c << label("Parent", parent) unless parent.empty?
      c << label("Includes", includes) unless includes.empty?
      c << label("Routes", routes)
    end

    double_space "Controller Overview", controllers
  end
end

