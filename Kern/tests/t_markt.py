#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Marktplatz, Samy Cage & Börtys Bitte (PTY)
# ------------------------------------------------------------
#  Der Zentrum-Marktplatz mit seinem Lager, der Lagermeister Samy
#  Cage - und Börtys neue Gesprächsoption, die nach der
#  abgeschlossenen Quest »Großer Ermittler« auftaucht:
#
#    1) Zentrum: Marktplatz -> Lager -> SamyCage (touch, cat,
#       Vorstellung, Wiedererkennen)
#    2) Die Option »Kann ich dir irgendwie behilflich sein?« gibt es
#       ERST nach »Großer Ermittler«
#    3) Börtys Bitte ganz: Erzählung (Michael Mitch, die Vermissten),
#       Hauptquest »Vermisste Bewohner«, Bierlieferung, 250 Bits,
#       Nebenquest »Bier für Börty«, Questlog
#    4) »Auftrag ablehnen« ändert nichts - die Bitte bleibt stehen
#    5) Samy ohne 250 Bits: keine Lieferung
#    6) Samy mit 250 Bits: bezahlen -> »Börtys Bierlieferung« (Item) ->
#       bei Börty abgeben -> Quest abgeschlossen, 100 EXP + 30 Bits ->
#       Nebenquest »Michael Mitch. Vermisst«
#    7) Zeugen: »Vermisste Bewohner?« & »Michael Mitch?« bei Samy und Börty
#    8) Samy: »Michael Mitch?« auch bei altem Spielstand (Quest nachholen)
#    9) Michael Mitch im Restaurant: Er will nicht zu Börty zurück ->
#       »Wegen Mitch...« bei Börty -> 250 EXP, 20 Bits und die neue
#       Nebenquest »Ein neuer Gehilfe für Börty«
#
#  Aufruf:  python3 Kern/tests/t_markt.py
# ============================================================
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL, RIGHT, Screen

TAB = b"\t"

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
ZENTRUM = CITY + "/Zentrum"
MARKT = ZENTRUM + "/Marktplatz"
LAGER = MARKT + "/Lager"
KNEIPE = CITY + "/Ostdistrikt/KneipeZumGoldenenLächeln"
RESTAURANT = CITY + "/Westdistrikt/Restaurant"


def start(name, scalars, inv=None, learn=None):
    """Session aus einem gepatchten Spielstand starten."""
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learn or LEARNED_ALL, inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


def leave(s, m, label="Ich hab es mir anders überlegt."):
    """Wählt im offenen Menü die letzte sichtbare Abschiedsoption."""
    hits = re.findall(r"(\d+)\)\s*" + re.escape(label), s.since(m))
    if not hits:
        raise RuntimeError("Abschiedsoption nicht gefunden: " + label)
    s.send(hits[-1], 0.6)
    s.send(b"\r", 1.0)


