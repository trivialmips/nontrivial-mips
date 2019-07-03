/**********************************************************************************************************************************************************************
	This file supplies some public function.
**********************************************************************************************************************************************************************/

#include "../config.h"

_fp32 bubble_sort(_fp32 *delta, _s32 len)
{
    _s32 i, j;
    _fp32 tmp, sum, average, tmp_print;
    tmp = sum = average = 0;
#if 0 //PRINT
    for(i = 0; i < len; i++)
    {
	//printf("%f ", delta[i]);
	if(delta[i] < 0) 
	{
		tmp_print = 0 - delta[i];
		printf("-%d ", (unsigned int)(tmp_print*1000));
	}
	else
	{
		tmp_print = delta[i];
		printf("%d ", (unsigned int)(tmp_print*1000));
	}
	if(i == len-1) printf("\r\n");
    }
#endif
    for(i = len; i > 0; i--)
    {
	for(j = 0; j < (i - 1); j++)
	{
	    if(delta[j] > delta[j+1])
	    {
		tmp = delta[j];
		delta[j] = delta[j+1];
		delta[j+1] = tmp;
	    }
	}
    }
#if 0 //PRINT
    for(i = 0; i < len; i++)
    {
	//printf("%f ", delta[i]);
	if(delta[i] < 0) 
	{
		tmp_print = 0 - delta[i];
		printf("-%d ", (unsigned int)(tmp_print*1000));
	}
	else
	{
		tmp_print = delta[i];
		printf("%d ", (unsigned int)(tmp_print*1000));
	}
	if(i == len-1) printf("\r\n");
    }
#endif
    
    for(i = 1; i < len - 1; i++)
    {
	sum += delta[i];
    }
    average = sum/(len -2);
    return average;
}

void UintToBcd(_u32 dat, _u8 *bcd_buf)
{
    //_u32 tmp = dat;

    //if(dat>=100000000) dat=dat%100000000 ;
    dat = dat%100000000 ;
    bcd_buf[3] = dat/10000000 ;
    bcd_buf[3] <<= 4 ;
    dat = dat%10000000 ;
    bcd_buf[3] |= (dat/1000000) ;

    dat = dat%1000000 ;
    bcd_buf[2] = dat/100000 ;
    bcd_buf[2] <<= 4 ;
    dat = dat%100000 ;
    bcd_buf[2] |= (dat/10000) ;

    dat = dat%10000 ;
    bcd_buf[1] = dat/1000 ;
    bcd_buf[1] <<= 4 ;
    dat = dat%1000 ;
    bcd_buf[1] |= (dat/100) ;

    dat = dat%100 ;
    bcd_buf[0] = dat/10 ;
    bcd_buf[0] <<= 4 ;
    dat = dat%10 ;
    bcd_buf[0] |= dat ;

//printf("***: %d\t***BCD:%x %x %x %x\n", tmp, bcd_buf[3], bcd_buf[2], bcd_buf[1], bcd_buf[0]);
}

void BcdToUint(_u8 *bcd_buf, _u32 dat)
{
    dat =  ( ( (_u32)bcd_buf[3]>>4 ) *10000000 )
 	 + ( ( (_u32)bcd_buf[3]&0xf )*1000000 )
	 + ( ( (_u32)bcd_buf[2]>>4 ) *100000 ) 
 	 + ( ( (_u32)bcd_buf[2]&0xf )*10000 )
	 + ( ( (_u32)bcd_buf[1]>>4 ) *1000 ) 
 	 + ( ( (_u32)bcd_buf[1]&0xf )*100 )
	 + ( ( (_u32)bcd_buf[0]>>4 ) *10 ) 
 	 + ( ( (_u32)bcd_buf[0]&0xf ) );

//printf("***BCD:%x %x %x %x\t***: %d\n", bcd_buf[3], bcd_buf[2], bcd_buf[1], bcd_buf[0], dat);
}

//print float number
#if PRINT
int printf_float(float data)
{
	unsigned int i=0,j=0;
	i = (unsigned int)(data);
	j = (unsigned int)((data-i)*1000000);
	printf("%d.%06d\n", i, j);

	return 0;
}
#endif

