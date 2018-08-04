#!/home/mjohnson/local/bin/python2.7

usage = """%prog

 (c) Mark Johnson, 26th July 2012

Prepare AG input from training data."""

import optparse, re, sys

def source2AGinput(inf, outf, boundary_rex, nskip, goldflag):
    for line in inf:
        line = line.strip()
        if len(line) == 0:
            continue
        components = line.split(None, nskip)
        words = boundary_rex.split(components[-1])
        if goldflag:
            outf.write(' '.join(''.join(word.split())
                                for word in words))
            outf.write('\n')
        else:
            outf.write(' '.join(' '.join(word.split())
                                for word in words))
            outf.write('\n')

if __name__ == '__main__':
    parser = optparse.OptionParser(usage=usage)
    parser.add_option("-b", "--boundary-re", dest="boundary_re", 
                      default=r"(?<!\S)[(][^()]*[)](?!\S)",
                      help="word boundary marker")
    parser.add_option("-g", "--gold", dest="gold", default=False, action="store_true",
                      help="prepare gold evaluation data")
    parser.add_option("-s", "--skip", dest="skip", type="int", default=1,
                      help="number of words at beginning of line to skip")
    options, args = parser.parse_args()
    boundary_rex = re.compile(options.boundary_re)
    if args:
        for arg in args:
            source2AGinput(open(arg, "rU"), sys.stdout, boundary_rex, 
                           options.skip, options.gold)
    else:
        source2AGinput(sys.stdin, sys.stdout, boundary_rex, 
                       options.skip, options.gold)
