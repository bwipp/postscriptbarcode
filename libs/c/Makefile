NAME = postscriptbarcode

VERSION := $(shell head -n 1 ../CHANGES)
MAJOR   := $(firstword $(subst ., ,$(VERSION)))

FUZZER = $(NAME)_fuzzer
FUZZER_CORPUS = corpus

# Fuzzer implies sanitizers
ifneq ($(filter fuzzer fuzzer-corpus-seeds,$(MAKECMDGOALS)),)
SANITIZE = yes
FUZZER_SAN_OPT = ,fuzzer
endif

ifeq ($(SANITIZE),yes)
CC=clang
SAN_LDFLAGS =
ifneq ($(shell uname -s),Darwin)
SAN_CFLAGS = -fsanitize=address,leak,undefined$(FUZZER_SAN_OPT) -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1
SAN_ENV = ASAN_OPTIONS="symbolize=1 detect_leaks=1" LSAN_OPTIONS="fast_unwind_on_malloc=0:malloc_context_size=50" ASAN_SYMBOLIZER_PATH="$(shell which llvm-symbolizer)"
else
# Leak detection is not supported on macOS builds of LLVM
SAN_CFLAGS = -fsanitize=address,undefined$(FUZZER_SAN_OPT) -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1
SAN_ENV = ASAN_OPTIONS="symbolize=1" LSAN_OPTIONS="fast_unwind_on_malloc=0:malloc_context_size=50" ASAN_SYMBOLIZER_PATH="$(shell which llvm-symbolizer)"
endif
endif

# MemorySanitizer: detects reads of uninitialised memory.
# Mutually exclusive with ASAN.
#
#   make MSAN=yes test
#
ifeq ($(MSAN),yes)
CC=clang
SAN_LDFLAGS =
SAN_CFLAGS = -fsanitize=memory -fsanitize-memory-track-origins=2 -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1
SAN_ENV = MSAN_SYMBOLIZER_PATH="$(shell which llvm-symbolizer)"
endif

ifeq ($(ANALYZER),yes)
ANALYZER_CFLAGS = -fanalyzer
endif

ifneq ($(shell uname -s),Darwin)
LDFLAGS = -Wl,--as-needed -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now $(SAN_LDFLAGS)
LDFLAGS_SO = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR)
CFLAGS_FORTIFY = -D_FORTIFY_SOURCE=2
else
LDFLAGS = $(SAN_LDFLAGS)
LDFLAGS_SO = -shared -Wl,-install_name,lib$(NAME).so.$(MAJOR)
CFLAGS_FORTIFY =
endif

LDLIBS = -lc
CFLAGS = -g -O2 $(CFLAGS_FORTIFY) -fvisibility=hidden -Wall -Wextra -Wconversion -Wformat=2 -Wshadow -Wundef -Wnull-dereference -Wstrict-prototypes -Wdeclaration-after-statement -pedantic -Werror -fstack-protector-strong -MMD -fPIC $(SAN_CFLAGS) $(ANALYZER_CFLAGS)

TEST_SHARED = $(NAME)_test_shared
TEST_STATIC = $(NAME)_test_static

PREFIX = /usr/local
LIBDIR = $(PREFIX)/lib

.PHONY: default all clean lib libstatic libshared test test-valgrind fuzzer fuzzer-corpus-seeds clean-fuzzer-corpus install install-static install-shared uninstall

default: lib
all: default test

lib: libshared libstatic
libshared: lib$(NAME).so.$(VERSION) lib$(NAME).so lib$(NAME).so.$(MAJOR)
libstatic: lib$(NAME).a

lib$(NAME).so: lib$(NAME).so.$(VERSION) lib$(NAME).so.$(MAJOR)
	ln -sf $< $@

lib$(NAME).so.$(MAJOR): lib$(NAME).so.$(VERSION)
	ln -sf $< $@

lib$(NAME).so.$(VERSION): $(NAME).o
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDFLAGS_SO) $(LDLIBS) $^ -o $@

lib$(NAME).a: $(NAME).o
	$(AR) cr $@ $^
	ranlib $@

$(NAME).o: $(NAME).c $(NAME).h $(NAME)_private.h
	$(CC) $(CFLAGS) -c -o $@ $<

$(TEST_SHARED): lib$(NAME).so $(NAME)_test.c
	$(CC) $(CFLAGS) $(NAME)_test.c -o $@ -L. -l$(NAME)

