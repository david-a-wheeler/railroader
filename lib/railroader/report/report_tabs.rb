# Generated tab-separated output suitable for the Jenkins Railroader Plugin:
# https://github.com/presidentbeef/railroader-jenkins-plugin
class Railroader::Report::Tabs < Railroader::Report::Base
  def generate_report
    [[:generic_warnings, "General"], [:controller_warnings, "Controller"],
     [:model_warnings, "Model"], [:template_warnings, "Template"]].map do |meth, category|

      self.send(meth).map do |w|
        line = w.line || 0
        w.warning_type.gsub!(/[^\w\s]/, ' ')
        "#{warning_file(w, :absolute)}\t#{line}\t#{w.warning_type}\t#{category}\t#{w.format_message}\t#{TEXT_CONFIDENCE[w.confidence]}"
      end.join "\n"

    end.join "\n"

  end
end
