require 'json'
require 'json-schema'

describe 'the maintainers schema' do
  it 'validates against the json meta schema' do
    json_meta_schema = JSON.parse(File.read('schema/json-meta-schema.json'))
    maintainers_schema = JSON.parse(File.read('schema/maintainers.json'))

    JSON::Validator.validate!(json_meta_schema, maintainers_schema)
#    JSON::Validator.validate!(@schema, json)
  end
end

describe 'the maintainers example' do
  it 'validates against the maintainers schema' do
    maintainers_schema = JSON.parse(File.read('schema/maintainers.json'))
    maintainers_example = JSON.parse(File.read('MAINTAINERS-example'))

    JSON::Validator.validate!(maintainers_schema, maintainers_example)
  end
end

describe 'the maintainers unmaintained example' do
  it 'validates against the maintainers schema' do
    maintainers_schema = JSON.parse(File.read('schema/maintainers.json'))
    maintainers_example = JSON.parse(File.read('MAINTAINERS-unmaintained_example'))

    JSON::Validator.validate!(maintainers_schema, maintainers_example)
  end
end
