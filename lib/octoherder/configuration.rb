require 'hamsterdam'
require 'yaml'

module OctoHerder
  Configuration = Hamsterdam::Struct.define(:master, :repositories, :milestones, :columns)
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

      master = data.fetch('master')
      columns = data.fetch('columns', [])
      milestones = data.fetch('milestones', [])
      repositories = data.fetch('repositories', [])
      Configuration.new master: master, repositories: repositories, milestones: milestones, columns: columns
    end
  end
end
