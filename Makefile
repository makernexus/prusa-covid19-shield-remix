ALL_OUTPUT=normal_shield_no_support.stl normal_shield_with_support.stl \
           short_shield_no_support.stl short_shield_with_support.stl

all: $(ALL_OUTPUT)

# Create an scad file on-the-fly that calls that particular function
%.scad : prusa-covid-shield-remix.scad
	mkdir -p fab
	echo "use <prusa-covid-shield-remix.scad>; $*();" > $@

%.stl: %.scad
	openscad -o $@ -d $@.deps $<

clean:
	rm -f $(ALL_OUTPUT)
