# ============================================================
#  TerminalHero - Gemeinsamer Spielzustand (Model)
# ------------------------------------------------------------
#  ALLE veränderlichen Globals an einer Stelle. Sie werden hier angelegt,
#  beim Frischstart zurückgesetzt (run_shell) und von save.sh gesichert
#  bzw. geladen. Nur Deklarationen - keine Funktionen -, damit die
#  Ladereihenfolge keine Rolle spielt.
# ============================================================

# --- Ausgabe & Dialog (mittleres Fenster) --------------------
declare -ga OUT=()          # Zeilen im Ausgabe-/Dialogfenster
declare -ga CMD_HIST=()     # letzte Kommandozeilen (Verlauf)
DIALOG_ACTIVE=0            # 1 = ein Gespräch läuft (Eingabe gesperrt)
DIALOG_HINT=""             # Hinweistext in der Dialog-Kommandozeile

# --- Erkundung (Fenster bleiben dunkel, bis ...) -------------
SHOW_PATH=0                # 1 = PFAD-Fenster zeigt den Pfad (nach »pwd«)
SHOW_LS=0                  # 1 = ORDNER-Fenster zeigt Inhalt (nach »ls«)
LS_SHOW_ALL=0              # 1 = versteckte Dateien mit anzeigen

# --- Tutorial (zweites Intro) --------------------------------
TUT_STAGE=0                # 0=aus | 1..4 = erwartete Stufe
TUT_HINTED=0               # letzte Stufe, für die ein Hinweis kam
TUT_DONE=0                 # 1 = Tutorial in dieser Sitzung abgeschlossen
LAST_CAT_PATH=""           # zuletzt von »cat« aufgelöster Pfad
LAST_CAT_OK=0              # 1 = letztes »cat« war erfolgreich

# --- Erlente Befehle -----------------------------------------
declare -ga LEARNED=(pwd ls cd cat touch)
CD_BARE_KNOWN=0            # 1 = nacktes »cd« (Rückweg nach ~) erlernt

# --- Scrollen & Eingabe --------------------------------------
SCROLL=0                   # >0 = so viele Zeilen nach oben geblättert
SCROLL_MAX=0               # von render() berechnete Scroll-Grenze
FOLDER_SCROLL=0            # erste sichtbare Zeile im ORDNER-Fenster (0 = oben)
FOLDER_SCROLL_MAX=0        # von render() berechnete Scroll-Grenze
FOLDER_CAP=0               # sichtbare Zeilen im ORDNER-Fenster
FOLDER_VISIBLE=0           # 1 = ORDNER-Fenster zeigt gerade Inhalt
FOLDER_LAST_DIR=""         # Ordner der letzten Zeichnung (Offset-Reset)
CMD_BUFFER=""              # gerade getippte Kommandozeile
COMP_SIG=""                # Signatur der Tab-Trefferliste (Anti-Spam)
declare -ga WRAPPED=() WCOL=()   # umgebrochene Ausgabezeilen + Farben (Cache)
WRAP_KEY=""                # Signatur des Umbruch-Caches
IN_BYTES=""                # rohe, noch nicht gelesene Eingabe-Bytes
declare -ga KEYQ=()         # gelesene, noch nicht verarbeitete Tasten
CHOICE=0                   # Ergebnis der letzten ask()-Auswahl

# --- Gesprächs-/Fortschritts-Flags ---------------------------
AGENT_ATTITUDE="unbekannt"
AGENT_APPROACH="unbekannt"
README_DONE=0              # General (README) erstmals gesprochen
CONAN_DONE=0               # Kriegsrat (BarbarConan) gesprochen
DETEKTIV_DONE=0            # Chefermittler (DetektivConan) befragt
SAVE_LEARNED=0             # »save« im Downloads-Bereich erlernt
TOUCH_CREATE_KNOWN=0       # »touch« darf neue Dateien ANLEGEN (sonst nur Gespräche)

# --- Pixi-Quest ----------------------------------------------
HOME_FIRST_VISIT=0         # ~ zum ersten Mal betreten
PIXI_DESKTOP_DONE=0        # Schreibtisch-Szene gesehen
PIXI_GATE_DONE=0           # Wortgefecht am Haupttor geführt
PIXI_HALL_DONE=0           # Haupteingang-Szene gesehen
TORWAEHTER_DONE=0          # Gespräch mit dem Torwächter geführt

