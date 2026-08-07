# Perimetro funzionale — di cosa è fatto Halo

> Cosa deve avere il prodotto, indipendentemente dal calendario di lancio.
> `docs/PRODOTTO.md` dice *perché* Halo esiste, questo file dice *di quali
> pezzi è fatto*, `docs/launch/FEATURE-LANCIO.md` dice *quali di questi pezzi
> servono entro agosto*.
>
> Stato verificato sul modello dati e sul codice al 2026-08-06.

---

## 0 · La cosa da vedere prima di tutto

Halo completo sono **circa quindici funzioni**, non quaranta. La categoria non
premia l'ampiezza: BeReal era un bottone, Locket è una foto in un widget.

Il repo oggi ha Discovery, checkout Stripe, dashboard Clubs, billing
ricorrente, archivio Memory e upsell Plus — tutta roba di anello esterno — e
gli mancano **tre delle sette funzioni del nucleo**. È stato costruito il
perimetro prima del centro.

Il caso più netto: la tabella `follows` non registra **dove vi siete
incontrati**. Halo dichiara di essere la rete delle persone incontrate
davvero, e il database non sa dirlo di nessuna relazione.

---

## 1 · Nucleo — senza queste non è Halo, è un'altra app

| # | Funzione | Nel codice oggi |
|---|---|---|
| C1 | **Prova di co-presenza**: un Ring, un token che scade, un QR che genera la prova "eravamo lì nello stesso momento" | ✅ `rings`, `ring_members`, `event_checkins`, scanner QR, join token |
| C2 | **Provenienza della relazione**: ogni legame porta con sé dove e quando è nato | ❌ `follows` ha solo `tier`, `proposed_tier`, `created_at` |
| C3 | **Roster di co-presenza**: dopo lo scan vedi le persone e le aggiungi | ❌ oggi sono due contatori in `EventRingView` |
| C4 | **Grafo graduato che si muove da solo**: la distanza si deriva dal comportamento, non si dichiara | 🟡 tier e trigger esistono, ma `ChooseYourFiveView` chiede ancora la tassonomia al primo avvio |
| C5 | **Presenza leggera**: la vibe — mood, colore, una riga, 24h | ✅ 8 mood, nota ≤140, scadenza 24h |
| C6 | **Momenti a basso costo**, effimeri di default | ✅ foto/testo/audio, `easy` 3h / `standard` 72h, `min_tier` |
| C7 | **Risposta**: reazione in un tap **e** replica 1:1 effimera | 🟡 6 glifi ci sono, la reply no |
| C8 | **Il widget**: la presenza degli altri senza aprire niente | 🟡 esiste in lettura, non si può reagire da lì |

Sono otto, non sette, perché C2 e C3 sono la stessa idea vista da due lati: la
prova di co-presenza è inutile se non diventa una relazione (C3) e non resta
attaccata alla relazione (C2).

### Perché C2 non è un dettaglio da database

Con la provenienza, Halo può fare tre cose che nessuno può copiare senza
rompersi:

1. **Mostrare perché una persona è nella tua rete** — "conosciuta il 3 ottobre,
   Ring Aperitivo Bocconi". Un profilo che non ha bisogno di una bio.
2. **Difendersi dallo sporcamento del grafo nel tempo.** Ogni rete chiusa si
   sporca: fra due anni metà dei contatti sarà rumore. Se la relazione porta
   la propria origine, il decadimento è calcolabile invece che arbitrario.
3. **Rendere possibile il ricordo** (E1): senza provenienza, "il giorno dopo"
   e l'archivio Memory non hanno da cosa partire.

È una migration piccola (`follows.origin_ring_id`, `met_at`) e sblocca metà
dell'anello successivo.

---

## 2 · Completamento — ciò che rende il nucleo abitabile

| # | Funzione | Nel codice oggi |
|---|---|---|
| P1 | **Notifiche, quattro categorie e mai una quinta**: invito ricevuto · vibe di un Inner · reazione o reply su una cosa tua · richiamo del giorno dopo | ❌ nessuna infrastruttura push |
| P2 | **Inviti aperti**: un link che funziona su un telefono senza app e per chi non è iscritto, con codice breve di riserva | ❌ `invites.invitee_id` è `NOT NULL` |
| P3 | **Identità minima**: faccia, nome, dove vi siete incontrati. Niente bio da curare, niente numeri | 🟡 `profiles` ha ancora `bio`, che è una superficie da performance |
| P4 | **Audience senza selettore**: chi vede cosa lo decide la distanza, non un menu a tendina | 🟡 `min_tier` esiste ed è la strada giusta; va reso invisibile |
| P5 | **Sparire senza uscire**: mettere in pausa la propria presenza per un giorno | ❌ in una rete di gente che ti conosce davvero pesa più che in una di estranei |
| P6 | **Chiudere una relazione senza dramma**: allontanare in silenzio, decadimento per inattività | 🟡 `unfollow` esiste, il decadimento no |
| P7 | **Sicurezza**: blocco, segnalazione, uscita da un Ring | ✅ `blocks`, `reports` |
| P8 | **Obblighi**: cancellazione account, export dei propri dati, età, moderazione operativa | ❌ nessuno dei quattro |

