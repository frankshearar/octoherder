require 'octoherder'
require 'trollop'


module OctoHerder
  class CLI
    def self.run(args, octokit_client)
      p = Trollop::Parser.new do
        version OctoHerder::VERSION
        banner <<-HELP
OctoHerder helps you manage your multi-repository project.

Usage:
    
    octoherder [options]
where [options] are:
HELP
        opt :'input-file', 'Path to the canonical project setup', :short => 'f'
        opt :repo, 'Name of the master repository', :short => 'r'
        opt :'output-file', 'Path to the file that will contain the canonical project setup', :short => 'o'
      end

      opts = Trollop::with_standard_exception_handling p do
        p.parse args
        raise Trollop::HelpNeeded if args.empty? # Show help screen
      end
    end
  end
end
