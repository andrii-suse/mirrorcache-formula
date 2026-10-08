TESTS = $$( { \
	git status --porcelain *.sh 2>/dev/null | awk '{print $$NF}' | sed 's|^t/||'; \
	git log --name-only --format="" -- *.sh 2>/dev/null | grep -E '\.sh$$' | sed 's|^t/||'; \
	ls -t *.sh 2>/dev/null; \
} | awk '!seen[$$0]++ && -f $$0' )

list_tests:
	@for f in $(TESTS); do echo "$$f"; done

test_container:
	( for f in $(TESTS); do ./$$f && continue; echo FAIL $$f; exit 1 ; done )

test_container_fast:
	( for f in $(TESTS); do T_CACHE_PACKAGES=1 ./$$f && continue; echo FAIL $$f; exit 1 ; done )
