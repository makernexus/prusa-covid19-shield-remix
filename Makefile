ALL_OUTPUT=$(addprefix fab/, normal_shield_no_support.stl normal_shield_with_support.stl \
           thin_shield_no_support.stl thin_shield_with_support.stl \
           normal_stack3_with_support.stl thin_stack3_with_support.stl)

all: $(ALL_OUTPUT)

# Uncomment to keep the scad intermediate files.
# .SECONDARY: $(ALL_OUTPUT:.stl=.scad)

# Create an scad file on-the-fly that calls that particular function
fab/%_support.scad : prusa-covid-shield-remix.scad
	mkdir -p fab
	echo "use <../prusa-covid-shield-remix.scad>; $*_support();" > $@

%.stl: %.scad
	openscad -o $@ -d $@.deps $<

foo:
	echo

clean:
	rm -f $(ALL_OUTPUT) $(ALL_OUTPUT:=.deps)
