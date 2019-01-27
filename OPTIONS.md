This file may or may not be up-to-date. For best results but less information, run `railroader --help`.

## Scanning Options

There are some checks which are not run by default. To run all checks, use:

    railroader -A

Each check will be run in a separate thread by default. To disable this behavior:

    railroader -n

By default, Railroader scans the current directory. A path can also be specified as a bare argument, like:

    railroader some/path/to/app

But to be even more specific, the `-p` or `--path` option may be used:

    railroader -p path/to/app

To suppress informational warnings and just output the report:

    railroader -q

Note all Railroader output except reports are sent to stderr, making it simple to redirect stdout to a file and just get the report.

By default, Railroader will return a non-zero exit code if any security warnings are found or scanning errors are encountered. To disable this:

    railroader --no-exit-on-warn --no-exit-on-error

To force Railroader into Rails 3 mode:

    railroader -3

Or to force Railroader into Rails 4 mode:

    railroader -4

Beware some behavior and checks rely on knowing the exact version name. This shouldn't be a problem with any modern Rails app using a `Gemfile.lock` though.

Railroader used to parse `routes.rb` and attempt to infer which controller methods are used as actions. However, this is not perfect (especially for Rails 3/4), so now it assumes all controller methods are actions. To disable this behavior:

    railroader --no-assume-routes

While this shouldn't be necessary, it is possible to force Railroader to assume output is escaped by default:

    railroader --escape-html

If Railroader is running a bit slow, try

    railroader --faster

This will disable some features, but will probably be much faster (currently it is the same as `--skip-libs --no-branching`). *WARNING*: This may cause Railroader to miss some vulnerabilities.

To disable flow sensitivity in `if` expressions:

    railroader --no-branching

To instead limit the number of branches tracked for a given value:

    railroader --branch-limit LIMIT

`LIMIT` should be an integer value. `0` is almost the same as `--no-branching` but `--no-branching` is preferred. The default value is `5`. Lower values generally make Railroader go faster. `-1` is the same as unlimited.

To skip certain files or directories use:

    railroader --skip-files file1,/path1/,path2/

Directories are matched relative to the root path of your application and must end in a path separator for your platform (ex. `/`). The above invocation would match and skip the following:

* Any file named `file1`. Any file that has `file1` as a path component would still be scanned.
* Any file within `/path1`. Because of the leading `/`, only directories from the application's root directory will match. For example, `/lib/path1/some_path1_file.rb` would still be scanned.
* Any directory named `path2`. Because there is no leading `/`, any directory with `path2` as a path component will be skipped. For example, `/lib/path2/some_lib_for_testing.rb` would not be scanned.

Note Railroader does "whole program" analysis, therefore skipping a file may affect warning results from more than just that one file.

The inverse but even more dangerous option is to choose specific files or directories to scan:

    railroader --only-files file1,/path2/,path2/

Again, since Railroader looks at the whole program, it is very likely not going to behave as expected when scanning a subset of files. Also, if certain files are excluded Railroader may not function at all.

To skip processing of the `lib/` directory:

    railroader --skip-libs

To run a subset of checks:

    railroader --test Check1,Check2,etc

To exclude certain checks:

    railroader --except Check1,Check2,etc

Note it is not necessary to include the `Check` part of the check. For example, these are equivalent:

    railroader --test CheckSQL
    railroader --test SQL

## Output Options

To see all kinds of debugging information:

    railroader -d

To specify an output file for the results:

    railroader -o output_file

The output format is determined by the file extension or by using the `-f` option. Current options are: `text`, `html`, `tabs`, `json`, `markdown` and `csv`.

Multiple output files can be specified:

    railroader -o output.html -o output.json

To specify a CSS stylesheet to use with the HTML report:

    railroader --css-file my_cool_styling

By default, Railroader will only report a single warning of a given type for the same line of code. This can be disabled using

    railroader --no-combine-locations

To disable highlighting of "dangerous" or "user input" values in warnings:

    railroader --no-highlights

To report controller and route information:

    railroader --routes

However, if you really want to know what routes an app has, use

    rake routes

To set the limit on message length in HTML reports, use

    railroader --message-limit LIMIT

The default LIMIT is 100.

To limit width of the tables output in text reports, use

    railroader --table-width LIMIT

By default, there is no limit.

Railroader will warn about each model without `attr_accessible`. In the HTML report it may be nicer to get all models in one warning with

    railroader --no-separate-models

Sometimes you don't need a big report, just the summary:

    railroader --summary

Reports show relative paths by default. To use absolute paths instead:

    railroader --absolute-paths

This does not affect HTML or tab-separated reports.

To output Markdown with nice links to files on Github, use

    railroader --github-repo USER/REPO[/PATH][@REF]

For example,

    railroader --github-repo presidentbeef/inject-some-sql

To compare results of a scan with a previous scan, use the JSON output option and then:

    railroader --compare old_report.json

This will output JSON with two lists: one of fixed warnings and one of new warnings.

By default, railroader opens output in `less` pager. To have railroader output directly to terminal, use

    railroader --no-pager

## Ignoring Stuff

Railroader will ignore warnings if configured to do so. By default, it looks for a configuration file in `config/railroader.ignore`.

To specify a file to use:

    railroader -i path/to/config.ignore

To create and manage this file, use:

    railroader -I

To ignore possible XSS from model attributes:

    railroader --ignore-model-output

Railroader will raise warnings on models that use `attr_protected`. To suppress these warnings:

    railroader --ignore-protected

Railroader will assume that unknown methods involving untrusted data are dangerous. For example, this would cause a warning (Rails 2):

    <%= some_method(:option => params[:input]) %>

To only raise warnings only when untrusted data is being directly used:

    railroader --report-direct

This option is not supported very consistently, though.

To indicate certain methods return properly escaped output and should not be warned about in XSS checks:

    railroader --safe-methods benign_method_escapes_output,totally_safe_from_xss

Railroader warns about use of user input in URLs generated with `link_to`. Since Rails does not provide anyway of making these URLs really safe (e.g. limiting protocols to HTTP(S)), safe methods can be ignored with

    railroader --url-safe-methods ensure_safe_protocol_or_something

## Confidence Levels

Railroader assigns a confidence level to each warning. This provides a rough estimate of how certain the tool is that a given warning is actually a problem. Naturally, these ratings should not be taken as absolute truth.

There are three levels of confidence:

 + High - Either this is a simple warning (boolean value) or user input is very likely being used in unsafe ways.
 + Medium - This generally indicates an unsafe use of a variable, but the variable may or may not be user input.
 + Weak - Typically means user input was indirectly used in a potentially unsafe manner.

To only get warnings above a given confidence level:

    railroader -w3

The `-w` switch takes a number from 1 to 3, with 1 being low (all warnings) and 3 being high (only highest confidence warnings).

## Configuration Files

Railroader options can stored and read from YAML files. To simplify the process of writing a configuration file, the `-C` option will output the currently set options.

Options passed in on the commandline have priority over configuration files.

The default config locations are `./config/railroader.yml`, `~/.railroader/config.yml`, and `/etc/railroader/config.yml`

The `-c` option can be used to specify a configuration file to use.

## Miscellaneous

To list available checks with short descriptions:

    railroader --checks

To show checks which are optional (not run by default):

    railroader --optional-checks

To see Railroader's version:

    railroader --version

To see the real list of options:

    railroader --help
