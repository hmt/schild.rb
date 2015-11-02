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

# Halten wir Protokoll zu den erstellten Methoden
# Ist brauchbar, wenn man z.B. noch extremer als der SchildTypeSaver arbeiten möchte
module MethodLogger
  class Methods
    @@accessor_methods = {}

    def self.add(klass, meth)
      @@accessor_methods[klass] ||= []
      @@accessor_methods[klass] << meth
    end

    def self.list(klass)
      @@accessor_methods[klass]
    end
  end
end

# Schild hat teilweise nil in DB-Feldern. SchildTypeSaver gibt entweder einen
# Leer-String zurück ("") oder bei strftime das 1899 Datum zurück.
module SchildTypeSaver
  Symbol.include CoreExtensions::Symbol
  String.include CoreExtensions::String

  # bei include wird für jede Spalte in der Schild-Tabelle eine Ersatzmethode
  # erstellt, die bei nil ein Null-Objekt erstellt.
  def self.included(klass)
    klass.columns.each do |column|
      name = column.snake_case
      MethodLogger::Methods.add(klass, name)
      # allow_nil ist als Argument optional und lässt bei +true+ alle Ergebnisse durch
      define_method(name) do |allow_nil=false|
        ret = public_send(column)
        if allow_nil || ret
          ret
        else
         create_null_object(klass, column)
        end
      end
    end
  end

  def create_null_object(klass, column)
    k = DB.schema_type_class(klass.db_schema[column][:type])
    if k.class == Array
      # Sequel stellt :datetime als [Time, DateTime] dar, deswegen die Abfrage nach Array
      # Schild verwendet Time Objekte, wir machen das auch
      Time.new(1899)
    elsif k == Integer
      0
    else
      # alle anderen types werden als Klasse zurückgegeben
      k.new
    end
  end
end

# Mixin für Notenbezeichnungen
module NotenHelfer
  # Notenbezeichnung als String
  def note_s(ziffer)
    case ziffer
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
      "––––––"
    when "E1"
      "mit besonderem Erfolg teilgenommen"
    when "E2"
      "mit Erfolg teilgenommen"
    when 'E3'
      "teilgenommen"
    end
  end
end

# Das Schild Modul, das alle Klassen für die Datenbankanbindung bereitstellt
module Schild
  # ist die Datenbank-Verbindung. Alle Daten können über diese Konstante abgerufen werden
  DB = Sequel.connect("#{ENV['S_ADAPTER']}://#{ENV['S_HOST']}/#{ENV['S_DB']}?user=#{ENV['S_USER']}&password=#{ENV['S_PASSWORD']}")

  # Stellt die Schüler-Tabelle samt Assoziationen bereit.
  class Schueler < Sequel::Model(:schueler)
    many_to_one :fachklasse, :class => :Fachklasse, :key => :Fachklasse_ID
    one_to_many :abschnitte, :class => :Abschnitt
    one_to_one :bk_abschluss, :class => :BKAbschluss
    one_to_many :bk_abschluss_leistungen, :class => :BKAbschlussFaecher
    one_to_one :abi_abschluss, :class => :AbiAbschluss
    one_to_many :abi_abschluss_leistungen, :class => :AbiAbschlussFaecher
    one_to_many :vermerke, :class => :Vermerke
    one_to_one :schuelerfoto, :class => :Schuelerfotos
  end

  # Dient als Assoziation für Schüler und deren Klassenbezeichnung etc.
  class Fachklasse < Sequel::Model(:eigeneschule_fachklassen)
    one_to_many :schueler
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
  end

  # Assoziation für Noten
  class Noten < Sequel::Model(:schuelerleistungsdaten)
    many_to_one :abschnitt, :class => :Abschnitt, :key => :Abschnitt_ID
    many_to_one :fach, :class => :Faecher, :key => :Fach_ID
  end

  # Assoziation für Fächer
  class Faecher < Sequel::Model(:eigeneschule_faecher)
    #siehe abi_...
    one_to_one :noten
    one_to_many :abi_abschluss_leistungen
    one_to_one :sprachenfolge, :class => :Sprachenfolge, :key => :Fach_ID
  end

  # Assoziation für BK-Abschluss des Schülers
  class BKAbschluss < Sequel::Model(:schuelerbkabschluss)
    one_to_one :schueler
  end

  # Assoziation für die Prüfungsfächer des Schülers
  class BKAbschlussFaecher < Sequel::Model(:schuelerbkfaecher)
    many_to_one :schueler
  end

  # Assoziation für Abi-Abschluss des Schülers
  class AbiAbschluss < Sequel::Model(:schuelerabitur)
    one_to_one :schueler
  end

  # Assoziation für die Abifächer des Schülers
  class AbiAbschlussFaecher < Sequel::Model(:schuelerabifaecher)
    many_to_one :schueler
    many_to_one :fach, :class => :Faecher, :key => :Fach_ID
  end

  # Assoziation für die bisher erreichten Sprachniveaus
  class Sprachenfolge < Sequel::Model(:schuelersprachenfolge)
    one_to_one :Faecher
  end

  # Vermerke von Schülern
  class Vermerke < Sequel::Model(:schuelervermerke)
    many_to_one :Schueler
  end

  # Schülerfotos als jpg
  class Schuelerfotos < Sequel::Model(:schuelerfotos)
    one_to_one :schueler
  end

  # Schul-Tabelle
  class Schule < Sequel::Model(:eigeneschule)
  end

  # Tabelle für Schild-Nutzer
  class Nutzer < Sequel::Model(:users)
  end
