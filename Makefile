INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install
UNAME ?= $(shell uname)

CFLAGS := -O2 -g -Wall -fpic -std=c99

C_SO_NAME := librestyredisslot.so
LDFLAGS := -shared

# on Mac OS X, one should set instead:
# for Mac OS X environment, use one of options
ifeq ($(UNAME),Darwin)
	LDFLAGS := -bundle -undefined dynamic_lookup
	C_SO_NAME := librestyredisslot.dylib
endif

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

OBJS := src/redis_slot.o

.PHONY: default
default: compile


### clean:        Remove generated files
.PHONY: clean
clean:
	rm -f $(C_SO_NAME) $(OBJS) ${R3_CONGIGURE}


### compile:      Compile library
.PHONY: compile

compile: ${R3_FOLDER} ${R3_CONGIGURE} ${R3_STATIC_LIB} $(C_SO_NAME)

${OBJS} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $< -o $@

${C_SO_NAME} : ${OBJS}
	$(CC) $(MY_LDFLAGS) $(OBJS) -o $@


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) lib/resty/*.lua $(INST_LUADIR)/resty/
	$(INSTALL) $(C_SO_NAME) $(INST_LIBDIR)/



### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
