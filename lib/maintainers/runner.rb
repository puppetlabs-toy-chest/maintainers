# encoding: utf-8
# frozen_string_literal: true

require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

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

      doc = Hocon::Parser::ConfigDocumentFactory.parse_file(filename)
      doc = doc.set_config_value('maintainers.version',
                                 Hocon::ConfigValueFactory.from_any_ref(1))

      if issues_url
        doc = doc.set_value('maintainers.issues', issues_url)
      end
      File.open(filename, 'w') do |file|
        file.puts(doc.render)
      end
    end

    # add a contributor given the filename and contributor attributes
    def add(filename, github, email, name, comment=nil, section=nil)
        ro_doc = Hocon::ConfigFactory.parse_file(filename)
        rw_doc = Hocon::Parser::ConfigDocumentFactory.parse_file(filename)

        people = ro_doc.get_value('maintainers.people') if ro_doc.has_path?('maintainers.people')
        # modify people to add this person and then add that to rw_doc. i think.
        File.open(filename, 'w') do |file|
          file.puts(rw_doc.render)
        end
    end
  end
end
