
%.o:%.c
	$(CC) $(DEBUG) $(FLAGS) -EL -c -o $@ $<

objs= memset.o memcpy.o printf.o udelay.o putchar.o puts.o printhex.o  printbase.o memcmp.o strcat.o strchr.o strcmp.o strtok.o strspn.o strcspn.o 

$(TOPDIR)/libtinyc.a: $(objs)
	$(AR) -cr  $@ $?

clean:
	rm -f *.o *.a *.s 

