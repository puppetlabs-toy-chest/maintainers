# encoding: utf-8
# frozen_string_literal: true

require 'optparse'

module Maintainers
  # CLI entry point
  class CLI
    attr_reader :options

    def initialize
      @options = {}
    end

    def usage
      usage = <<USAGE
usage: maintainers <command> [<args>]

See below for subcommands. All operate on a file called 'MAINTAINERS'
in the current working directory, except for 'report' which looks for
that file throughout a github organization.

create --issues <issues text> [--unmaintained]

    Creates a MAINTAINERS file scaffold (but with no people yet).
    - An 'issues' string is required - typically this is the
      URL at which to file issues, but knock yourself out.
    - An 'unmaintained' flag is optional - this make explicit
      that a repo is not maintained.

add --github <github id> [--email <email address] [--name <street name>]

    Add a maintainer to the MAINTAINERS file. This can also be used to update
    a maintainer (e.g. adding an 'email' or 'name'): if the specified 'github' id
    is already in the MAINTAINERS file, the new fields will be merged with
    the exiting ones.
    - A 'github' id is required.
    - An 'email' address is optional.
    - A 'name' is optional.

remove --github <github id>

    Remove a maintainer from the MAINTAINERS file.
    - A 'github' id is required.

list

    List the maintainers in a tabular form.

validate

    Validate that the MAINTAINERS file can be read. This can
    be useful if you hand-edit the file but want to double-check
    that it is still machine readable.

report [--verbose] [--details [repo|people|lists]

    Report on maintainers throughout a github organization. By default,
    the report just lists maintained repos, but see --details for more.
    - The 'verbose' flag turns on some status. Note that the
      report can take a while (a couple minutes) due to the number
      of github API calls needed.
    - The 'details' flag generates a report which is either
      repo-centric, i.e. a sorted list of repos with the people
      maintainer each, people-centric, i.e. a sorted list of
      people with what repos they maintain, OR lists-centric, which
      creates a csv with rows for every maintainer on every repo.

    Note: for the report to include private repos, generate a github
    token with full control of private repositories, and then
    set the environment variable GITHUB_TOKEN to that token.
    Also note that this token may not really be optional:
    specifically, if you do *not* specify a GITHUB_TOKEN and the
    organization has a lot of repos (hi puppetlabs), you will likely
    hit github rate limit exceptions.
USAGE
      puts usage
      exit 1
    end

    # @return [Hash] Return an options hash
    def parse(args)

      subcommands = {
        'create' => OptionParser.new do |opts|
            opts.on("-i", "--issues [ISSUES URL]", "issues url") do |v|
              options[:issues] = v
            end
         end,
        'add' => OptionParser.new do |opts|
            opts.on("-g", "--github [GITHUB ID]", "github id") do |v|
              options[:github] = v
            end
            opts.on("-e", "--email [EMAIL ADDRESS]", "email address") do |v|
              options[:email] = v
            end
            opts.on("-n", "--name [REAL NAME]", "real name") do |v|
              options[:name] = v
            end
         end,
        'remove' => OptionParser.new do |opts|
            opts.on("-g", "--github [GITHUB ID]", "github id") do |v|
              options[:github] = v
            end
         end,
        'list' => OptionParser.new do |opts|
         end,
        'validate' => OptionParser.new do |opts|
         end,
        'report' => OptionParser.new do |opts|
            opts.on("-v", "--verbose", "verbosity") do |v|
              options[:verbose] = v
            end
            opts.on("-d", "--details [repos|people|lists]", "detailed report") do |v|
              options[:details] = v
            end
         end,
       }

      usage if args.count == 0

      subcommand = args.shift
      options[:subcommand] = subcommand

      usage unless subcommands.keys.include? subcommand

      subcommands[subcommand].order!

      if subcommand == 'create' && options[:issues].nil?
        $stderr.puts "Please specify --issues"
        usage
      end

      if subcommand == 'add' && options[:github].nil?
        $stderr.puts "Please specify --github"
        usage
      end

      if subcommand == 'report' && !options[:details].nil? && !['repo', 'people', 'lists'].include?(options[:details])
        $stderr.puts "--details must specify either 'repo', 'people', or lists"
        usage
      end

      if args.count > 0
        $stderr.puts "Unexpected additional args #{args}"
        usage
      end

      options
    end  # parse()

    # @return [Fixnum] exit code
    def run(args = ARGV)
      @options = parse(args)

      runner = Runner.new(@options)
      runner.run
    rescue StandardError, SyntaxError => e
      $stderr.puts e.message
      $stderr.puts e.backtrace
      return 1
    end
  end
end
