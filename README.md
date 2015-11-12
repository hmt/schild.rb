# schild

[Schild-NRW](http://www.svws.nrw.de/index.php?id=schildnrw) ist die offizielle Schulverwaltungssoftware in NRW, `schild` ein Ruby-Gem, das als API zwischen der Schild-NRW-Datenbank und eigenen Skripten fungieren kann. `schild` ermöglicht es, direkt und ohne die Schild-Oberfläche auf Daten zuzugreifen und für eigene Zwecke weiterzuverarbeiten, z.B. um eigene Dokumente (Reports/Berichte in Schild-Sprech genannt) zu erstellen.

Mit `schild` kann man eigene Skripte schreiben und komfortabel auf die Datenbank zugreifen. Kenntnisse in der Programmiersprache Ruby sind allerdings notwendig.

Um `schild` nutzen zu können muss es zuerst installiert werden:

```sh
gem install schild
```

Dazu muss ein Datenbankadapter installiert werden. Da in den meisten Fällen MySQL/MariaDB verwendet wird, kann dies so gemacht werden:

```sh
gem install mysql2
```

Falls es nicht klappt und Fehlermeldungen auftauchen. liegt es meist daran, dass neben dem Server auch die Entwicklerbibliotheken isntalliert sein müssen. `mysql-dev` oder ähnlich genannt. Das hängt vom jeweils verwendeten Betriebssystem ab.

Jetzt kann `schild` in einem Skript aufgerufen werden:

```ruby
require 'schild'
```
Da `schild` eine Datenbankverbindung zur Schild-Datenbank herstellen muss, werden noch ein paar Angaben gebraucht. `schild` verwendet dafür sog. Environment-Variablen. Unter Linux sehen die so aus:

```sh
export S_USER=schild
```

Mit Hilfe dieser Environment-Variablen teilen wir `schild` mit, wie es sich mit der Datenbank verbinden soll. Es bietet sich an, eine Konfigurationsdatei zu verwenden:

```yaml
#./config/env.yml
local_test:
    S_ADAPTER: mysql2
    S_HOST: localhost
    S_USER: schild
    S_PASSWORD: schild
    S_DB: schild-test
```        

Die angegebenen Variablen müssen angegeben werden, damit `schild` überhaupt eine Verbindung zur Datenbank aufbauen kann. Ob sie mit Hilfe eines weiteren Gems (siehe unten) oder direkt vom System aus festgelegt werden, ist gleich.

Die oben angegebene Datei wird nun verwendet, um auf die `schild-test`-Datenbank zuzugreifen:

```ruby
require 'envyable'
Envyable.load('./config/env.yml', 'testing')
require 'schild'
```

Hier ist es wichtig, dass zuerst die Variablen geladen werden und erst im Anschluss daran `schild`, denn `schild` versucht direkt beim ersten Laden die Verbindung zur Datenbank herzustellen.

Nun sollte noch das `Schild`-Modul geladen werden, das die Verwendung von  `schild` vereinfacht:

```ruby
require 'envyable'
Envyable.load('./config/env.yml', 'testing')
require 'schild'
include Schild
```

Um jedoch alle Hilfsmethoden nutzen zu können, die das `schild`-Gem zur
Verfügung stellt, noch besser folgender Befehl verwenden:

```ruby
include SchildErweitert
```

Jetzt können praktisch alle Tabellen abgerufen und Daten ausgelesen werden. Dabei ist das DB-Objekt die Datenbank:

```ruby
DB[:eigeneschule][SchulNr]
=> "123456"
```

Das ist wenig komfortabel, auch wenn es seinen Zweck erfüllt. Schild hat viele Tabellen mit vielen Verbindungen untereinander. `schild` bietet die Möglichkeit diese Abhängigkeiten komfortabel anzusteuern:

```ruby
Schule.schulnummer
```

oder:

```ruby
s = Schueler.where(:Klasse => 'B13B').first
s.skt_halbjahr.noten.map{ |n| "#{n.fach.Bezeichnung}: #{n.NotenKrz}"}
 => ["Deutsch/ Kommunikation: 3", "Englisch: 3", "Religionslehre: ", "Mathematik: 4-", "Sport/ Gesundheitsförderung: 2", "Wirtschafts- und Betriebslehre: 3", "Datenverarbeitung: ", "Fachpraxis Textil/ Bekleidung: 2", "Gestaltungslehre: 3", "Politik/ Gesellschaftslehre: 2", "Technologie Bekleidung: 5", "Technisches Zeichnen Bekleidung: 4"]
```

In diesem Beispiel wurde der erste Schüler der klasse B13B aus dem Datensatz `Schueler` gewählt und Daten aus verschiedenen Tabellen abgerufen:

* Das aktuelle Halbjahr aus Abschnitte
* Die Notenliste aus Noten
* Die Fachbezeichnung aus Faecher

`schild` vereinfacht an dieser Stelle einige Probleme von Schild. So sind z.B. Daten zur Schule unter `Schule` erreichbar, während die Tabelle unter Schild direkt nur über DB[:eigeneschule] anzusteuern wäre. Da viele Namen im Schema der Schild-Datenbank uneinheitlich sind, versucht `schild`, soweit es geht, eine einheitliche Form zu verwenden.

Alle zur Verfügung stehenden Hilfsmethoden werden in den API-Docs erläutert.

Ziel von `schild` ist es, möglichst viele Daten aus der Datenbank komfortabel zur Verfügung zu stellen.

## Erweiterte Funktionalität
Der Formulardesigner in Schild ignoriert fehlende Felder. Das kann `schild` auch. Anstelle der in der Datenbank verwendenten Tabellenspalten, die mit Großbuchstaben geschrieben werden, bietet `schild` die Möglichkeit Kleinbuchstaben zu verwenden:

```ruby
s = Schueler.first
=> #<Schild::Schueler @values={:ID=>1, ........}>

s.Bemerkungen
=> nil

s.bemerkungen
=> ""
```

Mit Hilfe dieser zusätzlichen Methoden können Fehlermeldungen in den erstellten Berichten komfortabel umgangen werden. Je nach Bedarf kann auf Typensicherheit gesetzt werden oder etwas mehr Freiheit.

Zum Abfragen der Tabellen stehen also die Methoden entsprechend der Tabellen zur Verfügung:

```ruby
s = Schueler.first
s.Geburtsdatum
=> nil
s.Vorname
=> "Stefan"
```

Dazu die erweiterte Methode
```ruby
s = Schueler.first
s.geburtsdatum
=> 1899-01-01 00:00:00 +0100
s.geburtsland_mutter
=> ""
```

Und es gibt noch die Unterstrichmethoden, die beides verbinden: Ruby-style und frei von nil:

```ruby
s = Schueler.first
s._geburtsdatum
=> nil0
s._geburtsland_mutter
=> nil
```
## Das sollte beachtet werden
`schild` läuft nur unter Ruby. Es läuft auch unter JRuby und kann dementsprechend in alle auf der JVM laufenden Sprachen eingesetzt werden.

Die Schild-Datenbank muss einigermaßen aktuell sein, ältere Datenbanken haben offensichtlich noch Großbuchstaben in den Tabellennamen verwendet. Das bereitet `schild` Schwierigkeiten. Bei neueren Versionen von Schild (2015) werden Kleinbuchstaben verwendet.

Es kann nicht garantiert werden, dass `schild` mit jeder Version von Schild funktioniert. `schild` hat keinerlei Einfluß auf die Entwicklung von Schild und kann bei jeder Änderung am Schema der Datenbank zu fehlerhaftem Verhalten veranlasst werden. Soweit möglich, werden Legacy-Methoden geschrieben, die trotz namensänderung auf alte Werte zugreifen können. Ebenso werden Warnungen geschrieben, wenn `schild` Methoden kennt, die Schild in alten Versionen noch nicht verwendet hat.

`schild` verändert keine Daten an der Schild-Datenbank. Es ist aber möglich, dass mit Hilfe von `schild` auf Daten zugegriffen und verändert wird. `schild` verwendet zum Ansteuern der Datenbank `sequel`, ein weiterer Gem zum komfortablen Bearbeiten von relationalen Datenbanken. Um sicherzugehen, dass keine Schreibzugriffe auf die Schild-Datenbank vorgenommen werden, muss der Datenbankbenutzer auf Lesezugriff beschränkt werden.

Abschließend sollte noch erwähnt werden, dass `schild` naturgemäß auf nicht besonders vielen Datenbanken getestet werden konnte. Es wir zur Zeit an einem Berufskolleg verwendet und funktioniert einwandfrei. Nicht alle Tabellen werden derzeit verwendet, können aber bei Bedarf relativ schnell eingebunden werden.

`schild` wird zur Zeit als Bibliothek für [Sahib](https://github.com/hmt/sahib) eingesetzt. Sahib ist eine komfortable Oberfläche zum Suchen von Schülern und Klassen und der Erstellung von Dokumenten mit Hilfe von HTML und CSS, die als PDF ausgegben werden. Zeugnisse und andere Dokumente können innerhalb von wenigen Minuten erstellt und ausgegeben werden.

## Tests
`schild` verwendet Tests, um sicherzustellen, dass alle Funktionen über den gesamten Entwicklungsprozess reibungslos funktionieren. Dazu wird die Testdatenbank verwendet, die von der ribeka GmbH auf ihrer Dropbox zur Verfügung gestellt wurde. Leider ist dies eine ältere Version, die an die neue Schild-Version angepasst werden musste. Die neue Version steht als [Download](https://www.dropbox.com/s/tyswqh1burf4ijo/schild-test.sql.gz?dl=0) zur Verfügung und kann in MySQL importiert werden.

Zum Ausführen der Tests reicht es nicht, `schild` als Gem zu installieren, es muss als vollständiger Klon in ein Arbeitsverzeichnis kopiert werden. Dazu wird im Besten Fall git verwendet:

```sh
git clone git@github.com:hmt/schild.git
cd schild
```

Um die Tests bei installierter Datenbank durchführen zu können, müssen die nötigen Abhängigkeiten installiert sein. Dies wird über `bundler` organisiert:

```sh
bundle install
```

Die Tests können nun mit `rake` gestartet werden:

```sh
rake
```

`rake` greift automatisch auf die `config/env.yml` zu, um Environment-Variablen einzulesen, die voreingestellt sind. Damit die Tests funktionieren, müssen diese Variablen evtl. an die jeweilige Datenbankanbindung angepasst werden.

## Mitmachen
Hilfe bei der Mitarbeit von `schild` wird gerne angenommen. Bitte Pull Requests und Issues bei Github nutzen. Alle Änderungen sollten mit Tests eingereicht werden.

## Lizenz
[![Creative Commons Lizenzvertrag](https://i.creativecommons.org/l/by/4.0/88x31.png)]("http://creativecommons.org/licenses/by/4.0/")
[schild](https://github.com/hmt/schild) von [HMT](https://github.com/hmt) ist lizenziert unter einer [Creative Commons Namensnennung 4.0 International Lizenz](http://creativecommons.org/licenses/by/4.0/).

Oder:
The MIT License (MIT)

Copyright (c) 2015 HMT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
