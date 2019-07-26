#include <iostream>
#include <random>
#include <unordered_map>
#include <iomanip>

using namespace std;

const size_t ROWS = 50000;
const long double W_RATIO = 0.4;
const long double I_RATIO = 0.1;

uint32_t be_write(uint32_t base, uint32_t write, uint8_t be) {
  uint32_t result = base;

  for(size_t i = 0; i < 4; ++i) if((be >> i) & 1) {
    result &= ~(0xfful << (i*8));
    result |= write & (0xfful << (i*8));
  }

  return result;
}

int main() {
  unordered_map<uint32_t, uint32_t> mem;

  random_device rd;
  mt19937 gen(rd());

  uniform_int_distribution<uint32_t> addr_dist(0, 255); // * 4
  uniform_int_distribution<uint32_t> data_dist(0, 0xfffffffful);
  uniform_real_distribution<long double> mode_dist(0, 1);
  uniform_int_distribution<uint8_t> be_dist(0, 0xf); // 4-byte byte enable

  cout<<hex;

  for(size_t i = 0; i<ROWS; ++i) {
    const auto mode = mode_dist(gen);
    const bool is_write = mode < W_RATIO;
    const bool is_invalidate = !is_write && mode < W_RATIO + I_RATIO;

    const auto addr = addr_dist(gen) * 4;

    if(is_invalidate) cout<<"i ";
    else if(is_write) cout<<"w ";
    else cout<<"r ";

    cout<<addr<<" ";

    if(is_invalidate) {
      cout<<"0 0"<<endl;
    } else if(is_write) {
      const auto be = be_dist(gen);
      const auto data = data_dist(gen);
      mem[addr] = be_write(mem[addr], data, be);

      cout<<data<<" "<<(uint32_t) be<<endl;
    } else {
      if(mem.count(addr) == 0) cout<<"0 0"<<endl;
      else cout<<mem[addr]<<" 0"<<endl;
    }
  }
}