# ==================================================== §1 Zentrum & Samy
with start("mk_samy", {"CWD": ZENTRUM}) as s:
    r = Report("1) Zentrum: Marktplatz, Lager, Samy Cage")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("cd Marktplatz")
    s.cmd("ls")
    r.check("der Marktplatz hat ein Lager", s.wait_from(m, "Lager", 12))
    m = s.mark()
    s.cmd("cd Lager")
    s.cmd("ls")
    r.check("im Lager steht SamyCage", s.wait_from(m, "SamyCage", 12))
    m = s.mark()
    s.cmd("cat SamyCage")
    r.check("die Datei nennt den Lagermeister", s.wait_from(m, "Lagermeister", 12))
    r.check("und seinen Zustand", s.wait_from(m, "schwer beschäftigt", 12))

    m = s.mark()
    s.cmd("touch SamyCage")
    r.check("er stellt sich vor", s.wait_from(m, "Ich bin Samy Cage", 20))
    r.check("er ist schwer beschäftigt", s.wait("Und ich bin schwer beschäftigt", 15))
    r.check("und schickt zur Seite", s.wait("geh doch bitte zur Seite", 15))
    r.check("keine Skriptfehler im Gespräch",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))
    s.send("1", 0.6)
    r.check("»Es ist wichtig!« findet Gehör", s.wait("Wichtig ist hier alles", 15))
    m2 = s.mark()
    s.send(b"\r", 1.0)                      # dialog_pause
    r.check("nach der Antwort erscheint das Menü erneut",
            s.wait_from(m2, "Sonst nichts. Ich geh zur Seite.", 10))
    s.send("2", 0.6)                        # zurück im Menü: zur Seite
    s.send(b"\r", 1.0)                      # Abschiedspause

    m = s.mark()
    s.cmd("touch SamyCage")
    r.check("beim zweiten Mal kennt er dich", s.wait_from(m, "Du schon wieder", 20))
    s.send("2", 0.6)
    r.check("»Ich geh zur Seite« ist vernünftig", s.wait("Sehr vernünftig", 15))
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ============================================ §2 erst nach dem Ermittler
with start("mk_ohne", {"CWD": KNEIPE, "BOERTY_INTRO_DONE": 1,
                       "ERMITTLER_DONE": 0}) as s:
    r = Report("2) Die Bitte gibt es erst nach »Großer Ermittler«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Börty")
    r.check("Standardgespräch öffnet", s.wait_from(m, "Was darf sein?", 20))
    s.drain(1.0)                            # Optionen sind gerendert
    r.check("das Handeln ist da (Gegenprobe)", "Handeln." in s.since(m))
    r.check("die Bitte fehlt noch", "behilflich" not in s.since(m))
    txt = s.since(m)
    r.check("Abschiedsoption steht ganz unten",
            txt.rfind("Ich hab es mir anders überlegt.") > txt.rfind("Handeln."))
    s.send("4", 0.6)
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ==================================================== §3 die ganze Bitte
with start("mk_bitte", {"CWD": KNEIPE, "BOERTY_INTRO_DONE": 1,
                        "ERMITTLER_DONE": 1, "BITS": 5}) as s:
    r = Report("3) Börtys Bitte: erzählen, annehmen, 250 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 20)
    s.drain(1.0)
    r.check("jetzt steht die Bitte da", "behilflich" in s.since(m))
    txt = s.since(m)
    r.check("Abschiedsoption steht nach der Bitte",
            txt.rfind("Ich hab es mir anders überlegt.") > txt.rfind("behilflich"))

    s.send("4", 0.6)
    r.check("Börty hat etwas", s.wait("Ja, da gäbe es schon was", 20))
    r.check("der Gehilfe wird genannt", s.wait("Michael Mitch", 25))
    r.check("und die Vermissten", s.wait("vermisst gemeldet", 30))
    r.check("spurlos verschwunden", s.wait("Spurlos", 30))
    r.check("neue Hauptquest im Log", s.wait("»Vermisste Bewohner« erhalten", 30))
    r.check("der Gefallen: zum Marktplatz", s.wait("Marktplatz im Zentrum", 30))
    r.check("Samy Cage wird genannt", s.wait("Samy Cage", 30))
    r.check("Börty gibt das Geld mit", s.wait("Ich geb dir das Geld direkt mit", 30))
    r.check("der Agent hakt nach", s.wait("Du vertraust mir einfach so deine Bits an?", 30))
    r.check("Pixi ist der Grund für das Vertrauen",
            s.wait("Eindruck bei Pixi hinterlassen", 30))

    s.send("1", 0.8)                        # Auftrag annehmen
    r.check("Annahme wird quittiert", s.wait("Ich hol dir dein Bier", 20))
    r.check("Börty nennt die 24-Stunden-Frist", s.wait("24 Stunden", 20))
    r.check("Frist-Hinweis im Ausgabefenster", s.wait("[ FRIST ]", 20))
    r.check("250 Bits gehen mit", s.wait("+250 Bits für die Bierlieferung", 20))
    r.check("Nebenquest »Bier für Börty«", s.wait("»Bier für Börty« erhalten", 20))
    r.check("Zielhinweis ins Zentrum", s.wait("cd Zentrum", 20))
    s.send(b"\r", 1.2)                      # dialog_pause
    leave(s, m)                             # zurück im Menü: Abschied

    # Kontostand: 5 Bits Startguthaben + 250 = 255
    m = s.mark()
    s.cmd("inventar")
    r.check("Kontostand 255 Bits", s.wait_from(m, "255 Bits", 12))
    s.esc()
    s.drain(0.8)

    # Questlog: beide Quests stehen drin
    m = s.mark()
    s.cmd("questlog")
    r.check("Hauptquest steht im Questlog", s.wait_from(m, "Vermisste Bewohner", 15))
    s.send(RIGHT, 0.6)                      # Reiter: Nebenquests
    r.check("Nebenquest steht im Questlog", s.wait("Bier für Börty", 15))
    s.esc()
    s.drain(0.8)

    # Charakterbogen: die Skillpunkte werden angezeigt
    m = s.mark()
    s.cmd("character")
    r.check("Charakterbogen zeigt SKILLPUNKTE", s.wait_from(m, "SKILLPUNKTE", 15))
    s.esc()
    s.drain(0.8)

    # Noch einmal fragen: nur noch die Erinnerung, keine zweite Quest
    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 20)
    s.send("4", 0.6)
    r.check("Erinnerung an die Lieferung", s.wait("Und? Warst du beim Samy?", 20))
    r.check("keine zweite Questmeldung",
            "»Vermisste Bewohner« erhalten" not in s.since(m))
    s.send(b"\r", 1.0)
    leave(s, m)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ==================================================== §4 Auftrag ablehnen
