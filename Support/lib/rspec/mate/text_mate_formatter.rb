require 'cgi'
require 'rspec/core/formatters/base_text_formatter'
require_relative 'text_mate_backtrace_printer'
require_relative 'snippet_extractor'
require_relative 'gutter_marks'

# This formatter is only used for RSpec 3 (older RSpec versions ship their own TextMateFormatter).
# Based on https://github.com/rspec/rspec-core/blob/2cc12cefece83918b2e0737f43a72be52f195a16/lib/rspec/core/formatters/html_formatter.rb
# See https://github.com/rspec/rspec-core/commit/74a286d1fe44fe6a3a6a248ee2e92718b7353e71#commitcomment-12159927 ff.
module RSpec
  module Mate
    module Formatters
      class TextMateFormatter < ::RSpec::Core::Formatters::BaseFormatter
        ::RSpec::Core::Formatters.register self, :message, :seed, :start, :example_group_started, :start_dump,
                                           :example_started, :example_passed, :example_failed,
                                           :example_pending, :dump_summary

        def initialize(output)
          super(output)
          @failed_examples = []
          @example_group_number = 0
          @example_number = 0
          @header_red = nil
          @printer = TextMateBacktracePrinter.new(output)
          @printer.print_html_start
          @printer.flush
        end

        def message(notification)
          @printer.message notification.message
        end

        def seed(notification)
          return unless notification.seed_used?
          @printer.message notification.fully_formatted
        end

        def start(notification)
          super
          @printer.flush
        end

        def example_group_started(notification)
          super
          @example_group_red = false
          @example_group_number += 1

          @printer.print_example_group_end unless example_group_number == 1
          @printer.print_example_group_start(example_group_number, notification.group.description, notification.group.parent_groups.size)
          @printer.flush
        end

        def start_dump(_notification)
          @printer.print_example_group_end
          @printer.flush
        end

        def example_started(_notification)
          @example_number += 1
        end

        def example_passed(passed)
          @printer.move_progress(percent_done)
          @printer.print_example_passed(passed.example.description, passed.example.execution_result.run_time)
          @printer.flush
        end

        def example_failed(failure)
          @failed_examples << failure.example
          unless @header_red
            @header_red = true
            @printer.make_header_red
          end

          unless @example_group_red
            @example_group_red = true
            @printer.make_example_group_header_red(example_group_number)
          end

          @printer.move_progress(percent_done)

          example = failure.example

          exception = failure.exception
          exception_details = if exception
                                {
                                  :message => exception.message,
                                  :backtrace => failure.formatted_backtrace.join("\n")
                                }
                              else
                                false
                              end
          extra = extra_failure_content(failure)

          @printer.print_example_failed(
            example.execution_result.pending_fixed,
            example.description,
            example.execution_result.run_time,
            @failed_examples.size,
            exception_details,
            extra == "" ? false : extra,
            true
          )
          @printer.flush
        end

        def example_pending(pending)
          example = pending.example

          @printer.make_header_yellow unless @header_red
          @printer.make_example_group_header_yellow(example_group_number) unless @example_group_red
          @printer.move_progress(percent_done)
          @printer.print_example_pending(example.description, example.execution_result.pending_message)
          @printer.flush
        end

        def dump_summary(summary)
          @printer.print_summary(
            summary.duration,
            summary.example_count,
            summary.failure_count,
            summary.pending_count
          )
          @printer.flush
          RSpec::Mate::GutterMarks.new(summary.examples).set_marks
        end

      private

        # If these methods are declared with attr_reader Ruby will issue a warning because they are private
        # rubocop:disable Style/TrivialAccessors

        # The number of the currently running example_group
        def example_group_number
          @example_group_number
        end

        # The number of the currently running example (a global counter)
        def example_number
          @example_number
        end
        # rubocop:enable Style/TrivialAccessors

        def percent_done
          result = 100.0
          if @example_count > 0
            result = ((example_number.to_f / @example_count.to_f * 1000).to_i / 10.0).to_f
          end
          result
        end

        # Override this method if you wish to output extra HTML for a failed spec. For example, you
        # could output links to images or other files produced during the specs.
        #
        def extra_failure_content(failure)
          backtrace = (failure.exception.backtrace || []).map do |line|
            RSpec.configuration.backtrace_formatter.backtrace_line(line)
          end
          backtrace.compact!
          @snippet_extractor ||= SnippetExtractor.new
          "    <pre class=\"ruby\"><code>#{@snippet_extractor.snippet(backtrace)}</code></pre>"
        end
      end
    end
  end
end
