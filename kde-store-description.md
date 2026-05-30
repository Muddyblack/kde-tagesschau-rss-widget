# Tagesschau News Widget

A KDE Plasma 6 widget for following German news (*Eilmeldungen*), custom RSS/Atom feeds, and live stock/crypto prices. Mainly aimed at German speakers — the primary source is tagesschau.de.

---

### Features

* **Tagesschau feed** — pulls from the official JSON API, shows headlines, teasers, and breaking news alerts
* **Custom RSS/Atom feeds** — add any feed URL and give it a custom icon
* **Finance board** — live prices for DAX, Dow, NASDAQ, EUR/USD, BTC, ETH, SOL, and a few tech stocks via Yahoo Finance and Binance
* **Breaking news** — if a *Eilmeldung* is detected, the panel icon turns red and you get a desktop notification
* **Expandable articles** — click a card to see the summary inline without opening a browser
* **IPO watchlist** — checks headlines against a list of companies (Anthropic, SpaceX, OpenAI, Stripe, etc.) and notifies you on a match
* **Category filter** — filter Tagesschau stories by section: Inland, Ausland, Wirtschaft, Sport, Wissen, Investigativ
* **Auto-refresh** — polls every 5 minutes, or hit the refresh button manually

---

### Installation

#### Via KDE Store (GUI)
Right-click your panel → *Add Widgets* → *Get New Widgets* → *Download New Plasma Widgets* → search **"Tagesschau"** → Install.

#### Manual (CLI)
```bash
git clone https://github.com/Muddyblack/kde-tagesschau-rss-widget.git
cd kde-tagesschau-rss-widget
kpackagetool6 -t Plasma/Applet -i package
```

---

### Requirements

* KDE Plasma 6.0+
* `plasma5support` (for the executable DataEngine)
* `libnotify` / `notify-send` (for desktop notifications)
