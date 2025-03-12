#!/usr/bin/awk -f

NR == 1 { next }

{
  genomeCoverage += ($2 * $3);
  count += $3;
}

END {
  if (count > 0) {
    printf "coverage\t%f\n", genomeCoverage / count;
  } else {
    print "coverage\t0";
  }
}
