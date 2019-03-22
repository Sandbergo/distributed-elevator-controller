# Elevator Design Presentation

Før vi setter i gang, kan det være nyttig å vite at vi har valgt å gjøre vårt design i Elixir, fordi det virket som en god utfordring og fordi Elixir har mye interessant innebygd funksjonalitet.

Presentasjonen er delt opp i fire deler:
1. Oversikt over våre moduler, med et medfølgende klassediagram
2. En demonstrasjon av en "happy path" med et sekvensdiagram
3. En diskusjon av potensielle feil og feilhåndtering
4. Et sekvensdiagram som ser på en feilhåndtering og recovery

### 1. Moduler
Dette klassediagrammet viser modulene vi har valgt, samt utvalgte metoder som viser hvordan de kommuniserer med hverandre. 
Først er det verdt å nevne at vi følger elixirs navnekonvensjon, moduler er CamelCase, alt annet er snake_case.

Vi leser diagrammet fra øverst til høyre:
 - Først har vi den gitte DriverInterfacen, som vi ikke har endret på.
 - Modulen "Poller" gir et ekstra abstraksjonslag til driveren, ved å loope og sende knappetrykk som meldinger og sende medlinger om etasje-endring til statemachinen. Eventuelt kan polleren merge med Drieren, men vi var usikre på om det var tillatt i oppgaven å modifisere den gitte kodebasen.
 - StateMachine har strukten direction og floor, mottar kommandoer og bekrefter gjennomførelse
 - OrderHandler har en ordrematrise, og kan regne ut en kostnadsfunksjon for en heis i en gitt tilstand, der heisen med den laveste costen blir sendt ordren. Orderen kan være ubekreftet, bekreftet og sendt. Hele ordrematrisen deles.  
 - NetworkHandler har ansvaret for oppstart av nettverket, og har også mulighet til å fange opp noder som taper forbindelse og restarte noder eller nettverk 
 - WatchDog tar seg av feil som ikke er nettverksrelaterte i den forstand at de lar seg løse av NetworkModule, eksempel på dette er ordre som ikke blir gjennomført p.g.a motorstopp.  

### 2. Happy path
Først litt om initialiseringen:
Under oppstart brukes NetworkHandler.init_nodes() der UDP-broadcast av IP-addresse og initialisering av prosesser, lagring av PID. 

Sekvensdiagram 1 er et eksempel på en enkel kjøring, der en ordre sendes og en heis kjører. _forklare flyten i diagrammet_

### 3. Feilhåndtering

Baserer oss på å merge error modes, at mest mulig håndteres likt med full prosess-restart og refordeling av ordrene som var i bekreftet tilstand. Mange feil unngås enkelt med bruk av Elixirs innebygde bibliotek, noder som faller av nettverket gir automatisk melding, multicast vil vente på bekreftelse før den går videre. En ordre bekreftes først etter at den er sendt til en heis, og slettes ikke før dørene er åpne. 

Vi har gjennomgått følgende feil:
- PC krasjer/mister strøm:
  - NetworkModule vil merke at nodene mistes, og initialiseringen av en node blir forsøkt på ny, restart av alle prosesser tilhørende den noden. 
- Heis henger, f.eks. motorstopp
  - WatchDog merker at ordre timer ut, refordeler oppgaven og deretter sender restartmelding til nettverksmodulen. 
- Pakketap
  - bruker multicast med timeout basert på TCP, ordre bekreftes ikke før vi er sikre på at en heis er på vei.
- Node mister nettverk
  - Merkes av NetworkModule, behandles likt som strømbrudd. Refordeling og forsøk på å restarte. 
- Brukeren "troller"
  - Poller er statemachine, multiple ordre er ikke et problem. Visse typer "trolling" kan være umulig å skille fra bruk (bestille heis åpen igjen og igjen i en etasje, "stalle" heisen) ignoreres 


### 4. Bad path

For å vise et eksempel på feilhåndtering, kan man se på situasjonen der heismotoren slutter å virke midtveis i en ordre. 