# --- Story: Zeitungsverlag & Nachtlager (Familie Nullpunkt) ---
VERLAG_DONE=0              # Familiengespräch im Verlag gesehen (Pixi/Rachel/Jack)
PIXI_GUIDE_DONE=0          # Pixi hat sich im Süddistrikt verabschiedet (geht in die Baracke)
BARACKE_SCENE_DONE=0       # Baracken-Gespräch: Armbanduhr entdeckt, »grep« gelernt

# --- Story: Großer Ermittler (Pixis Brief, Detektei Holmes) ---
PIXI_LETTER_DONE=0         # Pixi hat den Brief für Sherlock Holmes übergeben
AMANDA_INTRO_DONE=0        # Amanda Nox hat sich vorgestellt (auch ohne Quest)
AMANDA_DONE=0              # Amanda Nox im Rahmen der Sherlock-Quest nach Holmes gefragt
# --- Story: Unterstützung für Amanda (nach »Großer Ermittler«) --------
# Amanda sucht jemanden für ihre Aktenberge. Jack Nullpunkt zieht dafür
# vom DailyPulse-Verlag in die Detektei Holmes um.
AMANDA_HELP_GIVEN=0        # Nebenquest »Unterstützung für Amanda« erhalten
AMANDA_HELP_ASKED=0        # Jack wurde gefragt; er muss ggf. erst die Zeitung erledigen
AMANDA_HELP_JACK=0         # Jack arbeitet jetzt in der Detektei Holmes (physisch umgezogen)
AMANDA_HELP_DONE=0         # Amanda hat sich bedankt (200 EXP), Quest abgeschlossen
SHERLOCK_DONE=0            # Agent hat Sherlock Holmes angetroffen (nachts angesprochen) –
                           # danach bietet Börty seine Holmes-Auskunft nicht mehr an

# --- Story: Seltsame Religion (Sherlock Holmes → Novize Bill) ----------
# Nach der abgeschlossenen Hauptquest »Großer Ermittler« (ERMITTLER_DONE)
# hat Holmes mehr Aufträge als ihm lieb ist. Eine davon ist die Suche nach
# einer neuen, verschlossenen Religion mit Molerat-Bezug.
RELIGION_GIVEN=0           # Nebenquest »Seltsame Religion« von Holmes erhalten
BILL_MET=0                 # Novize Bill in der Kneipe kennengelernt
BILL_TOLD=0                # Bill hat nach einem Bier von den MoleratAnhängern
                           # und dem verschwundenen Priester erzählt (Quest-Update)

# --- Story: SchweinePriester's Tagebuch (KöniginnenKammer) -----------
# Das Tagebuch liegt in der KöniginnenKammer. Aufheben aktualisiert die
# Quest »Seltsame Religion« (falls aktiv); beim ersten Lesen wird sie
# vergeben, auch wenn Sherlock noch nicht gefragt wurde. Danach kann das
# Buch Novize Bill und Sherlock Holmes gezeigt werden (je einmal, +300 EXP).
TAGEBUCH_FOUND=0           # Tagebuch in der KöniginnenKammer aufgenommen
TAGEBUCH_READ=0            # Tagebuch mindestens einmal gelesen
RELIGION_BOOK_FIRST=0      # Quest »Seltsame Religion« kam über das Tagebuch
BILL_BOOK_DONE=0           # Bill hat das Buch gesehen (+300 EXP, einmalig)
SHERLOCK_BOOK_DONE=0       # Sherlock hat das Buch gesehen (+300 EXP, einmalig)
BOERTY_SH_DONE=0           # Börty hat von Holmes erzählt (Details will er bezahlt)
BOERTY_INTRO_DONE=0        # Börtys einmalige Vorstellung gesehen (»Gläser einräumen«)
BOERTY_INFO=0              # Börty wurde für die Holmes-Auskunft BEZAHLT (10 Bits,
                           # kern/items.sh) – erst dann nennt der Questlog Holmes'
                           # Nachtzeit im Ostdistrikt. Danach bietet er die Auskunft
                           # nicht mehr an (nur noch Standardgespräch).

