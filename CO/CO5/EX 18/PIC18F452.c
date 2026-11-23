
#include <xc.h>
#define _XTAL_FREQ 4000000UL

#define STEPS_PER_FLOOR 200

unsigned char floor_now = 0;
unsigned char request = 0;
unsigned char direction = 1;
unsigned char phase = 0;
unsigned char previous_buttons = 0x0F;

const unsigned char seg[4] = {
    0x3F, 0x06, 0x5B, 0x4F
};

const unsigned char motor[4] = {
    0x09, 0x0C, 0x06, 0x03
};

void display_floor(void)
{
    PORTC = seg[floor_now];
}

void update_leds(void)
{
    PORTAbits.RA0 = (direction == 1);
    PORTAbits.RA1 = (direction == 0);
    PORTAbits.RA2 = 0;
}

void read_buttons(void)
{
    unsigned char buttons;
    unsigned char pressed;

    buttons = (~PORTB) & 0x0F;
    pressed = buttons & (~previous_buttons);

    request |= pressed;
    previous_buttons = buttons;
}

void door_open(void)
{
    unsigned int i;

    LATD = 0;
    PORTAbits.RA0 = 0;
    PORTAbits.RA1 = 0;
    PORTAbits.RA2 = 1;

    for(i = 0; i < 200; i++)
    {
        read_buttons();
        __delay_ms(10);
    }

    PORTAbits.RA2 = 0;
}

unsigned char requests_above(void)
{
    unsigned char mask = 0;
    unsigned char i;

    for(i = floor_now + 1; i < 4; i++)
        mask |= (1 << i);

    return request & mask;
}

unsigned char requests_below(void)
{
    unsigned char mask = 0;
    unsigned char i;

    for(i = 0; i < floor_now; i++)
        mask |= (1 << i);

    return request & mask;
}

void move_one_floor(void)
{
    unsigned int i;

    update_leds();

    for(i = 0; i < STEPS_PER_FLOOR; i++)
    {
        read_buttons();

        if(direction == 1)
            phase = (phase + 1) & 3;
        else
            phase = (phase - 1) & 3;

        LATD = motor[phase];

        __delay_ms(10);
    }

    LATD = 0;

    if(direction == 1)
        floor_now++;
    else
        floor_now--;

    display_floor();
}

void initialise(void)
{
    ADCON1 = 0x0F;

    TRISA = 0xF8;
    TRISB = 0x0F;
    TRISC = 0x80;
    TRISD = 0xF0;

    PORTA = 0;
    PORTB = 0;
    PORTC = 0;
    PORTD = 0;

    LATD = 0;

    OPTION_REGbits.RBPU = 0;

    display_floor();
}

void main(void)
{
    initialise();

    while(1)
    {
        read_buttons();

        if(request & (1 << floor_now))
        {
            request &= ~(1 << floor_now);
            door_open();
        }

        else if(direction == 1)
        {
            if(requests_above())
            {
                move_one_floor();
            }
            else if(requests_below())
            {
                direction = 0;
            }
            else
            {
                PORTA &= 0xF8;
            }
        }

        else
        {
            if(requests_below())
            {
                move_one_floor();
            }
            else if(requests_above())
            {
                direction = 1;
            }
            else
            {
                PORTA &= 0xF8;
            }
        }
    }
}
