require "#{File.dirname(__FILE__)}/spec_helper"

describe Schueler do
  describe 'null-Objekte passen sich den DB-Typen an' do
    before do
      # lade einen Standardschueler
      @sm = Schueler.where(:Status => 2, :Geloescht => "-", :Gesperrt => "-").first
    end

    it 'gibt ein DateTime bei Daten zurück' do
      @sm.geburtsdatum.must_be_instance_of DateTime
    end

    it 'gibt String für Text zurück' do
      @sm.bemerkungen.must_be_instance_of String
    end

    it 'gibt 0 bei fehlendem Integer zurück' do
      Schueler[6176].erstes_halbjahr(2014).sum_fehl_std.must_equal 0
      Schueler[6176].erstes_halbjahr(2014).SumFehlStd.must_equal nil
    end
  end

  describe 'null-Objekte geben immer etwas zurück' do
    before do
      # lade einen Standardschueler
      @sm = Schueler.where(:Status => 2, :Geloescht => "-", :Gesperrt => "-").first
    end

    it 'gibt nil zurück, wenn leer' do
      @sm.Bemerkungen.must_equal nil
    end

    it 'gibt leeren String zurück, wenn leer und typensicher' do
      @sm.bemerkungen.must_equal ""
    end

    it 'gibt Fehler zurück, wenn Methode nicht existiert' do
      proc {@sm.bemerrrrrrrrrkungen}.must_raise NoMethodError
    end

    it 'gibt 1899 als Datum zurück, wenn strftime aufgerufen wird' do
      @sm.geburtsdatum.strftime("%Y").must_equal "1899"
    end

    it 'gibt nil zurück, wenn Geburtsdatum leer ist' do
      @sm.Geburtsdatum.must_equal nil
    end
  end
end

