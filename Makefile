js:
	@find coffee/lib -name '*.coffee' | xargs coffee -c -o js/lib
	@find coffee/test -name '*.coffee' | xargs coffee -c -o js/test

test:
	./node_modules/.bin/mocha ./coffee/test

test-js:
	./node_modules/.bin/mocha ./js/test

.PHONY: js test test-js