with start("mk_ablehnen", {"CWD": KNEIPE, "BOERTY_INTRO_DONE": 1,
                           "ERMITTLER_DONE": 1, "BITS": 0}) as s:
    r = Report("4) Ablehnen ändert nichts – die Bitte bleibt stehen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 20)
    s.send("4", 0.6)
    s.wait("Ja, da gäbe es schon was", 20)
    r.check("die Hauptquest kommt trotzdem", s.wait("»Vermisste Bewohner« erhalten", 30))
    s.wait("Nimmst du den Auftrag an?", 30)
    s.drain(0.5)
    s.send("2", 0.8)                        # Auftrag ablehnen
    r.check("Börty drängt", s.wait("Verdammt! Ich komm hier nicht weg!", 20))
    r.check("und bittet ums Überlegen", s.wait("Überleg es dir noch mal", 20))
    s.send(b"\r", 1.2)
    leave(s, m)                             # zurück im Menü: Abschied

    m = s.mark()
    s.cmd("inventar")
    r.check("keine Bits geflossen (0)", s.wait_from(m, "0 Bits", 12))
    s.esc()
    s.drain(0.8)

    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 20)
    s.drain(1.0)
    r.check("die Option steht weiter da", "behilflich" in s.since(m))
    s.send("4", 0.6)
    r.check("beim zweiten Mal nur die kurze Bitte",
            s.wait("Also? Bier. Marktplatz. Samy Cage. Im Zentrum.", 20))
    r.check("keine falsche Behauptung, das Geld sei schon übergeben",
            s.wait("Wenn du den Auftrag annimmst, sind die 250 Bits für die Lieferung dabei.", 20))
    r.check("kein falsches »wieder« beim Beutel",
            "schiebt den Beutel wieder" not in s.since(m))
    r.check("keine zweite Questmeldung",
            "»Vermisste Bewohner« erhalten" not in s.since(m))
    s.send("1", 0.8)
    r.check("jetzt wird angenommen", s.wait("Ich hol dir dein Bier", 20))
    r.check("und das Geld kommt mit", s.wait("+250 Bits für die Bierlieferung", 20))
    s.send(b"\r", 1.2)
    leave(s, m)
    m = s.mark()
    s.cmd("inventar")
    r.check("jetzt stehen 250 Bits auf dem Konto", s.wait_from(m, "250 Bits", 12))
    s.esc()
    s.drain(0.8)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# =============================================== §5 zu wenig Bits für Samy