P5 e P6 sono le funzioni che di solito mancano nelle app "solo amici veri", e
sono il motivo per cui poi le si abbandona invece di lasciarle: quando non
puoi allontanarti da qualcuno senza un gesto visibile, l'unica uscita è
smettere di aprire l'app.

---

## 3 · Estensione — dopo la prova di ritenzione, non prima

| # | Funzione | Nota |
|---|---|---|
| E1 | **Memoria**: l'archivio di ciò che sarebbe scaduto | È l'unica cosa per cui vale la pena pagare in un prodotto effimero: l'effimero gratis, il ricordo a pagamento. Dipende da C2 |
| E2 | **Live Activity durante un Ring attivo** | Mentre l'evento succede, Halo sta nella Dynamic Island con "12 persone qui". Trasforma l'app in un oggetto presente all'evento |
| E3 | **Tap fisico tra due telefoni** (NFC/NameDrop-style) | La versione più pura di C1: la prova è il gesto, senza QR e senza evento |
| E4 | **Ring ricorrenti** (corso, club, associazione) | Impalcatura §5: deve staccarsi senza rompere niente |
| E5 | **Secondo campus** | Si apre quando il primo è denso, e lo apre la rete (gli exchange), non il fondatore |

Tutto quello che oggi è in `Features/Plus`, `Features/Discovery` e la parte
billing di `Features/Rings` sta qui o fuori del tutto, non nel nucleo.

---

## 4 · Le funzioni di sistema valgono come feature

Halo vive di ritorno passivo, quindi le superfici iOS non sono contorno:

- **Widget lockscreen e StandBy** — il pavimento della ritenzione (C8).
- **`AppIntent`** — reagire senza aprire l'app; e Shortcuts gratis.
- **Live Activity** — l'evento in corso (E2).
- **Universal links** — la porta di ingresso reale, non lo scheme `halo://`.
- **Push** — il sistema nervoso (P1).

Sono cinque integrazioni di piattaforma: tre non esistono ancora nel repo.

---

## 5 · Cosa non deve avere, mai

Elenco vincolante di `docs/PRODOTTO.md` §8, ripetuto qui perché è la metà del
perimetro che conta di più: niente feed pubblico, reach algoritmica, creator
economy, profili scopribili, metriche pubbliche, mappa geografica,
messaggistica, ticketing.

Aggiungo tre confini che nascono da questo documento:

- **Niente CRM.** Provenienza e decadimento (C2, P6) servono al prodotto, non
  all'utente: nessuna schermata deve mai dire "non parli con Marco da 3 mesi".
  Il momento in cui Halo ti fa sentire in debito verso i tuoi amici, ha perso.
- **Niente presenza in tempo reale come posizione.** La vibe dice come stai,
  non dove sei.
- **Niente numeri accanto alle persone.** Nessun contatore, da nessuna parte,
  nemmeno "12 membri" nella UI utente.

---

## 5-bis · Le sei funzioni aggiunte dalla verifica

`docs/VERIFICA-OBIETTIVI.md` ha messo la lista contro gli obiettivi e ne ha
trovate sei che mancavano. Motivazione estesa lì, qui restano per completezza
dell'elenco.

| # | Funzione | Anello |
|---|---|---|
| M1 | Il primo minuto da solo — chi installa fuori da un evento apre un'app vuota | nucleo |
| M2 | Ring in dieci secondi, creato da chiunque (oggi è un form da dieci campi) | nucleo |
| M3 | Il primo segnale non lo dà l'utente — il Ring produce la prima card | completamento |
| M4 | Misurare la densità reciproca, non il volume di eventi | interna |
| M5 | L'host è il moltiplicatore — risultato privato del suo Ring | estensione |
| M6 | Cosa resta quando il Ring scade: il Ring finisce, le persone restano | completamento |

M1 e M2 sono nucleo, non completamento: senza M1 il lancio perde la
maggioranza dei download, senza M2 il campus 2 lo apre il fondatore invece
della rete — cioè l'obiettivo §6 di `PRODOTTO.md` non è raggiungibile.

---

## 6 · L'ordine con cui si costruisce

```
C1 ─► C3 ─► C2 ─► C4        la rete si forma e si spiega da sola
        │
        └─► C5 ─► C7 ─► P1 ─► C8        la rete si muove e ti richiama
                          │
                          └─► P5/P6/P8   la rete si può abitare a lungo
                                  │
                                  └─► E1  la rete diventa qualcosa da tenere
```

Sopra la linea `C1 → C3 → C2` non c'è niente da ottimizzare: finché lo scan
non produce relazioni con una provenienza, ogni altra funzione lavora su un
grafo che non esiste.
