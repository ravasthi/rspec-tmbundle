require 'stringio'

module RSpec
  module Mate
    class Runner
      def run_files(stdout, options={})
        files = ENV['TM_SELECTED_FILES'].scan(/'(.*?)'/).flatten.map do |path|
          File.expand_path(path)
        end
        options.merge!({:files => files})
        run(stdout, options)
      end

      def run_file(stdout, options={})
        options.merge!({:files => [single_file]})
        run(stdout, options)
      end
      
      def run_last_remembered_file(stdout, options={})
        options.merge!({:files => [last_remembered_single_file]})
        run(stdout, options)
      end

      def run_focussed(stdout, options={})
        options.merge!({:files => [single_file], :line => ENV['TM_LINE_NUMBER']})
        run(stdout, options)
      end

      def run(stdout, options)
        formatter = ENV['TM_RSPEC_FORMATTER'] || 'textmate'
        stderr = StringIO.new
        old_stderr = $stderr
        $stderr = stderr
        argv = options[:files].dup
        argv << '--format' << formatter
        if options[:line]
          argv << '--line'
          argv << options[:line]
        end
        argv += ENV['TM_RSPEC_OPTS'].split(" ") if ENV['TM_RSPEC_OPTS']
        Dir.chdir(project_directory) do
          if rspec2?
            ::RSpec::Core::Runner.disable_autorun!
            ::RSpec::Core::Runner.run(argv, stderr, stdout)
          else
            ::Spec::Runner::CommandLine.run(::Spec::Runner::OptionParser.parse(argv, stderr, stdout))
          end
        end
      rescue Exception => e
        require 'pp'
        stdout << "<h1>Uncaught Exception</h1>" <<
        "<p>#{e.class}: #{e.message}</p>" <<
        "<pre>#{e.backtrace.join("\n  ")}</pre>" <<
        "<h2>Options:</h2>" <<
        "<pre>#{PP.pp(options, '')}</pre>"
      ensure
        unless stderr.string == ""
          stdout << "<h2>stderr:</h2>" << 
           "<pre>" << stderr.string << "</pre>"
        end
        $stderr = old_stderr
      end

      def save_as_last_remembered_file(file)
        File.open(last_remembered_file_cache, "w") do |f|
          f << file
        end
      end

      def last_remembered_file_cache
        "/tmp/textmate_rspec_last_remembered_file_cache.txt"
      end
      
    protected

      def single_file
        File.expand_path(ENV['TM_FILEPATH'])
      end

      def last_remembered_single_file
        file = File.read(last_remembered_file_cache).strip
        File.expand_path(file) if file.size > 0
      end
      
      def project_directory
        File.expand_path(ENV['TM_PROJECT_DIRECTORY']) rescue File.dirname(single_file)
      end
    end
  end
end
