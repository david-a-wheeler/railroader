require 'railroader/tracker/collection'
require 'railroader/tracker/controller'
require 'railroader/tracker/model'

module Railroader
  class Library < Railroader::Collection
    include ControllerMethods
    include ModelMethods

    def initialize name, parent, file_name, src, tracker
      super
      initialize_controller
      initialize_model
      @collection = tracker.libs
    end
  end
end