# --- Story: Vermisste Bewohner & Bier für Börty (Börtys Bitte) --------
# Voraussetzung ist die abgeschlossene Hauptquest »Großer Ermittler«
# (ERMITTLER_DONE): erst dann hat Börty im Standardgespräch die Option
# »Kann ich dir irgendwie behilflich sein?«.
BOERTY_FAVOR_DONE=0        # Börtys Bitte erzählt (Lagergehilfe Michael Mitch
                           # verschwunden, seit Monaten Vermisste in der Stadt).
                           # Story-Flag, NICHT der Abschluss der Bierlieferung –
                           # das ist BIER_DONE.
VERMISSTE_GIVEN=0          # Hauptquest »Vermisste Bewohner« erhalten
SIMON_NEK_INFO=0           # Simon Guard hat von Nek Molerat erzählt
NEK_GIVEN=0                # Nebenquest »Wo ist Nek Molerat?« erhalten
JON_NEK_INFO=0             # Simple Jon im Wachhaus hat von Nek erzählt
JON_NEK_FOUND_INFO=0       # Simple Jon hat auf den Fund von Neks Leiche reagiert
BIER_GIVEN=0               # Nebenquest »Bier für Börty« ANGENOMMEN
                           # (Börty hat 250 Bits mitgegeben)
BIER_TAKEN=0               # Lagermeister Samy Cage hat die Lieferung
                           # herausgegeben (250 Bits bezahlt, Item im Inventar)
BIER_DONE=0                # Lieferung bei Börty abgegeben: Quest
                           # »Bier für Börty« abgeschlossen (100 EXP + 30 Bits)
BIER_FAILED=0              # Bierlieferung nach 24 Spielstunden ohne Kiste
                           # gescheitert (Event beim Wirt)
BIER_LOST_AT=-1            # Spielminute des Kistenverlusts; -1 = keine Frist
SAMY_INTRO_DONE=0          # Lagermeister Samy Cage (Zentrum/Marktplatz/Lager)
                           # hat sich vorgestellt

# --- Story: Brachland/Friedhof (Francesco Dellamorte) --------------
FRANCESCO_MET=0            # Erstes Treffen mit dem Totengräber im
                           # Brachland-Friedhof gesehen

# --- Story: DailyPulse-Zeitungskästen & Jacks Papierstau ----------
# Die Zeitungskästen stehen in allen fünf Bezirken. Sie verkaufen immer
# nur die AKTUELLE Ausgabe (ZEITUNG_EDITION -> Item-ID). Jedes Bit in
# ZEITUNG_EMPTIED markiert einen LEEREN Kasten: Er verkauft nichts, bis
# er wieder befüllt wird. Bei Jacks Quest werden alle fünf geleert; bei
# Rachels Verteilung (AUFLAGE_GIVEN) werden sie einzeln wieder befüllt.
ZEITUNG_EDITION=bezirke    # aktuell in den Kästen verkaufte Ausgabe (Item-ID)
ZEITUNG_EMPTIED=0          # Bitmaske: 1 = Kasten leer, 0 = Kasten gefüllt
ZEITUNG_GIVEN=0            # Jacks Quest »Die langweiligste Ausgabe« angenommen
ZEITUNG_DONE=0             # Jacks Quest abgeschlossen (200 EXP)
# Nach Neks Beerdigung erscheint eine zusätzliche DailyPulse-Ausgabe.
# Sie wird einige Ingame-Tage lang neben der Hauptausgabe an den Kästen
# und bei Tracey verkauft. ZEITUNG_EXTRA_DAY ist der erste Verkaufstag,
# ZEITUNG_EXTRA_UNTIL der letzte (jeweils inklusive); -1 = noch nicht
# erschienen bzw. nicht mehr verfügbar.
ZEITUNG_EXTRA_DAY=-1
ZEITUNG_EXTRA_UNTIL=-1
ZEITUNG_EXTRA_SHOWN=0      # Erscheinen-Hinweis bereits ausgegeben

# --- Story: Stadtrundgang mit Pixi ------------------------------
# Erst möglich, wenn »Großer Ermittler« (ERMITTLER_DONE) und Jacks
# Zeitungsquest (ZEITUNG_DONE) abgeschlossen sind. Pixi führt den Agenten
# dann in der Zeit von 06:00 bis 14:00 durch alle fünf Distrikte zurück
# in den DailyPulse-Verlag (1000 EXP).
RUNDGANG_GIVEN=0           # Pixi hat den Rundgang angeboten und er wurde begonnen
RUNDGANG_DONE=0            # Rundgang beendet (1000 EXP)

