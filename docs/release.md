# Vydání

Pipeline je z repa Distribution (`scripts/align-project.sh`): `ci.yml` při každém
pushi, `release-ios.yml` a `release-android.yml` po tagu `v*` (skill `release-flutter`).

## Ruční kroky v účtech (jednou)

1. **GitHub**: repo `lioilsources/Astro`; GitHub Pages ze `main` `/docs`.
2. **Apple Developer**: App ID `com.ol1n.astro` (bez App Group a capabilities),
   distribuční profil App Store pro `com.ol1n.astro`; uložit k ostatním profilům
   do složky appky `Astro`.
3. **App Store Connect**: nová appka Astro, bundle `com.ol1n.astro`, primární jazyk čeština.
   - Privacy Policy URL: `https://lioilsources.github.io/Astro/privacy.html`
   - Support URL: `https://lioilsources.github.io/Astro/support.html`
   - Marketing URL: `https://olin.now/astro`
   - Ochrana soukromí: „Data Not Collected“.
4. **Google Play**: appka `com.ol1n.astro`, upload key do secrets (workflow vytvoří `key.properties`).
5. **Secrets**: `Distribution/scripts/setup-gh-secrets.sh --repo lioilsources/Astro --app Astro`.

## Před prvním vydáním rozhodnout a ověřit

- **Věková kategorie**: výklad obsahuje nefiltrované pasáže o smrti, nemoci,
  závislosti a násilí (plán 5.1, rizika). Dotazník obchodu vyplnit podle toho.
- **Export compliance**: `ITSAppUsesNonExemptEncryption = false`. Appka šifruje jen
  vlastní data v telefonu (AES-GCM, balíček `cryptography`); ověřit, že to spadá
  pod výjimku.
- **Linka pomoci**: text „Linka první psychické pomoci“ v appce nemá číslo; doplnit
  ověřené číslo (plán 5.1).
- **App Store 4.3(b)**: přesycená kategorie; začít TestFlightem (plán 9).
- **Obsah**: plná dávka textů (F3) až po schválení pilotu; bez ní appka u většiny
  postavení ukazuje „Text zatím chybí“.
- **Ikona**: pilot `app/assets/icon/icon.svg` čeká na schválení, pak `flutter_launcher_icons`.
