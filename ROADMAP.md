# Trans AI Road Map


## Air Route ##
### Aircraft ###
- [x] The aircraft service shall be used to transport passenger from town to town. Build any available airport and airplane type, including chopper.
### Chopper ###
- [ ] Additional chopper service shall only be used to transport passenger from town to oil rig.
## Road Route ##
### Road Track ###
- [x] The road service shall be using bus to transport passenger from town to town. Also using truck for transporting freight cargoes, from industries to industries/town.
### Tram Track ###
- [x] The tram service shall be using tram-bus to transport passenger from town to town. Also using tram-truck for transporting freight cargoes, from industries to industries/town, but mostly only found mail truck available in the game.
## Marine Route ##
- [x] The ship service shall be used to transport passenger and/or mail from town to town. Also for transporting freight cargoes, from industries to industries/town.
- [x] The ship routes shall be using/build buoys to be able find proper route.
## Rail Route ##
- [x] The rail service shall be used to transport raw cargoes, from industries to industries.
- [ ] The rail service may additionally be used to transport passenger from town to town.
- [ ] The rail service may additionally be used to transport town affected cargoes from industries to town, as well as secondary or tertiary chain between industries.
### Double Track Route ###
- [x] The rail service shall be using double track if buildable, otherwise fallback to single track with maximum limit of two train operating.
## Special Feature ##
The following is considered as additional features of Trans AI.
### Cargo Concept (Many-to-one) ###
Trans AI shall try to use only one type of industry (if possible) as the destination of transporting cargo. ([Cargo Concept](http://www.openttdcoop.org/wiki/Gametype:Cargo_Concept)). 
- [ ] Road Route (50%)
- [ ] Marine Route (50%)
- [ ] Rail Route

For road and marine route, rework is needed from current implementation.

### Buying competitor company ###
- [x] Trans AI shall has ability to accept merger offered to him/her.
- [ ] Trans AI could be able to turn those negative income into profitable one. Failing to handle this, lead to bankruptcy of company.
### Infrastructure Maintenance ###
- [x] Trans AI would detect if infrastructure maintenance setting is activated in game, and act accordingly. (Mostly for air route)
### CargoDist ###
- [ ] Trans AI shall support CargoDist game mode using available API
