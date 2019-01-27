module Railroader
  ASTFile = Struct.new(:path, :ast)

  # This class handles reading and parsing files.
  class FileParser
    attr_reader :file_list

    def initialize tracker, app_tree
      @tracker = tracker
      @timeout = @tracker.options[:parser_timeout]
      @app_tree = app_tree
      @file_list = {}
    end

    def parse_files list, type
      read_files list, type do |path, contents|
        if ast = parse_ruby(contents, path)
          ASTFile.new(path, ast)
        end
      end
    end

    def read_files list, type
      @file_list[type] ||= []

      list.each do |path|
        result = yield path, read_path(path)
        if result
          @file_list[type] << result
        end
      end
    end

    def parse_ruby input, path
      begin
        Railroader.debug "Parsing #{path}"
        RubyParser.new.parse input, path, @timeout
      rescue Racc::ParseError => e
        @tracker.error e, "Could not parse #{path}"
        nil
      rescue Timeout::Error => e
        @tracker.error Exception.new("Parsing #{path} took too long (> #{@timeout} seconds). Try increasing the limit with --parser-timeout"), caller
        nil
      rescue => e
        @tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
        nil
      end
    end

    def read_path path
      @app_tree.read_path path
    end
  end
end
