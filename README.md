# ZCinema - Netflix-inspired Movie & Series Streaming App

ZCinema is a full-featured iOS streaming application that scrapes content from egibest.ws and provides a native Netflix-like experience with AMOLED black theme, professional video player, episode/season management, and direct video extraction from popular streaming servers.

## Features

- **Beautiful UI/UX** – Netflix-inspired dark/AMOLED theme with smooth animations
- **Dynamic Content Scraping** – Parses egibest.ws for movies, series, and anime
- **Professional Media Player** – AVPlayer-based with custom controls
- **Episode & Season Management** – For TV series with automatic episode listing
- **Multi-Server Support** – Extracts direct video URLs from Doodstream, Mixdrop, Streamtape, Cybervynx, Lulustream
- **Server Selection** – Choose between available streaming servers
- **Download Links** – Direct download support for offline viewing
- **Async/Await** – Modern Swift concurrency for smooth performance

## Requirements

- iOS 17.0+
- Xcode 15.4+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Al-Zng/ZCinema.git
cd ZCinema
```

2. Open ZCinema.xcodeproj in Xcode.
3. Build and run on simulator or device (requires iOS 17+).

Architecture

· SwiftUI – Declarative UI framework
· AVFoundation/AVKit – Native video playback
· WebKit – Embedded extraction of video streams (fallback)
· URLSession – HTML scraping and data fetching
· Combine & Async/Await – Reactive data flow

Scraping & Extraction

The app dynamically parses the target website's HTML structure:

· Homepage sections (latest movies, series, anime)
· Content details (title, description, genres, cast, rating)
· Episode lists for series
· Video server URLs from embed/direct links

Video extraction uses URLSession with custom headers and JavaScript evaluation via WebKit for dynamic pages.

Legal Disclaimer

This application is for educational purposes only. It does not host any copyrighted content. All media is streamed from third-party servers. Users are responsible for complying with local copyright laws.

Credits

· Icons: SF Symbols, FontAwesome
· Scraping patterns derived from egibest.ws HTML structure

License

MIT License – see LICENSE file.
