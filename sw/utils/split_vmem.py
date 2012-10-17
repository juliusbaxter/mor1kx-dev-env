import sys, os, getopt, string
from optparse import OptionParser

if (__name__ == '__main__'):
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("--in", dest="inFile", default="sram.vmem", help="Input VMEM file")
    parser.add_option("--out", dest="outFile", default="sram", help="Output VMEM file prefix")
    (opts, args) = parser.parse_args()

    f = open(opts.inFile, 'r')
    f0 = open ("%s0.vmem" % opts.outFile, 'w')
    f1 = open ("%s1.vmem" % opts.outFile, 'w')
    f2 = open ("%s2.vmem" % opts.outFile, 'w')
    f3 = open ("%s3.vmem" % opts.outFile, 'w')
    for line in f.readlines():
        line = line.rstrip('\n')
#        print line, " ", line[0]
        f0.write("%s%s\n"%(line[0],line[1]))
        f1.write("%s%s\n"%(line[2],line[3]))
        f2.write("%s%s\n"%(line[4],line[5]))
        f3.write("%s%s\n"%(line[6],line[7]))
       
        
        
    
