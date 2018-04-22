# Trans AI

Trans is an AI for [OpenTTD](www.openttd.org). It try to transporting cargoes from/to any towns and industries using Bus, Truck, Tram, Aircraft and Ship. In the future it would try to use all available vehicles. Current strategy is try to use only one type of industry (if possible) as the destination of transporting cargo named [Cargo Concept](http://www.openttdcoop.org/wiki/Gametype:Cargo_Concept)

## What is this repository for? ##

* Quick summary
> [OpenTTD](www.openttd.org) since version 0.7 allowing us to implement custom AIs to play with.
> This repository contain code of Trans, in-game AI opponent player for OpenTTD.

## How do I get set up? ##

* Summary of set up
> 1. Cloning repository directly to ai folder
> 2. Cloning repository to another folder and manual deploying
>
* Clone this repository to :
> * Linux : $(HOME)/.openttd/ai
> * MacOs : $(HOME)/Documents/OpenTTD/ai
> * Windows :
>>        - `C:\My Documents\OpenTTD\ai` (95, 98, ME)
>>        - `C:\Documents and Settings\<username>\My Documents\OpenTTD\ai` (2000, XP)
>>        - `C:\Users\<username>\Documents\OpenTTD\ai` (Vista, 7, 8, 10)
>
* Deployment instructions
> To create bundle package for deploying to bananas: run powershell script "bundle.ps1".
> Tar (archive) file produced by this script could be used to upload to bananas or be installed to 'ai' folder.
>
* Dependencies
> Trans AI would need :
> 1. [AI Library - Common ](http://noai.openttd.org/downloads/Libraries/AILibCommon-2.tar.gz)
> 2. [AI Library - List](http://noai.openttd.org/downloads/Libraries/AILibList-3.tar.gz)
> 3. [AI Library - String](http://noai.openttd.org/downloads/Libraries/AILib.String-2.tar.gz)
>
> Extract the .gz into .tar and put in your ../ai/library folder.
> OpenTTD can read both AI and AILibrary inside tar files but it does not extract .tar.gz files by itself.

## Licensing

* Trans AI is licensed under the GNU General Public License version 2.0. For the complete license text, see the file ['license.txt'](https://github.com/fanioz/AI-Trans/blob/master/license.txt). This license applies to all files in this distribution

## Who do I talk to? ##

* Repo owner or admin : [fanio **dot** zilla **at** gmail**dot** com](mailto:fanio.zilla@gmail.com)
