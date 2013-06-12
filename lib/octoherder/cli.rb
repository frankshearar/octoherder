require 'octoherder'
require 'trollop'


module OctoHerder
  class CLI
    def self.parse_argv(args)
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
        opt :output_file, 'Path to the file that will contain the canonical project setup', short: 'o', type: :string
        opt :user, 'User as whom to authenticate', short: 'u', type: :string, default: nil
        opt :password, 'User''s password', short: 'p', type: :string, default: nil
        opt :oauth_token, 'OAuth token', short: 't', type: :string, default: nil
        opt :version, "Print version and exit", short: 'v'
        opt :help, "Show this message", short: 'h'

        depends :output_file, :repo
        conflicts :password, :oauth_token
      end

      opts = Trollop::with_standard_exception_handling p do
        raise Trollop::HelpNeeded if args.empty? # Show help screen
        p.parse args
      end
    end

    def self.run(args)
      opts = parse_argv(args)
      kitty = Octokit.new(octoauth(opts))
      CLI.new.run kitty, opts
    end

    def self.octoauth cli_opts
      auth = {}
      auth[:login] = cli_opts[:user] if cli_opts[:user_given]
      auth[:password] = cli_opts[:password] if cli_opts[:password_given]
      auth[:oauth] = cli_opts[:oauth_token] if cli_opts[:oauth_token_given]
      auth
    end

    def run octokit_client, opts
      if opts[:input_file_given] then
        c = Configuration.read_string opts[:input_file].read
        c.update_milestones octokit_client
      end

      if opts[:output_file_given] then
        Configuration.generate_configuration(octokit_client, opts[:repo]).write_file(opts[:output_file])
      end
    end
  end
end
