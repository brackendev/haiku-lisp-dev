# beui-server Makefile for Haiku

CXX = g++
CXXFLAGS = -Wall -Wextra -Werror -O2 -std=c++17
LDFLAGS = -lbe -lroot -lpthread

TARGET = beui-server
SRCS = beui-server.cpp

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET)

format:
	@command -v haiku-format >/dev/null 2>&1 || \
		(echo "haiku-format not found. Install with: pkgman install haiku_format" && exit 1)
	@echo "Formatting with haiku-format..."
	haiku-format -i $(SRCS)

format-check:
	@command -v haiku-format >/dev/null 2>&1 || \
		(echo "haiku-format not found. Install with: pkgman install haiku_format" && exit 1)
	@echo "Checking format..."
	@violations=0; \
	for f in $(SRCS); do \
		if ! haiku-format "$$f" | diff -u "$$f" - >/tmp/haiku-fmt-diff.$$$$ 2>&1; then \
			echo "Format violations in $$f:"; \
			cat /tmp/haiku-fmt-diff.$$$$; \
			violations=$$((violations + 1)); \
		fi; \
		rm -f /tmp/haiku-fmt-diff.$$$$; \
	done; \
	if [ $$violations -ne 0 ]; then \
		echo ""; \
		echo "$$violations file(s) need formatting. Run 'make format' to fix."; \
		exit 1; \
	fi; \
	echo "All files clean"

build-check:
	@echo "Building with warnings as errors..."
	@$(MAKE) clean >/dev/null 2>&1
	$(MAKE) all
	@echo "Build succeeded with no warnings"

check: format-check build-check

help:
	@echo "beui-server Makefile (run on Haiku)"
	@echo ""
	@echo "  make               Build server"
	@echo "  make format        Format code in place (haiku-format -i)"
	@echo "  make format-check  Verify formatting without rewriting (strict)"
	@echo "  make check         Strict gate: format-check + warnings-as-errors build"
	@echo "  make build-check   Build with warnings as errors"
	@echo "  make clean         Remove build artifacts"
	@echo "  make help          Show this help"

.PHONY: all clean format format-check check build-check help
