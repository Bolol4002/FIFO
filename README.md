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

# 3. FIFO implementation: Circular Buffer

Dynamic memory allocation doesn't exist in FPGA hardware.
Instead use a **fixed-size circular buffer**.
Structure:
* `wraddr` → next write location
* `rdaddr` → next read location

Rules:

### Empty

```text
wraddr == rdaddr
```

### Full

```text
(wraddr + 1) == rdaddr
```

Pointers wrap around:

```text
0 → 1 → 2 → ... → N−1 → 0
```

For FIFO size = `2^N`:

* Pointer width = `N bits`
* Natural overflow handles wraparound
* Fill can be computed from pointer difference

---

# 4. Software model (C++)

The article first builds FIFO in C++ to explain behavior.

Core methods:

```cpp
reset()
write(item)
read()
fill()
```

Key ideas:

* Writes advance write pointer
* Reads advance read pointer
* Refuse writes when full
* Refuse reads when empty
* Track overflow/underflow flags

---

# 5. First Verilog attempt — Problems

Naively translating C++ into Verilog causes issues:

### Problem 1: Simultaneous read + write

```verilog
if(write)
else if(read)
```

One operation blocks the other.

### Problem 2: Pointer wrapping

Need modulo behavior.

### Problem 3: Fill count delay

Computing:

```verilog
fill = wraddr - rdaddr
```

becomes stale by one cycle.

---

# 6. Improved Verilog design

Main changes:

### Separate read/write logic

Use independent `always` blocks.

### Introduce flags

```text
full
empty
```

instead of recomputing every time.

### Allow simultaneous read/write

If FIFO isn't empty:

* Read current item
* Write next item

### Maintain fill counter incrementally

Instead of recalculating:

```text
read → fill--
write → fill++
both → unchanged
```

---

# 7. High-speed optimization

Problem:
Computing `full` and `empty` combinationally hurts timing.

Solution:
Register them **one cycle earlier**.

Precompute:

```verilog
dblnext = wraddr + 2
nxtread = rdaddr + 1
```

Then update:

```text
full
empty
```

synchronously.

Result:

* Better timing
* Easier FPGA routing
* Higher clock frequency

---

# 8. Main engineering lesson

FIFO is not a single reusable block.

Different systems want different behavior:

* UART → occupancy info
* Video → burst buffering
* AXI → multiple internal pointers
* CPU → different fullness thresholds

So in practice engineers often:

* start from a known-good FIFO,
* then adapt interface and policies per application.

---

## One-line takeaway

A FIFO in FPGA is fundamentally a **circular buffer with read/write pointers, full/empty detection, overflow/underflow handling, and careful treatment of simultaneous reads and writes for timing correctness.**