# --- Story: Die neueste Auflage: Sperrzone ---------------------
# Am Ende des Rundgangs ist Pixis Artikel gedruckt. Rachel gibt dem
# Agenten fünf Bündel und den Zeitungskastenschlüssel; jeder Kasten wird
# einmal mit der neuen Ausgabe befüllt. Die Hauptquest endet bei Rachel
# (50 Bits, ein Exemplar, 500 EXP).
AUFLAGE_GIVEN=0            # Rachels Hauptquest »Die neueste Auflage« angenommen
AUFLAGE_DONE=0             # Alle fünf Kästen befüllt und bei Rachel gemeldet (500 EXP)

# --- Story: Finde Tracey & Jimmys Zeitungsbote -----------------
# Nach der Baracken-Szene schickt Rachel den Agenten zu Tracey Briggs
# (Ostdistrikt, vor Jimmys Haus). Gefunden wird sie dort; danach steht sie
# im DailyPulse-Verlag. Sobald Rachel sich bei ihr bedankt hat
# (TRACEY_DONE), beginnt Traceys Stadttour: alle 4 Spielstunden wechselt
# sie zwischen Haupteingang und den fünf Distrikten (Charakter/
# TraceyBriggs.sh, tracey_wander_dir). Jimmy Page bietet anschließend
# 50 Bits je neuer Zeitungsausgabe (einmal pro Edition).
TRACEY_GIVEN=0             # Rachels Nebenquest »Finde Tracey« erhalten
TRACEY_FOUND=0             # Tracey im Ostdistrikt gefunden (Quest-Update)
TRACEY_DONE=0              # Bei Rachel abgeschlossen (100 EXP) -> Stadttour
TRACEY_TOUR_START=-1       # Spielminute, in der die 4-Stunden-Tour begann
TRACEY_ACTIVE_PATH=""      # flüchtig: wo Tracey gerade steht (nicht gespeichert)
JIMMY_INTRO_DONE=0         # Jimmy Page hat sich vorgestellt
JIMMY_TRACEY_DONE=0        # Jimmy hat von Traceys 100-Bit-Verkauf erzählt
JIMMY_GIVEN=0              # Nebenquest »Jimmys Zeitungsbote« erhalten
JIMMY_LAST_SOLD=""         # Edition, die Jimmy zuletzt gekauft hat (eine je Ausgabe)
JIMMY_FIRST_SALE=0         # Agent hat Jimmy mindestens eine Ausgabe verkauft
TRACEY_RIVAL_SEEN=0        # Traceys einmaliger Konkurrenz-Dialog wurde gezeigt

# --- Story: Suche nach Michael Mitch --------------------------
# Am Ende der Bierlieferung (BIER_DONE) fragt der Agent nach Mitch -
# daraus entsteht die Nebenquest »Michael Mitch. Vermisst«. Die
# INFO-Flags halten fest, wer schon etwas über die Vermissten bzw. über
# Mitch gesagt hat (Questlog-Verlauf, weitere Hinweise).
MITCH_GIVEN=0              # Nebenquest »Michael Mitch. Vermisst« erhalten
MITCH_TALKED=0             # Mitch im Restaurant getroffen: Er will nicht
                           # mehr für Börty arbeiten, der Agent soll es sagen
MITCH_DONE=0               # Börty informiert: Mitch-Quest abgeschlossen
                           # (250 EXP + 20 Bits, neue Nebenquest »gehilfe«)
GEHILFE_GIVEN=0            # Nebenquest »Ein neuer Gehilfe für Börty« erhalten
BOERTY_VERMISSTE_INFO=0    # Börty (Kneipe) auf »Vermisste Bewohner?«
                           # geantwortet: Holmes arbeitet an dem Fall
SAMY_VERMISSTE_INFO=0      # Samy Cage über die Vermissten gesprochen
SAMY_MITCH_INFO=0          # Samy Cage: Michael Mitch im Westdistrikt gesehen
MICHAEL_INTRO_DONE=0       # Michael Mitch hat sich im Restaurant vorgestellt

# --- Schlafen (Schlafplätze aus Interior/) --------------------
# Alle Schlafgelegenheiten (Matratze, Bett, Doppelbett) teilen sich
# diesen Tageszähler. Die 12 Stunden pro Tag verteilen sich also auf
# alle Schlafplätze zusammen.

