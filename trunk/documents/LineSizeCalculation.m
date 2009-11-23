% ECE485 Cash Controller Design Project
% Number of cache lines calculation

% syms x;
% eqn = ((64*8 + 1 + 1 + (32 - log2(x) - 4 - 2) )* x * 4) - 2*8*2^20;
% isfloat(solve(eqn,x))
% ((64*8 + 1 + 1 + (32 - log2(7957) - 4 - 2) )* 7957 * 4) - 2*8*2^20

% Parameters
NumWays=4;
NumBytes=64;
NumWords=NumBytes/4;
NumWordSelBits=log2(NumWords);
NumAddrBits=32;
WordSize=NumBytes*8;
CacheSize=2*2^20*8;

%Random Replacement
%Number of lines per way
f=@(x)((WordSize + 1 + 1 + (NumAddrBits - log2(x) - 2 - NumWordSelBits) )* x * NumWays) - CacheSize;
fzero(f,[7000,8000])

%Actual Cache size with 13 index bis
NumIndexBits=13;
NumLines=2^NumIndexBits;
NumTagBits=NumAddrBits-NumWordSelBits-NumIndexBits-2;

((WordSize + 1 + 1 + NumTagBits)* NumLines*NumWays)/(8*2^20)

%Actual Cache size with 12 index bis
NumIndexBits=12;
NumLines=2^NumIndexBits;
NumTagBits=NumAddrBits-NumWordSelBits-NumIndexBits-2;

((WordSize + 1 + 1 + NumTagBits)* NumLines*NumWays)/(8*2^20)

f=@(x)(((64*8 + 1 + 1 + (32 - log2(x) - 4 - 2) )* x )* 4) + 5*x - 2*8*2^20;
fzero(f,[7000,8000])

f=@(x)(((64*8 + 1 + 1 + (32 - log2(x) - 4 - 2) )* x )* 4) + 8*x*4 - 2*8*2^20;
fzero(f,[7000,8000])

f=@(x)(((64*8 + 1 + 1 + (32 - log2(x) - 4 - 2) )* x )* 4) + 3*x - 2*8*2^20;
fzero(f,[7000,8000])

(((64*8 + 1 + 1 + 13)* 4096*2* 4)+5*4096*2)/8/2^20;
fzero(f,[7000,8000])

f=@(x)(((64*8 + 1 + 1 + (32 - log2(x) - 4 - 2) )* x )* 2) + 3*x - 2*8*2^20;
fzero(f,[1000,80000])
log2(fzero(f,[10,80000]))
