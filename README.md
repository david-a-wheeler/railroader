<!-- [![Railroader Logo](http://railroader.org/images/logo_medium.png)](http://railroader.org/) -->

[![Build Status](https://travis-ci.org/david-a-wheeler/railroader.svg?branch=master)](https://travis-ci.org/david-a-wheeler/railroader)
[![Maintainability](https://api.codeclimate.com/v1/badges/1b08a5c74695cb0d11ec/maintainability)](https://codeclimate.com/github/david-a-wheeler/railroader/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1b08a5c74695cb0d11ec/test_coverage)](https://codeclimate.com/github/david-a-wheeler/railroader/test_coverage)
<!-- [![Gitter](https://badges.gitter.im/david-a-wheeler/railroader.svg)](https://gitter.im/david-a-wheeler/railroader) -->

# Railroader

Railroader is an open source static analysis tool which checks Ruby on Rails applications for security vulnerabilities.

Railroader is a fork of the Brakeman analysis tool version 4.3.1 (the last version of Brakeman that was open source software).  A key distinguishing feature is that Railroader is open source software (OSS), while Brakeman is not open source software any more.  Railroader is licensed under the [MIT-LICENSE](MIT-LICENSE). As a result, Railroader can be freely used for any purpose, including any commercial purposes.  In addition, contributors to Railroader (unlike Brakeman) retain their copyrights.

If you are interested in Brakeman, please see the [Brakeman site](https://brakemanscanner.org/) instead!

We are currently in a transition process, because we have just started creating Railroader as a fork of Brakeman.  Some names in the process of changing - help is wanted to complete it. We need to change the name, because we assume that Synopsys owns the trademarks and in any case we want to make sure there is *no* confusion by anyone that Railroader is Brakeman (they are now different projects).

# Installation

Using RubyGems:

    gem install railroader

Using Bundler:

    group :development do
      gem 'railroader', :require => false
    end

# Usage

From a Rails application's root directory:

    railroader

Outside of Rails root:

    railroader /path/to/rails/application

# Compatibility

Railroader should work with any version of Rails from 2.3.x to 5.x.

Railroader can analyze code written with Ruby 1.8 syntax and newer, but requires at least Ruby 1.9.3 to run.

# Basic Options

For a full list of options, use `railroader --help` or see the [OPTIONS.md](OPTIONS.md) file.

To specify an output file for the results:

    railroader -o output_file

The output format is determined by the file extension or by using the `-f` option. Current options are: `text`, `html`, `tabs`, `json`, `markdown`, `csv`, and `codeclimate`.

Multiple output files can be specified:

    railroader -o output.html -o output.json

To suppress informational warnings and just output the report:

    railroader -q

Note all Railroader output except reports are sent to stderr, making it simple to redirect stdout to a file and just get the report.

To see all kinds of debugging information:

    railroader -d

Specific checks can be skipped, if desired. The name needs to be the correct case. For example, to skip looking for default routes (`DefaultRoutes`):

    railroader -x DefaultRoutes

Multiple checks should be separated by a comma:

    railroader -x DefaultRoutes,Redirect

To do the opposite and only run a certain set of tests:

    railroader -t SQL,ValidationRegex

If Railroader is running a bit slow, try

    railroader --faster

This will disable some features, but will probably be much faster (currently it is the same as `--skip-libs --no-branching`). *WARNING*: This may cause Railroader to miss some vulnerabilities.

By default, Railroader will return a non-zero exit code if any security warnings are found or scanning errors are encountered. To disable this:

    railroader --no-exit-on-warn --no-exit-on-error

To skip certain files or directories that Railroader may have trouble parsing, use:

    railroader --skip-files file1,/path1/,path2/

To compare results of a scan with a previous scan, use the JSON output option and then:

    railroader --compare old_report.json

This will output JSON with two lists: one of fixed warnings and one of new warnings.

Railroader will ignore warnings if configured to do so. By default, it looks for a configuration file in `config/railroader.ignore`.
To create and manage this file, use:

    railroader -I

# Warning information

See [warning\_types](docs/warning_types) for more information on the warnings reported by this tool.

# Warning context

The HTML output format provides an excerpt from the original application source where a warning was triggered. Due to the processing done while looking for vulnerabilities, the source may not resemble the reported warning and reported line numbers may be slightly off. However, the context still provides a quick look into the code which raised the warning.

# Confidence levels

Railroader assigns a confidence level to each warning. This provides a rough estimate of how certain the tool is that a given warning is actually a problem. Naturally, these ratings should not be taken as absolute truth.

There are three levels of confidence:

 + High - Either this is a simple warning (boolean value) or user input is very likely being used in unsafe ways.
 + Medium - This generally indicates an unsafe use of a variable, but the variable may or may not be user input.
 + Weak - Typically means user input was indirectly used in a potentially unsafe manner.

To only get warnings above a given confidence level:

    railroader -w3

The `-w` switch takes a number from 1 to 3, with 1 being low (all warnings) and 3 being high (only highest confidence warnings).

# Configuration files

Railroader options can stored and read from YAML files. To simplify the process of writing a configuration file, the `-C` option will output the currently set options.

Options passed in on the commandline have priority over configuration files.

The default config locations are `./config/railroader.yml`, `~/.railroader/config.yml`, and `/etc/railroader/config.yml`

The `-c` option can be used to specify a configuration file to use.

# Continuous Integration

There is a [plugin available](http://railroader.org/docs/jenkins/) for Jenkins/Hudson.

For even more continuous testing, try the [Guard plugin](https://github.com/guard/guard-railroader).

# Building

    git clone git://github.com/david-a-wheeler/railroader.git
    cd railroader
    gem build railroader.gemspec
    gem install railroader*.gem

<!-- # Who is Using Railroader?

* [Code Climate](https://codeclimate.com/)
* [GitHub](https://github.com/)
* [Groupon](http://www.groupon.com/)
* [New Relic](http://newrelic.com)
* [Twitter](https://twitter.com/)

[..and more!](http://railroader.org)

-->

# Homepage/News

Website: http://railroader.org/

Twitter: https://twitter.com/railroader

# License

See [MIT-LICENSE](MIT-LICENSE).