with start("mk_kein_geld", {"CWD": LAGER, "SAMY_INTRO_DONE": 1, "ERMITTLER_DONE": 1,
                            "BOERTY_FAVOR_DONE": 1, "VERMISSTE_GIVEN": 1,
                            "BIER_GIVEN": 1, "BITS": 40}) as s:
    r = Report("5) Samy: ohne 250 Bits gibt es keine Lieferung")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.wait_from(m, "Ich bin immer noch schwer beschäftigt", 20)
    s.drain(1.2)
    r.check("die Option »Bier für Börty.« steht da", "Bier für Börty." in s.since(m))
    s.send("1", 0.6)
    r.check("er kennt dich als Börtys Gehilfen",
            s.wait("Ah, du bist also der neue Gehilfe von Börty?", 20))
    r.check("und hat von Mitch gehört",
            s.wait("Der ist wohl irgendwo verschwunden", 20))
    r.check("er fragt nach den 250 Bits", s.wait("Hast du die Bits? 250?", 20))
    r.check("ohne Geld kein Bier", s.wait("Kein Geld, kein Bier", 20))
    r.check("und der Agent soll wiederkommen",
            s.wait("Komm wieder, wenn du es zusammen hast", 20))
    s.send(b"\r", 1.2)
    leave(s, m, "Sonst nichts. Ich geh zur Seite.")

    m = s.mark()
    s.cmd("inventar")
    r.check("Inventar öffnet", s.wait_from(m, "INVENTAR", 12))
    s.drain(0.8)
    r.check("keine Lieferung im Inventar", "Bierlieferung" not in s.since(m))
    r.check("die 40 Bits sind noch da", "40 Bits" in s.since(m))
    s.esc()
    s.drain(0.8)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §6 bezahlen, Kiste holen, bei Börty abgeben
