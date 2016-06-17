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
      @sm.halbjahr(2013,1).noten.first.ID.must_equal 163701
    end

    it 'gibt Konferenzdatum zurück (Lernabschnitte)' do
      # offenbar keine in der Testdatenbank eingetragen
      # deshalb Default-Objekt anfordern
      @sm.halbjahr(2013,1).konferenzdatum.must_be_instance_of Time
    end

    it 'gibt berufsbezogene Fächer aus den angegebenen Lernabschnitten zurück' do
      @sm.halbjahr(2013,2).berufsbezogen.map{|n|n.fach.FachKrz}.must_include 'FF'
    end

    it 'gibt berufsübergreifende Fächer aus den angegebenen Lernabschnitten zurück' do
      @sm.halbjahr(2013,2).berufsuebergreifend.map{|n|n.fach.FachKrz}.must_include 'D'
    end

    it 'gibt Fächer aus dem Differenzierungsbereich zurück über angegebenen Lernabschnitt' do
      Schueler[394].halbjahr(2007,1).differenzierungsbereich.map{|n|n.fach.FachKrz}.must_include 'CHDIFF'
    end

    it 'gibt Fächer aus allen Fächergruppen zurück' do
      fg = @sm.halbjahr(2013,2).faechergruppen.flatten.count
      fg.must_equal (@sm.halbjahr(2013,2).noten.select{|n|n.AufZeugnis == '+'}).count
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

    it 'gibt Abschlussnote-BA zurück, wenn Abschlussnoten ohne Argumente angegeben wird' do
      Schueler[5346].bk_abschluss_leistungen.find{|l|l.fach_krz == "E"}.note(:vornote).must_equal 'ausreichend'
      Schueler[5346].bk_abschluss_leistungen.find{|l|l.fach_krz == "E"}.note.must_equal 'mangelhaft'
    end

    it 'gibt die Sprachfolge als Niveau zurück' do
      skip
      # in der Test-Datenbank sind keine Sprachenfolgen eingetragen, daher ist das RN ""
      Schueler[2072].halbjahr(2013,2).noten.find{|l|l.fach_id == 18}.fach.sprachenfolge.referenzniveau.must_equal ''
    end

    it 'gibt Vermerke für Schüler als Array zurück' do
      @sm.vermerke.must_be_instance_of Array
    end

    it 'gibt Vermerk als String zurück' do
      skip
      # Leider keine Vermerke in der Testdatenbank eingetragen
      @sm.vermerke.first.must_be_instance_of String
    end

    # in der Testdatenbank sind leider keine Schülerfotos
    it 'gibt das Schülerfoto als jpg zurück' do
      skip
      @sm.foto.must_be_instance_of String
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

    it 'gibt an, ob Schüler im Vergelich zu *datum* volljährig ist' do
      @sm.Geburtsdatum=Time.new(1990)
      @sm.volljaehrig_bei?(@sm.geburtsdatum).must_equal false
      @sm.volljaehrig_bei?(Time.now).must_equal true
    end

    it 'gibt zurück, ob ein Foto vorhanden ist' do
      @sm.foto_vorhanden?.must_equal false
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
      @sm.halbjahr(2013,2).noten[5].note.must_equal "gut"
    end

    it 'gibt die Textbezeichnung auch bei ungeraden Noten zurück' do
      Schueler[178].halbjahr(2010,1).noten[0].note.must_equal "mangelhaft"
      Schueler[178].halbjahr(2010,1).noten[0].NotenKrz.must_equal "5-"
    end

    it 'gibt die volle Fachbezeichnung zurück' do
      @sm.halbjahr(2013,2).noten[5].bezeichnung.must_equal "Farb- und Formveränderung"
    end

    it 'gibt die korrekte Fachgruppen_ID zurück' do
      @sm.halbjahr(2013,2).noten[5].fachgruppe_ID.must_equal 20
    end

    it 'gibt den Namen des Klassenlehrers zurück' do
      @sm.halbjahr(2013,2).v_name_klassenlehrer.must_equal "P. Ronnewinkel"
    end

    it 'gibt an, ob Klassenlehrer/in' do
      @sm.halbjahr(2013,2).klassenlehrer_in.must_equal "Klassenlehrer"
    end

    it 'gibt das zweite Halbjahr zurück' do
      @sm.halbjahr(2013,2).Abschnitt.must_equal 2
      @sm.halbjahr(2013,2).Jahr.must_equal 2013
    end

    it 'gibt das erste Halbjahr zurück' do
      @sm.halbjahr(2014,1).Abschnitt.must_equal 1
      @sm.halbjahr(2014,1).Jahr.must_equal 2014
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
