# Halo — revisione UI/UX contro i docs

> Ogni superficie dell'app passata alle cinque domande di `docs/PRODOTTO.md` §9
> e alle quattro di `docs/DESIGN.md` §7.
>
> `docs/PRODOTTO.md` dice **cosa è Halo**. `docs/DESIGN.md` dice **come si
> vede**. Questo file dice **cosa nell'app non è ancora d'accordo con loro**, e
> cosa è stato corretto passando.
>
> Revisione del 6 agosto 2026, subito dopo l'applicazione di `DESIGN.md` al
> layer token (#44).

---

## 0 · Il punto di partenza

Il commit #44 ha cambiato i **valori** dei token mantenendo ogni simbolo: niente
accent di brand, una famiglia di font, raggi morbidi, colore solo dai mood. È
stata la scelta giusta — ~24 superfici hanno ereditato la direzione senza un
refactor di massa.

Ma un token non può decidere *quali schermate esistono*, *in che ordine si
incontrano* e *come si chiamano*. Quella parte è rimasta ferma alla fase
precedente, e lì stanno tutti i disallineamenti veri.

La sintesi in una riga:

> **L'app oggi mette l'impalcatura e le feature congelate in primo piano, e il
> core in fondo a un pannello.**

---

## 1 · Verdetto per superficie

Legenda: ✅ allineata · ⚠️ allineata con debito · ❌ contraddice i docs.

| Superficie | File | Ruolo (§3 DESIGN) | Verdetto | Motivo |
|---|---|---|---|---|
| Sign in | `SignInView` + `WelcomeManifestoView` | guscio | ⚠️ | Il claim è in inglese e non è la tesi di §1. Il "ledger" mostra `likes 00 / inner 05 / feed NO`: metriche finte per dire che non ci sono metriche |
| Onboarding identità | `OnboardingView` | guscio | ✅ | Handle, nome, avatar. Corto, una volta, giustificato |
| **Scegli i tuoi 5** | `ChooseYourFiveView` → `InitialInnerCircleView` | — | ❌ | PRODOTTO §7 lo chiama *«il singolo errore di prodotto più grave nel repo»* ed è ancora un gate obbligatorio in `RootView` |
| Verifica Bocconi | `BocconiVerifyView` | guscio | ⚠️ | Impalcatura corretta (§5), ma sta nel pannello comandi *sopra* il Ring, che è core |
| Home / campo orbitale | `HomeView` | atto | ⚠️ | La superficie giusta, con la vocabolario sbagliata ("Orbita", "STORIES", "Moment") |
| Pulse | `PulseFeedView` | atto | ⚠️ | Feed cronologico solo fra mutui: non viola §8. Ma "Pulse" e "Moment" sì (§7) |
| Stato | `StatoView` | atto | ⚠️ | Terza vista sugli stessi dati (vedi §4 qui sotto) |
| Compose | `VibeFirstComposeView`, `EasyComposeView` | atto | ✅ | Vibe-first, effimero, basso costo. Esattamente R1 |
| HaloSpace | `HaloSpaceView` | atto | ⚠️ | Nome interno esposto all'utente ("HALO / SPACE") |
| **Event / Club Ring** | `EventRingView`, `ClubRingView` | guscio | ❌ | È **il core** (§5) e per raggiungerlo servono 4 tap dentro il profilo, sotto Discovery e Halo Plus |
| Profilo | `ProfileView` | misto | ❌ | Tre pannelli su cinque sono feature congelate da §8 |
| **Discovery** | `DiscoveryView` | — | ❌ | §8: profili pubblici congelati. È in cima al profilo, come azione della rail |
| **Halo Plus / Memory** | `PlusUpsellView`, `MemoryArchiveView` | — | ❌ | §8: paywall e StoreKit congelati. Hanno un pannello dedicato, un deep link e due entry point |
| Widget | `WidgetEntryView` | atto | ❌ | R5 chiede zero testo oltre alle iniziali: ci sono tre contatori e una wordmark |

---

## 2 · I quattro disallineamenti che contano

### 2.1 · L'onboarding chiede il lavoro più difficile per primo

`RootView` ha cinque fasi, e la quarta è `ChooseYourFiveView`. PRODOTTO §7 non
lascia margine interpretativo: *«esce dall'onboarding»*. Le tre ragioni sono
già scritte lì e non le ripeto — la più concreta è la seconda: una matricola o
uno studente in exchange al giorno 1 **non conosce ancora cinque persone**, ed è
esattamente l'utente del pilot.

C'è anche un effetto collaterale che il documento non nomina: il gate sta
davanti alla Home, quindi sta anche davanti al **Ring aperto da un QR**. Chi
scansiona il codice alla Welcome Week, installa e si registra non atterra sul
ring dell'evento: atterra su una schermata che gli chiede di fare la tassonomia
della propria vita sociale. È il momento di massima intenzione dell'intero
funnel, speso sull'unica schermata che i docs vogliono eliminare.

### 2.2 · Il core è sepolto sotto l'impalcatura

L'ordine di `ProfileView.commandPanel`, dall'alto:

```
manda una vibe          → core
aggiungi un Moment      → core
verifica Bocconi        → impalcatura (§5)
Event Ring              → CORE — la prova di co-presenza, il cuore del prodotto
Club e corsi            → impalcatura (§5)
scopri account pubblici → congelato (§8)
```

La prova di co-presenza — *«È il cuore»*, §5 — è il quarto item di un pannello
dentro il quinto tab. Sopra di lei ci sono un acceleratore locale e, nella rail
in cima alla stessa schermata, la scorciatoia a Discovery.

§5 dice che oggi il rapporto core/impalcatura è invertito nell'architettura e
che *«non è un refactor urgente»*. Vero per le RLS. **Non** vero per la
navigazione: lì l'inversione costa un tap ogni volta che qualcuno incontra
qualcuno, cioè sul loop di acquisizione (§4).

### 2.3 · Le feature congelate occupano il posto migliore

§8 congela Halo+, paywall, StoreKit, Discovery, profili pubblici e Clubs B2B
*«fino a prova di ritenzione»*. Nell'app sono tutt'altro che congelate:

- `ProfileView` ha un pannello `memory` dedicato con due bottoni e un contatore
- la rail del profilo ha `scopri` come unica azione
- `commandPanel` ha `scopri account pubblici`
- `HomeView` monta due sheet (`MemoryArchiveView`, `PlusUpsellView`) e gestisce
  una route `.memory` da deep link
- `MemoryArchiveView` fa da imbuto verso `PlusUpsellView`

Non è solo superficie sprecata. Un pannello che vende un archivio a pagamento
insegna all'utente che i suoi contenuti hanno un valore da conservare — cioè
l'esatto contrario di R1, che vuole l'atto di condividere a costo psicologico
zero.

### 2.4 · Il vocabolario supera il budget di §7

Il budget è **tre termini nel first run**: Ring, Vibe, Halo. La dock, da sola,
ne spende quattro nuovi:

| Dove | Oggi | §7 |
|---|---|---|
| dock tab 1 | `Orbita` | ❌ superficie, non concetto |
| dock tab 2 | `Pulse` | ❌ nome interno |
| dock tab 4 | `Stato` | ❌ nome interno |
| dock centro | `Nuovo Moment` | ❌ «Moment» non sopravvive |
| header home | `+N STORIES · ADESSO` | ❌ termine di un'altra app |
| HaloSpace | `HALO / SPACE` | ❌ nome interno |
| profilo | `INNER / INVITE`, `inner`, `close`, `orbita` | ⚠️ i tier devono essere idraulica invisibile |

Nessuno di questi termini è difendibile con la domanda 4 di §9 (*«quale dei tre
esistenti elimini?»*), perché nessuno di essi è un concetto: sono i nomi che le
schermate hanno nel repo, arrivati in superficie per inerzia.

Nota separata, ma dalla stessa radice: `docs/growth/founder-circles.md` contiene
ancora *«Halo is a private social map for campus»*, che §7 marca ❌ per
l'aspettativa di geolocalizzazione.

---

## 3 · Il widget contro R5

R5 è la regola più netta del documento di design — *«il widget si disegna per
primo»*, *«zero testo oltre alle iniziali, nessun conteggio, nessun badge»* — ed
è quella con più violazioni per riga di codice:

| Famiglia | Cosa mostra | R5 |
|---|---|---|
| `accessoryCircular` | il numero totale di bolle al centro | ❌ conteggio |
| `accessoryRectangular` | wordmark `HALO` + `+N` di overflow | ❌ testo e conteggio |
| `systemMedium` (StandBy) | `NN live` in fondo | ❌ conteggio |

Le iniziali nelle bolle rettangolari sono l'unica cosa che R5 consente
esplicitamente, e sono corrette.

Il resto è la vecchia abitudine da dashboard: un widget che riporta *quanti*
invece di mostrare *chi*. La differenza non è cosmetica — un conteggio è una
metrica, e una metrica su una schermata di blocco è una richiesta di attenzione.
Il colore delle persone non chiede niente.

---

## 4 · Tre viste sullo stesso grafo

Non è una violazione dei docs, quindi non è un ❌ — ma è il debito strutturale
più grosso che la revisione ha trovato, e va registrato.

`HomeView` (campo orbitale), `PulseFeedView` (timeline) e `StatoView` (cluster
di mood) leggono lo stesso dato — chi c'è, con che mood, da quanto — e lo
disegnano tre volte, in tre linguaggi diversi, per 3.100 righe complessive. Il
commento in testa a `StatoView` lo dice da sé: *«Compagna di Pulse: Pulse = feed
temporale, Stato = mappa di stati»*.

Contro la domanda 3 di §9 (*acquisisce o trattiene?*): il campo orbitale
trattiene ed è la controparte in-app del widget, quindi è core. Le altre due
sono presentazioni alternative dello stesso segnale, e nessuna delle due
acquisisce.

Questa revisione **non** le unisce: è una decisione di prodotto, non un
adeguamento ai docs, e va presa guardando dei dati d'uso che non esistono
ancora. Ma finché restano tre, ogni cambiamento sulla presenza va fatto tre
volte — ed è il motivo per cui il vocabolario è scappato in tre direzioni.

---

## 5 · Cosa cambia questa revisione

Applicato, perché i docs lo prescrivono alla lettera:

1. **Il gate «scegli i tuoi 5» esce dall'onboarding** (PRODOTTO §7). La fase
   `.initialCircle` sparisce da `AppState` e `RootView`: dopo l'identità si
   atterra sulla Home — o sul Ring, se si è arrivati da un QR. La scelta
   manuale resta raggiungibile dal profilo come rifinitura, che è ciò che §7
   consente.
2. **Il Ring sale nella dock** (PRODOTTO §5). La prova di co-presenza diventa
   una destinazione di primo livello invece del quarto item di un pannello.
   La dock passa da `Orbita · Pulse · [+] · Stato · Tu` a
   `Halo · Adesso · [+] · Ring · Tu`; "come stanno" (l'ex tab Stato) diventa un
   controllo nell'header della schermata Halo, perché è una lettura alternativa
   dello stesso campo e non una quinta destinazione.
3. **Le feature congelate escono dalla UI** (PRODOTTO §8). Discovery, Halo Plus
   e Memory perdono ogni entry point: i pannelli del profilo, le sheet montate
   da `HomeView`, il listener StoreKit all'avvio. Il deep link `halo://memory`
   continua a risolvere — un URL pubblicato non deve rompersi — ma atterra sulla
   Home. Il codice resta in repo: sono congelate, non cancellate.
4. **Il vocabolario rientra nel budget** (PRODOTTO §7). La dock e la copy di
   first run usano parole comuni; restano Ring, Vibe e Halo. I nomi dei tier
   sono corretti alla fonte, in `FriendshipTier.label`, che li spegne in un
   colpo solo nelle nove superfici che li rendevano.
5. **Il widget rispetta R5** (DESIGN R5). Via i tre contatori e la wordmark:
   restano le bolle e le iniziali. Lo spazio liberato nel rettangolare va in due
   bolle in più — due persone invece di un numero. Il conteggio sopravvive solo
   come label VoiceOver, perché l'accessibilità non può leggere un colore.
6. **Il claim del sign in è la tesi di §1** (PRODOTTO §1). Era *«Your people,
   not your audience.»*: inglese, e una frase che dice cosa Halo non è. Sotto,
   la riga di metriche finte (`likes 00 · inner 05 · feed NO`) diventa tre righe
   senza numeri — dei contatori usati per dire che non ci sono contatori restano
   dei contatori, sulla prima schermata che l'utente vede.

Non applicato, e perché:

- **Unione di Pulse e Stato** — decisione di prodotto, serve un dato d'uso (§4
  qui sopra).
- **Estrazione della verifica campus dalle RLS** — §5 la chiama esplicitamente
  «non un refactor urgente». La navigazione era la parte urgente ed è fatta.
- **Rimozione dei `.ttf` e delle voci `UIAppFonts`** — tocca il progetto Xcode,
  già tracciata in `PLAN.md`.
- **Il test delle due schermate di DESIGN §6** — premium-ovunque contro
  guscio-premium-atto-banale, la domanda *«qui dentro ci posteresti una foto
  fatta male?»* a dieci persone. È il modo in cui la direzione visiva si
  verifica, e non si fa scrivendo codice.
- **La copy di Discovery, Halo Plus e Memory** — sono superfici congelate e
  irraggiungibili, quindi il loro vocabolario non è più in first run. Andrà
  ripulito quando e se verranno scongelate, non prima.

---

## 6 · Come si tiene allineata

Una superficie nuova, o una modificata, passa le nove domande dei due documenti
prima di essere scritta. Le tre che in questa revisione hanno pescato tutto:

- **PRODOTTO §9.2** — *sopravvive a Bocconi?* Ha trovato il Ring sotto la
  verifica campus.
- **PRODOTTO §9.4** — *costa un termine nuovo?* Ha trovato quattro termini nella
  sola dock.
- **DESIGN §7.4** — *funziona nel widget?* Ha trovato i contatori, e con loro
  l'abitudine da dashboard che li aveva messi lì.
