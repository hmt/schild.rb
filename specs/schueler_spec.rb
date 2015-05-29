require "#{File.dirname(__FILE__)}/spec_helper"

describe Schueler do
  before do
    # lade einen Standardschueler
    @sm = Schueler.where(:Status => 2, :Geloescht => "-", :Gesperrt => "-").first
  end

  describe 'Models funktionieren erwartungsgemäß und geben einen Wert aus der Tabelle zurück' do
    it 'Model gibt Vornamen zurück' do
      @sm.Vorname.must_equal "Tanja"
    end
  end

  describe 'Associations funktionieren Erwartungsgemäß' do
    it 'geben Fachklassenbezeichnung zurück (eigeneschule_fachklassen:Fachklassen)' do
      @sm.fachklasse.Bezeichnung.must_equal "Friseur"
    end

    it 'geben Noten aus dem angegebenen Halbjahr und Jahr zurück (via Lernabschnitte und Leistungen)' do
      @sm.erstes_halbjahr(2013).noten.first.ID.must_equal 163701
    end

    it 'gibt Konferenzdatum zurück (Lernabschnitte)' do
      # offenbar keine in der Testdatenbank eingetragen
      # deshalb Default-Objekt anfordern
      @sm.erstes_halbjahr(2013).konferenzdatum.must_be_instance_of DateTime
    end

    it 'gibt berufsbezogene Fächer aus den angegebenen Lernabschnitten zurück' do
      @sm.zweites_halbjahr(2013).berufsbezogen.map{|n|n.fach.FachKrz}.must_include 'FF'
    end

    it 'gibt berufsübergreifende Fächer aus den angegebenen Lernabschnitten zurück' do
      @sm.zweites_halbjahr(2013).berufsuebergreifend.map{|n|n.fach.FachKrz}.must_include 'D'
    end

    it 'gibt Fächer aus dem Differenzierungsbereich zurück über angegebenen Lernabschnitt' do
      Schueler[394].erstes_halbjahr(2007).differenzierungsbereich.map{|n|n.fach.FachKrz}.must_include 'CHDIFF'
    end

    it 'gibt Fächer aus allen Fächergruppen zurück' do
      fg = @sm.zweites_halbjahr(2013).faechergruppen.flatten.count
      fg.must_equal (@sm.zweites_halbjahr(2013).noten.select{|n|n.AufZeugnis == '+'}).count
    end

    it 'gibt Zulassung zurück' do
      Schueler[166].bk_abschluss.zulassung?.must_equal true
      Schueler[19].bk_abschluss.zulassung?.must_equal false
    end

    it 'gibt Zulassung Berufsabschluss zurück' do
      Schueler[166].bk_abschluss.zulassung_ba?.must_equal true
      Schueler[19].bk_abschluss.zulassung_ba?.must_equal false
    end

    it 'gibt Berufsabschluss bestanden zurück' do
      Schueler[166].bk_abschluss.bestanden_ba?.must_equal true
      Schueler[19].bk_abschluss.bestanden_ba?.must_equal false
    end

    it 'gibt zurück, ob Fach schriftlich' do
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSTE"}.fach_schriftlich?.must_equal true
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSFK"}.fach_schriftlich?.must_equal false
    end

    it 'gibt zurück, ob Fach mündlich' do
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "M"}.fach_muendlich?.must_equal true
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSFK"}.fach_muendlich?.must_equal false
    end

    it 'gibt Note schriftlich zurück' do
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSTE"}.note_schriftlich.must_equal '3'
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSFK"}.note_schriftlich.must_equal ''
    end

    it 'gibt Note mündlich zurück' do
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "M"}.note_muendlich.must_equal '6'
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSFK"}.note_muendlich.must_equal ''
    end

    it 'gibt Abschlussnote zurück' do
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "M"}.note_abschluss.must_equal '5'
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSFK"}.note_abschluss.must_equal '3'
    end

    it 'gibt Abschlussfächer zurück' do
      Schueler[145].bk_abschluss_leistungen.find{|l|l.fach_krz == "GSTE"}.vornote.must_equal '4'
    end

    it 'gibt Abschlussnote als String zurück' do
      # note als Symbol
      Schueler[373].bk_abschluss_leistungen.find{|l|l.fach_krz == "M"}.note(:vornote).must_equal 'gut'
      # Note als String
      Schueler[381].bk_abschluss_leistungen.find{|l|l.fach_krz == "PB"}.note('note_abschluss_ba').must_equal 'mangelhaft'
    end
  end

  describe 'gibt die korrekte Anzahl von Schülern über Klasse zurück' do
    it 'returns a group of people eg Klasse xy' do
      Schueler.where(:Klasse => 'FOS2').count.must_equal 124
    end
  end

  describe 'Methoden funktionieren erwartungsgemäß' do
    it 'gibt korrekte Berufsbezeichnung nach Geschlecht zurück' do
      @sm.berufsbezeichnung_mw.must_include "in"
    end

    it 'gibt die korrekte Anrede zurück' do
      @sm.anrede.must_equal "Frau"
    end

    it 'gibt an, ob ein Schüler volljährig ist' do
      @sm.volljaehrig?.must_equal true
    end

    it 'gibt ein zusammengesetztes Datum des Schuljahres zurück' do
      @sm.schuljahr.must_equal "2014/15"
    end

    it 'gibt passende Bezeichnung Schüler oder Schülerin zurück' do
      @sm.schueler_in.must_equal "Schülerin"
      Schueler[24].schueler_in.must_equal "Schüler"
    end

    it 'gibt passende Bezeichnung Studierender oder Studierende zurück' do
      @sm.studierende_r.must_equal "Studierende"
      Schueler[24].studierende_r.must_equal "Studierender"
    end

    it 'gibt die Textbezeichnung für eine Note zurück' do
      @sm.zweites_halbjahr(2013).noten[5].note.must_equal "gut"
    end

    it 'gibt die Textbezeichnung auch bei ungeraden Noten zurück' do
      Schueler[178].erstes_halbjahr(2010).noten[0].note.must_equal "mangelhaft"
      Schueler[178].erstes_halbjahr(2010).noten[0].NotenKrz.must_equal "5-"
    end

    it 'gibt die volle Fachbezeichnung zurück' do
      @sm.zweites_halbjahr(2013).noten[5].bezeichnung.must_equal "Farb- und Formveränderung"
    end

    it 'gibt die korrekte Fachgruppen_ID zurück' do
      @sm.zweites_halbjahr(2013).noten[5].fachgruppe_ID.must_equal 20
    end

    it 'gibt den Namen des Klassenlehrers zurück' do
      @sm.zweites_halbjahr(2013).v_name_klassenlehrer.must_equal "P. Ronnewinkel"
    end

    it 'gibt an, ob Klassenlehrer/in' do
      @sm.zweites_halbjahr(2013).klassenlehrer_in.must_equal "Klassenlehrer"
    end

    it 'gibt das zweite Halbjahr zurück' do
      @sm.zweites_halbjahr(2013).Abschnitt.must_equal 2
      @sm.zweites_halbjahr(2013).Jahr.must_equal 2013
    end

    it 'gibt das erste Halbjahr zurück' do
      @sm.erstes_halbjahr(2014).Abschnitt.must_equal 1
      @sm.erstes_halbjahr(2014).Jahr.must_equal 2014
    end

    it 'gibt das aktuelle Halbjahr zurück' do
      @sm.akt_halbjahr.Jahr.must_equal 2014
      @sm.akt_halbjahr.Abschnitt.must_equal 1
    end

    it 'wählt das angegebene Jahr und Halbjahr aus' do
      @sm.halbjahr(2013, 2).ID.must_equal 14478
    end

    it 'gibt passendes Schuljahr zurück' do
      @sm.halbjahr(2013, 2).schuljahr.must_equal "2013/14"
    end
  end
end
