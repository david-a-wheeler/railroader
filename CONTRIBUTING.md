# Contribution guidelines

## License

NOTE: Your contributions *must* be released under at least the
file in MIT-LICENSE (the MIT license).
There is no need for a copyright assignent.

## Tests and style

When creating contributions:

* Use `bundle exec rake` to make sure that
  your changes pass tests.  If you add significant functionality, please
  add matching test(s) to check that it actually works, and also modify
  CHANGES.md to note it.
* Use `bundle exec rubocop` to ensure that your code has a reasonable style.

## Signed commits

Please use "git commit -a" (signed commits).  This indicates that you
agree with the Developer Certificate of Origin (DCO), which basically
states that you are legally allowed to make the contribution. Details here:
https://developercertificate.org/

## How to submit vulnerability reports

If you find an exploitable vulnerability in Railroader itself,
please send a private email to dwheeler (at) dwheeler (dot) com and do
*not* post the issue publicly on the issue tracker.
If practical, please send the email from one of the many systems that support
sending and receiving StartTLS (Gmail, Hotmail, and runbox.com are
known to do so).
In the subject line include `VULNERABILITY` (all-caps) and `Railroader`.

See the [EFF announcement about StartTLS](https://www.eff.org/deeplinks/2018/06/announcing-starttls-everywhere-securing-hop-hop-email-delivery)
if you'd like to know more more about StartTLS.

We strongly prefer that you use a coordinated disclosure process, that is,
give us a little time to *fix* the problem before telling everyone.
That's why we want you to use StartTLS, since that encrypts emails between
email systems.
We don't expect you to be quiet about it forever (that would be unreasonable).
We don't *require* that you provide a suggested fix, but one would be
greatly appreciated.

Thanks!

## How to create releases

(This text assumes you have permission to do this.)

To update the version number, edit `lib/railroader/version.rb`.
To fix that version number run `git tag VERSION` (use "v" as the prefix), then
`git push --tags`.

The final RubyGem is created and distributed using
(replace 4.3.5 with the current version):

    BM_PACKAGE=1 gem build railroader.gemspec
    gem push railroader-4.3.5.gem

For more about gems, see: https://guides.rubygems.org/make-your-own-gem/
