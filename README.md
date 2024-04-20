# WDG

## Features
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

FULL vision of datatsheet can be found in [datasheet.md](./doc/datasheet.md).

## Build and Test
```bash
make comp    # compile code with vcs
make run     # compile and run test with vcs
make wave    # open fsdb format waveform with verdi
```