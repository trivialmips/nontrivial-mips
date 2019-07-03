int puts(char *s)
{
char c;
while((c=*s))
{
 if(c == '\n') putchar('\r');
 putchar(c);
 s++;
}
putchar('\r');
putchar('\n');
return 0;
}
