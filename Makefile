ALL_OUTPUT=$(addprefix fab/, \
             normal_shield_no_support.stl normal_shield_with_support.stl \
             thin_shield_no_support.stl thin_shield_with_support.stl \
             thin-stack2.stl thin-stack3.stl thin-stack4.stl thin-stack5.stl \
             bottom_reinforcement.stl) img/version-img.png

# The 3mf file does not store the relative directory for some reason, so
# we have to put it here, to be able to easily reload-from-disk
# Reload-from-disk still needs to be manually (is there a commandline option
# for prusa-slicer to do that?)
release: fab/normal_shield_with_support.stl fab/thin_shield_with_support.stl
	ln -sf $^ .

# Same for stacks: prepare the STLs and link to local directory where 3mf
# is. That way, we can do a simple 'reload from disk'
stacks: fab/thin-stack2.stl fab/thin-stack3.stl fab/thin-stack4.stl fab/thin-stack5.stl
	ln -sf $^ .

# Building all the STLs we also push in fab/
all: $(ALL_OUTPUT)

# Uncomment to keep the scad intermediate files.
# .SECONDARY: $(ALL_OUTPUT:.stl=.scad)

# Create an scad file on-the-fly that calls that particular function
fab/%.scad : prusa-covid-shield-remix.scad
	mkdir -p fab
	echo "use <../prusa-covid-shield-remix.scad>; $*();" > $@

# The bottom reinforcment is just the same as the original.
fab/bottom_reinforcement.stl : baseline/bottom_reinforcement.stl
	cp $^ $@

img/version-img.png: fab/thin_shield_no_support.scad
	openscad -o$@-tmp.png --imgsize=1024,1024 \
             --camera=-0.5,-24.8,38,66.2,0,270,35 \
             --colorscheme=Nature $^ \
         && cat $@-tmp.png | pngtopnm | pnmcrop | pnmscale 0.25 | pnmtopng > $@
	rm -f $@-tmp.png

# Various stack arrangements.
# There certainly is a better Makefile way to describe this 3, 4, 5 pattern...
fab/thin-stack2.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=2 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 $<

fab/thin-stack3.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=3 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 $<

fab/thin-stack4.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=4 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 $<

fab/thin-stack5.stl: fab/thin_stack_with_support.scad
	openscad -o $@ -Ddefault_stack_height=5 -Dprint_layer_height=0.25 -Dsupport_wall=1.1 $<

%_support.stl: %_support.scad
	openscad -o $@ $<

# Unfortunately, we have to use the UI curently. For some reason the
# resulting gcode is entirely different if created on the command line.
fab/%_0.3mm_PETG_MK3S.gcode: %.3mf
	prusa-slicer $^ --export-gcode --output $@

# List all the available targets so that they are tab-completable.
fab/normal_shield_no_support.stl:
fab/normal_shield_with_support.stl:
fab/thin_shield_no_support.stl:
fab/thin_shield_with_support.stl:
fab/thin-stack2.stl:
fab/thin-stack3.stl:
fab/thin-stack4.stl:
fab/thin-stack5.stl:

clean:
	rm -f $(ALL_OUTPUT) $(ALL_OUTPUT:=.deps) *.stl
