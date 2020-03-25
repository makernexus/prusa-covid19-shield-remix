ALL_OUTPUT=prusa-covid-shield-remix-print_shield.stl \
           prusa-covid-shield-remix-support_modifier.stl

all: $(ALL_OUTPUT)

# Create an scad file on-the-fly that calls that particular function
prusa-covid-shield-remix-%.scad : prusa-covid-shield-remix.scad
	mkdir -p fab
	echo "use <prusa-covid-shield-remix.scad>; $*();" > $@

%.stl: %.scad
	openscad -o $@ -d $@.deps $<
