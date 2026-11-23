# ============================================================
#  Unit-Test-Teil: Zusammenfassung und Exit-Status
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ------------------------------------------------------------------
printf '\n============================================\n'
printf 'UNIT-TESTS: %d Checks, %d Fehler\n' "$((PASS+FAIL))" "$FAIL"
printf '============================================\n'
[ "$FAIL" = 0 ]
