require 'hamsterdam'
require 'octokit.rb'
require 'time'
require 'yaml'

module OctoHerder
  NEUTRAL_TONE = '#cccccc'

  Configuration = Hamsterdam::Struct.define(:master, :repositories, :milestones, :columns, :labels)
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
      labels = data.fetch('labels', [])
      milestones = data.fetch('milestones', [])
      repositories = data.fetch('repositories', [])
      Configuration.new master: master, repositories: repositories, milestones: milestones, columns: columns, labels: labels
    end

    def write_file path
      File.open(path.to_s, "w") { |f|
        h = Hash.new
        h['master'] = master
        h['repositories'] = repositories
        h['milestones'] = milestones # These are bare hashes at the moment
        h['columns'] = columns
        h['labels'] = labels
        f.puts h.to_yaml
      }
    end

    # Ensure that every repository has the specified labels. Labels always
    # have the same, neutral, colour.
    def update_labels octokit_connection
      ([master] + repositories).map {|str|
        Octokit::Repository.new str
      }.each { |r|
        actual_labels = octokit_connection.labels r
        (labels - actual_labels).each { |label|
          octokit_connection.add_label(r, label, NEUTRAL_TONE)
        }
      }
    end

    # Ensure that every repository has the specified milestones, ignoring
    # closed ones.
    def update_milestones octokit_connection
      milestone_titles = milestones.map { |m| m.fetch('title', '') }

      ([master] + repositories).map { |str|
        Octokit::Repository.new str
      }.each { |repo|
        actual_milestones = octokit_connection.list_milestones(repo).map { |m|
          m.fetch('title', '')
        }
        milestones.reject { |m| actual_milestones.include? m['title'] }.each { |m|
          opts = to_octokit_opts m
          octokit_connection.create_milestone(repo, m['title'], opts)
        }

        milestones.select { |m| actual_milestones.include? m['title'] }.each { |m|
          opts = to_octokit_opts m
          octokit_connection.update_milestone(repo, m['title'], opts)
        }
      }
      self
    end

    def to_octokit_opts hash
      opts = hash.dup
      opts.delete 'title'
      opts['due_on'] = opts['due_on'].iso8601 if opts.has_key? 'due_on'
      opts
    end
  end
end
