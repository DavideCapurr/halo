# Queste funzioni portano agli obiettivi?

> Verifica critica di `docs/PERIMETRO.md` contro gli obiettivi dichiarati in
> `docs/PRODOTTO.md`. Scritto per essere sgradevole dove serve: un elenco di
> feature che si auto-conferma non serve a niente.
>
> Data: 2026-08-06.

---

## 1 · Gli obiettivi, per come sono scritti

| | Obiettivo (`PRODOTTO.md`) |
|---|---|
| **O1** | 2-3 cluster densi e sovrapposti che completano il loop reciproco e tornano per quattro settimane (§10) |
| **O2** | Bocconi → campus 2 attraverso gli exchange, non attraverso il fondatore (§6) |
| **O3** | Una rete strutturalmente incompatibile con un business da reach (§3) |

---

## 2 · Il verdetto per obiettivo

### O1 — attivazione e ritorno · **le funzioni ci sono, tre sono assenti**

Il percorso `incontro → scan → roster → relazione reciproca → vibe → risposta
→ ritorno` è coperto da C1, C3, C5, C7, C8 e P1. Due dei sei anelli non
esistono ancora (roster e push), ma sono identificati e non c'è niente di
concettualmente irrisolto. **Questa parte del prodotto è pensata bene.**

### O2 — la macchina per il campus 2 · **scoperto**

`PRODOTTO.md` §6 dice che il gradino difficile è Bocconi → Bocconi+1, e che la
risposta giusta è "gli exchange tornano a Madrid con il loro Ring già vivo".

Nel perimetro questo è un item passivo (E5, "secondo campus"). **Nessuna
funzione della lista fa viaggiare la rete.** Cosa fa concretamente in Halo uno
studente che torna a Madrid a gennaio? Oggi: niente. Se non può creare un Ring
a Madrid in dieci secondi, il campus 2 lo apre di nuovo il fondatore — cioè il
tapis roulant che §6 dichiara di voler evitare.

Verificato: la creazione di un Ring oggi è un form da dieci campi (titolo,
sottotitolo, luogo, inizio, fine, pubblico, approvazione, limite membri,
prezzo). È una schermata da amministratore di eventi, non un gesto da studente
in un bar. Vedi M2.

### O3 — il moat · **coerente, e la disciplina regge**

Niente nella lista introduce reach, estranei o creator economy, e la lista dei
"mai" è più lunga di quella dei "sì". Su questo non ho critiche: è la parte più
solida del progetto.

---

## 3 · Il rischio strutturale che nessun documento nomina

Una rete chiusa alle sole relazioni reali ha **poco contenuto**. È matematica,
non esecuzione: 30 persone che conosci davvero producono qualche post a
settimana, non un feed.

Il cimitero della categoria è pieno di app morte esattamente qui — Path aveva
il limite a 150 persone, relazioni vere, un design migliore di Instagram, ed è
morta. Non per mancanza di feature: perché aprivi e non c'era niente.

La risposta giusta esiste ed è già nella tesi: **la presenza, non il
contenuto**. Una vibe non richiede che accada niente, e il widget funziona
anche a feed vuoto. È la scommessa corretta.

Ma il prodotto costruito finora non la riflette:

- la superficie principale è un feed (`HomeView`, 1.6k righe, più `Pulse`);
- il gesto centrale è comporre (`VibeFirstComposeView`, `EasyComposeView`,
  `ComposePostView`, dock di compose);
- la presenza vive in un widget **in sola lettura**.

> **Il test da superare: l'app deve essere buona in un giorno con zero post.**
> Oggi, in un giorno con zero post, Halo è una schermata vuota.

Non è un problema di priorità di lancio, è un problema di forma. Se il feed
resta il centro, Halo eredita il fallimento di Path anche facendo tutto il
resto giusto.

---

## 4 · Le sei funzioni che mancano alla lista

Numerate in continuità con `docs/PERIMETRO.md`.

### M1 · Il primo minuto da solo · nucleo
Chi installa Halo fuori da un evento apre un'app vuota, e non torna. Nessuna
funzione della lista copre questo caso, che è **la maggioranza dei download**
la settimana del lancio.

Due strade, entrambe accettabili, la seconda migliore:
1. l'onboarding non può finire senza uno scan — l'ultima schermata è la
   fotocamera;
