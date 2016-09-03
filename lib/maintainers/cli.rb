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
in the current working directory.

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
