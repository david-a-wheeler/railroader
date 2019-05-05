Contribution guidelines

When creating contributions, use "bundle exec rake" to make sure that
your changes pass tests.  If you add significant functionality, please
add matching test(s) to check that it actually works, and also modify
CHANGES.md to note it.

To update the version number, edit `lib/railroader/version.rb`.
To fix that version number run `git tag VERSION` (use "v" as the prefix), then
`git push --tags`.

The final RubyGem is created and distributed using
(replace 4.3.5 with the current version):

    BM_PACKAGE=1 gem build railroader.gemspec
    gem push railroader-4.3.5.gem

For more about gems, see: https://guides.rubygems.org/make-your-own-gem/
