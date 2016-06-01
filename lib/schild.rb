require 'schild/version'
require 'sequel'

# Das Schild Modul, das alle Klassen für die Datenbankanbindung bereitstellt
module Schild
  # ist die Datenbank-Verbindung. Alle Daten können über diese Konstante abgerufen werden

  @db = Sequel.connect("#{ENV['S_ADAPTER']}://#{ENV['S_HOST']}/#{ENV['S_DB']}?user=#{ENV['S_USER']}&password=#{ENV['S_PASSWORD']}&zeroDateTimeBehavior=convertToNull")

  def self.connect
    @db = Sequel.connect("#{ENV['S_ADAPTER']}://#{ENV['S_HOST']}/#{ENV['S_DB']}?user=#{ENV['S_USER']}&password=#{ENV['S_PASSWORD']}&zeroDateTimeBehavior=convertToNull")
  end

  def self.db
    @db
  end

  # Stellt die Schüler-Tabelle samt Assoziationen bereit.
  class Schueler < Sequel::Model(:schueler)
    many_to_one :fachklasse, :class => :Fachklasse, :key => :Fachklasse_ID
    one_to_many :abschnitte, :class => :Abschnitt
    one_to_one :bk_abschluss, :class => :BKAbschluss
    one_to_many :bk_abschluss_leistungen, :class => :BKAbschlussFaecher
    one_to_one :abi_abschluss, :class => :AbiAbschluss
    one_to_many :abi_abschluss_leistungen, :class => :AbiAbschlussFaecher
    one_to_one :fhr_abschluss, :class => :FHRAbschluss
    one_to_many :fhr_abschluss_leistungen, :class => :FHRAbschlussFaecher
    one_to_many :vermerke, :class => :Vermerke
    one_to_one :schuelerfoto, :class => :Schuelerfotos
    one_to_many :sprachenfolge, :class => :Sprachenfolge
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

  # Assoziation für FHR-Abschluss des Schülers
  class FHRAbschluss < Sequel::Model(:schuelerfhr)
    one_to_one :schueler
  end

  # Assoziation für die FHR-fächer des Schülers
  class FHRAbschlussFaecher < Sequel::Model(:schuelerfhrfaecher)
    many_to_one :schueler
    many_to_one :fach, :class => :Faecher, :key => :Fach_ID
  end

  # Assoziation für die bisher erreichten Sprachniveaus
  class Sprachenfolge < Sequel::Model(:schuelersprachenfolge)
    many_to_one :fach, :class => :Faecher, :key => :Fach_ID
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
  # erst Ruby 2.1.0 macht include zu einer public-Methode
  if Module.private_method_defined? :include
    class Module
      public :include
    end
  end

  # String und Symbol werden um snake_case ergänzt, das die Schild-Tabellen umbenennt
  # Legacy-Methoden aus alten Schild-Versionen wird teilweise auch unterstützt.
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

    module Schueler
      def entlassart
        return self.entlass_art if self.respond_to?(:entlass_art)
      end
    end

    module Fachklasse
      def dqr_niveau
        return self.DQR_Niveau if self.respond_to?(:DQR_Niveau)
        "Alte Schild-Version ohne DQR-Niveau"
      end
    end
  end

  # Schild hat teilweise nil in DB-Feldern. SchildTypeSaver gibt entweder einen
  # Leer-String zurück ("") oder bei strftime das 1899 Datum zurück.
  module SchildTypeSaver
    Symbol.include SchildErweitert::CoreExtensions::Symbol
    String.include CoreExtensions::String

    # bei include wird für jede Spalte in der Schild-Tabelle eine Ersatzmethode
    # erstellt, die bei nil ein Null-Objekt erstellt.
    def self.included(klass)
      klass.columns.each do |column|
        name = column.snake_case
        MethodLogger::Methods.add(klass, name)
        # allow_nil ist als Argument optional und lässt bei +true+ alle Ergebnisse durch
        define_method(("_"+name.to_s).to_sym) {public_send(column)}
        define_method(name) do |allow_nil=false|
          ret = public_send(column)
          if allow_nil || ret
            ret = ret.strip if ret.class == String
            ret
          else
            create_null_object(klass, column)
          end
        end
      end
    end

    def create_null_object(klass, column)
      k = Schild.db.schema_type_class(klass.db_schema[column][:type])
      if k.class == Array
        # Sequel stellt :datetime als [Time, DateTime] dar, deswegen die Abfrage nach Array
        # Schild verwendet Time Objekte, wir machen das auch
        Time.new(1899)
      elsif k == Integer
        0
      elsif k == Float
        0.0
      else
        # alle anderen types werden als Klasse zurückgegeben
        k.new
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

  # Mixin für Notenbezeichnungen
  module NotenHelfer
    # Noten können als Punkte abgerufen werden:
    # note[5] => "4-"
    # oder auch andersherum: note.index("4-") => 5
    @note = %w[6 5- 5 5+ 4- 4 4+ 3- 3 3+ 2- 2 2+ 1- 1 1+]

    def self.punkte_aus_note(note)
      return if note.nil?
      @note.index(note)
    end

    def self.note_aus_punkten(punkte)
      return unless punkte && punkte.to_i.between?(1,15) || punkte == "0"
      return punkte if ((punkte.to_i == 0) && (punkte.size > 1))
      return if (punkte.class == String) && punkte.empty?
      @note[punkte.to_i]
    end

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

  # Klassen sind Konstanten. Deswegen alle auslesen, die Klassen behalten und
  # dynamisch neue Klassen mit gleichem Namen erstellen.
  # Automatisch SchildTypeSaver einbinden.
  #
  # Sollen zusätzliche Methoden eingebunden werden, muss - wie unten Schueler
  # und andere Klassen - die neu erstelle Klasse gepatcht werden.
  # Die alten Methoden bleiben erhalten, d.h. auch die TypeSaver-Methoden.
  Schild.constants.map {|name| Schild.const_get(name)}.select {|o| o.is_a?(Class)}.each do |klass|
    name = Schild.const_get(klass.to_s).name.split("::").last
    klass = Class.new(klass) do
      include SchildTypeSaver
    end
    name = const_set(name, klass)
  end

  Fachklasse.include CoreExtensions::Fachklasse
  Schueler.include CoreExtensions::Schueler

  # Stellt die Schüler-Tabelle samt Assoziationen bereit.
  class Schueler
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
      return "Keine Fachklasse zugeordnet" if self.fachklasse.nil?
      self.geschlecht == 3 ? self.fachklasse.bezeichnung : self.fachklasse.beschreibung_w
    end

    # gibt +true+ zurück, wenn Schüler volljährig.
    def volljaehrig?
      self.volljaehrig == "+"
    end

    # gibt an, ob der Schüler zu einem Zeitpunkt *datum* volljährig war.
    def volljaehrig_bei?(datum)
      return false if datum.nil? || self.Geburtsdatum.nil?
      geb, datum = self.Geburtsdatum.to_date, datum.to_date
      (datum.year - geb.year - ((datum.month > geb.month || (datum.month == geb.month && datum.day >= geb.day)) ? 0 : 1)) >= 18
    end

    # fragt ab, ob in Schild ein Foto als hinterlegt eingetragen ist.
    def foto_vorhanden?
      !!(self.schuelerfoto && self.schuelerfoto.foto)
    end

    # gibt, wenn vorhanden, ein Foto als jpg-String zurück, ansonsten nil.
    def foto
      self.schuelerfoto.foto if self.foto_vorhanden?
    end
  end

  # Ist die Assoziation, die Halbjahre, sog. Abschnitte zurückgibt.
  class Abschnitt
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
      return "Kein Klassenlehrer angelegt" if klassenlehrer.nil?
      v = klassenlehrer.vorname
      n = klassenlehrer.nachname
      "#{v[0]}. #{n}"
    end

    # gibt "Klassenlehrer" entsprechend Geschlecht zurück
    def klassenlehrer_in
      return "Kein Klassenlehrer angelegt" if klassenlehrer.nil?
      klassenlehrer.geschlecht == "3" ? "Klassenlehrer" : "Klassenlehrerin"
    end

    # gibt das aktuelle Schuljahr als String im Format "2014/15" zurück.
    def schuljahr
      jahr = self.jahr
      "#{jahr}/#{jahr-1999}"
    end
  end

  # Assoziation für Noten
  class Noten
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


  # Assoziation für BK-Abschlussdaten
  class BKAbschluss
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
  class BKAbschlussFaecher
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
  class AbiAbschluss
    # Ist der Schüler zugelassen?
    def zulassung?
      self.Zugelassen == "+"
    end
    alias_method :zugelassen?, :zulassung?

    # Hat der Schüler die Abi-Prüfung bestanden?
    def bestanden_abi?
      self.PruefungBestanden == "+"
    end
    alias_method :pruefung_bestanden?, :bestanden_abi?

    def latinum?
      self.Latinum == "+"
    end

    def kl_latinum?
      self.KlLatinum == "+"
    end

    def graecum?
      self.Graecum == "+"
    end

    def hebraicum?
      self.Hebraicum == "+"
    end
  end

  # Assoziation für die jeweiligen Abi-Prüfungsfächer
  class AbiAbschlussFaecher
    include NotenHelfer

    def note(notenart)
      note_s send(notenart)
    end
  end

  # Assoziation für die jeweiligen FHR-Prüfungsfächer
  class FHRAbschlussFaecher
    include NotenHelfer

    def note(notenart)
      note_s send(notenart)
    end
  end

  # Schul-Tabelle mit vereinfachtem Zugriff auf Datenfelder mittel class-Methoden
  class Schule
    # gibt die Schulnummer zurück
    def self.schulnummer
      self.first.schul_nr
    end

    # gibt den Namen des Schulleiters als V. Name zurück
    def self.v_name_schulleiter
      "#{self.first.schulleiter_vorname[0]}. #{self.first.schulleiter_name}"
    end

    # gibt die männliche bzw. weibliche Form des Schulleiters zurück
    def self.schulleiter_in
      self.first.schulleiter_geschlecht == 3 ? "Schulleiter" : "Schulleiterin"
    end

    # gibt den Ort der Schule zurück
    def self.ort
      self.first.ort
    end
  end

  # Tabelle der Schuld-Benutzer zum Abgleichen der Daten
  class Nutzer
    alias :name :us_name
    alias :login :us_login_name
    alias :passwort :us_password
    alias :password :passwort

    # prüft, ob das angegebene Passwort mit dem gespeicherten Passwort übereinstimmt
    def passwort?(passwort='')
      crypt(passwort) == self.passwort
    end
    alias :password? :passwort?

    # ver- bzw. entschlüsselt einen String mit dem Schild-Passwortalgorithmus
    def crypt(passwort)
      passwort.codepoints.map{|c| ((c/16)*32+15-c).chr}.join('')
    end
  end
end

