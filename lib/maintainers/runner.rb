# encoding: utf-8
# frozen_string_literal: true

module Maintainers
  # Runner entry point
  class Runner
    def initialize(options)
      @options = options

      # for now just assume it's always MAINTAINERS
      options[:filename] ||= 'MAINTAINERS'
    end

    # Run, Lola, Run
    # @return nil
    def run
      case @options[:subcommand]
      when 'create'
        create(@options[:filename], @options[:issues])
      when 'add'
        add(@options[:filename], @options[:github], @options[:email], @options[:name])
      when 'remove'
        remove(@options[:filename], @options[:github])
      end
    end

    # Create a new file given the file name and an optional issues url
    def create(filename, issues_url = nil)
      File.open(filename, 'w')
    end

    # add a contributor given the filename and contributor attributes
    def add(filename, github, email, name, comment=nil, section=nil)
    end
  end
end
