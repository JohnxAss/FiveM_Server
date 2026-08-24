## Fahrzeug Spawnen

Öffnet eine Liste mit Fahrzeugen zum Auswählen. Das ausgewählte Fahrzeug wird nahe dem
Spieler gespawnt.

**Auswahl**
- Die Fahrzeuge sind nach Kategorien gruppiert (Sportwagen, Limousinen, Geländewagen,
  Motorräder, Einsatzfahrzeuge, Luftfahrzeuge, Nutzfahrzeuge, Boote).
- Ein Suchfeld filtert live über **alle** Kategorien – gesucht wird sowohl im Anzeigenamen
  ("Adder") als auch im Modellnamen ("adder").
- Der Fahrzeugkatalog liegt in der `config.lua` der Resource und dient gleichzeitig als
  Whitelist: Der Server spawnt nur Modelle, die dort eingetragen sind.

**Spawn-Verhalten**
- Das Fahrzeug erscheint ca. 3 m vor dem Spieler, in dessen Blickrichtung quer
  ausgerichtet, und wird sauber auf den Boden gesetzt.
- Der Spieler steigt **nicht** automatisch ein.
- Zuvor gespawnte Fahrzeuge werden vom Basic Admin **nicht** gelöscht (siehe Abgrenzung in
  [[Basic Admin]]). Sie werden aber auch nicht künstlich festgehalten – die Engine darf sie
  wie normale Weltfahrzeuge aufräumen, wenn der Spieler weit genug entfernt ist.
- Nach dem Spawn schließt sich das Menü.

**Fehlerfall**
- Modell lässt sich nicht laden (Timeout) → Notification "Fahrzeug konnte nicht geladen
  werden".

## Teleport zu Kartenmarkierung

Der Spieler wird zu der selbst gesetzten Kartenmarkierung teleportiert.

- Ist **kein** Wegpunkt gesetzt → Notification "Kein Wegpunkt gesetzt", das Menü bleibt
  offen.
- Die Kartenmarkierung liefert nur X/Y-Koordinaten. Die Z-Höhe (Bodenhöhe) wird ermittelt,
  indem gestaffelte Höhen von unten nach oben durchprobiert werden, bis der Boden gefunden
  ist. Dadurch landet der Spieler nicht unter der Map und fällt nicht ins Leere.
- Sitzt der Spieler in einem Fahrzeug, wird das **Fahrzeug samt Insassen** teleportiert.
  Zu Fuß wird nur der Spieler teleportiert.
- Bei Erfolg wird der Wegpunkt entfernt und das Menü geschlossen.
