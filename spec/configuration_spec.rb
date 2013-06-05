require_relative 'spec_helper.rb'
require 'rspec'
require 'octoherder/configuration'

module OctoHerder
  describe Configuration do
    it "should be instantiable" do
      Configuration.new
    end

    it "can read in a configuration file" do
      Configuration.read "data/sample.yml"
    end

    context "with sample.yml" do
      let(:conf) { Configuration.read "data/sample.yml" }
      let(:source) { YAML.read_file "data/sample.yml" }
      it "can read in the milestones" do
        expect(conf.milestones.count).to equal(source['milestones'].count)
      end
    end
  end
end
