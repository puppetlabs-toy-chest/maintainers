# encoding: utf-8
# frozen_string_literal: true

require 'json'
require 'json-schema'
require 'octokit'

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
      schema_path = File.join(Gem.loaded_specs['maintainers'].gem_dir, 'schema/MAINTAINERS.json')

      JSON.parse(File.read(schema_path))
    end

    def validate_json(maintainers, quiet = false)
      begin
        JSON::Validator.validate!(maintainers_schema, maintainers)
      rescue JSON::Schema::ValidationError => e
        puts e unless quiet
        false
      end
    end

    def write_file(filename, maintainers)
      maintainers_json = JSON.pretty_generate(maintainers)

      if !validate_json(maintainers_json)
        $stderr.puts "Invalid maintainers string!"
        exit 1
      end

      File.open(filename, 'w') { |f| f.write(maintainers_json) }
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
      maintainers["file_format"] = "This MAINTAINERS file format is described at https://github.com/puppetlabs/maintainers"
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

    def report(options)
      puts "Ok, hang tight, this may take a while as I query github ..."
      client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'], :auto_paginate => true)

      repos = client.org_repos(options[:org])

      puts "Found a total of #{repos.count} #{options[:org]} repos"

      # For now hardwire some arbitrary filters to help narrow down the
      # number of repos reported on (and thus github API calls):
      # - ignore repos with < 5 forks
      # - ignore repos on a blocklist
      # There are pretty arbitrary lines, so could be parameterized (or dropped).

      lightly_forked_repos, repos = repos.partition { |repo| repo.forks < 5 }

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

      blocklisted_repos, repos = repos.partition { |repo| blocklist.include? repo.name }

      no_maintainers_file_repos, repos = repos.partition { |repo|
        begin
          contents = client.contents("#{options[:org]}/#{repo.name}", :path => 'MAINTAINERS')
        rescue Octokit::NotFound
        end

        contents.nil?
      }

      unrecognized_maintainers_file_repos, repos = repos.partition { |repo|
        contents = client.contents("#{options[:org]}/#{repo.name}", :path => 'MAINTAINERS')
        # the file content is base64 encoded with some '\n's sprinkled in.
        # the split.join maneuver below strips out those '\n' sprinkles.
        maintainers = Base64.decode64(contents[:content].split.join)

        !validate_json(maintainers, true)
      }

      puts "Skipped #{lightly_forked_repos.count} repos with fewer than 5 forks" if lightly_forked_repos
      puts "Skipped #{blocklisted_repos.count} repos on a blocklist" if blocklisted_repos
      puts "Skipped #{no_maintainers_file_repos.count} without a MAINTAINERS file" if no_maintainers_file_repos
      puts "Skipped #{unrecognized_maintainers_file_repos.count} with a MAINTAINERS file in a different format" if unrecognized_maintainers_file_repos
      puts "Found #{repos.count} repos with MAINTAINERS files"

    end

  end
end
