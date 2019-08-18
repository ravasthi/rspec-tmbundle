require 'spec_helper'

module RSpec
  module Mate
    describe SwitchCommand do
      class << self
        def expect_twins(pair)
          specify do
            allow(File).to receive(:exist?).and_return(false)
            command = SwitchCommand.new
            expect(command.twin(pair.first)).to eq pair.last
            expect(command.twin(pair.last)).to eq pair.first
          end
        end

        def expect_webapp_twins(pair)
          specify do
            allow(File).to receive(:exist?).and_return(true)
            command = SwitchCommand.new
            expect(command.twin(pair.first)).to eq pair.last
            expect(command.twin(pair.last)).to eq pair.first
          end
        end
      end

      RSpec::Matchers.define :twin do |*args|
      end

      RSpec::Matchers.define :be_a do |expected|
        match do |actual|
          SwitchCommand.new.file_type(actual) == expected
        end
      end

      subject(:command) { described_class.new }

      describe "in a regular app" do
        expect_twins [
          "/Users/aslakhellesoy/scm/rspec/trunk/RSpec.tmbundle/Support/spec/rspec/mate/switch_command_spec.rb",
          "/Users/aslakhellesoy/scm/rspec/trunk/RSpec.tmbundle/Support/lib/rspec/mate/switch_command.rb"
        ]

        it "suggest a plain spec" do
          expect("/a/full/path/spec/snoopy/mooky_spec.rb").to be_a("spec")
        end

        it "suggests a plain file" do
          expect("/a/full/path/lib/snoopy/mooky.rb").to be_a("file")
        end
      end

      describe "in a Rails or Merb app" do
        expect_webapp_twins [
          "/a/full/path/app/controllers/mooky_controller.rb",
          "/a/full/path/spec/controllers/mooky_controller_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/controllers/application_controller.rb",
          "/a/full/path/spec/controllers/application_controller_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/controllers/job_applications_controller.rb",
          "/a/full/path/spec/controllers/job_applications_controller_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/helpers/application_helper.rb",
          "/a/full/path/spec/helpers/application_helper_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/models/mooky.rb",
          "/a/full/path/spec/models/mooky_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/helpers/mooky_helper.rb",
          "/a/full/path/spec/helpers/mooky_helper_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/views/mooky/show.html.erb",
          "/a/full/path/spec/views/mooky/show.html.erb_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/views/mooky/show.html.haml",
          "/a/full/path/spec/views/mooky/show.html.haml_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/views/mooky/show.html.slim",
          "/a/full/path/spec/views/mooky/show.html.slim_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/views/mooky/show.rhtml",
          "/a/full/path/spec/views/mooky/show.rhtml_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/views/mooky/show.js.rjs",
          "/a/full/path/spec/views/mooky/show.js.rjs_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/views/mooky/show.rjs",
          "/a/full/path/spec/views/mooky/show.rjs_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/lib/foo/mooky.rb",
          "/a/full/path/spec/lib/foo/mooky_spec.rb"
        ]

        expect_webapp_twins [
          "/a/full/path/app/lib/foo/mooky.rb",
          "/a/full/path/spec/app/lib/foo/mooky_spec.rb"
        ]

        it "suggests a controller spec" do
          expect("/a/full/path/spec/controllers/mooky_controller_spec.rb").to be_a("controller spec")
        end

        it "suggests a model spec" do
          expect("/a/full/path/spec/models/mooky_spec.rb").to be_a("model spec")
        end

        it "suggests a helper spec" do
          expect("/a/full/path/spec/helpers/mooky_helper_spec.rb").to be_a("helper spec")
        end

        it "suggests a view spec for erb" do
          expect("/a/full/path/spec/views/mooky/show.html.erb_spec.rb").to be_a("view spec")
        end

        it "suggests a view spec for haml" do
          expect("/a/full/path/spec/views/mooky/show.html.haml_spec.rb").to be_a("view spec")
        end

        it "suggests a view spec for slim" do
          expect("/a/full/path/spec/views/mooky/show.html.slim_spec.rb").to be_a("view spec")
        end

        it "suggests an rjs view spec" do
          expect("/a/full/path/spec/views/mooky/show.js.rjs_spec.rb").to be_a("view spec")
        end

        it "suggests a controller" do
          expect("/a/full/path/app/controllers/mooky_controller.rb").to be_a("controller")
        end

        it "suggests a model" do
          expect("/a/full/path/app/models/mooky.rb").to be_a("model")
        end

        it "suggests a helper" do
          expect("/a/full/path/app/helpers/mooky_helper.rb").to be_a("helper")
        end

        it "suggests a view" do
          expect("/a/full/path/app/views/mooky/show.html.erb").to be_a("view")
        end

        it "suggests an rjs view" do
          expect("/a/full/path/app/views/mooky/show.js.rjs").to be_a("view")
        end
      end

      describe '#described_class_for' do
        base = '/Users/foo/Code/bar'
        {
          # normal project
          '/Users/foo/Code/bar/lib/some_name.rb' => 'SomeName',
          '/Users/foo/Code/bar/lib/some/long_file_name.rb' => 'Some::LongFileName',
          '/Users/foo/Code/bar/lib/my/own/file.rb' => 'My::Own::File',

          '/Users/foo/Code/spec/some_name.rb' => 'SomeName',
          '/Users/foo/Code/spec/some/long_file_name.rb' => 'Some::LongFileName',
          '/Users/foo/Code/spec/my/own/file.rb' => 'My::Own::File',

          # rails
          '/Users/foo/Code/bar/app/controllers/file_controller.rb' => 'FileController',
          '/Users/foo/Code/bar/app/models/my/own/file.rb' => 'My::Own::File',
          '/Users/foo/Code/bar/app/other/my/own/file.rb' => 'My::Own::File',

          '/Users/foo/Code/bar/spec/controllers/file_controller.rb' => 'FileController',
          '/Users/foo/Code/bar/spec/models/my/own/file.rb' => 'My::Own::File',

          # This should probably detect it's a rails app from the presence
          # of an app/other folder in order to work.
          #
          # '/Users/foo/Code/bar/spec/other/my/own/file.rb' => 'My::Own::File',
        }.each_pair do |path, class_name|
          it "extracts the full class name from the path (#{class_name})" do
            expect(command.described_class_for(path, base)).to eq(class_name)
          end
        end
      end
    end
  end
end
