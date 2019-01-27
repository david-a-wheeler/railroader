require 'railroader/processors/base_processor'
require 'railroader/processors/alias_processor'
require 'railroader/processors/lib/rails3_config_processor.rb'
require 'railroader/processors/lib/rails2_config_processor.rb'

class Railroader::ConfigProcessor
  def self.new tracker
    if tracker.options[:rails3]
      Railroader::Rails3ConfigProcessor.new tracker
    else
      Railroader::Rails2ConfigProcessor.new tracker
    end
  end
end
