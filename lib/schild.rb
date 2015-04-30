require 'schild/version'
require 'sequel'

# erst Ruby 2.1.0 macht include zu einer public-Methode
if Module.private_method_defined? :include
  class Module
    public :include
  end
end

# String und Symbol werden um snake_case ergänzt, das die Schild-Tabellen umbenennt
module CoreExtensions
  module String
    def snake_case
      return downcase if match(/\A[A-Z]+\z/)
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z])([A-Z])/, '\1_\2').
        downcase
    end
  end

  module Symbol
    def snake_case
      to_s.snake_case
    end
  end
end

# Schild hat teilweise nil in DB-Feldern. SchildTypeSaver gibt entweder einen
# "Fehlt"-String zurück oder bei strftime das 1899 Datum zurück.
module SchildTypeSaver
  Symbol.include CoreExtensions::Symbol
  String.include CoreExtensions::String

  # bei include wird für jede Spalte in der Schild-Tabelle eine Ersatzmethode
  # erstellt, die bei nil ein Null-Objekt erstellt.
  def self.included(klass)
    klass.columns.each do  |column|
      name = column.snake_case
      define_method(name) { public_send(column) || create_null_object(klass, column)}
    end
  end

  def create_null_object(klass, column)
    k = DB.schema_type_class(klass.db_schema[column][:type])
    if k.class == Array
      # Sequel stellt :datetime als [Time, DateTime] dar
      DateTime.new(1899)
    elsif k == Integer
      0
    else
      # alle anderen types werden als Klasse zurückgegeben
      k.new
    end
  end
end

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
    include SchildTypeSaver

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

    # gibt die passende Bezeichnung zurück Schüler
    def schueler_in
      self.Geschlecht == 3 ? "Schüler" : "Schülerin"
    end

    # gibt die passende Bezeichnung zurück Studierende
    def studierende_r
      self.Geschlecht == 3 ? "Studierender" : "Studierende"
    end

    # gibt die jeweilige Berufsbezeichnung nach Geschlecht zurück.
    def berufsbezeichnung_mw
      self.geschlecht == 3 ? self.fachklasse.bezeichnung : self.fachklasse.beschreibung_w
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
    include SchildTypeSaver

    one_to_many :schueler
  end

  # Assoziation für Lehrer, hauptsächlich für Klassenlehrer
  class Klassenlehrer < Sequel::Model(:k_lehrer)
    include SchildTypeSaver

    one_to_one :abschnitt, :primary_key=>:Kuerzel, :key=>:KlassenLehrer
  end

  # Ist die Assoziation, die Halbjahre, sog. Abschnitte zurückgibt.
  class Abschnitt < Sequel::Model(:schuelerlernabschnittsdaten)
    include SchildTypeSaver

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

    # gibt das aktuelle Schuljahr als String im Format "2014/15" zurück.
    def schuljahr
      jahr = self.Jahr
      "#{jahr}/#{jahr-1999}"
    end
  end

  # Assoziation für Noten
  class Noten < Sequel::Model(:schuelerleistungsdaten)
    include SchildTypeSaver

    many_to_one :abschnitt, :class => :Abschnitt, :key => :Abschnitt_ID
    many_to_one :fach, :class => :Faecher, :key => :Fach_ID

    # Notenbezeichnung als String
    def note
      case self.NotenKrz
      when "1", "1+", "1-"
        "sehr gut"
      when "2", "2+", "2-"
        "gut"
      when "3", "3+", "3-"
        "befriedigend"
      when "4", "4+", "4-"
        "ausreichend"
      when "5", "5+", "5-"
        "mangelhaft"
      when "6"
        "ungenügend"
      when 'NB'
        "----------"
      when "E1"
        "mit besonderem Erfolg teilgenommen"
      when "E2"
        "mit Erfolg teilgenommen"
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
    include SchildTypeSaver

    one_to_one :noten
  end

  # Schul-Tabelle mit vereinfachtem Zugriff auf Datenfelder.
  class Schule < Sequel::Model(:eigeneschule)
    include SchildTypeSaver

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

