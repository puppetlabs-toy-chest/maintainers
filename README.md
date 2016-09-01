# Maintainers

This is a gem for maintaining MAINTAINERS files.

## Installation

```ruby
    $ gem install maintainers
```

## Usage

Some use cases:

### Create an empty MAINTAINERS file

The only top-level configurable you might want to specify is the issues url.

```ruby
maintainers create --issues https://github.com/gracehopper/newthing/issues
```

At this point you might drop some comments in the resultant MAINTAINERS file.

### Add or remove a maintainer from a MAINTAINERS file

Add users, optionally as a subsystem maintainer, optionally with a comment:

```ruby
maintainers add --github gracehopper --email grace@usnavy.gov --name "Grace Hopper"
maintainers add --github gracehopper --email grace@usnavy.gov --name "Grace Hopper" --subsystem --comment "Maintains ENIAC"
```

Remove user by specifying the github id:

```ruby
maintainers remove --github gracehopper
```

### List maintainers from a MAINTAINERS file

Emit a list of maintainers:

```ruby
maintainers list
```

### List maintainers for a repo

Emit a list of maintainers:

```ruby
maintainers list https://github.com/gracehopper/newthing
```

### Produce a summary report of maintainers within an org

```ruby
maintainers report https://github.com/gracehopper
```

### Report all repos in an org maintained by someone

```ruby
maintainers report --github gracehopper https://github.com/gracehopper
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/maintainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

