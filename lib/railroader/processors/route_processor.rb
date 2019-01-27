require 'railroader/processors/base_processor'
require 'railroader/processors/alias_processor'
require 'railroader/processors/lib/route_helper'
require 'railroader/util'
require 'railroader/processors/lib/rails3_route_processor.rb'
require 'railroader/processors/lib/rails2_route_processor.rb'
require 'set'

class Railroader::RoutesProcessor
  def self.new tracker
    if tracker.options[:rails3]
      Railroader::Rails3RoutesProcessor.new tracker
    else
      Railroader::Rails2RoutesProcessor.new tracker
    end
  end
end
