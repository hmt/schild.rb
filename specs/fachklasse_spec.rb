require "#{File.dirname(__FILE__)}/spec_helper"

describe Fachklasse do
  describe 'Assoziation' do
    it 'gibt ein Array von Schülern zurück' do
      Fachklasse.first.schueler.must_be_instance_of Array
    end
  end
end

