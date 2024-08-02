#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define WDG_BASE_ADDR 0x10004000
#define WDG_REG_CTRL  *((volatile uint32_t *)(WDG_BASE_ADDR + 0))
#define WDG_REG_PSCR  *((volatile uint32_t *)(WDG_BASE_ADDR + 4))
#define WDG_REG_CNT   *((volatile uint32_t *)(WDG_BASE_ADDR + 8))
#define WDG_REG_CMP   *((volatile uint32_t *)(WDG_BASE_ADDR + 12))
#define WDG_REG_STAT  *((volatile uint32_t *)(WDG_BASE_ADDR + 16))
#define WDG_REG_KEY   *((volatile uint32_t *)(WDG_BASE_ADDR + 20))
#define WDG_REG_FEED  *((volatile uint32_t *)(WDG_BASE_ADDR + 24))

#define WDG_MAGIC_NUM (uint32_t)0x5F3759DF

int main(){
    putstr("wdg test\n");
    
    WDG_REG_KEY = WDG_MAGIC_NUM;
    WDG_REG_CTRL = (uint32_t) 0x0;

    // feed wdg in every 50ms
    WDG_REG_KEY = WDG_MAGIC_NUM;
    WDG_REG_PSCR = (uint32_t)(50 - 1);    // div 50 for 1MHz

    WDG_REG_KEY = WDG_MAGIC_NUM;
    WDG_REG_CMP = (uint32_t)(50000 - 1);  // overflow in every 50ms

    while(WDG_REG_STAT == (uint32_t)0x1); // clear irq flag

    WDG_REG_KEY = WDG_MAGIC_NUM;
    WDG_REG_CTRL = (uint32_t) 0b101;      // core and ov trg en 

    WDG_REG_KEY = WDG_MAGIC_NUM;
    WDG_REG_FEED = (uint32_t) 0x1;
    WDG_REG_KEY = WDG_MAGIC_NUM;
    WDG_REG_FEED = (uint32_t) 0x0;

    for(int i = 0; i < 10; ++i) {
        printf("WDG_REG_PSCR: %d\n", WDG_REG_PSCR);
        while(WDG_REG_STAT == (uint32_t)0);
        printf("%d wdg reset trigger\n", i);
    }

    putstr("wdg reset test done\n");
    return 0;
}
