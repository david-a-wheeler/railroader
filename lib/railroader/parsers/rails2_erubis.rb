Railroader.load_railroader_dependency 'erubis'

# Erubis processor which ignores any output which is plain text.
class Railroader::ScannerErubis < Erubis::Eruby
  include Erubis::NoTextEnhancer
end