with start("mk_kasse", {"CWD": LAGER, "SAMY_INTRO_DONE": 1, "ERMITTLER_DONE": 1,
                        "BOERTY_INTRO_DONE": 1,
                        "BOERTY_FAVOR_DONE": 1, "VERMISSTE_GIVEN": 1,
                        "BIER_GIVEN": 1, "BITS": 260}) as s:
    r = Report("6) Samy: 250 Bits bezahlen -> Kiste -> bei Börty abgeben")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.send("1", 0.6)
    s.wait("Hast du die Bits? 250?", 20)
    r.check("der Agent legt das Geld hin", s.wait("250 Bits. Zähl sie ruhig nach.", 20))
    r.check("die 250 Bits sind abgebucht", s.wait("-250 Bits an Samy Cage", 20))
    r.check("die Kiste wandert ins Inventar",
            s.wait("»Börtys Bierlieferung« – abgeben bei Börty", 20))
    r.check("Samy mahnt die Flaschen",
            s.wait("Lass die Flaschen bloß nicht fallen", 20))
    s.send(b"\r", 1.2)
    leave(s, m, "Sonst nichts. Ich geh zur Seite.")

    m = s.mark()
    s.cmd("inventar")
    r.check("Inventar öffnet", s.wait_from(m, "INVENTAR", 12))
    s.drain(0.8)
    r.check("die Lieferung ist drin", "Bierlieferung" in s.since(m))
    r.check("nur noch 10 Bits übrig", "10 Bits" in s.since(m))
    s.esc()
    s.drain(0.8)

    # Ab durch die Stadt: zur Kneipe im Ostdistrikt
    m = s.mark()
    s.cmd("cd %s" % KNEIPE)
    s.cmd("touch Börty")
    r.check("Börty begrüßt wie immer", s.wait_from(m, "Was darf sein?", 25))
    s.drain(1.0)
    r.check("die Option heißt jetzt »Hier ist dein Bier.«",
            "Hier ist dein Bier." in s.since(m))
    s.send("4", 0.6)
    r.check("Börty freut sich", s.wait("Da ist sie ja!", 20))
    r.check("die Kiste ist aus dem Inventar", s.wait("»Börtys Bierlieferung« abgegeben", 20))
    r.check("30 Bits Belohnung", s.wait("+30 Bits Belohnung.", 20))
    r.check("Quest abgeschlossen", s.wait("»Bier für Börty«", 25))
    r.check("100 EXP Belohnung", s.wait("Questbelohnung: 100 EXP", 25))
    r.check("Börty bedankt sich", s.wait("Ein Problem gelöst.", 25))
    r.check("und Mitch bleibt das offene Thema",
            s.wait("Bleibt nur noch herauszufinden, wo Mitch abgeblieben ist.", 25))
    # Aus dem offenen Thema wird die eigene Quest: der Agent hakt nach.
    r.check("der Agent fragt nach Mitch",
            s.wait("Mitch ist also verschwunden?", 25))
    r.check("Börty weiß nicht, wo er steckt",
            s.wait("Keine Ahnung, wo er sein könnte", 25))
    r.check("und bittet um eine Nachricht",
            s.wait("melde dich bei mir", 25))
    r.check("neue Nebenquest »Michael Mitch. Vermisst«",
            s.wait("»Michael Mitch. Vermisst« erhalten", 25))
    s.send(b"\r", 1.2)
    leave(s, m)

    m = s.mark()
    s.cmd("inventar")
    r.check("Inventar öffnet", s.wait_from(m, "INVENTAR", 12))
    s.drain(0.8)
    r.check("die Lieferung ist weg", "Bierlieferung" not in s.since(m))
    r.check("Kontostand 48 (260-250+30+8 aus Aufstieg)",
            "48 Bits" in s.since(m))
    s.esc()
    s.drain(0.8)

    # Questlog: die Nebenquest steht unter »abgeschlossen«
    m = s.mark()
    s.cmd("questlog")
    r.check("Questlog öffnet", s.wait_from(m, "QUESTLOG", 15))
    s.send(RIGHT, 0.5)                      # Reiter: Nebenquests
    s.drain(0.5)
    sc = Screen(40, 110)                    # echten Schirm nachbauen
    sc.feed(bytes(s.buf[m:]))
    dump = sc.dump()
    r.check("»Michael Mitch. Vermisst« steht unter aktuell",
            "Michael Mitch. Vermisst" in dump)
    s.send(TAB, 0.5)                        # Fokus: Unterreiter
    s.send(RIGHT, 0.6)                      # Unterreiter: Abgeschlossen
    s.drain(0.6)
    sc = Screen(40, 110)                    # echten Schirm nachbauen
    sc.feed(bytes(s.buf[m:]))
    dump = sc.dump()
    r.check("»Bier für Börty« steht unter abgeschlossen", "Bier für Börty" in dump)
    r.check("mit dem Status abgeschlossen", "Status: abgeschlossen" in dump)
    s.esc()
    s.drain(0.8)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §7 Vermisste & Mitch bei den Zeugen
