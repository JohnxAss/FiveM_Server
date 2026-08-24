Einfach Liste am linken oberen Rand. Funktionen aus dem Basic Admin werden aufgelistet und
können ausgewählt werden.

## Technik & Bedienung

- Umgesetzt als **NUI** (eigenes HTML/CSS/JS-Overlay), kein externes Framework.
- Bedienung per **Maus** (Klick). Solange das Menü offen ist, ist der Mauszeiger frei.
- `ESC` schließt das Menü.

## Aufbau

Das Menü hat zwei Ebenen:

**Ebene 1 – Hauptmenü**

```
┌──────────────────────────┐
│ Basic Admin          [X] │
├──────────────────────────┤
│ ▸ Fahrzeug spawnen       │
│ ▸ Teleport zu Markierung │
└──────────────────────────┘
```

**Ebene 2 – Fahrzeugliste** (nach Klick auf "Fahrzeug spawnen")

```
┌──────────────────────────┐
│ Basic Admin          [X] │
├──────────────────────────┤
│ ‹ Zurück                 │
│ [ Suchen…              ] │
│ SPORTWAGEN               │
│   Adder                  │
│   Zentorno               │
│ EINSATZFAHRZEUGE         │
│   Police Cruiser         │
│   …            (scrollt) │
└──────────────────────────┘
```

## Elemente

| Funktion               | UI-Element   | Position          | Default   | Attribut               |
| ---------------------- | ------------ | ----------------- | --------- | ---------------------- |
| "Basic Admin" anzeigen | Textanzeige  | Kopfzeile Links   |           |                        |
| Menü schließen         | Button `X`   | Kopfzeile Rechts  |           |                        |
| Funktionsliste         | Liste        | Body              |           | Ebene 1                |
| Zurück zur Ebene 1     | Button `‹`   | Body oben         |           | nur Ebene 2            |
| Fahrzeug suchen        | Textfeld     | Body oben         | leer      | Live-Filter, nur Ebene 2 |
| Kategorie              | Überschrift  | Body              |           | nur Ebene 2            |
| Fahrzeug wählen        | Listeneintrag| Body              |           | nur Ebene 2, scrollbar |

## Position & Größe

- Fest oben links (`top: 20px; left: 20px`), überlagert das HUD.
- Feste Breite; die Fahrzeugliste ist in der Höhe begrenzt und scrollt bei Bedarf.
