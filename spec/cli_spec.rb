require 'spec_helper'
require 'octoherder'
require 'rspec'

module OctoHerder
  describe CLI do
    context "bin/octoherder" do
      let(:conf) { Configuration.read_file 'spec/data/sample.yml' }
      let (:kitty) { mock :octokit_client }
      let (:usage) {<<-USAGE
OctoHerder helps you manage your multi-repository project.

Usage:
    
    octoherder [options]
where [options] are:
   --input-file, -f:   Path to the canonical project setup
         --repo, -r:   Name of the master repository
  --output-file, -o:   Path to the file that will contain the canonical project
                       setup
      --version, -v:   Print version and exit
         --help, -h:   Show this message
USAGE
      }

      context "with no arguments" do
        it "should display usage" do
          output = `bin/octoherder`
          expect(output).to eq(usage)
        end
      end

      context "with --help" do
        it "should display usage" do
          output = `bin/octoherder --help`
          expect(output).to eq(usage)
        end
      end

      context "with -f" do
        it "should connect to GitHub" do
          kitty.stub(:connection)
          kitty.should_receive(:connection)

          CLI.run(["-f", "spec/data/sample.yml"], kitty)
        end
      end
    end
  end
end
