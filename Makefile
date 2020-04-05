ALL_OUTPUT=$(addprefix fab/, \
             normal_shield_no_support.stl normal_shield_with_support.stl \
             thin_shield_no_support.stl thin_shield_with_support.stl \
             thin-stack2.stl thin-stack3.stl thin-stack4.stl thin-stack5.stl \
             bottom_reinforcement.stl) \
             img/version-img.png baseline/maker-nexus-faceshield-cut.dxf

ASSEMBLE_3MF=./gen-3mf/scripts/assemble-3mf.sh

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

# -- concrete rules
img/version-img.png: fab/thin_shield_no_support.scad
	openscad -o$@-tmp.png --imgsize=1024,1024 \
             --camera=-0.5,-24.8,38,66.2,0,270,35 \
             --colorscheme=Nature $^ \
         && cat $@-tmp.png | pngtopnm | pnmcrop | pnmscale 0.25 | pnmtopng > $@
	rm -f $@-tmp.png

# The bottom reinforcment is just the same as the original.
fab/bottom_reinforcement.stl : baseline/bottom_reinforcement.stl
	cp $^ $@

# Experimental: assembling a 3mf in the two_shields arrangement using the
# PETG profile.
fab/two_shields-PETG.3mf: fab/thin_shield_with_support.3mf
	 $(ASSEMBLE_3MF) $^ $@ two_shields PETG

fab/two_shields-PLA.3mf: fab/normal_shield_with_support.3mf
	 $(ASSEMBLE_3MF) $^ $@ two_shields PLA

# -- pattern rules
# Qualifying with a support suffix, to distinguish from bottom_reinforcement
%_support.stl: %_support.scad
	openscad -o $@ $<

%_support.3mf: %_support.scad
	openscad -o $@ $<

# Create an scad file on-the-fly that calls that particular function
fab/%.scad : prusa-covid-shield-remix.scad
	mkdir -p fab
	echo "use <../prusa-covid-shield-remix.scad>; $*();" > $@

# Various stack arrangements in different heights.
define make-stack-rule
fab/$(2)-stack$(1).stl: fab/$(2)_stack_with_support.scad
	openscad -o "$$@" -Ddefault_stack_height=$(1) -Dprint_layer_height=0.25 -Dsupport_wall=1.1 $$<
endef  # make-stack-rule

# Create all the stack targets
$(foreach i, 2 3 4 5 6 7 8 9, $(eval $(call make-stack-rule,$(i),thin)))
$(foreach i, 2 3 4 5 6 7 8 9, $(eval $(call make-stack-rule,$(i),normal)))

%.dxf : %.ps
	pstoedit -nb -dt -f "dxf_s:-mm -ctl -splineaspolyline" $^ $@

%.ps : %.svg
	inkscape -f $^ -E $@

# Unfortunately, we have to use the UI curently. For some reason the
# resulting gcode is entirely different if created on the command line.
fab/%_0.3mm_PETG_MK3S.gcode: %.3mf
	prusa-slicer $^ --export-gcode --output $@

# List all the available targets so that they are tab-completable.
fab/normal_shield_no_support.stl:
fab/normal_shield_with_support.stl:
fab/thin_shield_no_support.stl:
fab/thin_shield_with_support.stl:

clean:
	rm -f $(ALL_OUTPUT) $(ALL_OUTPUT:=.deps) *.stl
