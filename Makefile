.PHONY: all pc vita clean
.SECONDARY:

VITA_CC := arm-vita-eabi-gcc
WEB_CC := emcc

VITA_TITLE := Portalban
VITA_APP_VER := 01.00
VITA_TITLEID := IVOAH0001

EXE := portalban

LIBS := sdl3
VITA_STATIC_LIBS := $(VITASDK)/arm-vita-eabi/lib/libSDL3.a

COMMON_CFLAGS += -MP -MMD

CFLAGS += $(COMMON_CFLAGS) $(shell pkg-config --cflags $(LIBS)) -g -fsanitize=address -fno-omit-frame-pointer
LDFLAGS += $(shell pkg-config --libs $(LIBS)) -g -fsanitize=address -fno-omit-frame-pointer

VITA_CFLAGS += $(COMMON_CFLAGS) -Wl,-q -std=gnu17 $(shell arm-vita-eabi-pkg-config --cflags $(LIBS))
VITA_LDFLAGS += -Wl,-q -std=gnu17 -Wl,-z,nocopyreloc $(shell arm-vita-eabi-pkg-config --libs $(LIBS))

WEB_CFLAGS += $(COMMON_CFLAGS) --use-port=sdl3
WEB_LDFLAGS += --use-port=sdl3

SOURCES := $(wildcard src/*.c)

OBJS := $(addprefix pc_build/, $(SOURCES:src/%.c=%.o))
VITA_OBJS := $(addprefix vita_build/, $(SOURCES:src/%.c=%.o))
WEB_OBJS := $(addprefix web_build/, $(SOURCES:src/%.c=%.o))

DEPS = $(OBJS:.o=.d)
VITA_DEPS = $(VITA_OBJS:.o=.d)
WEB_DEPS = $(WEB_OBJS:.o=.d)

all: pc vita web
pc: $(EXE)
vita: $(EXE).vpk
web: $(EXE).html

%_build:
	mkdir -p $@

$(EXE): $(OBJS)
	$(CC) $^ $(LDFLAGS) -o $@

pc_build/%.o: src/%.c | pc_build
	$(CC) -c $(CFLAGS) -o $@ $<

$(EXE).vpk: vita_build/$(EXE).self vita_build/param.sfo sce_sys levels sprites
	vita-pack-vpk -s vita_build/param.sfo -b vita_build/$(EXE).self \
		--add sce_sys/icon0.png=sce_sys/icon0.png \
		--add sce_sys/livearea/contents/bg.png=sce_sys/livearea/contents/bg.png \
		--add sce_sys/livearea/contents/startup.png=sce_sys/livearea/contents/startup.png \
		--add sce_sys/livearea/contents/template.xml=sce_sys/livearea/contents/template.xml \
		--add levels=levels \
		--add sprites=sprites \
		$(EXE).vpk

vita_build/$(EXE).self: vita_build/$(EXE).velf
	vita-make-fself -c -s $< $@

vita_build/param.sfo:
	vita-mksfoex \
		-s APP_VER="$(VITA_APP_VER)" \
		-s TITLE_ID="$(VITA_TITLEID)" \
		"$(VITA_TITLE)" vita_build/param.sfo

vita_build/$(EXE).velf: vita_build/$(EXE).elf
	vita-elf-create $< $@

vita_build/$(EXE).elf: $(VITA_OBJS)
	$(VITA_CC) -g $^ $(VITA_LDFLAGS) -o $@

vita_build/%.o : src/%.c | vita_build
	$(VITA_CC) -c $(VITA_CFLAGS) -o $@ $<

$(EXE).html $(EXE).js $(EXE).wasm $(EXE).data: $(WEB_OBJS)
	$(WEB_CC) $^ $(WEB_LDFLAGS) -o $@ --preload-file levels --preload-file sprites

web_build/%.o: src/%.c | web_build
	$(WEB_CC) -c $(WEB_CFLAGS) -o $@ $<

clean:
	rm -rf $(EXE) $(EXE).vpk $(EXE).html $(EXE).js $(EXE).wasm $(EXE).data *_build

-include $(DEPS)
-include $(VITA_DEPS)
-include $(WEB_DEPS)
