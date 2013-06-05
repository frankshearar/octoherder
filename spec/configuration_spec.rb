require_relative 'spec_helper.rb'
require 'rspec'
require 'octoherder/configuration'

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

      it "can read in the master repo name" do
        expect(conf.master).to eq(source['master'])
      end

      it "can read in the columns" do
        expect(conf.columns.count).to equal(source['columns'].count)
      end

      it "can read in the subsidiary repositories" do
        expect(conf.repositories.count).to equal(source['repositories'].count)
      end

      it "can read in the milestones" do
        expect(conf.milestones.count).to equal(source['milestones'].count)
      end
    end
  end
end
