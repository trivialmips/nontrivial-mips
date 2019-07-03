struct Date_Time{
    _u32 Year;
    _u32 Month;
    _u32 Day;
    _u32 Hour;
    _u32 Minute;
    _u32 Second;
};

void calendar(struct Date_Time *Date_and_Time);
//void calendar(struct Date_Time *Date_and_Time, _u32 lcdmode);
void DateInit(struct Date_Time *Date_and_Time);
