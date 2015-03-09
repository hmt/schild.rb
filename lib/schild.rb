require "schild/version"
require 'sequel'

# Das Schild Modul, das alle Klassen für die Datenbankanbindung bereitstellt
module Schild

  # ist die Datenbank-Verbindung. Alle Daten können über diese Konstante abgerufen werden
  DB = Sequel.connect(:adapter=>ENV['S_ADAPTER'], :host=>ENV['S_HOST'], :user=>ENV['S_USER'], :password=>ENV['S_PASSWORD'], :database=>ENV['S_DB'])

  # Stellt eine Verbindung zu einem Schild-Server her. Sollte nur aufgerufen werden, wenn wechselnde Verbindungen nötig sind.
  def self.connect
    Sequel.connect(:adapter=>ENV['S_ADAPTER'], :host=>ENV['S_HOST'], :user=>ENV['S_USER'], :password=>ENV['S_PASSWORD'], :database=>ENV['S_DB'])
  end

  # Stellt die Schüler-Tabelle samt Assoziationen bereit.
  class Schueler < Sequel::Model(:schueler)
    many_to_one :fachklasse, :class => :Fachklasse, :key => :Fachklasse_ID
    one_to_many :abschnitte, :class => :Abschnitt

    # gibt das z.Zt. aktuelle Halbjahr zurück.
    def akt_halbjahr
      abschnitte.last
    end

    # gibt das erste Halbjahr von +jahr+ zurück.
    def erstes_halbjahr(jahr)
      halbjahr(jahr, 1)
    end

    # gibt das zweite Halbjahr von +jahr+ zurück.
    def zweites_halbjahr(jahr)
      halbjahr(jahr, 2)
    end

    # gibt aus +jahr+ das Halbjahr +1+ oder +2+ zurück.
    def halbjahr(jahr, abschnitt)
      abschnitte_dataset.where(:jahr => jahr, :abschnitt => abschnitt).first
    end

    # gibt +Herr+ oder +Frau+ als Anrede für Schüler zurück.
    def anrede
      if self.Geschlecht == 3
        return "Herr"
      elsif self.Geschlecht == 4
        return "Frau"
      end
    end

    # gibt +true+ zurück, wenn Schüler volljährig.
    def volljaehrig?
      self.Volljaehrig == "+"
    end

    # gibt das aktuelle Schuljahr als String im Format "2014/15" zurück.
    def schuljahr
      jahr = self.AktSchuljahr
      "#{jahr}/#{jahr-1999}"
    end
  end

  # Dient als Assoziation für Schüler und deren Klassenbezeichnung etc.
  class Fachklasse < Sequel::Model(:eigeneschule_fachklassen)
    one_to_one :schueler
  end

  # Assoziation für Lehrer, hauptsächlich für Klassenlehrer
  class Klassenlehrer < Sequel::Model(:k_lehrer)
    one_to_one :abschnitt, :primary_key=>:Kuerzel, :key=>:KlassenLehrer
  end

  # Ist die Assoziation, die Halbjahre, sog. Abschnitte zurückgibt.
  class Abschnitt < Sequel::Model(:schuelerlernabschnittsdaten)
    many_to_one :schueler, :class => :Schueler, :key => :Schueler_ID
    one_to_many :noten, :class => :Noten
    many_to_one :klassenlehrer, :class => :Klassenlehrer, :primary_key=>:Kuerzel, :key=>:KlassenLehrer

    dataset_module do
      # filtert den Datensatz nach Jahr
      def jahr(i)
        where(:Jahr => i)
      end

      # filtert den Datensatz nach Halbjahr
      def halbjahr(i,j)
        jahr(i).where(:Abschnitt => j)
      end

      # filtert und gibt den Datensatz als Abschnitt des aktuellen Halbjahrs zurück
      def akt_halbjahr
        halbjahr(Time.new.year-1, 1).first
      end
    end

    # Hilfsmethode für die folgenden Methoden
    def faecher_nach_id(id)
      noten.sort_by{ |n| n.fach.SortierungS2 }.select{ |n| n.fach.Fachgruppe_ID == id && n.AufZeugnis == '+' }
    end

    # wählt alle berufsübergreifenden Fächer des gewählten Schülers in angegeben Halbjahr.
    def berufsuebergreifend
      faecher_nach_id 10
    end

    # wählt alle berufsbezogenen Fächer des gewählten Schülers in angegeben Halbjahr.
    def berufsbezogen
      faecher_nach_id 20
    end

    # wählt alle Fächer des Differenzierungsbreichs des gewählten Schülers in angegeben Halbjahr.
    def differenzierungsbereich
      faecher_nach_id 30
    end

    # wählt alle Fächergruppen aus.
    def faechergruppen
      [berufsuebergreifend, berufsbezogen, differenzierungsbereich]
    end

    # gibt den Namen des Klassenlehrers mit gekürztem Vornamen.
    def v_name_klassenlehrer
      v = klassenlehrer.Vorname
      n = klassenlehrer.Nachname
      "#{v[0]}. #{n}"
    end

    # gibt "Klassenlehrer" entsprechend Geschlecht zurück
    def klassenlehrer_in
      klassenlehrer.Geschlecht == "3" ? "Klassenlehrer" : "Klassenlehrerin"
    end
  end

  # Assoziation für Noten
  class Noten < Sequel::Model(:schuelerleistungsdaten)
    many_to_one :abschnitt, :class => :Abschnitt, :key => :Abschnitt_ID
    many_to_one :fach, :class => :Faecher, :key => :Fach_ID

    # Notenbezeichnung als String
    def note
      case self.NotenKrz
      when "1"
        "sehr gut"
      when "2"
        "gut"
      when "3"
        "befriedigend"
      when "4"
        "ausreichend"
      when "5"
        "mangelhaft"
      when "6"
        "ungenügend"
      when 'NB'
        "----------"
      when 'E3'
        "teilgenommen"
      end
    end

    # Bezeichnung des Fachs
    def bezeichnung
      fach.Bezeichnung
    end

    # Die Fachgruppen ID des Fachs
    def fachgruppe_ID
      fach.Fachgruppe_ID
    end
  end

  # Assoziation für Fächer
  class Faecher < Sequel::Model(:eigeneschule_faecher)
    one_to_one :noten
  end

  # Schul-Tabelle mit vereinfachtem Zugriff auf Datenfelder.
  class Schule < Sequel::Model(:eigeneschule)
    # gibt die Schulnummer zurück
    def self.schulnummer
      self.first.SchulNr
    end

    def self.v_name_schulleiter
      "#{self.first.SchulleiterVorname[0]}. #{self.first.SchulleiterName}"
    end

    def self.schulleiter_in
      self.first.SchulleiterGeschlecht == 3 ? "Schulleiter" : "Schulleiterin"
    end

    def self.ort
      self.first.Ort
    end
  end
end

