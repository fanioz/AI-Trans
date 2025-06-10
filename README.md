# Trans AI

Trans is an AI for [OpenTTD](http://www.openttd.org). It attempts to transport cargo to and from any towns and industries using buses, trucks, trams, aircraft, and ships. In the future, it will attempt to use all available vehicle types. Its current strategy is to use only one type of industry as a cargo destination where possible, based on the [Cargo Concept](http.www.openttdcoop.org/wiki/Gametype:Cargo_Concept). See implemented features in [ROADMAP.md](ROADMAP.md).

## What is this repository for? ##

* Quick summary
> Since version 0.7, [OpenTTD](http://www.openttd.org) allows for the implementation of custom AIs to play with.
> This repository contains the source code for Trans, an in-game AI opponent for OpenTTD.

## Installation

There are three ways to install Trans AI, depending on your needs.

### Option 1: In-Game Download (Recommended for Players)

The easiest way to get the latest stable version is to download it directly from OpenTTD's in-game content service ('Bananas').

1.  Open OpenTTD and click "Check Online Content".
2.  Search for "Trans AI" under the "AI" category.
3.  Select it and click "Download".

### Option 2: GitHub Releases (Latest Development Builds)

If you want to try the latest features, you can download development builds directly from our [GitHub Releases page](https://github.com/fanioz/AI-Trans/releases).

1.  Go to the releases page and find the latest release marked with a date (e.g., `250610`).
2.  Download the `.tar` file from the "Assets" section.
3.  Place the `Trans-AI-[version].tar` file directly in your OpenTTD `ai` directory. **No need to extract it.**

### Option 3: Clone from Source (For Developers)

If you plan to contribute to the development, you should clone the repository directly.

1.  Clone this repository into your OpenTTD `ai` folder:
    * **Linux**: `$(HOME)/.openttd/ai`
    * **macOS**: `$(HOME)/Documents/OpenTTD/ai`
    * **Windows**: `C:\Users\<username>\Documents\OpenTTD\ai`
2.  Ensure you have the required dependencies (see below).

### Dependencies

Trans AI requires the following libraries to be installed in your `../ai/library` folder:
1.  [AI Library - Common](http://noai.openttd.org/downloads/Libraries/AILibCommon-2.tar.gz)
2.  [AI Library - List](http://noai.openttd.org/downloads/Libraries/AILibList-3.tar.gz)
3.  [AI Library - String](http://noai.openttd.org/downloads/Libraries/AILib.String-2.tar.gz)

## Versioning

This project uses a rolling release model, with the version number based on the commit date in `YYMMDD` format. This means there is only one release per day; subsequent pushes on the same day will update the existing daily release with the latest changes.

If you clone this repository directly, the version number in your local `info.nut` file is intentionally set to a date far in the future. This ensures that OpenTTD gives priority to your local development version over any officially downloaded release.

Releases created from the `bananas` tag are special versions that are also uploaded to the official OpenTTD content service, 'Bananas'.

### Build Process
This project has moved from a manual script-based build to a fully automated process using GitHub Actions. The entire process is defined in the `.github/workflows/rolling-release.yml` file.

## Licensing

Trans AI is licensed under the GNU General Public License version 2.0. For the complete license text, see the file [license.txt](license.txt). This license applies to all files in this distribution.
By contributing your code, you agree to license your contribution under the GNU GPL v2 License.

## Contributing

### Using the issue tracker

The [issue tracker](https://github.com/fanioz/AI_Trans/issues) is the preferred channel for bug reports, feature requests, and pull requests. Please refer to [ROADMAP.md](ROADMAP.md) for contribution guidelines.

## Authors

* **Rifani Arsyad** - *a.k.a fanioz* -