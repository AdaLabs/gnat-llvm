all: sanity-check
	$(MAKE) -C llvm-interface build gnatlib-automated

.PHONY: acats ccg-acats fixed-bugs ccg-tests llvm clean distclean

sanity-check:
	@if ! [ -d llvm-interface/gnat_src ]; then \
          echo "error: directory llvm-interface/gnat_src not found"; exit 1; \
	fi

build build-opt clean gnatlib: sanity-check
	$(MAKE) -C llvm-interface $@

gnatlib%: sanity-check
	$(MAKE) -C llvm-interface $@

zfp: sanity-check
	$(MAKE) -C llvm-interface $@

automated:
	$(MAKE) -C llvm-interface bootstrap

# Entry points for cross builds. Currently, it builds a cross compiler that
# isn't bootstrapped (i.e., we build it directly with native GNAT). Cross
# GNAT-LLVM then compiles the minimal ZFP runtime (to be extended to the
# standard cross runtimes).
cross-automated:
	$(MAKE) -C llvm-interface zfp-opt

DESTDIR?=$(dir $(shell which llvm-config))

solada:
	$(MAKE) -C llvm-interface build

solada-install:
	mkdir -p $(DESTDIR)
	cp -rp llvm-interface/bin/* $(DESTDIR)

llvm:
	$(MAKE) -j1 -C llvm setup
	$(MAKE) -C llvm llvm

acats:
	$(MAKE) -C acats tests

ccg-acats:
	$(MAKE) -C acats ccg

fixed-bugs:
	$(MAKE) -C fixedbugs

ccg-tests:
	$(MAKE) -C ccg-tests/tests

distclean: clean
	$(MAKE) -C llvm clean

