require 'railroader/checks/base_check'

class Railroader::CheckExternalCheckConfigTest < Railroader::BaseCheck
  Railroader::Checks.add_optional self

  @description = "An external check for testing"

  def run_check
    raise "This should not have been loaded!"
  end
end
