#!/usr/bin/env python2.7

balance = 1000.0

for year in range(1, 11):
    if year >= 2:
        balance = balance + 1000.0
    balance = balance * (1 + 0.047)

print balance