include ../common.mak

# LDC: enable on Windows too (port from win64.mak)
ifneq (,$(findstring win,$(OS)))

CXX:=cl.exe
TESTS:=array allocator memory new string utility vector

.PHONY: all clean

all: $(addprefix $(ROOT)/,$(TESTS))

$(ROOT)/%: $(SRC)/%.cpp $(SRC)/%_test.d
	mkdir -p $(dir $@)

	$(CXX) /MT /EHsc $(CXXFLAGS_BASE) -c /Fo$(ROOT)/$*_cpp.obj $<
	$(DMD) -mscrtlib=libcmt $(DFLAGS) -main -unittest -version=CoreUnittest $(ROOT)/$*_cpp.obj -run $(SRC)/$*_test.d

	$(CXX) /MD /EHsc $(CXXFLAGS_BASE) -c /Fo$(ROOT)/$*_cpp.obj $<
	$(DMD) -mscrtlib=msvcrt $(DFLAGS) -main -unittest -version=CoreUnittest $(ROOT)/$*_cpp.obj -run $(SRC)/$*_test.d

	$(CXX) /MTd /EHsc $(CXXFLAGS_BASE) -c /Fo$(ROOT)/$*_cpp.obj $<
	$(DMD) -mscrtlib=libcmtd $(DFLAGS) -main -unittest -version=CoreUnittest $(ROOT)/$*_cpp.obj -run $(SRC)/$*_test.d

	$(CXX) /MDd /EHsc $(CXXFLAGS_BASE) -c /Fo$(ROOT)/$*_cpp.obj $<
	$(DMD) -mscrtlib=msvcrtd $(DFLAGS) -main -unittest -version=CoreUnittest $(ROOT)/$*_cpp.obj -run $(SRC)/$*_test.d

clean:
	rm -rf $(GENERATED)

else
# non-Windows:

HASCPP17:=`echo wow | $(CXX) -std=c++17 -E -xc++ - > /dev/null 2>&1 && echo yes`

TESTS:=allocator new utility
TESTS11:=array
TESTS17:=string_view
OLDABITESTS:=

ifeq (osx,$(OS))
	TESTS11+=memory
#	TESTS+=string
#	TESTS+=vector
endif
ifeq (linux,$(OS))
	TESTS11+=exception typeinfo
	TESTS+=typeinfo
#	TESTS+=string
#	TESTS+=vector
	OLDABITESTS+=string
endif
ifeq (freebsd,$(OS))
	TESTS11+=memory
	TESTS+=string
#	TESTS+=vector
endif

# some build machines have ancient compilers, so we need to disable C++17 tests
ifneq (yes,$(HASCPP17))
TESTS17:=
endif

# LDC: libexecinfo required on FreeBSD (not required with lld 9+ (`pragma(lib)` in druntime))
EXTRA_LDC_LIBS:=
ifneq (,$(findstring freebsd,$(OS)))
	EXTRA_LDC_LIBS+=-lexecinfo
endif

.PHONY: all clean

all: $(addprefix $(ROOT)/,$(addsuffix .done,$(TESTS))) $(addprefix $(ROOT)/,$(addsuffix _11.done,$(TESTS11))) $(addprefix $(ROOT)/,$(addsuffix _17.done,$(TESTS17))) $(addprefix $(ROOT)/,$(addsuffix _old.done,$(OLDABITESTS))) $(addprefix $(ROOT)/,$(addsuffix _libcpp.done,$(LIBCPPTESTS)))

# run C++98 tests
$(ROOT)/%.done : $(ROOT)/%
	@echo Testing $*
	$(QUIET)$(TIMELIMIT)$(ROOT)/$* $(RUN_ARGS)
	@touch $@
# run C++11 tests
$(ROOT)/%_11.done : $(ROOT)/%_11
	@echo Testing $*_11
	$(QUIET)$(TIMELIMIT)$(ROOT)/$*_11 $(RUN_ARGS)
	@touch $@
# run C++17 tests
$(ROOT)/%_17.done : $(ROOT)/%_17
	@echo Testing $*_17
	$(QUIET)$(TIMELIMIT)$(ROOT)/$*_17 $(RUN_ARGS)
	@touch $@
# run libstdc++ _GLIBCXX_USE_CXX11_ABI=0 tests
$(ROOT)/%_old.done : $(ROOT)/%_old
	@echo Testing $*_old
	$(QUIET)$(TIMELIMIT)$(ROOT)/$*_old $(RUN_ARGS)
	@touch $@

# build C++98 tests
$(ROOT)/%: $(SRC)/%.cpp $(SRC)/%_test.d
	mkdir -p $(dir $@)
	$(QUIET)$(DMD) $(DFLAGS) -extern-std=c++98 -main -unittest -version=CoreUnittest -c -of=$(ROOT)/$*_d.o $(SRC)/$*_test.d
	$(QUIET)$(CXX) $(CXXFLAGS_BASE) -std=c++98 -o $@ $< $(ROOT)/$*_d.o $(DRUNTIME) $(EXTRA_LDC_LIBS) -lpthread $(LDL)
# build C++11 tests
$(ROOT)/%_11: $(SRC)/%.cpp $(SRC)/%_test.d
	mkdir -p $(dir $@)
	$(QUIET)$(DMD) $(DFLAGS) -extern-std=c++11 -main -unittest -version=CoreUnittest -c -of=$(ROOT)/$*_11_d.o $(SRC)/$*_test.d
	$(QUIET)$(CXX) $(CXXFLAGS_BASE) -std=c++11 -o $@ $< $(ROOT)/$*_11_d.o $(DRUNTIME) $(EXTRA_LDC_LIBS) -lpthread $(LDL)
# build C++17 tests
$(ROOT)/%_17: $(SRC)/%.cpp $(SRC)/%_test.d
	mkdir -p $(dir $@)
	$(QUIET)$(DMD) $(DFLAGS) -extern-std=c++17 -main -unittest -version=CoreUnittest -c -of=$(ROOT)/$*_17_d.o $(SRC)/$*_test.d
	$(QUIET)$(CXX) $(CXXFLAGS_BASE) -std=c++17 -o $@ $< $(ROOT)/$*_17_d.o $(DRUNTIME) $(EXTRA_LDC_LIBS) -lpthread $(LDL)
# build libstdc++ _GLIBCXX_USE_CXX11_ABI=0 tests
$(ROOT)/%_old: $(SRC)/%.cpp $(SRC)/%_test.d
	mkdir -p $(dir $@)
	$(QUIET)$(DMD) $(DFLAGS) -version=_GLIBCXX_USE_CXX98_ABI -main -unittest -version=CoreUnittest -c -of=$(ROOT)/$*_old_d.o $(SRC)/$*_test.d
	$(QUIET)$(CXX) $(CXXFLAGS_BASE) -D_GLIBCXX_USE_CXX11_ABI=0 -o $@ $< $(ROOT)/$*_old_d.o $(DRUNTIME) $(EXTRA_LDC_LIBS) -lpthread $(LDL)

clean:
	rm -rf $(GENERATED)

endif
# end non-Windows
