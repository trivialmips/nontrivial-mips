/**********************************************************************************************************************************************************************
	This file uses TDC module to caculate temperature and waterflow.
**********************************************************************************************************************************************************************/

#include "../config.h"

#if (TDC_TEMP_MODULE|TDC_FLOW_MODULE)
//#undef PRINT

void InitTdc(void)
{
#if (TEMP_TEST|FLOW_TEST)
	//if PMU[0]&0x10000, the cruise delay will divide 4.
	PMU[0] = 0x4;    //cruise delay 0.25s,2s
#else
	PMU[0] = 0x7004;    //cruise delay 2s,8s
#endif
	Sonar[0] = 0xa210;   //4M div 4, 96mA, Fireup, stop2	
	Sonar[1] = 0xf8840081;  //use Stdc, measure 2
	Sonar[2] = 0xc0300000;  //detect first wave
	Sonar[3] = 0x8004000;  //set delay, detect first wave
	Sonar[4] = 0x4000500;  //set delay, from first wave to the first stop
	Thsens[0] = 0xf7;   
#if TDC_TEMP_MODULE
	PMU[1] |= 0x80;	   //cruise mode, temp
#endif
#if TDC_FLOW_MODULE
	PMU[1] |= 0x40;	   //cruise mode, flow
#endif

#if (TEMP_TEST|FLOW_TEST)
	printf("Tdc initted...\n");
#endif
}

static _fp32 Time_Caculate(_u32 *result, struct Data *Lcd_data, _u32 start, _u32 stop_num)
{
	_u32 i;
#if FLOW_TEST
	//printf("Time_Caculate...\n");        
#endif

	_fp32 average_time;
	short a[stop_num],b[stop_num];
	short sum_a, sum_b;
	for(i=0;i<stop_num;i++)
	{
		a[i] = (short)(result[i+start]/0x10000);
		b[i] = (short)(result[i+start]%0x10000);
		if(b[i] == 0x1fff) b[i] = -1;   //It's a bug in fpga 
//printf("result[%d] = 0x%x\n", i, result[i]);
#if 0
if(b[i]>0xd5) 
{
	printf("result_low[%d] = 0x%x\n", i, b[i]); //0xc7==199
	printf("-------------------------------------------------------------------------------------------------------------------------------------------\n");
}
#endif
	}

	sum_a = 0;
	sum_b = 0;
	for(i=1;i<stop_num;i++)
	{
		sum_a += a[i] - a[0];
		sum_b += b[0] - b[i];  //sum_b<0, may be
	}

	average_time = (_fp32)(sum_a)*125+(_fp32)(sum_b)*125/Lcd_data->auto_caculate;   //ns, 10-9(s)

	return average_time;
}

static _fp32 GetUltrasonicVelocity(_fp32 temp)
{
	_fp32 V;
    V =     1402336 + 
            5033.58f*temp - 
            5795.06f*temp*temp/100 + 
            3316.36f*temp*temp*temp/10000 - 
            1452.62f*temp*temp*temp*temp/1000000 + 
            3044.9f*temp*temp*temp*temp*temp/1000000000;
    
//printf("UltrasonicVelocity: %d\t", (unsigned int)(V)); 
	return V/1000;   //m/s
}

void Flow_Caculate(_fp32 delta_time, _fp32 duration, struct Data *Lcd_data)
{
	/*delta_time***********ns*/
#if (FLOW_TEST&TEMP_TEST)
	_fp32 UltrasonicVelocity;
	UltrasonicVelocity = GetUltrasonicVelocity(Lcd_data->temp1/LCD_MULTIPLE);

	_fp32 flow_Velocity;
	//flow_Velocity = (delta_time/1000000000)*UltrasonicVelocity*UltrasonicVelocity/(2*SOUND_PATH*COS_RESULT);
	flow_Velocity = delta_time*UltrasonicVelocity*UltrasonicVelocity/(2*SOUND_PATH*COS_RESULT*10000);   //m/s, flow_Velocity*LCD_MULTIPLE

	Lcd_data->flow = CONST*K_COEFFICIENT*DIAMETER*DIAMETER*flow_Velocity*3600;  //m3/h, Lcd_data->flow*LCD_MULTIPLE
	Lcd_data->total_flow += Lcd_data->flow*duration/3600;   //m3, Lcd_data->total_flow*LCD_MULTIPLE
#endif
}