# Nach der Bierlieferung steht die Suche nach Mitch: Der Lagermeister
# (Samy) und der Wirt (Börty) geben die Hinweise, die im Questlog landen.
with start("mk_zeugen", {"CWD": LAGER, "SAMY_INTRO_DONE": 1, "ERMITTLER_DONE": 1,
                         "BOERTY_INTRO_DONE": 1, "VERMISSTE_GIVEN": 1,
                         "MITCH_GIVEN": 1, "BITS": 100}) as s:
    r = Report("7) Zeugen: »Vermisste Bewohner?« & »Michael Mitch?«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # --- Samy: die Vermissten (kurz, wie seine Art) -------------------
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.wait_from(m, "Ich bin immer noch schwer beschäftigt", 20)
    s.drain(1.2)
    r.check("Option »Vermisste Bewohner?« steht da", "Vermisste Bewohner?" in s.since(m))
    r.check("Option »Michael Mitch?« steht da", "Michael Mitch?" in s.since(m))
    s.send("2", 0.6)
    r.check("Samy kennt die Vermissten", s.wait("Vermisste.", 20))
    r.check("zählt aber nur Kisten, keine Namen",
            s.wait("ich zähle Bestand, keine Namen", 20))
    s.send(b"\r", 1.2)
    leave(s, m, "Sonst nichts. Ich geh zur Seite.")

    # --- Samy: Michael Mitch -> Hinweis Westdistrikt ------------------
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.drain(1.2)
    s.send("3", 0.6)
    r.check("Samy kennt Mitch", s.wait("Ruhiger Kerl. Pünktlich wie ein Ladeplan.", 20))
    r.check("und nennt den Westdistrikt", s.wait("im Westdistrikt gesehen", 20))
    r.check("die Spur landet im Questlog",
            s.wait("Michael Mitch wurde zuletzt im Westdistrikt gesehen", 20))
    s.send(b"\r", 1.2)
    leave(s, m, "Sonst nichts. Ich geh zur Seite.")

    # --- Börty: die Vermissten -> Verweis auf Sherlock Holmes ---------
    m = s.mark()
    s.cmd("cd %s" % KNEIPE)
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 25)
    s.drain(1.0)
    r.check("Börty hat die Option »Vermisste Bewohner?«",
            "Vermisste Bewohner?" in s.since(m))
    s.send("5", 0.6)
    r.check("er nimmt sich Zeit", s.wait("Setz dich, das ist ein langes Glas.", 20))
    r.check("beschreibt die Lage", s.wait("Die Leute sind einfach weg.", 20))
    r.check("und verweist auf Holmes", s.wait("Sherlock Holmes", 20))
    r.check("der an dem Fall arbeitet",
            s.wait("Sherlock Holmes arbeitet am Fall der Vermissten", 20))
    s.send(b"\r", 1.2)
    leave(s, m)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ==================== §8 Samy: Mitch-Option bei älterem Spielstand
