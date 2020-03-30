ALL_OUTPUT=$(addprefix fab/, \
             normal_shield_no_support.stl normal_shield_with_support.stl \
             thin_shield_no_support.stl thin_shield_with_support.stl \
             normal_stack3_with_support.stl thin_stack3_with_support.stl)

# The 3mf file does not store the relative directory for some reason, so
# we have to put it here, to be able to easily reload-from-disk
release: fab/normal_shield_with_support.stl fab/thin_shield_with_support.stl
	ln -sf $^ .

# Same for stacks: prepare the STLs and link to local directory where 3mf
# is. That way, we can do a simple 'reload from disk'
stacks: fab/thin-stack3.stl fab/thin-stack4.stl fab/thin-stack5.stl
	ln -sf $^ .

# Building all the possible STLs.
all: $(ALL_OUTPUT)

# Uncomment to keep the scad intermediate files.
# .SECONDARY: $(ALL_OUTPUT:.stl=.scad)

# Create an scad file on-the-fly that calls that particular function
fab/%.scad : prusa-covid-shield-remix.scad
	mkdir -p fab
	echo "use <../prusa-covid-shield-remix.scad>; $*();" > $@

# Configure
# There certainly is a better Makefile way to describe this 3, 4, 5 pattern...
fab/thin-stack3.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=3 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 -d $@.deps $<

fab/thin-stack4.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=4 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 -d $@.deps $<

fab/thin-stack5.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=5 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 -d $@.deps $<

%_support.stl: %_support.scad
	openscad -o $@ -d $@.deps $<

# Unfortunately, we have to use the UI curently. For some reason the
# resulting gcode is entirely different if created on the command line.
fab/%_0.3mm_PETG_MK3S.gcode: %.3mf
	prusa-slicer $^ --export-gcode --output $@

# List all the available targets so that they are tab-completable.
fab/normal_shield_no_support.stl:
fab/normal_shield_with_support.stl:
fab/thin_shield_no_support.stl:
fab/thin_shield_with_support.stl:
fab/thin-stack3.stl:
fab/thin-stack4.stl:
fab/thin-stack5.stl:

clean:
	rm -f $(ALL_OUTPUT) $(ALL_OUTPUT:=.deps) *.stl
