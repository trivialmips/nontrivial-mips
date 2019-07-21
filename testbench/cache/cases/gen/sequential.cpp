#include <iostream>
#include <random>
#include <unordered_map>
#include <algorithm>
#include <iomanip>

using namespace std;

int main() {
  unordered_map<uint32_t, uint32_t> mem;

  random_device rd;
  mt19937 gen(rd());

  uniform_int_distribution<uint32_t> dist(0, 0xfffffffful);

  cout<<hex;

  // Generate writes
  for(uint32_t i = 0; i < 256; ++i)
    mem[i] = dist(gen);

  for(uint32_t i = 0; i < 256; ++i)
    cout<<"w "<<i*4<<" "<<mem[i]<<endl;
  for(uint32_t i = 0; i < 256; ++i)
    cout<<"r "<<i*4<<" "<<mem[i]<<endl;

  // Rewrite
  for(uint32_t i = 0; i < 256; ++i)
    mem[i] = dist(gen);
  for(uint32_t i = 0; i < 256; ++i)
    cout<<"w "<<i*4<<" "<<mem[i]<<endl;
  for(uint32_t i = 0; i < 256; ++i)
    cout<<"r "<<i*4<<" "<<mem[i]<<endl;

  // Random read
  vector<uint32_t> addrs;
  addrs.reserve(256);
  for(uint32_t i = 0; i<256; ++i)
    addrs.push_back(i);

  shuffle(addrs.begin(), addrs.end(), gen);
  for(const auto &addr : addrs)
    cout<<"r "<<addr*4<<" "<<mem[addr]<<endl;
}
