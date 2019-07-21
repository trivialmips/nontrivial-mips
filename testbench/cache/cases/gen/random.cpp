#include <iostream>
#include <random>
#include <unordered_map>
#include <iomanip>

using namespace std;

const size_t ROWS = 256 * 5;
const long double W_RATIO = 0.4;

int main() {
  unordered_map<uint32_t, uint32_t> mem;

  random_device rd;
  mt19937 gen(rd());

  uniform_int_distribution<uint32_t> addr_dist(0, 255); // * 4
  uniform_int_distribution<uint32_t> data_dist(0, 0xfffffffful);
  uniform_real_distribution<long double> write_dist(0, 1);

  cout<<hex;

  for(size_t i = 0; i<ROWS; ++i) {
    const bool is_write = write_dist(gen) < W_RATIO;
    const auto addr = addr_dist(gen) * 4;

    if(is_write) cout<<"w ";
    else cout<<"r ";

    cout<<addr<<" ";

    if(is_write) {
      const auto data = data_dist(gen);
      mem[addr] = data;

      cout<<data<<endl;
    } else {
      if(mem.count(addr) == 0) cout<<0<<endl;
      else cout<<mem[addr]<<endl;
    }
  }
}
