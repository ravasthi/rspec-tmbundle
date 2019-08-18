# This is based on Florian Weber's TDDMate

ENV['TM_PROJECT_DIRECTORY'] ||= File.dirname(ENV['TM_FILEPATH'])

require_relative 'mate/runner'
require_relative 'mate/switch_command'
