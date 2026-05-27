# qtui-server Makefile for Haiku
#
# Requires the LLD linker to work around a Haiku binutils bug:
#   pkgman install qt6_base_devel llvm17_lld

CXX = g++
MOC = /boot/system/lib/Qt6/moc

QT_HEADERS = /boot/system/develop/headers/Qt6
INCLUDES = -I. -I$(QT_HEADERS) -I$(QT_HEADERS)/QtWidgets -I$(QT_HEADERS)/QtGui -I$(QT_HEADERS)/QtCore

CXXFLAGS = -Wall -Wextra -Werror -O2 -std=c++17 -fPIC -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB $(INCLUDES)
LDFLAGS = -fuse-ld=lld -L/boot/system/lib -lQt6Widgets -lQt6Gui -lQt6Core

TARGET = qtui-server
SRCS = qtui-server.cpp
OBJ = qtui-server.o
MOC_OUT = qtui-server.moc

all: $(TARGET)

$(MOC_OUT): $(SRCS)
	$(MOC) $(INCLUDES) $< -o $@

$(OBJ): $(SRCS) $(MOC_OUT)
	$(CXX) -c $(CXXFLAGS) -o $@ $<

$(TARGET): $(OBJ)
	$(CXX) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET) $(OBJ) $(MOC_OUT)

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
	@echo "qtui-server Makefile (run on Haiku)"
	@echo ""
	@echo "  make               Build server"
	@echo "  make format        Format code in place (haiku-format -i)"
	@echo "  make format-check  Verify formatting without rewriting (strict)"
	@echo "  make check         Strict gate: format-check + warnings-as-errors build"
	@echo "  make build-check   Build with warnings as errors"
	@echo "  make clean         Remove build artifacts"
	@echo "  make help          Show this help"

.PHONY: all clean format format-check check build-check help
