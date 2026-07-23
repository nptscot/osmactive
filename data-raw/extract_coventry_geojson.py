#!/usr/bin/env python3
"""
Extract Coventry-area OSM ways (all highway= features) from a Geofabrik
West Midlands .osm.pbf snapshot, preserving all tags, and write a GeoJSON
file that can be read directly into R with sf.

Usage:
    python extract_coventry_geojson.py <input.pbf> <output.geojson>
"""
import sys
import json
import osmium
import shapely.wkb as wkblib
import shapely

# Coventry bounding box (WGS84)
BBOX = dict(xmin=-1.56, ymin=52.40, xmax=-1.45, ymax=52.43)

wkbfab = osmium.geom.WKBFactory()


class HighwayHandler(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.features = []

    def way(self, w):
        raw_tags = dict(w.tags)
        if "highway" not in raw_tags:
            return
        # Match osmextract's column naming convention: replace ':' with '_'
        # e.g. "cycleway:left" -> "cycleway_left" so that names align with
        # what the osmactive R functions expect (get_cycling_network(),
        # classify_cycle_infrastructure(), etc.)
        tags = {k.replace(":", "_"): v for k, v in raw_tags.items()}
        try:
            wkb = wkbfab.create_linestring(w)
        except RuntimeError:
            # e.g. way with < 2 points after node dedup
            return
        geom = wkblib.loads(wkb, hex=True)
        minx, miny, maxx, maxy = geom.bounds
        # keep ways that intersect the Coventry bbox
        if maxx < BBOX["xmin"] or minx > BBOX["xmax"]:
            return
        if maxy < BBOX["ymin"] or miny > BBOX["ymax"]:
            return
        tags["osm_id"] = w.id
        self.features.append((geom, tags))


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.pbf> <output.geojson>")
        sys.exit(1)

    in_pbf, out_geojson = sys.argv[1], sys.argv[2]

    handler = HighwayHandler()
    print(f"Reading {in_pbf} ...")
    handler.apply_file(in_pbf, locations=True, idx="flex_mem")
    print(f"  kept {len(handler.features)} highway ways intersecting Coventry bbox")

    features = []
    for geom, tags in handler.features:
        features.append(
            {
                "type": "Feature",
                "geometry": json.loads(shapely.to_geojson(geom)),
                "properties": tags,
            }
        )

    fc = {"type": "FeatureCollection", "features": features}
    with open(out_geojson, "w") as f:
        json.dump(fc, f)
    print(f"  wrote {out_geojson}")


if __name__ == "__main__":
    main()
