require 'spec_helper'
require 'rspec/mate/gutter_marks'

describe RSpec::Mate::GutterMarks do
  let(:example_group) { RSpec.describe("example group") }

  def example_with_location(path, line, &block)
    example_group.example('example', &block).tap do |ex|
      allow(ex).to receive(:file_path).and_return path
      allow(ex).to receive(:location).and_return "#{path}:#{line}"
    end
  end

  it 'runs `mate` with the appropriate arguments', :sandboxed do
    example_with_location('./foo/successes.rb', 5) {}
    example_with_location('./foo/failures.rb', 12) { raise "a failed example" }
    example_with_location('./foo/failures.rb', 24) { raise "another failure" }
    example_group.run
    gm = described_class.new(example_group.examples)
    expect(gm).to receive(:run_mate).with("--clear-mark=warning", "./foo/successes.rb")
    expect(gm).to receive(:run_mate).with("--clear-mark=warning", "./foo/failures.rb")
    expect(gm).to receive(:run_mate).with("--set-mark=warning:a failed example", "--line=12", "./foo/failures.rb")
    expect(gm).to receive(:run_mate).with("--set-mark=warning:another failure", "--line=24", "./foo/failures.rb")
    gm.set_marks
  end
end
