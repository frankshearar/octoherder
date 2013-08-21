require 'hamsterdam'
require 'octokit.rb'
require 'time'
require 'safe_yaml'

SafeYAML::OPTIONS[:default_mode] = :safe

module OctoHerder
  NEUTRAL_TONE = 'cccccc'

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
      labels = data.fetch('labels', []).map(&:to_s)
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
        add_new_labels octokit_connection, r, labels + columns
      }
    end

    def update_link_labels octokit_connection
      actual_labels = octokit_connection.labels(Octokit::Repository.new(master)).map(&:name)
      link_labels = repositories.map { | str | "Link <=> #{str}" }
      add_new_labels octokit_connection, master, link_labels
    end

    def add_new_labels octokit_connection, repository, labels
      existing_labels = octokit_connection.labels(repository).map(&:name)

      (labels - existing_labels).each { | label |
        begin
          octokit_connection.add_label(repository, label, NEUTRAL_TONE)
        rescue Octokit::Error => e
          # Referencing an instvar is disgusting (and fragile). But how else do
          # we get this very useful debugging info? The response body isn't
          # displayed in #inspect.
          puts "Label: #{label.inspect}"
          puts e.instance_variable_get("@response_body").inspect
          raise e
        end
      }
    end

    # Ensure that every repository has the specified milestones, ignoring
    # closed ones.
    def update_milestones octokit_connection
      milestone_titles = milestones.map { |m| m.fetch('title', '') }

      ([master] + repositories).map { |str|
        Octokit::Repository.new str
      }.each { |repo|
        # GitHub by default only shows open milestones. We don't want to try recreate
        # a closed milestone, so we have to explicitly ask for closed milestones.
        ms = octokit_connection.list_milestones(repo, state: 'open') + octokit_connection.list_milestones(repo, state: 'closed')

        # Map milestone titles to IDs
        actual_milestones = Hash[ms.map { |m|
          [m.fetch('title'), m.fetch('number')]
        }]

        milestone_titles = actual_milestones.keys

        milestones.reject { |m| milestone_titles.include? m.fetch('title') }.each { |m|
          opts = to_octokit_opts m
          begin
            octokit_connection.create_milestone(repo, m.fetch('title'), opts)
          rescue Octokit::Error => e
            # Referencing an instvar is disgusting (and fragile). But how else do
            # we get this very useful debugging info? The response body isn't
            # displayed in #inspect.
            puts "Milestone: #{m.fetch('title').inspect}"
            puts e.instance_variable_get("@response_body").inspect
            raise e
          end
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
      # Sometimes dates get read in and autoconverted to a Time and sometimes not.
      if opts['due_on'] && opts['due_on'].kind_of?(String) then
        opts['due_on'] = DateTime.iso8601(opts['due_on'])
      end
      opts
    end

    private
    @@huboard_link = /Link.*<=>(.*)/
    @@huboard_column = /[0-9]+\ .*/
  end
end
