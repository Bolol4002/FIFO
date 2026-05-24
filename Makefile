.PHONY: clean

%:
	@echo "Compiling using iverilog" && \
	iverilog -o sim/$@.out rtl/$@.v tb/$@_tb.v && \
	echo "=== Simulation Output ===" && \
	vvp sim/$@.out

clean:
	rm -f *.vcd