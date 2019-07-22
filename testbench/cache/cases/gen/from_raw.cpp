#include <iostream>
#include <random>
#include <iomanip>
#include <unordered_map>

using namespace std;

#define ADDR_SLICE true

int main() {
  random_device rd;
  mt19937 gen(rd());

  unordered_map<uint32_t, uint32_t> mem;
  uniform_int_distribution<uint32_t> dist(0, 0xfffffffful);

  size_t count = 0;
  while(!cin.eof()) {
    char mode;
    uint32_t addr, data;

    cin>>hex>>mode>>addr>>data;
    if(cin.eof()) break;

    ++count;

#ifdef ADDR_SLICE
    addr &= 0xffff;
#endif
    addr &= ~0x3; // align to 4 bytes

    cout<<hex<<mode<<" "<<addr<<" ";

    if(mode == 'r') {
      if(mem.count(addr) > 0) cout<<mem[addr]<<endl;
      else cout<<0<<endl;
    } else {
      mem[addr] = dist(gen);
      cout<<mem[addr]<<endl;
    }
  }

  cerr<<"Total count: "<<count<<endl;
}
