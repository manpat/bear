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

ifeq ($(MODE),debug)
run:
	gnome-terminal -e "gdb ./$(OUTPUTNAME).build"

else
run:
	bash -c "ulimit -d 8192 -t 2 && ./$(OUTPUTNAME).build"

endif