$(TEST_STATIC): $(NAME).o $(NAME)_test.c
	$(CC) $(CFLAGS) $(NAME).o $(NAME)_test.c -o $@

test: $(TEST_SHARED) $(TEST_STATIC)
	$(SAN_ENV) LD_LIBRARY_PATH=.:$$LD_LIBRARY_PATH ./$(TEST_SHARED)
	$(SAN_ENV) ./$(TEST_STATIC)

# Valgrind: full memory checking with leak detection.
# Mutually exclusive with ASAN/MSAN.
#
#   make test-valgrind
#
test-valgrind: $(TEST_SHARED) $(TEST_STATIC)
	LD_LIBRARY_PATH=.:$$LD_LIBRARY_PATH valgrind --leak-check=full --error-exitcode=1 ./$(TEST_SHARED)
	valgrind --leak-check=full --error-exitcode=1 ./$(TEST_STATIC)

# Fuzzer: builds with ASAN + libFuzzer instrumentation.
# Requires clang.
#
#   make fuzzer                 - Build and print run instructions
#   make fuzzer-corpus-seeds    - Seed the corpus from test data
#   make clean-fuzzer-corpus    - Remove the corpus directory
#
$(FUZZER): $(NAME).o $(NAME)_fuzzer.c
	$(CC) $(CFLAGS) $(NAME).o $(NAME)_fuzzer.c -o $@

$(FUZZER_CORPUS)/:
	mkdir -p $@

fuzzer: $(FUZZER) | $(FUZZER_CORPUS)/
	@echo
	@echo "Fuzzer built: ./$(FUZZER)"
	@echo
	@echo "Run with:"
	@echo "  cd libs/c && ./$(FUZZER) $(FUZZER_CORPUS)/"
	@echo
	@echo "Seed the corpus first with:"
	@echo "  make fuzzer-corpus-seeds"

fuzzer-corpus-seeds: $(FUZZER) | $(FUZZER_CORPUS)/
	@if [ -z "$$(ls -A $(FUZZER_CORPUS)/ 2>/dev/null)" ]; then \
		printf 'qrcode\0TESTING123\0version=20' > $(FUZZER_CORPUS)/qrcode_opts; \
		printf 'qrcode\0Hello World\0' > $(FUZZER_CORPUS)/qrcode_hello; \
		printf 'ean13\009521234543213\0' > $(FUZZER_CORPUS)/ean13; \
		printf 'code128\0Test\0includetext' > $(FUZZER_CORPUS)/code128; \
		printf 'datamatrix\0ABC123\0' > $(FUZZER_CORPUS)/datamatrix; \
		printf 'pdf417\0Hello\0columns=2' > $(FUZZER_CORPUS)/pdf417; \
		printf 'code39\0HELLO\0includecheck' > $(FUZZER_CORPUS)/code39; \
		printf 'nonexistent\0data\0' > $(FUZZER_CORPUS)/unknown; \
		printf '\0\0' > $(FUZZER_CORPUS)/empty_all; \
		printf 'qrcode' > $(FUZZER_CORPUS)/name_only; \
		echo "Seeded $(FUZZER_CORPUS)/ with $$(ls $(FUZZER_CORPUS)/ | wc -l) inputs"; \
	else \
		echo "$(FUZZER_CORPUS)/ already populated; skipping seed"; \
	fi

clean-fuzzer-corpus:
	$(RM) -r $(FUZZER_CORPUS)/

clean:
	$(RM) $(TEST_SHARED) $(TEST_STATIC) $(FUZZER) *.o *.so* *.a *.d

install: install-static install-shared

install-headers:
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 0644 $(NAME).h $(DESTDIR)$(PREFIX)/include
	install -m 0644 ../bindings/cpp/$(NAME).hpp $(DESTDIR)$(PREFIX)/include

install-static: libstatic install-headers
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).a $(DESTDIR)$(LIBDIR)

install-shared: libshared install-headers
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)
	cd $(DESTDIR)$(LIBDIR) && ln -sf lib$(NAME).so.$(VERSION) lib$(NAME).so
	cd $(DESTDIR)$(LIBDIR) && ln -sf lib$(NAME).so.$(VERSION) lib$(NAME).so.$(MAJOR)
	-ldconfig

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).hpp
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so*
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).a
	-ldconfig