2. l'app lo dice apertamente: *"Halo non serve da solo. Torna quando incontri
   qualcuno."* — e mette un promemoria. È l'unica onestà possibile, ed è
   coerente con un prodotto che rifiuta di riempire il vuoto con estranei.

### M2 · Ring in dieci secondi, creato da chiunque · nucleo
Un campo — il nome — e un QR. Niente prezzo, niente limiti, niente
approvazione: quelli restano nel Ring "club/corso", che è impalcatura.
È **la macchina di O2**: senza, il campus 2 non si apre da solo.

### M3 · Il primo segnale non lo dà l'utente · completamento
In ogni cluster nuovo tutti aspettano che qualcun altro pubblichi per primo.
Il Ring stesso deve produrre il primo oggetto: dopo l'evento, una card
"eravate in 14" nel feed di tutti i presenti, su cui si può reagire. Costa
poco, elimina la pagina bianca e la prima reazione è già un atto reciproco.

### M4 · Misurare la densità, non il volume · funzione interna
`analytics_events` conta eventi. O1 non parla di eventi, parla di **cluster
densi e sovrapposti**: serve una misura di reciprocità media per utente e di
sovrapposizione fra cluster. Senza, a fine orientation week si saprà quanti
download, che è il numero che `PRODOTTO.md` §10 dichiara esplicitamente di
non voler inseguire.

### M5 · L'host è il moltiplicatore · estensione
Chi crea un Ring vale venti utenti. Dargli, in privato, il risultato del suo
lavoro ("hai fatto incontrare 14 persone") è l'incentivo che produce il Ring
successivo.

*Tensione dichiarata:* `PERIMETRO.md` §5 vieta i numeri accanto alle persone.
Qui il numero non è accanto a una persona ed è privato — ma è comunque una
metrica di performance, e va tenuta d'occhio: se un giorno diventa pubblica,
o comparativa, ha rotto la regola.

### M6 · Cosa resta quando il Ring scade · completamento
I Ring hanno `expires_at`, le relazioni no. Va detto in modo esplicito nel
prodotto: il Ring finisce, le persone restano. È anche il momento naturale in
cui mostrare M3 e chiedere l'unica cosa che conta — chi vuoi tenere.

---

## 5 · Le tre cose che decidono il successo, e non sono feature

Rispondo alla domanda "queste funzioni mi faranno avere successo" senza
addolcirla: **no, non da sole, e non sono il vincolo attuale.**

### R1 · La domanda di validazione non è ancora stata fatta a nessuno
`PRODOTTO.md` §10 dice che il prossimo deliverable non è codice, ed è una
domanda da fare a persone vere: *"pensa all'ultima persona interessante che
hai conosciuto a un evento — che fine ha fatto?"*. Un mese dopo, il repo
contiene dieci PR di polish visivo e zero conversazioni registrate.

Costo: venti conversazioni, due giorni. Se la risposta prevalente è "c'è il
gruppo WhatsApp, funziona", tutto il resto di questo documento è irrilevante.

### R2 · Il collo di bottiglia è umano, ed è fermo
`docs/growth/founder-circles-tracker.csv` ha ancora venti righe con
`status=target` e nessun lead. I venti Founder Circle **sono** il lancio: il
prodotto rende possibile la densità, non la produce.

### R3 · La ritenzione è un'ipotesi, non un risultato
Che una vibe su un widget faccia tornare qualcuno per quattro settimane non è
dimostrato da nessuna parte. È una scommessa ragionevole e ben argomentata, ma
finché non ci sono cluster reali alla settimana 2, resta tale. Il piano deve
prevedere che la risposta sia no.

---

## 6 · Cosa cambierei, in una riga per punto

1. Chiudere il nucleo nell'ordine `C3 → C2 → P1` (roster, provenienza, push).
2. Aggiungere **M1** e **M2** al nucleo: senza il primo il lancio perde la
   maggioranza dei download, senza il secondo non esiste il campus 2.
3. Spostare il centro dal feed alla presenza — il test è il giorno con zero
   post (§3).
4. Fare **R1 questa settimana**, in parallelo al codice: costa due giorni ed è
   l'unica cosa che può invalidare tutto il resto.
5. Mettere **R2** in mano a una persona con un nome e una scadenza, oggi.
