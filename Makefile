SHELL = /bin/sh
# Copyright 2020 the aerpatch authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
.SUFFIXES:
.SUFFIXES: .r2



# Build directories.
gamedir = $(HOME)/.local/share/Steam/steamapps/common/HyperLightDrifter
prjdir = $(realpath $(CURDIR))
srcdir = $(prjdir)/src
builddir = $(prjdir)/build

# Build files.
src = $(wildcard $(srcdir)/*.r2)
origbin = $(gamedir)/HyperLightDrifter
patchbin = $(builddir)/HyperLightDrifter
patch = $(builddir)/HyperLightDrifter-diff

# Program and flag defaults.
R2 = radare2
R2FLAGS = -q
ALL_R2FLAGS = -nw $(R2FLAGS)
DIFF = rsync
ALL_DIFFFLAGS = $(DIFFFLAGS)



.PHONY: patch
patch: $(patch)

$(patch): $(builddir) $(origbin) $(patchbin)
	$(DIFF) --only-write-batch=$@ $(ALL_DIFFFLAGS) $(patchbin) $(origbin)

$(patchbin): $(builddir) $(origbin) $(src)
	cp -f $(origbin) $(patchbin)
	$(R2) -i $(src) $(ALL_R2FLAGS) $@

$(builddir):
	mkdir -p $@

.PHONY: all
all: patch

.PHONY: clean
clean:
	rm -rf $(builddir)
