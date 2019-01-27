require_relative '../test'
require 'railroader/warning'

class WarningTests < Minitest::Test
  def test_confidence_symbols
    [:high, :med, :medium, :low, :weak].each do |c|
      w = Railroader::Warning.new(confidence: c) 
      assert_equal Railroader::Warning::CONFIDENCE[c], w.confidence
    end
  end

  def test_confidence_integers
    [0, 1, 2].each do |c|
      w = Railroader::Warning.new(confidence: c) 
      assert_equal c, w.confidence
    end
  end

  def test_bad_confidence_symbol
    assert_raises do
      Railroader::Warning.new(confidence: :blah)
    end
  end

  def test_bad_confidence_integer
    assert_raises do
      Railroader::Warning.new(confidence: 10)
    end
  end
end
