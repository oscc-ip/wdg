## Datasheet

### Overview
The `wdg` IP is a fully parameterised soft IP to implement the watchdog timer. The IP features an APB4 slave interface, fully compliant with the AMBA APB Protocol Specification v2.0.

### Feature
* Programmable prescaler
    * max division factor is up to 2^20
    * can be changed ongoing
* 32-bit programmable free-running counter up wdg counter and compare register
* Auto reload counter
* Multiple clock source
    * internal division clock
    * external low-speed clock
* Register write-protected with key register
* Support software feed function bit
* Maskable overflow interrupt
* Static synchronous design
* Full synthesizable

### Interface
| port name | type        | description          |
|:--------- |:------------|:---------------------|
| apb4      | interface   | apb4 slave interface |
| wdg ->    | interface   | rtc slave interface |
| `wdg.rtc_clk_i` | input | rtc low speed clock input |
| `wdg.rst_o` | output | wdg system reset output |

### Register

| name | offset  | length | description |
|:----:|:-------:|:-----: | :---------: |
| [CTRL](#control-register) | 0x0 | 4 | control register |
| [PSCR](#prescaler-reigster) | 0x4 | 4 | prescaler register |
| [CNT](#counter-reigster) | 0x8 | 4 | counter register |
| [CMP](#compare-reigster) | 0xC | 4 | compare register |
| [STAT](#state-register) | 0x10 | 4 | state register |
| [KEY](#key-register) | 0x14 | 4 | key register |
| [FEED](#feed-register) | 0x18 | 4 | feed register |

#### Control Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:3]` | none | reserved |
| `[2:2]` | RW | EN |
| `[1:1]` | RW | ETR |
| `[0:0]` | RW | OVIE |

reset value: `depend on specific shuttle`

* EN: wdg counter enable
    * `EN = 1'b0`: watchdog counter disabled
    * `EN = 1'b1`: watchdog counter enabled

* ETR: extern tick clock trigger
    * `ETR = 1'b0`: intern clock trigger
    * `ETR = 1'b1`: extern periodic signal trigger

* OVIE: overflow interrupt enable
    * `OVIE = 1'b0`: overflow interrupt disabled
    * `OVIE = 1'b1`: overflow interrupt enabled

#### Prescaler Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:20]` | none | reserved |
| `[19:0]` | RW | PSCR |

reset value: `0x0000_0002`

* PSCR: the 20-bit prescaler value

#### Counter Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | none | CNT |

reset value: `0x0000_0000`

* CNT: the 32-bit watchdog counter value

#### Compare Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | RW | CMP |

reset value: `0x0000_0000`

* CMP: the 32-bit compare register value

#### State Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:1]` | none | reserved |
| `[0:0]` | RO | OVIF |

reset value: `0x0000_0000`

* OVIF: the overflow interrupt flag

### Key Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | RW | KEY |

reset value: `0x0000_0000`

* KEY: the 32-bit key register value
    * `KEY  = 32'h5F37_59DF`: unlock the write operation
    * `KEY != 32'h5F37_59DF`: no effect

### Feed Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:1]` | none | reserved |
| `[0:0]` | RW | FEED |

reset value: `0x0000_0000`

* FEED: feed watchdog bit
    * `FEED = 1'b1`: feed the watchdog
    * `FEED = 1'b0`: no effect

### Program Guide
These registers can be accessed by 4-byte aligned read and write. C-like pseudocode initialization operation:

```c
uint32_t val;
val = wdg.SYS // read the sys register
val = wdg.IDL // read the idl register
val = wdg.IDH // read the idh register

```
write operation:
```c
uint32_t val = value_to_be_written;
wdg.SYS = val // write the sys register
wdg.IDL = val // write the idl register
wdg.IDH = val // write the idh register

```

### Resoureces
### References
### Revision History