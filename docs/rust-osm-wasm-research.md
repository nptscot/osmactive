# Rust OSM + WASM Research

## Executive Summary

This research explores building a web-based interactive OSM visualization tool with a Rust/WASM backend. Key findings:

1. **osm2streets** is highly relevant - already has WASM, web demo, lane-level processing
2. **ohsome API** is the best option for historical OSM data (used successfully in Coventry analysis)
3. **npw** (Network Planning Workspace) shows the pattern - Rust + WASM + Svelte web
4. A modular approach building on existing tools is viable

---

## 1. Rust OSM Crates

### Available Crates (2025-2026)

| Crate | Purpose | Status | Historical Data |
|-------|---------|--------|----------------|
| **osm-io** | Read/write OSM PBF/XML | Active | No |
| **osmpbfreader** | Fast PBF parsing | Active | No |
| **osmgraph** | OSM to graph conversion | Active | No |
| **osm-api** | OSM API bindings | Early dev | Via API |
| **fast-osmpbf** | Fast PBF parser | Active | No |
| **osm-reader** (a-b-street) | XML/PBF reading | Active | No |

### Key Finding
**No mature Rust crate for historical OSM data directly.** The ohsome API (HTTP-based) is the best approach.

---

## 2. Historical OSM Data Options

### Option A: ohsome API (Recommended)
- **What:** HTTP API from University of Heidelberg
- **Historical:** ✅ Full history, time-series queries
- **Format:** GeoJSON, CSV
- **Used in:** Our Coventry cycle path analysis
- **Example:** `/elementsFullHistory` endpoint returns all changes
- **URL:** https://api.ohsome.org/v1/

### Option B: OSHDB (Java)
- OSHDB - OpenStreetMap History Data Analysis Framework
- Requires Java backend
- Powers ohsome API

### Option C: Geofabrik Downloads
- Full planet/history dumps
- Too large for web app (~100GB+)

---

## 3. osm2streets - Key Inspiration

### What is osm2streets?
- Rust library for converting OSM to street networks
- Lane-level detail (cycle lanes, footways, etc.)
- **WASM support** ✅
- **Web demo** ✅ (StreetExplorer)
- **Python bindings** ✅

### Architecture
```
osm2streets (Rust)
    ↓
osm2streets-js (WASM)
    ↓
StreetExplorer (Svelte/Leaflet)
```

### Key Features
- Lane-level representation
- Intersection geometry
- GeoJSON export
- Works offline

### Links
- Demo: https://a-b-street.github.io/osm2streets/
- GitHub: https://github.com/a-b-street/osm2streets
- JS bindings: osm2streets-js
- Python: osm2streets-py

---

## 4. npw (Network Planning Workspace) - Template

### What is npw?
- Our existing project: https://npw.scot
- Rust backend → WASM → Svelte web
- Active development (966 commits)

### Structure
```
npw/
├── backend/       # Rust core
├── web/          # Svelte frontend  
├── cli/          # Command line tools
└── problems-api/ # API server
```

### Why it's a good template
- Uses wasm-pack
- Builds to web
- Already processes OSM data
- Open source (Apache 2.0)

---

## 5. WASM Feasibility Assessment

### Pros
1. **Performance:** Rust compiles to efficient WASM
2. **Offline:** Works without server
3. **Privacy:** Data stays client-side
4. **Distribution:** No server infrastructure needed

### Cons
1. **Initial load:** WASM binary size (~1-5MB)
2. **Historical data:** Can't download full planet - need API
3. **Browser limits:** Memory constraints
4. **Complexity:** Debugging WASM harder than JS

### Performance Considerations
- PBF parsing in WASM is fast
- Can handle regional extracts (city-level)
- For historical: use ohsome API, process results in WASM

---

## 6. Proposed Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Web App (Svelte)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │  Map View   │  │  Timeline   │  │  Download   │   │
│  │  (Leaflet)  │  │  Slider    │  │  Button    │   │
│  └─────────────┘  └─────────────┘  └─────────────┘   │
└────────────────────────┬────────────────────────────────┘
                         │ GeoJSON
┌────────────────────────▼────────────────────────────────┐
│              WASM Module (Rust)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  OSM Parse  │  │  Transform  │  │  Filter     │  │
│  │  (osm-io)   │  │  (lanes)    │  │  (tags)     │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP
┌────────────────────────▼────────────────────────────────┐
│                  Data Sources                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  Geofabrik  │  │ ohsome API  │  │  Overpass   │  │
│  │  (current)   │  │ (historical)│  │  (live)     │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## 7. Next Steps / Recommendations

### Immediate (Quick Wins)
1. ✅ Use ohsome API for historical queries
2. ✅ Build on osm2streets for lane processing
3. ✅ Use npw as template for Rust+WASM+Svelte

### Medium Term
1. Create Rust library for OSM filtering (builds on osm-io)
2. Add WASM bindings to our existing code
3. Build interactive timeline component

### Long Term
1. Full modular library: `osm-wasm` crate
2. Historical processing in WASM
3. Offline-capable web app

---

## 8. Experiments to Try

### Experiment 1: osm2streets + WASM
```bash
# Clone and build
git clone https://github.com/a-b-street/osm2streets
cd osm2streets
cargo build --release
# Check for WASM target
rustup target add wasm32-unknown-unknown
cargo build --target wasm32-unknown-unknown
```

### Experiment 2: ohsome API + GeoJSON
```python
# Test historical query
import requests
response = requests.post(
    "https://api.ohsome.org/v1/elementsFullHistory",
    json={
        "bboxes": "-1.55,52.4,-1.45,52.45",  # Coventry
        "time": "2017-01-01/2024-12-31",
        "filter": "highway=*"
    }
)
```

### Experiment 3: npw template
```bash
# Clone and explore
git clone https://github.com/nptscot/npw
cd npw/web
npm ci
npm run dev
```

---

## 9. References

- osm2streets: https://github.com/a-b-street/osm2streets
- ohsome API: https://docs.ohsome.org
- npw: https://github.com/nptscot/npw
- Rust WASM book: https://rustwasm.github.io/book/
- crates.io OSM: https://crates.io/keywords/openstreetmap

---

*Research conducted: 2026-02-17*