# --- Archiv (Kapitelbilder & Orte) ---------------------------
ARCHIVE_KAP1=0             # 1 = Kapitel 1 "Ein neuer Agent" freigeschaltet/gesehen
ARCHIVE_ORT_DESKTOPCITY=0  # 1 = Ort "Desktop City" freigeschaltet/gesehen
SLEEP_HOURS_TODAY=0        # im aktuellen Spieltag geschlafene Stunden
SLEEP_DAY=-1               # Spieltag, zu dem der Zähler gehört (siehe kern/Uhrzeit.sh)

# --- Sitzen (Sitzgelegenheiten aus Interior/) -----------------
# Eigener Tageszähler, getrennt vom Schlafen: 12 Stunden schlafen UND
# 12 Stunden sitzen pro Spieltag sind möglich. Alle Sitzgelegenheiten
# (Stuhl, Sitzbank) teilen sich diesen Zähler.
SIT_HOURS_TODAY=0          # im aktuellen Spieltag gesessene Stunden
SIT_DAY=-1                 # Spieltag, zu dem der Sitzzähler gehört

# --- Fackel (NutzbareItems) -----------------------------------
# Die einfache Fackel brennt 3 Spielstunden lang. Solange sie brennt,
# zeigt das Ordner-Fenster den Inhalt automatisch an (kern/fackel.sh,
# kern/render.sh). TORCH_UNTIL_MIN ist die absolute Spielminute, bis zu
# der sie leuchtet; 0 = aus.
TORCH_UNTIL_MIN=0

# --- Kalender (cal) -------------------------------------------
# Nach »cal« bleibt das In-Game-Datum 24 Spielstunden lang mittig auf
# der oberen Linie des PFAD-Fensters sichtbar (kern/kalender.sh,
# kern/render.sh). CAL_UNTIL_MIN ist die Spielminute, bis zu der die
# Anzeige läuft; 0 = aus.
CAL_UNTIL_MIN=0

# --- Höhle & Neks Leiche (Charakter/NeksLeiche.sh) -------------
# Die Leiche ist ein dynamischer FS-Eintrag. NEKS_LEICHE_PATH hält ihren
# aktuellen Ort (auch nach dem Ablegen), DRAGGED_CORPSE denselben Pfad,
# solange sie hinter dem Agenten hergezogen wird ("" = nicht gezogen).
# NEKS_LEICHE_SEARCHED merkt, ob der Loot schon gefunden wurde.
NEKS_LEICHE_PATH=""
DRAGGED_CORPSE=""
NEKS_LEICHE_SEARCHED=0

# Nek-Quest-Fortschritt (Simon Guard am Haupttor):
#   NEK_FOUND        - Leiche wurde gefunden (Questlog: »Hab Nek gefunden …«)
#   NEK_REPORTED     - Der Agent hat Simon mindestens einmal vom Fund berichtet
#   NEK_MUST_SEARCH  - Simon hat zurück zum Durchsuchen geschickt
#   NEK_CORPSE_BROUGHT - Leiche wurde zu Simon gebracht
#   NEK_SIMON_SEARCHED - Simon hat die Leiche selbst durchsucht und das Amulett
#   NEK_AMULET_SOLD  - Amulett für 150 Bits an Simon verkauft
#   NEK_AMULET_KEPT  - Amulett behalten (oder Simon gegenüber verschwiegen)
#   NEK_DONE         - Nek-Quest abgeschlossen
NEK_FOUND=0
NEK_REPORTED=0
NEK_MUST_SEARCH=0
NEK_CORPSE_BROUGHT=0
NEK_SIMON_SEARCHED=0
NEK_AMULET_SOLD=0
NEK_AMULET_KEPT=0
NEK_DONE=0

# --- Story: Neks Beerdigung (getimte Quest) -------------------
# Nach dem Abschluss der Nek-Quest wird die Beerdigung angesetzt:
#   NEK_FUNERAL_DISPOSITION  cave|simon|lost
#   NEK_FUNERAL_DAY          Spieltag der Beerdigung (0 = Starttag)
#   NEK_FUNERAL_DISCOVERY_DAY Spieltag, an dem die Leiche gefunden wird
#                            (nur bei »lost«; -1 = nicht nötig)
#   NEK_FUNERAL_GIVEN        Quest »Neks Beerdigung« läuft
#   NEK_FUNERAL_FOUND        Leiche wurde bei »lost« in der Welt gefunden
#   NEK_FUNERAL_DONE         Beerdigung besucht, Quest abgeschlossen
#   NEK_FUNERAL_FAILED       Beerdigung verpasst, Quest gescheitert
NEK_FUNERAL_GIVEN=0
NEK_FUNERAL_DISPOSITION=""
NEK_FUNERAL_DAY=-1
NEK_FUNERAL_DISCOVERY_DAY=-1
NEK_FUNERAL_FOUND=0
NEK_FUNERAL_DONE=0
NEK_FUNERAL_FAILED=0

