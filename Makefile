
all: prusa-covid-shield-remix.stl

%.stl: %.scad
	openscad -o $@ -d $@.deps $<
