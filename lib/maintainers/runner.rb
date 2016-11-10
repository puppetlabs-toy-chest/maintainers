# encoding: utf-8
# frozen_string_literal: true

require 'json'
require 'json-schema'
require 'octokit'
require 'csv'

module Maintainers
  # Runner entry point
  class Runner
    def initialize(options)
      @options = options

      # for now just assume it's always MAINTAINERS
      options[:filename] ||= 'MAINTAINERS'

      # for now just assume it's always puppetlabs
      options[:org] ||= 'puppetlabs'
    end

    # Run, Lola, Run
    # @return nil
    def run
      case @options[:subcommand]
      when 'create'
        create(@options)
      when 'add'
        add(@options)
      when 'remove'
        remove(@options)
      when 'list'
        list(@options)
      when 'validate'
        validate(@options)
      when 'report'
        report(@options)
      end
    end

    def maintainers_schema
      # I don't know what the idiomatic way is to access a non-ruby file packaged
      # with the gem. This seems gross but it works.
      schema_path = File.join(Gem.loaded_specs['maintainers'].gem_dir, 'schema/MAINTAINERS-schema.json')

      JSON.parse(File.read(schema_path))
    end

    def validate_json(maintainers, quiet = false)
      begin
        JSON::Validator.validate!(maintainers_schema, maintainers)
      rescue JSON::Schema::ValidationError, JSON::Schema::UriError => e
        puts "JSON parsing failed or did not match schema\n#{e}\n#{maintainers}" unless quiet
        false
      end
    end

    def write_file(filename, maintainers)
      maintainers_json = JSON.pretty_generate(maintainers)

      if !validate_json(maintainers_json)
        $stderr.puts "Invalid maintainers string!"
        exit 1
      end

      File.open(filename, 'w') { |f| f.puts(maintainers_json) }
    end

    def create(options)
      filename = options[:filename]
      if File.exist?(filename)
        $stderr.puts "#{filename} already exists. Remove it and then re-run this command."
        exit 1
      end

      # minimum content for a maintainers file
      maintainers = {}
      maintainers["version"] = 1
      maintainers["file_format"] = "This MAINTAINERS file format is described at http://pup.pt/maintainers"
      maintainers["issues"] = options[:issues]
      maintainers["people"] = []

      write_file(filename, maintainers)
    end

    def add(options)
      filename = options[:filename]
      if !File.exist?(filename)
        $stderr.puts "No #{filename} file exists yet. You can use the 'create' subcommand to create one."
        exit 1
      end

      maintainers = JSON.load(File.read(filename))
      new_maintainer = { "github" => options[:github] }
      new_maintainer["email"] = options[:email] if options[:email]
      new_maintainer["name"]  = options[:name] if options[:name]
      index = maintainers["people"].index { |person| person["github"] == options[:github] }
      if index
        current = maintainers["people"][index]
        new_maintainer.merge! current
        maintainers["people"][index] = new_maintainer
      else
        maintainers["people"] << new_maintainer
      end

      write_file(filename, maintainers)
    end

    def remove(options)
      filename = options[:filename]
      if !File.exist?(filename)
        $stderr.puts "No #{filename} file exists yet. You can use the 'create' subcommand to create one."
        exit 1
      end

      maintainers = JSON.load(File.read(filename))
      index = maintainers["people"].index { |person| person["github"] == options[:github] }
      if index
        maintainers["people"].slice!(index)
      else
        puts "I didn't find #{options[:github]} in the file #{filename}"
      end

      write_file(filename, maintainers)
    end

    def list(options)
      filename = options[:filename]
      if !File.exist?(filename)
        $stderr.puts "No #{filename} file exists yet. You can use the 'create' subcommand to create one."
        exit 1
      end

      maintainers_json = File.read(filename)
      validate_json(maintainers_json)
      maintainers = JSON.load(maintainers_json)

      maintainers['people'].each { |p|
        puts "%-16s %-20s %s" % [ p['github'], p['name'], p['email'] ]
      }
    end

    def validate(options)
      filename = options[:filename]
      if !File.exist?(filename)
        $stderr.puts "No #{filename} file exists yet. You can use the 'create' subcommand to create one."
        exit 1
      end

      if validate_json(File.read(filename))
        puts "#{filename} looks good"
      else
        puts "There's something wrong with #{filename}"
        exit 1
      end
    end

    def report_basic(maintainers_files)
      maintainers_files.keys.sort.each { |repo|
        maintainers = JSON.load( maintainers_files[repo] )
        if !maintainers['maintained'].nil? && !maintainers['maintained']
          puts "#{repo} (unmaintained)"
        else
          puts "#{repo}"
        end
      }
    end

    def report_repo_details(maintainers_files)
      maintainers_files.keys.sort.each { |repo|
        puts "\t#{repo}"
        maintainers = JSON.load( maintainers_files[repo] )
        puts "\t\tunmaintained" if !maintainers['maintained'].nil? && !maintainers['maintained']
        maintainers['people'].each { |person|
          puts "\t\t#{person['name'] ? person['name'] : person['github']}"
        }
      }
    end

    def report_lists_details(maintainers_files)
      report_name = "repo_report_#{Time.new.strftime("%Y-%m-%d_%H:%M:%S")}.csv"
      CSV.open(report_name, "wb") do |csv|
        csv << ["repo","repo_group","maintainer"]
        maintainers_files.keys.sort.each { |repo|
          maintainers = JSON.load( maintainers_files[repo] )
          list = maintainers['internal_list']
          if list 
            maintainers['people'].each { |person|
              name =  "#{person['email'] ? person['email'] : person['name'] ? person['name'] : person['github']}"
              csv << [repo,list, name ]
            }
          end
        }
      puts "Your report is called '#{report_name}'"
      end
    end

    def report_people_details(maintainers_files)
      people = {}

      # populate the people hash, building up a 'repos' array per person
      maintainers_files.keys.sort.each { |repo|
        maintainers = JSON.load( maintainers_files[repo] )
        maintainers['people'].each { |person|
          github_id = person['github']
          if people[github_id].nil?
            people[github_id] = person
            people[github_id]['repos'] = [ repo ]
          else
            people[github_id]['repos'] <<  repo
          end
        }
      }

      # report out on the people hash
      people.keys.sort.each { |github_id|
        person = people[github_id]
        puts "#{person['name'] ? person['name'] : person['github']} is maintaining:"
        person['repos'].each { |repo| puts "\t#{repo}" }
      }
    end

    def report(options)
      puts "Ok, hang tight, this may take a while as I query github ..." if options[:verbose]
      client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'], :auto_paginate => true)

      repos = client.org_repos(options[:org])

      puts "Found a total of #{repos.count} #{options[:org]} repos" if options[:verbose]

      # For now hardwire some arbitrary filters to help narrow down the
      # number of repos reported on (and thus github API calls):
      # - ignore repos with < 5 forks
      # - ignore repos on a blocklist
      # There are pretty arbitrary lines, so could be parameterized (or dropped).

      lightly_forked, repos = repos.partition { |repo| repo.forks < 5 }

      blocklist = [
        'puppetlabs-modules',
        'courseware',
        'courseware-virtual',
        'showoff',
        'education-builds',
        'robby3',
        'pltraining-classroom',
        'pltraining-bootstrap',
        'sfdc_reporting',
        'tse-control-repo',
        'puppet-quest-guide',
        'courseware-lvm',
      ]

      blocklisted, repos = repos.partition { |repo| blocklist.include? repo.name }

      # hash of repo name to maintainers json blob
      maintainers_files = { }

      no_maintainers_file, repos = repos.partition { |repo|
        begin
          contents = client.contents("#{options[:org]}/#{repo.name}", :path => 'MAINTAINERS')

          # the file content is base64 encoded with some '\n's sprinkled in.
          # the split.join maneuver below strips out those '\n' sprinkles.
          maintainers = Base64.decode64(contents[:content].split.join)
          maintainers_files[repo.name] = maintainers
        rescue Octokit::NotFound
        end

        contents.nil?
      }

      # ok, kinda awkward and not sure if this is worth reporting on?
      # but some repos may contain a file called MAINTAINERS but in a
      # different format
      unrecognized_maintainers_file, repos = repos.partition { |repo|
        !validate_json(maintainers_files[repo.name], true)
      }
      unrecognized_maintainers_file.each { |repo| maintainers_files.delete(repo.name) }

      if options[:verbose]
        puts "Skipped #{lightly_forked.count} repos with fewer than 5 forks" if lightly_forked && lightly_forked.count > 0
        puts "Skipped #{blocklisted.count} repos on a blocklist" if blocklisted && blocklisted.count > 0
        puts "Skipped #{no_maintainers_file.count} without a MAINTAINERS file" if no_maintainers_file && no_maintainers_file.count > 0
        puts "Skipped #{unrecognized_maintainers_file.count} with a MAINTAINERS file in a different format" if unrecognized_maintainers_file && unrecognized_maintainers_file.count > 0
        puts "Found #{repos.count} repos with MAINTAINERS files"
      end

      case options[:details]
      when 'repo'
        report_repo_details(maintainers_files)
      when 'people'
        report_people_details(maintainers_files)      
      when 'lists'
        report_lists_details(maintainers_files)
      else
        report_basic(maintainers_files)
      end

    end

  end
end
