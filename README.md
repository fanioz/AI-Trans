# Trans AI

Trans is an AI for [OpenTTD](www.openttd.org). It try to transporting cargoes from/to any towns and industries using Bus, Truck, Tram, Aircraft and Ship. In the future it would try to use all available vehicles. Current strategy is try to use only one type of industry (if possible) as the destination of transporting cargo named "Cargo Concept", As described in openttd-coop

## What is this repository for? ##

* Quick summary
> This repository contain code of Trans, in-game AI opponent player for OpenTTD.
* Version numbering:
> The version number is in YYMMDD format. e.g Latest version was 100307, mean it was released at 7th of March 2010.

## How do I get set up? ##

* Summary of set up
> Clone this repository to :
> * Linux : $(HOME)/.openttd/ai
> * MacOs : $(HOME)/Documents/OpenTTD/ai
> * Windows :$(ALLUSERSPROFILE)\Documents\OpenTTD\ai"
>
* Dependencies
> Trans AI would need :
> 1. [Fibonacci Heap 2](http://noai.openttd.org/downloads/Libraries/Queue.FibonacciHeap.2.tar.gz)
> 2. [AI Library - Common ](http://noai.openttd.org/downloads/Libraries/AILibCommon-1.tar.gz)
> 3. [AI Library - List](http://noai.openttd.org/downloads/Libraries/AILibList-1.tar.gz)
>
> Put in your ../ai/library folder.
>
* Deployment instructions
> Deploy to bananas required 'make' command to generate archive prior uploading to bananas.

~~~~bash
make tar
~~~~

## Who do I talk to? ##

* Repo owner or admin : [fanio **dot** zilla **at** gmail* *dot** com](mailto:fanio.zilla@gmail.com)