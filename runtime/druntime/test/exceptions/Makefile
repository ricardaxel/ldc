include ../common.mak

TESTS=stderr_msg unittest_assert invalid_memory_operation unknown_gc static_dtor \
	  future_message refcounted rt_trap_exceptions_drt catch_in_finally \
	  message_with_null

ifeq ($(OS)-$(BUILD),linux-debug)
	TESTS+=line_trace line_trace_21656 long_backtrace_trunc rt_trap_exceptions cpp_demangle
	LINE_TRACE_DFLAGS:=-L--export-dynamic
endif
ifeq ($(OS),linux)
	TESTS+=rt_trap_exceptions_drt_gdb
endif
ifeq ($(OS)-$(BUILD),freebsd-debug)
	TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
	LINE_TRACE_DFLAGS:=-L--export-dynamic
endif
ifeq ($(OS)-$(BUILD),dragonflybsd-debug)
	TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
	LINE_TRACE_DFLAGS:=-L--export-dynamic
endif
ifeq ($(OS)-$(BUILD),osx-debug)
	TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
	LINE_TRACE_DFLAGS:=
endif

ifeq ($(BUILD),debug)
	TESTS+=assert_fail
endif

DIFF:=diff
SED:=sed
GDB:=gdb

.PHONY: all clean
all: $(addprefix $(ROOT)/,$(addsuffix .done,$(TESTS)))

$(ROOT)/line_trace.done: $(ROOT)/line_trace
	@echo Testing line_trace
	$(QUIET)$(TIMELIMIT)$(ROOT)/line_trace $(RUN_ARGS) > $(ROOT)/line_trace.output
	# Use sed to canonicalize line_trace.output and compare against expected output in line_trace.exp
	$(QUIET)$(SED) "s|^.*/src/|src/|g; s/\[0x[0-9a-f]*\]/\[ADDR\]/g; s/scope //g; s/Nl//g" $(ROOT)/line_trace.output | $(DIFF) line_trace.exp -
	@rm -f $(ROOT)/line_trace.output
	@touch $@

# https://issues.dlang.org/show_bug.cgi?id=21656
$(ROOT)/line_trace_21656.done: $(ROOT)/line_trace
	@echo Testing line_trace_21656
	@mkdir -p $(ROOT)/line_trace_21656
	@touch $(ROOT)/line_trace_21656/line_trace
	$(QUIET)cd $(ROOT)/line_trace_21656 && PATH="..:$$PATH" $(TIMELIMIT)line_trace $(RUN_ARGS) > line_trace.output
	$(QUIET)$(SED) "s|^.*/src/|src/|g; s/\[0x[0-9a-f]*\]/\[ADDR\]/g; s/scope //g; s/Nl//g" $(ROOT)/line_trace_21656/line_trace.output | $(DIFF) line_trace.exp -
	@rm -rf $(ROOT)/line_trace_21656
	@touch $@

$(ROOT)/long_backtrace_trunc.done: $(ROOT)/long_backtrace_trunc
	@echo Testing long_backtrace_trunc
	$(QUIET)$(TIMELIMIT)$(ROOT)/long_backtrace_trunc $(RUN_ARGS) > $(ROOT)/long_backtrace_trunc.output
	# Use sed to canonicalize long_backtrace_trunc.output and compare against expected output in long_backtrace_trunc.exp
	$(QUIET)$(SED) "s|^.*/src/|src/|g; s/\[0x[0-9a-f]*\]/\[ADDR\]/g; s/scope //g; s/Nl//g; s|.F.*F.|.|g; s|.G.*G.|.|g" $(ROOT)/long_backtrace_trunc.output | $(DIFF) long_backtrace_trunc.exp -
	@rm -f $(ROOT)/long_backtrace_trunc.output
	@touch $@

$(ROOT)/chain.done: $(ROOT)/chain
	@echo Testing chain
	$(QUIET)$(TIMELIMIT)$(ROOT)/chain $(RUN_ARGS) > $(ROOT)/chain.output
	@rm -f $(ROOT)/chain.output
	@touch $@