void Temp_Caculate(unsigned int *result, struct Data *Lcd_data, unsigned int num)
{
	int i;
#if TEMP_TEST
	//printf("Temp_Caculate...\n");        
#endif

	short a[num],b[num];
	for(i=0;i<num;i++)
	{
		a[i] = (short)(result[i]/0x10000);
		b[i] = (short)(result[i]%0x10000);
		if(b[i] == 0x1fff) b[i] = -1;   //It's a bug in fpga 
#if PRINT
//printf("0x%x\t0x%x\n", a[i],b[i]);
#endif
	}
	_fp32 r_input, r_output;
	     //1000.0ÊÇPT1000µÄµç×èÖµ£¬ÕâÊ±r_inputºÍr_outputÊÇµç×èÖµ
	_u32 temp_reg = *Thsens;
	if(temp_reg & 0x4)
	{	
		r_input = (_fp32)((a[5]-a[4])*Lcd_data->auto_caculate-(b[5]-b[4]))*2/(_fp32)((a[3]-a[2]+a[1]-a[0])*Lcd_data->auto_caculate-(b[3]-b[2]+b[1]-b[0])) ;
		r_output = (_fp32)((a[7]-a[6])*Lcd_data->auto_caculate-(b[7]-b[6]))*2/(_fp32)((a[3]-a[2]+a[1]-a[0])*Lcd_data->auto_caculate-(b[3]-b[2]+b[1]-b[0])) ;
 
		r_input += (_fp32)((a[11]-a[10])*Lcd_data->auto_caculate-(b[11]-b[10]))*2/(_fp32)((a[15]-a[14]+a[13]-a[12])*Lcd_data->auto_caculate-(b[15]-b[14]+a[13]-a[12])) ;
 		r_input /= 2;
		r_output += (_fp32)((a[9]-a[8])*Lcd_data->auto_caculate-(b[9]-b[8]))*2/(_fp32)((a[15]-a[14]+a[13]-a[12])*Lcd_data->auto_caculate-(b[15]-b[14]+a[13]-a[12])) ;
		r_output /=2;
	}
	else
	{		
		r_input = (_fp32)((a[3]-a[2])*Lcd_data->auto_caculate-(b[3]-b[2]))*2/(_fp32)((a[7]-a[6]+a[5]-a[4])*Lcd_data->auto_caculate-(b[7]-b[6]+b[5]-b[4])) ;
		r_output = (_fp32)((a[1]-a[0])*Lcd_data->auto_caculate-(b[1]-b[0]))*2/(_fp32)((a[7]-a[6]+a[5]-a[4])*Lcd_data->auto_caculate-(b[7]-b[6]+b[5]-b[4])) ;
 
		r_input += (_fp32)((a[13]-a[12])*Lcd_data->auto_caculate-(b[13]-b[12]))*2/(_fp32)((a[11]-a[10]+a[9]-a[8])*Lcd_data->auto_caculate-(b[11]-b[10]+a[9]-a[8])) ;
 		r_input /= 2;
		r_output += (_fp32)((a[15]-a[14])*Lcd_data->auto_caculate-(b[15]-b[14]))*2/(_fp32)((a[11]-a[10]+a[9]-a[8])*Lcd_data->auto_caculate-(b[11]-b[10]+a[9]-a[8])) ;
		r_output /=2;
	}

	_fp32 temp_in, temp_out;
	_fp32 tmp;
	//Í¨¹ý¹«Ê½¼ÆËã£¬ÕâÊ±r_inputºÍr_outputÊÇÎÂ¶ÈÖµ   
        //¹«Ê½À´Ô´ÓÚhttp://wenku.baidu.com/view/f9bab86a561252d380eb6e56.html Í¨¹ý²¬µç×è×èÖµÇóµÃÎÂ¶ÈµÄ·½·¨
        /******************************************************************************************************************************/
	/*      IN         */
	//tmp = r_input*1000;
	//temp_in = 101.373e-5*tmp*tmp + 23.5515*tmp - 245649725e-4;//ÊäÈëR(µ¥Î»:0.01R) Êä³öT(µ¥Î»:0.01¶È)
	//temp_in /= 100;
	temp_in = 10.1373f*r_input*r_input + 235.515f*r_input - 245.649725f;//ÊäÈëR(µ¥Î»:0.01R) Êä³öT(µ¥Î»:0.01¶È)
	
	/*      OUT         */
	//tmp = r_output*1000;
	//temp_out = 101.373e-5*tmp*tmp + 23.5515*tmp - 245649725e-4;//ÊäÈëR(µ¥Î»:0.01R) Êä³öT(µ¥Î»:0.01¶È)
	//temp_out /= 100;
	temp_out = 10.1373f*r_output*r_output + 235.515f*r_output - 245.649725f;//ÊäÈëR(µ¥Î»:0.01R) Êä³öT(µ¥Î»:0.01¶È)
        /******************************************************************************************************************************/

#if TEMP_TEST
	if((temp_in<0)||(temp_in>100)||(temp_out<0)||(temp_out>100))  
	{
		printf("---------------------------------------------------------------ERROR-----------------------------------------------------------------------\n");
		for(i=0;i<num;i++)
		{
			printf("result[%d] = 0x%x\n", i,result[i]);
		}
		printf("-------------------------------------------------------------------------------------------------------------------------------------------\n");
	}
#endif

	static int j=0;
	static _fp32 in[10];
	static _fp32 out[10];
	in[j] = temp_in;
	out[j++] = temp_out;
#if TEMP_TEST
	//printf("j = %d in: %d out: %d\n", j, (unsigned int)(temp_in*10000), (unsigned int)(temp_out*10000));
#endif
	if(j==10) 
	{
		temp_in = bubble_sort(&in, j);
		temp_out = bubble_sort(&out, j);
		j=0;
#if TEMP_TEST
		if(temp_in<0)
		{
			 tmp = 0 - temp_in;
			//printf("in: -%d\t", (unsigned int)(tmp*10000));   
			printf("---------------in: -");
		}
		else
		{
			 tmp = temp_in;
			//printf("in: %d\t", (unsigned int)(tmp*10000));    
			printf("---------------in: ");
		}
		printf_float(tmp);
		//printf("\t");
		if(temp_out<0)
		{
			 tmp = 0 - temp_out;
			//printf("out: -%d\t", (unsigned int)(tmp*10000)); 
			printf("---------------out: -");
		}
		else
		{
			 tmp = temp_out;
			//printf("out: %d\t", (unsigned int)(tmp*10000));  
			printf("---------------out: ");
		}
		printf_float(tmp);
		//printf("\n");
		printf("---------------------------------------------------------------------------------------------------------\n");
#endif
	}

	Lcd_data->temp1 = temp_in*LCD_MULTIPLE;
	Lcd_data->temp2 = temp_out*LCD_MULTIPLE;
	Lcd_data->temp0 = (temp_in - temp_out)*LCD_MULTIPLE;
}

