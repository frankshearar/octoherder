require 'spec_helper'
require 'octoherder'
require 'rspec'
require 'data/sample-github-responses'

module OctoHerder
  describe CLI do
    context "bin/octoherder" do
      let(:conf) { Configuration.read_file 'spec/data/sample.yml' }
      let (:kitty) { mock :octokit_client }
      let (:version) { "octoherder #{OctoHerder::VERSION}\n" }
      let (:usage) {<<-USAGE
OctoHerder helps you manage your multi-repository project.

Usage:
    
    octoherder [options]
where [options] are:
   --input-file, -i <filename/uri>:   Path to the canonical project setup
                    --repo, -r <s>:   Name of the master repository
  --output-file, -o <filename/uri>:   Path to the file that will contain the
                                      canonical project setup
                    --user, -u <s>:   User as whom to authenticate
                --password, -p <s>:   Users password
             --oauth-token, -t <s>:   OAuth token
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

      context "with --version" do
        it "should display the version string" do
          output = `bin/octoherder --version`
          expect(output).to eq(version)
        end
      end

      context "with --input-file" do
        before :each do
          kitty.stub(:connection)
          kitty.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
          kitty.stub(:create_milestone)
        end

        after :each do
          CLI.run(["--input-file", "spec/data/sample.yml"], kitty)
        end

        it "should read in the input file" do
          # We could only ask for the master repository's milestones if we
          # correctly read the sample config file.
          kitty.should_receive(:list_milestones).with(an_instance_of(Octokit::Repository))
        end
      end

      context "with --output-file" do
        it "requires --repo" do
          ->{
            CLI.run(["--output-file", "spec/data/sample.yml"], kitty)
          }.should raise_error(SystemExit)
        end
      end

      context "with --repo" do
        it "requires --output-file" do
          ->{
            CLI.run(["--repo", "foo/bar"], kitty)
          }.should raise_error(SystemExit)
        end
      end

      context "with --user" do
        let (:user) { 'me' }
        let (:password) { 'sekrit' }
        before :each do
          kitty.stub(:login)
        end

        it "passes the user to Octokit" do
          kitty.should_receive(:login).with(user)
          CLI.run(["--user", "me"], kitty)
        end

        it "passes the password to Octokit" do
          kitty.stub(:password)
          kitty.should_receive(:password).with(password)
          CLI.run(["--user", "me", "--password", password], kitty)
        end
      end
    end
  end
end
