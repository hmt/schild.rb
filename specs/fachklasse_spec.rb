require "#{File.dirname(__FILE__)}/spec_helper"

describe Fachklasse do
  before do
    @f = Fachklasse.first
  end
  describe 'Assoziation' do
    it 'gibt ein Array von Schülern zurück' do
      @f.schueler.must_be_instance_of Array
    end
  end
end
