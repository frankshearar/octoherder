require 'octoherder'
require 'trollop'


module OctoHerder
  class CLI
    def self.run(args, octokit_client)
      p = Trollop::Parser.new do
        version 'octoherder ' + OctoHerder::VERSION
        banner <<-HELP
OctoHerder helps you manage your multi-repository project.

Usage:
    
    octoherder [options]
where [options] are:
HELP
        opt :input_file, 'Path to the canonical project setup', short: 'i', type: :io, default: nil
        opt :repo, 'Name of the master repository', short: 'r', type: :string, default: nil
        opt :output_file, 'Path to the file that will contain the canonical project setup', short: 'o', type: :io
        opt :version, "Print version and exit", short: 'v'
        opt :help, "Show this message", short: 'h'

        depends :output_file, :repo
      end

      opts = Trollop::with_standard_exception_handling p do
        # We need this ordering because #parse will add the :help and :version opts.
        raise Trollop::HelpNeeded if args.empty? # Show help screen
        p.parse args
      end
      if opts[:input_file_given] then

        c = Configuration.read_string opts[:input_file].read
        c.update_milestones octokit_client
      end
    end
  end
end
