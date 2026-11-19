# Skóre a vzorce

Vlastní, dokumentované vzorce. Algoritmus Astromatu není známý a shoda bodů
s ním není cílem.

## Stav planety (`planetScore`)

| Složka | Body |
|---|---|
| sídlo (vládne) | +5 |
| povýšení | +4 |
| zničení | −5 |
| pád | −4 |
| úhlový dům (1, 4, 7, 10) | +2 |
| dům 6, 8, 12 | −1 |
| retrográdní (mimo Slunce a Měsíc) | −1 |
| každý harmonický aspekt (sextil, trigon) | +1 |
| každý napěťový aspekt (kvadrát, opozice) | −1 |

Záporné skóre → stinná stránka planety jde ve výkladu před základní text (plán 4.1).

Vládci: tradiční i moderní (Mars i Pluto ve Štíru, Saturn i Uran ve Vodnáři,
Jupiter i Neptun v Rybách). Povýšení sedmi klasických planet podle tradice;
u moderních je volba sporná, zvoleno: Uran ve Štíru, Neptun v Raku, Pluto ve Lvu.

## Orby

| Aspekt | Výchozí | Těsné orby |
|---|---|---|
| konjunkce, opozice | 8° | 3° |
| trigon, kvadrát | 6° | 3° |
| sextil | 4° | 3° |
| se Sluncem nebo Měsícem | +2° | +1° |
| ASC, MC, uzel | 3° | 3° |
| tranzity | 1° | 1° |

Aspekt se sbíhá (`applying`), když se odchylka od přesného úhlu zmenšuje.
Úhly mají v nativním horoskopu rychlost 0.
