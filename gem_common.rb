module Railroader
  module GemDependencies
    def self.dev_dependencies spec
      spec.add_development_dependency "minitest"
      spec.add_development_dependency 'rubocop', '~> 0.68.1'
      spec.add_development_dependency 'rubocop-performance'
    end

    def self.base_dependencies spec
      spec.add_dependency "ruby_parser", "~>3.13.1"
      # 4.12.1 known to cause problems
      spec.add_dependency "sexp_processor", ["~> 4.7", "!= 4.12.1", "< 4.13"]
      spec.add_dependency "ruby2ruby", "~>2.4.0"
      spec.add_dependency "safe_yaml", ">= 1.0"
    end

    def self.extended_dependencies spec
      spec.add_dependency "terminal-table", "~>1.4"
      spec.add_dependency "highline", ">=1.6.20", "<2.0"
      spec.add_dependency "erubis", "~>2.6"
      spec.add_dependency "haml", ">=3.0", "<5.0"
      spec.add_dependency "sass", "~>3.0", "<3.5.0"
      spec.add_dependency "slim", ">=1.3.6", "<3.0.8"
    end
  end
end
