NAME = postscriptbarcode

VERSION := $(shell head -n 1 ../CHANGES)
MAJOR   := $(firstword $(subst ., ,$(VERSION)))

FUZZER = $(NAME)_fuzzer
FUZZER_LOAD = $(NAME)_fuzzer_load
FUZZER_CORPUS = corpus
FUZZER_LOAD_CORPUS = corpus_load

# Fuzzer implies sanitizers
ifneq ($(filter fuzzer fuzzer-corpus-seeds fuzzer-load fuzzer-load-corpus-seeds,$(MAKECMDGOALS)),)
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

.PHONY: default
default: lib

.PHONY: all
all: default test

.PHONY: lib
lib: libshared libstatic

.PHONY: libshared
libshared: lib$(NAME).so.$(VERSION) lib$(NAME).so lib$(NAME).so.$(MAJOR)

.PHONY: libstatic
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

.PHONY: test
test: $(TEST_SHARED) $(TEST_STATIC)
	$(SAN_ENV) LD_LIBRARY_PATH=.:$$LD_LIBRARY_PATH ./$(TEST_SHARED)
	$(SAN_ENV) ./$(TEST_STATIC)

.PHONY: test-static
test-static: $(TEST_STATIC)
	$(SAN_ENV) ./$(TEST_STATIC)

# Valgrind: full memory checking with leak detection.
# Mutually exclusive with ASAN/MSAN.
#
#   make test-valgrind
#
.PHONY: test-valgrind
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

.PHONY: fuzzer
fuzzer: $(FUZZER) | $(FUZZER_CORPUS)/
	@echo
	@echo "Fuzzer built: ./$(FUZZER)"
	@echo
	@echo "Run with:"
	@echo "  cd libs/c && ./$(FUZZER) $(FUZZER_CORPUS)/"
	@echo
	@echo "Seed the corpus first with:"
	@echo "  make fuzzer-corpus-seeds"

.PHONY: fuzzer-corpus-seeds
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

.PHONY: clean-fuzzer-corpus
clean-fuzzer-corpus:
	$(RM) -r $(FUZZER_CORPUS)/ $(FUZZER_LOAD_CORPUS)/

#
# Load fuzzer: fuzzes the barcode.ps parser via fmemopen.
# Requires clang.
#
#   make fuzzer-load               - Build and print run instructions
#   make fuzzer-load-corpus-seeds  - Seed the corpus from barcode.ps
#   make clean-fuzzer-corpus       - Remove corpus directories
#
$(FUZZER_LOAD): $(NAME).o $(NAME)_fuzzer_load.c
	$(CC) $(CFLAGS) $(NAME).o $(NAME)_fuzzer_load.c -o $@

$(FUZZER_LOAD_CORPUS)/:
	mkdir -p $@

.PHONY: fuzzer-load
fuzzer-load: $(FUZZER_LOAD) | $(FUZZER_LOAD_CORPUS)/
	@echo
	@echo "Load fuzzer built: ./$(FUZZER_LOAD)"
	@echo
	@echo "Run with:"
	@echo "  cd libs/c && ./$(FUZZER_LOAD) -max_len=4096 $(FUZZER_LOAD_CORPUS)/"
	@echo
	@echo "Seed the corpus first with:"
	@echo "  make fuzzer-load-corpus-seeds"

.PHONY: fuzzer-load-corpus-seeds
fuzzer-load-corpus-seeds: $(FUZZER_LOAD) | $(FUZZER_LOAD_CORPUS)/
	@if [ -z "$$(ls -A $(FUZZER_LOAD_CORPUS)/ 2>/dev/null)" ]; then \
		printf '' > $(FUZZER_LOAD_CORPUS)/empty; \
		printf '%%!PS\n' > $(FUZZER_LOAD_CORPUS)/header_only; \
		printf '%% Barcode Writer in Pure PostScript - Version 2099-01-01\n' > $(FUZZER_LOAD_CORPUS)/version_only; \
		printf '%% Barcode Writer in Pure PostScript - Version 2099-01-01\n%% --BEGIN TEMPLATE--\n%% --END TEMPLATE--\n' > $(FUZZER_LOAD_CORPUS)/empty_template; \
		printf '%% Barcode Writer in Pure PostScript - Version 2099-01-01\n%% --BEGIN TEMPLATE--\n%% --BEGIN RESOURCE foo--\ncode\n%% --END RESOURCE foo--\n%% --END TEMPLATE--\n' > $(FUZZER_LOAD_CORPUS)/one_resource; \
		printf '%% Barcode Writer in Pure PostScript - Version 2099-01-01\n%% --BEGIN TEMPLATE--\n%% --BEGIN ENCODER bar--\n%% --REQUIRES foo--\n%% --DESC: Test\n%% --EXAM: data\n%% --EXOP: opts\n%% --RNDR: renlinear\n%% --FMLY: Test Family\ncode\n%% --END ENCODER bar--\n%% --END TEMPLATE--\n' > $(FUZZER_LOAD_CORPUS)/encoder_metadata; \
		printf '%% --BEGIN TEMPLATE--\n%% --BEGIN RESOURCE a--\nA\n%% --END RESOURCE a--\n%% --BEGIN RESOURCE b--\nB\n%% --END RESOURCE b--\n%% --BEGIN RESOURCE c--\nC\n%% --END RESOURCE c--\n%% --END TEMPLATE--\n' > $(FUZZER_LOAD_CORPUS)/multi_resource; \
		sed 's/$$/\r/' $(FUZZER_LOAD_CORPUS)/encoder_metadata > $(FUZZER_LOAD_CORPUS)/encoder_crlf; \
		sed 's/$$/\r/' $(FUZZER_LOAD_CORPUS)/multi_resource > $(FUZZER_LOAD_CORPUS)/multi_crlf; \
		printf '%% --BEGIN TEMPLATE--\n%% --BEGIN RESOURCE foo--\n' > $(FUZZER_LOAD_CORPUS)/truncated; \
		echo "Seeded $(FUZZER_LOAD_CORPUS)/ with $$(ls $(FUZZER_LOAD_CORPUS)/ | wc -l) inputs"; \
	else \
		echo "$(FUZZER_LOAD_CORPUS)/ already populated; skipping seed"; \
	fi

.PHONY: clean
clean:
	$(RM) $(TEST_SHARED) $(TEST_STATIC) $(FUZZER) $(FUZZER_LOAD) *.o *.so* *.a *.d

.PHONY: install
install: install-static install-shared

.PHONY: install-headers
install-headers:
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 0644 $(NAME).h $(DESTDIR)$(PREFIX)/include
	install -m 0644 ../bindings/cpp/$(NAME).hpp $(DESTDIR)$(PREFIX)/include

.PHONY: install-static
install-static: libstatic install-headers
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).a $(DESTDIR)$(LIBDIR)

.PHONY: install-shared
install-shared: libshared install-headers
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)
	cd $(DESTDIR)$(LIBDIR) && ln -sf lib$(NAME).so.$(VERSION) lib$(NAME).so
	cd $(DESTDIR)$(LIBDIR) && ln -sf lib$(NAME).so.$(VERSION) lib$(NAME).so.$(MAJOR)
	-ldconfig

.PHONY: uninstall
uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).hpp
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so*
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).a
	-ldconfig
