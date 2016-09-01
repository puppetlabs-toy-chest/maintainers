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
      puts "Imagine a usage statement here"
      exit 1
    end

    SUBCOMMANDS_WE_LOVE = [
      "create",
      "add",
      "remove",
      "list",
      "report",
      "help",
      "--help",
    ]

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
       }

      if args.count == 0
        $stderr.puts "Give me some args please"
        usage
      end

      subcommand = args.shift
      options[:subcommand] = subcommand

      unless subcommands.keys.include? subcommand
        usage
      end

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