$(ROOT)/stderr_msg.done: STDERR_EXP="stderr_msg msg"
$(ROOT)/unittest_assert.done: STDERR_EXP="unittest_assert msg"
$(ROOT)/invalid_memory_operation.done: STDERR_EXP="InvalidMemoryOperationError"
$(ROOT)/unknown_gc.done: STDERR_EXP="'unknowngc'"
$(ROOT)/static_dtor.done: STDERR_EXP="dtor_called_more_than_once"
$(ROOT)/static_dtor.done: NEGATE=!
$(ROOT)/future_message.done: STDERR_EXP="exception I have a custom message. exception exception "
$(ROOT)/catch_in_finally.done: STDERR_EXP="success."
$(ROOT)/rt_trap_exceptions.done: STDERR_EXP="object.Exception@src/rt_trap_exceptions.d(12): this will abort"
$(ROOT)/rt_trap_exceptions.done: STDERR_EXP2="src/rt_trap_exceptions.d:8 main"
$(ROOT)/assert_fail.done: STDERR_EXP="success."
$(ROOT)/cpp_demangle.done: STDERR_EXP="thrower(int)"

$(ROOT)/message_with_null.done: STDERR_EXP=" world"

$(ROOT)/%.done: $(ROOT)/%
	@echo Testing $*
	$(QUIET)$(TIMELIMIT)$(ROOT)/$* $(RUN_ARGS) 2>$(ROOT)/$*.stderr || true

	@if $(NEGATE) grep -qF $(STDERR_EXP) < $(ROOT)/$*.stderr ; then true ; else  \
		echo 'Searched for pattern $(STDERR_EXP), NEGATE = $(NEGATE)' ;\
		tail --bytes=5000 $(ROOT)/$*.stderr ;\
		exit 1 ;\
	fi
	@if [ ! -z $(STDERR_EXP2) ] ; then \
		if $(NEGATE) grep -qF $(STDERR_EXP2) < $(ROOT)/$*.stderr ; then true ; else \
			echo 'Searched for '$(STDERR_EXP2)' NEGATE = $(NEGATE)' ;\
			tail --bytes=5000 $(ROOT)/$*.stderr ;\
			exit 1 ;\
		fi \
	fi
	@touch $@

$(ROOT)/rt_trap_exceptions_drt.done: STDERR_EXP="uncaught exception\nobject.Exception@rt_trap_exceptions_drt.d(4): exception"
$(ROOT)/rt_trap_exceptions_drt.done: RUN_ARGS="--DRT-trapExceptions=0"
$(ROOT)/rt_trap_exceptions_drt.done: NEGATE=!


$(ROOT)/rt_trap_exceptions_drt_gdb.done: $(ROOT)/rt_trap_exceptions_drt
	@echo Testing rt_trap_exceptions_drt_gdb
	$(QUIET)$(TIMELIMIT) $(GDB) -n -ex 'set confirm off' -ex run -ex 'bt full' -ex q --args $< --DRT-trapExceptions=0 \
		> $(ROOT)/rt_trap_exceptions_drt_gdb.output 2>&1 || true
	cat $(ROOT)/rt_trap_exceptions_drt_gdb.output
	grep "D main (args=...) at .*rt_trap_exceptions_drt.d:9" > /dev/null < $(ROOT)/rt_trap_exceptions_drt_gdb.output
	grep 'myLocal' > /dev/null < $(ROOT)/rt_trap_exceptions_drt_gdb.output
	! grep "No stack." > /dev/null < $(ROOT)/rt_trap_exceptions_drt_gdb.output
	@touch $@

$(ROOT)/refcounted.done: $(ROOT)/refcounted
	$(QUIET) $<
	@touch $@

ifeq (ldmd,$(findstring ldmd,$(DMD)))
# LDC: Make sure allocation intended to provoke exception is not elided.
$(ROOT)/invalid_memory_operation: DFLAGS+=-disable-gc2stack
endif
$(ROOT)/unittest_assert: DFLAGS+=-unittest -version=CoreUnittest
$(ROOT)/line_trace: DFLAGS+=$(LINE_TRACE_DFLAGS)
$(ROOT)/long_backtrace_trunc: DFLAGS+=$(LINE_TRACE_DFLAGS)
$(ROOT)/rt_trap_exceptions: DFLAGS+=$(LINE_TRACE_DFLAGS)
$(ROOT)/rt_trap_exceptions_drt: DFLAGS+=-g
$(ROOT)/refcounted: DFLAGS+=-dip1008
$(ROOT)/cpp_demangle: DFLAGS+=-L-lstdc++ $(LINE_TRACE_DFLAGS)

$(ROOT)/%: $(SRC)/%.d $(DMD) $(DRUNTIME)
	$(QUIET)$(DMD) $(DFLAGS) -of$@ $<

clean:
	rm -rf $(GENERATED)
