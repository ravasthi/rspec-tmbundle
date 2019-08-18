module RSpec
  module Mate
    module Helpers
      def base_dir
        ENV['TM_RSPEC_BASEDIR'] || ENV['TM_PROJECT_DIRECTORY'] || File.dirname(ENV['TM_FILEPATH'])
      end
    end
  end
end
