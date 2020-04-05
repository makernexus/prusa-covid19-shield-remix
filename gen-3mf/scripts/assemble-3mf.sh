#!/bin/bash

TEMPLATE_DIR=$(dirname $0)/../templates
ARRANGEMENT_DIR="$TEMPLATE_DIR/arrangement"
FLAVOR_DIR="$TEMPLATE_DIR/slice-flavor"

if [ $# -ne 4 ] ; then
    echo "Usage: $0 <in-3mf> <out-3mf> <arrangement> <metadata-flavor>"
    exit 1
fi

IN_3MF="$1"               # input 3mf file; Expecting to contain one object
OUT_3MF="$(realpath $2)"  # Where we're going to write file
ARRANGEMENT="$3"          # Name of arrangement transformation
FLAVOR="$4"               # configuration flavor for slicer (PETG, PLA ?)

# Arrangement of the objects happens in this hand-edited footer.
ARRANGEMENT_XML_FOOTER="$ARRANGEMENT_DIR/3dmodel-footer-${ARRANGEMENT}.xml"
if [ ! -e "$ARRANGEMENT_XML_FOOTER" ] ; then
    echo "$ARRANGEMENT_XML_FOOTER does not exist; typo in '$ARRANGEMENT' ?"
    exit 2
fi

SLICE_CONFIG="$FLAVOR_DIR/Slic3r_PE-${FLAVOR}.config"
if [ ! -e "$SLICE_CONFIG" ] ; then
    echo "$SLICE_CONFIG does not exist; typo in '$FLAVOR' ?"
    exit 2
fi

TEMP_DIR=$(mktemp)

# We need an scad dir where we unpack the raw model from scad. In the
# assembly dir, we'll put everything together
IN_DIR="$TEMP_DIR/in"
IN_MODEL="$IN_DIR/3D/3dmodel.model"
OUT_DIR="$TEMP_DIR/out"

rm -rf "$TEMP_DIR"
mkdir -p "$IN_DIR" "$OUT_DIR"

# Get the original 3mf
unzip -q -d "$IN_DIR" "$IN_3MF"

# Start assembly. First the non-changed things
cp -r "$TEMPLATE_DIR/base/"* "$OUT_DIR"

mkdir "$OUT_DIR/3D" "$OUT_DIR/Metadata"

# Now, put together the model. We extract the <object></object> range from
# the input 3mf, but add our own transformations and stuff around.
cat "$ARRANGEMENT_DIR/3dmodel-header.xml" \
    <(awk '/<object /{p=1;} {if (p) print $0} /<\/object>/{p=0}' < $IN_MODEL) \
    "$ARRANGEMENT_XML_FOOTER" \
    > "$OUT_DIR/3D/3dmodel.model"

# Slicer configuration
cp "$SLICE_CONFIG" "$OUT_DIR/Metadata/Slic3r_PE.config"

# For now, we don't add a model configuration. Not sure if it is needed.

# zip always does things from the current directory, so change into it.
(cd "$OUT_DIR" ; zip -q -r "$OUT_3MF" .)

rm -rf "$TEMP_DIR"
