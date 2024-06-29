typedef char int8_t;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;

void printf(int8_t* str){
    static uint16_t* VideoMemory = (uint16_t*) 0xb8000;
    
    static uint8_t x=0, y=0;

    for(int i = 0; str[i] != '\0'; ++i){
        switch(str[i]) {
            case '\n':
                x=0;
                y++;
                break;
            default:
                VideoMemory[x+y*80] = (VideoMemory[i] & 0xFF00) | str[i];
                x++;
        }
        
        if(x >= 80){
            x=0;
            y++;
        }

        if(y >= 25){
            for(y = 0; y < 25; y++)
                for(x = 0; x < 80; x++)
                    VideoMemory[x+y*80] = (VideoMemory[i] & 0xFF00) | ' ';
            x=0;
            y=0;
        }
    }
}

extern "C" void kernelMain() {
    printf("Welcome to Hashida OS... EPK!!!\n");
}