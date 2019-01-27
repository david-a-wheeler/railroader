require 'railroader/processors/lib/processor_helper'
require 'railroader/processors/lib/safe_call_helper'
require 'railroader/util'

class Railroader::BasicProcessor < Railroader::SexpProcessor
  include Railroader::ProcessorHelper
  include Railroader::SafeCallHelper
  include Railroader::Util

  def initialize tracker
    super()
    @tracker = tracker
    @current_template = @current_module = @current_class = @current_method = nil
  end

  def process_default exp
    process_all exp
  end

  def process_if exp
    condition = exp.condition

    process condition

    if true? condition
      process exp.then_clause
    elsif false? condition
      process exp.else_clause
    else
      [exp.then_clause, exp.else_clause].compact.map do |e|
        process e
      end
    end

    exp
  end
end
