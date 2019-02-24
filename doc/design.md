# Design review plan

Presentasjon på 10 minutter, må dekke punktene:
- How you solve the fault tolerance challenge.
- Which modules you have chosen to partition the system into. (Including "interfaces").

## Modules

Ønsker å begrense antall moduler til 5 - 7

#### Class Diagram




## Module Interfaces

Mål om å separere modulkommunikasjon så langt det lar seg gjøre



## Error Handling 

Bruke elixirs innebygde supervisors til å håndtere feil og restarte systemet, 

## Scenarios


To enkle suksesscenarioer
- startup, bestilling, ordre gjennomføres mest effektivt
- startup, tre heiser, tre bestillinger gjennomført mest effektivt

#### Sequence Diagram 1

Tre errorscenarier
- pakketap
- motorstopp
- connection loss

#### Sequence Diagram 2