_fp32 get_density(_fp32 temp)
{
    _fp32 density;
    density = 1000.2f - temp*0.42f;  //kg/m3
    return density;
}

_fp32 get_enthalpy(_fp32 temp)
{
    _fp32 enthalpy;
    enthalpy = temp*4.18f + 0.85f;   //kJ/kg
    return enthalpy;
}

void Heat_Caculate(_fp32 duration, struct Data *Lcd_data)
{
    _fp32 density;   //ÃÜ¶È
    _fp32 enthalpy_in, enthalpy_out;    //<9f>áìÊÖµ
    _fp32 heat_duration;

    density = get_density(Lcd_data->temp1/LCD_MULTIPLE);      //µ±ÈÈÁ¿±í°²×°ÔÚ½øË®¹ÜÉÏ
    enthalpy_in = get_enthalpy(Lcd_data->temp1/LCD_MULTIPLE);
    enthalpy_out = get_enthalpy(Lcd_data->temp2/LCD_MULTIPLE);

	static _fp32 Last_total_flow;    //ÉÏ´Î¼ÆËãÊ±µÄÀÛ»ýÁ÷Á¿
    heat_duration = (Lcd_data->total_flow - Last_total_flow)*density*(enthalpy_in - enthalpy_out);
    Lcd_data->heat = heat_duration/(duration/3600);
    Lcd_data->total_heat += heat_duration;

    Last_total_flow = Lcd_data->total_flow;

}

