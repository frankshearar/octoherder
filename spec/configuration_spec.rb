require 'spec_helper'
require 'rspec'
require 'octoherder/configuration'
require 'data/sample-github-responses'

module OctoHerder
  describe Configuration do
    let (:conf_file) { (Pathname.new(__FILE__).parent + "data/sample.yml").to_s }

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
      let (:connection) { mock :octokit }
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
  end
end
