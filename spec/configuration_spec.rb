require 'spec_helper'
require 'rspec'
require 'octoherder/configuration'
require 'data/sample-github-responses'

module OctoHerder
  describe Configuration do
    let (:conf_file) { (Pathname.new(__FILE__).parent + "data/sample.yml").to_s }
    let (:connection) { mock :octokit }

    it "should be instantiable" do
      Configuration.new
    end

    it "can read in a configuration file" do
      Configuration.read_file conf_file
    end

    it "can read in a string" do
      Configuration.read_string File.open(conf_file, "r") { |f| f.read }
    end

    it "should reject empty input because there's no master defined" do
      expect {
        Configuration.read_string ""
      }.to raise_error(KeyError) { |e|
        expect(e.message).to include("master")
      }
    end

    context "with sample.yml" do
      let(:conf) { Configuration.read_file conf_file }
      let(:source) { YAML.load_file conf_file }
      let (:master) { source.fetch('master') }
      let (:labels) { source.fetch('labels', []) }
      let (:linked_repos) { source.fetch('repositories', []) }
      let (:milestones) { source.fetch('milestones', []) }
      let (:repo_count) { ([master] + linked_repos).length }

      it "can read in the master repo name" do
        expect(conf.master).to eq(source['master'])
      end

      it "can read in the columns" do
        expect(conf.columns.count).to equal(source['columns'].count)
      end

      it "can read in the labels" do
        expect(conf.labels.count).to equal(source['labels'].count)
      end

      it "can read in the subsidiary repositories" do
        expect(conf.repositories.count).to equal(source['repositories'].count)
      end

      it "can read in the milestones" do
        expect(conf.milestones.count).to equal(source['milestones'].count)
      end

      it "should add labels to repositories that lack some" do
        connection.stub(:labels).and_return([], [], [])
        connection.stub(:add_label)
        connection.should_receive(:labels).exactly(repo_count).times
        labels.each { |label|
          connection.should_receive(:add_label).with(an_instance_of(Octokit::Repository), label, OctoHerder::NEUTRAL_TONE)
        }

        conf.update_labels connection
      end

      it "should ask all repositories for their milestones" do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY,
                                                     [],
                                                     [])
        connection.stub(:create_milestone)
        connection.should_receive(:list_milestones).exactly(repo_count).times
        conf.update_milestones connection
      end

      it "should add all missing milestones to all repositories" do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:create_milestone)

          connection.should_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-1', {'state' => 'closed'}).exactly(repo_count).times
          connection.should_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-2', {'due_on' => '2011-04-10T20:09:31Z'}).exactly(repo_count).times
          connection.should_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-3', {'state' => 'open', 'description' => 'The third step in total world domination.'}).exactly(repo_count).times

        conf.update_milestones connection
      end

      it "should update existing milestones" do
        connection.stub(:list_milestones).and_return([{'title' => 'milestone-1'},
                                                      {'title' => 'milestone-2'},
                                                      {'title' => 'milestone-3'}])
        connection.stub(:update_milestone)
        connection.should_receive(:update_milestone).with(an_instance_of(Octokit::Repository), 'milestone-1', {'state' => 'closed'}).exactly(repo_count).times
        connection.should_receive(:update_milestone).with(an_instance_of(Octokit::Repository), 'milestone-2', {'due_on' => '2011-04-10T20:09:31Z'}).exactly(repo_count).times
        connection.should_receive(:update_milestone).with(an_instance_of(Octokit::Repository), 'milestone-3', {'state' => 'open', 'description' => 'The third step in total world domination.'}).exactly(repo_count).times

        conf.update_milestones connection
      end
    end

    context "generating a brand new configuration" do
      let (:labels) {
        [{ # Huboard link tags
           "url" => "https =>//api.github.com/repos/me/mine/labels/Link <=> me/other", # This needs escaping, but the tests don't care
           "name" => "Link <=> me/other",
           "color" => "f29513"
         },
         { # Cost tags
           "url" => "https =>//api.github.com/repos/me/mine/labels/0.5",
           "name" => "0.5",
           "color" => "cccccc"
         },

         { # Huboard column tags
           "url" => "https =>//api.github.com/repos/me/mine/labels/0 - Backlog",
           "name" => "0 - Backlog",
           "color" => "cccccc"
         },
         { # Random other tags
           "url" => "https =>//api.github.com/repos/me/mine/labels/critical",
           "name" => "critical",
           "color" => "ff0000"
         }]
      }

      it "can be done" do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:labels).and_return(labels)
        connection.should_receive(:list_milestones)
        connection.should_receive(:labels)
        c = Configuration.generate_configuration connection, "me/mine"
        expect(c.labels).to eq(['0.5', 'critical'])
        expect(c.repositories).to eq(['me/other'])
        expect(c.columns).to eq(['0 - Backlog'])
      end

      it "can write to a file" do
        target_file = "can-configuration-write-to-a-file"

        conf = Configuration.read_file conf_file
        conf.write_file(target_file)
        begin
          new_conf = Configuration.read_file target_file
          expect(new_conf).to eq(conf)
        ensure
          FileUtils.rm(target_file) if File.exist?(target_file)
        end
      end
    end
  end
end
