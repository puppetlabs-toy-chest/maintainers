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

Add users identified by github id, optionally specifying name, email address, and a comment.

```ruby
maintainers add --github gracehopper --email grace@usnavy.gov --name "Grace Hopper"
maintainers add --github gracehopper --email grace@usnavy.gov --name "Grace Hopper" --comment "Maintains ENIAC"
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

### Produce a summary report of maintainers within the puppetlabs org

```ruby
maintainers report
```

### Validate the MAINTAINERS file

Run this from the root of your project.

```ruby
maintainers validate
```

## Getting a github token

Some commands (for now, just `report`) will make use of a github token if one is specified in an environment variable `GITHUB_TOKEN`.

To use this, you will need to generate a suitable github token like so:
* Logged in at github.com, click on your avatar (upper right), then select 'Settings'
* In the left-hand nav scroll down to 'Personal Access Tokens' and select that
* Then select 'Generate new token'
* Give the token a description, then *be sure to select* the 'repo' permissions as in the image below
* Then click 'Generate Token' down below, and copy the resultant token to wherever you specify the `GITHUB_TOKEN` environment variable
* Profit!

![alt-tag](https://cloud.githubusercontent.com/assets/1752967/18526927/760b0464-7a77-11e6-865b-afcb5695c810.png)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/maintainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