/**********************************************************************************************************************************************************************
	When a res_valid interrupt comes, it will do
		Firstly clear the interrupt bit;
		Secondly read the result from the related regs;
		Finally	clear the result pointer.
***********************************************************************************************************************************************************************/
_u32 res_ready(struct Data *Lcd_data)
{
#if RES_TEST
	printf("res_ready...\n");        
#endif

	_u32 ptr; 
	ptr = Sonar[8];   //0xbfeb4020
#if RES_TEST
	printf("ptr:0x%x\n", ptr);
#endif
	_u32 current_ptr0,current_ptr1,last_ptr0,last_ptr1;
	current_ptr0 = ptr&0xf;
#if RES_TEST
	printf("current_ptr0:0x%x\n", current_ptr0);
#endif
	current_ptr1 = (ptr>>4)&0xf;
#if RES_TEST
	printf("current_ptr1:0x%x\n", current_ptr1);
#endif
	last_ptr0 = (ptr>>8)&0xf;
#if RES_TEST
	printf("last_ptr0:0x%x\n", last_ptr0);
#endif
	last_ptr1 = (ptr>>12)&0xf;
#if RES_TEST
	printf("last_ptr1:0x%x\n", last_ptr1);
#endif

	_u32 state, direction;
	static _fp32 delta_time,time_up,time_down;
	state = PMU[1];
	direction = Sonar[0];
	
	_u32 result[16];
	_u32 i;
	for(i=0; i<16; i++)
	{
		result[i] = Sonar[16+i];    //0xbfeb4040 Result[0]
#if RES_TEST
	printf("result[%d] = 0x%x\n", i, result[i]);
#endif
	}
	PMU[15] = 0x80000000;  //0xbfeb003c, clear regs, then you can start next measure

        /******************************************************************************************************************************/
	if((state&0xe00)==0x400)
	{
		_u32 sonar;
		_u32 stop_num;
		sonar = Sonar[1];
		stop_num = ((sonar>>21)&0x7);
#if FLOW_TEST
	//printf("stop_num = %d\n", stop_num);
#endif

		if((sonar&0x100000)==0x0)
		{
			Lcd_data->auto_caculate = result[last_ptr0-1] - result[last_ptr0-2];
		}

		if((current_ptr0-last_ptr0)<stop_num)   //If there is no water in the pipe, then the result will be less than stop_num.
		{
			delta_time = 0;
			return 1;
		}
		else
		{
			time_up = Time_Caculate(&result, Lcd_data, 0, stop_num);
#if FLOW_TEST
	//printf("time_up: %d\n", (unsigned int)(time_up*1000));        
#endif
			time_down = Time_Caculate(&result, Lcd_data, last_ptr0, stop_num);
#if FLOW_TEST
	//printf("time_down: %d\n", (unsigned int)(time_down*1000));        
#endif
			delta_time = (time_down - time_up)/(stop_num-1);
		}

#if FLOW_TEST
		if(delta_time > 1000.0)  //if delta_time>1us
		{
			delta_time = 0;
			printf("---------------------------------------------------------------ERROR-----------------------------------------------------------------------\n");
			for(i=0;i<12;i++)
			{
				printf("result[%d] = 0x%x\n", i,result[i]);
			}
			printf("-------------------------------------------------------------------------------------------------------------------------------------------\n");
		}
#endif
		_fp32 tmp;
#if 0 //FLOW_TEST
		if(delta_time<0)
		{
			tmp = 0 - delta_time;
			printf("delta_time: -%d\n", (unsigned int)(tmp*1000));        
		}
		else
		{
			tmp = delta_time;
			printf("delta_time: %d\n", (unsigned int)(tmp*1000));        
		}
#endif

#if 1
		static _u32 last_count=0;
		static _u32 j=0;
		static _fp32 delta[8];
		delta[j++] = delta_time;
		if(j==8) 
		{
			_fp32 average_delta_time;
			average_delta_time = bubble_sort(&delta, j);
			j=0;
#if FLOW_TEST
			if(average_delta_time<0)
			{
				tmp = 0 - average_delta_time;
				printf("------------------average_delta_time: -%d\n", (_u32)(tmp*1000));        
			}
			else
			{
				tmp = average_delta_time;
				printf("------------------average_delta_time: %d\n", (_u32)(tmp*1000));        
			}
#endif
			_u32 count;
			_fp32 duration;
			count = *(volatile _u32 *)0xbfeb001c; 
			count &= COUNT_MASK;
#if PRINT
//printf("count: %d\n", count);
#endif
			duration = (_fp32)( (count - last_count)%COUNT_COMPARE )/16;
			last_count = count;
			if(duration>16) return 2;  //if duration > 16seconds, it should be an error.

			Flow_Caculate(average_delta_time, duration, Lcd_data);
			Heat_Caculate(duration, Lcd_data);
		}
#endif

	}
	else if((state&0xe00)==0x600)
	{
		Temp_Caculate(&result, Lcd_data, 16);
	}

	return 0;
}
#endif
