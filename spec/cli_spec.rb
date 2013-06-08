require 'spec_helper'
require 'octoherder'
require 'rspec'

module OctoHerder
  describe CLI do
    context "bin/octoherder" do
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
    end
  end
end
