require 'spec_helper'
require 'octoherder/configuration'
require 'hashie'

module OctoHerder
  describe Configuration do
    let (:conf_file) { (Pathname.new(__FILE__).parent + "data/sample.yml").to_s }
    let (:connection) { double :octokit }

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
      let (:labels) { source.fetch('labels').map(&:to_s) }
      let (:columns) { source.fetch('columns') }
      let (:linked_repos) { source.fetch('repositories') }
      let (:milestones) { source.fetch('milestones') }
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

      it "should treat all labels as Strings" do
        expect(conf.labels).to eq(conf.labels.map(&:to_s))
      end


      it "should ask all repositories for their milestones" do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY,
                                                     [],
                                                     [])
        connection.stub(:create_milestone)
        connection.should_receive(:list_milestones).exactly(repo_count * ['open', 'closed'].size).times
        conf.update_milestones connection
      end

      it "should add any missing huboard repository links" do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:create_milestone)

        connection.stub(:labels) { |repo|
          repo_name = "#{repo.username}/#{repo.name}"
          if repo_name == master then
            [{name: "Link <=> " + conf.repositories.first}].map {|h| Hashie::Mash.new h}
          else
            []
          end
        }

        connection.stub(:add_label)
        # This happens to also check that we don't add any link labels to the
        # linked repositories.
        connection.should_receive(:add_label).exactly(conf.repositories.size - 1).times

        conf.update_link_labels connection
      end

      it "should add all missing milestones to all repositories" do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:create_milestone)

        connection.should_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-1', {'state' => 'closed'}).exactly(repo_count).times
        connection.should_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-2', {'due_on' => Time.iso8601('2011-04-10T20:09:31Z')}).exactly(repo_count).times
        connection.should_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-3', {'state' => 'open', 'description' => 'The third step in total world domination.'}).exactly(repo_count).times

        conf.update_milestones connection
      end

      it "should not try add a closed milestone" do
        connection.stub(:list_milestones).with(an_instance_of(Octokit::Repository), {state: 'open'}).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:list_milestones).with(an_instance_of(Octokit::Repository), {state: 'closed'}).and_return(LIST_CLOSED_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:create_milestone)

        connection.should_not_receive(:create_milestone).with(an_instance_of(Octokit::Repository), 'milestone-1', {'due_on' => Time.iso8601('2011-04-10T20:09:31Z')})

        conf.update_milestones connection
      end

      it "should update existing milestones" do
        connection.stub(:list_milestones).and_return([{'number' => 1, 'title' => 'milestone-1'},
                                                      {'number' => 2, 'title' => 'milestone-2'},
                                                      {'number' => 3, 'title' => 'milestone-3'}])
        connection.stub(:update_milestone)

        connection.should_receive(:update_milestone).with(an_instance_of(Octokit::Repository), 1, {'state' => 'closed'}).exactly(repo_count).times
        connection.should_receive(:update_milestone).with(an_instance_of(Octokit::Repository), 2, {'due_on' => Time.iso8601('2011-04-10T20:09:31Z')}).exactly(repo_count).times
        connection.should_receive(:update_milestone).with(an_instance_of(Octokit::Repository), 3, {'state' => 'open', 'description' => 'The third step in total world domination.'}).exactly(repo_count).times

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
         }].map { |h| Hashie::Mash.new h }
      }

      before :each do
        connection.stub(:list_milestones).and_return(LIST_MILESTONES_FOR_A_REPOSITORY)
        connection.stub(:labels).and_return(labels)
      end

      it "can be done" do
        connection.should_receive(:labels).ordered
        connection.should_receive(:list_milestones).ordered

        c = Configuration.generate_configuration connection, "me/mine"
        expect(c.labels).to eq(['0.5', 'critical'])
        expect(c.repositories).to eq(['me/other'])
        expect(c.columns).to eq(['0 - Backlog'])
      end

      it "should collect existing milestone information" do
        c = Configuration.generate_configuration connection, "me/mine"
        expect(c.milestones.length).to equal 1
        m = c.milestones.first
        expect(m).to eq({
          "state" => "open",
          "title" => "v1.0",
          "description" => "",
          "due_on" => nil})
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

    context "when updating master repository" do
      let (:master) { "my/master" }
      let (:repositories) { ["my/slave"] }
      let (:slave) { repositories.first }
      let (:milestones) { [] }
      let (:columns) { ["0 - Backlog"] }
      let (:labels) { ["existing-red-label", "new-blue-label"] }
      let (:conf) {
        Configuration.new master, repositories, milestones, columns, labels
      }

      before :each do
        connection.stub(:add_label)
        connection.stub(:update_label)
        connection.stub(:labels).and_return([])

      end

      it "should add missing columns" do
        connection.should_receive(:add_label).with(an_instance_of(Octokit::Repository), "0 - Backlog", {color: "cccccc"})

        conf.update_labels connection
      end
    end

    context "when updating linked repositories" do
      let (:master) { "my/master" }
      let (:repositories) { ["my/slave"] }
      let (:slave) { repositories.first }
      let (:milestones) { [] }
      let (:columns) { [] }
      let (:labels) { ["existing-red-label", "new-blue-label"] }
      let (:conf) {
        Configuration.new master, repositories, milestones, columns, labels
      }

      before :each do
       connection.stub(:add_label)
        connection.stub(:update_label)
        connection.stub(:labels) { |repo|
          repo_name = "#{repo.username}/#{repo.name}"
          case repo_name
          when master then master_labels
          when slave then slave_labels
          else fail("Unknown repository #{repo_name}")
          end
        }
      end

      context "with existing labels" do
        let (:master_labels) {
          [{
             "url" => "https =>//api.github.com/repos/me/mine/labels/existing-red-label",
             "name" => "existing-red-label",
             "color" => "ff0000"
           }].map { |h| Hashie::Mash.new h }
        }

        let (:slave_labels) {
          [{
             "url" => "https =>//api.github.com/repos/me/mine/labels/existing-red-label",
             "name" => "existing-red-label",
             "color" => "cccccc"
           }].map { |h| Hashie::Mash.new h }
        }

        it "should update labels in a linked repo" do
          connection.should_receive(:update_label).with(an_instance_of(Octokit::Repository), master_labels.first.name, {color: 'ff0000'})

          conf.update_labels connection
        end
      end

      context "with missing labels" do
        let (:columns) { ["0 - Backlog"] }
        let (:master_labels) {
          [{
             "url" => "https =>//api.github.com/repos/me/mine/labels/new-blue-label",
             "name" => "new-blue-label",
             "color" => "0000ff"
           },
           { # Huboard column tags
             "url" => "https =>//api.github.com/repos/me/mine/labels/0 - Backlog",
             "name" => "0 - Backlog",
             "color" => "cccccc"
           }].map { |h| Hashie::Mash.new h }
        }

        let (:slave_labels) { [] }

        it "should add labels to a linked repo with matching colour" do
          connection.should_receive(:add_label).with(an_instance_of(Octokit::Repository), "new-blue-label", {color: "0000ff"})
          connection.should_receive(:add_label).with(an_instance_of(Octokit::Repository), "0 - Backlog", {color: "cccccc"})

          conf.update_labels connection
        end
      end
    end
  end
end
