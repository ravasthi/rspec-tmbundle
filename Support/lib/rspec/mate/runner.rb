require 'stringio'
require 'cgi'
require 'shellwords'
require 'open3'
require 'yaml'

# This works because we declare a dependency on the Ruby bundle (see `info.plist`).
require "#{ENV['TM_RUBY_BUNDLE_SUPPORT']}/lib/executable"

require_relative 'helpers'

module RSpec
  module Mate
    class Runner
      include Helpers
      LAST_REMEMBERED_FILE_CACHE = "/tmp/textmate_rspec_last_remembered_file_cache.txt".freeze
      LAST_RUN_CACHE             = "/tmp/textmate_rspec_last_run.yml".freeze

      def run_files(options={})
        files = ENV['TM_SELECTED_FILES'] ? Shellwords.shellwords(ENV['TM_SELECTED_FILES']) : ["spec/"]
        options[:files] = files
        run(options)
      end

      def run_file(options={})
        options[:files] = [single_file]
        run(options)
      end

      def run_last_remembered_file(options={})
        options[:files] = [last_remembered_single_file]
        run(options)
      end

      def run_again
        run(:run_again => true)
      end

      def run_focussed(options={})
        options[:files] = [single_file]
        options[:line] = ENV['TM_LINE_NUMBER']

        run(options)
      end

      def run(options)
        if options.delete(:run_again)
          argv = load_argv_from_last_run
        else
          argv = build_argv_from_options(options)
          save_as_last_run(argv)
        end
        run_rspec(argv)
      end

      def run_rspec(argv)
        stderr     = StringIO.new
        old_stderr = $stderr
        $stderr    = stderr

        Thread.abort_on_exception = true
        Dir.chdir(project_directory) do
          cmd = Executable.find("rspec") + argv
          Open3.popen3(*cmd) do |i, out, err, _thread|
            i.close
            stderr_thread = Thread.new do
              while (line = err.gets)
                stderr.puts line
              end
            end
            while (line = out.gets)
              $stdout.puts line
              $stdout.flush
            end
            stderr_thread.join
          end
        end
      ensure
        unless stderr.string == ""
          $stdout <<
            "<pre class='stderr'>" <<
            CGI.escapeHTML(stderr.string) <<
            "</pre>"
        end

        $stderr = old_stderr
      end

      def save_as_last_remembered_file(file)
        File.open(LAST_REMEMBERED_FILE_CACHE, "w") do |f|
          f << file
        end
      end

    private

      def build_argv_from_options(options)
        default_formatter = 'RSpec::Mate::Formatters::TextMateFormatter'
        formatter = ENV['TM_RSPEC_FORMATTER'] || default_formatter

        # If :line is given, only the first file from :files is used. This should be ok though, because
        # :line is only ever set in #run_focussed, and there :files is always set to a single file only.
        argv = options[:line] ? ["#{options[:files].first}:#{options[:line]}"] : options[:files].dup

        argv << '--format' << formatter
        argv << '-r' << File.join(File.dirname(__FILE__), 'text_mate_formatter') if formatter == 'RSpec::Mate::Formatters::TextMateFormatter'
        argv << '-r' << File.join(File.dirname(__FILE__), 'filter_bundle_backtrace')

        argv += ENV['TM_RSPEC_OPTS'].split(" ") if ENV['TM_RSPEC_OPTS']

        argv
      end

      def last_remembered_single_file
        file = File.read(LAST_REMEMBERED_FILE_CACHE).strip

        File.expand_path(file) unless file.empty?
      end

      def save_as_last_run(args)
        File.open(LAST_RUN_CACHE, "w") do |f|
          f.write YAML.dump(args)
        end
      end

      def load_argv_from_last_run
        YAML.load_file(LAST_RUN_CACHE)
      end

      def project_directory
        File.expand_path(base_dir)
      rescue
        File.dirname(single_file)
      end

      def single_file
        File.expand_path(ENV['TM_FILEPATH'])
      end
    end
  end
end
