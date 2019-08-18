require "set"
require_relative "helpers"

module RSpec
  module Mate
    class GutterMarks
      include Helpers

      MARK = "warning".freeze
      SpecError = Struct.new(:line, :message)

      attr_reader :errors_by_path

      def initialize(examples)
        extract_data_from(examples)
      end

      def set_marks
        Dir.chdir(base_dir) do # Paths are relative to project directory
          errors_by_path.each do |path, errors|
            clear_marks_for(path)
            errors.each do |error|
              set_mark_for(path, error.line, error.message)
            end
          end
        end
      end

    private

      def clear_marks_for(path)
        run_mate("--clear-mark=#{MARK}", path)
      end

      def set_mark_for(path, line, message)
        message = message.strip.tr("\n", "\r")
        run_mate("--set-mark=#{MARK}:#{message}", "--line=#{line}", path)
      end

      def run_mate(*args)
        return unless ENV["TM_MATE"]
        system(ENV["TM_MATE"], *args)
      end

      def extract_data_from(examples)
        @errors_by_path = {}
        examples.each do |example|
          @errors_by_path[example.file_path] ||= []
          next unless example.execution_result.status == :failed && example.location =~ /:(\d+)$/
          line = Regexp.last_match(1)
          message = example.exception ? example.exception.message : "(no exception message)"
          @errors_by_path[example.file_path] << SpecError.new(line, message)
        end
      end
    end
  end
end