end

module SchildErweitert
  include Schild
  # Stellt die Schüler-Tabelle samt Assoziationen bereit.
  class Schueler < Schild::Schueler
    include SchildTypeSaver

    # gibt das z.Zt. aktuelle Halbjahr zurück.
    def akt_halbjahr
      abschnitte.last
    end

    # gibt aus +jahr+ das Halbjahr +1+ oder +2+ zurück.
    def halbjahr(jahr, abschnitt)
      abschnitte_dataset.where(:jahr => jahr, :abschnitt => abschnitt).first
    end

    # gibt +Herr+ oder +Frau+ als Anrede für Schüler zurück.
    def anrede
      self.geschlecht == 3 ? "Herr" : "Frau"
    end

    # gibt die passende Bezeichnung zurück Schüler
    def schueler_in
      self.geschlecht == 3 ? "Schüler" : "Schülerin"
    end

    # gibt die passende Bezeichnung zurück Studierende
    def studierende_r
      self.geschlecht == 3 ? "Studierender" : "Studierende"
    end

    # gibt die jeweilige Berufsbezeichnung nach Geschlecht zurück.
    def berufsbezeichnung_mw
      self.geschlecht == 3 ? self.fachklasse.bezeichnung : self.fachklasse.beschreibung_w
    end

    # gibt +true+ zurück, wenn Schüler volljährig.
    def volljaehrig?
      self.volljaehrig == "+"
    end

    # gibt an, ob der Schüler zu einem Zeitpunkt *datum* volljährig war.
    def volljaehrig_bei?(datum)
      geb, datum = self.geburtsdatum.to_date, datum.to_date
      (datum.year - geb.year - ((datum.month > geb.month || (datum.month == geb.month && datum.day >= geb.day)) ? 0 : 1)) >= 18
    end

    # fragt ab, ob in Schild ein Foto als hinterlegt eingetragen ist.
    def foto_vorhanden?
      self.foto_vorhanden == "+"
    end

    # gibt, wenn vorhanden, ein Foto als jpg-String zurück, ansonsten nil.
    def foto
      self.foto_vorhanden? ? self.schuelerfoto.foto : nil
    end
  end

  # Dient als Assoziation für Schüler und deren Klassenbezeichnung etc.
  class Fachklasse < Schild::Fachklasse
    include SchildTypeSaver
  end

  # Assoziation für Lehrer, hauptsächlich für Klassenlehrer
  class Klassenlehrer < Schild::Klassenlehrer
    include SchildTypeSaver
  end

  # Ist die Assoziation, die Halbjahre, sog. Abschnitte zurückgibt.
  class Abschnitt < Schild::Abschnitt
    include SchildTypeSaver

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
      noten.select{ |n| n.fach.Fachgruppe_ID == id && n.AufZeugnis == '+' }.sort_by{ |n| n.fach.SortierungS2 }
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
      v = klassenlehrer.vorname
      n = klassenlehrer.nachname
      "#{v[0]}. #{n}"
    end

    # gibt "Klassenlehrer" entsprechend Geschlecht zurück
    def klassenlehrer_in
      klassenlehrer.geschlecht == "3" ? "Klassenlehrer" : "Klassenlehrerin"
    end

    # gibt das aktuelle Schuljahr als String im Format "2014/15" zurück.
    def schuljahr
      jahr = self.jahr
      "#{jahr}/#{jahr-1999}"
    end
  end

  # Assoziation für Noten
  class Noten < Schild::Noten
    include SchildTypeSaver
    include NotenHelfer

    # note in String umwandeln
    def note
      note_s self.noten_krz
    end

    # Bezeichnung des Fachs
    def bezeichnung
      fach.bezeichnung
    end

    # Die Fachgruppen ID des Fachs
    def fachgruppe_ID
      fach.fachgruppe_id
    end
  end

  # Assoziation für Fächer
  class Faecher < Schild::Faecher
    include SchildTypeSaver
  end

  # Assoziation für BK-Abschlussdaten
  class BKAbschluss < Schild::BKAbschluss
    include SchildTypeSaver

    # Ist der Schüler zugelassen?
    def zulassung?
      self.Zulassung == "+"
    end

    # Ist der Schüler für den Berufsabschluss zugelassen?
    def zulassung_ba?
      self.ZulassungBA == "+"
    end

    # Hat der Schüler den Berufsabschluss bestanden?
    def bestanden_ba?
      self.BestandenBA == "+"
    end
  end

  # Assoziation für die jeweiligen BK-Prüfungsfächer
  class BKAbschlussFaecher < Schild::BKAbschlussFaecher
    include SchildTypeSaver
    include NotenHelfer

    # Wurde das Fach schriftlich geprüft?
    def fach_schriftlich?
      self.FachSchriftlich == "+"
    end

    # Wurde das Fach mündlich geprüft?
    def fach_muendlich?
      self.MdlPruefung == "+"
    end

    def note(notenart=:note_abschluss_ba)
      note_s send(notenart)
    end
  end

  # Assoziation für Abi-Abschlussdaten
  class AbiAbschluss < Schild::AbiAbschluss
    include SchildTypeSaver
  end

  # Assoziation für die jeweiligen Abi-Prüfungsfächer
  class AbiAbschlussFaecher < Schild::AbiAbschlussFaecher
    include SchildTypeSaver
    include NotenHelfer

    def note(notenart)
      note_s send(notenart)
    end
  end

  class Sprachenfolge < Schild::Sprachenfolge
    include SchildTypeSaver
  end

  class Vermerke < Schild::Vermerke
    include SchildTypeSaver
  end

  class Schuelerfotos < Schild::Schuelerfotos
    include SchildTypeSaver
  end

  # Schul-Tabelle mit vereinfachtem Zugriff auf Datenfelder.
  class Schule < Schild::Schule
    include SchildTypeSaver

    # gibt die Schulnummer zurück
    def self.schulnummer
      self.first.schul_nr
    end

    def self.v_name_schulleiter
      "#{self.first.schulleiter_vorname[0]}. #{self.first.schulleiter_name}"
    end

    def self.schulleiter_in
      self.first.schulleiter_geschlecht == 3 ? "Schulleiter" : "Schulleiterin"
    end

    def self.ort
      self.first.ort
    end
  end

  # Tabelle der Schuld-Benutzer zum Abgleichen der Daten
  class Nutzer < Schild::Nutzer
    include SchildTypeSaver

    def name
      self.us_name
    end

    def login
      self.us_login_name
    end

    def passwort
      self.us_password
    end
    alias :password :passwort

    def passwort?(passwort='')
      crypt(passwort) == self.passwort
    end
    alias :password? :passwort?

    def crypt(passwort)
      passwort.codepoints.map{|c| ((c/16)*32+15-c).chr}.join('')
    end
  end
end

