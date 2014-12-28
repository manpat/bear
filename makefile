OUTPUTNAME=`pwd | egrep -o "\w+$$"`
COMPILER=dmd
MODE=#debug
DIRS=
LIBS=
FLAGS=

ifeq ($(MODE),debug)
FLAGS=-gc
endif

$(OUTPUTNAME).build: *.d */*.d
	$(COMPILER) $(FLAGS) $^ -of$(OUTPUTNAME).build
	rm $(OUTPUTNAME).o

ifeq ($(MODE),debug)
run:
	gnome-terminal -e "gdb ./$(OUTPUTNAME).build"

else
run:
	bash -c "ulimit -d 1024 -t 1 && ./$(OUTPUTNAME).build"

endif