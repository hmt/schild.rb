require "#{File.dirname(__FILE__)}/spec_helper"

describe Schule do
  describe 'methods' do
    it 'gibt die Schulnummer zurück' do
      Schule.schulnummer.must_be_instance_of String
    end
  end
end