# --- Story: Neks Familie (Folgequest) -------------------------
# Simon beantwortet nach dem Nek-Abschluss die Frage nach dem Namen
# »Molerat« und verweist auf die Familie. Die Familie lebt auf der
# Farm im Farmland der Steppe, im Erdgeschoss des Anwesens
# (Orte/Anwesen.sh, Charakter/MoleratFamilie.sh).
NEK_FAMILY_GIVEN=0

# --- Story: Gregor Molerat & die MoleratCode-Nachfrage --------
# Gregor wohnt im Erdgeschoss des Anwesens auf der Farm. Sein
# Gespräch vergibt die Nebenquest »Von den Molerats, für die
# Molerats«: Die Familie braucht 120 MoleratCode.
GREGOR_CODE_GIVEN=0        # Quest ist vergeben
GREGOR_CODE_DELIVERED=0    # bereits abgegebene Stückzahl (0..120)
GREGOR_CODE_DONE=0         # 120 Stück abgegeben, Quest abgeschlossen
GREGOR_BOOK_DONE=0         # Gregor hat das Tagebuch erkannt (nach der Quest)

# --- Gegner: Molerats & Guy Sus --------------------------------
# MOLERATS_DEAD ist eine Bitmaske (1 = Molerat1, 2 = Molerat2,
# 4 = Molerat3) für die drei Story-Molerats in der Molerathöhle.
# Getötete Höhlen-Molerats werden beim Laden nicht wieder aufgebaut.
# Die Moleratgebiete im Brachland/Steppe haben eigene Zähler:
#   MOLERAT_AREA_DEAD[Gebiet] - Anzahl der dort gerade toten Molerats
#   MOLERAT_AREA_NEXT[Gebiet] - absolute Spielminute des nächsten Spawns
# So kann in jedem Gebiet unabhängig alle 24 Ingame-Stunden ein
# Molerat nachkommen, bis das Gebietsmaximum wieder erreicht ist.
declare -gA MOLERAT_AREA_DEAD=()
declare -gA MOLERAT_AREA_NEXT=()
# MoleratKrieger in der Großen Höhlenkammer und in der KöniginnenKammer
# haben eigene Zähler und einen 48-Stunden-Takt (maximal zwei bzw. drei
# Krieger je Kammer):
#   MOLERAT_KRIEGER_DEAD[Gebiet] - Anzahl der dort gerade toten Krieger
#   MOLERAT_KRIEGER_NEXT[Gebiet] - absolute Spielminute des nächsten Spawns
declare -gA MOLERAT_KRIEGER_DEAD=()
declare -gA MOLERAT_KRIEGER_NEXT=()
# Die MoleratKönigin in der KöniginnenKammer kehrt nach ihrer Vernichtung
# nicht zurück. 0 = lebt, 1 = endgültig tot.
MOLERAT_KOENIGIN_DEAD=0
# Guy Sus merkt sich, ob er den Agenten schon angesprochen hat und ob
# er nach dem Nachspiel verschwunden ist.
MOLERATS_DEAD=0
GUY_SUS_MET=0
GUY_SUS_GONE=0
GUY_SUS_CAVE_DONE=0
GUY_SUS_OUTSIDE_DONE=0

# Flüchtige Angriffsanker (nicht im Spielstand):
#   GEGNER_ACTIVE_CWD    Ordner, in dem gerade gekämpft wird ("" = keiner)
#   GEGNER_AGGRO_AT      Zeitpunkt, ab dem der erste Angriff fällig ist
#   GEGNER_LAST_ATTACK_AT Zeitpunkt der letzten Schadensabrechnung
#   GEGNER_LAST_CWD      zuletzt betretener Ordner (verhindert Doppel-Oink)
GEGNER_ACTIVE_CWD=""
GEGNER_AGGRO_AT=0
GEGNER_LAST_ATTACK_AT=0
GEGNER_LAST_CWD=""

# --- TUI ------------------------------------------------------
TUI_ACTIVE=0
