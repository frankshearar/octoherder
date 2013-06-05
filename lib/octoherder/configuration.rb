require 'hamsterdam'
require 'yaml'

module OctoHerder
  Configuration = Hamsterdam::Struct.define(:milestones)
  class Configuration
    def self.read file
      Configuration.new
    end
  end
end
