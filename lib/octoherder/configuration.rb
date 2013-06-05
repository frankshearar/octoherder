require 'hamsterdam'
require 'yaml'

module OctoHerder
  Configuration = Hamsterdam::Struct.define(:milestones)
  class Configuration
    def self.read_file path
      File.open(path.to_s, "r") { |f| self.read_string f.read }
    end

    def self.read_string source
      data = if source.empty? then
               {}
             else
               y = YAML.load(source)
             end

      milestones = data.fetch('milestones', [])
      Configuration.new milestones: milestones
    end
  end
end
