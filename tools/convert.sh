#!/bin/sh
# PNG -> indexed-palette JSON. No GUI, runs instantly.
#   tools/convert.sh <input.png> <output.json>   convert one file
#   tools/convert.sh                              convert every art/*.png -> data/*.json
# Assumes clean flat-color art; unique colors = palette.
set -e

convert_one() {
  in="$1"; out="$2"
  magick "$in" -depth 8 txt:- | awk '
    BEGIN { n=0; m=0 }
    /^# ImageMagick/ {
      # header: "# ImageMagick pixel enumeration: W,H,maxval,colorspace"
      hdr = $0; sub(/^.*: /, "", hdr); split(hdr, d, ",")
      imgw = d[1]; imgh = d[2]
      next
    }
    {
      # rows look like: x,y: (r,g,b,a) #RRGGBBAA srgba(r,g,b,a)
      split($1, xy, ",")              # xy[1]=x  xy[2]=y(with colon)
      x = xy[1]; gsub(":", "", xy[2]); y = xy[2]
      rgba = $0
      sub(/^[^(]*\(/, "", rgba); sub(/\).*$/, "", rgba)       # r,g,b,a
      split(rgba, c, ",")
      r=c[1]; g=c[2]; b=c[3]; a=c[4]
      if (a+0 < 128) next   # drop transparent + near-transparent pixels
      key = r "," g "," b
      if (!(key in idx)) { idx[key] = n; pal[n] = "[" r "," g "," b "]"; n++ }
      pix[m++] = "[" x "," y "," idx[key] "]"
    }
    END {
      palstr=""; for (i=0;i<n;i++) palstr = palstr (i?",":"") pal[i]
      pixstr=""; for (i=0;i<m;i++) pixstr = pixstr (i?",":"") pix[i]
      printf "{\"w\":%d,\"h\":%d,\"palette\":[%s],\"pixels\":[%s]}", imgw, imgh, palstr, pixstr
    }
  ' > "$out"
  echo "$in -> $out"
}

if [ -n "$1" ]; then
  convert_one "$1" "$2"
else
  mkdir -p data
  for f in art/*.png; do
    name=$(basename "$f" .png)
    convert_one "$f" "data/$name.json"
  done
fi
