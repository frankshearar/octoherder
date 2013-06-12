require 'spec_helper'
require 'octoherder'
require 'rspec'
require 'tempfile'
require 'data/sample-github-responses'

module OctoHerder
  describe CLI do
    def run(args, octokit_connection)
      CLI.new.run(octokit_connection, CLI.parse_argv(args))
    end

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
            --output-file, -o <s>:   Path to the file that will contain the
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
          kitty.stub(:labels)
          kitty.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
          kitty.stub(:create_milestone)
        end

        after :each do
          run(["--input-file", "spec/data/sample.yml"], kitty)
        end

        it "should read in the input file" do
          # We could only ask for the master repository's milestones if we
          # correctly read the sample config file.
          kitty.should_receive(:list_milestones).with(an_instance_of(Octokit::Repository))
        end
      end

      context "with --output-file" do
        before :each do
          kitty.stub(:labels).and_return([])
          kitty.stub(:list_milestones).and_return([])
        end

        it "requires --repo" do
          ->{
            run(["--output-file", "spec/data/sample.yml"], kitty)
          }.should raise_error(SystemExit)
        end

        it "writes to the given file" do
          temp = Tempfile.new('foo')
          begin
            run(["--output-file", temp.path, "--repo", "me/my-repo"], kitty)
            temp.rewind
            expect(temp.read).to_not be_empty
          ensure
            temp.close
            temp.unlink
          end
        end
      end

      context "with --repo" do
        it "requires --output-file" do
          ->{
            run(["--repo", "foo/bar"], kitty)
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
          pending "I don't know how to test this, because we push the login info into octokit at object instantiation time."
          kitty.should_receive(:login).with(user)
          run(["--user", "me"], kitty)
        end

        it "passes the password to Octokit" do
          pending "I don't know how to test this, because we push the login info into octokit at object instantiation time."
          kitty.stub(:password)
          kitty.should_receive(:password).with(password)
          run(["--user", "me", "--password", password], kitty)
        end
      end
    end

    context "Octokit integration" do
      it "should be able to run to completion" do
        expect {
          c = CLI.run ["--repo", "frankshearar/octoherder"]
        }.to raise_error(SystemExit)
      end

      it "should translate command line arguments into Octokit authorization credentials" do
        input = {user: 'me', password: 'password', user_given: true, password_given: true}
        output = CLI.octoauth input
        expect(output).to eq({login: 'me', password: 'password'})
      end

      it "should pass through the OAuth token"
    end
  end
end
