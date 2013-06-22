require 'hamsterdam'
require 'octokit.rb'
require 'time'
require 'safe_yaml'

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

    def self.generate_configuration octokit_connection, master_repo_name
      all_labels = octokit_connection.labels(master_repo_name).
        collect { |l| l.fetch('name', '') }
      repo_links = all_labels.select { |l| l.match @@huboard_link }
      repositories = repo_links.map { |l| l.match(@@huboard_link)[1].strip }
      columns = all_labels.select { |l| l.match(@@huboard_column) }
      labels = all_labels - repo_links - columns
      milestones = octokit_connection.list_milestones(master_repo_name).collect {|octohash|
        {
          "description" => octohash["description"],
          "due_on" => octohash["due_on"],
          "state" => octohash["state"],
          "title" => octohash["title"]
        }
      }

      Configuration.new master: master_repo_name, repositories: repositories, milestones: milestones, columns: columns, labels: labels
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
      ([master] + repositories).map { |str|
        Octokit::Repository.new str
      }.each { |r|
        actual_labels = octokit_connection.labels r
        ((labels + columns) - actual_labels).each { |label|
          octokit_connection.add_label(r, label, NEUTRAL_TONE)
        }
      }
    end

    def update_link_labels octokit_connection
      repositories.map { | str |
        octokit_connection.add_label(master, "Link <=> #{str}", NEUTRAL_TONE)
      }
    end

    # Ensure that every repository has the specified milestones, ignoring
    # closed ones.
    def update_milestones octokit_connection
      milestone_titles = milestones.map { |m| m.fetch('title', '') }

      ([master] + repositories).map { |str|
        Octokit::Repository.new str
      }.each { |repo|
        ms = octokit_connection.list_milestones(repo)

        # Map milestone titles to IDs
        actual_milestones = Hash[ms.map { |m|
          [m.fetch('title'), m.fetch('number')]
        }]

        milestone_titles = actual_milestones.keys

        milestones.reject { |m| milestone_titles.include? m.fetch('title') }.each { |m|
          opts = to_octokit_opts m
          octokit_connection.create_milestone(repo, m.fetch('title'), opts)
        }

        milestones.select { |m| milestone_titles.include? m.fetch('title') }.each { |m|
          milestone_number = actual_milestones[m.fetch('title')]
          opts = to_octokit_opts m
          octokit_connection.update_milestone(repo, milestone_number, opts)
        }
      }
      self
    end

    def to_octokit_opts hash
      opts = hash.dup
      opts.delete 'title'
      opts['due_on'] = opts['due_on'].iso8601 if opts['due_on']
      opts
    end

    private
    @@huboard_link = /Link.*<=>(.*)/
    @@huboard_column = /[0-9]+\ .*/
  end
end
