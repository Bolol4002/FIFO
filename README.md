# FIFO
rtl implementation of fifo

# Summary — *Getting the Basic FIFO Right* (ZipCPU)

- Ok so it has many application few of them which can be read from https://zipcpu.com/blog/2017/07/29/fifo.html
**Important note from the author:**
The author later found bugs in this FIFO design using formal verification. This version is mainly educational; it may mishandle **overflow** and **underflow** cases. The newer tutorial version is recommended.

## 1. What a FIFO is

FIFO = **First In, First Out**.

Think of it as a queue:

* Data enters at one end (**write**)
* Data leaves in the same order (**read**)

FIFO is used whenever:

> **Producer speed ≠ Consumer speed**

Examples:

* CPU buffering interrupts
* SDRAM burst transactions
* UART transmit/receive buffers
* Audio streaming
* Video pipelines

Purpose:

* Absorb timing differences
* Prevent stalls
* Reduce CPU overhead

---

# 2. FIFO operations

A basic FIFO supports:

### Reset

Clear contents and reset state.

### Write (enqueue)

Add data to the tail.

Constraint:

* If buffer is full → **overflow**

### Read (dequeue)

Remove oldest data.

Constraint:

* If buffer is empty → **underflow**

Status signals:

* Current fill level
* Empty
* Full
* Overflow flag
* Underflow flag

---

# 3. Block diagram

![Block diagram](img/block.png)

- when i_wr is high we write i_data to fifo.
- when i_rd is high we return o_data from fifo
- On any i_wr && !o_full, we’ll write i_data to memory
˝ On any i_rd && !o_empty, we’ll read and return o_data from memory
- On any w_wr, we’ll write i_data to our internal memory
- On any w_rd, we’ll read and return o_rdata from memory


# Verificatoin using - Verilator UCDB coverage

Good. This is exactly the point where toy RTL turns into **verification thinking**.

You already built FIFO RTL. Now the next jump is:

> Stop asking “does it work?”
>
> Start asking “how do I prove I exercised all important behavior?”

That is where **coverage** comes in.

---

# 1. What is coverage?

Simulation passing ≠ design verified.

Example:

You ran:

```text
write
write
read
```

Test passed.

But did you ever test:

* FIFO becoming full?
* reading when empty?
* simultaneous push+pop?
* pointer wraparound?
* reset during activity?

No.

Coverage measures **what scenarios happened**.

Two big categories:

| Type                | Checks                                    |
| ------------------- | ----------------------------------------- |
| Code Coverage       | Did simulator execute RTL lines/branches? |
| Functional Coverage | Did your intended scenarios happen?       |

For FIFO, functional coverage matters more.

---

# 2. What is UCDB?

UCDB = **Unified Coverage Database**

Think:

```text
Simulation
   ↓
Collect coverage
   ↓
Store results
   ↓
Generate report
```

Produces:

```text
coverage.ucdb
```

Then tools read it.

Usually:

```bash
vcover report coverage.ucdb
```

or GUI viewers.

---

# 3. Verilator and UCDB

Small correction.

Verilator traditionally focuses on:

* line coverage
* toggle coverage
* expression coverage

It does **not natively behave like full SystemVerilog functional coverage + UCDB workflows from commercial simulators**.

For your current stage:

Forget UCDB internals.

Focus on:

* collecting events
* printing coverage counters
* later move into SV covergroups/UVM.

Your goal this week:

```text
FIFO
↓
Testbench
↓
Coverage counters
↓
Coverage mindset
```

---

# 4. Coverage points for your FIFO

You wrote:

```text
push
pop
full
empty
```

Perfect beginner coverage set.

These become questions:

| Coverage Point | Meaning              |
| -------------- | -------------------- |
| push           | Was write attempted? |
| pop            | Was read attempted?  |
| full           | Did FIFO ever fill?  |
| empty          | Did FIFO ever drain? |

---

# 5. Add basic coverage into testbench

Create counters.

`tb/fifo_tb.v`

```verilog
module fifo_tb;

reg clk;
reg rst;
reg wr;
reg rd;
reg [7:0] data;

wire [7:0] o_data;
wire full;
wire empty;

fifo dut(
    .clk(clk),
    .rst(rst),
    .wr(wr),
    .rd(rd),
    .data(data),
    .o_data(o_data),
    .full(full),
    .empty(empty)
);

// coverage counters
integer cov_push = 0;
integer cov_pop = 0;
integer cov_full = 0;
integer cov_empty = 0;

// coverage monitor
always @(posedge clk) begin

    if (wr && !full)
        cov_push++;

    if (rd && !empty)
        cov_pop++;

    if (full)
        cov_full++;

    if (empty)
        cov_empty++;
end

initial begin

    clk=0;
    rst=1;
    wr=0;
    rd=0;

    #10 rst=0;

    // fill FIFO
    repeat(16) begin
        @(posedge clk);
        wr=1;
        data=$random;
    end

    wr=0;

    // drain FIFO
    repeat(16) begin
        @(posedge clk);
        rd=1;
    end

    rd=0;

    #20;

    $display("=== COVERAGE ===");
    $display("push=%0d",cov_push);
    $display("pop=%0d",cov_pop);
    $display("full=%0d",cov_full);
    $display("empty=%0d",cov_empty);

    $finish;

end

always #5 clk=~clk;

endmodule
```

---

# 6. Expected output

Example:

```text
=== COVERAGE ===
push=16
pop=16
full=2
empty=3
```

Interpretation:

```text
✓ writes happened
✓ reads happened
✓ full condition reached
✓ empty condition reached
```

If:

```text
full=0
```

your test never filled FIFO.

---

# 7. Review FIFO waveform (important)

Open waveform.

Signals to inspect:

```text
clk
rst
wr
rd
wptr
rptr
count
full
empty
data
o_data
```

Expected:

```text
count

0
1
2
3
...
16 -> full=1
15
14
...
0 -> empty=1
```

Watch for:

### Red flag 1 — count > DEPTH

Bug.

---

### Red flag 2 — pointers move while full

Bug.

---

### Red flag 3 — data order wrong

FIFO violation.

Write:

```text
10
20
30
```

Read:

```text
10
20
30
```

not

```text
30
10
20
```

---

# 8. One improvement in your RTL

This part:

```verilog
default: count <= count;
```

Remove it.

Registers already hold value.

Use:

```verilog
case ({wr && !full, rd && !empty})
    2'b10: count <= count + 1;
    2'b01: count <= count - 1;
endcase
```

Cleaner.

---

# 9. Next verification coverage points (after this works)

Order:

```text
✓ push
✓ pop
✓ full
✓ empty
↓
simultaneous wr+rd
↓
pointer wraparound
↓
overflow attempt
↓
underflow attempt
↓
randomized transactions
↓
scoreboard
↓
SV covergroups
↓
UVM
```

Do this properly and you're no longer “writing Verilog”—you're doing actual RTL verification.