# Nach der Bierlieferung (BIER_DONE), aber ohne das Mitch-Flag aus einer
# älteren Version: Die Option muss trotzdem da sein und die Quest
# nachholen.
with start("mk_mitch_nach", {"CWD": LAGER, "SAMY_INTRO_DONE": 1,
                             "BIER_DONE": 1, "MITCH_GIVEN": 0,
                             "BITS": 0}) as s:
    r = Report("8) Samy: »Michael Mitch?« auch bei altem Spielstand")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.wait_from(m, "Ich bin immer noch schwer beschäftigt", 20)
    s.drain(1.2)
    r.check("Option »Michael Mitch?« steht da",
            "Michael Mitch?" in s.since(m))
    s.send("2", 0.6)                  # Es ist wichtig! | Michael Mitch? | gehen
    r.check("Samy kennt Mitch",
            s.wait("Ruhiger Kerl. Pünktlich wie ein Ladeplan.", 20))
    r.check("Quest wird nachgeholt",
            s.wait("»Michael Mitch. Vermisst« erhalten", 20))
    r.check("und nennt den Westdistrikt",
            s.wait("im Westdistrikt gesehen", 20))
    s.send(b"\r", 1.2)
    leave(s, m, "Sonst nichts. Ich geh zur Seite.")
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ============ §9 Michael Mitch: Restaurant -> Börty -> Belohnung
# Der Agent hat die Mitch-Quest. Im Restaurant erzählt Mitch, warum er
# gegangen ist; die Quest führt zurück zu Börty. Dort beendet die Option
# »Wegen Mitch...« die Suche und startet die Gehilfen-Quest.
with start("mk_mitch_rest", {"CWD": RESTAURANT, "MICHAEL_INTRO_DONE": 1,
                             "MITCH_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                             "BIER_DONE": 1, "BOERTY_INTRO_DONE": 1,
                             "BOERTY_INFO": 1, "BITS": 0}) as s:
    r = Report("9) Michael Mitch: Restaurant, Börty & neue Gehilfen-Quest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # --- Im Restaurant: Mitch erzählt seine Geschichte -----------------
    m = s.mark()
    s.cmd("touch MichaelMitch")
    r.check("Mitch stellt sich vor", s.wait_from(m, "Michael Mitch.", 20))
    r.check("der Agent kommt von Börty",
            s.wait_from(m, "Börty schickt mich", 20))
    r.check("Mitch ist gegangen, ohne ein Wort",
            s.wait_from(m, "Ohne ein Wort", 20))
    r.check("er hatte Angst vor Börtys Reaktion",
            s.wait_from(m, "Angst", 20))
    r.check("im Restaurant gefällt es ihm besser",
            s.wait_from(m, "Hier gefällt es mir besser", 20))
    r.check("Börty zahlt zu wenig",
            s.wait_from(m, "Börty zahlt einfach zu wenig", 20))
    r.check("der Agent will es Börty sagen",
            s.wait_from(m, "Ich werde es ihm überbringen", 20))
    r.check("Questlog-Spur im Dialog",
            s.wait_from(m, "Mitch ist aufgetaucht", 20))
    r.check("neues Ziel führt zu Börty",
            s.wait_from(m, "Geh zu Börty", 20))
    r.check("keine Skriptfehler im Mitch-Gespräch",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))
    s.send(b"\r", 1.2)

    # --- Bei Börty: »Wegen Mitch...« -----------------------------------
    m = s.mark()
    s.cmd("cd %s" % KNEIPE)
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 25)
    s.drain(1.0)
    r.check("neue Option »Wegen Mitch...«",
            "Wegen Mitch..." in s.since(m))
    s.send("5", 0.6)                        # ... vor dem Abschied
    r.check("Börty fragt nach Mitch",
            s.wait("Du hast ihn gefunden?", 20))
    r.check("Mitch arbeitet im Restaurant",
            s.wait("Im Restaurant.", 20))
    r.check("Mitch nennt den schlechten Lohn",
            s.wait("du zahlst zu wenig", 20))
    r.check("Börty schimpft",
            s.wait("Dieser Hund", 20))
    r.check("der Agent nennt das bessere Gehalt",
            s.wait("besser bezahlen", 20))
    r.check("Börty braucht einen neuen Gehilfen",
            s.wait("neuen Gehilfen", 20))
    r.check("und kann selbst nicht weg",
            s.wait("ich komm hier nicht weg", 20))
    r.check("er bittet um einen Gefallen",
            s.wait("noch einen Gefallen", 20))
    r.check("der Agent fragt nach einem Neuen",
            s.wait("jemand Neues", 20))
    r.check("er verspricht nichts",
            s.wait("Ich verspreche nichts", 20))
    r.check("Mitch-Quest wird abgeschlossen",
            s.wait("QUEST ABGESCHLOSSEN", 20))
    r.check("250 EXP Belohnung",
            s.wait("Questbelohnung: 250 EXP", 20))
    r.check("20 Bits Belohnung",
            s.wait("+20 Bits Belohnung", 20))
    r.check("neue Nebenquest wird vergeben",
            s.wait("»Ein neuer Gehilfe für Börty« erhalten", 20))
    r.check("neues Ziel nennt die Gehilfen-Suche",
            s.wait("Halte Ausschau", 20))
    r.check("keine Skriptfehler bei Börty",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))
    s.send(b"\r", 1.2)
    leave(s, m)

    # --- Die Option verschwindet, die Bits sind gutgeschrieben ----------
    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 25)
    s.drain(1.0)
    r.check("»Wegen Mitch...« ist nach dem Abschluss weg",
            "Wegen Mitch..." not in s.since(m))
    s.send("5", 0.6)                        # Abschied (Option 4 = Vermisste)
    r.check("Börty verabschiedet den Agenten",
            s.wait("Alles klar", 20))
    s.send(b"\r", 1.0)

    m = s.mark()
    s.cmd("inventar")
    r.check("28 Bits sind auf dem Konto (20 + 8 aus Aufstieg)",
            s.wait_from(m, "28 Bits", 12))
    s.esc()
    s.drain(0.8)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print()
if fails:
    print("MARKT-TEST: %d Fehler" % fails)
else:
    print("MARKT-TEST: 0 Fehler")
sys.exit(1 if fails else 0)
