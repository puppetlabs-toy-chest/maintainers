require 'spec_helper'

describe Maintainers do
  it 'has a version number' do
    expect(Maintainers::VERSION).not_to be nil
  end
end

describe 'badly formed json' do
  it 'fails validation' do
    maintainers_schema = JSON.parse(File.read('schema/MAINTAINERS-schema.json'))
    # comma removed to make malformed input
    maintainers_example = <<-EOF
{
  "version": 1,
  "file_format": "This MAINTAINERS file format is described at http://pup.pt/maintainers",
  "maintained": false
  "issues": "This repo is not maintained",
  "people": []
}
    EOF

    runner = Maintainers::Runner.new({})
    expect(runner.validate_json(maintainers_example, true)).to be false
  end
end
