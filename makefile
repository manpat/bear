OUTPUTNAME=langtest
COMPILER=dmd
DIRS=
LIBS=

$(OUTPUTNAME).build: *.d */*.d
	$(COMPILER) $^ -of$(OUTPUTNAME).build

run: $(OUTPUTNAME).build
	./$(OUTPUTNAME).build