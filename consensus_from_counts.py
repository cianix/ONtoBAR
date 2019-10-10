#
# Copyright 2014 Luca Venturini. All rights reserved.
# Luca Venturini <luca.venturini@univr.it>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import sys;

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

inFile = open(sys.argv[1],'r')

sys.stdout.write('>CONSENSUS SEQUENCE\n')

c = 0

for line in inFile:
	data = line.strip().split('\t')
	if is_number(data[0]):
		
		cov = float(data[2])
		countA = float(data[4])
		countC = float(data[5])
		countG = float(data[6])
		countT = float(data[7])
	        try: freqA = countA/cov
	        except ZeroDivisionError: freqA = 0
		try: freqG = countG/cov
	        except ZeroDivisionError: freqG = 0
		try: freqC = countC/cov
	        except ZeroDivisionError: freqC = 0
		try: freqT = countT/cov
	        except ZeroDivisionError: freqT = 0
	
		freqMAX = max(freqA , freqC , freqG , freqT)
		if freqA == freqMAX:
			if c == 80:
				sys.stdout.write('A\n')
				c = 0
			else:
				sys.stdout.write('A')
				c += 1
		elif freqC == freqMAX:
			if c == 80:
				sys.stdout.write('C\n')
				c = 0
			else:
				sys.stdout.write('C')
				c += 1
		elif freqG == freqMAX:
			if c == 80:
				sys.stdout.write('G\n')
				c = 0
			else:
				sys.stdout.write('G')
				c += 1
		elif freqT == freqMAX:
			if c == 80:
				sys.stdout.write('T\n')
				c = 0
			else:
				sys.stdout.write('T')
				c += 1
